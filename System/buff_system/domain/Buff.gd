class_name Buff extends BuffTpl



# Reference
var res: BuffResource   # buff 元信息

var entity: String      # 引用实例类型 Clazz  (e.g. BaseUnit/Skill/LevelComp/Item/Buff)
var prop: String        # 实例对应属性名称

var reference_instance: Variant        # 引用实例（Skill、Item、Unit）

var unit: BaseUnit
var slot: BaseSlot



# basic properity
@export_group("Buff Meta Steup")
@export var id: StringName
@export var code: String


## buff 类型（可以同时符合多个类型）
@export_flags("BUFF", "DEBUFF", "DAMAGE", "HEAL", "RESTRICT", "STATUS") var type: int

@export var title: String
@export var desc: String
@export var icon_path: String


# buff properity
# 值单位类型
var _value: float   # buff 记录的修改前的属性值
@export var value: float
@export var value_unit: BuffResource.VALUE_UNIT
@export var value_dir: int:
    set(_val_dir):
        if _val_dir == 0 :
            value_dir = 1
        else:
            value_dir = -1

@export var cooldown: float            

# What state the turret is in
enum BUFF_STATE {
	Idle,
    Cool_Down
}
var current_state: BUFF_STATE = BUFF_STATE.Idle


@export var priority: int   # 优先级
@export var exclude_level: BuffResource.EXCLUDE_LEVEL = BuffResource.EXCLUDE_LEVEL.ALL   # 排除级别（叠加方式）




# buff logic action
@export var buff_script: Script
var buff_instance: Variant


# Timer
var cool_down_timer: Timer



func _ready() -> void:
    super._ready()

    # 内部变量赋值 _value
    _value = value


    # 初始化 buff timer
    cool_down_timer = Timer.new()
    cool_down_timer.wait_time = cooldown
    cool_down_timer.one_shot = true
    add_child(cool_down_timer)


func change_state(state: BUFF_STATE) -> void:
    current_state = state
    match current_state:
        BUFF_STATE.Idle:
            if cool_down_timer:
                cool_down_timer.stop()

        BUFF_STATE.Cool_Down:            
            if cool_down_timer:
                cool_down_timer.start()


func apply(_reference: Variant) -> bool:

    if _reference and prop:

        # 添加到节点树
        _reference.add_child(self)

        # 添加 buff
        # _reference.add_child(buff_instance)

        # reference_instance 属性值修改
        var ref_val = _reference.get(prop)
        _value = ref_val


        if value_unit == BuffResource.VALUE_UNIT.PERCENT:
            if CommonUtil.is_flag_set(BuffResource.BUFF_TYPE.BUFF, type):
                ref_val += ref_val * value / 100 * value_dir

            if CommonUtil.is_flag_set(BuffResource.BUFF_TYPE.DEBUFF, type):
                ref_val -= ref_val * value / 100 * value_dir

        elif value_unit == BuffResource.VALUE_UNIT.VALUE:
            if CommonUtil.is_flag_set(BuffResource.BUFF_TYPE.BUFF, type):
                ref_val += value * value_dir

            if CommonUtil.is_flag_set(BuffResource.BUFF_TYPE.DEBUFF, type):
                ref_val -= value * value_dir


        _reference.set(prop, ref_val)
        return true

    return false

        



func remove(_reference: Variant) -> bool:

    
    # reference_instance 属性值修改
    if _reference and prop:
        var ref_val = _reference.get(prop)


        if value_unit == BuffResource.VALUE_UNIT.PERCENT:
            if CommonUtil.is_flag_set(BuffResource.BUFF_TYPE.BUFF, type):
                ref_val = ref_val / (1.0 + value / 100 * value_dir)

            if CommonUtil.is_flag_set(BuffResource.BUFF_TYPE.DEBUFF, type):
                ref_val = ref_val * (1.0 + value / 100 * value_dir)

        elif value_unit == BuffResource.VALUE_UNIT.VALUE:
            if CommonUtil.is_flag_set(BuffResource.BUFF_TYPE.BUFF, type):
                ref_val -= value * value_dir

            if CommonUtil.is_flag_set(BuffResource.BUFF_TYPE.DEBUFF, type):
                ref_val += value * value_dir


        _reference.set(prop, ref_val)
        # 恢复为当前 buff 修改前的数值
        # _reference.set(prop, _value)

        # 删除 buff
        (_reference as Node).remove_child(self)
        return true

    return false        