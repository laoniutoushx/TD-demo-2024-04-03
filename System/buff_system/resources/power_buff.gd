extends Buff


func _ready() -> void:
    super._ready()


    # 停止单位移动（process false）
    if unit and unit.is_alive():

        # 监听单位死亡事件
        unit.logical_death.connect(_on_unit_logic_death)



# 监听单位死亡事件
func _on_unit_logic_death(unit: BaseUnit) -> void:
    queue_free()