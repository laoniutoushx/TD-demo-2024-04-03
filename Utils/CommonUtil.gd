class_name CommonUtil
extends Node


static func waiting_for(second: float):
	if second > 0:
		var timer = Timer.new()
		timer.start(second)
		await timer.timeout
		timer.queue_free()
	
