class_name Main extends Node3D



@onready var level_controller: LevelController = $LevelController
@onready var resource_manager: ResourceManager = $ResourceManager
# @onready var audio_manager: AudioManager = $AudioManager
@onready var player_controller: PlayerController
var turret_manager: TurretManager

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





# var input_event_callable_list: Array[Callable] = []

func _ready() -> void:
	SOS.main = self


	# 加载音频资源
	CommonUtil.load_resources_to_container_from_directory("res://Asserts/waves/")



func set_player_controller(controller: PlayerController) -> void:
	player_controller = controller



# func _input(event: InputEvent) -> void:
# 	for input_event_callable in input_event_callable_list:
# 		input_event_callable.call(event)
