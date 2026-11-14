extends Node
## Cursores contextuales (docs/diseno/interfaz/00-auditoria.md, P7 y mejora 4).
##
## Se dibujan una sola vez al empezar la partida, con las mismas primitivas que los íconos del HUD
## (Glyphs), en un SubViewport de 64 px por cursor; después se achican al tamaño de
## data/interfaz.json → "cursores.px" (por la escala de la interfaz) y se guardan como texturas.
## El controlador decide qué haría un clic (Controller.cursor_action) y llama a usar().

const CELDA := 64
const OSCURO := Color(0.05, 0.05, 0.06, 1.0)
const CLARO := Color("ece8e1")
const ACERO := Color("d9dee6")
const MADERA_MANGO := Color("9a7350")
const TIPOS := ["mover", "atacar", "recolectar_alimento", "recolectar_madera", "recolectar_piedra", "recolectar_riqueza", "construir", "reparar", "refugio", "depositar", "reunion", "no"]
## Punto activo de cada cursor en la celda de 64 px.
const PUNTA := {"mover": Vector2(4, 4), "atacar": Vector2(4, 4), "construir": Vector2(8, 8), "reparar": Vector2(8, 8), "reunion": Vector2(10, 58), "no": Vector2(32, 32)}

var texturas := {} # tipo -> ImageTexture
var actual := "-"
var listo := false
var _imagen: Image


func _ready() -> void:
	if DisplayServer.get_name() == "headless":
		return
	var vp := SubViewport.new()
	vp.size = Vector2i(CELDA * TIPOS.size(), CELDA)
	vp.transparent_bg = true
	vp.disable_3d = true
	vp.render_target_update_mode = SubViewport.UPDATE_ONCE
	var lienzo := Control.new()
	lienzo.size = Vector2(vp.size)
	lienzo.draw.connect(func() -> void:
		for i in TIPOS.size():
			_dibujar(lienzo, TIPOS[i], Vector2(i * CELDA, 0)))
	vp.add_child(lienzo)
	add_child(vp)
	await RenderingServer.frame_post_draw
	_imagen = vp.get_texture().get_image()
	vp.queue_free()
	var px := _px()
	for i in TIPOS.size():
		var img := _imagen.get_region(Rect2i(i * CELDA, 0, CELDA, CELDA))
		img.resize(px, px, Image.INTERPOLATE_LANCZOS)
		texturas[TIPOS[i]] = ImageTexture.create_from_image(img)
	listo = true
	var pedido := actual
	actual = "-"
	usar(pedido)


func _px() -> int:
	var path := "res://data/interfaz.json"
	var all: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(path)) if FileAccess.file_exists(path) else {}
	var base := int((all.get("cursores", {}) as Dictionary).get("px", 32))
	var esc := get_tree().root.content_scale_factor if get_tree() != null else 1.0
	return clampi(int(round(base * esc)), 16, 128)


## Pone el cursor del tipo pedido ("" = flecha del sistema). Solo cambia si es otro.
func usar(tipo: String) -> void:
	if tipo == actual:
		return
	actual = tipo
	if not listo:
		return
	if tipo == "" or not texturas.has(tipo):
		Input.set_custom_mouse_cursor(null)
		Input.set_default_cursor_shape(Input.CURSOR_ARROW)
		return
	var k := float(_px()) / CELDA
	Input.set_custom_mouse_cursor(texturas[tipo], Input.CURSOR_ARROW, PUNTA.get(tipo, Vector2(4, 4)) * k)


## Hoja con todos los cursores en tamaño de dibujo, para la documentación (o null en modo sin ventana).
func hoja() -> Image:
	return _imagen


func _exit_tree() -> void:
	if listo:
		Input.set_custom_mouse_cursor(null)


# ---------------------------------------------------------------- Dibujo

