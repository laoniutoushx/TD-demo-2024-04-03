@tool
extends Node3D

# 导出变量用于在编辑器中调整
@export var move_speed: float = 5.0
@export var anim_speed_factor: float = 1.0
@export var anim_name: String
@export var target: Node3D

# 节点引用
@onready var path: Path3D = $Path3D
@onready var path_follow: PathFollow3D = $Path3D/PathFollow3D

# 播放状态控制
var _animation_player: AnimationPlayer
var _is_paused: bool = false
var _was_playing: bool = false

@export var is_start: bool = false:
    set(value):
        is_start = value
        if not _animation_player:
            _animation_player = CommonUtil.get_first_node_by_node_type(target, "AnimationPlayer")
        
        if value:
            play()
        else:
            stop()

func _ready() -> void:
    if not Engine.is_editor_hint():
        # 仅在游戏运行时自动开始
        is_start = true

func _process(delta: float) -> void:
    if not _animation_player or _is_paused or not is_start:
        return
        
    # 更新路径进度
    path_follow.progress += move_speed * delta
    
    # 根据移动速度调整动画速度
    var anim_speed = move_speed * anim_speed_factor / 5
    _animation_player.speed_scale = anim_speed

func play() -> void:
    """
    开始播放动画
    """
    if not _animation_player:
        return
        
    _is_paused = false
    _animation_player.play(anim_name)
    _was_playing = true

func stop() -> void:
    """
    停止播放动画
    """
    if not _animation_player:
        return
        
    _animation_player.stop()
    _was_playing = false
    _is_paused = false

func pause_play() -> void:
    """
    暂停播放动画
    """
    if not _animation_player or not _was_playing:
        return
        
    _is_paused = true
    _animation_player.pause()

func resume_play() -> void:
    """
    恢复播放动画
    """
    if not _animation_player or not _was_playing:
        return
        
    _is_paused = false
    _animation_player.play()