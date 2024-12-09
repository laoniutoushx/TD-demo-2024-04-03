class_name LightingChain extends Node





func action(skill_context: SkillContext) -> void:
    # 播放施法动画 & 声音
    var source_unit: BaseUnit = skill_context.source
    var target_unit: BaseUnit = skill_context.target

    if source_unit is Gdbot:
        source_unit.jump()
        await CommonUtil.await_timer(0.1)
        source_unit.fall()
        await CommonUtil.await_timer(0.1)
        source_unit.idle()

    # var at: AnimationTree = CommonUtil.get_first_node_by_node_type(source_unit, Constants.AnimationTree_CLZ)


    var ap: AnimationPlayer = CommonUtil.get_first_node_by_node_type(source_unit, Constants.AnimationPlayer_CLZ)
    var anim_release_code: String = source_unit.anim_release

    if ap != null and ap.has_animation(anim_release_code):
        ap.play(anim_release_code)

    # 等待施法前摇开始
    await CommonUtil.await_timer(skill_context.skill.start_time)


    # 技能释放
    # 特效绑定模型位置
    # 伤害触发

    # -- vfx/source_unit/target_unit handler
    var vfx = SystemUtil.vfx_system.create_vfx("lighting_chian", SystemUtil.vfx_system.VFX_TYPE.RUNNING)
    target_unit.add_child(vfx)



    pass



