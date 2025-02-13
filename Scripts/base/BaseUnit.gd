# BaseUnit.gd
class_name BaseUnit extends Node


@export_group("Unit Steup")
# ref resource
var clazz: BaseUnitResource

# signal
signal logical_death(unit: BaseUnit)
# signal physic_death(unit: BaseUnit)


# meta config
@export var clz_code: String
@export var clz_name: String
@export var model_path: PackedScene	# model like glb, gltf...

@export var title: String
@export var desc: String

@export var icon_path: String
@export_range(0.0, 100.0, 0.01) var aabb_scale: float = 1	# 通过参数修正 代码获取 aabb 尺寸偏差的问题 ？？ 
@export_range(0.0, 100.0, 0.01) var aabb_height_scale: float = 1	# 通过参数修正 代码获取 aabb 尺寸偏差的问题 ？？ 

# define unit element phase
@export_flags("WOOD", "FIRE", "METAL", "WATER", "EARCH") var element_phase: int = 0
# define how unit move on mesh ground
@export_flags("WALK", "FLYING", "SWIM") var unit_move_type: int = 0
# define unit category
@export_flags("HUMAN", "BUILDING", "DECORATE_DESTORIED", "DECORATE_FOREVER") var unit_cate = 0
# armor
@export var armor_amount: float
enum ARMOR_TYPE_ENUM  {
	INVINCIBLE,
	NORMAL,
	HERO,
	ENEMY,
	FRIEND
}
@export_flags("INVINCIBLE", "NORMAL", "HERO", "ENEMY", "FRIEND") var armor_type = 0


# unit status
var health : float		
var max_health : float :
	set(value):
		health = value
		max_health = value
		
var _is_logic_alive := true


var move_speed : float
var turn_speed : float
var attack_speed : float
var attack_range : float
var attack_num : int
var attack_value: float	# 伤害值
var unit_growth_factor: float = 1.0     # 单位成长率
var projectile_speed: float:	# 弹道速率
	set (value):
		projectile_speed = value / 100	# 取值缩小 100 倍

# FightRegion
var vfx_projectile_name: String
var projectile_trace: Curve3D



# material and mesh
var _outline_mesh: MeshInstance3D
var _hit_flash_material = preload("res://Asserts/materials/hit_flash.tres")
var _outline_material = preload("res://Asserts/materials/outline_mat.tres")

# create mesh outline
var is_mesh_outline: bool
var is_mesh_standing: bool
var _mesh_standing: MeshInstance3D

# unit cost
# 魔法消耗
@export var mana_cost: float = 10.0
# 木材消耗
@export var wood_cost: float = 10.0
# 金钱消耗
@export var money_cost: float = 10.0





# selected circle
var is_selected_circle: bool


@export_group("Player")
# player meta into
# @export_flags("P0", "P1", "P2", "P3") 
@export var player_owner_idx: int

# player group => 0 & 1
@export var player_group: int




# ANIMATION
@export_group("Animation")
@export var anim_attack = Constants.ANIM_ATTACK
@export var anim_run = Constants.ANIM_RUN
@export var anim_walk = Constants.ANIM_WALK
@export var anim_idle = Constants.ANIM_IDEL
@export var anim_death = Constants.ANIM_DEATH

@export var anim_release = Constants.ANIM_RELEASE

@export var anim_ack_point = 0.03	# 攻击动画回复点


# Component - 组件系统预定义
@export_group("System Component")
@export_flags("LEVEL", "VFX", "ITEM", "DAMAGABLE", "BARRAGE") var component_systems = 0
@export var level_component: LevelComp





@export_group("Item")
@export var pickup_velocity := 1000.0
@export var item_metas: Array[ItemResource] = []	# item meta info
# Item（实例化后的物品列表）
var item_map: Dictionary = {}


@export_group("Skill")
@export var skill_metas: Array[SkillMetaResource] = []	# skill meta info
# Skill（实例化后的技能列表）
var skill_map: Dictionary = {}
# 一个单位，在多个技能中共享的状态（目前为 skill indicator）
var current_global_skill_state: int = 0


@export_group("Buff")
# Buff（实例化后的buff列表）
var buff_map: Dictionary = {}


# 内部变量
var _transformed_aabb: AABB		# 当前对象全局空间 AABB 包围盒
var _height: float				# 当前对象高度





