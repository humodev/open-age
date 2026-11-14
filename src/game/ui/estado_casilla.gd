class_name EstadoCasilla
extends RefCounted
## Estados de una casilla de la grilla de comandos, legibles sin depender del color
## (docs/diseno/interfaz/00-auditoria.md, P3, P18 y sección 5):
##   - disponible: glifo claro;
##   - no alcanza: borde rojo, glifo atenuado y una franja abajo con el recurso que falta
##     y cuánto ("−40" con el glifo de la madera);
##   - bloqueado: casilla oscurecida, glifo atenuado y candado, con la edad que pide.
## La letra del atajo va en una pastilla oscura propia, arriba a la izquierda.
## Todos los textos y glifos quedan a 4,5:1 o más contra su fondo (tests/test_paleta.gd).

const FONDO_BLOQUEO := Color(0, 0, 0, 0.32)
const FONDO_PASTILLA := Color(0, 0, 0, 0.62)


## Dibuja una casilla con comando. `res` es el banco del jugador; `rp` el recurso propio.
static func dibujar(ci: CanvasItem, r: Rect2, c: Dictionary, res: Dictionary, hover: bool, active: bool, letra: String, rp: Dictionary) -> void:
	var locked: bool = c["locked"] != ""
	var falta := faltante(c.get("cost", {}), res)
	var afford := falta.is_empty()
	var sb := StyleBoxFlat.new()
	sb.set_corner_radius_all(6)
	sb.bg_color = Color(1, 1, 1, 0.13 if hover else 0.075)
	if active:
		sb.bg_color = Color(Palette.UI_ACCENT, 0.3)
	sb.border_color = Color(1, 1, 1, 0.1)
	sb.set_border_width_all(1)
	if not afford and not locked:
		sb.border_color = Palette.UI_BAD
		sb.set_border_width_all(2)
	ci.draw_style_box(sb, r)
	if locked:
		var dark := StyleBoxFlat.new()
		dark.set_corner_radius_all(6)
		dark.bg_color = FONDO_BLOQUEO
		ci.draw_style_box(dark, r)
	var col := Palette.UI_TEXT
	if locked or not afford:
		col = Palette.UI_DIM
	Glyphs.draw(ci, c["icon"], r.grow(-14 if locked else -12), col)
	_pastilla(ci, Rect2(r.position + Vector2(3, 3), Vector2(17, 17)), letra, Palette.UI_TEXT)
	if locked:
		_candado(ci, Rect2(r.end.x - 19, r.position.y + 4, 15, 16), Palette.UI_TEXT)
		var edad := edad_pedida(str(c["locked"]))
		if edad != "":
			var w := Hud.font_b.get_string_size(edad, HORIZONTAL_ALIGNMENT_LEFT, -1, 13).x + 8
			_pastilla(ci, Rect2(r.end.x - w - 3, r.end.y - 20, w, 17), edad, Palette.UI_TEXT)
	elif not afford:
		var k: String = falta.keys()[0]
		var band := Rect2(r.position.x + 2, r.end.y - 19, r.size.x - 4, 17)
		var bsb := StyleBoxFlat.new()
		bsb.bg_color = FONDO_PASTILLA
		bsb.corner_radius_bottom_left = 5
		bsb.corner_radius_bottom_right = 5
		ci.draw_style_box(bsb, band)
		var icon_k := k if Palette.RES.has(k) else str(rp.get("icono", "riqueza"))
		var icol: Color = Palette.RES.get(k, Color(rp.get("color", "#cccccc")))
		Glyphs.draw(ci, icon_k, Rect2(band.position.x + 3, band.position.y + 2, 13, 13), icol)
		var txt := "−%d%s" % [falta[k], "+" if falta.size() > 1 else ""]
		ci.draw_string(Hud.font_b, Vector2(band.position.x + 18, band.end.y - 4), txt, HORIZONTAL_ALIGNMENT_LEFT, band.size.x - 20, 13, Palette.UI_BAD.lightened(0.15))


## Recursos que faltan para pagar `cost`, en el orden del banco: {recurso: cuánto falta}.
static func faltante(cost: Dictionary, res: Dictionary) -> Dictionary:
	var out := {}
	var keys: Array = Sim.RES_KINDS.duplicate()
	for k in cost:
		if not keys.has(k):
			keys.append(k)
	for k in keys:
		if cost.has(k) and int(res.get(k, 0)) < int(cost[k]):
			out[k] = int(cost[k]) - int(res.get(k, 0))
	return out


## "Requiere edad III" → "III" (vacío si el bloqueo no es por edad).
static func edad_pedida(motivo: String) -> String:
	var re := RegEx.create_from_string("(?i)edad ([IVX]+)")
	var m := re.search(motivo)
	return m.get_string(1) if m != null and not motivo.to_lower().contains("máxima") else ""


static func _pastilla(ci: CanvasItem, r: Rect2, txt: String, col: Color) -> void:
	var sb := StyleBoxFlat.new()
	sb.bg_color = FONDO_PASTILLA
	sb.set_corner_radius_all(4)
	ci.draw_style_box(sb, r)
	ci.draw_string(Hud.font_b, Vector2(r.position.x, r.end.y - 4), txt, HORIZONTAL_ALIGNMENT_CENTER, r.size.x, 13, col)


static func _candado(ci: CanvasItem, r: Rect2, col: Color) -> void:
	var sb := StyleBoxFlat.new()
	sb.bg_color = FONDO_PASTILLA
	sb.set_corner_radius_all(4)
	ci.draw_style_box(sb, r.grow(1))
	var body := Rect2(r.position.x + 2.5, r.position.y + r.size.y * 0.45, r.size.x - 5, r.size.y * 0.45)
	ci.draw_rect(body, col)
	var c := Vector2(r.get_center().x, body.position.y)
	ci.draw_arc(c, r.size.x * 0.24, PI, TAU, 10, col, 1.8, true)
	ci.draw_line(c + Vector2(-r.size.x * 0.24, 0), c + Vector2(-r.size.x * 0.24, 1), col, 1.8)
	ci.draw_line(c + Vector2(r.size.x * 0.24, 0), c + Vector2(r.size.x * 0.24, 1), col, 1.8)
	ci.draw_circle(Vector2(c.x, body.position.y + body.size.y * 0.45), 1.4, FONDO_PASTILLA)
