class_name BaseSlot extends PanelContainer

# type0
enum SLOT_TYPE {
	SKILL,
	SELECT,
	ITEM,
	DEFAULT
}

# slot state
enum SLOT_STATE {
	IN_ACTIVE,
	ACTIVE
}

signal slot_clicked(s: BaseSlot)


@onready var icon_texture: TextureRect = $IconTexture
@onready var short_cut: Label = $ShortCut
@onready var progress_bar: TextureProgressBar = $TextureProgressBar

static var action_bar: ActionBar

static var slot_panel_container_unactive_theme: Theme = preload("res://Components/action_bar/slot_panel_container_unactive_theme.tres")
static var _slot_material = preload("res://Components/action_bar/corner_boder_color.tres")
static var _slot_shader = preload("res://Components/action_bar/corner_boder_color.gdshader")

# 槽位引用的实体对象
@export var reference: Variant = null
# @export var slot_state: SLOT_STATE = SLOT_STATE.IN_ACTIVE

var slot_material: ShaderMaterial
var icon_res_container := {}

var is_active: bool = false
var is_mouse_hover: bool = false
var slot_type: SLOT_TYPE
# 快捷键（写死）
var mapping_key: String = ""

func _ready() -> void:
	slot_material = _slot_material.duplicate(true)
	progress_bar.value = 0.0
	# slot_state = SLOT_STATE.IN_ACTIVE
	
# input event handler register
func _input(event: InputEvent) -> void:
	# 绑定鼠标左键点击
	if (is_mouse_hover and
			(
				event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed 
			)
		):
		slot_clicked.emit(self)
		get_viewport().set_input_as_handled()

	# 按键主动绑定到显示的 slot 上（每次切换 action bar 时动态绑定）
	if mapping_key != "" and event is InputEventKey and event.pressed:
		if InputMap.action_has_event(mapping_key, event):
			print("Triggered action:", mapping_key)
			slot_clicked.emit(self)
			get_viewport().set_input_as_handled()


func active_callback(act: bool) -> void:
	# 回调函数（当前 slot 是否激活状态设置）
	is_active = act
	


func init(ref: Variant, icon_path: String, type: SLOT_TYPE = SLOT_TYPE.DEFAULT, active: bool = true, label: String = '' ) -> void:
	# 引用实体对象
	reference = ref

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
