extends Node3D
class_name WeaponRuntime
## WeaponRuntime — D4.2 hitscan weapon driven by a WeaponDef resource.
##
## Replaces the D3 hard-coded stub. The active weapon's stats come from a
## WeaponDef (.tres in data/weapons/). Server-authoritative damage:
## clients send a "fire from origin in this direction" RPC; the server
## raycasts in its world and resolves damage with rate-limit + range.
##
## ARCHITECTURE.md §3.5 anti-cheat: server validates rate (≤ rpm * 1.05)
## and range (max_range from WeaponDef). Clients cannot fabricate stats.

const DEFAULT_DEF := preload("res://data/weapons/ar1.tres")

@export var weapon_def: WeaponDef = DEFAULT_DEF

var _last_fire_time_ms_per_peer: Dictionary = {}  # peer_id -> int (server-side)

func _ready() -> void:
	if weapon_def == null:
		weapon_def = DEFAULT_DEF

## Called locally by Player on input. Sends RPC to server.
func try_fire(origin: Vector3, direction: Vector3) -> void:
	if not multiplayer.has_multiplayer_peer():
		return
	# Send to server (peer 1) for authoritative resolution.
	_server_resolve_fire.rpc_id(1, origin, direction)

@rpc("any_peer", "call_local", "reliable")
func _server_resolve_fire(origin: Vector3, direction: Vector3) -> void:
	if not multiplayer.is_server():
		return
	var sender_id := multiplayer.get_remote_sender_id()
	if sender_id == 0:
		sender_id = multiplayer.get_unique_id()  # local-server fire
	# Rate-limit per peer.
	var fire_interval: float = 60.0 / max(1.0, weapon_def.rpm)
	var now_ms := Time.get_ticks_msec()
	var last_ms: int = _last_fire_time_ms_per_peer.get(sender_id, 0)
	if (now_ms - last_ms) / 1000.0 < fire_interval * 0.95:  # 5% slack
		return
	_last_fire_time_ms_per_peer[sender_id] = now_ms

	# Raycast in physics space (server-authoritative world).
	var space_state := get_world_3d().direct_space_state
	var query := PhysicsRayQueryParameters3D.create(origin, origin + direction.normalized() * weapon_def.max_range)
	query.collision_mask = 0b00010  # players layer (2)
	var result := space_state.intersect_ray(query)
	if result.is_empty():
		return
	var hit_node: Node = result.collider
	if hit_node and hit_node.has_method("apply_damage"):
		# Don't damage self.
		if hit_node.has_method("get_multiplayer_authority") and hit_node.get_multiplayer_authority() == sender_id:
			return
		var hit_pos: Vector3 = result.position
		var distance: float = origin.distance_to(hit_pos)
		var dmg: float = weapon_def.damage_at(distance)
		# Headshot detection: hit point above 80% of capsule height counts
		# as a head hit. Capsule heights are stance-dependent; approximate
		# using the player node's global y and assume head is top 20%.
		if hit_node is Node3D:
			var p: Node3D = hit_node
			var head_y := p.global_position.y + 1.5  # rough; D4 cosmetic
			if hit_pos.y >= head_y - 0.2:
				dmg *= weapon_def.headshot_mult
		hit_node.apply_damage(dmg, sender_id)

## Switch the equipped weapon at runtime (D4.5 loot pickup will call this).
func equip(def: WeaponDef) -> void:
	if def != null:
		weapon_def = def
