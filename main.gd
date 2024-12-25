class_name Main extends Node3D



@onready var level_controller: LevelController = $LevelController
@onready var resource_manager: ResourceManager = $ResourceManager
@onready var player_controller: PlayerController = $PlayerController

# message bar
@onready var message_bar: Control = $MessageBar



@onready var vfx_system: VFXSystem = %VfxSystem
@onready var barrage_system: BarrageSystem = %BarrageSystem
@onready var damage_system: DamageSystem = %DamageSystem
@onready var unit_system: UnitSystem = %UnitSystem
@onready var skill_system: SkillSystem = %SkillSystem

var input_event_callable_list: Array[Callable] = []

func _ready() -> void:
	SOS.main = self
	pass

func _input(event: InputEvent) -> void:
	for input_event_callable in input_event_callable_list:
		input_event_callable.call(event)