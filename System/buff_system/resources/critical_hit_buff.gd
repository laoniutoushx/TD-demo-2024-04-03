extends Buff



func _ready() -> void:
    super._ready()

    # 注册单位 damage 回调
    if unit and unit.is_alive():
        unit.unit_action_damage_regist.emit(_on_action_damge_logic)
        
# 暴击逻辑（回调注入）
func _on_action_damge_logic(damage_ctx: DamageCtx) -> DamageCtx:

    if _prob_controller.next():
        # 触发暴击
        damage_ctx.damage_type = DamageCtx.DamageType.CRITICAL
        damage_ctx.damage = damage_ctx.damage * reference_instance.value_ext.get("critical_multiplier")
        return damage_ctx
    else:
        pass

    return damage_ctx


func _exit_tree() -> void:
    super._exit_tree()

    # 恢复单位移动（process false）
    if unit and unit.is_alive():
        unit.unit_action_damage_unregist.emit(_on_action_damge_logic)



# 监听单位死亡事件
func _on_unit_logic_death(unit: BaseUnit) -> void:
    unit.unit_action_damage_unregist.emit(_on_action_damge_logic)
    queue_free()