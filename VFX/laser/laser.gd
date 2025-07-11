class_name Laser
extends MeshInstance3D

var source_unit: BaseUnit
var target_unit: BaseUnit

var laser_mesh: Mesh = preload("res://VFX/laser/laser_mesh.tres")

func _ready() -> void:
    mesh = laser_mesh.duplicate()

func _physics_process(delta: float) -> void:
    # 确保 source_unit 和 target_unit 有效
    if not is_instance_valid(source_unit) or not is_instance_valid(target_unit):
        queue_free()  # 如果单位失效，销毁激光
        return
    
    _refresh_line()

    if mesh.material:
        mesh.material.uv1_offset.x -= delta / 4.0

func set_line(start: Vector3, end: Vector3): 
    var direction = start - end
    var length = direction.length()

    if length < 0.01:
        return  # 避免长度为 0 的情况

    # 中点设置为激光位置
    var center = (start + end) * 0.5
    global_position = center

    # 安全朝向目标点
    CommonUtil.safe_look_at(self, center, end)

    # 手动修正方向（根据你的模型实际情况）
    # rotate_y(PI * 1.5)

    # 设置 mesh 长度（调整 x 轴缩放）
    mesh.size = Vector2(length, mesh.size.y)

func set_line_by_unit(_s: BaseUnit, _t: BaseUnit) -> void:
    if not is_instance_valid(_s) or not is_instance_valid(_t):
        return  # 如果单位无效，不设置激光
    source_unit = _s
    target_unit = _t
    _refresh_line()

func _refresh_line() -> void:
    if not is_instance_valid(source_unit) or not is_instance_valid(target_unit):
        return  # 如果单位失效，直接返回
    
    var source_height = max(0.01, source_unit._height)
    var target_height = max(0.01, target_unit._height)

    var start = Vector3(source_unit.global_position.x, source_height * 0.5, source_unit.global_position.z)
    var end = Vector3(target_unit.global_position.x, target_height * 0.5, target_unit.global_position.z)

    set_line(start, end)