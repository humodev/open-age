extends RefCounted
## --- interfaz como AoE4 --- (proceso/67) Un solo estilo de marco para los paneles del HUD:
## barra de recursos, reloj, minimapa, panel de la selección, grilla de órdenes y ayudas.
## Fondo con degradé de tierra oscura, borde fino dorado, brillo arriba, sombra sobre el mundo y
## rombos en las esquinas de arriba. Los paneles pegados al borde de la pantalla no llevan borde
## ni esquina redonda de ese lado. Todo lo visual sale de data/interfaz.json → hud_estilo.

static var _cfg: Dictionary = {}


static func cfg() -> Dictionary:
	if _cfg.is_empty():
		var path := "res://data/interfaz.json"
		var all: Variant = JSON.parse_string(FileAccess.get_file_as_string(path)) if FileAccess.file_exists(path) else {}
		_cfg = (all as Dictionary).get("hud_estilo", {}) if all is Dictionary else {}
		if _cfg.is_empty():
			_cfg = {"_vacio": true}
	return _cfg


## Valor numérico de hud_estilo (o de una sección: "banda", "seleccion"…).
static func num(clave: String, def: float, seccion: String = "") -> float:
	var d: Dictionary = cfg() if seccion == "" else (cfg().get(seccion, {}) as Dictionary)
	return float(d.get(clave, def))


static func color(clave: String, def: String, alfa_clave: String = "") -> Color:
	var c := Color(str(cfg().get(clave, def)))
	if alfa_clave != "":
		c.a = num(alfa_clave, 1.0)
	return c


## Fondo de los paneles hechos con StyleBox (diálogos, paneles F5–F9, ficha): el mismo tono.
static func fondo_plano() -> Color:
	return color("fondo_arriba", "2a2520", "alfa")


static func borde_plano() -> Color:
	return color("borde", "c9a25a", "borde_alfa")


## Panel del HUD en `r`. `pegado`: lados que tocan el borde de la pantalla ("abajo", "izq", "der",
## "arriba"): sin borde ni esquina redonda de ese lado. `ornamentos`: rombos de las esquinas.
## `sombra` false: sin sombra (la grilla pegada a la selección no la echa sobre ella).
static func panel(ci: CanvasItem, r: Rect2, pegado: Array = [], ornamentos: bool = true, sombra: bool = true) -> void:
	var rad := int(num("radio", 6))
	var sb := StyleBoxFlat.new()
	sb.bg_color = color("fondo_arriba", "2a2520", "alfa")
	sb.set_corner_radius_all(rad)
	if pegado.has("abajo") or pegado.has("izq"):
		sb.corner_radius_bottom_left = 0
	if pegado.has("abajo") or pegado.has("der"):
		sb.corner_radius_bottom_right = 0
	if pegado.has("arriba") or pegado.has("izq"):
		sb.corner_radius_top_left = 0
	if pegado.has("arriba") or pegado.has("der"):
		sb.corner_radius_top_right = 0
	sb.shadow_color = Color(0, 0, 0, num("sombra_alfa", 0.45))
	sb.shadow_size = int(num("sombra_px", 10)) if sombra else 0
	sb.shadow_offset = Vector2(0, -2 if pegado.has("abajo") else 3)
	sb.anti_aliasing = true
	ci.draw_style_box(sb, r)
	# Degradé: más oscuro hacia abajo (desde debajo del radio, para no salirse de la esquina).
	var abajo := color("fondo_abajo", "15120f", "alfa")
	var y0 := r.position.y + rad
	var top := Color(abajo, 0.0)
	var pts := PackedVector2Array([Vector2(r.position.x, y0), Vector2(r.end.x, y0), Vector2(r.end.x, r.end.y - (0 if pegado.has("abajo") else rad)), Vector2(r.position.x, r.end.y - (0 if pegado.has("abajo") else rad))])
	if pts[2].y > pts[1].y:
		ci.draw_polygon(pts, PackedColorArray([top, top, abajo, abajo]))
	# Borde.
	var bd := StyleBoxFlat.new()
	bd.draw_center = false
	bd.bg_color = Color(0, 0, 0, 0)
	bd.border_color = color("borde", "c9a25a", "borde_alfa")
	bd.set_border_width_all(1)
	for lado in pegado:
		match lado:
			"abajo":
				bd.border_width_bottom = 0
			"izq":
				bd.border_width_left = 0
			"der":
				bd.border_width_right = 0
			"arriba":
				bd.border_width_top = 0
	bd.corner_radius_top_left = sb.corner_radius_top_left
	bd.corner_radius_top_right = sb.corner_radius_top_right
	bd.corner_radius_bottom_left = sb.corner_radius_bottom_left
	bd.corner_radius_bottom_right = sb.corner_radius_bottom_right
	bd.anti_aliasing = true
	ci.draw_style_box(bd, r)
	# Brillo de la arista de arriba (luz cenital, como el papel con gouache).
	if not pegado.has("arriba"):
		ci.draw_line(Vector2(r.position.x + rad, r.position.y + 1.5), Vector2(r.end.x - rad, r.position.y + 1.5), color("brillo", "fff2d8", "brillo_alfa"), 1.0)
	if ornamentos and not pegado.has("arriba"):
		var o := num("ornamento_px", 4)
		if not pegado.has("izq"):
			rombo(ci, r.position + Vector2(o + 2, o + 2), o)
		if not pegado.has("der"):
			rombo(ci, Vector2(r.end.x - o - 2, r.position.y + o + 2), o)


