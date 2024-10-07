extends Node3D


func _on_selection_box_selecting_finished(unit_map) -> void:
	print(123)


func _on_selection_box_selecting_started() -> void:
	print(1234)
