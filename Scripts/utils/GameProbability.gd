# GameProbability.gd
# 高性能游戏概率系统 - 优化版
class_name GameProbability extends RefCounted

# 性能优化：使用整数运算替代浮点运算
const PRECISION = 10000  # 精度：0.0001 (万分之一)
const HALF_PRECISION = PRECISION / 2

# 预计算的随机数池 (减少系统调用)
var _random_pool: PackedInt32Array = []
var _pool_index: int = 0
var _pool_size: int = 1024  # 随机数池大小

# 伪随机种子 (可控的随机性)
var _seed_state: int = 0

# 保底机制状态 (提升真实感)
var _pity_counters: Dictionary = {}  # 保底计数器
var _streak_counters: Dictionary = {}  # 连续失败计数器

func _ready():
    _initialize_random_pool()

# 初始化随机数池
func _initialize_random_pool():
    _random_pool.resize(_pool_size)
    for i in range(_pool_size):
        _random_pool[i] = randi()

# 高性能随机数获取
func _get_fast_random() -> int:
    if _pool_index >= _pool_size:
        _refill_random_pool()
    
    var result = _random_pool[_pool_index]
    _pool_index += 1
    return result

# 重新填充随机数池
func _refill_random_pool():
    for i in range(_pool_size):
        _random_pool[i] = randi()
    _pool_index = 0

# === 核心概率函数 (整数优化版) ===

# 基础概率判断 (整数运算，高性能)
func chance_fast(probability_int: int) -> bool:
    """
    使用整数进行概率判断，避免浮点运算
    probability_int: 0 到 PRECISION 之间的整数 (例如: 3000 = 30%)
    """
    return (_get_fast_random() % PRECISION) < probability_int

# 标准概率判断 (兼容浮点)
func chance(probability: float) -> bool:
    """
    标准概率判断，内部转换为整数运算
    probability: 0.0 到 1.0 之间的概率值
    """
    var prob_int = int(clamp(probability, 0.0, 1.0) * PRECISION)
    return chance_fast(prob_int)

# 百分比版本 (整数优化)
func percent(percentage: int) -> bool:
    """
    百分比概率判断 (0-100)
    percentage: 0 到 100 之间的整数
    """
    return chance_fast(percentage * (PRECISION / 100))

# === 游戏特化功能 ===

# 保底概率 (真实感提升)
func chance_with_pity(probability: float, pity_key: String, max_attempts: int = 100) -> bool:
    """
    带保底机制的概率判断，提升玩家体验
    probability: 基础概率
    pity_key: 保底计数器的唯一键
    max_attempts: 最大失败次数，达到后必定成功
    """
    if not _pity_counters.has(pity_key):
        _pity_counters[pity_key] = 0
    
    var attempts = _pity_counters[pity_key]
    
    # 保底机制：失败次数越多，概率越高
    var boosted_prob = probability
    if attempts > max_attempts * 0.7:  # 超过70%次数后开始提升概率
        var boost_factor = float(attempts - max_attempts * 0.7) / (max_attempts * 0.3)
        boosted_prob = lerp(probability, 1.0, boost_factor * 0.5)  # 最多提升50%
    
    # 强制保底
    if attempts >= max_attempts:
        _pity_counters[pity_key] = 0
        return true
    
    # 正常判断
    if chance(boosted_prob):
        _pity_counters[pity_key] = 0
        return true
    else:
        _pity_counters[pity_key] += 1
        return false

# 防连败系统 (避免玩家体验过差)
func chance_anti_streak(probability: float, streak_key: String, max_fails: int = 5) -> bool:
    """
    防连败概率系统，连续失败后提升成功率
    probability: 基础概率
    streak_key: 连败计数器的唯一键
    max_fails: 最大连续失败次数
    """
    if not _streak_counters.has(streak_key):
        _streak_counters[streak_key] = 0
    
    var streak = _streak_counters[streak_key]
    var adjusted_prob = probability
    
    # 连败后提升概率
    if streak > 0:
        var boost = min(streak * 0.1, 0.5)  # 每次失败提升10%，最多50%
        adjusted_prob = min(probability + boost, 0.95)  # 最高95%
    
    if chance(adjusted_prob):
        _streak_counters[streak_key] = 0
        return true
    else:
        _streak_counters[streak_key] += 1
        return false

# 高性能加权选择 (整数优化)
func weighted_choice_fast(weights: PackedInt32Array) -> int:
    """
    高性能加权选择，使用整数权重
    weights: 整数权重数组
    返回: 选中的索引，失败返回 -1
    """
    if weights.is_empty():
        return -1
    
    var total_weight = 0
    for weight in weights:
        total_weight += weight
    
    if total_weight <= 0:
        return -1
    
    var random_value = _get_fast_random() % total_weight
    var cumulative = 0
    
    for i in range(weights.size()):
        cumulative += weights[i]
        if random_value < cumulative:
            return i
    
    return weights.size() - 1  # 容错处理

