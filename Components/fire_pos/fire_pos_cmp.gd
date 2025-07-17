class_name FirePosCmp extends Marker3D

@export var fire_name: StringName = "fire"
@export var fire_animation: StringName = "attack"
@export var fire_projectile: PackedScene
@export_enum( "甲", "乙", "丙", "丁", "戊", "己", "庚", "辛", "壬", "癸") var fire_group: String = "甲"
@onready var ap: AnimationPlayer # = $AnimationPlayer




func _ready() -> void:
    await owner.ready

    # 实例化 AnimationPlayer
    ap = AnimationPlayer.new()
    add_child(ap)

    # await CommonUtil.await_timer(1.0)  # 等待1秒，确保所有组件都已准备好
    
    print("Owner ready: ", owner.name)
    print("FirePosCmp ready: ", fire_name)
    
    # 将父节点 owner AnimationPlayer 的动画设置为 fire_animation
    var parent_ap: AnimationPlayer = owner.ap
    if parent_ap and ap:

        print("动画列表:")
        var animations = parent_ap.get_animation_list()
        for anim_name in animations:
            print("  - ", anim_name)

        if parent_ap.has_animation(fire_animation):
            # 将 parent_ap 动画复制给 ap 并修改路径
            copy_and_setup_animation(parent_ap, ap, fire_animation)
        else:
            print("警告: 父级AnimationPlayer中未找到动画: ", fire_animation)
    else:
        print("错误: 未找到AnimationPlayer组件")


func copy_and_setup_animation(source_ap: AnimationPlayer, target_ap: AnimationPlayer, anim_name: StringName):
    var source_animation = source_ap.get_animation(anim_name)
    if not source_animation:
        print("错误: 源动画不存在: ", anim_name)
        return

    # 设置 root_node 为 source 的 root_node 相对当前节点
    var source_root_path: NodePath = source_ap.root_node
    var source_root_node: Node = source_ap.get_node(source_root_path)
    var target_root_path: NodePath = target_ap.get_path_to(source_root_node)
    target_ap.root_node = target_root_path

    var new_animation = source_animation.duplicate(true)

    # 修复轨道路径：以 root_node 为基准去找
    validate_and_fix_animation_tracks(new_animation, target_ap)

    var anim_library: AnimationLibrary = target_ap.get_animation_library("")
    if anim_library == null:
        anim_library = AnimationLibrary.new()
        target_ap.add_animation_library("", anim_library)


    if anim_library.has_animation(anim_name):
        anim_library.remove_animation(anim_name)

    anim_library.add_animation(anim_name, new_animation)
    print("动画 '%s' 已成功设置" % anim_name)


func validate_and_fix_animation_tracks(animation: Animation, target_ap: AnimationPlayer):
    var root_node = target_ap.get_node(target_ap.root_node)
    var tracks_to_remove = []

    for i in range(animation.get_track_count()):
        var track_path = animation.track_get_path(i)
        var relative_node_path = NodePath(str(track_path).split(":")[0])
        var target_node = root_node.get_node_or_null(relative_node_path)

        print("检查轨道 %d: %s -> 结果: %s" % [i, track_path, target_node])
        if not target_node:
            print("警告: 轨道路径无效，将移除: ", track_path)
            tracks_to_remove.append(i)

    tracks_to_remove.reverse()
    for i in tracks_to_remove:
        animation.remove_track(i)

