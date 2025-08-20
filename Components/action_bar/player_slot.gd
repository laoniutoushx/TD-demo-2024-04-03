extends BaseSlot




# mouse left click handler
func _on_slot_left_clicked(slot: BaseSlot) -> void:


	# 切换当前激活 slot
	self.action_bar.player_bar_comp.cur_active_slot = slot
	print("Player slot clicked %s" % "hahaha")
	# skill indicator show
	var talent: Talent = (self.reference as Talent)
	print(self.reference)
	print(talent)
	print(typeof(talent))

	# 技能禁用状态检测
	# 前置条件检查（魔耗）
	if talent is Talent and talent._is_disabled:
		SOS.main.message_bar.set_message("天赋无法施放")
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





func _on_mouse_exited() -> void:
	super._on_mouse_exited()

func _on_mouse_entered() -> void:
	super._on_mouse_entered()
