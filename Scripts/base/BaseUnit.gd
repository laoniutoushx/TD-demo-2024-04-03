# BaseUnit.gd
class_name BaseUnit extends Node


@export_group("Unit Steup")
# ref resource
var clazz: BaseUnitResource

# signal
signal logical_death(unit: BaseUnit)
signal health_changed(unit: BaseUnit, left_health: float)	# 生命值变化单位，剩余生命值
signal mana_changed(unit: BaseUnit, left_mana: float)	# 魔法变化单位，剩余魔法值
signal attack_unit(unit: BaseUnit, target: BaseUnit)	# 攻击单位，目标单位
signal level_up(unit: BaseUnit, unit_level: int)	# 单位升级

# signal physic_death(unit: BaseUnit)


# meta config
@export var clz_code: String
@export var clz_name: String
@export var model_path: PackedScene	# model like glb, gltf...

@export var title: String
@export var desc: String

@export var icon_path: String
@export_range(0.0, 100.0, 0.01) var aabb_scale: float	# 通过参数修正 代码获取 aabb 尺寸偏差的问题 ？？ 
@export_range(0.0, 100.0, 0.01) var aabb_height_scale: float	# 通过参数修正 代码获取 aabb 尺寸偏差的问题 ？？ 

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
# 魔法抗性
@export var magic_resistance: float


# unit status
var health : float : 
	set(value):
		var change_health_val = health - value
		if health != value:
			health_changed.emit(self, change_health_val)
		health = value
		if health < 0:
			health = 0
		elif health > max_health:
			health = max_health

var max_health : float :
	set(value):
		health = value
		max_health = value
		
var mana : float : 
	set(value):
		mana = value
		mana_changed.emit(self, mana)
		if mana < 0:
			mana = 0
		elif mana > max_mana:
			mana = max_mana

@export var max_mana : float :
	set(value):
		mana = value
		max_mana = value


var _is_logic_alive := true


var move_speed : float :
	set(value):
		move_speed = value
		_anim_speed = move_speed * anim_speed_factor / 5

		if _ap:
			_ap.speed_scale = _anim_speed


var turn_speed : float
var attack_speed : float
var attack_range : float
var attack_num : int
var attack_value: float	# 
# @export var critical_hit_factor: float = 1.0	# 致命一击
@export var bounce_times: int = 0	# 弹射次数
@export var bounce_distance: int = 20	# 弹射距离
@export var bounce_decay_factor: float = 0.3	# 衰减因子
@export var unit_growth_factor: float = 0.0     # 单位成长率
@export var projectile_speed: float:	# 弹道速率
	set (value):
		projectile_speed = value / 10	# 取值缩小 100 倍


@export var health_recove_rate_factor: float = 0.0		# 生命值恢复速率
@export var mana_recove_rate_factor: float = 0.0		# 魔法值恢复速率



# material and mesh
var _outline_mesh: MeshInstance3D
var _hit_flash_material = preload("res://Asserts/materials/hit_flash.tres")
var _outline_material = preload("res://Asserts/materials/outline_mat.tres")

# create mesh outline
@export var is_mesh_outline: bool
@export var is_mesh_standing: bool
var _mesh_standing: MeshInstance3D

# unit cost
# 魔法消耗
@export var mana_cost: float = -1
# 木材消耗
@export var wood_cost: float = -1
# 金钱消耗
@export var money_cost: float = -1

@export var money_reward: int = -1
@export var wood_reward: int = -1








@export_group("Player")
# player meta into
# @export_flags("P0", "P1", "P2", "P3") 
@export var player_owner_idx: int

# player group => 0 & 1
@export var player_group: int




# ANIMATION
@export_group("Animation")

var _ap: AnimationPlayer
var _at: AnimationTree

@export var anim_attack = Constants.ANIM_ATTACK
@export var anim_run = Constants.ANIM_RUN
@export var anim_walk = Constants.ANIM_WALK
@export var anim_idle = Constants.ANIM_IDEL
@export var anim_death = Constants.ANIM_DEATH
@export var anim_release = Constants.ANIM_RELEASE


var _anim_speed: float	# 动画播放速率
@export var anim_speed_factor: float = 1.0:
	set(value):
		anim_speed_factor = value
		_anim_speed = move_speed * anim_speed_factor / 5

		if _ap:
			_ap.speed_scale = _anim_speed


@export var anim_ack_point = 0.03	# 攻击动画回复点


# Component - 组件系统预定义
@export_group("System Component")
@export_flags("LEVEL", "VFX", "ITEM", "DAMAGABLE", "BARRAGE") var component_systems = 0
@export var level_component: LevelComp


# AUDIO
@export_group("Audio")
var audio_death: String


