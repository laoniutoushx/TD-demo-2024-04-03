extends Node


@onready var texture_rect: TextureRect = $CanvasLayer/PanelContainer/MarginContainer/GridContainer/HSplitContainer/VSplitContainer/TextureRect
@onready var texture_rect2: TextureRect = $CanvasLayer/PanelContainer/MarginContainer/GridContainer/HSplitContainer2/VSplitContainer/TextureRect

var choose_player_shader = preload("res://Levels/choose_player/ChosePlayer.gdshader")

var _on_mouse_choose := false

@export var level_scene:PackedScene

func _ready() -> void:
	texture_rect.material = ShaderMaterial.new()
	texture_rect2.material = ShaderMaterial.new()
	
func _input(event: InputEvent) -> void:
	if event.is_action_released("click") and _on_mouse_choose:
		# 初始化场景 1
		var begin_scene_inst = level_scene.instantiate()
		get_parent().add_child(begin_scene_inst)
		var path = begin_scene_inst.find_child("Path3D")
		self.queue_free()
	

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
