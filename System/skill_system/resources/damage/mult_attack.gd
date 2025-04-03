class_name MultAttack extends Node3D

var skill: Skill 
var source_unit: BaseUnit 
var target_position: Vector3 


func action(skill_context: SkillContext) -> void:
	# 播放施法动画 & 声音
	skill = skill_context.skill
	source_unit = skill_context.source
	target_position = skill_context.target_position
	

	for wave in range(skill.wave):

		var handler = InnerHandler.new(skill_context)
		add_child(handler)

		handler.projection_handler(target_position)



		if wave < skill.wave - 1:
			await CommonUtil.await_timer(skill.internal_time)    






class InnerHandler extends Node3D:
	signal finished()

	var skill_context: SkillContext
	var vfx
	var skill: Skill
	var source_unit: BaseUnit
	var target_unit: BaseUnit
	var target_position: Vector3
	var source_position: Vector3

	# 在 _process 函数中添加一个变量
	var move_progress: float = 0.0

	func _init(skill_context: SkillContext) -> void:
		self.skill_context = skill_context
		skill = skill_context.skill
		source_unit = skill_context.source
		target_unit = skill_context.target
		source_position = source_unit.global_position


	func _on_area3d_area_entered(area: Area3D) -> void:
		var _target_unit = area.owner
		if _target_unit is BaseUnit and _target_unit.is_alive():
			SystemUtil.damage_system.skill_damage(skill, source_unit, _target_unit)


	func projection_handler(dst_pos: Vector3) -> void:
		target_position = dst_pos

		vfx = SystemUtil.vfx_system.create_vfx("tornado", SystemUtil.vfx_system.VFX_TYPE.RUNNING)
		self.add_child(vfx)
		vfx.global_position = source_position


		var area: Area3D = vfx.find_child("Area3D")
		if area:
			area.area_entered.connect(_on_area3d_area_entered)
		
		await finished
		vfx.queue_free()



	func _process(delta):
		if target_position:
		   
			# 计算移动方向
			var direction = (target_position - source_position).normalized()

			# 更新物体位置
			vfx.global_position += direction * delta * skill.projection_speed

			# 判断物体是否接近目标
			var remaining_distance = vfx.global_position.distance_to(source_position)

			# 判断是否接近目标并且方向正确
			if remaining_distance >= skill.run_distance:
				set_process(false)
				# print("击中目标！")
				finished.emit()
