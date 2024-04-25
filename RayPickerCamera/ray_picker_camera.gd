extends Camera3D


@onready var ray_cast_3d: RayCast3D = $RayCast3D







# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	var mouse_position = get_viewport().get_mouse_position()
	var target = project_local_ray_normal(mouse_position)
	
	ray_cast_3d.target_position = project_local_ray_normal(mouse_position) * 100.0
	
	# 强制更新射线碰撞信息
	ray_cast_3d.force_raycast_update()
	
	var collider = ray_cast_3d.get_collider()
	var point = ray_cast_3d.get_collision_point()
	prints(collider , point)
