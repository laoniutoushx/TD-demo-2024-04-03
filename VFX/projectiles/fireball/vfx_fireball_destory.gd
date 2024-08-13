extends Node

@onready var vfx_death_effect: GPUParticles3D = $vfx_death_effect

func _ready() -> void:
	# 触发粒子系统
	vfx_death_effect.emitting = true

func _on_vfx_death_effect_finished() -> void:
	#queue_free()
	pass
