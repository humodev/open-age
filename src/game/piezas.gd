class_name Piezas
extends RefCounted
## Lo que se arma por casillas, en 3D y siguiendo el suelo (proceso/64-terreno-caminos-arboles):
## muros de piedra y empalizadas que se unen con sus vecinos (tramo, esquina, T, punta y
## diagonal), puertas y torres con el paño del color del jugador, campos con surcos y el cultivo
## de cada pueblo, andenes en terrazas de pirca y el cimiento de los edificios. Los caminos se
## pintan en el suelo (WorldView._pintar_caminos). Solo imagen. Estilos y medidas en
## data/arte_piezas.json; colores y altos de los muros de piedra en data/arte_edades.json → muros.
##
## Las mallas se arman en el espacio del nodo del edificio (`o`: su posición en el mundo) y cada
## vértice toma la altura de la malla del terreno (WorldView.height_tri).

enum Clase { NADA, MURO, CAMINO, CAMPO }

const PATRONES := {"sillar": 0, "pirca": 1, "ladrillo": 2, "revoque": 3, "tierra": 4, "madera": 5, "liso": 6}
const ORTO: Array[Vector2i] = [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]
const DIAG: Array[Vector2i] = [Vector2i(1, 1), Vector2i(-1, 1), Vector2i(1, -1), Vector2i(-1, -1)]
const SH_MURO := preload("res://src/game/shaders/pieza_muro.gdshader")
const SH_CAMPO := preload("res://src/game/shaders/pieza_campo.gdshader")
const SH_CULTIVO := preload("res://src/game/shaders/cultivo.gdshader")

static var _cfg := {}
static var _mats := {}


static func cfg() -> Dictionary:
	if _cfg.is_empty():
		_cfg = JSON.parse_string(FileAccess.get_file_as_string("res://data/arte_piezas.json"))
	return _cfg


static func clase(def: Dictionary) -> int:
	if def.get("camino", false):
		return Clase.CAMINO
	if def.get("linea", false) or def.get("puerta", false) or def.get("solo_sobre", false):
		return Clase.MURO
	if def.has("fuente"):
		return Clase.CAMPO
	return Clase.NADA


static func por_pueblo(tabla: Dictionary, civ: String) -> Variant:
	return tabla.get(civ, tabla.get("_defecto"))


static func _cm(v: Variant) -> float:
	return float(v) / 100.0


# ---------------------------------------------------------------- Materiales

static func mat_muro(patron: String, color: Color, junta := Color(0, 0, 0)) -> ShaderMaterial:
	var key := "m_%s_%s_%s" % [patron, color.to_html(), junta.to_html()]
	if not _mats.has(key):
		var m := ShaderMaterial.new()
		m.shader = SH_MURO
		m.set_shader_parameter("patron", int(PATRONES.get(patron, 6)))
		m.set_shader_parameter("color", color)
		m.set_shader_parameter("junta", junta if junta != Color(0, 0, 0) else color.darkened(0.35))
		m.set_shader_parameter("t_rock", load("res://assets/texturas/suelo/roca_color.jpg"))
		_mats[key] = m
	return _mats[key]


static func mat_campo(surcos: float, agua: bool, civ := "") -> ShaderMaterial:
	var key := "c_%.2f_%s" % [surcos, str(agua)]
	if not _mats.has(key):
		var c: Dictionary = cfg()["campos"]
		var m := ShaderMaterial.new()
		m.shader = SH_CAMPO
		m.set_shader_parameter("suelo_a", Color(String(c["suelo"][0])))
		m.set_shader_parameter("suelo_b", Color(String(c["suelo"][1])))
		m.set_shader_parameter("surcos", surcos)
		m.set_shader_parameter("agua", agua)
		m.set_shader_parameter("agua_color", Color(String(c["agua"]["color"])))
		m.set_shader_parameter("bordo", _cm(c["agua"]["bordo_cm"]))
		m.set_shader_parameter("t_dirt", load("res://assets/texturas/suelo/tierra_color.jpg"))
		_mats[key] = m
	return _mats[key]


static func mat_cultivo() -> ShaderMaterial:
	if not _mats.has("cultivo"):
		var m := ShaderMaterial.new()
		m.shader = SH_CULTIVO
		_mats["cultivo"] = m
	return _mats["cultivo"]


# ---------------------------------------------------------------- Malla

## Superficies por material; cada vértice con normal, color y UV propios.
class Malla:
	var o := Vector3.ZERO # posición del nodo en el mundo
	var sts := {}
	var mats := {}
	var cur: SurfaceTool

	func usar(mat: Material) -> void:
		var key := mat.get_instance_id()
		if not sts.has(key):
			var s := SurfaceTool.new()
			s.begin(Mesh.PRIMITIVE_TRIANGLES)
			sts[key] = s
			mats[key] = mat
		cur = sts[key]

	## Punto del mundo (x, alto, z) en el espacio del nodo.
	func p(x: float, y: float, z: float) -> Vector3:
		return Vector3(x - o.x, y - o.y, z - o.z)

	func v(pos: Vector3, n: Vector3, c: Color, uv: Vector2, uv2 := Vector2.ZERO) -> void:
		cur.set_normal(n)
		cur.set_color(c)
		cur.set_uv(uv)
		cur.set_uv2(uv2)
		cur.add_vertex(pos)

	## Cuadrilátero a, b, c, d (en orden alrededor) con una normal.
	func quad(a: Vector3, b: Vector3, c: Vector3, d: Vector3, n: Vector3, ca: Color, cb: Color, cc: Color, cd: Color, ua: Vector2, ub: Vector2, uc: Vector2, ud: Vector2) -> void:
		v(a, n, ca, ua)
		v(b, n, cb, ub)
		v(c, n, cc, uc)
		v(a, n, ca, ua)
		v(c, n, cc, uc)
		v(d, n, cd, ud)

	func vacia() -> bool:
		return sts.is_empty()

	func commit() -> ArrayMesh:
		var mesh := ArrayMesh.new()
		for key in sts:
			(sts[key] as SurfaceTool).commit(mesh)
			mesh.surface_set_material(mesh.get_surface_count() - 1, mats[key])
		return mesh


static func H(x: float, z: float) -> float:
	return WorldView.height_tri(x, z)


static func _h(x: int) -> float:
	var v := (x * 2654435761) & 0xffffffff
	v ^= v >> 15
	return float(v & 0xffff) / 65535.0


## Valor de 0 a 1 fijo para un punto del mundo (igual en las dos casillas que lo comparten).
static func _hp(q: Vector2, sal := 0) -> float:
	return _h(int(roundf(q.x * 97.0)) * 73856093 ^ int(roundf(q.y * 97.0)) * 19349663 ^ sal * 83492791)


## Dirección canónica (para que el dibujo de la cara siga igual de una casilla a la otra).
static func _canon(u: Vector2) -> Vector2:
	return -u if u.x < -0.001 or (absf(u.x) <= 0.001 and u.y < 0.0) else u


# ---------------------------------------------------------------- Bloques

