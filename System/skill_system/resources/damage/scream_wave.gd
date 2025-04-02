class_name ScreamWave extends Node3D

var skill: Skill 
var source_unit: BaseUnit 
var target_position: Vector3 


func action(skill_context: SkillContext) -> void:
	# 播放施法动画 & 声音
	skill = skill_context.skill
	source_unit = skill_context.source
	target_position = skill_context.target_position
	

	for wave in range(skill.wave):

		# shockwave
		var vfx = SystemUtil.vfx_system.create_vfx("scream_wave", SystemUtil.vfx_system.VFX_TYPE.RUNNING)
		vfx.global_position.y = 1
		self.add_child(vfx)


		var area: Area3D = vfx.find_child("Area3D")
		if area:
			area.area_entered.connect(_on_area3d_area_entered)
		


		# 先朝向目标
		vfx.look_at(target_position, Vector3.UP)
		# 然后旋转180度（π弧度）
		vfx.rotate_y(PI)


		# CommonUtil.play_audio(source_unit, "雷神之锤技巧(Leishenzhichui_SkillC)_爱给网_aigei_com")


 
		if wave < skill.wave - 1:
			await CommonUtil.await_timer(skill.internal_time)    


func _on_area3d_area_entered(area: Area3D) -> void:
	var target_unit = area.owner
	if target_unit is BaseUnit and target_unit.is_alive():
		SystemUtil.damage_system.skill_damage(skill, source_unit, target_unit)
