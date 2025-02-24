@tool
extends Node3D

# 用于存储当前的 tween 实例
var current_tween: Tween = null

# 编辑器按钮触发的函数
@export var trigger_animation: bool = false:
    set(value):
        trigger_animation = false  # 重置按钮状态
        _start_animation()

# 要进行动画的节点
@export var target_node: Node3D

# 动画参数
@export var animation_duration: float = 1.0
@export var start_position: Vector3 = Vector3.ZERO
@export var end_position: Vector3 = Vector3(0, 2, 5)
@export_enum("Position", "Rotation", "Scale") var animation_type: String = "Position"
@export var target_rotation: Vector3 = Vector3(0, 360, 0)  # 改名为 target_rotation
@export var scale_change: Vector3 = Vector3(2, 2, 2)

# 运行时参数
@export var auto_start: bool = false  # 运行时是否自动开始动画
@export var loop_animation: bool = false  # 是否循环播放
@export var ping_pong: bool = false  # 是否来回播放

func _ready():
    # 设置默认目标节点
    if not target_node:
        target_node = self
    
    # 如果在运行时且设置了自动开始，则开始动画
    if not Engine.is_editor_hint() and auto_start:
        _start_animation()

func _start_animation():
    # 检查是否可以开始动画
    if not target_node:
        print("未设置目标节点!")
        return
    
    # 如果已有正在运行的 tween，先停止它
    if current_tween and current_tween.is_valid():
        current_tween.kill()
    
    # 创建新的 tween
    current_tween = create_tween()
    current_tween.set_trans(Tween.TRANS_CUBIC)
    current_tween.set_ease(Tween.EASE_IN_OUT)
    
    # 根据是否在编辑器中设置不同的参数
    if Engine.is_editor_hint():
        _setup_editor_tween()
    else:
        _setup_runtime_tween()

func _setup_editor_tween():
    # 编辑器中的简单单次动画
    _add_single_tween()
    current_tween.finished.connect(_on_editor_tween_completed)

func _setup_runtime_tween():
    if ping_pong:
        # 来回播放动画
        _add_single_tween()
        _add_reverse_tween()
        if loop_animation:
            current_tween.set_loops()
    elif loop_animation:
        # 循环播放
        _add_single_tween()
        current_tween.set_loops()
    else:
        # 单次播放
        _add_single_tween()
    
    # 运行时的动画完成回调
    current_tween.finished.connect(_on_runtime_tween_completed)

func _add_single_tween():
    match animation_type:
        "Position":
            target_node.position = start_position
            current_tween.tween_property(
                target_node,
                "position",
                end_position,
                animation_duration
            )
        "Rotation":
            var current_rot = target_node.rotation_degrees
            var end_rot = current_rot + target_rotation  # 使用新的变量名
            current_tween.tween_property(
                target_node,
                "rotation_degrees",
                end_rot,
                animation_duration
            )
        "Scale":
            var start_scale = target_node.scale
            current_tween.tween_property(
                target_node,
                "scale",
                start_scale * scale_change,
                animation_duration
            )

func _add_reverse_tween():
    match animation_type:
        "Position":
            current_tween.tween_property(
                target_node,
                "position",
                start_position,
                animation_duration
            )
        "Rotation":
            var current_rot = target_node.rotation_degrees
            current_tween.tween_property(
                target_node,
                "rotation_degrees",
                current_rot - target_rotation,  # 使用新的变量名
                animation_duration
            )
        "Scale":
            var original_scale = target_node.scale / scale_change
            current_tween.tween_property(
                target_node,
                "scale",
                original_scale,
                animation_duration
            )

func _on_editor_tween_completed():
    print("编辑器 Tween 动画完成!")

func _on_runtime_tween_completed():
    print("运行时 Tween 动画完成!")