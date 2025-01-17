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
func init_buff_for_unit_by_res(ref: Variant, ele: Variant) -> Dictionary:
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
			buff_instance.reference_instance = ele

			print("value dir %s" % str(buff_instance.value_dir))
			
			buff_instance.res = buff_res

			# 保存实例
			ele.buff_map[buff_instance.get_instance_id()] = buff_instance
			buff_instance_map[buff_instance.get_instance_id()] = buff_instance


	return buff_instance_map


# _on_buff_enter
func _on_buff_enter(buff: Buff):

	pass

# _on_buff_exit
func _on_buff_exit(buff: Buff):

	pass

# func create_buff(buff_res: BuffResource):
# 	if buff_res.buff_script:
# 		var buff_instance: Buff = buff_res.buff_script.new()

# 		# 2. 初始化 buff
# 		buff_instance = CommonUtil.bean_properties_copy(buff_res, buff_instance)
# 		buff_instance.reference_instance = ele

# 		print("value dir %s" % str(buff_instance.value_dir))
		
# 		buff_instance.res = buff_res


# buff apply 
func apply(_buff: Buff, _reference: Variant):
	# buff exclude level 处理
	var buff: Buff = _buff.duplicate()
	buff = CommonUtil.bean_properties_copy(_buff.res, buff)


	# buff apply
	if buff.apply(_reference):
		# 开启计时器
		if buff.cooldown > 0 and buff.cool_down_timer:
			buff.cool_down_timer.timeout.connect(remove.bind(buff, _reference))
			buff.cool_down_timer.start()

		# 添加到 buff action_bar ui 界面
		SignalBus.buff_enter.emit(buff)




# buff remove
func remove(buff: Buff, reference: Variant):


	if buff.remove(reference):

		# 移出 buff action_bar ui 界面
		SignalBus.buff_exit.emit(buff)
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
