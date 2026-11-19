class_name Minimap
extends Control
## Minimapa orientado como la cámara (docs/07).

var sim: Sim
var cam: RtsCamera
var ctrl: Controller
var local: int
var _img: Image
var _tex: ImageTexture
var _refresh := 0.0
var _pings: Array[Dictionary] = []
var _drag := false
var _fog_img: Image
var _fog_mini: ImageTexture
var _fog_t := 0.0
# --- mundo ---
const MundoMinimapa := preload("res://src/game/ui/mundo_minimapa.gd")
var _extra: RefCounted
# --- fin mundo ---
var ordenes: Control # --- órdenes --- capa con las bengalas (src/game/ui/ordenes_capa.gd)
# --- fluidez 4 --- filtros (recursos, militares, edificios) y tamaño (data/interfaz.json → minimapa)
const FILTROS := [["recursos", "R", "Recursos"], ["militares", "M", "Tropa"], ["edificios", "E", "Edificios"], ["rutas", "$", "Rutas de comercio"]] # --- comercio --- (el último)
static var filtros := {}
static var tam_i := -1
var _chips: Array = [] # [Rect2, clave] en píxeles del control
# --- fin fluidez 4 ---


func setup(s: Sim, c: RtsCamera, controller: Controller, local_player: int) -> void:
	sim = s
	cam = c
	ctrl = controller
	local = local_player
	mouse_filter = Control.MOUSE_FILTER_STOP
	tooltip_text = " " # --- fluidez 4 --- (sin texto Godot no pide `_get_tooltip`)
	var n := sim.map.n
	_img = Image.create(n, n, false, Image.FORMAT_RGBA8)
	_tex = ImageTexture.create_from_image(_img)
	_fog_img = Image.create(n, n, false, Image.FORMAT_LA8)
	_fog_mini = ImageTexture.create_from_image(_fog_img)
	_extra = MundoMinimapa.new(sim, local) # --- mundo ---
	# --- fluidez 4 ---
	var mc := cfg_minimapa()
	if filtros.is_empty():
		filtros = (mc.get("filtros", {"recursos": true, "militares": true, "edificios": true}) as Dictionary).duplicate()
	if tam_i < 0:
		tam_i = int(mc.get("inicial", 1))
	_extra.set("filtros", filtros)
	# --- fin fluidez 4 ---
	_rebuild()


func _rebuild_fog() -> void:
	var g: PackedByteArray = sim.fog.grids[local]
	var la := PackedByteArray()
	la.resize(g.size() * 2)
	var alpha := [235, 120, 0]
	for i in g.size():
		la[i * 2 + 1] = alpha[g[i]]
	_fog_img.set_data(sim.map.n, sim.map.n, false, Image.FORMAT_LA8, la)
	_fog_mini.update(_fog_img)


func _rebuild() -> void:
	var n := sim.map.n
	for y in n:
		for x in n:
			var k := float((x * 7 + y * 13) % 5) / 40.0
			var c := Palette.GROUND_A.lerp(Palette.GROUND_B, 0.35 + k).lightened(sim.map.h_at(x, y) * 0.09)
			var w := sim.map.water[y * sim.map.n + x]
			if sim.map.rock[y * n + x] != 0:
				c = Color("5d5853")
			elif w == 1:
				c = Color("2b4d5e")
			elif w == 2:
				c = Color("4f7478")
			_img.set_pixel(x, y, c)
	for e in sim.entities:
		if not e.alive or not e.is_resource() or not filtros.get("recursos", true): # --- fluidez 4 ---
			continue
		var col: Color
		match e.res_kind:
			"madera":
				col = Palette.FOLIAGE.darkened(0.25)
			"alimento":
				col = Palette.BERRY
			"piedra":
				col = Palette.STONE.lightened(0.2)
			_:
				col = Palette.WEALTH
		for yy in range(e.ty, e.ty + e.h):
			for xx in range(e.tx, e.tx + e.w):
				_img.set_pixel(xx, yy, col)
	_tex.update(_img)


