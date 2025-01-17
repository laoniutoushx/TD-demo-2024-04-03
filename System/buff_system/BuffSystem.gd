class_name BuffSystem extends Node



func _ready() -> void:
	SystemUtil.buff_system = self
	# 在系统启动时，初始化所有 item template resource，将起保存在 container 当中
	CommonUtil.load_resources_to_container_from_directory("res://System/buff_system/resources/", BuffManager.container())

	# listener event
	SignalBus.buff_enter.connect(_on_buff_enter)
	SignalBus.buff_exit.connect(_on_buff_exit)



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
	var buff_instance_map = {}
	var buff_reses
	if ref is SkillMetaResource:
		buff_reses = (ref as SkillMetaResource).skill_buff_config

	if ref is ItemResource:
		buff_reses = (ref as ItemResource).item_buff_config

	if buff_reses == null:
		return {}
	
	for buff_res in buff_reses:
		# 1. 创建 buff
		
		if buff_res.buff_script:
			var buff_instance: Buff = buff_res.buff_script.new()

			# 2. 初始化 buff
			buff_instance = CommonUtil.bean_properties_copy(buff_res, buff_instance)
			buff_instance.reference_instance = unit

			print("value dir %s" % str(buff_instance.value_dir))
			
			buff_instance.res = buff_res

			# 保存实例
			unit.buff_map[buff_instance.get_instance_id()] = buff_instance
			buff_instance_map[buff_instance.get_instance_id()] = buff_instance


	return buff_instance_map


# _on_buff_enter
func _on_buff_enter(buff: Buff):

	pass

# _on_buff_exit
func _on_buff_exit(buff: Buff):

	pass


# buff apply 
func apply(buff: Buff, reference: Variant):
	# buff apply
	if buff.apply(reference):
		# 开启计时器
		if buff.cooldown > 0 and buff.cool_down_timer:
			buff.cool_down_timer.start()

		# 挂接 buff
		if reference is BaseUnit:
			reference.buff_map[buff.get_instance_id()] = buff

		if reference is Skill:
			(reference as Skill).unit.buff_map[buff.get_instance_id()] = buff

		if reference is Item:
			(reference as Item).unit.buff_map[buff.get_instance_id()] = buff


# buff remove
func remove(buff: Buff):
	var reference = buff.reference_instance

	if reference is BaseUnit:
		reference.buff_map.erase([buff.get_instance_id()])

	if reference is Skill:
		(reference as Skill).unit.erase([buff.get_instance_id()])

	if reference is Item:
		(reference as Item).unit.erase([buff.get_instance_id()])

	if buff.remove():
		buff.queue_free()



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
