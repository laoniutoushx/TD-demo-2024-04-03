class_name CommonUtil extends RefCounted

# ===============================
# 场景树相关方法
# ===============================

## 异步获取主场景树根节点
## 确保在场景树准备完成后才返回根节点
## @return Node 主场景树的根节点
static func await_get_root_node() -> Node:
	# 检查主循环的根节点是否已经在场景树中
	if Engine.get_main_loop().root.is_inside_tree():
		Constants.ROOT_NODE = Engine.get_main_loop().root
	else:
		# 如果还没准备好，等待一段时间后递归调用
		while Constants.GLB_TICKET > 2.0:
			return await_get_root_node()
	return Constants.ROOT_NODE

## 异步计时器方法
## 创建一个临时计时器，等待指定时间后执行回调
## @param second 等待的秒数（float或int）
## @param callback 计时器结束后的回调函数
static func await_timer(second, callback = func(): pass) -> void:
	# 确保时间参数是有效的数值类型
	if second is float or second is int:
		second = float(second)
		if second > 0:
			# 创建一次性计时器
			var timer = Timer.new()
			timer.one_shot = true

			# 将计时器添加到根节点
			var root = await_get_root_node()
			root.add_child(timer)
			timer.start(second)
			
			# 等待计时器超时
			await timer.timeout

			# 执行回调函数
			callback.call()

			# 释放计时器资源
			timer.queue_free()

## 延迟执行方法
## 在指定延迟后执行回调函数，使用信号连接方式
## @param delay 延迟时间（秒）
## @param callback 要执行的回调函数
static func delay_execution(delay: float, callback: Callable):
	if delay > 0:
		# 创建一次性计时器
		var timer = Timer.new()
		timer.one_shot = true
		var root = await_get_root_node()
		root.add_child(timer)
		
		# 创建回调包装函数，在执行完回调后清理计时器
		var callable: Callable = func(root: Node, timer: Timer, callback: Callable):
			callback.call()
			timer.queue_free()

		# 连接超时信号，设置为一次性连接
		timer.timeout.connect(callable.bind(root, timer, callback), CONNECT_ONE_SHOT)
		timer.start(delay)

## 处理每帧更新
## 更新全局计时器变量
## @param delta 帧间隔时间
func _process(delta: float) -> void:
	Constants.GLB_TICKET += delta

# ===============================
# 节点查找相关方法
# ===============================

## 递归获取所有MeshInstance3D节点
## 深度优先遍历查找所有网格实例
## @param node 要搜索的起始节点
## @return Array[MeshInstance3D] 找到的所有MeshInstance3D节点数组
static func get_all_mesh_instances(node: Node) -> Array[MeshInstance3D]:
	var mesh_instances = []
	# 检查当前节点是否是MeshInstance3D
	if node is MeshInstance3D:
		mesh_instances.append(node)
	# 递归搜索所有子节点
	for child in node.get_children():
		mesh_instances += get_all_mesh_instances(child)
	return mesh_instances

## 根据节点类型查找第一个匹配的节点
## 支持广度优先和深度优先两种搜索方式
## @param node 要搜索的起始节点
## @param clazz 要查找的节点类型名称
## @param use_bfs 是否使用广度优先搜索（默认true）
## @return Variant 找到的第一个匹配节点，未找到返回null
static func get_first_node_by_node_type(node: Node, clazz: String, use_bfs: bool = true) -> Variant:
	if not is_instance_valid(node):
		return null
	
	if use_bfs:
		# 广度优先遍历（层序遍历）
		var queue: Array[Node] = [node]
		
		while queue.size() > 0:
			var current_node = queue.pop_front()
			
			# 检查当前节点是否匹配指定类型
			if current_node.is_class(clazz):
				return current_node
			
			# 将当前节点的所有子节点加入队列
			for child in current_node.get_children():
				if is_instance_valid(child):
					queue.push_back(child)
		
		return null
	else:
		# 深度优先遍历
		if node.is_class(clazz):
			return node
		
		# 递归搜索子节点
		for child in node.get_children():
			var result = get_first_node_by_node_type(child, clazz, false)
			if result != null:
				return result
		
		return null

