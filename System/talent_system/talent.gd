class_name Talent extends Node3D



var unit: BaseUnit
var target: BaseUnit
var talent_res: TalentResource
var slot: BaseSlot


# Signal
signal talent_released(talent_context: TalentContext)      # initialize_skills 时注册
signal talent_cool_down(talent_context: TalentContext)
signal talent_disabled(talent_context: TalentContext, disabled: bool)      # action bar add_elements slot 时监听 skill_disabled 事件
signal talent_level_up(talent: Talent, level: int)
signal talent_cast_end(talent_context: TalentContext)	# 技能施法结束事件（技能施法结束后，可能会触发 buff 施法结束事件）



# basic properity
@export_group("Talent Meta Steup")
@export var id: String = UUID.v4()
@export var code: String
@export var title: String
@export var desc: String
@export var icon_path: String

# 冷却时间
@export var cooldown: float = 1.0
# 魔法消耗
@export var mana_cost: float = -1
# 技能伤害范围
@export var damage_range: float = 5.0
# 技能匹配目标对象范围（目标搜索范围，例如 light_chain 下一个目标匹配范围）
@export var match_range: float = 30.0
# 技能范围
@export var range: float = 5.0
# 释放距离
@export var release_distance: float = 10.0
# 技能点数（使用次数）
@export var stock: int  = -1
# 技能伤害值
@export var value: float = 0.0
# 技能伤害值（动态扩展）
@export var value_ext: Dictionary = {
	
}

# 技能运行距离（方向性技能）
@export var run_distance: float = 10.0
# 技能轮次（技能施法次数，触发多少次）
@export var epoch: int = 1



# 技能内部控制变量
@export_group("Talent Inner Steup") 
# 初始对象数量（skill 内部单位初始数量）
@export var init_num: int = 1
# 施法持续时间
@export var cast_duration: float = -1
# 间隔时间
@export var internal_time: float = -1
# 施法前摇
@export var start_time: float = 0.1
# 施法后摇
@export var end_time: float = 0.1
# 技能轮次
@export var wave: int = 1
# 技能投射速度 米/秒
@export var projection_speed: float = 1
# 触发几率（概率控制器）
@export var probability: float


# 技能禁用检查（魔法、健康值、金钱、木材）
@export_flags("MANA", "HEALTH", "MONEY", "WOOD") var disable_check: int = 0

# consume 消耗
# level up 
# release skill


@export_flags("TARGETED", "SELF_CAST", "NO_TARGET", "DIRECTION", "CIRCLE_RANGE", "PASSIVE") var release_type: int = 1
@export_flags("FLOOR", "UNIT", "NO_TARGET", "SELF", "FRIEND", "ENEMY") var target_type: int = 1	# 0: 地面, 1: 目标, 2: 无目标
@export_flags("DAMAGE","HEAL","BUILDING","BUFF","DEBUFF") var effect_type: int = 1	# 0: 伤害, 1: 治愈, 2: 建筑，3：buff，4：debuff


# 建筑变量
@export_group("Talent Build Steup")
# 建筑升级时间
@export var building_level_up_time: float = -1
# 建筑木材消耗
@export var wood_cost: float = -1
# 建筑金钱消耗
@export var money_cost: float = -1


@export_group("Talent Other Steup")
# Talent Script Template( 用于 动态 处理 Talent 逻辑 )
@export var talent_script: Script
var talent_script_instance: Variant

var talent_context: TalentContext

# Timer
var cool_down_timer: Timer


var _is_casting = false
var current_state: TALENT_STATE
var mouse_click_check = false



# FSM

# which state the skill at
enum TALENT_STATE {
    Idle,
    Targeted_Indicate,
    Building_Indicate,
    Direction_Indicate,
    Circle_Range_Indicate,
    Release,
    Casting,
    Cool_Down,
    Disabled
}





