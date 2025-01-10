extends Node3D

@onready var circle = $FadedCircle3D

# 缓存前一次设置的半径
var last_radius: float


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	
	hide()

	SignalBus.player_selected_units.connect(_on_player_selected_units)
	last_radius = circle.radius


func set_radius(rad: float):
	last_radius = circle.radius
	circle.radius = rad

# 恢复上一次设置的半径
func recover_radius():
	circle.radius = last_radius	


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
	
	hide()