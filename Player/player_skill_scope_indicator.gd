class_name PlayerSkillScopeIndicator extends Node3D



func _ready() -> void:
    visible = false
    pass


# 每帧设置当前位置为鼠标位置
# area3d 与 mouse position 同步 （ray picker 回调函数）
func skill_scope_indicatior_pos_sync(ray_cast: RayCast3D) -> void:
    global_position = ray_cast.get_collision_point()
    pass


func show_indicator() -> void:
    # 注册到 相机 RayPicker，跟随鼠标移动
    SignalBufferSystem.buffer_signal(SignalBus.ray_picker_regist, skill_scope_indicatior_pos_sync)
    visible = true


func hide_indicator() -> void:
    # 注册到 相机 RayPicker，跟随鼠标移动
    SignalBufferSystem.buffer_signal(SignalBus.ray_picker_unregist, skill_scope_indicatior_pos_sync)
    visible = false

    

