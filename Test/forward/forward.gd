extends Node3D


var hammer: PackedScene = preload("res://VFX/projectiles/hammer/vfx_hammer_running.tscn")
@onready var mark: Marker3D = %Marker3D

var vfx1: Node3D
var vfx2: Node3D
var vfx3: Node3D
var vfx4: Node3D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	
	vfx1 = hammer.instantiate()
	vfx1.global_position = Vector3(0, 0, 0)
	self.add_child(vfx1)
	
	

	vfx2 = hammer.instantiate()
	vfx2.global_position = Vector3(3, 0, 3)
	self.add_child(vfx2)
	


	vfx3 = hammer.instantiate()
	vfx3.global_position = Vector3(-3, 0, 3)
	self.add_child(vfx3)
	


	vfx4 = hammer.instantiate()
	vfx4.global_position = Vector3(3, 0, -3)
	self.add_child(vfx4)
	


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:

	var direction1 = (mark.global_position - vfx1.global_position).normalized()
	var direction2 = (mark.global_position - vfx2.global_position).normalized()
	var direction3 = (mark.global_position - vfx3.global_position).normalized()
	var direction4 = (mark.global_position - vfx4.global_position).normalized()

	vfx1.look_at(mark.global_position)
	vfx2.look_at(mark.global_position)
	vfx3.look_at(mark.global_position)
	vfx4.look_at(mark.global_position)

	# 物体 A 的 X 轴已经面向目标，然而 A 的默认方向是沿 Z 轴朝前
	# 如果需要使用 X 轴，先进行一个旋转调整
	vfx1.rotate_object_local(Vector3(-1, 0, 0), deg_to_rad(90))
	vfx2.rotate_object_local(Vector3(-1, 0, 0), deg_to_rad(90))
	vfx3.rotate_object_local(Vector3(-1, 0, 0), deg_to_rad(90))
	vfx4.rotate_object_local(Vector3(-1, 0, 0), deg_to_rad(90))
