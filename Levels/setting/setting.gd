extends Control



@onready var bg_volum: HSlider = %BgVolum
@onready var sound_volum: HSlider = %SoundVolum
@onready var lang_opt: OptionButton = %LangOpt
@onready var gra_opt: OptionButton = %GraOpt
@onready var apply: Button = %Apply
@onready var rt: Button = %Return






func _ready() -> void:
	toggle()




func _on_return_pressed() -> void:
	toggle()




func _on_apply_pressed() -> void:
	pass # Replace with function body.




func _on_sound_volum_value_changed(value:float) -> void:
	SOS.main.config["sound_volume"] = value / 5.0



func _on_bg_volum_value_changed(value:float) -> void:
	var bgm_player = CommonUtil.get_first_node_by_node_name(SOS.main.level_controller._cur_scene, "BGMPlayer")
	SOS.main.config["bg_volume"] = value / 5.0
	SignalBus.bgm_volume_changed.emit(value / 5.0)


func toggle() -> void:
	$CanvasLayer.visible = !$CanvasLayer.visible