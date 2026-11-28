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
static func panel(ci: CanvasItem, r: Rect2, pegado: Array = [], ornamentos: bool = true, sombra: bool = true, fina: bool = false) -> void:
	if pintado(): # --- interfaz pintada --- (proceso/68) papel con gouache y faja tejida del pueblo
		panel_pintado(ci.get_canvas_item(), r, pegado, ornamentos, sombra, fina)
		return
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
	if pintado() and _tex(str(pc().get("divisor", ""))) != null: # --- interfaz pintada --- un cordón
		cordon(ci.get_canvas_item(), a, b)
		if con_rombo:
			rombo(ci, (a + b) * 0.5, num("ornamento_px", 4) * 0.75)
		return
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


# --- interfaz pintada --- (proceso/68-interfaz-pintada) ---------------------------------------
## Paneles de papel pintado al gouache (superficie sin costuras) con una faja tejida del pueblo del
## JUGADOR en el borde, pieza de esquina, cordón divisor, medallón del retrato, botones y marca de
## agua. Texturas de tools/interfaz_pintada.py, al doble de resolución: se dibujan a escala 0,5
## (nítidas a 4K). Todo sale de data/interfaz.json → hud_estilo.pintado; sin él (o con activo
## false, o si falta la superficie) queda el marco dibujado con código de arriba.

static var pueblo := "" ## el del jugador (Hud.setup); vacío = la faja común (menús)
static var _texs: Dictionary = {}
static var _sbs: Dictionary = {}


static func pc() -> Dictionary:
	return cfg().get("pintado", {}) as Dictionary


static func pintado() -> bool:
	return bool(pc().get("activo", false)) and _tex(str(pc().get("superficie", ""))) != null


static func _tex(ruta: String) -> Texture2D:
	if ruta == "":
		return null
	if not _texs.has(ruta):
		_texs[ruta] = load(ruta) as Texture2D if ResourceLoader.exists(ruta) else null
	return _texs[ruta]


## El pueblo que se usa: el del jugador si tiene faja; si no, la común.
static func _civ() -> String:
	var pueblos: Dictionary = pc().get("pueblos", {})
	return pueblo if pueblos.has(pueblo) else str(pc().get("comun", "neutro"))


## Pieza del pueblo: marco, esquina o marca.
static func pieza(nombre: String) -> Texture2D:
	var carpeta := str(pc().get("carpeta", "res://assets/ui/hud"))
	return _tex("%s/%s/%s%s" % [carpeta, _civ(), nombre, ".webp" if nombre == "marca" else ".png"])


static func set_pueblo(civ: String) -> void:
	pueblo = civ
	_sbs.clear()


## Papel pintado en `r`, en mosaico a escala 0,5 (la textura es 2x), sin depender del repeat.
static func superficie(rid: RID, r: Rect2, mod: Color = Color.WHITE) -> void:
	var t := _tex(str(pc().get("superficie", "")))
	if t == null:
		return
	var ts := t.get_size() * 0.5
	var y := 0.0
	while y < r.size.y:
		var h := minf(ts.y, r.size.y - y)
		var x := 0.0
		while x < r.size.x:
			var w := minf(ts.x, r.size.x - x)
			RenderingServer.canvas_item_add_texture_rect_region(rid, Rect2(r.position + Vector2(x, y), Vector2(w, h)), t.get_rid(), Rect2(0, 0, w * 2.0, h * 2.0), mod)
			x += ts.x
		y += ts.y
	# Más oscuro hacia abajo (luz de arriba), como el degradé de proceso/67: solo oscurece.
	var abajo := Color(0, 0, 0, num("degrade_alfa", 0.28, "pintado") * mod.a)
	RenderingServer.canvas_item_add_polygon(rid, PackedVector2Array([r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y)]), PackedColorArray([Color(0, 0, 0, 0), Color(0, 0, 0, 0), abajo, abajo]))


## Ancho de la faja en la textura: filas × celda_px (la textura es 2c + 3 tiras).
static func _margen_marco() -> float:
	var f: Dictionary = (pc().get("pueblos", {}) as Dictionary).get(_civ(), {}).get("faja", {})
	return float(f.get("filas", 11)) * num("celda_px", 3, "pintado")


