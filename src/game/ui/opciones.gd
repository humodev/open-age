class_name Opciones
extends RefCounted
## Opciones del jugador (docs/diseno/interfaz/00-auditoria.md, P1, P2 y P15).
##
## Se guardan en user://opciones.cfg (ConfigFile) y se aplican al arrancar. El mismo
## diálogo se abre desde el menú principal y desde la pausa. Las capturas y las pruebas
## (--shot, --autotest) no leen ni escriben el archivo, para que salgan siempre iguales;
## --escala=, --paleta= y --barras=1 las fijan a mano.

const RUTA := "user://opciones.cfg"
## Resolución de diseño del HUD: a 1920×1080 una unidad de la interfaz es un píxel.
const BASE := Vector2(1920, 1080)
## Escalas de la opción; 0 es "automática".
const ESCALAS: Array[float] = [0.0, 0.8, 1.0, 1.25, 1.5]
## La automática nunca achica la interfaz por debajo de este factor (a 1366×768 sería 0,71
## y las letras de 12 px quedarían en 8,5 px reales)…
const AUTO_MIN := 0.85
## …ni la agranda tanto que no entre en una pantalla lógica de 1280×720.
const MIN_LOGICO := Vector2(1280, 720)

static var escala := 0.0
static var paleta := "normal"
static var general := 100.0
static var musica := 100.0
static var efectos := 100.0
static var ambiente := 100.0
static var bordes := true
static var velocidad_camara := 100.0
static var pantalla_completa := false
static var barras_siempre := false
## Si es verdadero, guardar() no escribe (capturas y pruebas).
static var solo_lectura := false


# ---------------------------------------------------------------- Archivo

static func cargar(ruta: String = RUTA) -> void:
	var cf := ConfigFile.new()
	if cf.load(ruta) != OK:
		return
	escala = float(cf.get_value("interfaz", "escala", escala))
	paleta = str(cf.get_value("interfaz", "paleta", paleta))
	barras_siempre = bool(cf.get_value("interfaz", "barras_siempre", barras_siempre))
	general = float(cf.get_value("sonido", "general", general))
	musica = float(cf.get_value("sonido", "musica", musica))
	efectos = float(cf.get_value("sonido", "efectos", efectos))
	ambiente = float(cf.get_value("sonido", "ambiente", ambiente))
	bordes = bool(cf.get_value("camara", "bordes", bordes))
	velocidad_camara = float(cf.get_value("camara", "velocidad", velocidad_camara))
	pantalla_completa = bool(cf.get_value("pantalla", "completa", pantalla_completa))


static func guardar(ruta: String = RUTA) -> void:
	if solo_lectura:
		return
	var cf := ConfigFile.new()
	cf.set_value("interfaz", "escala", escala)
	cf.set_value("interfaz", "paleta", paleta)
	cf.set_value("interfaz", "barras_siempre", barras_siempre)
	cf.set_value("sonido", "general", general)
	cf.set_value("sonido", "musica", musica)
	cf.set_value("sonido", "efectos", efectos)
	cf.set_value("sonido", "ambiente", ambiente)
	cf.set_value("camara", "bordes", bordes)
	cf.set_value("camara", "velocidad", velocidad_camara)
	cf.set_value("pantalla", "completa", pantalla_completa)
	cf.save(ruta)


static func restablecer() -> void:
	escala = 0.0
	paleta = "normal"
	general = 100.0
	musica = 100.0
	efectos = 100.0
	ambiente = 100.0
	bordes = true
	velocidad_camara = 100.0
	pantalla_completa = false
	barras_siempre = false


# ---------------------------------------------------------------- Aplicar

## Factor de escala total (píxeles reales por unidad de interfaz) para una ventana.
static func factor(win_size: Vector2, e: float = -1.0) -> float:
	if e < 0.0:
		e = escala
	var motor := minf(win_size.x / BASE.x, win_size.y / BASE.y)
	if e > 0.0:
		return motor * e
	var tope := minf(win_size.x / MIN_LOGICO.x, win_size.y / MIN_LOGICO.y)
	return minf(maxf(motor, AUTO_MIN), maxf(tope, motor))


## Porcentaje que da la escala automática en esta ventana (100 % a 1080p).
static func auto_pct(win_size: Vector2) -> int:
	var motor := minf(win_size.x / BASE.x, win_size.y / BASE.y)
	return int(round(factor(win_size, 0.0) / motor * 100.0))


## Estira la interfaz (canvas_items) desde 1920×1080 y le aplica la escala elegida.
## El 3D no se toca: se dibuja siempre a la resolución real.
static func aplicar_escala(win: Window) -> void:
	win.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	win.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_EXPAND
	win.content_scale_size = Vector2i(BASE)
	var s := Vector2(win.size)
	if s.x < 1.0 or s.y < 1.0:
		return
	var motor := minf(s.x / BASE.x, s.y / BASE.y)
	win.content_scale_factor = factor(s) / motor


