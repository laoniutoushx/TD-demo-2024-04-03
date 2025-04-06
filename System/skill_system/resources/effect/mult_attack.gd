class_name MultAttack extends Node3D

var skill: Skill 
var source_unit: BaseUnit 
var target_position: Vector3 


func action(skill_context: SkillContext) -> void:
	# 播放施法动画 & 声音
	skill = skill_context.skill
	source_unit = skill_context.source
	target_position = skill_context.target_position
	

	# stun buff
	if source_unit.is_alive():
		for buff: Buff in skill.buff_map.values():
			buff.value = skill.value
			# print("---------- %s, buff state %s" % [skill.title, is_instance_valid(buff)])
			SystemUtil.buff_system.apply(buff, source_unit)





