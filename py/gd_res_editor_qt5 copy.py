from PyQt5.QtWidgets import (QApplication, QWidget, QFileDialog, QVBoxLayout, QHBoxLayout,
                             QPushButton, QListWidget, QTableView, QHeaderView, QAbstractItemView,
                             QStyledItemDelegate, QSpinBox, QTextEdit, QLineEdit, QMessageBox,
                             QCheckBox, QSplitter, QComboBox, QMenu, QAction, QLabel)
from PyQt5.QtCore import Qt, QAbstractTableModel, QModelIndex, QVariant, QSettings
from PyQt5.QtGui import QColor

import sys
import os
import json
import re
import ast

class TresTableModel(QAbstractTableModel):
    def __init__(self, data, headers, types):
        super().__init__()
        self._data = data
        self.headers = headers
        self.types = types
        self._modified = False

    def rowCount(self, parent=None):
        return len(self._data)

    def columnCount(self, parent=None):
        return len(self.headers)

    def data(self, index, role=Qt.DisplayRole):
        if not index.isValid():
            return QVariant()
        row, col = index.row(), index.column()
        key = self.headers[col]
        value = self._data[row].get(key, "")
        if role == Qt.DisplayRole or role == Qt.EditRole:
            if self.types.get(key) == "bool":
                return value
            elif self.types.get(key) == "array":
                return json.dumps(value, indent=2, ensure_ascii=False)
            return value
        return QVariant()

    def setData(self, index, value, role=Qt.EditRole):
        if index.isValid() and role == Qt.EditRole:
            key = self.headers[index.column()]
            if self.types.get(key) == "bool":
                self._data[index.row()][key] = bool(value)
            elif self.types.get(key) in ("int", "float"):
                self._data[index.row()][key] = float(value) if "." in str(value) else int(value)
            elif self.types.get(key) == "array":
                try:
                    self._data[index.row()][key] = json.loads(value)
                except:
                    pass
            else:
                self._data[index.row()][key] = value
            self._modified = True
            self.dataChanged.emit(index, index)
            return True
        return False

    def headerData(self, section, orientation, role=Qt.DisplayRole):
        if orientation == Qt.Horizontal and role == Qt.DisplayRole:
            return self.headers[section]
        return super().headerData(section, orientation, role)

    def flags(self, index):
        if not index.isValid():
            return Qt.ItemIsEnabled
        return Qt.ItemFlags(Qt.ItemIsSelectable | Qt.ItemIsEnabled | Qt.ItemIsEditable)
    
    def is_modified(self):
        return self._modified
    
    def set_modified(self, state):
        self._modified = state
    
    def removeRow(self, row, parent=QModelIndex()):
        self.beginRemoveRows(parent, row, row)
        del self._data[row]
        self.endRemoveRows()
        self._modified = True
        return True


