class_name DamageCtx extends RefCounted


enum DamageType {
    NORMAL,  # 普通伤害
    CRITICAL,  # 暴击伤害
    HEAL,  # 治疗效果
    MISS,  # 闪避
    BUFF,  # 增益效果
    DEBUFF  # 减益效果
}

# 伤害来源类型
enum DamageSourceType {
    UNIT,   # 单位
    SKILL   # 技能
}

var damage: float = 0.0
var damage_type: DamageType = DamageType.NORMAL
var damage_source_type: DamageSourceType = DamageSourceType.UNIT
var source: BaseUnit
var target: BaseUnit

func _init(_source: BaseUnit, _target: BaseUnit, _damage: float, _damage_type: DamageType = DamageCtx.DamageType.NORMAL, _damage_source: DamageSourceType = DamageSourceType.UNIT) -> void:
    self.source = _source
    self.target = _target
    self.damage = _damage
    self.damage_type = _damage_type
    self.damage_source_type = _damage_source