class_name SelectionBox extends Node3D

signal frame_selecting_unit_entered(unit: BaseUnit)
signal frame_selecting_unit_exited(unit: BaseUnit)
signal selecting_started
signal selecting_finished(unit_map: Dictionary, end_project_pos: Vector3)

@onready var rectangular_selection_2d: Panel = $RectangularSelection2D

@onready var _area: Area3D = $SelectedArea
@onready var area_collision: CollisionShape3D = $SelectedArea/AreaCollision
@export var ray_length: float = 100.0

@export var selecting_delay: float = 0.1	# 延迟指定时间后开始执行框选逻辑


var start_project_pos: Vector3
var end_project_pos: Vector3
var cur_project_pos: Vector3

# control event trigger


func _ready() -> void:
	 # 确保 Panel 在所有子节点的最上层
	#get_parent().move_child(self, get_parent().get_child_count() - 1)
	
	SignalBufferSystem.buffer_signal(SignalBus.ray_picker_regist, select_area_pos_sync)
	SignalBus.unit_logic_death.connect(_on_unit_logic_death)
	await rectangular_selection_2d.ready
	rectangular_selection_2d.selecting_delay = selecting_delay
	
	
	
func _input(event: InputEvent) -> void:
	if (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed):
		_start()
		
	if (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed):
		_finish()
	


func _physics_process(_delta):
	_update()


func _selecting():
	return area_collision.disabled == false

func _start():
	if Constants.SELECTION_START: return
	Constants.SELECTION_START = true
	start_project_pos = cur_project_pos
	#print(start_project_pos)
	
	_area.global_position = start_project_pos
	area_collision.shape.size = Vector3.ZERO
	
	# delay to enable detect
	area_collision.disabled = false
	selecting_started.emit()
	#CommonUtil.delay_execution(selecting_delay, func(): 
		#area_collision.disabled = false
		#selecting_started.emit(
		#)


func _finish():
	if not _selecting() or not Constants.SELECTION_START:
		return

	Constants.SELECTION_START = false

	end_project_pos = cur_project_pos
	area_collision.disabled = true
	print("finish -> " + str(DoubleCacheSelection.units().keys().size()))
	var units = DoubleCacheSelection.units()
	selecting_finished.emit(units, end_project_pos)
	DoubleCacheSelection.shift_cache()

func _update():
	if not _selecting():
		return
	
	#_area.global_position = (cur_project_pos - start_project_pos) / 2.0
	_area.global_position = start_project_pos + (cur_project_pos - start_project_pos) / 2.0
	area_collision.shape.size = abs(cur_project_pos - start_project_pos)
	
	
# area3d 与 mouse position 同步 （ray picker 回调函数）
func select_area_pos_sync(ray_cast: RayCast3D) -> void:
	cur_project_pos = ray_cast.get_collision_point()


func _on_selected_area_area_entered(area: Area3D) -> void:
	# TODO player owner check
	if area.owner is BaseUnit and (area.owner as BaseUnit).is_alive():
		DoubleCacheSelection.append(area.owner)
		frame_selecting_unit_entered.emit(area.owner)
		#print("enter -> " + str(DoubleCacheSelection.units().keys().size()))


func _on_selected_area_area_exited(area: Area3D) -> void:
	if area.owner is BaseUnit:
		DoubleCacheSelection.remove(area.owner)
		frame_selecting_unit_exited.emit(area.owner)

# listening unit death
func _on_unit_logic_death(id:int, enemy :Enemy):
	DoubleCacheSelection.remove(enemy)


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
	static func _init():
		current_selection_unit_map = cache[current_idx]
	
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
