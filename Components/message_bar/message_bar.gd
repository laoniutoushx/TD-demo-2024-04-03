extends Control

@onready var msg: Label = %Msg

var local_position: Vector2

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	local_position = msg.position


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func set_message(message: String) -> void:
	msg.text = message
	shake()
	CommonUtil.delay_execution(2, (func() -> void:
		msg.text = ""
	))


func shake() -> void:
	var tween = create_tween()
	var shake = 5
	var duration = 0.1

	for i in shake:

		var offset = Vector2(randf_range(-2, 2), randf_range(-2, 2))
		tween.tween_property(msg, "position", msg.position + offset, duration / 2).set_trans(Tween.TRANS_BOUNCE )
		tween.tween_property(msg, "position", local_position, duration / 2).set_trans(Tween.TRANS_BOUNCE )
	
	# tween.tween_property(msg, "position", local_position, duration / 2).set_trans(Tween.TRANS_SINE)

