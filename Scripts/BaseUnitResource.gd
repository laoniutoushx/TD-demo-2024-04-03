class_name BaseUnitResource
extends Resource


# meta config
@export var clz_code: String
@export var clz_name: String
@export var model_path: PackedScene	# model like glb, gltf...


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