## Lugar señalado por un aviso (la base rival): mira que late unos segundos.
var senalado := {}


func senalar(x: int, y: int, secs: float) -> void:
	senalado = {"p": Vector2(x / 1000.0, y / 1000.0), "t": secs}


func ping(x: int, y: int) -> void:
	_pings.append({"p": Vector2(x / 1000.0, y / 1000.0), "t": 0.0})


# --- mundo ---
## Destello chico donde golpean algo propio (más frecuente que el aviso "¡Nos atacan!").
func flash(x: int, y: int) -> void:
	_extra.flash(x, y)
# --- fin mundo ---


func _xf() -> Transform2D:
	var n := float(sim.map.n)
	var r := cam.right_xz()
	var f := cam.forward_xz()
	var s := (minf(size.x, size.y) - 18.0) / (n * (absf(r.x) + absf(r.z)))
	var xa := Vector2(r.x, -f.x) * s
	var ya := Vector2(r.z, -f.z) * s
	var origin := size / 2.0 - (xa + ya) * (n / 2.0)
	return Transform2D(xa, ya, origin)


func _process(delta: float) -> void:
	_refresh -= delta
	if _refresh <= 0.0:
		_refresh = 2.0
		_rebuild()
	_fog_t -= delta
	if _fog_t <= 0.0 and ctrl.view != null and ctrl.view.fog_on:
		_fog_t = 0.5
		_rebuild_fog()
	for p in _pings:
		p["t"] += delta
	_pings = _pings.filter(func(p: Dictionary) -> bool: return p["t"] < 3.0)
	if not senalado.is_empty():
		senalado["t"] = float(senalado["t"]) - delta
		if float(senalado["t"]) <= 0.0:
			senalado = {}
	_extra.process(delta) # --- mundo ---
	queue_redraw()


