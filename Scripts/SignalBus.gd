extends Node

# Global Signal Scripts
# Signal Instance, Shared by all instance

# Level
signal next_level(code:String)	# scene code


# Unit event
signal unit_logic_death(id:int, unit :BaseUnit)
signal unit_physic_death(id:int, unit :BaseUnit)
signal unit_take_damage(id:int, unit :BaseUnit, damage: float)



# RayPicker

# Class TurretManager - Paramaters [ Collider, Ray_Cast, GridMap ]
# Class PlayerController - Paramaters [ Camera, viewport ]
signal ray_picker_regist(callable: Callable)
signal ray_picker_unregist(callable: Callable)


# PlayerController
signal player_selected_units(unit_map: Dictionary, mouse_pos: Vector3)		# unit selected
