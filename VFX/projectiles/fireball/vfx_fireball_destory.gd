extends Node


func _on_vfx_death_effect_finished() -> void:
	queue_free()
