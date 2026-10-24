extends SceneTree

var main_scene
var failures := 0
var assertions := 0
var started := Time.get_ticks_msec()
var original_mouse := Vector2i.ZERO
var native_samples: Array = []

func _initialize() -> void:
	call_deferred("run")

func _process(_delta: float) -> bool:
	if Time.get_ticks_msec() - started > 90000: quit(1)
	return false

func check(value: bool, description: String) -> void:
	assertions += 1
	if not value:
		failures += 1
		push_error("CURSOR_POLICY_FAILED: " + description)

func key(code: int) -> void:
	var event := InputEventKey.new()
	event.keycode = code
	event.pressed = true
	root.push_input(event, true)
	event = event.duplicate()
	event.pressed = false
	root.push_input(event, true)

func click(point: Vector2) -> void:
	var motion := InputEventMouseMotion.new()
	motion.position = point
	root.push_input(motion, true)
	var button := InputEventMouseButton.new()
	button.position = point
	button.button_index = MOUSE_BUTTON_LEFT
	button.pressed = true
	root.push_input(button, true)
	button = button.duplicate()
	button.pressed = false
	root.push_input(button, true)

func mouse_mode() -> int:
	return main_scene.cursor_policy.effective_mode if DisplayServer.get_name() == "headless" else Input.mouse_mode

func run() -> void:
	if DisplayServer.get_name() != "headless": original_mouse = DisplayServer.mouse_get_position()
	main_scene = load(ProjectSettings.get_setting("application/run/main_scene")).instantiate()
	main_scene.settings_path = "user://demo_cursor_settings.cfg"
	root.add_child(main_scene)
	await create_timer(0.5).timeout
	check(mouse_mode() == Input.MOUSE_MODE_VISIBLE, "menu does not confine mouse")
	var controller = main_scene.level_controller
	controller.next_level("level1")
	await create_timer(0.5).timeout
	var policy = main_scene.cursor_policy
	var level = controller._cur_scene
	level.wave_manager.cancel_spawning()
	var camera = level.get_node("RTSController")
	root.focus_entered.emit()
	click(root.get_visible_rect().size * 0.5)
	await process_frame
	policy.sync_mode()
	check(policy.is_confined(), "battle confines visible cursor")
	var owner_a := Node.new()
	var owner_b := Node.new()
	main_scene.add_child(owner_a)
	main_scene.add_child(owner_b)
	policy.request_hidden(owner_a, true)
	policy.request_hidden(owner_b, true)
	check(mouse_mode() == Input.MOUSE_MODE_CONFINED_HIDDEN, "hidden skill cursor remains confined")
	policy.release_owner(owner_a)
	check(mouse_mode() == Input.MOUSE_MODE_CONFINED_HIDDEN, "releasing one owner keeps the other request")
	owner_b.queue_free()
	await process_frame
	await process_frame
	check(mouse_mode() == Input.MOUSE_MODE_CONFINED, "freed owner cannot leave hidden cursor behind")
	key(KEY_F2)
	check(mouse_mode() == Input.MOUSE_MODE_VISIBLE and policy.world_input_blocked(), "F2 releases cursor and blocks world polling")
	var selected_before: Dictionary = main_scene.player_controller.PlayerSelect.unit_map()
	click(Vector2(300, 300))
	check(policy.is_confined() and main_scene.player_controller.PlayerSelect.unit_map() == selected_before and not main_scene.player_controller.PlayerSelect.is_selecting(), "activation click cannot select or clear selection")
	check(not load("res://Scripts/utils/BattleInput.gd").pointer_available(root, Vector2(300, 300)), "activation frame also blocks polled skills/building")
	await process_frame
	await process_frame
	check(not policy.world_input_blocked(), "next frame restores world interaction")
	root.focus_exited.emit()
	check(mouse_mode() == Input.MOUSE_MODE_VISIBLE and camera.velocity == Vector3.ZERO, "focus loss releases immediately")
	root.focus_entered.emit()
	check(mouse_mode() == Input.MOUSE_MODE_VISIBLE, "focus return alone does not confine on title bar")
	click(Vector2(300, 300))
	await process_frame
	check(policy.is_confined(), "clicking game restores confinement")
	for mode in ["settings", "pause", "talent"]:
		match mode:
			"settings": controller.open_settings()
			"pause": paused = true
			"talent": main_scene.player_controller.player_status = 4
		check(mouse_mode() == Input.MOUSE_MODE_VISIBLE, mode + " releases immediately")
		match mode:
			"settings": controller._settings._on_return_pressed()
			"pause": paused = false
			"talent": main_scene.player_controller.player_status = 0
		await process_frame
		await process_frame
		check(policy.is_confined(), mode + " restores confinement")
	if DisplayServer.get_name() != "headless": await exercise_native(camera, policy)
	policy.request_hidden(owner_a, true)
	await controller.return_to_menu("")
	check(mouse_mode() == Input.MOUSE_MODE_VISIBLE and policy.hidden_owners.is_empty(), "session cleanup releases cursor and owners")
	owner_a.queue_free()
	main_scene.queue_free()
	await process_frame
	await create_timer(0.1).timeout
	if DisplayServer.get_name() != "headless": DisplayServer.warp_mouse(original_mouse - DisplayServer.window_get_position(root.get_window_id()))
	var report := {"display": DisplayServer.get_name(), "arguments": OS.get_cmdline_args(), "assertions": assertions, "failures": failures, "native_samples": native_samples}
	var file := FileAccess.open("res://.godot/cursor-policy-" + DisplayServer.get_name() + ".json", FileAccess.WRITE)
	file.store_string(JSON.stringify(report, "\t"))
	file.close()
	print("CURSOR_POLICY_OK" if failures == 0 else "CURSOR_POLICY_FAILED")
	print("CURSOR_ASSERTIONS: ", assertions, "; failures=", failures)
	quit(0 if failures == 0 else 1)

