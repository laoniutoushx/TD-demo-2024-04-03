class_name Buff extends Node



# Reference
var unit: BaseUnit
var target: BaseUnit
var item_res: ItemResource
var slot: BaseSlot

## Item 效果（属性提升，buff 叠加，技能释放，状态转变）



# basic properity
@export_group("Item Meta Steup")
@export var id: StringName
@export var code: String
@export var sort: int

## buff 类型（可以同时否和多个类型
@export_flags("BUFF", "DEBUFF", "DAMAGE", "HEAL", "RESTRICT", "STATUS") var type

@export var title: String
@export var desc: String
@export var icon_path: String


@export var buff_script: Script
var buff_script_instance: Variant


# Timer
var cool_down_timer: Timer


## Item 逻辑处理
