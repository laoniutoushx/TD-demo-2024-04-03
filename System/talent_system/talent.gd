class_name Talent extends Node



var unit: BaseUnit
var target: BaseUnit
var item_res: ItemResource
var slot: BaseSlot
var chest: TreasureChest


# basic properity
@export_group("Talent Meta Steup")
@export var id: String = UUID.v4()
@export var code: String
@export var title: String
@export var desc: String
@export var icon_path: String



# Talent Script Template( 用于 动态 处理 Talent 逻辑 )
@export var talent_script: Script



# Talent Script Template( 用于 动态 处理 Talent 逻辑 )
var talent_res: TalentResource
var talent_script_instance: Variant



# Timer
var cool_down_timer: Timer