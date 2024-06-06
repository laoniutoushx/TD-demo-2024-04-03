extends BaseUnit

class_name Enemy

@export var speed := 5
@export var life := 20
@export var money := 10
@export var wood := 1

@onready var path: PathFollow3D = $"."
@onready var base = get_tree().get_first_node_in_group("base")

var is_finish = false

func _ready() -> void:
	# 初始化时创建 path3d 与 pathfollow3d
	pass



# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	path.progress = path.progress + (delta * speed)
	if path.progress_ratio >= 0.98 && !is_finish:
		is_finish = true
		base.take_damage()
		set_process(false)


func take_damage(damage: float):
	life -= damage
	if life <= 0:
		SignalBus.emit_signal("enemy_death", self)
		queue_free()
		
