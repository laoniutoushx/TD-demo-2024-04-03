class_name ThunderChain extends Node3D





func action(skill_context: SkillContext) -> void:
	# 播放施法动画 & 声音
	var skill: Skill = skill_context.skill
	var source_unit: BaseUnit = skill_context.source
	var target_unit: BaseUnit = skill_context.target


	# 技能释放
	# 音效播放
	# 特效绑定模型位置
	# 伤害触发


	# -- vfx/source_unit/target_unit handler
	var vfx  = SystemUtil.vfx_system.create_vfx("laser", SystemUtil.vfx_system.VFX_TYPE.RUNNING)
	target_unit.add_child(vfx)


	var source_mesh = CommonUtil.get_first_node_by_node_type(source_unit, Constants.MeshInstance3D_CLZ)
	var source_aabb = CommonUtil.get_scaled_aabb(source_mesh)
	var source_height = source_aabb.size.y

	var target_mesh = CommonUtil.get_first_node_by_node_type(target_unit, Constants.MeshInstance3D_CLZ)
	var target_aabb = CommonUtil.get_scaled_aabb(target_mesh)
	var target_height = target_aabb.size.y

	vfx.set_line(Vector3(source_unit.global_position.x, source_unit.global_position.y + source_height / 2, source_unit.global_position.z), 
		Vector3(target_unit.global_position.x, target_unit.global_position.y + target_height / 2, target_unit.global_position.z))

	SystemUtil.damage_system.skill_damage(skill, source_unit, target_unit)
	
	CommonUtil.delay_execution(2.0, func():     
		if is_instance_valid(vfx): 
			vfx.queue_free()
	)