## 根据节点类型查找所有匹配的节点
## 支持广度优先和深度优先两种搜索方式
## @param node 要搜索的起始节点
## @param clazz 要查找的节点类型名称
## @param use_bfs 是否使用广度优先搜索（默认true）
## @return Array[Node] 找到的所有匹配节点数组
static func get_all_nodes_by_node_type(node: Node, clazz: String, use_bfs: bool = true) -> Array[Node]:
	if not is_instance_valid(node):
		return []
	
	var result: Array[Node] = []
	
	if use_bfs:
		# 广度优先遍历
		var queue: Array[Node] = [node]
		
		while queue.size() > 0:
			var current_node = queue.pop_front()
			
			# 检查当前节点是否匹配
			if current_node.is_class(clazz):
				result.append(current_node)
			
			# 将当前节点的所有子节点加入队列
			for child in current_node.get_children():
				if is_instance_valid(child):
					queue.push_back(child)
	else:
		# 深度优先遍历
		if node.is_class(clazz):
			result.append(node)
		
		# 递归搜索子节点
		for child in node.get_children():
			var child_results = get_all_nodes_by_node_type(child, clazz, false)
			result.append_array(child_results)
	
	return result

## 根据节点名称查找第一个匹配的节点
## 支持广度优先和深度优先两种搜索方式
## @param node 要搜索的起始节点
## @param name 要查找的节点名称
## @param use_bfs 是否使用广度优先搜索（默认true）
## @return Variant 找到的第一个匹配节点，未找到返回null
static func get_first_node_by_node_name(node: Node, name: String, use_bfs: bool = true) -> Variant:
	if not is_instance_valid(node):
		return null
	
	if use_bfs:
		# 广度优先遍历
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
		# 深度优先遍历
		if node.name == name:
			return node
		
		# 递归搜索子节点
		for child in node.get_children():
			var result = get_first_node_by_node_name(child, name, false)
			if result != null:
				return result
		
		return null

## 根据节点类型向上查找第一个匹配的父节点
## 沿着父节点链向上搜索，直到找到匹配的类型
## @param node 开始搜索的节点
## @param clazz 要查找的父节点类型名称
## @return Variant 找到的第一个匹配的父节点，未找到返回null
static func get_first_parent_by_node_type(node: Node, clazz: String) -> Variant:
	if node == null: 
		return null
	if node.is_class(clazz):
		return node
	else:
		# 递归向上搜索父节点
		return get_first_parent_by_node_type(node.get_parent(), clazz)

## 根据节点名称向上查找第一个匹配的父节点
## WARNING: 注意每个实例化的场景，节点name必须唯一，重复名称系统会加上后缀@Num
## @param node 开始搜索的节点
## @param name 要查找的父节点名称
## @return Variant 找到的第一个匹配的父节点，未找到返回null
static func get_first_parent_by_node_name(node: Node, name: String) -> Variant:
	if node == null: 
		return null
	print(node.name)
	if node.name == name:
		return node
	else:
		# 递归向上搜索父节点
		return get_first_parent_by_node_name(node.get_parent(), name)

## 获取当前节点到指定类型节点中间的所有节点（向上查找）
## @param node 开始搜索的节点
## @param clazz 目标节点类型名称，为空时默认查找owner的类型
## @return Array[Variant] 从当前节点到目标节点的所有父节点数组
static func get_all_parent_node_by_node_type(node: Node, clazz: String) -> Array[Variant]:
	# 如果类型为空，使用owner的类型
	if clazz == null:
		clazz = node.owner.get_class()  # 修复了原代码中的拼写错误
	
	var parent_nodes = []
	if node == null:
		return parent_nodes
	
	# 如果当前节点已经是目标类型，直接返回
	if node.is_class(clazz):
		parent_nodes.append(node)
		return parent_nodes

	# 向上遍历父节点链
	while node.get_parent() != null:
		node = node.get_parent()
		parent_nodes.append(node)
		# 找到目标类型后停止
		if node.is_class(clazz):
			break
	
	return parent_nodes

