extends Buff


var _vfx

func _ready() -> void:
    super._ready()

    # 停止单位移动（process false）
    if reference_instance is Enemy:
        reference_instance.change_state(Enemy.EnemyState.STUN)

    
    # 添加 vfx 到单位
    _vfx = SystemUtil.vfx_system.create_vfx("stunvfx", SystemUtil.vfx_system.VFX_TYPE.RUNNING)

    # 高度获取
    if reference_instance is BaseUnit or reference_instance is Enemy:
        var height = reference_instance._height
        _vfx.position.y += height


    

    await ready
    # reference_instance.call_deferred("add_child", _vfx)
    reference_instance.add_child(_vfx)



func _exit_tree() -> void:
    super._exit_tree()

    
    # 恢复单位移动（process false）
    if reference_instance is Enemy:
        reference_instance.change_state(Enemy.EnemyState.WALKING)

    # 移出 vfx 从单位
    _vfx.queue_free()