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
func get_meta_skill_by_id(skill_code: String) -> SkillMetaResource:
	return skill_meta_map[skill_code]
	
# 实例化 技能
func initialize_skills(unit: BaseUnit, skill_metas: Array[SkillMetaResource]) -> Dictionary:
	var skill_map: Dictionary = {}
	for idx in range(skill_metas.size()):
		var skill: Skill = _initialize_skill(unit, skill_metas[idx], idx)
		if skill != null:
			skill_map[skill.code] = skill

			# add to unit tree
			skill.name = skill.code
			self.add_child(skill)

	return skill_map
	
 # 实例化
func _initialize_skill(unit: BaseUnit, skill_meta_res: SkillMetaResource, idx: int = 0) -> Skill:
	if skill_meta_res != null:
		var skill: Skill = Skill.new()
		CommonUtil.bean_properties_copy(skill_meta_res, skill)
		skill.skill_meta_res = skill_meta_res
		skill.sort = idx
		if skill.code == null:
			printerr("skill code not define")
			
		# skill id
		skill.id = UUID.v4()
		skill.unit = unit
		
		return skill
	
	return null
	

func action(skill_context: SkillContext) -> void:
	# 判断技能类型
	# 范围技能
	# 范围单位选择
	
	var skill: Skill = skill_context.skill

	var release_type: SkillMetaResource.SKILL_RELEASE_TYPE = skill.release_type

	if release_type == SkillMetaResource.SKILL_RELEASE_TYPE.TARGETED:
		var range: float = skill.range	# 技能范围

		var light_chain = LightingChain.new()
		light_chain.action(skill_context)



	pass	
