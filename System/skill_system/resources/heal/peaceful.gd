class_name Peaceful extends Node3D
# 白风


var skill: Skill 
var source_unit: BaseUnit 
var target_position: Vector3 


func action(skill_context: SkillContext) -> void:
	# 播放施法动画 & 声音
	skill = skill_context.skill
	source_unit = skill_context.source
	target_position = skill_context.target_position
	


	# 临时创建一个 Area 实例
	var area_tscn: PackedScene = load("res://Components/area/area.tscn")
	var area_inst: Area = area_tscn.instantiate().duplicate()

	area_inst.init(skill.range)
	source_unit.add_child(area_inst)

	area_inst.area_entered.connect(_on_area_3d_area_entered.bind(skill_context))
	area_inst.area_exited.connect(_on_area_3d_area_exited.bind(skill_context))

	# 此处监听 技能释放完毕信号，在此处执行所有释放操作




# 单位进入技能释放范围
func _on_area_3d_area_entered(area: Area3D, skill_context: SkillContext):
	for buff: Buff in skill.buff_map.values():
		SystemUtil.buff_system.apply(buff, skill, source_unit)



# 单位离开技能释放范围
func _on_area_3d_area_exited(area: Area3D, skill_context: SkillContext):
	for buff: Buff in skill.buff_map.values():
		SystemUtil.buff_system.remove(buff, source_unit)



