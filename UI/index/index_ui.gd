extends Control


@onready var start_button = %Start
@onready var canvas_layer: CanvasLayer = $CanvasLayer


func _ready() -> void: 
	pass



func _on_start_pressed() -> void: 
	print("start clicked")
	var pc = CommonUtil.get_first_node_by_node_name(SOS.main, "PlayerController", false)
	if pc:
		pc.queue_free()


	# 创建 player controller
	var player_controller: PlayerController = load("res://Player/player_controller.tscn").instantiate()
	SOS.main.add_child(player_controller)
	SOS.main.set_player_controller(player_controller)


	# SignalBus.next_level.emit("choose_player")
	SignalBus.next_level.emit("level1")

	SOS.main.level_controller.level_map["index"].queue_free()




func _on_setting_pressed() -> void:
	# SignalBus.next_level.emit("setting")
	var setting =  load("res://Levels/setting/setting.tscn").instantiate()
	SOS.main.add_child(setting)
	setting.toggle()




func _show() -> void:
	canvas_layer.visible = true

func _hide() -> void:
	canvas_layer.visible = false
