class_name PlayerController extends Node

var client_id: String = OS.get_unique_id()

# Player Status
static var mouse_key_state: PlayerStatus.MouseKeyState = PlayerStatus.MouseKeyState.IDEL
static var mouse_state: PlayerStatus.MouseState = PlayerStatus.MouseState.IDEL

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	PlayerMovement.calculate_mouse_speed(get_viewport(), delta)

	pass

# player input event handler ( change status )
func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				mouse_key_state = PlayerStatus.MouseKeyState.MOUSE_LEFT_CLICK
			else:
				mouse_key_state = PlayerStatus.MouseKeyState.MOUSE_LEFT_RELEASED
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			if event.pressed:
				mouse_key_state = PlayerStatus.MouseKeyState.MOUSE_RIGHT_CLICK
			else:
				mouse_key_state = PlayerStatus.MouseKeyState.MOUSE_RIGHT_RELEASED


class PlayerStatus:
	enum MouseKeyState {
		IDEL,
		MOUSE_LEFT_CLICK,
		MOUSE_RIGHT_CLICK,
		MOUSE_LEFT_PRESSING,
		MOUSE_RIGHT_PRESSING,
		MOUSE_RIGHT_RELEASED,
		MOUSE_LEFT_RELEASED
	}
	enum MouseState {
		IDEL,
		MOVING
	}

class PlayerMovement:
	
	static var previous_mouse_position = Vector2.ZERO
	static var current_mouse_position = Vector2.ZERO
	static var mouse_speed = Vector2.ZERO

	static func calculate_mouse_speed(viewport: Viewport, delta: float) -> void:
		current_mouse_position = viewport.get_mouse_position()
		mouse_speed = (current_mouse_position - previous_mouse_position) / delta
		if mouse_speed.length() > 0:
			mouse_state = PlayerStatus.MouseState.MOVING
		else:
			mouse_state = PlayerStatus.MouseState.IDEL
    	previous_mouse_position = current_mouse_position

