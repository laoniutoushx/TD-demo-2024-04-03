extends Buff


var _vfx

var attack_num_increase: int = 0

func _ready() -> void:
    super._ready()


    refresh()
        

# 空接口， buff 自己实现内部逻辑
func refresh() -> void:
    if unit and unit.is_alive():
        attack_num_increase = reference_instance.value - unit.attack_num
        unit.attack_num = reference_instance.value 



func _exit_tree() -> void:
    super._exit_tree()

    # 恢复单位攻击数量
    if unit and unit.is_alive():
        unit.attack_num = unit.attack_num - attack_num_increase

    # 移出 vfx 从单位
    # if _vfx and is_instance_valid(_vfx):
    #     _vfx.queue_free()


# 监听单位死亡事件
func _on_unit_logic_death(unit: BaseUnit) -> void:
    # 移出 vfx 从单位
    # _vfx.queue_free()

    queue_free()