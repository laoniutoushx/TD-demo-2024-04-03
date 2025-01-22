class_name CommonUtil extends Node


# get main scene tree
static func await_get_root_node() -> Node:
	if Engine.get_main_loop().root.is_inside_tree():
		Constants.ROOT_NODE = Engine.get_main_loop().root
	else:
		while Constants.GLB_TICKET > 2.0:
			return await_get_root_node()
	return Constants.ROOT_NODE



static func await_timer(second):
	if second is float or second is int:
		second = float(second)
		if second > 0:
			var timer = Timer.new()
			timer.one_shot = true
			var root = await_get_root_node()
			root.add_child(timer)
			timer.start(second)
			await timer.timeout
			root.remove_child(timer)
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
	

static func get_first_node_by_node_type(node: Node, clazz: String) -> Variant:
	#print(node.get_class(), str(clazz))
	if is_instance_valid(node):
		if node.is_class(clazz):
			return node
		else:
			for child in node.get_children():
				var _node = get_first_node_by_node_type(child, clazz)
				if _node != null and _node.is_class(clazz):
					return _node
				else:
					continue
	return null
	
	
static func get_first_node_by_node_name(node: Node, name: String) -> Variant:
	#print(node.get_class(), name)
	if node.name == name:
		return node
	else:
		for child in node.get_children():
			var _node = get_first_node_by_node_name(child, name)
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



# 获取 transformed 之后的 aab
static func get_scaled_aabb(mesh_instance: MeshInstance3D) -> AABB:
	var mesh: Mesh = mesh_instance.mesh

	var local_aabb = mesh_instance.mesh.get_aabb()
	var basis = mesh_instance.global_transform.basis
	var scale = basis.get_scale()

	# print("local_aabb : %s" % local_aabb)
	# print("basis : %s" % basis)
	# print("scale : %s" % scale)

	var scaled_aabb = AABB(local_aabb.position * scale, local_aabb.size * scale)
	# print("scaled_aabb : %s" % scaled_aabb)
	return scaled_aabb
	
# 获取 transformed 之后的 AABB
# static func get_scaled_aabb(mesh_instance: MeshInstance3D) -> AABB:
# 	var local_aabb = mesh_instance.mesh.get_aabb()  # 获取局部包围盒
# 	var transform = mesh_instance.global_transform  # 获取全局变换
# 	var scale = transform.basis.get_scale()  # 获取缩放因子

# 	# 计算缩放后的包围盒
# 	var scaled_position = local_aabb.position * scale
# 	var scaled_size = local_aabb.size * scale
# 	var scaled_aabb = AABB(scaled_position, scaled_size)

# 	return scaled_aabb


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


# common resource get
static func get_resource(file_name):
	if ResourceLoaderUtil.contains_resource(file_name):
		return ResourceLoaderUtil.get_resource(file_name)

# common resource load
static func load_resources_to_container_from_directory(path: String, container: Dictionary):
	ResourceLoaderUtil.load_resources_to_container_from_directory(path, container)



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



# Inner Class
# Resource Loader
class ResourceLoaderUtil:
	static var _common_container = {}

	# 主函数：加载指定目录下的所有 .tres 和 .tscn 文件到指定容器（不指定容器则加载到默认 自定义容器中 _common_container ）
	static func load_resources_to_container_from_directory(path, container: Dictionary) -> Dictionary:
		var dir = DirAccess.open(path)
		
		if dir:
			dir.list_dir_begin()
			var file_name = dir.get_next()
			while file_name != "":
				if dir.current_is_dir():
					# 递归处理子目录
					load_resources_to_container_from_directory(dir.get_current_dir() + "/" + file_name, container if container != null else _common_container)
				elif file_name.ends_with(".tres") or file_name.ends_with(".tscn") or file_name.ends_with("png") or file_name.ends_with("svg"):
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




# 自定义计时器
static func create_timer(wait_time: float) -> Cimer:
	return Cimer.new(wait_time)


class Cimer extends Node:
	var wait_time: float
	var time_left: float

	signal timeout

	func _init(_wait_time: float) -> void:
		self.wait_time = _wait_time
		self.time_left = _wait_time

	func _ready() -> void:
		set_process(false)

	
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
		else:
			timeout.emit()
			set_process(false)

			await CommonUtil.await_timer(2)
			queue_free()
			