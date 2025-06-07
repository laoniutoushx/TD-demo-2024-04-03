class_name CommonUtil extends RefCounted


# get main scene tree
static func await_get_root_node() -> Node:
	if Engine.get_main_loop().root.is_inside_tree():
		Constants.ROOT_NODE = Engine.get_main_loop().root
	else:
		while Constants.GLB_TICKET > 2.0:
			return await_get_root_node()
	return Constants.ROOT_NODE



static func await_timer(second, callback = func(): pass) -> void:
	if second is float or second is int:
		second = float(second)
		if second > 0:
			var timer = Timer.new()
			timer.one_shot = true


			var root = await_get_root_node()
			root.add_child(timer)
			timer.start(second)
			await timer.timeout

			# 回调
			callback.call()

			# 释放计时器
			timer.queue_free()



static func delay_execution(delay: float, callback: Callable):
	if delay > 0:
		var timer = Timer.new()
		timer.one_shot = true
		var root = await_get_root_node()
		root.add_child(timer)
		
		var callable: Callable = func(root: Node, timer: Timer, callback: Callable):
			callback.call()
			timer.queue_free()


		timer.timeout.connect(callable.bind(root, timer, callback), CONNECT_ONE_SHOT)
		timer.start(delay)



func _process(delta: float) -> void:
	Constants.GLB_TICKET += delta



static func get_all_mesh_instances(node: Node) -> Array[MeshInstance3D]:
	var mesh_instances = []
	if node is MeshInstance3D:
		mesh_instances.append(node)
	for child in node.get_children():
		mesh_instances += get_all_mesh_instances(child)
	return mesh_instances
	


static func get_first_node_by_node_type(node: Node, clazz: String, use_bfs: bool = false) -> Variant:
	if not is_instance_valid(node):
		return null
	
	if use_bfs:
		# 广度优先遍历 (默认)
		var queue: Array[Node] = [node]
		
		while queue.size() > 0:
			var current_node = queue.pop_front()
			
			# 检查当前节点是否匹配
			if current_node.is_class(clazz):
				return current_node
			
			# 将当前节点的所有子节点加入队列
			for child in current_node.get_children():
				if is_instance_valid(child):
					queue.push_back(child)
		
		return null
	else:
		# 深度优先遍历 (原方法)
		if node.is_class(clazz):
			return node
		else:
			for child in node.get_children():
				var _node = get_first_node_by_node_type(child, clazz, false)
				if _node != null and _node.is_class(clazz):
					return _node
				else:
					continue
		return null
	


static func get_first_node_by_node_name(node: Node, name: String, use_bfs: bool = false) -> Variant:
	if not is_instance_valid(node):
		return null
	
	if use_bfs:
		# 广度优先遍历 (默认)
		var queue: Array[Node] = [node]
		
		while queue.size() > 0:
			var current_node = queue.pop_front()
			
			# 检查当前节点名称是否匹配
			if current_node.name == name:
				return current_node
			
			# 将当前节点的所有子节点加入队列
			for child in current_node.get_children():
				if is_instance_valid(child):
					queue.push_back(child)
		
		return null
	else:
		# 深度优先遍历 (原方法)
		if node.name == name:
			return node
		else:
			for child in node.get_children():
				var _node = get_first_node_by_node_name(child, name, false)
				if _node != null and _node.name == name:
					return _node
				else:
					continue
		return null



static func get_first_parent_by_node_type(node: Node, clazz: String) -> Variant:
	if node == null: return
	if node.is_class(clazz):
		return node
	else:
		return get_first_parent_by_node_type(node.get_parent(), clazz)


# WARNING 注意每个实例化的场景，节点 name 必须唯一的，重复名称系统会加上后缀 @Num
static func get_first_parent_by_node_name(node: Node, name: String) -> Variant:
	if node == null: return
	print(node.name)
	if node.name == name:
		return node
	else:
		return get_first_parent_by_node_name(node.get_parent(), name)

# 获取当前节点到指定类型节点中间的所有节点（向上查找），clazz 为空默认查找 owner.clazz
static func get_all_parent_node_by_node_type(node: Node, clazz: String) -> Array[Variant]:
	if clazz == null:
		clazz = node.owner.gat_class()
	var parent_nodes = []
	if node == null:
		return parent_nodes
	if node.is_class(clazz):
		parent_nodes.append(node)
		return parent_nodes

	while node.get_parent() != null:
		node = node.get_parent()
		parent_nodes.append(node)
		if node.is_class(clazz):
			break
	return parent_nodes


