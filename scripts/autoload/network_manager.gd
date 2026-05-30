extends Node
## NetworkManager — wraps Godot's MultiplayerAPI for Kurukshetra.
##
## D3 implementation: ENet host + join, --server CLI flag for headless,
## room-code stub (D5 will wire the real WAN code system).
##
## See docs/ARCHITECTURE.md §3 (Networking Architecture) and ADR 0006.

signal connected_to_server(peer_id: int)
signal disconnected_from_server(reason: String)
signal peer_connected(peer_id: int)
signal peer_disconnected(peer_id: int)
signal hosted(port: int)
signal join_failed(reason: String)

## Default ENet port range. One match per port. ARCHITECTURE.md §6.4.
const PORT_BASE := 30000
const PORT_MAX := 30099
const MAX_PEERS := 16  ## 4 squads × 4 players. ARCHITECTURE.md §1.

## Authoritative server tick. ARCHITECTURE.md §3.3.
const SERVER_TICK_HZ := 30
const SNAPSHOT_HZ := 20

var is_server: bool = false
var room_code: String = ""
var peer: ENetMultiplayerPeer

func _ready() -> void:
	print("[NetworkManager] ready")
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.server_disconnected.connect(_on_server_disconnected)
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)

	# Honour --server CLI flag for headless dedicated-server boot (D4-friendly,
	# but works in D3 too). User args (after --) are in get_cmdline_user_args().
	var args := OS.get_cmdline_user_args()
	print("[NetworkManager] user args: %s" % str(args))
	if "--server" in args or OS.has_feature("dedicated_server"):
		print("[NetworkManager] --server flag detected; auto-hosting on port %d" % PORT_BASE)
		var port := host_match(PORT_BASE)
		if port < 0:
			push_error("[NetworkManager] failed to host on %d; quitting" % PORT_BASE)
			get_tree().quit(1)
		else:
			print("[NetworkManager] dedicated server up on port %d" % port)
			# Auto-load match scene on the server side so peers have something
			# to spawn into when they connect.
			get_tree().change_scene_to_file.call_deferred("res://scenes/match.tscn")

# region transport API ----------------------------------------------------

## Host a match server. Returns the assigned port, or -1 on failure.
## Tries `port_hint`, then walks PORT_BASE..PORT_MAX if that's busy.
func host_match(port_hint: int = PORT_BASE) -> int:
	peer = ENetMultiplayerPeer.new()
	var ports := [port_hint]
	for p in range(PORT_BASE, PORT_MAX + 1):
		if p != port_hint:
			ports.append(p)
	for port in ports:
		var err := peer.create_server(port, MAX_PEERS)
		if err == OK:
			multiplayer.multiplayer_peer = peer
			is_server = true
			room_code = _generate_room_code()
			hosted.emit(port)
			print("[NetworkManager] hosting on port %d, room code %s" % [port, room_code])
			return port
	push_error("[NetworkManager] no free port in %d-%d" % [PORT_BASE, PORT_MAX])
	return -1

## Join a match by host:port. D3: bare IP+port; D4 will add room-code → relay.
func join_match(address: String, port: int = PORT_BASE) -> bool:
	peer = ENetMultiplayerPeer.new()
	var err := peer.create_client(address, port)
	if err != OK:
		push_error("[NetworkManager] create_client failed: %s" % error_string(err))
		join_failed.emit("create_client failed: %s" % error_string(err))
		return false
	multiplayer.multiplayer_peer = peer
	is_server = false
	print("[NetworkManager] dialing %s:%d ..." % [address, port])
	return true

func leave_match() -> void:
	if multiplayer.multiplayer_peer != null:
		multiplayer.multiplayer_peer.close()
		multiplayer.multiplayer_peer = null
	is_server = false
	room_code = ""
	peer = null

# endregion

# region helpers ----------------------------------------------------------

func _generate_room_code() -> String:
	# 4-char A-Z 0-9 (no I, O, 0, 1 to avoid confusion). 32^4 ≈ 1M codes.
	const ALPHABET := "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var s := ""
	for i in range(4):
		s += ALPHABET[rng.randi_range(0, ALPHABET.length() - 1)]
	return s

# endregion

# region signal handlers --------------------------------------------------

func _on_connected_to_server() -> void:
	print("[NetworkManager] connected (peer_id=%d)" % multiplayer.get_unique_id())
	connected_to_server.emit(multiplayer.get_unique_id())

func _on_connection_failed() -> void:
	push_error("[NetworkManager] connection_failed")
	join_failed.emit("connection_failed")
	multiplayer.multiplayer_peer = null
	peer = null

func _on_server_disconnected() -> void:
	print("[NetworkManager] server disconnected")
	disconnected_from_server.emit("server closed")
	multiplayer.multiplayer_peer = null
	peer = null

func _on_peer_connected(peer_id: int) -> void:
	print("[NetworkManager] peer connected: %d" % peer_id)
	peer_connected.emit(peer_id)

func _on_peer_disconnected(peer_id: int) -> void:
	print("[NetworkManager] peer disconnected: %d" % peer_id)
	peer_disconnected.emit(peer_id)

# endregion
