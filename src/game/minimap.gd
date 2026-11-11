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


func setup(s: Sim, c: RtsCamera, controller: Controller, local_player: int) -> void:
	sim = s
	cam = c
	ctrl = controller
	local = local_player
	mouse_filter = Control.MOUSE_FILTER_STOP
	var n := sim.map.n
	_img = Image.create(n, n, false, Image.FORMAT_RGBA8)
	_tex = ImageTexture.create_from_image(_img)
	_rebuild()


func _rebuild() -> void:
	var n := sim.map.n
	for y in n:
		for x in n:
			var k := float((x * 7 + y * 13) % 5) / 40.0
			_img.set_pixel(x, y, Palette.GROUND_A.lerp(Palette.GROUND_B, 0.35 + k))
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
	for p in _pings:
		p["t"] += delta
	_pings = _pings.filter(func(p: Dictionary) -> bool: return p["t"] < 3.0)
	queue_redraw()


func _draw() -> void:
	draw_style_box(Hud.panel_box(10), Rect2(Vector2.ZERO, size))
	var xf := _xf()
	var n := float(sim.map.n)
	draw_set_transform_matrix(xf)
	draw_texture_rect(_tex, Rect2(0, 0, n, n), false)
	for e in sim.actives:
		var col := Palette.team(e.owner)
		if e.is_building():
			draw_rect(Rect2(e.tx, e.ty, e.w, e.h), col if e.built else Color(col, 0.55))
	for e in sim.actives:
		if e.is_unit():
			draw_rect(Rect2(e.x / 1000.0 - 0.9, e.y / 1000.0 - 0.9, 1.8, 1.8), Palette.team(e.owner).lightened(0.15))
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
			var ids := []
			for e in ctrl.selected_entities():
				if e.owner == local and e.is_unit():
					ids.append(e.id)
			if not ids.is_empty():
				sim.push_command({"t": "move", "player": local, "ids": ids, "x": int(t.x * 1000), "y": int(t.y * 1000)})
		accept_event()
	elif event is InputEventMouseMotion and _drag:
		var t := _to_tile((event as InputEventMouseMotion).position)
		cam.look_at_point(Vector3(t.x, 0, t.y))
		accept_event()
