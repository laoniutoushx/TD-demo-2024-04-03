class_name PlayerBarComponent extends ActionBar.BaseBarComponent


var cur_active_slot: BaseSlot	



# 装配 skill 时，需要检查 skill 状态，当 skill 处于 release 状态时，需要处理 progress_bar  等信息
func setup_for_player():
	# var unit: BaseUnit = unit_map.values()[0]
	# var item_map: Dictionary = unit.item_map
	# if item_map != null and item_map.keys().size() > 0:
	# 	for code in item_map.keys():
	# 		if _slot_num < 3:	# 0,1,2 三个槽位
	# 			var item: Item = item_map[code]
	# 			var _slot = _create_item_slot(item)
	# 			item.slot = _slot
	# 			_bind_mapping_key(_slot, _slot_num)

	# # 如果 _slot_num < 3 ，剩余槽位创建 item_slot_empty 占位槽，保持 UI 布局一致
	# while _slot_num < 1:
	# 	var _slot = super.add_element(UUID.v4(), _player_bar, func(a1, a2): pass, _action_bar.item_slot_empty)
	# 	_slot_num += 1
	pass




func _create_item_slot(item: Item) -> BaseSlot:	
	var slot_instance: BaseSlot = super.add_element(item.id, _player_bar, func(a1, a2): pass, _action_bar.item_slot)
	
	slot_instance.custome_init(
		item,
		item.icon_path,
		BaseSlot.SLOT_TYPE.ITEM, 
		item.unit.player_group == SOS.main.player_controller.get_player_group_idx()
	)
	# click signal listener
	slot_instance.slot_clicked.connect(_on_slot_clicked)


	# slot_state = SLOT_STATE.IN_ACTIVE

	# skill init
	slot_instance.timer = item.cool_down_timer
	slot_instance.progress_bar.max_value = item.cooldown

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
		short_cut_text = "1"
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



func pick_up(item: Item) -> void:
	if item == null:
		printerr("ERROR: item is null")
		return

	if _slot_fill_num >= 3:
		printerr("ERROR: item bar is full, cannot add more items")
		return
	
	# 取出一个槽，放入元素
	for slot in _slots:
		if slot.reference == null:  # 找到一个空槽位
			# 找到一个空槽位
			slot.custome_init(
						item,
						item.icon_path,
						BaseSlot.SLOT_TYPE.ITEM, 
						true
					)
			_slot_fill_num += 1
			break


func drop_item(slot: BaseSlot) -> void:
	if slot == null:
		printerr("ERROR: item is null")
		return
	
	# 删除掉 item slot
	slot.custome_init(
		null,
		"",
		BaseSlot.SLOT_TYPE.ITEM, 
		false
	)

	slot.reference = null

	# 清除当前激活槽位
	if cur_active_slot == slot:
		cur_active_slot = null

	_slot_fill_num -= 1

	
func remove_element(ele: Variant):
	ele = (ele as Item)
	if _player_bar.has_node(ele.id):
		var _s: BaseSlot = _player_bar.get_node(ele.id)
		_action_bar.deregister_active(_s.active_callback)
		_s.queue_free()
		_slot_num -= 1
		# 不是空槽位
		if _s.reference:
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
	# var skill: Skill = (slot.reference as Skill)


	# if CommonUtil.is_flag_set(SkillMetaResource.SKILL_RELEASE_TYPE.TARGETED, skill.release_type):
	# 	if CommonUtil.is_flag_set(SkillMetaResource.SKILL_EFFECT_TYPE.BUILDING, skill.effect_type):
	# 		skill.change_state(Skill.SKILL_STATE.Building_Indicate)
	# 	else:
	# 		skill.change_state(Skill.SKILL_STATE.Targeted_Indicate)

	# if CommonUtil.is_flag_set(SkillMetaResource.SKILL_RELEASE_TYPE.CIRCLE_RANGE, skill.release_type):
	# 	skill.change_state(Skill.SKILL_STATE.Circle_Range_Indicate)


	
	
