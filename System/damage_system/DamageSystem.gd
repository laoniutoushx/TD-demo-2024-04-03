extends Node3D
class_name DamageSystem

var _tick := 0.0

func _ready() -> void:
	SystemUtil.damage_system = self


func action(source: BaseUnit, target:BaseUnit):
	var cur_tick = _tick

	var vfx_projectile_name: String = (source as BaseUnit).vfx_projectile_name

	# 等待动画回复点
	await CommonUtil.await_timer(source.anim_ack_point)
	
	# 1. AnimationPlayer => 动画回复点
	animation_action(source, target)

	var fire_pos: Vector3 = CommonUtil.get_fire_pos(source)
	
	# 1. 弹幕系统（源、目标
	var bs = await (SystemUtil.barrage_system as BarrageSystem).action(source, fire_pos, target, null)


	# 伤害追加
	if target and target is BaseUnit and (target as BaseUnit).is_alive(): 
		target.take_damage(DamageCtx.new(source, target, source.attack_value, DamageCtx.DamageType.NORMAL))


	
	# 受击动画（mesh_standing）
	_under_attack_anim(target)
	
	# destory vfx create
	_vfx_projectile_destory(target)

	var dest_pos: Vector3 = bs[0]
	var target_unit_id = bs[1]
	target = bs[2]


	# # 2. 弹幕弹跳逻辑
	for bt in range(source.bounce_times):

		if target_unit_id:

			# 2.1 获取下一个弹跳目标	
			var selected_unit = get_units_in_range_physics_3d(dest_pos, source.bounce_distance, target_unit_id)

			if selected_unit:
				fire_pos = Vector3(target.global_position.x, target._height / 2, target.global_position.z)

				bs = await (SystemUtil.barrage_system as BarrageSystem).action(source, fire_pos, selected_unit, null)

				target = selected_unit

				# print("bounce target: %s" % target.get_instance_id())
				# print("到达目标")
				
				# 伤害追加
				if selected_unit and target is BaseUnit and (target as BaseUnit).is_alive(): 
					target.take_damage(DamageCtx.new(source, target, source.attack_value, DamageCtx.DamageType.NORMAL))
				
				# 受击动画（mesh_standing）
				_under_attack_anim(target)
				
				# destory vfx create
				_vfx_projectile_destory(target)

				dest_pos = bs[0]
				target_unit_id = bs[1]
				target = bs[2]
			else:
				break


func _under_attack_anim(target:BaseUnit):
	# 受击动画（mesh_standing）
	if target and target is BaseUnit:
		var mesh_standing = (target as BaseUnit).get_mesh_standing()
		if mesh_standing != null:
			mesh_standing.visible = true
			# 等待 0.1 秒后恢复, wait to do
			CommonUtil.delay_execution(0.1, 
				(func(_mesh_standing) -> void: if _mesh_standing: _mesh_standing.visible = false).bind(mesh_standing)
			)

func _vfx_projectile_destory(target:BaseUnit):
	# 受击动画（mesh_standing）
	if target and target is BaseUnit:
		var mesh_standing = (target as BaseUnit).get_mesh_standing()
		if mesh_standing != null:
			mesh_standing.visible = true
			# 等待 0.1 秒后恢复, wait to do
			CommonUtil.delay_execution(0.1, 
				(func(_mesh_standing) -> void: if _mesh_standing: _mesh_standing.visible = false).bind(mesh_standing)
			)		


# 方法1：距离计算
func get_units_in_range_physics_3d(center_position: Vector3, range_distance: float, target_unit_id: int) -> BaseUnit:
	for unit in SOS.main.get_tree().get_nodes_in_group("enemy"):
		# print(unit.global_position.distance_to(target_position))
		if unit is BaseUnit and  unit.is_alive() and unit.get_instance_id() != target_unit_id and unit.global_position.distance_to(center_position) <= range_distance:
			return unit
	return null



func animation_action(source: BaseUnit, target:BaseUnit):
	var ap: AnimationPlayer = source.find_child(Constants.AnimationPlayer_CLZ)
	if ap != null:
		if ap.is_playing():
			ap.stop()
		ap.play(source.anim_attack)



func _process(delta: float) -> void:
	_tick += delta



func skill_damage(skill: Skill, source: BaseUnit, target:BaseUnit) -> bool:
	# print("skill value: %s, skill name: %s " % skill.value, skill.title)
	return target.take_skill_damage(skill.value)


func skill_range_damage(skill: Skill, source: BaseUnit, target_position: Vector3, affect_range: float = 5):
	var units_within_range: Array = []

	for unit in SOS.main.get_tree().get_nodes_in_group("enemy"):
		# print(unit.global_position.distance_to(target_position))
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

				var is_in_range = target_position.x >= unit_position.x - world_unit_size.x / 2 and target_position.x <= unit_position.x + world_unit_size.x / 2 and target_position.z >= unit_position.z - world_unit_size.z / 2 and target_position.z <= unit_position.z + world_unit_size.z / 2
				if is_in_range:
					if CommonUtil.is_flag_set(SkillMetaResource.SKILL_TARGET_TYPE.ENEMY, skill.target_type) and unit.owner.player_group != source.player_group:
						unit.owner.take_skill_damage(skill.value)
				
				# var min_x = unit_position.x - world_unit_size.x / 2
				# var max_x = unit_position.x + world_unit_size.x / 2
				# var min_z = unit_position.z - world_unit_size.z / 2
				# var max_z = unit_position.z + world_unit_size.z / 2

				# if target_position.x >= min_x and target_position.x <= max_x and target_position.z >= min_z and target_position.z <= max_z:
				# 	if CommonUtil.is_flag_set(SkillMetaResource.SKILL_TARGET_TYPE.ENEMY, skill.target_type) and unit.owner.player_group != source.player_group:
				# 		unit.owner.take_damage(skill.value)
