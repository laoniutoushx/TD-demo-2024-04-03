class_name UnitSlotIndicator extends BaseSlotIndicator


@onready var title: Label = %Title
@onready var level: Label = %Level

@onready var mana_cost: Label = %ManaCost
@onready var money_cost: Label = %MoneyCost
@onready var wood_cost: Label = %WoodCost

@onready var desc: RichTextLabel = %Desc

@onready var element_phase: Label = %ElementPhase
@onready var damage: Label = %Damage
@onready var attack_range: Label = %AttackRange
@onready var target_type: Label = %TargetType
@onready var attack_num: Label = %AttackNum


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	super._ready()	


func refresh_slot_indicator_info(_slot: BaseSlot) -> void:
	if not _slot.reference:
		return 

	if _slot.reference is BaseUnit:
		_slot_info(_slot)


# 依据 base_slot 显示对应提示信息（数据驱动）
func _slot_info(_slot: BaseSlot) -> void:
	var unit = _slot.reference as BaseUnit

	# Meta
	if unit.title:
		title.text = str(unit.title)
	else:
		title.visible = false

	if unit.level:
		level.text = "等级 %s" % [str(unit.level)]
	else:
		level.visible = false

	if unit.desc:
		desc.text = str(unit.desc)
	else:
		desc.visible = false
	

	# Cost
	if unit.mana_cost:
		mana_cost.text = "魔法消耗： %s" % str(unit.mana_cost)
	else:
		mana_cost.visible = false

	if unit.money_cost:
		money_cost.text = "金钱： %s" % str(unit.money_cost)
	else:
		money_cost.visible = false

	if unit.wood_cost:
		wood_cost.text = "木材： %s" % str(unit.wood_cost)
	else:
		wood_cost.visible = false


	# Functional
	if unit.element_phase:
		var element_phase_str = CommonUtil.bit_set_to_str(unit.element_phase, BaseUnitResource.ELEMENT_PHASE_STR, ' | ')
		element_phase.text = "五行： %s" % str(element_phase_str)
	else:
		element_phase.visible = false

	if unit.value:
		damage.text = "伤害： %s" % str(unit.value)
	else:
		damage.visible = false

	if unit.attack_num:
		attack_num.text = "数量： %s" % str(unit.attack_num)
	else:
		attack_num.visible = false

	if unit.attack_range:
		attack_range.text = "范围： %s m" % str(unit.attack_range)
	else:
		attack_range.visible = false

	# if unit.target_type:
	# 	var target_type_str = CommonUtil.bit_set_to_str(unit.target_type, SkillMetaResource.SKILL_TARGET_TYPE_CHN)
	# 	target_type.text = "目标类型： %s" % str(target_type_str)
	# else:
	# 	target_type.visible = false

