extends Node
## AudioManager — central audio routing for Kurukshetra.
##
## v0.1 scaffold: bus setup hooks only. Real SFX/music wiring lands when
## we add Kenney + Freesound assets in deliverable 3.

const BUS_MASTER := "Master"
const BUS_SFX := "SFX"
const BUS_MUSIC := "Music"
const BUS_UI := "UI"

func _ready() -> void:
	print("[AudioManager] ready (no audio assets loaded yet — see ATTRIBUTIONS.md)")

func play_sfx(_stream: AudioStream, _volume_db: float = 0.0) -> void:
	pass  # deliverable 3

func play_music(_stream: AudioStream, _fade_seconds: float = 1.0) -> void:
	pass  # deliverable 3

func stop_music(_fade_seconds: float = 1.0) -> void:
	pass  # deliverable 3
