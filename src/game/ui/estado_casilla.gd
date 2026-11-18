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

const FONDO_BLOQUEO := Color(0, 0, 0, 0.5) # --- iconos --- más oscuro: se lee apagado (proceso/28)
const FONDO_PASTILLA := Color(0, 0, 0, 0.62)
## --- aprender --- Opción "Mostrar nombres en la grilla" (src/game/ui/opciones.gd): el glifo
## se achica y el nombre va debajo, en dos renglones (uno si abajo hay franja o edad). Si el
## propio no es el común ("Oga"), arriba va el común ("Casa") y abajo el propio, más tenue.
static var nombres := true


## Dibuja una casilla con comando. `res` es el banco del jugador; `rp` el recurso propio.
## --- iconos --- (proceso/28) Cada estado se ve sin depender del color ni del candado
## (estado()): falta recurso → borde y tinte ámbar y la franja de lo que falta; bloqueado o tope →
## oscurecida y rayada en diagonal, con la edad que pide en su color o «Máx. n»; en curso → borde
## y tilde; población llena → borde y pastilla de población; en la cola → borde y cuántos.
static func dibujar(ci: CanvasItem, r: Rect2, c: Dictionary, res: Dictionary, hover: bool, active: bool, letra: String, rp: Dictionary) -> void:
	var est := estado(c, res)
	var locked: bool = est == "bloqueado" or est == "tope"
	var falta := faltante(c.get("cost", {}), res) if est == "falta" else {}
	var afford := falta.is_empty()
	var sb := StyleBoxFlat.new()
	sb.set_corner_radius_all(6)
	sb.bg_color = Color(1, 1, 1, 0.13 if hover else 0.075)
	if active:
		sb.bg_color = Color(Palette.UI_ACCENT, 0.3)
	sb.border_color = Color(1, 1, 1, 0.1)
	sb.set_border_width_all(1)
	var borde := _color_borde(est, c)
	if borde.a > 0.0:
		sb.border_color = borde
		sb.set_border_width_all(2)
		if est == "falta":
			sb.bg_color = sb.bg_color.blend(Color(borde, 0.1))
	ci.draw_style_box(sb, r)
	if locked:
		var dark := StyleBoxFlat.new()
		dark.set_corner_radius_all(6)
		dark.bg_color = FONDO_BLOQUEO
		ci.draw_style_box(dark, r)
		_rayado(ci, r.grow(-2))
	_franja_edad(ci, r, c)
	var col := Palette.UI_TEXT
	if locked:
		col = GLIFO_BLOQUEO
	elif not afford:
		# --- ronda 7 --- (jugador nuevo: «en ámbar, el texto queda muy apagado») el glifo en ámbar
		# claro y el nombre en el color de siempre: lo que falta ya lo dicen el borde y la franja.
		col = Palette.UI_TEXT.lerp(Iconos.color_estado("falta", Palette.UI_ACCENT), 0.6)
	var tcol := Palette.UI_DIM.lightened(0.2) if locked else Palette.UI_TEXT
	# --- fin iconos ---
	# --- aprender ---
	var nombre := str(c.get("name", "")).trim_prefix("Construir: ") if nombres else ""
	nombre = nombre.left(1).to_upper() + nombre.substr(1)
	# Con nombre común ("Casa" para "Oga"), el común arriba y el propio abajo, más tenue
	# (jugador nuevo, ronda 3); si abajo hay franja o edad, solo el común.
	var comun := str(c.get("common", "")) if nombres else ""
	# Un común largo que no entra ni achicado («Hito · edad I…» parecía de la edad I; jugador
	# nuevo, ronda 5) usa su forma corta («Edad II»).
	var dos: Array = [] # --- ronda 6 --- «Hito» arriba y «Edad II» abajo (jugador nuevo, ronda 6)
	if comun != "" and c.has("common_corto") and _fit(Hud.font_b, comun, 11, r.size.x - 8) < 11:
		comun = str(c["common_corto"])
		dos = c.get("common_dos", [])
	# Franja de lo que falta en varios renglones (costo real, 4k): el glifo se achica y queda un
	# solo nombre (el común si hay) justo encima; si no entra, solo el glifo, como sin nombres.
	var franja := _alto_franja(falta.size()) + 2.0 if not afford and not locked and falta.size() > 1 else 0.0
	if nombre != "" and franja > 0.0:
		var label := comun if comun != "" else nombre
		if dos.size() == 2: # --- ronda 6 --- un solo renglón: «Hito edad II»
			label = "%s %s" % [dos[0], str(dos[1]).to_lower()]
		var top := r.end.y - franja
		var gs := minf(26.0, top - r.position.y - 3.0 - 13.0)
		if gs >= 10.0:
			Glyphs.draw(ci, c["icon"], Rect2(r.position.x + (r.size.x - gs) / 2.0 + 2, r.position.y + 3, gs, gs), col)
			var ajf := _ajuste(Hud.font_b, label, 10, r.size.x - 4, 1) # --- ronda 7 ---
			ci.draw_string(Hud.font_b, Vector2(r.position.x + 2, top - 2.0), ajf[0], HORIZONTAL_ALIGNMENT_CENTER, r.size.x - 4, ajf[1], tcol)
		else:
			Glyphs.draw(ci, c["icon"], _rect_glifo(r, locked, falta), col)
	elif nombre != "" and dos.size() == 2:
		# --- ronda 6 --- glifo más chico y dos renglones: «Hito» (tenue) y «Edad II»
		Glyphs.draw(ci, c["icon"], Rect2(r.position.x + (r.size.x - 18) / 2.0 + 2, r.position.y + 3, 18, 18), col)
		var tcol2 := tcol
		ci.draw_string(Hud.font_b, Vector2(r.position.x + 2, r.position.y + 30), str(dos[0]), HORIZONTAL_ALIGNMENT_CENTER, r.size.x - 4, _fit(Hud.font_b, str(dos[0]), 10, r.size.x - 4), Palette.UI_DIM.lightened(0.2))
		ci.draw_string(Hud.font_b, Vector2(r.position.x + 2, r.position.y + 40.5), str(dos[1]), HORIZONTAL_ALIGNMENT_CENTER, r.size.x - 4, _fit(Hud.font_b, str(dos[1]), 11, r.size.x - 4), tcol2)
	elif nombre != "":
		var lines := 1 if (locked and (edad_pedida(str(c["locked"])) != "" or est == "tope")) or (not afford and not locked) else 2
		# Compacto (jugador nuevo, ronda 4): sin común, un renglón no alcanza («Trabajo de la
		# riqueza» con la edad abajo) → glifo chico y dos renglones arriba de la pastilla.
		# --- ronda 7 --- también el común («Taller de asedio» con la edad abajo se cortaba por la
		# izquierda: «aller de asedio»): si no entra en un renglón, glifo chico y dos renglones.
		var etq := comun if comun != "" else nombre
		var fetq: Font = Hud.font_b if comun != "" else Hud.font
		var compacto := lines == 1 and _fit_lineas(fetq, etq, 10, r.size.x - 4, 1) < 9
		if compacto:
			Glyphs.draw(ci, c["icon"], Rect2(r.position.x + (r.size.x - 18) / 2.0 + 2, r.position.y + 3, 18, 18), col)
			var ajc := _ajuste(fetq, etq, 9, r.size.x - 4, 2)
			ci.draw_multiline_string(fetq, Vector2(r.position.x + 2, r.position.y + 31), ajc[0], HORIZONTAL_ALIGNMENT_CENTER, r.size.x - 4, ajc[1], 2, tcol)
		else:
			Glyphs.draw(ci, c["icon"], Rect2(r.position.x + (r.size.x - 26) / 2.0 + 2, r.position.y + 3, 26, 26), col)
		if compacto:
			pass
		elif comun != "" and lines == 2 and _fit(Hud.font_b, comun, 11, r.size.x - 4) < 9:
			# --- depósitos de comida --- (4m) común largo ("Granero y leñera"): en dos renglones
			# y sin el propio, que queda en la ayuda; achicado hasta lo ilegible no sirve.
			var ajb := _ajuste(Hud.font_b, comun, 10, r.size.x - 4, 2) # «Depósito de piedra y riqueza»
			ci.draw_multiline_string(Hud.font_b, Vector2(r.position.x + 2, r.position.y + 39 - (10 - ajb[1]) * 0.5), ajb[0], HORIZONTAL_ALIGNMENT_CENTER, r.size.x - 4, ajb[1], 2, tcol)
		elif comun != "":
			var aj1 := _ajuste(Hud.font_b, comun, 11, r.size.x - 4, 1)
			ci.draw_string(Hud.font_b, Vector2(r.position.x + 2, r.position.y + 39), aj1[0], HORIZONTAL_ALIGNMENT_CENTER, r.size.x - 4, aj1[1], tcol)
			if lines == 2:
				var aj2 := _ajuste(Hud.font, nombre, 10, r.size.x - 4, 1)
				ci.draw_string(Hud.font, Vector2(r.position.x + 2, r.position.y + 51), aj2[0], HORIZONTAL_ALIGNMENT_CENTER, r.size.x - 4, aj2[1], Palette.UI_DIM.lightened(0.2))
		else:
			# Achicado hasta que entre entero en sus renglones (jugador nuevo, ronda 4: «Mamposteri»,
			# «Trabajo de»): una palabra larga no se corta por la mitad ni se pierde un renglón.
			var ajn := _ajuste(Hud.font, nombre, 10, r.size.x - 4, lines)
			ci.draw_multiline_string(Hud.font, Vector2(r.position.x + 2, r.position.y + 39 - (10 - ajn[1]) * 0.5), ajn[0], HORIZONTAL_ALIGNMENT_CENTER, r.size.x - 4, ajn[1], lines, tcol)
	else:
		Glyphs.draw(ci, c["icon"], _rect_glifo(r, locked, falta), col) # --- costo real ---
	# --- fin aprender ---
	_pastilla(ci, Rect2(r.position + Vector2(3, 3), Vector2(17, 17)), letra, Palette.UI_TEXT)
	if locked:
		# --- iconos --- candado chico (ya no es lo único que avisa) y la edad en su color, o el tope
		_candado(ci, Rect2(r.end.x - 17, r.position.y + 4, 13, 14), Palette.UI_DIM)
		var edad := edad_pedida(str(c["locked"]))
		if est == "tope":
			_pastilla_color(ci, r, "Máx. " + str(c["locked"]).get_slice(":", 1).strip_edges(), Iconos.color_estado("tope", Palette.UI_NEUTRAL))
		elif edad != "":
			var n := Iconos.edad_de_romano(edad)
			# Solo el número: «Edad III» tapaba el segundo renglón del nombre; la ayuda lo dice entero.
			_pastilla_color(ci, r, edad, Iconos.color_edad(n), "", 13)
		# --- fin iconos ---
	elif est == "en_curso":
		_tilde(ci, Rect2(r.end.x - 19, r.position.y + 3, 16, 16), Iconos.color_estado("hecho", Palette.UI_GOOD)) # --- iconos ---
	elif est == "aviso":
		_aviso_pob(ci, Rect2(r.end.x - 21, r.position.y + 3, 18, 17), Iconos.color_estado("tope", Palette.UI_NEUTRAL)) # --- iconos ---
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
			# --- iconos --- el número en el color del recurso que falta (no en rojo: no es un error)
			ci.draw_string(Hud.font_b, Vector2(p.x + gs + 5, p.y + rh - (4.0 if solo else 2.5)), items[i][1], HORIZONTAL_ALIGNMENT_LEFT, band.size.x - gs - 6, 13 if solo else 12, _texto_recurso(icol))
		# --- fin costo real ---
	# --- ronda 7 --- estrellita de «recomendado» (arriba a la derecha, si está libre)
	if c.get("recomendado", false) and not locked and est != "en_curso" and est != "aviso" and int(c.get("en_cola", 0)) == 0:
		_estrella(ci, Rect2(r.end.x - 18, r.position.y + 3, 15, 15), Iconos.color_estado("recomendado", Palette.WEALTH))
	# --- iconos --- cuántas hay en la cola de lo elegido (arriba a la derecha)
	var cola := int(c.get("en_cola", 0))
	if cola > 0 and not locked:
		var txt := "×%d" % cola
		var tw := Hud.font_b.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 12).x + 8
		var pr := Rect2(r.end.x - tw - 3, r.position.y + 3, tw, 17)
		var psb := StyleBoxFlat.new()
		psb.bg_color = FONDO_PASTILLA
		psb.set_corner_radius_all(4)
		ci.draw_style_box(psb, pr)
		ci.draw_string(Hud.font_b, Vector2(pr.position.x, pr.end.y - 4), txt, HORIZONTAL_ALIGNMENT_CENTER, pr.size.x, 12, Palette.UI_ACCENT)


