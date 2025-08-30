extends Control




# 设置以下节点数据
    # %WaveLabel.text = "完成波次：15/31"
    # %DefeatLabel.text = "消灭敌人：130"
    # %ResLabel.text = "获取资源：1230/32"
    # %ScoreLabel.text = "最终得分：123456"
func setup(is_win: bool) -> void:
    if is_win:
        %VictoryLabel.visible = true
        %FailedLabel.visible = false
    else:
        %VictoryLabel.visible = false
        %FailedLabel.visible = true


    %WaveLabel.text = "完成波次：%d/%d" % [SOS.main.level_controller._pre_scene.wave_manager.cur_wave_index, SOS.main.level_controller._pre_scene.wave_manager.wave_resources.size()]
    %DefeatLabel.text = "消灭敌人：%d" % SOS.main.player_controller.death_unit_num
    %ResLabel.text = "获取资源：%d/%d" % [SOS.main.player_controller.total_money, SOS.main.player_controller.total_wood]
    %ScoreLabel.text = "最终得分：%d" % SOS.main.player_controller.player_score



func _on_restart_pressed() -> void:
    get_tree().paused = true
    SOS.main.level_controller.level_map["game_over"].queue_free()
    SOS.main.level_controller.level_map["level1"].queue_free()
    var index_scene = SOS.main.level_controller.next_level("index")
    get_tree().paused = false



func _on_setting_pressed() -> void:
    SOS.main.level_controller.next_level("setting")
