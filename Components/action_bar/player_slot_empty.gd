extends BaseSlot



# mouse left click handler
func _on_slot_left_clicked(slot: BaseSlot) -> void:

	# 切换玩家状态
	SOS.main.player_controller.player_status = SOS.main.player_controller.PLAYER_STATUS.CHOOSING_TALENT

	# 隐藏其他 UI（UI & ActionBar）
	SOS.main.level_controller._cur_scene.action_bar.ui_toggle()
	SOS.main.level_controller._cur_scene.ui.ui_toggle()


	# show player talent choose ui
	SystemUtil.talent_system.show_player_talent_ui()







func _on_mouse_entered() -> void:
	super._on_mouse_entered()


func _on_mouse_exited() -> void:
	super._on_mouse_exited()

