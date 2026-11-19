class_name Iconos
extends RefCounted
## Íconos de la grilla y color por edad (proceso/28-iconos-y-estados).
##
## - Cada casilla de construir, entrenar o investigar tiene un ícono propio. Los glifos nuevos se
##   dibujan acá (dibujo vectorial en código, sin imágenes); los de antes siguen en glyphs.gd.
## - Un ícono se puede reemplazar por una imagen sin tocar el código: data/iconos.json →
##   "imagenes" ({nombre de ícono: ruta res://}). Si la ruta no existe, queda el glifo.
## - El ícono de una investigación sale de data/iconos.json → "tecnologias" y, si no está ahí, del
##   campo `icono` de data/tecnologias.json.
## - La paleta de las edades (I a IV) y los colores de los estados de una casilla también están en
##   data/iconos.json: nada de colores sueltos en el código.

const RUTA := "res://data/iconos.json"

static var _cfg: Dictionary = {}
static var _tex: Dictionary = {}


static func cfg() -> Dictionary:
	if _cfg.is_empty():
		_cfg = JSON.parse_string(FileAccess.get_file_as_string(RUTA)) if FileAccess.file_exists(RUTA) else {}
		if _cfg == null:
			_cfg = {}
	return _cfg


## Ícono de una investigación: la tabla de la interfaz y, si no, el de sus datos.
static func de_tecnologia(tech: String, t: Dictionary) -> String:
	return String((cfg().get("tecnologias", {}) as Dictionary).get(tech, t.get("icono", "")))


# ---------------------------------------------------------------- Edades

## Color de la edad `age` (1 a 4) para bordes, franjas y textos.
static func color_edad(age: int) -> Color:
	var cols: Array = (cfg().get("edades", {}) as Dictionary).get("colores", [])
	if cols.is_empty():
		return Palette.UI_ACCENT
	return Color(String(cols[clampi(age, 1, cols.size()) - 1]))


## Color de la edad para escribir sobre el fondo oscuro (el de la franja puede ser más oscuro).
static func texto_edad(age: int) -> Color:
	var cols: Array = (cfg().get("edades", {}) as Dictionary).get("texto", [])
	if cols.is_empty():
		return color_edad(age)
	return Color(String(cols[clampi(age, 1, cols.size()) - 1]))


## "III" → 3 (0 si no es un número romano de edad).
static func edad_de_romano(r: String) -> int:
	return {"I": 1, "II": 2, "III": 3, "IV": 4, "V": 5}.get(r.strip_edges().to_upper(), 0)


## «Edad III» con el color de la edad, en BBCode (para RichTextLabel).
static func edad_bb(age: int) -> String:
	return "[color=#%s]Edad %s[/color]" % [texto_edad(age).to_html(false), Sim._roman(age)]


## Luminancia relativa (WCAG) de un color.
static func luminancia(c: Color) -> float:
	var f := func(x: float) -> float: return x / 12.92 if x <= 0.04045 else pow((x + 0.055) / 1.055, 2.4)
	return 0.2126 * f.call(c.r) + 0.7152 * f.call(c.g) + 0.0722 * f.call(c.b)


## Texto que se lee sobre `fondo`: oscuro sobre los claros, blanco sobre los oscuros.
static func texto_sobre(fondo: Color) -> Color:
	return OSCURO if luminancia(fondo) > 0.18 else Color(1, 1, 1)


## Color de un estado de casilla (data/iconos.json → estados): falta, bloqueo, hecho, tope…
static func color_estado(k: String, fallback: Color) -> Color:
	var v: String = String((cfg().get("estados", {}) as Dictionary).get(k, ""))
	return Color(v) if v != "" else fallback


# ---------------------------------------------------------------- Imágenes

