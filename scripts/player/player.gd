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

# Armor (D4.3): tier -> (max plate hp, absorb percent of incoming dmg).
# Tier 0 means "no armor", tiers 1-3 are increasingly rare loot.
const ARMOR_MAX := [0.0, 50.0, 75.0, 100.0]
const ARMOR_ABSORB := [0.0, 0.20, 0.40, 0.55]

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

# Local revive progress (input-authority side only; not replicated).
const REVIVE_RANGE := 2.0
const REVIVE_HOLD_SECONDS := 5.0
var _revive_target: Player = null
var _revive_progress: float = 0.0

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

	# Revive (D4.4): hold interact for 5 s next to a downed teammate.
	_update_revive(delta)

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
	# Armor absorbs a fraction of incoming damage (D4.3); per-tier values live
	# in ARMOR_ABSORB. Plate hp drains as it absorbs; tier resets to 0 once
	# plate is empty so unarmored hits don't keep absorbing.
	var absorbed := 0.0
	if armor > 0.0 and armor_tier > 0 and armor_tier < ARMOR_ABSORB.size():
		var pct: float = ARMOR_ABSORB[armor_tier]
		absorbed = amount * pct
		# Plate also can't absorb more than it has hp left (one-to-one).
		absorbed = min(absorbed, armor)
		armor = max(0.0, armor - absorbed)
		amount -= absorbed
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

## Server-only: equip an armor plate of the given tier (1-3). Refills the
## plate to its tier max regardless of previous tier (loot pickup overrides).
func equip_armor(tier: int) -> void:
	if not multiplayer.is_server():
		return
	if tier <= 0 or tier >= ARMOR_MAX.size():
		return
	armor_tier = tier
	armor = ARMOR_MAX[tier]
	print("[Player %d] equipped armor tier %d (%.0f hp)" % [peer_id, tier, armor])

## Server-only: heal HP up to MAX_HP. Called by med-kit pickup (D4.5).
func heal(amount: float) -> void:
	if not multiplayer.is_server() or is_dead:
		return
	hp = min(MAX_HP, hp + amount)

## Local revive progress (D4.4). Runs only on the input-authority side of a
## *standing* player. While interact is held within REVIVE_RANGE of a downed
## teammate, _revive_progress accumulates; at REVIVE_HOLD_SECONDS the revive
## RPC fires (server validates).
func _update_revive(delta: float) -> void:
	if is_downed or is_dead:
		_revive_target = null
		_revive_progress = 0.0
		return
	if not Input.is_action_pressed("interact"):
		_revive_target = null
		_revive_progress = 0.0
		return
	# Pick the closest downed teammate inside REVIVE_RANGE.
	var best: Player = null
	var best_d2: float = REVIVE_RANGE * REVIVE_RANGE
	for p in get_tree().get_nodes_in_group("players"):
		if p == self or not (p is Player):
			continue
		var pl: Player = p
		if not pl.is_downed or pl.is_dead:
			continue
		var d2: float = global_position.distance_squared_to(pl.global_position)
		if d2 < best_d2:
			best_d2 = d2
			best = pl
	if best == null:
		_revive_target = null
		_revive_progress = 0.0
		return
	# Reset progress if we switched targets.
	if best != _revive_target:
		_revive_target = best
		_revive_progress = 0.0
	_revive_progress += delta
	if _revive_progress >= REVIVE_HOLD_SECONDS:
		print("[Player %d] reviving peer %d (5s held)" % [peer_id, _revive_target.peer_id])
		_revive_target.revive.rpc_id(1, peer_id)
		_revive_target = null
		_revive_progress = 0.0

# Server-side bleedout tick (called by Match._process every second).
func server_bleedout_tick(dps: float) -> void:
	if not multiplayer.is_server() or not is_downed or is_dead:
		return
	hp = max(0.0, hp - dps)
	if hp <= 0.0:
		_die.rpc()

# endregion
