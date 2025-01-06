class_name BuffResource extends Resource


# basic properity
@export_group("Buff Meta Steup")
@export var id: StringName
@export var code: String
@export var sort: int

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


@export var buff_script: Script
