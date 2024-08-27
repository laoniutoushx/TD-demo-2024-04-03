extends BaseUnit

@export var projectile: PackedScene
@onready var barrel: MeshInstance3D = $TurretBase/TurretTop/Visor/Barrel
@onready var turret_top: MeshInstance3D = $TurretBase/TurretTop
@export var rotate_speed: float = 5


var enemies: Array = []
var current_enemy

# aiming
var acquire_slerp_progress:float = 0

# state   idle（呆滞状态）
enum TurretState {
	IDLE, AIMMING, ATTACK, ATTACK_INTERVAL, UNKNOW
}
var pre_state: TurretState
var current_state: TurretState


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	current_state = TurretState.IDLE
	vfx_projectile_name = "fireball"
	
	



# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
	match current_state:
		TurretState.IDLE:
			if enemies.size() > 0:
				if current_enemy == null:
					current_enemy = enemies[0]
				pre_state = current_state
				current_state = TurretState.AIMMING
			#print("idle")

		
		TurretState.AIMMING:
			#print("aiming")
			if current_enemy == null:
				pre_state = current_state
				current_state = TurretState.IDLE
			else:
				var target_direction = turret_top.global_position.direction_to(Vector3(current_enemy.position.x, turret_top.global_position.y, current_enemy.position.z))
				var target_basis:Basis = Basis.looking_at(target_direction)
				turret_top.basis = turret_top.basis.slerp(target_basis, acquire_slerp_progress)
				acquire_slerp_progress += delta * rotate_speed
				if acquire_slerp_progress >= 0.97:
					acquire_slerp_progress = 0
					current_state = TurretState.ATTACK
					turret_top.look_at(Vector3(current_enemy.position.x, turret_top.global_position.y, current_enemy.position.z))
				

			 
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
			if pre_state == TurretState.ATTACK:
				pre_state = TurretState.UNKNOW	# 防止重复进入当前状态 ATTACK_INTERVAL

				CommonUtil.delay_execution(0.5, (func(node: BaseUnit) -> void:
					pre_state = current_state
					node.current_state = node.TurretState.ATTACK).bind(self)
				)




func attack(target) -> void:

	#var projectile_ins = projectile.instantiate()
	#projectile_ins.target = current_enemy
	#projectile_ins.starting_position = turret_top.global_position
	#add_child(projectile_ins) 
	
	(SystemUtil.damage_system as DamageSystem).action(self, current_enemy)
	
	pass


func _on_area_3d_area_entered(area: Area3D) -> void:
	# TODO 获取当前节点实例化场景的顶级节点
	var enemy = CommonUtil.get_first_parent_by_node_type(area, "PathFollow3D")
	if enemy != null && enemy is BaseUnit && !enemy.is_logic_dead():
		enemies.append(enemy)
		enemy_signal_registger(enemy)
				


func _on_area_3d_area_exited(area: Area3D) -> void:
	var enemy = CommonUtil.get_first_parent_by_node_type(area, "PathFollow3D")
	if enemy != null:
		enemies.erase(enemy)
		if enemy == current_enemy:
			current_enemy = null
					

func enemy_signal_registger(enemy) -> void:
	# 为 enemy 创建死亡信号
	var signal_name = Constants.LOGIC_DEAD + str(enemy.get_instance_id())
	enemy.add_user_signal(signal_name, [{"name": "enemy", "type": TYPE_OBJECT}])
	var signal_enemy_death = Signal(enemy, signal_name)
	
	# turret 监听当前信号，绑定某个 func 
	signal_enemy_death.connect(_on_enemy_logic_death, CONNECT_ONE_SHOT)
	enemy.signal_container[signal_name] = signal_enemy_death
	pass


# enemy 死亡触发事件， turret 监听该 enemy 死亡事件，删除对应敌人集合
func _on_enemy_logic_death(enemy: BaseUnit) -> void:
	enemies.erase(enemy)
	if current_enemy == enemy:
		current_enemy = null
	if enemy:
		enemy.do_after_logic_dead()
	pass
