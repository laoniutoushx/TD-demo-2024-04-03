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

        # player audio
        CommonUtil.play_audio(source_unit, "雷神之锤技巧(Leishenzhichui_SkillC)_爱给网_aigei_com")
        handler.projection_handler(target_position)


        # handler.queue_free()


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
        self.add_child(vfx)
        vfx.global_position = Vector3(source_unit.global_position.x, target_unit._height / 2, source_unit.global_position.z)
        
        await finished
        vfx.queue_free()

        # 销毁特效
        var vfx1 = SystemUtil.vfx_system.create_vfx("hammer", SystemUtil.vfx_system.VFX_TYPE.DESTORY)
        vfx1.position.y = target_unit._height / 2
        # print(target_unit.global_transform.basis.get_scale())
        vfx1.scale = target_unit.global_transform.basis.get_scale()
        target_unit.add_child(vfx1)

        # 造成伤害（单位逻辑死亡，则返回）
        SOS.main.damage_system.skill_damage(skill, source_unit, target_unit)

        # stun buff
        if target_unit.is_alive():
            for buff: Buff in skill.buff_map.values():
                # print("---------- %s, buff state %s" % [skill.title, is_instance_valid(buff)])
                SystemUtil.buff_system.apply(buff, target_unit)

        # 播放音效(魔法击中)
        CommonUtil.play_audio(target_unit, "魔法击中-YS070510_爱给网_aigei_com")


        # 等待销毁特性播放完毕
        await vfx1.tree_exited
        vfx1.queue_free()



        

        







    # func _process(delta):
    #     if target_unit:
    #         # 计算移动方向
    #         var target_pos = Vector3(target_unit.global_position.x, target_unit._height / 2, target_unit.global_position.z)
    #         var direction = (target_pos - vfx.global_position).normalized()

    #         vfx.look_at(target_pos, Vector3.FORWARD)
    #         # 物体 A 的 X 轴已经面向目标，然而 A 的默认方向是沿 Z 轴朝前
	#         # 如果需要使用 X 轴，先进行一个旋转调整
    #         vfx.rotate_object_local(Vector3(-1, 0, 0), deg_to_rad(90))
    #         vfx.global_position += (direction * delta * skill.projection_speed)
            
    #         # vfx.global_position = vfx.global_position.lerp(target_pos, move_progress) # vfx.global_position.lerp(target_unit.global_position, ease(move_progress, 1.0)) # ease(progress, curve)
    #         # vfx.global_position = vfx.global_position.lerp(target_unit.global_position, move_progress) # ease(progress, curve)

    #         if vfx.global_position.distance_to(target_pos) < 0.1:
    #             print("击中目标！")
    #             finished.emit()


    func _process(delta):
        if target_unit:
            # 计算目标点的位置
            var target_pos = Vector3(target_unit.global_position.x, target_unit._height / 2, target_unit.global_position.z)
            
            # 计算移动方向
            var direction = (target_pos - vfx.global_position).normalized()

            # 使用 look_at 让物体 A 的 X 轴朝向目标
            vfx.look_at(target_pos, Vector3.FORWARD)
            
            # 进行旋转调整，如果物体的默认方向不是你期望的
            vfx.rotate_object_local(Vector3(-1, 0, 0), deg_to_rad(90))
            vfx.rotate_object_local(Vector3(0, 1, 0), deg_to_rad(90))

            # 更新物体位置
            vfx.global_position += direction * delta * skill.projection_speed

            # 判断物体是否接近目标
            var remaining_distance = vfx.global_position.distance_to(target_pos)

            # 判断是否接近目标并且方向正确
            if remaining_distance < 1:
                set_process(false)
                # print("击中目标！")
                finished.emit()
                
