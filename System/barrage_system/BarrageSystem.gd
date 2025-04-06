class_name BarrageSystem extends Node3D

var signal_dict = {}
var projectile_scene: PackedScene

func _ready() -> void:
	SystemUtil.barrage_system = self
	projectile_scene = preload("res://System/barrage_system/projectile.tscn")

# 弹道执行
# source: BaseUnit
# target: BaseUnit
# projection: PackedScene 投射物
func action(source, target, projection: PackedScene) -> Array:

	var target_unit_id: int = target.get_instance_id()

	# TODO 不处理伤害，可以执行 等待，等待弹道完成后，触发

	# 1. 获取弹道模型
	if source is BaseUnit:
		# load projectile vfx scene instance
		var vfx_projectile_name: String = (source as BaseUnit).vfx_projectile_name
		var vfx_projectile_ins: Node3D = (SystemUtil.vfx_system as VFXSystem).create_vfx(vfx_projectile_name, VFXSystem.VFX_TYPE.RUNNING)
		
		# 2. 加载弹道场景
		# append projectile vfx instance to project instance
		
		var projectile_instance: Node3D = projectile_scene.instantiate()
		projectile_instance.source = source
		projectile_instance.target = target
		projectile_instance.fire_pos = get_fire_pos(source)
		projectile_instance.speed = source.projectile_speed
		projectile_instance.damage = source.attack_value
		projectile_instance.add_child(vfx_projectile_ins) 

		var pi_ap: AnimationPlayer = CommonUtil.get_first_node_by_node_type(vfx_projectile_ins, Constants.AnimationPlayer_CLZ)
		if pi_ap:
			pi_ap.play(Constants.ANIM_RUN)

		source.add_child(projectile_instance) 

		
		
		# 3. load projectile vfx destory scene instance
		var signal_name = str(projectile_instance.get_instance_id()) + UUID.v4()
	
		self.add_user_signal(signal_name, [{"name": "pos", "type": TYPE_VECTOR3}])
		var signal_projectile = Signal(self, signal_name)
		#var ps_instance: ProjectileSignal = ProjectileSignal.new()
		
		var projectile_exiting: Callable = func(target, projectile_instance, signal_projectile) -> void:
			# 发送 exiting position
			var pos = projectile_instance.global_position
			#emit_signal(str(projectile_instance.get_instance_id()), pos)
			signal_projectile.emit(pos)
		
		projectile_instance.tree_exiting.connect(
			projectile_exiting.bind(target, projectile_instance, signal_projectile),
			CONNECT_ONE_SHOT
		)
		
		# waiting for projectile arrived
		var vfx_projectile_destory_pos = await signal_projectile
		
		
		

		return [vfx_projectile_destory_pos, target_unit_id, target]
	
	return [null, null, null]



# 寻找 fire_pos 节点，定义在 Metadata 当中（has_key fire_pos）
func get_fire_pos(source):
	if source is Turret and source.fire_poses and source.fire_poses.size() > 0:
		return source.fire_poses[0].global_position


	var fire_pos_nodes: Array = find_nodes_by_meta(source, "fire_pos")
	if fire_pos_nodes and fire_pos_nodes.size() == 0:
		return source.global_position
	
	# TODO 如果有多个发射位置，默认返回第一个，（后续有其他逻辑时处理）
	return fire_pos_nodes[0].global_position


func find_nodes_by_meta(source: Node, meta_key: String) -> Array:
	return _recursive_find_nodes_by_meta(source, meta_key)


func _recursive_find_nodes_by_meta(node: Node, meta_key: String) -> Array:
	var result = []
	if node.has_meta(meta_key):
		result.append(node)
	for child in node.get_children():
		result += _recursive_find_nodes_by_meta(child, meta_key)
	return result		
