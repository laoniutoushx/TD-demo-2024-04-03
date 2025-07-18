extends Buff


var _vfx

func _ready() -> void:
    super._ready()

    
    # 添加 vfx 到单位
    _vfx = SystemUtil.vfx_system.create_vfx("force_field", SystemUtil.vfx_system.VFX_TYPE.RUNNING).duplicate()



    # 高度获取
    if unit:
        var height = unit._height
        _vfx.position.y = height / 2

        # 注册伤害逻辑
        unit.unit_take_damage_regist.emit(_on_take_damge_logic)


    await ready
    # reference_instance.call_deferred("add_child", _vfx)
    unit.add_child(_vfx)



# 空接口， buff 自己实现内部逻辑
func refresh() -> void:
    super.refresh()

    if reference_instance:
        value = reference_instance.value



func _exit_tree() -> void:
    unit.unit_take_damage_unregist.emit(_on_take_damge_logic)

    # play death animation
    var ap: AnimationPlayer = CommonUtil.get_first_node_by_node_type(_vfx, Constants.AnimationPlayer_CLZ)
    ap.animation_finished.connect(_on_animation_player_animation_finished, CONNECT_ONE_SHOT)
    ap.play("death")
    await ap.animation_finished




# 防御值逻辑（回调注入）
func _on_take_damge_logic(damage_ctx: DamageCtx) -> DamageCtx:
    value = value - damage_ctx.damage

    if value <= 0:
        damage_ctx.damage = abs(value)

        SystemUtil.buff_system.remove(self, unit)
        return damage_ctx

    # 伤害值小于 防御值（不处理）
    damage_ctx.damage = 0
    return damage_ctx


# 自动kill
func _on_animation_player_animation_finished(anim_name:StringName) -> void:
    if anim_name == "death":
        super._exit_tree()

