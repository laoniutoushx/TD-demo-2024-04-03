# ProbabilityController.gd
# 独立概率控制器
class_name ProbabilityController
extends RefCounted

enum Strategy {
    SIMPLE_RANDOM,
    ACCUMULATOR,
    DETERMINISTIC
}

var strategy: Strategy
var chance: float
var accumulator: float = 0.0
var counter: int = 0
var trigger_every: int = 1
var offset: int = 0

func _init(_chance: float, _strategy := Strategy.SIMPLE_RANDOM):
    chance = _chance
    strategy = _strategy

    match strategy:
        Strategy.SIMPLE_RANDOM:
            pass  # nothing needed
        Strategy.ACCUMULATOR:
            accumulator = 0.0
        Strategy.DETERMINISTIC:
            trigger_every = max(1, int(1.0 / chance))
            offset = randi() % trigger_every

func next() -> bool:
    match strategy:
        Strategy.SIMPLE_RANDOM:
            return randf() < chance

        Strategy.ACCUMULATOR:
            accumulator += chance
            if accumulator >= 1.0:
                accumulator -= 1.0
                return true
            return false

        Strategy.DETERMINISTIC:
            var result = (counter + offset) % trigger_every == 0
            counter += 1
            return result

    return false
