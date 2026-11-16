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
## --- aprender --- Opción "Mostrar nombres en la grilla" (src/game/ui/opciones.gd): el glifo
## se achica y el nombre va debajo, en dos renglones (uno si abajo hay franja o edad). Si el
## propio no es el común ("Oga"), arriba va el común ("Casa") y abajo el propio, más tenue.
static var nombres := true


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
	# --- aprender ---
	var nombre := str(c.get("name", "")).trim_prefix("Construir: ") if nombres else ""
	nombre = nombre.left(1).to_upper() + nombre.substr(1)
	# Con nombre común ("Casa" para "Oga"), el común arriba y el propio abajo, más tenue
	# (jugador nuevo, ronda 3); si abajo hay franja o edad, solo el común.
	var comun := str(c.get("common", "")) if nombres else ""
	# Franja de lo que falta en varios renglones (costo real, 4k): el glifo se achica y queda un
	# solo nombre (el común si hay) justo encima; si no entra, solo el glifo, como sin nombres.
	var franja := _alto_franja(falta.size()) + 2.0 if not afford and not locked and falta.size() > 1 else 0.0
	if nombre != "" and franja > 0.0:
		var label := comun if comun != "" else nombre
		var top := r.end.y - franja
		var gs := minf(26.0, top - r.position.y - 3.0 - 13.0)
		if gs >= 10.0:
			Glyphs.draw(ci, c["icon"], Rect2(r.position.x + (r.size.x - gs) / 2.0 + 2, r.position.y + 3, gs, gs), col)
			ci.draw_string(Hud.font_b, Vector2(r.position.x + 2, top - 2.0), label, HORIZONTAL_ALIGNMENT_CENTER, r.size.x - 4, _fit(Hud.font_b, label, 10, r.size.x - 4), Palette.UI_DIM.lightened(0.2))
		else:
			Glyphs.draw(ci, c["icon"], _rect_glifo(r, locked, falta), col)
	elif nombre != "":
		Glyphs.draw(ci, c["icon"], Rect2(r.position.x + (r.size.x - 26) / 2.0 + 2, r.position.y + 3, 26, 26), col)
		var lines := 1 if (locked and edad_pedida(str(c["locked"])) != "") or (not afford and not locked) else 2
		var tcol := Palette.UI_TEXT if col == Palette.UI_TEXT else Palette.UI_DIM.lightened(0.2)
		if comun != "" and lines == 2 and _fit(Hud.font_b, comun, 11, r.size.x - 4) < 9:
			# --- depósitos de comida --- (4m) común largo ("Granero y leñera"): en dos renglones
			# y sin el propio, que queda en la ayuda; achicado hasta lo ilegible no sirve.
			ci.draw_multiline_string(Hud.font_b, Vector2(r.position.x + 2, r.position.y + 39), comun, HORIZONTAL_ALIGNMENT_CENTER, r.size.x - 4, 10, 2, tcol)
		elif comun != "":
			ci.draw_string(Hud.font_b, Vector2(r.position.x + 2, r.position.y + 39), comun, HORIZONTAL_ALIGNMENT_CENTER, r.size.x - 4, _fit(Hud.font_b, comun, 11, r.size.x - 4), tcol)
			if lines == 2:
				ci.draw_string(Hud.font, Vector2(r.position.x + 2, r.position.y + 51), nombre, HORIZONTAL_ALIGNMENT_CENTER, r.size.x - 4, _fit(Hud.font, nombre, 10, r.size.x - 4), Palette.UI_DIM.lightened(0.2))
		else:
			# Achicado hasta que entre entero en sus renglones (jugador nuevo, ronda 4: «Mamposteri»,
			# «Trabajo de»): una palabra larga no se corta por la mitad ni se pierde un renglón.
			var fs := _fit_lineas(Hud.font, nombre, 10, r.size.x - 4, lines)
			ci.draw_multiline_string(Hud.font, Vector2(r.position.x + 2, r.position.y + 39 - (10 - fs) * 0.5), nombre, HORIZONTAL_ALIGNMENT_CENTER, r.size.x - 4, fs, lines, tcol)
	else:
		Glyphs.draw(ci, c["icon"], _rect_glifo(r, locked, falta), col) # --- costo real ---
	# --- fin aprender ---
	_pastilla(ci, Rect2(r.position + Vector2(3, 3), Vector2(17, 17)), letra, Palette.UI_TEXT)
	if locked:
		_candado(ci, Rect2(r.end.x - 19, r.position.y + 4, 15, 16), Palette.UI_TEXT)
		var edad := edad_pedida(str(c["locked"]))
		if edad != "":
			var w := Hud.font_b.get_string_size(edad, HORIZONTAL_ALIGNMENT_LEFT, -1, 13).x + 8
			_pastilla(ci, Rect2(r.end.x - w - 3, r.end.y - 20, w, 17), edad, Palette.UI_TEXT)
	elif not afford:
		# --- costo real --- (proceso/24, 4k) cada recurso que falta con su número, uno por
		# renglón: el hito ya no dice "−300+" sino todo lo que pide (también mit'a o fama).
		var items := faltan_textos(falta)
		var band := Rect2(r.position.x + 2, r.end.y - 2 - _alto_franja(items.size()), r.size.x - 4, _alto_franja(items.size()))
		var bsb := StyleBoxFlat.new()
		bsb.bg_color = FONDO_PASTILLA
		bsb.corner_radius_bottom_left = 5
		bsb.corner_radius_bottom_right = 5
		ci.draw_style_box(bsb, band)
		var solo := items.size() == 1
		var rh := 17.0 if solo else FILA_FALTA
		var gs := 13.0 if solo else 11.0
		for i in items.size():
			var k: String = items[i][0]
			var p := band.position + Vector2(0, rh * i)
			var icon_k := k if Palette.RES.has(k) else str(rp.get("icono", "riqueza"))
			var icol: Color = Palette.RES.get(k, Color(rp.get("color", "#cccccc")))
			Glyphs.draw(ci, icon_k, Rect2(p.x + 3, p.y + (rh - gs) / 2.0, gs, gs), icol)
			ci.draw_string(Hud.font_b, Vector2(p.x + gs + 5, p.y + rh - (4.0 if solo else 2.5)), items[i][1], HORIZONTAL_ALIGNMENT_LEFT, band.size.x - gs - 6, 13 if solo else 12, Palette.UI_BAD.lightened(0.15))
		# --- fin costo real ---