## AABB


# 获取 transformed 之后的 aab
static func get_scaled_aabb(mesh_instance: MeshInstance3D) -> AABB:
	if not mesh_instance:
		return AABB()

		
	var local_aabb := mesh_instance.mesh.get_aabb()
	var corners := PackedVector3Array()
	corners.resize(8)
	
	# 获取本地AABB的8个角点
	corners[0] = local_aabb.position
	corners[1] = Vector3(local_aabb.position.x + local_aabb.size.x, local_aabb.position.y, local_aabb.position.z)
	corners[2] = Vector3(local_aabb.position.x, local_aabb.position.y + local_aabb.size.y, local_aabb.position.z)
	corners[3] = Vector3(local_aabb.position.x, local_aabb.position.y, local_aabb.position.z + local_aabb.size.z)
	corners[4] = local_aabb.position + local_aabb.size
	corners[5] = Vector3(local_aabb.position.x + local_aabb.size.x, local_aabb.position.y + local_aabb.size.y, local_aabb.position.z)
	corners[6] = Vector3(local_aabb.position.x + local_aabb.size.x, local_aabb.position.y, local_aabb.position.z + local_aabb.size.z)
	corners[7] = Vector3(local_aabb.position.x, local_aabb.position.y + local_aabb.size.y, local_aabb.position.z + local_aabb.size.z)
	
	# 转换到全局空间
	var global_transform := mesh_instance.global_transform
	var min_pos := global_transform * corners[0]
	var max_pos := min_pos
	
	for i in range(1, 8):
		var global_point := global_transform * corners[i]
		min_pos = min_pos.min(global_point)
		max_pos = max_pos.max(global_point)
	
	# 创建新的AABB并缓存
	var global_aabb := AABB(min_pos, max_pos - min_pos)

	
	return global_aabb


# 获取 transformed 之后的 AABB 的 height 高度
static func get_scaled_aabb_height(node: Node) -> float:
	var mesh_instance: MeshInstance3D = get_first_node_by_node_type(node, Constants.MeshInstance3D_CLZ)
	if mesh_instance:
		var global_scaled_aabb: AABB = get_scaled_aabb(mesh_instance)
		return global_scaled_aabb.size.y
	else:
		return 0


static func get_basic_scale(node: Node) -> Vector3:
	var basis = node.global_transform.basis
	return basis.get_scale()



static func create_outline_mesh(mesh_instance: MeshInstance3D, outline_width: float = 0.05) -> ArrayMesh:
	var original_mesh = mesh_instance.mesh
	var st = SurfaceTool.new()
	st.create_from(original_mesh, 0)
	
	var arrays = st.commit_to_arrays()
	var vertices = arrays[Mesh.ARRAY_VERTEX]
	var normals = arrays[Mesh.ARRAY_NORMAL]
	
	for i in range(vertices.size()):
		vertices[i] += normals[i] * outline_width
	
	arrays[Mesh.ARRAY_VERTEX] = vertices
	
	var outline_mesh = ArrayMesh.new()
	outline_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	
	return outline_mesh




# 计算相关
# "det == 0"	 look at 共线错误修复
static func safe_look_at(node: Node3D, from: Vector3, to: Vector3, up: Vector3 = Vector3.UP) -> void:
	var direction = (to - from).normalized()

	# 检查是否和 up 向量共线（即点积接近 ±1）
	if abs(direction.dot(up)) > 0.999:
		up = Vector3.FORWARD if abs(direction.dot(Vector3.FORWARD)) < 0.999 else Vector3.RIGHT

	node.look_at(to, up)


# static func safe_look_at(node: Node3D, from: Vector3, to: Vector3) -> void:
# 	var direction := (to - from).normalized()
# 	if direction.length() < 0.001:
# 		return # 避免无效方向

# 	# 计算安全的 up 向量：尝试默认 UP，如果共线则用 FORWARD，再不行用 RIGHT
# 	var up := Vector3.UP
# 	if abs(direction.dot(up)) > 0.99:
# 		up = Vector3.FORWARD
# 		if abs(direction.dot(up)) > 0.99:
# 			up = Vector3.RIGHT

# 	# 确保 up 与方向正交
# 	var right = direction.cross(up).normalized()
# 	up = right.cross(direction).normalized()

