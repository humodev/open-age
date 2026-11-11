class_name SimRng
extends RefCounted
## xorshift32 en enteros: igual en toda plataforma.

var state: int


func _init(seed_value: int) -> void:
	state = (seed_value & 0xffffffff) | 1


func next() -> int:
	var x := state
	x ^= (x << 13) & 0xffffffff
	x ^= x >> 17
	x ^= (x << 5) & 0xffffffff
	state = x & 0xffffffff
	return state


## Entero en [lo, hi].
func range_i(lo: int, hi: int) -> int:
	return lo + next() % (hi - lo + 1)
