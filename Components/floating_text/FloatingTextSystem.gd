class_name FloatingTextSystem
extends Node3D

@export var floating_text_scene: PackedScene
@export var pool_size := 10
@export var max_pool_size := 64
var available_texts: Array[Node3D] = []

func _ready() -> void:
	SystemUtil.floating_text_system = self
	for i in mini(pool_size, max_pool_size):
		available_texts.append(_create_instance())

func _create_instance() -> Node3D:
	var instance = floating_text_scene.instantiate()
	instance.recycled.connect(_recycle_instance)
	add_child(instance)
	return instance

func spawn(position: Vector3, text: String, color: Color = Color.WHITE, damage_type: DamageCtx.DamageType = DamageCtx.DamageType.NORMAL) -> void:
	var instance: Node3D = available_texts.pop_back() if not available_texts.is_empty() else _create_instance()
	instance.global_position = position + Vector3(0, 1.5, 0)
	instance.setup(text, color, damage_type)

func _recycle_instance(instance: Node3D) -> void:
	if available_texts.size() >= max_pool_size:
		instance.queue_free()
	elif not available_texts.has(instance):
		available_texts.append(instance)

func reset_session() -> void:
	available_texts.clear()
	for instance in get_children():
		instance.reset_for_pool()
		_recycle_instance(instance)
