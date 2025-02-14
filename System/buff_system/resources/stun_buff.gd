extends Buff


var _vfx

func _ready() -> void:
    super._ready()


    # 停止单位移动（process false）
    if unit and unit.is_alive():
        unit.change_state(Enemy.EnemyState.STUN)

        # 监听单位死亡事件
        unit.logical_death.connect(_on_unit_logic_death)

        # 添加 vfx 到单位
        _vfx = SystemUtil.vfx_system.create_vfx("stunvfx", SystemUtil.vfx_system.VFX_TYPE.RUNNING)

        # 高度获取
        var height = unit._height
        _vfx.position.y += height

        unit.add_child(_vfx)

    # await ready

    # if unit:
    #     # unit.call_deferred("add_child", _vfx)
    #     unit.add_child(_vfx)



func _exit_tree() -> void:
    super._exit_tree()

    # 恢复单位移动（process false）
    if unit is Enemy:
        if unit.is_alive():
            unit.change_state(Enemy.EnemyState.WALKING)
        else:
            unit.change_state(Enemy.EnemyState.DEAD)

    # 移出 vfx 从单位
    if _vfx and is_instance_valid(_vfx):
        _vfx.queue_free()


# 监听单位死亡事件
func _on_unit_logic_death(unit: BaseUnit) -> void:
    # 移出 vfx 从单位
    _vfx.queue_free()

    queue_free()