extends Resource
class_name WeaponDef
## WeaponDef — D4 weapon stat sheet.
##
## CC0/CC-BY first; this is pure data so no licensing implications. Five
## weapons cover the BR archetype matrix per ARCHITECTURE.md §4.3:
##   pistol — sidearm, low damage, infinite-ish ammo, fast swap
##   ar1    — assault rifle, balanced (the "default" gun)
##   ar2    — heavy AR, more damage / lower RPM / more recoil
##   smg    — close range, high RPM, falls off fast past 30 m
##   sniper — bolt-action, one-shot to chest with no armor, 200 m range

@export var id: StringName = &"unknown"
@export var display_name: String = "Unknown Weapon"
@export var damage: float = 25.0
@export var rpm: float = 600.0           # rounds per minute (fire rate)
@export var max_range: float = 100.0     # metres
@export var falloff_start: float = 50.0  # metres; damage tapers past this
@export var falloff_min_pct: float = 0.5 # damage at max_range as fraction of base
@export var headshot_mult: float = 1.5   # crit multiplier on headshot hit
@export var mag_size: int = 30
@export var reload_seconds: float = 2.0

## Helper: damage at a given hit distance (linear falloff start..max).
func damage_at(distance: float) -> float:
	if distance <= falloff_start:
		return damage
	if distance >= max_range:
		return damage * falloff_min_pct
	var t: float = (distance - falloff_start) / max(0.001, max_range - falloff_start)
	return damage * lerp(1.0, falloff_min_pct, t)
