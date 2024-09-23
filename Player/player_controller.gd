class_name PlayerController extends Node

# Scope Node Define
@onready var select_area: Area3D = %SelectArea
@onready var collision_shape: CollisionShape3D = %CollisionShape
@onready var selection_box: SelectionBox = $SelectionBox


var client_id: String = OS.get_unique_id()


# Player Status
static var mouse_key_state: PlayerStatus.MouseKeyState = PlayerStatus.MouseKeyState.IDEL
static var mouse_state: PlayerStatus.MouseState = PlayerStatus.MouseState.IDEL

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Signal 监听
	#SignalBus.ray_picker_regist.emit(click_to_select)
	SignalBufferSystem.buffer_signal(SignalBus.ray_picker_regist, select_area_pos_sync)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	PlayerMouseMovement.calculate_mouse_speed(get_viewport(), delta)

# area3d 与 mouse position 同步 （ray picker 回调函数）
func select_area_pos_sync(ray_cast: RayCast3D) -> void:
	select_area.global_position = ray_cast.get_collision_point()
	if mouse_key_state == PlayerStatus.MouseKeyState.MOUSE_LEFT_CLICK:
		refresh_selection_units()

func refresh_selection_units() -> void:
	# remove last selected units
	for unit in PlayerSelect.units():
		PlayerSelect.remove_selected_unit(unit)
		if is_instance_valid(unit) and unit.has_method('hide_selected_circle'):
			(unit as BaseUnit).hide_selected_circle()
	
	# record selected units
	for candidate in PlayerSelect.candidates():
		PlayerSelect.add_selected_unit(candidate)
		if is_instance_valid(candidate) and candidate.has_method('show_selected_circle'):
			(candidate as BaseUnit).show_selected_circle()


func unit_selected_handler(unit) -> void:
	PlayerSelect.remove_candidate_unit(unit)
	PlayerSelect.add_selected_unit(unit)
	if unit is BaseUnit and unit.has_method('show_selected_circle'):
		(unit as BaseUnit).show_selected_circle()
	pass

# player input event handler ( change status )
func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				mouse_key_state = PlayerStatus.MouseKeyState.MOUSE_LEFT_CLICK
			else:
				mouse_key_state = PlayerStatus.MouseKeyState.MOUSE_LEFT_RELEASED
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			if event.pressed:
				mouse_key_state = PlayerStatus.MouseKeyState.MOUSE_RIGHT_CLICK
			else:
				mouse_key_state = PlayerStatus.MouseKeyState.MOUSE_RIGHT_RELEASED

# keyboard states and mouse states
class PlayerStatus:
	enum MouseKeyState {
		IDEL,
		MOUSE_LEFT_CLICK,
		MOUSE_RIGHT_CLICK,
		MOUSE_LEFT_PRESSING,
		MOUSE_RIGHT_PRESSING,
		MOUSE_RIGHT_RELEASED,
		MOUSE_LEFT_RELEASED
	}
	enum MouseState {
		IDEL,
		MOVING
	}

# mouse move state caculate
class PlayerMouseMovement:
	
	static var previous_mouse_position = Vector2.ZERO
	static var current_mouse_position = Vector2.ZERO
	static var mouse_speed = Vector2.ZERO

	static func calculate_mouse_speed(viewport: Viewport, delta):
		current_mouse_position = viewport.get_mouse_position()
		mouse_speed = (current_mouse_position - previous_mouse_position) / delta
		if mouse_speed.length() > 0:
			PlayerController.mouse_state = PlayerStatus.MouseState.MOVING
		else:
			PlayerController.mouse_state = PlayerStatus.MouseState.IDEL
		previous_mouse_position = current_mouse_position

# Player Selected Unit
class PlayerSelect:
	
	static var _candidate_selected_unit: Dictionary = {}
	static var _selected_unit: Dictionary = {}
	
	# Selected Untis
	static func clearl_unit():
		_selected_unit.clear()
	
	static func contains_unit(unit: Object) -> bool:
		if unit != null:
			return _selected_unit.keys().has(unit.get_instance_id())
		return unit != null
		
	static func units() -> Array:
		return _selected_unit.values()
		
	static func add_selected_unit(unit) -> Object:
		if unit != null:
			_selected_unit[unit.get_instance_id()] = unit
		return null
	
	static func remove_selected_unit(unit) -> bool:
		if unit != null:
			_selected_unit.erase(unit.get_instance_id())
		return unit == null	
		
	# Candidate Units
	static func clear_candidate():
		_candidate_selected_unit.clear()
	
	static func contains_candidate(unit) -> bool:
		if unit != null:
			return _candidate_selected_unit.keys().has(unit.get_instance_id())
		return unit != null
		
	static func candidates() -> Array:
		return _candidate_selected_unit.values()
	
	static func add_candidate_unit(unit) -> Object:
		if unit != null:
			_candidate_selected_unit[unit.get_instance_id()] = unit
		return null
	
	static func remove_candidate_unit(unit) -> bool:
		if unit != null:
			return _candidate_selected_unit.erase(unit.get_instance_id())
		return unit == null
		


func _on_select_area_area_entered(area: Area3D) -> void:
	var _enter_node = area.owner
	candidate_unit_add(_enter_node)


func _on_select_area_area_exited(area: Area3D) -> void:
	var _exit_node = area.owner
	candidate_unit_remove(_exit_node)


func _on_selection_box_frame_selecting_unit_entered(unit: BaseUnit) -> void:
	candidate_unit_add(unit)


func _on_selection_box_frame_selecting_unit_exited(unit: BaseUnit) -> void:
	candidate_unit_remove(unit)


func candidate_unit_add(unit) -> void:
	if unit is BaseUnit and unit.has_method('show_selected_circle'):
		PlayerSelect.add_candidate_unit(unit)
		(unit as BaseUnit).show_selected_circle()

func candidate_unit_remove(unit) -> void:
	if unit is BaseUnit and unit.has_method('hide_selected_circle'):
		PlayerSelect.remove_candidate_unit(unit)
		(unit as BaseUnit).hide_selected_circle()

func _on_selection_box_selecting_finished() -> void:
	refresh_selection_units()


# Selection Circle UI Logic Layer
