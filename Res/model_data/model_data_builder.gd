extends Resource
class_name ModelData

@export_group("Model Info")

@export var name : String = ""
@export_file var scene_path : String = ""
var scene : PackedScene
@export var vignette : Texture			# 图标
@export var y_offset = 0.0				# y 偏移
@export var scale_compensation = 1.0	# 缩放补偿

@export_group("Projectile Info")
@export var projectile_scene : PackedScene
@export var projectile_speed : float
@export var projectile_arc : float	# 弧度


@export_group("Priority Info")
@export var move_speed : float
@export var turn_speed : float  
@export var attack_speed : float  
