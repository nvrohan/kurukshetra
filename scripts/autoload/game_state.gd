extends Node
## GameState — global match state for Kurukshetra.
##
## v0.1 scaffold: enum + signals + minimal accessors.
## Real match-phase logic (zone shrink, squad assignment, knockdown
## tracking) lands in deliverable 3.

signal phase_changed(new_phase: MatchPhase)
signal player_joined(peer_id: int, display_name: String)
signal player_left(peer_id: int)
signal match_ended(winner_squad: int)

enum MatchPhase {
	BOOT,         ## App just launched
	MAIN_MENU,
	LOBBY,        ## Room code entered, waiting for players
	IN_MATCH,     ## Active battle
	POST_MATCH,   ## Results screen
}

var current_phase: MatchPhase = MatchPhase.BOOT

## Map of peer_id (int) -> { name: String, squad: int, knocked: bool }
var players: Dictionary = {}

## Server-only seed for deterministic loot spawns. ARCHITECTURE.md §3.2.
var match_seed: int = 0

func _ready() -> void:
	print("[GameState] ready")

func set_phase(phase: MatchPhase) -> void:
	if phase == current_phase:
		return
	current_phase = phase
	phase_changed.emit(phase)

func register_player(peer_id: int, display_name: String, squad: int) -> void:
	players[peer_id] = {
		"name": display_name,
		"squad": squad,
		"knocked": false,
	}
	player_joined.emit(peer_id, display_name)

func unregister_player(peer_id: int) -> void:
	if peer_id in players:
		players.erase(peer_id)
		player_left.emit(peer_id)

func reset() -> void:
	players.clear()
	match_seed = 0
	set_phase(MatchPhase.MAIN_MENU)