# 标准加权选择
func weighted_choice(items: Array, weights: Array):
    """
    标准加权选择，兼容浮点权重
    """
    if items.size() != weights.size() or items.is_empty():
        return null
    
    # 转换为整数权重
    var int_weights = PackedInt32Array()
    for weight in weights:
        int_weights.append(int(weight * 1000))  # 保留3位小数精度
    
    var index = weighted_choice_fast(int_weights)
    return items[index] if index >= 0 else null

# === 游戏专用概率模式 ===

# 渐进概率 (越使用概率越高，适合技能熟练度)
func progressive_chance(base_prob: float, progress_key: String, increment: float = 0.01) -> bool:
    """
    渐进概率系统，使用次数越多成功率越高
    base_prob: 基础概率
    progress_key: 进度键
    increment: 每次使用的概率增量
    """
    if not _pity_counters.has(progress_key):
        _pity_counters[progress_key] = 0
    
    var usage_count = _pity_counters[progress_key]
    var current_prob = min(base_prob + usage_count * increment, 0.95)
    
    _pity_counters[progress_key] += 1
    return chance(current_prob)

# 衰减概率 (连续成功后概率降低，适合暴击系统)
func decay_chance(base_prob: float, decay_key: String, decay_rate: float = 0.8) -> bool:
    """
    衰减概率系统，连续成功后概率降低
    base_prob: 基础概率
    decay_key: 衰减键
    decay_rate: 衰减率 (0.8 = 每次成功后概率变为80%)
    """
    if not _streak_counters.has(decay_key):
        _streak_counters[decay_key] = 0
    
    var success_streak = _streak_counters[decay_key]
    var current_prob = base_prob * pow(decay_rate, success_streak)
    current_prob = max(current_prob, base_prob * 0.1)  # 最低保持10%基础概率
    
    if chance(current_prob):
        _streak_counters[decay_key] += 1
        return true
    else:
        _streak_counters[decay_key] = 0
        return false

# === 性能优化的批量操作 ===

# 批量概率判断 (减少函数调用开销)
func batch_chance(probabilities: Array) -> Array:
    """
    批量进行概率判断，提升性能
    probabilities: 概率数组
    返回: 布尔结果数组
    """
    var results = []
    results.resize(probabilities.size())
    
    for i in range(probabilities.size()):
        results[i] = chance(probabilities[i])
    
    return results

# 预计算概率表 (对于固定概率的高频调用)
var _probability_tables: Dictionary = {}

func create_probability_table(table_name: String, probability: float, size: int = 1000):
    """
    创建预计算的概率表，适用于高频固定概率判断
    table_name: 表名
    probability: 概率值
    size: 表大小
    """
    var table = PackedByteArray()
    table.resize(size)
    
    for i in range(size):
        table[i] = 1 if chance(probability) else 0
    
    _probability_tables[table_name] = {
        "table": table,
        "index": 0,
        "size": size
    }

func table_chance(table_name: String) -> bool:
    """
    使用预计算表进行概率判断，极高性能
    """
    if not _probability_tables.has(table_name):
        return false
    
    var table_data = _probability_tables[table_name]
    var result = table_data.table[table_data.index] == 1
    
    table_data.index = (table_data.index + 1) % table_data.size
    return result

# === 调试和性能监控 ===

# 性能测试
func benchmark_methods(iterations: int = 100000):
    """
    性能基准测试
    """
    var start_time = Time.get_ticks_usec()
    
    # 测试标准方法
    var standard_hits = 0
    for i in range(iterations):
        if chance(0.5):
            standard_hits += 1
    var standard_time = Time.get_ticks_usec() - start_time
    
    # 测试快速方法
    start_time = Time.get_ticks_usec()
    var fast_hits = 0
    for i in range(iterations):
        if chance_fast(HALF_PRECISION):
            fast_hits += 1
    var fast_time = Time.get_ticks_usec() - start_time
    
    # 测试表查找方法
    create_probability_table("benchmark", 0.5, 1000)
    start_time = Time.get_ticks_usec()
    var table_hits = 0
    for i in range(iterations):
        if table_chance("benchmark"):
            table_hits += 1
    var table_time = Time.get_ticks_usec() - start_time
    
    print("=== 性能基准测试 ===")
    print("迭代次数: ", iterations)
    print("标准方法: ", standard_time, "μs, 命中: ", standard_hits)
    print("快速方法: ", fast_time, "μs, 命中: ", fast_hits)
    print("表查找法: ", table_time, "μs, 命中: ", table_hits)
    print("性能提升: 快速方法 ", float(standard_time) / fast_time, "x")
    print("性能提升: 表查找法 ", float(standard_time) / table_time, "x")

# 重置所有状态
func reset_all_states():
    """
    重置所有保底和连击状态
    """
    _pity_counters.clear()
    _streak_counters.clear()
    _probability_tables.clear()
    _initialize_random_pool()

# 获取状态信息
func get_state_info() -> Dictionary:
    """
    获取当前系统状态信息
    """
    return {
        "pity_counters": _pity_counters.duplicate(),
        "streak_counters": _streak_counters.duplicate(),
        "probability_tables": _probability_tables.keys(),
        "random_pool_index": _pool_index,
        "random_pool_size": _pool_size
    }