class_name ActionBar extends Node

@onready var canvas_layer: CanvasLayer = $CanvasLayer

@onready var skill_bar: GridContainer = %SkillGridContainer
@onready var item_bar: GridContainer = %ItemGridContainer
@onready var selection_bar: GridContainer = %SelectedGridContainer

@export var slot: PackedScene

var selection_bar_comp: SelectionBarComponent

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	SignalBus.player_select_units.connect(_on_player_select_units)
	selection_bar_comp = SelectionBarComponent.new(selection_bar, slot)


func show_toggle() -> void:
	# toggle
	canvas_layer.visible = !canvas_layer.visible

func display() -> void:
	canvas_layer.visible = true	

func hide() -> void:
	canvas_layer.visible = false	

func _on_player_select_units(units: Array) -> void:
	print(units.size())
	if units.size() == 0:
		hide()
	else:
		display()
		open_selection_bar(units)


func open_selection_bar(units: Array):
	# selection bar init
	selection_bar_comp.add_elements(units)



class SelectionBarComponent:
	var _slot: PackedScene
	var _selection_bar: GridContainer
	func _init(selection_bar: GridContainer, slot: PackedScene) -> void:
		_slot = slot
		_selection_bar = selection_bar
	
	func add_elements(elements):
		for element in elements:
			# 只保留类型为 BaseUnit 且是 玩家所属单位
			var select_slot_instance: BaseSlot = _slot.instantiate()
			_selection_bar.add_child(select_slot_instance)
			
			print(element.get_class())
			#select_slot_instance.init()
		
