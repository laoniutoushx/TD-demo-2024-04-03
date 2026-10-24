class_name ScreamPain extends Node3D

const PROJECTILE = preload("res://System/skill_system/domain/SkillProjectile.gd")

func action(context: SkillContext) -> void:
	var skill = context.skill
	var source = context.source
	for wave in skill.wave:
		if not is_instance_valid(source) or not source.is_alive():
			return
		var shockwave = SystemUtil.vfx_system.create_vfx("shockwave", VFXSystem.VFX_TYPE.RUNNING)
		if shockwave:
			add_child(shockwave)
			shockwave.position.y = source._height * 0.5
			CommonUtil.delay_execution(0.5, shockwave, shockwave.queue_free)
		CommonUtil.play_audio(source, "施法")
		for target in SystemUtil.unit_system.get_units_in_range(source, skill.range, BaseUnit.ARMOR_TYPE_ENUM.ENEMY):
			var projectile = PROJECTILE.new()
			add_child(projectile)
			projectile.configure(source, target, SystemUtil.vfx_system.create_vfx("scream_ball", VFXSystem.VFX_TYPE.RUNNING), skill.projection_speed)
			projectile.hit.connect(_on_hit.bind(skill, source), CONNECT_ONE_SHOT)
		if wave < skill.wave - 1:
			await CommonUtil.await_timer(skill.internal_time)

func _on_hit(target, skill, source) -> void:
	SystemUtil.damage_system.skill_damage(skill, source, target)
	CommonUtil.play_audio(target, "魔法击中-YS070510_爱给网_aigei_com")
