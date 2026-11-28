class_name RtsCamera
extends Node3D
## Cámara del juego (docs/07, "Cámara"). Los valores están en data/interfaz.json → camara.
##
## Perspectiva como AoE4 (proceso/59): lente abierta y cerca, así lo lejano se ve más chico.
## `zoom` no es la distancia real sino la escala en el centro de la pantalla, medida como la
## distancia que daría la lente de referencia (la de 30° de antes): con el mismo `zoom`, el
## aldeano del centro mide lo mismo, y lo que escala con 40/zoom (barras, carteles, sonido,
## capturas con --cam) no cambia. La distancia real es `zoom * k_dist`.

const YAW_DEG := 45.0 # la cámara mira hacia +x+z (el rival queda "arriba"); data → camara.yaw_deg

static var _cfg := {}

var cam: Camera3D
var focus := Vector3(24, 0, 24)
var zoom := 28.0 # con la gente al 60 % (proceso/24, 4p) el aldeano mide unos 33 px a 1080p
var pitch_deg := 52.0 # las capturas de documentación pueden bajarlo (--cam=x,z,zoom,inclinación)
var _zoom_target := 28.0
var map_size := 128.0
var edge_pan := true
var _drag := false


## data/interfaz.json → camara (se lee una vez).
static func cfg() -> Dictionary:
	if _cfg.is_empty():
		var raw: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/interfaz.json"))
		_cfg = (raw as Dictionary).get("camara", {}) if raw is Dictionary else {}
		if _cfg.is_empty():
			_cfg = {"_vacio": true}
	return _cfg


static func _f(key: String, def: float) -> float:
	return float(cfg().get(key, def))


## Distancia real por unidad de zoom: con la lente abierta, la cámara se acerca para que el
## centro de la pantalla conserve la escala de la lente de referencia.
static func k_dist() -> float:
	return tan(deg_to_rad(_f("fov_ref_deg", 30.0)) / 2.0) / tan(deg_to_rad(_f("fov_deg", 30.0)) / 2.0)


func _ready() -> void:
	cam = Camera3D.new()
	cam.fov = _f("fov_deg", 30.0)
	cam.near = _f("cerca", 1.0)
	cam.far = _f("lejos", 400.0)
	add_child(cam)
	pitch_deg = _f("pitch_deg", 54.0)
	zoom = _f("zoom_inicial", 28.0)
	_zoom_target = zoom
	_apply()


func forward_xz() -> Vector3:
	var yaw := deg_to_rad(_f("yaw_deg", YAW_DEG))
	return Vector3(sin(yaw), 0, cos(yaw))


func right_xz() -> Vector3:
	var f := forward_xz()
	return Vector3(-f.z, 0, f.x)


func look_at_point(p: Vector3) -> void:
	focus = Vector3(p.x, 0, p.z)
	_apply()


func _apply() -> void:
	focus.x = clampf(focus.x, -4.0, map_size + 4.0)
	focus.z = clampf(focus.z, -4.0, map_size + 4.0)
	var pitch := deg_to_rad(pitch_deg)
	var dist := zoom * k_dist()
	var back := -forward_xz() * cos(pitch) * dist
	var fh := WorldView.height_at(focus.x, focus.z)
	cam.position = focus + Vector3(0, fh, 0) + back + Vector3(0, sin(pitch) * dist, 0)
	cam.look_at(focus + Vector3(0, fh, 0), Vector3.UP)


func _process(delta: float) -> void:
	var dir := Vector2.ZERO
	if Input.is_action_pressed("ui_left") or Input.is_physical_key_pressed(KEY_LEFT):
		dir.x -= 1
	if Input.is_action_pressed("ui_right") or Input.is_physical_key_pressed(KEY_RIGHT):
		dir.x += 1
	if Input.is_physical_key_pressed(KEY_UP):
		dir.y += 1
	if Input.is_physical_key_pressed(KEY_DOWN):
		dir.y -= 1
	if edge_pan and DisplayServer.window_is_focused() and not _drag:
		var vp := get_viewport()
		var m := vp.get_mouse_position()
		var size := vp.get_visible_rect().size
		var edge := _f("borde_px", 6)
		if m.x >= 0 and m.y >= 0 and m.x <= size.x and m.y <= size.y:
			if m.x < edge:
				dir.x -= 1
			elif m.x > size.x - edge:
				dir.x += 1
			if m.y < edge:
				dir.y += 1
			elif m.y > size.y - edge:
				dir.y -= 1
	if dir != Vector2.ZERO:
		dir = dir.normalized()
		focus += (right_xz() * dir.x + forward_xz() * dir.y) * zoom * _f("pan", 1.1) * delta * Opciones.velocidad_camara / 100.0 # --- opciones --- velocidad elegida
	zoom = lerpf(zoom, _zoom_target, clampf(delta * 12.0, 0.0, 1.0))
	_apply()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		var zmin := _f("zoom_min", 16.0)
		var zmax := _f("zoom_max", 70.0)
		var step := _f("rueda", 0.88)
		if mb.button_index == MOUSE_BUTTON_WHEEL_UP and mb.pressed:
			_zoom_target = clampf(_zoom_target * step, zmin, zmax)
		elif mb.button_index == MOUSE_BUTTON_WHEEL_DOWN and mb.pressed:
			_zoom_target = clampf(_zoom_target / step, zmin, zmax)
		elif mb.button_index == MOUSE_BUTTON_MIDDLE:
			_drag = mb.pressed
	elif event is InputEventMouseMotion and _drag:
		var mm := event as InputEventMouseMotion
		var k := zoom * _f("arrastre", 0.0022)
		focus -= (right_xz() * mm.relative.x - forward_xz() * mm.relative.y) * k


## Punto del suelo bajo una posición de pantalla.
func ground_at(screen: Vector2) -> Vector3:
	var o := cam.project_ray_origin(screen)
	var d := cam.project_ray_normal(screen)
	if absf(d.y) < 0.0001:
		return focus
	# Intersección con el terreno: punto fijo sobre la altura suavizada.
	var t := -o.y / d.y
	for i in 6:
		var p := o + d * t
		t = (WorldView.height_at(p.x, p.z) - o.y) / d.y
	return o + d * t
