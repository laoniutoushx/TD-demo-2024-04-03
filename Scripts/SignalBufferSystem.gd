# SignalBufferSystem.gd
extends Node

var _signal_buffers = {}

func buffer_signal(_signal: Signal, callable: Callable):
	var signal_name = _signal.get_name()
	if not _signal_buffers.has(signal_name):
		_signal_buffers[signal_name] = []
	
	_signal_buffers[signal_name].append(callable)

func connect_buffered(_signal: Signal, callable: Callable):
	# 首先正常连接信号
	_signal.connect(callable)
	
	# 检查是否有缓冲的信号
	var signal_name = _signal.get_name()

	if _signal_buffers.has(signal_name):
		var buffered_signals = _signal_buffers[signal_name]
		for args in buffered_signals:
			_signal.emit(args)
		
		# 清除已处理的缓冲信号
		_signal_buffers[signal_name].clear()

# 在项目的自动加载中添加这个脚本
