class_name BuffTpl extends Node


func _ready() -> void:
	pass


func _exit_tree() -> void:
	pass


func apply(_reference: Variant) -> bool:
	return false


func remove(_reference: Variant) -> bool:
	return false	


func apply_cond(buff_ctx: BuffContext) -> bool:
	return true	