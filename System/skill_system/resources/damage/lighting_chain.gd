class_name LightingChain extends Node





func action(skill_context: SkillContext) -> void:
    # 播放施法动画 & 声音
    var source_unit: BaseUnit = skill_context.source

    var ap: AnimationPlayer = CommonUtil.get_first_node_by_node_type(source_unit, Constants.AnimationPlayer_CLZ)
    var anim_release_code: String = source_unit.anim_release

    if ap != null and ap.has_animation(anim_release_code):
        ap.play(anim_release_code)

    # 等待施法前摇开始
    await CommonUtil.await_timer(skill_context.skill.start_time)


    pass



