extends Control
## MainMenu — D3: real host/join wiring.
##
## On Host: NetworkManager.host_match() then change to match scene.
## On Join: prompt for IP (default 127.0.0.1), join, scene change happens
##          when peer_connected fires (see _on_connected).

const MATCH_SCENE := "res://scenes/match.tscn"

@onready var host_btn: Button = $VBoxContainer/HostButton
@onready var join_btn: Button = $VBoxContainer/JoinButton
@onready var quit_btn: Button = $VBoxContainer/QuitButton
@onready var status_label: Label = $VBoxContainer/Status if has_node("VBoxContainer/Status") else null

func _ready() -> void:
	host_btn.pressed.connect(_on_host_pressed)
	join_btn.pressed.connect(_on_join_pressed)
	quit_btn.pressed.connect(_on_quit_pressed)
	NetworkManager.connected_to_server.connect(_on_connected)
	NetworkManager.join_failed.connect(_on_join_failed)

	# CLI conveniences for the run-prototype.sh script:
	#   --auto-host          → host on startup
	#   --auto-join=IP:PORT  → join on startup
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
	_set_status("hosting on %d, code %s" % [port, NetworkManager.room_code])
	# Server hosts the match scene immediately.
	get_tree().change_scene_to_file(MATCH_SCENE)

func _on_join_pressed() -> void:
	# D3: no IP prompt UI yet, hardcode 127.0.0.1 (CLI flag overrides).
	NetworkManager.join_match("127.0.0.1", NetworkManager.PORT_BASE)
	_set_status("joining 127.0.0.1...")

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
