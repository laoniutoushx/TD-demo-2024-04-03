class_name Skill extends Node3D

# Reference
var skill_meta_res: SkillMetaResource
var unit: BaseUnit
var target: BaseUnit
var slot: BaseSlot


# Signal
signal skill_released(skill_context: SkillContext)      # initialize_skills 时注册
signal skill_cool_down(skill_context: SkillContext)
signal skill_disabled(skill_context: SkillContext, disabled: bool)      # action bar add_elements slot 时监听 skill_disabled 事件
signal skill_level_up(skill: Skill, level: int)


# meta info 
@export_group("Skill Meta Steup")
var id: StringName
var code: String
@export var sort: int

@export var title: String = "Unnamed Skill"
@export var desc: String
@export var icon_path: String
@export var level: int
@export var max_level: int
@export var level_limit: int	# 技能生效等级限制
@export var next_level_limit: int	# 下一级技能生效等级限制

# 初始化释放
@export var init_release: bool
# 自动施法
@export var auto_release: bool = false :
    set(value):
        auto_release = value
        if not is_inside_tree():
            await ready
        SignalBus.skill_auto_release.emit(value, skill_context)

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
@export_group("Skill Inner Steup") 
# 初始对象数量（skill 内部单位初始数量）
@export var init_num: int = 1
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
@export_group("Skill Build Steup")
# 建筑升级时间
@export var building_level_up_time: float = -1
# 建筑木材消耗
@export var wood_cost: float = -1
# 建筑金钱消耗
@export var money_cost: float = -1


# 其他配置
@export_group("Skill Other Steup")
# Skill Script Template( ClassDB )
@export var skill_script: Script
var skill_script_instance: Variant




@export_group("Skill Buff")
# Buff（实例化后的buff列表）
var buff_map: Dictionary = {}


# Timer
var cool_down_timer: Timer

# 禁用 skill
var _is_disabled = false
var _mana_disabled = false
var _health_disabled = false
var _money_disabled = false
var _wood_disabled = false
var _level_disabled = false


# FSM

# which state the skill at
enum SKILL_STATE {
	Idle,
	Targeted_Indicate,
    Building_Indicate,
    Direction_Indicate,
    Circle_Range_Indicate,
	Release,
    Cool_Down,
    Disabled
}

var current_state: SKILL_STATE
var mouse_click_check = false

var skill_context: SkillContext

# AI 相关（技能范围判断 AREA)
var _area_ai: Area3D

## 独立概率器是否初始化
var _prob_controller: ProbabilityController = null





#################### Ready ###########################
func _ready() -> void:
    # 技能上下文构建
    # SkillContext 上下文，保存 skill: Skill, target: BaseUnit, source: BaseUnit, position: Vector3 等信息
    skill_context = SkillContext.new(self, null, unit, Vector3.ZERO)
    current_state = SKILL_STATE.Idle

    # cool_down_timer 配置
    cool_down_timer = Timer.new()
    cool_down_timer.one_shot = true
    cool_down_timer.autostart = false
    cool_down_timer.wait_time = cooldown
    add_child(cool_down_timer)

    # player 监听技能释放
    skill_released.connect(SOS.main.player_controller._on_skill_released)

    # 如果技能设置为初始化时自动施法，则在此手动激活
    if init_release:
        change_state(SKILL_STATE.Release)

    # 监听单位等级提升事件
    unit.level_up.connect(_on_unit_level_up)


# 监听单位升级事件
func _on_unit_level_up(unit: BaseUnit, unit_level: int) -> void:
    # 如果单位升级了，那么 =》 
    if unit_level >= level_limit:
        print("skill [%s] is idle, because unit [%s] level [%s] >= limit [%s]" % [code, unit.name, level, level_limit])
        if current_state == SKILL_STATE.Disabled:
            change_state(SKILL_STATE.Idle)


        # 处理技能升级逻辑
        if skill_meta_res.skill_level_config and skill_meta_res.skill_level_config.size() + 1 > level:

            var next_level_skill_res: SkillMetaResource = skill_meta_res.skill_level_config[level - 1]
            if next_level_skill_res and level < max_level and unit_level >= next_level_skill_res.level_limit:
                # 刷新技能属性数据到对应技能等级
                CommonUtil.bean_properties_copy(next_level_skill_res, self)

                # 刷新技能槽图标展示等级
                if slot:
                    slot.reset_level(level)
                
                # 技能升级事件
                skill_level_up.emit(self, level)



