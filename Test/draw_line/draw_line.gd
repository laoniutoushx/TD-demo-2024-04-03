extends Node3D


# var line_material: ShaderMaterial = load("res://Test/draw_line/draw_line.tres")

# @onready var draw_line: MeshInstance3D = $MeshInstance3D2


# func _ready() -> void:
# 	pass # Replace with function body.


# func _physics_process(delta: float) -> void:
# 	if draw_line.mesh is ImmediateMesh:
# 		draw_line.mesh.clear_surfaces()

# 	_draw_line(Vector3(0, 0, 0), Vector3(1, 10, 1))


# func _draw_line(point_a: Vector3, point_b: Vector3, color: Color = Color.RED) -> void:
# 	if point_a == point_b:
# 		return

# 	if draw_line.mesh is ImmediateMesh:
# 		draw_line.mesh.surface_begin(Mesh.PRIMITIVE_LINES, line_material)
# 		draw_line.mesh.surface_add_vertex(point_a)
# 		draw_line.mesh.surface_add_vertex(point_b)

# 		draw_line.mesh.surface_end()
# 		# draw_line.mesh.surface_set_material(0, line_material)
	




# extends Node3D

# @export var line_length: float = 10.0  # 线条的长度
# @export var line_thickness: float = 0.1  # 线条的厚度
# @export var line_color: Color = Color(1, 0, 0)  # 线条的颜色
# @export var line_segments: int = 1  # 线段的数量，用于模拟长线条
# @export var line_alpha: float = 1.0  # 线条的透明度

# var plane_mesh : PlaneMesh
# var plane_instance : MeshInstance3D

# func _ready():
# 	# 创建 PlaneMesh
# 	plane_mesh = PlaneMesh.new()
# 	plane_mesh.size = Vector2(line_length, line_thickness)  # 调整宽高使其像线条

# 	# 创建 MeshInstance3D 来显示 PlaneMesh
# 	plane_instance = MeshInstance3D.new()
# 	plane_instance.mesh = plane_mesh
# 	plane_instance.material_override = create_line_material()
	
# 	# 设置初始位置
# 	plane_instance.transform.origin = Vector3(0, 0, 0)

# 	# 将 MeshInstance3D 添加到场景
# 	add_child(plane_instance)

# # 创建自定义的线条材质
# func create_line_material() -> ShaderMaterial:
# 	var shader = Shader.new()
# 	shader.code = """
# 		shader_type spatial;

# 		uniform vec4 line_color : hint_color;
# 		uniform float line_alpha;
# 		uniform int line_segments;

# 		void fragment() {
# 			vec2 uv = FRAGCOORD.xy / vec2(100.0, 100.0);  // 假设UV坐标是从0到1的

# 			// 模拟线条效果：通过计算`uv.x`值来拉伸和控制宽度
# 			if (mod(uv.x * float(line_segments), 2.0) > 1.0) {
# 				discard;  // 丢弃不需要的片段，形成线条
# 			}

# 			// 设置颜色和透明度
# 			COLOR = line_color;
# 			COLOR.a *= line_alpha;
# 		}
# 	"""
# 	var material = ShaderMaterial.new()
# 	material.shader = shader
# 	material.set_shader_param("line_color", line_color)
# 	material.set_shader_param("line_alpha", line_alpha)
# 	material.set_shader_param("line_segments", line_segments)
# 	return material




# 在其他脚本中
@onready var lightning = $Lightning  # 假设节点名为 "Lightning"

func _ready():
    # 设置起点和终点
    lightning.start_point = Vector3(0, 0, 0)
    lightning.end_point = Vector3(0, 5, 5)
    lightning.generate_lightning()

# 动态更新闪电位置
func update_lightning(new_start: Vector3, new_end: Vector3):
    lightning.start_point = new_start
    lightning.end_point = new_end
    lightning.generate_lightning()