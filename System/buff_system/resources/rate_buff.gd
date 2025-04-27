extends Buff


func _ready() -> void:
    super._ready()


    # 每秒执行某个任务



# 监听单位死亡事件
func _on_unit_logic_death(unit: BaseUnit) -> void:
    queue_free()



func _on_rate_buff_ticked(unit: BaseUnit):
    var prop_val = unit.get(prop)

    if value_unit == BuffResource.VALUE_UNIT.PERCENT:
        # if CommonUtil.is_flag_set(BuffResource.BUFF_TYPE.BUFF, type):
            ref_val += ref_val * value / 100 * value_dir

        # if CommonUtil.is_flag_set(BuffResource.BUFF_TYPE.DEBUFF, type):
            # ref_val -= ref_val * value / 100 * value_dir

    elif value_unit == BuffResource.VALUE_UNIT.VALUE:
        # if CommonUtil.is_flag_set(BuffResource.BUFF_TYPE.BUFF, type):
            ref_val += value * value_dir

        # if CommonUtil.is_flag_set(BuffResource.BUFF_TYPE.DEBUFF, type):
            # ref_val -= value * value_dir


    unit.set(prop, ref_val)

