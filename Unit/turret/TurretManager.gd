extends Node3D
class_name TurretManager

@export var turret: PackedScene


var ray_picker: RayPicker

# 自定义 Annotation

var chock_material: Material = preload("res://Test/glow shader test 2/glow 3d - chocked.tres")

var cell_mesh_container: Dictionary = {}

func _ready() -> void:
	SignalBus.ray_picker_regist.emit(callable_build_turret)
	pass


func build_turret(position: Vector3, turret_code) -> void:
	var new_turret: Turret  = turret.instantiate()
	
	#var new_turret: Turret = SystemUtil.unit_system.create_unit()
	
	new_turret.global_position = position
	
	# player
	new_turret.player_group = SOS.main.player_controller.get_player_group_idx()
	new_turret.player_owner_idx = SOS.main.player_controller.get_player_idx()
	new_turret.clz_name = 'turret'
	new_turret.clz_code = 'turret'
	
	add_child(new_turret)


# 炮塔应该有状态机来控制，状态应该包括（idle/patrolling/aimming/attacking/）




# 注册 build_turret function 到 RayPicker
func callable_build_turret(ray_cast_3d: RayCast3D, grid_map: GridMap) -> void:
	Input.set_default_cursor_shape(Input.CURSOR_ARROW)
	if ray_cast_3d.is_colliding():
		var collider = ray_cast_3d.get_collider()
		if collider is GridMap:
			Input.set_default_cursor_shape(Input.CURSOR_POINTING_HAND)
			if Input.is_action_pressed("click"):
				var point = ray_cast_3d.get_collision_point()

				set_cell_material(grid_map, point, chock_material)

				# 当前 grid_map 没有 cell 格子
				# if grid_map.get_cell_item(cell) == 0: 
				# 	# 将 mesh library 索引为 1 的格子设置到当前 gridmap 位置

				# 	grid_map.set_cell_item(cell, 1)

				# 	# TODO 逻辑耦合 buliding turret
				# 	self.build_turret(grid_map.map_to_local(cell), null) 


func set_cell_material(grid_map: GridMap, point: Vector3, material: Material) -> void:
	var cell =  grid_map.local_to_map(point)
	var cell_position = grid_map.map_to_local(cell)
	cell_position.y += 0.3

	if not cell_mesh_container.has(cell_position):
		cell_mesh_container[cell_position] = cell

		var mesh_instance = MeshInstance3D.new()
		mesh_instance.mesh = grid_map.mesh_library.get_item_mesh(1)  # 使用默认的块 Mesh
		var m = load("res://Test/glow shader test 2/glow 3d - chocked.tres")
		mesh_instance.material_override = m
		mesh_instance.global_transform.origin = cell_position
		add_child(mesh_instance)
