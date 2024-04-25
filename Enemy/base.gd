extends Node3D

@export var life := 5
@onready var lifeLable: Label3D = $Label3D

var current_life: int:
	set(life_in):
		current_life = life_in
		print("life was changed")
		lifeLable.text = str(current_life) + "/" + str(life)
		
		var red = Color.RED
		var white = Color.WHITE
		
		lifeLable.modulate = red.lerp(white, float(current_life) / float(life))

		if current_life == 0:
			print("game over")
			get_tree().reload_current_scene()

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	current_life = life



# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func take_damage() -> void:
	current_life = current_life - 1

