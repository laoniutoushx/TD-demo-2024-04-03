extends Control


@export_enum("GREEDY", "COOLDOWN", "SHUTDOWN") var talent_code: String
@export_multiline var talent_text: String = "No talents available."


@onready var talent_label: RichTextLabel = %TalentContent
@onready var ap: AnimationPlayer = %AnimationPlayer
@onready var choose_talent_bar_container: Control = %ChooseTalentBarContainer
@onready var color_rect: ColorRect = %ColorRect



func _ready() -> void:
    set_process_input(false)  # 关闭输入处理

    talent_label.text = talent_text

    self.pivot_offset = self.size / 2  # Set the pivot to the center of the node

    var mat := choose_talent_bar_container.material
    if mat is ShaderMaterial:
        choose_talent_bar_container.material = mat.duplicate()  # true 表示深拷贝子资源





func _on_color_rect_mouse_entered() -> void:
    color_rect.mouse_entered.disconnect(_on_color_rect_mouse_entered)
    color_rect.mouse_entered.connect(_on_color_rect_mouse_exited)

    set_process_input(true)  # 开启输入处理

    # 鼠标滑过高亮动画
    ap.play("burning")


func _on_color_rect_mouse_exited() -> void:
    color_rect.mouse_entered.disconnect(_on_color_rect_mouse_exited)
    color_rect.mouse_entered.connect(_on_color_rect_mouse_entered)

    set_process_input(false)  # 关闭输入处理

    # 鼠标滑过高亮动画-
    ap.stop()                      # 停止当前动画
    ap.play("RESET")        # 播放想恢复的动画
    ap.seek(0.0, true)              # 跳到第一帧，并立即应用属性
    ap.stop()                      # 再次停止，保持第一帧状态


func _input(event: InputEvent) -> void:
    if event is InputEventMouseButton:
        # 处理鼠标左键点击事件
        if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
            set_process_input(false)  # 关闭输入处理
            # 执行选择天赋的逻辑
            _on_talent_selected()




func _on_talent_selected() -> void:

    # 天赋创建(添加到玩家）
    if talent_code == "GREEDY":
        SOS.main.player_controller.add_talent("greedy_talent")
    elif talent_code == "COOLDOWN":
        SOS.main.player_controller.add_talent("cooldown_talent")
    elif talent_code == "SHUTDOWN":
        SOS.main.player_controller.add_talent("shutdown_talent")

    # 播放选择动画
    ap.play("selected")  # 播放选择动画
    await ap.animation_finished

    # 关闭天赋选择界面
    SOS.main.level_controller._cur_scene.ui.talent_choose.hide()

    # 切换玩家状态
    SOS.main.player_controller.player_status = SOS.main.player_controller.PLAYER_STATUS.DEFAULT

    # 隐藏其他 UI（UI & ActionBar）
    SOS.main.level_controller._cur_scene.action_bar.ui_toggle()
    # SOS.main.level_controller._cur_scene.ui.ui_toggle()


    # 重设 player_slot 信息数据（refresh）




