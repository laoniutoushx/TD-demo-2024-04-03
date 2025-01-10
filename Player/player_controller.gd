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


# Player corsor 
var cursor_default = load("res://Asserts/Images/indicator/cursor_point.png")
var cursor_target = load("res://Asserts/Images/indicator/target_select.png")
var cursor_building = load("res://Asserts/Images/indicator/cursor_building.png")

# Skill Indicator Grid Map Material
var skill_indicator_grid_map_material: ShaderMaterial = load("res://Test/glow shader test 2/glow 3d - chocked.tres")


var player_mouse_position: Node3D

# player status（unique status）互斥状态，全局唯一
enum PLAYER_STATUS {
	DEFAULT,
	CHOOSING_TARGETED_UNIT,
	CHOOSING_BUILDING_AREA
}

var player_status = PLAYER_STATUS.DEFAULT
var player_mouse_position_limit: Vector2	# 玩家鼠标移动范围限制


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



# area3d 与 mouse position 同步 （ray picker 回调函数）
func select_area_pos_sync(ray_cast: RayCast3D) -> void:
	# 此处多一个处理，当玩家处在技能提示阶段，准备释放技能时，限制获取到的最大点击位置（鼠标移动限制只针对无法移动单位）
	if player_mouse_position_limit:
		pass

	select_area.global_position = ray_cast.get_collision_point()
	player_mouse_position.global_position = ray_cast.get_collision_point()


# mouse coursor 切换
func switch_cursor(cousor: Constants.CURSOR_STATUS) -> void:
	if cousor == Constants.CURSOR_STATUS.DEFAULT:
		Input.set_custom_mouse_cursor(cursor_default, Input.CURSOR_ARROW, Vector2(0, 0))
	elif cousor == Constants.CURSOR_STATUS.TARGETED:
		Input.set_custom_mouse_cursor(cursor_target, Input.CURSOR_ARROW, Vector2(16, 16))
	elif cousor == Constants.CURSOR_STATUS.HAND:
		# 完全清除自定义光标
		# Input.set_custom_mouse_cursor(null)
		Input.set_custom_mouse_cursor(cursor_building, Input.CURSOR_ARROW, Vector2(16, 16))
		


# 选中单位		
# TODO click select && frame select (click select trigger when show circle, but unit will move out to candidate， how to stop it）
func refresh_selection_units(unit_map: Dictionary, mouse_pos: Vector3, on_selected_player_status: PLAYER_STATUS) -> void:
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
	SignalBus.player_selected_units.emit(unit_map, mouse_pos, on_selected_player_status)




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


func _on_selection_box_selecting_finished(unit_map: Dictionary, mouse_pos: Vector3, on_selected_player_status: PLAYER_STATUS) -> void:
	PlayerSelect._selecting = false
	refresh_selection_units(unit_map, mouse_pos, on_selected_player_status)
	
	
# listening unit death
func _on_unit_logic_death(id: int, unit: BaseUnit):
	if unit.has_method('hide_selected_circle'):
		unit.hide_selected_circle()
	
	# 单位逻辑死亡时，清除单位网格效果（outline）等
	var unit_mesh: MeshInstance3D = CommonUtil.get_first_node_by_node_type(unit, Constants.MeshInstance3D_CLZ)
	unit_mesh.material_overlay = null
