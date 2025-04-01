extends MeshInstance3D

@export var height: float = 10.0  # 龙卷风高度
@export var radius_bottom: float = 3.0  # 底部半径
@export var radius_top: float = 0.5  # 顶部半径
@export var twist_amount: float = 2.0  # 扭曲度
@export var segments: int = 30  # 细分数量
@export var rings: int = 15  # 环数（决定细节）
@export var uv_scale: float = 1.0  # UV缩放

func _ready():
    var mesh = create_tornado_mesh()
    self.mesh = mesh

func create_tornado_mesh() -> ArrayMesh:
    var st = SurfaceTool.new()
    st.begin(Mesh.PRIMITIVE_TRIANGLES)
    
    var vertices = []
    var normals = []
    var uvs = []
    var indices = []
    
    # 生成螺旋结构
    for i in range(rings + 1):
        var t = i / float(rings)
        var angle = t * twist_amount * TAU
        var r = lerp(radius_bottom, radius_top, t)
        var y = t * height

        for j in range(segments):
            var theta = j / float(segments) * TAU
            var x = cos(theta + angle) * r
            var z = sin(theta + angle) * r
            vertices.append(Vector3(x, y, z))
            normals.append(Vector3(x, 0, z).normalized())
            uvs.append(Vector2(j / float(segments), t * uv_scale))
    
    # 生成三角面
    for i in range(rings):
        for j in range(segments):
            var curr = i * segments + j
            var next = curr + segments
            var next_j = (j + 1) % segments
            
            # 组成两组三角形
            indices.append(curr)
            indices.append(next)
            indices.append(curr + 1 if next_j != 0 else i * segments)
            
            indices.append(curr + 1 if next_j != 0 else i * segments)
            indices.append(next)
            indices.append(next + 1 if next_j != 0 else (i + 1) * segments)
    
    # 发送数据到 SurfaceTool
    for v in range(vertices.size()):
        st.set_normal(normals[v])
        st.set_uv(uvs[v])
        st.add_vertex(vertices[v])

    for i in range(0, indices.size(), 3):
        st.add_index(indices[i])
        st.add_index(indices[i + 1])
        st.add_index(indices[i + 2])

    st.generate_normals()
    var mesh = ArrayMesh.new()
    st.commit(mesh)
    return mesh
