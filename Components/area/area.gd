class_name Area extends Area3D


@onready var collision: CollisionShape3D = $CollisionShape3D


var rad: float = 0

# 自定义初始化
func init(_radius: float = 0) -> void:
	rad = _radius

	

func _ready() -> void:	
	# 实例化
	collision.shape = collision.shape.duplicate()
	collision.shape.radius = rad
	collision.disabled = false
