extends Control
## La Guía (G). Dos partes:
##   - Lecciones (proceso/36-aprendizaje): una por mecánica, cortas y opcionales, en
##     data/lecciones.json. Están en toda partida; el botón «¿Cómo se usa?» del panel de la
##     selección abre la que corresponde a lo elegido.
##   - Registro (proceso/23-como-aoe4/03-aprender-a-jugar.md), solo en campañas: los mensajes
##     de la Guía se van, pero acá quedan para releerlos. El botón «Releer la guía» aparece
##     debajo de los objetivos cuando hubo algún mensaje.

const LECCIONES := "res://data/lecciones.json"

var hud # Hud
var mensajes: Array[Dictionary] = [] # {t: segundos, quien, texto}
var max_msgs := 60
var boton: Button
var boton_como: Button # «¿Cómo se usa?», sobre el panel de la selección
var _panel: PanelContainer
var _lista: VBoxContainer
var _scroll: ScrollContainer
var _tab_lec: Button
var _tab_reg: Button
var _lecciones_box: HBoxContainer
var _indice: VBoxContainer
var _cuerpo: VBoxContainer
var _tab := "lecciones"
var _actual := ""
var _resaltar: Array = []
var _como_ids: Array = [] # lecciones de la selección de ahora

static var _data: Dictionary = {}


static func data() -> Dictionary:
	if _data.is_empty() and FileAccess.file_exists(LECCIONES):
		_data = JSON.parse_string(FileAccess.get_file_as_string(LECCIONES))
	return _data


## Reemplaza los marcadores {reglas:a.b}, {casillas:a.b}, {min:a.b} y {edad:a.b} por los
## valores de data/reglas.json (así el texto sigue al balance).
static func texto(s: String, reglas: Dictionary) -> String:
	var re := RegEx.create_from_string("\\{(reglas|casillas|min|edad):([a-z0-9_.]+)\\}")
	var out := s
	for m in re.search_all(s):
		var v: Variant = reglas
		for k in m.get_string(2).split("."):
			v = (v as Dictionary).get(k, null) if v is Dictionary else null
		if v == null:
			continue
		var n := int(v)
		var rep := str(n)
		match m.get_string(1):
			"casillas":
				rep = str(n / 1000)
			"min":
				rep = str(n / 60000)
			"edad":
				rep = ["0", "I", "II", "III", "IV", "V"][clampi(n, 0, 5)]
		out = out.replace(m.get_string(0), rep)
	return out


func setup(h) -> void:
	hud = h
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var path := "res://data/interfaz.json"
	if FileAccess.file_exists(path):
		max_msgs = int((JSON.parse_string(FileAccess.get_file_as_string(path)) as Dictionary).get("guia", {}).get("registro_max", 60))
	boton = Button.new()
	boton.text = "Releer la guía  G"
	boton.focus_mode = Control.FOCUS_NONE
	boton.add_theme_font_size_override("font_size", 14)
	boton.visible = false
	boton.pressed.connect(func() -> void: abrir("registro"))
	add_child(boton)
	boton_como = Button.new()
	boton_como.text = "¿Cómo se usa?"
	boton_como.tooltip_text = "Abre la lección de la Guía (G) sobre lo que elegiste"
	boton_como.focus_mode = Control.FOCUS_NONE
	boton_como.add_theme_font_size_override("font_size", 13)
	boton_como.visible = false
	boton_como.pressed.connect(func() -> void:
		if not _como_ids.is_empty():
			abrir_leccion(_como_ids[0], _como_ids))
	add_child(boton_como)
	_panel = PanelContainer.new()
	var sb := Hud.panel_box(10)
	sb.bg_color = Color(0.07, 0.075, 0.085, 0.97)
	sb.content_margin_left = 26
	sb.content_margin_right = 26
	sb.content_margin_top = 18
	sb.content_margin_bottom = 18
	_panel.add_theme_stylebox_override("panel", sb)
	Hud._anchor(_panel, Vector2(0.5, 0.5), Rect2(-430, -300, 860, 600))
	_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 10)
	_panel.add_child(vb)
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 14)
	vb.add_child(top)
	var tl := Label.new()
	tl.text = "La Guía"
	tl.add_theme_font_override("font", Hud.font_b)
	tl.add_theme_font_size_override("font_size", 24)
	tl.add_theme_color_override("font_color", Palette.UI_ACCENT)
	top.add_child(tl)
	_tab_lec = _tab_button("Lecciones", "lecciones")
	top.add_child(_tab_lec)
	_tab_reg = _tab_button("Lo que dijo la Guía", "registro")
	_tab_reg.visible = hud.sim.scenario != null
	top.add_child(_tab_reg)
	# Lecciones: índice a la izquierda, la lección a la derecha.
	_lecciones_box = HBoxContainer.new()
	_lecciones_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_lecciones_box.add_theme_constant_override("separation", 18)
	vb.add_child(_lecciones_box)
	_indice = VBoxContainer.new()
	_indice.custom_minimum_size = Vector2(250, 0)
	_indice.add_theme_constant_override("separation", 4)
	_lecciones_box.add_child(_indice)
	var d := data()
	for id in d.get("orden", []):
		var lec: Dictionary = d.get("lecciones", {}).get(id, {})
		if lec.is_empty():
			continue
		var b := Button.new()
		b.text = String(lec.get("titulo", id))
		b.name = "lec_" + String(id)
		b.toggle_mode = true
		b.focus_mode = Control.FOCUS_NONE
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.add_theme_font_size_override("font_size", 15)
		b.pressed.connect(abrir_leccion.bind(String(id), []))
		_indice.add_child(b)
	var cs := ScrollContainer.new()
	cs.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cs.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_lecciones_box.add_child(cs)
	_cuerpo = VBoxContainer.new()
	_cuerpo.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_cuerpo.add_theme_constant_override("separation", 8)
	cs.add_child(_cuerpo)
	# Registro de mensajes (campañas).
	_scroll = ScrollContainer.new()
	_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	vb.add_child(_scroll)
	_lista = VBoxContainer.new()
	_lista.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_lista.add_theme_constant_override("separation", 12)
	_scroll.add_child(_lista)
	var cb := Button.new()
	cb.text = "Cerrar (G)"
	cb.focus_mode = Control.FOCUS_NONE
	cb.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	cb.custom_minimum_size = Vector2(200, 0)
	cb.pressed.connect(toggle)
	vb.add_child(cb)
	_panel.visible = false
	add_child(_panel)


