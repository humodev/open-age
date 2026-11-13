class_name DetalleSuelo
## Mallas del detalle del suelo que se mueve con el viento (etapa 16): matas,
## pasto alto, flores y juncos o totora. Hojas de dos tramos con el color en el
## vértice (oscuro abajo, claro en la punta) y un único material con el
## sombreador de viento (shaders/grass.gdshader). Solo imagen.

enum { MATA, MATA_SECA, PIEDRAS, FLORES, PASTO_ALTO, JUNCOS }

static var _mat: ShaderMaterial


static func material() -> ShaderMaterial:
	if _mat == null:
		_mat = ShaderMaterial.new()
		_mat.shader = preload("res://src/game/shaders/grass.gdshader")
	return _mat


## Ruido de las manchas de pasto alto; lo usan la mezcla del suelo y el detalle,
## así la mancha pintada y las matas coinciden.
static func lush_noise(terrain: String) -> FastNoiseLite:
	var nz := FastNoiseLite.new()
	nz.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	nz.seed = hash(terrain) & 0xffff
	nz.frequency = 0.07
	nz.fractal_octaves = 2
	return nz


## Intensidad de la mancha (0 a 1) en un punto del mundo; `amount` es la
## fracción del mapa que se quiere cubierta (data/ambiente.json → pasto_alto).
static func lush_at(nz: FastNoiseLite, x: float, z: float, amount: float) -> float:
	var v := nz.get_noise_2d(x, z) * 0.5 + 0.5 # 0..1
	var thr := 0.74 - amount * 0.3
	return clampf((v - thr) / 0.12, 0.0, 1.0)


## Malla de un tipo con los colores del bioma (ver data/ambiente.json → detalle).
static func mesh(kind: int, det: Dictionary) -> Mesh:
	var rng := RandomNumberGenerator.new()
	rng.seed = 7919 * (kind + 1)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	match kind:
		MATA, MATA_SECA:
			var c := Ambiente.cols(det["pasto"] if kind == MATA else det["seco"])
			for i in 9:
				_blade(st, rng, 0.07, 0.17, 0.3, 0.045, c[i % c.size()], 0.45)
		PASTO_ALTO:
			var c := Ambiente.cols(det["alto"])
			for i in 20:
				_blade(st, rng, 0.38, 0.32, 0.58, 0.05, c[i % c.size()], 0.55)
		FLORES:
			var c := Ambiente.cols(det["pasto"])
			var fl := Ambiente.cols(det["flores"])
			for i in 7:
				var at := _blade(st, rng, 0.14, 0.16, 0.27, 0.035, c[i % c.size()], 0.25)
				_head(st, at, 0.05, fl[(i + rng.randi() % 2) % fl.size()])
		PIEDRAS:
			# Piedritas con color en el vértice, así comparten el material y la niebla.
			var c := Ambiente.col(det["piedras"])
			for pb in [[Vector3(0, 0.02, 0), 0.07, Vector3(1.3, 0.6, 1.0), 0.0], [Vector3(0.11, 0.015, 0.05), 0.045, Vector3(1.0, 0.6, 1.2), 0.2], [Vector3(-0.08, 0.01, 0.09), 0.035, Vector3(1, 0.7, 1), 0.08]]:
				_pebble(st, pb[0], pb[1], pb[2], c.darkened(pb[3]))
		JUNCOS:
			var c := Ambiente.col(det["juncos"])
			for i in 24:
				var tone := c.lightened(rng.randf_range(-0.05, 0.2))
				_blade(st, rng, 0.3, 0.45, 0.95, 0.05, tone, 0.28)
	st.index() # vértices compartidos: menos trabajo para el sombreador de viento
	return st.commit()


## Hoja de dos tramos inclinada hacia afuera; devuelve la punta.
static func _blade(st: SurfaceTool, rng: RandomNumberGenerator, spread: float, h0: float, h1: float, w: float, c: Color, lean_k: float) -> Vector3:
	var a := rng.randf() * TAU
	var r := sqrt(rng.randf()) * spread
	var base := Vector3(cos(a) * r, 0.0, sin(a) * r)
	var h := rng.randf_range(h0, h1)
	var face := rng.randf() * TAU
	var side := Vector3(cos(face), 0.0, sin(face)) * w * 0.5
	var out := Vector3(cos(a), 0.0, sin(a)) * (lean_k * h)
	var mid := base + Vector3(0.0, h * 0.55, 0.0) + out * 0.3
	var tip := base + Vector3(0.0, h, 0.0) + out
	var dark := c.darkened(0.42)
	var midc := c.darkened(0.12)
	var tipc := c.lightened(0.12)
	_tri(st, base - side, dark, base + side, dark, mid + side * 0.7, midc)
	_tri(st, base - side, dark, mid + side * 0.7, midc, mid - side * 0.7, midc)
	_tri(st, mid - side * 0.7, midc, mid + side * 0.7, midc, tip, tipc)
	return tip


## Cabeza de flor: dos triángulos cruzados.
static func _head(st: SurfaceTool, at: Vector3, s: float, c: Color) -> void:
	_tri(st, at + Vector3(-s, 0.0, 0.0), c, at + Vector3(s, 0.0, 0.0), c, at + Vector3(0.0, s * 0.6, s), c.lightened(0.15))
	_tri(st, at + Vector3(0.0, 0.0, -s), c, at + Vector3(0.0, 0.0, s), c, at + Vector3(s, s * 0.6, 0.0), c.lightened(0.15))
	_tri(st, at + Vector3(-s, s * 0.3, -s * 0.6), c, at + Vector3(s, s * 0.3, s * 0.6), c, at + Vector3(0.0, s * 0.3, -s), c)


static func _pebble(st: SurfaceTool, at: Vector3, r: float, scl: Vector3, c: Color) -> void:
	var sm := SphereMesh.new()
	sm.radius = r
	sm.height = r * 2.0
	sm.radial_segments = 5
	sm.rings = 2
	var arr := sm.get_mesh_arrays()
	var verts: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
	var norms: PackedVector3Array = arr[Mesh.ARRAY_NORMAL]
	var cl := c.srgb_to_linear()
	cl.a = 0.0 # piedra: no se mece
	for idx: int in arr[Mesh.ARRAY_INDEX]:
		st.set_color(cl)
		st.set_normal((norms[idx] / scl).normalized())
		st.add_vertex(verts[idx] * scl + at)


static func _tri(st: SurfaceTool, a: Vector3, ca: Color, b: Vector3, cb: Color, c: Vector3, cc: Color) -> void:
	for v in [[a, ca], [b, cb], [c, cc]]:
		st.set_color((v[1] as Color).srgb_to_linear()) # el sombreador usa COLOR crudo
		st.set_normal(Vector3.UP)
		st.add_vertex(v[0])
