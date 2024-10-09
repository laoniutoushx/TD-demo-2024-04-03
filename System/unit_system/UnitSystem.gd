class_name UnitSystem extends Node



func _ready() -> void:
	SystemUtil.unit_system = self



func create_unit(unit_res: Resource) -> BaseUnit:
	
	if unit_res is EnemyResource:
		return _enemy_create(unit_res)
	
	return null


func _enemy_create(enemy_resource: EnemyResource) -> Enemy:
	var enemy_instance: Enemy = enemy_resource.model_path.instantiate()
	#enemy_instance = CommonUtil.bean_properties_copy(enemy_resource, enemy_instance)
	
	# player
	enemy_instance.player_group = 1
	enemy_instance.player_owner_idx = 1
	
	return enemy_instance
