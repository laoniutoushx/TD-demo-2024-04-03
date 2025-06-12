extends Node3D
class_name DamageSystem

var _tick := 0.0

func _ready() -> void:
	SystemUtil.damage_system = self


func action(source: BaseUnit, target: BaseUnit):
	# 等待动画回复点
	await CommonUtil.await_timer(source.anim_ack_point)
	
	var fire_pos_marks: Array = CommonUtil.get_fire_pos(source)
	
	# 并发处理所有火力点 - 不等待完成
	process_all_fire_positions_concurrent(source, target, fire_pos_marks)

	# 火力点轮换
	source.current_fire_pos_key = CommonUtil.get_next_fire_pos_key(source)


# 并发处理所有火力点 - 核心方法
func process_all_fire_positions_concurrent(source: BaseUnit, target: BaseUnit, fire_pos_marks: Array) -> void:
	# 直接启动所有并发任务，不存储返回值
	for fire_pos_mark: Marker3D in fire_pos_marks:
		# 每个火力点独立启动，不等待
		process_single_fire_position_async(source, target, fire_pos_mark)
	
	# 可选：如果需要等待所有任务完成，可以使用信号或计数器
	# 这里不等待，实现真正的"发射后不管"并发


# 单个火力点的异步处理 - 完全独立
func process_single_fire_position_async(source: BaseUnit, original_target: BaseUnit, fire_pos_mark: Marker3D) -> void:
	var fire_pos = fire_pos_mark.global_position
	var current_target = original_target

	# 播放火力点动画
	if fire_pos_mark and fire_pos_mark.ap and fire_pos_mark.fire_animation:
		fire_pos_mark.ap.play(fire_pos_mark.fire_animation)
	
	# 弹幕系统处理
	var bs = await (SystemUtil.barrage_system as BarrageSystem).action(source, fire_pos, current_target, fire_pos_mark)
	
	# 处理主目标伤害
	await apply_damage_and_effects(source, current_target)
	
	# 更新目标信息
	var dest_pos: Vector3 = bs[0]
	var target_unit_id = bs[1]
	current_target = bs[2]
	
	# 处理弹跳逻辑
	await process_bounce_chain(source, current_target, dest_pos, target_unit_id, fire_pos_mark)


# 处理弹跳链
func process_bounce_chain(source: BaseUnit, initial_target: BaseUnit, dest_pos: Vector3, target_unit_id: int, fire_pos_mark: Marker3D) -> void:
	var current_target = initial_target
	var current_dest_pos = dest_pos
	var current_target_unit_id = target_unit_id
	
	# 弹跳处理
	for bounce_count in range(source.bounce_times):
		if not current_target_unit_id:
			break
			
		# 寻找下一个弹跳目标
		var next_target = get_units_in_range_physics_3d(current_dest_pos, source.bounce_distance, current_target_unit_id)
		
		if not next_target:
			break
		
		# 计算新的发射位置
		var new_fire_pos = Vector3(current_target.global_position.x, current_target._height / 2, current_target.global_position.z)
		
		# 弹幕系统处理弹跳
		var bounce_result = await (SystemUtil.barrage_system as BarrageSystem).action(source, new_fire_pos, next_target, fire_pos_mark)
		
		# 更新目标
		current_target = next_target
		
		# 处理弹跳目标的伤害和效果
		await apply_damage_and_effects(source, current_target)
		
		# 更新位置和目标信息
		current_dest_pos = bounce_result[0]
		current_target_unit_id = bounce_result[1]
		current_target = bounce_result[2]


# 应用伤害和效果
func apply_damage_and_effects(source: BaseUnit, target: BaseUnit) -> void:
	if not target or not target is BaseUnit or not (target as BaseUnit).is_alive():
		return
	
	# 造成伤害
	target.take_damage(DamageCtx.new(source, target, source.attack_value))
	
	# 受击动画
	_under_attack_anim(target)
	
	# 销毁特效
	_vfx_projectile_destory(target)