# ===============================
# 描边效果相关方法
# ===============================

## 为单位的所有MeshInstance3D添加描边效果
## 遍历单位下的所有网格实例并应用描边材质
## @param unit 要添加描边的单位节点
## @param outline_material 描边材质
static func add_outline_to_unit(unit: Node3D, outline_material: Material):
	var mesh_nodes = CommonUtil.get_all_nodes_by_node_type(unit, Constants.MeshInstance3D_CLZ, false)
	
	for mesh_node in mesh_nodes:
		var mesh_instance = mesh_node as MeshInstance3D
		if mesh_instance != null:
			# 设置材质覆盖层来实现描边效果
			mesh_instance.material_overlay = outline_material

## 移除单位的所有描边效果
## 清除所有网格实例的材质覆盖层
## @param unit 要移除描边的单位节点
static func remove_outline_from_unit(unit: Variant):
	var mesh_nodes = CommonUtil.get_all_nodes_by_node_type(unit, Constants.MeshInstance3D_CLZ, false)
	
	for mesh_node in mesh_nodes:
		var mesh_instance = mesh_node as MeshInstance3D
		if mesh_instance != null:
			# 清除材质覆盖层
			mesh_instance.material_overlay = null

## 创建描边网格
## 根据原始网格创建一个稍微放大的描边网格
## @param mesh_instance 原始网格实例
## @param outline_width 描边宽度（默认0.05）
## @return ArrayMesh 创建的描边网格
static func create_outline_mesh(mesh_instance: MeshInstance3D, outline_width: float = 0.05) -> ArrayMesh:
	var original_mesh = mesh_instance.mesh
	var st = SurfaceTool.new()
	st.create_from(original_mesh, 0)
	
	# 获取网格数据
	var arrays = st.commit_to_arrays()
	var vertices = arrays[Mesh.ARRAY_VERTEX]
	var normals = arrays[Mesh.ARRAY_NORMAL]
	
	# 沿法线方向扩展顶点以创建描边效果
	for i in range(vertices.size()):
		vertices[i] += normals[i] * outline_width
	
	arrays[Mesh.ARRAY_VERTEX] = vertices
	
	# 创建新的网格
	var outline_mesh = ArrayMesh.new()
	outline_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	
	return outline_mesh

# ===============================
# AABB（轴对齐包围盒）相关方法
# ===============================

## 获取经过变换后的AABB包围盒
## 计算网格实例在全局坐标系中的包围盒
## @param mesh_instance 要计算AABB的网格实例
## @return AABB 全局坐标系中的包围盒
static func get_scaled_aabb(mesh_instance: MeshInstance3D) -> AABB:
	if not mesh_instance:
		return AABB()
	
	# 获取本地空间的AABB
	var local_aabb := mesh_instance.mesh.get_aabb()
	var corners := PackedVector3Array()
	corners.resize(8)
	
	# 计算本地AABB的8个角点
	corners[0] = local_aabb.position
	corners[1] = Vector3(local_aabb.position.x + local_aabb.size.x, local_aabb.position.y, local_aabb.position.z)
	corners[2] = Vector3(local_aabb.position.x, local_aabb.position.y + local_aabb.size.y, local_aabb.position.z)
	corners[3] = Vector3(local_aabb.position.x, local_aabb.position.y, local_aabb.position.z + local_aabb.size.z)
	corners[4] = local_aabb.position + local_aabb.size
	corners[5] = Vector3(local_aabb.position.x + local_aabb.size.x, local_aabb.position.y + local_aabb.size.y, local_aabb.position.z)
	corners[6] = Vector3(local_aabb.position.x + local_aabb.size.x, local_aabb.position.y, local_aabb.position.z + local_aabb.size.z)
	corners[7] = Vector3(local_aabb.position.x, local_aabb.position.y + local_aabb.size.y, local_aabb.position.z + local_aabb.size.z)
	
	# 将所有角点转换到全局空间
	var global_transform := mesh_instance.global_transform
	var min_pos := global_transform * corners[0]
	var max_pos := min_pos
	
	# 找到全局空间中的最小和最大点
	for i in range(1, 8):
		var global_point := global_transform * corners[i]
		min_pos = min_pos.min(global_point)
		max_pos = max_pos.max(global_point)
	
	# 创建全局AABB
	var global_aabb := AABB(min_pos, max_pos - min_pos)
	
	return global_aabb

