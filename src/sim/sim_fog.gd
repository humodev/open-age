class_name SimFog
extends RefCounted
## Visión por jugador (docs/05, "Visión y niebla"). 0 = sin explorar, 1 = explorado, 2 = visible.
## Vive en la simulación porque sigilo y emboscada (H2) dependen de ella.

const P := 1000

var n: int
var grids: Array[PackedByteArray] = []
var _circles := {} # radio en casillas -> PackedInt32Array de pares (dx, dy)


func _init(size: int, num_players: int) -> void:
	n = size
	for i in num_players:
		var g := PackedByteArray()
		g.resize(n * n)
		grids.append(g)


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


# --- rendimiento 4 --- Pintado incremental (proceso/32-ronda-8/09). Cada círculo distinto
# (casilla, radio) cuenta en las casillas que cubre; solo se pintan los círculos que aparecen y
# se despintan los que desaparecen. Visible (2) = cuenta > 0, como la unión de antes; al llegar
# a 0 queda explorada (1). La grilla queda igual que repintando todo.
var _cnt: Array[PackedInt32Array] = [] # por jugador: círculos que cubren cada casilla
var _keys: Array[Dictionary] = [] # por jugador: círculos pintados (clave -> true)
var _own: PackedByteArray = PackedByteArray() # 1 si la grilla del jugador viene de su propio `update`
var _diff: Array[PackedInt32Array] = [] # por jugador: casillas que cambiaron en el último `update`
var _ver := PackedInt32Array() # por jugador: cuántos `update` lleva
var _synced := PackedInt32Array() # por jugador: versión de la fuente que copió la última vez (-1: ninguna)
var _synced_src := PackedInt32Array()


func _ensure(np: int) -> void:
	if _cnt.size() == np:
		return
	for i in range(_cnt.size(), np):
		var c := PackedInt32Array()
		c.resize(n * n)
		_cnt.append(c)
		_keys.append({})
		_own.append(0)
		_diff.append(PackedInt32Array())
		_ver.append(0)
		_synced.append(-1)
		_synced_src.append(-1)


func update(pid: int, sources: Array) -> void:
	_ensure(grids.size())
	var g := grids[pid]
	var cnt := _cnt[pid]
	if _own[pid] == 0:
		# La grilla venía de copiar a un aliado: lo visible pasa a explorado y se cuenta de cero.
		for i in g.size():
			if g[i] == 2:
				g[i] = 1
		cnt.fill(0)
		_keys[pid] = {}
		_own[pid] = 1
	var cur := {} # (casilla, radio) de este turno: en un ejército apretado se repiten mucho
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
		cur[(cy * n + cx) * 64 + r] = true
	var old: Dictionary = _keys[pid]
	var diff := PackedInt32Array()
	# Primero se despinta: una casilla que se va y vuelve en el mismo turno queda en 2.
	for k: int in old:
		if not cur.has(k):
			_paint(g, cnt, k, -1, diff)
	for k: int in cur:
		if not old.has(k):
			_paint(g, cnt, k, 1, diff)
	_keys[pid] = cur
	_diff[pid] = diff
	_ver[pid] += 1


## Suma `d` (1 o -1) a la cuenta de las casillas del círculo de la clave `k`; anota en `diff`
## las que pasan de 0 a 1 (quedan visibles) o de 1 a 0 (quedan exploradas).
func _paint(g: PackedByteArray, cnt: PackedInt32Array, k: int, d: int, diff: PackedInt32Array) -> void:
	var r := k % 64
	var c := k / 64
	var cx := c % n
	var cy := c / n
	# Por renglones (proceso/32-ronda-8/04): las mismas casillas que `_circle(r)`.
	var half := _spans(r)
	for dy in range(-r, r + 1):
		var y := cy + dy
		if y < 0 or y >= n:
			continue
		var w := half[dy + r]
		var row := y * n
		for idx in range(row + maxi(0, cx - w), row + mini(n - 1, cx + w) + 1):
			var v := cnt[idx] + d
			cnt[idx] = v
			if d > 0:
				if v == 1:
					g[idx] = 2
					diff.append(idx)
			elif v == 0:
				g[idx] = 1
				diff.append(idx)


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
## Lo explorado propio se conserva: solo se suma lo visible del aliado. Si la última copia fue
## de la versión anterior del aliado, alcanza con las casillas que cambiaron en su `update`;
## si no, se recorre toda la grilla.
func copy_from(pid: int, src: int) -> void:
	_ensure(grids.size())
	var g := grids[pid]
	var gs := grids[src]
	if _own[pid] == 0 and _synced_src[pid] == src and _synced[pid] == _ver[src] - 1:
		for idx in _diff[src]:
			g[idx] = gs[idx]
	else:
		for i in g.size():
			if gs[i] == 2:
				g[i] = 2
			elif g[i] == 2:
				g[i] = 1
	_own[pid] = 0
	_synced[pid] = _ver[src]
	_synced_src[pid] = src


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