# 受击动画处理
func _under_attack_anim(target: BaseUnit):
	if not target or not target is BaseUnit:
		return
		
	var mesh_standing = (target as BaseUnit).get_mesh_standing()
	if mesh_standing == null:
		return
		
	mesh_standing.visible = true
	# 延迟隐藏
	CommonUtil.delay_execution(0.1, 
		func(): 
			if mesh_standing and is_instance_valid(mesh_standing): 
				mesh_standing.visible = false
	)


# 弹丸销毁特效
func _vfx_projectile_destory(target: BaseUnit):
	if not target or not target is BaseUnit:
		return
		
	var mesh_standing = (target as BaseUnit).get_mesh_standing()
	if mesh_standing == null:
		return
		
	mesh_standing.visible = true
	# 延迟隐藏
	CommonUtil.delay_execution(0.1, 
		func(): 
			if mesh_standing and is_instance_valid(mesh_standing): 
				mesh_standing.visible = false
	)


# 范围内单位查找
func get_units_in_range_physics_3d(center_position: Vector3, range_distance: float, target_unit_id: int) -> BaseUnit:
	for unit in SOS.main.get_tree().get_nodes_in_group("enemy"):
		if unit is BaseUnit and unit.is_alive() and unit.get_instance_id() != target_unit_id:
			if unit.global_position.distance_to(center_position) <= range_distance:
				return unit
	return null


# 动画处理
func animation_action(source: BaseUnit, target: BaseUnit):
	var ap: AnimationPlayer = CommonUtil.get_first_node_by_node_type(source, Constants.AnimationPlayer_CLZ) 
	if ap != null:
		if ap.is_playing():
			ap.stop()
		ap.play(source.anim_attack)


func _process(delta: float) -> void:
	_tick += delta


# 技能伤害
func skill_damage(skill: Skill, source: BaseUnit, target: BaseUnit) -> bool:
	if target.is_alive():
		return target.take_skill_damage(DamageCtx.new(source, target, skill.value, DamageCtx.DamageType.NORMAL, DamageCtx.DamageSourceType.SKILL))
	return true


# 技能范围伤害
func skill_range_damage(skill: Skill, source: BaseUnit, target_position: Vector3, affect_range: float = 5):
	var units_within_range: Array = []

	for unit in SOS.main.get_tree().get_nodes_in_group("enemy"):
		if unit.global_position.distance_to(target_position) <= affect_range:
			units_within_range.append(unit)

	for unit in units_within_range:
		if unit and unit.owner and unit.owner is BaseUnit and unit.owner.is_alive():
			var unit_position = unit.owner.global_position
			var area = CommonUtil.get_first_node_by_node_name(unit.owner, "AttackedScope")
			if area:
				var collision: CollisionShape3D = CommonUtil.get_first_node_by_node_type(area, Constants.CollisionShape3D_CLZ)
				var shape: Shape3D = collision.shape
				var shape_size: Vector3

				# 根据碰撞形状处理
				if shape is BoxShape3D:
					shape_size = shape.size
				elif shape is CapsuleShape3D:
					shape_size = Vector3(shape.radius * 2, shape.height, shape.radius * 2)

				var scale: Vector3 = CommonUtil.get_basic_scale(collision)
				var world_unit_size = shape_size * scale

				var is_in_range = target_position.x >= unit_position.x - world_unit_size.x / 2 and target_position.x <= unit_position.x + world_unit_size.x / 2 and target_position.z >= unit_position.z - world_unit_size.z / 2 and target_position.z <= unit_position.z + world_unit_size.z / 2
				
				if is_in_range:
					if CommonUtil.is_flag_set(SkillMetaResource.SKILL_TARGET_TYPE.ENEMY, skill.target_type) and unit.owner.player_group != source.player_group:
						unit.owner.take_skill_damage(DamageCtx.new(source, unit.owner, skill.value, DamageCtx.DamageType.NORMAL, DamageCtx.DamageSourceType.SKILL))