func _tab_button(txt: String, tab: String) -> Button:
	var b := Button.new()
	b.text = txt
	b.toggle_mode = true
	b.focus_mode = Control.FOCUS_NONE
	b.add_theme_font_size_override("font_size", 15)
	b.pressed.connect(func() -> void:
		_tab = tab
		_rebuild())
	return b


func add(ev: Dictionary) -> void:
	mensajes.append({"t": hud.sim.tick * hud.sim.tick_ms / 1000, "quien": str(ev.get("quien", "")), "texto": str(ev.get("texto", ""))})
	while mensajes.size() > max_msgs:
		mensajes.pop_front()
	boton.visible = true
	if _panel.visible:
		_rebuild()


func is_open() -> bool:
	return _panel.visible


## Controles que tapan el mapa (para `Hud.blocks`).
func blockers() -> Array[Control]:
	return [boton, boton_como, _panel]


## G: en campañas con mensajes abre el registro la primera vez; si no, las lecciones.
func toggle() -> void:
	if _panel.visible:
		_panel.visible = false
		return
	if _actual == "" and _tab == "lecciones" and not mensajes.is_empty():
		_tab = "registro"
	_mostrar()


func abrir(tab: String) -> void:
	_tab = tab
	_mostrar()


## Abre la lección `id`; `resaltar` marca en el índice las otras que tocan a la selección.
func abrir_leccion(id: String, resaltar: Array = []) -> void:
	_actual = id
	if not resaltar.is_empty():
		_resaltar = resaltar
	_tab = "lecciones"
	_mostrar()


func _mostrar() -> void:
	if _actual == "":
		_actual = String((data().get("orden", [""]) as Array)[0])
	_panel.visible = true
	_rebuild()
	move_to_front()


func _rebuild() -> void:
	if _tab == "registro" and hud.sim.scenario == null:
		_tab = "lecciones"
	_tab_lec.button_pressed = _tab == "lecciones"
	_tab_reg.button_pressed = _tab == "registro"
	_lecciones_box.visible = _tab == "lecciones"
	_scroll.visible = _tab == "registro"
	if _tab == "lecciones":
		_rebuild_leccion()
	else:
		_rebuild_registro()


func _rebuild_leccion() -> void:
	for b: Button in _indice.get_children():
		var id := String(b.name).substr(4)
		b.button_pressed = id == _actual
		b.add_theme_color_override("font_color", Palette.UI_ACCENT if id in _resaltar else Palette.UI_TEXT)
	for c in _cuerpo.get_children():
		c.queue_free()
	var lec: Dictionary = data().get("lecciones", {}).get(_actual, {})
	if lec.is_empty():
		return
	var reglas: Dictionary = hud.sim.data.reglas
	var t := Label.new()
	t.text = String(lec.get("titulo", _actual))
	t.add_theme_font_override("font", Hud.font_b)
	t.add_theme_font_size_override("font_size", 21)
	t.add_theme_color_override("font_color", Palette.UI_ACCENT)
	_cuerpo.add_child(t)
	for par in [["Qué es", "que"], ["Cuándo conviene", "cuando"], ["Un consejo", "consejo"]]:
		var h := Label.new()
		h.text = par[0]
		h.add_theme_font_override("font", Hud.font_b)
		h.add_theme_font_size_override("font_size", 14)
		h.add_theme_color_override("font_color", Palette.UI_DIM)
		_cuerpo.add_child(h)
		var p := Label.new()
		p.text = texto(String(lec.get(par[1], "")), reglas)
		p.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		p.custom_minimum_size = Vector2(500, 0)
		p.add_theme_font_size_override("font_size", 17)
		_cuerpo.add_child(p)


