class_name TornadoFoxI extends Node3D

var skill: Skill 
var source_unit: BaseUnit 
var target_position: Vector3 


func action(skill_context: SkillContext) -> void:
	# 播放施法动画 & 声音
	skill = skill_context.skill
	source_unit = skill_context.source
	target_position = skill_context.target_position
	

	for epoch in range(skill.epoch):

		var matched_units: Array[BaseUnit] = SystemUtil.unit_system.get_units_in_range(
			source_unit, skill.range, BaseUnit.ARMOR_TYPE_ENUM.ENEMY
		)

		var handler = InnerHandler.new(skill_context, matched_units)
		add_child(handler)
		handler.handler()


		if epoch < skill.epoch - 1:
			await CommonUtil.await_timer(skill.internal_time)    






class InnerHandler extends Node3D:
	signal finished()

	var skill_context: SkillContext
	var skill: Skill
	var source_unit: BaseUnit
	var target_unit: BaseUnit
	var matched_units: Array[BaseUnit]

	var vfxs: Array[Node3D]


	func _init(skill_context: SkillContext, matched_units) -> void:
		self.skill_context = skill_context
		skill = skill_context.skill
		source_unit = skill_context.source
		target_unit = skill_context.target

		matched_units = matched_units




	func handler() -> void:

		for matched_unit in matched_units:
			if matched_unit and matched_unit.is_alive():
				var vfx = SystemUtil.vfx_system.create_vfx("funnel_tornado", SystemUtil.vfx_system.VFX_TYPE.RUNNING)
				matched_unit.add_child(vfx)

				vfxs.append(vfx)


		for w in range(skill.wave):
			await CommonUtil.await_timer(skill.start_time)
		
			for matched_unit in matched_units:
				if matched_unit and is_instance_valid(matched_unit) and matched_unit.is_alive():
					SystemUtil.damage_system.skill_damage(
						skill, source_unit, matched_unit
					)
			
			await CommonUtil.await_timer(skill.internal_time)

			await CommonUtil.await_timer(skill.end_time)
			

		for vfx in vfxs:
			if vfx and is_instance_valid(vfx):
				vfx.queue_free()
