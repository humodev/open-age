class_name CampaignUI
extends Control
## Menú de campañas, introducción de misión y epílogo (docs/campanas/).

signal start_mission(civ: String, index: int)
signal back

const SAVE := "user://progreso.json"

var _campaigns: Array[Dictionary] = []
var _list: VBoxContainer
var _detail: VBoxContainer


## Lámina de una civilización (generada con IA, ver assets/CREDITOS.md), o null.
static func plate(civ: String) -> Texture2D:
	var path := "res://assets/generados/laminas/%s.jpg" % civ
	return load(path) if ResourceLoader.exists(path) else null


static func load_campaigns() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var order := ["tutorial", "tawantinsuyu", "mapuches", "guaranies", "etiopia", "palmares", "ayutthaya"]
	for k in order:
		var path := "res://data/campanas/%s.json" % k
		if FileAccess.file_exists(path):
			var c: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(path))
			c["_clave"] = k
			out.append(c)
	return out


static func progress() -> Dictionary:
	if not FileAccess.file_exists(SAVE):
		return {}
	var v: Variant = JSON.parse_string(FileAccess.get_file_as_string(SAVE))
	return v if v is Dictionary else {}


## Marca la misión como ganada y desbloquea la siguiente.
static func mark_won(civ: String, index: int) -> void:
	var p := progress()
	p[civ] = maxi(int(p.get(civ, 0)), index + 1)
	var f := FileAccess.open(SAVE, FileAccess.WRITE)
	if f != null:
		f.store_string(JSON.stringify(p))


func _ready() -> void:
	Hud.load_fonts()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var bg := ColorRect.new()
	bg.color = Color(0.035, 0.04, 0.05, 0.93)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	_campaigns = load_campaigns()
	var root := HBoxContainer.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.offset_left = 90
	root.offset_top = 80
	root.offset_right = -90
	root.offset_bottom = -60
	root.add_theme_constant_override("separation", 48)
	add_child(root)
	var left := VBoxContainer.new()
	left.custom_minimum_size = Vector2(430, 0)
	left.add_theme_constant_override("separation", 10)
	root.add_child(left)
	left.add_child(_label("Campañas", 44, Palette.UI_TEXT, true))
	left.add_child(_label("Seis historias contadas desde adentro.", 17, Palette.UI_ACCENT))
	var gap := Control.new()
	gap.custom_minimum_size = Vector2(0, 16)
	left.add_child(gap)
	_list = VBoxContainer.new()
	_list.add_theme_constant_override("separation", 8)
	left.add_child(_list)
	var gap2 := Control.new()
	gap2.size_flags_vertical = Control.SIZE_EXPAND_FILL
	left.add_child(gap2)
	left.add_child(_button("Volver", func() -> void: back.emit(), 260))
	var scroll := ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	root.add_child(scroll)
	_detail = VBoxContainer.new()
	_detail.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_detail.add_theme_constant_override("separation", 12)
	scroll.add_child(_detail)
	var prog := progress()
	for i in _campaigns.size():
		var c := _campaigns[i]
		var data := SimData.load_default().for_civ(c["civ"])
		var won: int = int(prog.get(c["_clave"], 0))
		var name: String = "Tutorial" if c["_clave"] == "tutorial" else data.civ.get("nombre", c["civ"])
		var idx := i
		_list.add_child(_button("%s · %s   %d/%d" % [name, c["titulo"], mini(won, (c["misiones"] as Array).size()), (c["misiones"] as Array).size()], func() -> void: _show(idx), 430)) # progreso real, no "/4" fijo
	if not _campaigns.is_empty():
		_show(0)


