class_name BaseUnitResource
extends Resource

# unit category
enum UnitCate {
	HUMAN,
	BUILDING,
	DECORATE_DESTORIED,
	DECORATE_FOREVER
}

# unit move type
enum UnitMoveType {
	FLYING,
	WALKING,
	SWIMMING
}

@export var clz_code: String
@export var clz_name: String
@export var cate: Array[UnitCate]
@export var move_type: Array[UnitMoveType]
