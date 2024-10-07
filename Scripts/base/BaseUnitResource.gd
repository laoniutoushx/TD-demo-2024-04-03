class_name BaseUnitResource
extends Resource

@export_group("Unit Steup")
# meta config
@export var clz_code: String
@export var clz_name: String
@export var model_path: PackedScene	# model like glb, gltf...

@export var icon_path: String


# define how unit move on mesh ground
@export_flags("WALK", "FLYING", "SWIM") var unit_move_type: int = 0
# define unit category
@export_flags("HUMAN", "BUILDING", "DECORATE_DESTORIED", "DECORATE_FOREVER") var unit_cate = 0
# armor
@export var armor_amount: float
@export_flags("INVINCIBLE", "NORMAL", "HERO") var armor_type = 0

# create mesh outline
@export var is_mesh_outline: bool = false
@export var is_mesh_standing: bool = false


@export var max_health : float
@export var move_speed : float
@export var turn_speed : float
@export var attack_speed : float

# FightRegion
@export var vfx_projectile_name: String

# ANIMATION
@export var anim_run = Constants.ANIM_RUN
@export var anim_walk = Constants.ANIM_WALK
@export var anim_idle = Constants.ANIM_IDEL
@export var anim_death = Constants.ANIM_DEATH

# Action Behavior
@export_group("Action")
@export var is_selected_circle: bool = true

# Component - 组件系统预定义
@export_group("System Component")
@export_flags("VFX", "ITEM", "DAMAGABLE", "BARRAGE") var component_system = 0

# Item related
@export_group("Item")
# 拾取速度
@export var pickup_velocity := 1000.0

# Skill related
@export_group("Skill")
@export var skills: Array[SkillMeta] = []
