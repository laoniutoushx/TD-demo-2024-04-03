# CoroutineNode.gd
extends Node
class_name CoroutineNode

var _running: Array = []   # 不用写 Array[GDScriptFunctionState]，编辑器会报错

func start_coroutine(func_ref: Callable):
    var state = func_ref.call() # state 实际就是 GDScriptFunctionState
    if state and state is GDScriptFunctionState:
        _running.append(state)
        _resume(state)

func _resume(state):
    if not state.is_valid():
        return
    if state.is_completed():
        _running.erase(state)
        return
    state.completed.connect(func():
        _running.erase(state)
    )
    state.resume()

func stop_all_coroutines():
    _running.clear()

func _exit_tree():
    stop_all_coroutines()
