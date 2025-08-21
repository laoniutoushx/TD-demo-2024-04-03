extends Node3D



func action(talent_context: TalentContext) -> void:
    # 播放施法动画 & 声音
    var talent: Talent = talent_context.talent
    var source_unit: BaseUnit = talent_context.source
    var target_unit: BaseUnit = talent_context.target



    SystemUtil.damage_system.skill_damage(talent, source_unit, target_unit)



