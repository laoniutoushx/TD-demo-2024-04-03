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
	
	# await CommonUtil.await_timer(2.0)
	
	# load skill meta resources
	load_skill_meta_res()

	# load skill resource
	# CommonUtil.load_resources_to_container_from_directory("res://System/skill_system/resources", skill_meta_map)

	# 自动释放逻辑处理
	SignalBus.skill_auto_release.connect(_on_skill_auto_release)




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

		if skill != null:
			skill_map[skill.code] = skill

			# add to unit tree
			skill.name = skill.code
			source_unit.add_child(skill)

			skill.add_child(skill.skill_script_instance)


			## 只处理玩家单位（不涉及敌人单位）
			if SystemUtil.unit_system.is_player_unit(source_unit):
				# listener skill disabled cond
				# 技能初始化时，判断技能是否应该禁用（手动触发）
				if CommonUtil.is_flag_set(SkillMetaResource.SKILL_DISABLE_CHECK.MANA, skill.disable_check):
					skill._on_mana_changed(source_unit, source_unit.max_mana)

					skill.skill_released.connect(source_unit._on_skill_released)	# 技能释放触发单位魔法变动
					source_unit.mana_changed.connect(skill._on_mana_changed)		# 单位魔法变动触发技能魔法变动事件（管理 ui 等禁用）
					
				if CommonUtil.is_flag_set(SkillMetaResource.SKILL_DISABLE_CHECK.WOOD, skill.disable_check):	
					skill._on_wood_changed(source_unit, SOS.main.player_controller.wood)
					SignalBus.wood_changed.connect(skill._on_wood_changed)
				if CommonUtil.is_flag_set(SkillMetaResource.SKILL_DISABLE_CHECK.MONEY, skill.disable_check):	
					skill._on_money_changed(source_unit, SOS.main.player_controller.money)
					SignalBus.money_changed.connect(skill._on_money_changed)



	return skill_map


	
 # 实例化
func _initialize_skill(source_unit: BaseUnit, skill_meta_res: SkillMetaResource, idx: int = 0) -> Skill:
	if skill_meta_res != null:
		var skill: Skill = Skill.new().duplicate()
		skill.unit = source_unit

		# skill context init
		# skill.skill_context = SkillContext.new(skill, null, source_unit, Vector3.ZERO)

		# skill property init
		CommonUtil.bean_properties_copy(skill_meta_res, skill)
		# 手动赋值 skill_script
		skill.skill_script = skill_meta_res.skill_script


		skill.skill_meta_res = skill_meta_res
		skill.sort = idx
		if skill.code == null:
			printerr("ERROR: skill code not define")
			
		# skill id
		skill.id = UUID.v4()

		# skill unit
		skill.unit = source_unit


		# 实例化技能脚本
		# assert(skill.skill_script != null, "skill script not define")
		if skill.skill_script != null:
			skill.skill_script_instance = skill.skill_script.new()
			# if skill.skill_script_instance.has_method("init"):
			# 	skill.skill_script_instance.init(skill)
			# else:
			# 	printerr("INFO: %s skill script method [init] not define" % [skill.title])
		else:
			printerr("ERROR: %s skill script not define" % [skill.title])
		
		return skill
	
	return null


	
# 技能释放入口
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
	if is_instance_valid(skill):
		skill.skill_script_instance.action(skill_context)
		await CommonUtil.await_timer(skill_context.skill.end_time)



