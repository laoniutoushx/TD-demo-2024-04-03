class_name LevelController
extends Node

signal scene_changed(code: String, scene: Node)

const LEVEL_RESOURCE_GROUP = preload("res://Asserts/resources/demo_ui/LevelResourceGroup.tres")
const SETTINGS_PATH = "res://Levels/setting/setting.tscn"
const PLAYER_PATH = "res://Player/player_controller.tscn"
var level_tres_arr: Array[LevelResource] = []
var level_tres_map: Dictionary = {}
var level_map: Dictionary = {}
var _pre_scene: Node
var _cur_scene: Node
var _settings: Control
var _transitioning := false
var _battle_finished := false
var result: Dictionary = {}
var session_id := 0
var battle_active := false

func _ready() -> void:
	SignalBus.next_level.connect(next_level)
	level_res_load()
	initialize_level.call_deferred()

func initialize_level() -> void:
	next_level("index")

func level_res_load() -> void:
	LEVEL_RESOURCE_GROUP.load_all_into(level_tres_arr)
	for resource in level_tres_arr:
		level_tres_map[resource.code] = resource

func next_level(code: String) -> Node:
	if code == "setting":
		return open_settings()
	if _transitioning or not level_tres_map.has(code):
		return null
	if is_instance_valid(_cur_scene) and level_map.get(code) == _cur_scene:
		return _cur_scene
	_transitioning = true
	if code == "level1":
		session_id += 1
		battle_active = true
		_battle_finished = false
		result.clear()
		var player = load(PLAYER_PATH).instantiate()
		get_parent().set_player_controller(player)
		get_parent().add_child(player)
		get_tree().set_meta(Constants.WAVE_RESOURCE, level_tres_map[code].waves)
	_pre_scene = _cur_scene
	var scene = level_tres_map[code].scene.instantiate()
	_cur_scene = scene
	level_map[code] = scene
	if code == "level1":
		get_parent().add_child(scene)
	else:
		add_child(scene)
	if is_instance_valid(_pre_scene) and code != "game_over":
		for key in level_map.keys():
			if level_map[key] == _pre_scene:
				level_map.erase(key)
		_pre_scene.queue_free()
	_transitioning = false
	scene_changed.emit(code, scene)
	return scene

func open_settings() -> Control:
	if not is_instance_valid(_settings):
		_settings = load(SETTINGS_PATH).instantiate()
		get_parent().add_child(_settings)
		_settings.tree_exiting.connect(_on_settings_closed, CONNECT_ONE_SHOT)
		if _cur_scene == level_map.get("index"):
			_cur_scene.index_ui._hide()
		elif _cur_scene == level_map.get("game_over"):
			_cur_scene.hide()
	return _settings

func finish_battle(is_win: bool) -> void:
	if _battle_finished or not is_instance_valid(level_map.get("level1")):
		return
	_battle_finished = true
	battle_active = false
	get_parent().barrage_system.reset_session()
	var battle = level_map["level1"]
	var player = get_parent().player_controller
	result = {
		"wave": battle.wave_manager.cur_wave_index,
		"waves": battle.wave_manager.wave_resources.size(),
		"defeated": player.death_unit_num,
		"money": player.total_money,
		"wood": player.total_wood,
		"score": player.player_score,
	}
	SignalBus.game_over.emit()
	battle.ui.layer.visible = false
	battle.action_bar.hidden()
	battle.process_mode = Node.PROCESS_MODE_DISABLED
	player.process_mode = Node.PROCESS_MODE_DISABLED
	var screen = next_level("game_over")
	screen.setup(is_win)

func return_to_menu(next_code: String = "index") -> void:
	if _transitioning:
		return
	_transitioning = true
	battle_active = false
	session_id += 1
	SignalBus.game_over.emit()
	if is_instance_valid(_settings):
		_settings.queue_free()
	_settings = null
	for scene in level_map.values():
		if is_instance_valid(scene):
			scene.process_mode = Node.PROCESS_MODE_DISABLED
			scene.queue_free()
	level_map.clear()
	_cur_scene = null
	_pre_scene = null
	var player = get_parent().player_controller
	get_parent().player_controller = null
	get_parent().turret_manager = null
	if is_instance_valid(player):
		player.queue_free()
	get_parent().reset_session_modules()
	await get_tree().process_frame
	BaseSlot.action_bar = null
	get_tree().paused = false
	_transitioning = false
	next_level(next_code)

func _on_settings_closed() -> void:
	_settings = null
	if not is_instance_valid(_cur_scene) or _transitioning:
		return
	if _cur_scene == level_map.get("index"):
		_cur_scene.index_ui._show()
	elif _cur_scene == level_map.get("game_over"):
		_cur_scene.show()
