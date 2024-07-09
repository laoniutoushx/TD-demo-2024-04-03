extends Node

# Global Signal Scripts
# Signal Instance, Shared by all instance

# Level
signal next_level(code:String)	# scene code


# Enemey
signal enemy_death(id:int, enemy :Enemy)
signal enemy_take_damage(id:int, enemy :Enemy, damage: float)
