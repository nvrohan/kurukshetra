extends Node3D
## WeaponStub — D3 hitscan placeholder.
##
## Per ADR 0006: 1 weapon, 600 RPM, 25 dmg, hitscan ray. Server-authoritative
## damage; client merely sends "fire from here in this direction" RPC.
## ARCHITECTURE.md §3.5 (anti-cheat: server validates rate + range).

const RATE_RPM := 600.0
const FIRE_INTERVAL := 60.0 / RATE_RPM  ## 0.1 s between shots
const DAMAGE := 25.0
const MAX_RANGE := 100.0  ## metres; sniper later, AR is shorter

var _last_fire_time_ms_per_peer: Dictionary = {}  # peer_id -> int

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
	var now_ms := Time.get_ticks_msec()
	var last_ms: int = _last_fire_time_ms_per_peer.get(sender_id, 0)
	if (now_ms - last_ms) / 1000.0 < FIRE_INTERVAL * 0.95:  # 5% slack
		return
	_last_fire_time_ms_per_peer[sender_id] = now_ms

	# Raycast in physics space (server-authoritative world).
	var space_state := get_world_3d().direct_space_state
	var query := PhysicsRayQueryParameters3D.create(origin, origin + direction.normalized() * MAX_RANGE)
	query.collision_mask = 0b00010  # players layer (2)
	var result := space_state.intersect_ray(query)
	if result.is_empty():
		return
	var hit_node: Node = result.collider
	if hit_node and hit_node.has_method("apply_damage"):
		# Don't damage self.
		if hit_node.has_method("get_multiplayer_authority") and hit_node.get_multiplayer_authority() == sender_id:
			return
		hit_node.apply_damage(DAMAGE, sender_id)