## --- iconos --- (proceso/28) Estado de una casilla, en orden de prioridad:
##   en_curso   investigación ya pedida (no se puede volver a pedir, pero no es un bloqueo);
##   tope       máximo por edad alcanzado (bloquea);
##   bloqueado  falta la edad o un requisito (bloquea);
##   falta      no alcanzan los recursos;
##   aviso      se puede, pero no va a salir enseguida (población llena);
##   disponible se puede ya.
static func estado(c: Dictionary, res: Dictionary) -> String:
	if c.get("en_curso", false):
		return "en_curso"
	if c.get("tope", false):
		return "tope"
	if str(c.get("locked", "")) != "":
		return "bloqueado"
	if not faltante(c.get("cost", {}), res).is_empty():
		return "falta"
	if str(c.get("aviso", "")) != "":
		return "aviso"
	return "disponible"


const GLIFO_BLOQUEO := Color("6f6b64")


static func _color_borde(est: String, c: Dictionary) -> Color:
	match est:
		"falta":
			return Iconos.color_estado("falta", Palette.UI_ACCENT)
		"en_curso":
			return Iconos.color_estado("hecho", Palette.UI_GOOD)
		"aviso":
			return Iconos.color_estado("tope", Palette.UI_NEUTRAL)
		"disponible":
			if int(c.get("en_cola", 0)) > 0:
				return Color(Iconos.color_estado("hecho", Palette.UI_GOOD), 0.75)
	return Color(0, 0, 0, 0)


