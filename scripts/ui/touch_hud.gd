extends Control
class_name TouchHud
## TouchHud — D5 on-screen controls for Android.
##
## Two virtual joysticks + 6 action buttons:
##   - Left stick: movement (drives move_forward/move_backward/move_left/move_right).
##   - Right stick: look — emitted as relative mouse motion so player.gd's
##     existing camera code (which reads InputEventMouseMotion) keeps working.
##   - Buttons (right side): FIRE, JUMP, RELOAD, INTERACT.
##   - Buttons (left side, above stick): CROUCH, PRONE.
##
## Visibility: only shown on mobile builds. On desktop, the node hides itself
## in _ready() so it never steals input on dev/test runs.
##
## Implementation notes:
##   * Joysticks are pure GDScript (ColorRect base + thumb knob). We track
##     the originating touch index per stick so multi-touch (move + look at
##     once) works.
##   * Action buttons use TouchScreenButton's action_press/action_release —
##     the stock Godot behaviour that drives existing input maps unchanged.
##   * Mouse_filter = STOP only on the active widgets; the rest of the
##     overlay is MOUSE_FILTER_IGNORE so taps on the world (e.g. UI debug)
##     fall through.

const STICK_RADIUS := 90.0       # px — stick base
const STICK_DEAD_ZONE := 0.18    # below this, output 0
const LOOK_SENSITIVITY := 4.0    # multiplier for synthetic mouse-motion events

@onready var move_base: Control = $MoveStick
@onready var move_knob: ColorRect = $MoveStick/Knob
@onready var look_base: Control = $LookStick
@onready var look_knob: ColorRect = $LookStick/Knob

# Button -> action map; buttons send button_down / button_up signals which we
# translate to Input.action_press / Input.action_release. Same actions as
# the keyboard input map (project.godot [input]) so player.gd doesn't care
# whether the input came from K/M or touch.
const BUTTON_ACTIONS := {
	"ActionButtons/FireBtn": "fire",
	"ActionButtons/JumpBtn": "jump",
	"ActionButtons/ReloadBtn": "reload",
	"ActionButtons/InteractBtn": "interact",
	"StanceButtons/CrouchBtn": "crouch",
	"StanceButtons/ProneBtn": "prone",
}

# Per-stick state: -1 means "no active touch".
var _move_touch_id: int = -1
var _move_center: Vector2 = Vector2.ZERO
var _look_touch_id: int = -1
var _look_last_pos: Vector2 = Vector2.ZERO

# Active virtual axes for movement; zeroed out when stick released.
var _vfwd: float = 0.0
var _vback: float = 0.0
var _vleft: float = 0.0
var _vright: float = 0.0

func _ready() -> void:
	# Decide whether this is a touch device. Be GENEROUS: a false negative
	# here freezes the player (no controls + set_process_input(false)), which
	# is exactly the bug we are fixing. Show controls if ANY signal says touch.
	var os_name := OS.get_name()
	var is_mobile_os := os_name == "Android" or os_name == "iOS"
	var has_mobile_feat := OS.has_feature("mobile")
	var has_touch_feat := OS.has_feature("touch")
	var touchscreen := DisplayServer.is_touchscreen_available()
	# Allow a manual override for desktop testing: run with --touch-hud.
	var forced := "--touch-hud" in OS.get_cmdline_user_args()
	var show_touch := is_mobile_os or has_mobile_feat or has_touch_feat or touchscreen or forced

	print("[TouchHud] os=%s mobile_feat=%s touch_feat=%s touchscreen=%s forced=%s -> show=%s" % [
		os_name, has_mobile_feat, has_touch_feat, touchscreen, forced, show_touch])

	if not show_touch:
		# Desktop without touch: hide widgets but DO NOT kill _input — harmless,
		# and keeps behaviour debuggable. Just stay invisible.
		visible = false
		return

	visible = true
	# Make sure we actually receive screen-touch/drag events. _input() fires
	# regardless of mouse_filter, but be explicit and keep the root pass-through
	# so taps on empty areas reach the 3D world.
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_process_input(true)
	# Ensure the HUD fills the viewport even if instanced oddly.
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_reset_knob(move_knob, move_base)
	_reset_knob(look_knob, look_base)
	_wire_buttons()

func _wire_buttons() -> void:
	for path in BUTTON_ACTIONS.keys():
		var btn := get_node_or_null(path) as Button
		if btn == null:
			push_warning("[TouchHud] missing button node at %s" % path)
			continue
		var action: String = BUTTON_ACTIONS[path]
		btn.button_down.connect(func() -> void: Input.action_press(action))
		btn.button_up.connect(func() -> void: Input.action_release(action))

