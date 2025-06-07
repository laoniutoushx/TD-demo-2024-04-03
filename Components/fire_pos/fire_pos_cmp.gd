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
    """复制动画并修改轨道路径，使目标AnimationPlayer能控制源场景中的节点"""
    
    # 获取源动画
    var source_animation = source_ap.get_animation(anim_name)
    if not source_animation:
        print("错误: 源动画不存在: ", anim_name)
        return
    
    # 创建动画副本
    var new_animation = source_animation.duplicate(true)
    
    print("开始复制动画: ", anim_name)
    print("轨道数量: ", new_animation.get_track_count())
    
    # 获取到owner的路径字符串
    var owner_path_str = str(get_path_to(owner))
    
    # 修改每个轨道的路径
    for track_idx in new_animation.get_track_count():
        var old_path = new_animation.track_get_path(track_idx)
        print("原始轨道路径[%d]: %s" % [track_idx, old_path])
        
        # 解析原始路径
        var old_path_str = str(old_path)
        var new_path_str: String
        
        if old_path_str.contains(":"):
            # 包含属性的路径，如 "Unit:position"
            var parts = old_path_str.split(":", false, 1)
            var node_path = parts[0]
            var property = parts[1]
            
            # 创建指向owner中对应节点的新路径字符串
            new_path_str = owner_path_str + "/" + node_path + ":" + property
        else:
            # 纯节点路径
            new_path_str = owner_path_str + "/" + old_path_str
        
        # 创建新的NodePath并设置
        var new_path = NodePath(new_path_str)
        new_animation.track_set_path(track_idx, new_path)
        print("新轨道路径[%d]: %s" % [track_idx, new_path])
    
    # 添加动画到目标AnimationPlayer
    target_ap.add_animation(anim_name, new_animation)
    print("动画复制完成: ", anim_name)

func play_fire_animation():
    """播放火焰动画"""
    if ap and ap.has_animation(fire_animation):
        print("播放火焰动画: ", fire_animation)
        ap.play(fire_animation)
    else:
        print("错误: 动画不存在或AnimationPlayer未初始化")

func stop_fire_animation():
    """停止火焰动画"""
    if ap:
        ap.stop()

func is_fire_animation_playing() -> bool:
    """检查火焰动画是否正在播放"""
    if ap:
        return ap.is_playing() and ap.current_animation == fire_animation
    return false

# 可选：更高级的路径处理方法
func copy_and_setup_animation_advanced(source_ap: AnimationPlayer, target_ap: AnimationPlayer, anim_name: StringName):
    """高级版本：支持更复杂的路径映射和错误处理"""
    
    var source_animation = source_ap.get_animation(anim_name)
    if not source_animation:
        push_error("源动画不存在: " + str(anim_name))
        return
    
    var new_animation = source_animation.duplicate(true)
    var failed_tracks = []
    
    for track_idx in new_animation.get_track_count():
        var old_path = new_animation.track_get_path(track_idx)
        var success = false
        
        # 尝试不同的路径映射策略
        var mapping_strategies = [
            _map_direct_path,
            _map_relative_path,
            _map_by_node_name
        ]
        
        for strategy in mapping_strategies:
            var new_path = strategy.call(old_path)
            if new_path and _validate_path(new_path):
                new_animation.track_set_path(track_idx, new_path)
                success = true
                break
        
        if not success:
            failed_tracks.append({"index": track_idx, "path": old_path})
    
    if failed_tracks.size() > 0:
        print("警告: 以下轨道路径映射失败:")
        for failed in failed_tracks:
            print("  轨道[%d]: %s" % [failed.index, failed.path])
    
    target_ap.add_animation(anim_name, new_animation)

func _map_direct_path(old_path: NodePath) -> NodePath:
    """直接路径映射"""
    var old_path_str = str(old_path)
    var owner_path_str = str(get_path_to(owner))
    
    if old_path_str.contains(":"):
        var parts = old_path_str.split(":", false, 1)
        var new_path_str = owner_path_str + "/" + parts[0] + ":" + parts[1]
        return NodePath(new_path_str)
    else:
        var new_path_str = owner_path_str + "/" + old_path_str
        return NodePath(new_path_str)

func _map_relative_path(old_path: NodePath) -> NodePath:
    """相对路径映射"""
    # 移除开头的相对路径符号
    var old_path_str = str(old_path).lstrip("./")
    return _map_direct_path(NodePath(old_path_str))

func _map_by_node_name(old_path: NodePath) -> NodePath:
    """通过节点名称查找映射"""
    var old_path_str = str(old_path)
    var parts = old_path_str.split("/")
    var node_name = parts[-1]
    
    if node_name.contains(":"):
        var node_prop = node_name.split(":", false, 1)
        node_name = node_prop[0]
        var property = node_prop[1]
        
        # 在owner中查找同名节点
        var found_node = _find_node_by_name(owner, node_name)
        if found_node:
            var found_path_str = str(get_path_to(found_node))
            return NodePath(found_path_str + ":" + property)
    
    return NodePath()

func _find_node_by_name(root: Node, name: String) -> Node:
    """递归查找指定名称的节点"""
    if root.name == name:
        return root
    
    for child in root.get_children():
        var found = _find_node_by_name(child, name)
        if found:
            return found
    
    return null

func _validate_path(path: NodePath) -> bool:
    """验证路径是否有效"""
    if not path:
        return false
    
    # 如果路径包含属性，只验证节点部分
    var node_path = path
    if str(path).contains(":"):
        var path_parts = str(path).split(":", false, 1)
        node_path = NodePath(path_parts[0])
    
    # 尝试获取路径指向的节点
    var target_node = get_node_or_null(node_path)
    return target_node != null