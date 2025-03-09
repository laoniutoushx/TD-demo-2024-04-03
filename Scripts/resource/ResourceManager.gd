class_name ResourceManager extends Node


@export var extensions: Array[String] = []
@export var res_paths: Array[String] = []

# func _ready() -> void:
# 	if extensions.size() > 0:
# 		set_supported_extensions(extensions)
# 		if res_paths.size() > 0:
# 			for res_path: String in res_paths:
# 				load_resources_in_directory(res_path)
			


# 存储加载的资源
# Dictionary 结构: 
# {
#   "file_name": resource,
#   "file_path": resource
# }
var _loaded_resources: Dictionary = {}

# 支持的文件类型
var _supported_extensions: Array[String] = []

# 设置支持的文件扩展名
func set_supported_extensions(extensions: Array[String]) -> void:
	_supported_extensions = extensions

# 加载指定目录下的所有支持类型的资源
func load_resources_in_directory(path: String) -> void:
	var dir = DirAccess.open(path)
	if not dir:
		printerr("无法打开目录：", path)
		return
	
	_scan_directory(dir, path)

# 递归扫描目录
func _scan_directory(dir: DirAccess, current_path: String) -> void:
	dir.list_dir_begin()
	var file_name = dir.get_next()
	
	while file_name != "":
		var full_path = current_path.path_join(file_name)
		
		if dir.current_is_dir():
			var subdir = DirAccess.open(full_path)
			if subdir:
				_scan_directory(subdir, full_path)
		else:
			var extension = file_name.get_extension()
			if _supported_extensions.has(extension):
				_load_resource(full_path, file_name)
		
		file_name = dir.get_next()
	
	dir.list_dir_end()

# 加载单个资源
func _load_resource(file_path: String, file_name: String) -> void:
	var resource = load(file_path)
	if resource:
		var base_name = file_name.get_basename()
		_loaded_resources[base_name] = resource
		_loaded_resources[file_path] = resource
	else:
		printerr("无法加载资源：", file_path)

# 通过文件名获取资源
func get_resource_by_name(name: String) -> Resource:
	if _loaded_resources.has(name):
		return _loaded_resources[name]
	printerr("找不到资源：", name)
	return null

# 通过路径获取资源
func get_resource_by_path(path: String) -> Resource:
	if _loaded_resources.has(path):
		return _loaded_resources[path]
	printerr("找不到资源：", path)
	return null

# 获取所有已加载资源的文件名
func get_all_resource_names() -> Array:
	var names: Array = []
	for key in _loaded_resources.keys():
		if not key.begins_with("res://"):
			names.append(key)
	return names

# 获取所有已加载资源的路径
func get_all_resource_paths() -> Array:
	var paths: Array = []
	for key in _loaded_resources.keys():
		if key.begins_with("res://"):
			paths.append(key)
	return paths

# 清除所有已加载的资源
func clear_resources() -> void:
	_loaded_resources.clear()
