class_name SelectionBox extends Node3D
const BattleInput = preload("res://Scripts/utils/BattleInput.gd")

signal selecting_started
signal selecting_finished(unit_map: Dictionary, end_project_pos: Vector3, player_status: PlayerController.PLAYER_STATUS)

enum GestureState { IDLE, PRESSED, DRAGGING }
@onready var rectangular_selection_2d: Panel = $RectangularSelection2D
@onready var _area: Area3D = $SelectedArea
@onready var area_collision: CollisionShape3D = $SelectedArea/AreaCollision
@export var ray_length: float = 100.0
@export var selecting_delay: float = 0.1 # Retained for existing scene serialization.
@export var drag_threshold := 6.0
var gesture_state := GestureState.IDLE
var start_screen_pos := Vector2.ZERO
var end_screen_pos := Vector2.ZERO
var player_status: PlayerController.PLAYER_STATUS
var window_focused := true
var last_cancel_reason := ""

func _ready() -> void:
	# Cleanup must still run if the tree is paused. Actions remain explicitly guarded.
	process_mode = Node.PROCESS_MODE_ALWAYS
	_area.monitoring = false
	area_collision.disabled = true
	get_window().focus_exited.connect(_focus_lost)
	get_window().focus_entered.connect(_focus_gained)
	get_window().mouse_exited.connect(_pointer_exited)
	get_viewport().size_changed.connect(_viewport_resized)

func _focus_lost() -> void:
	window_focused = false
	cancel_selection("focus_lost")

func _focus_gained() -> void:
	window_focused = true

func _pointer_exited() -> void:
	if BattleInput.cursor_confined() and window_focused: return
	cancel_selection("pointer_exited")

func _viewport_resized() -> void:
	cancel_selection("viewport_resized")

func _notification(what: int) -> void:
	if not is_node_ready(): return
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT or what == NOTIFICATION_WM_WINDOW_FOCUS_OUT:
		_focus_lost()
	elif what == NOTIFICATION_APPLICATION_FOCUS_IN or what == NOTIFICATION_WM_WINDOW_FOCUS_IN:
		_focus_gained()
	elif what == NOTIFICATION_PAUSED:
		cancel_selection("paused")

func _exit_tree() -> void:
	if is_node_ready(): cancel_selection("exit_tree")

func _process(_delta: float) -> void:
	if is_selecting() and not _can_continue(): cancel_selection("interaction_blocked")

func _can_continue() -> bool:
	if not window_focused or not BattleInput.interaction_available(get_viewport()): return false
	return is_instance_valid(SOS.main) and is_instance_valid(SOS.main.player_controller) and SOS.main.player_controller.player_status == PlayerController.PLAYER_STATUS.DEFAULT

func _input(event: InputEvent) -> void:
	if not is_selecting(): return
	if not _can_continue():
		cancel_selection("interaction_blocked")
		return
	if event is InputEventMouseMotion:
		if (event.button_mask & MOUSE_BUTTON_MASK_LEFT) == 0:
			cancel_selection("lost_release")
		elif not get_viewport().get_visible_rect().has_point(event.position):
			cancel_selection("pointer_exited")
		else: _move_pointer(event.position)
	elif event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		cancel_selection("escape")
		get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			cancel_selection("right_click")
			get_viewport().set_input_as_handled()
		elif event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
			_move_pointer(event.position)
			if BattleInput.pointer_available(get_viewport(), event.position): _finish()
			else: cancel_selection("release_over_ui")
			# This release belongs to the gesture, including when released over UI.
			get_viewport().set_input_as_handled()

func _unhandled_input(event: InputEvent) -> void:
	if not event is InputEventMouseButton or event.button_index != MOUSE_BUTTON_LEFT or not event.pressed: return
	if is_selecting() or not _can_continue() or not BattleInput.pointer_available(get_viewport(), event.position): return
	start_screen_pos = event.position
	end_screen_pos = event.position
	player_status = SOS.main.player_controller.player_status
	gesture_state = GestureState.PRESSED
	Constants.SELECTION_START = true
	PlayerController.PlayerSelect._selecting = true
	selecting_started.emit()
	get_viewport().set_input_as_handled()

func is_selecting() -> bool:
	return gesture_state != GestureState.IDLE

func _selecting() -> bool:
	return is_selecting()

