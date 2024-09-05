extends Resource
class_name ItemResource

# Class Template


# basic properity
@export var id: String = UUID.v4()
@export var code: String
@export var name: String
@export var icon: Texture2D
@export var model: PackedScene
@export var description:String
# 分类
@export_flags("WEAPON", "CLOTHING", "SHOES", "JEWELRY", "OTHER") var category
# 特性
@export_flags("EXPENDABLE", "UNUSED") var nature  
# 起始位置
@export var borning_position: Vector3



# skill table