func exercise_native(camera, policy) -> void:
	# Actual OS cursor positions, not merely an Input.mouse_mode enum assertion.
	policy.released = true
	policy.sync_mode()
	root.size = Vector2i(960, 640)
	root.position = DisplayServer.screen_get_usable_rect().position + Vector2i(100, 100)
	root.grab_focus()
	await create_timer(0.2).timeout
	var client := Rect2i(DisplayServer.window_get_position(root.get_window_id()), DisplayServer.window_get_size(root.get_window_id()))
	DisplayServer.warp_mouse(client.size / 2)
	await create_timer(0.1).timeout
	key(KEY_F2)
	await create_timer(0.1).timeout
	check(root.has_focus() and policy.is_confined(), "native window really has focus and confines mouse")
	var center: Vector2 = camera.map_bounds.get_center()
	var initial := Vector3(center.x, camera.cam.global_position.y, center.y)
	for direction in [Vector2i(-1, 0), Vector2i(1, 0), Vector2i(0, -1), Vector2i(0, 1), Vector2i(-1, -1), Vector2i(1, -1), Vector2i(-1, 1), Vector2i(1, 1)]:
		camera.cam.global_position = initial
		camera.velocity = Vector3.ZERO
		var attempted := client.get_center()
		if direction.x != 0: attempted.x = client.position.x - 80 if direction.x < 0 else client.end.x + 80
		if direction.y != 0: attempted.y = client.position.y - 80 if direction.y < 0 else client.end.y + 80
		DisplayServer.warp_mouse(attempted - client.position)
		await create_timer(0.18).timeout
		var actual := DisplayServer.mouse_get_position()
		check(client.has_point(actual), "OS clamps cursor inside client " + str(direction))
		var middle: Vector3 = camera.cam.global_position
		await create_timer(0.18).timeout
		var displacement: Vector3 = camera.cam.global_position - middle
		check(displacement.x * direction.x + displacement.z * direction.y > 0, "edge keeps scrolling without further motion " + str(direction))
		native_samples.append({"direction": str(direction), "attempted": str(attempted), "actual": str(actual), "inside": client.has_point(actual), "continued_displacement": str(displacement)})
	key(KEY_F2)
	var stopped: Vector3 = camera.cam.global_position
	DisplayServer.warp_mouse(client.size + Vector2i(25, 25))
	await create_timer(0.1).timeout
	check(not client.has_point(DisplayServer.mouse_get_position()), "F2 actually releases OS cursor outside window")
	check(camera.velocity == Vector3.ZERO and camera.cam.global_position == stopped, "released cursor outside window cannot keep moving camera")
