extends SceneTree

# Run with Godot --path <project> --script res://tests/game_flow_smoke.gd.
# The same test runs against the headless and Forward+ renderers.
var elapsed := 0.0
var main_scene
var menu_node_limit := 0
var initial_orphans := 0
var binding_report: Array = []

func _initialize() -> void:
	call_deferred("run")

func _process(delta: float) -> bool:
	elapsed += delta
	if elapsed > 120.0:
		push_error("FLOW_TEST_TIMEOUT")
		quit(1)
	return false

func check(condition: bool, message: String) -> bool:
	if not condition:
		push_error("FLOW_TEST_FAILED: " + message)
		quit(1)
	return condition

func run() -> void:
	var entry_path: String = ProjectSettings.get_setting("application/run/main_scene", "")
	if not check(entry_path == "res://Main.tscn", "default entry preserves original demo"):
		return
	main_scene = load(entry_path).instantiate()
	main_scene.settings_path = "user://demo_regression_settings.cfg"
	root.add_child(main_scene)
	await create_timer(1.0).timeout
	initial_orphans = int(Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT))
	var controller = main_scene.level_controller
	var bus = root.get_node("SignalBus")
	if "--exit-from-menu" in OS.get_cmdline_user_args():
		print("MENU_EXIT_OK")
		controller._cur_scene.index_ui._on_exit_pressed()
		return
	for cycle in 3:
		var menu = controller._cur_scene
		if not check(menu == controller.level_map.get("index"), "menu route"):
			return
		if cycle == 0:
			await capture("menu")
		var settings = controller.open_settings()
		check(controller.open_settings() == settings, "single settings window")
		if cycle == 0:
			await capture("settings")
		settings.bg_volum.value = 0.0
		check(is_equal_approx(main_scene.config.bg_volume, 0.0), "mute music")
		settings.bg_volum.value = 50.0
		settings.sound_volum.value = 25.0
		settings._on_apply_pressed()
		await process_frame
		settings = controller.open_settings()
		check(is_equal_approx(settings.sound_volum.value, 25.0), "settings retained")
		settings._on_return_pressed()
		await process_frame
		menu.index_ui._on_start_pressed()
		await create_timer(2.0).timeout
		var level = controller._cur_scene
		level.get_node("RTSController").edge_scroll_enabled = false
		if cycle == 0:
			await audit_battle_resources(level)
		if not check(level.get("action_bar") != null, "battle route"):
			return
		check(is_instance_valid(main_scene.player_controller), "player initialized")
		var unit = level.gdbot
		bus.player_selected_units.emit({unit.get_instance_id(): unit}, Vector3.ZERO, 0)
		await process_frame
		check(level.action_bar.active_unit == unit, "selection and action bar")
		check(not unit.skill_map.is_empty(), "unit skills initialized")
		check(unit.buff_map.size() > 0, "passive recovery buffs")
		var health = unit.health
		unit.health = health - 5.0
		await create_timer(1.1).timeout
		check(unit.health > health - 5.0, "recovery tick")
		main_scene.player_controller.add_talent("greedy_talent")
		level.action_bar.player_bar_comp.reset_slot_for_player()
		await process_frame
		if cycle == 0:
			# Drop the starting item, remove its effects, then pick it up again.
			var item = unit.item_map.values()[0]
			var item_code = item.code
			var slot = item.slot
			var chest = main_scene.item_system.generate_chest(item, unit.global_position)
			for buff in unit.buff_map.values():
				if buff.reference_instance == item:
					main_scene.buff_system.remove(buff, unit)
			level.action_bar.item_bar_comp.drop_item(slot)
			main_scene.item_system.remove_item_from_inventory(item)
			await process_frame
			var picked = main_scene.item_system.pick_up(unit, chest)
			check(is_instance_valid(picked) and unit.item_map.has(item_code), "drop and pickup")
			await process_frame
			await exercise_building(level, unit, bus)
			await capture("battle")
			if "--quit-in-combat" in OS.get_cmdline_user_args():
				print("COMBAT_SHUTDOWN_OK")
				main_scene.request_quit()
				return
		# Damage and death through the real enemy path.
		var enemies = get_nodes_in_group("enemy")
		if not enemies.is_empty():
			var enemy = null
			for candidate in enemies:
				if candidate.has_method("take_damage"):
					enemy = candidate
					break
			if not check(is_instance_valid(enemy), "spawned enemy"):
				return
			var damage = load("res://System/damage_system/damage_ctx.gd").new(unit, enemy, 10.0)
			check(enemy.take_damage(damage) is bool, "damage result")
			enemy._damage(load("res://System/damage_system/damage_ctx.gd").new(unit, enemy, 10.0))
			check(enemy.health < enemy.max_health, "enemy takes damage")
			bus.player_selected_units.emit({}, Vector3.ZERO, 0)
			await process_frame
		# Keep a projectile pending while the battle is ended and restarted.
		if cycle == 0:
			for turret in level.turret_manager.get_children():
				if turret.get("fire_poses") == null or turret.fire_poses.is_empty() or not turret.is_alive():
					continue
				for target in get_nodes_in_group("enemy"):
					if target.has_method("take_damage") and target.is_alive():
						turret.projectile_speed = 0.001
						main_scene.barrage_system.action(turret, turret.global_position, target, turret.fire_poses[0])
						break
				break
		# Exercise loss, duplicate loss, result settings and restart.
		var base = get_first_node_in_group("base")
		for i in base.life:
			base.take_damage()
		var result_screen = controller._cur_scene
		if cycle == 0:
			await capture("result")
		base.take_damage()
		check(controller._cur_scene == result_screen, "single result screen")
		check(controller.result.waves > 0, "result snapshot")
		result_screen._on_setting_pressed()
		await process_frame
		controller._settings._on_return_pressed()
		if cycle == 0:
			result_screen._on_restart_pressed()
			await create_timer(0.5).timeout
			check(controller.battle_active and controller._cur_scene.get("gdbot") != null, "restart directly into new battle")
			check(main_scene.player_controller.money == 20, "restart resets economy")
			controller.finish_battle(false)
			result_screen = controller._cur_scene
		result_screen._on_menu_pressed()
		await create_timer(0.5).timeout
		check(main_scene.player_controller == null, "player released")
		check(not is_instance_valid(level), "old battle released")
		check(main_scene.barrage_system.get_child_count() == 0, "projectiles cancelled")
		check(main_scene.vfx_system.get_child_count() == 0, "effects released")

		if cycle == 0:
			menu_node_limit = get_node_count() + main_scene.floating_text_system.max_pool_size
		check(get_node_count() <= menu_node_limit, "bounded scene node count")
		check(int(Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT)) <= initial_orphans, "no orphan nodes after restart")
		print("LIFECYCLE_SAMPLE: nodes=", get_node_count(), " orphans=", Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT))
		print("FLOW_CYCLE_OK: ", cycle + 1)
	main_scene.queue_free()
	await process_frame
	await create_timer(0.3).timeout
	print("FLOW_TEST_OK")
	var report_file := FileAccess.open("res://.godot/asset-binding-report.json", FileAccess.WRITE)
	if report_file: report_file.store_string(JSON.stringify(binding_report, "\t"))
	quit()


