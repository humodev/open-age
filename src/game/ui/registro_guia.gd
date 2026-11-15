extends Control
## Registro de la Guía (proceso/23-como-aoe4/03-aprender-a-jugar.md): los mensajes de las
## campañas se van, pero acá quedan para releerlos. Se abre con F7 o con el botón
## "Releer la guía", que aparece debajo de los objetivos cuando hubo algún mensaje.

var hud # Hud
var mensajes: Array[Dictionary] = [] # {t: segundos, quien, texto}
var max_msgs := 60
var boton: Button
var _panel: PanelContainer
var _lista: VBoxContainer
var _scroll: ScrollContainer


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
	boton.pressed.connect(toggle)
	add_child(boton)
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
	var tl := Label.new()
	tl.text = "Lo que dijo la Guía"
	tl.add_theme_font_override("font", Hud.font_b)
	tl.add_theme_font_size_override("font_size", 24)
	tl.add_theme_color_override("font_color", Palette.UI_ACCENT)
	vb.add_child(tl)
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
	return [boton, _panel]


func toggle() -> void:
	_panel.visible = not _panel.visible
	if _panel.visible:
		_rebuild()
		move_to_front()


func _rebuild() -> void:
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


func _unhandled_key_input(event: InputEvent) -> void:
	var k := event as InputEventKey
	if k == null or not k.pressed or k.echo or not hud.is_visible_in_tree():
		return
	if k.physical_keycode == KEY_G or (k.physical_keycode == KEY_ESCAPE and _panel.visible):
		toggle()
		get_viewport().set_input_as_handled()
