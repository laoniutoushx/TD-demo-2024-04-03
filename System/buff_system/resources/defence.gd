extends Buff


var _vfx

func _ready() -> void:
    super._ready()



    
    # 添加 vfx 到单位
    _vfx = SystemUtil.vfx_system.create_vfx("force_field", SystemUtil.vfx_system.VFX_TYPE.RUNNING)

    # 高度获取
    if reference_instance is BaseUnit or reference_instance is Enemy:
        var height = reference_instance._height
        _vfx.position.y = height / 2

        # 注册伤害逻辑
        reference_instance.unit_take_damage_regist.emit(_on_take_damge_logic)




    await ready
    # reference_instance.call_deferred("add_child", _vfx)
    reference_instance.add_child(_vfx)



func _exit_tree() -> void:
    reference_instance.unit_take_damage_unregist.emit(_on_take_damge_logic)
    super._exit_tree()


# 防御值逻辑
func _on_take_damge_logic(damage: float) -> float:
    return damage - value