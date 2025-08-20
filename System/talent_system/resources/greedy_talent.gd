extends Node3D



func action(talent_context: TalentContext) -> void:
    # 播放施法动画 & 声音
    var talent: Talent = talent_context.talent
    var source_unit: BaseUnit = talent_context.source
    var target_unit: BaseUnit = talent_context.target



    if source_unit.is_alive():
        for buff: Buff in talent.buff_map.values():
            print("buff code %s, buff cooldown %s" % [buff.code, buff.cooldown])
            SystemUtil.buff_system.apply(buff, talent, source_unit)




