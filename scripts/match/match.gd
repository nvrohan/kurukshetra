extends Node3D
## Match — D3 match controller.
##
## Owns the MultiplayerSpawner that creates Player instances on connect.
## Server-side spawn; clients get them replicated automatically.

const PLAYER_SCENE := preload("res://scenes/player.tscn")

@onready var players_root: Node = $Players
@onready var spawn_points: Node3D = $SpawnPoints
@onready var zone_manager: Node = $ZoneManager

var _spawn_index := 0

func _ready() -> void:
	add_to_group("match")
	if multiplayer.is_server() or not multiplayer.has_multiplayer_peer():
		# Listen for new peers FIRST so we don't miss connections that
		# arrive before our deferred host-spawn runs.
		NetworkManager.peer_connected.connect(_server_spawn_player)
		NetworkManager.peer_disconnected.connect(_server_despawn_player)
		# Defer host's own spawn one frame to let MultiplayerSpawner finish
		# its scene-tree wiring (avoids "Node not found: MultiplayerSynchronizer"
		# when clients connect before peer 1 is fully wired).
		_server_spawn_player.call_deferred(1)
		print("[Match] server-side ready, spawn-on-connect armed")
	else:
		print("[Match] client-side ready, peer_id=%d" % multiplayer.get_unique_id())

func _server_spawn_player(peer_id: int) -> void:
	if not (multiplayer.is_server() or not multiplayer.has_multiplayer_peer()):
		return
	if players_root.has_node(str(peer_id)):
		return  # already spawned
	var player := PLAYER_SCENE.instantiate()
	player.name = str(peer_id)
	player.peer_id = peer_id
	player.add_to_group("players")
	# Pick a spawn point round-robin.
	var spawns := spawn_points.get_children()
	if spawns.size() > 0:
		var sp: Node3D = spawns[_spawn_index % spawns.size()]
		player.position = sp.position
		_spawn_index += 1
	players_root.add_child(player, true)  # readable name = true
	print("[Match] spawned player for peer %d at %s" % [peer_id, player.position])

func _server_despawn_player(peer_id: int) -> void:
	if not (multiplayer.is_server() or not multiplayer.has_multiplayer_peer()):
		return
	if players_root.has_node(str(peer_id)):
		players_root.get_node(str(peer_id)).queue_free()
		print("[Match] despawned player for peer %d" % peer_id)
