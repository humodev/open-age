class_name SimFog
extends RefCounted
## Visión por jugador (docs/05, "Visión y niebla"). 0 = sin explorar, 1 = explorado, 2 = visible.
## Vive en la simulación porque sigilo y emboscada (H2) dependen de ella.

const P := 1000

var n: int
var grids: Array[PackedByteArray] = []
var _visible: Array[PackedInt32Array] = [] # celdas visibles en la última pasada
var _circles := {} # radio en casillas -> PackedInt32Array de pares (dx, dy)


func _init(size: int, num_players: int) -> void:
	n = size
	for i in num_players:
		var g := PackedByteArray()
		g.resize(n * n)
		grids.append(g)
		_visible.append(PackedInt32Array())


func _circle(r: int) -> PackedInt32Array:
	if _circles.has(r):
		return _circles[r]
	var out := PackedInt32Array()
	for dy in range(-r, r + 1):
		for dx in range(-r, r + 1):
			if dx * dx + dy * dy <= r * r + r:
				out.append(dx)
				out.append(dy)
	_circles[r] = out
	return out


func update(pid: int, sources: Array) -> void:
	var g := grids[pid]
	var prev := _visible[pid]
	for idx in prev:
		g[idx] = 1
	var now := PackedInt32Array()
	for e: SimEntity in sources:
		var cx := e.x / P
		var cy := e.y / P
		var r: int = int(e.def.get("vision", 0)) / P
		if e.is_building():
			r += maxi(e.w, e.h) / 2
		var offs := _circle(r)
		for k in range(0, offs.size(), 2):
			var x := cx + offs[k]
			var y := cy + offs[k + 1]
			if x < 0 or y < 0 or x >= n or y >= n:
				continue
			var idx := y * n + x
			if g[idx] != 2:
				g[idx] = 2
				now.append(idx)
	_visible[pid] = now


func state(pid: int, tx: int, ty: int) -> int:
	if tx < 0 or ty < 0 or tx >= n or ty >= n:
		return 0
	return grids[pid][ty * n + tx]


func is_visible(pid: int, e: SimEntity) -> bool:
	if e.is_unit():
		return state(pid, e.x / P, e.y / P) == 2
	for yy in range(e.ty, e.ty + e.h):
		for xx in range(e.tx, e.tx + e.w):
			if state(pid, xx, yy) == 2:
				return true
	return false


func is_explored(pid: int, e: SimEntity) -> bool:
	return state(pid, e.tx + e.w / 2, e.ty + e.h / 2) >= 1 if not e.is_unit() else state(pid, e.x / P, e.y / P) >= 1
