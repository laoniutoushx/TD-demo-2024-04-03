extends Node


func _ready() -> void:
	SignalBus.connect("enemy_logic_death", _on_enemy_death)
	
	pass

func _on_enemy_death(id:int, enemy :Enemy):
	var money = enemy.money
	var wood = enemy.wood
	
	var money_label = $CanvasLayer/PanelContainer/MarginContainer/GridContainer/HSplitContainer/MoneyLabel

	var wood_label = $CanvasLayer/PanelContainer/MarginContainer/GridContainer/HSplitContainer2/WoodLabel
	
	money_label.text = str(int(money_label.text) + money)
	wood_label.text = str(int(wood_label.text) + wood)
