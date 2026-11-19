class_name SalaRed
extends Control
## La sala «Red» del menú (proceso/37): crear (puerto) o unirse (IP y puerto), pueblo y
## color de cada uno, mapa y opciones del anfitrión, listo y empezar. La partida se arma con
## la partida a medida (PartidaConfig.a_args) en SesionRed.empezar_partida().

signal empezar(args: Dictionary)
signal volver

var _data: SimData
var _civ_keys: Array = []
var _map_keys: Array = []
var _s: SesionRed = null
var _estado: Label
var _puerto_crear: LineEdit
var _ip: LineEdit
var _puerto_unir: LineEdit
var _filas: Array = [] # [civ, color, listo] por jugador
var _terreno: OptionButton
var _sitios: CheckButton
var _hitos: CheckButton
var _maravilla: CheckButton
var _semilla: LineEdit
var _empezar: Button
var _conexion: Control
var _juego: Control


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_data = SimData.load_default()
	_civ_keys = _data.civs.keys().filter(func(k: String) -> bool: return not _data.civs[k].civ.get("solo_ia", false))
	_civ_keys.sort()
	_map_keys = _data.reglas["terrenos"].keys()
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
	col.add_theme_constant_override("separation", 8)
	col.custom_minimum_size = Vector2(560, 0)
	panel.add_child(col)

	var title := Label.new()
	title.text = "Red · 1 contra 1"
	title.add_theme_font_override("font", Hud.font_b)
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", Palette.UI_ACCENT)
	col.add_child(title)

	# Conexión
	var puerto := str(_cfg_puerto())
	_conexion = VBoxContainer.new()
	col.add_child(_conexion)
	var crow := _row(_conexion)
	crow.add_child(_label("Crear", 70))
	crow.add_child(_label("Puerto", 60))
	_puerto_crear = _edit(puerto, 90)
	crow.add_child(_puerto_crear)
	crow.add_child(_boton("Crear sala", _crear))
	var urow := _row(_conexion)
	urow.add_child(_label("Unirse", 70))
	urow.add_child(_label("IP", 60))
	_ip = _edit("127.0.0.1", 150)
	urow.add_child(_ip)
	urow.add_child(_label("Puerto", 60))
	_puerto_unir = _edit(puerto, 90)
	urow.add_child(_puerto_unir)
	urow.add_child(_boton("Unirse", _unirse))

	_estado = _label("Creá una sala o unite a la de otro.", 520)
	_estado.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	col.add_child(_estado)

	# Jugadores y opciones (con la sala abierta)
	_juego = VBoxContainer.new()
	(_juego as VBoxContainer).add_theme_constant_override("separation", 8)
	_juego.visible = false
	col.add_child(_juego)
	var civ_names: Array = ["Al azar"]
	for k in _civ_keys:
		civ_names.append(_data.civs[k].civ.get("nombre", k))
	for i in 2:
		var r := _row(_juego)
		r.add_child(_label("Anfitrión" if i == 0 else "Invitado", 90))
		var civ := _ob(civ_names, 190)
		var color := _ob(Palette.TEAM_NAMES.slice(0, PartidaConfig.MAX), 120)
		color.select(i)
		var listo := _check("Listo")
		r.add_child(civ)
		r.add_child(color)
		r.add_child(listo)
		civ.item_selected.connect(func(_x: int) -> void: _mio())
		color.item_selected.connect(func(_x: int) -> void: _mio())
		listo.toggled.connect(func(_x: bool) -> void: _mio())
		_filas.append([civ, color, listo])
	var mrow := _row(_juego)
	mrow.add_child(_label("Mapa", 90))
	var tnames: Array = ["Al azar"]
	for k in _map_keys:
		tnames.append(_data.reglas["terrenos"][k]["nombre"])
	_terreno = _ob(tnames, 190)
	mrow.add_child(_terreno)
	mrow.add_child(_label("Semilla", 70))
	_semilla = _edit("", 100)
	_semilla.placeholder_text = "al azar"
	mrow.add_child(_semilla)
	var orow := _row(_juego)
	orow.add_child(_label("Victoria", 90))
	_sitios = _check("Sitios")
	_hitos = _check("Hitos")
	_maravilla = _check("Maravilla")
	for cb: CheckButton in [_sitios, _hitos, _maravilla]:
		cb.button_pressed = true
		orow.add_child(cb)
		cb.toggled.connect(func(_x: bool) -> void: _opciones())
	_terreno.item_selected.connect(func(_x: int) -> void: _opciones())
	_semilla.text_changed.connect(func(_x: String) -> void: _opciones())
	var nota := _label("En red cada uno tiene 3 pausas de 60 s (Esc). Si alguien se cae, el otro lo espera 60 s.", 520)
	nota.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	nota.add_theme_font_size_override("font_size", 13)
	_juego.add_child(nota)

	var brow := _row(col)
	_empezar = _boton("Empezar", func() -> void:
		if _s != null:
			_s.empezar_partida())
	_empezar.visible = false
	brow.add_child(_empezar)
	brow.add_child(_boton("Volver", _volver))
	_automatico.call_deferred()