# Action Behavior
@export_group("Action")
# selected circle
var is_selected_circle: bool


@export_group("Item")
@export var pickup_velocity := 1000.0
@export var item_metas: Array[ItemResource] = []	# item meta info
# 掉落装备
@export var drop_item_metas: Dictionary = {}	# drop item meta info

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



##################################################################
#单位受到伤害逻辑
signal unit_take_damage_regist(callable: Callable)
signal unit_take_damage_unregist(callable: Callable)

## Take Damage 回调处理（用于植入其他处理逻辑），先于回调函数执行（收到伤害 - 伤害目标单位，当前单位作为受到伤害单位，执行逻辑）
var take_damage_callback_list: Array = []

# Register Callable Function to be called when other Component 
func _on_unit_take_damage_regist(callable: Callable) -> void:
	take_damage_callback_list.append(callable)


func _on_unit_take_damage_unregist(callable: Callable) -> void:
	take_damage_callback_list.erase(callable)

##################################################################
# 单位触发伤害逻辑
signal unit_action_damage_regist(callable: Callable)
signal unit_action_damage_unregist(callable: Callable)

## Action Damage 回调处理（用于植入其他处理逻辑），先于回调函数执行（触发伤害 - 当前 self 作为伤害来源单位，执行逻辑）
var action_damage_callback_list: Array = []

# Register Callable Function to be called when other Component 
func _on_unit_action_damage_regist(callable: Callable) -> void:
	action_damage_callback_list.append(callable)


func _on_unit_action_damage_unregist(callable: Callable) -> void:
	action_damage_callback_list.erase(callable)
##################################################################





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
	var select_circle = CommonUtil.get_first_node_by_node_name(self, Constants.FadedCircle3D_CLZ)
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
	var aabb: AABB = CommonUtil.get_scaled_aabb(CommonUtil.get_first_node_by_node_type(self.get_child(0), Constants.MeshInstance3D_CLZ, false))
	# _transformed_aabb = AABB(aabb.position * aabb_scale, aabb.size * aabb_scale)
	_transformed_aabb = aabb.grow(aabb_scale)
	_height = aabb.size.y * aabb_height_scale


	# take damage
	unit_take_damage_regist.connect(_on_unit_take_damage_regist)
	unit_take_damage_unregist.connect(_on_unit_take_damage_unregist)
	unit_action_damage_regist.connect(_on_unit_action_damage_regist)
	unit_action_damage_unregist.connect(_on_unit_action_damage_unregist)

	# animation init
	_ap = CommonUtil.get_first_node_by_node_name(self, Constants.AnimationPlayer_CLZ)
	_at = CommonUtil.get_first_node_by_node_name(self, Constants.AnimationTree_CLZ)

	# 魔法值设置
	mana = max_mana

	# 监听自己的等级升级事件
	SignalBus.unit_level_up.connect(_on_unit_level_up)





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
	set_physics_process(false)
	
	# 移出 health bar
	var health_bar = CommonUtil.get_first_node_by_node_name(self, "HealthBar3D")
	if health_bar != null:
		health_bar.hide()
		# health_bar.queue_free()
	
	# player death animation
	death_effect()

	# 播放死亡音效
	CommonUtil.play_audio(self, audio_death)

	# 在单位位置创建血迹贴图
	var bs: PackedScene = CommonUtil.get_resource("blood_sc_01")
	if bs:
		var blood_stain: Decal = bs.instantiate()
		blood_stain.global_position = self.global_position
		blood_stain.scale = Vector3(_transformed_aabb.size.x, 1, _transformed_aabb.size.z)
		SOS.main.get_tree().get_root().add_child(blood_stain)



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
	await CommonUtil.await_timer(10)	# waiting 5 second for everything is over
	unit.queue_free()


# 逻辑死亡
func _on_logic_dead(unit: BaseUnit) -> void:
	if unit:

		unit.do_after_logic_dead()

		# 爆装备
		if drop_item_metas and drop_item_metas.size() > 0:
			
			for drop_item_key in drop_item_metas.keys():
				var drop_item: DropItem = drop_item_metas[drop_item_key]
				if SOS.main.prob.chance_fast(drop_item.chance):
					# 创建装备模型
					var chest_model: Node3D = drop_item.scene.instantiate()
					chest_model.steup(drop_item)
					SOS.main.item_system.add_child(chest_model)
					chest_model.global_position = unit.global_position
		


# is dead
func is_logic_dead() -> bool:
	return !is_alive()



