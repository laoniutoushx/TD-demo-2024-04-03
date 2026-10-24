class_name Main extends Node3D



@onready var level_controller: LevelController = $LevelController
@onready var resource_manager: ResourceManager = $ResourceManager
# @onready var audio_manager: AudioManager = $AudioManager
@onready var player_controller: PlayerController
var turret_manager: TurretManager

# Additional gameplay systems can opt into the same session teardown contract.
var session_modules: Array[Node] = []
var settings_path := "user://demo_settings.cfg"
var _quitting := false
var cursor_policy: Node

# UI
@onready var message_bar: Control = %MessageBar
@onready var building_key_indicator: Control = %BuildingKeyIndicator
@onready var skill_slot_indicator: Control = %SkillSlotIndicator
@onready var unit_slot_indicator: Control = %UnitSlotIndicator
@onready var item_slot_indicator: Control = %ItemSlotIndicator



@onready var vfx_system: VFXSystem = %VfxSystem
@onready var barrage_system: BarrageSystem = %BarrageSystem
@onready var damage_system: DamageSystem = %DamageSystem
@onready var unit_system: UnitSystem = %UnitSystem
@onready var skill_system: SkillSystem = %SkillSystem
@onready var item_system: ItemSystem = %ItemSystem
@onready var talent_system: TalentSystem = %TalentSystem
@onready var buff_system: BuffSystem = %BuffSystem
@onready var floating_text_system: FloatingTextSystem = %FloatingTextSystem

# 高性能概率发生器
@onready var prob: GameProbability = %GameProbability


# 配置信息
@export var config: Dictionary = {
	"bg_volume": 0.5,
	"sound_volume": 0.5,
	"language": "en",
	"graphics_quality": "high"
}


# var input_event_callable_list: Array[Callable] = []

func _ready() -> void:
	SOS.main = self
	cursor_policy = preload("res://Scripts/controller/BattleCursor.gd").new()
	cursor_policy.name = "BattleCursor"
	add_child(cursor_policy)
	register_session_module(cursor_policy)
	get_tree().auto_accept_quit = false
	get_window().close_requested.connect(request_quit)
	load_config()
	for bus_name in ["Music", "SFX"]:
		if AudioServer.get_bus_index(bus_name) < 0:
			AudioServer.add_bus()
			AudioServer.set_bus_name(AudioServer.bus_count - 1, bus_name)
	apply_audio_settings()
	SignalBus.bgm_volume_changed.connect(func(_value): apply_audio_settings())
	for module in [vfx_system, barrage_system, damage_system, skill_system, item_system, talent_system, buff_system, floating_text_system]:
		register_session_module(module)


	# 加载音频资源
	CommonUtil.load_resources_to_container_from_directory("res://Asserts/waves/")



func set_player_controller(controller: PlayerController) -> void:
	player_controller = controller

func _notification(what: int) -> void:
	if what in [NOTIFICATION_PAUSED, NOTIFICATION_UNPAUSED] and is_instance_valid(cursor_policy):
		cursor_policy.sync_mode()

func load_config() -> void:
	var file := ConfigFile.new()
	if file.load(settings_path) != OK: return
	for key in ["bg_volume", "sound_volume"]:
		var value = file.get_value("settings", key, config[key])
		if value is float or value is int: config[key] = clampf(float(value), 0.0, 1.0)
	var quality = file.get_value("settings", "graphics_quality", "high")
	if quality in ["low", "medium", "high"]: config.graphics_quality = quality

func save_config() -> Error:
	var file := ConfigFile.new()
	for key in config: file.set_value("settings", key, config[key])
	return file.save(settings_path)

func request_quit() -> void:
	if _quitting: return
	_quitting = true
	if is_instance_valid(cursor_policy): cursor_policy.sync_mode()
	# Flush session-owned viewports and effects while RenderingServer still exists.
	while level_controller._transitioning: await get_tree().process_frame
	await level_controller.return_to_menu("")
	await get_tree().process_frame
	if DisplayServer.get_name() != "headless": await RenderingServer.frame_post_draw
	get_tree().quit()

func apply_audio_settings() -> void:
	for entry in [["Music", "bg_volume"], ["SFX", "sound_volume"]]:
		var index := AudioServer.get_bus_index(entry[0])
		if index >= 0: AudioServer.set_bus_volume_db(index, linear_to_db(maxf(config[entry[1]], 0.00001)))

func apply_graphics(scene: Node) -> void:
	if not is_instance_valid(scene): return
	for world in scene.find_children("*", "WorldEnvironment", true, false):
		if world.environment == null: continue
		if not world.has_meta("quality_baseline"): world.set_meta("quality_baseline", world.environment)
		var environment: Environment = world.get_meta("quality_baseline").duplicate(true)
		if config.graphics_quality != "high":
			environment.sdfgi_enabled = false
			environment.volumetric_fog_enabled = false
		if config.graphics_quality == "low":
			environment.ssao_enabled = false
			environment.glow_enabled = false
		world.environment = environment



# func _input(event: InputEvent) -> void:
# 	for input_event_callable in input_event_callable_list:
# 		input_event_callable.call(event)

func _exit_tree() -> void:
	if SOS.main == self:
		SOS.main = null
	BaseSlot.action_bar = null
	CommonUtil.ResourceLoaderUtil._directory_cache.clear()
	CommonUtil.ResourceLoaderUtil._common_container.clear()
	ActionBar.icon_res_container.clear()
	ItemSystem.ItemManager._item_res_container.clear()
	ItemSystem.ItemManager._item_domain_container.clear()
	BuffSystem.BuffManager._buff_res_container.clear()
	BuffSystem.BuffManager._buff_domain_container.clear()
	for property in ["vfx_system", "damage_system", "barrage_system", "unit_system", "skill_system", "item_system", "talent_system", "buff_system", "floating_text_system"]:
		SystemUtil.set(property, null)

func register_session_module(module: Node) -> void:
	if module.has_method("reset_session") and not session_modules.has(module):
		session_modules.append(module)

func reset_session_modules() -> void:
	Constants.SELECTION_START = false
	PlayerController.PlayerSelect._selecting = false
	PlayerController.PlayerSelect.clear_unit()
	PlayerController.PlayerSelect.clear_candidate()
	SelectionBox.DoubleCacheSelection.reset()
	for module in session_modules.duplicate():
		if is_instance_valid(module):
			module.reset_session()
		else:
			session_modules.erase(module)
	for indicator in [building_key_indicator, skill_slot_indicator, unit_slot_indicator, item_slot_indicator]:
		indicator.hide()
		indicator.set_process(false)
	Input.set_custom_mouse_cursor(null)
