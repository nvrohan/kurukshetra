extends Node3D
class_name LootSpawner
## LootSpawner — D4.5 server-side loot generator.
##
## On match start (server only), scatters `count` loot pickups across the
## training_island map. Drives a sibling MultiplayerSpawner so clients
## replicate each spawn deterministically. Pickup is initiated by the player
## via `Player.try_pickup` (interact key); this node provides discovery only.
##
## Rarity weights (per ARCHITECTURE.md §4.4):
##   common 50%, uncommon 30%, rare 15%, epic 5%
##
## Kind mix: 60% weapons, 25% armor, 15% medkits.
## Weapon pool: all 5 WeaponDef .tres in data/weapons/.
## Armor: rarity n+1 where rarity≥1, else common = no plate (skipped).
## Med: heal = 25 + 25*rarity (so common=25 hp, epic=100 hp).

const PICKUP_SCENE := preload("res://scenes/loot_pickup.tscn")

const WEAPONS := [
	"res://data/weapons/pistol.tres",
	"res://data/weapons/ar1.tres",
	"res://data/weapons/ar2.tres",
	"res://data/weapons/smg.tres",
	"res://data/weapons/sniper.tres",
]

@export var count: int = 24
@export var map_radius: float = 90.0   # spawn within this radius of map center
@export var min_separation: float = 6.0

@onready var spawner: MultiplayerSpawner = $MultiplayerSpawner

func _ready() -> void:
	spawner.spawn_function = _spawn_loot_node
	if multiplayer.is_server() or not multiplayer.has_multiplayer_peer():
		# Defer one frame so other Match nodes finish wiring.
		_server_populate.call_deferred()

func _server_populate() -> void:
	if not (multiplayer.is_server() or not multiplayer.has_multiplayer_peer()):
		return
	var rng := RandomNumberGenerator.new()
	rng.seed = GameState.match_seed if GameState.match_seed != 0 else Time.get_unix_time_from_system()
	var placed: Array[Vector3] = []
	var attempts := 0
	while placed.size() < count and attempts < count * 20:
		attempts += 1
		var r: float = sqrt(rng.randf()) * map_radius
		var theta: float = rng.randf() * TAU
		var pos := Vector3(cos(theta) * r, 0.5, sin(theta) * r)
		var ok := true
		for p in placed:
			if p.distance_to(pos) < min_separation:
				ok = false
				break
		if not ok:
			continue
		placed.append(pos)
		var data := _roll_loot(rng, pos)
		spawner.spawn(data)
	print("[LootSpawner] populated %d pickups (attempts=%d)" % [placed.size(), attempts])

func _roll_loot(rng: RandomNumberGenerator, pos: Vector3) -> Dictionary:
	var rarity_roll := rng.randf()
	var rarity: int = 0
	if rarity_roll < 0.05:
		rarity = 3
	elif rarity_roll < 0.20:
		rarity = 2
	elif rarity_roll < 0.50:
		rarity = 1
	var kind_roll := rng.randf()
	var kind: int
	var payload: String = ""
	if kind_roll < 0.60:
		kind = 0  # weapon
		payload = WEAPONS[rng.randi_range(0, WEAPONS.size() - 1)]
	elif kind_roll < 0.85:
		kind = 1  # armor
		# Armor tier maps roughly to rarity but capped at 3.
		var tier: int = clamp(rarity + 1, 1, 3)
		payload = str(tier)
	else:
		kind = 2  # med
		payload = str(25.0 + 25.0 * rarity)
	return {
		"kind": kind,
		"rarity": rarity,
		"payload": payload,
		"pos": [pos.x, pos.y, pos.z],
	}

func _spawn_loot_node(data: Variant) -> Node:
	var d: Dictionary = data
	var node := PICKUP_SCENE.instantiate()
	node.kind = int(d.get("kind", 0))
	node.rarity = int(d.get("rarity", 0))
	node.payload = String(d.get("payload", ""))
	var pos_arr: Array = d.get("pos", [0.0, 0.5, 0.0])
	node.position = Vector3(pos_arr[0], pos_arr[1], pos_arr[2])
	return node
