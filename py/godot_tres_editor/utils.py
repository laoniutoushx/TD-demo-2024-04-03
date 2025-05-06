import os
import re
import json

def parse_tres(filepath):
    """解析 .tres 文件，提取资源类和字段"""
    with open(filepath, encoding='utf-8') as f:
        content = f.read()
    
    match = re.search(r'\[gd_resource.*?script_class="(.*?)".*?\]', content)
    script_class = match.group(1) if match else None
    resource_match = re.search(r'\[resource\](.*)', content, re.DOTALL)
    resource_block = resource_match.group(1).strip() if resource_match else ""
    
    fields = {}
    
    for line in resource_block.splitlines():
        if "=" not in line:
            continue
        key, value = map(str.strip, line.split("=", 1))
        
        # 处理 null 值
        if value == "null":
            fields[key] = None
        # 处理 Godot 4 的 Array 引用
        elif value.startswith('Array['):
            # 保存原始格式，以便后续保存时保持一致
            fields[key] = {
                'type': 'godot_array',
                'raw_value': value,
                'parsed_value': parse_godot_array(value)
            }
        # 处理 ExtResource 引用
        elif value.startswith("ExtResource"):
            fields[key] = {
                'type': 'ext_resource',
                'raw_value': value
            }
        # 处理 SubResource 引用
        elif value.startswith("SubResource"):
            fields[key] = {
                'type': 'sub_resource',
                'raw_value': value
            }
        # 处理布尔值
        elif value in ("true", "false"):
            fields[key] = value == "true"
        # 处理字符串 - 使用双引号作为判断依据
        elif value.startswith('"') and value.endswith('"'):
            fields[key] = {
                'type': 'string',
                'value': value[1:-1]
            }
        # 处理数字
        else:
            try:
                fields[key] = float(value) if '.' in value else int(value)
            except:
                # 如果不是数字，则标记为其他类型
                fields[key] = {
                    'type': 'other',
                    'raw_value': value
                }

    return script_class, fields

def parse_godot_array(array_str):
    """解析 Godot 的 Array 结构"""
    try:
        # 提取 Array 类型和内容
        match = re.match(r'Array\[(.*?)\]\((.*)\)', array_str)
        if match:
            array_type = match.group(1)
            array_content = match.group(2)
            
            # 尝试解析数组内容
            if array_content.strip() == '[]':
                return []
            
            # 这里可以进一步解析数组内容，但需要更复杂的逻辑
            # 暂时返回原始内容
            return {
                'type': array_type,
                'content': array_content
            }
        return array_str
    except Exception as e:
        print(f"解析 Godot Array 失败: {str(e)}")
        return array_str

def detect_types(sample):
    """检测数据类型"""
    types = {}
    for k, v in sample.items():
        if k.startswith('_'):  # 跳过内部字段
            continue
            
        if isinstance(v, bool):
            types[k] = "bool"
        elif isinstance(v, int):
            types[k] = "int"
        elif isinstance(v, float):
            types[k] = "float"
        elif isinstance(v, list):
            types[k] = "array"
        elif isinstance(v, dict):
            # 根据字典中的类型字段判断
            if 'type' in v:
                if v['type'] == 'godot_array':
                    types[k] = "godot_array"
                elif v['type'] in ('ext_resource', 'sub_resource'):
                    types[k] = v['type']
                elif v['type'] == 'string':
                    types[k] = "string"
                elif v['type'] == 'other':
                    types[k] = "other"
                else:
                    types[k] = v['type']
            else:
                types[k] = "dict"
        else:
            # 如果是简单字符串，也标记为字符串类型
            if isinstance(v, str):
                types[k] = "string"
            else:
                types[k] = "unknown"
    return types

def save_tres_file(filepath, item):
    """保存 .tres 文件，保留所有资源引用"""
    try:
        with open(filepath, 'r', encoding='utf-8') as f:
            content = f.read()
        
        # 分离文件的三个主要部分：头部、资源引用和资源块
        header_match = re.search(r'(\[gd_resource.*?\])', content, re.DOTALL)
        if not header_match:
            return False
        
        header = header_match.group(1)
        
        # 提取资源引用部分（位于头部和资源块之间的所有内容）
        resource_start = content.find("[resource]")
        if resource_start == -1:
            return False
            
        references_section = content[len(header):resource_start].strip()
        
        # 生成新的资源块
        resource_block = "[resource]\n"
        
        for key, value in item.items():
            if key.startswith('_'):  # 跳过内部字段
                continue
                
            # 根据类型格式化值
            if value is None:
                # 特殊处理 null 值
                formatted_value = "null"
            elif isinstance(value, bool):
                formatted_value = "true" if value else "false"
            elif isinstance(value, (int, float)):
                formatted_value = str(value)
            elif isinstance(value, dict):
                if value.get('type') == 'godot_array':
                    # 使用原始格式保存 Godot Array
                    formatted_value = value.get('raw_value')
                elif value.get('type') in ('ext_resource', 'sub_resource'):
                    # 使用原始格式保存资源引用
                    formatted_value = value.get('raw_value')
                elif value.get('type') == 'string':
                    # 为字符串添加双引号
                    formatted_value = f'"{value.get("value")}"'
                elif value.get('type') == 'other':
                    # 保持原始格式
                    formatted_value = value.get('raw_value')
                else:
                    # 未知类型，尝试转换为字符串
                    formatted_value = f'"{str(value)}"'
            elif isinstance(value, list):
                # 为普通数组生成 Godot 格式
                formatted_value = f"[{', '.join(map(str, value))}]"
            elif isinstance(value, str) and (value.startswith("ExtResource") or value.startswith("SubResource")):
                # 保持原始资源引用格式
                formatted_value = value
            else:
                # 为字符串添加引号
                formatted_value = f'"{value}"'
            
            resource_block += f"{key} = {formatted_value}\n"
        
        # 合并所有部分：头部、资源引用和新的资源块
        new_content = f"{header}\n\n{references_section}\n\n{resource_block}"
        
        # 将更新后的内容写回文件
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(new_content)
        
        return True
    except Exception as e:
        print(f"保存文件失败: {str(e)}")
        return False