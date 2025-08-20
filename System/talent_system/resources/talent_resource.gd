@tool
class_name TalentResource extends Resource


@export_group("Talent Meta Steup")
# meta info 
@export var id: String = UUID.v4()
@export var code: String
@export var title: String = "Unnamed Talent"
@export var desc: String
@export var icon_path: String
@export var level: int = 1
@export var level_up_gap: int = 1
@export var max_level: int = 3
@export var level_limit: int = -1	# 技能生效等级限制

# 初始化释放
@export var init_release: bool
# 自动施法
@export var auto_release: bool = false
# 冷却时间
@export var cooldown: float = 1.0
# 魔法消耗
@export var mana_cost: float = -1
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

# 技能伤害值
@export var value: float = 0.0

# 技能伤害值（动态扩展）
@export var value_ext: Dictionary = {
	
}

# 技能运行距离（方向性技能）
@export var run_distance: float = 10.0
# 技能轮次（技能施法次数，触发多少次）
@export var epoch: int = 1




# 技能内部控制变量
@export_group("Talent Inner Steup")
# 初始对象数量（skill 内部单位初始数量）
@export var init_num: int = 1
# 施法持续时间
@export var cast_duration: float = -1
# 间隔时间
@export var internal_time: float = -1
# 施法前摇
@export var start_time: float = 0.1
# 施法后摇
@export var end_time: float = 0.1
# 技能轮次（内部频次控制）
@export var wave: int = 1
# 技能投射速度 米/秒
@export var projection_speed: float = 1
# 技能触发几率（概率控制器）
@export var probability: float = 0.25

# 技能禁用检查（魔法、健康值、金钱、木材）
enum TALENT_DISABLE_CHECK{
	MANA,	
	HEALTH,
	MONEY,
	WOOD
}
@export_flags("MANA", "HEALTH", "MONEY", "WOOD") var disable_check: int = 0

# consume 消耗
# level up 
# release skill

enum TALENT_RELEASE_TYPE{
	TARGETED,	
	SELF_CAST,
	NO_TARGET,
	DIRECTION,
	CIRCLE_RANGE,
	PASSIVE
}
@export_flags("TARGETED", "SELF_CAST", "NO_TARGET", "DIRECTION", "CIRCLE_RANGE", "PASSIVE") var release_type: int = 1



enum TALENT_TARGET_TYPE_CHN{
	地面,
	单位,
	无目标,
	自己,
	友军,
	敌人
}
enum TALENT_TARGET_TYPE{
	FLOOR,
	UNIT,
	NO_TARGET,
	SELF,
	FRIEND,
	ENEMY
}
@export_flags("FLOOR", "UNIT", "NO_TARGET", "SELF", "FRIEND", "ENEMY") var target_type: int = 1	# 0: 地面, 1: 目标, 2: 无目标



enum TALENT_EFFECT_TYPE{
	DAMAGE,
	HEAL,
	BUILDING,
	BUFF,
	DEBUFF,
}
@export_flags("DAMAGE","HEAL","BUILDING","BUFF","DEBUFF") var effect_type: int = 1	# 0: 伤害, 1: 治愈, 2: 建筑，3：buff，4：debuff


# 建筑变量
@export_group("Talent Build Steup")

# Building（这两个变量没有写入 Skill.gd 当中，防止循环依赖)
@export var building_scene: PackedScene
@export var building_res: BaseUnitResource

# 建筑升级时间
@export var building_level_up_time: float = -1
# 建筑木材消耗
@export var wood_cost: float = -1
# 建筑金钱消耗
@export var money_cost: float = -1




# 其他配置
@export_group("Talent Other Steup")
# Talent Script Template( 用于 动态 处理 Talent 逻辑 )
@export var talent_script: Script

# talent buff config
@export var talent_buff_config: Array[BuffResource] = []

