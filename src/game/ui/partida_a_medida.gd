class_name PartidaAMedida
extends Control
## --- partida a medida --- (proceso/31) Pantalla «Partida personalizada», como la de AoE:
## el mapa, un renglón por jugador (de 2 a 8: tipo, pueblo, dificultad, estilo, equipo y color),
## las opciones de partida y presets rápidos (1v1, 1v3, 1v6, 2v2, 4v4, todos contra todos).
## Recuerda la última configuración en user://partida_a_medida.json (PartidaConfig).

signal empezar(args: Dictionary)
signal volver

var cfg: Dictionary
var _data: SimData
var _civ_keys: Array = []
var _dif_keys: Array = []
var _sty_keys: Array = []
var _map_keys: Array = []
var _tiempos: Array = []
var _rows: Array = [] # por renglón: {dot, tipo, civ, dif, sty, eq, col}
var _terreno: OptionButton
var _tamano: OptionButton
var _recursos: OptionButton
var _semilla: LineEdit
var _sitios: CheckButton
var _hitos: CheckButton
var _maravilla: CheckButton
var _tiempo: OptionButton
var _ubic: OptionButton
var _estado: Label
var _go: Button
var _quieto := false # mientras se rellenan los controles desde cfg

const TIPOS_NOMBRE := ["Vos", "IA", "Cerrado"]
const TAMANOS_NOMBRE := ["Chico", "Normal", "Grande"]
const RECURSOS := [["normal", "Normales"], ["medios", "Medios"], ["altos", "Altos"]]
const UBICACION := [["juntos", "Aliados juntos"], ["mezclados", "Aliados mezclados"]]


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_data = SimData.load_default()
	_civ_keys = _data.civs.keys().filter(func(k: String) -> bool: return not _data.civs[k].civ.get("solo_ia", false))
	_civ_keys.sort()
	_dif_keys = _data.reglas["dificultades"].keys()
	_sty_keys = _data.reglas["estilos_ia"].keys()
	_map_keys = _data.reglas["terrenos"].keys()
	_tiempos = _data.reglas["opciones_partida"]["tiempo_limite_min"]
	cfg = PartidaConfig.cargar()

	var dim := ColorRect.new()
	dim.color = Color(0.02, 0.025, 0.03, 0.82)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var panel := PanelContainer.new()
	var sb := Hud.panel_box(10)
	sb.content_margin_left = 18
	sb.content_margin_right = 18
	sb.content_margin_top = 12
	sb.content_margin_bottom = 12
	panel.add_theme_stylebox_override("panel", sb)
	center.add_child(panel)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 7)
	panel.add_child(col)

	var title := Label.new()
	title.text = "Partida personalizada"
	title.add_theme_font_override("font", Hud.font_b)
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", Palette.UI_ACCENT)
	col.add_child(title)

	# Presets rápidos
	var prow := _row(col)
	prow.add_child(_label("Rápido", 80))
	for k in PartidaConfig.PRESETS_ORDEN:
		var b := _small_button(PartidaConfig.PRESETS_NOMBRE[k], func() -> void: _preset(k))
		b.tooltip_text = "Vos contra %s en equipo" % k.substr(2) if k in ["1v3", "1v6"] else ""
		prow.add_child(b)

	# Mapa
	var mrow := _row(col)
	mrow.add_child(_label("Mapa", 80))
	var tnames: Array = ["Al azar"]
	for k in _map_keys:
		tnames.append(_data.reglas["terrenos"][k]["nombre"])
	_terreno = _ob(tnames, 170)
	for i in _map_keys.size():
		_terreno.set_item_tooltip(i + 1, _data.reglas["terrenos"][_map_keys[i]].get("descripcion", ""))
	mrow.add_child(_terreno)
	mrow.add_child(_label("Tamaño", 60))
	_tamano = _ob(TAMANOS_NOMBRE, 100)
	_tamano.tooltip_text = "Con 3 o más jugadores. El 1 contra 1 se juega siempre en el mapa de dos."
	mrow.add_child(_tamano)
	mrow.add_child(_label("Recursos", 70))
	_recursos = _ob(RECURSOS.map(func(r: Array) -> String: return r[1]), 110)
	mrow.add_child(_recursos)
	mrow.add_child(_label("Semilla", 60))
	_semilla = LineEdit.new()
	_semilla.placeholder_text = "al azar"
	_semilla.custom_minimum_size = Vector2(100, 30)
	_semilla.add_theme_font_override("font", Hud.font)
	mrow.add_child(_semilla)
	mrow.add_child(_small_button("Al azar", func() -> void:
		_semilla.text = ""
		_leer()))

	# Jugadores
	var head := _row(col)
	for h in [["", 6], ["", 70], ["Tipo", 100], ["Pueblo", 160], ["Dificultad", 110], ["Estilo", 125], ["Equipo", 110], ["Color", 120]]:
		var l := _label(h[0], h[1])
		l.add_theme_font_size_override("font_size", 13)
		head.add_child(l)
	var civ_names: Array = ["Al azar"]
	for k in _civ_keys:
		civ_names.append(_data.civs[k].civ.get("nombre", k))
	var dif_names: Array = _dif_keys.map(func(k: String) -> String: return _data.reglas["dificultades"][k]["nombre"])
	var sty_names: Array = _sty_keys.map(func(k: String) -> String: return _data.reglas["estilos_ia"][k]["nombre"])
	var eq_names: Array = ["Sin equipo", "Equipo 1", "Equipo 2", "Equipo 3", "Equipo 4"]
	for i in PartidaConfig.MAX:
		var r := _row(col)
		var dot := ColorRect.new()
		dot.custom_minimum_size = Vector2(6, 26)
		r.add_child(dot)
		r.add_child(_label("Jugador %d" % (i + 1), 70))
		var w := {"dot": dot, "tipo": _ob(TIPOS_NOMBRE, 100), "civ": _ob(civ_names, 160), "dif": _ob(dif_names, 110), "sty": _ob(sty_names, 125), "eq": _ob(eq_names, 110), "col": _ob([], 120)}
		for c in Palette.TEAM.size():
			(w["col"] as OptionButton).add_icon_item(_swatch(Palette.TEAM[c]), Palette.TEAM_NAMES[c])
		for k in ["tipo", "civ", "dif", "sty", "eq", "col"]:
			r.add_child(w[k])
		(w["tipo"] as OptionButton).item_selected.connect(func(t: int) -> void: _tipo(i, t))
		(w["col"] as OptionButton).item_selected.connect(func(c: int) -> void: _color(i, c))
		for k in ["civ", "dif", "sty", "eq"]:
			(w[k] as OptionButton).item_selected.connect(func(_x: int) -> void: _leer())
		_rows.append(w)

	# Opciones de partida
	var sep := HSeparator.new()
	col.add_child(sep)
	var orow := _row(col)
	orow.add_child(_label("Victoria", 80))
	_sitios = _check("Sitios sagrados", "Gana quien tiene todos los sitios sagrados el tiempo que pide reglas.json.")
	_hitos = _check("Hitos", "Pierde quien se queda sin capital ni hitos. Apagado: hay que arrasar todo.")
	_maravilla = _check("Maravilla", "Gana quien mantiene en pie su maravilla de la edad IV.")
	for c in [_sitios, _hitos, _maravilla]:
		orow.add_child(c)
	var orow2 := _row(col)
	orow2.add_child(_label("Tiempo límite", 100))
	_tiempo = _ob(_tiempos.map(func(m: Variant) -> String: return "Sin límite" if int(m) == 0 else "%d minutos" % int(m)), 130)
	orow2.add_child(_tiempo)
	orow2.add_child(_label("Ubicación", 80))
	_ubic = _ob(UBICACION.map(func(u: Array) -> String: return u[1]), 170)
	_ubic.tooltip_text = "Dónde arranca cada aliado en el círculo de bases: al lado o alternados con los rivales."
	orow2.add_child(_ubic)
	for ob: OptionButton in [_terreno, _tamano, _recursos, _tiempo, _ubic]:
		ob.item_selected.connect(func(_x: int) -> void: _leer())
	for cb: CheckButton in [_sitios, _hitos, _maravilla]:
		cb.toggled.connect(func(_b: bool) -> void: _leer())
	_semilla.text_changed.connect(func(_t: String) -> void: _leer())

	_estado = Label.new()
	_estado.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_estado.custom_minimum_size = Vector2(860, 0)
	_estado.add_theme_font_override("font", Hud.font)
	_estado.add_theme_font_size_override("font_size", 14)
	col.add_child(_estado)
	var brow := _row(col)
	brow.alignment = BoxContainer.ALIGNMENT_END
	brow.add_child(_small_button("Volver", func() -> void: volver.emit()))
	_go = _small_button("Empezar", _empezar)
	_go.custom_minimum_size = Vector2(160, 38)
	_go.add_theme_font_override("font", Hud.font_b)
	brow.add_child(_go)
	_poner()


