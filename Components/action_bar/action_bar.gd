class_name ActionBar extends Node

@onready var canvas_layer: CanvasLayer = $CanvasLayer

@onready var skill_bar: GridContainer = %SkillBar
@onready var item_bar: GridContainer = %ItemBar
@onready var selection_bar: GridContainer = %SelectionBar

@export var slot: PackedScene

var selection_bar_comp: SelectionBarComponent

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	SignalBus.player_selected_units.connect(_on_player_select_units)
	selection_bar_comp = SelectionBarComponent.new(selection_bar, slot)
	add_child(selection_bar_comp)


func show_toggle() -> void:
	# toggle
	canvas_layer.visible = !canvas_layer.visible

func display() -> void:
	canvas_layer.visible = true	

func hide() -> void:
	canvas_layer.visible = false	

func _on_player_select_units(unit_map: Dictionary) -> void:
	print(unit_map.size())
	if unit_map.size() == 0:
		hide()
	else:
		open_selection_bar(unit_map)
		



func open_selection_bar(unit_map: Dictionary):
	selection_bar_comp.clear()
	# selection bar init
	selection_bar_comp.add_elements(unit_map.values())
	display()


# Note add_elements 与 clear 为互斥操作，同时进行可能导致 BUG
class SelectionBarComponent extends Node:
	var mutex = Mutex.new()
	
	var _slot_ps: PackedScene
	var _selection_bar: GridContainer

	var _slot_num = 0
	
	func _init(selection_bar: GridContainer, slot_ps: PackedScene) -> void:
		_slot_ps = slot_ps
		_selection_bar = selection_bar
	
	func add_elements(elements: Array):
		mutex.lock()
		for element: BaseUnit in elements:
			if is_instance_valid(self) and is_instance_valid(element) and is_instance_valid(_selection_bar) and _slot_num < 16 * 2:
				# 只保留类型为 BaseUnit 且是 玩家所属单位
				var select_slot_instance: BaseSlot = _slot_ps.instantiate()
				print("slot_name -> " + str(select_slot_instance.get_name()))
				_selection_bar.add_child(select_slot_instance)
				print("slot_name -> " + str(select_slot_instance.get_name()))
				select_slot_instance.init(element.icon_path, null)
				print("slot_name -> " + str(select_slot_instance.get_name()))
				print("slot_num -> " + str(_slot_num))
				_slot_num += 1
		mutex.unlock()
		
		
	func clear():
		mutex.lock()
		for child in _selection_bar.get_children():
			child.free()
		_slot_num = 0
		mutex.unlock()
