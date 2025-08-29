class_name LevelController
extends Node

var level_tres_arr: Array[LevelResource] = []
var level_tres_map: Dictionary = {}
const LEVEL_RESOURCE_GROUP = preload("res://Asserts/resources/demo_ui/LevelResourceGroup.tres")


var _pre_scene
var _cur_scene


func _ready():
	# listener signal 
	SignalBus.next_level.connect(next_level)
	
	level_res_load()
	await self.ready
	initialize_level()

 
# initialize level
func initialize_level():
	# next_level("choose_player")
	next_level("index")
	
func next_level_before():
	#if _pre_scene != null:
		#_pre_scene.queue_free()
	pass
	
# load level scene by scene code	
func next_level(code: String) -> Node:
	next_level_before()
	var s = load_scene(code)
	next_level_after()

	return s
	
	
func next_level_after():
	pass



func load_scene(scene_code: String) -> Node:
	var scene
	if scene_code == "index":
		scene = level_tres_map['index'].scene.instantiate()
		add_child(scene)

	if scene_code == "choose_player":
		scene = level_tres_map['choose_player'].scene.instantiate()
		add_child(scene)

	if scene_code == "game_over":
		scene = level_tres_map['game_over'].scene.instantiate()
		add_child(scene)		
	
	if scene_code == "level1":
		# binding LevelResource
		get_tree().set_meta(Constants.WAVE_RESOURCE, level_tres_map[scene_code].waves)
		# 初始化场景 1
		scene = level_tres_map['level1'].scene.instantiate()
		get_parent().add_child(scene)




	_pre_scene = _cur_scene
	_cur_scene = scene

	
	return scene


# load all level resource by resource group plugin
func level_res_load():
	LEVEL_RESOURCE_GROUP.load_all_into(level_tres_arr)
	await LEVEL_RESOURCE_GROUP.load_all_into
	for level_res: LevelResource in level_tres_arr:
		level_tres_map[level_res.code] = level_res
		
