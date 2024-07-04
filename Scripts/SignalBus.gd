extends Node

# Global Signal Scripts
# Signal Instance, Shared by all instance

signal enemy_death(enemy :Enemy)
signal enemy_take_damage(id:int, enemy :Enemy, damage: float)
