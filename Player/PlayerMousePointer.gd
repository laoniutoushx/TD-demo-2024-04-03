extends Node


func change_mouse_to_magic_circle():
    # 隐藏默认鼠标
    Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
    
    # 创建一个TextureRect作为自定义鼠标
    var magic_circle = TextureRect.new()
    magic_circle.texture = preload("res://path_to_your_magic_circle_texture.png")
    magic_circle.rect_size = Vector2(64, 64)  # 根据你的纹理大小调整
    magic_circle.name = "MagicCircle"
    
    # 将其添加到场景中
    add_child(magic_circle)