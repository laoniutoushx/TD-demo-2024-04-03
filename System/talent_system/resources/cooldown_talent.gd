extends Node3D



func action(talent_context: TalentContext) -> void:
    # 播放施法动画 & 声音
    var talent: Talent = talent_context.talent
    var source_unit: BaseUnit = talent_context.source
    var target_unit: BaseUnit = talent_context.target



    # 获取节点树中所有 group 为 friend 的节点
    var friends = get_tree().get_nodes_in_group("friend")

    # 重置所有单位技能 CD
    for friend in friends:
        if friend is Turret and is_instance_valid(friend):
            var skill_map = friend.skill_map
            for skill_code in skill_map.keys():
                var skill: Skill = skill_map[skill_code]
                if skill.current_state != Skill.SKILL_STATE.Idle:
                    skill.cool_down_timer.timeout.emit()
                    skill.cool_down_timer.stop()




