extends Node3D

const BattleInput = preload("res://Scripts/utils/BattleInput.gd")
@export var cam: Camera3D
## World-space camera anchor bounds; preserves existing level configuration.
@export var map_bounds: Rect2
@export var edge_scroll_enabled := true
@export_range(1, 100) var edge_margin := 20.0
@export_range(1, 100) var scroll_speed := 30.0
@export_range(1, 1000) var acceleration := 220.0
var velocity := Vector3.ZERO
var diagnostics: Dictionary = {}

func _notification(what: int) -> void:
	if what == NOTIFICATION_PAUSED: velocity = Vector3.ZERO

func _process(delta: float) -> void:
	mouse_camera_move(delta)

func scroll_direction(mouse: Vector2, viewport_size: Vector2) -> Vector3:
	if not mouse.is_finite() or viewport_size.x <= 0 or viewport_size.y <= 0: return Vector3.ZERO
	var direction := Vector3.ZERO
	if mouse.x <= edge_margin: direction.x -= 1
	elif mouse.x >= viewport_size.x - edge_margin: direction.x += 1
	if mouse.y <= edge_margin: direction.z -= 1
	elif mouse.y >= viewport_size.y - edge_margin: direction.z += 1
	return direction.normalized()

func _stop(reason: String) -> void:
	velocity = Vector3.ZERO
	diagnostics["reason"] = reason

func mouse_camera_move(delta: float) -> void:
	if not is_instance_valid(cam):
		_stop("no_camera")
		return
	var policy = SOS.main.cursor_policy if is_instance_valid(SOS.main) else null
	var point: Vector2 = policy.sample_pointer() if is_instance_valid(policy) else get_viewport().get_mouse_position()
	var rect := get_viewport().get_visible_rect()
	diagnostics = {"frame": Engine.get_process_frames(), "sample": point, "focused": policy.focused if is_instance_valid(policy) else get_window().has_focus(), "mode": Input.mouse_mode, "position": cam.global_position, "direction": Vector3.ZERO}
	if not edge_scroll_enabled:
		_stop("disabled")
		return
	if not point.is_finite() or not rect.has_point(point):
		_stop("invalid_or_outside_pointer")
		return
	var blocked_reason := BattleInput.edge_scroll_block_reason(get_viewport(), point)
	if not blocked_reason.is_empty():
		_stop(blocked_reason)
		return
	var direction := scroll_direction(point - rect.position, rect.size)
	diagnostics["direction"] = direction
	if direction == Vector3.ZERO:
		_stop("interior")
		return
	if direction.x == 0 or signf(direction.x) != signf(velocity.x): velocity.x = 0
	if direction.z == 0 or signf(direction.z) != signf(velocity.z): velocity.z = 0
	velocity = velocity.move_toward(direction * scroll_speed, acceleration * delta)
	var next_position := cam.global_position + velocity * delta
	next_position.x = clampf(next_position.x, map_bounds.position.x, map_bounds.end.x)
	next_position.z = clampf(next_position.z, map_bounds.position.y, map_bounds.end.y)
	if (next_position.x == map_bounds.position.x and velocity.x < 0) or (next_position.x == map_bounds.end.x and velocity.x > 0): velocity.x = 0
	if (next_position.z == map_bounds.position.y and velocity.z < 0) or (next_position.z == map_bounds.end.y and velocity.z > 0): velocity.z = 0
	cam.global_position = next_position
	diagnostics["position"] = next_position
	diagnostics["reason"] = "map_boundary" if velocity == Vector3.ZERO else "scrolling"
