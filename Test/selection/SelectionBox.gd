class_name SelectionBox extends Node3D

signal frame_selecting_unit_entered(unit: BaseUnit)
signal frame_selecting_unit_exited(unit: BaseUnit)
signal selecting_started
signal selecting_finished

@onready var rectangular_selection_2d: Panel = $RectangularSelection2D

@onready var _area: Area3D = $SelectedArea
@onready var area_collision: CollisionShape3D = $SelectedArea/AreaCollision
@export var ray_length: float = 100.0

@export var selecting_delay: float = 0.05	# 延迟指定时间后开始执行框选逻辑


var start_project_pos: Vector3
var end_project_pos: Vector3
var cur_project_pos: Vector3

func _ready() -> void:
	SignalBufferSystem.buffer_signal(SignalBus.ray_picker_regist, select_area_pos_sync)
	await rectangular_selection_2d.ready
	rectangular_selection_2d.selecting_delay = selecting_delay

func _physics_process(_delta):
	_update()

func _input(event: InputEvent) -> void:
#func _unhandled_input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		_start()
	if (
		event is InputEventMouseButton
		and event.button_index == MOUSE_BUTTON_LEFT
		and not event.pressed
	):
		_finish()

func _selecting():
	return area_collision.disabled == false

func _start():

	start_project_pos = cur_project_pos
	print(start_project_pos)
	
	_area.global_position = start_project_pos
	area_collision.shape.size = Vector3.ZERO
	
	# delay to enable detect
	#area_collision.disabled = false
	#selecting_started.emit()
	CommonUtil.delay_execution(selecting_delay, func(): 
		area_collision.disabled = false
		selecting_started.emit()
		)


func _finish():
	if not _selecting():
		return
	
	end_project_pos = cur_project_pos
	area_collision.disabled = true
	selecting_finished.emit()

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
	if area.owner is BaseUnit:
		frame_selecting_unit_entered.emit(area.owner)


func _on_selected_area_area_exited(area: Area3D) -> void:
	if area.owner is BaseUnit:
		if area_collision.disabled == false:
			frame_selecting_unit_exited.emit(area.owner)