## Controles ← cfg.
func _poner() -> void:
	_quieto = true
	_terreno.selected = _map_keys.find(str(cfg["terreno"])) + 1
	_tamano.selected = maxi(0, PartidaConfig.TAMANOS.find(str(cfg["tamano"])))
	_recursos.selected = maxi(0, RECURSOS.map(func(r: Array) -> String: return r[0]).find(str(cfg["recursos"])))
	_semilla.text = "" if int(cfg["semilla"]) < 0 else str(int(cfg["semilla"]))
	_sitios.button_pressed = bool(cfg["sitios"])
	_hitos.button_pressed = bool(cfg["hitos"])
	_maravilla.button_pressed = bool(cfg["maravilla"])
	_tiempo.selected = maxi(0, _tiempos.find(int(cfg["tiempo"])))
	_ubic.selected = maxi(0, UBICACION.map(func(u: Array) -> String: return u[0]).find(str(cfg["ubicacion"])))
	var cols := PartidaConfig.colores(cfg["jugadores"])
	for i in PartidaConfig.MAX:
		var j: Dictionary = cfg["jugadores"][i]
		j["color"] = cols[i]
		var w: Dictionary = _rows[i]
		(w["tipo"] as OptionButton).selected = maxi(0, PartidaConfig.TIPOS.find(str(j["tipo"])))
		(w["civ"] as OptionButton).selected = _civ_keys.find(str(j["civ"])) + 1
		(w["dif"] as OptionButton).selected = maxi(0, _dif_keys.find(str(j["dificultad"])))
		(w["sty"] as OptionButton).selected = maxi(0, _sty_keys.find(str(j["estilo"])))
		(w["eq"] as OptionButton).selected = clampi(int(j["equipo"]), 0, 4)
		(w["col"] as OptionButton).selected = int(j["color"])
	_quieto = false
	_refrescar()