## Textura que reemplaza al glifo `kind` (o null). Se busca el nombre entero y, si es compuesto
## («guerrero^1», «atacar~hondero~2»), también el nombre entero; las partes no se reemplazan solas.
static func imagen(kind: String) -> Texture2D:
	if _tex.has(kind):
		return _tex[kind]
	var t: Texture2D = null
	var ruta := String((cfg().get("imagenes", {}) as Dictionary).get(kind, ""))
	if ruta != "" and ResourceLoader.exists(ruta):
		t = load(ruta) as Texture2D
	_tex[kind] = t
	return t


## Dibuja la imagen de `kind` si hay una; devuelve si la dibujó. `col` atenúa la imagen igual que
## al glifo: claro = tal cual; atenuado = más oscuro y transparente.
static func dibujar_imagen(ci: CanvasItem, kind: String, r: Rect2, col: Color) -> bool:
	var t := imagen(kind)
	if t == null:
		return false
	var mod := Color(1, 1, 1, col.a)
	if col.get_luminance() < Palette.UI_TEXT.get_luminance() - 0.05:
		mod = Color(col.lightened(0.25), col.a)
	var s := minf(r.size.x, r.size.y)
	ci.draw_texture_rect(t, Rect2(r.get_center() - Vector2(s, s) / 2.0, Vector2(s, s)), false, mod)
	return true


# ---------------------------------------------------------------- Glifos nuevos

## Nombres que dibuja Glyphs.draw (los de antes) más los de acá. Los compuestos se revisan por
## partes. tests/iconos.gd lo usa para que ningún comando caiga en el círculo de reserva.
const DE_GLYPHS := ["aldeano", "alimento", "arbol", "arbusto", "arcabuz", "ariete", "atacar", "barrio_japones", "barrio_portugues", "bengala", "calma", "camino", "campana", "carga", "carpa", "casa", "catapulta", "centro", "corral", "cuartel", "decision", "deposito", "detener", "elefante", "empalizada", "escudo", "explorador", "expulsar", "form_abierta", "form_bloque", "form_columna", "form_linea", "fortaleza", "granja", "guerrero", "gult", "hito", "hito_economia", "hito_guerra", "hito_logro", "hondero", "info", "jinete", "kraal", "lancero", "madera", "mantener", "menu_economia", "menu_militar", "mercado", "mocambo", "ocioso", "patrullar", "piedra", "pob", "puerta", "qollqa", "refugio", "riqueza", "roca", "telar", "terraza", "torre", "velocidad", "vida", "volver"]
const PROPIOS := ["diana", "establo", "taller_asedio", "ruka", "boleador", "incendiario", "awqa", "katana", "elefante_guerra", "hacha", "pico", "orfebre", "canasta", "riego", "muro", "martillo", "vigia", "aspillera", "engranaje", "investigar", "yunque", "espada", "arco", "adiestramiento", "maravilla",
	# --- paso 6 --- saberes propios (mapuches y guaraníes): mejoras, unidades y el hoyo
	"coselete", "trigo", "estacas", "lawen", "tropilla", "poncho", "remonta", "pron", "mandioca", "remo", "yuyo", "oga", "mborore", "yerba", "flecha_dura", "imprenta", "aty",
	"weichafe_montado", "kona_waiki", "canoa", "jinete_lanza", "kaaguygua", "hoyo",
	# --- paso 6, par 2 --- Etiopía y Palmares
	"arado", "acta", "kosso", "cota", "amba", "amole", "massawa", "katama", "palmera", "vigia_mocambo", "fuelle", "sanguar", "kilombo", "trato", "hierro", "fojo",
	"gasa", "farasanna", "jinete_corte", "zagaia", "guarnicao", "capitao",
	# --- paso 6, par 3 --- Tawantinsuyu y Ayutthaya
	"chunu", "khipu", "tumi", "puente_soga", "champi", "wayrachina", "waraka", "chaski", "cornaca", "vasija", "recetario", "arroz_crecida", "junco", "canal", "fundicion", "astillero",
	"galga", "jinete_manco", "ngao", "suan_phlu",
	# --- ronda 8, 05 --- la guardia de la IV
	"guardia"]
