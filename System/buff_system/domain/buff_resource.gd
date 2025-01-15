@tool
class_name BuffResource extends Resource



# basic properity
@export_group("Buff Meta Steup")
@export var id: StringName
@export var code: String


# Meta Reference
enum ENTITY{
    BaseUnit,
    Skill,
    Item,
}
@export var entity: String      # 引用实例  (e.g. BaseUnit/Skill/LevelComp/Item/Buff class_name)
@export var prop: String       # 实例对应属性名称（ var name ）

@export var property_selector: PropertySelectorResource


## buff 类型（可以同时符合多个类型）
@export_flags("BUFF", "DEBUFF", "DAMAGE", "HEAL", "RESTRICT", "STATUS") var type

@export var title: String
@export var desc: String
@export var icon_path: String


# buff properity
# 值单位类型
enum VALUE_UNIT {
    PERCENT,
    VALUE
}

@export var value: float
@export var value_unit: VALUE_UNIT



@export var priority: int   # 优先级

enum EXCLUDE_LEVEL {
    NONE,       # 无（不允许任何叠加）
    SELF,       # 自己（允许自己叠加）
    TYPE,       # 同类BUFF（允许同类BUFF叠加）
    ALL,        # 任意BUFF（允许任意BUFF叠加）
}
@export var exclude_level: EXCLUDE_LEVEL = EXCLUDE_LEVEL.ALL   # 排除级别（叠加方式）




@export var buff_script: Script