func _draw() -> void:
	draw_style_box(Hud.panel_box(10), Rect2(Vector2.ZERO, size))
	Hud.dibujar_marco(self, Rect2(Vector2.ZERO, size)) # --- arte de interfaz ---
	var xf := _xf()
	var n := float(sim.map.n)
	draw_set_transform_matrix(xf)
	draw_texture_rect(_tex, Rect2(0, 0, n, n), false)
	if ctrl.view.fog_on:
		draw_texture_rect(_fog_mini, Rect2(0, 0, n, n), false)
	for e in sim.actives:
		if ctrl.view.fog_state(e) == 0 or (e.is_unit() and ctrl.view.fog_state(e) < 2) or e.inside >= 0:
			continue
		var col := Palette.team(e.owner)
		if e.is_building() and filtros.get("edificios", true): # --- fluidez 4 ---
			draw_rect(Rect2(e.tx, e.ty, e.w, e.h), col if e.built else Color(col, 0.55))
			# Aliados (docs/11): sus edificios llevan borde claro, así se separan de los rivales.
			if e.owner >= 0 and e.owner != local and not sim.enemies(local, e.owner):
				draw_rect(Rect2(e.tx - 0.6, e.ty - 0.6, e.w + 1.2, e.h + 1.2), Color(1, 1, 1, 0.8), false, 0.8)
	for e in sim.actives:
		if e.is_unit() and e.inside < 0 and ctrl.view.fog_state(e) == 2 and (filtros.get("militares", true) or not e.is_military()): # --- fluidez 4 ---
			draw_rect(Rect2(e.x / 1000.0 - 0.9, e.y / 1000.0 - 0.9, 1.8, 1.8), Palette.team(e.owner).lightened(0.15))
	_extra.draw(self, ctrl.view, 1.0 / xf.x.length()) # --- mundo ---
	_draw_rutas(1.0 / xf.x.length()) # --- comercio ---
	draw_set_transform_matrix(Transform2D.IDENTITY)
	# Borde del mapa.
	var corners := PackedVector2Array([xf * Vector2(0, 0), xf * Vector2(n, 0), xf * Vector2(n, n), xf * Vector2(0, n), xf * Vector2(0, 0)])
	draw_polyline(corners, Color(1, 1, 1, 0.12), 1.0, true)
	# Lo que ve la cámara.
	var vs := get_viewport().get_visible_rect().size
	var quad := PackedVector2Array()
	for sp in [Vector2(0, 0), Vector2(vs.x, 0), Vector2(vs.x, vs.y), Vector2(0, vs.y), Vector2(0, 0)]:
		var g := cam.ground_at(sp)
		quad.append(xf * Vector2(g.x, g.z))
	draw_polyline(quad, Color(0, 0, 0, 0.5), 3.5, true) # --- mundo --- contorno para que se lea sobre el pasto claro
	draw_polyline(quad, Color(1, 1, 1, 0.85), 1.5, true)
	_draw_wonders(xf) # --- ronda 8, 05 ---
	for p in _pings:
		var k: float = fmod(p["t"], 1.0)
		draw_arc(xf * (p["p"] as Vector2), 4.0 + k * 16.0, 0, TAU, 24, Color(Palette.UI_BAD, 1.0 - k), 2.0, true)
	if not senalado.is_empty():
		var sp: Vector2 = xf * (senalado["p"] as Vector2)
		var sk := fmod(float(senalado["t"]), 1.0)
		draw_arc(sp, 6.0 + sk * 10.0, 0, TAU, 24, Color(Palette.UI_ACCENT, 0.4 + 0.6 * sk), 2.5, true)
		for dv in [Vector2(1, 0), Vector2(-1, 0), Vector2(0, 1), Vector2(0, -1)]:
			draw_line(sp + dv * 4.0, sp + dv * 10.0, Color(0, 0, 0, 0.7), 3.5)
			draw_line(sp + dv * 4.0, sp + dv * 10.0, Palette.UI_ACCENT, 1.8)
	# --- órdenes --- (bengalas del equipo)
	if ordenes != null:
		for f in ordenes.flares:
			var fk: float = fmod(f["t"] * 1.5, 1.0)
			var fp: Vector2 = xf * Vector2(f["x"], f["y"])
			draw_arc(fp, 5.0 + fk * 18.0, 0, TAU, 24, Color(Palette.team(f["player"]), 1.0 - fk), 2.5, true)
			draw_circle(fp, 3.5, Color.WHITE)
	# --- fin órdenes ---
	_draw_chips() # --- fluidez 4 ---


# --- fluidez 4 ---
## --- ronda 8, 05 --- Marca fija de cada maravilla, en obra o terminada, aun con la niebla (la
## ven todos, como en AoE4): un rombo con el color del dueño y, si es rival, un anillo que late.
func _draw_wonders(xf: Transform2D) -> void:
	var beat := 0.5 + 0.5 * sin(Time.get_ticks_msec() / 220.0)
	for p in sim.players:
		var w := sim.wonder_of(int(p["id"]))
		if w == null:
			continue
		var c: Vector2 = xf * Vector2(w.tx + w.w / 2.0, w.ty + w.h / 2.0)
		var col := Palette.team(w.owner)
		var r := 6.0
		var dia := PackedVector2Array([c + Vector2(0, -r), c + Vector2(r, 0), c + Vector2(0, r), c + Vector2(-r, 0)])
		draw_colored_polygon(dia, Color(0, 0, 0, 0.75))
		var r2 := r - 1.8
		draw_colored_polygon(PackedVector2Array([c + Vector2(0, -r2), c + Vector2(r2, 0), c + Vector2(0, r2), c + Vector2(-r2, 0)]), col if w.built else Color(col, 0.6))
		if sim.enemies(local, w.owner):
			draw_arc(c, 9.0 + beat * 3.0, 0, TAU, 24, Color(Palette.UI_BAD, 0.5 + 0.5 * beat), 2.0, true)


