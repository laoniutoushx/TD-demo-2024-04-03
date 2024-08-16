extends Node
class_name BarrageSystem

var signal_dict = {}
var projectile_res: PackedScene

func _ready() -> void:
	SystemUtil.barrage_system = self
	projectile_res = preload("res://System/barrage_system/projectile.tscn")

# 弹道执行
func action(source, target):
	# 1. 获取弹道模型
	if source is BaseUnit:
		# load projectile vfx scene instance
		var vfx_projectile_name: String = (source as BaseUnit).vfx_projectile_name
		var vfx_projectile_ins: Node3D = (SystemUtil.vfx_system as VFXSystem).create_vfx(vfx_projectile_name, VFXSystem.VFX_TYPE.RUNNING)
		
		# 2. 加载弹道场景
		# append projectile vfx instance to project instance
		
		var projectile_instance: Node3D = projectile_res.instantiate()
		projectile_instance.source = source
		projectile_instance.target = target
		projectile_instance.fire_pos = get_fire_pos(source)
		projectile_instance.add_child(vfx_projectile_ins) 
		source.add_child(projectile_instance) 
		
		
		# 3. load projectile vfx destory scene instance
		var signal_name = str(projectile_instance.get_instance_id())
		self.add_user_signal(signal_name, [{"name": "pos", "type": TYPE_VECTOR3}])
		var signal_projectile = Signal(self, signal_name)
		#var ps_instance: ProjectileSignal = ProjectileSignal.new()
		
		var temp_conn: Callable = func(projectile_instance, signal_projectile) -> void:
			var pos = projectile_instance.global_position
			#emit_signal(str(projectile_instance.get_instance_id()), pos)
			signal_projectile.emit(pos)
		
		
		projectile_instance.tree_exiting.connect(
			temp_conn.bind(projectile_instance, signal_projectile),
			CONNECT_ONE_SHOT
		)

		var vfx_projectile_destory_pos = await signal_projectile
		print("global position: (%f, %f, %f)" % [vfx_projectile_destory_pos.x, vfx_projectile_destory_pos.y, vfx_projectile_destory_pos.z])
		
		var vfx_projectile_destory_ins: Node3D = (SystemUtil.vfx_system as VFXSystem).create_vfx(vfx_projectile_name, VFXSystem.VFX_TYPE.DESTORY)
		vfx_projectile_destory_ins.global_position = vfx_projectile_destory_pos
		#self.add_child(vfx_projectile_destory_ins) 	# 当前节点类型为 Node，self.add_child 可能无法正常工作
		get_parent().add_child(vfx_projectile_destory_ins) 





# 寻找 fire_pos 节点，定义在 Metadata 当中（has_key fire_pos）
func get_fire_pos(source):
	var fire_pos_nodes: Array = find_nodes_by_meta(source, "fire_pos")
	if fire_pos_nodes.size() == 1:
		return fire_pos_nodes[0].global_position
	
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
