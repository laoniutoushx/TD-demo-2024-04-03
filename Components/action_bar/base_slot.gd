class_name BaseSlot extends PanelContainer

@onready var icon_texture: TextureRect = $IconTexture
@onready var short_cut: Label = $ShortCut

func init(icon_path: String, label) -> void:
	if icon_path != null:
		icon_texture.texture = load(icon_path)
	
	# 关键字
	if label != null:
		short_cut.text = label
