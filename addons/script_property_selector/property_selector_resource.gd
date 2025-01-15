@tool
class_name PropertySelectorResource
extends Resource

# 用于存储选择的脚本类型
@export var selected_script_name: String = ""
# 用于存储选择的属性列表
@export var selected_properties: Array[String] = []