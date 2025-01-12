extends Node3D

@onready var circle = $FadedCircle3D




# Called when the node enters the scene tree for the first time.
func _ready() -> void:

	hide()
	SignalBus.player_selected_units.connect(_on_player_selected_units)



func set_radius(rad: float):
	circle.radius = rad




# player select event
# 当只选中一个单位是，显示当前单位攻击范围指示框
func _on_player_selected_units(unit_map: Dictionary, mouse_pos: Vector3, on_selected_player_status: PlayerController.PLAYER_STATUS) -> void:	
	if unit_map.size() == 1:	# 只选择了一个单位
		if unit_map.keys()[0] == owner.get_instance_id():
			# 选择的是自己
			if owner is BaseUnit:
				if owner is Turret:
					# 初始化，默认设置为单位攻击范围
					set_radius(owner.attack_range)
			show()
			return 
	
	# 选择单位时玩家状态（default）
	if on_selected_player_status == SOS.main.player_controller.PLAYER_STATUS.DEFAULT:
		hide()