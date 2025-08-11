class_name TalentSystem extends Node3D



func _ready() -> void:
	SystemUtil.talent_system = self
	# 在系统启动时，初始化所有 item template resource，将起保存在 container 当中
	CommonUtil.load_resources_to_container_from_directory("res://System/talent_system/resources/")





# 实例化 技能
# func initialize_talent(source_unit: BaseUnit, talent_metas: Array[TalentResource]) -> Dictionary:
# 	var talent_map: Dictionary = {}
# 	for idx in range(talent_metas.size()):
# 		var talent: Talent = _initialize_talent(source_unit, talent_metas[idx], idx)

# 		if talent != null:
# 			# 初始化 buff
# 			# SystemUtil.buff_system.init_buff_for_unit_by_res(source_unit, talent.talent_res, talent)

# 			talent.unit = source_unit
# 			talent_map[talent.code] = talent  

# 			# add to unit tree
# 			talent.name = talent.code
# 			source_unit.add_child(talent)
# 			talent.add_child(talent.talent_script_instance)

# 	return talent_map
	
# # 实例化
# func _initialize_talent(source_unit: BaseUnit, talent_meta_res: TalentResource, idx: int = 0) -> Talent:
# 	if talent_meta_res != null:
# 		var talent: Talent = Talent.new()
# 		talent.unit = source_unit
# 		CommonUtil.bean_properties_copy(talent_meta_res, talent)
# 		# 手动赋值 skill_script
# 		talent.talent_script = talent_meta_res.item_script
# 		talent.talent_res = talent_meta_res
# 		if talent.code == null:
# 			printerr("ERROR: talent code not define")
			
# 		# skill id
# 		talent.id = UUID.v4()

# 		# 实例化技能脚本
# 		# assert(skill.skill_script != null, "skill script not define")
# 		if talent.talent_script != null:
# 			talent.talent_script_instance = talent.talent_script.new()
# 		else:
# 			printerr("ERROR: talent script not define")

# 		return talent
	
# 	return null