# 	node.global_transform = Transform3D().looking_at(to, up).translated(from)





# 属性拷贝
static func bean_properties_copy(src: Object, tar: Object) -> Variant:
	# 获取源对象的属性列表
	var src_properties = src.get_property_list()
	
	# 遍历每个属性
	for property in src_properties:
		var prop_name = property.name
		
		# 过滤掉内置属性，只复制用户自定义的属性
		if property.usage & PROPERTY_USAGE_SCRIPT_VARIABLE != 0:
			# 尝试从目标对象获取属性值并复制
			if tar.has_method("get") and tar.has_method("set"):
				if tar.get_indexed(prop_name) != null:
					var value = src.get(prop_name)
					if value != null:
						tar.set(prop_name, value)
	
	return tar


# 资源处理
# common resource get
static func get_resource(file_name):
	if ResourceLoaderUtil.contains_resource(file_name):
		return ResourceLoaderUtil.get_resource(file_name)

# common resource load
static func load_resources_to_container_from_directory(path: String, container = null) -> void:
	ResourceLoaderUtil.load_resources_to_container_from_directory(path, container)


# Inner Class
# Resource Loader
class ResourceLoaderUtil:
	static var _common_container = {}

	# 主函数：加载指定目录下的所有 .tres 和 .tscn 文件到指定容器（不指定容器则加载到默认 自定义容器中 _common_container ）
	static func load_resources_to_container_from_directory(path, container = null) -> Dictionary:
		var dir = DirAccess.open(path)
		
		if dir:
			dir.list_dir_begin()
			var file_name = dir.get_next()
			while file_name != "":
				if dir.current_is_dir():
					# 递归处理子目录
					load_resources_to_container_from_directory(dir.get_current_dir() + "/" + file_name, container if container != null else _common_container)
				elif (file_name.ends_with(".tres") or file_name.ends_with(".tscn") 
					or file_name.ends_with("png") or file_name.ends_with("svg")
					or file_name.ends_with("wav") or file_name.ends_with("mp3")
					):
					# 加载资源
					var full_path = path + "/" + file_name
					var resource = load(full_path)
					if resource:
						(container if container != null else _common_container)[full_path.get_file().get_basename()] = resource
						print("Loaded: " + file_name)
				file_name = dir.get_next()
			dir.list_dir_end()
		else:
			print("An error occurred when trying to access the path.")
		
		return container if container else _common_container


	# 获取加载的资源
	static func get_resource(file_name):
		return _common_container.get(file_name)

	# 是否存在
	static func contains_resource(file_name):
		return _common_container.has(file_name)


	# 打印所有加载的资源
	static func print_loaded_resources():
		for key in _common_container.keys():
			print(key + ": " + str(_common_container[key]))



## 二进制相关逻辑处理（多选）
# 处理 export_flags 相关数据
static func is_flag_set(flag: int, bit_set: int) -> bool:
	return (int(pow(2, flag)) & bit_set) != 0

# 改进的 is_flag_set，使用位移运算，更高效
# static func is_flag_set(flag: int, bit_set: int) -> bool:
# 	return (1 << flag) & bit_set != 0	

static func set_flag(flag: int) -> int:
	return int(pow(2, flag))

static func has_overlapping_flags(bit_set1: int, bit_set2: int) -> bool:
	return (bit_set1 & bit_set2) != 0	

# 将传入 bit_set 从 10 进制转为 2 进制，并取出二进制位为 1 的位置，根据位置获取 type 中对应的枚举值，拼接成字符串返回
static func bit_set_to_str(bit_set: int, type_dict: Dictionary, split_str: String = ', ') -> String:
	var type = get_enum_values_as_array(type_dict)
	var binary_str = int_to_binary_string(bit_set)
	var result = []

	for i in range(binary_str.length()):
		# 从低位到高位，检查是否为 1
		if binary_str[binary_str.length() - i - 1] == "1":
			if i < type.size():
				result.append(type[i])

	return split_str.join(result)


# 将枚举类型的值提取为数组
static func get_enum_values_as_array(enum_type: Dictionary) -> Array:
	if typeof(enum_type) == 27:	# TYPE_DICTIONARY corresponds to 27
		return enum_type.keys()
	return []