## Para probar sin tocar nada (proceso/37, «Cómo probarlo»):
##   --red-crear=PUERTO | --red-unirse=IP:PUERTO, --red-civ=clave, --red-color=N,
##   --red-terreno=clave, --red-semilla=N, --red-listo=1 (el anfitrión empieza solo).
## --salir-a, --shot y --shot-at pasan a la partida.
var _auto := {}


func _automatico() -> void:
	for x in OS.get_cmdline_user_args():
		var kv := x.trim_prefix("--").split("=", true, 1)
		if kv[0].begins_with("red-") or kv[0] in ["salir-a", "shot", "shot-at"]:
			_auto[kv[0]] = kv[1] if kv.size() > 1 else "1"
	if _auto.has("red-civ"):
		(_filas[0][0] as OptionButton).select(_civ_keys.find(_auto["red-civ"]) + 1)
		(_filas[1][0] as OptionButton).select(_civ_keys.find(_auto["red-civ"]) + 1)
	if _auto.has("red-crear"):
		_puerto_crear.text = str(_auto["red-crear"])
		if _auto.has("red-terreno"):
			_terreno.select(_map_keys.find(_auto["red-terreno"]) + 1)
		_semilla.text = str(_auto.get("red-semilla", ""))
		_crear()
	elif _auto.has("red-unirse"):
		var ip_p := str(_auto["red-unirse"]).rsplit(":", true, 1)
		_ip.text = ip_p[0]
		_puerto_unir.text = ip_p[1] if ip_p.size() > 1 else str(_cfg_puerto())
		_unirse()
	else:
		return
	if _s == null:
		return
	var f: Array = _filas[_s.local]
	if _auto.has("red-color"):
		(f[1] as OptionButton).select(int(_auto["red-color"]))
	(f[0] as OptionButton).select(_civ_keys.find(str(_auto.get("red-civ", ""))) + 1)
	if _auto.get("red-listo", "") == "1":
		(f[2] as CheckButton).set_pressed_no_signal(true)
	_mio()


func _cfg_puerto() -> int:
	var c = JSON.parse_string(FileAccess.get_file_as_string("res://data/red.json"))
	return int((c as Dictionary).get("puerto", 47800)) if c is Dictionary else 47800


func _sesion() -> SesionRed:
	_s = SesionRed.nueva(get_tree())
	_s.sala_cambio.connect(_refrescar)
	_s.aviso.connect(func(t: String) -> void: _estado.text = t)
	_s.empezar.connect(func(a: Dictionary) -> void:
		for k in ["salir-a", "shot", "shot-at"]:
			if _auto.has(k):
				a[k] = _auto[k]
		empezar.emit(a))
	return _s


func _crear() -> void:
	var s := _sesion()
	var err := s.crear(int(_puerto_crear.text))
	if err != OK:
		_estado.text = "No se pudo abrir el puerto %s (error %d)" % [_puerto_crear.text, err]
		s.cerrar()
		_s = null
		return
	_opciones() # antes que lo propio: elegir() refresca la pantalla con las opciones de la sesión
	_mio()
	_refrescar()


func _unirse() -> void:
	var s := _sesion()
	var err := s.unirse(_ip.text.strip_edges(), int(_puerto_unir.text))
	if err != OK:
		_estado.text = "No se pudo conectar (error %d)" % err
		s.cerrar()
		_s = null
		return
	_mio()
	_refrescar()


func _volver() -> void:
	if _s != null and is_instance_valid(_s) and _s.estado != "partida":
		_s.cerrar()
	_s = null
	volver.emit()