## Bloque de base horizontal en `bot` y techo horizontal en `top`, orientado por `u`: a lo largo
## va de ub.x a ub.y abajo y de ut.x a ut.y arriba; de costado, ±nb abajo y ±nt arriba.
## `abajo`: color al pie (el de arriba es `col`).
static func bloque(m: Malla, c: Vector2, u: Vector2, ub: Vector2, ut: Vector2, nb: float, nt: float, bot: float, top: float, col: Color, abajo := Color(-1, 0, 0), techo := true) -> void:
	var n := Vector2(-u.y, u.x)
	var cb := abajo if abajo.r >= 0.0 else col * 0.62
	cb.a = 1.0
	var uc := _canon(u)
	var P := func(a: float, s: float, y: float) -> Vector3:
		var q := c + u * a + n * s
		return m.p(q.x, y, q.y)
	var U := func(a: float, s: float, y: float) -> Vector2:
		var q := c + u * a + n * s
		return Vector2(q.dot(uc), y)
	# Caras a lo largo (±n) y de punta (±u).
	for s: float in [-1.0, 1.0]:
		var a0: Vector3 = P.call(ub.x, nb * s, bot)
		var a1: Vector3 = P.call(ub.y, nb * s, bot)
		var b1: Vector3 = P.call(ut.y, nt * s, top)
		var b0: Vector3 = P.call(ut.x, nt * s, top)
		var nn := Vector3(n.x * s, (nb - nt) / maxf(top - bot, 0.01), n.y * s).normalized()
		m.quad(a0, a1, b1, b0, nn, cb, cb, col, col, U.call(ub.x, nb * s, bot), U.call(ub.y, nb * s, bot), U.call(ut.y, nt * s, top), U.call(ut.x, nt * s, top))
	for e in [[ub.x, ut.x, -1.0], [ub.y, ut.y, 1.0]]:
		var a0: Vector3 = P.call(e[0], -nb, bot)
		var a1: Vector3 = P.call(e[0], nb, bot)
		var b1: Vector3 = P.call(e[1], nt, top)
		var b0: Vector3 = P.call(e[1], -nt, top)
		var lean: float = (float(e[0]) - float(e[1])) * float(e[2]) / maxf(top - bot, 0.01)
		var nn := Vector3(u.x * e[2], lean, u.y * e[2]).normalized()
		var ua := Vector2((c + n * -nb).dot(Vector2(-uc.y, uc.x)), bot)
		m.quad(a0, a1, b1, b0, nn, cb, cb, col, col, ua, ua + Vector2(nb * 2.0, 0), Vector2(ua.x + nb + nt, top), Vector2(ua.x + nb - nt, top))
	if techo:
		var t0: Vector3 = P.call(ut.x, -nt, top)
		var t1: Vector3 = P.call(ut.y, -nt, top)
		var t2: Vector3 = P.call(ut.y, nt, top)
		var t3: Vector3 = P.call(ut.x, nt, top)
		var ct := col * 1.06
		ct.a = 1.0
		m.quad(t0, t1, t2, t3, Vector3.UP, ct, ct, ct, ct, U.call(ut.x, -nt, top), U.call(ut.y, -nt, top), U.call(ut.y, nt, top), U.call(ut.x, nt, top))


## Pirámide sobre un rectángulo (las almenas en hoja).
static func punta(m: Malla, c: Vector2, u: Vector2, hu: float, hn: float, y: float, alto: float, col: Color) -> void:
	var n := Vector2(-u.y, u.x)
	var apex := m.p(c.x, y + alto, c.y)
	var cs: Array[Vector2] = [c - u * hu - n * hn, c + u * hu - n * hn, c + u * hu + n * hn, c - u * hu + n * hn]
	for i in 4:
		var a := m.p(cs[i].x, y, cs[i].y)
		var b := m.p(cs[(i + 1) % 4].x, y, cs[(i + 1) % 4].y)
		var nn := (b - a).cross(apex - a).normalized()
		if nn.y < 0.0:
			nn = -nn
		m.v(a, nn, col, Vector2(0, y))
		m.v(b, nn, col, Vector2(0.2, y))
		m.v(apex, nn, col, Vector2(0.1, y + alto))


## Palo: cilindro de `lados` caras de `y0` a `y1` (con la punta corrida `lean`), con punta
## aguzada si `aguja` > 0.
static func palo(m: Malla, c: Vector2, r: float, y0: float, y1: float, col: Color, lados := 6, aguja := 0.0, lean := Vector2.ZERO, gira := 0.0) -> void:
	var top := c + lean
	var cb := col * 0.6
	cb.a = 1.0
	for i in lados:
		var a0 := gira + TAU * i / lados
		var a1 := gira + TAU * (i + 1) / lados
		var d0 := Vector2(cos(a0), sin(a0))
		var d1 := Vector2(cos(a1), sin(a1))
		var nn := Vector3(cos((a0 + a1) * 0.5), 0.0, sin((a0 + a1) * 0.5))
		var p0 := c + d0 * r
		var p1 := c + d1 * r
		var q0 := top + d0 * r
		var q1 := top + d1 * r
		m.quad(m.p(p0.x, y0, p0.y), m.p(p1.x, y0, p1.y), m.p(q1.x, y1, q1.y), m.p(q0.x, y1, q0.y), nn, cb, cb, col, col, Vector2(i * 0.05, y0), Vector2((i + 1) * 0.05, y0), Vector2((i + 1) * 0.05, y1), Vector2(i * 0.05, y1))
		var apex := m.p(top.x, y1 + aguja, top.y)
		var ct := col * 1.12
		ct.a = 1.0
		var nt := Vector3(nn.x, 0.6 if aguja > 0.0 else 4.0, nn.z).normalized()
		m.v(m.p(q0.x, y1, q0.y), nt, col, Vector2(i * 0.05, y1))
		m.v(m.p(q1.x, y1, q1.y), nt, col, Vector2((i + 1) * 0.05, y1))
		m.v(apex, nt, ct, Vector2((i + 0.5) * 0.05, y1 + aguja))


## Paño del color del jugador colgado de una cara: centro de la cara `c` (mundo), normal `n`.
static func pano(m: Malla, c: Vector2, n: Vector2, y_top: float, ancho: float, alto: float, team: Color) -> void:
	var u := Vector2(-n.y, n.x)
	var q := c + n * 0.012
	var a := q - u * ancho * 0.5
	var b := q + u * ancho * 0.5
	var tip := q + n * 0.01
	var cl := team
	var cd := team.darkened(0.25)
	var nn := Vector3(n.x, 0, n.y)
	m.quad(m.p(a.x, y_top, a.y), m.p(b.x, y_top, b.y), m.p(b.x, y_top - alto * 0.82, b.y), m.p(a.x, y_top - alto * 0.82, a.y), nn, cl, cl, cd, cd, Vector2.ZERO, Vector2.ZERO, Vector2.ZERO, Vector2.ZERO)
	# Punta en V abajo.
	m.v(m.p(a.x, y_top - alto * 0.82, a.y), nn, cd, Vector2.ZERO)
	m.v(m.p(b.x, y_top - alto * 0.82, b.y), nn, cd, Vector2.ZERO)
	m.v(m.p(tip.x, y_top - alto, tip.y), nn, cd, Vector2.ZERO)


# ---------------------------------------------------------------- Muros

## Estilo de la pieza: {"piedra": bool, "estilo": clave, ...} con lo de arte_edades y arte_piezas.
static func estilo_muro(def: Dictionary, civ: String) -> Dictionary:
	var arte := String(def.get("arte", ""))
	var muros: Dictionary = CivMeshes.arte().get("muros", {})
	if arte != "" and muros.has(arte):
		var out: Dictionary = (cfg()["muros"].get(arte, cfg()["muros"]["sillar"]) as Dictionary).duplicate()
		out.merge(muros[arte], true)
		out["es_piedra"] = true
		out["estilo"] = arte
		return out
	var em: Dictionary = cfg()["empalizadas"]
	var clave := String(por_pueblo(em["por_pueblo"], civ))
	var out2: Dictionary = (em[clave] as Dictionary).duplicate()
	out2["es_piedra"] = false
	out2["estilo"] = clave
	out2["puerta"] = em["puerta"]
	return out2


