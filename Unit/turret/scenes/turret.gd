class_name Turret extends BaseUnit

# @export var projectile: PackedScene
# @onready var barrel: MeshInstance3D = $TurretBase/TurretTop/Visor/Barrel
@export var turret_top: Node3D
@export var fire_poses: Array[Marker3D]

@export var hud: HUD



var enemies: Dictionary = {}
var current_enemy

# aiming
var acquire_slerp_progress:float = 0

# state   idle（呆滞状态）
enum TurretState {
	BUILDING, IDLE, AIMMING, ATTACK, ATTACK_INTERVAL, AIMMING_WAITING, FREEZEING
}
var pre_state: TurretState
var current_state: TurretState
var ap: AnimationPlayer


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	super._ready()


	# 塔防单位状态设置
	current_state = TurretState.BUILDING

	# animation play
	ap = CommonUtil.get_first_node_by_node_type(self, Constants.AnimationPlayer_CLZ)

	# HUD 初始化
	hud.init_hud_bar(self)
	



# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
	match current_state:
		TurretState.BUILDING:
			pass


		TurretState.IDLE:
			# animation play
			if ap != null and ap.has_animation(anim_idle):
				ap.play(anim_idle)

			if enemies.size() > 0:
				if current_enemy == null:
					current_enemy = enemies.values()[0]
					print(enemies)
				pre_state = current_state
				current_state = TurretState.AIMMING
			#print("idle")

		
		TurretState.AIMMING:
			# 从攻击状态跳转回瞄准状态，等待攻击间隔完毕
			if current_enemy == null:
				pre_state = current_state
				current_state = TurretState.IDLE
			else:
				var target_direction = turret_top.global_position.direction_to(Vector3(current_enemy.position.x, turret_top.global_position.y, current_enemy.position.z))

				var target_basis:Basis = Basis.looking_at(target_direction)

				turret_top.basis = turret_top.basis.slerp(target_basis, acquire_slerp_progress)
				acquire_slerp_progress += delta * turn_speed
				if acquire_slerp_progress >= 0.97:
					pre_state = current_state
					current_state = TurretState.ATTACK
					acquire_slerp_progress = 0
					turret_top.look_at(Vector3(current_enemy.position.x, turret_top.global_position.y, current_enemy.position.z))
				
		# 需要一个执行动画回复点的状态或方法，等待执行完成后，执行 attack
		# 等待动画回复点
		# await CommonUtil.await_timer(anim_ack_point)
			 
		TurretState.ATTACK:
			if current_enemy != null:
				turret_top.look_at(Vector3(current_enemy.position.x, turret_top.global_position.y, current_enemy.position.z))
				# 在转换为 attack 状态后立即发起攻击，之后等待攻击间隔冷却后切换状态（Timer.timeout）
				attack(turret_top)
				pre_state = current_state
				current_state = TurretState.ATTACK_INTERVAL
			else:
				pre_state = current_state
				current_state = TurretState.IDLE
			
			
		TurretState.ATTACK_INTERVAL:
			# 立即转入寻敌状态
			pre_state = current_state
			current_state = TurretState.AIMMING_WAITING
			CommonUtil.delay_execution(attack_speed, (func(node: BaseUnit) -> void:
					if node and is_instance_valid(node):
						node.pre_state = node.TurretState.AIMMING_WAITING).bind(self)
				)


		TurretState.AIMMING_WAITING:
			# print(pre_state)
			# 从攻击状态跳转回瞄准状态，等待攻击间隔完毕
			if pre_state == TurretState.AIMMING_WAITING:
				if current_enemy == null:
					current_state = TurretState.IDLE	
				else:
					current_state = TurretState.AIMMING
			else:
				if current_enemy != null:
					var target_direction = turret_top.global_position.direction_to(Vector3(current_enemy.position.x, turret_top.global_position.y, current_enemy.position.z))
					var target_basis:Basis = Basis.looking_at(target_direction)
					turret_top.basis = turret_top.basis.slerp(target_basis, acquire_slerp_progress)
					acquire_slerp_progress += delta * turn_speed
					if acquire_slerp_progress >= 0.97:
						acquire_slerp_progress = 0
				else:
					if enemies.size() > 0:
						current_enemy = enemies.values()[0]

		TurretState.FREEZEING:	# 冻结
			set_physics_process(false)
				




func attack(turret_top) -> void:

	#var projectile_ins = projectile.instantiate()
	#projectile_ins.target = current_enemy
	#projectile_ins.starting_position = turret_top.global_position
	#add_child(projectile_ins) 

	# animation play
	var ap: AnimationPlayer = CommonUtil.get_first_node_by_node_type(self, Constants.AnimationPlayer_CLZ)
	if ap != null and ap.has_animation(anim_attack):
		ap.play(anim_attack)

	# 选择 N 个单位攻击
	if attack_num == 1:
		(SystemUtil.damage_system as DamageSystem).action(self, current_enemy)
	else:
		# 选取 attack_num 个敌人
		for i in range(attack_num):
			if enemies.size() > i:
				# projectile fire
				(SystemUtil.damage_system as DamageSystem).action(self, enemies.values()[i])
				i += 1
	pass


# func _on_area_3d_area_entered(area: Area3D) -> void:
# 	# TODO 获取当前节点实例化场景的顶级节点
# 	var enemy = area.owner
# 	if enemy != null && enemy is BaseUnit && enemy.player_owner_idx != self.player_owner_idx && !enemy.is_logic_dead():
# 		enemies[enemy.get_instance_id()] = enemy
# 		(enemy as BaseUnit).logical_death.connect(_on_enemy_logic_death, CONNECT_ONE_SHOT)

				


# func _on_area_3d_area_exited(area: Area3D) -> void:
# 	var enemy = area.owner
# 	if enemy != null:
# 		enemies.erase(enemy.get_instance_id())
# 		if enemy == current_enemy:
# 			current_enemy = null




func _on_attacking_scope_area_entered(area:Area3D) -> void:
	# TODO 获取当前节点实例化场景的顶级节点
	var enemy = area.owner
	if enemy != null && enemy is BaseUnit && enemy.player_owner_idx != self.player_owner_idx && !enemy.is_logic_dead():
		enemies[enemy.get_instance_id()] = enemy
		if not (enemy as BaseUnit).logical_death.is_connected(_on_enemy_logic_death):
			(enemy as BaseUnit).logical_death.connect(_on_enemy_logic_death, CONNECT_ONE_SHOT)	



func _on_attacking_scope_area_exited(area:Area3D) -> void:
	var enemy = area.owner
	if enemy != null:
		enemies.erase(enemy.get_instance_id())
		if enemy == current_enemy:
			current_enemy = null

				



# enemy 死亡触发事件， turret 监听该 enemy 死亡事件，删除对应敌人集合
func _on_enemy_logic_death(enemy: BaseUnit) -> void:
	enemies.erase(enemy.get_instance_id())
	if current_enemy == enemy:
		current_enemy = null


func change_state(new_state: TurretState) -> void:
	pre_state = current_state
	current_state = new_state
