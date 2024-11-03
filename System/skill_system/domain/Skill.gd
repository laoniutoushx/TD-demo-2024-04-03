class_name Skill extends Node

# Reference
var skill_meta_res: SkillMetaResource
var unit: BaseUnit


# meta info 
var id: String
var code: String
@export var sort: int

@export var title: String = "Unnamed Skill"
@export var desc: String
@export var icon_path: String
@export var level: int = 0
@export var max_level: int = 3

# 冷却时间
@export var cooldown: float = 1.0
# 魔法消耗
@export var mana_cost: float = 10.0
# 技能范围
@export var range: float = 5.0
# 释放距离
@export var release_distance: float 
# 技能点数（使用次数）
@export var stock: int  = 1

# consume 消耗
# level up 
# release skill


@export var release_type: SkillMetaResource.SKILL_RELEASE_TYPE
@export var target_type: SkillMetaResource.SKILL_RELEASE_TYPE	# 0: 地面, 1: 目标, 2: 无目标
# define how unit move on mesh ground( walk/fly )
@export var target_move_type = 0
# define unit category (  HUMAN/BUILDING/DECORATE_DESTORIED/DECORATE_FOREVER )
@export var target_cate = 0


# Skill Script Template( ClassDB )
@export var script_name: Script


# FSM

# What state the turret is in
enum SKILL_STATE {
	Idle,
	Indicate,
	Released
}

var current_state: SKILL_STATE = SKILL_STATE.Idle

# Handles everything related to changing states
# You could also move each state's setup into a separate function if you had a lot to do.
func change_state(new_state: SKILL_STATE) -> void:
    current_state = new_state
    
    match current_state:
        SKILL_STATE.Indicate:
            SOS.main.player_controller.player_skill_scope_indicator.show_indicator()
            # 开启一个监听器，监听 mouse clicked 事件，事件触发时，切换 skill state
            var _on_gui_input = func (event: InputEvent) -> void:
                # 检查事件是否为鼠标按下
                if (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed):
                    print("左键点击!")

            var viewport =SOS.main.get_viewport()
            viewport.connect(SOS.main.input_event, _on_gui_input)


        SKILL_STATE.Released:
            pass
        SKILL_STATE.Idle:
            pass
    
