class_name BaseSlot extends PanelContainer

enum SLOT_TYPE {
	SKILL,
	SELECT,
	ITEM,
	DEFAULT
}

signal slot_clicked(s: BaseSlot)


@onready var icon_texture: TextureRect = $IconTexture
@onready var short_cut: Label = $ShortCut

static var action_bar: ActionBar

static var slot_panel_container_unactive_theme: Theme = preload("res://Components/action_bar/slot_panel_container_unactive_theme.tres")
static var _slot_material = preload("res://Components/action_bar/corner_boder_color.tres")
static var _slot_shader = preload("res://Components/action_bar/corner_boder_color.gdshader")

var slot_material: ShaderMaterial
var icon_res_container := {}

var is_active: bool = false
var is_mouse_hover: bool = false
var slot_type: SLOT_TYPE

func _ready() -> void:
	slot_material = _slot_material.duplicate(true)
	
	
# input event handler register
func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed and is_mouse_hover:
		#get_viewport().set_input_as_handled()
		slot_clicked.emit(self)
		get_viewport().set_input_as_handled()


func active_callback(act: bool) -> void:
	is_active = act
	


func init(icon_path: String, type: SLOT_TYPE = SLOT_TYPE.DEFAULT, active: bool = true, label: String = '' ) -> void:
	# 图标初始化
	if icon_path != null and icon_res_container.has(icon_path.get_file().get_basename()):
		icon_texture.texture = icon_res_container[icon_path.get_file().get_basename()]
	else:
		icon_texture.texture = SOS.main.resource_manager.get_resource_by_name(icon_path.get_file().get_basename())
	
	if icon_texture.texture == null:
		icon_texture.texture = SOS.main.resource_manager.get_resource_by_name('icon')	
	
	icon_texture.material = slot_material
	
	# slot label name
	if label != null:
		short_cut.text = label
	
	slot_type = type
	is_active = active
	
	# 激活 or 不激活	
	do(active)
		
		
func do(active):
	if active:
		icon_texture.material.set_shader_parameter("modulate_color", Color.WHITE)
		icon_texture.material.set_shader_parameter("show_border", false)
		self.theme = null
	else:
		icon_texture.material.set_shader_parameter("modulate_color", Color.DIM_GRAY)
		icon_texture.material.set_shader_parameter("show_border", false)
		self.theme = slot_panel_container_unactive_theme
	


func _on_mouse_entered() -> void:
	is_mouse_hover = true
	icon_texture.material.set_shader_parameter("show_border", true)
	


func _on_mouse_exited() -> void:
	is_mouse_hover = false
	icon_texture.material.set_shader_parameter("show_border", false)
