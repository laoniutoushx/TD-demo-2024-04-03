class_name CommonUtil
extends Node

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
	pass


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
	var local_aabb = mesh_instance.mesh.get_aabb()
	var basis = mesh_instance.global_transform.basis
	var scale = basis.get_scale()
	var scaled_aabb = AABB(local_aabb.position * scale, local_aabb.size * scale)
	return scaled_aabb



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
					load_resources_to_container_from_directory(path.plus_file(file_name), container if container != null else _common_container)
				elif file_name.ends_with(".tres") or file_name.ends_with(".tscn"):
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
