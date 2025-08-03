class_name ItemSystem extends Node3D



func _ready() -> void:
	SystemUtil.item_system = self
	# 在系统启动时，初始化所有 item template resource，将起保存在 container 当中
	CommonUtil.load_resources_to_container_from_directory("res://System/item_system/resources/", ItemManager.container())


# generate item 
func generate_item(item_code: String, p: Vector3) -> Item:
	# load item res
	var item_res: ItemResource = ItemManager.got(item_code)
	

	
	return null

	
# 实例化 技能
func initialize_items(source_unit: BaseUnit, item_metas: Array[ItemResource]) -> Dictionary:
	var item_map: Dictionary = {}
	for idx in range(item_metas.size()):
		var item: Item = _initialize_item(source_unit, item_metas[idx], idx)

		if item != null:
			# 初始化 buff
			SystemUtil.buff_system.init_buff_for_unit_by_res(item.item_res, item)

			item.unit = source_unit
			item_map[item.code] = item

			# add to unit tree
			item.name = item.code
			source_unit.add_child(item)
			item.add_child(item.item_script_instance)

	return item_map
	
 # 实例化
func _initialize_item(source_unit: BaseUnit, item_meta_res: ItemResource, idx: int = 0) -> Item:
	if item_meta_res != null:
		var item: Item = Item.new()
		item.unit = source_unit
		CommonUtil.bean_properties_copy(item_meta_res, item)
		# 手动赋值 skill_script
		item.item_script = item_meta_res.item_script
		item.item_res = item_meta_res
		item.sort = idx
		if item.code == null:
			printerr("ERROR: item code not define")
			
		# skill id
		item.id = UUID.v4()

		# 实例化技能脚本
		# assert(skill.skill_script != null, "skill script not define")
		if item.item_script != null:
			item.item_script_instance = item.item_script.new()
		else:
			printerr("ERROR: item script not define")
		
		return item
	
	return null
	


func pick_up(source: BaseUnit, item: TreasureChest) -> Item:
	# 获取 item
	var drop_item: DropItem = item.drop_item
	if drop_item == null:
		return null
	
	# 获取 item resource
	var item_res: ItemResource = CommonUtil.get_resource(drop_item.item_name, ItemManager.container())
	if item_res == null:
		printerr("ERROR: item resource not found for %s" % drop_item.item_name)
		return null
	
	# 实例化 item
	var new_item: Item = _initialize_item(source, item_res)
	if new_item == null:
		printerr("ERROR: failed to initialize item for %s" % drop_item.item_name)
		return null

	# 初始化 buff
	SystemUtil.buff_system.init_buff_for_unit_by_res(item_res, new_item)

	new_item.unit = source
	source.item_map[new_item.code] = new_item

	# add to unit tree
	new_item.name = new_item.code
	source.add_child(new_item)
	new_item.add_child(new_item.item_script_instance)

	# action bar item bar 处理
	# 获取一个空白的 item slot
	SOS.main.level_controller._cur_scene.action_bar.item_bar_comp.pick_up(new_item)


	# 删除掉宝箱
	item.queue_free()


	return new_item




# Inner Class
# control item data
class ItemManager:

	static var _item_res_container = {}    # code => ItemResource
	static var _item_domain_container = {} # id => Item


	static func put(k: String, v: Object) -> Object:
		_item_domain_container[k] = v
		return v


	static func got(k: String) -> Object:
		return _item_domain_container[k]


	# 获取容器
	static func container() -> Dictionary:
		return _item_res_container