# 自动施法入口
# auto release
func _on_skill_auto_release(is_auto_release: bool, skill_context: SkillContext):
	if not skill_context:
		return 

	var skill: Skill = skill_context.skill
	var source_unit: BaseUnit = skill_context.source
	var target_unit: BaseUnit = skill_context.target

	# await skill.ready
	# await skill.unit.ready

	if is_auto_release:
		# 判断技能类型（不是建筑类型）
		if not CommonUtil.is_flag_set(SkillMetaResource.SKILL_EFFECT_TYPE.BUILDING, skill.effect_type):


			# 技能需要范围判断（自释放除外）
			if not CommonUtil.is_flag_set(SkillMetaResource.SKILL_RELEASE_TYPE.SELF_CAST, skill.release_type):
				# load area_tscn
				var area_tscn: PackedScene = load("res://Components/area/area.tscn")
				var area_inst: Area = area_tscn.instantiate().duplicate()

				area_inst.init(skill.release_distance)
				source_unit.add_child(area_inst)

				skill._area_ai = area_inst
				area_inst.area_entered.connect(_on_area_3d_area_entered.bind(skill_context))
				area_inst.area_exited.connect(_on_area_3d_area_exited.bind(skill_context))

				await skill._area_ai.ready
			
			# 技能冷却
			skill.skill_cool_down.connect(_on_skill_cool_down)

			

			# 等待 area_ai 完成后，立即执行
			skill_release_right_now(skill_context)
 
	else:
		if skill.skill_cool_down.is_connected(_on_skill_cool_down):
			skill.skill_cool_down.disconnect(_on_skill_cool_down)
		if skill._area_ai:
			skill._area_ai.area_entered.disconnect(_on_area_3d_area_entered)
			skill._area_ai.area_exited.disconnect(_on_area_3d_area_exited)
			skill._area_ai.queue_free()
		skill._area_ai = null




## Skill AI Hanlder（事件驱动 - 技能冷却、进入释放范围） + Command Queue
var auto_release_skill_command_container: Dictionary = {}



# 技能冷却完成
func _on_skill_cool_down(skill_context: SkillContext) -> void:
	await CommonUtil.await_timer(0.3)
	skill_release_right_now(skill_context)


# 单位进入技能释放范围
func _on_area_3d_area_entered(area: Area3D, skill_context: SkillContext):
	skill_release_right_now(skill_context)


# 单位离开技能释放范围
func _on_area_3d_area_exited(area: Area3D, skill_context: SkillContext):
	pass	# do nothing


# 立即执行一次技能释放
func skill_release_right_now(skill_context: SkillContext) -> void:
	var skill: Skill = skill_context.skill
	if not is_instance_valid(skill):
		return

	# 1. 技能状态判断（技能未在释放或冷却中 或 技能禁用）
	if (skill.current_state == Skill.SKILL_STATE.Cool_Down or skill.current_state == Skill.SKILL_STATE.Release 
			or skill._is_disabled):
		return

	# 2. 技能释放条件是否满足
	if skill._area_ai and skill._area_ai.has_overlapping_areas() and CommonUtil.is_flag_set(SkillMetaResource.SKILL_TARGET_TYPE.ENEMY, skill.target_type):
		var areas:Array[Area3D] =  skill._area_ai.get_overlapping_areas()
		for area in areas:
			var matched_unit = area.owner
			if matched_unit is Enemy and matched_unit.is_alive() and matched_unit.player_group != SOS.main.player_controller.player_group_idx:
				skill_context.source = skill.unit
				skill_context.target = matched_unit
				skill_context.target_position = matched_unit.global_position
				skill.change_state(Skill.SKILL_STATE.Release)
				break
		return

	if skill._area_ai and skill._area_ai.has_overlapping_areas() and CommonUtil.is_flag_set(SkillMetaResource.SKILL_TARGET_TYPE.FRIEND, skill.target_type):
		var areas:Array[Area3D] =  skill._area_ai.get_overlapping_areas()
		for area in areas:
			var matched_unit = area.owner
			if matched_unit is Turret and matched_unit.player_group == SOS.main.player_controller.player_group_idx:
				skill_context.source = skill.unit
				skill_context.target = matched_unit
				skill_context.target_position = matched_unit.global_position
				skill.change_state(Skill.SKILL_STATE.Release)
				break
		return

	if CommonUtil.is_flag_set(SkillMetaResource.SKILL_TARGET_TYPE.SELF, skill.target_type):
		skill_context.source = skill.unit
		skill_context.target = skill.unit
		skill_context.target_position = skill.unit.global_position
		skill.change_state(Skill.SKILL_STATE.Release)
		return
