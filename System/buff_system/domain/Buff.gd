class_name Buff extends BuffTpl



# Reference
var res: BuffResource

var entity: String     # 引用实例  (e.g. BaseUnit/Skill/LevelComp/Item/Buff)
var prop: String        # 实例对应属性名称

var reference_instance: Variant        # 引用实例



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
@export var value: float
@export var value_unit: BuffResource.VALUE_UNIT
@export var value_dir: int:
    set(_val_dir):
        if _val_dir == 0 :
            value_dir = 1
        else:
            value_dir = -1

@export var cooldown: float            




@export var priority: int   # 优先级
@export var exclude_level: BuffResource.EXCLUDE_LEVEL = BuffResource.EXCLUDE_LEVEL.ALL   # 排除级别（叠加方式）




# buff logic action
@export var buff_script: Script
var buff_instance: Variant


# Timer
var cool_down_timer: Timer



func _ready() -> void:
    super._ready()

    # 初始化 buff timer
    cool_down_timer = Timer.new()
    cool_down_timer.wait_time = cooldown
    cool_down_timer.one_shot = true
    cool_down_timer.timeout.connect(remove)
    add_child(cool_down_timer)



func apply(_reference: Variant) -> bool:

    if reference_instance and prop:
        # 添加 buff
        reference_instance.add_child(buff_instance)

        # reference_instance 属性值修改
        var ref_val = reference_instance.get(prop)



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


        reference_instance.set(prop, ref_val)
        return true

    return false

        



func remove() -> bool:

    # reference_instance 属性值修改
    if reference_instance and prop:
        var ref_val = reference_instance.get(prop)



        if value_unit == BuffResource.VALUE_UNIT.PERCENT:
            if CommonUtil.is_flag_set(BuffResource.BUFF_TYPE.BUFF, type):
                ref_val -= ref_val * value / 100 * value_dir

            if CommonUtil.is_flag_set(BuffResource.BUFF_TYPE.DEBUFF, type):
                ref_val += ref_val * value / 100 * value_dir

        elif value_unit == BuffResource.VALUE_UNIT.VALUE:
            if CommonUtil.is_flag_set(BuffResource.BUFF_TYPE.BUFF, type):
                ref_val -= value * value_dir

            if CommonUtil.is_flag_set(BuffResource.BUFF_TYPE.DEBUFF, type):
                ref_val += value * value_dir


        reference_instance.set(prop, ref_val)

        # 删除 buff
        (reference_instance as Node).remove_child(buff_instance)
        return true

    return false        