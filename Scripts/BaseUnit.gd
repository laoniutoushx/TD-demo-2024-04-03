# BaseUnit.gd
extends Node

# base unit
class_name BaseUnit

var _outline_mesh: MeshInstance3D


# player meta into
@export_flags("P1", "P2", "P3", "P4") var player_owner_idx: int = 0


# define how unit move on mesh ground
@export_flags("WALK", "FLYING", "SWIM") var unit_move_type: int = 0
# define unit category
@export_flags("HUMAN", "BUILDING", "DECORATE_DESTORIED", "DECORATE_FOREVER") var unit_cate = 0

# create mesh outline
@export var mesh_outline: bool = false
@export var mesh_standing: bool = false


var health : float		
@export var max_health : float :
	set(value):
		health = value
		max_health = value
		
@export var move_speed : float
@export var turn_speed : float
@export var attack_speed : float

# FightRegion
@export var vfx_projectile_name: String
@export var projectile_speed: String
@export var projectile_trace: Curve3D


func _ready() -> void:
	health = max_health
	# 是否创建 mesh_outline
	if mesh_outline:
		_create_mesh_outline()
		
	# 是否创建 mesh_standing
	if mesh_standing:
		_create_mesh_standing()


# unit death effect
func death_effect():
	pass

# is dead
func is_dead() -> bool:
	return health <= 0

# damage unit
func take_damage(damage: float):
	health -= damage
	if is_dead():
		death_effect()
	else:
		# 受击动画
		await CommonUtil.await_timer(0.1)

			

		
		pass

# heal unit health
func heal(amount: int):
	health = min(health + amount, max_health)
	
func _create_mesh_outline():
	# 1. 获取对象 mesh 网格
	var origin_mesh = CommonUtil.get_first_mesh_instances(self)
	var outline_mesh_data = CommonUtil.create_outline_mesh(origin_mesh)
	_outline_mesh = MeshInstance3D.new()
	_outline_mesh.mesh = outline_mesh_data
	
	origin_mesh.add_child(_outline_mesh)
	
func _create_mesh_standing():
	var origin_mesh = CommonUtil.get_first_mesh_instances(self)
	var standing_mesh = origin_mesh.duplicate()
	standing_mesh.scale = Vector3(1.01, 1.01, 1.01)
	standing_mesh.visible = false
	origin_mesh.add_child(standing_mesh)
	pass
