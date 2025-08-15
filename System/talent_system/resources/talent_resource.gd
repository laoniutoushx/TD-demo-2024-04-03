@tool
class_name TalentResource extends Resource


@export var id: String = UUID.v4()
@export var code: String
@export var title: String
@export var desc: String
@export var icon_path: String



# Talent Script Template( 用于 动态 处理 Talent 逻辑 )
@export var talent_script: Script