## Rayas diagonales finas: lo bloqueado se distingue de lo que solo no alcanza también en grises.
static func _rayado(ci: CanvasItem, r: Rect2) -> void:
	var paso := 7.0
	var col := Color(1, 1, 1, 0.07)
	var d := 0.0
	while d < r.size.x + r.size.y:
		# Recta x + y = d (en coordenadas de r), recortada al rectángulo.
		var a := Vector2(minf(d, r.size.x), d - minf(d, r.size.x))
		var b := Vector2(d - minf(d, r.size.y), minf(d, r.size.y))
		ci.draw_line(r.position + a, r.position + b, col, 1.5)
		d += paso


## Franja de la edad a la izquierda: toda investigación y lo que se habilita desde la edad II.
static func _franja_edad(ci: CanvasItem, r: Rect2, c: Dictionary) -> void:
	var edad := int(c.get("edad", 0))
	if edad <= 0 or (edad < 2 and c.get("kind", "") != "research"):
		return
	ci.draw_rect(Rect2(r.position.x + 1, r.position.y + 6, 4, r.size.y - 12), Iconos.color_edad(edad))


## Pastilla de color abajo a la derecha («III» en el color de la edad, «Máx. 2»); si no entra,
## `corto`.
static func _pastilla_color(ci: CanvasItem, r: Rect2, txt: String, fondo: Color, corto: String = "", fs: int = 11) -> void:
	if corto != "" and Hud.font_b.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x + 8 > r.size.x - 8:
		txt = corto
		fs = 13
	var w := Hud.font_b.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x + 8
	var pr := Rect2(r.end.x - w - 3, r.end.y - 19, w, 16)
	var sb := StyleBoxFlat.new()
	sb.bg_color = fondo
	sb.set_corner_radius_all(4)
	ci.draw_style_box(sb, pr)
	ci.draw_string(Hud.font_b, Vector2(pr.position.x, pr.end.y - 4), txt, HORIZONTAL_ALIGNMENT_CENTER, pr.size.x, fs, Iconos.texto_sobre(fondo))


