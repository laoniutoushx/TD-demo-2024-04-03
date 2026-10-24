extends Control
var original_config: Dictionary

@onready var bg_volum: HSlider = %BgVolum
@onready var sound_volum: HSlider = %SoundVolum
@onready var lang_opt: OptionButton = %LangOpt
@onready var gra_opt: OptionButton = %GraOpt
@onready var apply: Button = %Apply
@onready var rt: Button = %Return

func _ready() -> void:
	original_config = SOS.main.config.duplicate(true)
	bg_volum.set_value_no_signal(SOS.main.config["bg_volume"] * 100.0)
	sound_volum.set_value_no_signal(SOS.main.config["sound_volume"] * 100.0)
	lang_opt.select(1 if SOS.main.config["language"] == "en" else 0)
	gra_opt.select(["low", "medium", "high"].find(SOS.main.config["graphics_quality"]))
	lang_opt.disabled = true
	gra_opt.disabled = false
	lang_opt.tooltip_text = "暂未提供语言切换"
	gra_opt.tooltip_text = "低：关闭SSAO、辉光和动态GI；中：关闭动态GI与体积雾；高：场景原始效果"
	gra_opt.item_selected.connect(func(index): SOS.main.config.graphics_quality = ["low", "medium", "high"][index]; SOS.main.apply_graphics(SOS.main.level_controller._cur_scene))
	$CanvasLayer.visible = true

func _on_return_pressed() -> void:
	SOS.main.config = original_config.duplicate(true)
	SOS.main.apply_audio_settings()
	SOS.main.apply_graphics(SOS.main.level_controller._cur_scene)
	queue_free()

func _on_apply_pressed() -> void:
	SOS.main.save_config()
	queue_free()

func _on_sound_volum_value_changed(value: float) -> void:
	SOS.main.config["sound_volume"] = clampf(value / 100.0, 0.0, 1.0)
	SOS.main.apply_audio_settings()

func _on_bg_volum_value_changed(value: float) -> void:
	var volume = clampf(value / 100.0, 0.0, 1.0)
	SOS.main.config["bg_volume"] = volume
	SignalBus.bgm_volume_changed.emit(volume)

func toggle() -> void:
	_on_return_pressed()
