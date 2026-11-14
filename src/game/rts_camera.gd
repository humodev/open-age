class_name RtsCamera
extends Node3D
## Cámara de lente larga y ángulo alto (docs/07, "Cámara").

const PITCH_DEG := 54.0
const YAW_DEG := 45.0 # el rival queda "arriba" en la pantalla
const ZOOM_MIN := 16.0
const ZOOM_MAX := 70.0
const PAN_SPEED := 1.1 # fracción de la distancia por segundo
const EDGE := 6

var cam: Camera3D
var focus := Vector3(24, 0, 24)
var zoom := 32.0
var pitch_deg := PITCH_DEG # las capturas de documentación pueden bajarlo
var _zoom_target := 32.0
var map_size := 128.0
var edge_pan := true
var _drag := false


func _ready() -> void:
	cam = Camera3D.new()
	cam.fov = 30.0
	cam.near = 1.0
	cam.far = 400.0
	add_child(cam)
	_apply()


func forward_xz() -> Vector3:
	var yaw := deg_to_rad(YAW_DEG)
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
	var back := -forward_xz() * cos(pitch) * zoom
	var fh := WorldView.height_at(focus.x, focus.z)
	cam.position = focus + Vector3(0, fh, 0) + back + Vector3(0, sin(pitch) * zoom, 0)
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
		if m.x >= 0 and m.y >= 0 and m.x <= size.x and m.y <= size.y:
			if m.x < EDGE:
				dir.x -= 1
			elif m.x > size.x - EDGE:
				dir.x += 1
			if m.y < EDGE:
				dir.y += 1
			elif m.y > size.y - EDGE:
				dir.y -= 1
	if dir != Vector2.ZERO:
		dir = dir.normalized()
		focus += (right_xz() * dir.x + forward_xz() * dir.y) * zoom * PAN_SPEED * delta * Opciones.velocidad_camara / 100.0 # --- opciones --- velocidad elegida
	zoom = lerpf(zoom, _zoom_target, clampf(delta * 12.0, 0.0, 1.0))
	_apply()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_WHEEL_UP and mb.pressed:
			_zoom_target = clampf(_zoom_target * 0.88, ZOOM_MIN, ZOOM_MAX)
		elif mb.button_index == MOUSE_BUTTON_WHEEL_DOWN and mb.pressed:
			_zoom_target = clampf(_zoom_target / 0.88, ZOOM_MIN, ZOOM_MAX)
		elif mb.button_index == MOUSE_BUTTON_MIDDLE:
			_drag = mb.pressed
	elif event is InputEventMouseMotion and _drag:
		var mm := event as InputEventMouseMotion
		var k := zoom * 0.0022
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
