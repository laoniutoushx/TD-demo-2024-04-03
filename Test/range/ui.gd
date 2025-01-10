extends Node2D

# 定义圆形区域的中心点和半径
var mouse_area_center : Vector2 = Vector2(400, 400)
var mouse_area_radius : float = 300.0

var last_pos := Vector2.ZERO
var current_velocity := Vector2.ZERO
var predicted_distance := 0.0

@onready var label = $Label

var cursor_default = load("res://Asserts/Images/indicator/cursor_point.png")

func _ready():
	Input.use_accumulated_input = false
	Input.set_custom_mouse_cursor(cursor_default)

	# 创建一个标签来显示信息
	if not label:
		label = Label.new()
		add_child(label)
	label.position = Vector2(10, 10)

func _input(event):
	if event is InputEventMouseMotion:
		var relative_motion = event.relative
		current_velocity = event.velocity
		var current_distance = relative_motion.length()
		var delta = get_process_delta_time()
		predicted_distance = current_velocity.length() * delta
		update_label(current_distance, predicted_distance)

func update_label(current: float, predicted: float):
	label.text = """
	当前移动距离: %.2f 像素
	预测下一帧距离: %.2f 像素
	当前速度: %.2f 像素/秒
	""" % [current, predicted, current_velocity.length()]

func _draw():
	# 绘制圆形范围
	draw_circle(mouse_area_center, mouse_area_radius, Color(0.3, 0.3, 0.3, 0.3))

	# 获取鼠标当前位置
	var current_pos = get_viewport().get_mouse_position()

	# 计算鼠标当前位置到圆心的距离
	var distance_to_center = mouse_area_center.distance_to(current_pos)

	# 如果鼠标超出了圆形范围，将其位置限制到圆形边界
	if distance_to_center > mouse_area_radius:
		var direction = (current_pos - mouse_area_center).normalized()
		var clamped_pos = mouse_area_center + direction * mouse_area_radius
		Input.warp_mouse(clamped_pos)

	# 绘制当前位置
	draw_circle(current_pos, 5, Color.WHITE)

	# 绘制预测位置
	var predicted_pos = current_pos + current_velocity.normalized() * predicted_distance
	draw_circle(predicted_pos, 3, Color.RED)

	# 绘制连接线
	draw_line(current_pos, predicted_pos, Color.YELLOW)

func _process(_delta):
	queue_redraw()  # 持续更新绘制