## Muro, empalizada, puerta o torre de una casilla. `con`: direcciones de los vecinos unidos
## (las cuatro y las diagonales sin esquina). `obra`: fracción del alto (en obra).
static func muro(e: SimEntity, con: Array, civ: String, team: Color, o: Vector3, obra := 1.0) -> ArrayMesh:
	var st := estilo_muro(e.def, civ)
	var pieza := CivMeshes.pieza_muro(e.def)
	var m := Malla.new()
	m.o = o
	var c := Vector2(e.tx + 0.5, e.ty + 0.5)
	if st["es_piedra"]:
		_muro_piedra(m, c, con, st, pieza, team, obra)
	else:
		_empalizada(m, c, con, st, pieza, team, obra)
	return m.commit()


## Eje de una pieza: el de los vecinos (para la puerta), o x si no tiene.
static func _eje(con: Array) -> Vector2:
	for d: Vector2i in con:
		if d.y == 0:
			return Vector2(1, 0)
	for d: Vector2i in con:
		if d.x == 0:
			return Vector2(0, 1)
	for d: Vector2i in con:
		return _canon(Vector2(d).normalized())
	return Vector2(1, 0)


static func _recto(con: Array) -> bool:
	return con.size() == 2 and (con[0] as Vector2i) == -(con[1] as Vector2i)


static func _min_suelo(c: Vector2, r: float) -> float:
	var g := H(c.x, c.y)
	for d in [Vector2(-r, -r), Vector2(r, -r), Vector2(r, r), Vector2(-r, r), Vector2(r, 0), Vector2(-r, 0), Vector2(0, r), Vector2(0, -r)]:
		g = minf(g, H(c.x + d.x, c.y + d.y))
	return g


static func _max_suelo(c: Vector2, r: float) -> float:
	var g := H(c.x, c.y)
	for d in [Vector2(-r, -r), Vector2(r, -r), Vector2(r, r), Vector2(-r, r), Vector2(r, 0), Vector2(-r, 0), Vector2(0, r), Vector2(0, -r)]:
		g = maxf(g, H(c.x + d.x, c.y + d.y))
	return g


static func _muro_piedra(m: Malla, c: Vector2, con: Array, st: Dictionary, pieza: String, team: Color, obra: float) -> void:
	var col := Color(String(st.get("piedra", "#a39c8f")))
	var junta := Color(String(st.get("junta", "#7d776c")))
	m.usar(mat_muro(String(st.get("patron", "sillar")), col, junta))
	var alto := _cm(st.get("alto_cm", 150)) * obra
	var gr: Array = st.get("grosor_cm", [60, 55])
	var hb := _cm(gr[0]) / 2.0
	var ht := _cm(gr[1]) / 2.0
	var sink := _cm(st.get("hundido_cm", 45))
	var blanco := Color(1, 1, 1)
	if pieza == "puerta":
		_puerta_piedra(m, c, con, st, team, obra, col, junta, hb, ht, sink, alto)
		return
	var segs: Array = []
	if con.is_empty():
		segs.append([c - Vector2(0.36, 0), c + Vector2(0.36, 0), true])
	else:
		for d: Vector2i in con:
			segs.append([c, c + Vector2(d) * 0.5, false])
	for s: Array in segs:
		_lienzo(m, s[0], s[1], hb, ht, sink, alto, st, s[2], obra)
	if not con.is_empty() and not _recto(con):
		# Pilar en el nudo: tapa la junta de las esquinas y hace de remate en las puntas.
		var bot := _min_suelo(c, hb) - sink
		m.usar(mat_muro(String(st.get("patron", "sillar")), col, junta))
		bloque(m, c, Vector2(1, 0), Vector2(-hb, hb), Vector2(-ht, ht), hb, ht, bot, H(c.x, c.y) + alto, blanco)
		if obra >= 0.99:
			_remate(m, c, Vector2(1, 0), ht, H(c.x, c.y) + alto, st, col)
	if pieza == "torre":
		_torre_piedra(m, c, st, team, obra, col, junta, hb, sink)


## Lienzo de muro de `a` a `b` que sigue el suelo: base hundida, techo a `alto` del suelo de cada
## punto, talud entre `hb` (pie) y `ht` (arriba), y el remate del estilo (almenas o lajas).
static func _lienzo(m: Malla, a: Vector2, b: Vector2, hb: float, ht: float, sink: float, alto: float, st: Dictionary, tapas: bool, obra: float) -> void:
	var L := a.distance_to(b)
	if L < 0.01:
		return
	var u := (b - a) / L
	var n := Vector2(-u.y, u.x)
	var uc := _canon(u)
	var pasos := maxi(2, ceili(L / 0.125))
	var qs: Array[Vector2] = []
	var bots: Array[float] = []
	var tops: Array[float] = []
	for i in pasos + 1:
		var q := a + u * (L * i / pasos)
		var g := H(q.x, q.y)
		qs.append(q)
		bots.append(minf(g, minf(H(q.x - n.x * hb, q.y - n.y * hb), H(q.x + n.x * hb, q.y + n.y * hb))) - sink)
		tops.append(g + alto)
	var cb := Color(0.6, 0.6, 0.6)
	var ct := Color(1, 1, 1)
	var lean := (hb - ht) / maxf(alto + sink, 0.01)
	for s: float in [-1.0, 1.0]:
		var nn := Vector3(n.x * s, lean, n.y * s).normalized()
		for i in pasos:
			var q0 := qs[i]
			var q1 := qs[i + 1]
			var p0 := q0 + n * hb * s
			var p1 := q1 + n * hb * s
			var r0 := q0 + n * ht * s
			var r1 := q1 + n * ht * s
			m.quad(m.p(p0.x, bots[i], p0.y), m.p(p1.x, bots[i + 1], p1.y), m.p(r1.x, tops[i + 1], r1.y), m.p(r0.x, tops[i], r0.y), nn, cb, cb, ct, ct,
				Vector2(q0.dot(uc), bots[i]), Vector2(q1.dot(uc), bots[i + 1]), Vector2(q1.dot(uc), tops[i + 1]), Vector2(q0.dot(uc), tops[i]))
	var ctop := Color(1.06, 1.06, 1.06)
	for i in pasos:
		var q0 := qs[i]
		var q1 := qs[i + 1]
		var l0 := q0 - n * ht
		var l1 := q1 - n * ht
		var r0 := q0 + n * ht
		var r1 := q1 + n * ht
		var nn := Vector3(-u.x * (tops[i + 1] - tops[i]), L / pasos, -u.y * (tops[i + 1] - tops[i])).normalized()
		m.quad(m.p(l0.x, tops[i], l0.y), m.p(l1.x, tops[i + 1], l1.y), m.p(r1.x, tops[i + 1], r1.y), m.p(r0.x, tops[i], r0.y), nn, ctop, ctop, ctop, ctop,
			Vector2(q0.dot(uc), -ht), Vector2(q1.dot(uc), -ht), Vector2(q1.dot(uc), ht), Vector2(q0.dot(uc), ht))
	if tapas:
		for k in [0, pasos]:
			var sg := -1.0 if k == 0 else 1.0
			var q := qs[k]
			var nn := Vector3(u.x * sg, 0, u.y * sg)
			var pl := q - n * hb
			var pr := q + n * hb
			var tl := q - n * ht
			var tr := q + n * ht
			m.quad(m.p(pl.x, bots[k], pl.y), m.p(pr.x, bots[k], pr.y), m.p(tr.x, tops[k], tr.y), m.p(tl.x, tops[k], tl.y), nn, cb, cb, ct, ct,
				Vector2(pl.dot(n), bots[k]), Vector2(pr.dot(n), bots[k]), Vector2(tr.dot(n), tops[k]), Vector2(tl.dot(n), tops[k]))
	if obra < 0.99:
		return
	# Remate: almenas cada `almena_paso_cm` o lajas a lo largo.
	var col := Color(String(st.get("piedra", "#a39c8f")))
	var paso := _cm(st.get("almena_paso_cm", 25))
	var k := maxi(1, roundi(L / paso))
	for j in k:
		var t := (j + 0.5) * L / k
		var q := a + u * t
		_remate(m, q, u, ht, H(q.x, q.y) + alto, st, col)


