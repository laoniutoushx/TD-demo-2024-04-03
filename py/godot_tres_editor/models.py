from PyQt5.QtCore import Qt, QAbstractTableModel, QModelIndex, QVariant
from PyQt5.QtGui import QBrush, QColor
import json
import copy
import os

class TresTableModel(QAbstractTableModel):
    def __init__(self, data, headers, types):
        super().__init__()
        self._data = data
        self._headers = headers
        self._types = types
        self._modified = False
        # 跟踪每行的修改状态，使用集合而不是字典
        self._modified_rows = set()
        # 跟踪每个文件的修改状态，使用集合而不是字典
        self._modified_files = set()
        # 跟踪重命名的文件
        self._renamed_files = {}
        
        # 添加特殊列：文件名
        if '_filepath' in data[0] and 'filename' not in self._headers:
            self._headers.append('filename')
            self._types['filename'] = 'string'
            # 为每行数据添加文件名字段
            for row in self._data:
                if '_filepath' in row:
                    row['filename'] = os.path.basename(row['_filepath'])

    def rowCount(self, parent=None):
        return len(self._data)

    def columnCount(self, parent=None):
        return len(self._headers)

    def data(self, index, role):
        if not index.isValid():
            return None
        
        row = index.row()
        col = index.column()
        
        if row >= len(self._data) or col >= len(self._headers):
            return None
        
        key = self._headers[col]
        
        # 特殊处理文件名列
        if key == 'filename' and '_filepath' in self._data[row]:
            if role == Qt.DisplayRole or role == Qt.EditRole:
                return os.path.basename(self._data[row]['_filepath'])
            # 为文件名列添加特殊背景色
            elif role == Qt.BackgroundRole:
                return QBrush(QColor(220, 230, 255))  # 淡蓝色背景
            elif role == Qt.ToolTipRole:
                return "点击编辑以重命名文件"
            return None
            
        value = self._data[row].get(key)
        
        if role == Qt.DisplayRole or role == Qt.EditRole:
            # 处理字符串类型的字典
            if isinstance(value, dict) and value.get('type') == 'string':
                return value.get('value', '')
            # 处理其他类型的字典
            elif isinstance(value, dict) and 'raw_value' in value:
                return value.get('raw_value', '')
            # 处理 None 值
            elif value is None:
                return ""
            # 处理布尔值
            elif isinstance(value, bool):
                return "true" if value else "false"
            # 处理其他类型
            else:
                return str(value)
        
        # 设置背景色，标记已修改的单元格
        elif role == Qt.BackgroundRole:
            if row in self._modified_rows:
                return QBrush(QColor(255, 255, 200))  # 淡黄色背景
        
        return None

    def setData(self, index, value, role):
        if not index.isValid() or role != Qt.EditRole:
            return False
            
        row = index.row()
        col = index.column()
        
        if row >= len(self._data) or col >= len(self._headers):
            return False
            
        key = self._headers[col]
        old_value = self._data[row].get(key)
        
        # 特殊处理文件名列 - 实现文件重命名
        if key == 'filename':
            old_filepath = self._data[row].get('_filepath', '')
            if not old_filepath or not os.path.exists(old_filepath):
                return False
                
            # 获取目录和新文件路径
            directory = os.path.dirname(old_filepath)
            new_filename = value.strip()
            
            # 验证新文件名
            if not new_filename or new_filename == os.path.basename(old_filepath):
                return False
                
            # 确保文件名以.tres结尾
            if not new_filename.endswith('.tres'):
                new_filename += '.tres'
                
            new_filepath = os.path.join(directory, new_filename)
            
            # 检查新文件是否已存在
            if os.path.exists(new_filepath):
                return False
                
            # 标记为已修改
            self._modified_rows.add(row)
            self._modified = True
            
            # 更新数据模型中的文件路径
            self._data[row]['_filepath'] = new_filepath
            self._data[row]['filename'] = new_filename
            
            # 添加到修改文件列表，但不立即执行文件系统操作
            # 文件重命名将在保存时执行
            if not hasattr(self, '_renamed_files'):
                self._renamed_files = {}
            self._renamed_files[old_filepath] = new_filepath
            
            # 发出数据更改信号
            self.dataChanged.emit(index, index)
            return True
        
        # 根据字段类型处理输入值
        field_type = self._types.get(key)
        
        if field_type == "int":
            try:
                new_value = int(value)
            except:
                return False
        elif field_type == "float":
            try:
                new_value = float(value)
            except:
                return False
        elif field_type == "bool":
            new_value = value.lower() in ("true", "yes", "1")
        elif field_type == "string":
            # 如果原值是字符串字典，更新其值
            if isinstance(old_value, dict) and old_value.get('type') == 'string':
                new_value = copy.deepcopy(old_value)
                new_value['value'] = value
            else:
                # 否则创建新的字符串字典或直接使用字符串值
                new_value = value
        elif field_type in ("ext_resource", "sub_resource", "godot_array", "other"):
            # 对于特殊类型，保持原始结构，只更新值
            if isinstance(old_value, dict) and 'raw_value' in old_value:
                new_value = copy.deepcopy(old_value)
                new_value['raw_value'] = value
            else:
                new_value = value
        else:
            # 其他类型保持不变
            new_value = value
        
        # 检查值是否真的改变了
        if isinstance(old_value, dict) and isinstance(new_value, dict):
            # 对于字典类型，比较关键字段
            if old_value.get('type') == 'string' and new_value.get('type') == 'string':
                value_changed = old_value.get('value') != new_value.get('value')
            elif 'raw_value' in old_value and 'raw_value' in new_value:
                value_changed = old_value.get('raw_value') != new_value.get('raw_value')
            else:
                value_changed = old_value != new_value
        else:
            # 对于简单类型，直接比较
            value_changed = old_value != new_value
        
        # 只有在值真的改变时才更新
        if value_changed:
            # 更新数据
            self._data[row][key] = new_value
            
            # 确保 _modified_rows 是集合类型
            if not isinstance(self._modified_rows, set):
                self._modified_rows = set(self._modified_rows if isinstance(self._modified_rows, list) else [])
            
            # 标记为已修改
            self._modified_rows.add(row)
            self._modified = True
            
            # 如果有文件路径，记录此文件已修改
            filepath = self._data[row].get('_filepath')
            if filepath:
                # 确保 _modified_files 是集合类型
                if not isinstance(self._modified_files, set):
                    self._modified_files = set(self._modified_files if isinstance(self._modified_files, list) else [])
                self._modified_files.add(filepath)
            
            # 发出数据更改信号
            self.dataChanged.emit(index, index)
        
        return True

    def headerData(self, section, orientation, role=Qt.DisplayRole):
        if orientation == Qt.Horizontal and role == Qt.DisplayRole:
            return self._headers[section]
        return super().headerData(section, orientation, role)

    def flags(self, index):
        if not index.isValid():
            return Qt.ItemIsEnabled
        return Qt.ItemFlags(Qt.ItemIsSelectable | Qt.ItemIsEnabled | Qt.ItemIsEditable)
    
    def is_modified(self):
        return self._modified
    
    def set_modified(self, state):
        self._modified = state
        if not state:
            self._modified_rows.clear()
            self._modified_files.clear()
    
    def get_modified_rows(self):
        """返回已修改的行索引列表"""
        return list(self._modified_rows)
    
    def get_modified_files(self):
        """返回已修改的文件路径列表"""
        return list(self._modified_files)
    
    def clear_row_modified_state(self, row):
        """清除指定行的修改状态"""
        if row in self._modified_rows:
            self._modified_rows.remove(row)
            
    def clear_file_modified_state(self, filepath):
        """清除指定文件的修改状态"""
        if filepath in self._modified_files:
            self._modified_files.remove(filepath)
            
            # 检查是否还有修改过的行
            if not self._modified_rows and not self._modified_files:
                self._modified = False
    
    def removeRow(self, row, parent=QModelIndex()):
        self.beginRemoveRows(parent, row, row)
        
        # 获取要删除的行对应的文件路径
        filepath = self._data[row].get('_filepath')
        if filepath:
            self._modified_files.add(filepath)
            
        del self._data[row]
        self.endRemoveRows()
        
        # 确保 _modified_rows 是集合类型
        if not isinstance(self._modified_rows, set):
            self._modified_rows = set(self._modified_rows if isinstance(self._modified_rows, list) else [])
        
        # 更新已修改行的索引（删除行后，后面的行索引会减1）
        updated_modified_rows = set()
        for modified_row in self._modified_rows:
            if modified_row < row:
                updated_modified_rows.add(modified_row)
            elif modified_row > row:
                updated_modified_rows.add(modified_row - 1)
        self._modified_rows = updated_modified_rows
        
        self._modified = True
        return True