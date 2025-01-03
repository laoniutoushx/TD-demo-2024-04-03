class_name Item extends Node

# Reference
var unit: BaseUnit
var target: BaseUnit
var item_res: ItemResource
var slot: BaseSlot

## Item 效果（属性提升，buff 叠加，技能释放，状态转变）



# basic properity
@export_group("Item Meta Steup")
@export var id: String = UUID.v4()
@export var code: String
@export var title: String
@export var desc: String
@export var icon: Texture2D
@export var model: PackedScene
@export var description:String


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



# 分类
@export_flags("WEAPON", "CLOTHING", "SHOES", "JEWELRY", "OTHER") var category
# 特性
@export_flags("EXPENDABLE", "UNUSED") var nature  
# 起始位置
@export var borning_position: Vector3


# Item Script Template( 用于 动态 处理 Item 逻辑 )
@export var item_script: Script


# item level config
var item_level_config: Array[Item] = []



## Item 逻辑处理
