class_name RingBufferDic extends Node


enum PopMode {LIFO, FIFO}
@export var maxHistoryEntries := 32
var history := {}
var hwm := 0 # high water mark
var LIFO := -1 # -1 means buffer empty
var FIFO := -1 # -1 means buffer empty
var pop_counter := 0


func push_history(item):
	if pop_counter < maxHistoryEntries: pop_counter += 1
	if pop_counter > hwm: hwm = pop_counter
	LIFO = posmod(LIFO + 1, hwm)
	if LIFO == FIFO: FIFO = posmod(FIFO + 1, hwm)
	if FIFO == -1: FIFO = 0
	history[LIFO] = item


func pop_history(pop_mode: int = PopMode.LIFO):
	if pop_counter == 0: return null
	var result
	pop_counter -= 1
	
	if pop_mode == PopMode.LIFO:
		result = history[LIFO]
		LIFO = wrapi(LIFO - 1, 0, hwm)
		if pop_counter == 1: FIFO = LIFO
	else:
		result = history[FIFO]
		FIFO = wrapi(FIFO + 1, 0, hwm)
		if pop_counter == 1: LIFO = FIFO
	
	if pop_counter == 0:
		LIFO = -1
		FIFO = -1
	
	return result



"""
# Test script
class_name RingBufferDic extends Node

enum Mode {PUSH, POP}

enum PopMode {LIFO, FIFO}
export(int) var maxHistoryEntries := 4
var history := {}
var hwm := 0 # Buffer high water mark
var LIFO := -1 # -1 means buffer empty
var FIFO := -1 # -1 means buffer empty
var pop_counter := 0
var index :=0

var timer_start: int
var timer_stop: int
var x


func push_history():
	if pop_counter < maxHistoryEntries: pop_counter += 1
	if pop_counter > hwm: hwm = pop_counter
	LIFO = posmod(LIFO + 1, hwm)
	if LIFO == FIFO: FIFO = posmod(FIFO + 1, hwm)
	if FIFO == -1: FIFO = 0
	history[LIFO] = index
	index += 1


func pop_history(pop_mode: int = PopMode.LIFO):
	if pop_counter == 0: return null
	var result
	pop_counter -= 1
	
	if pop_mode == PopMode.LIFO:
		result = history[LIFO]
		history[LIFO] = null # DEBUG ONLY!!
		LIFO = wrapi(LIFO - 1, 0, hwm)
		if pop_counter == 1: FIFO = LIFO
	else:
		result = history[FIFO]
		history[FIFO] = null # DEBUG ONLY!!
		FIFO = wrapi(FIFO + 1, 0, hwm)
		if pop_counter == 1: LIFO = FIFO
	
	if pop_counter == 0:
		LIFO = -1
		FIFO = -1
	
	return result


func print_history(mode: int, val = null, pop_mode = PopMode.LIFO):
	var s: String
	for j in history.size():
		s += str(j) + "=" + str(history[j]) + "; "
	print(s)
	if mode == Mode.PUSH:
		print(
			"popcounter=", pop_counter,
			"; LIFO idx=", LIFO,
			"; FIFO idx=", FIFO
		)
	else:
		print(
			"popcounter=", pop_counter,
			"; LIFO idx=", LIFO,
			"; FIFO idx=", FIFO,
			"; popped val=", val,
			"; pop method=", PopMode.keys()[pop_mode]
		)
	print()
	

func instrument(mode: int):
	if mode == 0:
		# stop
		timer_stop = OS.get_ticks_msec()
		if timer_stop > timer_start:
			print("took: ", (timer_stop - timer_start) * 0.001, " secs")
	else:
		# start
		timer_start = OS.get_ticks_msec()


func _ready():
	randomize()
	
	for i in range(0, 1 + (randi() % 10)):
		push_history()
		print_history(Mode.PUSH)

	for i in range(0, 1 + (randi() % 10)):
		var m: int = randi() % 2
		x = pop_history(m)
		print_history(Mode.POP, x, m)
	
	for i in range(0, 1 + (randi() % 10)):
		push_history()
		print_history(Mode.PUSH)

	for i in range(0, 1 + (randi() % 10)):
		var m: int = randi() % 2
		x = pop_history(m)
		print_history(Mode.POP, x, m)
"""
