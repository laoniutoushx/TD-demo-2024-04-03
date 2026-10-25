extends Node
## Sole owner of battle mouse mode. Visibility requests never change confinement.
var main: Node
var focused := true
var released := false
var needs_activation := false
var activation_frame := -1
var hidden_owners: Dictionary = {}
var session_id := -1
var confined := false
var effective_mode := Input.MOUSE_MODE_VISIBLE
var pointer := Vector2.ZERO
var hint_session := -1
## Optional instance-local reader for deterministic tests; production uses Viewport.
var pointer_reader: Callable
var sample_frame := -1

func invalidate_pointer_sample() -> void:
	sample_frame = -1

func sample_pointer() -> Vector2:
	var frame := Engine.get_process_frames()
	if sample_frame == frame: return pointer
	sample_frame = frame
	pointer = Vector2.INF
	var viewport := get_viewport()
	var rect := viewport.get_visible_rect()
	if rect.size.x <= 0 or rect.size.y <= 0: return pointer
	if DisplayServer.get_name() != "headless":
		if get_window().mode == Window.MODE_MINIMIZED or is_zero_approx(viewport.get_screen_transform().determinant()): return pointer
	var position: Vector2 = pointer_reader.call() if pointer_reader.is_valid() else viewport.get_mouse_position()
	if not position.is_finite(): return pointer
	# Only correct a rounding-sized boundary error, never arbitrary outside data.
	if is_confined() and not rect.has_point(position) and rect.grow(1.0).has_point(position):
		position = position.clamp(rect.position, rect.end - Vector2(0.001, 0.001))
	pointer = position
	return pointer

func _ready() -> void:
	main = get_parent()
	process_mode = Node.PROCESS_MODE_ALWAYS
	process_priority = -100
	focused = get_window().has_focus() if DisplayServer.get_name() != "headless" else true
	needs_activation = not focused
	invalidate_pointer_sample()
	get_window().focus_exited.connect(_focus_lost)
	get_window().focus_entered.connect(_focus_gained)
	get_window().mouse_exited.connect(_mouse_exited)
	get_window().mouse_entered.connect(_mouse_entered)

func _context_active() -> bool:
	if not is_instance_valid(main) or main._quitting or get_tree().paused: return false
	var controller = main.level_controller
	if not is_instance_valid(controller) or not controller.battle_active or controller._transitioning or is_instance_valid(controller._settings): return false
	var player = main.player_controller
	return is_instance_valid(player) and player.player_status != PlayerController.PLAYER_STATUS.CHOOSING_TALENT

func _process(_delta: float) -> void:
	invalidate_pointer_sample()
	sync_mode()

func sync_mode() -> void:
	if not is_instance_valid(main): return
	var controller = main.level_controller
	if is_instance_valid(controller) and session_id != controller.session_id:
		session_id = controller.session_id
		hidden_owners.clear()
		released = false
		needs_activation = not focused
	for id in hidden_owners.keys():
		var owner = hidden_owners[id].get_ref()
		if not is_instance_valid(owner) or (owner is Node and owner.is_queued_for_deletion()): hidden_owners.erase(id)
	var inside := get_viewport().get_visible_rect().has_point(sample_pointer())
	confined = _context_active() and focused and not released and not needs_activation and (confined or inside)
	var mode := Input.MOUSE_MODE_VISIBLE
	if confined: mode = Input.MOUSE_MODE_CONFINED_HIDDEN if not hidden_owners.is_empty() else Input.MOUSE_MODE_CONFINED
	effective_mode = mode
	if Input.mouse_mode != mode: Input.set_mouse_mode(mode)
	if confined and hint_session != session_id:
		hint_session = session_id
		main.message_bar.set_message("战斗中鼠标限制在窗口内 · F2 可释放")
	if not confined: _stop_camera()

func request_hidden(owner: Object, hidden: bool) -> void:
	if not is_instance_valid(owner): return
	sync_mode()
	if hidden: hidden_owners[owner.get_instance_id()] = weakref(owner)
	else: hidden_owners.erase(owner.get_instance_id())
	sync_mode()

func release_owner(owner: Object) -> void:
	request_hidden(owner, false)

func world_input_blocked() -> bool:
	return not input_block_reason().is_empty()

func input_block_reason() -> String:
	if not focused: return "unfocused"
	if released: return "cursor_released"
	if needs_activation: return "awaiting_activation"
	if activation_frame == Engine.get_process_frames(): return "activation_frame"
	return ""

func is_confined() -> bool:
	return confined and (DisplayServer.get_name() == "headless" or Input.mouse_mode in [Input.MOUSE_MODE_CONFINED, Input.MOUSE_MODE_CONFINED_HIDDEN])

func _input(event: InputEvent) -> void:
	if event is InputEventMouse: invalidate_pointer_sample()
	if not _context_active() or not focused: return
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F2:
		if released or needs_activation: _activate()
		else:
			released = true
			_cancel_gesture()
			sync_mode()
			main.message_bar.set_message("鼠标已释放 · F2 或点击战场恢复限制")
		get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT and (released or needs_activation):
		var input_policy = load("res://Scripts/utils/BattleInput.gd")
		if get_viewport().get_visible_rect().has_point(event.position) and not input_policy.over_blocking_ui(get_viewport(), event.position):
			_activate()
			get_viewport().set_input_as_handled()

func _activate() -> void:
	released = false
	needs_activation = false
	activation_frame = Engine.get_process_frames()
	_cancel_gesture()
	sync_mode()
	main.message_bar.set_message("鼠标已限制在窗口内 · F2 释放" if confined else "鼠标进入游戏区域后恢复限制 · F2 释放")

func _focus_lost() -> void:
	focused = false
	needs_activation = true
	_cancel_gesture()
	sync_mode()

func _focus_gained() -> void:
	focused = true
	invalidate_pointer_sample()
	# A focus change never captures while dragging the title bar.
	sync_mode()

func _mouse_exited() -> void:
	invalidate_pointer_sample()

func _mouse_entered() -> void:
	invalidate_pointer_sample()
	sync_mode()

func _notification(what: int) -> void:
	if not is_node_ready(): return
	if what == NOTIFICATION_PAUSED: sync_mode()
	elif what == NOTIFICATION_APPLICATION_FOCUS_OUT: _focus_lost()

func _cancel_gesture() -> void:
	var player = main.player_controller
	if is_instance_valid(player) and is_instance_valid(player.selection_box): player.selection_box.cancel_selection("cursor_released")
	_stop_camera()

func _stop_camera() -> void:
	if not is_instance_valid(main.level_controller): return
	var level = main.level_controller.level_map.get("level1")
	if is_instance_valid(level):
		var camera = level.get_node_or_null("RTSController")
		if camera != null: camera.velocity = Vector3.ZERO

func reset_session() -> void:
	hidden_owners.clear()
	released = false
	needs_activation = false
	activation_frame = -1
	invalidate_pointer_sample()
	confined = false
	effective_mode = Input.MOUSE_MODE_VISIBLE
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _exit_tree() -> void:
	reset_session()
