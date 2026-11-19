extends Control
## Hoja de atajos de una pantalla (proceso/24, 4q; jugador nuevo, ronda 5: «un principiante no
## sabe qué tecla hace qué; los controles están al final de Mi pueblo»). Las teclas salen de
## Teclas (lo que el jugador reasignó en Opciones → Teclas), no escritas a mano. Se abre con la
## acción `atajos` (F12 de fábrica) o desde la pausa; Esc o la misma tecla la cierran.

var hud # Hud
var _panel: PanelContainer
var _cols: HBoxContainer


func setup(h) -> void:
	hud = h
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel = PanelContainer.new()
	var sb := Hud.panel_box(10)
	sb.bg_color = Color(0.07, 0.075, 0.085, 0.97)
	sb.content_margin_left = 26
	sb.content_margin_right = 26
	sb.content_margin_top = 18
	sb.content_margin_bottom = 18
	_panel.add_theme_stylebox_override("panel", sb)
	Hud._anchor(_panel, Vector2(0.5, 0.5), Rect2(-560, -330, 1120, 660))
	_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 12)
	_panel.add_child(vb)
	var tl := Label.new()
	tl.text = "Atajos de teclado"
	tl.add_theme_font_override("font", Hud.font_b)
	tl.add_theme_font_size_override("font_size", 24)
	tl.add_theme_color_override("font_color", Palette.UI_ACCENT)
	vb.add_child(tl)
	_cols = HBoxContainer.new()
	_cols.add_theme_constant_override("separation", 28)
	_cols.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vb.add_child(_cols)
	var pie := Label.new()
	pie.name = "Pie"
	pie.add_theme_font_size_override("font_size", 13)
	pie.add_theme_color_override("font_color", Palette.UI_DIM)
	vb.add_child(pie)
	var cb := Button.new()
	cb.name = "Cerrar"
	cb.focus_mode = Control.FOCUS_NONE
	cb.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	cb.custom_minimum_size = Vector2(200, 0)
	cb.pressed.connect(toggle)
	vb.add_child(cb)
	_panel.visible = false
	add_child(_panel)


func is_open() -> bool:
	return _panel.visible


func blockers() -> Array[Control]:
	return [_panel]


func toggle() -> void:
	_panel.visible = not _panel.visible
	if _panel.visible:
		_rebuild()
		move_to_front()


static func _k(accion: String) -> String:
	return Teclas.texto(accion)