static func aplicar_sonido(main: Node) -> void:
	AudioServer.set_bus_volume_db(0, _db(general))
	var au: Variant = main.get("audio") if main != null else null
	if au != null:
		au.set_volume(true, _db(musica))
		au.set_volume(false, _db(efectos))
		au.set_ambient_volume(_db(ambiente))


static func aplicar_camara(main: Node) -> void:
	var c: Variant = main.get("cam") if main != null else null
	if c != null and is_instance_valid(c) and not bool(main.get("_menu_mode")) and not (main.get("_args") as Dictionary).has("shot"):
		c.edge_pan = bordes


static func aplicar_pantalla() -> void:
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if pantalla_completa else DisplayServer.WINDOW_MODE_MAXIMIZED)


static func _volumen(k: String) -> float:
	return {"general": general, "musica": musica, "efectos": efectos, "ambiente": ambiente}[k]


static func _fijar_volumen(k: String, v: float) -> void:
	match k:
		"general":
			general = v
		"musica":
			musica = v
		"efectos":
			efectos = v
		"ambiente":
			ambiente = v


static func _db(pct: float) -> float:
	return linear_to_db(maxf(pct / 100.0, 0.0001))


# ---------------------------------------------------------------- Diálogo

## Arma el diálogo de opciones dentro de `host` y devuelve el panel: mostrarlo u ocultarlo
## muestra u oculta el fondo oscuro, igual que los diálogos de Hud.
static func dialogo(host: Control, main: Node) -> PanelContainer:
	Hud.load_fonts()
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.5)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	dim.theme = tema()
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dim.add_child(center)
	var pc := PanelContainer.new()
	var sb := Hud.panel_box(10)
	sb.bg_color = Color(0.075, 0.08, 0.09, 0.97)
	sb.content_margin_left = 34
	sb.content_margin_right = 34
	sb.content_margin_top = 24
	sb.content_margin_bottom = 24
	pc.add_theme_stylebox_override("panel", sb)
	center.add_child(pc)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 8)
	pc.add_child(vb)
	var tl := Label.new()
	tl.text = "Opciones"
	tl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tl.add_theme_font_override("font", Hud.font_b)
	tl.add_theme_font_size_override("font_size", 30)
	vb.add_child(tl)

	var cols := HBoxContainer.new()
	cols.add_theme_constant_override("separation", 40)
	vb.add_child(cols)
	var izq := VBoxContainer.new()
	izq.add_theme_constant_override("separation", 8)
	cols.add_child(izq)
	var der := VBoxContainer.new()
	der.add_theme_constant_override("separation", 8)
	cols.add_child(der)

	# Interfaz
	_seccion(izq, "Interfaz")
	var esc := OptionButton.new()
	var win := host.get_window()
	esc.add_item("Automática (%d %%)" % auto_pct(Vector2(win.size)))
	for e in ESCALAS.slice(1):
		esc.add_item("%d %%" % int(e * 100.0))
	esc.selected = maxi(0, ESCALAS.find(escala))
	esc.item_selected.connect(func(i: int) -> void:
		escala = ESCALAS[i]
		aplicar_escala(host.get_window()))
	_fila(izq, "Escala de la interfaz", esc)
	var pal := OptionButton.new()
	for m in Palette.MODOS_ORDEN:
		pal.add_item(Palette.MODOS[m]["nombre"])
	pal.selected = maxi(0, Palette.MODOS_ORDEN.find(paleta))
	_fila(izq, "Colores", pal)
	var muestra := Muestra.new()
	muestra.custom_minimum_size = Vector2(530, 92)
	izq.add_child(muestra)
	pal.item_selected.connect(func(i: int) -> void:
		paleta = Palette.MODOS_ORDEN[i]
		Palette.aplicar(paleta)
		muestra.queue_redraw())
	var barras := _interruptor()
	barras.button_pressed = barras_siempre
	barras.toggled.connect(func(on: bool) -> void: barras_siempre = on)
	_fila(izq, "Barras de vida siempre visibles", barras)

	# Sonido
	_seccion(der, "Sonido")
	var sliders := {}
	for s in [["General", "general"], ["Música", "musica"], ["Efectos", "efectos"], ["Ambiente", "ambiente"]]:
		var key: String = s[1]
		sliders[key] = _deslizador(der, s[0], 0, 100, 5, _volumen(key), "%d %%", func(v: float) -> void:
			_fijar_volumen(key, v)
			aplicar_sonido(main))

	# Cámara
	_seccion(der, "Cámara")
	var borde := _interruptor()
	borde.button_pressed = bordes
	borde.toggled.connect(func(on: bool) -> void:
		bordes = on
		aplicar_camara(main))
	_fila(der, "Mover con los bordes de la pantalla", borde)
	var vel := _deslizador(der, "Velocidad", 50, 200, 10, velocidad_camara, "%d %%", func(v: float) -> void: velocidad_camara = v)

	# Pantalla
	_seccion(der, "Pantalla")
	var fs := _interruptor()
	fs.button_pressed = DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN
	fs.toggled.connect(func(on: bool) -> void:
		pantalla_completa = on
		aplicar_pantalla())
	_fila(der, "Pantalla completa", fs)

	var nota := Label.new()
	nota.text = "Los colores de las unidades y los edificios cambian desde la próxima partida."
	nota.add_theme_font_size_override("font_size", 15)
	nota.add_theme_color_override("font_color", Palette.UI_DIM)
	vb.add_child(nota)

	var botones := HBoxContainer.new()
	botones.alignment = BoxContainer.ALIGNMENT_CENTER
	botones.add_theme_constant_override("separation", 14)
	vb.add_child(botones)
	var rb := Button.new()
	rb.text = "Restablecer"
	rb.custom_minimum_size = Vector2(200, 0)
	botones.add_child(rb)
	var cb := Button.new()
	cb.text = "Cerrar"
	cb.custom_minimum_size = Vector2(200, 0)
	botones.add_child(cb)
	cb.pressed.connect(func() -> void: pc.visible = false)
	rb.pressed.connect(func() -> void:
		restablecer()
		esc.selected = 0
		pal.selected = 0
		barras.button_pressed = false
		borde.button_pressed = true
		fs.button_pressed = false
		for k in sliders:
			(sliders[k] as HSlider).value = 100.0
		vel.value = 100.0
		Palette.aplicar(paleta)
		aplicar_escala(host.get_window())
		aplicar_sonido(main)
		muestra.queue_redraw())

	host.add_child(dim)
	pc.visibility_changed.connect(func() -> void:
		dim.visible = pc.visible
		if not pc.visible:
			guardar()
		else:
			esc.set_item_text(0, "Automática (%d %%)" % auto_pct(Vector2(host.get_window().size)))
			cb.grab_focus())
	pc.visible = false
	dim.visible = false
	return pc


