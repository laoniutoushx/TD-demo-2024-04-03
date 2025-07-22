extends Buff

var timer: Timer

func _ready() -> void:
	super._ready()

	unit.logical_death.connect(_on_unit_logic_death)
	
	# Create and configure a timer to execute a task every second
	timer = Timer.new()
	if reference_instance is Skill:
		timer.wait_time = reference_instance.internal_time  # 1 second
	else:
		timer.wait_time = 1.0  # Default to 1 second if not a

	timer.autostart = true
	timer.one_shot = false
	add_child(timer)

	timer.timeout.connect(_on_timer_timeout)


func refresh() -> void:
	super.refresh()


# Called when the timer times out
func _on_timer_timeout() -> void:
	# Get the owning unit and call the rate buff tick function
	_on_rate_buff_ticked(unit)

# Monitor unit death events
func _on_unit_logic_death(id:int, _unit :BaseUnit) -> void:
	if id == unit.get_instance_id():
		queue_free()

func _on_rate_buff_ticked(unit: BaseUnit):
	var prop_val = unit.get(prop)

	if value_unit == BuffResource.VALUE_UNIT.PERCENT:
		if prop == 'health_recove_rate_factor':
			var health = unit.health + unit.health * value / 100 * _value_dir
			unit.health = min(health, unit.max_health)
		else:
			var mana = unit.mana + unit.mana * value / 100 * _value_dir
			unit.mana = min(mana, unit.max_mana)


	elif value_unit == BuffResource.VALUE_UNIT.VALUE:
		if prop == 'health_recove_rate_factor':
			var health = unit.health + value * _value_dir
			unit.health = min(health, unit.max_health) 
		else:
			var mana = unit.mana + value * _value_dir
			unit.mana = min(mana, unit.max_mana)



