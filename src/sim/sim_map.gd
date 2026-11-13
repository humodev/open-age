class_name SimMap
extends RefCounted
## Grilla del mapa: casillas sólidas, puertas, ocupación para construir y búsqueda de caminos.
## Cada jugador tiene su propia grilla de caminos porque sus puertas solo lo dejan pasar a él.

const P := 1000

var n: int
var solid := PackedByteArray() # bloquea a todos
var gate_owner := PackedInt32Array() # dueño de la puerta en la casilla, -1 sin puerta
var occupied := PackedInt32Array() # id de la entidad que ocupa la casilla, -1 libre, -3 agua
var height := PackedByteArray() # nivel de altura entero (D-027)
var water := PackedByteArray() # 0 tierra, 1 agua profunda (sólida), 2 vado (transitable, no edificable)
var astar: AStarGrid2D # puertas cerradas para todos
var astars: Array[AStarGrid2D] = [] # una por jugador


func _init(size: int, num_players: int = 2) -> void:
	n = size
	solid.resize(n * n)
	occupied.resize(n * n)
	occupied.fill(-1)
	gate_owner.resize(n * n)
	gate_owner.fill(-1)
	height.resize(n * n)
	water.resize(n * n)
	astar = _new_astar()
	for i in num_players:
		astars.append(_new_astar())


func _new_astar() -> AStarGrid2D:
	var a := AStarGrid2D.new()
	a.region = Rect2i(0, 0, n, n)
	a.cell_size = Vector2(1, 1)
	a.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	a.default_compute_heuristic = AStarGrid2D.HEURISTIC_OCTILE
	a.default_estimate_heuristic = AStarGrid2D.HEURISTIC_OCTILE
	a.update()
	return a


func _grid(pid: int) -> AStarGrid2D:
	return astars[pid] if pid >= 0 and pid < astars.size() else astar


func in_bounds(tx: int, ty: int) -> bool:
	return tx >= 0 and ty >= 0 and tx < n and ty < n


## Sólida para el jugador `pid` (-1: puertas cerradas para todos).
func is_solid(tx: int, ty: int, pid: int = -1) -> bool:
	if not in_bounds(tx, ty):
		return true
	var idx := ty * n + tx
	if solid[idx] != 0:
		return true
	var g := gate_owner[idx]
	return g >= 0 and g != pid


func occupant(tx: int, ty: int) -> int:
	if not in_bounds(tx, ty):
		return -2
	return occupied[ty * n + tx]


func is_free_rect(tx: int, ty: int, w: int, h: int) -> bool:
	for yy in range(ty, ty + h):
		for xx in range(tx, tx + w):
			if occupant(xx, yy) != -1:
				return false
	return true


func mark(tx: int, ty: int, w: int, h: int, id: int, blocks: bool, gate_pid: int = -1) -> void:
	for yy in range(ty, ty + h):
		for xx in range(tx, tx + w):
			if not in_bounds(xx, yy):
				continue
			var idx := yy * n + xx
			var cell := Vector2i(xx, yy)
			occupied[idx] = id
			if gate_pid >= 0:
				gate_owner[idx] = gate_pid
				astar.set_point_solid(cell, true)
				for p in astars.size():
					astars[p].set_point_solid(cell, p != gate_pid)
			elif blocks:
				solid[idx] = 1
				astar.set_point_solid(cell, true)
				for a in astars:
					a.set_point_solid(cell, true)


func clear(tx: int, ty: int, w: int, h: int) -> void:
	for yy in range(ty, ty + h):
		for xx in range(tx, tx + w):
			if not in_bounds(xx, yy):
				continue
			var idx := yy * n + xx
			var cell := Vector2i(xx, yy)
			occupied[idx] = -1
			solid[idx] = 0
			gate_owner[idx] = -1
			astar.set_point_solid(cell, false)
			for a in astars:
				a.set_point_solid(cell, false)


## ¿La huella tiene al menos una casilla vecina libre?
func has_free_neighbor(tx: int, ty: int, w: int, h: int, pid: int = -1) -> bool:
	for xx in range(tx - 1, tx + w + 1):
		if not is_solid(xx, ty - 1, pid) or not is_solid(xx, ty + h, pid):
			return true
	for yy in range(ty, ty + h):
		if not is_solid(tx - 1, yy, pid) or not is_solid(tx + w, yy, pid):
			return true
	return false


## Casilla libre más cercana a (tx, ty) buscando en anillos.
func nearest_free(tx: int, ty: int, max_r: int = 12, pid: int = -1) -> Vector2i:
	if not is_solid(tx, ty, pid):
		return Vector2i(tx, ty)
	for r in range(1, max_r + 1):
		for dy in range(-r, r + 1):
			for dx in range(-r, r + 1):
				if absi(dx) != r and absi(dy) != r:
					continue
				if not is_solid(tx + dx, ty + dy, pid):
					return Vector2i(tx + dx, ty + dy)
	return Vector2i(-1, -1)


func find_path(from: Vector2i, to: Vector2i, pid: int = -1) -> Array[Vector2i]:
	if is_solid(from.x, from.y, pid):
		return [] as Array[Vector2i]
	to = Vector2i(clampi(to.x, 0, n - 1), clampi(to.y, 0, n - 1))
	return _grid(pid).get_id_path(from, to, true)


func h_at(tx: int, ty: int) -> int:
	if not in_bounds(tx, ty):
		return 0
	return height[ty * n + tx]


func is_water(tx: int, ty: int) -> bool:
	return in_bounds(tx, ty) and water[ty * n + tx] != 0


## Agua: la profunda es sólida para todos; el vado se camina pero no se edifica.
func set_water(tx: int, ty: int, kind: int) -> void:
	if not in_bounds(tx, ty):
		return
	var idx := ty * n + tx
	water[idx] = kind
	height[idx] = 0
	occupied[idx] = -3
	if kind == 1:
		solid[idx] = 1
		var cell := Vector2i(tx, ty)
		astar.set_point_solid(cell, true)
		for a in astars:
			a.set_point_solid(cell, true)


## ¿Huella pareja y en tierra?
func is_flat(tx: int, ty: int, w: int, h: int) -> bool:
	var h0 := h_at(tx, ty)
	for yy in range(ty, ty + h):
		for xx in range(tx, tx + w):
			if h_at(xx, yy) != h0 or is_water(xx, yy):
				return false
	return true


## ¿La casilla está en ladera (algún vecino a otra altura)?
func is_slope(tx: int, ty: int) -> bool:
	var h0 := h_at(tx, ty)
	for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
		if in_bounds(tx + d.x, ty + d.y) and h_at(tx + d.x, ty + d.y) != h0:
			return true
	return false
