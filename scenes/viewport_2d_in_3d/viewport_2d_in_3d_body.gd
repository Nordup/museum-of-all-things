extends XRToolsInteractableBody


## Screen size
@export var screen_size = Vector2(3.0, 2.0)

## Viewport size
@export var viewport_size = Vector2(100.0, 100.0)


# Current mouse mask
var _mouse_mask := 0

# Viewport node
var _viewport : Viewport

# Dictionary of pointers to touch-index
var _touches := {}

# Dictionary of pressed pointers
var _presses := {}

# Dominant pointer (index == 0)
var _dominant : Node3D

# Mouse pointer
var _mouse : Node3D

# Last mouse position
var _mouse_last := Vector2.ZERO


func _ready():
	# Get viewport node
	_viewport = get_node("../Viewport")


## Convert intersection point to screen coordinate
func global_to_viewport(p_at : Vector3) -> Vector2:
	var t = $CollisionShape3D.global_transform
	var at = t.affine_inverse() * p_at

	# Convert to screen space
	at.x = ((at.x / screen_size.x) + 0.5) * viewport_size.x
	at.y = (0.5 - (at.y / screen_size.y)) * viewport_size.y

	return Vector2(at.x, at.y)


# Report touch-down event
func _report_touch_down(index : int, at : Vector2) -> void:
	var event := InputEventScreenTouch.new()
	event.index = index
	event.position = at
	event.pressed = true
	_viewport.push_input(event)


# Report touch-up event
func _report_touch_up(index : int, at : Vector2) -> void:
	var event := InputEventScreenTouch.new()
	event.index = index
	event.position = at
	event.pressed = false
	_viewport.push_input(event)


# Report touch-move event
func _report_touch_move(index : int, pressed : bool, from : Vector2, to : Vector2) -> void:
	var event := InputEventScreenDrag.new()
	event.index = index
	event.position = to
	event.pressure = 1.0 if pressed else 0.0
	event.relative = to - from
	_viewport.push_input(event)


# Report mouse-down event
func _report_mouse_down(at : Vector2) -> void:
	var event := InputEventMouseButton.new()
	event.button_index = 1
	event.pressed = true
	event.position = at
	event.global_position = at
	event.button_mask = 1
	_viewport.push_input(event)


# Report mouse-up event
func _report_mouse_up(at : Vector2) -> void:
	var event := InputEventMouseButton.new()
	event.button_index = 1
	event.pressed = false
	event.position = at
	event.global_position = at
	event.button_mask = 0
	_viewport.push_input(event)


# Report mouse-move event
func _report_mouse_move(pressed : bool, from : Vector2, to : Vector2) -> void:
	var event := InputEventMouseMotion.new()
	event.position = to
	event.global_position = to
	event.relative = to - from
	event.button_mask = 1 if pressed else 0
	event.pressure = 1.0 if pressed else 0.0
	_viewport.push_input(event)


# Find the next free touch index
func _next_touch_index() -> int:
	# Get the current touches
	var current := _touches.values()
	current.sort()

	# Look for a hole
	for touch in current.size():
		if current[touch] != touch:
			return touch

	# No hole so add to end
	return current.size()
