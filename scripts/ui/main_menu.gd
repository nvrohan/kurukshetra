extends Control
## MainMenu — boot screen for Kurukshetra v0.1 scaffold.
##
## Wires three placeholder buttons to no-op handlers. Real host/join flow
## arrives with the lobby UI in deliverable 3.

func _ready() -> void:
	GameState.set_phase(GameState.MatchPhase.MAIN_MENU)

func _on_host_pressed() -> void:
	print("[MainMenu] Host pressed — NetworkManager.host_match() is a stub (deliverable 3)")
	NetworkManager.host_match()

func _on_join_pressed() -> void:
	print("[MainMenu] Join pressed — NetworkManager.join_match() is a stub (deliverable 3)")
	NetworkManager.join_match("127.0.0.1", NetworkManager.PORT_BASE)

func _on_quit_pressed() -> void:
	get_tree().quit()
