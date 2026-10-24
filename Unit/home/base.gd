extends Node3D

@export var life := 5
@onready var lifeLable: Label3D = $Label3D

var current_life: int:
	set(life_in):
		current_life = clampi(life_in, 0, life)
		print("life was changed")
		lifeLable.text = str(current_life) + "/" + str(life)

		var green = Color.GREEN
		var red = Color.RED

		lifeLable.modulate = red.lerp(green, float(current_life) / float(life))

		if current_life == 0:
			SOS.main.level_controller.finish_battle(false)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	current_life = life



# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func take_damage() -> void:
	if current_life > 0:
		current_life -= 1
