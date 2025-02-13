extends Node3D


# @onready var cow: MeshInstance3D = %Cow
@onready var cow: MeshInstance3D = %Pug

@onready var aabb_box: MeshInstance3D = %AABBBox


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	print(cow.mesh.get_aabb().size)
	print(cow.transform.basis)
	print(cow.owner.transform.basis)
	print(cow.get_global_transform().basis)
	print(cow.owner.get_global_transform().basis)




	aabb_box.global_position = cow.mesh.get_aabb().get_center()

	var global_scale = get_global_scale(cow)
	print(global_scale)

	# print(aabb_box.mesh.size * global_scale)
	print(aabb_box.mesh.size) 
	# aabb_box.mesh.size = cow.mesh.get_aabb().size
	print(aabb_box.mesh.size)
	# aabb_box.mesh.size = get_global_aabb(cow.mesh, cow.global_transform).size
	aabb_box.mesh.size = get_transformed_aabb(cow).size
	print(get_global_aabb(cow.mesh, cow.global_transform))
	print(get_scaled_aabb(cow))
	print(get_transformed_aabb(cow))

	print("---------")



# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass



func get_global_scale(mesh_instance: MeshInstance3D) -> Vector3:
	# 获取全局变换矩阵
	var global_transform: Transform3D = mesh_instance.global_transform

	# 从变换矩阵中提取缩放向量
	# 方法一：使用 basis_x, basis_y, basis_z 的长度
	var scale_x = global_transform.basis.x.length()
	var scale_y = global_transform.basis.y.length()
	var scale_z = global_transform.basis.z.length()
	return Vector3(scale_x, scale_y, scale_z)



func get_global_aabb(obj_mesh: Mesh, obj_global_transform: Transform3D) -> AABB:
	# save the global position
	var global_position: Vector3 = obj_global_transform.origin

	obj_global_transform.origin = Vector3.ZERO

	# Get Mesh Vertices
	var mesh_points: SurfaceTool = SurfaceTool.new()
	mesh_points.create_from(obj_mesh, 0)
	var mesh_points_array: Array = mesh_points.commit_to_arrays()
	var vertices: Array = mesh_points_array[ArrayMesh.ARRAY_VERTEX]

	# Apply transform and set vertex to form AABB
	var start:Vector3 = Vector3.ZERO
	var end:Vector3 = Vector3.ZERO
	for point: Vector3 in (vertices as Array[Vector3]):
		point = obj_global_transform * point

		if point.x > start.x : start.x = point.x
		if point.x < end.x: end.x = point.x

		if point.y > start.y : start.y = point.y
		if point.y < end.y: end.y = point.y

		if point.z > start.z : start.z = point.z
		if point.z < end.z: end.z = point.z

	var new_aabb:AABB = AABB(start, -(end-start))
	new_aabb.position = new_aabb.position + global_position - (new_aabb.size)


	return new_aabb


static func get_scaled_aabb(mesh_instance: MeshInstance3D) -> AABB:

	var aabb: AABB = mesh_instance.mesh.get_aabb()
	var scale = mesh_instance.global_transform.basis.get_scale()
	var scaled_aabb = aabb.expand(aabb.size * (scale - Vector3.ONE)) # Adjust for scaling
	# var scaled_aabb = aabb.grow(mesh_instance.global_transform.basis.get_scale())

	return scaled_aabb



static func get_transformed_aabb(mesh_instance: MeshInstance3D) -> AABB:
	# 检查缓存是否有效
	# if mesh_instance._cached_global_transform == mesh_instance.global_transform:
	# 	return mesh_instance._cached_global_aabb
		
	var local_aabb := mesh_instance.mesh.get_aabb()
	var corners := PackedVector3Array()
	corners.resize(8)
	
	# 获取本地AABB的8个角点
	corners[0] = local_aabb.position
	corners[1] = Vector3(local_aabb.position.x + local_aabb.size.x, local_aabb.position.y, local_aabb.position.z)
	corners[2] = Vector3(local_aabb.position.x, local_aabb.position.y + local_aabb.size.y, local_aabb.position.z)
	corners[3] = Vector3(local_aabb.position.x, local_aabb.position.y, local_aabb.position.z + local_aabb.size.z)
	corners[4] = local_aabb.position + local_aabb.size
	corners[5] = Vector3(local_aabb.position.x + local_aabb.size.x, local_aabb.position.y + local_aabb.size.y, local_aabb.position.z)
	corners[6] = Vector3(local_aabb.position.x + local_aabb.size.x, local_aabb.position.y, local_aabb.position.z + local_aabb.size.z)
	corners[7] = Vector3(local_aabb.position.x, local_aabb.position.y + local_aabb.size.y, local_aabb.position.z + local_aabb.size.z)
	
	# 转换到全局空间
	var global_transform := mesh_instance.global_transform
	var min_pos := global_transform * corners[0]
	var max_pos := min_pos
	
	for i in range(1, 8):
		var global_point := global_transform * corners[i]
		min_pos = min_pos.min(global_point)
		max_pos = max_pos.max(global_point)
	
	# 创建新的AABB并缓存
	var global_aabb := AABB(min_pos, max_pos - min_pos)
	# mesh_instance._cached_global_transform = mesh_instance.global_transform
	# mesh_instance._cached_global_aabb = global_aabb
	
	return global_aabb

# 如果只需要高度
static func get_transformed_height(mesh_instance: MeshInstance3D) -> float:
	return get_transformed_aabb(mesh_instance).size.y