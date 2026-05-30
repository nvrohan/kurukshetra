extends CharacterBody3D
class_name Player
## Player — D4 controller.
##
## Movement states (4.1): standing, crouch, prone, jump. Each affects speed,
## camera height, and collider height (so prone players are harder to hit).
## State is set on the input-authority side and replicated via
## MultiplayerSynchronizer (see player.tscn replication config).
##
## Authority model (per ARCHITECTURE.md §3.2 + ADR 0006):
## - Position/rotation: input-authority owns (D3 model — D4+ may flip server).
## - HP / armor / is_dead / is_downed: server-authoritative.
## - Movement state (stance): input-authority owns (visual only).

const WALK_SPEED := 4.0     # m/s, ARCHITECTURE.md §4.2
const SPRINT_SPEED := 7.0
const CROUCH_SPEED := 2.0
const PRONE_SPEED := 1.0
const JUMP_VELOCITY := 6.0
const GRAVITY := 20.0
const MAX_HP := 100.0

# Stance constants (replicated as int)
const STANCE_STAND := 0
const STANCE_CROUCH := 1
const STANCE_PRONE := 2

# Collider/camera heights per stance.
const HEIGHT_STAND := 1.8
const HEIGHT_CROUCH := 1.2
const HEIGHT_PRONE := 0.6
const CAM_HEIGHT_STAND := 1.5
const CAM_HEIGHT_CROUCH := 1.0
const CAM_HEIGHT_PRONE := 0.4

@export var peer_id: int = 1   # set on spawn; drives input authority
@export var hp: float = MAX_HP
@export var armor: float = 0.0
@export var armor_tier: int = 0   # 0 none, 1 light, 2 medium, 3 heavy (D4.3)
@export var is_dead: bool = false
@export var is_downed: bool = false
@export var stance: int = STANCE_STAND

@onready var camera: Camera3D = $SpringArm3D/Camera3D
@onready var spring_arm: SpringArm3D = $SpringArm3D
@onready var weapon: Node3D = $WeaponMount/WeaponStub
@onready var mesh_inst: MeshInstance3D = $Mesh
@onready var collision: CollisionShape3D = $Collision

func _ready() -> void:
	# Authority is set by Match._spawn_player_node BEFORE _ready (required
	# for MultiplayerSynchronizer). Here we just verify and wire camera.
	camera.current = (peer_id == multiplayer.get_unique_id())
	_apply_stance_visuals(stance)
	print("[Player %d] ready, authority=%d, camera_local=%s" % [peer_id, get_multiplayer_authority(), camera.current])

func _physics_process(delta: float) -> void:
	# Only the input-authority peer drives movement (D3 model: each client
	# moves their own player; server just relays. D4+ may flip to
	# server-authoritative.)
	if not is_multiplayer_authority():
		# Non-authority peers still need to apply visuals from synced stance.
		_apply_stance_visuals(stance)
		return
	if is_dead:
		velocity = Vector3.ZERO
		move_and_slide()
		return

	# Stance toggles (input-authority side). Cannot change while airborne
	# except to come down. Prone -> stand requires going via crouch (Q to
	# toggle prone, C to toggle crouch — common BR convention).
	if not is_downed:
		if Input.is_action_just_pressed("crouch"):
			_set_stance(STANCE_STAND if stance == STANCE_CROUCH else STANCE_CROUCH)
		if Input.is_action_just_pressed("prone"):
			_set_stance(STANCE_STAND if stance == STANCE_PRONE else STANCE_PRONE)

	# Jump: only from grounded standing/crouch (not prone, not downed).
	if Input.is_action_just_pressed("jump") and is_on_floor() and not is_downed:
		if stance != STANCE_PRONE:
			# Auto-stand from crouch on jump.
			if stance == STANCE_CROUCH:
				_set_stance(STANCE_STAND)
			velocity.y = JUMP_VELOCITY

	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	var speed := _current_speed()

	if is_downed:
		# Crawl at prone speed regardless of input — slow.
		speed = PRONE_SPEED * 0.5

	if direction:
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed
	else:
		velocity.x = move_toward(velocity.x, 0, speed)
		velocity.z = move_toward(velocity.z, 0, speed)

	# Gravity
	if not is_on_floor():
		velocity.y -= GRAVITY * delta

	move_and_slide()

	# Fire on input-authority side; weapon handles its own RPC to server.
	# Cannot fire while downed.
	if not is_downed and Input.is_action_just_pressed("fire") and weapon and weapon.has_method("try_fire"):
		weapon.try_fire(camera.global_transform.origin, -camera.global_transform.basis.z)

