class_name TreasureChest extends Node3D


@export var drop_item: DropItem


# hud 显示高度（固定值）
var _height: float = 2.5


func _ready() -> void:
    $AnimationPlayer.play("burning")



func steup(_drop_item: DropItem) -> void:
    drop_item = _drop_item



func show_selected_circle() -> void:
    var select_circle = CommonUtil.get_first_node_by_node_name(self, Constants.FadedCircle3D_CLZ)	
    if select_circle:
        select_circle.visible = true

        # 添加动效
        var tween = create_tween()
        tween.tween_property(select_circle, "radius", select_circle.radius * 1.25, 0.0)
        tween.tween_property(select_circle, "radius", select_circle.radius, 0.1)