const OSCURO := Color(0.06, 0.065, 0.075)
const _SABERES := preload("res://src/game/ui/iconos_saberes.gd") # --- paso 6 --- glifos de los saberes propios


## Ícono de un edificio o una unidad cuando la tabla lo pide (data/iconos.json → tipos), o "".
static func de_tipo(type: String) -> String:
	return String((cfg().get("tipos", {}) as Dictionary).get(type, ""))


static func conocido(kind: String) -> bool:
	if imagen(kind) != null:
		return true
	for sep in ["#", "+", "^", "~"]:
		if kind.contains(sep):
			for p in kind.split(sep):
				if p != "" and not p.is_valid_int() and not conocido(p):
					return false
			return true
	return kind in DE_GLYPHS or kind in PROPIOS


## Dibuja `kind` si es de los de acá (una imagen, «x#n» o un glifo nuevo); devuelve false si le
## toca a Glyphs.draw.
static func dibujar(ci: CanvasItem, kind: String, r: Rect2, col: Color) -> bool:
	if dibujar_imagen(ci, kind, r, col):
		return true
	if kind.contains("#"):
		_tanda(ci, kind, r, col)
		return true
	if not kind in PROPIOS:
		return false
	var c := r.get_center()
	var s := minf(r.size.x, r.size.y)
	var w := maxf(1.5, s * 0.07)
	var claro := col == Palette.UI_TEXT
	if _SABERES.dibujar(ci, kind, c, s, w, col, claro, r): # --- paso 6 ---
		return true
	match kind:
		"maravilla":
			# --- paso 7 --- Maravilla: obra grande de tres cuerpos escalonados, con portada y
			# estandarte arriba; sin símbolos sagrados (sol, cruz, templo).
			ci.draw_rect(Rect2(c + Vector2(-s * 0.46, s * 0.22), Vector2(s * 0.92, s * 0.2)), col)
			ci.draw_rect(Rect2(c + Vector2(-s * 0.34, s * 0.02), Vector2(s * 0.68, s * 0.22)), col.darkened(0.12))
			ci.draw_rect(Rect2(c + Vector2(-s * 0.22, -s * 0.2), Vector2(s * 0.44, s * 0.24)), col)
			ci.draw_rect(Rect2(c + Vector2(-s * 0.07, s * 0.24), Vector2(s * 0.14, s * 0.18)), OSCURO)
			for x: float in [-0.13, 0.0, 0.13]:
				ci.draw_rect(Rect2(c + Vector2(s * (x - 0.03), -s * 0.12), Vector2(s * 0.06, s * 0.1)), OSCURO)
			ci.draw_line(c + Vector2(0, -s * 0.2), c + Vector2(0, -s * 0.48), col, w)
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(0, -s * 0.48), c + Vector2(s * 0.26, -s * 0.42), c + Vector2(0, -s * 0.35)]), Palette.UI_ACCENT if claro else col)
		"guardia":
			# --- ronda 8, 05 --- Guardia de la IV: escudo alto con un galón de élite, la lanza
			# larga detrás y tres puntas arriba (la élite), sin emblemas de ningún pueblo.
			ci.draw_line(c + Vector2(s * 0.3, s * 0.46), c + Vector2(s * 0.3, -s * 0.4), col, w)
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(s * 0.3, -s * 0.5), c + Vector2(s * 0.38, -s * 0.36), c + Vector2(s * 0.22, -s * 0.36)]), col)
			var sh := PackedVector2Array([c + Vector2(-s * 0.3, -s * 0.26), c + Vector2(s * 0.18, -s * 0.26), c + Vector2(s * 0.18, s * 0.14), c + Vector2(-s * 0.06, s * 0.42), c + Vector2(-s * 0.3, s * 0.14)])
			ci.draw_colored_polygon(sh, col)
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(-s * 0.2, -s * 0.06), c + Vector2(-s * 0.06, s * 0.06), c + Vector2(s * 0.08, -s * 0.06), c + Vector2(s * 0.08, s * 0.04), c + Vector2(-s * 0.06, s * 0.16), c + Vector2(-s * 0.2, s * 0.04)]), OSCURO)
			for x: float in [-0.2, -0.06, 0.08]:
				ci.draw_colored_polygon(PackedVector2Array([c + Vector2(s * (x - 0.05), -s * 0.3), c + Vector2(s * x, -s * 0.44), c + Vector2(s * (x + 0.05), -s * 0.3)]), Palette.UI_ACCENT if claro else col)
		"diana":
			# Campo de tiro: blanco de anillos con una flecha clavada.
			var dc := c + Vector2(-s * 0.06, s * 0.06)
			ci.draw_circle(dc, s * 0.36, col)
			ci.draw_circle(dc, s * 0.26, OSCURO)
			ci.draw_circle(dc, s * 0.17, col)
			ci.draw_circle(dc, s * 0.07, OSCURO)
			var a := c + Vector2(s * 0.44, -s * 0.44)
			ci.draw_line(a, dc, OSCURO, w * 2.6)
			ci.draw_line(a, dc, col, w)
			ci.draw_colored_polygon(PackedVector2Array([a, a + Vector2(-s * 0.18, -s * 0.02), a + Vector2(s * 0.02, s * 0.18)]), col)
		"establo":
			# Establo: galpón de techo quebrado con una herradura en el portón.
			ci.draw_rect(Rect2(c + Vector2(-s * 0.36, -s * 0.06), Vector2(s * 0.72, s * 0.42)), col)
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(-s * 0.44, -s * 0.04), c + Vector2(-s * 0.3, -s * 0.28), c + Vector2(0, -s * 0.42), c + Vector2(s * 0.3, -s * 0.28), c + Vector2(s * 0.44, -s * 0.04)]), col.darkened(0.2))
			ci.draw_arc(c + Vector2(0, s * 0.15), s * 0.15, PI * 0.75, PI * 2.25, 16, OSCURO, w * 1.6)
		"taller_asedio":
			# Taller de asedio: rueda de carro y martillo.
			var rc := c + Vector2(-s * 0.1, s * 0.12)
			ci.draw_arc(rc, s * 0.28, 0, TAU, 22, col, w * 1.5)
			for i in 4:
				var d := Vector2.from_angle(PI * i / 4.0) * s * 0.27
				ci.draw_line(rc - d, rc + d, col, w * 0.8)
			ci.draw_circle(rc, s * 0.07, col)
			ci.draw_line(c + Vector2(s * 0.0, -s * 0.04), c + Vector2(s * 0.36, -s * 0.38), OSCURO, w * 2.8)
			ci.draw_line(c + Vector2(s * 0.0, -s * 0.04), c + Vector2(s * 0.36, -s * 0.38), col, w * 1.2)
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(s * 0.16, -s * 0.46), c + Vector2(s * 0.46, -s * 0.16), c + Vector2(s * 0.36, -s * 0.06), c + Vector2(s * 0.06, -s * 0.36)]), col)
		"ruka":
			# Lof: ruka de techo redondo (paja hasta el suelo), puerta y bandera de centro chico.
			var pts := PackedVector2Array()
			for i in 13:
				var a := PI + PI * i / 12.0
				pts.append(c + Vector2(cos(a) * s * 0.44, s * 0.36 + sin(a) * s * 0.62))
			ci.draw_colored_polygon(pts, col)
			for i in 2:
				ci.draw_arc(c + Vector2(0, s * 0.36), s * (0.22 + i * 0.12), PI * 1.12, PI * 1.88, 12, col.darkened(0.3), w * 0.6)
			ci.draw_rect(Rect2(c + Vector2(-s * 0.08, s * 0.12), Vector2(s * 0.16, s * 0.24)), OSCURO)
			ci.draw_line(c + Vector2(0, -s * 0.24), c + Vector2(0, -s * 0.48), col, w * 0.8)
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(0, -s * 0.48), c + Vector2(s * 0.22, -s * 0.43), c + Vector2(0, -s * 0.38)]), Palette.UI_ACCENT if claro else col)
		"boleador":
			# Boleador: figura con las boleadoras girando arriba (tres bolas atadas).
			Glyphs._figure(ci, c + Vector2(-s * 0.16, s * 0.04), s, col, 0.85)
			var h := c + Vector2(s * 0.14, -s * 0.18)
			ci.draw_line(c + Vector2(-s * 0.04, s * 0.02), h, col, w)
			for i in 3:
				var p := h + Vector2.from_angle(-PI * 0.4 + TAU * i / 3.0) * s * 0.22
				ci.draw_line(h, p, col, w * 0.6)
				ci.draw_circle(p, s * 0.075, col)
		"incendiario":
			# Incendiarios: figura con una antorcha encendida.
			Glyphs._figure(ci, c + Vector2(-s * 0.16, s * 0.04), s, col, 0.85)
			ci.draw_line(c + Vector2(-s * 0.04, s * 0.08), c + Vector2(s * 0.22, -s * 0.16), col.darkened(0.25), w * 1.4)
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(s * 0.14, -s * 0.12), c + Vector2(s * 0.12, -s * 0.3), c + Vector2(s * 0.28, -s * 0.5), c + Vector2(s * 0.4, -s * 0.3), c + Vector2(s * 0.32, -s * 0.12)]), col)
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(s * 0.2, -s * 0.16), c + Vector2(s * 0.2, -s * 0.3), c + Vector2(s * 0.28, -s * 0.38), c + Vector2(s * 0.32, -s * 0.18)]), Palette.UI_ACCENT if claro else OSCURO)
		"awqa":
			# Leva inca: figura con la porra estrellada (champi).
			Glyphs._figure(ci, c + Vector2(-s * 0.12, s * 0.04), s, col, 0.9)
			ci.draw_line(c + Vector2(s * 0.04, s * 0.12), c + Vector2(s * 0.28, -s * 0.22), col.darkened(0.25), w * 1.3)
			var st := PackedVector2Array()
			for i in 12:
				st.append(c + Vector2(s * 0.3, -s * 0.28) + Vector2.from_angle(TAU * i / 12.0) * s * (0.16 if i % 2 == 0 else 0.08))
			ci.draw_colored_polygon(st, col)
		"katana":
			# Compañía japonesa: figura con la espada curva en alto.
			Glyphs._figure(ci, c + Vector2(-s * 0.14, s * 0.04), s, col, 0.9)
			ci.draw_arc(c + Vector2(-s * 0.36, s * 0.2), s * 0.66, -PI * 0.36, -PI * 0.1, 12, col, w * 1.2)
			ci.draw_line(c + Vector2(s * 0.12, s * 0.06), c + Vector2(s * 0.2, -s * 0.04), col, w * 2.2)
		"elefante_guerra":
			# Elefante de guerra: el elefante con una lanza y un banderín sobre el lomo.
			Glyphs.draw(ci, "elefante", Rect2(r.position + Vector2(0, r.size.y * 0.1), r.size * 0.9), col)
			ci.draw_line(c + Vector2(-s * 0.32, -s * 0.02), c + Vector2(s * 0.3, -s * 0.48), col, w)
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(s * 0.3, -s * 0.48), c + Vector2(s * 0.06, -s * 0.46), c + Vector2(s * 0.16, -s * 0.32)]), Palette.UI_ACCENT if claro else col)
		"hacha":
			# Herramientas de tala: hacha.
			ci.draw_line(c + Vector2(-s * 0.34, s * 0.4), c + Vector2(s * 0.16, -s * 0.3), col.darkened(0.2), w * 1.5)
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(s * 0.0, -s * 0.36), c + Vector2(s * 0.2, -s * 0.44), c + Vector2(s * 0.44, -s * 0.2), c + Vector2(s * 0.36, s * 0.0), c + Vector2(s * 0.1, -s * 0.12)]), col)
			ci.draw_line(c + Vector2(s * 0.24, -s * 0.4), c + Vector2(s * 0.4, -s * 0.06), col.lightened(0.3) if claro else col.darkened(0.2), w * 0.6)
		"pico":
			# Cantería: pico de minero.
			ci.draw_line(c + Vector2(-s * 0.28, s * 0.42), c + Vector2(s * 0.1, -s * 0.16), col.darkened(0.2), w * 1.5)
			ci.draw_arc(c + Vector2(s * 0.22, s * 0.16), s * 0.5, -PI * 0.92, -PI * 0.28, 16, col, w * 1.9)
			ci.draw_circle(c + Vector2(s * 0.08, -s * 0.18), s * 0.08, col)
		"orfebre":
			# Trabajo de la riqueza: anillo con una gema.
			ci.draw_arc(c + Vector2(0, s * 0.14), s * 0.25, 0, TAU, 24, col, w * 1.6)
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(0, -s * 0.46), c + Vector2(s * 0.18, -s * 0.26), c + Vector2(0, -s * 0.06), c + Vector2(-s * 0.18, -s * 0.26)]), Palette.WEALTH if claro else col)
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(0, -s * 0.46), c + Vector2(s * 0.18, -s * 0.26), c + Vector2(0, -s * 0.26)]), Color(1, 1, 1, 0.35 * col.a))
		"canasta":
			# Cestas de carga: canasta tejida, ancha, con frutos y la correa para la espalda.
			ci.draw_arc(c + Vector2(0, -s * 0.06), s * 0.32, PI * 1.05, PI * 1.95, 12, col, w)
			ci.draw_circle(c + Vector2(-s * 0.13, -s * 0.1), s * 0.1, col.lightened(0.1) if claro else col)
			ci.draw_circle(c + Vector2(s * 0.1, -s * 0.12), s * 0.11, col.lightened(0.1) if claro else col)
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(-s * 0.4, -s * 0.04), c + Vector2(s * 0.4, -s * 0.04), c + Vector2(s * 0.3, s * 0.38), c + Vector2(-s * 0.3, s * 0.38)]), col)
			for i in 3:
				var y := c.y + s * (0.06 + i * 0.1)
				ci.draw_line(Vector2(c.x - s * 0.36 + i * s * 0.03, y), Vector2(c.x + s * 0.36 - i * s * 0.03, y), OSCURO, w * 0.5)
		"riego":
			# Riego: gota sobre los surcos.
			for i in 3:
				var y := c.y + s * (0.1 + i * 0.12)
				ci.draw_rect(Rect2(Vector2(c.x - s * 0.42, y), Vector2(s * 0.84, s * 0.07)), col.darkened(0.12 * i))
			var gota := Palette.UI_NEUTRAL if claro else col
			ci.draw_circle(c + Vector2(0, -s * 0.16), s * 0.17, gota)
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(-s * 0.15, -s * 0.22), c + Vector2(0, -s * 0.48), c + Vector2(s * 0.15, -s * 0.22)]), gota)
		"muro":
			# Mampostería: muro de piedra labrada (hiladas trabadas).
			for row in 3:
				var y := c.y - s * 0.3 + row * s * 0.22
				var off := (row % 2) * s * 0.14 - s * 0.14
				for i in 4:
					var x0 := c.x - s * 0.42 + off + i * s * 0.28
					var x1 := minf(x0 + s * 0.25, c.x + s * 0.42)
					x0 = maxf(x0, c.x - s * 0.42)
					if x1 > x0:
						ci.draw_rect(Rect2(Vector2(x0, y), Vector2(x1 - x0, s * 0.18)), col if (row + i) % 2 == 0 else col.darkened(0.18))
		"martillo":
			# Reparación: martillo sobre un muro.
			for i in 3:
				ci.draw_rect(Rect2(c + Vector2(-s * 0.42 + i * s * 0.29, s * 0.2), Vector2(s * 0.26, s * 0.18)), col.darkened(0.2))
			ci.draw_line(c + Vector2(-s * 0.24, s * 0.12), c + Vector2(s * 0.16, -s * 0.28), OSCURO, w * 2.8)
			ci.draw_line(c + Vector2(-s * 0.24, s * 0.12), c + Vector2(s * 0.16, -s * 0.28), col, w * 1.3)
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(-s * 0.02, -s * 0.36), c + Vector2(s * 0.14, -s * 0.5), c + Vector2(s * 0.44, -s * 0.2), c + Vector2(s * 0.3, -s * 0.06)]), col)
		"vigia":
			# Vigías: ojo abierto sobre la almena.
			var eye := PackedVector2Array()
			for i in 17:
				var t := float(i) / 16.0
				eye.append(c + Vector2(lerpf(-s * 0.44, s * 0.44, t), -s * 0.1 - sin(t * PI) * s * 0.22))
			for i in range(15, 0, -1):
				var t := float(i) / 16.0
				eye.append(c + Vector2(lerpf(-s * 0.44, s * 0.44, t), -s * 0.1 + sin(t * PI) * s * 0.22))
			ci.draw_colored_polygon(eye, col)
			ci.draw_circle(c + Vector2(0, -s * 0.1), s * 0.13, OSCURO)
			ci.draw_circle(c + Vector2(s * 0.04, -s * 0.14), s * 0.045, col)
			for i in 3:
				ci.draw_rect(Rect2(c + Vector2(-s * 0.38 + i * s * 0.29, s * 0.22), Vector2(s * 0.18, s * 0.18)), col.darkened(0.2))
		"aspillera":
			# Aspilleras: torre que dispara más flechas (tres saliendo de la ranura).
			Glyphs.draw(ci, "torre", Rect2(r.position + Vector2(-s * 0.2, s * 0.06), r.size * 0.86), col)
			ci.draw_rect(Rect2(c + Vector2(-s * 0.24, -s * 0.04), Vector2(s * 0.06, s * 0.2)), OSCURO)
			for i in 3:
				var y := -s * 0.3 + i * s * 0.22
				ci.draw_line(c + Vector2(s * 0.06, y + s * 0.07), c + Vector2(s * 0.4, y), col, w * 0.9)
				ci.draw_colored_polygon(PackedVector2Array([c + Vector2(s * 0.48, y - s * 0.015), c + Vector2(s * 0.34, y - s * 0.08), c + Vector2(s * 0.36, y + s * 0.06)]), col)
		"engranaje":
			# Oficio maestro: engranaje con el corazón de riqueza (el motor propio del pueblo).
			var g := PackedVector2Array()
			for i in 32:
				var a := TAU * (i + 0.5) / 32.0
				g.append(c + Vector2.from_angle(a) * s * (0.44 if (i / 2) % 2 == 0 else 0.32))
			ci.draw_colored_polygon(g, col)
			ci.draw_circle(c, s * 0.18, OSCURO)
			ci.draw_circle(c, s * 0.11, Palette.WEALTH if claro else col)
		"yunque":
			# --- ronda 7 --- Submenú de la herrería: yunque con su pie.
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(-s * 0.44, -s * 0.2), c + Vector2(s * 0.3, -s * 0.2), c + Vector2(s * 0.44, -s * 0.1), c + Vector2(s * 0.2, s * 0.02), c + Vector2(-s * 0.22, s * 0.02), c + Vector2(-s * 0.3, -s * 0.08)]), col)
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(-s * 0.1, s * 0.02), c + Vector2(s * 0.08, s * 0.02), c + Vector2(s * 0.14, s * 0.26), c + Vector2(-s * 0.16, s * 0.26)]), col)
			ci.draw_rect(Rect2(c + Vector2(-s * 0.28, s * 0.26), Vector2(s * 0.52, s * 0.1)), col)
			ci.draw_line(c + Vector2(s * 0.06, -s * 0.44), c + Vector2(s * 0.22, -s * 0.28), col, w * 1.4)
		"investigar":
			# Submenú de investigaciones: pergamino con renglones.
			ci.draw_rect(Rect2(c + Vector2(-s * 0.3, -s * 0.36), Vector2(s * 0.6, s * 0.7)), col)
			ci.draw_circle(c + Vector2(-s * 0.3, -s * 0.36), s * 0.09, col.darkened(0.25))
			ci.draw_circle(c + Vector2(s * 0.3, s * 0.34), s * 0.09, col.darkened(0.25))
			for i in 4:
				var y := -s * 0.2 + i * s * 0.13
				ci.draw_line(c + Vector2(-s * 0.2, y), c + Vector2(s * 0.2 - (i % 2) * s * 0.12, y), OSCURO, w * 0.7)
		"espada":
			# Herrería, ataque cuerpo a cuerpo: espada.
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(s * 0.38, -s * 0.44), c + Vector2(s * 0.42, -s * 0.4), c + Vector2(-s * 0.06, s * 0.16), c + Vector2(-s * 0.16, s * 0.06)]), col)
			ci.draw_line(c + Vector2(-s * 0.26, -s * 0.02), c + Vector2(s * 0.02, s * 0.26), col, w * 1.5)
			ci.draw_line(c + Vector2(-s * 0.12, s * 0.12), c + Vector2(-s * 0.3, s * 0.3), col.darkened(0.25), w * 1.7)
			ci.draw_circle(c + Vector2(-s * 0.34, s * 0.34), s * 0.07, col)
		"arco":
			# Herrería, ataque a distancia: arco tenso con la flecha.
			var bc := c + Vector2(-s * 0.28, s * 0.28)
			ci.draw_arc(bc, s * 0.62, -PI * 0.5, 0.0, 18, col, w * 1.5)
			ci.draw_line(bc + Vector2(0, -s * 0.62), bc + Vector2(s * 0.62, 0), col.darkened(0.2), w * 0.6)
			ci.draw_line(c + Vector2(-s * 0.36, s * 0.36), c + Vector2(s * 0.34, -s * 0.34), col, w)
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(s * 0.44, -s * 0.44), c + Vector2(s * 0.24, -s * 0.38), c + Vector2(s * 0.38, -s * 0.24)]), col)
		"adiestramiento":
			# Adiestramiento: figura frente al muñeco de práctica, con la cruz de vida.
			Glyphs._figure(ci, c + Vector2(-s * 0.2, s * 0.04), s, col, 0.85)
			ci.draw_line(c + Vector2(s * 0.24, s * 0.44), c + Vector2(s * 0.24, -s * 0.28), col.darkened(0.2), w * 1.3)
			ci.draw_line(c + Vector2(s * 0.06, -s * 0.12), c + Vector2(s * 0.42, -s * 0.12), col.darkened(0.2), w * 1.3)
			ci.draw_circle(c + Vector2(s * 0.24, -s * 0.34), s * 0.1, col.darkened(0.2))
			Glyphs.draw(ci, "vida", Rect2(c + Vector2(-s * 0.5, -s * 0.5), Vector2(s * 0.34, s * 0.34)), Palette.UI_GOOD if claro else col)
	return true


## «hacha#2»: el glifo con la tanda en palotes dorados arriba a la derecha (como la herrería).
static func _tanda(ci: CanvasItem, kind: String, r: Rect2, col: Color) -> void:
	var parts := kind.split("#")
	var n := int(parts[1]) if parts.size() > 1 else 0
	var s := minf(r.size.x, r.size.y)
	var o := r.position + (r.size - Vector2(s, s)) / 2.0
	Glyphs.draw(ci, parts[0], Rect2(o + Vector2(0, s * 0.1), Vector2(s, s) * 0.86), col)
	var w := maxf(1.5, s * 0.07)
	for i in n:
		var x := o.x + s * (0.94 - 0.11 * (n - 1 - i))
		ci.draw_line(Vector2(x, o.y + s * 0.02), Vector2(x, o.y + s * 0.26), Palette.UI_ACCENT, w)
