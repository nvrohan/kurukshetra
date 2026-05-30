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
