# BaseUnit.gd
extends Node

# base unit
class_name BaseUnit

var _outline_mesh: MeshInstance3D
var _hit_flash_material = preload("res://Asserts/materials/hit_flash.tres")

# player meta into
@export_flags("P1", "P2", "P3", "P4") var player_owner_idx: int = 0


# define how unit move on mesh ground
@export_flags("WALK", "FLYING", "SWIM") var unit_move_type: int = 0
# define unit category
@export_flags("HUMAN", "BUILDING", "DECORATE_DESTORIED", "DECORATE_FOREVER") var unit_cate = 0

# create mesh outline
@export var is_mesh_outline: bool = false
@export var is_mesh_standing: bool = false

var _mesh_outline
var _mesh_standing: MeshInstance3D


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
	if is_mesh_outline:
		_create_mesh_outline()
		
	# 是否创建 mesh_standing
	if is_mesh_standing:
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
	_mesh_standing = origin_mesh.duplicate()
	_mesh_standing.transform.origin = Vector3(0, 0, 0)
	_mesh_standing.scale = Vector3(1.01, 1.01, 1.01)
	_mesh_standing.material_override = _hit_flash_material
	_mesh_standing.visible = false
	origin_mesh.add_child(_mesh_standing)
	pass
	
func get_mesh_standing() -> MeshInstance3D:
	return _mesh_standing	
