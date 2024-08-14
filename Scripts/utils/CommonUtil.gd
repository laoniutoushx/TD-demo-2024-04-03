class_name CommonUtil
extends Node

# get main scene tree
static func await_get_root_node() -> Node:
	if Engine.get_main_loop().root.is_inside_tree():
		Constants.ROOT_NODE = Engine.get_main_loop().root
	else:
		while Constants.GLB_TICKET > 2.0:
			return await_get_root_node()
	return Constants.ROOT_NODE


static func await_timer(second):
	if second is float or second is int:
		second = float(second)
		if second > 0:
			var timer = Timer.new()
			timer.one_shot = true
			var root = await_get_root_node()
			root.add_child(timer)
			timer.start(second)
			await timer.timeout
			root.remove_child(timer)
			timer.queue_free()

func _process(delta: float) -> void:
	Constants.GLB_TICKET += delta
