class_name ActionBar extends Control

@onready var skill_bar: GridContainer = %SkillBar

@onready var layer: CanvasLayer = %CanvasLayer
@onready var item_bar: GridContainer = %ItemBar
@onready var selection_bar: GridContainer = %SelectionBar
@onready var buff_bar: GridContainer = %BuffBar

@onready var progress_util_bar: ProgressUtilBar = %ProgressUtilBar


@export var slot: PackedScene

static var icon_res_container := {}

var selection_bar_comp: SelectionBarComponent
var item_bar_comp: ItemBarComponent
var skill_bar_comp: SkillBarComponent
var buff_bar_comp: BuffBarComponent

var active_callback_list: Array[Callable] = []

var active_unit: BaseUnit


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	hidden()
	# Action Bar Icon Container
	CommonUtil.load_resources_to_container_from_directory("res://Asserts/Images/icon/", icon_res_container)

	#canvas_layer.visible = false
	SignalBus.player_selected_units.connect(_on_player_select_units)
	SignalBus.unit_logic_death.connect(_on_unit_logic_death)
	
	selection_bar_comp = SelectionBarComponent.new(self)
	item_bar_comp = ItemBarComponent.new(self)
	skill_bar_comp = SkillBarComponent.new(self)
	buff_bar_comp = BuffBarComponent.new(self)

	add_child(selection_bar_comp)
	add_child(item_bar_comp)
	add_child(skill_bar_comp)
	add_child(buff_bar_comp)

	# progress_util_bar
	progress_util_bar.action_bar = self
	

func register_active(cale: Callable):
	active_callback_list.append(cale)

func deregister_active(cale: Callable):
	active_callback_list.erase(cale)
	
func register_active_exec(is_active: bool):
	for active_cale in active_callback_list:
		active_cale.call(is_active)


func show_toggle() -> void:
	# toggle
	layer.visible = !layer.visible

func display() -> void:
	layer.visible = true	
	register_active_exec(true)

func hidden() -> void:
	layer.visible = false	
	register_active_exec(false)


# REGION building bar 



# REGION building bar 



# REGION selection bar 
func _on_player_select_units(unit_map: Dictionary, mouse_pos: Vector3, on_selected_player_status: PlayerController.PLAYER_STATUS) -> void:
	if on_selected_player_status == PlayerController.PLAYER_STATUS.DEFAULT:
		if unit_map.size() == 0:
			# 默认激活单位
			active_unit = null
			# skill bar clear
			close_skill_bar()
			close_item_bar()
			close_buff_bar()
			hidden()
		else:
			# 默认激活单位
			active_unit = unit_map.values()[0]
			# 显示 action_bar
			display()
			# selection bar
			open_selection_bar(unit_map)
			# skill bar
			open_skill_bar(unit_map)
			# item bar
			open_item_bar(unit_map)
			# item bar
			open_buff_bar(unit_map)
			# progress bar
			progress_util_bar.close()
		

func _on_unit_logic_death(id:int, unit :BaseUnit):
	selection_bar_comp.remove_element(unit)
	if active_unit and id == active_unit.get_instance_id():
		active_unit = null
		buff_bar_comp.clear()
		skill_bar_comp.clear()
		item_bar_comp.clear()


func open_selection_bar(unit_map: Dictionary):
	selection_bar_comp.clear()
	# selection bar init
	selection_bar_comp.add_elements(unit_map.values(), selection_bar_comp.add_element_hook)
	
func open_skill_bar(unit_map: Dictionary):
	skill_bar_comp.clear()
	# skill bar init
	skill_bar_comp.setup_for_unit(unit_map)

func open_item_bar(unit_map: Dictionary):
	item_bar_comp.clear()
	# item bar init
	item_bar_comp.setup_for_unit(unit_map)	

func open_buff_bar(unit_map: Dictionary):
	buff_bar_comp.clear()
	# buff bar init
	buff_bar_comp.setup_for_unit(unit_map)



func close_skill_bar():
	skill_bar_comp.clear()

func close_item_bar():
	item_bar_comp.clear()	

func close_buff_bar():
	buff_bar_comp.clear()		

# REGION selection bar 

