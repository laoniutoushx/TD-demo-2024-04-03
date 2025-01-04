class_name ItemSlotIndicator extends BaseSlotIndicator


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

	if _slot.reference is Item:
		_slot_info(_slot)


# 依据 base_slot 显示对应提示信息（数据驱动）
func _slot_info(_slot: BaseSlot) -> void:
	var item = _slot.reference as Item

	# Meta
	if item.title:
		title.text = str(item.title)
	else:
		title.visible = false

	if item.level:
		level.text = "等级 %s" % [str(item.level)]
	else:
		level.visible = false

	if item.desc:
		desc.text = str(item.desc)
	else:
		desc.visible = false
	

	# Cost
	if item.mana_cost:
		mana_cost.text = "魔法消耗： %s" % str(item.mana_cost)
	else:
		mana_cost.visible = false

	if item.money_cost:
		money_cost.text = "金钱： %s" % str(item.money_cost)
	else:
		money_cost.visible = false

	if item.wood_cost:
		wood_cost.text = "木材： %s" % str(item.wood_cost)
	else:
		wood_cost.visible = false


	# Functional
	if item.value:
		damage.text = "伤害： %s" % str(item.value)
	else:
		damage.visible = false

	# if item.init_num:
	# 	init_num.text = "数量： %s" % str(item.init_num)
	# else:
	# 	init_num.visible = false

	# if item.range:
	# 	damage_range.text = "伤害范围： %s m" % str(item.range)
	# else:
	# 	damage_range.visible = false

	# if item.target_type:
	# 	var target_type_str = CommonUtil.bit_set_to_str(item.target_type, SkillMetaResource.SKILL_TARGET_TYPE_CHN)
	# 	target_type.text = "目标类型： %s" % str(target_type_str)
	# else:
	# 	target_type.visible = false

	# if item.wave:
	# 	wave.text = "轮次： %s" % str(item.wave)
	# else:
	# 	wave.visible = false
	
	# if item.internal_time > -1:
	# 	duration.text = "持续时间： %s s" % str(item.internal_time * item.wave)
	# else:
	# 	duration.visible = false
