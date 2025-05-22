class_name FloatingTextSystem
extends Node3D

@export var floating_text_scene: PackedScene
@export var pool_size: int = 10

var available_texts: Array = []

func _ready():
    for i in pool_size:
        var instance = floating_text_scene.instantiate()
        instance.visible = false
        add_child(instance)
        available_texts.append(instance)

    SystemUtil.floating_text_system = self

func spawn(position: Vector3, text: String, color: Color = Color.WHITE, damage_type: DamageCtx.DamageType = DamageCtx.DamageType.NORMAL) -> void:
    var instance: Node3D = null
    
    # 清理无效实例
    while not available_texts.is_empty() and not is_instance_valid(available_texts.back()):
        available_texts.pop_back()
    
    if not available_texts.is_empty():
        instance = available_texts.pop_back()
        if is_instance_valid(instance):
            instance.visible = true
        else:
            instance = null
    
    if not instance:
        instance = floating_text_scene.instantiate()
        # 添加自动清理监听
        instance.tree_exiting.connect(_on_instance_exiting.bind(instance))
        add_child(instance)
    
    if is_instance_valid(instance):
        instance.global_position = position + Vector3(0, 1.5, 0)
        instance.setup(text, color, damage_type)
        instance.visible = true
        
        # 自动回收机制
        
        var timer = get_tree().create_timer(instance.lifetime)
        timer.timeout.connect(_recycle_instance.bind(instance))
        # timer.timeout.connect((func(_instance): _recycle_instance(_instance)).bind(instance))


func _recycle_instance(instance) -> void:
    if not is_instance_valid(instance):
        return
    if not instance.is_inside_tree():
        return
    instance.visible = false
    if not available_texts.has(instance):
        available_texts.append(instance)          


func _on_instance_exiting(instance) -> void:
    if available_texts.has(instance):
        available_texts.erase(instance)
