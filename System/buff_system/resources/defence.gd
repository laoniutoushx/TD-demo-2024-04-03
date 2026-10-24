extends Buff


var _vfx

func _ready() -> void:
    super._ready()
    _vfx = SystemUtil.vfx_system.create_vfx("force_field", VFXSystem.VFX_TYPE.RUNNING)
    if is_instance_valid(unit):
        unit.unit_take_damage_regist.emit(_on_take_damge_logic)
        if is_instance_valid(_vfx):
            add_child(_vfx)
            _vfx.position.y = unit._height / 2

# 空接口， buff 自己实现内部逻辑
func refresh() -> void:
    super.refresh()

    if reference_instance:
        value = reference_instance.value



func _exit_tree() -> void:
    if is_instance_valid(unit):
        unit.unit_take_damage_unregist.emit(_on_take_damge_logic)

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
