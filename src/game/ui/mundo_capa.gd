extends Control
## Información sobre el mundo 3D: alcances, órdenes, íconos de trabajo, textos
## flotantes, sitios sagrados y vista previa al colocar edificios (docs/07, "Información en el mundo").
## Dibuja en 2D proyectando puntos del suelo: no agrega nodos a la escena y solo lee la simulación.

const Colocacion := preload("res://src/game/ui/mundo_colocacion.gd")
const Cola := preload("res://src/game/ui/mundo_cola.gd")
const P := 1000.0
const O := SimEntity.Order

## Topes de textos flotantes a la vez (para no saturar la pantalla).
const MAX_ENTREGAS := 10
const MAX_DANIOS := 8
## Un golpe es "fuerte" si saca al menos esta fracción de la vida máxima.
const DANIO_FUERTE := 0.12
## Más unidades seleccionadas que esto: solo se dibuja la línea al destino (sin el camino).
const MAX_CAMINOS := 12
const MAX_ALCANCES := 24
const TECLA_INFO := KEY_ALT

var sim: Sim
var ctrl: Controller
var cam: RtsCamera
var view: WorldView
var mini: Control
var local: int
var cola: RefCounted

var _floats: Array[Dictionary] = []
var _time := 0.0
var _site_r := 0.0
var _sites: Array[SimEntity] = []
var _sites_tick := -1
var _font: Font
var _tip: Control
var _tip_lines: Array = []


func setup(s: Sim, c: Controller, camera: RtsCamera, minimap: Control) -> void:
	sim = s
	ctrl = c
	cam = camera
	view = c.view
	local = c.local
	mini = minimap
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_font = Hud.font_b
	_site_r = float(sim.data.reglas.get("sitios", {}).get("radio", 0)) / P
	cola = Cola.new(sim, local)
	ctrl.cola = cola
	_tip = Control.new()
	_tip.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_tip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_tip.z_index = 50
	_tip.draw.connect(_draw_tip)
	add_child(_tip)


func _process(delta: float) -> void:
	_time += delta
	cola.tick()
	var keep: Array[Dictionary] = []
	for f in _floats:
		f["t"] += delta
		if f["t"] < f["dur"]:
			keep.append(f)
	_floats = keep
	queue_redraw()
	_tip.queue_redraw()


# ---------------------------------------------------------------- Eventos

func on_events(events: Array) -> void:
	for ev in events:
		match ev["t"]:
			"deposit":
				var e: SimEntity = sim.by_id.get(ev["id"])
				if e != null and e.owner == local and int(ev["n"]) > 0:
					_float_deposit(e, ev["res"], int(ev["n"]))
			"hit":
				var b: SimEntity = sim.by_id.get(ev["b"])
				if b == null or b.owner < 0:
					continue
				if b.owner == local and mini != null:
					mini.flash(b.x, b.y)
				var dmg := int(ev.get("dmg", 0))
				if dmg > 0 and float(dmg) >= float(b.hp_max) * DANIO_FUERTE and view.fog_state(b) == 2:
					_float_damage(b, dmg)
			"age":
				if int(ev["player"]) == local:
					_float_age(int(ev["age"]), String(ev.get("hito", "")))


func _count(kind: String) -> int:
	var n := 0
	for f in _floats:
		if f["kind"] == kind:
			n += 1
	return n


func _float_deposit(e: SimEntity, res: String, n: int) -> void:
	var pos := WorldView.to_world(e.x, e.y, 1.5)
	# Entregas seguidas en el mismo depósito se suman en un solo número.
	for f in _floats:
		if f["kind"] == "dep" and f["res"] == res and (f["pos"] as Vector3).distance_to(pos) < 3.0 and f["t"] < 0.9:
			f["n"] += n
			f["text"] = "+%d" % f["n"]
			f["t"] = minf(f["t"], 0.2)
			return
	if _count("dep") >= MAX_ENTREGAS or not _on_screen(pos):
		return
	_floats.append({"kind": "dep", "res": res, "n": n, "pos": pos, "text": "+%d" % n, "col": Palette.RES.get(res, Palette.UI_TEXT), "t": 0.0, "dur": 1.6, "size": 16, "icon": res})