## Tamaño de letra (de `size` para abajo, hasta 7) con el que `txt` entra en `w`.
static func _fit(f: Font, txt: String, size: int, w: float) -> int:
	while size > 7 and f.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x > w:
		size -= 1
	return size


## Tamaño de letra (de `size` para abajo, hasta 7) con el que `txt` entra en `lines` renglones
## de ancho `w` sin partir ninguna palabra.
static func _fit_lineas(f: Font, txt: String, size: int, w: float, lines: int) -> int:
	while size > 7:
		var ok := true
		for word in txt.split(" ", false):
			ok = ok and f.get_string_size(word, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x <= w
		if ok:
			var used := f.get_multiline_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, w, size).y
			ok = used <= f.get_height(size) * lines + 0.5
		if ok:
			break
		size -= 1
	return size


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


## --- costo real --- alto de la franja de lo que falta: un renglón por recurso.
const FILA_FALTA := 13.0

static func _alto_franja(n: int) -> float:
	return 17.0 if n <= 1 else FILA_FALTA * n + 1.0


## Glifo de la casilla: si la franja de lo que falta ocupa más de un renglón, se achica y
## sube para que no lo tape.
static func _rect_glifo(r: Rect2, locked: bool, falta: Dictionary) -> Rect2:
	if locked or falta.size() <= 1:
		return r.grow(-14 if locked else -12)
	var s := clampf(r.size.y - _alto_franja(falta.size()) - 8.0, 14.0, r.size.x - 24.0)
	return Rect2(r.position.x + (r.size.x - s) / 2.0 + 3.0, r.position.y + 3.0, s, s)


## [[recurso, texto]] de lo que falta, en el orden del banco ("−40").
static func faltan_textos(falta: Dictionary) -> Array:
	var out := []
	for k in falta:
		out.append([k, "−%d" % int(falta[k])])
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
