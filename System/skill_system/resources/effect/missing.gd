class_name Missing extends Node3D


func action(skill_context: SkillContext) -> void:
    # 播放施法动画 & 声音
    var skill: Skill = skill_context.skill
    var source_unit: BaseUnit = skill_context.source
    var target_unit: BaseUnit = skill_context.target


    if source_unit.is_alive():
        for buff: Buff in skill.buff_map.values():

            # 预先设置概率控制器初始化回调
            buff.is_prob = true
            buff.prob_callback = (func(_skill: Skill) -> ProbabilityController:
                return ProbabilityController.new(_skill.value)).bind(skill)

            buff.value = skill.value


            SystemUtil.buff_system.apply(buff, source_unit)


