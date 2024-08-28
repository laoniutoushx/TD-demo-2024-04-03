# BaseUnit.gd
extends Node

# base unit
class_name BaseUnit

# signal
var signal_container = {}

# material and mesh
var _outline_mesh: MeshInstance3D
var _hit_flash_material = preload("res://Asserts/materials/hit_flash.tres")

# create mesh outline
@export var is_mesh_outline: bool = false
@export var is_mesh_standing: bool = false

var _mesh_outline
var _mesh_standing: MeshInstance3D

# player meta into
@export_flags("P1", "P2", "P3", "P4") var player_owner_idx: int = 0


# define how unit move on mesh ground
@export_flags("WALK", "FLYING", "SWIM") var unit_move_type: int = 0
# define unit category
@export_flags("HUMAN", "BUILDING", "DECORATE_DESTORIED", "DECORATE_FOREVER") var unit_cate = 0


# ANIMATION
@export var anim_run = Constants.ANIM_RUN
@export var anim_walk = Constants.ANIM_WALK
@export var anim_idle = Constants.ANIM_IDEL
@export var anim_death = Constants.ANIM_DEATH


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


# enemy 死亡触发事件， turret 监听该 enemy 死亡事件，删除对应敌人集合
func do_after_logic_dead() -> void:
	# stop moving
	set_process(false)
	
	# 移出 health bar
	var health_bar = CommonUtil.get_first_node_by_node_name(self, "HealthBar3D")
	health_bar.queue_free()
	
	# player death animation
	death_effect()
	pass		

# unit death effect
func death_effect():
	# physic signal
	var signal_name = Constants.PHYSIC_DEAD + str(get_instance_id())
	add_user_signal(signal_name, [{"name": "unit", "type": TYPE_OBJECT}])
	var signal_physic_dead = Signal(self, signal_name)
	signal_physic_dead.connect(_on_physic_dead, CONNECT_ONE_SHOT)
	
	# logic animation player
	var ap: AnimationPlayer = CommonUtil.get_first_node_by_node_type(self, "AnimationPlayer")
	if ap != null:
		ap.play(anim_death)
		
		# 参数有默认时，是自右向左
		ap.animation_finished.connect(_on_animation_player_animation_finished.bind(self, signal_physic_dead), CONNECT_ONE_SHOT)
		#SignalBus.emit_signal("enemy_physic_death", get_instance_id(), self)
	else:	
		signal_physic_dead.emit(self)


func _on_animation_player_animation_finished(anim_name: String, unit:BaseUnit, signal_physic_dead:Signal) -> void:
	signal_physic_dead.emit(unit)
	pass # Replace with function body.
	
#func _on_animation_finished(anim_name: String, target_animation: String):
	## 判断是否是指定的动画播放完毕
	#if anim_name == target_animation:
		#print("Animation finished: ", anim_name)
		#signal_physic_dead.emit(self)  # 发射自定义信号

# 物理死亡
func _on_physic_dead(unit: BaseUnit) -> void:
	unit.queue_free()



# is dead
func is_logic_dead() -> bool:
	return health <= 0

# damage unit
func take_damage(damage: float):
	health -= damage


# heal unit health
func heal(amount: int):
	health = min(health + amount, max_health)
	
func _create_mesh_outline():
	# 1. 获取对象 mesh 网格
	var origin_mesh = CommonUtil.get_first_node_by_node_type(self, "MeshInstance3D")
	var outline_mesh_data = CommonUtil.create_outline_mesh(origin_mesh)
	_outline_mesh = MeshInstance3D.new()
	_outline_mesh.mesh = outline_mesh_data
	
	origin_mesh.add_child(_outline_mesh)
	
func _create_mesh_standing():
	var origin_mesh: MeshInstance3D = CommonUtil.get_first_node_by_node_type(self, "MeshInstance3D")
	_mesh_standing = origin_mesh.duplicate()
	_mesh_standing.transform.origin = Vector3(0, 0, 0)
	_mesh_standing.scale = Vector3(1.01, 1.01, 1.01)
	_mesh_standing.material_override = _hit_flash_material
	_mesh_standing.visible = false
	origin_mesh.add_child(_mesh_standing)
	# 如果有骨骼，设置 mesh_standing 骨骼（添加到场景树当中后再获取相对路径）
	var skeleton: Skeleton3D = CommonUtil.get_first_node_by_node_type(self, "Skeleton3D")
	if skeleton != null:
		_mesh_standing.skeleton = _mesh_standing.get_path_to(skeleton)



func get_mesh_standing() -> MeshInstance3D:
	return _mesh_standing	
