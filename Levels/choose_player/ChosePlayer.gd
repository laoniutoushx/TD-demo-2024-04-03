extends Node

var choose_player_tres = ResourceLoader.load("res://Levels/choose_player/ChoosePlayer.tres")
@onready var canvas_layer: CanvasLayer = $CanvasLayer

@onready var texture_rect: TextureRect = $CanvasLayer/PanelContainer/MarginContainer/GridContainer/HSplitContainer/VSplitContainer/TextureRect
@onready var texture_rect2: TextureRect = $CanvasLayer/PanelContainer/MarginContainer/GridContainer/HSplitContainer2/VSplitContainer/TextureRect

var choose_player_shader = preload("res://Levels/choose_player/ChosePlayer.gdshader")

var _on_mouse_choose := false

func _ready() -> void:
	
	texture_rect.material = ShaderMaterial.new()
	texture_rect2.material = ShaderMaterial.new()
	
func _input(event: InputEvent) -> void:
	if event.is_action_released("click") and _on_mouse_choose:
		SignalBus.next_level.emit("level1")
		canvas_layer.hide()
		#self.queue_free()
	

func _on_v_split_container_mouse_entered() -> void:
	texture_rect.material.shader = choose_player_shader
	_on_mouse_choose = true


func _on_v_split_container_mouse_exited() -> void:
	texture_rect.material.shader = null
	_on_mouse_choose = false




func _on_h_split_container_2_mouse_entered() -> void:
	texture_rect2.material.shader = choose_player_shader
	_on_mouse_choose = true


func _on_h_split_container_2_mouse_exited() -> void:
	texture_rect2.material.shader = null
	_on_mouse_choose = false