## Almena o laja sobre el muro en `q`, con el techo en `y`.
static func _remate(m: Malla, q: Vector2, u: Vector2, ht: float, y: float, st: Dictionary, col: Color) -> void:
	var blanco := Color(1.04, 1.04, 1.04)
	match String(st.get("almena", "cuadrada")):
		"ninguna":
			var hu := 0.07 + 0.03 * _hp(q, 3)
			var cl := Color(0.92, 0.92, 0.92) * (0.9 + 0.2 * _hp(q, 9))
			cl.a = 1.0
			bloque(m, q, u.rotated((_hp(q, 5) - 0.5) * 0.6), Vector2(-hu, hu), Vector2(-hu * 0.9, hu * 0.9), ht + 0.012, ht + 0.004, y - 0.03, y + 0.05 + 0.03 * _hp(q, 7), cl, Color(0.8, 0.8, 0.8))
		"hoja":
			bloque(m, q, u, Vector2(-0.055, 0.055), Vector2(-0.055, 0.055), ht * 0.8, ht * 0.8, y - 0.02, y + 0.09, blanco, Color(0.9, 0.9, 0.9))
			punta(m, q, u, 0.055, ht * 0.8, y + 0.09, 0.13, blanco)
		"redonda":
			bloque(m, q, u, Vector2(-0.06, 0.06), Vector2(-0.045, 0.045), ht * 0.8, ht * 0.6, y - 0.02, y + 0.12, blanco, Color(0.9, 0.9, 0.9))
		_:
			bloque(m, q, u, Vector2(-0.065, 0.065), Vector2(-0.06, 0.06), ht, ht, y - 0.02, y + 0.16, blanco, Color(0.9, 0.9, 0.9))


static func _puerta_piedra(m: Malla, c: Vector2, con: Array, st: Dictionary, team: Color, obra: float, col: Color, junta: Color, hb: float, ht: float, sink: float, alto: float) -> void:
	var u := _eje(con)
	var n := Vector2(-u.y, u.x)
	var Lh := 0.5 if absf(u.x) < 0.01 or absf(u.y) < 0.01 else 0.7072
	var pc: Dictionary = st.get("puerta", {})
	var w0 := _cm(pc.get("vano_cm", 46)) / 2.0
	var trap: bool = pc.get("trapecio", false)
	var w1 := w0 * (0.72 if trap else 1.0)
	var gmin := _min_suelo(c, 0.5)
	var gmax := _max_suelo(c, 0.5)
	var bot := gmin - sink
	var top := gmax + alto + 0.28 * obra
	var blanco := Color(1, 1, 1)
	m.usar(mat_muro(String(st.get("patron", "sillar")), col, junta))
	for s: float in [-1.0, 1.0]:
		var cj := c + u * s * (w0 + Lh) * 0.5
		var half := (Lh - w0) * 0.5
		# Jamba: la cara del vano se inclina en la portada trapezoidal.
		var ub := Vector2(-half, half)
		var ut := Vector2(-half, half)
		if s < 0.0:
			ut.y = half + (w0 - w1)
		else:
			ut.x = -half - (w0 - w1)
		bloque(m, cj, u, ub, ut, hb + 0.03, ht + 0.03, bot, top, blanco)
	if obra < 0.99:
		return
	var y_din := gmax + alto * 0.72
	# Dintel y cornisa.
	bloque(m, c, u, Vector2(-w1 - 0.02, w1 + 0.02), Vector2(-w1 - 0.02, w1 + 0.02), ht + 0.02, ht + 0.02, y_din, top, blanco)
	bloque(m, c, u, Vector2(-Lh, Lh), Vector2(-Lh, Lh), hb + 0.05, hb + 0.05, top, top + 0.07, Color(1.08, 1.08, 1.08), Color(0.9, 0.9, 0.9))
	var paso := _cm(st.get("almena_paso_cm", 25))
	var k := maxi(1, roundi(2.0 * Lh / paso))
	for j in k:
		_remate(m, c + u * (-Lh + (j + 0.5) * 2.0 * Lh / k), u, hb + 0.02, top + 0.07, st, col)
	# Hojas de madera en el vano.
	m.usar(mat_muro("madera", Palette.WOOD_BEAM.darkened(0.2)))
	bloque(m, c, u, Vector2(-w0 + 0.01, w0 - 0.01), Vector2(-w1 + 0.01, w1 - 0.01), 0.035, 0.035, gmin - 0.05, y_din, Color(1, 1, 1), Color(0.8, 0.8, 0.8))
	# Paños del color del jugador en las dos caras de cada jamba.
	var pz: Dictionary = cfg()["torre_paño"]
	m.usar(mat_muro("liso", team))
	for s: float in [-1.0, 1.0]:
		var cj := c + u * s * (w0 + Lh) * 0.5
		for f: float in [-1.0, 1.0]:
			pano(m, cj + n * f * (hb + 0.03 - 0.02), n * f, top - 0.06, _cm(pz["ancho_cm"]), _cm(pz["alto_cm"]), team)