# 监听所属单位攻击事件
func _on_unit_attack(source: BaseUnit, target: BaseUnit) -> void:
    # 被动技能注册（攻击、受击触发）
    if source.get_instance_id() == unit.get_instance_id() and _prob_controller.next():
        skill_context.source = source
        skill_context.target = target
        skill_context.target_position = target.global_position

        # 触发技能释放
        change_state(SKILL_STATE.Release)
        # SystemUtil.skill_system.skill_release_right_now(skill_context)



# 监听所属单位魔法值变化( SkillSystem initialize_skills 方法中监听 )
func _on_mana_changed(unit: BaseUnit, left_mana: float):
    if unit.get_instance_id() == self.unit.get_instance_id():

        if mana_cost > -1:
            if left_mana < mana_cost:
                _mana_disabled = true
                call_deferred("skill_disabled_check")
            else:
                _mana_disabled = false
                call_deferred("skill_disabled_check")



# 监听所属玩家木材变化( SkillSystem initialize_skills 方法中监听 )
func _on_wood_changed(source: Object, left_wood: int):

    # 判断是否是建筑技能
    if CommonUtil.is_flag_set(SkillMetaResource.SKILL_EFFECT_TYPE.BUILDING, self.effect_type):
        if skill_meta_res.building_res.wood_cost > -1:
            if left_wood < skill_meta_res.building_res.wood_cost:
                _wood_disabled = true
                call_deferred("skill_disabled_check")
            else:
                _wood_disabled = false
                call_deferred("skill_disabled_check")



# 监听所属玩家金钱变化( SkillSystem initialize_skills 方法中监听 )
func _on_money_changed(source: Object, left_money: int):

    # 判断是否是建筑技能
    if CommonUtil.is_flag_set(SkillMetaResource.SKILL_EFFECT_TYPE.BUILDING, self.effect_type):
        # print("skill name %s - %s， skill building money cost %s" % [self.code, self.name, skill_meta_res.building_res.money_cost])
        if skill_meta_res.building_res.money_cost > -1:
            if left_money < skill_meta_res.building_res.money_cost:
                _money_disabled = true
                call_deferred("skill_disabled_check")
            else:
                _money_disabled = false
                call_deferred("skill_disabled_check")



func skill_disabled_check() -> void:
    _is_disabled = _mana_disabled || _health_disabled || _money_disabled || _wood_disabled
    # print("skill name %s - %s， skill status in [mana %s, health %s, money %s, wood %s]， [ real value mana %s, health %s, money %s, wood %s]" 
            # % [self.code, self.name, _mana_disabled, _health_disabled, _money_disabled, _wood_disabled, 
            # unit.mana, null, SOS.main.player_controller.money, SOS.main.player_controller.wood])
    skill_disabled.emit(skill_context, _is_disabled)




func _input(event: InputEvent) -> void:
    if mouse_click_check and event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
        # 单位事件监听
        if current_state == SKILL_STATE.Direction_Indicate or current_state == SKILL_STATE.Circle_Range_Indicate:
            mouse_click_check = false
            # 鼠标在 3d 空间中位置
            # skill_context.target_position =  SOS.main.player_controller.player_mouse_position.global_position
            # 玩家 circle indicator 在 3d 空间中位置（适配玩家技能范围，防止释放技能超出技能施法范围距离）
            skill_context.target_position =  SOS.main.player_controller.player_skill_scope_indicator.global_position

            change_state(SKILL_STATE.Release)
            Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
            get_viewport().set_input_as_handled()
    
    if event is InputEventKey and event.pressed and event.keycode  == KEY_ESCAPE:
        if current_state == SKILL_STATE.Targeted_Indicate or current_state == SKILL_STATE.Building_Indicate or current_state == SKILL_STATE.Circle_Range_Indicate:
            Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
            change_state(SKILL_STATE.Idle)
            mouse_click_check = false
            get_viewport().set_input_as_handled()




