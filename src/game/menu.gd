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
	box.add_child(_button("Salir", func() -> void: get_tree().quit()))

	var hint := Label.new()
	hint.text = "Clic izquierdo: seleccionar · Clic derecho: ordenar · Q W E R / A S D F / Z X C V: grilla de comandos\nH: centro · . : aldeano inactivo · Ctrl+1…9: grupos · F3: velocidad · Esc: pausa"
	# Va dentro de la columna, debajo de "Salir": así no se pisa cuando el menú crece.
	hint.add_theme_font_override("font", Hud.font)
	hint.add_theme_font_size_override("font_size", 14)
	hint.add_theme_color_override("font_color", Color(Palette.UI_DIM, 0.85))
	box.add_child(hint)


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


func difficulty() -> String:
	return ["facil", "normal", "dificil"][maxi(0, _diff.selected)]


## Tipo de mapa elegido ("" = al azar).
func terrain() -> String:
	return "" if _map.selected <= 0 else str(_map_keys[_map.selected - 1])


## Estilo de juego de la IA, independiente de la dificultad.
func style() -> String:
	return str(_style_keys[maxi(0, _style.selected)])
