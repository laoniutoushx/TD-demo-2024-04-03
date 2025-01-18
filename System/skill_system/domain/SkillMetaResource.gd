class_name SkillMetaResource extends Resource

#数据驱动: 将技能数据存储在外部文件（如 JSON, YAML），方便修改和扩展。
#事件系统: 使用 Godot 的信号机制，将技能效果与其他系统（如 UI、动画）解耦。
#组件系统: 将技能效果拆分成多个组件，方便组合和复用。
#状态机: 使用状态机管理技能的各个阶段（施法、生效、冷却等）。
#节点树: 利用 Godot 的节点树，创建复杂的技能效果。

# SKILL_RELEASE_TYPE
#1. 指向性技能
#单体指向: 需要选择一个特定目标进行施放。
#区域指向: 选择一个地面位置，技能在该区域生效。
#2. 自身释放技能
#自我增益: 增加自身属性，如护盾、加速等。
#范围效果: 以自身为中心的范围效果，影响周围单位。
#3. 无目标技能
#全局效果: 影响整个战场或特定条件下的所有单位。
#持续性效果: 在特定时间内持续生效，不依赖于目标。
#4. 方向性技能
#直线技能: 沿着一个方向生效，影响路径上的所有单位。
#扇形技能: 以一个角度扇形区域生效，影响该区域内的单位。
#5. 范围释放技能
#范围技能: 以目标点为中心的范围生效，影响周围单位。




@export_group("Skill Meta Steup")
# meta info 
@export var code: String
@export var title: String = "Unnamed Skill"
@export var desc: String
@export var icon_path: String
@export var level: int = 1
@export var level_up_gap: int = 1
@export var max_level: int = 3

# 自动施法
@export var auto_release: bool = false
# 冷却时间
@export var cooldown: float = 1.0
# 魔法消耗
@export var mana_cost: float = -1
# 木材消耗
@export var wood_cost: float = -1
# 金钱消耗
@export var money_cost: float = -1
# 技能伤害范围
@export var damage_range: float = 5.0
# 技能匹配目标对象范围
@export var match_range: float = 30.0
# 技能影响（释放）范围
@export var range: float = 5.0
# 释放距离
@export var release_distance: float = 10.0
# 技能点数（使用次数）
@export var stock: int  = -1
# 值
@export var value: float


# 技能内部控制变量
@export_group("Skill Inner Steup")
# 初始对象数量（skill 内部单位初始数量）
@export var init_num: int = 1
# 间隔时间
@export var internal_time: float = -1
# 施法前摇
@export var start_time: float = 0.1
# 施法后摇
@export var end_time: float = 0.1
# 技能轮次
@export var wave: int = 1


# consume 消耗
# level up 
# release skill

enum SKILL_RELEASE_TYPE{
	TARGETED,	
	SELF_CAST,
	NO_TARGET,
	DIRECTION,
	CIRCLE_RANGE
}
@export_flags("TARGETED", "SELF_CAST", "NO_TARGET", "DIRECTION", "CIRCLE_RANGE") var release_type: int = 1



enum SKILL_TARGET_TYPE_CHN{
	地面,
	单位,
	无目标,
	友军,
	敌人
}
enum SKILL_TARGET_TYPE{
	FLOOR,
	UNIT,
	NO_TARGET,
	FRIEND,
	ENEMY
}
@export_flags("FLOOR", "UNIT", "NO_TARGET", "FRIEND", "ENEMY") var target_type: int = 1	# 0: 地面, 1: 目标, 2: 无目标



enum SKILL_EFFECT_TYPE{
	DAMAGE,
	HEAL,
	BUILDING,
	BUFF,
	DEBUFF,
}
@export_flags("DAMAGE","HEAL","BUILDING","BUFF","DEBUFF") var effect_type: int = 1	# 0: 伤害, 1: 治愈, 2: 建筑，3：buff，4：debuff



# Skill Script Template( ClassDB )
@export var skill_script: Script


# Building
@export var building_scene: PackedScene
@export var building_res: BaseUnitResource


# skill level config
@export var skill_level_config: Array[SkillMetaResource] = []

# skill buff config
@export var skill_buff_config: Array[BuffResource] = []