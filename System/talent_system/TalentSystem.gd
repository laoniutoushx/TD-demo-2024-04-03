class_name TalentSystem extends Node3D


func _ready() -> void:
	SystemUtil.talent_system = self
	# 在系统启动时，初始化所有 item template resource，将起保存在 container 当中
	CommonUtil.load_resources_to_container_from_directory("res://System/talent_system/resources/")

	# IOC 注册到 SystemUtil
	SystemUtil.talent_system = self




func show_player_talent_ui() -> void:
	SOS.main.level_controller._cur_scene.ui.talent_choose.show()


# 实例化 天赋
func initialize_talent(talent_code: String) -> Talent:

	# 获取资源文件
	var talent_meta_res: TalentResource = CommonUtil.get_resource(talent_code)


	var talent: Talent = _initialize_talent(talent_meta_res)

	# 初始化 buff
	SystemUtil.buff_system.init_buff_for_unit_by_res(SOS.main.level_controller._cur_scene.gdbot, talent.talent_res, talent)


	if talent != null:
		

		# add to unit tree
		talent.name = talent.code

		# 固定单位（source unit）
		talent.unit = SOS.main.level_controller._cur_scene.gdbot
		talent.add_child(talent.talent_script_instance)



	return talent


	

# # 实例化
func _initialize_talent(talent_meta_res: TalentResource, idx: int = 0) -> Talent:
	if talent_meta_res != null:
		var talent: Talent = Talent.new().duplicate()
		talent.unit = SOS.main.level_controller._cur_scene.gdbot

		CommonUtil.bean_properties_copy(talent_meta_res, talent)

		# 手动赋值 skill_script
		talent.talent_script = talent_meta_res.talent_script
		talent.talent_res = talent_meta_res
		if talent.code == null:
			printerr("ERROR: talent code not define")
			
		# skill id
		talent.id = UUID.v4()

		# 实例化技能脚本
		# assert(skill.skill_script != null, "skill script not define")
		if talent.talent_script != null:
			talent.talent_script_instance = talent.talent_script.new()
		else:
			printerr("ERROR: talent script not define")

		return talent
	
	return null







# 天赋释放入口
func release(talent_context: TalentContext) -> void:
	# 加载技能 元数据 对应 action 脚本，执行
	# 0. 鼠标等效果处理， 施法效果, UI interactive
	# 1. talent 准备( anim/cooldown/vfx/audio )
	# 2. talent 执行（ do action ）可包括任何逻辑, take_damage, vfx, other logic, audio 等
	# 3. talent 完成( vfx/anim/audio )

	var talent: Talent = talent_context.talent
	var source_unit: BaseUnit = talent_context.source
	var target_unit: BaseUnit = talent_context.target

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

	await CommonUtil.await_timer(talent_context.talent.start_time)
	if is_instance_valid(talent):
		
		# 显示技能释放漂浮文字
		SystemUtil.floating_text_system.spawn(
			Vector3(source_unit.global_position.x, source_unit._height, source_unit.global_position.z),
			talent.title,
			Color.GREEN_YELLOW
		)

		talent.talent_script_instance.action(talent_context)
		await CommonUtil.await_timer(talent_context.talent.end_time)
