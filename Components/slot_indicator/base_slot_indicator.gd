class_name BaseSlotIndicator extends Control


@onready var panel: PanelContainer = $PanelContainer


# slot_indicator 下边界 与 slot 中心点的距离
@export var keep_bottom_margin: float = 0
var cur_slot: BaseSlot


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	hide()
	print("indicator size: %s" % panel.size)

# 依据 base_slot 显示对应提示信息（数据驱动）
func show_toggle(_slot: BaseSlot) -> void:
	cur_slot = _slot
	# Data Driven
	refresh_slot_indicator_info(_slot)
	defer_show(_slot)


func defer_show(_slot: BaseSlot) -> void:
	if is_visible():
		hide()
	else:
		_on_panel_container_resized()
		show()

# 刷新位置
func _on_panel_container_resized() -> void:
	if cur_slot:
		var border_limit_y: float = cur_slot.global_position.y  - keep_bottom_margin
			
		# location slot indicator 
		var slot_pos: Vector2 = cur_slot.global_position
		# print("slot pos: %s" % slot_pos)
		var slot_size: Vector2 = cur_slot.size
		# print("slot slot_size: %s" % slot_size)
		var indicator_size: Vector2 = panel.size
		# print("indicator size: %s" % indicator_size)

		# var indicator_pos: Vector2 = slot_pos + (slot_size / 2) - Vector2(0, (indicator_size.y / 2))
		var indicator_pos: Vector2 = Vector2(slot_pos.x + slot_size.x / 2, border_limit_y - (indicator_size.y / 2))
		self.global_position = indicator_pos


func refresh_slot_indicator_info(_slot: BaseSlot) -> void:
	pass
	
