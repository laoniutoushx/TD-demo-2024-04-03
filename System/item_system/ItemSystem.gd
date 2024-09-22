extends Node
class_name ItemSystem



func _ready() -> void:
	# 在系统启动时，初始化所有 item template resource，将起保存在 container 当中
	CommonUtil.load_resources_to_container_from_directory("res://System/item_system/resources/", ItemManager.container())
	pass

# generate item 
func generate_item(item_code: String, p: Vector3) -> ItemDomain:
	# load item res
	var item_res: ItemResource = ItemManager.got(item_code)
	

	
	return null


# Inner Class
# control item data
class ItemManager:

	static var _item_res_container = {}    # code => ItemResource
	static var _item_domain_container = {} # id => ItemDomain


	static func put(k: String, v: Object) -> Object:
		_item_domain_container[k] = v
		return v


	static func got(k: String) -> Object:
		return _item_domain_container[k]


	# 获取容器
	static func container() -> Dictionary:
		return _item_res_container
