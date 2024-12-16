extends Node
class_name DamageSystem

var _tick := 0.0

func _ready() -> void:
	SystemUtil.damage_system = self


func action(source: BaseUnit, target:BaseUnit):
	var cur_tick = _tick
	# 1. AnimationPlayer => 动画回复点
	animation_action(source, target)
	await _tick - cur_tick >= 0.01
	
	# 1. 弹幕系统（源、目标
	(SystemUtil.barrage_system as BarrageSystem).action(source, target)

	

	
	# 
	
	
	
	pass

func animation_action(source: BaseUnit, target:BaseUnit):
	var ap: AnimationPlayer = source.find_child("AnimationPlayer")
	if ap != null:
		ap.play("attack")



func _process(delta: float) -> void:
	_tick += delta



func skill_damage(skill: Skill, source: BaseUnit, target:BaseUnit):
	print(skill.value)
	target.take_damage(skill.value)
