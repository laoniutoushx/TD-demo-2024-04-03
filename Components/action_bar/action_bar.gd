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
	CommonUtil.load_resources_to_container_from_directory("res://Asserts/Images/icon/enemy", icon_res_container)
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
func _on_player_select_units(unit_map: Dictionary) -> void:
	if unit_map.size() == 0:
		hide()
	else:
		open_selection_bar(unit_map)
		skill_bar_comp.setup_for_unit(unit_map)
		

func _on_unit_logic_death(id:int, unit :BaseUnit):
	selection_bar_comp.remove_element(unit)


func open_selection_bar(unit_map: Dictionary):
	selection_bar_comp.clear()
	# selection bar init
	selection_bar_comp.add_elements(unit_map.values(), selection_bar_comp.add_element_hook)
	display()
# REGION selection bar 

class BaseBarComponent extends Node:
	var _action_bar: ActionBar
	var _slot_ps: PackedScene
	var _selection_bar: GridContainer
	var _icon_res_container: Dictionary

	var _slot_num = 0
	
	func _init(action_bar: ActionBar):
		_action_bar = action_bar
		_slot_ps = action_bar.slot
		_selection_bar = action_bar.selection_bar
		_icon_res_container = ActionBar.icon_res_container
	

	func add_elements(elements: Array, hook: Callable):
		for element: BaseUnit in elements:
			if element.is_alive() and is_instance_valid(element) and _slot_num < 16 * 2:
				# 只保留类型为 BaseUnit 且是 玩家所属单位
				var select_slot_instance: BaseSlot = _slot_ps.instantiate()
				select_slot_instance.name = str(element.get_instance_id())
				select_slot_instance.icon_res_container = _icon_res_container
				select_slot_instance.action_bar = _action_bar
				_selection_bar.add_child(select_slot_instance)
				_action_bar.register_active(select_slot_instance.active_callback)
				
				if hook != null:
					hook.call(_action_bar, select_slot_instance)
				
				if element != null and is_instance_valid(element) and select_slot_instance != null and is_instance_valid(select_slot_instance):
					print("%s, element player group: %s, player gouup: %s" % [element.clz_name, str(element.player_group), str(SOS.main.player_controller.get_player_group_idx())])
					select_slot_instance.init(
						element.icon_path,
						null, 
						element.player_group == SOS.main.player_controller.get_player_group_idx()
					)
					_slot_num += 1
		
	func remove_element(ele: BaseUnit):
		if _selection_bar.has_node(str(ele.get_instance_id())):
			var _s: BaseSlot = _selection_bar.get_node(str(ele.get_instance_id()))
			_action_bar.deregister_active(_s.active_callback)
			_s.queue_free()

		
		
	func clear():
		for child in _selection_bar.get_children():
			child.free()
		_action_bar.active_callback_list.clear()
		_slot_num = 0


class SelectionBarComponent extends BaseBarComponent:
	
	func add_element_hook(ab: ActionBar, bs: BaseSlot):
		bs.slot_clicked.connect(slot_item_clicked)
		
	func slot_item_clicked(slot: BaseSlot):
		print("slot print %s" % [slot.name])
	


class ItemBarComponent extends BaseBarComponent:
	pass
	
class BulidingBarComponent extends BaseBarComponent:
	pass
	
