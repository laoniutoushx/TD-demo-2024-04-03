extends Buff


var _vfx

func _ready() -> void:
    super._ready()

    # 停止单位移动（process false）
    if reference_instance is BaseUnit:
        reference_instance.set_process(false)
    
    # 添加 vfx 到单位
    _vfx = SystemUtil.vfx_system.create_vfx("stun", SystemUtil.vfx_system.VFX_TYPE.RUNNING)
    _vfx.global_position = reference_instance.global_position

    # 高度获取
    if reference_instance is BaseUnit:
        var height = CommonUtil.get_scaled_aabb_height(reference_instance)
        _vfx.global_position.y += height

    add_child(_vfx)



func _exit_tree() -> void:
    super._exit_tree()

    
    # 恢复单位移动（process false）
    if reference_instance is BaseUnit:
        reference_instance.set_process(true)

    # 移出 vfx 从单位
    _vfx.queue_free()