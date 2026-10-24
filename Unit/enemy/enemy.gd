class_name Enemy extends BaseUnit

@onready var path: PathFollow3D = $"."
@onready var base = get_tree().get_first_node_in_group("base")


var is_finish = false


func _ready() -> void:
	super._ready()	
	# 初始化时创建 path3d 与 pathfollow3d
	
	# 初始化 walk 动画

	change_state(EnemyState.WALKING)
	
	# health bar
	_health_bar_create()
	

# health bar creation
func _health_bar_create() -> void:
	await self.ready
	var bars = get_tree().get_first_node_in_group("screen_health_bars")
	if is_instance_valid(bars): bars.register_unit(self)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if not is_alive() or current_state != EnemyState.WALKING: return
	
	path.progress = path.progress + (delta * move_speed)
	if path.progress_ratio >= 0.98 && !is_finish:
		is_finish = true
		if is_instance_valid(base):
			base.take_damage()
		do_logical_death("leaked")
		set_process(false)


func take_damage(damage_ctx: DamageCtx) -> bool:
	return super.take_damage(damage_ctx)


#func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	#print("++++" + anim_name)
	#pass # Replace with function body.


# 状态机
# state   idle（呆滞状态）
enum EnemyState {
	IDLE, WALKING, STUN, DEAD
}
var pre_state: EnemyState
var current_state: EnemyState


func _physics_process(delta: float) -> void:

	if not is_alive(): return

	match current_state:		
		EnemyState.IDLE:
			pass

		EnemyState.STUN:
			pass

		EnemyState.WALKING:
			pass


		EnemyState.DEAD:
			pass






func change_state(new_state: EnemyState) -> void:
	if not is_alive() and new_state != EnemyState.DEAD: return
	pre_state = current_state
	current_state = new_state

	if current_state == EnemyState.IDLE:
		# 初始化 idle 动画
		if _ap and _ap.has_animation(anim_idle):
			_ap.play(anim_idle)
			_ap.speed_scale = _anim_speed


	if current_state == EnemyState.STUN:
		set_process(false)
		if _ap and _ap.has_animation(anim_idle):
			_ap.play(anim_idle)
			_ap.speed_scale = _anim_speed



	if current_state == EnemyState.WALKING:
		set_process(true)
		# 初始化 walk 动画
		if _ap and _ap.has_animation(anim_run):
			_ap.play(anim_run)
			_ap.speed_scale = _anim_speed



	if current_state == EnemyState.DEAD:
		if _ap and _ap.has_animation(anim_death):
			_ap.play(anim_death)
			_ap.speed_scale = _anim_speed
