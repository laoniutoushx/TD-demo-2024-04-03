class_name FireRain extends Node3D





func action(skill_context: SkillContext) -> void:
    # 播放施法动画 & 声音
    var skill: Skill = skill_context.skill
    var source_unit: BaseUnit = skill_context.source
    var target_unit: BaseUnit = skill_context.target


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
   
    var tween: Tween
    for point in points:
        var handler = InnerHandler.new(skill_context)
        add_child(handler)
        handler.vfx_handler(point)

  


    # SystemUtil.damage_system.skill_damage(skill, source_unit, target_unit)

    # await CommonUtil.await_timer(2.0)
    
    # if is_instance_valid(vfx):
    #     vfx.queue_free()


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

        SystemUtil.damage_system.skill_range_damage(skill_context.skill, skill_context.source, point, 10.0)

        # await CommonUtil.await_timer(2.0)
        
        if is_instance_valid(vfx):
            vfx.queue_free()
