extends Sprite3D

class_name HealthBar

@export var width = 78
@export var height = 10

@onready var health_bar: HealthBar2D = $SubViewport/HealthBar
@onready var sub_viewport: SubViewport = $SubViewport
@export var y_scale := 1.2	# y axis缩放比例（与目标对象 y 相比）


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	SignalBus.connect("enemy_take_damage", _on_enemy_take_damage)
	pass


func prepare(value:float) -> void:
	health_bar.under_bar.max_value = value
	health_bar.under_bar.value = value
	
	health_bar.over_bar.max_value = value
	health_bar.over_bar.value = value
	
	# BUG 当事件同时传递时，可能导致 bar 刷新值失败
	health_bar._over_bar_value = value
	health_bar._under_bar_value = value
	pass


func resize(_x: float, _y: float, w_w_scale: float):
	# 重设 subviewport container 2d 尺寸
	sub_viewport.size = Vector2i(_x, _y)
	
	# 重设 health_bar 比例（ health bar 必须设置比例，如果设置尺寸，还需要重写 progress bar 填充参数 px）
	health_bar.scale.x = w_w_scale
	health_bar.scale.y = w_w_scale
	





func get_health_bar2d_size():
	return Vector2i(width, height)


func _on_enemy_take_damage(id:int, enemy: Enemy, damage:float) -> void:
	if id == get_parent().get_instance_id():	# use id and parent id compare(约定物体实例化到其子节点）
		health_bar.update_health(damage)
	pass	
