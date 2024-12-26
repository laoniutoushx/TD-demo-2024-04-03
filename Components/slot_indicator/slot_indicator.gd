extends Control


@onready var panel: PanelContainer = $PanelContainer

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	hide()
	print("indicator size: %s" % panel.size)

# 依据 base_slot 显示对应提示信息（数据驱动）
func show_toggle(_slot: BaseSlot) -> void:
	# location slot indicator 
	var slot_pos: Vector2 = _slot.global_position
	print("slot pos: %s" % slot_pos)
	var slot_size: Vector2 = _slot.size
	print("slot slot_size: %s" % slot_size)
	var indicator_size: Vector2 = panel.size
	print("indicator size: %s" % indicator_size)


	var indicator_pos: Vector2 = slot_pos + (slot_size / 2) - Vector2(0, (indicator_size.y / 2))
	self.global_position = indicator_pos

	# Data Driven



	if is_visible():
		hide()
	else:
		show()
