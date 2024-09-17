extends Node3D

var source: Node
var target: Node
var fire_pos: Vector3
var lerp_pos: float = 0


@export var speed: float
@export var damage: float

func _ready() -> void:
	# 初始位置定位
	# WARNING 某些特殊情况下，在 projectile 不初始化情况下，
	# 有可能其位置在 0，0，0 点位，导致bug，某些帧可能会获取到 projectile 在 0，0，0 位置的的 position，影响 borning 与 death 特性的创建位置
	self.look_at(target.global_position)
	var mesh_node = CommonUtil.get_first_node_by_node_type(target, "MeshInstance3D")
	var aabb = mesh_node.mesh.get_aabb()
	
	var y_scale_instance = 1.0
	var parent_nodes = CommonUtil.get_all_parent_node_by_node_type(mesh_node, mesh_node.owner.get_class())
	for parent_node in parent_nodes:
		if parent_node.scale != null:
			y_scale_instance *= parent_node.scale.y
			
	var height = aabb.size.y * y_scale_instance
	
	global_position = fire_pos.lerp(Vector3(target.global_position.x, height / 2.0, target.global_position.z), lerp_pos)


func _physics_process(delta: float) -> void:
	if target != null and !target.is_logic_dead():
		if lerp_pos < 1: 
			self.look_at(target.global_position)
			var mesh_node = CommonUtil.get_first_node_by_node_type(target, Constants.MeshInstance3D_CLZ)
			var aabb = CommonUtil.get_scaled_aabb(mesh_node)
			var height = aabb.size.y
			global_position = fire_pos.lerp(Vector3(target.global_position.x, height / 2.0, target.global_position.z), lerp_pos)
			lerp_pos += delta * speed
		else:
			queue_free()
	else:
		queue_free()
