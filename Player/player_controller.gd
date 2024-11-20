class_name PlayerController extends Node3D

# Scope Node Define
@onready var select_area: Area3D = %SelectArea
@onready var collision_shape: CollisionShape3D = %CollisionShape
@onready var selection_box: SelectionBox = %SelectionBox
@onready var player_skill_scope_indicator: PlayerSkillScopeIndicator = %PlayerSkillScopeIndicator




var client_id: String = OS.get_unique_id()
var player_idx: int
var player_group_idx: int


var outline_material: ShaderMaterial


# Player Status
static var mouse_key_state: PlayerStatus.MouseKeyState = PlayerStatus.MouseKeyState.IDEL
static var mouse_state: PlayerStatus.MouseState = PlayerStatus.MouseState.IDEL

# Player corsor 
var cursor_default = load("res://Asserts/Images/indicator/cursor_point.png")
var cursor_target = load("res://Asserts/Images/indicator/target_select.png")


var player_mouse_position


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# 注册到 main

	# Signal 监听
	#SignalBus.ray_picker_regist.emit(click_to_select)
	SignalBufferSystem.buffer_signal(SignalBus.ray_picker_regist, select_area_pos_sync)
	SignalBus.unit_logic_death.connect(_on_unit_logic_death)
	player_idx = get_player_idx()
	player_group_idx = get_player_group_idx()
	
	outline_material = preload("res://Asserts/shared/shader/3d/outline/outline_mat.tres")

	# 设置鼠标光标
	Input.set_custom_mouse_cursor(cursor_default)

	player_mouse_position = $PlayerMousePosition

# 获取玩家索引信息
func get_player_idx():
	return 0

func get_player_group_idx():
	return 0

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	PlayerMouseMovement.calculate_mouse_speed(get_viewport(), delta)

# area3d 与 mouse position 同步 （ray picker 回调函数）
func select_area_pos_sync(ray_cast: RayCast3D) -> void:
	select_area.global_position = ray_cast.get_collision_point()
	player_mouse_position.global_position = ray_cast.get_collision_point()


# mouse coursor 切换
func switch_cursor(cousor: Constants.CURSOR_STATUS) -> void:
	if cousor == Constants.CURSOR_STATUS.TARGETED:
		Input.set_custom_mouse_cursor(cursor_target, Input.CURSOR_ARROW, Vector2(16, 16))
	else:
		Input.set_custom_mouse_cursor(cursor_default, Input.CURSOR_ARROW, Vector2(0, 0))




# 选中单位		
# TODO click select && frame select (click select trigger when show circle, but unit will move out to candidate， how to stop it）
func refresh_selection_units(unit_map: Dictionary) -> void:
	# remove last selected units
	for unit in PlayerSelect.units():
		if is_instance_valid(unit) and !unit_map.keys().has(unit.get_instance_id()) and unit.has_method('hide_selected_circle'):
			(unit as BaseUnit).hide_selected_circle()
	
	# 清空
	PlayerSelect.set_unit_map(unit_map)
	
	# append new selected units
	for key in unit_map.keys():
		var unit = unit_map[key]
		if is_instance_valid(unit) and unit is BaseUnit and unit.has_method('show_selected_circle'):
			(unit as BaseUnit).show_selected_circle()
	
	# emit signal player_selected_units
	SignalBus.player_selected_units.emit(unit_map)


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
	static var _selecting := false
	static var _candidate_selected_unit: Dictionary = {}
	static var _selected_unit: Dictionary = {}
	
	static func is_selecting():
		return _selecting
	
	# Selected Untis
	static func clear_unit():
		_selected_unit.clear()
	
	static func contains_unit(unit: Object) -> bool:
		if unit != null:
			return _selected_unit.keys().has(unit.get_instance_id())
		return false
		
	static func units() -> Array:
		return _selected_unit.values()
		
	static func add_selected_unit(unit) -> Object:
		if unit != null:
			_selected_unit[unit.get_instance_id()] = unit
		return null
		
	static func set_unit_map(unit_map) -> void:
		_selected_unit = unit_map
	
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
		

# monitor when unit enter mouse scope
func _on_select_area_area_entered(area: Area3D) -> void:
	var unit = area.owner
	if unit is BaseUnit and unit.is_alive() and unit.has_method('show_selected_circle'):
		(unit as BaseUnit).show_selected_circle()
		var unit_mesh: MeshInstance3D = CommonUtil.get_first_node_by_node_type(unit, Constants.MeshInstance3D_CLZ)
		if unit_mesh != null:
			unit_mesh.material_overlay = outline_material

# monitor when unit exit mouse scope(notice when selected, not hide)
func _on_select_area_area_exited(area: Area3D) -> void:
	var unit = area.owner
	
	var unit_mesh: MeshInstance3D = CommonUtil.get_first_node_by_node_type(unit, Constants.MeshInstance3D_CLZ)
	if unit_mesh != null:
		unit_mesh.material_overlay = null
	
	if PlayerSelect.is_selecting():
		return
	if unit is BaseUnit and !PlayerSelect.contains_unit(unit) and unit.has_method('hide_selected_circle'):
		(unit as BaseUnit).hide_selected_circle()




# Selection Box Event Callback
func _on_selection_box_frame_selecting_unit_entered(unit: BaseUnit) -> void:
	if unit is BaseUnit and unit.has_method('show_selected_circle'):
		(unit as BaseUnit).show_selected_circle()



func _on_selection_box_frame_selecting_unit_exited(unit: BaseUnit) -> void:
	if unit is BaseUnit and unit.has_method('hide_selected_circle'):
		(unit as BaseUnit).hide_selected_circle()



func _on_selection_box_selecting_started() -> void:
	PlayerSelect._selecting = true


func _on_selection_box_selecting_finished(unit_map: Dictionary) -> void:
	PlayerSelect._selecting = false
	refresh_selection_units(unit_map)
	
	
# listening unit death
func _on_unit_logic_death(id: int, unit: BaseUnit):
	if unit.has_method('hide_selected_circle'):
		unit.hide_selected_circle()
	
	var unit_mesh: MeshInstance3D = CommonUtil.get_first_node_by_node_type(unit, Constants.MeshInstance3D_CLZ)
	unit_mesh.material_overlay = null
