extends Node
class_name ItemSystem

var _item_res_container_dic = {}    # code => ItemResource

var _item_domain_container_dic = {} # id => ItemDomain


func _ready() -> void:
    # 在系统启动时，初始化所有 item template resource，将起保存在 container 当中
    pass


func generate_item(item_code: String, p: Vector3) -> ItemDomain:
    # load item res
    var item_res: ItemResource = load("res://System/item_system/resources/%s.tres" % [item_code])
    

    
    return null