## 获取经过变换后的AABB高度
## 计算节点在全局坐标系中的包围盒高度
## @param node 要计算高度的节点
## @return float 包围盒的高度值
static func get_scaled_aabb_height(node: Node) -> float:
	var mesh_instance: MeshInstance3D = get_first_node_by_node_type(node, Constants.MeshInstance3D_CLZ)
	if mesh_instance:
		var global_scaled_aabb: AABB = get_scaled_aabb(mesh_instance)
		return global_scaled_aabb.size.y
	else:
		return 0

## 获取节点的基础缩放值
## 从全局变换矩阵中提取缩放信息
## @param node 要获取缩放的节点
## @return Vector3 缩放向量
static func get_basic_scale(node: Node) -> Vector3:
	var basis = node.global_transform.basis
	return basis.get_scale()

# ===============================
# 变换和旋转相关方法
# ===============================

## 使用四元数插值实现安全的平滑旋转
## 避免因无效向量导致的旋转问题
## @param node 要旋转的节点
## @param from 起始位置
## @param to 目标位置
## @param up 上方向向量（默认Vector3.UP）
## @param speed 旋转速度（0-1之间）
static func safe_look_at(node: Node3D, from: Vector3, to: Vector3, up: Vector3 = Vector3.UP, speed: float = 1.0) -> void:
	var direction = to - from
	var distance = direction.length()
	
	# 检查方向向量是否有效
	if distance < 0.001 or not direction.is_finite() or direction.is_equal_approx(Vector3.ZERO):
		return  # 跳过无效或接近零的方向向量
	
	direction = direction.normalized()
	
	# 选择合适的up向量，确保不与方向向量平行
	var fallback_up = Vector3.UP
	if abs(direction.dot(fallback_up)) > 0.999:
		fallback_up = Vector3.FORWARD if abs(direction.dot(Vector3.FORWARD)) < 0.999 else Vector3.RIGHT
	
	# 计算目标旋转基矩阵
	var target_basis = Basis.looking_at(direction, fallback_up)
	
	# 验证基矩阵是否有效
	if target_basis.is_finite() and abs(target_basis.determinant()) > 0.0001:
		# 使用四元数插值实现平滑旋转
		var current_quat = node.transform.basis.get_rotation_quaternion()
		var target_quat = target_basis.get_rotation_quaternion()
		var new_quat = current_quat.slerp(target_quat, speed)
		
		# 应用新的位置和旋转
		node.global_position = from
		node.transform.basis = Basis(new_quat)
	else:
		# 如果基矩阵无效，保持当前旋转
		print_debug("Invalid basis in safe_look_at: ", target_basis)

# ===============================
# 属性拷贝相关方法
# ===============================

## 对象属性拷贝
## 将源对象的脚本变量属性复制到目标对象
## @param src 源对象
## @param tar 目标对象
## @return Variant 返回目标对象
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

# ===============================
# 资源管理相关方法
# ===============================

