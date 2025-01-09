extends Node3D


@onready var status_label: Label = %StatusLabel
@onready var level_label: Label = %LevelLabel

static var is_show := false



func _input(event: InputEvent) -> void:
	if event.is_action_pressed("cycle_debug_menu"):
		is_show = true
		set_physics_process(true)

		if is_show:
			visible = true
			set_physics_process(true)
		else:
			visible = false
			set_physics_process(false)


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	refresh_turret_status()
	if is_show:
		show()
		set_physics_process(true)
	else:
		hide()
		set_physics_process(false)
		

func _physics_process(delta: float) -> void:
	refresh_turret_status()


func refresh_turret_status():
	if owner is Turret:
		# var turret_status_enum_type_str = Turret.TurretState[Turret.TurretState.keys()[(owner as Turret).current_state]]
		var turret_status_enum_type_str = Turret.TurretState.keys()[(owner as Turret).current_state]

		status_label.text = turret_status_enum_type_str		

		var level_comp: LevelComp = CommonUtil.get_component_by_name(owner, "LevelComp")
		level_label.text = "Lv %d EXP %d" % [level_comp.level, int(level_comp.exp)]

