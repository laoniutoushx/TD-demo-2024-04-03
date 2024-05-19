extends Node3D

# camera move
@export_range(0, 100, 1) var camera_move_speed:float = 20.0


# 
@export_range(0, 32, 4) var camera_automatic_pan_margin:int = 16
@export_range(0, 20, 0.5) var camera_automatic_pan_speed:float = 12


# Flags
var camera_can_move_base:bool = true
var camara_can_automatic_pan:bool = true


# Noddes
@onready var camara_socket:Node3D = $camera_socket
@onready var camara:Camera3D = $camera_socket/Camera3D



func _ready() -> void:
	pass
	
	
func _process(delta: float) -> void:
	pass
	
	
func _unhandled_input(event: InputEvent) -> void:
	pass
	
func camera_base_move(delta:float) -> void:
	if !camera_can_move_base: return
	var velocity_direction:Vector3 = Vector3.ZERO
	
	
func camera_automatic_pan(delta:float) -> void:
	if !camara_can_automatic_pan: return
	
	var viewport_current:Viewport = get_viewport()
	var pan_direction:Vector2 = Vector2(-1, -1) # starts negative
	var viewport_visible_rectangle:Rect2i = Rect2i(viewport_current.get_visible_rect())
	var viewport_size:Vector2i = viewport_visible_rectangle.size
	
	
	
	pass
	
	
