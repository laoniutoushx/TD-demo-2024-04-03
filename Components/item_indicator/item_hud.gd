extends Node3D



@onready var _sprite_3d: Sprite3D = %Sprite3D
@onready var sub_viewport: SubViewport = %SubViewport
@onready var item_hud_2d: Control = %ItemHud2D


func _ready() -> void:
    pass


func steup(treasure_chest: TreasureChest) -> void:
    var drop_item: DropItem = treasure_chest.drop_item

    # 返回
    if drop_item == null:
        return


    var item_res: ItemResource = CommonUtil.get_resource(drop_item.item_name, ItemSystem.ItemManager.container())

    if item_res:
        # 设置物品名称
        item_hud_2d.title.text = item_res.title
        item_hud_2d.desc.text = item_res.desc
        item_hud_2d.detail_list.text = item_res.icon_path


    resize(treasure_chest)



func resize(treasure_chest: TreasureChest) -> void:
    # 调整 sub_viewport 的大小
    sub_viewport.size = Vector2i(item_hud_2d.container.size.x, item_hud_2d.container.size.y)

    # 调整 整体底部位置
    # self.position.y = (treasure_chest._height) * 1.25   
    simple_position_above_node(treasure_chest, _sprite_3d)



# 方法2：更简单的定位方式（如果你知道宝箱的确切高度）
func simple_position_above_node(treasure_chest: TreasureChest, sprite_3d: Sprite3D) -> void:
    """简化版本的定位方法"""
    # 获取宝箱的高度
    var chest_height: float = treasure_chest._height if treasure_chest.has_method("_height") else 1.0
    
    # 获取 Sprite3D 的高度
    var sprite_height: float = get_sprite3d_world_height(sprite_3d)
    
    # 计算目标位置
    # 宝箱顶部 + Sprite3D 高度的一半（因为 Sprite3D 的锚点在中心）
    var target_y: float = treasure_chest.global_position.y + chest_height + sprite_height
    
    # 设置最终位置
    self.global_position = Vector3(
        treasure_chest.global_position.x,
        target_y,
        treasure_chest.global_position.z
    )


func get_sprite3d_world_height(sprite_3d: Sprite3D) -> float:
    """获取 Sprite3D 在世界空间中的高度"""
    if not sprite_3d.texture:
        return 1.0
    
    var texture_height: float = sprite_3d.texture.get_height()
    var pixel_size: float = sprite_3d.pixel_size
    
    # Sprite3D 的世界高度 = 纹理高度 * 像素大小 * 缩放
    var world_height: float = texture_height * pixel_size * sprite_3d.scale.y
    
    return world_height    