func _current_speed() -> float:
	match stance:
		STANCE_PRONE:
			return PRONE_SPEED
		STANCE_CROUCH:
			return CROUCH_SPEED
		_:
			return SPRINT_SPEED if Input.is_action_pressed("sprint") else WALK_SPEED

func _set_stance(new_stance: int) -> void:
	if stance == new_stance:
		return
	stance = new_stance
	_apply_stance_visuals(new_stance)

func _apply_stance_visuals(s: int) -> void:
	# Adjust capsule height + camera mount height per stance. Mesh + collider
	# are children of the body; we tweak their `transform.origin.y` so the
	# capsule sits with its base on the floor.
	var body_height: float
	match s:
		STANCE_PRONE:
			body_height = HEIGHT_PRONE
		STANCE_CROUCH:
			body_height = HEIGHT_CROUCH
		_:
			body_height = HEIGHT_STAND
	if mesh_inst and mesh_inst.mesh is CapsuleMesh:
		(mesh_inst.mesh as CapsuleMesh).height = body_height
		mesh_inst.position.y = body_height * 0.5
	if collision and collision.shape is CapsuleShape3D:
		(collision.shape as CapsuleShape3D).height = body_height
		collision.position.y = body_height * 0.5
	if spring_arm:
		var cam_y: float
		match s:
			STANCE_PRONE: cam_y = CAM_HEIGHT_PRONE
			STANCE_CROUCH: cam_y = CAM_HEIGHT_CROUCH
			_: cam_y = CAM_HEIGHT_STAND
		spring_arm.position.y = cam_y


# region damage (server-authoritative) ------------------------------------

@rpc("any_peer", "call_local", "reliable")
func apply_damage(amount: float, source_peer: int) -> void:
	# Only server applies damage. ARCHITECTURE.md §3.5.
	if not multiplayer.is_server():
		return
	if is_dead:
		return
	# Armor absorbs a fraction of incoming damage (D4.3): light=20%, med=40%, heavy=55%.
	var absorbed := 0.0
	if armor > 0.0:
		var pct := 0.0
		match armor_tier:
			1: pct = 0.20
			2: pct = 0.40
			3: pct = 0.55
		absorbed = amount * pct
		armor = max(0.0, armor - absorbed)
		amount -= absorbed
		# Once armor is gone, tier resets so future hits don't keep absorbing.
		if armor <= 0.0:
			armor_tier = 0
	hp = max(0.0, hp - amount)
	print("[Player %d] hit by peer %d for %.1f (armor absorbed %.1f) -> hp=%.1f armor=%.1f" % [peer_id, source_peer, amount, absorbed, hp, armor])
	if hp <= 0.0:
		# D4.4: knockdown rather than outright kill (handled by Match later).
		# For now, set is_downed; if already downed, finalize death.
		if is_downed:
			_die.rpc()
		else:
			_knockdown.rpc()

@rpc("authority", "call_local", "reliable")
func _knockdown() -> void:
	is_downed = true
	hp = 30.0  # bleedout pool — drops over 30s via _process_bleedout on server
	stance = STANCE_PRONE
	_apply_stance_visuals(stance)
	print("[Player %d] downed" % peer_id)

@rpc("authority", "call_local", "reliable")
func _die() -> void:
	is_dead = true
	is_downed = false
	hp = 0.0
	print("[Player %d] dead" % peer_id)

@rpc("any_peer", "call_local", "reliable")
func revive(by_peer: int) -> void:
	# Server-authoritative revive. Called by another player's interact key.
	if not multiplayer.is_server():
		return
	if not is_downed or is_dead:
		return
	is_downed = false
	hp = 30.0  # revive comes back at low health
	stance = STANCE_STAND
	print("[Player %d] revived by peer %d" % [peer_id, by_peer])

# Server-side bleedout tick (called by Match._process every second).
func server_bleedout_tick(dps: float) -> void:
	if not multiplayer.is_server() or not is_downed or is_dead:
		return
	hp = max(0.0, hp - dps)
	if hp <= 0.0:
		_die.rpc()

# endregion
