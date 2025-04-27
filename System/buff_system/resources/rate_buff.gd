extends Buff

var timer: Timer

func _ready() -> void:
	super._ready()

	unit.logical_death.connect(_on_unit_logic_death)
	
	# Create and configure a timer to execute a task every second
	timer = Timer.new()
	timer.wait_time = 1.0  # 1 second
	timer.autostart = true
	timer.one_shot = false
	add_child(timer)

	timer.timeout.connect(_on_timer_timeout)

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
		# if CommonUtil.is_flag_set(BuffResource.BUFF_TYPE.BUFF, type):
		unit.health += unit.health * value / 100 * value_dir
		# if CommonUtil.is_flag_set(BuffResource.BUFF_TYPE.DEBUFF, type):
		# ref_val -= ref_val * value / 100 * value_dir

	elif value_unit == BuffResource.VALUE_UNIT.VALUE:
		# if CommonUtil.is_flag_set(BuffResource.BUFF_TYPE.BUFF, type):
		unit.health += value * value_dir
		# if CommonUtil.is_flag_set(BuffResource.BUFF_TYPE.DEBUFF, type):
		# ref_val -= value * value_dir