static func _torre_piedra(m: Malla, c: Vector2, st: Dictionary, team: Color, obra: float, col: Color, junta: Color, hb: float, sink: float) -> void:
	var r := maxf(hb + 0.08, 0.4)
	var gmin := _min_suelo(c, r)
	var gmax := _max_suelo(c, r)
	var top := gmax + (_cm(st.get("alto_cm", 150)) + _cm(st.get("torre_extra_cm", 120))) * obra
	var blanco := Color(1, 1, 1)
	m.usar(mat_muro(String(st.get("patron", "sillar")), col.lightened(0.04), junta))
	var redonda: bool = st.get("torre_redonda", false)
	if redonda:
		var lados := 12
		for i in lados:
			var a0 := TAU * i / lados
			var a1 := TAU * (i + 1) / lados
			var d0 := Vector2(cos(a0), sin(a0))
			var d1 := Vector2(cos(a1), sin(a1))
			var nn := Vector3(cos((a0 + a1) * 0.5), 0.05, sin((a0 + a1) * 0.5)).normalized()
			var p0 := c + d0 * r
			var p1 := c + d1 * r
			var q0 := c + d0 * r * 0.92
			var q1 := c + d1 * r * 0.92
			var cb := Color(0.6, 0.6, 0.6)
			m.quad(m.p(p0.x, gmin - sink, p0.y), m.p(p1.x, gmin - sink, p1.y), m.p(q1.x, top, q1.y), m.p(q0.x, top, q0.y), nn, cb, cb, blanco, blanco,
				Vector2(a0 * r, gmin - sink), Vector2(a1 * r, gmin - sink), Vector2(a1 * r, top), Vector2(a0 * r, top))
			m.v(m.p(q0.x, top, q0.y), Vector3.UP, blanco, Vector2(a0 * r, 0))
			m.v(m.p(q1.x, top, q1.y), Vector3.UP, blanco, Vector2(a1 * r, 0))
			m.v(m.p(c.x, top, c.y), Vector3.UP, blanco, Vector2(0, 0))
	else:
		bloque(m, c, Vector2(1, 0), Vector2(-r, r), Vector2(-r * 0.93, r * 0.93), r, r * 0.93, gmin - sink, top, blanco)
	if obra < 0.99:
		return
	# Cornisa y almenas alrededor.
	var rt := r * (0.92 if redonda else 0.93)
	bloque(m, c, Vector2(1, 0), Vector2(-rt - 0.05, rt + 0.05), Vector2(-rt - 0.05, rt + 0.05), rt + 0.05, rt + 0.05, top - 0.02, top + 0.08, Color(1.08, 1.08, 1.08), Color(0.9, 0.9, 0.9))
	var st2 := st.duplicate()
	if String(st2.get("almena", "")) == "ninguna":
		st2["almena"] = "cuadrada"
	for i in 8:
		var a := TAU * i / 8.0
		var q := c + Vector2(cos(a), sin(a)) * (rt - 0.02)
		_remate(m, q, Vector2(-sin(a), cos(a)), 0.06, top + 0.08, st2, col)
	# Saetera oscura y paños del color del jugador en las cuatro caras.
	var pz: Dictionary = cfg()["torre_paño"]
	m.usar(mat_muro("liso", Color(0.08, 0.07, 0.06)))
	for d: Vector2 in [Vector2(-1, 0), Vector2(0, -1)]:
		var fc := c + d * (rt + 0.015)
		bloque(m, fc, Vector2(-d.y, d.x), Vector2(-0.035, 0.035), Vector2(-0.035, 0.035), 0.01, 0.01, top - 0.62, top - 0.34, Color(1, 1, 1), Color(1, 1, 1))
	m.usar(mat_muro("liso", team))
	for d: Vector2 in [Vector2(1, 0), Vector2(-1, 0), Vector2(0, 1), Vector2(0, -1)]:
		var off := Vector2(-d.y, d.x) * 0.15
		pano(m, c + d * rt + off, d, top - 0.06, _cm(pz["ancho_cm"]), _cm(pz["alto_cm"]), team)


# ---------------------------------------------------------------- Empalizadas

static func _empalizada(m: Malla, c: Vector2, con: Array, st: Dictionary, pieza: String, team: Color, obra: float) -> void:
	var col := Color(String(st.get("color", "7a5a3a")))
	if pieza == "puerta":
		_puerta_palos(m, c, con, st, team, obra, col)
		return
	var segs: Array = []
	if con.is_empty():
		segs.append([c - Vector2(0.4, 0), c + Vector2(0.4, 0)])
	else:
		for d: Vector2i in con:
			segs.append([c, c + Vector2(d) * 0.5])
	if st.get("terraplen", false):
		m.usar(mat_campo(0.0, false))
		for s: Array in segs:
			_terraplen(m, s[0], s[1])
	m.usar(mat_muro("madera", col))
	for s: Array in segs:
		_palos(m, s[0], s[1], st, obra, col, 0.0)
	if not con.is_empty() and not _recto(con):
		var g := H(c.x, c.y)
		var r := _cm(st.get("radio_cm", 7)) * 1.5
		palo(m, c, r, g - 0.3, g + _cm(st.get("alto_cm", 120)) * obra * 1.04, col, 7, r * 2.0 if st.get("punta", true) else 0.0)


## Palos a lo largo de `a`→`b`, en una o dos filas, desde `t0`.
static func _palos(m: Malla, a: Vector2, b: Vector2, st: Dictionary, obra: float, col: Color, t0: float) -> void:
	var L := a.distance_to(b)
	if L - t0 < 0.02:
		return
	var u := (b - a) / L
	var n := Vector2(-u.y, u.x)
	var r := _cm(st.get("radio_cm", 7))
	var paso := _cm(st.get("paso_cm", 14))
	var alto := _cm(st.get("alto_cm", 120)) * obra
	var desp := float(st.get("desparejo_pct", 10)) / 100.0
	var filas := int(st.get("filas", 1))
	var sep := _cm(st.get("separacion_cm", 30))
	var aguja := r * 2.4 if st.get("punta", true) else 0.0
	var k := maxi(1, roundi((L - t0) / paso))
	for f in filas:
		var off := n * (f - (filas - 1) * 0.5) * sep
		for j in k:
			var q := a + u * (t0 + (j + 0.5) * (L - t0) / k) + off
			var g := H(q.x, q.y)
			var hh := alto * (1.0 + desp * (_hp(q, 1) * 2.0 - 1.0))
			var lean := Vector2.ZERO
			if desp > 0.2:
				lean = Vector2(_hp(q, 2) - 0.5, _hp(q, 4) - 0.5) * 0.06
			var cc := col * (0.86 + 0.28 * _hp(q, 6))
			cc.a = 1.0
			palo(m, q, r * (0.85 + 0.3 * _hp(q, 8)), g - 0.3, g + hh, cc, 6, aguja * (0.8 + 0.4 * _hp(q, 9)), lean, _hp(q, 10) * 1.0)
		# Ataduras: dos bandas oscuras que siguen el suelo.
		for fr in st.get("atado_pct", [40]):
			var y_k := float(fr) / 100.0 * alto
			for s: float in [-1.0, 1.0]:
				var pasos := maxi(1, ceili(L / 0.25))
				for i in pasos:
					var q0 := a + u * (L * i / pasos) + off + n * s * (r + 0.008)
					var q1 := a + u * (L * (i + 1) / pasos) + off + n * s * (r + 0.008)
					var y0 := H(q0.x, q0.y) + y_k
					var y1 := H(q1.x, q1.y) + y_k
					var cd := Color(0.42, 0.36, 0.3)
					m.quad(m.p(q0.x, y0 - 0.025, q0.y), m.p(q1.x, y1 - 0.025, q1.y), m.p(q1.x, y1 + 0.025, q1.y), m.p(q0.x, y0 + 0.025, q0.y), Vector3(n.x * s, 0, n.y * s), cd, cd, cd, cd, Vector2.ZERO, Vector2.ZERO, Vector2.ZERO, Vector2.ZERO)
	if st.get("estrepes", false):
		var ks := maxi(1, roundi(L / 0.2))
		for j in ks:
			var q := a + u * ((j + 0.5) * L / ks)
			for s: float in [-1.0, 1.0]:
				var b0 := q + n * s * (0.16 + 0.08 * _hp(q, 11 + int(s)))
				var g := H(b0.x, b0.y)
				palo(m, b0, 0.018, g - 0.05, g + 0.12, col.darkened(0.1), 4, 0.1, n * s * 0.14)


