class_name Skill extends Node

# Reference
var skill_meta_res: SkillMetaResource
var unit: BaseUnit
var target: BaseUnit



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
# 值
@export var value: float


# 技能内部控制变量
# 间隔时间
@export var internal_time: float = 0.1
# 施法前摇
@export var start_time: float = 0.1
# 施法后摇
@export var end_time: float = 0.1

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
	Targeted_Indicate,
    Direction_Indicate,
    Circle_Range_Indicate,
	Release
}

var current_state: SKILL_STATE
var mouse_click_check = false

var skill_context: SkillContext

func _ready() -> void:
    # 技能上下文构建
    # SkillContext 上下文，保存 skill: Skill, target: BaseUnit, source: BaseUnit, position: Vector3 等信息
    skill_context = SkillContext.new(self, null, unit, Vector3.ZERO)
    current_state = SKILL_STATE.Idle


func _input(event: InputEvent) -> void:
    if mouse_click_check and event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
        if current_state == SKILL_STATE.Direction_Indicate or current_state == SKILL_STATE.Circle_Range_Indicate:
            # 鼠标在 3d 空间中位置
            skill_context.position =  SOS.main.player_controller.player_mouse_position.global_position

            change_state(SKILL_STATE.Release)
            mouse_click_check = false
            Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
            get_viewport().set_input_as_handled()


func _on_player_selected_units(unit_map: Dictionary, mouse_pos: Vector3):
    if current_state == SKILL_STATE.Targeted_Indicate:
        if not unit_map.is_empty():
            var min_unit = null
            var min_distance = INF  # 使用 INF 作为初始最小距离
            
            # 遍历所有单位
            for u_key in unit_map.keys():
                var unit = unit_map.get(u_key)
                # 计算单位到原点的距离
                var distance = Vector2(unit.global_position.x, unit.global_position.z).length()
                
                # 如果找到更近的单位，更新最小距离和对应的单位
                if distance < min_distance:
                    min_distance = distance
                    min_unit = unit
            
            # 此时 min_unit 就是距离原点最近的单位
            if min_unit:
                # 在这里处理最近的单位，比如选中它
                print("最近的单位距离: ", min_distance)
                print("最近的单位: ", min_unit)


                skill_context.position = mouse_pos
                skill_context.target = min_unit
                change_state(SKILL_STATE.Release)
                SignalBus.player_selected_units.disconnect(_on_player_selected_units)
                SOS.main.player_controller.switch_cursor(Constants.CURSOR_STATUS.DEFAULT)


        
        pass



# Handles everything related to changing states
# You could also move each state's setup into a separate function if you had a lot to do.
func change_state(new_state: SKILL_STATE) -> void:
    current_state = new_state
    
    match current_state:
        SKILL_STATE.Circle_Range_Indicate:
            # PlayerStatus 切换
            SOS.main.player_controller.player_status = SOS.main.player_controller.PLAYER_STATUS.CHOOSING_TARGETED_UNIT
            # 技能指示器
            SOS.main.player_controller.player_skill_scope_indicator.show_indicator()
            # 隐藏鼠标光标
            Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
            mouse_click_check = true
            # 点击任意位置后，释放

        SKILL_STATE.Targeted_Indicate:
            # PlayerStatus 切换
            SOS.main.player_controller.player_status = SOS.main.player_controller.PLAYER_STATUS.CHOOSING_TARGETED_UNIT
            # 切换鼠标光标
            SOS.main.player_controller.switch_cursor(Constants.CURSOR_STATUS.TARGETED)
            # 监听玩家选择单位信号
            # 必须选中一个目标，才能切换状态（注意必须选中）
            SignalBus.player_selected_units.connect(_on_player_selected_units)
            

        SKILL_STATE.Release:
            # when click left mouse
            SOS.main.player_controller.player_status = SOS.main.player_controller.PLAYER_STATUS.DEFAULT
            SystemUtil.skill_system.release(skill_context)

            SOS.main.player_controller.player_skill_scope_indicator.hide_indicator()
            change_state(SKILL_STATE.Idle)


        SKILL_STATE.Idle:
            pass
    