## 通用资源获取方法
## 从资源容器中获取指定名称的资源
## @param file_name 资源文件名
## @return 资源对象，如果不存在则返回null
static func get_resource(file_name):
	if ResourceLoaderUtil.contains_resource(file_name):
		return ResourceLoaderUtil.get_resource(file_name)

## 通用资源加载方法
## 从指定目录加载资源到容器中
## @param path 资源目录路径
## @param container 资源容器（可选）
static func load_resources_to_container_from_directory(path: String, container = null) -> void:
	ResourceLoaderUtil.load_resources_to_container_from_directory(path, container)

# ===============================
# 内部类：资源加载工具
# ===============================

class ResourceLoaderUtil:
	## 默认资源容器
	static var _common_container = {}

	## 从指定目录加载所有资源文件到容器
	## 支持.tres、.tscn、.png、.svg、.wav、.mp3等格式
	## @param path 资源目录路径
	## @param container 目标容器（可选，默认使用_common_container）
	## @return Dictionary 返回使用的容器
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
					# 加载支持的资源格式
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

	## 从容器中获取指定名称的资源
	## @param file_name 资源文件名
	## @return 资源对象
	static func get_resource(file_name):
		return _common_container.get(file_name)

	## 检查容器中是否存在指定名称的资源
	## @param file_name 资源文件名
	## @return bool 是否存在
	static func contains_resource(file_name):
		return _common_container.has(file_name)

	## 打印所有已加载的资源
	## 用于调试和查看资源加载情况
	static func print_loaded_resources():
		for key in _common_container.keys():
			print(key + ": " + str(_common_container[key]))

# ===============================
# 位操作相关方法
# ===============================

## 检查指定位标志是否已设置
## @param flag 要检查的位标志索引
## @param bit_set 位集合
## @return bool 是否已设置该位标志
static func is_flag_set(flag: int, bit_set: int) -> bool:
	return (int(pow(2, flag)) & bit_set) != 0

## 设置指定位标志
## @param flag 要设置的位标志索引
## @return int 设置后的位值
static func set_flag(flag: int) -> int:
	return int(pow(2, flag))

## 检查两个位集合是否有重叠的标志
## @param bit_set1 第一个位集合
## @param bit_set2 第二个位集合
## @return bool 是否有重叠的位标志
static func has_overlapping_flags(bit_set1: int, bit_set2: int) -> bool:
	return (bit_set1 & bit_set2) != 0

## 将位集合转换为字符串表示
## 根据位集合中设置的位，从类型字典中获取对应的枚举值并拼接成字符串
## @param bit_set 位集合
## @param type_dict 类型字典
## @param split_str 分隔符（默认', '）
## @return String 拼接后的字符串
static func bit_set_to_str(bit_set: int, type_dict: Dictionary, split_str: String = ', ') -> String:
	var type = get_enum_values_as_array(type_dict)
	var binary_str = int_to_binary_string(bit_set)
	var result = []

	# 从低位到高位检查每一位
	for i in range(binary_str.length()):
		if binary_str[binary_str.length() - i - 1] == "1":
			if i < type.size():
				result.append(type[i])

	return split_str.join(result)

## 将枚举类型的值提取为数组
## @param enum_type 枚举类型字典
## @return Array 枚举值数组
static func get_enum_values_as_array(enum_type: Dictionary) -> Array:
	if typeof(enum_type) == 27:  # TYPE_DICTIONARY corresponds to 27
		return enum_type.keys()
	return []

## 将整数转换为32位二进制字符串
## @param value 要转换的整数
## @return String 32位二进制字符串
static func int_to_binary_string(value: int) -> String:
	var binary_str = ""
	while value > 0:
		binary_str = str(value % 2) + binary_str
		value = value / 2

	# 手动填充到32位
	var padding_length = max(0, 32 - binary_str.length())
	var padding = "0".repeat(padding_length)
	return padding + binary_str

# ===============================
# 集合工具相关方法
# ===============================