func capture(label: String) -> void:
	if DisplayServer.get_name() == "headless":
		return
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://.godot/qa_" + label + ".png")

func exercise_building(level, unit, bus) -> void:
	var built: Array = []
	for skill in unit.skill_map.values():
		if skill.skill_meta_res.building_res == null:
			continue
		var turret = main_scene.unit_system.create_unit(skill.skill_meta_res.building_res, 0)
		level.turret_manager.add_child(turret)
		turret.position = Vector3(3.0 + built.size() * 3.0, 0, 10.0)
		skill.skill_context.building = turret
		skill.skill_context.callback = turret.change_state.bind(1)
		await skill.skill_script_instance.action(skill.skill_context)
		check(is_instance_valid(turret) and turret.current_state == 1, "building " + skill.code)
		built.append(turret)
	if built.is_empty():
		check(false, "buildable units")
		return
	var cannon = built[1]
	bus.player_selected_units.emit({cannon.get_instance_id(): cannon}, Vector3.ZERO, 0)
	await process_frame
	if cannon.skill_map.has("building_level_up"):
		var upgrade = cannon.skill_map["building_level_up"]
		await upgrade.skill_script_instance.action(upgrade.skill_context)
		check(not cannon.is_alive(), "upgrade retires old turret")
	for turret in built:
		if not is_instance_valid(turret) or not turret.is_alive():
			continue
		bus.player_selected_units.emit({turret.get_instance_id(): turret}, Vector3.ZERO, 0)
		await process_frame
		for skill in turret.skill_map.values():
			if skill.skill_meta_res.building_res != null or (skill.release_type & 32) != 0:
				continue
			var enemy = null
			for candidate in get_nodes_in_group("enemy"):
				if candidate.has_method("take_damage") and candidate.is_alive():
					enemy = candidate
					break
			if not is_instance_valid(enemy):
				continue
			skill.skill_context.target = enemy
			skill.skill_context.target_position = enemy.global_position
			skill.change_state(skill.SKILL_STATE.Release)
			await create_timer(0.6).timeout
	await create_timer(2.0).timeout
	bus.player_selected_units.emit({unit.get_instance_id(): unit}, Vector3.ZERO, 0)
	await process_frame

