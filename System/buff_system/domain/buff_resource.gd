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
enum BUFF_TYPE{
    BUFF,
    DEBUFF,
    DAMAGE,
    HEAL,
    RESTRICT,
    STATUS,
}
@export_flags("BUFF", "DEBUFF", "DAMAGE", "HEAL", "RESTRICT", "STATUS") var type: int

@export var title: String
@export var desc: String
@export var icon_path: String


# buff properity
# 值单位类型
enum VALUE_UNIT {
    PERCENT,
    VALUE
}
enum VALUE_DIR {
    POSITIVE,
    NEGATIVE
}
@export var value: float = 0.0
@export var value_unit: VALUE_UNIT
@export var value_dir: VALUE_DIR = VALUE_DIR.POSITIVE

@export var cooldown: float = -1.0

@export var max_overlay_num: int = 1





@export var priority: int   # 优先级

enum EXCLUDE_LEVEL {
    NONE,       # 无（允许任意BUFF叠加）
    SELF,       # 自己（自己不可叠加）
    TYPE,       # 同类BUFF（同类不可叠加）
    ALL,        # 任意BUFF（不可和任何BUFF叠加）
}
@export var exclude_level: EXCLUDE_LEVEL = EXCLUDE_LEVEL.ALL   # 排除级别（叠加方式）




@export var buff_script: Script



