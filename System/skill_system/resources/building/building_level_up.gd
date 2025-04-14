class_name BuildingLevelUp extends Node3D





func action(skill_context: SkillContext) -> void:
    # 播放施法动画 & 声音
    var skill: Skill = skill_context.skill
    var source_unit: BaseUnit = skill_context.source
    var target_unit: BaseUnit = skill_context.target

    var unit_res: BaseUnitResource = skill.skill_meta_res.building_res


    # 实例化新单位
    var unit_inst: BaseUnit = SystemUtil.unit_system.create_unit(unit_res, SOS.main.player_controller.player_group_idx)

    # ui相关处理（升级中，升级动画，升级提示，升级完成）
    # 升级中，开启倒计时


    # await 升级完成（完成单位替换，隐藏旧单位，添加新单位）
    var cimer = CommonUtil.create_timer(skill.building_level_up_time, func(): pass, CONNECT_PERSIST)

    # 设置进度条最大值

    SOS.main.level_controller._cur_scene.action_bar.progress_util_bar.steup(skill.building_level_up_time)


    var callback: Callable = (func(_cimer): SOS.main.level_controller._cur_scene.action_bar.progress_util_bar.update_util_bar(_cimer.time_left)).bind(cimer)

    cimer.bind_callback(callback)

    add_child(cimer)

    cimer.start()

    await cimer.timeout

    # 升级完成，替换单位
    print("升级完成，替换单位")



