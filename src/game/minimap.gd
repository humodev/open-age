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


func setup(s: Sim, c: RtsCamera, controller: Controller, local_player: int) -> void:
	sim = s
	cam = c
	ctrl = controller
	local = local_player
	mouse_filter = Control.MOUSE_FILTER_STOP
	var n := sim.map.n
	_img = Image.create(n, n, false, Image.FORMAT_RGBA8)
	_tex = ImageTexture.create_from_image(_img)
	_fog_img = Image.create(n, n, false, Image.FORMAT_LA8)
	_fog_mini = ImageTexture.create_from_image(_fog_img)
	_extra = MundoMinimapa.new(sim, local) # --- mundo ---
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
		if not e.alive or not e.is_resource():
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
	_extra.process(delta) # --- mundo ---
	queue_redraw()


func _draw() -> void:
	draw_style_box(Hud.panel_box(10), Rect2(Vector2.ZERO, size))
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
		if e.is_building():
			draw_rect(Rect2(e.tx, e.ty, e.w, e.h), col if e.built else Color(col, 0.55))
	for e in sim.actives:
		if e.is_unit() and e.inside < 0 and ctrl.view.fog_state(e) == 2:
			draw_rect(Rect2(e.x / 1000.0 - 0.9, e.y / 1000.0 - 0.9, 1.8, 1.8), Palette.team(e.owner).lightened(0.15))
	_extra.draw(self, ctrl.view, 1.0 / xf.x.length()) # --- mundo ---
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
	for p in _pings:
		var k: float = fmod(p["t"], 1.0)
		draw_arc(xf * (p["p"] as Vector2), 4.0 + k * 16.0, 0, TAU, 24, Color(Palette.UI_BAD, 1.0 - k), 2.0, true)


func _to_tile(local_pos: Vector2) -> Vector2:
	return _xf().affine_inverse() * local_pos


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT:
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
					sim.push_command({"t": "move", "player": local, "ids": ids, "x": int(g.x * 1000), "y": int(g.z * 1000), "amove": amove})
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
