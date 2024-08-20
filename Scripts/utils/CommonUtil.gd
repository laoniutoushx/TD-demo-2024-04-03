class_name CommonUtil
extends Node

# get main scene tree
static func await_get_root_node() -> Node:
	if Engine.get_main_loop().root.is_inside_tree():
		Constants.ROOT_NODE = Engine.get_main_loop().root
	else:
		while Constants.GLB_TICKET > 2.0:
			return await_get_root_node()
	return Constants.ROOT_NODE


static func await_timer(second):
	if second is float or second is int:
		second = float(second)
		if second > 0:
			var timer = Timer.new()
			timer.one_shot = true
			var root = await_get_root_node()
			root.add_child(timer)
			timer.start(second)
			await timer.timeout
			root.remove_child(timer)
			timer.queue_free()

func _process(delta: float) -> void:
	Constants.GLB_TICKET += delta


static func get_all_mesh_instances(node: Node) -> Array[MeshInstance3D]:
	var mesh_instances = []
	if node is MeshInstance3D:
		mesh_instances.append(node)
	for child in node.get_children():
		mesh_instances += get_all_mesh_instances(child)
	return mesh_instances
	

static func get_first_mesh_instances(node: Node) -> MeshInstance3D:
	var mesh_instance
	if node is MeshInstance3D:
		mesh_instance = node
		return mesh_instance
	for child in node.get_children():
		mesh_instance = get_all_mesh_instances(child)
	return mesh_instance
		

static func create_outline_mesh(mesh_instance: MeshInstance3D, outline_width: float = 0.05) -> ArrayMesh:
	var original_mesh = mesh_instance.mesh
	var st = SurfaceTool.new()
	st.create_from(original_mesh, 0)
	
	var arrays = st.commit_to_arrays()
	var vertices = arrays[Mesh.ARRAY_VERTEX]
	var normals = arrays[Mesh.ARRAY_NORMAL]
	
	for i in range(vertices.size()):
		vertices[i] += normals[i] * outline_width
	
	arrays[Mesh.ARRAY_VERTEX] = vertices
	
	var outline_mesh = ArrayMesh.new()
	outline_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	
	return outline_mesh
