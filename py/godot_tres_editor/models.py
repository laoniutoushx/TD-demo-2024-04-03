from PyQt5.QtCore import Qt, QAbstractTableModel, QModelIndex, QVariant
from PyQt5.QtGui import QBrush, QColor
import json
import copy

class TresTableModel(QAbstractTableModel):
    def __init__(self, data, headers, types):
        super().__init__()
        self._data = data
        self.headers = headers
        self.types = types
        self._modified = False
        # 跟踪每行的修改状态，使用集合而不是字典
        self._modified_rows = set()
        # 跟踪每个文件的修改状态，使用集合而不是字典
        self._modified_files = set()

    def rowCount(self, parent=None):
        return len(self._data)

    def columnCount(self, parent=None):
        return len(self.headers)

    def data(self, index, role):
        if not index.isValid():
            return None
        
        row = index.row()
        col = index.column()
        
        if row >= len(self._data) or col >= len(self.headers):
            return None
        
        key = self.headers[col]
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
        
        if row >= len(self._data) or col >= len(self.headers):
            return False
            
        key = self.headers[col]
        old_value = self._data[row].get(key)
        
        # 根据字段类型处理输入值
        field_type = self.types.get(key)
        
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
            
            # 标记为已修改
            self._modified_rows.add(row)
            self._modified = True
            
            # 如果有文件路径，记录此文件已修改
            filepath = self._data[row].get('_filepath')
            if filepath:
                self._modified_files.add(filepath)
            
            # 发出数据更改信号
            self.dataChanged.emit(index, index)
        
        return True

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