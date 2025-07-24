extends Node
class_name VFXSystem

const m_hit_flash: Material = preload("res://Asserts/materials/hit_flash.tres")

	
enum VFX_TYPE{
	BURNING,
	RUNNING,
	DESTORY
}

var vfx_res_map: Dictionary = {}
# 
func _ready() -> void:
	SystemUtil.vfx_system = self
	CommonUtil.load_resources_to_container_from_directory("res://VFX", vfx_res_map)
	


func create_vfx(vfx_name: String, vfx_type: VFX_TYPE) -> Node3D:
	var vfx_scene: PackedScene
	if vfx_type == null:
		vfx_scene = vfx_res_map.get("vfx_%s" % [vfx_name, vfx_name])
		# vfx_scene = load("res://VFX/projectiles/%s/vfx_%s.tscn" % [vfx_name, vfx_name])
	else:
		# 约定 vfx 后缀
		#print("res://VFX/projectiles/%s/vfx_%s_%s.tscn" % [vfx_name, vfx_name, str(VFX_TYPE.keys()[vfx_type]).to_lower()])
		# vfx_scene = load("res://VFX/projectiles/%s/vfx_%s_%s.tscn" % [vfx_name, vfx_name, str(VFX_TYPE.keys()[vfx_type]).to_lower()])
		var path = "vfx_%s_%s" % [vfx_name, str(VFX_TYPE.keys()[vfx_type]).to_lower()]
		vfx_scene = vfx_res_map.get("vfx_%s_%s" % [vfx_name, str(VFX_TYPE.keys()[vfx_type]).to_lower()])
	return vfx_scene.instantiate() if vfx_scene else null
