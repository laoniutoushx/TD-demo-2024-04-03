extends Node


@onready var layer: CanvasLayer = %CanvasLayer
@onready var talent_choose: Control = %TalentChoose



func _ready() -> void:
	# SignalBus.unit_logic_death.connect(_on_enemy_death)
	SignalBus.money_changed.connect(_on_money_changed)
	SignalBus.wood_changed.connect(_on_wood_changed)

	SignalBus.wave_start.connect(_on_wave_start)
	SignalBus.wave_end.connect(_on_wave_end)


	# 初始化
	_on_money_changed(null, SOS.main.player_controller.money)
	_on_wood_changed(null, SOS.main.player_controller.wood)


	reset_wave_tip_pivot_offset_center()

	
	pass


func ui_toggle():
	layer.visible = !layer.visible


func _on_money_changed(enemy: Object, money: int):
	var money_label = %MoneyLabel
	money_label.text = str(money)


func _on_wood_changed(enemy: Object, wood: int):
	var wood_label = %WoodLabel
	wood_label.text = str(wood)
	
 
func _on_wave_start(wave_index: int, wave_resource: WaveResource, wave_resources: Array):
	reset_wave_tip_pivot_offset_center()

	var wave_label = %WaveLabel
	wave_label.text = "Wave: " + str(wave_index + 1) + "/" + str(wave_resources.size())
	
	# var wave_progress = %WaveProgress
	# wave_progress.max_value = base_level.wave_resources.size()
	# wave_progress.value = wave_index + 1

	# 你的代码修改为：
	var wave_tip = %WaveTip
	wave_tip.text = "敌人开始进攻!!!\n-第%s波-" % [CommonUtil.number_to_chinese(wave_index + 1)]
	# wave_tip.text = "第 " + str(wave_index + 1) + " 波怪物正在赶来！"

	# 播放动效
	%AnimationPlayer.play("wave_tip")


func _on_wave_end(wave_index: int, wave_resource: WaveResource, wave_resources: Array):
	reset_wave_tip_pivot_offset_center()

	var wave_label = %WaveLabel
	wave_label.text = "Wave: " + str(wave_index + 1) + "/" + str(wave_resources.size())
	
	# var wave_progress = %WaveProgress
	# wave_progress.max_value = base_level.wave_resources.size()
	# wave_progress.value = wave_index + 1	

	var wave_tip = %WaveTip
	wave_tip.text = "准备防御第 " + str(wave_index + 1) + " 波怪物！"


func reset_wave_tip_pivot_offset_center():
	%WavePanel.pivot_offset = %WavePanel.size / 2 # 设置偏移量（中心位置）	