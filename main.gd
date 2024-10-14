class_name Main extends Node3D



@onready var level_controller: LevelController = $LevelController
@onready var resource_manager: ResourceManager = $ResourceManager
@onready var player_controller: PlayerController = $PlayerController



@onready var vfx_system: VFXSystem = %VfxSystem
@onready var barrage_system: BarrageSystem = %BarrageSystem
@onready var damage_system: DamageSystem = %DamageSystem
@onready var unit_system: UnitSystem = %UnitSystem
@onready var skill_system: SkillSystem = %SkillSystem


func _ready() -> void:
	SOS.main = self
	pass
