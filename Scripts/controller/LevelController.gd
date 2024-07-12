class_name LevelController
extends Node

var level_tres_arr: Array[LevelResource] = []
var level_tres_map: Dictionary = {}
const LEVEL_RESOURCE_GROUP = preload("res://Res/LevelResourceGroup.tres")


func _ready():
	# listener signal 
	SignalBus.connect("next_level", next_level)
	
	level_res_load()
	await self.ready
	initialize_level()

 
# initialize level
func initialize_level():
	next_level("choose_player")
	
func next_level_before():
	pass	
	
# load level scene by scene code	
func next_level(code: String):
	next_level_before()
	load_scene(code)
	next_level_after()
	
	
func next_level_after():
	pass



func load_scene(scene_code: String) -> Node:
	var scene
	if scene_code == "choose_player":
		scene = level_tres_map['choose_player'].scene.instantiate()
		add_child(scene)
	
	if scene_code == "level1":
		# binding LevelResource
		get_tree().set_meta(Constants.WAVE_RESOURCE, level_tres_map[scene_code].waves)
		# 初始化场景 1
		scene = level_tres_map['level1'].scene.instantiate()
		get_parent().add_child(scene)
		var path = scene.find_child("Path3D")
		

	
	return scene


# load all level resource by resource group plugin
func level_res_load():
	LEVEL_RESOURCE_GROUP.load_all_into(level_tres_arr)
	await LEVEL_RESOURCE_GROUP.load_all_into
	for level_res: LevelResource in level_tres_arr:
		level_tres_map[level_res.code] = level_res
		
