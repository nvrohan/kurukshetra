extends Node3D
## Match — D4 match controller.
##
## Owns a MultiplayerSpawner with a custom spawn_function. All player spawns
## (including the host's own) go through `spawner.spawn(peer_id)`, which
## guarantees the spawn event is recorded by the spawner and replayed to any
## peer that connects later. This is the proper fix for the D3 known issue
## where peer 1's host-side player wasn't being replicated to first-joining
## clients ("Node not found: Match/Players/1/MultiplayerSynchronizer").

const PLAYER_SCENE := preload("res://scenes/player.tscn")

@onready var players_root: Node = $Players
@onready var spawn_points: Node3D = $SpawnPoints
@onready var zone_manager: Node = $ZoneManager
@onready var spawner: MultiplayerSpawner = $MultiplayerSpawner

var _spawn_index := 0
var _bleedout_accumulator := 0.0  # seconds; ticks 30s bleedout for downed players (D4.4)

func _ready() -> void:
	add_to_group("match")
	# Wire the spawner's custom spawn function. Returning the constructed
	# node tells MultiplayerSpawner to track it; clients will run the same
	# function with the same arg (the peer_id int) and end up with an
	# identical local copy.
	spawner.spawn_function = _spawn_player_node
	if multiplayer.is_server() or not multiplayer.has_multiplayer_peer():
		# Listen for new peers FIRST so we don't miss connections that
		# arrive before our deferred host-spawn runs.
		NetworkManager.peer_connected.connect(_server_spawn_player)
		NetworkManager.peer_disconnected.connect(_server_despawn_player)
		# Defer host's own spawn one frame to let the spawner finish wiring.
		_server_spawn_player.call_deferred(1)
		print("[Match] server-side ready, spawn-on-connect armed")
	else:
		print("[Match] client-side ready, peer_id=%d" % multiplayer.get_unique_id())

func _physics_process(delta: float) -> void:
	# Server-only: tick bleedout for downed players (D4.4). 30 s pool drains
	# at 1 hp/s; when hp hits 0 the player dies. server_bleedout_tick handles
	# the actual hp decrement and death RPC.
	if not (multiplayer.is_server() or not multiplayer.has_multiplayer_peer()):
		return
	_bleedout_accumulator += delta
	if _bleedout_accumulator >= 1.0:
		_bleedout_accumulator -= 1.0
		for p in players_root.get_children():
			if p.has_method("server_bleedout_tick"):
				p.server_bleedout_tick(1.0)

func _server_spawn_player(peer_id: int) -> void:
	if not (multiplayer.is_server() or not multiplayer.has_multiplayer_peer()):
		return
	if players_root.has_node(str(peer_id)):
		return  # already spawned
	# spawn() runs _spawn_player_node on every peer (including server) and
	# is recorded so late-joiners get replayed. Pass the peer_id as the
	# spawn data; spawn point selection is server-side via _spawn_index.
	spawner.spawn(peer_id)

func _spawn_player_node(data: Variant) -> Node:
	var peer_id: int = int(data)
	var player := PLAYER_SCENE.instantiate()
	player.name = str(peer_id)
	player.peer_id = peer_id
	player.add_to_group("players")
	# Authority MUST be set before _ready (i.e. here in _spawn_custom), or
	# the synchronizer rejects pending spawns with "no network ID". This is
	# the second half of the D3 host-spawn fix.
	player.set_multiplayer_authority(peer_id)
	# Server picks the spawn point, clients get position via MultiplayerSynchronizer.
	if multiplayer.is_server() or not multiplayer.has_multiplayer_peer():
		var spawns := spawn_points.get_children()
		if spawns.size() > 0:
			var sp: Node3D = spawns[_spawn_index % spawns.size()]
			player.position = sp.position
			_spawn_index += 1
	print("[Match] spawn_function for peer %d at %s (server=%s)" % [peer_id, player.position, str(multiplayer.is_server())])
	return player

func _server_despawn_player(peer_id: int) -> void:
	if not (multiplayer.is_server() or not multiplayer.has_multiplayer_peer()):
		return
	if players_root.has_node(str(peer_id)):
		players_root.get_node(str(peer_id)).queue_free()
		print("[Match] despawned player for peer %d" % peer_id)

# region kill feed (D4.6) -------------------------------------------------

## Server-only: announce a kill to every peer's HUD.
## `victim` and `killer` are display strings (e.g. "Player 1234567"),
## `weapon` is the weapon display name (or "zone" / "bleedout").
@rpc("authority", "call_local", "reliable")
func broadcast_kill(killer: String, victim: String, weapon: String) -> void:
	for hud in get_tree().get_nodes_in_group("match_hud"):
		if hud.has_method("push_kill"):
			hud.push_kill(killer, victim, weapon)

## Helper used by Player on the server side. Builds display strings then
## RPCs broadcast_kill to every peer.
func server_announce_kill(killer_peer: int, victim_peer: int, weapon: String) -> void:
	if not (multiplayer.is_server() or not multiplayer.has_multiplayer_peer()):
		return
	var killer_name := _peer_display_name(killer_peer)
	var victim_name := _peer_display_name(victim_peer)
	broadcast_kill.rpc(killer_name, victim_name, weapon)

func _peer_display_name(peer_id: int) -> String:
	if peer_id == 0:
		return "the zone"
	if peer_id < 0:
		return "bleedout"
	var info: Dictionary = GameState.players.get(peer_id, {})
	if info.has("name") and info["name"]:
		return String(info["name"])
	return "Player %d" % peer_id

# endregion

# region loot pickup (D4.5) -----------------------------------------------

## Server-side pickup resolver. Player.try_pickup() RPCs this. We resolve
## by walking the loot group, finding the closest unconsumed pickup within
## INTERACT_RANGE of the requesting player's position, and applying its
## effect server-authoritatively. The pickup then despawns.
const PICKUP_RANGE := 2.5

@rpc("any_peer", "call_local", "reliable")
func server_request_pickup() -> void:
	if not (multiplayer.is_server() or not multiplayer.has_multiplayer_peer()):
		return
	var sender_id := multiplayer.get_remote_sender_id()
	if sender_id == 0:
		sender_id = multiplayer.get_unique_id()  # local-server pickup
	if not players_root.has_node(str(sender_id)):
		return
	var player := players_root.get_node(str(sender_id))
	var origin: Vector3 = player.global_position
	var best: Node = null
	var best_d: float = PICKUP_RANGE
	for l in get_tree().get_nodes_in_group("loot"):
		if not is_instance_valid(l) or bool(l.get("consumed")):
			continue
		var d: float = origin.distance_to(l.global_position)
		if d < best_d:
			best_d = d
			best = l
	if best == null:
		return
	if not best.has_method("server_consume"):
		return
	if not best.server_consume(sender_id):
		return
	var kind: int = int(best.get("kind"))
	var payload: String = String(best.get("payload"))
	match kind:
		0:  # weapon
			var def: WeaponDef = load(payload)
			if def != null and player.get("weapon") != null:
				player.weapon.equip(def)
				print("[Match] peer %d picked up weapon %s" % [sender_id, def.id])
		1:  # armor
			var tier := int(payload)
			if player.has_method("equip_armor"):
				player.equip_armor(tier)
		2:  # med
			var amount := float(payload)
			if player.has_method("heal"):
				player.heal(amount)

# endregion