func _move_pointer(point: Vector2) -> void:
	end_screen_pos = point
	if start_screen_pos.distance_to(point) >= drag_threshold: gesture_state = GestureState.DRAGGING
	if gesture_state == GestureState.DRAGGING:
		rectangular_selection_2d.show_rect(Rect2(start_screen_pos, point - start_screen_pos))

func cancel_selection(reason := "cancelled") -> void:
	last_cancel_reason = reason
	gesture_state = GestureState.IDLE
	Constants.SELECTION_START = false
	PlayerController.PlayerSelect._selecting = false
	if is_instance_valid(rectangular_selection_2d): rectangular_selection_2d.clear()

func _finish() -> void:
	if not is_selecting(): return
	var units := _query_selection()
	# Derive the endpoint from this release rather than an older RayPicker frame.
	var camera := get_viewport().get_camera_3d()
	var endpoint := Vector3.ZERO
	if camera != null:
		var origin := camera.project_ray_origin(end_screen_pos)
		var direction := camera.project_ray_normal(end_screen_pos)
		var ground = Plane(Vector3.UP, 0.0).intersects_ray(origin, direction)
		if ground != null: endpoint = ground
		if not units.is_empty(): endpoint = units.values()[0].global_position
	var status := player_status
	cancel_selection("completed")
	selecting_finished.emit(units, endpoint, status)

func _query_selection() -> Dictionary:
	var camera := get_viewport().get_camera_3d()
	var result := {}
	if camera == null: return result
	var rectangle := Rect2(start_screen_pos, end_screen_pos - start_screen_pos).abs()
	var single_click := gesture_state == GestureState.PRESSED
	if single_click:
		var origin := camera.project_ray_origin(end_screen_pos)
		var query := PhysicsRayQueryParameters3D.create(origin, origin + camera.project_ray_normal(end_screen_pos) * 1000.0, 7)
		query.collide_with_areas = true
		query.collide_with_bodies = false
		var hit := get_world_3d().direct_space_state.intersect_ray(query)
		if not hit.is_empty():
			var unit = hit.collider.owner
			if _can_select(unit):
				result[unit.get_instance_id()] = unit
				return result
	var closest_distance := 26.0 * 26.0
	for unit in get_tree().get_nodes_in_group("selectable_units"):
		if not _can_select(unit): continue
		var center: Vector3 = unit.global_position + Vector3.UP * unit._height * 0.5
		if camera.is_position_behind(center): continue
		var screen := camera.unproject_position(center)
		if single_click:
			var distance := screen.distance_squared_to(end_screen_pos)
			if distance < closest_distance:
				closest_distance = distance
				result = {unit.get_instance_id(): unit}
		elif rectangle.has_point(screen): result[unit.get_instance_id()] = unit
	return result

func _can_select(unit: Variant) -> bool:
	return is_instance_valid(unit) and unit is Node3D and unit.is_visible_in_tree() and not unit.is_queued_for_deletion() and ((unit is BaseUnit and unit.is_alive()) or unit is TreasureChest)

# Compatibility nodes remain disabled; screen queries are authoritative.
func _on_selected_area_area_entered(_area: Area3D) -> void:
	pass

func _on_selected_area_area_exited(_area: Area3D) -> void:
	pass

class DoubleCacheSelection:
	# Selection Box Units
	# Use Double Shift Cache Units Arrays
	static var selection_units_01: Dictionary = {}
	static var selection_units_02: Dictionary = {}
	static var selection_units_03: Dictionary = {}
	static var selection_units_04: Dictionary = {}
	static var selection_units_05: Dictionary = {}
	static var selection_units_06: Dictionary = {}

	static var cache: Array[Dictionary] = [selection_units_01, selection_units_02, selection_units_03, selection_units_04, selection_units_05, selection_units_06]
	static var current_idx = 0
	
	static var current_selection_unit_map: Dictionary
	static func _static_init():
		current_selection_unit_map = cache[current_idx]

	static func reset() -> void:
		for entry in cache: entry.clear()
		current_idx = 0
		current_selection_unit_map = cache[0]
	
	static func append(unit: Object):
		current_selection_unit_map[unit.get_instance_id()] = unit
		
	static func remove(unit: Object):
		current_selection_unit_map.erase(unit.get_instance_id())
		
	static func shift_cache() -> void:
		# 数组索引切换 ( 0 - 5 )
		current_idx = 0 if current_idx == 5 else current_idx + 1
		# 切换前清除前一个数组中的数据
		cache[current_idx].clear()
		current_selection_unit_map = cache[current_idx]
		
	static func units():
		return current_selection_unit_map
