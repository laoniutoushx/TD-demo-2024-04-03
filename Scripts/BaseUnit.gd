# BaseUnit.gd
extends Node

# base unit
class_name BaseUnit


# player meta into
@export_flags("P1", "P2", "P3", "P4") var player_owner_idx: int = 0


# define how unit move on mesh ground
@export_flags("WALK", "FLYING", "SWIM") var unit_move_type: int = 0
# define unit category
@export_flags("HUMAN", "BUILDING", "DECORATE_DESTORIED", "DECORATE_FOREVER") var unit_cate = 0


var health : float
@export var max_health : float
@export var move_speed : float
@export var turn_speed : float

func _ready() -> void:
	health = max_health


# unit death effect
func death_effect():
	pass

# is dead
func is_dead() -> bool:
	return health <= 0

# damage unit
func take_damage(damage: float):
	health -= damage
	if is_dead():
		death_effect()

# heal unit health
func heal(amount: int):
	health = min(health + amount, max_health)


