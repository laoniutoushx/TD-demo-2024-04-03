class_name PlayerSkillScopeIndicator extends Node3D

# 引入状态机
@onready var skill_release_indicator: Decal = $SklillReleaseIndicator

var _center: Vector3
var _radius: float
var _is_limit_move: bool = false

func _ready() -> void:
    hide_indicator()
    pass


func limit_move(center: Vector3, radius: float):
    _center = center
    _radius = radius * 3    # ? 为什么要 3 倍
    _is_limit_move = true


func not_limit_move():
    _is_limit_move = false    



# 每帧设置当前位置为鼠标位置
# area3d 与 mouse position 同步 （ray picker 回调函数）
func skill_scope_indicatior_pos_sync(ray_cast: RayCast3D) -> void:
    var collision_point = ray_cast.get_collision_point()
    if _is_limit_move:
        # 
        var current_pos := Vector2(collision_point.x, collision_point.z)
        var mouse_area_center := Vector2(_center.x, _center.z)
        var distance_to_center = current_pos.distance_to(mouse_area_center)


        print("distance to center %s, _radius %s" % [distance_to_center, _radius])

        # 如果鼠标超出了圆形范围，将其位置限制到圆形边界
        if distance_to_center  >= _radius:
            var direction = (current_pos - mouse_area_center).normalized()
            var clamped_pos = mouse_area_center + direction * _radius
            
            global_position = Vector3(clamped_pos.x, collision_point.y, clamped_pos.y)
        else:
            global_position = collision_point
    else:
        global_position = collision_point



func show_indicator() -> void:
    # 注册到 相机 RayPicker，跟随鼠标移动
    SignalBufferSystem.buffer_signal(SignalBus.ray_picker_regist, skill_scope_indicatior_pos_sync)
    visible = true


func hide_indicator() -> void:
    # 注册到 相机 RayPicker，跟随鼠标移动
    SignalBufferSystem.buffer_signal(SignalBus.ray_picker_unregist, skill_scope_indicatior_pos_sync)
    visible = false


func set_indicator_size(x: float, y: float) -> void:
    skill_release_indicator.size.x = x
    skill_release_indicator.size.z = y  # z = y
    
func reset_indicator_size() -> void:
    skill_release_indicator.size = Vector3(10, 10, 10)
    
