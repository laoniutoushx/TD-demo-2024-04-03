class_name CriticalHit extends Node3D


func action(skill_context: SkillContext) -> void:
    # 播放施法动画 & 声音
    var skill: Skill = skill_context.skill
    var source_unit: BaseUnit = skill_context.source
    var target_unit: BaseUnit = skill_context.target


    for buff: Buff in skill.buff_map.values():
        SystemUtil.buff_system.apply(buff, source_unit)


