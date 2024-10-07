class_name Skill extends Node

# Reference
var skill_meta: SkillMeta
var unit: BaseUnit


# meta info 
@export var id: String
@export var title: String = "Unnamed Skill"
@export var desc: String
@export var icon_name: String
@export var icon_idx: int
@export var level: int = 0
@export var max_level: int = 3

# 冷却时间
@export var cooldown: float = 1.0
# 魔法消耗
@export var mana_cost: float = 10.0
# 技能范围
@export var range: float = 5.0
# 释放距离
@export var release_distance: float 
# 技能点数（使用次数）
@export var stock: int  = 1

# consume 消耗
# level up 
# release skill


@export var release_type: SkillMeta.SKILL_RELEASE_TYPE
@export var target_type: SkillMeta.SKILL_RELEASE_TYPE	# 0: 地面, 1: 目标, 2: 无目标
# define how unit move on mesh ground( walk/fly )
@export var target_move_type = 0
# define unit category (  HUMAN/BUILDING/DECORATE_DESTORIED/DECORATE_FOREVER )
@export var target_cate = 0


# Skill Script Template( ClassDB )
@export var script_name: Script


func _ready() -> void:
	id = skill_meta.id
