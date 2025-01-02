extends Control


@onready var margin_container: MarginContainer = $NinePatchRect/MarginContainer
@onready var nine_patch_rect: NinePatchRect = $NinePatchRect



# Called when the node enters the scene tree for the first time.
func _ready() -> void:

	nine_patch_rect.size.y = margin_container.size.y
	nine_patch_rect.global_position = global_position - Vector2(0, (margin_container.size.y / 2))


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
