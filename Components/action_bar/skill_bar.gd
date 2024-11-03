class_name SkillBarComponent extends ActionBar.BaseBarComponent


var cur_active_slot: BaseSlot	
	
func setup_for_unit(unit_map: Dictionary):
	var unit: BaseUnit = unit_map.values()[0]
	var skill_map: Dictionary = unit.skill_map
	if skill_map != null and skill_map.keys().size() > 0:
		for code in skill_map.keys():
			if _slot_num <= 5:
				var skill: Skill = skill_map[code]
				_create_slot(skill)

func _create_slot(skill: Skill) -> BaseSlot:	
	var slot_instance: BaseSlot = super.add_element(skill.id, _skill_bar)
	
	slot_instance.init(
		skill,
		skill.icon_path,
		BaseSlot.SLOT_TYPE.SKILL, 
		skill.unit.player_group == SOS.main.player_controller.get_player_group_idx()
	)
	# click signal listener
	slot_instance.slot_clicked.connect(_on_slot_clicked)
	_slot_num += 1

	return slot_instance
	
	
func remove_element(ele: Variant):
	ele = (ele as Skill)
	if _skill_bar.has_node(ele.id):
		var _s: BaseSlot = _skill_bar.get_node(ele.id)
		_action_bar.deregister_active(_s.active_callback)
		_s.queue_free()
		_slot_num -= 1
		
		
func clear():
	for child: BaseSlot in _skill_bar.get_children():
		_action_bar.deregister_active(child.active_callback)
		child.queue_free()
	_slot_num = 0


func _on_slot_clicked(slot: BaseSlot):
	cur_active_slot = slot
	print("slot cliecked %s" % "hahaha")
	# skill indicator show
	var skill: Skill = (slot.reference as Skill)

	skill.change_state(Skill.SKILL_STATE.Indicate)

	# SOS.main.player_controller.player_skill_scope_indicator.show_indicator()
	
	
