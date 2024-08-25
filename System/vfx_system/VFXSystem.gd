extends Node
class_name VFXSystem

const vfx_path_prefix = "res://VFX/projectiles/"
const vfx_path_suffix = "vfx_"
const m_hit_flash: Material = preload("res://Asserts/materials/hit_flash.tres")

class VFX:
	var burning_vfx: PackedScene
	var running_vfx: PackedScene
	var destory_vfx: PackedScene
	
enum VFX_TYPE{
	BURNING,
	RUNNING,
	DESTORY
}

# 
func _ready() -> void:
	SystemUtil.vfx_system = self
	


func create_vfx(vfx_name: String, vfx_type: VFX_TYPE) -> Node3D:
	var vfx_scene: PackedScene
	if vfx_type == null:
		vfx_scene = load("res://VFX/projectiles/%s/vfx_%s.tscn" % [vfx_name, vfx_name])
	else:
		# 约定 vfx 后缀
		#print("res://VFX/projectiles/%s/vfx_%s_%s.tscn" % [vfx_name, vfx_name, str(VFX_TYPE.keys()[vfx_type]).to_lower()])
		vfx_scene = load("res://VFX/projectiles/%s/vfx_%s_%s.tscn" % [vfx_name, vfx_name, str(VFX_TYPE.keys()[vfx_type]).to_lower()])
	return vfx_scene.instantiate()
