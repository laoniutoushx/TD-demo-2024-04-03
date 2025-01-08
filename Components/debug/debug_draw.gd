extends Node3D


@onready var status_label: Label = %StatusLabel

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	refresh_turret_status()

func _physics_process(delta: float) -> void:
	refresh_turret_status()


func refresh_turret_status():
	if owner is Turret:
		# var turret_status_enum_type_str = Turret.TurretState[Turret.TurretState.keys()[(owner as Turret).current_state]]
		var turret_status_enum_type_str = Turret.TurretState.keys()[(owner as Turret).current_state]

		status_label.text = turret_status_enum_type_str		