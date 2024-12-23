class_name FireRain extends Node3D





func action(skill_context: SkillContext) -> void:
    # 播放施法动画 & 声音
    var skill: Skill = skill_context.skill
    var source_unit: BaseUnit = skill_context.source
    var target_unit: BaseUnit = skill_context.target


    # 初始数量
    var init_num: int = skill.init_num

  
    # -- vfx/source_unit/target_unit handler
    var vfx = SystemUtil.vfx_system.create_vfx("lighting_chain", SystemUtil.vfx_system.VFX_TYPE.RUNNING)
    target_unit.add_child(vfx)

    SystemUtil.damage_system.skill_damage(skill, source_unit, target_unit)

    await CommonUtil.await_timer(2.0)
    
    if is_instance_valid(vfx):
        vfx.queue_free()
