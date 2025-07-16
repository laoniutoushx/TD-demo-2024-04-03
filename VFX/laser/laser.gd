class_name Laser
extends MeshInstance3D

var source_unit: BaseUnit
var target_unit: BaseUnit

var laser_mesh: Mesh = preload("res://VFX/laser/laser_mesh.tres")

func _ready() -> void:
    mesh = laser_mesh.duplicate()

func _process(delta: float) -> void:
    # 确保 source_unit 和 target_unit 有效
    if not is_instance_valid(source_unit) or not is_instance_valid(target_unit):
        set_process(false)
        queue_free()  # 如果单位失效，销毁激光
        return
    
    _refresh_line()

    if mesh.material:
        mesh.material.uv1_offset.x += delta / 4.0

func set_line(start: Vector3, end: Vector3): 
    var direction = end - start
    var length = direction.length()

    if length < 0.01:
        return  # 避免长度为 0 的情况

    # 设置激光位置到中点
    var center = (start + end) * 0.5
    global_position = center

    # 方法1：使用 transform.looking_at（推荐）
    if direction.length() > 0.01:
        global_transform = global_transform.looking_at(end, Vector3.UP)
        # 如果需要额外旋转修正
        rotate_y(PI * 1.5)
    
    # 方法2：如果方法1还有问题，使用手动计算（备选）
    # global_rotation = Vector3.ZERO
    # var forward = direction.normalized()
    # if forward.length() > 0.01:
    #     basis = Basis.looking_at(forward, Vector3.UP)
    #     rotate_y(PI * 1.5)
    
    # 设置 mesh 长度
    mesh.size = Vector2(length, mesh.size.y)

func set_line_by_unit(_s: BaseUnit, _t: BaseUnit) -> void:
    if not is_instance_valid(_s) or not is_instance_valid(_t):
        return
    source_unit = _s
    target_unit = _t
    _refresh_line()

func _refresh_line() -> void:
    if not is_instance_valid(source_unit) or not is_instance_valid(target_unit):
        return
    
    var source_height = max(0.01, source_unit._height)
    var target_height = max(0.01, target_unit._height)

    # 只使用位置信息，不考虑单位朝向
    var start = Vector3(source_unit.global_position.x, source_height * 0.5, source_unit.global_position.z)
    var end = Vector3(target_unit.global_position.x, target_height * 0.5, target_unit.global_position.z)

    set_line(start, end)