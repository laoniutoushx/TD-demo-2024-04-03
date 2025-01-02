extends Control


@onready var panel: PanelContainer = $PanelContainer

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



# slot_indicator 下边界 与 slot 中心点的距离
@export var keep_bottom_margin: int = 0
var cur_slot: BaseSlot


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	hide()
	print("indicator size: %s" % panel.size)

# 依据 base_slot 显示对应提示信息（数据驱动）
func show_toggle(_slot: BaseSlot) -> void:
	cur_slot = _slot
	# Data Driven
	refresh_slot_indicator_info(_slot)
	defer_show(_slot)


func defer_show(_slot: BaseSlot) -> void:
	if is_visible():
		hide()
	else:
		_on_panel_container_resized()
		show()

# 刷新位置
func _on_panel_container_resized() -> void:
	if cur_slot:
		var border_limit_y: int = cur_slot.global_position.y  - keep_bottom_margin
			
		# location slot indicator 
		var slot_pos: Vector2 = cur_slot.global_position
		print("slot pos: %s" % slot_pos)
		var slot_size: Vector2 = cur_slot.size
		print("slot slot_size: %s" % slot_size)
		var indicator_size: Vector2 = panel.size
		print("indicator size: %s" % indicator_size)

		# var indicator_pos: Vector2 = slot_pos + (slot_size / 2) - Vector2(0, (indicator_size.y / 2))
		var indicator_pos: Vector2 = Vector2(slot_pos.x + slot_size.x / 2, border_limit_y - (indicator_size.y / 2))
		self.global_position = indicator_pos


func refresh_slot_indicator_info(_slot: BaseSlot) -> void:
	if not _slot.reference:
		return 

	if _slot.reference is Skill:
		var skill = _slot.reference as Skill

		# Meta
		if skill.title:
			title.text = str(skill.title)
		else:
			title.visible = false

		if skill.level:
			level.text = "等级 %s" % [str(skill.level)]
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



	pass