## Terraplén al pie de la empalizada (la tierra del foso), sobre el suelo.
static func _terraplen(m: Malla, a: Vector2, b: Vector2) -> void:
	var L := a.distance_to(b)
	if L < 0.01:
		return
	var u := (b - a) / L
	var n := Vector2(-u.y, u.x)
	var perfil := [[-0.42, 0.0], [-0.22, 0.07], [0.0, 0.1], [0.22, 0.07], [0.42, 0.0]]
	var pasos := maxi(2, ceili(L / 0.125))
	var blanco := Color(0.9, 0.85, 0.8)
	for i in pasos:
		var q0 := a + u * (L * i / pasos)
		var q1 := a + u * (L * (i + 1) / pasos)
		for k in perfil.size() - 1:
			var s0: float = perfil[k][0]
			var s1: float = perfil[k + 1][0]
			var h0: float = perfil[k][1]
			var h1: float = perfil[k + 1][1]
			var pa := q0 + n * s0
			var pb := q1 + n * s0
			var pc := q1 + n * s1
			var pd := q0 + n * s1
			var nn := Vector3(-n.x * (h1 - h0), absf(s1 - s0), -n.y * (h1 - h0)).normalized()
			var t := Vector2(1, 1)
			m.v(m.p(pa.x, H(pa.x, pa.y) + h0 + 0.01, pa.y), nn, blanco, Vector2(1, 0.5), t)
			m.v(m.p(pb.x, H(pb.x, pb.y) + h0 + 0.01, pb.y), nn, blanco, Vector2(1, 0.5), t)
			m.v(m.p(pc.x, H(pc.x, pc.y) + h1 + 0.01, pc.y), nn, blanco, Vector2(1, 0.5), t)
			m.v(m.p(pa.x, H(pa.x, pa.y) + h0 + 0.01, pa.y), nn, blanco, Vector2(1, 0.5), t)
			m.v(m.p(pc.x, H(pc.x, pc.y) + h1 + 0.01, pc.y), nn, blanco, Vector2(1, 0.5), t)
			m.v(m.p(pd.x, H(pd.x, pd.y) + h1 + 0.01, pd.y), nn, blanco, Vector2(1, 0.5), t)


static func _puerta_palos(m: Malla, c: Vector2, con: Array, st: Dictionary, team: Color, obra: float, col: Color) -> void:
	var u := _eje(con)
	var n := Vector2(-u.y, u.x)
	var Lh := 0.5 if absf(u.x) < 0.01 or absf(u.y) < 0.01 else 0.7072
	var pc: Dictionary = st["puerta"]
	var w0 := _cm(pc["vano_cm"]) / 2.0
	var rp := _cm(pc["poste_radio_cm"])
	var alto := _cm(st.get("alto_cm", 120)) * obra
	var top := _max_suelo(c, 0.5) + alto + _cm(pc["extra_cm"]) * obra
	if st.get("terraplen", false):
		m.usar(mat_campo(0.0, false))
		_terraplen(m, c - u * Lh, c - u * (w0 + rp))
		_terraplen(m, c + u * (w0 + rp), c + u * Lh)
	m.usar(mat_muro("madera", col))
	for s: float in [-1.0, 1.0]:
		var pp := c + u * s * (w0 + rp * 0.5)
		var g := H(pp.x, pp.y)
		palo(m, pp, rp, g - 0.35, top, col.darkened(0.08), 8, rp * 1.6)
		_palos(m, c + u * s * Lh, c + u * s * (w0 + rp * 1.6), st, obra, col, 0.0)
	if obra < 0.99:
		return
	# Travesaño y hoja de tablas verticales.
	var y_tr := top - 0.16
	var gmin := _min_suelo(c, w0)
	bloque(m, c, u, Vector2(-w0 - rp * 1.8, w0 + rp * 1.8), Vector2(-w0 - rp * 1.8, w0 + rp * 1.8), 0.06, 0.06, y_tr - 0.05, y_tr + 0.05, Color(0.85, 0.85, 0.85), Color(0.7, 0.7, 0.7))
	var tablas := maxi(3, roundi(2.0 * w0 / 0.09))
	for j in tablas:
		var q := c + u * (-w0 + (j + 0.5) * 2.0 * w0 / tablas)
		palo(m, q, 0.045, gmin - 0.05, y_tr - 0.06 - 0.03 * _hp(q, 1), col.lightened(0.06), 5, 0.0)
	var pz: Dictionary = cfg()["torre_paño"]
	m.usar(mat_muro("liso", team))
	for f: float in [-1.0, 1.0]:
		pano(m, c + n * f * 0.07, n * f, y_tr + 0.04, _cm(pz["ancho_cm"]) * 1.2, _cm(pz["alto_cm"]), team)


# ---------------------------------------------------------------- Campos y andenes

## Cultivo de un pueblo (data/arte_piezas.json → campos.cultivos).
static func cultivo_de(def: Dictionary, civ: String) -> Dictionary:
	var c: Dictionary = cfg()["campos"]
	var clave := String(c["anden"]) if def.get("permite_ladera", false) else String(por_pueblo(c["por_pueblo"], civ))
	return c["cultivos"].get(clave, c["cultivos"]["maiz"])


## Los surcos van a lo largo de x o de z según la casilla (variedad entre campos vecinos).
static func eje_campo(e: SimEntity) -> int:
	return ((e.tx / 2) + (e.ty / 2)) % 2


## Terrazas de un andén: eje, sentido y alto de cada una (siguen la ladera; en el llano, escalones).
static func terrazas(e: SimEntity) -> Dictionary:
	var an: Dictionary = cfg()["andenes"]
	var k := int(an["escalones"])
	var x0 := float(e.tx)
	var z0 := float(e.ty)
	var gw := 0.0
	var ge := 0.0
	var gn := 0.0
	var gs := 0.0
	for i in 5:
		var t := 0.1 + 0.2 * i
		gw += H(x0 + 0.05, z0 + t * e.h)
		ge += H(x0 + e.w - 0.05, z0 + t * e.h)
		gn += H(x0 + t * e.w, z0 + 0.05)
		gs += H(x0 + t * e.w, z0 + e.h - 0.05)
	var eje_x := absf(ge - gw) >= absf(gs - gn)
	var sube := 1.0 if (ge >= gw if eje_x else gs >= gn) else -1.0
	var largo := float(e.w if eje_x else e.h)
	var hs: Array[float] = []
	var step := _cm(an["escalon_min_cm"])
	for b in k:
		# Franja b (0 = la más baja), en coordenada a lo largo del eje.
		var a0 := float(b) / k
		var a1 := float(b + 1) / k
		var mx := -INF
		for i in 4:
			for j in 4:
				var fa := lerpf(a0, a1, (i + 0.5) / 4.0)
				if sube < 0.0:
					fa = 1.0 - fa
				var fo := (j + 0.5) / 4.0
				var wx := x0 + (fa * e.w if eje_x else fo * e.w)
				var wz := z0 + (fo * e.h if eje_x else fa * e.h)
				mx = maxf(mx, H(wx, wz))
		var hb := mx + 0.04
		if b > 0:
			hb = maxf(hb, hs[b - 1] + step)
		else:
			hb = maxf(hb, _min_suelo(Vector2(x0 + e.w * 0.5, z0 + e.h * 0.5), 0.9) + step)
		hs.append(hb)
	return {"eje_x": eje_x, "sube": sube, "largo": largo, "alturas": hs}


