extends Node3D



func action(talent_context: TalentContext) -> void:
    # 播放施法动画 & 声音
    var talent: Talent = talent_context.talent
    var source_unit: BaseUnit = talent_context.source
    var target_unit: BaseUnit = talent_context.target



    # 获取节点树中所有 group 为 friend 的节点
    var friends = get_tree().get_nodes_in_group("friend")

    for friend in friends:
        if friend is Turret:
            print(friend.title)




