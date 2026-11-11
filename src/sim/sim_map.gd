class_name SimMap
extends RefCounted
## Grilla del mapa: casillas sólidas, ocupación para construir y búsqueda de caminos.

const P := 1000 # milésimas por casilla

var n: int
var solid := PackedByteArray() # bloquea caminos
var occupied := PackedInt32Array() # id de la entidad que ocupa la casilla, -1 libre
var astar := AStarGrid2D.new()


func _init(size: int) -> void:
	n = size
	solid.resize(n * n)
	occupied.resize(n * n)
	occupied.fill(-1)
	astar.region = Rect2i(0, 0, n, n)
	astar.cell_size = Vector2(1, 1)
	astar.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	astar.default_compute_heuristic = AStarGrid2D.HEURISTIC_OCTILE
	astar.default_estimate_heuristic = AStarGrid2D.HEURISTIC_OCTILE
	astar.update()


func in_bounds(tx: int, ty: int) -> bool:
	return tx >= 0 and ty >= 0 and tx < n and ty < n


func is_solid(tx: int, ty: int) -> bool:
	if not in_bounds(tx, ty):
		return true
	return solid[ty * n + tx] != 0


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


func mark(tx: int, ty: int, w: int, h: int, id: int, blocks: bool) -> void:
	for yy in range(ty, ty + h):
		for xx in range(tx, tx + w):
			if not in_bounds(xx, yy):
				continue
			occupied[yy * n + xx] = id
			if blocks:
				solid[yy * n + xx] = 1
				astar.set_point_solid(Vector2i(xx, yy), true)


func clear(tx: int, ty: int, w: int, h: int) -> void:
	for yy in range(ty, ty + h):
		for xx in range(tx, tx + w):
			if not in_bounds(xx, yy):
				continue
			occupied[yy * n + xx] = -1
			solid[yy * n + xx] = 0
			astar.set_point_solid(Vector2i(xx, yy), false)


## ¿La huella tiene al menos una casilla vecina libre?
func has_free_neighbor(tx: int, ty: int, w: int, h: int) -> bool:
	for xx in range(tx - 1, tx + w + 1):
		if not is_solid(xx, ty - 1) or not is_solid(xx, ty + h):
			return true
	for yy in range(ty, ty + h):
		if not is_solid(tx - 1, yy) or not is_solid(tx + w, yy):
			return true
	return false


## Casilla libre más cercana a (tx, ty) buscando en anillos.
func nearest_free(tx: int, ty: int, max_r: int = 12) -> Vector2i:
	if not is_solid(tx, ty):
		return Vector2i(tx, ty)
	for r in range(1, max_r + 1):
		for dy in range(-r, r + 1):
			for dx in range(-r, r + 1):
				if absi(dx) != r and absi(dy) != r:
					continue
				if not is_solid(tx + dx, ty + dy):
					return Vector2i(tx + dx, ty + dy)
	return Vector2i(-1, -1)


func find_path(from: Vector2i, to: Vector2i) -> Array[Vector2i]:
	if is_solid(from.x, from.y):
		return [] as Array[Vector2i]
	to = Vector2i(clampi(to.x, 0, n - 1), clampi(to.y, 0, n - 1))
	return astar.get_id_path(from, to, true)