func _dibujar(ci: CanvasItem, tipo: String, o: Vector2) -> void:
	match tipo:
		"mover":
			_flecha(ci, o)
			_insignia(ci, o, Palette.UI_GOOD)
			var c := o + Vector2(46, 46)
			for d: Vector2 in [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT]:
				var side := Vector2(-d.y, d.x)
				_poli(ci, [c + d * 13, c + d * 5 + side * 6, c + d * 5 - side * 6], Palette.UI_GOOD, 0)
		"atacar":
			# Espada en diagonal con la punta arriba a la izquierda.
			_poli(ci, [o + Vector2(3, 3), o + Vector2(14, 7), o + Vector2(43, 36), o + Vector2(36, 43), o + Vector2(7, 14)], ACERO, 3)
			_linea(ci, o + Vector2(8, 8), o + Vector2(38, 38), ACERO.darkened(0.25), 2)
			_linea(ci, o + Vector2(28, 50), o + Vector2(50, 28), Palette.UI_BAD, 7)
			_linea(ci, o + Vector2(42, 42), o + Vector2(55, 55), MADERA_MANGO, 7)
			_circulo(ci, o + Vector2(57, 57), 5, Palette.UI_BAD)
		"construir", "reparar":
			# Martillo: cabeza arriba a la izquierda, mango en diagonal.
			_linea(ci, o + Vector2(22, 22), o + Vector2(56, 56), MADERA_MANGO, 8)
			_poli(ci, [o + Vector2(2, 16), o + Vector2(16, 2), o + Vector2(34, 20), o + Vector2(20, 34)], ACERO, 3)
			_poli(ci, [o + Vector2(2, 16), o + Vector2(9, 9), o + Vector2(27, 27), o + Vector2(20, 34)], ACERO.darkened(0.2), 0)
			if tipo == "reparar":
				_insignia(ci, o, Palette.UI_GOOD)
				ci.draw_rect(Rect2(o + Vector2(43, 37), Vector2(6, 18)), Palette.UI_GOOD)
				ci.draw_rect(Rect2(o + Vector2(37, 43), Vector2(18, 6)), Palette.UI_GOOD)
		"refugio", "depositar":
			_flecha(ci, o)
			_insignia(ci, o, Palette.UI_ACCENT)
			Glyphs.draw(ci, "refugio" if tipo == "refugio" else "deposito", Rect2(o + Vector2(33, 33), Vector2(26, 26)), CLARO)
		"reunion":
			_linea(ci, o + Vector2(10, 4), o + Vector2(10, 58), MADERA_MANGO, 4)
			_poli(ci, [o + Vector2(12, 5), o + Vector2(50, 15), o + Vector2(12, 27)], Palette.UI_ACCENT, 3)
			_circulo(ci, o + Vector2(10, 58), 4, CLARO)
		"no":
			ci.draw_arc(o + Vector2(32, 32), 22, 0, TAU, 40, OSCURO, 13, true)
			ci.draw_arc(o + Vector2(32, 32), 22, 0, TAU, 40, Palette.UI_BAD, 7, true)
			_linea(ci, o + Vector2(17, 17), o + Vector2(47, 47), Palette.UI_BAD, 7)
		_:
			if tipo.begins_with("recolectar_"):
				var k := tipo.trim_prefix("recolectar_")
				_flecha(ci, o)
				_insignia(ci, o, Palette.RES.get(k, CLARO))
				Glyphs.draw(ci, k, Rect2(o + Vector2(32, 32), Vector2(28, 28)), Palette.RES.get(k, CLARO))


## Flecha base, con la punta en (4, 4).
func _flecha(ci: CanvasItem, o: Vector2) -> void:
	_poli(ci, [o + Vector2(4, 4), o + Vector2(4, 44), o + Vector2(14, 35), o + Vector2(21, 51), o + Vector2(29, 47), o + Vector2(22, 32), o + Vector2(35, 32)], CLARO, 3)


## Disco oscuro con borde de color, abajo a la derecha, donde va el ícono de la acción.
func _insignia(ci: CanvasItem, o: Vector2, col: Color) -> void:
	ci.draw_circle(o + Vector2(46, 46), 17, OSCURO)
	ci.draw_arc(o + Vector2(46, 46), 15, 0, TAU, 32, col, 2.5, true)


func _poli(ci: CanvasItem, pts: Array, col: Color, borde: float) -> void:
	var p := PackedVector2Array(pts)
	if borde > 0:
		for q in Geometry2D.offset_polygon(p, borde, Geometry2D.JOIN_ROUND):
			ci.draw_colored_polygon(q, OSCURO)
	ci.draw_colored_polygon(p, col)


func _linea(ci: CanvasItem, a: Vector2, b: Vector2, col: Color, w: float) -> void:
	ci.draw_line(a, b, OSCURO, w + 5)
	ci.draw_circle(a, (w + 5) / 2.0, OSCURO)
	ci.draw_circle(b, (w + 5) / 2.0, OSCURO)
	ci.draw_line(a, b, col, w)


func _circulo(ci: CanvasItem, c: Vector2, r: float, col: Color) -> void:
	ci.draw_circle(c, r + 2.5, OSCURO)
	ci.draw_circle(c, r, col)
