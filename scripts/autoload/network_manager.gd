extends Node
## NetworkManager — wraps Godot's MultiplayerAPI for Kurukshetra.
##
## v0.1 scaffold: signal surface only, no transport wired up yet.
## Deliverable 3 will add ENet host/join + reconciliation.
##
## See docs/ARCHITECTURE.md §3 (Networking Architecture) for the contract
## this autoload is implementing.

signal connected_to_server(peer_id: int)
signal disconnected_from_server(reason: String)
signal peer_connected(peer_id: int)
signal peer_disconnected(peer_id: int)
signal room_code_assigned(code: String)

## Default ENet port range. One match per port. See ARCHITECTURE.md §6.4.
const PORT_BASE := 30000
const PORT_MAX := 30099
const MAX_PEERS := 16  ## 4 squads × 4 players. ARCHITECTURE.md §1.

## Authoritative server tick. ARCHITECTURE.md §3.3.
const SERVER_TICK_HZ := 30
const SNAPSHOT_HZ := 20

var is_server: bool = false
var room_code: String = ""

func _ready() -> void:
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.server_disconnected.connect(_on_server_disconnected)
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	print("[NetworkManager] ready (v0.1 scaffold — transport not wired yet)")

# region transport API (stubs — to be implemented in deliverable 3) -------

## Host a match server. Returns the assigned port, or -1 on failure.
func host_match(_port_hint: int = PORT_BASE) -> int:
	push_warning("NetworkManager.host_match not implemented (deliverable 3)")
	return -1

## Join a match by host:port (LAN) or room code (WAN, post-MVP relay).
func join_match(_address: String, _port: int) -> bool:
	push_warning("NetworkManager.join_match not implemented (deliverable 3)")
	return false

func leave_match() -> void:
	if multiplayer.multiplayer_peer != null:
		multiplayer.multiplayer_peer.close()
		multiplayer.multiplayer_peer = null
	is_server = false
	room_code = ""

# endregion

# region signal handlers --------------------------------------------------

func _on_connected_to_server() -> void:
	connected_to_server.emit(multiplayer.get_unique_id())

func _on_server_disconnected() -> void:
	disconnected_from_server.emit("server closed")

func _on_peer_connected(peer_id: int) -> void:
	peer_connected.emit(peer_id)

func _on_peer_disconnected(peer_id: int) -> void:
	peer_disconnected.emit(peer_id)

# endregion
