class_name ThunderChain extends Node3D


func action(skill_context: SkillContext) -> void:
	# 播放施法动画 & 声音
	var skill: Skill = skill_context.skill
	var source_unit: BaseUnit = skill_context.source
	var target_unit: BaseUnit = skill_context.target


	var _s_u: BaseUnit = source_unit
	var _t_u: BaseUnit = target_unit

	# var handler = InnerHandler.new(skill_context)
	# add_child(handler)
	# handler.vfx_handler(_s_u, _t_u)
	var damaged_units = []

	for wave in range(skill.wave):
		if wave == 0:
			var handler = InnerHandler.new(skill_context)
			add_child(handler)
			print("source unit: %s, target unit: %s" % [_s_u.clz_code, _t_u.clz_code])
			handler.vfx_handler(_s_u, _t_u)
		else:

			_s_u = _t_u
			# 获取 source_target 单位 skill.range 码范围内随机 enemy 单位
			var enemies_in_range: Array[BaseUnit] = SystemUtil.unit_system.get_units_in_range(_s_u, skill.match_range, BaseUnit.ARMOR_TYPE_ENUM.ENEMY)
			# Remove already damaged units from the list of potential targets
			var units_to_remove = []
			for damaged_unit in damaged_units:
				if damaged_unit in enemies_in_range:
					units_to_remove.append(damaged_unit)
			for unit_to_remove in units_to_remove:
				enemies_in_range.erase(unit_to_remove)
					
			# If there are any enemies in range, select one at random and damage it
			if enemies_in_range.size() > 0:
				_t_u = enemies_in_range[randi() % enemies_in_range.size()]
				var handler = InnerHandler.new(skill_context)
				add_child(handler)
				print("source unit: %s, target unit: %s" % [_s_u.clz_code, _t_u.clz_code])
				handler.vfx_handler(_s_u, _t_u)
			else:
				break

		damaged_units.append(_t_u)
		damaged_units.append(_s_u)

		if wave < skill.wave - 1:
			await CommonUtil.await_timer(skill.internal_time)
		



class InnerHandler extends Node3D:
	var skill_context: SkillContext

	func _init(skill_context: SkillContext) -> void:
		self.skill_context = skill_context

	func vfx_handler(source_unit, target_unit) -> void:
		var skill: Skill = skill_context.skill

		# -- vfx/source_unit/target_unit handler
		var vfx = SystemUtil.vfx_system.create_vfx("laser", SystemUtil.vfx_system.VFX_TYPE.RUNNING)
		target_unit.add_child(vfx)


		var source_mesh = CommonUtil.get_first_node_by_node_type(source_unit, Constants.MeshInstance3D_CLZ)
		var source_aabb = CommonUtil.get_scaled_aabb(source_mesh)
		var source_height = source_aabb.size.y

		var target_mesh = CommonUtil.get_first_node_by_node_type(target_unit, Constants.MeshInstance3D_CLZ)
		var target_aabb = CommonUtil.get_scaled_aabb(target_mesh)
		var target_height = target_aabb.size.y

		vfx.set_line_by_unit(source_unit, target_unit)

		SystemUtil.damage_system.skill_damage(skill, source_unit, target_unit)
		
		CommonUtil.delay_execution(0.5, func():
			if is_instance_valid(vfx):
				vfx.queue_free()
		)
