class_name BuildingLevelUp extends Node3D





func action(skill_context: SkillContext) -> void:
    # 播放施法动画 & 声音
    var skill: Skill = skill_context.skill
    var source_unit: BaseUnit = skill_context.source
    var target_unit: BaseUnit = skill_context.target

    var unit_res: BaseUnitResource = skill.skill_meta_res.building_res

    var unit_id = source_unit.get_instance_id()
    var generation = SOS.main.level_controller.session_id




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


    # 创建升级特效
    var vfx_leveling_up = SystemUtil.vfx_system.create_vfx("leveling_up_circle", SystemUtil.vfx_system.VFX_TYPE.RUNNING)
    source_unit.add_child(vfx_leveling_up)

    # 创建升级特效
    vfx_leveling_up = SystemUtil.vfx_system.create_vfx("leveling_up_arrow", SystemUtil.vfx_system.VFX_TYPE.RUNNING)
    source_unit.add_child(vfx_leveling_up)
    vfx_leveling_up.position = Vector3(vfx_leveling_up.position.x, source_unit._height, vfx_leveling_up.position.z)


    await cimer.timeout
    if not SystemUtil.skill_system._session_valid(generation, source_unit) or not source_unit.is_alive(): return

    # 升级完成，替换单位
    print("升级完成，替换单位")

    # 实例化新单位
    var unit_inst: Turret = SystemUtil.unit_system.create_unit(unit_res, SOS.main.player_controller.player_group_idx)
    


    # 逻辑死亡
    SOS.main.level_controller._cur_scene.turret_manager.add_child(unit_inst)
    unit_inst.global_position = source_unit.global_position
    unit_inst.unit_uid = source_unit.unit_uid
    SystemUtil.item_system.transfer_all(source_unit, unit_inst)
    var old_level = SystemUtil.unit_system.get_component_from_unit(source_unit, BaseUnitResource.COMPONENT_SYSTEM.LEVEL)
    var new_level = SystemUtil.unit_system.get_component_from_unit(unit_inst, BaseUnitResource.COMPONENT_SYSTEM.LEVEL)
    if is_instance_valid(old_level) and is_instance_valid(new_level):
        for property in ["level", "exp", "level_up_experience", "relife"]: new_level.set(property, old_level.get(property))
    for code in source_unit.skill_map:
        if unit_inst.skill_map.has(code):
            var old_skill: Skill = source_unit.skill_map[code]
            var new_skill: Skill = unit_inst.skill_map[code]
            if old_skill.cool_down_timer.time_left > 0 and old_skill.cooldown > 0:
                new_skill.current_state = Skill.SKILL_STATE.Cool_Down
                new_skill.cool_down_timer.start(maxf(0.001, old_skill.cool_down_timer.time_left / old_skill.cooldown * new_skill.cooldown))
                new_skill.cool_down_timer.timeout.connect(new_skill.change_state.bind(Skill.SKILL_STATE.Idle), CONNECT_ONE_SHOT)
    var manager = SOS.main.level_controller._cur_scene.turret_manager
    manager.replace_building(source_unit, unit_inst)
    var was_selected = PlayerController.PlayerSelect.contains_unit(source_unit)
    source_unit.do_logical_death("upgrade")
    if was_selected:
        var selected_units = PlayerController.PlayerSelect.unit_map()
        selected_units.erase(source_unit.get_instance_id())
        selected_units[unit_inst.get_instance_id()] = unit_inst
        SOS.main.player_controller.refresh_selection_units(selected_units, unit_inst.global_position, PlayerController.PLAYER_STATUS.DEFAULT)

    # 单位状态切换
    unit_inst.change_state(Turret.TurretState.IDLE)

    # 关闭进度条
    SOS.main.level_controller._cur_scene.action_bar.progress_util_bar.close()
    
    # 创建升级特效
    var vfx = SystemUtil.vfx_system.create_vfx("LV_Up_style_b", VFXSystem.VFX_TYPE.BURNING)
    unit_inst.add_child(vfx)





