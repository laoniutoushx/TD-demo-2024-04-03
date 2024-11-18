class_name LightingChain extends Node





func action(skill_context: SkillContext) -> void:
    # 播放施法动画 & 声音
    var source: BaseUnit = skill_context.skill.source
    var animation_player: AnimationPlayer = CommonUtil.get_first_parent_by_node_type(source, Constants.AnimationPlayer_CLZ)

    if animation_player != null:
        var anim_release_code: String = skill_context.source.anim_release
        if animation_player.has_animation(anim_release_code):
            animation_player.play(anim_release_code)

    # 等待施法前摇开始
    await CommonUtil.await_timer(skill_context.skill.start_time)


    pass