## Las secciones: [título, [[tecla, qué hace], …]]. Lo más usado primero.
static func secciones() -> Array:
	var grilla := "%s %s %s %s · %s %s %s %s · %s %s %s %s" % [_k("grilla_0"), _k("grilla_1"), _k("grilla_2"), _k("grilla_3"), _k("grilla_4"), _k("grilla_5"), _k("grilla_6"), _k("grilla_7"), _k("grilla_8"), _k("grilla_9"), _k("grilla_10"), _k("grilla_11")]
	return [
		["Lo básico", [
			["Clic izquierdo", "elegir (arrastrá para un grupo; doble clic o Ctrl + clic: todos los del tipo en pantalla)"], # --- fluidez 5 ---
			["Clic derecho", "mover, atacar, juntar, construir, reparar o alojar; sobre una unidad propia, seguirla y escoltarla"], # --- fluidez 5 ---
			[grilla, "la grilla de órdenes: construir, entrenar, investigar"],
			# --- ronda 6 --- la elección de blancos (proceso/24, 5d): ya no «lo primero que ven»
			["%s y clic" % _k("grilla_4"), "atacar en movimiento: primero a los soldados, después a los aldeanos y a lo que tira flechas. Para tirar edificios: asedio y clic derecho sobre el edificio"],
			# --- fin ronda 6 ---
			[_k("grilla_5"), "detener"],
			# --- fluidez 5 ---
			["Mayús + órdenes", "encolar: mover, atacar, construir y también mantener posición"],
			["Patrullar + Mayús + clics", "patrulla de varios puntos: recorre la ronda y vuelve a empezar"],
			# --- fin fluidez 5 ---
			[_k("ir_aviso"), "ir al último ataque o aviso"],
			[_k("avisos_atras"), "recorrer los avisos anteriores"],
			["Esc", "pausa (y cerrar esta hoja)"],
		]],
		["Elegir", [
			[_k("ocioso_aldeano"), "el siguiente aldeano sin trabajo (Mayús: todos)"],
			[_k("ocioso_militar"), "el siguiente militar quieto (Mayús: todos)"],
			[_k("ejercito"), "todo el ejército"],
			[_k("del_tipo"), "todos los del tipo de lo elegido"],
			[_k("centro"), "el centro (dos veces: la cámara va ahí)"],
			[_k("produccion"), "recorrer los edificios que entrenan (con aldeanos y tropas: cambia de grilla)"], # --- ronda 6 ---
			[_k("todos_aldeanos"), "todos los aldeanos"],
			[_k("produccion_todos"), "todos los edificios de producción militar"],
			[_k("campana"), "campana: los aldeanos se refugian (otra vez: calma)"],
			[_k("borrar"), "borrar lo elegido"],
		]],
		["Grupos, cámara y Alt", [
			["Ctrl + %s…%s" % [_k("grupo_1"), _k("grupo_0")], "guardar lo elegido como grupo"],
			["%s…%s" % [_k("grupo_1"), _k("grupo_0")], "elegir el grupo (dos veces: la cámara va ahí)"],
			["Mayús + %s…%s" % [_k("grupo_1"), _k("grupo_0")], "sumar al grupo"],
			["Ctrl + Alt + 1…8", "guardar la cámara"],
			["Alt + 1…8 · %s %s %s" % [_k("marcador_1"), _k("marcador_2"), _k("marcador_3")], "volver a una cámara guardada"],
			["Flechas, bordes, botón del medio", "mover la cámara (el botón del medio la arrastra); rueda: acercar y alejar"], # --- fluidez 5 --- no gira: el ángulo es fijo
			["Mantener Alt", "ver qué es cada edificio y cada tropa (choque, distancia, línea, asedio, aldeano), los alcances y las barras de vida"], # --- ronda 6 ---
		]],
		["Paneles", [
			[_k("ayuda"), "cómo juega tu pueblo"],
			[_k("economia"), "economía"],
			[_k("velocidad"), "velocidad del juego"],
			[_k("edad"), "qué falta para la próxima edad"],
			[_k("sucesos"), "registro de sucesos"],
			[_k("puntaje"), "puntaje y tributos"],
			[_k("pausa"), "pausa"],
			[_k("atajos"), "esta hoja"],
		]],
	]


func _rebuild() -> void:
	for c in _cols.get_children():
		c.queue_free()
	for sec: Array in secciones():
		var col := VBoxContainer.new()
		col.add_theme_constant_override("separation", 6)
		col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var h := Label.new()
		h.text = sec[0]
		h.add_theme_font_override("font", Hud.font_b)
		h.add_theme_font_size_override("font_size", 17)
		h.add_theme_color_override("font_color", Palette.UI_ACCENT)
		col.add_child(h)
		for row: Array in sec[1]:
			var key := Label.new()
			key.text = row[0]
			key.add_theme_font_override("font", Hud.font_b)
			key.add_theme_font_size_override("font_size", 15)
			key.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			col.add_child(key)
			var what := Label.new()
			what.text = row[1]
			what.add_theme_font_size_override("font_size", 13)
			what.add_theme_color_override("font_color", Palette.UI_DIM.lightened(0.25))
			what.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			what.custom_minimum_size = Vector2(230, 0)
			col.add_child(what)
		_cols.add_child(col)
	(_panel.find_child("Pie", true, false) as Label).text = "Las teclas se cambian en Opciones → Teclas. En la grilla, Mayús entrena 5 de una vez."
	(_panel.find_child("Cerrar", true, false) as Button).text = "Cerrar (%s)" % _k("atajos")


func _unhandled_key_input(event: InputEvent) -> void:
	var k := event as InputEventKey
	if k == null or not k.pressed or k.echo or not hud.is_visible_in_tree():
		return
	if Teclas.es(k.physical_keycode, "atajos") or (k.physical_keycode == KEY_ESCAPE and _panel.visible):
		toggle()
		get_viewport().set_input_as_handled()
