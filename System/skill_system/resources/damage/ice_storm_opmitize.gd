class_name IceStormOpmitize extends Node3D

# 简单的音频控制
static var last_cast_time: float = 0.0
static var audio_min_interval: float = 0.1

func action(skill_context: SkillContext) -> void:
    var skill: Skill = skill_context.skill
    var source_unit: BaseUnit = skill_context.source
    var target_unit: BaseUnit = skill_context.target

    # 异步执行避免阻塞
    _execute_waves_async(skill_context)

func _execute_waves_async(skill_context: SkillContext) -> void:
    var skill: Skill = skill_context.skill
    var source_unit: BaseUnit = skill_context.source

    for wave in range(skill.wave):
        var init_num: int = skill.init_num
        var target_position: Vector3 = skill_context.target_position
        var radius = skill.range

        # 控制音频播放频率
        var current_time = Time.get_time_dict_from_system()
        var time_seconds = current_time.hour * 3600 + current_time.minute * 60 + current_time.second
        
        if time_seconds - last_cast_time >= audio_min_interval:
            CommonUtil.play_audio(source_unit, "冰雨坠落_爱给网_aigei_com", 1)
            last_cast_time = time_seconds

        # 预生成所有坐标
        var points = _generate_points_optimized(target_position, radius, init_num)
        
        # 分批创建冰柱，但不等待完成
        _create_ice_pillars_batch(skill_context, points)

        if wave < skill.wave - 1:
            await CommonUtil.await_timer(skill.internal_time)

# 优化的点位生成
func _generate_points_optimized(center: Vector3, radius: float, count: int) -> Array[Vector3]:
    var points: Array[Vector3] = []
    points.resize(count)
    
    for i in count:
        var angle = randf() * TAU
        var distance = sqrt(randf()) * radius  # 均匀分布
        points[i] = center + Vector3(cos(angle) * distance, 0, sin(angle) * distance)
    
    return points

# 分批创建冰柱（不阻塞）
func _create_ice_pillars_batch(skill_context: SkillContext, points: Array[Vector3]) -> void:
    var batch_size = 2  # 减小批次大小
    var batch_delay = 0.03  # 减少延迟
    
    for i in points.size():
        # 直接创建，不等待
        _create_single_ice_pillar(skill_context, i, points[i])
        
        # 简单的分帧控制
        if (i + 1) % batch_size == 0 and i < points.size() - 1:
            await get_tree().create_timer(batch_delay).timeout

# 简化的单个冰柱创建
func _create_single_ice_pillar(skill_context: SkillContext, idx: int, point: Vector3) -> void:
    # 创建处理器，但使用更轻量的方式
    var handler = SimplifiedHandler.new()
    add_child(handler)
    
    # 直接开始处理，不等待返回
    handler.process_ice_pillar(skill_context, idx, point)

# 简化的处理器类
class SimplifiedHandler extends Node3D:
    func process_ice_pillar(skill_context: SkillContext, idx: int, point: Vector3) -> void:
        var vfx = SystemUtil.vfx_system.create_vfx("ice_prise", SystemUtil.vfx_system.VFX_TYPE.RUNNING)
        if not vfx:
            queue_free()
            return
            
        add_child(vfx)
        vfx.global_position = Vector3(point.x, 30, point.z)
        
        # 创建动画
        var tween = create_tween()
        tween.tween_property(vfx, "global_position", point, 1.0)
        
        # 等待动画完成后处理
        await tween.finished
        
        # 音效处理（只有第一个播放）
        if idx == 0:
            _play_impact_sound()
        
        # 伤害处理
        _apply_damage_simple(skill_context, point)
        
        # 清理运行特效
        if is_instance_valid(vfx):
            vfx.queue_free()
        
        # 创建销毁特效
        await _create_destroy_effect_simple(point)
        
        # 清理自己
        queue_free()
    
    func _play_impact_sound() -> void:
        # 简单的音效播放，避免重叠
        var current_time = Time.get_time_dict_from_system()
        var time_seconds = current_time.hour * 3600 + current_time.minute * 60 + current_time.second
        
        if time_seconds - IceStorm.last_cast_time >= 0.1:
            CommonUtil.play_audio(self, "魔法 魔术 冰 冲击_ 大的 炮弹_ 危险冰块_ 碎片_ 长_爱给网_aigei_com", 1)
    
    func _apply_damage_simple(skill_context: SkillContext, point: Vector3) -> void:
        var affect_units = SystemUtil.damage_system.skill_range_damage(
            skill_context.skill, 
            skill_context.source, 
            point, 
            skill_context.skill.damage_range
        )
        
        # 简单应用 Buff，不分帧
        var bf = CommonUtil.get_first_value(skill_context.skill.buff_map)
        for au in affect_units:
            SystemUtil.buff_system.apply(bf, skill_context.skill, au)
    
    func _create_destroy_effect_simple(point: Vector3) -> void:
        var destroy_vfx = SystemUtil.vfx_system.create_vfx("ice_prise", SystemUtil.vfx_system.VFX_TYPE.DESTORY)
        if destroy_vfx:
            add_child(destroy_vfx)
            destroy_vfx.global_position = point
            
            # 简单等待后清理
            await get_tree().create_timer(1.0).timeout
            
            if is_instance_valid(destroy_vfx):
                destroy_vfx.queue_free()