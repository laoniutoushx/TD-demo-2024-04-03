class_name ProgressUtilBar extends Control


@onready var bar: TextureProgressBar = %Bar
@onready var bar_text: RichTextLabel = %BarText

var bar_text_tplate: String

var action_bar: ActionBar


func _ready() -> void:
    bar_text_tplate = bar_text.text
    bar_text.text = bar_text_tplate.format([bar.value])


func update_util_bar(value: float, _max_value: float) -> void:
    if visible == false:
        show()

    bar.max_value = _max_value

    bar.value = float(_max_value) - float(value)
    bar_text.text = bar_text_tplate.format([int(float(value) / float(_max_value) * 100.0)])
    # print("bar.value: %s, %s", [bar.value, value] )


func close() -> void:
    if visible:
        hide()

    # bar.value = 0
    # bar_text.text = bar_text_tplate.format([0])
    # hide()    

