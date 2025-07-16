class_name IceStorm extends Node3D





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

        CommonUtil.play_audio(source_unit, "冰雨坠落_爱给网_aigei_com", 1)
        
        var idx = 0
        while points.size() < init_num:
            var angle = randf() * TAU
            var distance = randf() * radius
            var new_point = target_position + Vector3(cos(angle) * distance, 0, sin(angle) * distance)
            points.append(new_point)
            

            # 释放
            var handler = InnerHandler.new(skill_context)
            add_child(handler)
            handler.vfx_handler(idx, new_point)
            idx += 1



        if wave < skill.wave - 1:
            await CommonUtil.await_timer(skill.internal_time)



class InnerHandler extends Node3D:
    var skill_context: SkillContext

    func _init(skill_context: SkillContext) -> void:
        self.skill_context = skill_context

    func vfx_handler(idx: int, point: Vector3) -> void:
        var vfx = SystemUtil.vfx_system.create_vfx("ice_prise", SystemUtil.vfx_system.VFX_TYPE.RUNNING)

        # vfx.rotate_x(90)
        
        self.add_child(vfx)
        # 注意全局位置设置（必须在 add_child 生效之后）
        vfx.global_position = Vector3(point.x, 30, point.z)

        
        var tween: Tween = create_tween()
        tween.tween_property(vfx, "global_position", point, 1)
        await tween.finished

        if idx == 0:    # 只为第一个点播放特效声音
            CommonUtil.play_audio(self, "魔法 魔术 冰 冲击_ 大的 炮弹_ 危险冰块_ 碎片_ 长_爱给网_aigei_com", 1)
        var affect_unit_in_range = SystemUtil.damage_system.skill_range_damage(skill_context.skill, skill_context.source, point, skill_context.skill.damage_range)
        for au in affect_unit_in_range:
            var bf = CommonUtil.get_first_value(skill_context.skill.buff_map)
            SystemUtil.buff_system.apply(bf, au)

        # await CommonUtil.await_timer(2.0)
        
        if is_instance_valid(vfx):
            vfx.queue_free()

        var vfx_destory = SystemUtil.vfx_system.create_vfx("ice_prise", SystemUtil.vfx_system.VFX_TYPE.DESTORY)
        if vfx_destory:
            self.add_child(vfx_destory)

            # vfx_destory.look_at(point)
            # vfx_destory.rotate_z(90)
            vfx_destory.global_position = point 

            await CommonUtil.await_timer(1.0)

            if is_instance_valid(vfx_destory):
                vfx_destory.queue_free()