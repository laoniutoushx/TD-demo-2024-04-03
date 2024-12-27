extends MeshInstance3D




# func _ready():

# 	var line_material: ShaderMaterial = load("res://Test/draw_line/draw_line.tres")

# 	# Begin draw.
# 	mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES)

# 	# Prepare attributes for add_vertex.
# 	mesh.surface_set_normal(Vector3(0, 0, 1))
# 	mesh.surface_set_uv(Vector2(0, 0))
# 	# Call last for each vertex, adds the above attributes.
# 	mesh.surface_add_vertex(Vector3(-1, -1, 0))

# 	mesh.surface_set_normal(Vector3(0, 0, 1))
# 	mesh.surface_set_uv(Vector2(0, 1))
# 	mesh.surface_add_vertex(Vector3(-1, 1, 0))

# 	mesh.surface_set_normal(Vector3(0, 0, 1))
# 	mesh.surface_set_uv(Vector2(1, 1))
# 	mesh.surface_add_vertex(Vector3(1, 1, 0))

# 	mesh.surface_set_material(0, line_material)
# 	mesh.surface_set_material(1, line_material)

# 	# End drawing.
# 	mesh.surface_end()



# func _process(delta):

# 	# Clean up before drawing.
# 	mesh.clear_surfaces()

# 	# Begin draw.
# 	mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES)

# 	# Draw mesh.

# 	# End drawing.
# 	mesh.surface_end()	
