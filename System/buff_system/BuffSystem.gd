class_name BuffSystem extends Node



func _ready() -> void:
	SystemUtil.buff_system = self
	# 在系统启动时，初始化所有 item template resource，将起保存在 container 当中
	CommonUtil.load_resources_to_container_from_directory("res://System/buff_system/resources/", BuffManager.container())



## 创建 buff
func create_buff_by_code(code: String) -> Object:
	var item_res = BuffManager.got(code)
	if item_res == null:
		return null
	var item = BuffManager.put(item_res.id, item_res.instance())
	return item





## 初始化 buff（通过 skill or item）
## ref skill or item resource
func init_buff_for_unit_by_res(ref: Variant, unit: BaseUnit) -> Dictionary:
	var buff_instances = {}
	var buff_reses
	if ref is SkillMetaResource:
		buff_reses = (ref as SkillMetaResource).skill_buff_config

	if ref is ItemResource:
		buff_reses = (ref as ItemResource).item_buff_config

	if buff_reses == null:
		return {}
	
	for buff_res in buff_reses:
		# 1. 创建 buff
		var buff_script: Script = buff_res.buff_script
		var buff_instance: Buff = buff_script.new()

		# 2. 初始化 buff
		buff_instance = CommonUtil.bean_properties_copy(buff_res, buff_instance)
		buff_instance.ref = unit

		unit.buff_map[buff_instance.get_instance_id()] = buff_instance
		buff_instances[buff_instance.get_instance_id()] = buff_instance

	return buff_instances




# apply apply 
func apply(buff: Buff):
	var entity = buff.entity
	if entity:
		var prop: String = buff.prop
		var value = entity.get(prop)



		# if buff.value_unit == BuffResource.VALUE_UNIT.PERCENT:
	

	buff.apply()

	pass






# Inner Class
# control item data
class BuffManager:

	static var _buff_res_container = {}    # code => ItemResource
	static var _buff_domain_container = {} # id => Item


	static func put(k: String, v: Object) -> Object:
		_buff_domain_container[k] = v
		return v


	static func got(k: String) -> Object:
		return _buff_domain_container[k]


	# 获取容器
	static func container() -> Dictionary:
		return _buff_res_container
