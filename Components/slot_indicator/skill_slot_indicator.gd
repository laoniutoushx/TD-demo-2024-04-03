class_name SkillSlotIndicator extends BaseSlotIndicator


@onready var title: Label = %Title
@onready var level: Label = %Level

@onready var mana_cost: Label = %ManaCost
@onready var money_cost: Label = %MoneyCost
@onready var wood_cost: Label = %WoodCost

@onready var desc: RichTextLabel = %Desc

@onready var damage: Label = %Damage
@onready var damage_range: Label = %DamageRange
@onready var duration: Label = %Duration
@onready var wave: Label = %Wave
@onready var target_type: Label = %TargetType
@onready var init_num: Label = %InitNum


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	super._ready()	


func refresh_slot_indicator_info(_slot: BaseSlot) -> void:
	if not _slot.reference:
		return 

	if _slot.reference is Skill:
		_slot_info(_slot)


# 依据 base_slot 显示对应提示信息（数据驱动）
func _slot_info(_slot: BaseSlot) -> void:
	var skill = _slot.reference as Skill
	var level_comp: LevelComp = CommonUtil.get_component_by_name(skill, "LevelComp")


	# Meta
	if skill.title:
		title.text = str(skill.title)
	else:
		title.visible = false

	if level_comp and level_comp.level:
		level.text = "等级 %s" % [str(level_comp.level)]
	else:
		level.visible = false

	if skill.desc:
		desc.text = str(skill.desc)
	else:
		desc.visible = false
	

	# Cost
	if skill.mana_cost:
		mana_cost.text = "魔法消耗： %s" % str(skill.mana_cost)
	else:
		mana_cost.visible = false

	if skill.money_cost:
		money_cost.text = "金钱： %s" % str(skill.money_cost)
	else:
		money_cost.visible = false

	if skill.wood_cost:
		wood_cost.text = "木材： %s" % str(skill.wood_cost)
	else:
		wood_cost.visible = false


	# Functional
	if skill.value:
		damage.text = "伤害： %s" % str(skill.value)
	else:
		damage.visible = false

	if skill.init_num:
		init_num.text = "数量： %s" % str(skill.init_num)
	else:
		init_num.visible = false

	if skill.range:
		damage_range.text = "伤害范围： %s m" % str(skill.range)
	else:
		damage_range.visible = false

	if skill.target_type:
		var target_type_str = CommonUtil.bit_set_to_str(skill.target_type, SkillMetaResource.SKILL_TARGET_TYPE_CHN)
		target_type.text = "目标类型： %s" % str(target_type_str)
	else:
		target_type.visible = false

	if skill.wave:
		wave.text = "轮次： %s" % str(skill.wave)
	else:
		wave.visible = false
	
	if skill.internal_time > -1:
		duration.text = "持续时间： %s s" % str(skill.internal_time * skill.wave)
	else:
		duration.visible = false
