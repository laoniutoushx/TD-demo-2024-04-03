extends Node3D

# 闪电参数
var start_point: Vector3
var end_point: Vector3
var segments = 12 # 闪电段数
var displacement = 1.0 # 闪电弯曲程度
var thickness = 0.1 # 闪电粗细
var lifetime = 0.2 # 闪电持续时间
var color = Color(0.5, 0.7, 1.0, 1.0) # 闪电颜色

var points: Array[Vector3] = []
var mesh_instance: MeshInstance3D
var time_alive = 0.0


@export var use_custom_material: bool
@export var lightning_material: Material


func _ready():
	mesh_instance = MeshInstance3D.new()
	add_child(mesh_instance)

	if use_custom_material:
		if lightning_material:
			mesh_instance.material_override = lightning_material
		else:
			push_warning("Custom material is not assigned.")
	else:
		create_default_material()

func create_default_material():
	# 创建闪电材质
	var material = StandardMaterial3D.new()
	material.emission_enabled = true
	material.emission = color
	material.emission_energy = 5.0
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.vertex_color_use_as_albedo = true
	material.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	mesh_instance.material_override = material


func generate_lightning():
	points.clear()
	points.append(start_point)
	
	# 生成中间点
	var segment_length = start_point.distance_to(end_point) / segments
	var direction = (end_point - start_point).normalized()
	
	# 创建一个垂直于主方向的基准向量
	var up = Vector3.UP
	if direction.dot(up) > 0.9:
		up = Vector3.RIGHT
	
	var perpendicular1 = direction.cross(up).normalized()
	var perpendicular2 = direction.cross(perpendicular1).normalized()
	
	for i in range(1, segments):
		var segment_point = start_point + direction * (segment_length * i)
		
		# 在两个垂直方向上添加随机偏移
		var offset = (perpendicular1 * (randf() * 2 - 1) +
					 perpendicular2 * (randf() * 2 - 1)) * displacement
		points.append(segment_point + offset)
	
	points.append(end_point)
	time_alive = 0
	update_mesh()

func update_mesh():
	if points.size() < 2:
		return
		
	var mesh = ImmediateMesh.new()
	mesh_instance.mesh = mesh
	
	mesh.clear_surfaces()
	mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLE_STRIP)
	
	# 为每个段生成三角形带
	for i in range(points.size() - 1):
		var current = points[i]
		var next = points[i + 1]
		var direction = (next - current).normalized()
		
		# 创建垂直于方向的向量
		var camera = get_viewport().get_camera_3d()
		var cam_pos = camera.global_position
		var to_camera = (cam_pos - current).normalized()
		var side_vector = direction.cross(to_camera).normalized() * thickness
		
		# 创建三角形带的顶点
		mesh.surface_set_color(color)
		mesh.surface_add_vertex(current + side_vector)
		mesh.surface_add_vertex(current - side_vector)
		
		if i == points.size() - 2:
			mesh.surface_set_color(color)
			mesh.surface_add_vertex(next + side_vector)
			mesh.surface_add_vertex(next - side_vector)
	
	mesh.surface_end()

func _process(delta):
	time_alive += delta
	if time_alive >= lifetime:
		generate_lightning()
	
	# 更新mesh以始终面向摄像机
	update_mesh()
