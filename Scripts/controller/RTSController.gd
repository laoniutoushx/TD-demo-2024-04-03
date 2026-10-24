extends Node3D

const BattleInput = preload("res://Scripts/utils/BattleInput.gd")
@export var cam: Camera3D
## World-space camera anchor bounds; preserves the existing level configuration.
@export var map_bounds: Rect2
@export var edge_scroll_enabled := true
@export_range(1, 100) var edge_margin := 20.0
@export_range(1, 100) var scroll_speed := 30.0
@export_range(1, 1000) var acceleration := 220.0
var velocity := Vector3.ZERO
var window_focused := true
var pointer_inside := true
var pointer_position := Vector2.ZERO

func _ready() -> void:
	pointer_position = get_viewport().get_mouse_position()
	get_window().focus_exited.connect(_focus_lost)
	get_window().focus_entered.connect(_focus_gained)
	get_window().mouse_exited.connect(_pointer_exited)
	get_window().mouse_entered.connect(_pointer_entered)
	get_viewport().size_changed.connect(_pointer_exited)

func _input(event: InputEvent) -> void:
	if event is InputEventMouse:
		pointer_position = event.position
		pointer_inside = get_viewport().get_visible_rect().has_point(pointer_position)
		if not pointer_inside or scroll_direction(pointer_position, get_viewport().get_visible_rect().size) == Vector3.ZERO:
			velocity = Vector3.ZERO

func _focus_lost() -> void:
	window_focused = false
	velocity = Vector3.ZERO

func _focus_gained() -> void:
	window_focused = true
	if is_inside_tree(): pointer_position = get_viewport().get_mouse_position()

func _pointer_exited() -> void:
	if BattleInput.cursor_confined() and window_focused:
		# Native confinement can produce boundary/occlusion exit notifications.
		pointer_position = pointer_position.clamp(Vector2.ZERO, get_viewport().get_visible_rect().size - Vector2.ONE)
		pointer_inside = true
		return
	pointer_inside = false
	velocity = Vector3.ZERO

func _pointer_entered() -> void:
	pointer_position = get_viewport().get_mouse_position()
	pointer_inside = get_viewport().get_visible_rect().has_point(pointer_position)

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT or what == NOTIFICATION_WM_WINDOW_FOCUS_OUT:
		_focus_lost()
	elif what == NOTIFICATION_APPLICATION_FOCUS_IN or what == NOTIFICATION_WM_WINDOW_FOCUS_IN:
		_focus_gained()
	elif what == NOTIFICATION_PAUSED:
		velocity = Vector3.ZERO

func _process(delta: float) -> void:
	mouse_camera_move(delta)

func scroll_direction(mouse: Vector2, viewport_size: Vector2) -> Vector3:
	var direction := Vector3.ZERO
	if mouse.x < edge_margin: direction.x -= 1
	elif mouse.x > viewport_size.x - edge_margin: direction.x += 1
	if mouse.y < edge_margin: direction.z -= 1
	elif mouse.y > viewport_size.y - edge_margin: direction.z += 1
	return direction.normalized()

func mouse_camera_move(delta: float) -> void:
	if not is_instance_valid(cam): return
	if BattleInput.cursor_confined():
		pointer_position = pointer_position.clamp(Vector2.ZERO, get_viewport().get_visible_rect().size - Vector2.ONE)
		pointer_inside = true
	if not edge_scroll_enabled or not window_focused or not pointer_inside or not BattleInput.edge_scroll_available(get_viewport(), pointer_position):
		velocity = Vector3.ZERO
		return
	var direction := scroll_direction(pointer_position, get_viewport().get_visible_rect().size)
	if direction == Vector3.ZERO:
		velocity = Vector3.ZERO
		return
	if direction.x == 0 or signf(direction.x) != signf(velocity.x): velocity.x = 0
	if direction.z == 0 or signf(direction.z) != signf(velocity.z): velocity.z = 0
	velocity = velocity.move_toward(direction * scroll_speed, acceleration * delta)
	var position := cam.global_position + velocity * delta
	position.x = clampf(position.x, map_bounds.position.x, map_bounds.end.x)
	position.z = clampf(position.z, map_bounds.position.y, map_bounds.end.y)
	if position.x == map_bounds.position.x and velocity.x < 0 or position.x == map_bounds.end.x and velocity.x > 0: velocity.x = 0
	if position.z == map_bounds.position.y and velocity.z < 0 or position.z == map_bounds.end.y and velocity.z > 0: velocity.z = 0
	cam.global_position = position
