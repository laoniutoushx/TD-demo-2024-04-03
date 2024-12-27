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
# 		draw_line.mesh.surface_begin(Mesh.PRIMITIVE_LINES)
# 		draw_line.mesh.surface_add_vertex(point_a)
# 		draw_line.mesh.surface_add_vertex(point_b)

# 		draw_line.mesh.surface_end()
# 		# draw_line.mesh.surface_set_material(0, line_material)
	


