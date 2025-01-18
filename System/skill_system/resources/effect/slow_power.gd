class_name FireRain extends Node3D





func action(skill_context: SkillContext) -> void:
    # 播放施法动画 & 声音
    var skill: Skill = skill_context.skill
    var source_unit: BaseUnit = skill_context.source
    var target_unit: BaseUnit = skill_context.target


    # 一定范围内单位，进入时，添加 buff，移除时取消 buff

    # load area_tscn
    var area_tscn: PackedScene = load("res://Components/area/area.tscn")
    var area_inst: Area = area_tscn.instantiate()

    area_inst.init(skill.range)
    source_unit.add_child(area_inst)
    area_inst.area_entered.connect(_on_area_3d_area_entered.bind(skill_context))
    area_inst.area_exited.connect(_on_area_3d_area_exited.bind(skill_context))



func _on_area_3d_area_entered(area: Area3D, skill_context):
    var skill: Skill = skill_context.skill
    var target_unit: BaseUnit = area.owner

    # print("---------- %s" % target_unit.title)
    # print("---------- %s, skill state %s, skill buff_map state %s, " % [skill.title, is_instance_valid(skill), is_instance_valid(skill.buff_map.values())])
    # print("%s---------- %s" % [str((area.owner as BaseUnit).player_group), str(SOS.main.player_controller.player_group_idx)])

    if area.owner is BaseUnit and (area.owner as BaseUnit).player_group != SOS.main.player_controller.player_group_idx:
        for buff: Buff in skill.buff_map.values():
            # print("---------- %s, buff state %s" % [skill.title, is_instance_valid(buff)])
            SystemUtil.buff_system.apply(buff, target_unit)

func _on_area_3d_area_exited(area: Area3D, skill_context):
    var skill: Skill = skill_context.skill
    var target_unit: BaseUnit = area.owner

    if area.owner is BaseUnit and (area.owner as BaseUnit).player_group != SOS.main.player_controller.player_group_idx:
        for buff: Buff in area.owner.buff_map.values():
            SystemUtil.buff_system.remove(buff, target_unit)