import flet as ft
import os
import re
from PIL import Image


class TresResource:
    def __init__(self, path):
        self.path = path
        self.ext_resources = {}
        self.properties = {}
        self.script_class = ""
        self.raw_lines = []

    def load(self):
        with open(self.path, "r", encoding="utf-8") as f:
            self.raw_lines = f.readlines()

        in_resource_block = False
        for line in self.raw_lines:
            if line.startswith("[gd_resource"):
                m = re.search(r'script_class="(.*?)"', line)
                if m:
                    self.script_class = m.group(1)
            elif line.startswith("[ext_resource"):
                path_match = re.search(r'path="(.*?)"', line)
                id_match = re.search(r'id="(.*?)"', line)
                if path_match and id_match:
                    self.ext_resources[id_match.group(1)] = path_match.group(1)
            elif line.startswith("[resource]"):
                in_resource_block = True
            elif in_resource_block:
                if "=" in line:
                    key, val = map(str.strip, line.split("=", 1))
                    self.properties[key] = val

    def save(self):
        new_lines = []
        in_resource_block = False
        for line in self.raw_lines:
            if line.startswith("[resource]"):
                in_resource_block = True
                new_lines.append(line)
                for k, v in self.properties.items():
                    new_lines.append(f"{k} = {v}\n")
                break
            else:
                new_lines.append(line)

        with open(self.path, "w", encoding="utf-8") as f:
            f.writelines(new_lines)

    def set_property(self, key, value):
        self.properties[key] = value

    def delete_property(self, key):
        if key in self.properties:
            del self.properties[key]

    def to_dict(self):
        return {
            "path": self.path,
            "script_class": self.script_class,
            "properties": self.properties,
            "ext_resources": self.ext_resources,
        }


def main(page: ft.Page):
    page.title = "Godot Tres 编辑器"
    page.scroll = ft.ScrollMode.ADAPTIVE

    file_picker = ft.FilePicker()
    page.overlay.append(file_picker)

    tres_list = ft.Column(scroll=ft.ScrollMode.ALWAYS)
    prop_edit_view = ft.Column()
    script_filter = ft.TextField(label="Script Class Filter", width=300)
    current_resource: TresResource = None

    def show_tres_properties(tres: TresResource):
        nonlocal current_resource
        current_resource = tres
        prop_edit_view.controls.clear()

        icon_path = tres.properties.get("icon_path", "").strip('"')
        if icon_path and os.path.exists(icon_path):
            prop_edit_view.controls.append(ft.Image(src=icon_path, width=128, height=128))

        for key, val in tres.properties.items():
            if val in ["true", "false"]:
                ctrl = ft.Switch(label=key, value=(val == "true"),
                                 on_change=lambda e, k=key: update_property(k, str(e.control.value).lower()))
            elif val.replace(".", "", 1).isdigit():
                ctrl = ft.TextField(label=key, value=val,
                                    on_change=lambda e, k=key: update_property(k, e.control.value))
            else:
                ctrl = ft.TextField(label=key, value=val,
                                    on_change=lambda e, k=key: update_property(k, '"' + e.control.value.strip().replace('"', '') + '"'))

            prop_edit_view.controls.append(ctrl)

        prop_edit_view.controls.append(ft.TextButton(text="保存修改", on_click=lambda _: save_tres()))
        prop_edit_view.controls.append(ft.TextButton(text="新增键值", on_click=lambda _: add_new_key()))
        prop_edit_view.controls.append(ft.TextButton(text="删除选中键", on_click=lambda _: delete_key_dialog()))

        page.update()

    def update_property(key, val):
        if current_resource:
            current_resource.set_property(key, val)

    def save_tres():
        if current_resource:
            current_resource.save()
            page.snack_bar = ft.SnackBar(ft.Text("保存成功"))
            page.snack_bar.open = True
            page.update()

    def add_new_key():
        def add_key(e):
            k = key_field.value.strip()
            v = val_field.value.strip()
            if k:
                current_resource.set_property(k, v)
                show_tres_properties(current_resource)
                dialog.open = False
                page.update()

        key_field = ft.TextField(label="键")
        val_field = ft.TextField(label="值")
        dialog = ft.AlertDialog(
            title=ft.Text("新增键值对"),
            content=ft.Column([key_field, val_field]),
            actions=[ft.TextButton("添加", on_click=add_key)],
        )
        page.dialog = dialog
        dialog.open = True
        page.update()

    def delete_key_dialog():
        def delete_key(e):
            k = key_field.value.strip()
            if k:
                current_resource.delete_property(k)
                show_tres_properties(current_resource)
                dialog.open = False
                page.update()

        key_field = ft.TextField(label="要删除的键")
        dialog = ft.AlertDialog(
            title=ft.Text("删除键值"),
            content=key_field,
            actions=[ft.TextButton("删除", on_click=delete_key)],
        )
        page.dialog = dialog
        dialog.open = True
        page.update()

    def on_folder_selected(e: ft.FilePickerResultEvent):
        path = e.path
        tres_list.controls.clear()
        if path:
            for root, _, files in os.walk(path):
                for f in files:
                    if f.endswith(".tres"):
                        full_path = os.path.join(root, f)
                        tres = TresResource(full_path)
                        tres.load()
                        if script_filter.value == "" or tres.script_class == script_filter.value:
                            tres_list.controls.append(
                                ft.TextButton(text=os.path.relpath(full_path, path),
                                              on_click=lambda e, tr=tres: show_tres_properties(tr)))
        page.update()

    def pick_folder(e):
        file_picker.on_result = on_folder_selected
        file_picker.get_directory_path()

    top_row = ft.Row([ft.ElevatedButton("选择目录", on_click=pick_folder), script_filter])

    page.add(top_row, ft.Row([ft.Container(tres_list, width=300), ft.VerticalDivider(), ft.Container(prop_edit_view, expand=True)]))


ft.app(target=main)