func audit_battle_resources(level) -> void:
	var enemy_names: Dictionary = {}
	for wave in level.wave_manager.wave_resources:
		if wave == null:
			continue
		for spawner in wave.enemy_spawner_resource:
			enemy_names[spawner.enemy_res_name] = true
	for enemy_name in enemy_names:
		var resource = load("res://Unit/enemy/resources/" + enemy_name + ".tres")
		if not check(resource != null, "enemy resource " + enemy_name):
			return
		var enemy = main_scene.unit_system.create_unit(resource, 1)
		level.wave_manager.get_node("%Path3D").add_child(enemy)
		enemy.set_process(false)
		if enemy._ap:
			for animation_name in [enemy.anim_run, enemy.anim_idle, enemy.anim_death]:
				check(animation_name == "" or enemy._ap.has_animation(animation_name), "animation " + enemy_name + ": " + animation_name)
		await process_frame
		var enemy_binding = load("res://Scripts/utils/AssetBindingAudit.gd").inspect_unit(enemy)
		binding_report.append(enemy_binding)
		check(enemy_binding.issues.is_empty(), "enemy bindings " + enemy_name)
		enemy.queue_free()
		await process_frame
	var pending: Array = []
	for skill in level.gdbot.skill_map.values():
		if skill.skill_meta_res.building_res != null:
			pending.append(skill.skill_meta_res.building_res)
	var visited: Dictionary = {}
	while not pending.is_empty():
		var resource = pending.pop_back()
		if visited.has(resource.resource_path):
			continue
		visited[resource.resource_path] = true
		var turret = main_scene.unit_system.create_unit(resource, 0)
		level.turret_manager.add_child(turret)
		turret.set_physics_process(false)
		for skill in turret.skill_map.values():
			if skill.skill_meta_res.building_res != null:
				pending.append(skill.skill_meta_res.building_res)
		await process_frame
		var turret_binding = load("res://Scripts/utils/AssetBindingAudit.gd").inspect_unit(turret)
		binding_report.append(turret_binding)
		check(turret_binding.issues.is_empty(), "turret bindings " + resource.resource_path)
		turret.queue_free()
		await process_frame
	print("RESOURCE_AUDIT_OK: ", enemy_names.size(), " enemy types, ", visited.size(), " building tiers")
