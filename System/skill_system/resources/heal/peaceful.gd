class_name Peaceful extends Node3D
# 白风


var skill: Skill 
var source_unit: BaseUnit 
var target_position: Vector3 


var affected_units: Dictionary = {}  # 受影响的单位列表


func action(skill_context: SkillContext) -> void:
	# 播放施法动画 & 声音
	skill = skill_context.skill
	source_unit = skill_context.source
	target_position = skill_context.target_position
	

	# 创建 vfx
	var vfx = SystemUtil.vfx_system.create_vfx("peaceful", SystemUtil.vfx_system.VFX_TYPE.BURNING)
	source_unit.add_child(vfx)


	# 临时创建一个 Area 实例
	var area_tscn: PackedScene = load("res://Components/area/area.tscn")
	var area_inst: Area = area_tscn.instantiate().duplicate()

	area_inst.init(skill.range)
	source_unit.add_child(area_inst)

	area_inst.area_entered.connect(_on_area_3d_area_entered.bind(skill_context))
	area_inst.area_exited.connect(_on_area_3d_area_exited.bind(skill_context))

	# 此处监听 技能释放完毕信号，在此处执行所有释放操作
	skill.skill_cast_end.connect(_on_skill_cast_end.bind(area_inst, vfx), CONNECT_ONE_SHOT)




func _on_skill_cast_end(_skill_context: SkillContext, _area_inst, _vfx):
	var _su = _skill_context.source
	var _sk = _skill_context.skill
	if _area_inst and is_instance_valid(_area_inst):
		_area_inst.area_entered.disconnect(_on_area_3d_area_entered)
		_area_inst.area_exited.disconnect(_on_area_3d_area_exited)
		_area_inst.queue_free()
	if _vfx and is_instance_valid(_vfx):		
		_vfx.queue_free()

	# 自释放
	_sk.skill_cast_end.disconnect(_on_skill_cast_end)

	# 删除所有单位 buff 
	for _au in affected_units.values():
		if _au and is_instance_valid(_au):
			for unit_buff: Buff in _au.buff_map.values():
				for skill_buff: Buff in _sk.buff_map.values():
					if unit_buff.code == skill_buff.code:
						SystemUtil.buff_system.remove(unit_buff, _au)

	# for unit_buff: Buff in _su.buff_map.values():
	# 	for skill_buff: Buff in _sk.buff_map.values():
	# 		if unit_buff.code == skill_buff.code:
	# 			SystemUtil.buff_system.remove(unit_buff, _su)

	





func _on_area_3d_area_entered(area: Area3D, skill_context):
	var skill: Skill = skill_context.skill
	var target_unit: BaseUnit = area.owner

	# print("---------- %s" % target_unit.title)
	# print("---------- %s, skill state %s, skill buff_map state %s, " % [skill.title, is_instance_valid(skill), is_instance_valid(skill.buff_map.values())])
	# print("%s---------- %s" % [str((area.owner as BaseUnit).player_group), str(SOS.main.player_controller.player_group_idx)])

	if target_unit and target_unit.is_alive() and target_unit.player_group != SOS.main.player_controller.player_group_idx:

		affected_units[target_unit.get_instance_id()] = target_unit

		target_unit.logical_death.connect(_on_target_unit_logical_death, CONNECT_ONE_SHOT)

		for buff: Buff in skill.buff_map.values():
			buff.value = skill.value
			# print("---------- %s, buff state %s" % [skill.title, is_instance_valid(buff)])
			SystemUtil.buff_system.apply(buff, skill, target_unit)
			




func _on_area_3d_area_exited(area: Area3D, skill_context):
	var skill: Skill = skill_context.skill
	var target_unit: BaseUnit = area.owner

	if target_unit and target_unit.is_alive() and target_unit.player_group != SOS.main.player_controller.player_group_idx:

		affected_units.erase(target_unit.get_instance_id())

		for unit_buff: Buff in target_unit.buff_map.values():
			# if unit_buff.code in skill.buff_map.keys():
			# 	SystemUtil.buff_system.remove(unit_buff, target_unit)

			for skill_buff: Buff in skill.buff_map.values():
				if unit_buff.code == skill_buff.code:
					SystemUtil.buff_system.remove(unit_buff, target_unit)



func _on_target_unit_logical_death(unit: BaseUnit) -> void:
	affected_units.erase(unit.get_instance_id())
