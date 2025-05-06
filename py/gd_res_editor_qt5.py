import sys
import os
import json
import glob

from PyQt5.QtWidgets import (
    QApplication, QWidget, QFileDialog, QVBoxLayout, QPushButton,
    QHBoxLayout, QLabel, QLineEdit, QTableWidget, QTableWidgetItem,
    QHeaderView, QMessageBox, QListWidget
)

from PyQt5.QtCore import Qt

import re


SETTINGS_FILE = "settings.json"


class TresEditor(QWidget):
    def __init__(self):
        super().__init__()
        self.setWindowTitle("Godot .tres 资源编辑器")
        self.resize(1300, 800)

        self.resource_dir = ""
        self.resources = []
        self.class_to_files = {}
        self.current_class = ""
        self.settings = self.load_settings()

        self.init_ui()

        # 加载上次记录
        if self.settings.get("last_resource_dir"):
            self.resource_path_input.setText(self.settings["last_resource_dir"])
            self.resource_dir = self.settings["last_resource_dir"]
            self.scan_script_classes()

            # 如果之前选中过 script_class，恢复选中
            if self.settings.get("last_script_class"):
                last_cls = self.settings["last_script_class"]
                matching_items = self.class_list.findItems(last_cls, Qt.MatchExactly)
                if matching_items:
                    self.class_list.setCurrentItem(matching_items[0])
                    self.load_class_resources(matching_items[0])

    def init_ui(self):
        layout = QVBoxLayout()

        # 资源目录选择
        path_layout = QHBoxLayout()
        self.resource_path_input = QLineEdit()
        path_layout.addWidget(QLabel("资源目录:"))
        path_layout.addWidget(self.resource_path_input)
        path_layout.addWidget(QPushButton("选择", clicked=self.choose_resource_dir))
        layout.addLayout(path_layout)

        # script_class 列表
        self.class_list = QListWidget()
        self.class_list.itemClicked.connect(self.load_class_resources)
        layout.addWidget(QLabel("script_class 资源类型列表:"))
        layout.addWidget(self.class_list)

        # 表格展示区域
        self.table = QTableWidget()
        self.table.setEditTriggers(QTableWidget.AllEditTriggers)
        self.table.horizontalHeader().setMinimumSectionSize(150)  # ✅ 设置最小列宽
        layout.addWidget(self.table)

        # 控制按钮
        btn_layout = QHBoxLayout()
        btn_layout.addWidget(QPushButton("添加行", clicked=self.add_row))
        btn_layout.addWidget(QPushButton("删除行", clicked=self.delete_row))
        btn_layout.addWidget(QPushButton("保存所有", clicked=self.save_all))
        layout.addLayout(btn_layout)

        self.setLayout(layout)

    def choose_resource_dir(self):
        directory = QFileDialog.getExistingDirectory(self, "选择资源目录")
        if directory:
            self.resource_path_input.setText(directory)
            self.resource_dir = directory
            self.settings["last_resource_dir"] = directory
            self.save_settings()
            self.scan_script_classes()

    def scan_script_classes(self):
        self.class_to_files.clear()
        self.class_list.clear()

        files = glob.glob(os.path.join(self.resource_dir, "**/*.tres"), recursive=True)
        for file_path in files:
            with open(file_path, encoding="utf-8") as f:
                content = f.read()
                match = re.search(r'script_class\s*=\s*"(.*?)"', content)
                if match:
                    cls = match.group(1)
                    self.class_to_files.setdefault(cls, []).append(file_path)

        if not self.class_to_files:
            QMessageBox.information(self, "结果", "未找到任何含 script_class 的资源文件。")
            return

        for cls in sorted(self.class_to_files.keys()):
            self.class_list.addItem(cls)

    def load_class_resources(self, item):
        cls = item.text()
        self.current_class = cls
        self.settings["last_script_class"] = cls
        self.save_settings()
        self.resources.clear()

        for file_path in self.class_to_files[cls]:
            with open(file_path, encoding="utf-8") as f:
                content = f.read()
                data = self.parse_tres_content(content)
                if data:
                    data["__file_path"] = file_path
                    self.resources.append(data)

        self.refresh_table()

    def parse_tres_content(self, content):
        resource_match = re.search(r"\[resource\]\n(.*?)(\n\[|$)", content, re.DOTALL)
        if not resource_match:
            return None
        block = resource_match.group(1).strip()
        result = {}
        for line in block.splitlines():
            if "=" not in line:
                continue
            key, val = line.split("=", 1)
            result[key.strip()] = val.strip()
        return result

    def refresh_table(self):
        if not self.resources:
            self.table.setRowCount(0)
            self.table.setColumnCount(0)
            return

        keys = sorted({key for res in self.resources for key in res if not key.startswith("__")})
        self.table.setColumnCount(len(keys))
        self.table.setRowCount(len(self.resources))
        self.table.setHorizontalHeaderLabels(keys)

        for row, res in enumerate(self.resources):
            for col, key in enumerate(keys):
                item = QTableWidgetItem(res.get(key, ""))
                self.table.setItem(row, col, item)

        self.table.horizontalHeader().setSectionResizeMode(QHeaderView.Interactive)  # ✅ 可拖拽宽度

    def add_row(self):
        self.table.insertRow(self.table.rowCount())

    def delete_row(self):
        selected = self.table.currentRow()
        if selected >= 0:
            self.table.removeRow(selected)
            if selected < len(self.resources):
                del self.resources[selected]

    def save_all(self):
        if not self.resources:
            QMessageBox.information(self, "提示", "没有数据可保存")
            return

        headers = [self.table.horizontalHeaderItem(i).text() for i in range(self.table.columnCount())]

        for row in range(self.table.rowCount()):
            res = {k: self.table.item(row, col).text() for col, k in enumerate(headers)}
            path = self.resources[row].get("__file_path", None)
            if path:
                self.write_tres_file(path, res)

        QMessageBox.information(self, "完成", "所有文件保存成功！")

    def write_tres_file(self, path, data):
        with open(path, "r", encoding="utf-8") as f:
            content = f.read()

        new_resource_block = "[resource]\n" + "\n".join(f"{k} = {v}" for k, v in data.items())
        new_content = re.sub(r"\[resource\]\n(.*?)(\n\[|$)", new_resource_block, content, flags=re.DOTALL)

        with open(path, "w", encoding="utf-8") as f:
            f.write(new_content)

    def load_settings(self):
        if os.path.exists(SETTINGS_FILE):
            try:
                with open(SETTINGS_FILE, "r", encoding="utf-8") as f:
                    return json.load(f)
            except Exception:
                return {}
        return {}

    def save_settings(self):
        with open(SETTINGS_FILE, "w", encoding="utf-8") as f:
            json.dump(self.settings, f, indent=4)


if __name__ == "__main__":
    app = QApplication(sys.argv)
    window = TresEditor()
    window.show()
    sys.exit(app.exec_())
