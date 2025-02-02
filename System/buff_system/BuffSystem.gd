class_name BuffSystem extends Node

# 每次添加 buff 时，记录 buff 的实例 id 的添加数量，用于计数
# 每次删除 buff 或 buff 消失时，检查 buff 的实例 id 的添加数量
# 先检查数量，在执行实际 buff 实例的添加或移除操作，同时满足 buff 排斥条件和 buff 叠加限制，以及 buff 的持续时间（记录 buff 叠加层数）


# 一个 buff 被添加到某个 实例的次数
# key: buff_code&instance_id -> count(*)
var __buff_inst_counter: Dictionary = {}


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

			# print("value dir %s" % str(buff_instance.value_dir))
			
			buff_instance.res = buff_res

			# 保存实例
			ele.buff_map[buff_instance.get_instance_id()] = buff_instance
			buff_instance_map[buff_instance.get_instance_id()] = buff_instance


	return buff_instance_map



# buff apply 
func apply(_buff: Buff, _reference: Variant):	

	# buff 计数
	var _id = str(_buff.code) + "&" + str(_reference.get_instance_id())
	if __buff_inst_counter.has(_id):
		__buff_inst_counter[_id] += 1
	else:
		__buff_inst_counter[_id] = 1


	# 进入后，处理 buff 计数
	print("buff enter %s" % __buff_inst_counter)	

	# 无论是否可以叠加，都应该增加 cooldown 时间
	if _buff.cooldown > 0:
		SignalBus.buff_cooldown_extend.emit(_buff, _reference)

	# 叠加层数检查
	if _buff.max_overlay_num > -1:
		var buff_count = 0
		for bm: Buff in _reference.buff_map.values():
			if _buff.code == bm.code:
				buff_count += 1

		if buff_count >= _buff.max_overlay_num:
			print("buff code %s already has %s buff" % [_buff.code, buff_count])
			return


	# buff 添加
	var buff: Buff = _buff.duplicate()
	buff = CommonUtil.bean_properties_copy(_buff.res, buff)

	_reference.buff_map[buff.get_instance_id()] = buff

	if _reference is BaseUnit or _reference is Enemy:
		buff.unit = _reference

	# buff apply
	if buff.apply(_reference):
		# buff exit tree 绑定
		buff.tree_exiting.connect(_on_buff_exiting_tree.bind(buff, _reference), CONNECT_ONE_SHOT)

		# 开启计时器
		if buff.cooldown > 0:
			buff.cool_down_timer.timeout.connect(remove.bind(buff, _reference))
			buff.change_state(Buff.BUFF_STATE.Cool_Down)
			# buff.cool_down_timer.start()

		# 添加到 buff action_bar ui 界面
		SignalBus.buff_enter.emit(buff, _reference)

	


# buff remove
func remove(_buff: Buff, _reference: Variant):
	# 当 buff 为永久 buff （cooldown == -1）时，检查 buff 计数
	if _buff.cooldown == -1:
		# buff 计数（未达到最小数量时，不删除）（只适合 范围类光辉类 buff）（单体延迟冷却时间类，这里到期后应该立即删除，后期没有机会再触发删除）
		var _id = str(_buff.code) + "&" + str(_reference.get_instance_id())
		if __buff_inst_counter[_id] > 1:
			__buff_inst_counter[_id] -= 1
			# 退出时，处理 buff 计数
			print("buff exit %s" % __buff_inst_counter)
			return
	else:
		# buff 可以倒计时，当前删除函数触发，执行后续删除逻辑
		pass

	# 删除 reference 实体上关联的 buff 信息
	_reference.buff_map.erase(_buff.get_instance_id())

	if _buff.remove(_reference):
		# 移出 buff action_bar ui 界面
		SignalBus.buff_exit.emit(_buff, _reference)

		# 删除 buff
		_buff.queue_free()



# buff 退出节点树
func _on_buff_exiting_tree(_buff: Buff, _reference: Variant):
	# buff 计数
	var _id = str(_buff.code) + "&" + str(_reference.get_instance_id())
	__buff_inst_counter.erase(_id)
	

	# 退出时，处理 buff 计数
	print("buff exit %s" % __buff_inst_counter)





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
