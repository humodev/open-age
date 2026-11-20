class_name PanelBase
extends PanelContainer
## Panel «Mi base» (C17, proceso/30-fluidez/07): una fila por tipo de edificio propio con
## cuántos hay, en obra, dañados y vacíos o parados. Un clic en un número va al siguiente de
## esos (lo elige y centra la cámara); Mayús + clic los elige a todos. Tecla: mi_base (F11).
## Solo lee la simulación.
##
## Vacíos o parados: granja sin granjero, edificio que produce con la cola vacía y sin
## repetición, repetición frenada por población o recursos, obra sin constructores.

const COLS := ["Total", "En obra", "Dañados", "Vacíos o parados"]
const REFRESCO_S := 0.5 # cada cuánto se recuentan (solo con el panel abierto)

var hud: Hud
var _grid: GridContainer
var _vacio: Label
var _filas := {} # tipo → [Label, Button × 4]
var _listas := {} # tipo → [ids todos, en obra, dañados, vacíos]
var _ciclo := {} # "tipo:col" → índice del último visitado
var _t := 0.0


func setup(h: Hud) -> void:
	hud = h
	name = "MiBase"
	visible = false
	mouse_filter = Control.MOUSE_FILTER_STOP
	position = Vector2(12, 66)
	custom_minimum_size = Vector2(500, 0)
	var sb := Hud.panel_box(8)
	sb.set_content_margin_all(14)
	add_theme_stylebox_override("panel", sb)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 8)
	add_child(vb)
	var top := HBoxContainer.new()
	vb.add_child(top)
	var tl := Label.new()
	tl.text = "Mi base · %s" % Teclas.texto("mi_base")
	tl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if Hud.font_b != null:
		tl.add_theme_font_override("font", Hud.font_b)
	tl.add_theme_font_size_override("font_size", Hud.ts(20))
	top.add_child(tl)
	var x := Button.new()
	x.text = "×"
	x.flat = true
	x.tooltip_text = "Cerrar"
	x.pressed.connect(func() -> void: visible = false)
	top.add_child(x)
	var hint := Label.new()
	hint.text = "Clic: ir al siguiente · Mayús + clic: elegir todos"
	hint.add_theme_font_size_override("font_size", Hud.ts(12))
	hint.add_theme_color_override("font_color", Palette.UI_DIM)
	vb.add_child(hint)
	var sc := ScrollContainer.new()
	sc.custom_minimum_size = Vector2(0, 380)
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	vb.add_child(sc)
	_grid = GridContainer.new()
	_grid.columns = 1 + COLS.size()
	_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_grid.add_theme_constant_override("h_separation", 6)
	sc.add_child(_grid)
	_vacio = Label.new()
	_vacio.text = "Todavía no hay edificios."
	_vacio.add_theme_color_override("font_color", Palette.UI_DIM)
	vb.add_child(_vacio)
	hud.add_child(self)
	visibility_changed.connect(func() -> void:
		if visible:
			_t = REFRESCO_S
			if not hud._blockers.has(self):
				hud._blockers.append(self)
		else:
			hud._blockers.erase(self))


func toggle() -> void:
	visible = not visible


func _unhandled_key_input(event: InputEvent) -> void:
	var k := event as InputEventKey
	if k == null or not k.pressed or k.echo or not hud.is_visible_in_tree():
		return
	if Teclas.es(k.physical_keycode, "mi_base"):
		toggle()
		get_viewport().set_input_as_handled()


func _process(delta: float) -> void:
	if not visible:
		return
	_t += delta
	if _t < REFRESCO_S:
		return
	_t = 0.0
	_recontar()


## Recuenta los edificios propios y actualiza las filas (se rearma solo si cambian los tipos).
func _recontar() -> void:
	var sim := hud.sim
	var listas := {}
	for e in sim.actives:
		if e.owner != hud.local or not e.alive or not e.is_building():
			continue
		var l: Array = listas.get_or_add(e.type, [[], [], [], []])
		l[0].append(e.id)
		if not e.built:
			l[1].append(e.id)
		elif e.hp < e.hp_max:
			l[2].append(e.id)
		if es_vacio(sim, e):
			l[3].append(e.id)
	_listas = listas
	var tipos := listas.keys()
	tipos.sort_custom(func(a: String, b: String) -> bool: return _nombre(a) < _nombre(b))
	if tipos != _filas.keys():
		_armar(tipos)
	for t: String in tipos:
		var f: Array = _filas[t]
		for c in COLS.size():
			var n: int = (listas[t][c] as Array).size()
			var b: Button = f[1 + c]
			b.text = str(n) if n > 0 else "·"
			b.disabled = n == 0
			if c >= 2 and n > 0:
				b.add_theme_color_override("font_color", Palette.UI_BAD)
			else:
				b.remove_theme_color_override("font_color")
	_vacio.visible = tipos.is_empty()


## Vacío o parado (ver el encabezado). Solo lectura: no toca la simulación.
static func es_vacio(sim: Sim, e: SimEntity) -> bool:
	if not e.built:
		return e.workers_now == 0
	if str(e.def.get("fuente", "")) != "":
		var f: SimEntity = sim.by_id.get(e.farmer)
		return f == null or not f.alive or f.target != e.id
	if e.repeat != "":
		return sim.repeat_block(e) in ["pob", "recursos"]
	return not (e.def.get("produce", []) as Array).is_empty() and e.queue.is_empty()


func _nombre(tipo: String) -> String:
	return str(hud.sim.dp(hud.local).edificios.get(tipo, {}).get("nombre", tipo))


func _armar(tipos: Array) -> void:
	for c in _grid.get_children():
		c.queue_free()
	_filas.clear()
	var head := Label.new()
	head.text = "Edificio"
	head.add_theme_color_override("font_color", Palette.UI_DIM)
	head.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_grid.add_child(head)
	for c: String in COLS:
		var h := Label.new()
		h.text = c
		h.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		h.add_theme_font_size_override("font_size", Hud.ts(12))
		h.add_theme_color_override("font_color", Palette.UI_DIM)
		_grid.add_child(h)
	for t: String in tipos:
		var lbl := Label.new()
		lbl.text = _nombre(t)
		lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_grid.add_child(lbl)
		var f: Array = [lbl]
		for c in COLS.size():
			var b := Button.new()
			b.flat = true
			b.custom_minimum_size = Vector2(64, 0)
			b.pressed.connect(_ir.bind(t, c))
			_grid.add_child(b)
			f.append(b)
		_filas[t] = f


## Va al siguiente edificio de esa celda; con Mayús, los elige a todos.
func _ir(tipo: String, col: int) -> void:
	var ids: Array = _listas.get(tipo, [[], [], [], []])[col]
	if ids.is_empty() or hud.ctrl == null:
		return
	var sel: Array[int] = []
	if Input.is_key_pressed(KEY_SHIFT):
		sel.assign(ids)
	else:
		var key := "%s:%d" % [tipo, col]
		var i: int = (int(_ciclo.get(key, -1)) + 1) % ids.size()
		_ciclo[key] = i
		sel.append(int(ids[i]))
	hud.ctrl.select_ids(sel)
	hud.ctrl.center_on_selection()