## Tilde en un círculo: investigación en curso.
static func _tilde(ci: CanvasItem, r: Rect2, col: Color) -> void:
	ci.draw_circle(r.get_center(), r.size.x * 0.5, col)
	var p := r.position
	var s := r.size.x
	ci.draw_polyline(PackedVector2Array([p + Vector2(s * 0.24, s * 0.52), p + Vector2(s * 0.43, s * 0.72), p + Vector2(s * 0.78, s * 0.3)]), Iconos.OSCURO, 2.2, true)


## Población llena: la figura de población con un signo, en la pastilla del tope.
static func _aviso_pob(ci: CanvasItem, r: Rect2, col: Color) -> void:
	var sb := StyleBoxFlat.new()
	sb.bg_color = col
	sb.set_corner_radius_all(4)
	ci.draw_style_box(sb, r)
	Glyphs.draw(ci, "pob", Rect2(r.position + Vector2(1, 1), Vector2(r.size.y - 2, r.size.y - 2)), Iconos.OSCURO)
	ci.draw_string(Hud.font_b, Vector2(r.position.x + r.size.y - 5, r.end.y - 3), "!", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Iconos.OSCURO)


## Primera línea de la ayuda y de la ficha (proceso/28): qué pasa si hago clic ahora. Devuelve
## renglones de tramos [[texto, color], …]. Rojo (estados.bloquea) solo para lo que impide el clic
## por edad, requisito o tope; ámbar (estados.falta) para lo que falta juntar o lo que no bloquea;
## verde (estados.puede) si se puede. `falta_txt` es el «Faltan 40 de madera» del controlador.
static func lineas_ayuda(c: Dictionary, res: Dictionary, falta_txt: String) -> Array:
	var rojo := Iconos.color_estado("bloquea", Palette.UI_BAD)
	var ambar := Iconos.color_estado("falta", Palette.UI_ACCENT)
	var verde := Iconos.color_estado("puede", Palette.UI_GOOD)
	var locked := str(c.get("locked", ""))
	match estado(c, res):
		"en_curso":
			return [[["Ya está en investigación", Iconos.color_estado("hecho", Palette.UI_GOOD)]]]
		"tope":
			return [[["No se puede: " + locked.to_lower(), rojo]]]
		"bloqueado":
			var edad := edad_pedida(locked)
			if edad != "":
				return [[["Necesita la ", rojo], ["edad " + edad, Iconos.texto_edad(Iconos.edad_de_romano(edad))]]]
			return [[["No se puede: " + locked.left(1).to_lower() + locked.substr(1), rojo]]]
		"falta":
			return [[["Falta: " + falta_txt.trim_prefix("Faltan ").trim_prefix("Falta "), ambar]]]
	var puede := {"build": "Podés construirlo", "train": "Podés entrenarlo", "research": "Podés investigarlo"}.get(c.get("kind", ""), "Podés hacerlo") as String
	var out: Array = [[[puede, verde]]]
	if str(c.get("aviso", "")) != "":
		out.append([[str(c["aviso"]), ambar]])
	return out


