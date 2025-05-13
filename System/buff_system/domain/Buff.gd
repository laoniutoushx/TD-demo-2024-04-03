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

var _value_dir: int # buff 记录的属性值方向（原始位 0 和 1， 这里映射为 0 => 1, 1 => -1 ，方便计算正负数）
@export var value_dir: int:
    set(value):
        value_dir = value
        if value_dir == 0:
            _value_dir = 1
        else:
            _value_dir = -1
        


@export var cooldown: float     
@export var max_overlay_num: int    

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


# Inner Variable
var buff_instance: Variant
var cool_down_timer: CommonUtil.Cimer
var __buff_stack_num: int = 0     # buff 创建次数（程序内部调用）

var prop_value_delta: float = 0.0   # buff 属性值变化量（buff 叠加时，属性值变化量）

## TODO
var _prob_controller: ProbabilityController = null


func init(skill: Skill) -> void:
    # 初始化独立概率控制器
    _prob_controller = ProbabilityController.new(skill.value_ext.get("critical_chance"))


func _ready() -> void:
    super._ready()

    # 内部变量赋值 _value
    _value = value

    # 当冷却时间大于 -1 ，表示当前 buff 需要开启倒计时
    if cooldown > 0:
        # 初始化 buff timer
        cool_down_timer = CommonUtil.create_timer(cooldown)
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
    # buff exclude level 检查
    if not is_fit_exclude_level(self, _reference):
        print("buff code %s exclude level %s" % [self.code, self.exclude_level])
        return false 

    # 引用单位存在
    if _reference: 
        reference_instance = _reference

        # 添加到节点树
        _reference.add_child(self)

        # 属性修改
        if prop:
            # 添加 buff
            # _reference.add_child(buff_instance)

            # reference_instance 属性值修改
            var ref_val = _reference.get(prop)
            _value = ref_val


            if value_unit == BuffResource.VALUE_UNIT.PERCENT:
                prop_value_delta = ref_val * value / 100 * _value_dir
                ref_val += prop_value_delta


            elif value_unit == BuffResource.VALUE_UNIT.VALUE:
                prop_value_delta = value * _value_dir
                ref_val += prop_value_delta



            _reference.set(prop, ref_val)

            # print("REF_VAL %s" % ref_val)

        return true
    
    return false

        



func remove(_reference: Variant) -> bool:

    
    # reference_instance 属性值修改
    if _reference:

        if prop:
            var ref_val = _reference.get(prop)


            if value_unit == BuffResource.VALUE_UNIT.PERCENT:
                # ref_val -= ref_val / (1.0 + value / 100 * _value_dir)
                ref_val -= prop_value_delta


            elif value_unit == BuffResource.VALUE_UNIT.VALUE:
                # ref_val -= value * _value_dir
                ref_val -= prop_value_delta



            _reference.set(prop, ref_val)
            # 恢复为当前 buff 修改前的数值
            # _reference.set(prop, _value)

            # 删除 buff
            (_reference as Node).remove_child(self)

            # print("REF_VAL %s" % ref_val)

        return true

    return false        



# 判断排除等级
func is_fit_exclude_level(_buff: Buff, _reference: Variant) -> bool:
    # 
    if _buff.exclude_level == BuffResource.EXCLUDE_LEVEL.ALL:
        return true

    if _buff.exclude_level == BuffResource.EXCLUDE_LEVEL.TYPE:
        # 获取已有第一个 buff
        if _reference.buff_map.size() == 0:
            return true

        var bm: Buff = _reference.buff_map.values()[0]
        if CommonUtil.has_overlapping_flags(_buff.type, bm.type):
            return true	
        else: 
            return false

    if _buff.exclude_level == BuffResource.EXCLUDE_LEVEL.SELF:
        for bm: Buff in _reference.buff_map.values():
            if bm.code != _buff.code:
                return false
        return true
    
    if _buff.exclude_level == BuffResource.EXCLUDE_LEVEL.NONE:
        return _reference.buff_map.size() == 0

    return true