class_name MainMenu
extends Control
## Menú de inicio sobre una partida IA contra IA de fondo.

signal play(seed_value: int, civ: String, rival: String)
signal watch(seed_value: int, civ: String, rival: String)
signal campaigns
signal replay

var _seed_edit: LineEdit
var _civ: OptionButton
var _rival: OptionButton
var _info: Label
var _keys: Array = []
var _diff: OptionButton
var _map: OptionButton
var _style: OptionButton
var _style_keys: Array = []
var _map_keys: Array = []
var _plate: TextureRect
# --- lugares --- (docs/11, paso 5: de 2 a 8 jugadores y equipos)
const MODOS := [
	["1 contra 1", [0, 1]],
	["2 contra 2", [0, 1, 0, 1]],
	["3 contra 3", [0, 1, 0, 1, 0, 1]],
	["4 contra 4", [0, 1, 0, 1, 0, 1, 0, 1]],
	["Todos contra todos (4)", [0, 1, 2, 3]],
	["Todos contra todos (6)", [0, 1, 2, 3, 4, 5]],
	["Todos contra todos (8)", [0, 1, 2, 3, 4, 5, 6, 7]],
]
var _mode: OptionButton
var _slots_box: VBoxContainer
var _slot_rows: Array = [] # [civ, equipo, dificultad, estilo] por lugar (el 0 es el tuyo)
var _data: SimData
# --- fin lugares ---