var _refrescando := false


## Lo propio a la sesión (pueblo, color, listo).
func _mio() -> void:
	if _refrescando or _s == null:
		return
	var f: Array = _filas[_s.local]
	var civ := "azar" if (f[0] as OptionButton).selected <= 0 else str(_civ_keys[(f[0] as OptionButton).selected - 1])
	if _s.estado == "conectando": # todavía sin sala: va en el «hola»
		_s.sala["jugadores"][_s.local] = {"civ": civ, "color": (f[1] as OptionButton).selected, "listo": (f[2] as CheckButton).button_pressed, "conectado": true}
		return
	_s.elegir(civ, (f[1] as OptionButton).selected, (f[2] as CheckButton).button_pressed)


func _opciones() -> void:
	if _refrescando or _s == null or not _s.es_anfitrion():
		return
	_s.opciones({
		"terreno": "" if _terreno.selected <= 0 else str(_map_keys[_terreno.selected - 1]),
		"semilla": int(_semilla.text) if _semilla.text.strip_edges().is_valid_int() else -1,
		"sitios": _sitios.button_pressed, "hitos": _hitos.button_pressed, "maravilla": _maravilla.button_pressed,
	})


func _refrescar() -> void:
	if _s == null or not is_instance_valid(_s):
		_juego.visible = false
		_conexion.visible = true
		_empezar.visible = false
		return
	_refrescando = true
	var abierta := _s.estado in ["sala", "conectando"]
	_conexion.visible = not abierta
	_juego.visible = abierta
	for i in 2:
		var j: Dictionary = _s.sala["jugadores"][i]
		var f: Array = _filas[i]
		var mia: bool = i == _s.local
		var civ := str(j["civ"])
		(f[0] as OptionButton).select(0 if civ == "azar" else _civ_keys.find(civ) + 1)
		(f[1] as OptionButton).select(int(j["color"]))
		(f[2] as CheckButton).set_pressed_no_signal(bool(j["listo"]))
		for c: Control in f:
			c.set("disabled", not mia)
		if i == 1 and not j["conectado"]:
			(f[2] as CheckButton).text = "Sin conectar"
		else:
			(f[2] as CheckButton).text = "Listo"
	var op: Dictionary = _s.sala["opciones"]
	var t := str(op.get("terreno", ""))
	_terreno.select(0 if t == "" else _map_keys.find(t) + 1)
	_sitios.set_pressed_no_signal(bool(op.get("sitios", true)))
	_hitos.set_pressed_no_signal(bool(op.get("hitos", true)))
	_maravilla.set_pressed_no_signal(bool(op.get("maravilla", true)))
	if not _s.es_anfitrion():
		var sem := int(op.get("semilla", -1))
		_semilla.text = "" if sem < 0 else str(sem)
	for c: Control in [_terreno, _sitios, _hitos, _maravilla]:
		c.set("disabled", not _s.es_anfitrion())
	_semilla.editable = _s.es_anfitrion()
	_empezar.visible = _s.es_anfitrion()
	var falta := _s.puede_empezar()
	_empezar.disabled = falta != ""
	_empezar.tooltip_text = falta
	if falta == "" and _s.es_anfitrion() and _auto.get("red-listo", "") == "1":
		_s.empezar_partida.call_deferred()
	_refrescando = false


func _process(_d: float) -> void:
	# El estado de la conexión cambia sin señal de sala (conectando → sala, corte).
	if _s != null and is_instance_valid(_s):
		var abierta := _s.estado in ["sala", "conectando"]
		if abierta != _juego.visible:
			_refrescar()
	elif _juego.visible:
		_s = null
		_refrescar()


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


func _edit(t: String, w: float) -> LineEdit:
	var e := LineEdit.new()
	e.text = t
	e.custom_minimum_size = Vector2(w, 30)
	e.add_theme_font_override("font", Hud.font)
	return e


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


func _check(text: String) -> CheckButton:
	var cb := CheckButton.new()
	cb.text = text
	cb.add_theme_font_override("font", Hud.font)
	cb.add_theme_font_size_override("font_size", 14)
	Opciones.interruptor_en(cb)
	return cb


func _boton(text: String, cb: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(110, 32)
	b.add_theme_font_override("font", Hud.font_b)
	b.pressed.connect(cb)
	return b