## cfg ← controles.
func _leer() -> void:
	if _quieto:
		return
	cfg["terreno"] = "" if _terreno.selected <= 0 else str(_map_keys[_terreno.selected - 1])
	cfg["tamano"] = PartidaConfig.TAMANOS[maxi(0, _tamano.selected)]
	cfg["recursos"] = RECURSOS[maxi(0, _recursos.selected)][0]
	cfg["semilla"] = int(_semilla.text) if _semilla.text.strip_edges().is_valid_int() else -1
	cfg["sitios"] = _sitios.button_pressed
	cfg["hitos"] = _hitos.button_pressed
	cfg["maravilla"] = _maravilla.button_pressed
	cfg["tiempo"] = int(_tiempos[maxi(0, _tiempo.selected)])
	cfg["ubicacion"] = UBICACION[maxi(0, _ubic.selected)][0]
	for i in PartidaConfig.MAX:
		var j: Dictionary = cfg["jugadores"][i]
		var w: Dictionary = _rows[i]
		var c := (w["civ"] as OptionButton).selected
		j["civ"] = "azar" if c <= 0 else str(_civ_keys[c - 1])
		j["dificultad"] = str(_dif_keys[maxi(0, (w["dif"] as OptionButton).selected)])
		j["estilo"] = str(_sty_keys[maxi(0, (w["sty"] as OptionButton).selected)])
		j["equipo"] = (w["eq"] as OptionButton).selected
	_refrescar()


func _tipo(i: int, t: int) -> void:
	if _quieto:
		return
	cfg["jugadores"][i]["tipo"] = PartidaConfig.TIPOS[t]
	if PartidaConfig.TIPOS[t] == "vos": # un solo «Vos»: el anterior pasa a IA
		for k in PartidaConfig.MAX:
			if k != i and cfg["jugadores"][k]["tipo"] == "vos":
				cfg["jugadores"][k]["tipo"] = "ia"
	_leer()
	_poner()


## Color sin repetir: si otro lo tenía, se queda con el de este renglón.
func _color(i: int, c: int) -> void:
	if _quieto:
		return
	var old := int(cfg["jugadores"][i]["color"])
	for k in PartidaConfig.MAX:
		if k != i and int(cfg["jugadores"][k]["color"]) == c:
			cfg["jugadores"][k]["color"] = old
	cfg["jugadores"][i]["color"] = c
	_poner()


func _preset(nombre: String) -> void:
	_leer()
	PartidaConfig.aplicar_preset(cfg, nombre)
	_poner()


