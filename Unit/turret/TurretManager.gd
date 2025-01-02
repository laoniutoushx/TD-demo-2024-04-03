class_name TurretManager extends Node3D

var turret: BaseUnit
var ray_picker: RayPicker
var skill_context: SkillContext

# 自定义 Annotation

var chock_material: Material = preload("res://Test/glow shader test 2/glow 3d - chocked.tres")

var cell_mesh_container: Dictionary = {}

func _ready() -> void:
	SignalBus.building_floor_indicator_show.connect(_on_building_floor_indicator_show)
	SignalBus.building_floor_indicator_hide.connect(_on_building_floor_indicator_hide)

	# 依赖注入
	SOS.main.turret_manager = self



func build_turret(position: Vector3, turret_code) -> void:

	turret.global_position = position
	
	# player
	turret.player_group = SOS.main.player_controller.get_player_group_idx()
	turret.player_owner_idx = SOS.main.player_controller.get_player_idx()
	turret.clz_name = 'turret'
	turret.clz_code = 'turret'
	
	turret.change_state(Turret.TurretState.IDLE)
 

# 炮塔应该有状态机来控制，状态应该包括（idle/patrolling/aimming/attacking/）




# 注册 build_turret function 到 RayPicker
func callable_build_turret(ray_cast_3d: RayCast3D, _grid_map: GridMap) -> void:
	# 同步建筑位置
	turret.global_position = ray_cast_3d.get_collision_point()

	if ray_cast_3d.is_colliding():
		var collider = ray_cast_3d.get_collider()
		if collider is GridMap:

			if Input.is_action_pressed("click"):
				var point = ray_cast_3d.get_collision_point()
				var cell =  _grid_map.local_to_map(point)

				# 当前 _grid_map 没有 cell 格子
				if _grid_map.get_cell_item(cell) == 0: 
					# 取消点击事件传递
					get_viewport().set_input_as_handled()

					# 取消注册
					SignalBus.ray_picker_unregist.emit(callable_build_turret)

					# 清除 cell mesh
					_clear_cell_mesh_indicator_in_position()

					# 将 mesh library 索引为 1 的格子设置到当前 gridmap 位置
					_grid_map.set_cell_item(cell, 1)

					# 创建 Turret
					# self.build_turret(_grid_map.map_to_local(cell), null)

					# 鼠标样式切换
					SOS.main.player_controller.switch_cursor(Constants.CURSOR_STATUS.DEFAULT)


					# skill state chagne
					var cell_center_pos: Vector3 = _grid_map.map_to_local(cell)
					cell_center_pos.y += 1.09
					var bind_build_turret: Callable = build_turret.bind(cell_center_pos, null)
					skill_context.callback = bind_build_turret
					skill_context.building = turret
					# skill_context.building_origin_pos = skill_context.building.global_position
					skill_context.building.global_position = cell_center_pos
					# skill_context.building.global_position = Vector3(turret.global_position.x, 10, turret.global_position.z)
					skill_context.skill.change_state(Skill.SKILL_STATE.Release)


# 显示建筑指示
func _on_building_floor_indicator_show(_skill_context: SkillContext):
	skill_context = _skill_context
	var grid_map = CommonUtil.get_first_node_by_node_name(self.get_parent(), "GridMap")
 
	# 创建指示 mesh
	for cell in grid_map.get_used_cells():
		# 判断 cell 索引，确认颜色
		var item_idx = grid_map.get_cell_item(cell)
		var cell_position = grid_map.map_to_local(cell)
		if item_idx == 0:
			if not cell_mesh_container.keys().has(cell_position):
				cell_position.y += 0.3
				var _cellmesh_instance = _create_cell_mesh_indicator_in_position(grid_map, cell_position)
				cell_mesh_container[cell_position] = _cellmesh_instance

	# 在鼠标位置创建 building model
	if skill_context.skill.skill_meta_res.building_scene != null:
		# turret = skill_context.skill.skill_meta_res.building_scene.instantiate()
		turret = SystemUtil.unit_system.create_unit(skill_context.skill.skill_meta_res.building_res)
		add_child(turret)


	SignalBus.ray_picker_regist.emit(callable_build_turret)


# 隐藏建筑指示
func _on_building_floor_indicator_hide(_skill_context: SkillContext):
	# 取消相机碰撞检测回调注册函数
	SignalBus.ray_picker_unregist.emit(callable_build_turret)
	# 清空所有指示
	_clear_cell_mesh_indicator_in_position()



# 创建 cell mesh 指示
func _create_cell_mesh_indicator_in_position(grid_map, cell_position: Vector3) -> MeshInstance3D:
	var cellmesh_instance = MeshInstance3D.new()
	cellmesh_instance.mesh = grid_map.mesh_library.get_item_mesh(1)  # 使用默认的块 Mesh
	var m = load("res://Test/glow shader test 2/glow 3d - chocked.tres")
	cellmesh_instance.material_override = m
	cellmesh_instance.global_transform.origin = cell_position
	add_child(cellmesh_instance)
	return cellmesh_instance


# 清空所有指示
func _clear_cell_mesh_indicator_in_position() -> void:
	for cell_position in cell_mesh_container:
		remove_child(cell_mesh_container[cell_position])
	
	cell_mesh_container.clear()
