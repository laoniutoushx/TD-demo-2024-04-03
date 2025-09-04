extends Control

@onready var index_ui: Control = %IndexUi
@onready var bg_texture: TextureRect = %BGTexture
@onready var bg_level: Node3D = %BGLevel
@onready var subviewport: SubViewport = %SubViewport

func _ready() -> void:
    index_ui._hide()
    
    # 可选：显示加载提示
    _show_loading_hint()
    
    await _wait_for_rendering_with_feedback()
    
    # 隐藏加载提示，显示UI
    _hide_loading_hint()
    _show_ui_smoothly()

    # music 启动
    # var audio_stream = load("res://Asserts/Audios/background/StartMenuBGM.mp3") as AudioStream
    # SOS.main.audio_manager.play_bg_music(audio_stream)
    SignalBus.bgm_volume_changed.connect(self._on_bgm_volume_changed)
    $BGMPlayer.volume_db = SOS.main.config["bg_volume"]


func _on_bgm_volume_changed(value: float) -> void:
    $BGMPlayer.volume_db = value


func _show_loading_hint():
    # 如果你有加载提示节点的话
    pass

func _hide_loading_hint():
    pass

func _wait_for_rendering_with_feedback():
    await get_tree().process_frame
    subviewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
    
    # 分阶段等待并提供反馈
    print("阶段1: 基础渲染...")
    for i in range(8):
        await get_tree().process_frame
    
    print("阶段2: 等待纹理...")
    while subviewport.get_texture() == null:
        await get_tree().process_frame
    
    print("阶段3: 稳定渲染...")
    await get_tree().create_timer(0.1).timeout
    
    print("渲染完成!")

func _show_ui_smoothly():
    index_ui.modulate.a = 0.0
    index_ui._show()
    
    var tween = create_tween()
    tween.tween_property(index_ui, "modulate:a", 1.0, 0.3)