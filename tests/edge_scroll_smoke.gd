extends SceneTree

class MotionFilter extends Node:
	var enabled := false
	func _input(event: InputEvent) -> void:
		if enabled and event is InputEventMouseMotion: get_viewport().set_input_as_handled()

var main_scene
var failures := 0
var assertions := 0
var started := Time.get_ticks_msec()
var samples: Array = []
var saved_mouse := Vector2i.ZERO
var interrupted := false

func _initialize() -> void:
	call_deferred("run")

func _process(_delta: float) -> bool:
	if Time.get_ticks_msec() - started > 540000: quit(1)
	return false

func check(value: bool, message: String) -> void:
	assertions += 1
	if not value:
		failures += 1
		push_error("EDGE_SCROLL_FAILED: " + message)

func key_f2() -> void:
	var event := InputEventKey.new()
	event.keycode = KEY_F2
	event.pressed = true
	root.push_input(event, true)
	event = event.duplicate()
	event.pressed = false
	root.push_input(event, true)

func frames(count: int) -> void:
	# process_frame precedes Node._process; wait through completed node updates.
	for index in count:
		await process_frame
		await create_timer(0.0).timeout

func run() -> void:
	if DisplayServer.get_name() == "headless":
		push_error("EDGE_SCROLL_FAILED: native desktop required")
		quit(1)
		return
	saved_mouse = DisplayServer.mouse_get_position()
	main_scene = load(ProjectSettings.get_setting("application/run/main_scene")).instantiate()
	main_scene.settings_path = "user://demo_edge_settings.cfg"
	root.add_child(main_scene)
	await create_timer(0.5).timeout
	main_scene.level_controller.next_level("level1")
	await create_timer(0.5).timeout
	var level = main_scene.level_controller._cur_scene
	level.wave_manager.cancel_spawning()
	var camera = level.get_node("RTSController")
	var policy = main_scene.cursor_policy
	policy.released = true
	policy.sync_mode()
	root.size = Vector2i(960, 640)
	root.position = DisplayServer.screen_get_usable_rect().position + Vector2i(100, 100)
	root.grab_focus()
	await create_timer(0.2).timeout
	DisplayServer.warp_mouse(root.size / 2)
	await create_timer(0.1).timeout
	root.focus_entered.emit()
	key_f2()
	await frames(3)
	check(root.has_focus() and policy.is_confined(), "native focus and confinement")
	var center: Vector2 = camera.map_bounds.get_center()
	var initial := Vector3(center.x, camera.cam.global_position.y, center.y)
	var filter := MotionFilter.new()
	main_scene.add_child(filter)
	# Establish an interior event cache, then prevent delivery of the final motion.
	DisplayServer.warp_mouse(root.size / 2)
	await frames(3)
	camera.cam.global_position = initial
	camera.velocity = Vector3.ZERO
	filter.enabled = true
	var before_frame := Engine.get_process_frames()
	DisplayServer.warp_mouse(Vector2i(-80, root.size.y / 2))
	await frames(2)
	check(camera.cam.global_position.x < initial.x, "edge starts within two frames even when final motion is consumed")
	samples.append({"case": "consumed_motion", "frames": Engine.get_process_frames() - before_frame, "initial": str(initial), "after_two_frames": str(camera.cam.global_position), "actual_mouse": str(DisplayServer.mouse_get_position()), "diagnostics": camera.get("diagnostics")})
	var middle: Vector3 = camera.cam.global_position
	await frames(3)
	check(camera.cam.global_position.x < middle.x, "missed event cannot leave camera stuck")
	if failures == 0 and not "--probe-only" in OS.get_cmdline_user_args():
		await stress(camera, policy, initial)
	if failures == 0 and not interrupted: await resizing(camera, policy, initial)
	filter.queue_free()
	await main_scene.level_controller.return_to_menu("")
	main_scene.queue_free()
	await frames(2)
	DisplayServer.warp_mouse(saved_mouse - DisplayServer.window_get_position(root.get_window_id()))
	var output := "res://.godot/edge-scroll-probe.json" if "--probe-only" in OS.get_cmdline_user_args() else "res://.godot/edge-scroll-results.json"
	var file := FileAccess.open(output, FileAccess.WRITE)
	file.store_string(JSON.stringify({"assertions": assertions, "failures": failures, "interrupted": interrupted, "samples": samples}, "\t"))
	file.close()
	print("EDGE_SCROLL_INTERRUPTED" if interrupted else ("EDGE_SCROLL_OK" if failures == 0 else "EDGE_SCROLL_FAILED"))
	print("EDGE_ASSERTIONS: ", assertions, "; failures=", failures)
	quit(0 if failures == 0 and not interrupted else 1)

func native_environment_valid(target: Vector2i, policy, phase: String) -> bool:
	var size := DisplayServer.window_get_size(root.get_window_id())
	var expected := target.clamp(Vector2i.ZERO, size - Vector2i.ONE)
	var actual := DisplayServer.mouse_get_position() - DisplayServer.window_get_position(root.get_window_id())
	if root.has_focus() and policy.focused and policy.is_confined() and Vector2(actual).distance_to(Vector2(expected)) <= 2.0: return true
	interrupted = true
	samples.append({"case": "environment_interrupted", "phase": phase, "expected_client_position": str(expected), "actual_client_position": str(actual), "window_focused": root.has_focus(), "policy_focused": policy.focused, "confined": policy.is_confined()})
	print("EDGE_ENVIRONMENT_INTERRUPTED: ", samples.back())
	return false