## Renglones cerrados apagados, «Vos» sin dificultad ni estilo, ubicación solo con aliados y
## una línea que dice la partida o por qué no se puede jugar.
func _refrescar() -> void:
	var abiertos := 0
	var equipos := {}
	var con_aliados := false
	for i in PartidaConfig.MAX:
		var j: Dictionary = cfg["jugadores"][i]
		var w: Dictionary = _rows[i]
		var cerrado: bool = j["tipo"] == "cerrado"
		var ia: bool = j["tipo"] == "ia"
		(w["dot"] as ColorRect).color = Color(Palette.TEAM[int(j["color"]) % Palette.TEAM.size()], 0.25 if cerrado else 1.0)
		for k in ["civ", "eq", "col"]:
			(w[k] as OptionButton).disabled = cerrado
		for k in ["dif", "sty"]:
			(w[k] as OptionButton).disabled = not ia
		if not cerrado:
			abiertos += 1
			var e := int(j["equipo"])
			if e > 0 and equipos.has(e):
				con_aliados = true
			equipos[e if e > 0 else 10 + i] = true
	_ubic.disabled = not con_aliados
	_tamano.disabled = abiertos <= 2
	var err := PartidaConfig.problema(cfg)
	_go.disabled = err != ""
	if err != "":
		_estado.text = err
		_estado.add_theme_color_override("font_color", Palette.UI_BAD)
	else:
		var a := PartidaConfig.a_args(cfg)
		var txt := "%d jugadores · %s" % [abiertos, "todos contra todos" if equipos.size() == abiertos else "%d equipos" % equipos.size()]
		if a.has("aivai"):
			txt += " · sin «Vos»: mirás IA contra IA"
		_estado.text = txt + "."
		_estado.add_theme_color_override("font_color", Palette.UI_DIM)


func _empezar() -> void:
	_leer()
	if PartidaConfig.problema(cfg) != "":
		return
	PartidaConfig.guardar(cfg)
	empezar.emit(PartidaConfig.a_args(cfg))


func _unhandled_key_input(event: InputEvent) -> void:
	var k := event as InputEventKey
	if k != null and k.pressed and k.keycode == KEY_ESCAPE and is_visible_in_tree():
		volver.emit()
		get_viewport().set_input_as_handled()


# ---------------------------------------------------------------- piezas

func _row(parent: Control) -> HBoxContainer:
	var r := HBoxContainer.new()
	r.add_theme_constant_override("separation", 6)
	parent.add_child(r)
	return r


func _label(t: String, w: float) -> Label:
	var l := Label.new()
	l.text = t
	l.custom_minimum_size = Vector2(w, 0)
	l.add_theme_font_override("font", Hud.font)
	l.add_theme_color_override("font_color", Palette.UI_DIM)
	return l


func _ob(items: Array, w: float) -> OptionButton:
	var ob := OptionButton.new()
	ob.custom_minimum_size = Vector2(w, 30)
	ob.add_theme_font_override("font", Hud.font)
	ob.add_theme_font_size_override("font_size", 14)
	ob.fit_to_longest_item = false
	ob.clip_text = true
	for it in items:
		ob.add_item(it)
	return ob


func _check(text: String, tip: String) -> CheckButton:
	var cb := CheckButton.new()
	cb.text = text
	cb.tooltip_text = tip
	cb.add_theme_font_override("font", Hud.font)
	cb.add_theme_font_size_override("font_size", 14)
	Opciones.interruptor_en(cb)
	return cb


func _small_button(text: String, cb: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(0, 32)
	b.add_theme_font_override("font", Hud.font)
	b.add_theme_font_size_override("font_size", 14)
	var n := StyleBoxFlat.new()
	n.bg_color = Color(1, 1, 1, 0.07)
	n.set_corner_radius_all(5)
	n.content_margin_left = 10
	n.content_margin_right = 10
	n.border_color = Color(1, 1, 1, 0.08)
	n.set_border_width_all(1)
	var h := n.duplicate() as StyleBoxFlat
	h.bg_color = Color(Palette.UI_ACCENT, 0.22)
	h.border_color = Color(Palette.UI_ACCENT, 0.6)
	b.add_theme_stylebox_override("normal", n)
	b.add_theme_stylebox_override("hover", h)
	b.add_theme_stylebox_override("pressed", h)
	b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	b.add_theme_color_override("font_color", Palette.UI_TEXT)
	b.pressed.connect(cb)
	return b


static func _swatch(c: Color) -> ImageTexture:
	var img := Image.create(14, 14, false, Image.FORMAT_RGBA8)
	img.fill(c)
	return ImageTexture.create_from_image(img)
