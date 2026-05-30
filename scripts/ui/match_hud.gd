extends Control
class_name MatchHud
## MatchHud — D4.6 + D4.5 in-match overlay.
##
## Shows three things:
##   - Kill feed (top-right): last 5 kills, each line fades out after 5 s.
##   - Player stats (bottom-left): HP / armor / current zone phase.
##   - Pickup hint (bottom-center): "Press E to pick up <name>" when standing
##     on a LootPickup.
##
## All updates are local-render only. Kill events arrive as RPC from the
## server (see Match.broadcast_kill). Stats are pulled each frame from the
## local player node. Touch-friendly: mouse_filter=ignore so taps fall through.

const KILL_FEED_MAX := 5
const KILL_FADE_SECONDS := 5.0

@onready var kill_feed: VBoxContainer = $KillFeed
@onready var stats_label: Label = $Stats
@onready var pickup_hint: Label = $PickupHint

# Each entry: { "label": Label, "born_ms": int }
var _kill_entries: Array = []

func _ready() -> void:
	add_to_group("match_hud")
	# Mouse filter on container too.
	kill_feed.mouse_filter = Control.MOUSE_FILTER_IGNORE

func _process(_delta: float) -> void:
	_tick_kill_feed()
	_update_stats()

func _tick_kill_feed() -> void:
	var now := Time.get_ticks_msec()
	var dead: Array = []
	for entry in _kill_entries:
		var age: float = (now - entry["born_ms"]) / 1000.0
		if age >= KILL_FADE_SECONDS:
			dead.append(entry)
			continue
		var l: Label = entry["label"]
		if not is_instance_valid(l):
			dead.append(entry)
			continue
		# Fade out over the last second of life.
		var fade_t: float = clamp((KILL_FADE_SECONDS - age), 0.0, 1.0)
		l.modulate.a = fade_t
	for d in dead:
		var l: Label = d["label"]
		if is_instance_valid(l):
			l.queue_free()
		_kill_entries.erase(d)

func push_kill(killer: String, victim: String, weapon: String) -> void:
	var label := Label.new()
	label.text = "%s  »  %s   [%s]" % [killer, victim, weapon]
	label.add_theme_font_size_override("font_size", 16)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	kill_feed.add_child(label)
	_kill_entries.append({"label": label, "born_ms": Time.get_ticks_msec()})
	# Trim oldest if over cap.
	while _kill_entries.size() > KILL_FEED_MAX:
		var oldest: Dictionary = _kill_entries[0]
		var l: Label = oldest["label"]
		if is_instance_valid(l):
			l.queue_free()
		_kill_entries.pop_front()
	print("[MatchHud] kill: %s -> %s [%s]" % [killer, victim, weapon])

func set_pickup_hint(text: String) -> void:
	pickup_hint.text = text

func _update_stats() -> void:
	var local_id := multiplayer.get_unique_id() if multiplayer.has_multiplayer_peer() else 1
	var local_player: Node = null
	for p in get_tree().get_nodes_in_group("players"):
		if p.has_method("get_multiplayer_authority") and p.get_multiplayer_authority() == local_id:
			local_player = p
			break
	if local_player == null:
		stats_label.text = "HP --   ARMOR --"
		return
	var hp: float = float(local_player.get("hp")) if local_player.get("hp") != null else 0.0
	var armor: float = float(local_player.get("armor")) if local_player.get("armor") != null else 0.0
	var armor_tier: int = int(local_player.get("armor_tier")) if local_player.get("armor_tier") != null else 0
	var downed: bool = bool(local_player.get("is_downed")) if local_player.get("is_downed") != null else false
	var dead: bool = bool(local_player.get("is_dead")) if local_player.get("is_dead") != null else false
	var phase: int = -1
	var radius: float = 0.0
	for n in get_tree().get_nodes_in_group("zone_manager"):
		phase = int(n.get("current_phase"))
		radius = float(n.get("current_radius"))
		break
	var status := ""
	if dead:
		status = "  [DEAD]"
	elif downed:
		status = "  [DOWNED]"
	stats_label.text = "HP %.0f   ARMOR %.0f (T%d)   ZONE %d r=%.0f%s" % [hp, armor, armor_tier, phase, radius, status]
