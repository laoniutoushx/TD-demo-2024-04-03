class_name Main extends Node3D



@onready var level_controller: LevelController = $LevelController
@onready var resource_manager: ResourceManager = $ResourceManager
@onready var player_controller: PlayerController = $PlayerController
var turret_manager: TurretManager

# UI
@onready var message_bar: Control = $UI/MessageBar
@onready var building_key_indicator: Control = $UI/BuildingKeyIndicator
@onready var skill_slot_indicator: Control = $UI/SkillSlotIndicator
@onready var unit_slot_indicator: Control = $UI/UnitSlotIndicator
@onready var item_slot_indicator: Control = $UI/ItemSlotIndicator



@onready var vfx_system: VFXSystem = %VfxSystem
@onready var barrage_system: BarrageSystem = %BarrageSystem
@onready var damage_system: DamageSystem = %DamageSystem
@onready var unit_system: UnitSystem = %UnitSystem
@onready var skill_system: SkillSystem = %SkillSystem
@onready var item_system: ItemSystem = %ItemSystem
@onready var buff_system: BuffSystem = %BuffSystem


var input_event_callable_list: Array[Callable] = []

func _ready() -> void:
	SOS.main = self


func _input(event: InputEvent) -> void:
	for input_event_callable in input_event_callable_list:
		input_event_callable.call(event)