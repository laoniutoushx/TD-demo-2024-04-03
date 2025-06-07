class_name FirePosCmp extends Marker3D

@export var fire_name: StringName = "fire"
@export var fire_animation: StringName = "attack"

@onready var ap: AnimationPlayer = $AnimationPlayer

func _ready() -> void:
	await owner.ready
	
	print("Owner ready: ", owner.name)
	print("FirePosCmp ready: ", fire_name)
	
	# 将父节点 owner AnimationPlayer 的动画设置为 fire_animation
	var parent_ap: AnimationPlayer = CommonUtil.get_first_node_by_node_type(owner, Constants.AnimationPlayer_CLZ)
	if parent_ap and ap:
		if parent_ap.has_animation(fire_animation):
			# 从 parent_ap 获取动画资源
			var animation_resource: Animation = parent_ap.get_animation(fire_animation)
			if animation_resource:
				# 获取或创建动画库
				var anim_lib: AnimationLibrary
				if ap.has_animation_library(""):
					anim_lib = ap.get_animation_library("")
				else:
					anim_lib = AnimationLibrary.new()
					ap.add_animation_library("", anim_lib)
				
				# 将动画添加到库中
				anim_lib.add_animation(fire_animation, animation_resource)
				print("Animation added: ", fire_animation)
				
				# 可选：设置为当前播放的动画
				ap.current_animation = fire_animation
			else:
				print("Failed to get animation resource: ", fire_animation)
		else:
			print("Parent AnimationPlayer does not have animation: ", fire_animation)