## 将数组转换为映射表
## 使用实例ID作为键，对象作为值
## @param arr 要转换的数组
## @return Dictionary 转换后的映射表
static func arr_to_map(arr: Array) -> Dictionary:
	var map = {}
	for item in arr:
		map[item.get_instance_id()] = item
	return map

## 获取 Dictionary 的第一个键值对
## @param dict 要操作的 Dictionary
## @return 返回包含 key 和 value 的 Dictionary，如果为空则返回 null
static func get_first_entry(dict: Dictionary) -> Dictionary:
	if dict.is_empty():
		return {}
	
	for key in dict:
		return {"key": key, "value": dict[key]}
	
	return {}

## 获取 Dictionary 的第一个键
## @param dict 要操作的 Dictionary
## @return 第一个键，如果为空则返回 null
static func get_first_key(dict: Dictionary) -> Variant:
	if dict.is_empty():
		return null
	
	return dict.keys()[0]

## 获取 Dictionary 的第一个值
## @param dict 要操作的 Dictionary
## @return 第一个值，如果为空则返回 null
static func get_first_value(dict: Dictionary) -> Variant:
	if dict.is_empty():
		return null
	
	return dict.values()[0]	




# ===============================
# 组件相关方法
# ===============================

## 根据名称获取组件
## 在引用节点下查找指定名称的子节点
## @param reference 引用节点
## @param name 组件名称
## @return Variant 找到的组件节点
static func get_component_by_name(reference: Node, name: String) -> Variant:
	return reference.find_child(name, true)

# ===============================
# 自定义计时器相关方法
# ===============================

## 创建自定义计时器
## @param wait_time 等待时间
## @param callback 回调函数
## @param flag 连接标志（默认CONNECT_ONE_SHOT）
## @return Cimer 自定义计时器实例
static func create_timer(wait_time: float, callback: Callable = func(): pass, flag: int = CONNECT_ONE_SHOT) -> Cimer:
	return Cimer.new(wait_time, callback, flag)

## 异步等待自定义计时器
## @param wait_time 等待时间
## @param callback 回调函数
## @param flag 连接标志（默认CONNECT_ONE_SHOT）
static func await_cimer(wait_time: float, callback: Callable = func(): pass, flag: int = CONNECT_ONE_SHOT) -> void:
	var cimer = create_timer(wait_time, callback, flag)
	cimer.start()
	await cimer.timeout

# ===============================
# 自定义计时器类
# ===============================

## 可以延长时间的自定义计时器类
## 支持暂停、恢复、延长时间等功能
class Cimer extends Node:
	var wait_time: float      # 等待时间
	var time_left: float      # 剩余时间
	var callback: Callable    # 回调函数
	var flag: int            # 连接标志

	signal timeout           # 超时信号

	## 构造函数
	## @param _wait_time 等待时间
	## @param callback 回调函数
	## @param flag 连接标志
	func _init(_wait_time: float, callback: Callable, flag: int) -> void:
		self.wait_time = _wait_time
		self.time_left = _wait_time
		self.callback = callback
		self.flag = flag

	## 节点准备完成时调用
	func _ready() -> void:
		set_process(false)  # 默认不处理

	## 绑定回调函数
	## @param callback 新的回调函数
	func bind_callback(callback: Callable) -> void:
		self.callback = callback

	## 启动计时器
	func start() -> void:
		set_process(true)

	## 停止计时器
	func stop() -> void:
		set_process(false)

	## 检查计时器是否正在运行
	## @return bool 是否正在运行
	func is_running() -> bool:
		return is_processing()

	## 增加等待时间
	## @param time 要增加的时间
	func add_time(time: float) -> void:
		wait_time += time
		time_left += time

	## 每帧处理计时器逻辑
	## @param delta 帧间隔时间
	func _process(delta: float) -> void:
		if time_left > 0:
			time_left -= delta
			
			# 如果是持续模式，每帧调用回调
			if flag == CONNECT_PERSIST:
				self.callback.call()
		else:
			# 计时器结束
			set_process(false)
			callback.call()
			timeout.emit()
			
			# 延迟释放资源
			await CommonUtil.await_timer(2)
			queue_free()

