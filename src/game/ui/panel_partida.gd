extends Control
## Paneles de información de la partida. Un solo nodo que cuelga del HUD:
## botonera, puntaje en vivo, registro de sucesos, economía, avance de edad,
## "cómo juega mi pueblo" y la pantalla de fin con estadísticas.
##
## Teclas: F1 tu pueblo (reemplaza la ayuda vieja, que ya incluía la ficha),
## F2 economía, F4 avance de edad, F5 registro de sucesos, F6 puntaje.
## Enganches en hud.gd, marcados con "# --- paneles ---".

const C := preload("res://src/game/ui/panel_comun.gd")
const Datos := preload("res://src/game/ui/panel_datos.gd")
const Economia := preload("res://src/game/ui/panel_economia.gd")
const Edad := preload("res://src/game/ui/panel_edad.gd")
const Pueblo := preload("res://src/game/ui/panel_pueblo.gd")
const Sucesos := preload("res://src/game/ui/panel_sucesos.gd")
const Puntaje := preload("res://src/game/ui/panel_puntaje.gd")
const Fin := preload("res://src/game/ui/panel_fin.gd")

const RIGHT_W := 330.0
const BUTTONS := [["economia", "Economía", "F2"], ["edad", "Edad", "F4"], ["pueblo", "Mi pueblo", "F1"]]

var hud: Hud
var datos # PanelDatos
var economia: Control
var edad: Control
var pueblo: PanelContainer
var sucesos: Control
var puntaje: Control
var fin: Control
var _bar: Control


func setup(h: Hud) -> void:
	hud = h
	name = "Paneles"
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	datos = Datos.new(hud.sim, hud.local)
	hud.add_child(self)

	_bar = ButtonBar.new()
	_bar.paneles = self
	Hud._anchor(_bar, Vector2(1, 0), Rect2(-RIGHT_W - 12, 94, RIGHT_W, 32))
	add_child(_bar)
	hud._blockers.append(_bar)

	puntaje = Puntaje.new()
	puntaje.hud = hud
	puntaje.datos = datos
	Hud._anchor(puntaje, Vector2(1, 0), Rect2(-RIGHT_W - 12, 132, RIGHT_W, 48))
	add_child(puntaje)

	sucesos = Sucesos.new()
	sucesos.hud = hud
	sucesos.datos = datos
	Hud._anchor(sucesos, Vector2(1, 0), Rect2(-RIGHT_W - 12, 186, RIGHT_W, 60))
	add_child(sucesos)
	hud._blockers.append(sucesos)

	economia = _side(Economia.new(), 540)
	edad = _side(Edad.new(), 560)

	# La ficha del pueblo reemplaza al diálogo de ayuda: F1 y el botón de la pausa
	# siguen llamando a Hud._toggle_help(), que ahora la abre a ella.
	pueblo = Pueblo.new()
	pueblo.build(hud)
	if hud._help != null:
		var old_dim := hud._help.get_parent().get_parent()
		hud._help.visible = false
		old_dim.queue_free()
	hud._help = pueblo

	fin = Fin.new()
	fin.hud = hud
	fin.datos = datos
	fin.visible = false
	add_child(fin)
	_block_when_visible(fin)


func _side(c: Control, w: float) -> Control:
	c.set("hud", hud)
	c.set("datos", datos)
	c.position = Vector2(12, 66)
	c.size = Vector2(w, 400)
	c.visible = false
	add_child(c)
	_block_when_visible(c)
	return c


## Un panel oculto no tiene que tapar clics del mapa: entra y sale de los bloqueos del HUD.
func _block_when_visible(c: Control) -> void:
	c.visibility_changed.connect(func() -> void:
		if c.visible and not hud._blockers.has(c):
			hud._blockers.append(c)
		elif not c.visible:
			hud._blockers.erase(c))


func toggle(which: String) -> void:
	match which:
		"economia":
			economia.visible = not economia.visible
			if economia.visible:
				edad.visible = false
		"edad":
			edad.visible = not edad.visible
			if edad.visible:
				economia.visible = false
		"pueblo":
			hud._toggle_help()
		"sucesos":
			sucesos.toggle()
		"puntaje":
			puntaje.visible = not puntaje.visible


func is_open(which: String) -> bool:
	match which:
		"economia":
			return economia.visible
		"edad":
			return edad.visible
		"pueblo":
			return pueblo.visible
		"puntaje":
			return puntaje.visible
	return false


func on_events(events: Array) -> void:
	datos.on_events(events)


func show_end(winner: int) -> void:
	hud._end.visible = false
	economia.visible = false
	edad.visible = false
	fin.open(winner)


func _unhandled_key_input(event: InputEvent) -> void:
	var k := event as InputEventKey
	if k == null or not k.pressed or k.echo or not hud.is_visible_in_tree():
		return
	match k.physical_keycode:
		KEY_F2:
			toggle("economia")
		KEY_F4:
			toggle("edad")
		KEY_F5:
			toggle("sucesos")
		KEY_F6:
			toggle("puntaje")
		_:
			return
	get_viewport().set_input_as_handled()


func _process(_d: float) -> void:
	# El registro va debajo del puntaje (si está a la vista).
	var y := puntaje.offset_top + (puntaje.size.y + 6 if puntaje.visible else 0.0)
	if sucesos.offset_top != y:
		sucesos.offset_top = y
	sucesos.offset_bottom = sucesos.offset_top + sucesos.size.y
	_bar.queue_redraw()


# ---------------------------------------------------------------- Botonera

class ButtonBar:
	extends Control
	var paneles
	var _hover := -1

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_STOP
		mouse_exited.connect(func() -> void: _hover = -1)

	func _rect(i: int) -> Rect2:
		var n: int = BUTTONS.size()
		var w := (size.x - (n - 1) * 4.0) / n
		return Rect2(i * (w + 4.0), 0, w, size.y)

	func _gui_input(event: InputEvent) -> void:
		if event is InputEventMouseMotion:
			_hover = -1
			for i in BUTTONS.size():
				if _rect(i).has_point(event.position):
					_hover = i
		elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			for i in BUTTONS.size():
				if _rect(i).has_point(event.position):
					paneles.toggle(BUTTONS[i][0])
			accept_event()

	func _draw() -> void:
		for i in BUTTONS.size():
			var b: Array = BUTTONS[i]
			var r := _rect(i)
			var sb := Hud.panel_box(6)
			sb.shadow_size = 4
			var on: bool = paneles.is_open(b[0])
			if on:
				sb.bg_color = Color(0.2, 0.17, 0.08, 0.92)
				sb.border_color = Color(Palette.UI_ACCENT, 0.5)
			elif i == _hover:
				sb.bg_color = Palette.UI_BG_2
			draw_style_box(sb, r)
			draw_string(Hud.font_b, Vector2(r.position.x + 8, 21), b[1], HORIZONTAL_ALIGNMENT_LEFT, r.size.x - 30, 13, Palette.UI_ACCENT if on else Palette.UI_TEXT)
			draw_string(Hud.font, Vector2(r.position.x, 21), b[2], HORIZONTAL_ALIGNMENT_RIGHT, r.size.x - 6, 11, Palette.UI_DIM)
