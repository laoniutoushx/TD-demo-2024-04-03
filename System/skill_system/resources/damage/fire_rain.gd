class_name RagePower extends Node3D





func action(skill_context: SkillContext) -> void:
    # 播放施法动画 & 声音
    var skill: Skill = skill_context.skill
    var source_unit: BaseUnit = skill_context.source
    var target_unit: BaseUnit = skill_context.target


    for wave in range(skill.wave):

        # 初始数量
        var init_num: int = skill.init_num
        var target_position: Vector3 = skill_context.target_position

        var points = []
        var radius = skill.range

        while points.size() < init_num:
            var angle = randf() * TAU
            var distance = randf() * radius
            var new_point = target_position + Vector3(cos(angle) * distance, 0, sin(angle) * distance)
            points.append(new_point)
    
        for point in points:
            var handler = InnerHandler.new(skill_context)
            add_child(handler)
            handler.vfx_handler(point)

        if wave < skill.wave - 1:
            await CommonUtil.await_timer(skill.internal_time)



class InnerHandler extends Node3D:
    var skill_context: SkillContext

    func _init(skill_context: SkillContext) -> void:
        self.skill_context = skill_context

    func vfx_handler(point: Vector3) -> void:
        var vfx = SystemUtil.vfx_system.create_vfx("fireball_another", SystemUtil.vfx_system.VFX_TYPE.RUNNING)

        vfx.global_position = Vector3(point.x, 30, point.z)
        # vfx.rotate_x(90)

        self.add_child(vfx)
        
        var tween: Tween = create_tween()
        tween.tween_property(vfx, "global_position", point, 1)
        await tween.finished

        SystemUtil.damage_system.skill_range_damage(skill_context.skill, skill_context.source, point, skill_context.skill.damage_range)

        # await CommonUtil.await_timer(2.0)
        
        if is_instance_valid(vfx):
            vfx.queue_free()

        var vfx_destory = SystemUtil.vfx_system.create_vfx("fireball_another", SystemUtil.vfx_system.VFX_TYPE.DESTORY)
        vfx_destory.look_at(point)
        vfx_destory.global_position = point
        vfx_destory.rotate_z(90)
        self.add_child(vfx_destory)

        await CommonUtil.await_timer(1.0)

        if is_instance_valid(vfx_destory):
            vfx_destory.queue_free()