class BaseBarComponent extends Node:
	var _action_bar: ActionBar
	var _slot_ps: PackedScene
	var _bar: GridContainer
	var _icon_res_container: Dictionary

	var _skill_bar: GridContainer
	var _item_bar: GridContainer
	var _selection_bar: GridContainer
	var _buff_bar: GridContainer




	var _slot_num = 0
	
	func _init(action_bar: ActionBar):
		_action_bar = action_bar
		_skill_bar = _action_bar.skill_bar
		_item_bar = _action_bar.item_bar
		_selection_bar = _action_bar.selection_bar
		_buff_bar = _action_bar.buff_bar
	
		_slot_ps = action_bar.slot
		_icon_res_container = ActionBar.icon_res_container



	
	func _ready() -> void:
		pass

		
	func add_element(id: String, _bar: GridContainer, hook: Callable = func(ab: ActionBar, bs: BaseSlot): pass) -> BaseSlot:
		# 只保留类型为 BaseUnit 且是 玩家所属单位
		var slot_instance: BaseSlot = _slot_ps.instantiate()
		slot_instance.name = id
		slot_instance.icon_res_container = _icon_res_container
		slot_instance.action_bar = _action_bar
		_bar.add_child(slot_instance)
		_action_bar.register_active(slot_instance.active_callback)
		
		# 添加 element 时的钩子函数
		if hook != null:
			hook.call(_action_bar, slot_instance)
			
		return slot_instance
		
	func remove_element(ele: Variant):
		pass

	func clear():
		pass


class SelectionBarComponent extends BaseBarComponent:

	func _ready() -> void:
		# 加载 icon resource
		CommonUtil.load_resources_to_container_from_directory("res://Asserts/Images/icon/enemy/")
		CommonUtil.load_resources_to_container_from_directory("res://Asserts/Images/icon/player/")

	
	func add_elements(elements: Array, hook: Callable):
		
		for element: BaseUnit in elements:
			if element.is_alive() and is_instance_valid(element) and _slot_num < 16 * 2:
				var select_slot_instance: BaseSlot = super.add_element(str(element.get_instance_id()), _selection_bar, add_element_hook)
				
				if element != null and is_instance_valid(element) and select_slot_instance != null and is_instance_valid(select_slot_instance):
					print("%s, element player group: %s, player gouup: %s" % [element.clz_name, str(element.player_group), str(SOS.main.player_controller.get_player_group_idx())])
					print("element icon path: %s" % [element.icon_path])
					select_slot_instance.custome_init(
						element,
						element.icon_path,
						BaseSlot.SLOT_TYPE.SELECT, 
						element.player_group == SOS.main.player_controller.get_player_group_idx()
					)
					_slot_num += 1
					
		
	func remove_element(ele: Variant):
		ele = (ele as BaseUnit)
		if _selection_bar.has_node(str(ele.get_instance_id())):
			var _s: BaseSlot = _selection_bar.get_node(str(ele.get_instance_id()))
			_action_bar.deregister_active(_s.active_callback)
			_s.queue_free()
			_slot_num -= 1
			
			
			
	func clear():
		for child: BaseSlot in _selection_bar.get_children():
			_action_bar.deregister_active(child.active_callback)
			child.queue_free()
		_slot_num = 0
	
	
	func add_element_hook(ab: ActionBar, bs: BaseSlot):
		bs.slot_clicked.connect(slot_item_clicked)
		
		
	func slot_item_clicked(slot: BaseSlot):
		print("slot print %s" % [slot.name])
	

	