func _float_damage(b: SimEntity, dmg: int) -> void:
	var pos := WorldView.to_world(b.x, b.y, 1.4 if b.is_unit() else 2.4)
	if _count("dmg") >= MAX_DANIOS or not _on_screen(pos):
		return
	pos += Vector3(randf_range(-0.3, 0.3), 0, randf_range(-0.3, 0.3))
	var col := Palette.UI_BAD if b.owner == local else Color("ffb15c")
	_floats.append({"kind": "dmg", "pos": pos, "text": "-%d" % dmg, "col": col, "t": 0.0, "dur": 1.1, "size": 17})


func _float_age(age: int, hito: String) -> void:
	var hito_e: SimEntity = null
	var capital: SimEntity = null
	for e in sim.actives:
		if e.owner != local or not e.is_building():
			continue
		if e.type == hito and (hito_e == null or e.id > hito_e.id):
			hito_e = e
		if e.capital:
			capital = e
	var at := hito_e if hito_e != null else capital
	if at == null:
		return
	_floats.append({"kind": "age", "pos": WorldView.to_world(at.x, at.y, 4.0), "text": "¡Edad %s!" % Sim._roman(age), "col": Palette.UI_ACCENT, "t": 0.0, "dur": 3.2, "size": 34})


# ---------------------------------------------------------------- Proyección

func _on_screen(wp: Vector3) -> bool:
	if cam.cam.is_position_behind(wp):
		return false
	return get_viewport_rect().grow(40).has_point(cam.cam.unproject_position(wp))


## Punto del suelo (en casillas) proyectado a la pantalla.
func _gp(x: float, z: float, lift: float = 0.06) -> Vector2:
	return cam.cam.unproject_position(Vector3(x, WorldView.height_at(x, z) + lift, z))


