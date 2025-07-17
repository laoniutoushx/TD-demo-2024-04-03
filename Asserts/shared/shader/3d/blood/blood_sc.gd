# BloodDecal.gd
extends Decal

# 淡入淡出控制参数
@export var fade_in_duration: float = 0.5  # 淡入时间
@export var stay_duration: float = 3.0     # 停留时间
@export var fade_out_duration: float = 2.0  # 淡出时间
@export var shrink_fade: bool = true        # 是否从边缘收缩消失

# 私有变量
var _initial_size: Vector3
var _fade_tween: Tween
var _lifecycle_timer: float = 0.0
var _current_phase: FadePhase = FadePhase.FADE_IN

enum FadePhase {
    FADE_IN,
    STAYING,
    FADE_OUT,
    FINISHED
}

func _ready():
    # 保存初始尺寸
    _initial_size = size
    
    # 创建Tween（Godot 4中Tween是RefCounted，不需要add_child）
    _fade_tween = create_tween()
    
    # 开始淡入效果
    start_fade_in()

func start_fade_in():
    """开始淡入效果"""
    _current_phase = FadePhase.FADE_IN
    
    # 设置初始状态
    modulate.a = 0.0
    if shrink_fade:
        size = Vector3.ZERO
    
    # 创建新的Tween链
    _fade_tween = create_tween()
    _fade_tween.set_parallel(true)  # 允许并行动画
    
    # 透明度淡入
    _fade_tween.tween_property(self, "modulate:a", 1.0, fade_in_duration)
    
    # 尺寸淡入
    if shrink_fade:
        _fade_tween.tween_property(self, "size", _initial_size, fade_in_duration)
    
    # 淡入完成后进入停留阶段
    _fade_tween.tween_callback(_start_staying).set_delay(fade_in_duration)

func _update_fade_in(progress: float):
    """更新淡入效果（已替换为直接属性动画）"""
    # 这个函数现在不需要了，已被 tween_property 替代
    pass

func _start_staying():
    """开始停留阶段"""
    _current_phase = FadePhase.STAYING
    
    # 创建新的Tween用于停留阶段
    _fade_tween = create_tween()
    
    # 停留时间结束后开始淡出
    _fade_tween.tween_callback(_start_fade_out).set_delay(stay_duration)

func _start_fade_out():
    """开始淡出效果"""
    _current_phase = FadePhase.FADE_OUT
    
    # 创建新的Tween用于淡出
    _fade_tween = create_tween()
    _fade_tween.set_parallel(true)  # 允许并行动画
    
    # 淡出动画 - 从边缘向中心消失
    _fade_tween.tween_method(
        _update_fade_out,
        1.0,
        0.0,
        fade_out_duration
    )
    
    # 淡出完成后销毁
    _fade_tween.tween_callback(_on_fade_complete).set_delay(fade_out_duration)

func _update_fade_out(progress: float):
    """更新淡出效果 - 从边缘向中心消失"""
    # 透明度变化
    modulate.a = progress
    
    # 尺寸变化（从边缘向中心收缩）
    if shrink_fade:
        size = _initial_size * progress
        
        # 添加一些随机扰动让消失更自然
        var noise_factor = (1.0 - progress) * 0.1
        size.x += randf_range(-noise_factor, noise_factor)
        size.z += randf_range(-noise_factor, noise_factor)

func _on_fade_complete():
    """淡出完成回调"""
    _current_phase = FadePhase.FINISHED
    queue_free()

# 公共方法
func force_fade_out():
    """强制开始淡出"""
    if _current_phase != FadePhase.FADE_OUT and _current_phase != FadePhase.FINISHED:
        if _fade_tween:
            _fade_tween.kill()
        _start_fade_out()

func set_fade_parameters(fade_in: float, stay: float, fade_out: float):
    """设置淡入淡出参数"""
    fade_in_duration = fade_in
    stay_duration = stay
    fade_out_duration = fade_out

func get_current_phase() -> FadePhase:
    """获取当前阶段"""
    return _current_phase

