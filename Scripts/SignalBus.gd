extends Node

# Global Signal Scripts
# Signal Instance, Shared by all instance

# Level
signal next_level(code:String)	# scene code


## Unit event
signal unit_logic_death(id:int, unit :BaseUnit)
signal unit_physic_death(id:int, unit :BaseUnit)
signal unit_take_damage(id:int, unit :BaseUnit, damage: float)





# RayPicker

# Class TurretManager - Paramaters [ Collider, Ray_Cast, GridMap ]
# Class PlayerController - Paramaters [ Camera, viewport ]
signal ray_picker_regist(callable: Callable)
signal ray_picker_unregist(callable: Callable)


# PlayerController
signal player_selected_units(unit_map: Dictionary, mouse_pos: Vector3, on_selected_player_status: PlayerController.PLAYER_STATUS)		# unit selected


# Skill
signal building_floor_indicator_show(skill_context: SkillContext)   # 建筑技能指示事件
signal building_floor_indicator_hide(skill_context: SkillContext)   # 建筑技能指示事件

signal skill_auto_release(is_auto_release: bool, skill_context: SkillContext)

signal skill_level_up(skill_context: SkillContext)   # 技能升级开始



# Buff
signal buff_enter(buff: Buff, _ref: Variant)   # buff 新增
signal buff_exit(buff: Buff, _ref: Variant)    # buff 删除
signal buff_cooldown_extend(buff: Buff, _ref: Variant)    # buff 删除