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


var map: SimMap
var vision_per_level := 0
var site_vision := 0 # --- esport 3a --- casillas que se ven alrededor de cada sitio sagrado, para todos
var vision_extra := {} # --- paso 6, par 2 --- dueño -> {tipo de edificio: visión extra} (aviso de los mocambos)


func update(pid: int, sources: Array) -> void:
	var g := grids[pid]
	var prev := _visible[pid]
	for idx in prev:
		g[idx] = 1
	var now := PackedInt32Array()
	var done := {} # (casilla, radio) ya pintados: en un ejército apretado se repiten mucho
	for e: SimEntity in sources:
		var cx := e.x / P
		var cy := e.y / P
		var r: int = int(e.def.get("vision", 0)) / P
		if e.owner < 0 and e.def.get("sagrado", false):
			r = site_vision
		elif map != null:
			r += map.h_at(cx, cy) * vision_per_level / P
		if e.is_building() and e.owner >= 0:
			r += maxi(e.w, e.h) / 2
			if not vision_extra.is_empty():
				r += int((vision_extra.get(e.owner, {}) as Dictionary).get(e.type, 0)) / P
		var key := (cy * n + cx) * 64 + r
		if done.has(key):
			continue
		done[key] = true
		# Por renglones (proceso/32-ronda-8/04): las mismas casillas que `_circle(r)`, sin
		# mirar el borde ni leer el desplazamiento de a una.
		var half := _spans(r)
		for dy in range(-r, r + 1):
			var y := cy + dy
			if y < 0 or y >= n:
				continue
			var w := half[dy + r]
			var row := y * n
			for idx in range(row + maxi(0, cx - w), row + mini(n - 1, cx + w) + 1):
				if g[idx] != 2:
					g[idx] = 2
					now.append(idx)
	_visible[pid] = now


var _half := {} # radio -> ancho a cada lado de cada renglón del círculo de `_circle`
func _spans(r: int) -> PackedInt32Array:
	if _half.has(r):
		return _half[r]
	var out := PackedInt32Array()
	for dy in range(-r, r + 1):
		var w := -1
		for dx in range(0, r + 1):
			if dx * dx + dy * dy <= r * r + r:
				w = dx
		out.append(w)
	_half[r] = out
	return out


## Mismo estado de visión que un aliado (visión compartida, ya calculada en el tick).
## Lo explorado propio se conserva: solo se suma lo visible del aliado.
func copy_from(pid: int, src: int) -> void:
	var g := grids[pid]
	for idx in _visible[pid]:
		g[idx] = 1
	var now := _visible[src]
	for idx in now:
		g[idx] = 2
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
