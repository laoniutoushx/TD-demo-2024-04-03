class_name TalentContext


var talent: Talent
var target: BaseUnit
var source: BaseUnit
var target_position: Vector3

# 技能范围定义回调
var skill_scope_delegate: Callable


# building about
# var building_origin_pos: Vector3
var building: BaseUnit
var callback: Callable


func _init(talent: Talent, target: BaseUnit, source: BaseUnit, position: Vector3) -> void:
    # @export var target_type: SkillMetaResource.SKILL_RELEASE_TYPE	# 0: 地面, 1: 目标, 2: 无目标

    self.source = source
    self.talent = talent
    self.target_position = position
    self.target = target