# 单位升级
func _on_unit_level_up(id: int, unit: BaseUnit, level: int) -> void:
	if self.get_instance_id() == id:
		# 升级后攻击力=前一级攻击力×(1+成长率+随机波动)
		attack_value = attack_value *  (1 + unit_growth_factor + randf_range(0, SOS.main.player_controller.lucky_factor))  



# 源伤害逻辑处理
func action_damage(damage_ctx: DamageCtx) -> DamageCtx:

	# TODO 伤害前置处理（暴击、闪避等），附加到某一次攻击当中
	if not action_damage_callback_list.is_empty():
		for callback in action_damage_callback_list:
			damage_ctx = callback.call(damage_ctx)

	return damage_ctx



# 技能伤害
func take_skill_damage(damage_ctx: DamageCtx) -> bool:
	return _damage(damage_ctx)


# damage unit
func take_damage(damage_ctx: DamageCtx) -> bool:
	damage_ctx = damage_ctx.source.action_damage(damage_ctx)

	# 受击音效
	CommonUtil.play_audio(damage_ctx.target, "击中 拳头 打击 重击 01_爱给网_aigei_com", -5)

	# TODO 伤害前置处理（暴击、闪避等），附加到某一次攻击当中
	if not take_damage_callback_list.is_empty():
		for callback in take_damage_callback_list:
			damage_ctx = callback.call(damage_ctx)

	if damage_ctx.damage_type == DamageCtx.DamageType.MISS:

		# 显示漂浮文字
		SystemUtil.floating_text_system.spawn(
			Vector3(self.global_position.x, self._height, self.global_position.z),
			'miss',
			Color.RED,
			damage_ctx.damage_type
		)

		return false


	return _damage(damage_ctx)



# 伤害单位
func _damage(damage_ctx: DamageCtx) -> bool:
	var value = damage_ctx.damage

	if value <= 0:
		return _is_logic_alive

	health -= value
	SignalBus.unit_take_damage.emit(get_instance_id(), self, value)

	# 显示漂浮文字
	SystemUtil.floating_text_system.spawn(
		Vector3(self.global_position.x, self._height, self.global_position.z),
		str(int(value)),
		Color.WHITE if damage_ctx.damage_source_type == DamageCtx.DamageSourceType.UNIT else Color.DEEP_PINK ,
		damage_ctx.damage_type
	)
	
	if health + value > 0 and health <= 0:
		_is_logic_alive = false
		logical_death.emit(self)
		SignalBus.unit_logic_death.emit(get_instance_id(), self)
	
	return _is_logic_alive



# 立即逻辑死亡
func do_logical_death() -> void:
	_is_logic_alive = false
	logical_death.emit(self)
	SignalBus.unit_logic_death.emit(get_instance_id(), self)




# heal unit health
func heal(amount: int):
	health = min(health + amount, max_health)


	
func _create_mesh_outline():
	CommonUtil.add_outline_to_unit(self.get_child(0), _outline_material)

	# 1. 获取对象 mesh 网格
	# var origin_mesh = CommonUtil.get_first_node_by_node_type(self, Constants.MeshInstance3D_CLZ, false)
	# if origin_mesh != null:
	# 	var om: MeshInstance3D = (origin_mesh as MeshInstance3D)
	# 	om.material_overlay = _outline_material

	
func _create_mesh_standing():
	var origin_mesh: MeshInstance3D = CommonUtil.get_first_node_by_node_type(self, Constants.MeshInstance3D_CLZ, false)
	_mesh_standing = origin_mesh.duplicate()
	_mesh_standing.transform.origin = Vector3(0, 0, 0)
	_mesh_standing.scale = Vector3(1.01, 1.01, 1.01)
	_mesh_standing.material_override = _hit_flash_material
	_mesh_standing.visible = false
	origin_mesh.add_child(_mesh_standing)
	# 如果有骨骼，设置 mesh_standing 骨骼（添加到场景树当中后再获取相对路径）
	var skeleton: Skeleton3D = CommonUtil.get_first_node_by_node_type(self, Constants.Skeleton3D_CLZ)
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
	var select_circle = CommonUtil.get_first_node_by_node_name(self, Constants.FadedCircle3D_CLZ)	
	if select_circle:
		select_circle.visible = true

		# 添加动效
		var tween = create_tween()
		tween.tween_property(select_circle, "radius", select_circle.radius * 1.25, 0.0)
		tween.tween_property(select_circle, "radius", select_circle.radius, 0.1)



func hide_selected_circle() -> void:
	var select_circle = CommonUtil.get_first_node_by_node_name(self, Constants.FadedCircle3D_CLZ)	
	if select_circle:
		select_circle.visible = false


# 监听技能释放事件
func _on_skill_released(skill_context: SkillContext) -> void:
	var skill = skill_context.skill
	self.mana -= skill.mana_cost