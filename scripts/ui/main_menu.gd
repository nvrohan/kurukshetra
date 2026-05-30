extends Control
## MainMenu — D4.7 lobby UI with room-code entry.
##
## Host: NetworkManager.host_match() then change to match scene; the room
## code is shown in HostedCodeLabel so the host can read it out / share.
## Join: host enters a 4-char A-Z2-9 room code (no I/O/0/1) and a host IP
## (defaults to 127.0.0.1; LAN play uses 192.168.*). The code is *not* a
## relay token (no STUN/relay infra in MVP — see ARCHITECTURE.md §3.1):
## it's a stable per-match identifier the joiner echoes back to the host
## so we can refuse joins to the wrong match if the host port has been
## reused. D5/D6 will replace this with a proper rendezvous server.
##
## CLI flags (used by tools/run-prototype.sh):
##   --auto-host          → host on startup
##   --auto-join=IP:PORT  → join on startup (no code check)

const MATCH_SCENE := "res://scenes/match.tscn"

@onready var host_btn: Button = $VBoxContainer/HostButton
@onready var join_btn: Button = $VBoxContainer/JoinButton
@onready var quit_btn: Button = $VBoxContainer/QuitButton
@onready var hosted_code_label: Label = $VBoxContainer/HostedCodeLabel
@onready var code_edit: LineEdit = $VBoxContainer/CodeRow/CodeEdit
@onready var host_edit: LineEdit = $VBoxContainer/HostRow/HostEdit
@onready var status_label: Label = $VBoxContainer/Status if has_node("VBoxContainer/Status") else null

func _ready() -> void:
	host_btn.pressed.connect(_on_host_pressed)
	join_btn.pressed.connect(_on_join_pressed)
	quit_btn.pressed.connect(_on_quit_pressed)
	NetworkManager.connected_to_server.connect(_on_connected)
	NetworkManager.join_failed.connect(_on_join_failed)

	# CLI conveniences for the run-prototype.sh script and the cron tests.
	# User args (after --) live in get_cmdline_user_args(), not get_cmdline_args().
	var args := OS.get_cmdline_user_args()
	print("[MainMenu] user args: %s" % str(args))
	for arg in args:
		if arg == "--auto-host":
			print("[MainMenu] --auto-host")
			_on_host_pressed()
		elif arg.begins_with("--auto-join="):
			var spec := arg.substr("--auto-join=".length())
			var parts := spec.split(":")
			var ip := parts[0]
			var port := int(parts[1]) if parts.size() > 1 else NetworkManager.PORT_BASE
			print("[MainMenu] --auto-join=%s:%d" % [ip, port])
			NetworkManager.join_match(ip, port)

func _on_host_pressed() -> void:
	var port := NetworkManager.host_match()
	if port < 0:
		_set_status("host failed")
		return
	hosted_code_label.text = "Room code: %s   (port %d)" % [NetworkManager.room_code, port]
	_set_status("hosting on %d, code %s" % [port, NetworkManager.room_code])
	# Server hosts the match scene immediately.
	get_tree().change_scene_to_file(MATCH_SCENE)

func _on_join_pressed() -> void:
	var ip := host_edit.text.strip_edges() if host_edit else "127.0.0.1"
	if ip == "":
		ip = "127.0.0.1"
	var code := code_edit.text.strip_edges().to_upper() if code_edit else ""
	# Soft-validate the code: must be empty (peer-direct join) or 4 chars
	# from the trusted alphabet. We don't enforce the code matches the host
	# yet (no rendezvous infra) but we display it so the joiner sees the
	# value they typed, and we stash it on NetworkManager for any future
	# server-side check.
	if code != "" and not _is_valid_code(code):
		_set_status("invalid code: 4 chars from A-Z 2-9 (no I O 0 1)")
		return
	NetworkManager.room_code = code
	NetworkManager.join_match(ip, NetworkManager.PORT_BASE)
	_set_status("joining %s code=%s..." % [ip, code if code != "" else "<none>"])

func _is_valid_code(code: String) -> bool:
	if code.length() != 4:
		return false
	const ALPHABET := "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"
	for c in code:
		if not ALPHABET.contains(c):
			return false
	return true

func _on_connected(_peer_id: int) -> void:
	# Client transitions to match scene when connected.
	get_tree().change_scene_to_file(MATCH_SCENE)

func _on_join_failed(reason: String) -> void:
	_set_status("join failed: %s" % reason)

func _on_quit_pressed() -> void:
	get_tree().quit()

func _set_status(text: String) -> void:
	print("[MainMenu] %s" % text)
	if status_label:
		status_label.text = text
