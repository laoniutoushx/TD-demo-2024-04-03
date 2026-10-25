extends RefCounted
## UI clicks and edge scrolling deliberately have different policies.
static func interaction_available(viewport: Viewport) -> bool:
	return interaction_block_reason(viewport).is_empty()

static func interaction_block_reason(viewport: Viewport) -> String:
	if viewport.get_tree().paused: return "paused"
	if is_instance_valid(SOS.main):
		if is_instance_valid(SOS.main.cursor_policy):
			var reason: String = SOS.main.cursor_policy.input_block_reason()
			if not reason.is_empty(): return reason
		var controller = SOS.main.level_controller
		if is_instance_valid(controller):
			if controller._transitioning: return "scene_transition"
			if controller._battle_finished: return "battle_finished"
			if is_instance_valid(controller._settings): return "settings"
		var player = SOS.main.player_controller
		if is_instance_valid(player) and player.player_status == PlayerController.PLAYER_STATUS.CHOOSING_TALENT: return "talent_modal"
	return ""

static func over_blocking_ui(viewport: Viewport, point: Vector2) -> bool:
	# Use this event's position, not the previous GUI hover result.
	for control in viewport.get_tree().get_nodes_in_group("blocks_world_input"):
		if not control is Control or control.get_viewport() != viewport or not control.is_visible_in_tree(): continue
		var local: Vector2 = control.get_global_transform_with_canvas().affine_inverse() * point
		if Rect2(Vector2.ZERO, control.size).has_point(local): return true
	return false

static func pointer_available(viewport: Viewport, event_position := Vector2.INF) -> bool:
	var point: Vector2 = viewport.get_mouse_position() if event_position == Vector2.INF else event_position
	return interaction_available(viewport) and viewport.get_visible_rect().has_point(point) and not over_blocking_ui(viewport, point)

static func edge_scroll_available(viewport: Viewport, point: Vector2) -> bool:
	return edge_scroll_block_reason(viewport, point).is_empty()

static func edge_scroll_block_reason(viewport: Viewport, point: Vector2) -> String:
	var reason := interaction_block_reason(viewport)
	if not reason.is_empty(): return reason
	if not point.is_finite() or not viewport.get_visible_rect().has_point(point): return "outside_viewport"
	if viewport.gui_is_dragging(): return "gui_drag"
	return ""

static func cursor_confined() -> bool:
	return is_instance_valid(SOS.main) and is_instance_valid(SOS.main.cursor_policy) and SOS.main.cursor_policy.is_confined()

static func request_cursor_hidden(owner: Object, hidden: bool) -> void:
	if is_instance_valid(SOS.main) and is_instance_valid(SOS.main.cursor_policy):
		SOS.main.cursor_policy.request_hidden(owner, hidden)
