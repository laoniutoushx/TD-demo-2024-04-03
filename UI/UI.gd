extends Node


func _ready() -> void:
	# SignalBus.unit_logic_death.connect(_on_enemy_death)
	SignalBus.money_changed.connect(_on_money_changed)
	SignalBus.wood_changed.connect(_on_wood_changed)
	
	pass

func _on_enemy_death(id:int, enemy :Enemy):
	var money = enemy.money
	var wood = enemy.wood

	var money_label = $CanvasLayer/PanelContainer/MarginContainer/GridContainer/HSplitContainer/MoneyLabel
	var wood_label = $CanvasLayer/PanelContainer/MarginContainer/GridContainer/HSplitContainer2/WoodLabel
	
	money_label.text = str(int(money_label.text) + money)
	wood_label.text = str(int(wood_label.text) + wood)


func _on_money_changed(enemy: Object, money: int):
	var money_label = $CanvasLayer/PanelContainer/MarginContainer/GridContainer/HSplitContainer/MoneyLabel
	money_label.text = str(int(money_label.text) + money)


func _on_wood_changed(enemy: Object, wood: int):
	var wood_label = $CanvasLayer/PanelContainer/MarginContainer/GridContainer/HSplitContainer2/WoodLabel
	wood_label.text = str(int(wood_label.text) + wood)