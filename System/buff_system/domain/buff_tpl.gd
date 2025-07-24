class_name BuffTpl extends Node3D


func _ready() -> void:
	pass


func _exit_tree() -> void:
	pass


func apply(_reference: Variant, _target: Variant) -> bool:
	return false


func remove(_target: Variant) -> bool:
	return false	


func apply_cond(buff_ctx: BuffContext) -> bool:
	return true	