func _ready() -> void:
	# 注意 BaseUnit 与 BaseUnitResource 的 cycle reference 
	clazz_init()

	# print("_ready %s, %s, %s, %s" % [self.name, get_instance_id(), clz_code, get_class()])
	
	
	health = max_health
	# 是否创建 mesh_outline
	if is_mesh_outline:
		_create_mesh_outline()
		
	# 是否创建 mesh_standing
	if is_mesh_standing:
		_create_mesh_standing()
		
	# 是否创建 Selected Circle
	#if is_selected_circle:
		#_create_selected_circle()
	
	# hide select circle
	var select_circle = CommonUtil.get_first_node_by_node_name(self, "FadedCircle3D")
	select_circle.hide()
	
	# attack area fixed
	var attacking_scope = CommonUtil.get_first_node_by_node_name(self, "AttackingScope")
	if attacking_scope:
		# print("has attack scop")
		var cylinder_collision: CollisionShape3D = attacking_scope.get_child(0)
		if cylinder_collision and cylinder_collision.shape:
			# print("has cylinder collision")
			print(attack_range)
			(cylinder_collision.shape as CylinderShape3D).radius = attack_range
			

	
	# system component load（item）
	item_map = SystemUtil.item_system.initialize_items(self, item_metas)
	
	# system component load（skill）
	skill_map = SystemUtil.skill_system.initialize_skills(self, skill_metas)

	# level_up
	if CommonUtil.is_flag_set(BaseUnitResource.COMPONENT_SYSTEM.LEVEL, component_systems):
		pass

	# signal register
	logical_death.connect(_on_logic_dead, CONNECT_ONE_SHOT)
	# physic_death.connect(_on_physic_dead, CONNECT_ONE_SHOT)


	# AABB

	var aabb: AABB = CommonUtil.get_scaled_aabb(CommonUtil.get_first_node_by_node_type(self, Constants.MeshInstance3D_CLZ))
	# _transformed_aabb = AABB(aabb.position * aabb_scale, aabb.size * aabb_scale)
	_transformed_aabb = aabb.grow(aabb_scale)
	_height = aabb.size.y * aabb_height_scale

	print("clz - %s" % self.clz_name)
	print(self.aabb_scale)
	print(self.aabb_height_scale)
	print(_transformed_aabb)
	print(_height)


# clz 初始化
func clazz_init():
	var current_scene_name: String = self.scene_file_path.get_file().get_basename()

	# load clz resource
	clazz = SOS.main.resource_manager.get_resource_by_name(current_scene_name)
	
	# bean property copy
	if clazz != null:
		CommonUtil.bean_properties_copy(clazz, self)
	
	
func is_alive() -> bool:
	return _is_logic_alive

# enemy 死亡触发事件， turret 监听该 enemy 死亡事件，删除对应敌人集合
func do_after_logic_dead() -> void:

	# stop moving
	set_process(false)
	
	# 移出 health bar
	var health_bar = CommonUtil.get_first_node_by_node_name(self, "HealthBar3D")
	if health_bar != null:
		health_bar.hide()
		# health_bar.queue_free()
	
	# player death animation
	death_effect()



# unit death effect
func death_effect():
	# physic signal
	var signal_name = Constants.PHYSIC_DEAD + str(get_instance_id())
	add_user_signal(signal_name, [{"name": "unit", "type": TYPE_OBJECT}])
	var signal_physic_dead = Signal(self, signal_name)
	signal_physic_dead.connect(_on_physic_dead, CONNECT_ONE_SHOT)
	
	# logic animation player
	var ap: AnimationPlayer = CommonUtil.get_first_node_by_node_type(self, Constants.AnimationPlayer_CLZ)
	if ap != null and ap.has_animation(anim_death):
		ap.play(anim_death)
		ap.animation_finished.connect(_on_animation_player_animation_finished.bind(self, signal_physic_dead), CONNECT_ONE_SHOT)
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
	unit.hide()
	await CommonUtil.await_timer(5)	# waiting 5 second for everything is over
	unit.queue_free()


# 逻辑死亡
func _on_logic_dead(unit: BaseUnit) -> void:
	if unit:
		unit.do_after_logic_dead()


# is dead
func is_logic_dead() -> bool:
	return !is_alive()

# damage unit
func take_damage(damage: float):
	health -= damage
	SignalBus.unit_take_damage.emit(get_instance_id(), self, damage)
	if health + damage > 0 and health <= 0:
		_is_logic_alive = false
		logical_death.emit(self)
		SignalBus.unit_logic_death.emit(get_instance_id(), self)


# heal unit health
func heal(amount: int):
	health = min(health + amount, max_health)


	
func _create_mesh_outline():
	# 1. 获取对象 mesh 网格
	var origin_mesh = CommonUtil.get_first_node_by_node_type(self, "MeshInstance3D")
	if origin_mesh != null:
		var om: MeshInstance3D = (origin_mesh as MeshInstance3D)
		om.material_overlay = _outline_material
	
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

func _create_selected_circle() -> void:
	var selected_circle_scene: PackedScene = preload("res://generic-scenes-and-nodes/3d/FadedCircle3D.tscn")
	var selected_circle: Node3D = selected_circle_scene.instantiate()
	selected_circle.color = Color.WHITE
	
	var mesh_node = CommonUtil.get_first_node_by_node_type(self, Constants.MeshInstance3D_CLZ)
	var aabb = CommonUtil.get_scaled_aabb(mesh_node)
	var max_len = min(aabb.size.x, aabb.size.z)
	
	selected_circle.radius = max_len * 1.2 / 2.0
	add_child(selected_circle)
	pass


func get_mesh_standing() -> MeshInstance3D:
	return _mesh_standing	

func show_selected_circle() -> void:
	var select_circle = CommonUtil.get_first_node_by_node_name(self, "FadedCircle3D")	
	if select_circle:
		select_circle.visible = true

		# 添加动效
		var tween = create_tween()
		tween.tween_property(select_circle, "radius", select_circle.radius * 1.25, 0.0)
		tween.tween_property(select_circle, "radius", select_circle.radius, 0.1)



func hide_selected_circle() -> void:
	var select_circle = CommonUtil.get_first_node_by_node_name(self, "FadedCircle3D")	
	if select_circle:
		select_circle.visible = false
