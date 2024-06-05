extends Node3D

@export var begin_scene:PackedScene

func _ready() -> void:
	# 初始化场景 1
	var begin_scene_inst = begin_scene.instantiate()
	add_child(begin_scene_inst)
	
	var path = begin_scene_inst.find_child("Path3D")

	
	pass
