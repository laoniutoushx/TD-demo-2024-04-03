extends Node3D

@export var life := 5
@onready var lifeLable: Label3D = $Label3D

var current_life: int:
	set(life_in):
		current_life = life_in
		print("life was changed")
		lifeLable.text = str(current_life) + "/" + str(life)

		var green = Color.GREEN
		var red = Color.RED

		lifeLable.modulate = red.lerp(green, float(current_life) / float(life))

		if current_life == 0:
			print("game over")
			SignalBus.game_over.emit()
			# get_tree().reload_current_scene()

			var level1_scene = SOS.main.level_controller._cur_scene
			# show game over scene

			var game_over_scene = SOS.main.level_controller.next_level("game_over")
			game_over_scene.setup(false)



	

			



# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	current_life = life



# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func take_damage() -> void:
	current_life = current_life - 1
