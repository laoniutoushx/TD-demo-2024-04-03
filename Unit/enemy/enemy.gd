class_name Enemy
extends BaseUnit

@export var money := 10
@export var wood := 1

@onready var path: PathFollow3D = $"."
@onready var base = get_tree().get_first_node_in_group("base")


var is_finish = false

func _ready() -> void:
	super._ready()	
	# 初始化时创建 path3d 与 pathfollow3d
	
	# 初始化 walk 动画
	var ap: AnimationPlayer = CommonUtil.get_first_node_by_node_name(self, "AnimationPlayer")
	if ap:
		ap.play(anim_run)
	
	
	# TODO 使用方法注解等方式实现自动初始化对应 tscn 目标，按照一定逻辑
	# 初始化创建 health_bar tscn
	await self.ready
	var health_bar: HealthBar = preload("res://UI/component/health_bar/health_bar.tscn").instantiate()
	var aabb = CommonUtil.get_first_node_by_node_type(self, "MeshInstance3D").mesh.get_aabb()
	var height = aabb.size.y
	health_bar.position.y = self.position.y + height * health_bar.y_scale
	health_bar.prepare(max_health)
	add_child(health_bar) 
	pass



# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	
	path.progress = path.progress + (delta * move_speed)
	if path.progress_ratio >= 0.98 && !is_finish:
		is_finish = true
		base.take_damage()
		set_process(false)


func take_damage(damage: float):
	super.take_damage(damage)
	var pos = self.global_position
	#print("global position-take d: (%f, %f, %f)" % [pos.x, pos.y, pos.z])
	SignalBus.emit_signal("enemy_take_damage", get_instance_id(), self, damage)
	if super.is_logic_dead():
		print("emit signal - " + Constants.LOGIC_DEAD + str(get_instance_id()))
		var signal_enemy_death: Signal = signal_container.get(Constants.LOGIC_DEAD + str(get_instance_id()))
		signal_enemy_death.emit(self)
		# Global Signal
		SignalBus.emit_signal("enemy_logic_death", get_instance_id(), self)




#func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	#print("++++" + anim_name)
	#pass # Replace with function body.
