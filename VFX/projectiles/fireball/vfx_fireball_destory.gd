extends Node3D


@onready var vfx_death_effect: GPUParticles3D = $vfx_death_effect

func _ready() -> void:
	# 触发粒子系统
	await vfx_death_effect.ready
	vfx_death_effect.emitting = true