func _ready() -> void:
	Hud.load_fonts()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP

	var grad := Gradient.new()
	grad.set_color(0, Color(0.03, 0.035, 0.045, 0.92))
	grad.set_color(1, Color(0.03, 0.035, 0.045, 0.0))
	var gt := GradientTexture2D.new()
	gt.gradient = grad
	gt.fill_from = Vector2(0, 0)
	gt.fill_to = Vector2(0.75, 0)
	var tr := TextureRect.new()
	tr.texture = gt
	tr.stretch_mode = TextureRect.STRETCH_SCALE
	tr.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(tr)

	var box := VBoxContainer.new()
	box.anchor_top = 0.5
	box.anchor_bottom = 0.5
	box.offset_left = 110
	box.offset_top = -420
	box.offset_right = 640
	box.offset_bottom = 260
	box.add_theme_constant_override("separation", 14)
	add_child(box)

	var title := Label.new()
	title.text = "Raíces"
	title.add_theme_font_override("font", load("res://assets/fonts/FiraSans-Bold.ttf"))
	title.add_theme_font_size_override("font_size", 76)
	title.add_theme_color_override("font_color", Palette.UI_TEXT)
	box.add_child(title)

	var sub := Label.new()
	sub.text = "Seis pueblos del sur global, 1400–1800"
	sub.add_theme_font_override("font", Hud.font)
	sub.add_theme_font_size_override("font_size", 20)
	sub.add_theme_color_override("font_color", Palette.UI_ACCENT)
	box.add_child(sub)

	var gap := Control.new()
	gap.custom_minimum_size = Vector2(0, 26)
	box.add_child(gap)

	var data := SimData.load_default()
	_keys = data.civs.keys()
	_keys.sort()
	_civ = _civ_picker(data, "Tu pueblo")
	box.add_child(_civ.get_parent())
	_rival = _civ_picker(data, "Rival")
	box.add_child(_rival.get_parent())
	var drow := HBoxContainer.new()
	drow.add_theme_constant_override("separation", 12)
	var dl := Label.new()
	dl.text = "Dificultad"
	dl.custom_minimum_size = Vector2(110, 0)
	dl.add_theme_font_override("font", Hud.font)
	dl.add_theme_color_override("font_color", Palette.UI_DIM)
	drow.add_child(dl)
	_diff = OptionButton.new()
	_diff.custom_minimum_size = Vector2(270, 38)
	_diff.add_theme_font_override("font", Hud.font_b)
	for k in ["facil", "normal", "dificil"]:
		_diff.add_item(data.reglas["dificultades"][k]["nombre"])
	_diff.selected = 1
	drow.add_child(_diff)
	box.add_child(drow)
	var srow := HBoxContainer.new()
	srow.add_theme_constant_override("separation", 12)
	var sl := Label.new()
	sl.text = "Estilo de la IA"
	sl.custom_minimum_size = Vector2(110, 0)
	sl.add_theme_font_override("font", Hud.font)
	sl.add_theme_color_override("font_color", Palette.UI_DIM)
	srow.add_child(sl)
	_style = OptionButton.new()
	_style.custom_minimum_size = Vector2(270, 38)
	_style.add_theme_font_override("font", Hud.font_b)
	_style_keys = data.reglas["estilos_ia"].keys()
	for k in _style_keys:
		_style.add_item(data.reglas["estilos_ia"][k]["nombre"])
		_style.set_item_tooltip(_style.item_count - 1, data.reglas["estilos_ia"][k].get("descripcion", ""))
	_style.selected = maxi(0, _style_keys.find("normal"))
	srow.add_child(_style)
	box.add_child(srow)
	var mrow := HBoxContainer.new()
	mrow.add_theme_constant_override("separation", 12)
	var ml := Label.new()
	ml.text = "Mapa"
	ml.custom_minimum_size = Vector2(110, 0)
	ml.add_theme_font_override("font", Hud.font)
	ml.add_theme_color_override("font_color", Palette.UI_DIM)
	mrow.add_child(ml)
	_map = OptionButton.new()
	_map.custom_minimum_size = Vector2(270, 38)
	_map.add_theme_font_override("font", Hud.font_b)
	_map.add_item("Al azar")
	_map_keys = data.reglas["terrenos"].keys()
	for k in _map_keys:
		_map.add_item(data.reglas["terrenos"][k]["nombre"])
		var desc: String = data.reglas["terrenos"][k].get("descripcion", "")
		if desc != "":
			_map.set_item_tooltip(_map.item_count - 1, desc)
	mrow.add_child(_map)
	box.add_child(mrow)
	_plate = TextureRect.new()
	_plate.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_plate.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_plate.custom_minimum_size = Vector2(520, 150)
	_plate.visible = false
	box.add_child(_plate)
	_info = Label.new()
	_info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_info.custom_minimum_size = Vector2(520, 70)
	_info.add_theme_font_override("font", Hud.font)
	_info.add_theme_font_size_override("font_size", 15)
	_info.add_theme_color_override("font_color", Palette.UI_DIM)
	box.add_child(_info)
	_civ.item_selected.connect(func(_i: int) -> void: _describe(data))
	_data = data
	_build_slots() # --- lugares ---
	_describe(data)
	box.add_child(_button("Campañas", func() -> void: campaigns.emit()))
	box.add_child(_button("Escaramuza contra la IA", func() -> void: play.emit(_seed(), _pick(_civ), _pick(_rival))))
	box.add_child(_button("Mirar IA contra IA", func() -> void: watch.emit(_seed(), _pick(_civ), _pick(_rival))))

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	var l := Label.new()
	l.text = "Semilla del mapa"
	l.add_theme_font_override("font", Hud.font)
	l.add_theme_color_override("font_color", Palette.UI_DIM)
	row.add_child(l)
	_seed_edit = LineEdit.new()
	_seed_edit.placeholder_text = "al azar"
	_seed_edit.custom_minimum_size = Vector2(140, 0)
	_seed_edit.add_theme_font_override("font", Hud.font)
	row.add_child(_seed_edit)
	box.add_child(row)

	if FileAccess.file_exists("user://ultima_partida.json"):
		box.add_child(_button("Ver la última partida", func() -> void: replay.emit()))
	var gap2 := Control.new()
	gap2.custom_minimum_size = Vector2(0, 10)
	box.add_child(gap2)
	# --- opciones --- (src/game/ui/opciones.gd, el mismo diálogo de la pausa)
	# "Opciones" y "Salir" comparten renglón: el menú no crece y entra a 1366×768.
	var orow := HBoxContainer.new()
	orow.add_theme_constant_override("separation", 10)
	box.add_child(orow)
	var ob := _button("Opciones", func() -> void: open_options())
	ob.custom_minimum_size.x = 185
	orow.add_child(ob)
	var qb := _button("Salir", func() -> void: get_tree().quit())
	qb.custom_minimum_size.x = 185
	orow.add_child(qb)
	_options = Opciones.dialogo(self, get_parent().get_parent() if get_parent() != null else null)
	# --- fin opciones ---

	var hint := Label.new()
	hint.text = "Clic izquierdo: seleccionar · Clic derecho: ordenar · Q W E R / A S D F / Z X C V: grilla de comandos\nH: centro · . : aldeano inactivo · Ctrl+1…9: grupos · F3: velocidad · Esc: pausa"
	# Va dentro de la columna, debajo de "Salir": así no se pisa cuando el menú crece.
	hint.add_theme_font_override("font", Hud.font)
	hint.add_theme_font_size_override("font_size", 14)
	hint.add_theme_color_override("font_color", Color(Palette.UI_DIM, 0.85))
	box.add_child(hint)


