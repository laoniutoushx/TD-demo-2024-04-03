extends RefCounted
## UI clicks and edge scrolling deliberately have different policies.
static func interaction_available(viewport: Viewport) -> bool:
	if viewport.get_tree().paused: return false
	if is_instance_valid(SOS.main):
		if is_instance_valid(SOS.main.cursor_policy) and SOS.main.cursor_policy.world_input_blocked(): return false
		var controller = SOS.main.level_controller
		if is_instance_valid(controller):
			if controller._transitioning or controller._battle_finished or is_instance_valid(controller._settings): return false
		var player = SOS.main.player_controller
		if is_instance_valid(player) and player.player_status == PlayerController.PLAYER_STATUS.CHOOSING_TALENT: return false
	return true

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
	return interaction_available(viewport) and viewport.get_visible_rect().has_point(point) and not viewport.gui_is_dragging()

static func cursor_confined() -> bool:
	return is_instance_valid(SOS.main) and is_instance_valid(SOS.main.cursor_policy) and SOS.main.cursor_policy.is_confined()

static func request_cursor_hidden(owner: Object, hidden: bool) -> void:
	if is_instance_valid(SOS.main) and is_instance_valid(SOS.main.cursor_policy):
		SOS.main.cursor_policy.request_hidden(owner, hidden)
