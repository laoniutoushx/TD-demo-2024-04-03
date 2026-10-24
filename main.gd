class_name Main extends Node3D



@onready var level_controller: LevelController = $LevelController
@onready var resource_manager: ResourceManager = $ResourceManager
# @onready var audio_manager: AudioManager = $AudioManager
@onready var player_controller: PlayerController
var turret_manager: TurretManager

# Additional gameplay systems can opt into the same session teardown contract.
var session_modules: Array[Node] = []

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
	for module in [vfx_system, barrage_system, damage_system, skill_system, item_system, talent_system, buff_system, floating_text_system]:
		register_session_module(module)


	# 加载音频资源
	CommonUtil.load_resources_to_container_from_directory("res://Asserts/waves/")



func set_player_controller(controller: PlayerController) -> void:
	player_controller = controller



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
	for module in session_modules.duplicate():
		if is_instance_valid(module):
			module.reset_session()
		else:
			session_modules.erase(module)
	for indicator in [building_key_indicator, skill_slot_indicator, unit_slot_indicator, item_slot_indicator]:
		indicator.hide()
		indicator.set_process(false)
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	Input.set_custom_mouse_cursor(null)
