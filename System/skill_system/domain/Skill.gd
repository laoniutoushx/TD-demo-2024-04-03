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
	Release
}

var current_state: SKILL_STATE = SKILL_STATE.Idle


func _input(event: InputEvent) -> void:
    if current_state == SKILL_STATE.Indicate and event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
        change_state(SKILL_STATE.Release)
        get_viewport().set_input_as_handled()





# Handles everything related to changing states
# You could also move each state's setup into a separate function if you had a lot to do.
func change_state(new_state: SKILL_STATE) -> void:
    current_state = new_state
    
    match current_state:
        SKILL_STATE.Indicate:
            # 隐藏鼠标光标
            Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
            SOS.main.player_controller.player_skill_scope_indicator.show_indicator()

        SKILL_STATE.Release:
            action()
            Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
        SKILL_STATE.Idle:
            pass
    
# skill 动作执行
func action() -> void:
    # 加载技能 元数据 对应 action 脚本，执行
    # 0. 鼠标等效果处理， 施法效果, UI interactive
    # 1. skill 准备( anim/cooldown/vfx/audio )
    # 2. skill 执行（ do action ）可包括任何逻辑, take_damage, vfx, other logic, audio 等
    # 3. skill 完成( vfx/anim/audio )

    # SkillContext 上下文，保存 skill, target, source, position 等信息
    
    pass