## Altura del suelo de un campo en (x, z): el terreno, o la terraza del andén.
static func suelo_campo(e: SimEntity, ter: Dictionary, x: float, z: float) -> float:
	if ter.is_empty():
		return H(x, z) + 0.035
	var fa := (x - e.tx) / e.w if ter["eje_x"] else (z - e.ty) / e.h
	if float(ter["sube"]) < 0.0:
		fa = 1.0 - fa
	var hs: Array = ter["alturas"]
	return hs[clampi(int(fa * hs.size()), 0, hs.size() - 1)]


## Campo de una granja: suelo arado que sigue el terreno (o las terrazas del andén, con sus muros
## de pirca).
static func campo(e: SimEntity, civ: String, o: Vector3) -> ArrayMesh:
	var m := Malla.new()
	m.o = o
	var cfgc: Dictionary = cfg()["campos"]
	var anden: bool = e.def.get("permite_ladera", false)
	var agua: bool = int(e.def.get("bono_agua_pct", 0)) > 0
	var ter := terrazas(e) if anden else {}
	var eje := (0 if ter["eje_x"] else 1) if anden else eje_campo(e)
	# Andén: los surcos van a lo largo de la terraza (de través al eje que sube).
	if anden:
		eje = 1 - eje
	m.usar(mat_campo(_cm(cfgc["surcos_cm"]), agua))
	var ins := 0.04
	var res := 6
	var nx := e.w * res
	var nz := e.h * res
	var x0 := e.tx + ins
	var z0 := e.ty + ins
	var sx := (e.w - 2.0 * ins) / nx
	var sz := (e.h - 2.0 * ins) / nz
	var tam := Vector2(e.w - 2.0 * ins, e.h - 2.0 * ins)
	if eje == 1:
		tam = Vector2(tam.y, tam.x)
	var pts := []
	for j in nz + 1:
		var fila := []
		for i in nx + 1:
			var x := x0 + i * sx
			var z := z0 + j * sz
			fila.append(Vector3(x, suelo_campo(e, ter, x, z), z))
		pts.append(fila)
	var blanco := Color(1, 1, 1)
	for j in nz:
		for i in nx:
			var a: Vector3 = pts[j][i]
			var b: Vector3 = pts[j][i + 1]
			var cc: Vector3 = pts[j + 1][i + 1]
			var d: Vector3 = pts[j + 1][i]
			var nn := (d - a).cross(b - a).normalized()
			if nn.y < 0.0:
				nn = -nn
			for q: Vector3 in [a, b, cc, a, cc, d]:
				var lu := Vector2(q.x - x0, q.z - z0)
				if eje == 1:
					lu = Vector2(lu.y, lu.x)
				m.v(m.p(q.x, q.y, q.z), nn, blanco, lu, tam)
	if anden:
		_muros_anden(m, e, ter)
	return m.commit()


## Muros de contención de las terrazas: el frente de cada una y los costados, de su alto hasta
## debajo del suelo.
static func _muros_anden(m: Malla, e: SimEntity, ter: Dictionary) -> void:
	var an: Dictionary = cfg()["andenes"]
	var st: Dictionary = estilo_muro({"arte": an["muro"]}, "tawantinsuyu")
	m.usar(mat_muro(String(st.get("patron", "pirca")), Color(String(st.get("piedra", "#9b8c74"))), Color(String(st.get("junta", "#6f6352")))))
	var sink := _cm(an["hundido_cm"])
	var hs: Array = ter["alturas"]
	var k := hs.size()
	var eje_x: bool = ter["eje_x"]
	var sube: float = ter["sube"]
	var lw := float(e.w)
	var lh := float(e.h)
	# Coordenadas: a (a lo largo del eje que sube, 0..1) y b (de través, 0..1).
	var W := func(a: float, b: float) -> Vector2:
		var fa := a if sube > 0.0 else 1.0 - a
		return Vector2(e.tx + (fa * lw if eje_x else b * lw), e.ty + (b * lh if eje_x else fa * lh))
	var cb := Color(0.6, 0.6, 0.6)
	var ct := Color(1.02, 1.02, 1.02)
	var pasos := 8
	# Frente de cada terraza (en a = t/k) y el fondo de la última.
	for t in k + 1:
		var a := float(t) / k
		var y_top: float = hs[mini(t, k - 1)] if t < k else hs[k - 1]
		for i in pasos:
			var b0 := float(i) / pasos
			var b1 := float(i + 1) / pasos
			var p0: Vector2 = W.call(a, b0)
			var p1: Vector2 = W.call(a, b1)
			var y0b := H(p0.x, p0.y) - sink
			var y1b := H(p1.x, p1.y) - sink
			if t > 0 and t < k:
				y0b = minf(y0b, float(hs[t - 1]) - sink)
				y1b = minf(y1b, float(hs[t - 1]) - sink)
			var d := Vector2(p1 - p0).normalized()
			var nn := Vector3(d.y, 0, -d.x)
			var along := p0.dot(Vector2(absf(d.x), absf(d.y)))
			m.quad(m.p(p0.x, y0b, p0.y), m.p(p1.x, y1b, p1.y), m.p(p1.x, y_top + 0.03, p1.y), m.p(p0.x, y_top + 0.03, p0.y), nn, cb, cb, ct, ct,
				Vector2(along, y0b), Vector2(along + 1.0 / pasos * (lh if eje_x else lw), y1b), Vector2(along + 1.0 / pasos * (lh if eje_x else lw), y_top), Vector2(along, y_top))
	# Cordón de piedra en el filo de cada terraza: se lee el escalón desde arriba.
	for t in k:
		var a := float(t) / k
		var p0: Vector2 = W.call(a, 0.0)
		var p1: Vector2 = W.call(a, 1.0)
		var dd := (p1 - p0)
		var mid := (p0 + p1) * 0.5 + Vector2(dd.y, -dd.x).normalized() * 0.0
		var hl := dd.length() * 0.5
		bloque(m, mid, dd.normalized(), Vector2(-hl, hl), Vector2(-hl, hl), 0.07, 0.06, float(hs[t]) - 0.05, float(hs[t]) + 0.055, Color(1.12, 1.12, 1.12), Color(0.8, 0.8, 0.8))
	# Costados de cada terraza.
	for t in k:
		for b: float in [0.0, 1.0]:
			for i in 3:
				var a0 := (t + i / 3.0) / k
				var a1 := (t + (i + 1) / 3.0) / k
				var p0: Vector2 = W.call(a0, b)
				var p1: Vector2 = W.call(a1, b)
				var y_top: float = hs[t]
				var d := Vector2(p1 - p0).normalized()
				var nn := Vector3(d.y, 0, -d.x)
				m.quad(m.p(p0.x, H(p0.x, p0.y) - sink, p0.y), m.p(p1.x, H(p1.x, p1.y) - sink, p1.y), m.p(p1.x, y_top + 0.03, p1.y), m.p(p0.x, y_top + 0.03, p0.y), nn, cb, cb, ct, ct,
					Vector2(p0.dot(Vector2(absf(d.x), absf(d.y))), -1), Vector2(p1.dot(Vector2(absf(d.x), absf(d.y))), -1), Vector2(p1.dot(Vector2(absf(d.x), absf(d.y))), y_top), Vector2(p0.dot(Vector2(absf(d.x), absf(d.y))), y_top))


