from PyQt5.QtWidgets import (QWidget, QFileDialog, QVBoxLayout, QHBoxLayout,
                             QPushButton, QTableView, QHeaderView, QAbstractItemView,
                             QSplitter, QComboBox, QMenu, QAction, QLabel, QLineEdit,
                             QMessageBox, QListWidget, QListWidgetItem, QCheckBox, QDialog)
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
        
        # 初始化排序相关属性
        self.current_sort_column = -1  # 当前排序列
        self.current_sort_order = 0    # 0: 不排序, 1: 升序, 2: 降序
        self.original_data_order = None  # 原始数据顺序
        
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
        self.save_btn = QPushButton("保存所有修改")
        self.save_btn.clicked.connect(self.save_changes)
        self.save_btn.setEnabled(False)
        
        self.save_row_btn = QPushButton("保存选中行")
        self.save_row_btn.clicked.connect(self.save_selected_row)
        self.save_row_btn.setEnabled(False)
        
        self.add_row_btn = QPushButton("添加行")
        self.add_row_btn.clicked.connect(self.add_row)
        self.add_row_btn.setEnabled(False)
        
        self.delete_row_btn = QPushButton("删除选中行")
        self.delete_row_btn.clicked.connect(self.delete_row)
        self.delete_row_btn.setEnabled(False)
        
        action_layout.addWidget(self.save_btn)
        action_layout.addWidget(self.save_row_btn)
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
        # 添加表头点击事件
        self.frozen_table.horizontalHeader().setSectionsClickable(True)
        self.frozen_table.horizontalHeader().sectionClicked.connect(self.on_header_clicked)
        
        # 主表格
        self.table = QTableView()
        self.table.setAlternatingRowColors(True)
        self.table.setSelectionBehavior(QAbstractItemView.SelectRows)
        self.table.horizontalHeader().setMinimumSectionSize(100)
        self.table.setEditTriggers(QAbstractItemView.DoubleClicked | QAbstractItemView.SelectedClicked)
        self.table.verticalHeader().setDefaultSectionSize(25)
        self.table.setContextMenuPolicy(Qt.CustomContextMenu)
        self.table.customContextMenuRequested.connect(self.show_context_menu)
        # 添加表头点击事件
        self.table.horizontalHeader().setSectionsClickable(True)
        self.table.horizontalHeader().sectionClicked.connect(self.on_header_clicked)
        
        # 连接表格选择
        self.frozen_table.verticalScrollBar().valueChanged.connect(self.table.verticalScrollBar().setValue)
        self.table.verticalScrollBar().valueChanged.connect(self.frozen_table.verticalScrollBar().setValue)
        self.frozen_table.verticalHeader().sectionClicked.connect(self.on_row_selected)
        self.table.verticalHeader().sectionClicked.connect(self.on_row_selected)
        
        # 添加单元格点击事件，使点击任何单元格都能选中整行
        self.frozen_table.clicked.connect(self.on_cell_clicked)
        self.table.clicked.connect(self.on_cell_clicked)
        
        splitter.addWidget(self.frozen_table)
        splitter.addWidget(self.table)
        splitter.setSizes([300, 900])  # 设置初始大小
        
        main_layout.addWidget(splitter, 1)  # 给表格区域最多空间
        
        # 替换冻结列下拉框为选择按钮
        frozen_layout = QHBoxLayout()
        frozen_label = QLabel("冻结列:")
        self.frozen_columns_display = QLineEdit()
        self.frozen_columns_display.setReadOnly(True)
        self.frozen_columns_display.setPlaceholderText("未选择任何列")
        
        self.select_columns_btn = QPushButton("选择列")
        self.select_columns_btn.clicked.connect(self.show_column_selector)
        self.select_columns_btn.setFixedWidth(80)
        
        self.clear_frozen_btn = QPushButton("清除冻结")
        self.clear_frozen_btn.clicked.connect(self.clear_frozen_columns)
        self.clear_frozen_btn.setFixedWidth(80)
        
        frozen_layout.addWidget(frozen_label)
        frozen_layout.addWidget(self.frozen_columns_display, 1)
        frozen_layout.addWidget(self.select_columns_btn)
        frozen_layout.addWidget(self.clear_frozen_btn)
        
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
            
        # 保存原始数据的副本，用于恢复排序
        self.original_data = self.data.copy()
            
        self.headers = [h for h in list(self.data[0].keys()) if not h.startswith('_')]
        self.types = detect_types(self.data[0])
    
        self.model = TresTableModel(self.data, self.headers, self.types)
        self.table.setModel(self.model)
        self.frozen_table.setModel(self.model)
        
        # 连接到数据更改信号
        self.model.dataChanged.connect(self.on_data_changed)
    
        # 重置排序状态
        self.current_sort_column = -1
        self.current_sort_order = 0
        self.original_data_order = list(range(len(self.data)))  # 初始化为默认顺序
        
        # 加载上次保存的冻结列设置
        last_frozen = self.settings.value(f"frozen_columns_{class_name}", "")
        if last_frozen:
            # 这里需要修改，不再使用 column_select_combo
            self.frozen_columns_display.setText(last_frozen)
            
            # 获取选中列的索引
            frozen_indices = []
            for col_name in last_frozen.split(","):
                col_name = col_name.strip()
                if col_name in self.headers:
                    frozen_indices.append(self.headers.index(col_name))
            self.setup_frozen_columns(frozen_indices)
        else:
            # 设置默认冻结列（id 和 name，如果存在）
            default_frozen = []
            default_frozen_names = []
            for col in ["id", "name"]:
                if col in self.headers:
                    default_frozen.append(self.headers.index(col))
                    default_frozen_names.append(col)
            
            if default_frozen:
                self.setup_frozen_columns(default_frozen)
                # 这里需要修改，不再使用 column_select_combo
                self.frozen_columns_display.setText(",".join(default_frozen_names))
        
        self.save_btn.setEnabled(False)
        self.add_row_btn.setEnabled(True)
        self.delete_row_btn.setEnabled(False)
    
    # 删除这个方法
    def update_frozen_columns(self):
        """根据用户选择更新冻结列"""
        frozen_columns_text = self.column_select_combo.currentText().split(",")
        frozen_indices = []
        frozen_names = []
        
        for text in frozen_columns_text:
            col_name = text.strip()
            if col_name and col_name in self.headers:
                frozen_indices.append(self.headers.index(col_name))
                frozen_names.append(col_name)
        
        if frozen_indices:
            self.setup_frozen_columns(frozen_indices)
            # 保存冻结列设置到 QSettings
            self.settings.setValue(f"frozen_columns_{self.current_class}", ",".join(frozen_names))
            QMessageBox.information(self, "冻结列", f"已冻结以下列: {', '.join(frozen_names)}")
        else:
            QMessageBox.warning(self, "冻结列", "没有找到指定的列名，请检查输入")

    def clear_frozen_columns(self):
        """清除所有冻结列"""
        self.setup_frozen_columns([])
        # 这里需要修改，不再使用 column_select_combo
        self.frozen_columns_display.setText("")
        # 清除保存的冻结列设置
        self.settings.remove(f"frozen_columns_{self.current_class}")
        QMessageBox.information(self, "冻结列", "已清除所有冻结列")

    
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
        
        # 调整冻结表的大小
        if frozen_columns:
            # 计算冻结表的总宽度
            frozen_width = 0
            for col in frozen_columns:
                frozen_width += self.frozen_table.columnWidth(col)
            
            # 确保冻结表有合理的最小宽度
            min_width = max(300, frozen_width + 50)  # 添加一些额外空间
            
            # 获取当前的分割器大小
            total_width = sum(self.frozen_table.parent().sizes())
            
            # 设置新的分割器大小
            self.frozen_table.parent().setSizes([min_width, total_width - min_width])
    
    def on_data_changed(self, topLeft, bottomRight):
        """当数据变化时更新UI状态"""
        self.save_btn.setEnabled(True)
        
        # 如果有选中的行，并且该行被修改，启用保存行按钮
        indexes = self.table.selectionModel().selectedRows()
        if not indexes:
            indexes = self.frozen_table.selectionModel().selectedRows()
        
        if indexes:
            row = indexes[0].row()
            if row in self.model.get_modified_rows():
                self.save_row_btn.setEnabled(True)

    def save_changes(self):
        """保存所有修改"""
        if not hasattr(self, 'model') or not self.model.is_modified():
            return
            
        # 获取所有已修改的文件
        modified_files = self.model.get_modified_files()
        
        if not modified_files:
            QMessageBox.information(self, "保存", "没有修改需要保存")
            return
        
        success_count = 0
        error_files = []
        
        # 按文件分组保存数据
        for filepath in modified_files:
            # 收集此文件的所有数据项
            file_items = [item for item in self.data if item.get('_filepath') == filepath]
            
            if not file_items:
                continue
                
            # 尝试保存文件
            if save_tres_file(filepath, file_items[0]):  # 目前只处理每个文件的第一个项目
                success_count += 1
            else:
                error_files.append(os.path.basename(filepath))
        
        # 如果所有文件都保存成功，清除修改状态
        if not error_files:
            self.model.set_modified(False)
            self.save_btn.setEnabled(False)
            self.save_row_btn.setEnabled(False)
            QMessageBox.information(self, "保存成功", f"已成功保存 {success_count} 个文件的修改")
        else:
            # 有些文件保存失败
            error_msg = "以下文件保存失败:\n" + "\n".join(error_files)
            QMessageBox.warning(self, "部分保存失败", error_msg)
    
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
        
        # 如果选中的行已被修改，启用"保存选中行"按钮
        self.save_row_btn.setEnabled(row in self.model._modified_rows)

    def save_selected_row(self):
        """保存选中的行"""
        indexes = self.table.selectionModel().selectedRows()
        if not indexes:
            indexes = self.frozen_table.selectionModel().selectedRows()
        
        if not indexes:
            return
            
        # 获取选中的行
        row = indexes[0].row()
        
        # 检查此行是否已修改
        if row not in self.model.get_modified_rows():
            QMessageBox.information(self, "保存", "选中的行没有修改，无需保存")
            return
            
        # 获取此行对应的文件路径
        filepath = self.data[row].get('_filepath')
        if not filepath:
            QMessageBox.warning(self, "保存失败", "无法确定此行对应的文件路径")
            return
            
        # 保存此行数据到对应的文件
        if save_tres_file(filepath, self.data[row]):
            # 清除此行的修改状态
            self.model.clear_row_modified_state(row)
            
            # 如果此文件没有其他修改的行，清除文件的修改状态
            file_still_modified = False
            for i, item in enumerate(self.data):
                if i != row and i in self.model.get_modified_rows() and item.get('_filepath') == filepath:
                    file_still_modified = True
                    break
                    
            if not file_still_modified:
                self.model.clear_file_modified_state(filepath)
                
            # 更新保存按钮状态
            self.save_btn.setEnabled(self.model.is_modified())
            self.save_row_btn.setEnabled(False)
            
            # 刷新表格显示
            self.model.dataChanged.emit(
                self.model.index(row, 0),
                self.model.index(row, self.model.columnCount() - 1)
            )
            
            QMessageBox.information(self, "保存成功", f"已成功保存行 {row+1} 到文件 {os.path.basename(filepath)}")
        else:
            QMessageBox.warning(self, "保存失败", f"无法保存行 {row+1} 到文件 {filepath}")

    def show_context_menu(self, pos):
        """显示表格的上下文菜单"""
        table = self.sender()
        index = table.indexAt(pos)
        if not index.isValid():
            return
            
        menu = QMenu(self)
        
        # 添加复制单元格内容的操作
        copy_action = QAction("复制单元格内容", self)
        copy_action.triggered.connect(lambda: self.copy_cell_content(index))
        menu.addAction(copy_action)
        
        # 添加批量修改列的操作
        batch_edit_action = QAction("批量修改此列", self)
        batch_edit_action.triggered.connect(lambda: self.batch_edit_column(index.column()))
        menu.addAction(batch_edit_action)
        
        menu.exec_(table.viewport().mapToGlobal(pos))
    
    def batch_edit_column(self, column):
        """批量修改指定列的所有单元格"""
        if column < 0 or column >= len(self.headers):
            return
            
        column_name = self.headers[column]
        column_type = self.types.get(column_name)
        
        # 创建批量编辑对话框
        dialog = QDialog(self)
        dialog.setWindowTitle(f"批量修改列: {column_name}")
        dialog.setMinimumWidth(300)
        
        layout = QVBoxLayout(dialog)
        
        # 添加说明标签
        type_info = f"列类型: {column_type}" if column_type else ""
        layout.addWidget(QLabel(f"请输入新值，将应用到所有行\n{type_info}"))
        
        # 添加输入框
        input_field = QLineEdit()
        layout.addWidget(input_field)
        
        # 添加按钮
        button_layout = QHBoxLayout()
        ok_button = QPushButton("确定")
        cancel_button = QPushButton("取消")
        
        button_layout.addWidget(ok_button)
        button_layout.addWidget(cancel_button)
        layout.addLayout(button_layout)
        
        # 连接按钮信号
        ok_button.clicked.connect(dialog.accept)
        cancel_button.clicked.connect(dialog.reject)
        
        # 显示对话框
        if dialog.exec_() == QDialog.Accepted:
            new_value = input_field.text()
            self.apply_batch_edit(column, new_value)
    
    def apply_batch_edit(self, column, value_text):
        """将新值应用到指定列的所有单元格"""
        if not hasattr(self, 'model') or not self.model:
            return
            
        column_name = self.headers[column]
        column_type = self.types.get(column_name)
        
        # 根据列类型转换值
        try:
            if column_type == "int":
                new_value = int(value_text)
            elif column_type == "float":
                new_value = float(value_text)
            elif column_type == "bool":
                new_value = value_text.lower() in ("true", "yes", "1")
            else:
                new_value = value_text
        except ValueError:
            QMessageBox.warning(self, "类型错误", f"输入的值无法转换为 {column_type} 类型")
            return
        
        # 应用到所有行
        row_count = self.model.rowCount()
        for row in range(row_count):
            index = self.model.index(row, column)
            self.model.setData(index, new_value, Qt.EditRole)
        
        QMessageBox.information(self, "批量修改完成", f"已将 {column_name} 列的所有单元格修改为: {value_text}")

    def show_column_selector(self):
        """显示列选择对话框"""
        if not hasattr(self, 'headers') or not self.headers:
            return
            
        # 创建对话框
        dialog = QDialog(self)
        dialog.setWindowTitle("选择要冻结的列")
        dialog.setMinimumWidth(300)
        dialog.setMinimumHeight(400)
        
        layout = QVBoxLayout(dialog)
        
        # 创建列表控件
        list_widget = QListWidget()
        
        # 获取当前冻结的列
        current_frozen = self.frozen_columns_display.text().split(", ") if self.frozen_columns_display.text() else []
        
        # 添加所有列到列表中
        for header in self.headers:
            item = QListWidgetItem(header)
            item.setFlags(item.flags() | Qt.ItemIsUserCheckable)
            item.setCheckState(Qt.Checked if header in current_frozen else Qt.Unchecked)
            list_widget.addItem(item)
        
        layout.addWidget(list_widget)
        
        # 添加按钮
        button_layout = QHBoxLayout()
        ok_button = QPushButton("确定")
        cancel_button = QPushButton("取消")
        
        button_layout.addWidget(ok_button)
        button_layout.addWidget(cancel_button)
        
        layout.addLayout(button_layout)
        
        # 连接按钮信号
        ok_button.clicked.connect(lambda: self.apply_column_selection(list_widget, dialog))
        cancel_button.clicked.connect(dialog.reject)
        
        # 显示对话框
        dialog.exec_()

    def apply_column_selection(self, list_widget, dialog):
        """应用列选择"""
        selected_columns = []
        
        # 获取所有选中的列
        for i in range(list_widget.count()):
            item = list_widget.item(i)
            if item.checkState() == Qt.Checked:
                selected_columns.append(item.text())
        
        # 更新显示
        if selected_columns:
            self.frozen_columns_display.setText(", ".join(selected_columns))
            
            # 获取选中列的索引
            frozen_indices = [self.headers.index(col) for col in selected_columns if col in self.headers]
            
            # 应用冻结
            self.setup_frozen_columns(frozen_indices)
            
            # 保存设置
            self.settings.setValue(f"frozen_columns_{self.current_class}", ",".join(selected_columns))
        else:
            self.clear_frozen_columns()
        
        # 关闭对话框
        dialog.accept()


    def on_cell_clicked(self, index):
        """处理单元格点击事件，选中整行"""
        if index.isValid():
            row = index.row()
            self.on_row_selected(row)

    def on_header_clicked(self, logical_index):
        """处理表头点击事件，实现排序功能"""
        if not hasattr(self, 'model') or not self.model:
            return
            
        # 如果点击的是当前排序列，则切换排序顺序
        if logical_index == self.current_sort_column:
            # 循环切换：不排序 -> 升序 -> 降序 -> 不排序
            self.current_sort_order = (self.current_sort_order + 1) % 3
        else:
            # 如果点击的是新列，则设置为升序
            self.current_sort_column = logical_index
            self.current_sort_order = 1  # 升序
        
        # 清除所有表头的排序指示器
        self.table.horizontalHeader().setSortIndicatorShown(False)
        self.frozen_table.horizontalHeader().setSortIndicatorShown(False)
        
        # 根据排序状态执行排序
        if self.current_sort_order == 0:
            # 不排序，恢复原始顺序
            if self.original_data_order is not None:
                self.restore_original_order()
            else:
                # 如果没有原始顺序记录，只是清除排序指示器
                self.current_sort_column = -1
        else:
            # 显示排序指示器
            sort_order = Qt.AscendingOrder if self.current_sort_order == 1 else Qt.DescendingOrder
            
            # 设置主表和冻结表的排序指示器
            if not self.table.isColumnHidden(logical_index):
                self.table.horizontalHeader().setSortIndicatorShown(True)
                self.table.horizontalHeader().setSortIndicator(logical_index, sort_order)
            
            if not self.frozen_table.isColumnHidden(logical_index):
                self.frozen_table.horizontalHeader().setSortIndicatorShown(True)
                self.frozen_table.horizontalHeader().setSortIndicator(logical_index, sort_order)
            
            # 执行排序
            self.sort_data(logical_index, sort_order)
    
    def restore_original_order(self):
        """恢复数据的原始顺序"""
        if not hasattr(self, 'model') or not self.model:
            return
            
        # 如果没有保存原始顺序，则无法恢复
        if not hasattr(self, 'original_data_order'):
            return
            
        # 使用保存的原始数据副本恢复顺序
        if hasattr(self, 'original_data') and self.original_data:
            # 保留修改状态
            modified_rows = self.model.get_modified_rows()
            modified_files = self.model.get_modified_files()
            
            # 恢复原始数据
            self.data.clear()
            self.data.extend(self.original_data.copy())
            
            # 恢复修改状态
            self.model._modified_rows = modified_rows
            self.model._modified_files = modified_files
            
            # 清除排序状态
            self.current_sort_column = -1
            self.current_sort_order = 0
            
            # 通知模型数据已更改
            self.model.layoutChanged.emit()
        else:
            # 如果没有原始数据副本，则使用原始顺序索引
            if hasattr(self, 'original_data_order') and self.original_data_order:
                # 根据原始顺序重新排列数据
                sorted_data = [None] * len(self.data)
                for i, original_index in enumerate(self.original_data_order):
                    if original_index < len(self.data):
                        sorted_data[original_index] = self.data[i]
                
                # 过滤掉可能的 None 值
                self.data = [item for item in sorted_data if item is not None]
                
                # 通知模型数据已更改
                self.model.layoutChanged.emit()
    
    def sort_data(self, column, order):
        """对数据进行排序"""
        if not hasattr(self, 'model') or not self.model:
            return
            
        # 确保原始顺序已初始化
        if not hasattr(self, 'original_data_order') or self.original_data_order is None:
            self.original_data_order = list(range(len(self.data)))
        
        # 获取列名
        column_name = self.headers[column]
        
        # 根据列的数据类型进行排序
        column_type = self.types.get(column_name)
        
        # 定义排序键函数
        def get_sort_key(item):
            value = item.get(column_name)
            
            # 处理不同类型的值
            if isinstance(value, dict):
                if value.get('type') == 'string':
                    return value.get('value', '')
                elif 'raw_value' in value:
                    return value.get('raw_value', '')
            
            # 处理 None 值
            if value is None:
                if column_type == "int" or column_type == "float":
                    return float('-inf') if order == Qt.AscendingOrder else float('inf')
                else:
                    return "" if order == Qt.AscendingOrder else "zzzzzzzzz"
            
            return value
        
        # 排序数据
        self.data.sort(
            key=get_sort_key,
            reverse=(order == Qt.DescendingOrder)
        )
        
        # 通知模型数据已更改
        self.model.layoutChanged.emit()