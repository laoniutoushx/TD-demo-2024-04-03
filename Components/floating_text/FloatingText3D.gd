extends Node3D

@export var float_speed: float = 2.0
@export var gravity: float = 0.5
@export var lifetime: float = 1.5
@export var horizontal_variance: float = 0.3

var velocity: Vector3 = Vector3.ZERO
@onready var label: Label3D = $Label3D

func setup(text: String, color: Color = Color.WHITE):
    label.text = text
    label.modulate = color
    # 初始速度向上加随机水平偏移
    velocity = Vector3(
        randf_range(-horizontal_variance, horizontal_variance),
        float_speed,
        randf_range(-horizontal_variance, horizontal_variance)
    )
    
    var tween = create_tween()
    tween.tween_property(label, "modulate:a", 0.0, lifetime)
    tween.tween_callback(queue_free)

func _physics_process(delta):
    velocity.y -= gravity * delta
    global_translate(velocity * delta)
