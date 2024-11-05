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

            # TODO 在对象实例化时，将 skill 绑定到对象树上，之后可以在 skill 中使用 get_tree() 的方法

            # 可选：如果需要全局监听鼠标点击，可以使用以下方式
            var click_handler: Callable = func() -> void:
                print("hello")
                if Input.is_action_just_pressed("click"):
                   change_state(SKILL_STATE.Released)
            get_tree().process_frame.connect(click_handler)

        SKILL_STATE.Released:
            pass
        SKILL_STATE.Idle:
            pass
    
