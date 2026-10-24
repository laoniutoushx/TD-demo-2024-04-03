extends Control

func setup(is_win: bool) -> void:
	var stats = SOS.main.level_controller.result
	%VictoryLabel.visible = is_win
	%FailedLabel.visible = not is_win
	%WaveLabel.text = "完成波次：%d/%d" % [stats.get("wave", 0), stats.get("waves", 0)]
	%DefeatLabel.text = "消灭敌人：%d" % stats.get("defeated", 0)
	%ResLabel.text = "获取资源：%d/%d" % [stats.get("money", 0), stats.get("wood", 0)]
	%ScoreLabel.text = "最终得分：%d" % stats.get("score", 0)

func _on_restart_pressed() -> void:
	SOS.main.level_controller.return_to_menu("level1")

func _on_setting_pressed() -> void:
	SOS.main.level_controller.open_settings()

func _on_menu_pressed() -> void:
	SOS.main.level_controller.return_to_menu()
