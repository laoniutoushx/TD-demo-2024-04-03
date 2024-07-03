extends Sprite3D


@onready var progress_bar: ProgressBar = $SubViewport/ProgressBar


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	texture = $SubViewport.get_texture()
	
	# initialize value
	#progress_bar.show_percentage = false
	#progress_bar.value = 100



# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	
	
	pass
