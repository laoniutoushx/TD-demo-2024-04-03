class_name Buff extends BuffTpl



# Reference
var entity: String     # 引用实例  (e.g. BaseUnit/Skill/LevelComp/Item/Buff)
var prop: String        # 实例对应属性名称

var ref: Variant        # 引用实例



# basic properity
@export_group("Buff Meta Steup")
@export var id: StringName
@export var code: String


## buff 类型（可以同时符合多个类型）
@export_flags("BUFF", "DEBUFF", "RESTRICT", "STATUS") var type

@export var title: String
@export var desc: String
@export var icon_path: String


# buff properity
# 值单位类型
@export var value: float
@export var value_unit: BuffResource.VALUE_UNIT



@export var priority: int   # 优先级
@export var exclude_level: BuffResource.EXCLUDE_LEVEL = BuffResource.EXCLUDE_LEVEL.ALL   # 排除级别（叠加方式）




# buff logic action
@export var buff_script: Script
var buff_script_instance: Variant


# Timer
var cool_down_timer: Timer


