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

	if talent != null:
		

		# add to unit tree
		talent.name = talent.code
		talent.add_child(talent.talent_script_instance)



	return talent


	

# # 实例化
func _initialize_talent(talent_meta_res: TalentResource, idx: int = 0) -> Talent:
	if talent_meta_res != null:
		var talent: Talent = Talent.new()
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
