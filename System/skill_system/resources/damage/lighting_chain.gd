class_name LightingChain extends Skill


func action(skill_context: SkillContext) -> void:
    # 播放施法动画 & 声音
    var source: BaseUnit = skill_context.skill.source
    var animation_player: AnimationPlayer = CommonUtil.get_first_parent_by_node_type(source, Constants.AnimationPlayer_CLZ)

    if animation_player != null:
        if animation_player.has_animation("LightingChain"):
            animation_player.play("LightingChain")

    # 等待施法前摇开始
    await CommonUtil.await_timer(skill_context.skill.start_time)


    pass



