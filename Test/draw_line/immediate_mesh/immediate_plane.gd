extends MeshInstance3D


var material = load("res://Test/draw_line/draw_line_material.tres") # 加载你的shader文件


func _ready():
    # create_rect()
    create_rectangle(10, 10)

func create_rect():
# 创建 ImmediateMesh
    var immediate_mesh = ImmediateMesh.new()
    
    # 创建 ShaderMaterial
    # var shader_material = ShaderMaterial.new()
    # var material = load("res://Test/draw_line/draw_line_standard_mat.tres") # 加载你的shader文件
    
    # shader_material.shader = shader
    
    # 设置网格
    mesh = immediate_mesh
    
    # 重要：使用 material_override 而不是直接设置 material
    material_override = material
    
    # 开始绘制
    immediate_mesh.clear_surfaces()
    # 重要：这里使用 null 作为材质参数
    immediate_mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES, null)
    
    # 定义平面的大小
    var size = 0.5
    var half_size = size / 2.0
    
    # 第一个三角形
    immediate_mesh.surface_set_normal(Vector3(0, 1, 0))
    immediate_mesh.surface_set_uv(Vector2(0, 0))
    immediate_mesh.surface_add_vertex(Vector3(-half_size, 0, -half_size))
    
    immediate_mesh.surface_set_normal(Vector3(0, 1, 0))
    immediate_mesh.surface_set_uv(Vector2(1, 0))
    immediate_mesh.surface_add_vertex(Vector3(half_size, 0, -half_size))
    
    immediate_mesh.surface_set_normal(Vector3(0, 1, 0))
    immediate_mesh.surface_set_uv(Vector2(0, 1))
    immediate_mesh.surface_add_vertex(Vector3(-half_size, 0, half_size))
    
    # 第二个三角形
    immediate_mesh.surface_set_normal(Vector3(0, 1, 0))
    immediate_mesh.surface_set_uv(Vector2(1, 0))
    immediate_mesh.surface_add_vertex(Vector3(half_size, 0, -half_size))
    
    immediate_mesh.surface_set_normal(Vector3(0, 1, 0))
    immediate_mesh.surface_set_uv(Vector2(1, 1))
    immediate_mesh.surface_add_vertex(Vector3(half_size, 0, half_size))
    
    immediate_mesh.surface_set_normal(Vector3(0, 1, 0))
    immediate_mesh.surface_set_uv(Vector2(0, 1))
    immediate_mesh.surface_add_vertex(Vector3(-half_size, 0, half_size))
    
    immediate_mesh.surface_end()


func create_rectangle(width: float, height: float):
    var immediate_mesh = ImmediateMesh.new()

    mesh = immediate_mesh
    material_override = material
    
    immediate_mesh.clear_surfaces()
    immediate_mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES, null)
    
    # 计算半宽和半高
    var half_width = width / 2.0
    var half_height = height / 2.0
    
    # 第一个三角形
    # 左下角
    immediate_mesh.surface_set_normal(Vector3(0, 1, 0))
    immediate_mesh.surface_set_uv(Vector2(0, 0))
    immediate_mesh.surface_add_vertex(Vector3(-half_width, 0, -half_height))
    
    # 右下角
    immediate_mesh.surface_set_normal(Vector3(0, 1, 0))
    immediate_mesh.surface_set_uv(Vector2(1, 0))
    immediate_mesh.surface_add_vertex(Vector3(half_width, 0, -half_height))
    
    # 左上角
    immediate_mesh.surface_set_normal(Vector3(0, 1, 0))
    immediate_mesh.surface_set_uv(Vector2(0, 1))
    immediate_mesh.surface_add_vertex(Vector3(-half_width, 0, half_height))
    
    # 第二个三角形
    # 右下角
    immediate_mesh.surface_set_normal(Vector3(0, 1, 0))
    immediate_mesh.surface_set_uv(Vector2(1, 0))
    immediate_mesh.surface_add_vertex(Vector3(half_width, 0, -half_height))
    
    # 右上角
    immediate_mesh.surface_set_normal(Vector3(0, 1, 0))
    immediate_mesh.surface_set_uv(Vector2(1, 1))
    immediate_mesh.surface_add_vertex(Vector3(half_width, 0, half_height))
    
    # 左上角
    immediate_mesh.surface_set_normal(Vector3(0, 1, 0))
    immediate_mesh.surface_set_uv(Vector2(0, 1))
    immediate_mesh.surface_add_vertex(Vector3(-half_width, 0, half_height))
    
    immediate_mesh.surface_end()	