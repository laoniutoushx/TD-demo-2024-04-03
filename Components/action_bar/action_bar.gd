class_name ActionBar extends Node

@onready var canvas_layer: CanvasLayer = $CanvasLayer

@onready var skill_bar: GridContainer = %SkillBar
@onready var item_bar: GridContainer = %ItemBar
@onready var selection_bar: GridContainer = %SelectionBar
@onready var bulilding_bar: GridContainer = %BulildingBar


@export var slot: PackedScene

static var icon_res_container := {}

var selection_bar_comp: SelectionBarComponent
var item_bar_comp: ItemBarComponent
var skill_bar_comp: SkillBarComponent
var building_bar_comp: BulidingBarComponent

var active_callback_list: Array[Callable] = []

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	CommonUtil.load_resources_to_container_from_directory("res://Asserts/Images/icon/enemy/", icon_res_container)
	#canvas_layer.visible = false
	SignalBus.player_selected_units.connect(_on_player_select_units)
	SignalBus.unit_logic_death.connect(_on_unit_logic_death)
	
	selection_bar_comp = SelectionBarComponent.new(self)
	item_bar_comp = ItemBarComponent.new(self)
	skill_bar_comp = SkillBarComponent.new(self)
	building_bar_comp = BulidingBarComponent.new(self)
	

func register_active(cale: Callable):
	active_callback_list.append(cale)

func deregister_active(cale: Callable):
	active_callback_list.erase(cale)
	
func register_active_exec(is_active: bool):
	for active_cale in active_callback_list:
		active_cale.call(is_active)


func show_toggle() -> void:
	# toggle
	canvas_layer.visible = !canvas_layer.visible

func display() -> void:
	canvas_layer.visible = true	
	register_active_exec(true)

func hide() -> void:
	canvas_layer.visible = false	
	register_active_exec(false)


# REGION building bar 



# REGION building bar 



# REGION selection bar 
func _on_player_select_units(unit_map: Dictionary, mouse_pos: Vector3, on_selected_player_status: PlayerController.PLAYER_STATUS) -> void:
	if on_selected_player_status == PlayerController.PLAYER_STATUS.DEFAULT:
		if unit_map.size() == 0:
			# skill bar clear
			close_skill_bar()
			hide()
		else:
			display()
			# selection bar
			open_selection_bar(unit_map)
			# skill bar
			open_skill_bar(unit_map)
		
		

func _on_unit_logic_death(id:int, unit :BaseUnit):
	selection_bar_comp.remove_element(unit)


func open_selection_bar(unit_map: Dictionary):
	selection_bar_comp.clear()
	# selection bar init
	selection_bar_comp.add_elements(unit_map.values(), selection_bar_comp.add_element_hook)
	
func open_skill_bar(unit_map: Dictionary):
	skill_bar_comp.clear()
	# skill bar init
	skill_bar_comp.setup_for_unit(unit_map)

func close_skill_bar():
	skill_bar_comp.clear()

# REGION selection bar 

class BaseBarComponent extends Node:
	var _action_bar: ActionBar
	var _slot_ps: PackedScene
	var _bar: GridContainer
	var _icon_res_container: Dictionary

	var _skill_bar: GridContainer
	var _item_bar: GridContainer
	var _selection_bar: GridContainer
	var _bulilding_bar: GridContainer

	var _slot_num = 0
	
	func _init(action_bar: ActionBar):
		_action_bar = action_bar
		_skill_bar = _action_bar.skill_bar
		_item_bar = _action_bar.item_bar
		_selection_bar = _action_bar.selection_bar
		_bulilding_bar = _action_bar.bulilding_bar
	
		_slot_ps = action_bar.slot
		_icon_res_container = ActionBar.icon_res_container

		
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
	


class ItemBarComponent extends BaseBarComponent:
	pass
	
class BulidingBarComponent extends BaseBarComponent:
	pass
	
