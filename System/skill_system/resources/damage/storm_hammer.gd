class_name StormHammer extends Node3D

const PROJECTILE = preload("res://System/skill_system/domain/SkillProjectile.gd")

func action(context: SkillContext) -> void:
	if not is_instance_valid(context.target):
		return
	for i in context.skill.init_num:
		var projectile = PROJECTILE.new()
		add_child(projectile)
		projectile.configure(context.source, context.target, SystemUtil.vfx_system.create_vfx("hammer", VFXSystem.VFX_TYPE.RUNNING), context.skill.projection_speed)
		projectile.hit.connect(_on_hit.bind(context.skill, context.source), CONNECT_ONE_SHOT)
		CommonUtil.play_audio(context.source, "雷神之锤技巧(Leishenzhichui_SkillC)_爱给网_aigei_com")

func _on_hit(target, skill, source) -> void:
	var impact = SystemUtil.vfx_system.create_vfx("hammer", VFXSystem.VFX_TYPE.DESTORY)
	if impact:
		target.add_child(impact)
		impact.position.y = target._height * 0.5
		CommonUtil.delay_execution(2.0, impact, impact.queue_free)
	SystemUtil.damage_system.skill_damage(skill, source, target)
	if target.is_alive():
		for buff in skill.buff_map.values():
			SystemUtil.buff_system.apply(buff, skill, target)
	CommonUtil.play_audio(target, "魔法击中-YS070510_爱给网_aigei_com")
