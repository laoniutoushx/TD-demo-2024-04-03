class_name BuffTpl extends Node


func _ready() -> void:
	SignalBus.buff_enter.emit(self)


func _exit_tree() -> void:
	SignalBus.buff_exit.emit(self)


func apply(_reference: Variant) -> bool:
	return false


func remove() -> bool:
	return false	


func apply_cond(buff_ctx: BuffContext) -> bool:
	return true	