# 废弃 Decrease Decription 这个方法暂时标记为不使用
func _on_player_selected_units(unit_map: Dictionary, mouse_pos: Vector3, on_selected_player_status: PlayerController.PLAYER_STATUS) -> void:
    if current_state == SKILL_STATE.Targeted_Indicate:
        if not unit_map.is_empty():
            var min_unit = null
            var min_distance = INF  # 使用 INF 作为初始最小距离
            
            # 遍历所有单位
            for u_key in unit_map.keys():
                var unit = unit_map.get(u_key)

                # 根据 skill target type 动态判断是否满足条件
                if not _skill_target_unit_cond_matched(unit):
                    continue

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


                skill_context.target_position = mouse_pos
                skill_context.target = min_unit

                change_state(SKILL_STATE.Release)
                SignalBus.player_selected_units.disconnect(_on_player_selected_units)
                SOS.main.player_controller.switch_cursor(Constants.CURSOR_STATUS.DEFAULT)
            else:
                print("没有找到最近的单位")
                SOS.main.message_bar.set_message("没有选中任何单位")

        else:
            print("没有选中任何单位")
            SOS.main.message_bar.set_message("没有选中任何单位")


# skill target selected unit filter
func _skill_target_unit_cond_matched(_u: BaseUnit) -> bool:

    var conditions = [
        # friend unit
        CommonUtil.is_flag_set(SkillMetaResource.SKILL_TARGET_TYPE.FRIEND, target_type) and _u.player_group == SOS.main.player_controller.player_group_idx,
        # enemy unit
        CommonUtil.is_flag_set(SkillMetaResource.SKILL_TARGET_TYPE.ENEMY, target_type) and _u.player_group != SOS.main.player_controller.player_group_idx
    ]

    return conditions.any(func(x): return x)





# Handles everything related to changing states
# You could also move each state's setup into a separate function if you had a lot to do.
func change_state(new_state: SKILL_STATE) -> void:

    # 前置条件检查（魔耗）
    # if _is_disabled:
    #     SOS.main.message_bar.set_message("技能无法施放，魔法不足")
    #     # change_state(SKILL_STATE.Idle)
    #     return


    # 从前一个状态迁移过来时，执行操作
    if (current_state == SKILL_STATE.Targeted_Indicate 
        or current_state == SKILL_STATE.Building_Indicate 
        or current_state == SKILL_STATE.Circle_Range_Indicate):
        # 单位全局技能共享状态值 -1
        unit.current_global_skill_state = 0
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

            
        if current_state == SKILL_STATE.Building_Indicate:
            # 关闭 BuildingKeyIndicator
            SOS.main.building_key_indicator.show_toggle()
            # 销毁 turrent 
            SignalBus.building_floor_indicator_hide.emit(skill_context)
            # 如果切换到 Idle 状态，直接删除 turret（耦合代码）
            if new_state == SKILL_STATE.Idle and SOS.main.turret_manager:
                SOS.main.turret_manager.turret.queue_free()
                SOS.main.turret_manager.cell_mesh_indicator.queue_free()
                

        if current_state == SKILL_STATE.Circle_Range_Indicate:
            # 隐藏技能指示器
            SOS.main.player_controller.player_skill_scope_indicator.hide_indicator()



        if current_state == SKILL_STATE.Targeted_Indicate:

            # 隐藏技能指示器
            SOS.main.player_controller.player_skill_target_indicator.hide()


 
    

    # 旧状态
    current_state = new_state

    match current_state:
        SKILL_STATE.Circle_Range_Indicate:
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
            unit.current_global_skill_state = 1
            # PlayerStatus 切换
            SOS.main.player_controller.player_status = SOS.main.player_controller.PLAYER_STATUS.CHOOSING_TARGETED_UNIT
            # 技能指示器
            SOS.main.player_controller.player_skill_scope_indicator.set_indicator_size(range * 2, range * 2)
            SOS.main.player_controller.player_skill_scope_indicator.show_indicator()
            # 隐藏鼠标光标
            Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
            mouse_click_check = true
            # 点击任意位置后，释放

        SKILL_STATE.Targeted_Indicate:
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
            unit.current_global_skill_state = 1

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


        SKILL_STATE.Building_Indicate:
            slot.icon_texture.material.set_shader_parameter("enable_gradient", true)

            # 技能框放大
            var tween = create_tween()
            tween.tween_property(slot, "scale", Vector2(1.2, 1.2), 0.1)

            # 单位技能范围指示
            # var range_comp = CommonUtil.get_component_by_name(unit, "RangeIndicator")
            # if range_comp:
            #     range_comp.set_radius(release_distance)

            # 单位全局技能状态处理
            unit.current_global_skill_state = 1

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
            SignalBus.building_floor_indicator_show.emit(skill_context)


            
        SKILL_STATE.Release:

            # # 前置条件检查（魔耗）
            # if _is_disabled:
            #     SOS.main.message_bar.set_message("技能无法施放，魔法不足")
            #     change_state(SKILL_STATE.Idle)
            #     return            

            # 技能释放魔法消耗
            skill_released.emit(skill_context)

            # releasing
            SystemUtil.skill_system.release(skill_context)
            
            if cooldown > -1:
                change_state(SKILL_STATE.Cool_Down)
            else:
                change_state(SKILL_STATE.Idle)



        SKILL_STATE.Cool_Down:

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

            change_state(SKILL_STATE.Idle)

            # 技能冷却完毕信号
            skill_cool_down.emit(skill_context)
            


        SKILL_STATE.Idle:
            print("skill [%s] is idle" % code)

        SKILL_STATE.Disabled:
            print("skill [%s] is Disabled" % code)            



