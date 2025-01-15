@tool
extends EditorInspectorPlugin

class ScriptTypeProperty extends EditorProperty:
    var dropdown = OptionButton.new()
    var updating = false
    
    func _init():
        add_child(dropdown)
        dropdown.item_selected.connect(_on_selection_changed)
        _update_script_list()
        
    func _update_script_list():
        dropdown.clear()
        dropdown.add_item("None", 0)
        
        var script_list = ProjectSettings.get_global_class_list()
        var index = 1
        for script_info in script_list:
            dropdown.add_item(script_info.class_name, index)
            index += 1
            
    func _update_property():
        var new_value = get_edited_object()[get_edited_property()]
        updating = true
        
        if new_value == null or new_value.is_empty():
            dropdown.selected = 0
        else:
            for i in dropdown.item_count:
                if dropdown.get_item_text(i) == new_value:
                    dropdown.selected = i
                    break
                    
        updating = false
        
    func _on_selection_changed(index: int):
        if updating:
            return
        var selected = dropdown.get_item_text(index) if index > 0 else ""
        emit_changed(get_edited_property(), selected)

class ScriptPropertiesProperty extends EditorProperty:
    var container = VBoxContainer.new()
    var scroll = ScrollContainer.new()
    var updating = false
    var checkboxes = []
    
    func _init():
        scroll.add_child(container)
        scroll.custom_minimum_size = Vector2(0, 200)  # 设置最小高度
        add_child(scroll)
        
    func update_properties(script_name: String):
        for checkbox in checkboxes:
            checkbox.queue_free()
        checkboxes.clear()
        
        if script_name.is_empty():
            return
            
        var script_list = ProjectSettings.get_global_class_list()
        var script_path = ""
        for script_info in script_list:
            if script_info.class_name == script_name:
                script_path = script_info.path
                break
                
        if script_path.is_empty():
            return
            
        var script = load(script_path)
        if script == null:
            return
            
        var properties = script.get_script_property_list()
        
        for prop in properties:
            if prop.usage & PROPERTY_USAGE_SCRIPT_VARIABLE:
                var checkbox = CheckBox.new()
                checkbox.text = prop.name
                checkbox.toggled.connect(_on_checkbox_toggled.bind(prop.name))
                container.add_child(checkbox)
                checkboxes.append(checkbox)
                
    func _update_property():
        var new_value = get_edited_object()[get_edited_property()]
        if new_value == null:
            new_value = []
            
        updating = true
        for checkbox in checkboxes:
            checkbox.button_pressed = new_value.has(checkbox.text)
        updating = false
        
    func _on_checkbox_toggled(pressed: bool, prop_name: String):
        if updating:
            return
            
        var current_value = get_edited_object()[get_edited_property()]
        if current_value == null:
            current_value = []
            
        var new_value = current_value.duplicate()
        
        if pressed and not new_value.has(prop_name):
            new_value.append(prop_name)
        elif not pressed and new_value.has(prop_name):
            new_value.erase(prop_name)
            
        emit_changed(get_edited_property(), new_value)

func _can_handle(object):
    return object is PropertySelectorResource

func _parse_property(object, type, name, hint_type, hint_string, usage_flags, wide):
    if object is PropertySelectorResource:
        match name:
            "selected_script_name":
                var editor = ScriptTypeProperty.new()
                add_property_editor(name, editor)
                return true
            "selected_properties":
                var editor = ScriptPropertiesProperty.new()
                # 获取当前选择的脚本名称
                editor.update_properties(object.selected_script_name)
                add_property_editor(name, editor)
                return true
    return false