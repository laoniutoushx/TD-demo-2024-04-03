class_name BaseUnitResource
extends Resource

@export_group("Unit Steup")
# meta config
@export var clz_code: String
@export var clz_name: String
@export var model_path: PackedScene	# model like glb, gltf...

@export var title: String
@export var desc: String

@export var icon_path: String

@export_range(0.0, 1.0) var aabb_scale: float = 1	# 通过参数修正 代码获取 aabb 尺寸偏差的问题 ？？ 

enum ELEMENT_PHASE_STR{
	木,
	火,
    土,
	金,
	水
}

# define unit element phase（五行）
@export_flags("WOOD", "FIRE", "EARCH", "METAL", "WATER") var element_phase: int = 0
# define how unit move on mesh ground（移动方式）
@export_flags("WALK", "FLYING", "SWIM") var unit_move_type: int = 0
# define unit category（单位类型）
@export_flags("HUMAN", "BUILDING", "DECORATE_DESTORIED", "DECORATE_FOREVER") var unit_cate = 0

# armor（护甲）
@export var armor_amount: float
@export_flags("INVINCIBLE", "NORMAL", "HERO", "ENEMY", "FRIEND") var armor_type = 0

# create mesh outline
@export var is_mesh_outline: bool = false
@export var is_mesh_standing: bool = false


# unit cost
# 魔法消耗
@export var mana_cost: float = 10.0
# 木材消耗
@export var wood_cost: float = 10.0
# 金钱消耗
@export var money_cost: float = 10.0

# unit status

@export var max_health : float
@export var move_speed : float
@export var turn_speed : float
@export var attack_speed : float
@export var attack_range : float
@export var attack_num : int = 1

@export var attack_value: float	# 伤害值
@export var unit_growth_factor: float = 1.0     # 单位成长率



# FightRegion
@export var vfx_projectile_name: String

# ANIMATION
@export_group("Animation")
@export var anim_run = Constants.ANIM_RUN
@export var anim_walk = Constants.ANIM_WALK
@export var anim_idle = Constants.ANIM_IDEL
@export var anim_death = Constants.ANIM_DEATH


@export var anim_release = Constants.ANIM_RELEASE

@export var anim_ack_point = 0.03	# 攻击动画回复点


# Action Behavior
@export_group("Action")
@export var is_selected_circle: bool = true

# Component - 组件系统预定义
@export_group("System Component")
@export_flags("LEVEL", "VFX", "ITEM", "DAMAGABLE", "BARRAGE") var component_systems = 0
enum COMPONENT_SYSTEM{
	LEVEL,
	VFX,	
	ITEM,
	DAMAGABLE,
	BARRAGE
}

# Item related
@export_group("Item")
# 拾取速度
@export var pickup_velocity := 1000.0
@export var item_metas: Array[ItemResource] = []	# item meta info

# Skill related
@export_group("Skill")
@export var skill_metas: Array[SkillMetaResource] = []



# Component
@export_group("Component")
@export var level_component: PackedScene