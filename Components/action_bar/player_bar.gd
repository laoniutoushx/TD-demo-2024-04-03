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

	# talent init
	slot_instance.timer = talent.cool_down_timer
	slot_instance.progress_bar.max_value = talent.cooldown

	# if talent status = Cool_Down
	if talent.current_state == talent.TALENT_STATE.Cool_Down:
		slot_instance.progress_bar.value = talent.cool_down_timer.time_left
		slot_instance.progress_bar.visible = true
		slot_instance.set_process(true)

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


	slot.mapping_key = short_cut_text
	slot.short_cut.text = short_cut_text




# 重置 slot 内容
func reset_slot_for_player():
	clear()
	# empty_slot()
	_slot_num = 0
	_slot_fill_num = 0
	setup_for_player()


# 清空 slot
func empty_slot() -> void:
	for slot: BaseSlot in _slots:
		if slot == null:
			printerr("ERROR: slot is null")
			return
		
		# 删除掉 item slot
		slot.custome_init(
			null,
			"",
			BaseSlot.SLOT_TYPE.TALENT, 
			false
		)

		slot.reference = null

		# 清除当前激活槽位
		if cur_active_slot == slot:
			cur_active_slot = null

		_slot_fill_num -= 1



		
		
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