## Contorno de un rectángulo del suelo agrandado `r` casillas (esquinas redondeadas):
## es la forma exacta del alcance medido al borde de un edificio.
func _shape(x0: float, z0: float, x1: float, z1: float, r: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	var seg := 8 if r > 0.0 else 1
	var corners := [[x1, z1, 0.0], [x0, z1, PI * 0.5], [x0, z0, PI], [x1, z0, PI * 1.5]]
	for c in corners:
		for i in seg + 1:
			var a: float = c[2] + PI * 0.5 * float(i) / float(seg)
			pts.append(_gp(c[0] + cos(a) * r, c[1] + sin(a) * r))
	# Lados largos sin esquinas: se subdividen para seguir el relieve.
	return pts


func _draw_area(pts: PackedVector2Array, center: Vector2, col: Color, fill_a: float, width: float = 2.0) -> void:
	if pts.size() < 3:
		return
	if fill_a > 0.0:
		var fc := Color(col, fill_a)
		var cols := PackedColorArray([fc, fc, fc])
		for i in pts.size():
			draw_primitive(PackedVector2Array([center, pts[i], pts[(i + 1) % pts.size()]]), cols, PackedVector2Array())
	var closed := pts.duplicate()
	closed.append(pts[0])
	draw_polyline(closed, Color(0, 0, 0, col.a * 0.35), width + 2.0, true)
	draw_polyline(closed, col, width, true)


## Alcance medido desde el borde de un edificio o desde el centro de una unidad.
func _draw_reach(e: SimEntity, reach: float, col: Color, fill_a: float) -> void:
	var wp := WorldView.to_world(e.x, e.y)
	if cam.cam.is_position_behind(wp):
		return
	if e.is_building():
		_draw_area(_shape(e.tx, e.ty, e.tx + e.w, e.ty + e.h, reach), _gp(wp.x, wp.z), col, fill_a)
	else:
		_draw_area(_shape(wp.x, wp.z, wp.x, wp.z, reach + e.radius / P), _gp(wp.x, wp.z), col, fill_a, 1.5)


static func _reach_of(sim_: Sim, e: SimEntity) -> float:
	var r := float(e.def.get("alcance", 0))
	if e.is_building():
		r += sim_.mod(e.owner, "b_alcance")
	return r / P


# ---------------------------------------------------------------- Dibujo

func _draw() -> void:
	if sim == null or not is_visible_in_tree():
		return
	var info := Input.is_key_pressed(TECLA_INFO) and ctrl.enabled
	_tip_lines = []
	_draw_sites()
	_draw_ranges(info)
	if ctrl.mode == "place" and ctrl.place_type != "":
		_draw_placement()
	_draw_orders()
	_draw_icons()
	_draw_floats()


## Sitios sagrados: zona de captura con el color de quien lo tiene y anillo de progreso.
func _draw_sites() -> void:
	if sim.tick != _sites_tick:
		_sites_tick = sim.tick
		_sites.clear()
		for e in sim.actives:
			if e.is_building() and e.def.get("sagrado", false):
				_sites.append(e)
	for e in _sites:
		if not e.alive or view.fog_state(e) == 0:
			continue
		var wp := WorldView.to_world(e.x, e.y)
		if not _on_screen(wp):
			continue
		var c := _gp(wp.x, wp.z)
		var hold := Palette.team(e.holder) if e.holder >= 0 else Color(0.95, 0.92, 0.85)
		var zone := _shape(wp.x - _site_r, wp.z - _site_r, wp.x + _site_r, wp.z + _site_r, 0.0)
		_draw_area(zone, c, Color(hold, 0.7), 0.08 if e.holder >= 0 else 0.03, 1.5)
		var seen := view.fog_state(e) == 2
		if not seen or e.capture <= 0 or e.aux < 0:
			continue
		var cfg: Dictionary = sim.data.reglas["sitios"]
		var k := clampf(float(e.capture) / float(cfg["captura_ms"]), 0.0, 1.0)
		var ring := PackedVector2Array()
		var full := PackedVector2Array()
		var rr := 1.9
		for i in 33:
			var a := -PI * 0.5 + TAU * float(i) / 32.0
			var p := _gp(wp.x + cos(a) * rr, wp.z + sin(a) * rr, 0.08)
			full.append(p)
			if float(i) / 32.0 <= k:
				ring.append(p)
		draw_polyline(full, Color(0, 0, 0, 0.45), 6.0, true)
		if ring.size() >= 2:
			draw_polyline(ring, Palette.team(e.aux), 4.0, true)
		var bottom := 0.0
		for p in full:
			bottom = maxf(bottom, p.y)
		var who := "Capturás" if e.aux == local else "Te lo toman"
		_text(Vector2(c.x, bottom + 20), "%s · %d%%" % [who, int(k * 100.0)], 14, Palette.team(e.aux).lightened(0.55), true)


## Alcance de torres y centros seleccionados; con la tecla de información, el de toda
## la selección y el de las defensas enemigas a la vista.
func _draw_ranges(info: bool) -> void:
	var drawn := 0
	var seen := []
	for e in ctrl.selected_entities():
		if drawn >= MAX_ALCANCES:
			break
		if e.is_building() and e.def.has("ataque") and e.built:
			var col := Color(1, 1, 1, 0.6) if e.owner == local else Color(Palette.UI_BAD, 0.75)
			_draw_reach(e, _reach_of(sim, e), col, 0.05)
			drawn += 1
		elif info and e.is_unit() and e.def.has("ataque"):
			# Una formación de iguales comparte casi el mismo círculo: se dibuja uno
			# por cada grupo de unidades con el mismo alcance a menos de 2 casillas.
			var reach := maxf(_reach_of(sim, e), 0.4)
			var here := Vector2(e.x / P, e.y / P)
			var dup := false
			for d in seen:
				if d[1] == reach and (d[0] as Vector2).distance_squared_to(here) < 4.0:
					dup = true
					break
			if dup:
				continue
			seen.append([here, reach])
			var col := Color(Palette.UI_ACCENT, 0.75) if e.owner == local else Color(Palette.UI_BAD, 0.75)
			_draw_reach(e, reach, col, 0.0)
			drawn += 1
	if not info:
		return
	for e in sim.actives:
		if e.is_building() and e.owner >= 0 and e.owner != local and e.def.has("ataque") and e.built and view.fog_state(e) > 0:
			if _on_screen(WorldView.to_world(e.x, e.y)):
				_draw_reach(e, _reach_of(sim, e), Color(Palette.UI_BAD, 0.55), 0.06)


## Vista previa del edificio que se está por colocar.
func _draw_placement() -> void:
	var type: String = ctrl.place_type
	var def: Dictionary = sim.dp(local).edificios.get(type, {})
	if def.is_empty():
		return
	var tile: Vector2i = ctrl._ghost.get_meta("tile", Vector2i(-1, -1))
	if tile.x < -50:
		return
	var tam: Array = def["tam"]
	var cx: float = tile.x + tam[0] / 2.0
	var cz: float = tile.y + tam[1] / 2.0
	var center := _gp(cx, cz)
	# Defensas propias ya hechas: para ubicar la nueva sin superponer de más.
	if def.has("ataque"):
		for e in sim.actives:
			if e.owner == local and e.is_building() and e.def.has("ataque") and _on_screen(WorldView.to_world(e.x, e.y)):
				_draw_reach(e, _reach_of(sim, e), Color(1, 1, 1, 0.22), 0.0)
		var reach := (float(def["alcance"]) + sim.mod(local, "b_alcance")) / P
		_draw_area(_shape(tile.x, tile.y, tile.x + tam[0], tile.y + tam[1], reach), center, Color(Palette.UI_ACCENT, 0.85), 0.07)
	if int(def.get("guarnicion", 0)) > 0:
		var rc := float(sim.data.reglas.get("radio_campana", 0)) / P
		_draw_area(_shape(tile.x, tile.y, tile.x + tam[0], tile.y + tam[1], rc), center, Color(0.7, 0.85, 1.0, 0.55), 0.0, 1.5)
	# Separación mínima: dónde no puede ir otra pieza del mismo tipo.
	var sep := int(def.get("separacion", 0))
	if sep > 0:
		for e in sim.actives:
			if e.owner == local and e.type == type and _on_screen(WorldView.to_world(e.x, e.y)):
				var ec := _gp(e.x / P, e.y / P)
				_draw_area(_shape(e.tx - sep + 1, e.ty - sep + 1, e.tx + sep - 1 + e.w, e.ty + sep - 1 + e.h, 0.0), ec, Color(Palette.UI_BAD, 0.6), 0.06, 1.5)
	if ctrl._line_drag:
		return
	# Casillas de la huella: verdes, doradas (ladera que rinde) o rojas (bloquean).
	for c in Colocacion.casillas(sim, type, tile.x, tile.y, local):
		var col: Color = [Color(0.45, 1.0, 0.55, 0.28), Color(Palette.UI_ACCENT, 0.45), Color(1.0, 0.3, 0.25, 0.55)][c[2]]
		var q := PackedVector2Array([_gp(c[0] + 0.06, c[1] + 0.06), _gp(c[0] + 0.94, c[1] + 0.06), _gp(c[0] + 0.94, c[1] + 0.94), _gp(c[0] + 0.06, c[1] + 0.94)])
		draw_colored_polygon(q, col)
	# Renglones junto al cursor: van en una capa encima de los paneles.
	_tip_lines = Colocacion.detalles(sim, local, type, tile.x, tile.y)


## Recuadro de la vista previa junto al cursor (encima de la interfaz).
func _draw_tip() -> void:
	var lines := _tip_lines
	if lines.is_empty() or ctrl.mode != "place":
		return
	var m := ctrl.mouse_pos() + Vector2(22, 18)
	var fs := 14
	var wmax := 0.0
	for l in lines:
		wmax = maxf(wmax, _font.get_string_size(l[0], HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x)
	var box := Rect2(m, Vector2(wmax + 16, lines.size() * 19 + 8))
	var vs := get_viewport_rect().size
	if box.end.x > vs.x - 8:
		box.position.x = m.x - 44 - box.size.x
	if box.end.y > vs.y - 8:
		box.position.y = m.y - 36 - box.size.y
	_tip.draw_rect(box, Color(0.06, 0.065, 0.075, 0.9))
	_tip.draw_rect(box, Color(1, 1, 1, 0.12), false, 1.0)
	for i in lines.size():
		_tip.draw_string(_font, box.position + Vector2(8, 18 + i * 19), lines[i][0], HORIZONTAL_ALIGNMENT_LEFT, -1, fs, lines[i][1])


## Punto de reunión de los edificios seleccionados y orden en curso (más la cola) de
## las unidades seleccionadas, como líneas punteadas. Los trazos se juntan por color
## y se dibujan con una sola llamada (con 100 unidades seleccionadas sigue liviano).
func _draw_orders() -> void:
	var sel := ctrl.selected_entities()
	if sel.is_empty() or sel[0].owner != local:
		return
	var few := sel.size() <= MAX_CAMINOS
	var dashes := {} # Color -> Array de puntos (por pares)
	var dots := {} # casilla del destino -> [punto, color, radio, número]
	for e in sel:
		if e.is_building():
			if e.rally_set and e.def.has("produce"):
				var a := _gp(e.x / P, e.y / P, 0.3)
				var to := Vector2(e.rally_x, e.rally_y)
				var rt: SimEntity = sim.by_id.get(e.rally_target)
				if rt != null and rt.alive and e.rally_target >= 0:
					to = Vector2(rt.x, rt.y)
				var b := _gp(to.x / P, to.y / P, 0.1)
				_dash(dashes, a, b, Color(Palette.UI_ACCENT, 0.95), 9.0)
				dots[Vector2i(to / P)] = [b, Palette.UI_ACCENT, 4.5, ""]
			continue
		if not e.is_unit() or e.inside >= 0:
			continue
		var v: Dictionary = view.visuals.get(e.id, {})
		var np: Vector3 = (v["node"] as Node3D).position if not v.is_empty() else WorldView.to_world(e.x, e.y)
		var from := _gp(np.x, np.z, 0.1)
		var end := Vector2(-1, -1)
		var col := Palette.UI_GOOD
		var t: SimEntity = sim.by_id.get(e.target) if e.target >= 0 else null
		match e.order:
			O.MOVE:
				end = Vector2(e.goal_x, e.goal_y)
			O.ATTACK_MOVE:
				end = Vector2(e.amove_x, e.amove_y)
				col = Color("ff8a5c")
			O.ATTACK:
				col = Palette.UI_BAD
			O.GATHER, O.RETURN:
				col = Palette.RES.get(e.carry_res if e.carry_res != "" else e.gather_kind, Palette.UI_ACCENT)
				if e.order == O.RETURN:
					t = sim.by_id.get(e.aux)
			O.BUILD:
				col = Palette.UI_ACCENT
			O.GARRISON:
				col = Color(0.75, 0.85, 1.0)
		# Con muchas unidades seleccionadas solo se marcan los destinos de movimiento:
		# las líneas a cada blanco o recurso serían una maraña.
		if end.x < 0 and t != null and t.alive and few:
			end = Vector2(t.x, t.y)
		var last := from
		var lc := Color(col, 0.8)
		if end.x >= 0:
			if few and e.order in [O.MOVE, O.ATTACK_MOVE] and e.path_i < e.path.size():
				for i in range(e.path_i, e.path.size()):
					var pt := _gp(e.path[i].x + 0.5, e.path[i].y + 0.5, 0.1)
					_dash(dashes, last, pt, lc, 7.0)
					last = pt
			var pe := _gp(end.x / P, end.y / P, 0.1)
			_dash(dashes, last, pe, lc, 7.0 if few else 0.0)
			dots[Vector2i(end / P)] = [pe, col, 3.0, ""]
			last = pe
		# Órdenes en cola (mayúsculas): siguen desde el destino actual, numeradas.
		var queued: Array = cola.puntos(e.id)
		for i in queued.size():
			var q: Array = queued[i]
			var qc := Color("ff8a5c") if q[2] else Palette.UI_GOOD
			var pq := _gp(q[0] / P, q[1] / P, 0.1)
			_dash(dashes, last, pq, Color(qc, 0.8), 5.0)
			var key := Vector2i(int(q[0] / P), int(q[1] / P))
			if not dots.has(key) or dots[key][3] == "":
				dots[key] = [pq, qc, 6.5, str(i + 1)]
			last = pq
	for c in dashes:
		var segs := PackedVector2Array(dashes[c])
		draw_multiline(segs, Color(0, 0, 0, 0.35), 3.5)
		draw_multiline(segs, c, 2.0)
	for k in dots:
		var d: Array = dots[k]
		draw_circle(d[0], d[2] + 1.5, Color(0, 0, 0, 0.55))
		draw_circle(d[0], d[2], d[1])
		if d[3] != "":
			_text(d[0] + Vector2(0, 4), d[3], 11, Color(0.05, 0.05, 0.05), false)


## Agrega los trazos de una línea punteada al lote de su color.
func _dash(acc: Dictionary, a: Vector2, b: Vector2, col: Color, step: float) -> void:
	var segs: Array = acc.get_or_add(col, [])
	var d := b - a
	var n := int(d.length() / (step * 2.0)) if step > 0.0 else 0
	if n <= 0:
		segs.append(a)
		segs.append(b)
	else:
		var u := d / (n * 2.0)
		for i in n:
			segs.append(a + u * (i * 2))
			segs.append(a + u * (i * 2 + 1))


## Íconos sobre los aldeanos propios: ocioso (Zz) o lo que recolecta.
func _draw_icons() -> void:
	var zoom_k := clampf(40.0 / cam.zoom, 0.6, 1.4)
	var show_work := cam.zoom < 55.0
	var vr := get_viewport_rect().grow(20)
	for e in sim.actives:
		if e.owner != local or e.fn != "civil" or e.inside >= 0:
			continue
		var idle := e.order == O.IDLE
		var kind := ""
		if not idle:
			if not show_work:
				continue
			if e.order == O.GATHER or e.order == O.RETURN:
				kind = e.carry_res if e.carry_res != "" else e.gather_kind
			elif e.order == O.BUILD:
				kind = "construir"
			if kind == "":
				continue
		var v: Dictionary = view.visuals.get(e.id, {})
		if v.is_empty():
			continue
		var wp: Vector3 = (v["node"] as Node3D).position + Vector3(0, 1.75, 0)
		if cam.cam.is_position_behind(wp):
			continue
		var sp := cam.cam.unproject_position(wp)
		if not vr.has_point(sp):
			continue
		if idle:
			var bob := sin(_time * 4.0 + e.id) * 2.0
			var r := 9.0 * zoom_k
			var c := sp + Vector2(0, -r + bob)
			draw_circle(c, r + 1.5, Color(0, 0, 0, 0.6))
			draw_circle(c, r, Palette.UI_ACCENT)
			_text(c + Vector2(0, r * 0.45), "Zz", int(11 * zoom_k), Color(0.12, 0.1, 0.05), false)
		else:
			var s := 15.0 * zoom_k
			var c := sp + Vector2(0, -s * 0.5)
			draw_circle(c, s * 0.55, Color(0, 0, 0, 0.5))
			if kind == "construir":
				_hammer(c, s, Palette.UI_ACCENT)
			else:
				Glyphs.draw(self, kind, Rect2(c - Vector2(s, s) * 0.5, Vector2(s, s)), Palette.RES.get(kind, Palette.UI_TEXT))


func _hammer(c: Vector2, s: float, col: Color) -> void:
	draw_line(c + Vector2(-s * 0.25, s * 0.3), c + Vector2(s * 0.15, -s * 0.1), col, maxf(1.5, s * 0.12))
	draw_rect(Rect2(c + Vector2(0.0, -s * 0.35), Vector2(s * 0.32, s * 0.2)), col)


func _draw_floats() -> void:
	for f in _floats:
		var pos: Vector3 = f["pos"]
		if cam.cam.is_position_behind(pos):
			continue
		var k: float = f["t"] / f["dur"]
		var sp := cam.cam.unproject_position(pos)
		var rise := 34.0 if f["kind"] != "age" else 26.0
		sp.y -= k * rise
		var a := 1.0 if k < 0.6 else 1.0 - (k - 0.6) / 0.4
		var size: int = f["size"]
		if f["kind"] == "age":
			size = int(size * (1.0 + 0.25 * maxf(0.0, 1.0 - f["t"] * 3.0)))
		var col: Color = f["col"]
		_text(sp, f["text"], size, Color(col, a), true)
		if f.has("icon"):
			var tw := _font.get_string_size(f["text"], HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
			Glyphs.draw(self, f["icon"], Rect2(sp + Vector2(tw * 0.5 + 2, -size * 0.85), Vector2(size, size)), Color(col, a))


## Texto centrado con contorno oscuro.
func _text(at: Vector2, s: String, size: int, col: Color, outline: bool) -> void:
	var w := _font.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	var p := at - Vector2(w * 0.5, 0)
	if outline:
		draw_string_outline(_font, p, s, HORIZONTAL_ALIGNMENT_LEFT, -1, size, 4, Color(0, 0, 0, col.a * 0.75))
	draw_string(_font, p, s, HORIZONTAL_ALIGNMENT_LEFT, -1, size, col)
