extends Control
## One canvas for enemies; weak references never extend a unit's lifetime.
var units: Dictionary = {}

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_to_group("screen_health_bars")

func register_unit(unit: BaseUnit) -> void:
	units[unit.get_instance_id()] = {"unit": weakref(unit), "trail": 1.0}

func _process(delta: float) -> void:
	for id in units.keys():
		var unit = units[id].unit.get_ref()
		if not is_instance_valid(unit) or not unit.is_alive() or not unit.is_inside_tree():
			units.erase(id)
			continue
		var ratio := clampf(unit.health / maxf(unit.max_health, 0.001), 0.0, 1.0)
		units[id].trail = move_toward(units[id].trail, ratio, delta * 0.7)
	queue_redraw()

func _draw() -> void:
	var camera := get_viewport().get_camera_3d()
	if camera == null: return
	for data in units.values():
		var unit = data.unit.get_ref()
		if not is_instance_valid(unit) or not unit.is_alive(): continue
		if unit.health >= unit.max_health and not PlayerController.PlayerSelect.contains_unit(unit): continue
		var point: Vector3 = unit.global_position + Vector3.UP * (unit._height + 0.25)
		if not unit.health_anchor_path.is_empty():
			var anchor = unit.get_node_or_null(unit.health_anchor_path)
			if anchor is Node3D: point = anchor.global_position
		if camera.is_position_behind(point): continue
		var screen := camera.unproject_position(point)
		if not get_viewport_rect().grow(50).has_point(screen): continue
		var ratio := clampf(unit.health / maxf(unit.max_health, 0.001), 0.0, 1.0)
		var rect := Rect2(screen - Vector2(24, 4), Vector2(48, 7))
		draw_rect(rect.grow(1), Color("17251c"))
		draw_rect(Rect2(rect.position, Vector2(48 * data.trail, 7)), Color("ab7848"))
		draw_rect(Rect2(rect.position, Vector2(48 * ratio, 7)), Color("8ac279"))
