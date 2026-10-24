class_name TurretManager extends Node3D

const BattleInput = preload("res://Scripts/utils/BattleInput.gd")
@export var cell_mesh_indicator_scene: PackedScene
var turret: BaseUnit
var cell_mesh_indicator: MeshInstance3D
var skill_context: SkillContext
var cell_mesh_container: Dictionary = {}
## Runtime occupation is separate from the authored GridMap terrain.
var occupied: Dictionary = {}
var grid: GridMap
var preview_cell := Vector3i.ZERO
var preview_valid := false
var last_reason := ""

func _ready() -> void:
	grid = get_parent().get_node("GridMap")
	SignalBus.building_floor_indicator_show.connect(_on_building_floor_indicator_show)
	SignalBus.building_floor_indicator_hide.connect(_on_building_floor_indicator_hide)
	SOS.main.turret_manager = self

func world_to_cell(point: Vector3) -> Vector3i:
	return grid.local_to_map(grid.to_local(point))

func cell_to_world(cell: Vector3i) -> Vector3:
	return grid.to_global(grid.map_to_local(cell))

func footprint_cells(cell: Vector3i, definition: BaseUnitResource = null) -> Array[Vector3i]:
	if definition == null and skill_context != null and is_instance_valid(skill_context.skill): definition = skill_context.skill.skill_meta_res.building_res
	var footprint: Vector2i = definition.building_footprint if definition else Vector2i.ONE
	var cells: Array[Vector3i] = []
	for x in clampi(footprint.x, 1, 8):
		for z in clampi(footprint.y, 1, 8): cells.append(cell + Vector3i(x, 0, z))
	return cells

func placement_reason(cell: Vector3i, definition: BaseUnitResource = null) -> String:
	for occupied_cell in footprint_cells(cell, definition):
		if grid.get_cell_item(occupied_cell) != 0: return "占地范围包含不可建造地块"
		if occupied.has(occupied_cell): return "地块已被建筑占用"
	return ""

func placement_position(cell: Vector3i) -> Vector3:
	var cells := footprint_cells(cell)
	return (cell_to_world(cells[0]) + cell_to_world(cells[-1])) * 0.5

func callable_build_turret(ray: RayCast3D, _grid: GridMap) -> void:
	preview_valid = false
	if not is_instance_valid(turret) or not ray.is_colliding() or ray.get_collider() != grid: return
	preview_cell = world_to_cell(ray.get_collision_point())
	last_reason = placement_reason(preview_cell)
	preview_valid = last_reason == ""
	var point := placement_position(preview_cell)
	turret.global_position = point + Vector3.UP * 0.001
	if is_instance_valid(cell_mesh_indicator): cell_mesh_indicator.global_position = point + Vector3.UP * 0.02

func _unhandled_input(event: InputEvent) -> void:
	if not is_instance_valid(turret): return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if not BattleInput.pointer_available(get_viewport(), event.position): return
		# A ray miss must never confirm the last frame's valid placement.
		var camera = get_viewport().get_camera_3d()
		if camera is RayPicker:
			camera.ray_cast_3d.force_raycast_update()
			callable_build_turret(camera.ray_cast_3d, grid)
		if not preview_valid:
			SOS.main.message_bar.set_message(last_reason if last_reason != "" else "请选择可建造地块")
			return
		confirm_build(preview_cell)
		get_viewport().set_input_as_handled()

func confirm_build(cell: Vector3i) -> bool:
	if not is_instance_valid(turret) or skill_context == null or placement_reason(cell) != "": return false
	var reason := SOS.main.player_controller.validate_skill_cost(skill_context)
	if reason != "":
		SOS.main.message_bar.set_message(reason)
		return false
	var building: BaseUnit = turret
	var point := placement_position(cell) + Vector3.UP * 0.001
	var cells := footprint_cells(cell)
	for reserved_cell in cells: occupied[reserved_cell] = building.get_instance_id()
	building.set_meta("build_cell", cell)
	building.set_meta("build_cells", cells)
	building.tree_exiting.connect(_release_cells.bind(cells, building.get_instance_id()), CONNECT_ONE_SHOT)
	building.logical_death.connect(_on_building_left.bind(cells, building.get_instance_id()), CONNECT_ONE_SHOT)
	skill_context.building = building
	skill_context.callback = _finish_building.bind(building, point)
	building.global_position = point
	skill_context.skill.change_state(Skill.SKILL_STATE.Release)
	return true