## La faja del pueblo como 9 cortes, escalada para que mida `px` en pantalla. Los lados pegados al
## borde de la pantalla van sin faja (margen 0 de ese lado).
static func faja(rid: RID, r: Rect2, pegado: Array = [], px: float = -1.0, mod: Color = Color.WHITE) -> void:
	var t := pieza("marco")
	if t == null:
		return
	var m := _margen_marco()
	if px <= 0.0:
		px = num("faja_px", 11, "pintado")
	var k := px / m
	var clave := "%s|%s" % [_civ(), ",".join(pegado)]
	var sb: StyleBoxTexture = _sbs.get(clave)
	if sb == null:
		sb = StyleBoxTexture.new()
		sb.texture = t
		# Lado pegado (al borde de la pantalla o al panel vecino): sin faja. Se recorta esa franja de
		# la textura (region_rect) y su margen queda en 0: los lados de al lado llegan hasta el final.
		var ts := t.get_size()
		var reg := Rect2(Vector2.ZERO, ts)
		if pegado.has("izq"):
			reg = reg.grow_side(SIDE_LEFT, -m)
		if pegado.has("der"):
			reg = reg.grow_side(SIDE_RIGHT, -m)
		if pegado.has("arriba"):
			reg = reg.grow_side(SIDE_TOP, -m)
		if pegado.has("abajo"):
			reg = reg.grow_side(SIDE_BOTTOM, -m)
		sb.region_rect = reg
		sb.texture_margin_left = 0.0 if pegado.has("izq") else m
		sb.texture_margin_right = 0.0 if pegado.has("der") else m
		sb.texture_margin_top = 0.0 if pegado.has("arriba") else m
		sb.texture_margin_bottom = 0.0 if pegado.has("abajo") else m
		sb.axis_stretch_horizontal = StyleBoxTexture.AXIS_STRETCH_MODE_TILE_FIT
		sb.axis_stretch_vertical = StyleBoxTexture.AXIS_STRETCH_MODE_TILE_FIT
		sb.draw_center = false
		_sbs[clave] = sb
	sb.modulate_color = mod
	RenderingServer.canvas_item_add_set_transform(rid, Transform2D(0.0, Vector2(k, k), 0.0, r.position))
	sb.draw(rid, Rect2(Vector2.ZERO, r.size / k))
	RenderingServer.canvas_item_add_set_transform(rid, Transform2D.IDENTITY)


## Panel pintado: sombra, papel, faja y piezas de esquina. Sobre un RID para que lo usen tanto
## los paneles dibujados a mano como el StyleBox de los diálogos (estilo_pintado.gd).
static func panel_pintado(rid: RID, r: Rect2, pegado: Array = [], ornamentos: bool = true, sombra: bool = true, fina: bool = false, mod: Color = Color.WHITE) -> void:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(color("fondo_abajo", "13110e"), mod.a)
	sb.shadow_color = Color(0, 0, 0, num("sombra_alfa", 0.45) * mod.a)
	sb.shadow_size = int(num("sombra_px", 10)) if sombra else 0
	sb.shadow_offset = Vector2(0, -2 if pegado.has("abajo") else 3)
	sb.draw(rid, r)
	superficie(rid, r, Color(1, 1, 1, num("superficie_alfa", 0.97, "pintado") * mod.a))
	var px := num("faja_fina_px" if fina else "faja_px", 9 if fina else 18, "pintado")
	# La faja monta sobre el borde: una parte cae afuera del panel y no tapa el contenido.
	var rf := r
	var fuera := px * num("faja_fuera", 0.5, "pintado")
	for par in [["izq", SIDE_LEFT], ["der", SIDE_RIGHT], ["arriba", SIDE_TOP], ["abajo", SIDE_BOTTOM]]:
		if not pegado.has(par[0]):
			rf = rf.grow_side(par[1], fuera)
	faja(rid, rf, pegado, px, Color(1, 1, 1, mod.a))
	if ornamentos and not fina and not pegado.has("arriba"):
		var e := pieza("esquina")
		if e != null:
			var s := num("esquina_px", 30, "pintado")
			for lado in ["izq", "der"]:
				if pegado.has(lado):
					continue
				var cx := rf.position.x + px * 0.5 if lado == "izq" else rf.end.x - px * 0.5
				RenderingServer.canvas_item_add_texture_rect(rid, Rect2(Vector2(cx, rf.position.y + px * 0.5) - Vector2(s, s) * 0.5, Vector2(s, s)), e.get_rid(), false, Color(1, 1, 1, mod.a))


