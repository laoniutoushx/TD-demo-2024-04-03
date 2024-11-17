class_name SkillContext

var skill: Skill
var target: BaseUnit
var source: BaseUnit
var position: Vector3

# 技能范围定义回调
var skill_scope_delegate: Callable


func _init(skill: Skill, target: BaseUnit, source: BaseUnit, position: Vector3) -> void:
    # @export var target_type: SkillMetaResource.SKILL_RELEASE_TYPE	# 0: 地面, 1: 目标, 2: 无目标
    var target_type = skill.target_type
    var release_type = skill.release_type
    source = source
    skill = skill
    position = position
    target = target