static func cfg_minimapa() -> Dictionary:
	var path := "res://data/interfaz.json"
	var all: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(path)) if FileAccess.file_exists(path) else {}
	return all.get("minimapa", {})


## Lado en píxeles del tamaño elegido.
func lado() -> float:
	var t: Array = cfg_minimapa().get("tamanos", [250])
	return float(t[clampi(tam_i, 0, t.size() - 1)])


## Prende o apaga un filtro ("recursos", "militares", "edificios").
func filtrar(clave: String, on: bool) -> void:
	filtros[clave] = on
	_rebuild()
	queue_redraw()


## Pasa al tamaño siguiente (vuelve al más chico después del más grande).
func cambiar_tamano() -> void:
	var t: Array = cfg_minimapa().get("tamanos", [250])
	tam_i = (tam_i + 1) % t.size()
	aplicar_tamano()


func aplicar_tamano() -> void:
	var s := lado()
	offset_left = 12
	offset_right = 12 + s
	offset_top = -12 - s
	offset_bottom = -12


func _draw_chips() -> void:
	_chips.clear()
	var x := 8.0
	for f in FILTROS:
		var r := Rect2(x, 6, 20, 18)
		var on: bool = filtros.get(f[0], true)
		draw_rect(r, Color(0, 0, 0, 0.55 if on else 0.3))
		draw_rect(r, Color(Palette.UI_ACCENT, 0.9) if on else Color(1, 1, 1, 0.25), false, 1.0)
		draw_string(Hud.font_b, r.position + Vector2(0, 14), f[1], HORIZONTAL_ALIGNMENT_CENTER, r.size.x, 12, Palette.UI_TEXT if on else Palette.UI_DIM)
		_chips.append([r, f[0]])
		x += 23.0
	var rt := Rect2(size.x - 28, 6, 20, 18)
	draw_rect(rt, Color(0, 0, 0, 0.55))
	draw_rect(rt, Color(1, 1, 1, 0.35), false, 1.0)
	draw_string(Hud.font_b, rt.position + Vector2(0, 14), "±", HORIZONTAL_ALIGNMENT_CENTER, rt.size.x, 13, Palette.UI_TEXT)
	_chips.append([rt, "tamano"])


func _get_tooltip(at: Vector2) -> String:
	for c in _chips:
		if (c[0] as Rect2).has_point(at):
			if c[1] == "tamano":
				return "Tamaño del minimapa"
			for f in FILTROS:
				if f[0] == c[1]:
					return "%s en el minimapa: %s" % [f[2], "se ven" if filtros.get(f[0], true) else "ocultos"]
	return ""
# --- fin fluidez 4 ---


# --- comercio --- (proceso/33-comercio, §3) rutas en el minimapa: las de lo seleccionado
# siempre; con el botón «Rutas», todas las propias y aliadas, y las enemigas donde hay visión.
func _draw_rutas(px: float) -> void:
	var todas: bool = filtros.get("rutas", false)
	var sel := {}
	for e in ctrl.selected_entities():
		sel[e.id] = true
	var rutas := {}
	for e in sim.actives:
		if not e.is_unit() or e.order != SimEntity.Order.TRADE or e.owner < 0:
			continue
		var mine := sel.has(e.id) or sel.has(e.trade_home)
		if not mine:
			if not todas:
				continue
			if sim.enemies(local, e.owner) and ctrl.view.fog_state(e) < 2:
				continue
		rutas[[e.owner, e.trade_home, e.trade_dest, e.trade_wx, e.trade_wy]] = true
	for k: Array in rutas:
		var home: SimEntity = sim.by_id.get(k[1])
		var dest: SimEntity = sim.by_id.get(k[2])
		if home == null or dest == null:
			continue
		var pts := PackedVector2Array([Vector2(home.x, home.y) / 1000.0])
		if int(k[3]) >= 0:
			pts.append(Vector2(k[3], k[4]) / 1000.0)
		pts.append(Vector2(dest.x, dest.y) / 1000.0)
		var col := Palette.team(int(k[0]))
		for i in range(1, pts.size()):
			var a := pts[i - 1]
			var b := pts[i]
			var n := int(a.distance_to(b) / 3.0)
			for j in n:
				if j % 2 == 0:
					draw_line(a.lerp(b, float(j) / n), a.lerp(b, float(j + 1) / n), col, px * 1.6)
	for m in sim.comercio.neutrals:
		draw_rect(Rect2(m.tx - 0.5, m.ty - 0.5, 4, 4), Palette.WEALTH, false, px * 1.5)
