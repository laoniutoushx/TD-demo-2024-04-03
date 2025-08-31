class_name Thunderclap extends Node3D





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
    var vfx = SystemUtil.vfx_system.create_vfx("thunderclap", SystemUtil.vfx_system.VFX_TYPE.RUNNING)
    target_unit.add_child(vfx)

    SystemUtil.damage_system.skill_damage(skill, source_unit, target_unit)
    
    CommonUtil.delay_execution(2, self, (func(_vfx):
        if _vfx and is_instance_valid(_vfx):
            _vfx.queue_free()
    ).bind(vfx))



