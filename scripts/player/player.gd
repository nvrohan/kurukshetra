extends CharacterBody3D
class_name Player
## Player — D3 minimal controller per ADR 0006.
##
## Walk + sprint only (crouch/prone/jump deferred to D4+). Authority
## per ARCHITECTURE.md §3.2: server owns position, client sends input
## intent. D3 uses simple state replication via MultiplayerSynchronizer
## (no client-side prediction yet — that's a D4+ refinement).

const WALK_SPEED := 4.0     # m/s, ARCHITECTURE.md §4.2
const SPRINT_SPEED := 7.0
const GRAVITY := 20.0
const MAX_HP := 100.0

@export var peer_id: int = 1   # set on spawn; drives input authority
@export var hp: float = MAX_HP
@export var is_dead: bool = false

## Synchronized properties (server -> all clients via MultiplayerSynchronizer
## node in the .tscn). Position + rotation + hp + is_dead.

@onready var camera: Camera3D = $SpringArm3D/Camera3D
@onready var spring_arm: SpringArm3D = $SpringArm3D
@onready var weapon: Node3D = $WeaponMount/WeaponStub

func _ready() -> void:
	# Authority is set by Match._spawn_player_node BEFORE _ready (required
	# for MultiplayerSynchronizer). Here we just verify and wire camera.
	# Only the local player's camera should be active.
	camera.current = (peer_id == multiplayer.get_unique_id())
	print("[Player %d] ready, authority=%d, camera_local=%s" % [peer_id, get_multiplayer_authority(), camera.current])

func _physics_process(delta: float) -> void:
	# Only the input-authority peer drives movement (D3 model: each client
	# moves their own player; server just relays. D4 will flip to
	# server-authoritative.)
	if not is_multiplayer_authority():
		return
	if is_dead:
		velocity = Vector3.ZERO
		move_and_slide()
		return

	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	var speed := SPRINT_SPEED if Input.is_action_pressed("sprint") else WALK_SPEED

	if direction:
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed
	else:
		velocity.x = move_toward(velocity.x, 0, speed)
		velocity.z = move_toward(velocity.z, 0, speed)

	# Gravity
	if not is_on_floor():
		velocity.y -= GRAVITY * delta
	else:
		velocity.y = 0.0

	move_and_slide()

	# Fire on input-authority side; weapon handles its own RPC to server.
	if Input.is_action_just_pressed("fire") and weapon and weapon.has_method("try_fire"):
		weapon.try_fire(camera.global_transform.origin, -camera.global_transform.basis.z)


# region damage (server-authoritative) ------------------------------------

@rpc("any_peer", "call_local", "reliable")
func apply_damage(amount: float, source_peer: int) -> void:
	# Only server applies damage. ARCHITECTURE.md §3.5.
	if not multiplayer.is_server():
		return
	if is_dead:
		return
	hp = max(0.0, hp - amount)
	print("[Player %d] hit by peer %d for %.1f -> %.1f hp" % [peer_id, source_peer, amount, hp])
	if hp <= 0.0:
		_die.rpc()

@rpc("authority", "call_local", "reliable")
func _die() -> void:
	is_dead = true
	hp = 0.0
	print("[Player %d] dead" % peer_id)

# endregion
