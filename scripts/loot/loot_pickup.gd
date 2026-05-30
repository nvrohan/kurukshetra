extends Area3D
class_name LootPickup
## LootPickup — D4.5 ground-spawned loot.
##
## A LootPickup is a small Area3D the player walks into to highlight, then
## presses interact (E) to pick up. Server-authoritative: the local player's
## interact press fires an RPC; server validates range + state and applies
## the effect (equip weapon / armor / heal). The pickup node is freed on
## consumption so it disappears for everyone.
##
## Kinds (D4.5):
##   weapon — `payload` is a WeaponDef .tres path; equips on player.weapon.
##   armor  — `payload` is the plate tier int (1/2/3); calls Player.equip_armor.
##   med    — `payload` is heal amount (float); calls Player.heal.
##
## Rarities (4 tiers per ARCHITECTURE.md §4.4):
##   0 common (white), 1 uncommon (green), 2 rare (blue), 3 epic (purple)
##
## Replication: this node is spawned via the match's loot MultiplayerSpawner
## (server only spawns; clients replicate). Its `consumed` flag is synced so
## the despawn is deterministic.

const KIND_WEAPON := 0
const KIND_ARMOR := 1
const KIND_MED := 2

const RARITY_COLORS := [
	Color(0.85, 0.85, 0.85, 1.0),   # common — white
	Color(0.30, 0.85, 0.30, 1.0),   # uncommon — green
	Color(0.30, 0.55, 0.95, 1.0),   # rare — blue
	Color(0.75, 0.35, 0.95, 1.0),   # epic — purple
]

@export var kind: int = KIND_WEAPON
@export var rarity: int = 0
@export var payload: String = ""   # weapon def path / armor tier (as str) / heal amount (as str)
@export var consumed: bool = false

@onready var mesh: MeshInstance3D = $Mesh

func _ready() -> void:
	add_to_group("loot")
	_apply_visuals()
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _apply_visuals() -> void:
	if mesh and mesh.get_surface_override_material(0) is StandardMaterial3D:
		var mat: StandardMaterial3D = mesh.get_surface_override_material(0)
		mat.albedo_color = RARITY_COLORS[clamp(rarity, 0, RARITY_COLORS.size() - 1)]
		mat.emission_enabled = true
		mat.emission = mat.albedo_color
		mat.emission_energy_multiplier = 0.4

func _process(delta: float) -> void:
	# Gentle bob + spin so loot is easy to spot. Cosmetic only.
	if mesh:
		mesh.rotation.y += delta * 1.2
		mesh.position.y = 0.5 + sin(Time.get_ticks_msec() * 0.003) * 0.1

# Interact: each candidate player polls overlapping loot in their _physics_process
# (cheap because Area3D maintains its own list). Loot itself is passive; the
# pickup RPC is sent from Player. We only expose a server_consume() hook here.

func server_consume(by_peer: int) -> bool:
	# Returns true if this consume is accepted (idempotent).
	if not multiplayer.is_server() and multiplayer.has_multiplayer_peer():
		return false
	if consumed:
		return false
	consumed = true
	# Hide immediately on server; replicated to clients via sync; spawner
	# despawn frees the node at end-of-frame.
	visible = false
	monitoring = false
	monitorable = false
	# Defer free so the sync packet that flips `consumed` actually goes out.
	queue_free.call_deferred()
	print("[Loot] consumed by peer %d (kind=%d rarity=%d payload=%s)" % [by_peer, kind, rarity, payload])
	return true

func _on_body_entered(_body: Node) -> void:
	pass

func _on_body_exited(_body: Node) -> void:
	pass