func _finish_building(building: BaseUnit, point: Vector3) -> void:
	if not is_instance_valid(building): return
	building.global_position = point
	building.player_group = SOS.main.player_controller.get_player_group_idx()
	building.player_owner_idx = SOS.main.player_controller.get_player_idx()
	building.change_state(Turret.TurretState.IDLE)

func _release_cell(cell: Vector3i, id: int) -> void:
	if occupied.get(cell, -1) == id: occupied.erase(cell)

func _release_cells(cells: Array, id: int) -> void:
	for cell in cells: _release_cell(cell, id)

func _on_building_left(_unit: BaseUnit, cells: Array, id: int) -> void:
	_release_cells(cells, id)

func replace_building(old: BaseUnit, replacement: BaseUnit) -> void:
	if not old.has_meta("build_cell"): return
	var cell: Vector3i = old.get_meta("build_cell")
	var cells: Array = old.get_meta("build_cells", [cell])
	for reserved_cell in cells: occupied[reserved_cell] = replacement.get_instance_id()
	replacement.set_meta("build_cell", cell)
	replacement.set_meta("build_cells", cells)
	replacement.tree_exiting.connect(_release_cells.bind(cells, replacement.get_instance_id()), CONNECT_ONE_SHOT)
	replacement.logical_death.connect(_on_building_left.bind(cells, replacement.get_instance_id()), CONNECT_ONE_SHOT)

func _on_building_floor_indicator_show(context: SkillContext) -> void:
	cancel_preview()
	skill_context = context
	skill_context.cost_paid = false
	for cell in grid.get_used_cells():
		if placement_reason(cell) != "": continue
		var indicator := MeshInstance3D.new()
		indicator.mesh = grid.mesh_library.get_item_mesh(1)
		indicator.material_override = preload("res://Test/glow shader test 2/plane_edge_trans.tres")
		add_child(indicator)
		indicator.global_position = cell_to_world(cell) + Vector3.UP * 0.01
		cell_mesh_container[cell] = indicator
	var definition: BaseUnitResource = context.skill.skill_meta_res.building_res
	if definition != null:
		turret = SystemUtil.unit_system.create_unit(definition, SOS.main.player_controller.player_group_idx)
		add_child(turret)
	if cell_mesh_indicator_scene:
		cell_mesh_indicator = cell_mesh_indicator_scene.instantiate()
		add_child(cell_mesh_indicator)
	SignalBus.ray_picker_regist.emit(callable_build_turret)

func _on_building_floor_indicator_hide(context: SkillContext) -> void:
	if context != skill_context: return
	SignalBus.ray_picker_unregist.emit(callable_build_turret)
	_clear_cell_mesh_indicator_in_position()
	if is_instance_valid(cell_mesh_indicator): cell_mesh_indicator.queue_free()
	cell_mesh_indicator = null
	if context.cost_paid:
		turret = null
		preview_valid = false

func cancel_preview() -> void:
	SignalBus.ray_picker_unregist.emit(callable_build_turret)
	_clear_cell_mesh_indicator_in_position()
	if is_instance_valid(turret): turret.queue_free()
	if is_instance_valid(cell_mesh_indicator): cell_mesh_indicator.queue_free()
	turret = null
	cell_mesh_indicator = null
	preview_valid = false

func _clear_cell_mesh_indicator_in_position() -> void:
	for indicator in cell_mesh_container.values():
		if is_instance_valid(indicator): indicator.queue_free()
	cell_mesh_container.clear()