## Rombo dorado con contorno oscuro (esquinas de los paneles y separadores).
static func rombo(ci: CanvasItem, c: Vector2, o: float) -> void:
	var pts := PackedVector2Array([c + Vector2(0, -o), c + Vector2(o, 0), c + Vector2(0, o), c + Vector2(-o, 0)])
	var borde := PackedVector2Array([c + Vector2(0, -o - 1), c + Vector2(o + 1, 0), c + Vector2(0, o + 1), c + Vector2(-o - 1, 0)])
	ci.draw_colored_polygon(borde, Color(0, 0, 0, 0.6))
	ci.draw_colored_polygon(pts, color("ornamento", "e3b23c", "ornamento_alfa"))


## Línea divisoria con un rombo al medio (entre la cabecera y el cuerpo, entre secciones).
static func divisor(ci: CanvasItem, a: Vector2, b: Vector2, con_rombo: bool = false) -> void:
	var col := color("borde", "c9a25a", "divisor_alfa")
	ci.draw_line(a, b, col, 1.0)
	if con_rombo:
		rombo(ci, (a + b) * 0.5, num("ornamento_px", 4) * 0.75)


## Cabecera de la selección: el color del dueño que se apaga hacia la derecha (como la franja con
## el nombre de AoE4, pero con el color del jugador en lugar de la bandera).
static func cabecera(ci: CanvasItem, r: Rect2, team: Color) -> void:
	var a := Color(team, num("cabecera_alfa", 0.5))
	var z := Color(team, 0.0)
	var mid := r.position.x + r.size.x * num("cabecera_fin", 0.7)
	ci.draw_polygon(PackedVector2Array([r.position, Vector2(mid, r.position.y), Vector2(mid, r.end.y), Vector2(r.position.x, r.end.y)]), PackedColorArray([a, z, z, a]))
	divisor(ci, Vector2(r.position.x, r.end.y), Vector2(r.end.x, r.end.y))


## Casilla vacía hundida (grilla y cola): más oscura que el panel, con la arista de abajo clara.
static func casilla_vacia(ci: CanvasItem, r: Rect2) -> void:
	var sb := StyleBoxFlat.new()
	sb.bg_color = color("casilla_vacia", "0d0b09", "casilla_vacia_alfa")
	sb.set_corner_radius_all(int(num("radio_casilla", 5)))
	sb.border_color = Color(1, 1, 1, num("casilla_borde_alfa", 0.06))
	sb.border_width_bottom = 1
	ci.draw_style_box(sb, r)
	ci.draw_line(Vector2(r.position.x + 3, r.position.y + 1), Vector2(r.end.x - 3, r.position.y + 1), Color(0, 0, 0, 0.35), 1.0)


## Pastilla (cantidad de aldeanos por recurso, ociosos): con color si hay algo, apagada si no.
static func pastilla(ci: CanvasItem, r: Rect2, col: Color, on: bool) -> void:
	var sb := StyleBoxFlat.new()
	sb.set_corner_radius_all(int(num("radio_pastilla", 4)))
	sb.bg_color = Color(col, num("pastilla_alfa", 0.26)) if on else color("casilla_vacia", "0d0b09", "casilla_vacia_alfa")
	sb.border_color = Color(col, num("pastilla_borde_alfa", 0.7)) if on else Color(1, 1, 1, num("casilla_borde_alfa", 0.06))
	sb.set_border_width_all(1)
	ci.draw_style_box(sb, r)