func _rebuild_registro() -> void:
	for c in _lista.get_children():
		c.queue_free()
	if mensajes.is_empty():
		var l := Label.new()
		l.text = "Todavía no hubo mensajes."
		l.add_theme_color_override("font_color", Palette.UI_DIM)
		_lista.add_child(l)
	# El más nuevo arriba: lo que se busca casi siempre es lo último.
	for i in range(mensajes.size() - 1, -1, -1):
		var m: Dictionary = mensajes[i]
		var who := Label.new()
		who.text = "%s · %s" % [Hud._fmt_time(int(m["t"])), m["quien"]]
		who.add_theme_font_override("font", Hud.font_b)
		who.add_theme_font_size_override("font_size", 14)
		who.add_theme_color_override("font_color", Palette.UI_ACCENT if i == mensajes.size() - 1 else Palette.UI_DIM)
		_lista.add_child(who)
		var txt := Label.new()
		txt.text = m["texto"]
		txt.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		txt.custom_minimum_size = Vector2(780, 0)
		txt.add_theme_font_size_override("font_size", 17)
		_lista.add_child(txt)
	_scroll.scroll_vertical = 0


## Debajo del panel de objetivos (su alto cambia con la cantidad de objetivos).
func place_button(below: float) -> void:
	boton.position = Vector2(12, below + 6)
	boton.size = Vector2(190, 30)


# ---------------------------------------------------------------- ¿Cómo se usa?

## Lecciones que tocan a una entidad, en el orden del índice.
static func lecciones_de(sim: Sim, e: SimEntity) -> Array:
	var flags := {e.type: true}
	var def: Dictionary = e.def
	if e.is_building():
		for u in def.get("produce", []):
			var ud: Dictionary = sim.dp(maxi(e.owner, 0)).unidades.get(u, {}) if e.owner >= 0 else {}
			var fn := String(ud.get("funcion", ud.get("fn", "")))
			if u == "aldeano" or fn == "civil":
				flags["produce_aldeano"] = true
			elif u != "comerciante":
				flags["produce_tropa"] = true
		if def.get("mercado", false):
			flags["mercado"] = true
		if def.get("sagrado", false):
			flags["sagrado"] = true
		if def.get("maravilla", false):
			flags["maravilla"] = true
		if def.has("su_puerta") or def.has("sobre") or e.type in ["empalizada", "puerta"]:
			flags["muro"] = true
	elif e.is_unit():
		if def.has("area"):
			flags["area"] = true
		if e.fn == "civil":
			flags["aldeano"] = true
		elif e.fn in ["choque", "distancia", "linea"]:
			flags["tropa"] = true
	var out := []
	var d := data()
	for id in d.get("orden", []):
		for f in (d.get("lecciones", {}).get(id, {}) as Dictionary).get("para", []):
			if flags.has(f):
				out.append(String(id))
				break
	return out


func _process(_d: float) -> void:
	var sel: Array = hud.ctrl.selected_entities()
	var sp: Control = hud.get("_sel")
	if sel.is_empty() or sp == null or not sp.visible or _panel.visible:
		boton_como.visible = false
		return
	var e: SimEntity = sel[0]
	if e.is_resource():
		boton_como.visible = false
		return
	_como_ids = lecciones_de(hud.sim, e)
	boton_como.visible = not _como_ids.is_empty()
	if boton_como.visible:
		var r := sp.get_global_rect()
		boton_como.size = Vector2(124, 26)
		boton_como.position = Vector2(r.end.x - 132, r.end.y - 34)


func _unhandled_key_input(event: InputEvent) -> void:
	var k := event as InputEventKey
	if k == null or not k.pressed or k.echo or not hud.is_visible_in_tree():
		return
	# G mientras se arrastra un muro pone la puerta (controller): no abre la Guía.
	if Teclas.es(k.physical_keycode, "guia") and hud.ctrl.get("_line_drag"):
		return
	if Teclas.es(k.physical_keycode, "guia") or (k.physical_keycode == KEY_ESCAPE and _panel.visible):
		toggle()
		get_viewport().set_input_as_handled()
