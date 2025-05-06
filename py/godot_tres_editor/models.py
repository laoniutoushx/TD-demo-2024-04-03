from PyQt5.QtCore import Qt, QAbstractTableModel, QModelIndex, QVariant
import json

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
            # 处理 Godot 特有的数据类型
            if self.types.get(key) == "bool":
                return value
            elif self.types.get(key) == "array":
                return json.dumps(value, indent=2, ensure_ascii=False)
            elif self.types.get(key) == "godot_array":
                # 显示原始的 Godot Array 字符串
                return value.get('raw_value', str(value))
            elif self.types.get(key) in ("ext_resource", "sub_resource"):
                # 显示原始的资源引用字符串
                return value.get('raw_value', str(value))
            return value
        return QVariant()

    def setData(self, index, value, role=Qt.EditRole):
        if index.isValid() and role == Qt.EditRole:
            key = self.headers[index.column()]
            
            # 根据类型处理数据
            if self.types.get(key) == "bool":
                self._data[index.row()][key] = bool(value)
            elif self.types.get(key) in ("int", "float"):
                self._data[index.row()][key] = float(value) if "." in str(value) else int(value)
            elif self.types.get(key) == "array":
                try:
                    self._data[index.row()][key] = json.loads(value)
                except:
                    pass
            elif self.types.get(key) == "godot_array":
                # 更新 Godot Array 的原始值
                if isinstance(self._data[index.row()][key], dict):
                    self._data[index.row()][key]['raw_value'] = value
                else:
                    self._data[index.row()][key] = {
                        'type': 'godot_array',
                        'raw_value': value
                    }
            elif self.types.get(key) in ("ext_resource", "sub_resource"):
                # 更新资源引用的原始值
                if isinstance(self._data[index.row()][key], dict):
                    self._data[index.row()][key]['raw_value'] = value
                else:
                    self._data[index.row()][key] = {
                        'type': self.types.get(key),
                        'raw_value': value
                    }
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