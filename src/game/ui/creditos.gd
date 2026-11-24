class_name Creditos
extends RefCounted
## Pantalla de créditos del menú (proceso/51): lo que pide atribución por su licencia (la música
## CC BY-SA y CC BY de C-07 y C-24, los íconos CC BY, OpenStreetMap y Copernicus) y un resumen de lo
## libre. El texto está en data/creditos.json; la lista completa, en assets/CREDITOS.md.


## Diálogo oculto, como el de Opciones: se muestra con `visible = true`.
static func dialogo(host: Control) -> PanelContainer:
	Hud.load_fonts()
	var cfg: Dictionary = {}
	var path := "res://data/creditos.json"
	if FileAccess.file_exists(path):
		cfg = JSON.parse_string(FileAccess.get_file_as_string(path))
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.5)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	dim.theme = Opciones.tema()
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
	vb.add_theme_constant_override("separation", 10)
	pc.add_child(vb)
	var tl := Label.new()
	tl.text = str(cfg.get("titulo", "Créditos"))
	tl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tl.add_theme_font_override("font", Hud.font_b)
	tl.add_theme_font_size_override("font_size", Hud.ts(30))
	vb.add_child(tl)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(760, 440)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	vb.add_child(scroll)
	var body := VBoxContainer.new()
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 6)
	scroll.add_child(body)
	for sec: Dictionary in cfg.get("secciones", []):
		var h := Label.new()
		h.text = str(sec.get("titulo", ""))
		h.add_theme_font_override("font", Hud.font_b)
		h.add_theme_font_size_override("font_size", Hud.ts(18))
		h.add_theme_color_override("font_color", Palette.UI_ACCENT)
		body.add_child(h)
		for line in sec.get("lineas", []):
			var l := Label.new()
			l.text = str(line)
			l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			l.custom_minimum_size = Vector2(730, 0)
			l.add_theme_font_override("font", Hud.font)
			l.add_theme_font_size_override("font_size", Hud.ts(15))
			l.add_theme_color_override("font_color", Palette.UI_TEXT)
			body.add_child(l)
	var pie := Label.new()
	pie.text = str(cfg.get("pie", ""))
	pie.add_theme_font_override("font", Hud.font)
	pie.add_theme_font_size_override("font_size", Hud.ts(13))
	pie.add_theme_color_override("font_color", Palette.UI_DIM)
	vb.add_child(pie)
	var cb := Button.new()
	cb.text = "Cerrar"
	cb.custom_minimum_size = Vector2(200, 0)
	cb.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	vb.add_child(cb)
	cb.pressed.connect(func() -> void: pc.visible = false)
	host.add_child(dim)
	pc.visibility_changed.connect(func() -> void:
		dim.visible = pc.visible
		if pc.visible:
			dim.move_to_front()
			cb.grab_focus())
	pc.visible = false
	dim.visible = false
	return pc
