class_name BarrageSystem extends Node3D

const PROJECTILE_SCENE = preload("res://System/barrage_system/projectile.tscn")

func _ready() -> void:
	SystemUtil.barrage_system = self

# Completion belongs to the projectile, not a dynamically allocated signal on
# this persistent system. Cancellation always resolves the waiting attack.
func action(source, fire_pos: Vector3, target, fire_pos_mark: Marker3D, attack_uid := "") -> Array:
	if not is_instance_valid(source) or not is_instance_valid(target) or not is_instance_valid(fire_pos_mark):
		return []
	if fire_pos_mark.fire_projectile == null:
		return []
	var projectile = PROJECTILE_SCENE.instantiate()
	projectile.source = source
	projectile.set_meta("attack_uid", attack_uid)
	projectile.target = target
	projectile.fire_pos = fire_pos
	projectile.speed = source.projectile_speed
	projectile.damage = source.attack_value
	var effect = fire_pos_mark.fire_projectile.instantiate()
	projectile.add_child(effect)
	var target_id = target.get_instance_id()
	add_child(projectile)
	var animation = CommonUtil.get_first_node_by_node_type(effect, "AnimationPlayer")
	if animation and animation.has_animation(Constants.ANIM_RUN):
		animation.play(Constants.ANIM_RUN)
	var completion = await projectile.resolved
	if not completion[1] or not is_instance_valid(source) or not is_instance_valid(target):
		return []
	return [completion[0], target_id, target]

func reset_session() -> void:
	for projectile in get_children():
		projectile.queue_free()