## Interruptor que se lee sin depender del color: dice "Sí" o "No" y cambia de fondo.
static func _interruptor() -> Button:
	var b := Button.new()
	b.toggle_mode = true
	b.custom_minimum_size = Vector2(84, 0)
	b.text = "No"
	b.toggled.connect(func(on: bool) -> void: b.text = "Sí" if on else "No")
	var on := StyleBoxFlat.new()
	on.bg_color = Color(Palette.UI_ACCENT, 0.85)
	on.set_corner_radius_all(6)
	on.content_margin_top = 8
	on.content_margin_bottom = 8
	b.add_theme_stylebox_override("pressed", on)
	b.add_theme_stylebox_override("hover_pressed", on)
	b.add_theme_color_override("font_pressed_color", Color("1a1b1d"))
	b.add_theme_color_override("font_hover_pressed_color", Color("1a1b1d"))
	return b


static func _seccion(vb: VBoxContainer, titulo: String) -> void:
	var l := Label.new()
	l.text = titulo
	l.add_theme_font_override("font", Hud.font_b)
	l.add_theme_font_size_override("font_size", 18)
	l.add_theme_color_override("font_color", Palette.UI_ACCENT)
	if vb.get_child_count() > 0:
		var gap := Control.new()
		gap.custom_minimum_size = Vector2(0, 6)
		vb.add_child(gap)
	vb.add_child(l)


static func _fila(vb: VBoxContainer, texto: String, ctl: Control) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	var l := Label.new()
	l.text = texto
	l.custom_minimum_size = Vector2(250, 0)
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(l)
	ctl.custom_minimum_size.x = maxf(ctl.custom_minimum_size.x, 220 if ctl is OptionButton else 0)
	row.add_child(ctl)
	vb.add_child(row)
	return row


static func _deslizador(vb: VBoxContainer, texto: String, lo: float, hi: float, paso: float, val: float, fmt: String, cb: Callable) -> HSlider:
	var sl := HSlider.new()
	sl.min_value = lo
	sl.max_value = hi
	sl.step = paso
	sl.value = val
	sl.custom_minimum_size = Vector2(170, 28)
	sl.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var v := Label.new()
	v.text = fmt % int(val)
	v.custom_minimum_size = Vector2(56, 0)
	v.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	sl.value_changed.connect(func(x: float) -> void:
		v.text = fmt % int(x)
		cb.call(x))
	var row := _fila(vb, texto, sl)
	row.add_child(v)
	return sl


