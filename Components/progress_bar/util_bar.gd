class_name ProgressUtilBar extends Control


@onready var bar: TextureProgressBar = %Bar
@onready var bar_text: RichTextLabel = %BarText

var bar_text_tplate: String


func _ready() -> void:
    bar_text_tplate = bar_text.text
    bar_text.text = bar_text_tplate.format([bar.value])


func steup(max_vlaue: float) -> void:
    bar.max_value = max_vlaue


func update_util_bar(value: float) -> void:
    if visible == false:
        show()

    bar.value = float(bar.max_value) - float(value)
    bar_text.text = bar_text_tplate.format([int(float(bar.value) / float(bar.max_value) * 100.0)])
    # print("bar.value: %s, %s", [bar.value, value] )