func _show(i: int) -> void:
	for ch in _detail.get_children():
		ch.queue_free()
	var c := _campaigns[i]
	var won: int = int(progress().get(c["_clave"], 0))
	var tex := plate(c["civ"])
	if tex != null:
		var tr := TextureRect.new()
		tr.texture = tex
		tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		tr.custom_minimum_size = Vector2(0, 300)
		_detail.add_child(tr)
	_detail.add_child(_label(c["titulo"], 36, Palette.UI_TEXT, true))
	_detail.add_child(_label(c.get("resumen", ""), 18, Palette.UI_DIM))
	for mi in (c["misiones"] as Array).size():
		var m: Dictionary = c["misiones"][mi]
		var card := PanelContainer.new()
		var sb := Hud.panel_box(8)
		sb.content_margin_left = 22
		sb.content_margin_right = 22
		sb.content_margin_top = 16
		sb.content_margin_bottom = 16
		card.add_theme_stylebox_override("panel", sb)
		var vb := VBoxContainer.new()
		vb.add_theme_constant_override("separation", 6)
		card.add_child(vb)
		var locked := mi > won
		var head := "%d. %s" % [mi + 1, m["titulo"]]
		vb.add_child(_label(head, 22, Palette.UI_DIM if locked else Palette.UI_TEXT, true))
		vb.add_child(_label(subtitle(m), 15, Palette.UI_ACCENT))
		if not locked:
			var intro: Array = m.get("intro", [])
			if not intro.is_empty():
				var l := _label(intro[0], 15, Palette.UI_DIM)
				vb.add_child(l)
			var civ: String = c["_clave"]
			var idx := mi
			var row := HBoxContainer.new()
			row.add_child(_button("Jugar" if mi >= won else "Volver a jugar", func() -> void: start_mission.emit(civ, idx), 220))
			if mi < won:
				row.add_child(_label("  ✓ ganada", 15, Palette.UI_GOOD))
			vb.add_child(row)
		else:
			vb.add_child(_label("Se desbloquea al ganar la misión anterior.", 14, Color(Palette.UI_DIM, 0.6)))
		_detail.add_child(card)


## "1554 · Cuesta de Marigüeñu": año y lugar, sin "· " suelto si falta uno de los dos.
static func subtitle(m: Dictionary) -> String:
	var parts: Array[String] = []
	for k in ["anio", "lugar"]:
		var v := str(m.get(k, "")).strip_edges()
		if v != "":
			parts.append(v)
	return " · ".join(parts)


func _label(t: String, size: int, col: Color, bold: bool = false) -> Label:
	var l := Label.new()
	l.text = t
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.add_theme_font_override("font", Hud.font_b if bold else Hud.font)
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", col)
	return l


static func _button(text: String, cb: Callable, width: int) -> Button:
	var b := Button.new()
	b.text = text
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	b.custom_minimum_size = Vector2(width, 46)
	b.add_theme_font_override("font", Hud.font_b)
	b.add_theme_font_size_override("font_size", 17)
	var n := StyleBoxFlat.new()
	n.bg_color = Color(1, 1, 1, 0.07)
	n.set_corner_radius_all(6)
	n.content_margin_left = 18
	n.content_margin_right = 18
	var h := n.duplicate() as StyleBoxFlat
	h.bg_color = Color(Palette.UI_ACCENT, 0.24)
	b.add_theme_stylebox_override("normal", n)
	b.add_theme_stylebox_override("hover", h)
	b.add_theme_stylebox_override("pressed", h)
	b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	b.add_theme_color_override("font_color", Palette.UI_TEXT)
	b.pressed.connect(cb)
	return b


# ---------------------------------------------------------------- Introducción y epílogo

## Pantalla de texto a página completa: introducción o epílogo de una misión.
static func story(m: Dictionary, epilogue: bool, buttons: Array, civ: String = "") -> Control:
	Hud.load_fonts()
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_STOP
	var bg := ColorRect.new()
	bg.color = Color(0.03, 0.035, 0.045, 1.0)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(bg)
	var tex := plate(civ)
	if tex != null:
		var art := TextureRect.new()
		art.texture = tex
		art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		art.modulate = Color(0.32, 0.32, 0.34)
		root.add_child(art)
		var veil := ColorRect.new()
		veil.color = Color(0.02, 0.025, 0.03, 0.45)
		veil.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		root.add_child(veil)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(center)
	var vb := VBoxContainer.new()
	vb.custom_minimum_size = Vector2(860, 0)
	vb.add_theme_constant_override("separation", 16)
	center.add_child(vb)
	var tmp := CampaignUI.new()
	vb.add_child(tmp._label(subtitle(m), 18, Palette.UI_ACCENT))
	vb.add_child(tmp._label(m.get("titulo", ""), 46, Palette.UI_TEXT, true))
	var gap := Control.new()
	gap.custom_minimum_size = Vector2(0, 8)
	vb.add_child(gap)
	for para in m.get("epilogo" if epilogue else "intro", []):
		vb.add_child(tmp._label(para, 19, Color(Palette.UI_TEXT, 0.92)))
	if epilogue and not (m.get("fuentes", []) as Array).is_empty():
		vb.add_child(tmp._label("Fuentes: " + "; ".join(m["fuentes"]), 13, Palette.UI_DIM))
	tmp.free()
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	for b in buttons:
		row.add_child(_button(b[0], b[1], 260))
	var gap2 := Control.new()
	gap2.custom_minimum_size = Vector2(0, 14)
	vb.add_child(gap2)
	vb.add_child(row)
	return root
