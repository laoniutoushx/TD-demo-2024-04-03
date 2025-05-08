class_name FloatingTextSystem
extends Node

@export var floating_text_scene: PackedScene
@export var pool_size: int = 10

var available_texts: Array = []

func _ready():
    for i in pool_size:
        var instance = floating_text_scene.instantiate()
        instance.visible = false
        add_child(instance)
        available_texts.append(instance)

func spawn(position: Vector3, text: String, color: Color = Color.WHITE) -> void:
    var instance: Node3D
    if available_texts.is_empty():
        instance = floating_text_scene.instantiate()
        add_child(instance)
    else:
        instance = available_texts.pop_back()
    
    instance.global_position = position + Vector3(0, 1.5, 0)  # 调整到单位头顶
    instance.setup(text, color)
    instance.visible = true
    
    # 回收完成后重新加入可用池
    await instance.get_tree().create_timer(instance.lifetime).timeout
    instance.visible = false
    available_texts.append(instance)
