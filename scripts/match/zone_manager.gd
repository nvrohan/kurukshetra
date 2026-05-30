extends Node3D
class_name ZoneManager
## ZoneManager — D3 implementation, phases 0-2 only per ADR 0006.
##
## Server authoritative. Phase schedule (per ARCHITECTURE.md §4.5, truncated):
##   Phase 0: full map (radius 100 m for 200×200 playground) — wait 90 s
##   Phase 1: shrink to 50 m over 60 s, then wait 90 s, 1 hp/s outside
##   Phase 2: shrink to 25 m over 60 s, 2 hp/s outside (D3 stops here)

signal phase_changed(phase: int, target_radius: float, shrink_seconds: float)

const PHASE_DEFS := [
	{"radius": 100.0, "wait": 90.0, "shrink": 0.0, "dps": 0.0},   # phase 0
	{"radius": 50.0,  "wait": 90.0, "shrink": 60.0, "dps": 1.0},  # phase 1
	{"radius": 25.0,  "wait": 0.0,  "shrink": 60.0, "dps": 2.0},  # phase 2
]

@export var current_phase: int = 0
@export var current_radius: float = 100.0
@export var target_radius: float = 100.0
@export var center: Vector3 = Vector3.ZERO

var _phase_elapsed: float = 0.0
var _shrinking: bool = false
var _shrink_from: float = 100.0
var _shrink_t: float = 0.0
var _damage_accumulator: float = 0.0  # ticks down per second

func _ready() -> void:
	if multiplayer.is_server() or not multiplayer.has_multiplayer_peer():
		print("[ZoneManager] server starting, phase 0")
	current_radius = PHASE_DEFS[0]["radius"]
	target_radius = current_radius

func _physics_process(delta: float) -> void:
	# Server-only simulation; clients receive `current_radius` via sync.
	if multiplayer.has_multiplayer_peer() and not multiplayer.is_server():
		return

	if current_phase >= PHASE_DEFS.size():
		return  # past D3 horizon

	var phase: Dictionary = PHASE_DEFS[current_phase]
	_phase_elapsed += delta

	# Shrink animation
	if _shrinking:
		_shrink_t += delta
		var shrink_dur: float = phase["shrink"]
		var t: float = min(1.0, _shrink_t / shrink_dur) if shrink_dur > 0 else 1.0
		current_radius = lerp(_shrink_from, float(phase["radius"]), t)
		if t >= 1.0:
			_shrinking = false
			current_radius = phase["radius"]
			target_radius = current_radius
	else:
		# Waiting: should we start shrinking, or advance phase?
		var wait: float = phase["wait"]
		var shrink: float = phase["shrink"]
		if shrink > 0 and _phase_elapsed >= wait:
			_shrinking = true
			_shrink_t = 0.0
			_shrink_from = current_radius
			target_radius = phase["radius"]
		elif shrink == 0 and _phase_elapsed >= wait:
			_advance_phase()

	# Phase advance after shrink completes
	if not _shrinking and current_radius == phase["radius"] and _phase_elapsed >= phase["wait"] + phase["shrink"]:
		_advance_phase()

	# Damage outside zone (every full second)
	_damage_accumulator += delta
	if _damage_accumulator >= 1.0:
		_damage_accumulator -= 1.0
		var dps: float = phase["dps"]
		if dps > 0:
			_apply_zone_damage(dps)

func _advance_phase() -> void:
	current_phase += 1
	_phase_elapsed = 0.0
	_shrinking = false
	if current_phase < PHASE_DEFS.size():
		var phase: Dictionary = PHASE_DEFS[current_phase]
		print("[ZoneManager] phase %d -> radius %.1f (shrink %.1fs)" % [current_phase, phase["radius"], phase["shrink"]])
		phase_changed.emit(current_phase, phase["radius"], phase["shrink"])
	else:
		print("[ZoneManager] D3 horizon reached (phase 2 done)")

func _apply_zone_damage(dps: float) -> void:
	# Find all Player nodes in scene; damage those outside circle.
	var players := get_tree().get_nodes_in_group("players")
	for player in players:
		if not is_instance_valid(player):
			continue
		var pos: Vector3 = player.global_position
		var d2 := Vector2(pos.x - center.x, pos.z - center.z).length()
		if d2 > current_radius and player.has_method("apply_damage"):
			player.apply_damage(dps, 0)  # 0 = "the zone"
