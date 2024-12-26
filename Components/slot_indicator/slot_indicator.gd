extends Control


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	hide()


# 依据 base_slot 显示对应提示信息（数据驱动）
func show_toggle(_slot: BaseSlot) -> void:
	# Data Driven

	if is_visible():
		hide()
	else:
		show()