## Matas del cultivo de un campo, apoyadas cada una en su suelo. UV2.x: alto sobre el suelo
## (el shader las hace crecer); COLOR.a = 1 en espigas y flores.
static func cultivo(e: SimEntity, civ: String, o: Vector3) -> ArrayMesh:
	var cu := cultivo_de(e.def, civ)
	var anden: bool = e.def.get("permite_ladera", false)
	var ter := terrazas(e) if anden else {}
	var eje := eje_campo(e)
	if anden:
		eje = 0 if not ter["eje_x"] else 1
	var surco := _cm(cfg()["campos"]["surcos_cm"])
	var paso := _cm(cu["paso_cm"])
	var hh := _cm(cu["alto_cm"])
	var flor := Color(String(cu["flor"]))
	flor.a = 1.0
	var forma := String(cu["forma"])
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var la := float(e.w if eje == 0 else e.h) # a lo largo de los surcos
	var lt := float(e.h if eje == 0 else e.w)
	var filas := maxi(1, int((lt - 0.16) / surco))
	var por_fila := maxi(1, int((la - 0.14) / paso))
	var mm := {"st": st, "o": o}
	for f in filas:
		var bt := 0.08 + (f + 0.5) * (lt - 0.16) / filas
		if anden:
			# Sin matas pegadas al filo de cada terraza.
			var k := (ter["alturas"] as Array).size()
			var fr := fmod(bt / lt * k, 1.0)
			if fr < 0.18 or fr > 0.9:
				continue
		for i in por_fila:
			var ba := 0.07 + (i + 0.5) * (la - 0.14) / por_fila
			var x := e.tx + (ba if eje == 0 else bt)
			var z := e.ty + (bt if eje == 0 else ba)
			var q := Vector2(x, z)
			x += (_hp(q, 1) - 0.5) * 0.05
			z += (_hp(q, 2) - 0.5) * 0.05
			var g := suelo_campo(e, ter, x, z) - 0.01
			var k := hh * (0.82 + 0.3 * _hp(q, 3))
			var var_c := 0.85 + 0.3 * _hp(q, 4)
			_mata(mm, forma, Vector3(x, g, z), k, _hp(q, 5) * TAU, Color(var_c, var_c, var_c, 0.0), flor)
	return st.commit()


## Una hoja o tallo: cuadrilátero de `a` (base, ancho wa) a `b` (punta, ancho wb), de cara a `n`.
static func _hoja(mm: Dictionary, base: Vector3, a: Vector3, b: Vector3, wa: float, wb: float, c0: Color, c1: Color) -> void:
	var st: SurfaceTool = mm["st"]
	var o: Vector3 = mm["o"]
	var d := (b - a)
	var side := d.cross(Vector3.UP)
	if side.length() < 0.001:
		side = Vector3(1, 0, 0)
	side = side.normalized()
	var nn := Vector3.UP.lerp(side.cross(d).normalized(), 0.4).normalized()
	var pts := [a - side * wa * 0.5, a + side * wa * 0.5, b + side * wb * 0.5, b - side * wb * 0.5]
	var cols := [c0, c0, c1, c1]
	for idx in [0, 1, 2, 0, 2, 3]:
		var p: Vector3 = pts[idx]
		st.set_normal(nn)
		st.set_color(cols[idx])
		st.set_uv2(Vector2(p.y - base.y, 0))
		st.add_vertex(p - o)


static func _mata(mm: Dictionary, forma: String, b: Vector3, h: float, giro: float, c: Color, flor: Color) -> void:
	var dir := func(ang: float) -> Vector3:
		return Vector3(cos(giro + ang), 0, sin(giro + ang))
	match forma:
		"maiz":
			_hoja(mm, b, b, b + Vector3(0, h, 0), h * 0.07, h * 0.04, c, c)
			_hoja(mm, b, b, b + Vector3(0, h, 0), h * 0.07, h * 0.04, c, c) # (cruzado abajo)
			for i in 4:
				var y := h * (0.3 + 0.15 * i)
				var dd: Vector3 = dir.call(i * 2.4)
				_hoja(mm, b, b + Vector3(0, y, 0), b + Vector3(0, y + h * 0.12, 0) + dd * h * 0.34, h * 0.08, h * 0.02, c, c)
			_hoja(mm, b, b + Vector3(0, h * 0.92, 0), b + Vector3(0, h * 1.12, 0), h * 0.05, h * 0.01, flor, flor)
			var ds: Vector3 = dir.call(1.0)
			_hoja(mm, b, b + Vector3(0, h * 0.5, 0) + ds * h * 0.04, b + Vector3(0, h * 0.68, 0) + ds * h * 0.09, h * 0.07, h * 0.05, flor, flor)
		"quinua":
			for i in 3:
				var dd: Vector3 = dir.call(i * 2.1)
				_hoja(mm, b, b, b + Vector3(0, h * 0.62, 0) + dd * h * 0.08, h * 0.08, h * 0.05, c, c)
				_hoja(mm, b, b + Vector3(0, h * 0.2, 0), b + Vector3(0, h * 0.4, 0) + dd * h * 0.25, h * 0.14, h * 0.04, c, c)
			for i in 3:
				var dd: Vector3 = dir.call(i * 2.1 + 0.5)
				_hoja(mm, b, b + Vector3(0, h * 0.55, 0) + dd * h * 0.03, b + Vector3(0, h * 1.0, 0) + dd * h * 0.07, h * 0.16, h * 0.06, flor, flor)
		"mandioca":
			_hoja(mm, b, b, b + Vector3(0, h * 0.8, 0), h * 0.04, h * 0.03, c * Color(0.7, 0.55, 0.45, 1.0), c)
			for t in 2:
				var y := h * (0.72 + 0.26 * t)
				for i in 5:
					var dd: Vector3 = dir.call(TAU * i / 5.0 + t * 0.6)
					_hoja(mm, b, b + Vector3(0, y, 0), b + Vector3(0, y - h * 0.06, 0) + dd * h * 0.32, h * 0.03, h * 0.11, c, c)
		"arroz", "tef":
			var n := 6 if forma == "arroz" else 5
			for i in n:
				var dd: Vector3 = dir.call(TAU * i / n)
				var tip := b + Vector3(0, h, 0) + dd * h * 0.32
				_hoja(mm, b, b, tip, h * 0.06, h * 0.01, c, c)
				if i % 2 == 0:
					_hoja(mm, b, tip - dd * h * 0.04, tip + dd * h * 0.08 - Vector3(0, h * 0.12, 0), h * 0.05, h * 0.02, flor, flor)
		_:
			_hoja(mm, b, b, b + Vector3(0, h, 0), h * 0.1, h * 0.02, c, c)


# ---------------------------------------------------------------- Cimiento

## Zócalo de un edificio: la huella hundida en el suelo; donde el suelo no se pudo aplanar (la
## orilla, el borde de otro edificio) tapa el aire bajo el edificio.
static func cimiento(e: SimEntity, civ: String) -> ArrayMesh:
	var cc: Dictionary = cfg()["cimiento"]
	var pp: Dictionary = por_pueblo(cc["por_pueblo"], civ)
	var m := Malla.new()
	m.o = Vector3.ZERO
	m.usar(mat_muro(String(pp["patron"]), Color(String(pp["color"]))))
	var hx := e.w * 0.5 - _cm(cc["borde_cm"])
	var hz := e.h * 0.5 - _cm(cc["borde_cm"])
	bloque(m, Vector2.ZERO, Vector2(1, 0), Vector2(-hx, hx), Vector2(-hx + 0.03, hx - 0.03), hz, hz - 0.03, -_cm(cc["hondo_cm"]), _cm(cc["tope_cm"]), Color(1, 1, 1), Color(0.55, 0.55, 0.55))
	return m.commit()