func _reset_knob(knob: ColorRect, base: Control) -> void:
	knob.position = base.size * 0.5 - knob.size * 0.5

func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		_handle_touch(event)
	elif event is InputEventScreenDrag:
		_handle_drag(event)

func _handle_touch(ev: InputEventScreenTouch) -> void:
	if ev.pressed:
		# Decide which stick (if any) accepts this touch.
		var local_in_move := move_base.get_global_rect().has_point(ev.position)
		var local_in_look := look_base.get_global_rect().has_point(ev.position)
		if local_in_move and _move_touch_id == -1:
			_move_touch_id = ev.index
			_move_center = move_base.global_position + move_base.size * 0.5
			_apply_move_vec(ev.position - _move_center)
		elif local_in_look and _look_touch_id == -1:
			_look_touch_id = ev.index
			_look_last_pos = ev.position
	else:
		if ev.index == _move_touch_id:
			_move_touch_id = -1
			_apply_move_vec(Vector2.ZERO)
			_reset_knob(move_knob, move_base)
		elif ev.index == _look_touch_id:
			_look_touch_id = -1
			_reset_knob(look_knob, look_base)

func _handle_drag(ev: InputEventScreenDrag) -> void:
	if ev.index == _move_touch_id:
		_apply_move_vec(ev.position - _move_center)
	elif ev.index == _look_touch_id:
		var rel: Vector2 = ev.position - _look_last_pos
		_look_last_pos = ev.position
		_emit_look(rel)
		# Visualise the right-stick deflection clamped to base.
		var local: Vector2 = ev.position - look_base.global_position
		var clamped: Vector2 = (local - look_base.size * 0.5).limit_length(STICK_RADIUS)
		look_knob.position = look_base.size * 0.5 + clamped - look_knob.size * 0.5

func _apply_move_vec(delta: Vector2) -> void:
	# Map joystick offset into a 2D axis [-1..1] and drive the four cardinal
	# input actions via Input.action_press / action_release. Using the
	# strength variant keeps Input.get_vector() smooth for analog movement.
	var v: Vector2 = delta / STICK_RADIUS
	var mag: float = v.length()
	if mag < STICK_DEAD_ZONE:
		v = Vector2.ZERO
	elif mag > 1.0:
		v = v.normalized()
	# Update knob visual.
	var clamped: Vector2 = delta.limit_length(STICK_RADIUS)
	move_knob.position = move_base.size * 0.5 + clamped - move_knob.size * 0.5
	# Drive virtual axes — note Y-axis: in Godot screen coords, down is +.
	# Forward = up = -Y on the stick.
	var fwd: float = max(0.0, -v.y)
	var back: float = max(0.0, v.y)
	var left: float = max(0.0, -v.x)
	var right: float = max(0.0, v.x)
	_set_axis("move_forward", _vfwd, fwd)
	_set_axis("move_backward", _vback, back)
	_set_axis("move_left", _vleft, left)
	_set_axis("move_right", _vright, right)
	_vfwd = fwd; _vback = back; _vleft = left; _vright = right

func _set_axis(action: String, prev: float, cur: float) -> void:
	# Use action_press with strength to drive analog movement.
	if cur > 0.0:
		Input.action_press(action, cur)
	elif prev > 0.0:
		Input.action_release(action)

func _emit_look(rel: Vector2) -> void:
	# Drive look by calling the local player's apply_look() directly. Synthetic
	# InputEventMouseMotion does NOT reliably reach gameplay code on Android,
	# so we resolve our own input-authority player and rotate it.
	var p := _local_player()
	if p and p.has_method("apply_look"):
		# Scale screen-pixel delta into radians. Tuned to feel close to mouse.
		p.apply_look(rel * TOUCH_LOOK_SENS)

const TOUCH_LOOK_SENS := 0.005   # radians per screen pixel

# Cache the local player lookup; the match repopulates Players each round.
var _cached_player: Node = null
func _local_player() -> Node:
	if _cached_player and is_instance_valid(_cached_player):
		return _cached_player
	var my_id := multiplayer.get_unique_id() if multiplayer.has_multiplayer_peer() else 1
	# Players live under Match/Players/<peer_id> (see match.gd).
	var match_node := get_tree().get_first_node_in_group("match")
	if match_node == null:
		return null
	var players := match_node.get_node_or_null("Players")
	if players == null:
		return null
	var node := players.get_node_or_null(str(my_id))
	if node:
		_cached_player = node
	return node
