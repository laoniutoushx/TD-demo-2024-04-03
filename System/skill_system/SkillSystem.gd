class_name SkillSystem extends Node


# SkillSystem 说明
# 加载 skill 元数据，实例化 skill
# 获取实例化后 skill 对象
# skill 执行
# 	0. 鼠标等效果处理， 施法效果, UI interactive
#	1. skill 准备( anim/cooldown/vfx/audio )
# 	2. skill 执行（ do action ） ，可包括任何逻辑, take_damage, vfx, other logic, audio 等
# 	3. skill 完成( vfx/anim/audio )

# variable define
var skill_meta_map: Dictionary = {}


func _ready() -> void:
	SystemUtil.skill_system = self
	
	await CommonUtil.await_timer(2.0)
	
	# load skill meta resources
	load_skill_meta_res()

# 加载技能信息
func load_skill_meta_res():
	CommonUtil.load_resources_to_container_from_directory("res://System/skill_system/resources", skill_meta_map)


# 获取技能元信息
func get_meta_skill_by_id(skill_code: String) -> SkillMeta:
	return skill_meta_map[skill_code]
	
# 实例化 技能
func initialize_skills(skill_codes: Array[String]) -> Array[Skill]:
	var skill_list: Array[Skill] = []
	for skill_code in skill_codes:
		var skill = _initialize_skill(skill_code)
		skill_list.append(skill)
	return skill_list
	
 # 实例化
func _initialize_skill(skill_code: String) -> Skill:
	var skill_meta: SkillMeta = get_meta_skill_by_id(skill_code)
	if skill_meta != null:
		var skill = Skill.new()
		skill = CommonUtil.bean_properties_copy(skill_meta, skill)
		
		
		return skill
	
	return null
	
	
