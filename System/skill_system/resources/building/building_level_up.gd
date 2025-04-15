class_name BuildingLevelUp extends Node3D





func action(skill_context: SkillContext) -> void:
    # 播放施法动画 & 声音
    var skill: Skill = skill_context.skill
    var source_unit: BaseUnit = skill_context.source
    var target_unit: BaseUnit = skill_context.target

    var unit_res: BaseUnitResource = skill.skill_meta_res.building_res

    var unit_id = source_unit.get_instance_id()




    # ui相关处理（升级中，升级动画，升级提示，升级完成）
    # 升级中，开启倒计时，锁定单位
    source_unit.change_state(Turret.TurretState.FREEZEING)


    # await 升级完成（完成单位替换，隐藏旧单位，添加新单位）
    var cimer = CommonUtil.create_timer(skill.building_level_up_time, func(): pass, CONNECT_PERSIST)

    # 设置进度条最大值

    var _action_bar = SOS.main.level_controller._cur_scene.action_bar

    var callback: Callable = (
        func(_cimer, _skill, _unit_id, _action_bar): 
            if _action_bar.active_unit and unit_id == _action_bar.active_unit.get_instance_id():
                _action_bar.progress_util_bar.update_util_bar(_cimer.time_left, _skill.building_level_up_time)
    ).bind(cimer, skill, unit_id, _action_bar)

    cimer.bind_callback(callback)
    add_child(cimer)
    cimer.start()

    await cimer.timeout

    # 升级完成，替换单位
    print("升级完成，替换单位")

    # 实例化新单位
    var unit_inst: Turret = SystemUtil.unit_system.create_unit(unit_res, SOS.main.player_controller.player_group_idx)
    


    # 逻辑死亡
    source_unit.hide()
    source_unit.do_logical_death()

    
    SOS.main.level_controller._cur_scene.turret_manager.add_child(unit_inst)
    unit_inst.global_position = source_unit.global_position

    # 单位状态切换
    unit_inst.change_state(Turret.TurretState.IDLE)

    # 关闭进度条
    SOS.main.level_controller._cur_scene.action_bar.progress_util_bar.close()



