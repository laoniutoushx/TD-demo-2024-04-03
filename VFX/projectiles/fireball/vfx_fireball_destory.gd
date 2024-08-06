extends Node

@onready var vfx_death_effect: GPUParticles3D = $vfx_death_effect

func _ready() -> void:
	# 确保 one_shot 为 true
	vfx_death_effect.one_shot = true
	# 触发粒子系统
	vfx_death_effect.emitting = true

func _on_vfx_death_effect_finished() -> void:
	#queue_free()
	pass
