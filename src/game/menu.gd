class_name MainMenu
extends Control
## Menú de inicio sobre una partida IA contra IA de fondo.

signal play(seed_value: int, civ: String, rival: String)
signal watch(seed_value: int, civ: String, rival: String)
signal campaigns

var _seed_edit: LineEdit
var _civ: OptionButton
var _rival: OptionButton
var _info: Label
var _keys: Array = []


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
	box.offset_top = -330
	box.offset_right = 640
	box.offset_bottom = 260
	box.add_theme_constant_override("separation", 14)
	add_child(box)

	var title := Label.new()
	title.text = "Proyecto Sur"
	title.add_theme_font_override("font", load("res://assets/fonts/FiraSans-Bold.ttf"))
	title.add_theme_font_size_override("font_size", 76)
	title.add_theme_color_override("font_color", Palette.UI_TEXT)
	box.add_child(title)

	var sub := Label.new()
	sub.text = "Prototipo H1 · Sur global, 1400–1800"
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

	var gap2 := Control.new()
	gap2.custom_minimum_size = Vector2(0, 10)
	box.add_child(gap2)
	box.add_child(_button("Salir", func() -> void: get_tree().quit()))

	var hint := Label.new()
	hint.text = "Clic izquierdo: seleccionar · Clic derecho: ordenar · Q W E R / A S D F / Z X C V: grilla de comandos\nH: centro · . : aldeano inactivo · Ctrl+1…9: grupos · F3: velocidad · Esc: pausa"
	hint.anchor_top = 1.0
	hint.anchor_bottom = 1.0
	hint.offset_left = 110
	hint.offset_top = -86
	hint.offset_right = 1400
	hint.offset_bottom = -30
	hint.add_theme_font_override("font", Hud.font)
	hint.add_theme_font_size_override("font_size", 15)
	hint.add_theme_color_override("font_color", Color(Palette.UI_DIM, 0.85))
	add_child(hint)


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
		return
	var c: Dictionary = data.civs[_keys[_civ.selected - 1]].civ
	_info.text = "«%s»  %s\n%s" % [c.get("frase", ""), c.get("region", ""), c.get("descripcion", "")]