# 将整数转换为二进制字符串
static func int_to_binary_string(value: int) -> String:
	var binary_str = ""
	while value > 0:
		binary_str = str(value % 2) + binary_str
		value = value / 2

	# Pad the binary string to 32 bits manually
	var padding_length = max(0, 32 - binary_str.length())
	var padding = "0".repeat(padding_length)
	return padding + binary_str


# 集合工具类
static func arr_to_map(arr: Array) -> Dictionary:
	var map = {}
	for item in arr:
		map[item.get_instance_id()] = item
	return map



# 组件相关
static func get_component_by_name(reference: Node, name: String) -> Variant:
	return reference.find_child(name, true)




##  自定义计时器 Cimer
# 
static func create_timer(wait_time: float, callback: Callable = func(): pass, flag: int = CONNECT_ONE_SHOT) -> Cimer:
	return Cimer.new(wait_time, callback, flag)

# 可以延长时间的计时器（自定义）
class Cimer extends Node:
	var wait_time: float
	var time_left: float
	var callback: Callable
	var flag: int

	signal timeout

	func _init(_wait_time: float, callback: Callable, flag: int) -> void:
		self.wait_time = _wait_time
		self.time_left = _wait_time
		self.callback = callback
		self.flag = flag
		


	func _ready() -> void:
		set_process(false)


	func bind_callback(callback: Callable) -> void:
		self.callback = callback

	
	func start() -> void:
		set_process(true)

	func stop() -> void:
		set_process(false)

	func is_running() -> bool:
		return is_processing()

	func add_time(time: float) -> void:
		wait_time += time
		time_left += time

	func _process(delta: float) -> void:
		if time_left > 0:
			time_left -= delta

			if flag == CONNECT_PERSIST:
				self.callback.call()


		else:
			set_process(false)
			callback.call()
			timeout.emit()
			
			# 延迟释放
			await CommonUtil.await_timer(2)
			queue_free()

# await cimer
static func await_cimer(wait_time: float, callback: Callable = func(): pass, flag: int = CONNECT_ONE_SHOT) -> void:
	var cimer = create_timer(wait_time, callback, flag)
	cimer.start()

	await cimer.timeout



# 声音播放
static func play_audio(place: Variant, audio_name: String, volume_db: float = 1.0):
	# 创建 AudioStreamPlayer 节点
	var audio_player = AudioStreamPlayer.new()
	
	# 加载音频资源
	var sound_effect = get_resource(audio_name)
	
	# 设置音频资源
	audio_player.stream = sound_effect
	
	# 将节点添加到场景中
	if is_instance_valid(place):
		place.add_child(audio_player)
	
	# 播放音频
	audio_player.play()
	
	# 播放完成后自动释放节点
	audio_player.finished.connect(audio_player.queue_free)



# 寻找 fire_pos 节点，定义在 Metadata 当中（has_key fire_pos）
static func get_fire_pos(source) -> Marker3D:
	if source is Turret and source.fire_poses and source.fire_poses.size() > 0:
		return source.fire_poses[0]


	var fire_pos_nodes: Array = find_nodes_by_meta(source, "fire_pos")
	if fire_pos_nodes and fire_pos_nodes.size() == 0:
		return source
	
	# TODO 如果有多个发射位置，默认返回第一个，（后续有其他逻辑时处理）
	return fire_pos_nodes[0]


static func find_nodes_by_meta(source: Node, meta_key: String) -> Array:
	return _recursive_find_nodes_by_meta(source, meta_key)	


static func _recursive_find_nodes_by_meta(node: Node, meta_key: String) -> Array:
	var result = []
	if node.has_meta(meta_key):
		result.append(node)
	for child in node.get_children():
		result += _recursive_find_nodes_by_meta(child, meta_key)
	return result			





# 将数字转换为中文数字的函数
static func number_to_chinese(num: int) -> String:
	if num == 0:
		return "零"
	
	var units = ["", "十", "百", "千"]
	var digits = ["", "一", "二", "三", "四", "五", "六", "七", "八", "九"]
	
	var result = ""
	var str_num = str(num)
	var length = str_num.length()
	
	for i in range(length):
		var digit = int(str_num[i])
		var unit_index = length - i - 1
		
		if digit != 0:
			result += digits[digit]
			if unit_index > 0:
				result += units[unit_index]
	
	# 处理特殊情况（如"一十"简化为"十"）
	if result.begins_with("一十"):
		result = result.substr(1)
	
	return result