## Dibuja los renglones de lineas_ayuda desde `at` (línea de base del primero); devuelve el alto.
static func dibujar_lineas(ci: CanvasItem, at: Vector2, lineas: Array, fs0: int, w: float, paint: bool) -> float:
	var y := 0.0
	for ln: Array in lineas:
		var fs := fs0
		while fs > 10 and ln.reduce(func(acc: float, seg: Array) -> float: return acc + Hud.font_b.get_string_size(seg[0], HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x, 0.0) > w:
			fs -= 1
		var x := at.x
		for seg: Array in ln:
			if paint:
				ci.draw_string(Hud.font_b, Vector2(x, at.y + y), seg[0], HORIZONTAL_ALIGNMENT_LEFT, -1, fs, seg[1])
			x += Hud.font_b.get_string_size(seg[0], HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
		y += fs0 + 6
	return y


## Color de recurso aclarado para que el número se lea sobre la franja oscura (4,5:1 o más).
static func _texto_recurso(c: Color) -> Color:
	var t := c
	for i in 6:
		if Iconos.luminancia(t) >= 0.3:
			break
		t = t.lightened(0.15)
	return t
# --- fin iconos ---


## --- ronda 7 --- Estrella de cinco puntas con borde oscuro (se ve sobre cualquier fondo).
static func _estrella(ci: CanvasItem, r: Rect2, col: Color) -> void:
	var c := r.get_center()
	var s := minf(r.size.x, r.size.y) * 0.5
	var pts := PackedVector2Array()
	for i in 10:
		pts.append(c + Vector2.from_angle(-PI / 2.0 + PI * i / 5.0) * (s if i % 2 == 0 else s * 0.45))
	var borde := pts.duplicate()
	borde.append(pts[0])
	ci.draw_colored_polygon(pts, col)
	ci.draw_polyline(borde, Color(0.06, 0.065, 0.075, 0.9), 1.2, true)


## Letra más chica que se acepta antes de abreviar (ronda 7).
const MIN_LEGIBLE := 8


## --- ronda 7 --- (jugador nuevo: «aller de asedio», «Pohã ñana (remedios del») [texto, tamaño]
## con que `txt` entra entero en `lines` renglones de `w`: achica hasta MIN_LEGIBLE; si no
## alcanza, deja afuera lo que va entre paréntesis (sigue en la ayuda) y, como último recurso,
## saca palabras del final y pone «…». Nunca se corta una palabra por la mitad.
static func _ajuste(f: Font, txt: String, size: int, w: float, lines: int) -> Array:
	var t := txt
	while true:
		var fs := _fit_lineas(f, t, size, w, lines)
		if fs >= MIN_LEGIBLE and _entra(f, t, fs, w, lines):
			return [t, fs]
		if t.contains(" ("):
			t = t.get_slice(" (", 0).strip_edges()
			continue
		break
	var fs7 := _fit_lineas(f, t, size, w, lines)
	if _entra(f, t, fs7, w, lines):
		return [t, fs7]
	var words := t.split(" ", false)
	while words.size() > 1:
		words.resize(words.size() - 1)
		var corto := " ".join(words).trim_suffix(",").trim_suffix(" de").trim_suffix(" del") + "…"
		var fsc := _fit_lineas(f, corto, size, w, lines)
		if _entra(f, corto, fsc, w, lines):
			return [corto, fsc]
	return [t, fs7]


## ¿`txt` entra en `lines` renglones de `w` con letra `fs`, sin partir palabras?
static func _entra(f: Font, txt: String, fs: int, w: float, lines: int) -> bool:
	for word in txt.split(" ", false):
		if f.get_string_size(word, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x > w:
			return false
	return f.get_multiline_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, w, fs).y <= f.get_height(fs) * lines + 0.5


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