# --- opciones ---
var _options: PanelContainer


func open_options() -> void:
	_options.visible = true
# --- fin opciones ---


func _seed() -> int:
	var t := _seed_edit.text.strip_edges()
	return int(t) if t.is_valid_int() else randi() % 100000


func _button(text: String, cb: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	b.custom_minimum_size = Vector2(380, 54)
	b.add_theme_font_override("font", Hud.font_b)
	b.add_theme_font_size_override("font_size", 21)
	var n := StyleBoxFlat.new()
	n.bg_color = Color(1, 1, 1, 0.07)
	n.set_corner_radius_all(6)
	n.content_margin_left = 22
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


func _civ_picker(data: SimData, label: String) -> OptionButton:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	var l := Label.new()
	l.text = label
	l.custom_minimum_size = Vector2(110, 0)
	l.add_theme_font_override("font", Hud.font)
	l.add_theme_color_override("font_color", Palette.UI_DIM)
	row.add_child(l)
	var ob := OptionButton.new()
	ob.custom_minimum_size = Vector2(270, 38)
	ob.add_theme_font_override("font", Hud.font_b)
	ob.add_item("Al azar")
	for k in _keys:
		ob.add_item(data.civs[k].civ.get("nombre", k))
	row.add_child(ob)
	return ob


func _pick(ob: OptionButton) -> String:
	return "azar" if ob.selected <= 0 else _keys[ob.selected - 1]


func _describe(data: SimData) -> void:
	if _civ.selected <= 0:
		_info.text = "Seis pueblos, seis formas de jugar. Elegí uno o dejá que decida la suerte."
		_plate.visible = false
		return
	_plate.texture = CampaignUI.plate(_keys[_civ.selected - 1])
	_plate.visible = _plate.texture != null
	var c: Dictionary = data.civs[_keys[_civ.selected - 1]].civ
	_info.text = "«%s»  %s\n%s" % [c.get("frase", ""), c.get("region", ""), c.get("descripcion", "")]


# --- lugares ---
## Columna de la derecha: tipo de partida y un renglón por lugar.
func _build_slots() -> void:
	var panel := PanelContainer.new()
	panel.anchor_top = 0.5
	panel.anchor_bottom = 0.5
	panel.offset_left = 700
	panel.offset_top = -270
	panel.offset_right = 1360
	var sb := Hud.panel_box(8)
	sb.content_margin_left = 14
	sb.content_margin_right = 14
	sb.content_margin_top = 10
	sb.content_margin_bottom = 10
	panel.add_theme_stylebox_override("panel", sb)
	add_child(panel)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 8)
	panel.add_child(col)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	row.add_child(_label("Partida", 110))
	_mode = OptionButton.new()
	_mode.custom_minimum_size = Vector2(270, 38)
	_mode.add_theme_font_override("font", Hud.font_b)
	for m in MODOS:
		_mode.add_item(m[0])
	row.add_child(_mode)
	col.add_child(row)
	_slots_box = VBoxContainer.new()
	_slots_box.add_theme_constant_override("separation", 6)
	col.add_child(_slots_box)
	_mode.item_selected.connect(func(_i: int) -> void: _fill_slots())
	_civ.item_selected.connect(_mirror_civ)
	# --partida=N preselecciona el tipo de partida (para las capturas).
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--partida="):
			_mode.selected = clampi(int(a.split("=")[1]), 0, MODOS.size() - 1)
	_fill_slots()


