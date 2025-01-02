class_name UnitSystem extends Node



func _ready() -> void:
	SystemUtil.unit_system = self



func create_unit(unit_res: Resource) -> BaseUnit:

	
	if unit_res is EnemyResource:
		return _enemy_create(unit_res)
	else:
		return _unit_create(unit_res)


func _enemy_create(enemy_resource: EnemyResource) -> Enemy:
	var enemy_instance: Enemy = enemy_resource.model_path.instantiate()
	#enemy_instance = CommonUtil.bean_properties_copy(enemy_resource, enemy_instance)
	
	# player
	enemy_instance.player_group = 1
	enemy_instance.player_owner_idx = 1
	
	return enemy_instance


func _unit_create(unit_resource: BaseUnitResource) -> Enemy:
	var unit_instance: BaseUnit = unit_resource.model_path.instantiate()
		
	# player
	unit_instance.player_group = 0
	unit_instance.player_owner_idx = 0
	
	return unit_instance


func get_units_in_range(source_unit: BaseUnit, range: float, unit_type: BaseUnit.ARMOR_TYPE_ENUM) -> Array[BaseUnit]:
	var position: Vector3 = source_unit.global_position
 
	var units_within_range: Array = []
	var units: Array[BaseUnit] = []

	for unit in SOS.main.get_tree().get_nodes_in_group("enemy"):
		# print(unit.global_position.distance_to(target_position))
		if unit.global_position.distance_to(source_unit.global_position) <= range:
			units_within_range.append(unit)


	print("chain chain chain")
	if unit_type == BaseUnit.ARMOR_TYPE_ENUM.ENEMY:
		for unit in units_within_range:
			if unit and unit.owner and unit.owner is BaseUnit and !unit.owner.is_logic_dead() and SOS.main.player_controller.player_group_idx != unit.owner.player_group:
				units.append(unit.owner)
				print(unit.owner.clz_code)

	print("chain chain chain")
	return units