# Handles everything related to changing states
# You could also move each state's setup into a separate function if you had a lot to do.
func change_state(new_state: TALENT_STATE) -> void:

    # 前置条件检查（魔耗）
    # if _is_disabled:
    #     SOS.main.message_bar.set_message("技能无法施放，魔法不足")
    #     # change_state(TALENT_STATE.Idle)
    #     return


    # 从前一个状态迁移过来时，执行操作
    if (current_state == TALENT_STATE.Targeted_Indicate 
        or current_state == TALENT_STATE.Building_Indicate 
        or current_state == TALENT_STATE.Circle_Range_Indicate):
        # 单位全局技能共享状态值 -1
        unit.current_global_TALENT_STATE = 0
        # player status 变更 DEFAULT
        SOS.main.player_controller.player_status = SOS.main.player_controller.PLAYER_STATUS.DEFAULT
        # player cursor 变更 DEFAULT
        Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
        SOS.main.player_controller.switch_cursor(Constants.CURSOR_STATUS.DEFAULT)

        slot.icon_texture.material.set_shader_parameter("enable_gradient", false)
        var tween = create_tween()
        tween.tween_property(slot, "scale", Vector2(1.0, 1.0), 0.1)


        var range_comp = CommonUtil.get_component_by_name(unit, "RangeIndicator")
        if range_comp:
            range_comp.set_radius(unit.attack_range)


        # 恢复 cursor 移动
        SOS.main.player_controller.not_limit_move()

            
        if current_state == TALENT_STATE.Building_Indicate:
            # 关闭 BuildingKeyIndicator
            SOS.main.building_key_indicator.show_toggle()
            # 销毁 turrent 
            SignalBus.building_floor_indicator_hide.emit(talent_context)
            # 如果切换到 Idle 状态，直接删除 turret（耦合代码）
            if new_state == TALENT_STATE.Idle and SOS.main.turret_manager:
                SOS.main.turret_manager.turret.queue_free()
                SOS.main.turret_manager.cell_mesh_indicator.queue_free()
                

        if current_state == TALENT_STATE.Circle_Range_Indicate:
            # 隐藏技能指示器
            SOS.main.player_controller.player_skill_scope_indicator.hide_indicator()



        if current_state == TALENT_STATE.Targeted_Indicate:

            # 隐藏技能指示器
            SOS.main.player_controller.player_skill_target_indicator.hide()



    

    # 旧状态
    current_state = new_state

    match current_state:
        TALENT_STATE.Circle_Range_Indicate:
            slot.icon_texture.material.set_shader_parameter("enable_gradient", true)

            # 技能框放大
            var tween = create_tween()
            tween.tween_property(slot, "scale", Vector2(1.2, 1.2), 0.1)

            # 单位技能范围指示
            var range_comp = CommonUtil.get_component_by_name(unit, "RangeIndicator")
            if range_comp:
                range_comp.set_radius(release_distance)

            # 限制 cursor 移动
            SOS.main.player_controller.limit_move(unit.global_position, release_distance)

            # 单位全局技能状态处理
            unit.current_global_TALENT_STATE = 1
            # PlayerStatus 切换
            SOS.main.player_controller.player_status = SOS.main.player_controller.PLAYER_STATUS.CHOOSING_TARGETED_UNIT
            # 技能指示器
            SOS.main.player_controller.player_skill_scope_indicator.set_indicator_size(range * 2, range * 2)
            SOS.main.player_controller.player_skill_scope_indicator.show_indicator()
            # 隐藏鼠标光标
            Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
            mouse_click_check = true
            # 点击任意位置后，释放

        TALENT_STATE.Targeted_Indicate:
            slot.icon_texture.material.set_shader_parameter("enable_gradient", true)

            # 技能框放大
            var tween = create_tween()
            tween.tween_property(slot, "scale", Vector2(1.2, 1.2), 0.1)

            # 单位技能范围指示
            var range_comp = CommonUtil.get_component_by_name(unit, "RangeIndicator")
            if range_comp:
                range_comp.set_radius(release_distance)


            # 限制 cursor 移动
            SOS.main.player_controller.limit_move(unit.global_position, release_distance)     
            SOS.main.player_controller.player_skill_target_indicator.show()



            # 单位全局技能状态处理
            unit.current_global_TALENT_STATE = 1

            # TODO 可以在此处注册 键盘 Esc 事件，取消 indicator
            

            # PlayerStatus 切换
            SOS.main.player_controller.player_status = SOS.main.player_controller.PLAYER_STATUS.CHOOSING_TARGETED_UNIT

            # 等待3帧
            await CommonUtil.await_timer(0.1)

            # 切换鼠标光标
            # SOS.main.player_controller.switch_cursor(Constants.CURSOR_STATUS.TARGETED)
            # 隐藏鼠标光标（开始捕捉模式）
            Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
            mouse_click_check = true


            # 监听玩家选择单位信号
            # 必须选中一个目标，才能切换状态（注意必须选中）
            # SignalBus.player_selected_units.connect(_on_player_selected_units)
            set_process(true)

            # TODO 此处改为监听玩家 3d 空间鼠标位置附近碰撞单位，同时鼠标样式调整为 Sprite3D 或 Decel 模式，并禁止鼠标显示
            # 此时禁用 SelectionBox 与 RectangularSelection2D 的选择，启用程序目标选择


        TALENT_STATE.Building_Indicate:
            slot.icon_texture.material.set_shader_parameter("enable_gradient", true)

            # 技能框放大
            var tween = create_tween()
            tween.tween_property(slot, "scale", Vector2(1.2, 1.2), 0.1)

            # 单位技能范围指示
            # var range_comp = CommonUtil.get_component_by_name(unit, "RangeIndicator")
            # if range_comp:
            #     range_comp.set_radius(release_distance)

            # 单位全局技能状态处理
            unit.current_global_TALENT_STATE = 1

            # 开启 BuildingKeyIndicator（ 左键单击/ Esc 取消）
            SOS.main.building_key_indicator.show_toggle()

            # TODO 可以在此处注册 键盘 Esc 事件，取消 indicator


            # PlayerStatus 切换
            SOS.main.player_controller.player_status = SOS.main.player_controller.PLAYER_STATUS.CHOOSING_BUILDING_AREA
            # 切换鼠标光标
            SOS.main.player_controller.switch_cursor(Constants.CURSOR_STATUS.HAND)

            # 针对无目标点击地面技能，停顿 0.1 s（修复点击建筑单位图标，立即再对应位置建造单位的 BUG）
            await CommonUtil.await_timer(0.1)  # 等待一帧，确保状态切换

            # building floor indicator show by signal
            SignalBus.building_floor_indicator_show.emit(talent_context)


            
        TALENT_STATE.Release:

            # # 前置条件检查（魔耗）
            # if _is_disabled:
            #     SOS.main.message_bar.set_message("技能无法施放，魔法不足")
            #     change_state(TALENT_STATE.Idle)
            #     return            

            # 技能释放魔法消耗
            talent_released.emit(talent_context)

            # releasing
            SystemUtil.talent_system.release(talent_context)

            # 技能为持续释放（记录持续释放状态）
            if cast_duration > -1:
                _is_casting = true
                CommonUtil.delay_execution(cast_duration, func():
                    _is_casting = false
                    talent_cast_end.emit(talent_context)
                )

            
            if cooldown > -1:
                change_state(TALENT_STATE.Cool_Down)
            else:
                change_state(TALENT_STATE.Idle)





        TALENT_STATE.Cool_Down:

            # 开始倒计时
            cool_down_timer.start()

            # 槽
            if slot:
                if is_instance_valid(slot) and is_instance_valid(slot.progress_bar):
                    slot.progress_bar.visible = true    
                    slot.set_process(true)

            await cool_down_timer.timeout
            
            if slot:
                if is_instance_valid(slot) and is_instance_valid(slot.progress_bar):
                    slot.progress_bar.visible = false             
                    slot.set_process(false)

            change_state(TALENT_STATE.Idle)

            # 技能冷却完毕信号
            talent_cool_down.emit(talent_context)
            


        TALENT_STATE.Idle:
            print("talent [%s] is idle" % code)

        TALENT_STATE.Disabled:
            print("talent [%s] is Disabled" % code)            
