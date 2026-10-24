extends RefCounted

static func inspect_unit(unit: BaseUnit) -> Dictionary:
	var report := {"resource": unit.clazz.resource_path if unit.clazz else "", "scene": unit.scene_file_path, "animation_player": "", "animation_tree": "", "issues": [], "fire_points": []}
	if is_instance_valid(unit._ap):
		report.animation_player = str(unit.get_path_to(unit._ap))
	if is_instance_valid(unit._at): report.animation_tree = str(unit.get_path_to(unit._at))
	if unit is Enemy:
		for name in [unit.anim_idle, unit.anim_run, unit.anim_death]:
			if name != "" and (unit._ap == null or not unit._ap.has_animation(name)):
				report.issues.append("Missing animation: " + name)
	for pair in [[unit.animation_player_path, "AnimationPlayer"], [unit.animation_tree_path, "AnimationTree"], [unit.health_anchor_path, "Node3D"]]:
		if not pair[0].is_empty():
			var node = unit.get_node_or_null(pair[0])
			if node == null or not node.is_class(pair[1]): report.issues.append("Invalid explicit binding: " + str(pair[0]))
	if unit is Turret:
		if not is_instance_valid(unit.turret_top): report.issues.append("Missing turret pivot")
		for marker in unit.fire_poses:
			var point := {"path": str(unit.get_path_to(marker)), "group": marker.fire_group, "animation": str(marker.fire_animation), "projectile": ""}
			if marker.fire_projectile != null: point.projectile = marker.fire_projectile.resource_path
			else: report.issues.append("Missing projectile: " + point.path)
			if is_instance_valid(marker.ap) and marker.fire_animation != "" and not marker.ap.has_animation(marker.fire_animation):
				report.issues.append("Missing fire animation: " + point.path)
			if marker.has_meta("invalid_animation_tracks"):
				report.issues.append_array(marker.get_meta("invalid_animation_tracks"))
			report.fire_points.append(point)
	return report
