extends Node


func _ready() -> void:
	# SignalBus.unit_logic_death.connect(_on_enemy_death)
	SignalBus.money_changed.connect(_on_money_changed)
	SignalBus.wood_changed.connect(_on_wood_changed)

	# 初始化
	_on_money_changed(null, SOS.main.player_controller.money)
	_on_wood_changed(null, SOS.main.player_controller.wood)

	
	pass

func _on_money_changed(enemy: Object, money: int):
	var money_label = $CanvasLayer/PanelContainer/MarginContainer/GridContainer/HSplitContainer/MoneyLabel
	money_label.text = str(money)


func _on_wood_changed(enemy: Object, wood: int):
	var wood_label = $CanvasLayer/PanelContainer/MarginContainer/GridContainer/HSplitContainer2/WoodLabel
	wood_label.text = str(wood)
	