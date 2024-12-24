extends Node
class_name DamageSystem

var _tick := 0.0

func _ready() -> void:
	SystemUtil.damage_system = self


func action(source: BaseUnit, target:BaseUnit):
	var cur_tick = _tick
	# 1. AnimationPlayer => 动画回复点
	animation_action(source, target)
	await _tick - cur_tick >= 0.01
	
	# 1. 弹幕系统（源、目标
	(SystemUtil.barrage_system as BarrageSystem).action(source, target)


func animation_action(source: BaseUnit, target:BaseUnit):
	var ap: AnimationPlayer = source.find_child("AnimationPlayer")
	if ap != null:
		ap.play("attack")



func _process(delta: float) -> void:
	_tick += delta



func skill_damage(skill: Skill, source: BaseUnit, target:BaseUnit):
	print(skill.value)
	target.take_damage(skill.value)


func skill_range_damage(skill: Skill, source: BaseUnit, target_position: Vector3, affect_range: float = 5):
	var units_within_range: Array = []

	for unit in SOS.main.get_tree().get_nodes_in_group("enemy"):
		print(unit.global_position.distance_to(target_position))
		if unit.global_position.distance_to(target_position) <= affect_range:
			units_within_range.append(unit)

	for unit in units_within_range:
		if unit and unit.owner and unit.owner is BaseUnit:
			var unit_position = unit.owner.global_position
			var area = CommonUtil.get_first_node_by_node_name(unit.owner, "AttackedScope")
			if area:
				var collision: CollisionShape3D = CommonUtil.get_first_node_by_node_type(area, Constants.CollisionShape3D_CLZ)
				var shape: Shape3D = collision.shape
				var shape_size: Vector3

				# 暂时按照 collision shape 形状处理
				if shape is BoxShape3D:
					shape_size = shape.size
				elif shape is CapsuleShape3D:
					shape_size = Vector3(shape.radius * 2, shape.height, shape.radius * 2)


				var scale: Vector3 = CommonUtil.get_basic_scale(collision)

				var world_unit_size = shape_size * scale
				
				var min_x = unit_position.x - world_unit_size.x / 2
				var max_x = unit_position.x + world_unit_size.x / 2
				var min_z = unit_position.z - world_unit_size.z / 2
				var max_z = unit_position.z + world_unit_size.z / 2

				if target_position.x >= min_x and target_position.x <= max_x and target_position.z >= min_z and target_position.z <= max_z:
					if CommonUtil.is_flag_set(SkillMetaResource.SKILL_TARGET_TYPE.ENEMY, skill.target_type) and unit.owner.player_group != source.player_group:
						unit.owner.take_damage(skill.value)


