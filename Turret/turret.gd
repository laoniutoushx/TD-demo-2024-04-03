extends Node3D

@export var projectile: PackedScene
@onready var barrel: MeshInstance3D = $TurretBase/TurretTop/Visor/Barrel
@onready var turret_top: MeshInstance3D = $TurretBase/TurretTop
@export var rotate_speed: float = 1


var enemies: Array = []
var current_enemy

# aiming
var acquire_slerp_progress:float = 0

# attack
var attack_timer: Timer = null

# state   idle（呆滞状态）
enum TurretState {
	IDLE, AIMMING, ATTACK
}

var current_state: TurretState


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	current_state = TurretState.IDLE



# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
	match current_state:
		TurretState.IDLE:
			if enemies.size() > 0:
				if current_enemy == null:
					current_enemy = enemies[0]
				current_state = TurretState.AIMMING
			#print("idle")

		
		TurretState.AIMMING:
			#print("aiming")
			if current_enemy == null:
				current_state = TurretState.IDLE
			else:
				var target_direction = turret_top.global_position.direction_to(Vector3(current_enemy.position.x, turret_top.global_position.y, current_enemy.position.z))
				var target_basis:Basis = Basis.looking_at(target_direction)
				turret_top.basis = turret_top.basis.slerp(target_basis, acquire_slerp_progress)
				acquire_slerp_progress += delta * rotate_speed
				if acquire_slerp_progress > 1:
					acquire_slerp_progress = 0
					current_state = TurretState.ATTACK
					turret_top.look_at(Vector3(current_enemy.position.x, turret_top.global_position.y, current_enemy.position.z))
				

			 
		TurretState.ATTACK:
			if current_enemy != null:
				turret_top.look_at(Vector3(current_enemy.position.x, turret_top.global_position.y, current_enemy.position.z))
			
			# 在转换为 attack 状态后立即发起攻击，之后等待攻击间隔冷却后切换状态（Timer.timeout）
			if attack_timer == null:
				attack(turret_top)
				
				attack_timer = Timer.new()
				attack_timer.wait_time = 0.5
				attack_timer.autostart = true
				attack_timer.one_shot = true
				add_child(attack_timer)
				
				
				await attack_timer.timeout
				
				if attack_timer.time_left == 0:
					print("Timer has timed out!")
					current_state = TurretState.IDLE
					attack_timer.queue_free()
					print("attack timer queue")
					attack_timer = null
				


				# 连接计时器的 "timeout" 信号到一个方法
				# attack_timer.timeout.connect(_on_timer_timeout, attack_timer)

func attack(target) -> void:
	var projectile_ins = projectile.instantiate()
	projectile_ins.target = current_enemy
	projectile_ins.starting_position = turret_top.global_position
	add_child(projectile_ins) 
	
	pass


func _on_area_3d_area_entered(area: Area3D) -> void:
	var enemy = area.get_parent_node_3d()
	if enemy != null && enemy.get_groups() != null:
		for group in enemy.get_groups():
			if group.get_basename() == 'enemy':
				print("entered")
				enemies.append(enemy)
				
				



func _on_area_3d_area_exited(area: Area3D) -> void:
	var enemy = area.get_parent_node_3d()
	if enemy != null && enemy.get_groups() != null:
		for group in enemy.get_groups():
			if group.get_basename() == 'enemy':
				print("exited")
				enemies.erase(enemy)
				if enemy == current_enemy:
					current_enemy = null
