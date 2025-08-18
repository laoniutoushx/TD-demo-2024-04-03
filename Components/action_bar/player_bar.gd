class_name PlayerBarComponent extends ActionBar.BaseBarComponent


var cur_active_slot: BaseSlot	



# 装配 skill 时，需要检查 skill 状态，当 skill 处于 release 状态时，需要处理 progress_bar  等信息
func setup_for_player():
	var player_talent_map: Dictionary = SOS.main.player_controller.player_talent_map



	if player_talent_map != null and player_talent_map.keys().size() > 0:
		for code in player_talent_map.keys():
			if _slot_num < 1:	# 0,1,2 三个槽位
				var talent: Talent = player_talent_map[code]
				var _slot = _create_talent_slot(talent)
				talent.slot = _slot
				_bind_mapping_key(_slot, _slot_num)



	# 如果 _slot_num < 3 ，剩余槽位创建 item_slot_empty 占位槽，保持 UI 布局一致
	while _slot_num < 1:
		var _slot = super.add_element(UUID.v4(), _player_bar, func(a1, a2): pass, _action_bar.player_slot_empty)
		_slot_num += 1
	pass




func reset_slot_for_player():
	clear()
	_slot_num = 0
	_slot_fill_num = 0
	setup_for_player()




func _create_talent_slot(talent: Talent) -> BaseSlot:	
	var slot_instance: BaseSlot = super.add_element(talent.id, _player_bar, func(a1, a2): pass, _action_bar.player_slot)
	
	slot_instance.custome_init(
		talent,
		talent.icon_path,
		BaseSlot.SLOT_TYPE.TALENT, 
		true
	)
	# click signal listener
	slot_instance.slot_clicked.connect(_on_slot_clicked)


	# slot_state = SLOT_STATE.IN_ACTIVE

	# skill init
	slot_instance.timer = talent.cool_down_timer
	slot_instance.progress_bar.max_value = talent.cooldown

	# # if skill status = Cool_Down
	# if skill.current_state == skill.SKILL_STATE.Cool_Down:
	# 	slot_instance.progress_bar.value = skill.cool_down_timer.time_left
	# 	slot_instance.progress_bar.visible = true
	# 	slot_instance.set_process(true)

	_slot_num += 1
	if slot_instance.reference:
		_slot_fill_num += 1	

	return slot_instance

# 绑定快捷键
# 按键主动绑定到显示的 slot 上（每次切换 action bar 时动态绑定）
func _bind_mapping_key(slot: BaseSlot, idx: int):
	if slot.short_cut == null:
		return

	var short_cut_text = ""
	if idx == 1:
		short_cut_text = "Z"
	elif idx == 2:
		short_cut_text = "2"
	elif idx == 3:
		short_cut_text = "3"
	elif idx == 4:
		short_cut_text = "4"
	elif idx == 5:
		short_cut_text = "5"	

	slot.mapping_key = short_cut_text
	slot.short_cut.text = short_cut_text


# func add_element(ele: Variant):
# 	ele = (ele as Item)
# 	if not _player_bar.has_node(ele.id):
# 		var _s: BaseSlot = _create_item_slot(ele)
# 		_action_bar.register_active(_s.active_callback)
# 		_player_bar.add_child(_s)
# 	else:
# 		printerr("ERROR: item slot already exists for %s" % ele.id)
# 		return
	
# 	# cur_active_slot = _s
# 	print("slot added %s" % ele.id)


		
		
func clear():
	_slots = []
	for child in _player_bar.get_children():
		if child is BaseSlot:
			_action_bar.deregister_active(child.active_callback)

		child.queue_free()
	_slot_num = 0
	_slot_fill_num = 0




func _on_slot_clicked(slot: BaseSlot):
	cur_active_slot = slot
	print("slot cliecked %s" % "hahaha")
	# skill indicator show
	var talent: Talent = (slot.reference as Talent)

	# 技能禁用状态检测
	# 前置条件检查（魔耗）
	if talent._is_disabled:
		SOS.main.message_bar.set_message("技能无法施放，魔法不足")
		# change_state(SKILL_STATE.Idle)
		return


	# Target
	if CommonUtil.is_flag_set(TalentResource.TALENT_RELEASE_TYPE.TARGETED, talent.release_type):
		if CommonUtil.is_flag_set(TalentResource.TALENT_EFFECT_TYPE.BUILDING, talent.effect_type):
			talent.change_state(Talent.TALENT_STATE.Building_Indicate)
		else:
			talent.change_state(Talent.TALENT_STATE.Targeted_Indicate)

	# Range 
	if CommonUtil.is_flag_set(TalentResource.TALENT_RELEASE_TYPE.CIRCLE_RANGE, talent.release_type):
		talent.change_state(Talent.TALENT_STATE.Circle_Range_Indicate)

	# Self Cast | No Target
	if (CommonUtil.is_flag_set(TalentResource.TALENT_RELEASE_TYPE.SELF_CAST, talent.release_type)
		or CommonUtil.is_flag_set(TalentResource.TALENT_RELEASE_TYPE.NO_TARGET, talent.release_type)
		):
		talent.change_state(Talent.TALENT_STATE.Release)
