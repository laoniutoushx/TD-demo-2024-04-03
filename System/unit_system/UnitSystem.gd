class_name UnitSystem extends Node



func _ready() -> void:
	SystemUtil.unit_system = self



func create_unit(unit_res: Resource, player_idx: int) -> BaseUnit:

	# print(unit_res.clz_code)
	# print(unit_res.get_class())

	return _unit_create(unit_res, player_idx)



func _unit_create(unit_resource: BaseUnitResource, player_idx) -> BaseUnit:
	var unit_instance: BaseUnit = unit_resource.model_path.instantiate()
	unit_instance = CommonUtil.bean_properties_copy(unit_resource, unit_instance)
	
	# player
	unit_instance.player_group = player_idx
	unit_instance.player_owner_idx = player_idx
	
	return unit_instance



func get_units_in_range(source_unit: BaseUnit, range: float, unit_type: BaseUnit.ARMOR_TYPE_ENUM) -> Array[BaseUnit]:
	var position: Vector3 = source_unit.global_position
 
	var units_within_range: Array = []
	var units: Array[BaseUnit] = []

	for unit in SOS.main.get_tree().get_nodes_in_group("enemy"):
		# print(unit.global_position.distance_to(target_position))
		if unit.global_position.distance_to(source_unit.global_position) <= range:
			units_within_range.append(unit)


	# print("chain chain chain")
	if unit_type == BaseUnit.ARMOR_TYPE_ENUM.ENEMY:
		for unit in units_within_range:
			if unit and unit.owner and unit.owner is BaseUnit and !unit.owner.is_logic_dead() and SOS.main.player_controller.player_group_idx != unit.owner.player_group:
				units.append(unit.owner)
				print(unit.owner.clz_code)

	# print("chain chain chain")
	return units



# 获取单位组件信息
func get_component_from_unit(unit: BaseUnit, component_type: BaseUnitResource.COMPONENT_SYSTEM) -> Node:
	if component_type == BaseUnitResource.COMPONENT_SYSTEM.LEVEL:
		return CommonUtil.get_first_node_by_node_name(unit, "LevelComp")

	return null
	
	