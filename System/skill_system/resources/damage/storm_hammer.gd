class_name StormHammer extends Node3D





func action(skill_context: SkillContext) -> void:
    # 播放施法动画 & 声音
    var skill: Skill = skill_context.skill
    var source_unit: BaseUnit = skill_context.source
    var target_unit: BaseUnit = skill_context.target


    # 初始数量
    var init_num: int = skill.init_num
    var target_position: Vector3 = skill_context.target_position

    for i in init_num:
        var handler = InnerHandler.new(skill_context)
        add_child(handler)
        handler.projection_handler(target_position)

        await handler.finished

        handler.queue_free()





class InnerHandler extends Node3D:
    signal finished()

    var skill_context: SkillContext
    var vfx
    var skill: Skill
    var source_unit: BaseUnit
    var target_unit: BaseUnit

    # 在 _process 函数中添加一个变量
    var move_progress: float = 0.0

    func _init(skill_context: SkillContext) -> void:
        self.skill_context = skill_context
        skill = skill_context.skill
        source_unit = skill_context.source
        target_unit = skill_context.target

    func projection_handler(point: Vector3) -> void:


        vfx = SystemUtil.vfx_system.create_vfx("hammer", SystemUtil.vfx_system.VFX_TYPE.RUNNING)
        vfx.global_position = Vector3(source_unit.global_position.x, 3, source_unit.global_position.z)
        # vfx.rotate_z(90)
        vfx.look_at(target_unit.global_position)

        self.add_child(vfx)

        # var tween = create_tween()
        # tween.tween_property(vfx, "global_position", target_unit.global_position, 0.5)
        # await tween.finished



    func _process(delta):
        if target_unit:
            move_progress = min(1.0, move_progress + skill.projection_speed * delta) # 限制在 0 到 1 之间
            var target_pos = Vector3(target_unit.global_position.x, CommonUtil.get_scaled_aabb_height(target_unit) / 2, target_unit.global_position.z)
            vfx.look_at(target_pos)
            vfx.global_position = vfx.global_position.lerp(target_pos, move_progress) # vfx.global_position.lerp(target_unit.global_position, ease(move_progress, 1.0)) # ease(progress, curve)
            # vfx.global_position = vfx.global_position.lerp(target_unit.global_position, move_progress) # ease(progress, curve)

            if move_progress >= 0.97: # 使用 move_progress 判断是否到达
                print("击中目标！")
                finished.emit()