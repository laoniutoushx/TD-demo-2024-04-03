class_name Item extends Node3D

# Reference
var unit: BaseUnit
var target: BaseUnit
var item_res: ItemResource
var slot: BaseSlot
var chest: TreasureChest

## Item 效果（属性提升，buff 叠加，技能释放，状态转变）



# basic properity
@export_group("Item Meta Steup")
@export var id: String
@export var code: String
@export var sort: int

@export var title: String
@export var desc: String
@export var icon_path: String
@export var model: PackedScene


# status
@export_group("Item Inner Steup")
# 冷却时间
@export var cooldown: float = 1.0
# 魔法消耗
@export var mana_cost: float = 10.0
# 木材消耗
@export var wood_cost: float = 10.0
# 金钱消耗
@export var money_cost: float = 10.0
@export var level: int = 1
@export var max_level: int = 3
@export var stock: int = 1
@export var value: float


@export_flags("TARGETED", "SELF_CAST", "NO_TARGET", "DIRECTION", "CIRCLE_RANGE", "PASSIVE") var release_type: int = 32


# 分类
@export_flags("WEAPON", "CLOTHING", "SHOES", "JEWELRY", "OTHER") var category
# 特性
@export_flags("EXPENDABLE", "UNUSED") var nature  
# 起始位置
@export var borning_position: Vector3


# Item Script Template( 用于 动态 处理 Item 逻辑 )
@export var item_script: Script
var item_script_instance: Variant

@export_group("Skill Buff")
# Buff（实例化后的buff列表）
var buff_map: Dictionary = {}



# Timer
var cool_down_timer: Timer



var _transformed_aabb: AABB
var _height: float = 0.0

func _ready() -> void:
	# 获取 _height

	# AABB
	# var aabb: AABB = CommonUtil.get_scaled_aabb(CommonUtil.get_first_node_by_node_type(self.get_child(0), Constants.MeshInstance3D_CLZ, false))
	# # _transformed_aabb = AABB(aabb.position * aabb_scale, aabb.size * aabb_scale)
	# _transformed_aabb = aabb.grow(1)
	# _height = aabb.size.y * 2
	pass



## Item 逻辑处理
func action(item_context: ItemContext) -> void:
	pass