func stress(camera, policy, initial: Vector3) -> void:
	var previous_cap := Engine.max_fps
	var previous_vsync := DisplayServer.window_get_vsync_mode(root.get_window_id())
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED, root.get_window_id())
	var directions := [Vector2i(-1, 0), Vector2i(1, 0), Vector2i(0, -1), Vector2i(0, 1), Vector2i(-1, -1), Vector2i(1, -1), Vector2i(-1, 1), Vector2i(1, 1)]
	for cap in [30, 60, 144]:
		Engine.max_fps = cap
		var batch_started := Time.get_ticks_msec()
		var frame_started := Engine.get_process_frames()
		for iteration in 50:
			for direction in directions:
				DisplayServer.warp_mouse(root.size / 2)
				await frames(2)
				if not native_environment_valid(root.size / 2, policy, "interior"): return
				check(camera.velocity == Vector3.ZERO, "interior stops camera")
				camera.cam.global_position = initial
				camera.velocity = Vector3.ZERO
				var point := root.size / 2
				if direction.x != 0: point.x = -80 if direction.x < 0 else root.size.x + 80
				if direction.y != 0: point.y = -80 if direction.y < 0 else root.size.y + 80
				DisplayServer.warp_mouse(point)
				await frames(2)
				if not native_environment_valid(point, policy, "rapid_edge"): return
				var displacement: Vector3 = camera.cam.global_position - initial
				var began: bool = displacement.x * direction.x + displacement.z * direction.y > 0
				check(began, "rapid edge start cap=%d iteration=%d direction=%s" % [cap, iteration, direction])
				var held: Vector3 = camera.cam.global_position
				await frames(2)
				if not native_environment_valid(point, policy, "held_edge"): return
				var continued: Vector3 = camera.cam.global_position - held
				check(continued.x * direction.x + continued.z * direction.y > 0, "stationary edge continues")
				if not began:
					samples.append({"cap": cap, "iteration": iteration, "direction": str(direction), "actual_mouse": str(DisplayServer.mouse_get_position()), "viewport_mouse": str(root.get_mouse_position()), "confined": policy.is_confined(), "focused": root.has_focus(), "position": str(camera.cam.global_position), "diagnostics": camera.get("diagnostics")})
			if iteration % 10 == 0: print("EDGE_PROGRESS: cap=", cap, " iteration=", iteration, " failures=", failures)
		var elapsed_ms := Time.get_ticks_msec() - batch_started
		samples.append({"cap": cap, "attempts": 400, "elapsed_ms": elapsed_ms, "measured_fps": (Engine.get_process_frames() - frame_started) * 1000.0 / maxf(1, elapsed_ms)})
	Engine.max_fps = previous_cap
	DisplayServer.window_set_vsync_mode(previous_vsync, root.get_window_id())

func resizing(camera, policy, initial: Vector3) -> void:
	var usable := DisplayServer.screen_get_usable_rect()
	for resolution in [Vector2i(1280, 720), Vector2i(1920, 1080), Vector2i(1280, 800), Vector2i(2560, 1080)]:
		# Test logical resolutions even on monitors smaller than the requested size.
		root.size = resolution.min(usable.size - Vector2i(120, 120))
		root.content_scale_size = resolution
		root.grab_focus()
		await frames(3)
		DisplayServer.warp_mouse(root.size / 2)
		await frames(2)
		if policy.released or policy.needs_activation:
			key_f2()
			await frames(2)
		for direction in [Vector2i(-1, 0), Vector2i(1, 0), Vector2i(0, -1), Vector2i(0, 1)]:
			camera.cam.global_position = initial
			camera.velocity = Vector3.ZERO
			var point := root.size / 2
			if direction.x != 0: point.x = -80 if direction.x < 0 else root.size.x + 80
			if direction.y != 0: point.y = -80 if direction.y < 0 else root.size.y + 80
			DisplayServer.warp_mouse(point)
			await frames(2)
			if not native_environment_valid(point, policy, "resized_edge"): return
			var offset: Vector3 = camera.cam.global_position - initial
			check(offset.x * direction.x + offset.z * direction.y > 0, "resized window edge " + str(resolution) + str(direction))
		samples.append({"logical_target": str(resolution), "physical_size": str(root.size), "viewport_rect": str(root.get_visible_rect())})
	root.mode = Window.MODE_MAXIMIZED
	await frames(3)
	DisplayServer.warp_mouse(Vector2i(-80, DisplayServer.window_get_size(root.get_window_id()).y / 2))
	await frames(2)
	if not native_environment_valid(Vector2i(-80, DisplayServer.window_get_size(root.get_window_id()).y / 2), policy, "maximized_edge"): return
	check(camera.velocity.x < 0, "maximized window still scrolls at left edge")
	root.mode = Window.MODE_WINDOWED
	await frames(2)