# 专门处理 targeted 模式下，玩家选择单位的逻辑        
func _process(delta: float) -> void:
    # 监听 target mouse clicked
    if Input.is_action_pressed("click"):
        if mouse_click_check and current_state == SKILL_STATE.Targeted_Indicate:
            
            # 目标类型检查-地面
            if CommonUtil.is_flag_set(SkillMetaResource.SKILL_TARGET_TYPE.FLOOR, target_type):
                print("技能无需目标")
                # 停止监听
                mouse_click_check = false
                set_process(false)

                skill_context.target_position = SOS.main.player_controller.player_skill_target_indicator.global_position
                skill_context.target = null

                change_state(SKILL_STATE.Release)

            # 目标类型检查-某个单位
            if CommonUtil.is_flag_set(SkillMetaResource.SKILL_TARGET_TYPE.UNIT, target_type):
                var cur_unit_map = SOS.main.player_controller.cur_unit_map
                if not cur_unit_map.is_empty():

                    # 停止监听
                    mouse_click_check = false
                    set_process(false)

                    # 获取选中单位
                    var min_unit = null
                    var min_distance = INF  # 使用 INF 作为初始最小距离
                    
                    # 遍历所有单位
                    for u_key in cur_unit_map.keys():
                        var _unit = cur_unit_map.get(u_key)
                        
                        if not _unit:
                            continue

                        # 根据 skill target type 动态判断是否满足条件
                        if not _skill_target_unit_cond_matched(_unit):
                            continue

                        # 计算单位到原点的距离
                        var distance = Vector2(_unit.global_position.x, _unit.global_position.z).length()
                        
                        # 如果找到更近的单位，更新最小距离和对应的单位
                        if distance < min_distance:
                            min_distance = distance
                            min_unit = _unit
                    
                    # 此时 min_unit 就是距离原点最近的单位
                    if min_unit:
                        # 在这里处理最近的单位，比如选中它
                        print("最近的单位距离: ", min_distance)
                        print("最近的单位: ", min_unit)


                        skill_context.target_position = SOS.main.player_controller.player_skill_target_indicator.global_position
                        skill_context.target = min_unit

                        change_state(SKILL_STATE.Release)

                    else:
                        print("没有找到最近的单位")
                        SOS.main.message_bar.set_message("没有选中任何单位")

                else:
                    print("没有选中任何单位")
                    SOS.main.message_bar.set_message("没有选中任何单位")