# ===============================
# 音频播放相关方法
# ===============================

## 播放音频
## 创建临时音频播放器播放指定音频，播放完成后自动清理
## @param place 放置音频播放器的节点
## @param audio_name 音频资源名称
## @param volume_db 音量（分贝）
static func play_audio(place: Variant, audio_name: String, volume_db: float = 0.0):
	# 创建音频播放器节点
	var audio_player = AudioStreamPlayer.new()
	
	# 加载音频资源
	var sound_effect = get_resource(audio_name)
	
	# 设置音频资源
	audio_player.stream = sound_effect
	
	# 将节点添加到场景中
	if is_instance_valid(place):
		place.add_child(audio_player)
	
	# 设置音量（分贝）- 必须在添加到场景后设置
	audio_player.volume_db = volume_db
	
	# 播放音频
	audio_player.play()
	
	# 播放完成后自动释放节点
	audio_player.finished.connect(audio_player.queue_free)

# ===============================
# 火力点相关方法
# ===============================

## 寻找火力点位置
## 从单位的火力点映射中获取当前火力点键对应的所有位置
## @param source 源单位
## @return Array 火力点位置数组
static func get_fire_pos(source) -> Array:
	# 获取fire_pos_map中current_fire_pos_key对应的所有pos(mark3d)
	if not is_instance_valid(source):
		return []

	if source is Turret and source.fire_poses and source.fire_poses.size() > 0:
		return source.fire_poses_map.get(source.current_fire_pos_key, null)

	return []

## 获取下一个火力点键（顺序轮换）
## 在火力点键列表中循环切换到下一个
## @param source 基础单位
## @return String 下一个火力点键
static func get_next_fire_pos_key(source: BaseUnit) -> String:
	var fire_poses_map = source.fire_poses_map  # 火力点映射
	var keys = fire_poses_map.keys()
	
	if keys.is_empty():
		return ""
	
	var current_key = source.current_fire_pos_key
	var current_index = keys.find(current_key)
	
	# 如果当前key不存在或者是最后一个，回到第一个
	if current_index == -1 or current_index >= keys.size() - 1:
		return keys[0]
	else:
		return keys[current_index + 1]

## 根据元数据查找节点
## 查找所有具有指定元数据键的节点
## @param source 源节点
## @param meta_key 元数据键名
## @return Array 匹配的节点数组
static func find_nodes_by_meta(source: Node, meta_key: String) -> Array:
	return _recursive_find_nodes_by_meta(source, meta_key)

## 递归查找具有指定元数据的节点
## 深度优先遍历查找所有具有指定元数据键的节点
## @param node 当前节点
## @param meta_key 元数据键名
## @return Array 匹配的节点数组
static func _recursive_find_nodes_by_meta(node: Node, meta_key: String) -> Array:
	var result = []
	# 检查当前节点是否有指定的元数据
	if node.has_meta(meta_key):
		result.append(node)
	# 递归检查所有子节点
	for child in node.get_children():
		result += _recursive_find_nodes_by_meta(child, meta_key)
	return result

# ===============================
# 数字转换相关方法
# ===============================

## 将数字转换为中文数字
## 支持0-9999的数字转换为对应的中文数字表示
## @param num 要转换的数字
## @return String 中文数字字符串
static func number_to_chinese(num: int) -> String:
	if num == 0:
		return "零"
	
	# 中文数字单位和数字映射
	var units = ["", "十", "百", "千"]
	var digits = ["", "一", "二", "三", "四", "五", "六", "七", "八", "九"]
	
	var result = ""
	var str_num = str(num)
	var length = str_num.length()
	
	# 从高位到低位处理每一位数字
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