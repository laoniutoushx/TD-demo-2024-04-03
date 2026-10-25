extends SceneTree

var main_scene
var failures := 0
var performance_samples: Array = []
var elapsed := 0.0
var started_at := Time.get_ticks_msec()

func _process(delta: float) -> bool:
	elapsed += delta
	if Time.get_ticks_msec() - started_at > 180000:
		push_error("RTS_QUALITY_TIMEOUT")
		quit(1)
	return false

func _initialize() -> void:
	call_deferred("run")

func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error("RTS_QUALITY_FAILED: " + message)

func run() -> void:
	main_scene = load(ProjectSettings.get_setting("application/run/main_scene")).instantiate()
	main_scene.settings_path = "user://demo_quality_settings.cfg"
	root.add_child(main_scene)
	await create_timer(1.0).timeout
	var controller = main_scene.level_controller
	controller.next_level("level1")
	await create_timer(0.6).timeout
	# Synthetic gameplay events must explicitly activate the new focus policy.
	root.focus_entered.emit()
	if main_scene.cursor_policy.world_input_blocked():
		var activate := InputEventKey.new()
		activate.keycode = KEY_F2
		activate.pressed = true
		root.push_input(activate, true)
		activate = activate.duplicate()
		activate.pressed = false
		root.push_input(activate, true)
		await process_frame
	var level = controller._cur_scene
	var player = main_scene.player_controller
	var camera_controller = level.get_node("RTSController")
	check(is_equal_approx(camera_controller.scroll_direction(Vector2.ZERO, Vector2(1080, 768)).length(), 1.0), "diagonal scrolling normalized")
	var camera_position: Vector3 = camera_controller.cam.global_position
	root.focus_exited.emit()
	camera_controller.mouse_camera_move(0.5)
	check(camera_controller.cam.global_position == camera_position and camera_controller.velocity == Vector3.ZERO, "focus loss stops camera")
	root.focus_entered.emit()
	var reactivate := InputEventKey.new()
	reactivate.keycode = KEY_F2
	reactivate.pressed = true
	root.push_input(reactivate, true)
	reactivate = reactivate.duplicate()
	reactivate.pressed = false
	root.push_input(reactivate, true)
	await process_frame
	camera_controller.edge_scroll_enabled = false
	var manager = level.turret_manager
	var grid = level.get_node("GridMap")
	var cell: Vector3i = grid.get_used_cells()[0]
	var old_transform: Transform3D = grid.transform
	grid.position += Vector3(3, 2, 5)
	check(manager.world_to_cell(manager.cell_to_world(cell)) == cell, "transformed grid roundtrip")
	grid.transform = old_transform
	var footprint_definition = load("res://Unit/turret/resources/Cannon1.tres").duplicate(false)
	footprint_definition.building_footprint = Vector2i(2, 1)
	for candidate in grid.get_used_cells():
		if manager.placement_reason(candidate, footprint_definition) == "":
			var neighbor: Vector3i = candidate + Vector3i(1, 0, 0)
			manager.occupied[neighbor] = 999
			check(manager.placement_reason(candidate, footprint_definition) != "", "multi-cell footprint checks every cell")
			manager.occupied.erase(neighbor)
			break
	var source = level.gdbot
	root.get_node("SignalBus").player_selected_units.emit({source.get_instance_id(): source}, source.global_position, 0)
	await process_frame
	var building_skill
	for skill in source.skill_map.values():
		if skill.skill_meta_res.building_res != null and skill.skill_meta_res.building_res.resource_path.ends_with("Cannon1.tres"):
			building_skill = skill
	check(is_instance_valid(building_skill), "original cannon building skill retained")
	if building_skill == null:
		quit(1)
		return
	var original = building_skill.skill_meta_res
	building_skill.skill_meta_res = original.duplicate(false)
	building_skill.skill_meta_res.building_res = original.building_res.duplicate(false)
	building_skill.skill_meta_res.building_res.wood_cost = 10
	building_skill.skill_meta_res.building_res.money_cost = 30
	player.wood = 100
	player.money = 5
	var context = load("res://System/skill_system/domain/SkillContext.gd").new(building_skill, null, source, Vector3.ZERO)
	var mana: float = source.mana
	check(not player.commit_skill_cost(context), "reject insufficient second resource")
	check(player.wood == 100 and player.money == 5 and source.mana == mana, "failed transaction changes no balances")
	player.money = 100
	check(player.commit_skill_cost(context), "atomic payment")
	check(player.commit_skill_cost(context) and player.money == 70 and player.wood == 90, "same payment idempotent")
	building_skill.skill_meta_res = original
	player.money = 10000
	player.wood = 10000
	building_skill.change_state(building_skill.SKILL_STATE.Building_Indicate)
	await create_timer(0.15).timeout
	check(is_instance_valid(manager.turret), "original preview created")
	building_skill.change_state(building_skill.SKILL_STATE.Idle)
	manager.cancel_preview()
	await process_frame
	check(manager.turret == null and manager.occupied.is_empty(), "cancel clears preview without occupation")
	building_skill.change_state(building_skill.SKILL_STATE.Building_Indicate)
	await create_timer(0.15).timeout
	for candidate in grid.get_used_cells():
		if manager.placement_reason(candidate) == "":
			cell = candidate
			break
	check(manager.confirm_build(cell), "confirm grid building")
	var paid: int = player.money
	check(not manager.confirm_build(cell) and player.money == paid, "duplicate build rejected")
	await create_timer(1.5).timeout
	var cannon = instance_from_id(manager.occupied.get(cell, 0))
	check(is_instance_valid(cannon) and cannon.is_alive(), "build animation completes")
	var legacy_delay: float = main_scene.damage_system.attack_delay(cannon)
	cannon.anim_ack_normalized = 0.5
	check(is_equal_approx(main_scene.damage_system.attack_delay(cannon), cannon._ap.get_animation(cannon.anim_attack).length * 0.5), "normalized animation release binding")
	cannon.anim_ack_normalized = -1
	check(is_equal_approx(main_scene.damage_system.attack_delay(cannon), legacy_delay), "legacy attack timing retained")
	var item_id: String = source.item_map.values()[0].id
	main_scene.item_system.transfer_all(source, cannon)
	player.refresh_selection_units({cannon.get_instance_id(): cannon}, cannon.global_position, 0)
	var upgrade = cannon.skill_map.get("building_level_up")
	check(upgrade != null, "existing upgrade path")
	if upgrade:
		upgrade.building_level_up_time = 0.03
		var uid: String = cannon.unit_uid
		var kills: int = player.death_unit_num
		var gold: int = player.money
		await upgrade.skill_script_instance.action(upgrade.skill_context)
		var upgraded = instance_from_id(manager.occupied.get(cell, 0))
		check(is_instance_valid(upgraded) and upgraded != cannon and upgraded.unit_uid == uid, "upgrade keeps identity and occupied cell")
		check(player.death_unit_num == kills and player.money == gold, "upgrade emits no death income")
		check(upgraded.item_map.size() == 1 and upgraded.item_map.values()[0].id == item_id, "upgrade preserves item instance")
		var base_damage: float = upgraded.attack_value
		for iteration in 20:
			var modifier = load("res://System/buff_system/resources/power_buff.gd").new()
			modifier.code = "quality_roundtrip"
			modifier.prop = "attack_value"
			modifier.value = 25
			modifier.value_unit = 0
			modifier.max_overlay_num = 1
			main_scene.buff_system.apply(modifier, upgraded.item_map.values()[0], upgraded)
			modifier.free()
			for buff in upgraded.buff_map.values().duplicate():
				if buff.code == "quality_roundtrip": main_scene.buff_system.remove(buff, upgraded)
			check(is_equal_approx(upgraded.attack_value, base_damage), "buff roundtrip without residual")
			await process_frame
	# Exercise the actual right-click input path, not only ItemSystem.pick_up().
	player.refresh_selection_units({source.get_instance_id(): source}, source.global_position, 0)
	var motion := InputEventMouseMotion.new()
	motion.position = Vector2(540, 230)
	Input.parse_input_event(motion)
	await process_frame
	var chest = main_scene.item_system._chest.instantiate()
	chest.drop_item = load("res://System/item_system/domain/DropItem.gd").new()
	chest.drop_item.item_name = "axe"
	main_scene.item_system.add_child(chest)
	player.cur_unit_map = {chest.get_instance_id(): chest}
	player.set_process_unhandled_input(true)
	var right_click := InputEventMouseButton.new()
	right_click.button_index = MOUSE_BUTTON_RIGHT
	right_click.position = motion.position
	right_click.pressed = true
	root.push_input(right_click, true)
	if not source.item_map.has("axe"):
		print("PICKUP_INPUT_STATE: mode=", player.player_status, " mouse=", root.get_mouse_position(), " allowed=", load("res://Scripts/utils/BattleInput.gd").pointer_available(root, right_click.position), " selected=", player.PlayerSelect.units().size(), " listening=", player.is_processing_unhandled_input(), " handled=", root.is_input_handled())
		for control in main_scene.find_children("*", "Control", true, false):
			if control.get_viewport() == root and control.is_visible_in_tree() and control.mouse_filter == Control.MOUSE_FILTER_STOP and control.get_global_rect().has_point(right_click.position): print("PICKUP_BLOCKER: ", control.get_path())
	check(source.item_map.has("axe") and chest.is_queued_for_deletion(), "right-click pickup through actual input")
	var right_release := right_click.duplicate()
	right_release.pressed = false
	root.push_input(right_release, true)
	if not source.item_map.has("axe"):
		call_deferred("finish")
		return
	var item_slot = source.item_map["axe"].slot
	var source_damage: float = source.attack_value
	for iteration in 2:
		item_slot._on_slot_right_clicked(item_slot)
		var escape := InputEventKey.new()
		escape.keycode = KEY_ESCAPE
		escape.pressed = true
		root.push_input(escape, true)
		var escape_release := escape.duplicate()
		escape_release.pressed = false
		root.push_input(escape_release, true)
		check(player.player_status == 0 and source.item_map.has("axe") and source.attack_value == source_damage, "drop preview cancel keeps equipment and effect")
	# Preserve normal overlapping wave policy; use explicit tracking for terminal tests.
	var waves = level.wave_manager
	waves.cancel_spawning()
	for spawner in waves.get_children():
		if spawner.get_script() == load("res://Unit/enemy/EnemySpawner.gd"): spawner.queue_free()
	for enemy in get_nodes_in_group("enemy"):
		if enemy.has_method("is_alive") and enemy.is_alive(): enemy.do_logical_death("cleanup")
	await process_frame
	waves.is_game_over = false
	var enemy_name: String = waves.wave_resources[0].enemy_spawner_resource[0].enemy_res_name
	var enemy_resource = load("res://Unit/enemy/resources/" + enemy_name + ".tres")
	for count in [50, 100, 200]:
		var pressure: Array = []
		for index in count:
			var enemy = main_scene.unit_system.create_unit(enemy_resource, 1)
			level.get_node("Path3D").add_child(enemy)
			enemy.progress = index * 0.15
			enemy.set_process(false)
			enemy.max_health = 1000000.0
			pressure.append(enemy)
		for warmup in 15: await process_frame
		var frames: Array[float] = []
		var previous_tick := Time.get_ticks_usec()
		for frame in 30:
			await process_frame
			var current_tick := Time.get_ticks_usec()
			frames.append((current_tick - previous_tick) / 1000.0)
			previous_tick = current_tick
		frames.sort()
		performance_samples.append({"enemies": count, "quality": main_scene.config.graphics_quality, "resolution": str(root.size), "mean_frame_ms": frames.reduce(func(a, b): return a + b, 0.0) / frames.size(), "p95_frame_ms": frames[int(frames.size() * 0.95)], "draw_calls": Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)})
		for enemy in pressure:
			if is_instance_valid(enemy): enemy.queue_free()
		await process_frame
	waves.all_spawning_finished = true
	var final_enemy = main_scene.unit_system.create_unit(enemy_resource, 1)
	level.get_node("Path3D").add_child(final_enemy)
	waves.register_enemy(final_enemy, 31)
	waves._check_clear()
	check(controller.battle_active, "last spawning complete does not win while enemy alive")
	final_enemy.do_logical_death()
	final_enemy.do_logical_death()
	await create_timer(0.1).timeout
	check(controller.result.get("is_win", false), "final tracked enemy resolves victory once")
	await controller.return_to_menu("level1")
	await process_frame
	var defeat_level = controller._cur_scene
	defeat_level.wave_manager.cancel_spawning()
	defeat_level.wave_manager.is_game_over = false
	defeat_level.wave_manager.all_spawning_finished = true
	defeat_level.wave_manager._check_clear.call_deferred()
	var base = get_first_node_in_group("base")
	base.current_life = 1
	base.take_damage()
	await process_frame
	check(controller.result.get("is_win", true) == false, "same-frame failure beats deferred final clear")
	for cycle in 20:
		await controller.return_to_menu("level1")
		await process_frame
		await controller.return_to_menu()
		await process_frame
		check(main_scene.player_controller == null, "repeated player teardown")
	var settings = controller.open_settings()
	var saved_config: Dictionary = main_scene.config.duplicate(true)
	settings.sound_volum.value = 17
	settings._on_return_pressed()
	await process_frame
	check(main_scene.config == saved_config, "settings cancel restores preview")
	var output := FileAccess.open("res://.godot/rts-performance.json", FileAccess.WRITE)
	output.store_string(JSON.stringify(performance_samples, "\t"))
	output.close()
	call_deferred("finish")

func finish() -> void:
	main_scene.queue_free()
	await process_frame
	await create_timer(0.3).timeout
	print("RTS_QUALITY_OK" if failures == 0 else "RTS_QUALITY_FAILED")
	quit(0 if failures == 0 else 1)