## Tema propio: el diálogo vive tanto en el HUD como en el menú principal.
static func tema() -> Theme:
	var t := Theme.new()
	t.default_font = Hud.font
	t.default_font_size = 17
	var btn := StyleBoxFlat.new()
	btn.bg_color = Color(1, 1, 1, 0.08)
	btn.set_corner_radius_all(6)
	btn.content_margin_left = 16
	btn.content_margin_right = 16
	btn.content_margin_top = 8
	btn.content_margin_bottom = 8
	btn.border_color = Color(1, 1, 1, 0.12)
	btn.set_border_width_all(1)
	var hov := btn.duplicate() as StyleBoxFlat
	hov.bg_color = Color(1, 1, 1, 0.14)
	var prs := btn.duplicate() as StyleBoxFlat
	prs.bg_color = Color(Palette.UI_ACCENT, 0.3)
	var foc := btn.duplicate() as StyleBoxFlat
	foc.bg_color = Color(0, 0, 0, 0)
	foc.border_color = Palette.UI_ACCENT
	foc.set_border_width_all(2)
	for cls in ["Button", "OptionButton", "CheckButton"]:
		t.set_stylebox("normal", cls, btn if cls != "CheckButton" else StyleBoxEmpty.new())
		t.set_stylebox("hover", cls, hov if cls != "CheckButton" else StyleBoxEmpty.new())
		t.set_stylebox("pressed", cls, prs if cls != "CheckButton" else StyleBoxEmpty.new())
		t.set_stylebox("focus", cls, foc)
		t.set_color("font_color", cls, Palette.UI_TEXT)
		t.set_color("font_hover_color", cls, Color.WHITE)
		t.set_color("font_pressed_color", cls, Color.WHITE)
		t.set_font("font", cls, Hud.font_b)
	t.set_color("font_color", "Label", Palette.UI_TEXT)
	var track := StyleBoxFlat.new()
	track.bg_color = Color(1, 1, 1, 0.16)
	track.set_corner_radius_all(3)
	track.content_margin_top = 3
	track.content_margin_bottom = 3
	var fill := track.duplicate() as StyleBoxFlat
	fill.bg_color = Palette.UI_ACCENT
	t.set_stylebox("slider", "HSlider", track)
	t.set_stylebox("grabber_area", "HSlider", fill)
	t.set_stylebox("grabber_area_highlight", "HSlider", fill)
	t.set_stylebox("panel", "PopupMenu", Hud.panel_box(6))
	t.set_font("font", "PopupMenu", Hud.font)
	t.set_font_size("font_size", "PopupMenu", 17)
	t.set_color("font_color", "PopupMenu", Palette.UI_TEXT)
	t.set_color("font_hover_color", "PopupMenu", Color.WHITE)
	return t


## Muestra de la paleta elegida: equipos con nombre, recursos con su glifo y vida buena y mala.
class Muestra:
	extends Control

	func _draw() -> void:
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color(0, 0, 0, 0.25)
		sb.set_corner_radius_all(6)
		draw_style_box(sb, Rect2(Vector2.ZERO, size))
		var x := 12.0
		for i in 4:
			var col: Color = Palette.team(i) if Palette.modo != "relativa" else [Palette.RELATIVA["yo"], Palette.RELATIVA["aliado"], Palette.RELATIVA["rival"], Palette.RELATIVA["rival"]][i]
			var nombre: String = Palette.TEAM_NAMES[i] if Palette.modo != "relativa" else ["Vos", "Aliado", "Rival", "Rival"][i]
			draw_rect(Rect2(x, 12, 26, 26), col)
			draw_string(Hud.font, Vector2(x + 32, 31), nombre, HORIZONTAL_ALIGNMENT_LEFT, 74, 15, Palette.UI_TEXT)
			x += 106
		x = 12.0
		for k in Sim.RES_KINDS:
			Glyphs.draw(self, k, Rect2(x, 50, 28, 28), Palette.RES[k])
			draw_string(Hud.font, Vector2(x + 32, 70), Palette.RES_NAMES[k], HORIZONTAL_ALIGNMENT_LEFT, 74, 15, Palette.UI_TEXT)
			x += 106
		var bw := 70.0
		var bx := size.x - bw - 14
		draw_rect(Rect2(bx, 16, bw, 8), Color(0, 0, 0, 0.5))
		draw_rect(Rect2(bx, 16, bw * 0.9, 8), Palette.UI_GOOD)
		draw_rect(Rect2(bx, 34, bw, 8), Color(0, 0, 0, 0.5))
		draw_rect(Rect2(bx, 34, bw * 0.2, 8), Palette.UI_BAD)
		draw_string(Hud.font, Vector2(bx, 66), "Vida", HORIZONTAL_ALIGNMENT_LEFT, bw, 15, Palette.UI_DIM)
