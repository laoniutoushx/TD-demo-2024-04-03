extends Node3D
class_name TurretManager

@export var turret: PackedScene


@onready var grid_map: GridMap = $GridMap
var ray_picker: RayPicker

# 自定义 Annotation

var chock_material: Material = preload("res://Test/glow shader test 2/glow 3d - chocked.tres")

var cell_mesh_container: Dictionary = {}

func _ready() -> void:
	# SignalBus.ray_picker_regist.emit(callable_build_turret)
	SignalBus.building_floor_indicator_show.connect(_on_building_floor_indicator_show)
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
func callable_build_turret(ray_cast_3d: RayCast3D, _grid_map: GridMap) -> void:
	Input.set_default_cursor_shape(Input.CURSOR_ARROW)
	if ray_cast_3d.is_colliding():
		var collider = ray_cast_3d.get_collider()
		if collider is GridMap:
			Input.set_default_cursor_shape(Input.CURSOR_POINTING_HAND)
			if Input.is_action_pressed("click"):
				var point = ray_cast_3d.get_collision_point()
				var cell =  _grid_map.local_to_map(point)

				# 当前 _grid_map 没有 cell 格子
				if _grid_map.get_cell_item(cell) == 0: 
					# 将 mesh library 索引为 1 的格子设置到当前 gridmap 位置

					_grid_map.set_cell_item(cell, 1)

					# TODO 逻辑耦合 buliding turret
					self.build_turret(_grid_map.map_to_local(cell), null)



func _on_building_floor_indicator_show(skill_context: SkillContext):
	# 创建指示 mesh
	var size = grid_map.get_used_cells().size()
	for cell in grid_map.get_used_cells():
		var cell_position = grid_map.map_to_local(cell)
		if not cell_mesh_container.keys().has(cell_position):
			cell_position.y += 0.3
			var _cellmesh_instance = _create_cell_mesh_indicator_in_position(cell_position)
	
	# 开始监听 ray picker 点击位置



func _create_cell_mesh_indicator_in_position(cell_position: Vector3) -> MeshInstance3D:
	var cellmesh_instance = MeshInstance3D.new()
	cellmesh_instance.mesh = grid_map.mesh_library.get_item_mesh(1)  # 使用默认的块 Mesh
	var m = load("res://Test/glow shader test 2/glow 3d - chocked.tres")
	cellmesh_instance.material_override = m
	cellmesh_instance.global_transform.origin = cell_position
	add_child(cellmesh_instance)
	return cellmesh_instance