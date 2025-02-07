class_name BuildingBaseTurret extends Node3D





func action(skill_context: SkillContext) -> void:
    # 播放施法动画 & 声音
    var skill: Skill = skill_context.skill
    var source_unit: BaseUnit = skill_context.source
    var target_unit: BaseUnit = skill_context.target


    # 技能释放
    var building: BaseUnit = skill_context.building
    var gp = skill_context.building.global_position
    # building.position = Vector3(origin_p.x, 100, origin_p.z)
    var vfx = SystemUtil.vfx_system.create_vfx("build_located", VFXSystem.VFX_TYPE.RUNNING)
    building.add_child(vfx)
    
    building.global_position = Vector3(gp.x, 30.0, gp.z)

    var tween: Tween = create_tween()
    tween.set_ease(Tween.EASE_OUT)
    tween.set_trans(Tween.TRANS_EXPO)  # 使用指数曲线让效果更明显
    tween.tween_property(building, "global_position", gp, 1)

    # TODO 逻辑耦合 buliding turret
    await tween.finished

    # player building place audio
    CommonUtil.play_audio(source_unit, "building-placing")

    # 创建 AudioStreamPlayer 节点
    # var audio_player = AudioStreamPlayer.new()

    skill_context.callback.call()
    # fixed bug when player building another turret（status changed to building）
    building.change_state(Turret.TurretState.IDLE)

    # remove vfx
    CommonUtil.delay_execution(0.3, func(): if is_instance_valid(vfx): vfx.queue_free())