# BUFF BAR	
class BuffBarComponent extends BaseBarComponent:


	func _ready() -> void:
		super._ready()

		# 监听 buff enter 事件
		SignalBus.buff_enter.connect(_on_buff_enter)
		SignalBus.buff_exit.connect(_on_buff_exit)
		SignalBus.buff_cooldown_extend.connect(_on_buff_cooldown_extend)


	func _on_buff_enter(buff: Buff, _ref: Variant):
		# 确认时当前激活单位，添加 buff 图标
		if _action_bar.active_unit and _ref.get_instance_id() == _action_bar.active_unit.get_instance_id():
			add_elements([buff], func(): )


	func _on_buff_exit(buff: Buff, _ref: Variant):
		# 确认时当前激活单位，删除 buff 图标
		if _action_bar.active_unit and _ref.get_instance_id() == _action_bar.active_unit.get_instance_id():
			remove_element(buff)


	func _on_buff_cooldown_extend(buff: Buff, _ref: Variant):
		if _action_bar.active_unit and _ref.get_instance_id() == _action_bar.active_unit.get_instance_id():
			# 延长 buff
			# extend_slot_cooldown(buff)
			for slot: BaseSlot in _buff_bar.get_children():
				if is_instance_valid(slot) and is_instance_valid(buff) and is_instance_valid(slot.reference) and slot.reference is Buff and slot.reference.code == buff.code:
					slot.extend_cooldown(buff.cooldown)




	# 装配 skill 时，需要检查 skill 状态，当 skill 处于 release 状态时，需要处理 progress_bar  等信息
	func setup_for_unit(unit_map: Dictionary):
		var unit: BaseUnit = unit_map.values()[0]
		var buff_map: Dictionary = unit.buff_map
		if buff_map != null and buff_map.keys().size() > 0:
			for code in buff_map.keys():
				if _slot_num <= 5:
					var buff: Buff = buff_map[code]
					var _slot = _create_buff_slot(buff)
					buff.slot = _slot
					# _bind_mapping_key(_slot, _slot_num)		


	func _create_buff_slot(buff: Buff) -> BaseSlot:	
		# 注意这里传递的 instance_id , 绑定了 slot id，删除时通过该 id 寻找节点树
		var slot_instance: BaseSlot = super.add_element(str(buff.get_instance_id()), _buff_bar)
		
		slot_instance.custome_init(
			buff,
			buff.icon_path,
			BaseSlot.SLOT_TYPE.ITEM, 
			buff.unit.player_group == SOS.main.player_controller.get_player_group_idx()
		)
		# click signal listener
		slot_instance.slot_clicked.connect(slot_buff_clicked)

		# buff slot timer init
		if buff.cooldown > 0:
			slot_instance.cimer = buff.cool_down_timer
			# slot_instance.timer.timeout.connect(_on_slot_timer_timeout.bind(slot_instance))
			slot_instance.progress_bar.max_value = buff.cool_down_timer.wait_time	

			if buff.current_state == Buff.BUFF_STATE.Cool_Down:
				slot_instance.progress_bar.value = buff.cool_down_timer.time_left
				slot_instance.progress_bar.visible = true
				slot_instance.set_process(true)

		_slot_num += 1
		return slot_instance					


	func add_elements(elements: Array, hook: Callable):
		
		for element: Buff in elements:
			if is_instance_valid(element) and _slot_num < 20:
				var buff_slot_instance: BaseSlot = super.add_element(str(element.get_instance_id()), _buff_bar, add_element_hook)
				
				if element != null and is_instance_valid(element) and buff_slot_instance != null and is_instance_valid(buff_slot_instance):
					print(" buff title : %s" % [element.title])					
					print("element icon path: %s" % [element.icon_path])
					buff_slot_instance.custome_init(
						element,
						element.icon_path,
						BaseSlot.SLOT_TYPE.BUFF, 
						element.unit.player_group == SOS.main.player_controller.get_player_group_idx()
					)

					# buff timer init
					buff_slot_instance.cimer = element.cool_down_timer
					# buff_slot_instance.timer.timeout.connect(_on_slot_timer_timeout.bind(buff_slot_instance))
					buff_slot_instance.progress_bar.max_value = element.cooldown

					# 如果 buff 有冷却时间
					if element.cool_down_timer and element.cooldown > 0:
						buff_slot_instance.progress_bar.value = element.cool_down_timer.time_left
						buff_slot_instance.progress_bar.visible = true
						buff_slot_instance.set_process(true)

					_slot_num += 1
					
		
	func remove_element(ele: Variant):
		ele = (ele as Buff)
		if _buff_bar.has_node(str(ele.get_instance_id())):
			var _s: BaseSlot = _buff_bar.get_node(str(ele.get_instance_id()))
			_action_bar.deregister_active(_s.active_callback)
			_s.queue_free()
			_slot_num -= 1
			
			
			
	func clear():
		for child: BaseSlot in _buff_bar.get_children():
			_action_bar.deregister_active(child.active_callback)
			child.queue_free()
		_slot_num = 0
	
	
	func add_element_hook(ab: ActionBar, bs: BaseSlot):
		bs.slot_clicked.connect(slot_buff_clicked)
		


	func slot_buff_clicked(slot: BaseSlot):
		print("slot print %s" % [slot.name])
	
