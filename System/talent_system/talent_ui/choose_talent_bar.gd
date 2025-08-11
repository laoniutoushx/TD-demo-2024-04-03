extends Control


@onready var talent_label: RichTextLabel = %TalentContent
@export_multiline var talent_text: String = "No talents available."


func _ready() -> void:
    
    talent_label.text = talent_text