func _label(t: String, w: float) -> Label:
	var l := Label.new()
	l.text = t
	l.custom_minimum_size = Vector2(w, 0)
	l.add_theme_font_override("font", Hud.font)
	l.add_theme_color_override("font_color", Palette.UI_DIM)
	return l


func _small(items: Array, w: float, sel: int) -> OptionButton:
	var ob := OptionButton.new()
	ob.custom_minimum_size = Vector2(w, 32)
	ob.add_theme_font_override("font", Hud.font)
	ob.add_theme_font_size_override("font_size", 14)
	for it in items:
		ob.add_item(it)
	ob.selected = sel
	return ob


func _fill_slots() -> void:
	for c in _slots_box.get_children():
		c.queue_free()
	_slot_rows.clear()
	var teams: Array = MODOS[maxi(0, _mode.selected)][1]
	var solo := teams.size() == 2
	_rival.disabled = not solo
	_rival.tooltip_text = "" if solo else "Con más de dos jugadores, los rivales se eligen en la columna de lugares."
	if solo:
		return
	var civ_names: Array = ["Al azar"]
	for k in _keys:
		civ_names.append(_data.civs[k].civ.get("nombre", k))
	var team_names: Array = []
	for i in 8:
		team_names.append("Equipo %d" % (i + 1))
	var dif_names: Array = []
	for k in ["facil", "normal", "dificil"]:
		dif_names.append(_data.reglas["dificultades"][k]["nombre"])
	var sty_names: Array = []
	for k in _style_keys:
		sty_names.append(_data.reglas["estilos_ia"][k]["nombre"])
	for i in teams.size():
		var r := HBoxContainer.new()
		r.add_theme_constant_override("separation", 8)
		var dot := ColorRect.new()
		dot.color = Palette.TEAM[i % Palette.TEAM.size()]
		dot.custom_minimum_size = Vector2(6, 28)
		r.add_child(dot)
		r.add_child(_label("Vos" if i == 0 else "IA %d" % i, 44))
		var civ := _small(civ_names, 170, 0)
		var tm := _small(team_names, 110, int(teams[i]))
		var dif := _small(dif_names, 100, maxi(0, _diff.selected))
		var sty := _small(sty_names, 130, maxi(0, _style.selected))
		if i == 0:
			civ.disabled = true
			civ.tooltip_text = "Tu pueblo se elige a la izquierda."
			civ.selected = _civ.selected
			dif.visible = false
			sty.visible = false
		r.add_child(civ)
		r.add_child(tm)
		r.add_child(dif)
		r.add_child(sty)
		_slots_box.add_child(r)
		_slot_rows.append([civ, tm, dif, sty])


func _mirror_civ(i: int) -> void:
	if not _slot_rows.is_empty():
		(_slot_rows[0][0] as OptionButton).selected = i


## Lugares elegidos para main.gd; vacío en el 1 contra 1 (usa "Tu pueblo" y "Rival").
func slots() -> Array:
	if _slot_rows.is_empty():
		return []
	var out: Array = []
	for i in _slot_rows.size():
		var r: Array = _slot_rows[i]
		out.append({
			"civ": _pick(_civ) if i == 0 else _pick(r[0]),
			"equipo": (r[1] as OptionButton).selected,
			"ia": i != 0,
			"dificultad": ["facil", "normal", "dificil"][maxi(0, (r[2] as OptionButton).selected)],
			"estilo": str(_style_keys[maxi(0, (r[3] as OptionButton).selected)]),
		})
	return out
# --- fin lugares ---


func difficulty() -> String:
	return ["facil", "normal", "dificil"][maxi(0, _diff.selected)]


## Tipo de mapa elegido ("" = al azar).
func terrain() -> String:
	return "" if _map.selected <= 0 else str(_map_keys[_map.selected - 1])


## Estilo de juego de la IA, independiente de la dificultad.
func style() -> String:
	return str(_style_keys[maxi(0, _style.selected)])
