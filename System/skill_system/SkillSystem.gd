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
func initialize_skills(source_unit: BaseUnit, skill_metas: Array[SkillMetaResource]) -> Dictionary:
	var skill_map: Dictionary = {}
	for idx in range(skill_metas.size()):
		var skill: Skill = _initialize_skill(source_unit, skill_metas[idx], idx)

		# 初始化 buff
		SystemUtil.buff_system.init_buff_for_unit_by_res(skill.skill_meta_res, skill)

		skill.unit = source_unit
		if skill != null:
			skill_map[skill.code] = skill

			# add to unit tree
			skill.name = skill.code
			self.add_child(skill)
			skill.add_child(skill.skill_script_instance)

	return skill_map
	
 # 实例化
func _initialize_skill(source_unit: BaseUnit, skill_meta_res: SkillMetaResource, idx: int = 0) -> Skill:
	if skill_meta_res != null:
		var skill: Skill = Skill.new()
		skill.unit = source_unit
		CommonUtil.bean_properties_copy(skill_meta_res, skill)
		# 手动赋值 skill_script
		skill.skill_script = skill_meta_res.skill_script


		skill.skill_meta_res = skill_meta_res
		skill.sort = idx
		if skill.code == null:
			printerr("ERROR: skill code not define")
			
		# skill id
		skill.id = UUID.v4()


		# 实例化技能脚本
		# assert(skill.skill_script != null, "skill script not define")
		if skill.skill_script != null:
			skill.skill_script_instance = skill.skill_script.new()
		else:
			printerr("ERROR: skill script not define")
		
		return skill
	
	return null
	

func release(skill_context: SkillContext) -> void:
    # 加载技能 元数据 对应 action 脚本，执行
    # 0. 鼠标等效果处理， 施法效果, UI interactive
    # 1. skill 准备( anim/cooldown/vfx/audio )
    # 2. skill 执行（ do action ）可包括任何逻辑, take_damage, vfx, other logic, audio 等
    # 3. skill 完成( vfx/anim/audio )

	var skill: Skill = skill_context.skill
	var source_unit: BaseUnit = skill_context.source
	var target_unit: BaseUnit = skill_context.target

	if source_unit is Gdbot:

		source_unit.jump()
		await CommonUtil.await_timer(0.1)
		source_unit.fall()
		await CommonUtil.await_timer(0.1)
		source_unit.idle()


	var ap: AnimationPlayer = CommonUtil.get_first_node_by_node_type(source_unit, Constants.AnimationPlayer_CLZ)
	var anim_release_code: String = source_unit.anim_release

	if ap != null and ap.has_animation(anim_release_code):
		ap.play(anim_release_code)

	await CommonUtil.await_timer(skill_context.skill.start_time)
	skill.skill_script_instance.action(skill_context)
	await CommonUtil.await_timer(skill_context.skill.end_time)
