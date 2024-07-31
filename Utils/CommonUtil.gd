class_name CommonUtil
extends Node

# get main scene tree
static func get_main_scene_tree() -> Node:
	return Engine.get_main_loop().root


static func await_timer(second):
	if second is float or second is int:
		second = float(second)
		if second > 0:
			var timer = Timer.new()
			timer.one_shot = true
			get_main_scene_tree().add_child(timer)
			timer.start(second)
			await timer.timeout
			get_main_scene_tree().remove_child(timer)
			timer.queue_free()

	
