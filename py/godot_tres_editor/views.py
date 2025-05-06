from PyQt5.QtWidgets import (QWidget, QFileDialog, QVBoxLayout, QHBoxLayout,
                             QPushButton, QTableView, QHeaderView, QAbstractItemView,
                             QSplitter, QComboBox, QMenu, QAction, QLabel, QLineEdit,
                             QMessageBox)
from PyQt5.QtCore import Qt, QSettings, QModelIndex
import os
import sys

from godot_tres_editor.models import TresTableModel
from godot_tres_editor.utils import parse_tres, detect_types, save_tres_file

class TresEditor(QWidget):
    def __init__(self):
        super().__init__()
        self.setWindowTitle("Godot .tres Editor")
        self.resize(1200, 800)
        self.settings = QSettings("TresEditor", "LastState")
        self.current_dir = ""
        self.current_class = ""
        
        self._init_ui()
        self.data = []
        self.types = {}
        self.headers = []
        self.tres_files = {}  # 类名到文件路径的映射
        
        self.load_last_state()
    
    def _init_ui(self):
        """初始化 UI 界面"""
        main_layout = QVBoxLayout(self)
        
        # 顶部区域
        top_layout = QHBoxLayout()
        
        # 目录选择区域
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
        
        # 类选择区域
        class_layout = QHBoxLayout()
        class_label = QLabel("资源类型:")
        self.class_combo = QComboBox()
        self.class_combo.currentTextChanged.connect(self.class_selected)
        
        class_layout.addWidget(class_label)
        class_layout.addWidget(self.class_combo, 1)
        
        top_layout.addLayout(dir_layout, 3)
        top_layout.addLayout(class_layout, 1)
        
        main_layout.addLayout(top_layout)
        
        # 操作按钮
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
        
        # 表格视图
        splitter = QSplitter(Qt.Horizontal)
        
        # 冻结列表格
        self.frozen_table = QTableView()
        self.frozen_table.setAlternatingRowColors(True)
        self.frozen_table.setSelectionBehavior(QAbstractItemView.SelectRows)
        self.frozen_table.horizontalHeader().setMinimumSectionSize(100)
        self.frozen_table.setEditTriggers(QAbstractItemView.DoubleClicked | QAbstractItemView.SelectedClicked)
        self.frozen_table.verticalHeader().setDefaultSectionSize(25)
        self.frozen_table.setContextMenuPolicy(Qt.CustomContextMenu)
        self.frozen_table.customContextMenuRequested.connect(self.show_context_menu)
        
        # 主表格
        self.table = QTableView()
        self.table.setAlternatingRowColors(True)
        self.table.setSelectionBehavior(QAbstractItemView.SelectRows)
        self.table.horizontalHeader().setMinimumSectionSize(100)
        self.table.setEditTriggers(QAbstractItemView.DoubleClicked | QAbstractItemView.SelectedClicked)
        self.table.verticalHeader().setDefaultSectionSize(25)
        self.table.setContextMenuPolicy(Qt.CustomContextMenu)
        self.table.customContextMenuRequested.connect(self.show_context_menu)
        
        # 连接表格选择
        self.frozen_table.verticalScrollBar().valueChanged.connect(self.table.verticalScrollBar().setValue)
        self.table.verticalScrollBar().valueChanged.connect(self.frozen_table.verticalScrollBar().setValue)
        self.frozen_table.verticalHeader().sectionClicked.connect(self.on_row_selected)
        self.table.verticalHeader().sectionClicked.connect(self.on_row_selected)
        
        splitter.addWidget(self.frozen_table)
        splitter.addWidget(self.table)
        splitter.setSizes([300, 900])  # 设置初始大小
        
        main_layout.addWidget(splitter, 1)  # 给表格区域最多空间
        
        # 选择冻结列的下拉框
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
    
    def load_last_state(self):
        """加载上次的状态"""
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
        """选择目录"""
        path = QFileDialog.getExistingDirectory(self, "选择资源目录")
        if path:
            self.settings.setValue("last_dir", path)
            self.current_dir = path
            self.dir_display.setText(path)
            self.scan_directory(path)
    
    def scan_directory(self, path):
        """扫描目录中的 .tres 文件"""
        self.class_combo.clear()
        self.all_data = {}
        self.tres_files = {}  # 重置文件路径
        
        for root, _, files in os.walk(path):
            for f in files:
                if f.endswith(".tres"):
                    fp = os.path.join(root, f)
                    script_class, fields = parse_tres(fp)
                    if not script_class:
                        continue
                    
                    # 存储此类的文件路径
                    if script_class not in self.tres_files:
                        self.tres_files[script_class] = []
                    self.tres_files[script_class].append(fp)
                    
                    # 存储带有文件路径引用的数据
                    fields['_filepath'] = fp  # 添加文件路径到字段中，以便稍后保存
                    self.all_data.setdefault(script_class, []).append(fields)
        
        # 填充类下拉框
        for k in sorted(self.all_data.keys()):
            self.class_combo.addItem(k)
    
    def class_selected(self):
        """选择类时的处理"""
        class_name = self.class_combo.currentText()
        if not class_name:
            return
            
        self.current_class = class_name
        self.settings.setValue("last_class", class_name)
        
        # 检查是否有未保存的更改
        if hasattr(self, 'model') and self.model.is_modified():
            reply = QMessageBox.question(self, '未保存的修改', 
                                        '当前有未保存的修改，是否保存？',
                                        QMessageBox.Yes | QMessageBox.No | QMessageBox.Cancel)
            
            if reply == QMessageBox.Yes:
                self.save_changes()
            elif reply == QMessageBox.Cancel:
                # 恢复下拉框选择
                index = self.class_combo.findText(self.current_class)
                if index >= 0:
                    self.class_combo.setCurrentIndex(index)
                return
        
        self.data = self.all_data.get(class_name, [])
        if not self.data:
            return
            
        self.headers = [h for h in list(self.data[0].keys()) if not h.startswith('_')]
        self.types = detect_types(self.data[0])

        self.model = TresTableModel(self.data, self.headers, self.types)
        self.table.setModel(self.model)
        self.frozen_table.setModel(self.model)
        
        # 连接到数据更改信号
        self.model.dataChanged.connect(self.on_data_changed)

        # 用标题填充下拉框
        self.column_select_combo.clear()
        self.column_select_combo.addItems(self.headers)  # 默认建议
        
        # 设置冻结列视图（默认为 id 和 name，如果存在）
        default_frozen = []
        for col in ["id", "name"]:
            if col in self.headers:
                default_frozen.append(self.headers.index(col))
        
        self.setup_frozen_columns(default_frozen)
        self.save_btn.setEnabled(False)
        self.add_row_btn.setEnabled(True)
        self.delete_row_btn.setEnabled(False)
    
    def update_frozen_columns(self):
        """根据用户选择更新冻结列"""
        frozen_columns_text = self.column_select_combo.currentText().split(",")
        frozen_indices = []
        
        for text in frozen_columns_text:
            col_name = text.strip()
            if col_name and col_name in self.headers:
                frozen_indices.append(self.headers.index(col_name))
        
        self.setup_frozen_columns(frozen_indices)
    
    def setup_frozen_columns(self, frozen_columns):
        """设置冻结列"""
        if not hasattr(self, 'model') or not self.model:
            return
            
        # 在冻结表中隐藏除冻结列之外的所有列
        for col in range(self.model.columnCount()):
            if col in frozen_columns:
                self.frozen_table.setColumnHidden(col, False)
                self.table.setColumnHidden(col, True)  # 在主表中隐藏
            else:
                self.frozen_table.setColumnHidden(col, True)
                self.table.setColumnHidden(col, False)  # 在主表中显示
    
    def on_data_changed(self):
        """当模型中的数据更改时调用"""
        self.save_btn.setEnabled(True)
    
    def save_changes(self):
        """保存更改到 .tres 文件"""
        if not hasattr(self, 'model') or not self.model.is_modified():
            return
            
        # 按文件路径分组数据
        files_to_update = {}
        for item in self.data:
            filepath = item.get('_filepath')
            if filepath:
                if filepath not in files_to_update:
                    files_to_update[filepath] = []
                files_to_update[filepath].append(item)
        
        # 更新每个文件
        success = True
        for filepath, items in files_to_update.items():
            # 目前只处理每个文件的第一个项目 (TODO: 处理每个文件的多个项目)
            if not save_tres_file(filepath, items[0]):
                success = False
                QMessageBox.warning(self, "保存失败", f"无法保存文件 {filepath}")
        
        if success:
            # 标记为已保存
            self.model.set_modified(False)
            self.save_btn.setEnabled(False)
            QMessageBox.information(self, "保存成功", "所有修改已保存")
    
    def add_row(self):
        """向表格添加新行"""
        if not self.data:
            return
            
        # 根据第一行创建带有默认值的新行
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
        
        # 添加文件路径以便稍后保存
        if self.data[0].get('_filepath'):
            new_row['_filepath'] = self.data[0]['_filepath']
        
        # 添加到模型
        self.model.beginInsertRows(QModelIndex(), len(self.data), len(self.data))
        self.data.append(new_row)
        self.model.endInsertRows()
        self.model.set_modified(True)
        self.save_btn.setEnabled(True)
    
    def delete_row(self):
        """删除选中的行"""
        indexes = self.table.selectionModel().selectedRows()
        if not indexes:
            indexes = self.frozen_table.selectionModel().selectedRows()
        
        if not indexes:
            return
            
        # 获取要删除的行（取第一个选中的行）
        row = indexes[0].row()
        
        # 确认删除
        reply = QMessageBox.question(self, '确认删除', 
                                    '确定要删除选中的行吗？',
                                    QMessageBox.Yes | QMessageBox.No)
        
        if reply == QMessageBox.Yes:
            # 从模型中删除
            self.model.removeRow(row)
            self.save_btn.setEnabled(True)
    
    def on_row_selected(self, row):
        """处理任一表格中的行选择"""
        # 在两个表格中选择相同的行
        self.table.selectRow(row)
        self.frozen_table.selectRow(row)
        self.delete_row_btn.setEnabled(True)
    
    def show_context_menu(self, pos):
        """显示表格的上下文菜单"""
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