# --- fin comercio ---


func _to_tile(local_pos: Vector2) -> Vector2:
	return _xf().affine_inverse() * local_pos


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		# --- fluidez 4 --- (botones de filtro y tamaño)
		if mb.button_index == MOUSE_BUTTON_LEFT and mb.pressed:
			for c in _chips:
				if (c[0] as Rect2).has_point(mb.position):
					if c[1] == "tamano":
						cambiar_tamano()
					else:
						filtrar(c[1], not filtros.get(c[1], true))
					accept_event()
					return
		# --- fin fluidez 4 ---
		if mb.button_index == MOUSE_BUTTON_LEFT:
			# --- órdenes --- (Alt + clic en el minimapa: bengala)
			if mb.pressed and Input.is_key_pressed(KEY_ALT):
				var ft := _to_tile(mb.position)
				ctrl.flare(Vector3(clampf(ft.x, 0.5, sim.map.n - 0.5), 0, clampf(ft.y, 0.5, sim.map.n - 0.5)))
				accept_event()
				return
			# --- fin órdenes ---
			_drag = mb.pressed
			if mb.pressed:
				var t := _to_tile(mb.position)
				cam.look_at_point(Vector3(t.x, 0, t.y))
		elif mb.button_index == MOUSE_BUTTON_RIGHT and mb.pressed:
			var t := _to_tile(mb.position)
			# --- mundo --- órdenes desde el minimapa: mover (o ataque en movimiento con A),
			# encolar con mayúsculas y punto de reunión para edificios.
			var g := Vector3(clampf(t.x, 0.5, sim.map.n - 0.5), 0, clampf(t.y, 0.5, sim.map.n - 0.5))
			g.y = WorldView.height_at(g.x, g.z)
			var ids := []
			var shift := Input.is_key_pressed(KEY_SHIFT)
			for e in ctrl.selected_entities():
				if e.owner == local and e.is_unit():
					ids.append(e.id)
			if not ids.is_empty():
				var amove := ctrl.mode == "amove"
				if shift and ctrl.cola != null:
					if amove:
						ctrl.cola.orden_amove(ids, g)
					else:
						ctrl.cola.orden_derecha(ids, null, g, true)
				else:
					if ctrl.cola != null:
						ctrl.cola.limpiar(ids)
					sim.push_command({"t": "move", "player": local, "ids": ids, "x": int(g.x * 1000), "y": int(g.z * 1000), "amove": amove, "form": ctrl.formacion}) # --- órdenes ---
				ctrl.view.add_marker(g, Palette.UI_BAD if amove else Palette.UI_GOOD)
				if amove and not shift:
					ctrl.cancel_mode()
			else:
				var rally := false
				for e in ctrl.selected_entities():
					if e.owner == local and e.is_building() and e.def.has("produce"):
						sim.push_command({"t": "rally", "player": local, "building": e.id, "x": int(g.x * 1000), "y": int(g.z * 1000), "target": -1})
						rally = true
				if rally:
					ctrl.view.add_marker(g, Palette.UI_ACCENT)
			# --- fin mundo ---
		accept_event()
	elif event is InputEventMouseMotion and _drag:
		var t := _to_tile((event as InputEventMouseMotion).position)
		cam.look_at_point(Vector3(t.x, 0, t.y))
		accept_event()