## Cuánto entra la faja en el panel (para que la cabecera y lo de adentro empiecen después).
static func borde_interior(fina: bool = false) -> float:
	if not pintado():
		return 1.0
	var px := num("faja_fina_px" if fina else "faja_px", 9 if fina else 18, "pintado")
	return px * (1.0 - num("faja_fuera", 0.5, "pintado"))


## Cordón divisor (horizontal o vertical) de a a b.
static func cordon(rid: RID, a: Vector2, b: Vector2) -> void:
	var t := _tex(str(pc().get("divisor", "")))
	if t == null:
		return
	var largo := a.distance_to(b)
	var alto := t.get_height() * 0.5
	RenderingServer.canvas_item_add_set_transform(rid, Transform2D((b - a).angle(), a))
	var tw := t.get_width() * 0.5
	var x := 0.0
	while x < largo:
		var w := minf(tw, largo - x)
		RenderingServer.canvas_item_add_texture_rect_region(rid, Rect2(x, -alto * 0.5, w, alto), t.get_rid(), Rect2(0, 0, w * 2.0, t.get_height()))
		x += tw
	RenderingServer.canvas_item_add_set_transform(rid, Transform2D.IDENTITY)


## Medallón del retrato: marco de latón pintado alrededor de `r` (el retrato). false sin pintado.
static func medallon(ci: CanvasItem, r: Rect2) -> bool:
	if not pintado():
		return false
	var t := _tex(str(pc().get("medallon", "")))
	if t == null:
		return false
	var m := num("medallon_margen", 22, "pintado")
	var sb: StyleBoxTexture = _sbs.get("medallon")
	if sb == null:
		sb = StyleBoxTexture.new()
		sb.texture = t
		sb.set_texture_margin_all(m)
		sb.draw_center = false
		_sbs["medallon"] = sb
	var rid := ci.get_canvas_item()
	var rr := r.grow(m * 0.5 - 3.0) # el aro tapa 3 px del borde de la pintura
	RenderingServer.canvas_item_add_set_transform(rid, Transform2D(0.0, Vector2(0.5, 0.5), 0.0, rr.position))
	sb.draw(rid, Rect2(Vector2.ZERO, rr.size * 2.0))
	RenderingServer.canvas_item_add_set_transform(rid, Transform2D.IDENTITY)
	return true


## Marca de agua del pueblo (tinta hundida en el papel), abajo a la derecha de `r`.
static func marca(ci: CanvasItem, r: Rect2) -> void:
	if not pintado() or not ((pc().get("pueblos", {}) as Dictionary).get(_civ(), {}) as Dictionary).has("marca"):
		return
	var t := pieza("marca")
	if t == null:
		return
	var s := num("marca_px", 150, "pintado")
	var pos := Vector2(r.end.x - s - num("faja_px", 11, "pintado") - 4.0, r.end.y - s)
	ci.draw_texture_rect(t, Rect2(pos, Vector2(s, s)), false, Color(1, 1, 1, num("marca_alfa", 0.85, "pintado")))


## Botón pintado (normal, hover, pressed, disabled) como StyleBoxTexture, con los márgenes de
## contenido del que reemplaza. null sin pintado.
static func boton(estado: String, contenido: StyleBox = null) -> StyleBox:
	if not pintado():
		return null
	var b: Dictionary = pc().get("boton", {})
	var t := _tex(str(b.get(estado, "")))
	if t == null:
		return null
	var sb := StyleBoxTexture.new()
	sb.texture = t
	sb.set_texture_margin_all(float(b.get("margen", 12)))
	if contenido != null:
		for lado in [SIDE_LEFT, SIDE_TOP, SIDE_RIGHT, SIDE_BOTTOM]:
			sb.set_content_margin(lado, contenido.get_content_margin(lado))
	return sb


## Aviso con el mismo marco: papel, faja fina y la franja del tipo a la izquierda. false sin pintado.
static func aviso(ci: CanvasItem, r: Rect2, col: Color, alfa: float) -> bool:
	if not pintado():
		return false
	panel_pintado(ci.get_canvas_item(), r, [], false, true, true, Color(1, 1, 1, alfa))
	var px := num("faja_fina_px", 6, "pintado")
	ci.draw_rect(Rect2(r.position.x + px, r.position.y + px, 4, r.size.y - px * 2), Color(col, 0.9 * alfa))
	return true
# --- fin interfaz pintada ---