class TresEditor(QWidget):
    def __init__(self):
        super().__init__()
        self.setWindowTitle("Godot .tres Editor")
        self.resize(1200, 800)
        self.settings = QSettings("TresEditor", "LastState")
        self.current_dir = ""
        self.current_class = ""

        main_layout = QVBoxLayout(self)
        
        # Top section with minimized directory selection
        top_layout = QHBoxLayout()
        
        # Directory selection section (minimized)
        dir_layout = QHBoxLayout()
        dir_label = QLabel("资源目录:")
        self.dir_display = QLineEdit()
        self.dir_display.setReadOnly(True)
        self.browse_btn = QPushButton("浏览")
        self.browse_btn.setFixedWidth(60)
        self.browse_btn.clicked.connect(self.select_dir)
        
        dir_layout.addWidget(dir_label)
        dir_layout.addWidget(self.dir_display, 1)
        dir_layout.addWidget(self.browse_btn)
        
        # Class selection section
        class_layout = QHBoxLayout()
        class_label = QLabel("资源类型:")
        self.class_combo = QComboBox()
        self.class_combo.currentTextChanged.connect(self.class_selected)
        
        class_layout.addWidget(class_label)
        class_layout.addWidget(self.class_combo, 1)
        
        top_layout.addLayout(dir_layout, 3)
        top_layout.addLayout(class_layout, 1)
        
        main_layout.addLayout(top_layout)
        
        # Action buttons
        action_layout = QHBoxLayout()
        self.save_btn = QPushButton("保存修改")
        self.save_btn.clicked.connect(self.save_changes)
        self.save_btn.setEnabled(False)
        
        self.add_row_btn = QPushButton("添加行")
        self.add_row_btn.clicked.connect(self.add_row)
        self.add_row_btn.setEnabled(False)
        
        self.delete_row_btn = QPushButton("删除选中行")
        self.delete_row_btn.clicked.connect(self.delete_row)
        self.delete_row_btn.setEnabled(False)
        
        action_layout.addWidget(self.save_btn)
        action_layout.addWidget(self.add_row_btn)
        action_layout.addWidget(self.delete_row_btn)
        action_layout.addStretch(1)
        
        main_layout.addLayout(action_layout)

        # Table views in a splitter
        splitter = QSplitter(Qt.Horizontal)
        
        # Frozen columns table
        self.frozen_table = QTableView()
        self.frozen_table.setAlternatingRowColors(True)
        self.frozen_table.setSelectionBehavior(QAbstractItemView.SelectRows)
        self.frozen_table.horizontalHeader().setMinimumSectionSize(100)
        self.frozen_table.setEditTriggers(QAbstractItemView.DoubleClicked | QAbstractItemView.SelectedClicked)
        self.frozen_table.verticalHeader().setDefaultSectionSize(25)
        self.frozen_table.setContextMenuPolicy(Qt.CustomContextMenu)
        self.frozen_table.customContextMenuRequested.connect(self.show_context_menu)
        
        # Main table
        self.table = QTableView()
        self.table.setAlternatingRowColors(True)
        self.table.setSelectionBehavior(QAbstractItemView.SelectRows)
        self.table.horizontalHeader().setMinimumSectionSize(100)
        self.table.setEditTriggers(QAbstractItemView.DoubleClicked | QAbstractItemView.SelectedClicked)
        self.table.verticalHeader().setDefaultSectionSize(25)
        self.table.setContextMenuPolicy(Qt.CustomContextMenu)
        self.table.customContextMenuRequested.connect(self.show_context_menu)
        
        # Connect selection between tables
        self.frozen_table.verticalScrollBar().valueChanged.connect(self.table.verticalScrollBar().setValue)
        self.table.verticalScrollBar().valueChanged.connect(self.frozen_table.verticalScrollBar().setValue)
        self.frozen_table.verticalHeader().sectionClicked.connect(self.on_row_selected)
        self.table.verticalHeader().sectionClicked.connect(self.on_row_selected)
        
        splitter.addWidget(self.frozen_table)
        splitter.addWidget(self.table)
        splitter.setSizes([300, 900])  # Set initial sizes of the splitter
        
        main_layout.addWidget(splitter, 1)  # Give the table area the most space

        # ComboBox to choose frozen columns
        frozen_layout = QHBoxLayout()
        frozen_label = QLabel("冻结列:")
        self.column_select_combo = QComboBox()
        self.column_select_combo.setEditable(True)
        self.column_select_combo.setInsertPolicy(QComboBox.InsertAtTop)
        self.column_select_combo.setDuplicatesEnabled(False)
        self.column_select_combo.setToolTip("选择冻结的列 (输入多列名用逗号分隔)")
        self.column_select_combo.currentTextChanged.connect(self.update_frozen_columns)
        
        frozen_layout.addWidget(frozen_label)
        frozen_layout.addWidget(self.column_select_combo, 1)
        
        main_layout.addLayout(frozen_layout)

        self.data = []
        self.types = {}
        self.headers = []
        self.tres_files = {}  # Map class names to file paths

        self.load_last_state()

    def parse_tres(self, filepath):
        with open(filepath, encoding='utf-8') as f:
            content = f.read()
        
        # Store the original content for save functionality
        self.original_content = content
        
        match = re.search(r'\[gd_resource.*?script_class="(.*?)".*?\]', content)
        script_class = match.group(1) if match else None
        resource_match = re.search(r'\[resource\](.*)', content, re.DOTALL)
        resource_block = resource_match.group(1).strip() if resource_match else ""
        
        fields = {}
        
        for line in resource_block.splitlines():
            if "=" not in line:
                continue
            key, value = map(str.strip, line.split("=", 1))
            
            # Handle the "Array" case without eval
            if value.startswith('Array['):
                try:
                    value = value.replace("Array", "")  # Clean up Array notation
                    parsed_value = ast.literal_eval(value)  # Safely evaluate the array
                    fields[key] = parsed_value
                except:
                    fields[key] = value
            elif value.startswith("ExtResource"):
                # Handling `ExtResource` references
                fields[key] = value
            elif value in ("true", "false"):
                fields[key] = value == "true"
            elif value.startswith('"') and value.endswith('"'):
                fields[key] = value[1:-1]
            else:
                try:
                    fields[key] = float(value) if '.' in value else int(value)
                except:
                    fields[key] = value

        return script_class, fields

    def load_last_state(self):
        last_dir = self.settings.value("last_dir", "")
        last_class = self.settings.value("last_class", "")
        if last_dir and os.path.isdir(last_dir):
            self.scan_directory(last_dir)
            self.dir_display.setText(last_dir)
            if last_class:
                index = self.class_combo.findText(last_class)
                if index >= 0:
                    self.class_combo.setCurrentIndex(index)

    def select_dir(self):
        path = QFileDialog.getExistingDirectory(self, "选择资源目录")
        if path:
            self.settings.setValue("last_dir", path)
            self.current_dir = path
            self.dir_display.setText(path)
            self.scan_directory(path)

    def scan_directory(self, path):
        self.class_combo.clear()
        self.all_data = {}
        self.tres_files = {}  # Reset file paths
        
        for root, _, files in os.walk(path):
            for f in files:
                if f.endswith(".tres"):
                    fp = os.path.join(root, f)
                    script_class, fields = self.parse_tres(fp)
                    if not script_class:
                        continue
                    
                    # Store the file path for this class
                    if script_class not in self.tres_files:
                        self.tres_files[script_class] = []
                    self.tres_files[script_class].append(fp)
                    
                    # Store the data with filepath reference
                    fields['_filepath'] = fp  # Add filepath to fields for saving later
                    self.all_data.setdefault(script_class, []).append(fields)
        
        # Populate class combo box
        for k in sorted(self.all_data.keys()):
            self.class_combo.addItem(k)

    def class_selected(self):
        class_name = self.class_combo.currentText()
        if not class_name:
            return
            
        self.current_class = class_name
        self.settings.setValue("last_class", class_name)
        
        # Check if there are unsaved changes
        if hasattr(self, 'model') and self.model.is_modified():
            reply = QMessageBox.question(self, '未保存的修改', 
                                        '当前有未保存的修改，是否保存？',
                                        QMessageBox.Yes | QMessageBox.No | QMessageBox.Cancel)
            
            if reply == QMessageBox.Yes:
                self.save_changes()
            elif reply == QMessageBox.Cancel:
                # Revert combo box selection
                index = self.class_combo.findText(self.current_class)
                if index >= 0:
                    self.class_combo.setCurrentIndex(index)
                return
        
        self.data = self.all_data.get(class_name, [])
        if not self.data:
            return
            
        self.headers = [h for h in list(self.data[0].keys()) if not h.startswith('_')]
        self.types = self.detect_types(self.data[0])

        self.model = TresTableModel(self.data, self.headers, self.types)
        self.table.setModel(self.model)
        self.frozen_table.setModel(self.model)
        
        # Connect to data change signal
        self.model.dataChanged.connect(self.on_data_changed)

        # Populate the combo box with headers
        self.column_select_combo.clear()
        self.column_select_combo.addItem("id,name")  # Default suggestion
        
        # Set up frozen columns view (default to id and name if they exist)
        default_frozen = []
        for col in ["id", "name"]:
            if col in self.headers:
                default_frozen.append(self.headers.index(col))
        
        self.setup_frozen_columns(default_frozen)
        self.save_btn.setEnabled(False)
        self.add_row_btn.setEnabled(True)
        self.delete_row_btn.setEnabled(False)

    def detect_types(self, sample):
        types = {}
        for k, v in sample.items():
            if k.startswith('_'):  # Skip internal fields
                continue
            if isinstance(v, bool):
                types[k] = "bool"
            elif isinstance(v, int):
                types[k] = "int"
            elif isinstance(v, float):
                types[k] = "float"
            elif isinstance(v, list):
                types[k] = "array"
            else:
                types[k] = "string"
        return types

    def update_frozen_columns(self):
        """Update the frozen columns based on user selection."""
        frozen_columns_text = self.column_select_combo.currentText().split(",")
        frozen_indices = []
        
        for text in frozen_columns_text:
            col_name = text.strip()
            if col_name and col_name in self.headers:
                frozen_indices.append(self.headers.index(col_name))
        
        self.setup_frozen_columns(frozen_indices)

    def setup_frozen_columns(self, frozen_columns):
        """Set up the frozen columns."""
        if not hasattr(self, 'model') or not self.model:
            return
            
        # Hide all columns in frozen table except for the frozen ones
        for col in range(self.model.columnCount()):
            if col in frozen_columns:
                self.frozen_table.setColumnHidden(col, False)
                self.table.setColumnHidden(col, True)  # Hide in main table
            else:
                self.frozen_table.setColumnHidden(col, True)
                self.table.setColumnHidden(col, False)  # Show in main table

    def on_data_changed(self):
        """Called when data is changed in the model."""
        self.save_btn.setEnabled(True)

    def save_changes(self):
        """Save changes to .tres files."""
        if not hasattr(self, 'model') or not self.model.is_modified():
            return
            
        # Group data by filepath
        files_to_update = {}
        for item in self.data:
            filepath = item.get('_filepath')
            if filepath:
                if filepath not in files_to_update:
                    files_to_update[filepath] = []
                files_to_update[filepath].append(item)
        
        # Update each file
        for filepath, items in files_to_update.items():
            try:
                with open(filepath, 'r', encoding='utf-8') as f:
                    content = f.read()
                
                # Get the header part
                header_match = re.search(r'(\[gd_resource.*?\])', content, re.DOTALL)
                if not header_match:
                    continue
                
                header = header_match.group(1)
                
                # Generate new resource block
                resource_block = "[resource]\n"
                
                # Use only the first item for now (TODO: handle multiple items per file)
                item = items[0]
                for key, value in item.items():
                    if key.startswith('_'):  # Skip internal fields
                        continue
                        
                    # Format the value based on type
                    if isinstance(value, bool):
                        formatted_value = "true" if value else "false"
                    elif isinstance(value, (int, float)):
                        formatted_value = str(value)
                    elif isinstance(value, list):
                        # Format array properly for Godot
                        formatted_value = f"Array{value}"
                    elif isinstance(value, str) and value.startswith("ExtResource"):
                        formatted_value = value
                    else:
                        # Escape quotes for strings
                        formatted_value = f'"{value}"'
                    
                    resource_block += f"{key} = {formatted_value}\n"
                
                # Combine header and resource block
                new_content = f"{header}\n{resource_block}"
                
                # Write updated content back to file
                with open(filepath, 'w', encoding='utf-8') as f:
                    f.write(new_content)
                    
            except Exception as e:
                QMessageBox.warning(self, "保存失败", f"无法保存文件 {filepath}: {str(e)}")
        
        # Mark as saved
        self.model.set_modified(False)
        self.save_btn.setEnabled(False)
        QMessageBox.information(self, "保存成功", "所有修改已保存")

    def add_row(self):
        """Add a new row to the table."""
        if not self.data:
            return
            
        # Create a new row with default values based on the first row
        new_row = {}
        for key in self.headers:
            if self.types.get(key) == "int":
                new_row[key] = 0
            elif self.types.get(key) == "float":
                new_row[key] = 0.0
            elif self.types.get(key) == "bool":
                new_row[key] = False
            elif self.types.get(key) == "array":
                new_row[key] = []
            else:
                new_row[key] = ""
        
        # Add the filepath for saving later
        if self.data[0].get('_filepath'):
            new_row['_filepath'] = self.data[0]['_filepath']
        
        # Add to model
        self.model.beginInsertRows(QModelIndex(), len(self.data), len(self.data))
        self.data.append(new_row)
        self.model.endInsertRows()
        self.model.set_modified(True)
        self.save_btn.setEnabled(True)

    def delete_row(self):
        """Delete the selected row."""
        indexes = self.table.selectionModel().selectedRows()
        if not indexes:
            indexes = self.frozen_table.selectionModel().selectedRows()
        
        if not indexes:
            return
            
        # Get the row to delete (take the first selected row)
        row = indexes[0].row()
        
        # Confirm deletion
        reply = QMessageBox.question(self, '确认删除', 
                                    '确定要删除选中的行吗？',
                                    QMessageBox.Yes | QMessageBox.No)
        
        if reply == QMessageBox.Yes:
            # Remove from model
            self.model.removeRow(row)
            self.save_btn.setEnabled(True)

    def on_row_selected(self, row):
        """Handle row selection in either table."""
        # Select the same row in both tables
        self.table.selectRow(row)
        self.frozen_table.selectRow(row)
        self.delete_row_btn.setEnabled(True)

    def show_context_menu(self, pos):
        """Show context menu for table."""
        table = self.sender()
        index = table.indexAt(pos)
        
        if index.isValid():
            menu = QMenu(self)
            
            edit_action = QAction("编辑单元格", self)
            edit_action.triggered.connect(lambda: table.edit(index))
            
            delete_action = QAction("删除此行", self)
            delete_action.triggered.connect(self.delete_row)
            
            menu.addAction(edit_action)
            menu.addAction(delete_action)
            
            menu.exec_(table.viewport().mapToGlobal(pos))


if __name__ == '__main__':
    app = QApplication(sys.argv)
    window = TresEditor()
    window.show()
    sys.exit(app.exec_())