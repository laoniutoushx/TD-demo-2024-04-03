class_name PlayerController extends Node3D

# Scope Node Define
@onready var select_area: Area3D = %SelectArea
@onready var selection_box: SelectionBox = %SelectionBox
@onready var player_skill_scope_indicator: PlayerSkillScopeIndicator = %PlayerSkillScopeIndicator
@onready var player_skill_target_indicator = %PlayerSkillTargetIndicator


var wood: int = 0

func set_wood(s: Object, value: int) -> void:
	wood = value
	SignalBus.wood_changed.emit(s, wood)
	# print("wood changed %s" % [wood])


var money: int = 0

func set_money(s: Object, value: int) -> void:
	money = value
	SignalBus.money_changed.emit(s, money)
	# print("money changed %s" % [money])
	

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


# player status（unique status）互斥状态，全局唯一
enum PLAYER_STATUS {
	DEFAULT,
	CHOOSING_TARGETED_UNIT,
	CHOOSING_BUILDING_AREA
}

var player_status = PLAYER_STATUS.DEFAULT



# 当前鼠标位置所在单位
var cur_unit_map: Dictionary = {}


# 玩家鼠标移动范围限制
var limit_center: Vector3
var limit_radius: float
var is_limit_move: bool = false


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# 注册到 main

	# 加载 图标 资源
	CommonUtil.load_resources_to_container_from_directory("res://Asserts/Images/icon/")

	# Signal 监听
	#SignalBus.ray_picker_regist.emit(click_to_select)
	SignalBufferSystem.buffer_signal(SignalBus.ray_picker_regist, select_area_pos_sync)
	SignalBus.unit_logic_death.connect(_on_unit_logic_death)
	player_idx = get_player_idx()
	player_group_idx = get_player_group_idx()
	
	outline_material = preload("res://Asserts/shared/shader/3d/outline/outline_mat.tres")

	# 设置鼠标光标
	Input.set_custom_mouse_cursor(cursor_default)

	# target_indicator 默认隐藏
	player_skill_target_indicator.hide()

	# player 监听 skill 释放信号



# 获取玩家索引信息
func get_player_idx():
	return 0

func get_player_group_idx():
	return 0


# 限制玩家鼠标移动范围
func limit_move(center: Vector3, radius: float):
	limit_center = center
	limit_radius = radius    # ? 为什么要 3 倍
	is_limit_move = true


func not_limit_move():
	is_limit_move = false    



# TODO 当限制技能释放范围时，也同时限制鼠标移动范围（3d 反向映射 2d 空间）
# area3d 与 mouse position 同步 （ray picker 回调函数）
func select_area_pos_sync(ray_cast: RayCast3D) -> void:
	# 此处多一个处理，当玩家处在技能提示阶段，准备释放技能时，限制获取到的最大点击位置（鼠标移动限制只针对无法移动单位）
	var collision_point = ray_cast.get_collision_point()
	if is_limit_move:
		# 
		var current_pos := Vector2(collision_point.x, collision_point.z)
		var mouse_area_center := Vector2(SOS.main.player_controller.limit_center.x, SOS.main.player_controller.limit_center.z)
		var distance_to_center = current_pos.distance_to(mouse_area_center)


		# print("distance to center %s, _radius %s" % [distance_to_center, SOS.main.player_controller.limit_radius])

		# 如果鼠标超出了圆形范围，将其位置限制到圆形边界
		if distance_to_center  >= SOS.main.player_controller.limit_radius:
			var direction = (current_pos - mouse_area_center).normalized()
			var clamped_pos = mouse_area_center + direction * SOS.main.player_controller.limit_radius
			
			select_area.global_position = Vector3(clamped_pos.x, collision_point.y, clamped_pos.y)
			player_skill_target_indicator.global_position = Vector3(clamped_pos.x, collision_point.y, clamped_pos.y)
		else:
			select_area.global_position = collision_point
			player_skill_target_indicator.global_position = collision_point
	else:
		select_area.global_position = collision_point
		player_skill_target_indicator.global_position = collision_point



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



# 单位进入触发
# monitor when unit enter mouse scope
func _on_select_area_area_entered(area: Area3D) -> void:
	var unit = area.owner
	if unit and unit is BaseUnit and unit.is_alive() and unit.has_method('show_selected_circle'):

		# 添加单位到当前选中单位
		cur_unit_map[unit.get_instance_id()] = unit

		(unit as BaseUnit).show_selected_circle()
		var unit_mesh: MeshInstance3D = CommonUtil.get_first_node_by_node_type(unit, Constants.MeshInstance3D_CLZ)
		if unit_mesh != null:
			unit_mesh.material_overlay = outline_material

# 单位退出触发
# monitor when unit exit mouse scope(notice when selected, not hide)
func _on_select_area_area_exited(area: Area3D) -> void:
	var unit = area.owner

	# 移出单位到当前选中单位
	if unit:
		cur_unit_map.erase(unit.get_instance_id())

	
	var unit_mesh: MeshInstance3D = CommonUtil.get_first_node_by_node_type(unit, Constants.MeshInstance3D_CLZ)
	if unit_mesh != null:
		unit_mesh.material_overlay = null
	
	if PlayerSelect.is_selecting():
		return
	if unit and unit is BaseUnit and !PlayerSelect.contains_unit(unit) and unit.has_method('hide_selected_circle'):
		(unit as BaseUnit).hide_selected_circle()


# listening unit death
func _on_unit_logic_death(id: int, unit: BaseUnit):
	if unit.has_method('hide_selected_circle'):
		unit.hide_selected_circle()
	
	# 单位逻辑死亡时，清除单位网格效果（outline）等
	var unit_mesh: MeshInstance3D = CommonUtil.get_first_node_by_node_type(unit, Constants.MeshInstance3D_CLZ)
	unit_mesh.material_overlay = null

	# 移出单位到当前选中单位
	cur_unit_map.erase(id)

	# 树木、金钱处理
	set_wood(unit, wood)
	set_money(unit, money)



# player select box 监听事件
func _on_selection_box_selecting_started() -> void:
	PlayerSelect._selecting = true

# player select box 监听事件
func _on_selection_box_selecting_finished(unit_map: Dictionary, mouse_pos: Vector3, on_selected_player_status: PLAYER_STATUS) -> void:
	PlayerSelect._selecting = false
	refresh_selection_units(unit_map, mouse_pos, on_selected_player_status)
	
	
func _on_skill_released(skill_context: SkillContext) -> void:
	# 处理技能释放
	var skill: Skill = skill_context.skill

	# 技能是建筑技能，触发金钱、木材消耗
	if CommonUtil.is_flag_set(SkillMetaResource.SKILL_EFFECT_TYPE.BUILDING, skill.effect_type):
		
		# 获取建筑技能对应建筑单位信息（元数据中）
		var building_res: BaseUnitResource = skill.skill_meta_res.building_res

		if building_res.wood_cost > -1:
			if wood < building_res.wood_cost:
				# TODO 提示木材不足
				print("skill %s - %s wood not enough" % [skill.name, skill.title])
				return
			else:
				set_wood(skill, wood - building_res.wood_cost)
		
		if building_res.money_cost > -1:
			if money < building_res.money_cost:
				# TODO 提示金钱不足
				print("skill %s - %s money not enough" % [skill.name, skill.title])
				return
			else:
				set_money(skill, money - building_res.money_cost)




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



# 定义玩家单选单位（SelectArea）
