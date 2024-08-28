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
	var mesh_node = CommonUtil.get_first_node_by_node_type(self, "MeshInstance3D")
	var aabb = mesh_node.mesh.get_aabb()
	var width = aabb.size.x
	var height = aabb.size.y

	# 获取所有父节点，计算 scale 值
	var y_scale_instance = 1.0
	var x_scale_instance = 1.0
	var parent_nodes = CommonUtil.get_all_parent_node_by_node_type(mesh_node, "PathFollow3D")
	for parent_node in parent_nodes:
		if parent_node.scale != null:
			y_scale_instance *= parent_node.scale.y
			x_scale_instance *= parent_node.scale.x
	
	var real_width = width * x_scale_instance
	var real_height = height * health_bar.y_scale * y_scale_instance
	
	# health bar 长度比例计算  78 px : 10px => 2
	var default_scale_of_healthbar2d_x_y = float(health_bar.get_health_bar2d_size().x) / float(health_bar.get_health_bar2d_size().y)
	var default_scale_of_healthbar2d_and_mesh3d = 78.0 / 2.0
	
	# 4x width 扩大
	var health_bar_2d_width = real_width * default_scale_of_healthbar2d_and_mesh3d * 4
	var health_bar_2d_height = health_bar_2d_width / default_scale_of_healthbar2d_x_y
	
	# 412px : 78px = 4
	var w_w_scale = (health_bar_2d_width) / health_bar.get_health_bar2d_size().x
	
	
	health_bar.position.y = self.position.y + real_height

	add_child(health_bar) 
	health_bar.prepare(max_health)
	health_bar.resize(health_bar_2d_width, health_bar_2d_height, w_w_scale)
	
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
