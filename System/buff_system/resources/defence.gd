extends Buff


var _vfx

func _ready() -> void:
    super._ready()

    
    # 添加 vfx 到单位
    _vfx = SystemUtil.vfx_system.create_vfx("force_field", SystemUtil.vfx_system.VFX_TYPE.RUNNING)

    # 高度获取
    if unit:
        var height = reference_instance._height
        _vfx.position.y = height / 2

        # 注册伤害逻辑
        unit.unit_take_damage_regist.emit(_on_take_damge_logic)


    await ready
    # reference_instance.call_deferred("add_child", _vfx)
    unit.add_child(_vfx)



func _exit_tree() -> void:
    unit.unit_take_damage_unregist.emit(_on_take_damge_logic)
    _vfx.queue_free()
    super._exit_tree()


# 防御值逻辑
func _on_take_damge_logic(damage: float) -> float:
    value = value - damage

    if value <= 0:
        SystemUtil.buff_system.remove(self, unit)
        return abs(value)

    return 0