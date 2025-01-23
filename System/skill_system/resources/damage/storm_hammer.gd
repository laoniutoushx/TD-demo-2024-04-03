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





class InnerHandler extends Node3D:
    signal finished()

    var skill_context: SkillContext
    var vfx
    var skill: Skill
    var source_unit: BaseUnit
    var target_unit: BaseUnit

    var fire_pos: Vector3
    var lerp_pos: float = 0

    func _init(skill_context: SkillContext) -> void:
        self.skill_context = skill_context
        skill = skill_context.skill
        source_unit = skill_context.source
        target_unit = skill_context.target

    func projection_handler(point: Vector3) -> void:


        vfx = SystemUtil.vfx_system.create_vfx("storm_hammer", SystemUtil.vfx_system.VFX_TYPE.RUNNING)
        vfx.global_position = source_unit.global_position
        # vfx.rotate_x(90)

        self.add_child(vfx)


    func _physics_process(delta: float) -> void:
        if lerp_pos < 1: 
            vfx.look_at(target_unit.global_position)
            var mesh_node = CommonUtil.get_first_node_by_node_type(target_unit, Constants.MeshInstance3D_CLZ)
            var aabb = CommonUtil.get_scaled_aabb(mesh_node)
            var height = aabb.size.y
            global_position = source_unit.global_position.lerp(Vector3(target_unit.global_position.x, height / 2.0, target_unit.global_position.z), lerp_pos)
            lerp_pos += delta * skill.projection_speed
        else:
            finished.emit()