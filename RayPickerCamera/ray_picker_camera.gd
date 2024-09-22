class_name RayPicker extends Camera3D

@onready var ray_cast_3d: RayCast3D = $RayCast3D
@export var grid_map: GridMap
@export var turret_manager: Node3D

# callback func list
var callable_back_list: Array[Callable] = []

func _ready() -> void:
	#SignalBus.ray_picker_regist.connect(_on_ray_picker_regist)
	SignalBufferSystem.connect_buffered(SignalBus.ray_picker_regist, _on_ray_picker_regist)
	#$RayCast3D.debug_shape_custom_color = Color(1, 0, 0)  # 红色
	#$RayCast3D.debug_shape_thickness = 2


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	var mouse_position = get_viewport().get_mouse_position()
	var target = project_local_ray_normal(mouse_position)
	
	ray_cast_3d.target_position = project_local_ray_normal(mouse_position) * 100.0
	
	# 强制更新射线碰撞信息
	ray_cast_3d.force_raycast_update() 
	for callback in callable_back_list:
		var callbacl_class = callback.get_object()
		if callbacl_class is TurretManager:
			callback.call(ray_cast_3d, grid_map)
			continue
		if callbacl_class is PlayerController:
			callback.call(ray_cast_3d)
			continue
		if callbacl_class is SelectionBox:
			callback.call(ray_cast_3d)
			continue


# Register Callable Function to be called when other Component need RayPicker Result
func _on_ray_picker_regist(callable: Callable) -> void:
	callable_back_list.append(callable)


		
