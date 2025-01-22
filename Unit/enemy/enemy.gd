class_name Enemy extends BaseUnit

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
	
	# health bar
	_health_bar_create()
	

# health bar creation
func _health_bar_create():
	# TODO 使用方法注解等方式实现自动初始化对应 tscn 目标，按照一定逻辑
	# 初始化创建 health_bar tscn
	await self.ready
	var health_bar: HealthBar = preload("res://Components/health_bar/health_bar.tscn").instantiate()
	var mesh_node = CommonUtil.get_first_node_by_node_type(self, Constants.MeshInstance3D_CLZ)
	var aabb: AABB = CommonUtil.get_scaled_aabb(mesh_node)


	var width = aabb.size.x
	var height = aabb.size.y * aabb_scale	# ☆ 此处特殊处理，手动修正部分导入模型 aabb 获取高度不匹配情况 （ BUG ？？）

	var real_width = width
	var real_height = height * health_bar.y_scale 
	
	# health bar 长度比例计算  78 px : 10px => 2
	var default_scale_of_healthbar2d_x_y = float(health_bar.get_health_bar2d_size().x) / float(health_bar.get_health_bar2d_size().y)
	var default_scale_of_healthbar2d_and_mesh3d = 78.0 / 2.0
	
	# 4x width 扩大
	var health_bar_2d_width = real_width * default_scale_of_healthbar2d_and_mesh3d * 4
	var health_bar_2d_height = health_bar_2d_width / default_scale_of_healthbar2d_x_y
	
	# 412px : 78px = 4
	var w_w_scale = (health_bar_2d_width) / health_bar.get_health_bar2d_size().x
	
	add_child(health_bar) 
	# print("self.global_position.y %s" % self.global_position.y)
	# print("height %s" % height)
	health_bar.position.y = self.global_position.y + height

	health_bar.prepare(max_health)
	health_bar.resize(health_bar_2d_width, health_bar_2d_height, w_w_scale)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	
	path.progress = path.progress + (delta * move_speed)
	if path.progress_ratio >= 0.98 && !is_finish:
		is_finish = true
		base.take_damage()
		set_process(false)


func take_damage(damage: float):
	var pos = self.global_position
	super.take_damage(damage)


#func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	#print("++++" + anim_name)
	#pass # Replace with function body.
