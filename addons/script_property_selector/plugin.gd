@tool
extends EditorPlugin

var inspector_plugin

func _enter_tree():
    inspector_plugin = preload("res://addons/script_property_selector/script_property_selector.gd").new()
    add_inspector_plugin(inspector_plugin)

func _exit_tree():
    remove_inspector_plugin(inspector_plugin)
    inspector_plugin = null