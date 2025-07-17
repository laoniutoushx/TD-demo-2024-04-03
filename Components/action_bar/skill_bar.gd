class_name SkillBarComponent extends ActionBar.BaseBarComponent


var cur_active_slot: BaseSlot	

# 装配 skill 时，需要检查 skill 状态，当 skill 处于 release 状态时，需要处理 progress_bar  等信息
func setup_for_unit(unit_map: Dictionary):
	var unit: BaseUnit = unit_map.values()[0]
	var skill_map: Dictionary = unit.skill_map
	if skill_map != null and skill_map.keys().size() > 0:
		for code in skill_map.keys():
			if _slot_num <= 20:
				var skill: Skill = skill_map[code]
				var _slot = _create_skill_slot(skill)
				skill.slot = _slot
				_bind_mapping_key(_slot, _slot_num)


func _create_skill_slot(skill: Skill) -> BaseSlot:	
	var slot_instance: BaseSlot = super.add_element(skill.id, _skill_bar)
	
	slot_instance.custome_init(
		skill,
		skill.icon_path,
		BaseSlot.SLOT_TYPE.SKILL, 

		# 选中单位所属（玩家） 并且 skill 是否禁用 = false
		skill.unit.player_group == SOS.main.player_controller.get_player_group_idx() 
			and skill._is_disabled == false,
		skill.level
	)
	# click signal listener
	slot_instance.slot_clicked.connect(_on_slot_clicked)


	# slot_state = SLOT_STATE.IN_ACTIVE

	# board effect
	if skill.auto_release:
		slot_instance.boarder_effect.visible = true
		slot_instance.boarder_effect.play("default", 1.0, true)


	# skill init
	slot_instance.timer = skill.cool_down_timer
	slot_instance.progress_bar.max_value = skill.cooldown

	# if skill status = Cool_Down
	if skill.current_state == skill.SKILL_STATE.Cool_Down:
		slot_instance.progress_bar.value = skill.cool_down_timer.time_left
		slot_instance.progress_bar.visible = true
		slot_instance.set_process(true)

	# slot 监听技能禁用信号
	skill.skill_disabled.connect(slot_instance._on_skill_disabled)

	_slot_num += 1

	return slot_instance


# 绑定快捷键
# 按键主动绑定到显示的 slot 上（每次切换 action bar 时动态绑定）
func _bind_mapping_key(slot: BaseSlot, idx: int):
	var short_cut_text = ""
	if idx == 1:
		short_cut_text = "Q"
	elif idx == 2:
		short_cut_text = "W"
	elif idx == 3:
		short_cut_text = "E"
	elif idx == 4:
		short_cut_text = "R"
	elif idx == 5:
		short_cut_text = "T"	

	slot.mapping_key = short_cut_text
	slot.short_cut.text = short_cut_text
	
	
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

	# 技能禁用状态检测
	# 前置条件检查（魔耗）
	if skill._is_disabled:
		SOS.main.message_bar.set_message("技能无法施放，魔法不足")
		# change_state(SKILL_STATE.Idle)
		return


	# Target
	if CommonUtil.is_flag_set(SkillMetaResource.SKILL_RELEASE_TYPE.TARGETED, skill.release_type):
		if CommonUtil.is_flag_set(SkillMetaResource.SKILL_EFFECT_TYPE.BUILDING, skill.effect_type):
			skill.change_state(Skill.SKILL_STATE.Building_Indicate)
		else:
			skill.change_state(Skill.SKILL_STATE.Targeted_Indicate)

	# Range 
	if CommonUtil.is_flag_set(SkillMetaResource.SKILL_RELEASE_TYPE.CIRCLE_RANGE, skill.release_type):
		skill.change_state(Skill.SKILL_STATE.Circle_Range_Indicate)

	# Self Cast | No Target
	if (CommonUtil.is_flag_set(SkillMetaResource.SKILL_RELEASE_TYPE.SELF_CAST, skill.release_type)
		or CommonUtil.is_flag_set(SkillMetaResource.SKILL_RELEASE_TYPE.NO_TARGET, skill.release_type)
		):
		skill.change_state(Skill.SKILL_STATE.Release)



