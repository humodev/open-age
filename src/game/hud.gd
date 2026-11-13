class_name Hud
extends Control
## Interfaz de partida (docs/07-arte-y-ui.md). Se construye por código.

const O := SimEntity.Order
const SLOT := 62.0
const GAP := 6.0

static var font: Font
static var font_b: Font

var main: Node
var sim: Sim
var ctrl: Controller
var cam: RtsCamera
var local: int

var _top: Control
var _clock: Control
var _sel: Control
var _card: Control
var _mini: Minimap
var _tip: Control
var _notice: Label
var _notice_t := 0.0
var _menu: PanelContainer
var _end: PanelContainer
var _end_title: Label
var _end_body: Label
var _blockers: Array[Control] = []
var _objectives: Control
var _dialog: PanelContainer
var _dialog_who: Label
var _dialog_text: Label
var _dialog_queue: Array[Dictionary] = []
var _dialog_t := 0.0
# --- paneles --- (src/game/ui/panel_partida.gd)
const PANELES := preload("res://src/game/ui/panel_partida.gd")
var paneles: Control
# --- fin paneles ---


static func load_fonts() -> void:
	if font != null:
		return
	font = load("res://assets/fonts/FiraSans-Regular.ttf")
	font_b = load("res://assets/fonts/FiraSans-SemiBold.ttf")


func setup(m: Node, s: Sim, c: Controller, camera: RtsCamera, local_player: int) -> void:
	load_fonts()
	main = m
	sim = s
	ctrl = c
	cam = camera
	local = local_player
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	theme = _make_theme()

	var overlay := Overlay.new()
	overlay.setup(sim, ctrl, cam)
	add_child(overlay)

	_top = TopBar.new()
	_top.hud = self
	_top.position = Vector2(12, 10)
	_top.size = Vector2(760, 46)
	add_child(_top)
	_blockers.append(_top)

	_clock = ClockBar.new()
	_clock.hud = self
	_anchor(_clock, Vector2(1, 0), Rect2(-342, 10, 330, 76))
	add_child(_clock)
	_blockers.append(_clock)

	_mini = Minimap.new()
	_mini.setup(sim, cam, ctrl, local)
	_anchor(_mini, Vector2(0, 1), Rect2(12, -262, 250, 250))
	add_child(_mini)
	_blockers.append(_mini)

	_card = CommandCard.new()
	_card.hud = self
	var card_size := Vector2(SLOT * 4 + GAP * 5, SLOT * 3 + GAP * 4)
	_anchor(_card, Vector2(1, 1), Rect2(-card_size.x - 12, -card_size.y - 12, card_size.x, card_size.y))
	add_child(_card)
	_blockers.append(_card)

	_sel = SelectionPanel.new()
	_sel.hud = self
	_anchor(_sel, Vector2(0.5, 1), Rect2(-300, -184, 600, 172))
	add_child(_sel)
	_blockers.append(_sel)

	if sim.scenario != null:
		_objectives = ObjectivesPanel.new()
		_objectives.hud = self
		_objectives.position = Vector2(12, 66)
		_objectives.size = Vector2(440, 40)
		add_child(_objectives)
		_build_dialog()

	_tip = Tooltip.new()
	_tip.hud = self
	_tip.visible = false
	add_child(_tip)

	_notice = Label.new()
	_anchor(_notice, Vector2(0.5, 0), Rect2(-400, 74, 800, 60))
	_notice.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_notice.add_theme_font_override("font", font_b)
	_notice.add_theme_font_size_override("font_size", 19)
	_notice.add_theme_color_override("font_color", Palette.UI_TEXT)
	_notice.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.7))
	_notice.add_theme_constant_override("shadow_offset_y", 2)
	_notice.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_notice)

	_menu = _make_dialog("Pausa", "", [["Reanudar", func() -> void: toggle_menu()], ["Cómo se juega (F1)", func() -> void: _toggle_help()], ["Opciones", func() -> void: _options.visible = true], ["Nueva partida", func() -> void: main.restart()], ["Menú principal", func() -> void: main.to_menu()], ["Salir", func() -> void: get_tree().quit()]])
	_build_options()
	_build_help()
	_end = _make_dialog("", "", [["Seguir mirando", func() -> void: _end.visible = false], ["Nueva partida", func() -> void: main.restart()], ["Menú principal", func() -> void: main.to_menu()], ["Salir", func() -> void: get_tree().quit()]])
	_end_title = _end.get_meta("title")
	_end_body = _end.get_meta("body")
	# --- paneles ---
	paneles = PANELES.new()
	paneles.setup(self)
	# --- fin paneles ---


## Ancla un control a un punto relativo de la pantalla con márgenes fijos.
static func _anchor(c: Control, at: Vector2, r: Rect2) -> void:
	c.anchor_left = at.x
	c.anchor_right = at.x
	c.anchor_top = at.y
	c.anchor_bottom = at.y
	c.offset_left = r.position.x
	c.offset_top = r.position.y
	c.offset_right = r.position.x + r.size.x
	c.offset_bottom = r.position.y + r.size.y


func _build_dialog() -> void:
	_dialog = PanelContainer.new()
	var sb := panel_box(10)
	sb.bg_color = Color(0.06, 0.065, 0.075, 0.94)
	sb.border_color = Color(Palette.UI_ACCENT, 0.35)
	sb.content_margin_left = 22
	sb.content_margin_right = 22
	sb.content_margin_top = 14
	sb.content_margin_bottom = 16
	_dialog.add_theme_stylebox_override("panel", sb)
	_anchor(_dialog, Vector2(0.5, 0), Rect2(-420, 140, 840, 10))
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 4)
	_dialog.add_child(vb)
	_dialog_who = Label.new()
	_dialog_who.add_theme_font_override("font", font_b)
	_dialog_who.add_theme_font_size_override("font_size", 17)
	_dialog_who.add_theme_color_override("font_color", Palette.UI_ACCENT)
	vb.add_child(_dialog_who)
	_dialog_text = Label.new()
	_dialog_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_dialog_text.custom_minimum_size = Vector2(796, 0)
	_dialog_text.add_theme_font_size_override("font_size", 18)
	vb.add_child(_dialog_text)
	_dialog.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_dialog.visible = false
	add_child(_dialog)


func _next_dialog() -> void:
	if _dialog_queue.is_empty():
		_dialog.visible = false
		return
	var d: Dictionary = _dialog_queue.pop_front()
	_dialog_who.text = d.get("quien", "")
	_dialog_text.text = d.get("texto", "")
	_dialog.visible = true
	_dialog.reset_size()
	_dialog_t = clampf(String(d.get("texto", "")).length() / 16.0, 5.0, 14.0)


func blocks(m: Vector2) -> bool:
	if _menu.visible or _end.visible or (_options != null and _options.visible) or (_help != null and _help.visible):
		return true
	for c in _blockers:
		if c.get_global_rect().has_point(m):
			return true
	return false


func notify(msg: String, secs: float = 2.6) -> void:
	_notice.text = msg
	_notice_t = secs


func queue_icon(item: String) -> String:
	if item.begins_with("@"):
		return sim.dp(local).tecnologias[item.substr(1)]["icono"]
	return Glyphs.resolve(sim.dp(local).unidades.get(item, {}), item)


func on_events(events: Array) -> void:
	# --- paneles ---
	if paneles != null:
		paneles.on_events(events)
	# --- fin paneles ---
	for ev in events:
		var pid: int = ev.get("player", -2)
		match ev["t"]:
			"notify":
				if pid == local:
					notify(ev["msg"])
			"age":
				var name: String = sim.dp(pid).edades[ev["age"] - 1]["nombre"]
				if pid == local:
					var hdef: Dictionary = sim.dp(pid).edificios.get(ev.get("hito", ""), {})
					notify("Edad %s alcanzada · %s\n%s" % [Sim._roman(ev["age"]), name, ctrl.effects_text(hdef.get("efectos", []))], 5.0)
				else:
					notify("%s llegó a la edad %s" % [Palette.TEAM_NAMES[pid], Sim._roman(ev["age"])])
			"tech":
				if pid == local:
					notify("Investigación terminada: %s" % sim.dp(pid).tecnologias[ev["tech"]]["nombre"])
			"alarm":
				if pid == local:
					notify("¡Campana! Los aldeanos se refugian")
			"alert":
				if pid == local:
					notify("¡Nos atacan!")
					_mini.ping(ev["x"], ev["y"])
			"victory":
				if sim.scenario == null:
					_show_end(ev["player"])
			"dialogo":
				_dialog_queue.append(ev)
				if not _dialog.visible:
					_next_dialog()
			"sitio":
				notify("Sitio sagrado tomado por %s" % ("tu pueblo" if pid == local else "el rival"))
			"objetivo":
				match ev["estado"]:
					"hecho":
						notify("✓ " + String(ev["texto"]).substr(0, 90))
					"nuevo":
						notify("Nuevo objetivo: " + String(ev["texto"]).substr(0, 80), 4.0)
					"fallado":
						notify("✗ " + String(ev["texto"]).substr(0, 90), 4.0)
			"mision":
				main.mission_over(ev["resultado"])


func _show_end(winner: int) -> void:
	main.save_replay()
	_end.visible = true
	var p: Dictionary = sim.players[local]
	var st: Dictionary = p["stats"]
	_end_title.text = "Victoria" if winner == local else "Derrota"
	_end_title.add_theme_color_override("font_color", Palette.UI_ACCENT if winner == local else Palette.UI_BAD)
	_end_body.text = "Tiempo %s · Edad %s\nRecursos recolectados %d · Unidades entrenadas %d\nBajas causadas %d · Pérdidas %d" % [_fmt_time(sim.tick * sim.tick_ms / 1000), Sim._roman(p["age"]), st["recolectado"], st["entrenadas"], st["bajas"], st["muertes"]]
	# --- paneles ---
	if paneles != null:
		paneles.show_end(winner)
	# --- fin paneles ---


var _options: PanelContainer
var _help: PanelContainer


func _build_options() -> void:
	_options = _make_dialog("Opciones", "", [["Cerrar", func() -> void: _options.visible = false]])
	var vb: VBoxContainer = _options.get_child(0)
	var at := 2
	for bus in [["General", 0], ["Música", -1], ["Efectos", -2]]:
		var row := HBoxContainer.new()
		var l := Label.new()
		l.text = bus[0]
		l.custom_minimum_size = Vector2(110, 0)
		row.add_child(l)
		var sl := HSlider.new()
		sl.min_value = 0
		sl.max_value = 100
		sl.value = 80
		sl.custom_minimum_size = Vector2(220, 24)
		var which: int = bus[1]
		sl.value_changed.connect(func(v: float) -> void: _set_volume(which, v))
		row.add_child(sl)
		vb.add_child(row)
		vb.move_child(row, at)
		at += 1
	var fs := CheckButton.new()
	fs.text = "Pantalla completa"
	fs.button_pressed = DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN
	fs.toggled.connect(func(on: bool) -> void: DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if on else DisplayServer.WINDOW_MODE_MAXIMIZED))
	vb.add_child(fs)
	vb.move_child(fs, at)
	var edge := CheckButton.new()
	edge.text = "Mover la cámara con los bordes"
	edge.button_pressed = cam.edge_pan
	edge.toggled.connect(func(on: bool) -> void: cam.edge_pan = on)
	vb.add_child(edge)
	vb.move_child(edge, at + 1)


func _set_volume(which: int, v: float) -> void:
	var db := linear_to_db(maxf(v / 100.0, 0.0001))
	if which == 0:
		AudioServer.set_bus_volume_db(0, db)
	elif main.get("audio") != null:
		main.audio.set_volume(which == -1, db)


func _build_help() -> void:
	var dd := sim.dp(local)
	var c: Dictionary = dd.civ
	var civ_txt := ""
	if not c.is_empty():
		civ_txt = "%s — «%s»\n%s" % [c.get("nombre", ""), c.get("frase", ""), c.get("descripcion", "")]
		if dd.has_mod("recurso_propio"):
			civ_txt += "\nRecurso propio: %s." % dd.mod("recurso_propio")["nombre"]
		civ_txt += "\nEdades: %s.\nDebilidad: %s" % [", ".join(c.get("edades", [])), c.get("debilidad", "")]
	var controls := "Clic izquierdo: seleccionar (arrastrar para un grupo; doble clic: todos los del tipo)\nClic derecho: mover, atacar, recolectar, construir, reparar o alojar\nGrilla Q W E R / A S D F / Z X C V: construir, entrenar, investigar\nA y clic: atacar en movimiento · S: detener · Supr: eliminar\nCtrl + 1…9: grupos · H: centro · . : aldeano inactivo · Z en el centro: campana\nFlechas, bordes o botón del medio: cámara · F3: velocidad · Esc: pausa"
	_help = _make_dialog("Cómo se juega", civ_txt + "\n\n" + controls, [["Cerrar", func() -> void: _help.visible = false]])
	(_help.get_meta("body") as Label).horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	(_help.get_meta("body") as Label).custom_minimum_size = Vector2(760, 0)
	(_help.get_meta("body") as Label).autowrap_mode = TextServer.AUTOWRAP_WORD_SMART


func _toggle_help() -> void:
	_help.visible = not _help.visible


func toggle_menu() -> void:
	_menu.visible = not _menu.visible
	main.set_paused(_menu.visible)


func show_tip(cmd: Dictionary, anchor: Rect2) -> void:
	_tip.set("cmd", cmd)
	_tip.visible = true
	var sz: Vector2 = _tip.call("measure")
	_tip.size = sz
	_tip.position = Vector2(clampf(anchor.position.x + anchor.size.x - sz.x, 8, size.x - sz.x - 8), anchor.position.y - sz.y - 10)
	_tip.queue_redraw()


func hide_tip() -> void:
	_tip.visible = false


func _process(delta: float) -> void:
	if _dialog != null and _dialog.visible:
		_dialog_t -= delta
		if _dialog_t <= 0.0:
			_next_dialog()
	if _objectives != null:
		_objectives.queue_redraw()
	_notice_t -= delta
	_notice.modulate.a = clampf(_notice_t / 0.5, 0.0, 1.0)
	_top.queue_redraw()
	_clock.queue_redraw()
	_sel.queue_redraw()
	_card.queue_redraw()


static func _fmt_time(seconds: int) -> String:
	return "%02d:%02d" % [seconds / 60, seconds % 60]


# ---------------------------------------------------------------- Tema y diálogos

func _make_theme() -> Theme:
	var t := Theme.new()
	t.default_font = font
	t.default_font_size = 16
	var btn := StyleBoxFlat.new()
	btn.bg_color = Color(1, 1, 1, 0.06)
	btn.set_corner_radius_all(6)
	btn.content_margin_left = 18
	btn.content_margin_right = 18
	btn.content_margin_top = 10
	btn.content_margin_bottom = 10
	var hov := btn.duplicate() as StyleBoxFlat
	hov.bg_color = Color(1, 1, 1, 0.12)
	var prs := btn.duplicate() as StyleBoxFlat
	prs.bg_color = Color(Palette.UI_ACCENT, 0.3)
	t.set_stylebox("normal", "Button", btn)
	t.set_stylebox("hover", "Button", hov)
	t.set_stylebox("pressed", "Button", prs)
	t.set_stylebox("focus", "Button", StyleBoxEmpty.new())
	t.set_color("font_color", "Button", Palette.UI_TEXT)
	t.set_color("font_hover_color", "Button", Color.WHITE)
	t.set_font("font", "Button", font_b)
	t.set_color("font_color", "Label", Palette.UI_TEXT)
	return t


static func panel_box(radius: int = 8) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Palette.UI_BG
	sb.set_corner_radius_all(radius)
	sb.border_color = Palette.UI_LINE
	sb.set_border_width_all(1)
	sb.shadow_color = Color(0, 0, 0, 0.35)
	sb.shadow_size = 10
	sb.shadow_offset = Vector2(0, 3)
	return sb


func _make_dialog(title: String, body: String, buttons: Array) -> PanelContainer:
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.45)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	var pc := PanelContainer.new()
	var sb := panel_box(10)
	sb.content_margin_left = 36
	sb.content_margin_right = 36
	sb.content_margin_top = 28
	sb.content_margin_bottom = 28
	pc.add_theme_stylebox_override("panel", sb)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 12)
	pc.add_child(vb)
	var tl := Label.new()
	tl.text = title
	tl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tl.add_theme_font_override("font", font_b)
	tl.add_theme_font_size_override("font_size", 34)
	vb.add_child(tl)
	var bl := Label.new()
	bl.text = body
	bl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	bl.add_theme_color_override("font_color", Palette.UI_DIM)
	vb.add_child(bl)
	var sp := Control.new()
	sp.custom_minimum_size = Vector2(0, 6)
	vb.add_child(sp)
	for b in buttons:
		var button := Button.new()
		button.text = b[0]
		button.custom_minimum_size = Vector2(260, 0)
		button.pressed.connect(b[1])
		vb.add_child(button)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	center.add_child(pc)
	dim.add_child(center)
	add_child(dim)
	dim.visible = false
	pc.set_meta("title", tl)
	pc.set_meta("body", bl)
	# Mostrar u ocultar el panel muestra u oculta el fondo oscuro.
	pc.visibility_changed.connect(func() -> void: dim.visible = pc.visible)
	pc.visible = false
	dim.visible = false
	return pc


# ---------------------------------------------------------------- Objetivos de campaña

class ObjectivesPanel:
	extends Control
	var hud: Hud

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		var sc := hud.sim.scenario
		if sc == null:
			return
		var list := sc.active_objectives()
		var y := 34.0
		var lines: Array = []
		for o in list:
			var txt: String = o["texto"]
			var h := Hud.font.get_multiline_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, size.x - 50, 14).y
			lines.append([o, h])
			y += h + 8
		draw_style_box(Hud.panel_box(8), Rect2(Vector2.ZERO, Vector2(size.x, y + 6)))
		draw_string(Hud.font_b, Vector2(14, 24), "Objetivos", HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Palette.UI_ACCENT)
		y = 34.0
		for l in lines:
			var o: Dictionary = l[0]
			var st: String = o["estado"]
			var col := Palette.UI_TEXT
			var mark := "○"
			if st == "hecho":
				col = Palette.UI_GOOD
				mark = "✓"
			elif st == "fallado":
				col = Palette.UI_BAD
				mark = "✗"
			if o.get("secundario", false) and st == "activo":
				col = Palette.UI_DIM
			draw_string(Hud.font_b, Vector2(14, y + 14), mark, HORIZONTAL_ALIGNMENT_LEFT, -1, 15, col)
			draw_multiline_string(Hud.font, Vector2(36, y + 14), o["texto"], HORIZONTAL_ALIGNMENT_LEFT, size.x - 50, 14, -1, col)
			y += float(l[1]) + 8


# ---------------------------------------------------------------- Barra superior

class TopBar:
	extends Control
	var hud: Hud

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_STOP

	func _draw() -> void:
		draw_style_box(Hud.panel_box(), Rect2(Vector2.ZERO, size))
		var sim := hud.sim
		var p: Dictionary = sim.players[hud.local]
		var workers := {"alimento": 0, "madera": 0, "piedra": 0, "riqueza": 0}
		for e in sim.actives:
			if e.owner == hud.local and e.fn == "civil" and (e.order == O.GATHER or e.order == O.RETURN) and workers.has(e.gather_kind):
				workers[e.gather_kind] += 1
		var x := 14.0
		for k in Sim.RES_KINDS:
			Glyphs.draw(self, k, Rect2(x, 9, 28, 28), Palette.RES[k])
			draw_string(Hud.font_b, Vector2(x + 34, 30), str(p["res"][k]), HORIZONTAL_ALIGNMENT_LEFT, -1, 19, Palette.UI_TEXT)
			draw_string(Hud.font, Vector2(x + 34 + 58, 30), str(workers[k]), HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Palette.UI_DIM)
			x += 120
		var dd := sim.dp(hud.local)
		if dd.has_mod("recurso_propio"):
			var rp: Dictionary = dd.mod("recurso_propio")
			var col := Color(rp.get("color", "#cccccc"))
			Glyphs.draw(self, rp.get("icono", "riqueza"), Rect2(x, 9, 28, 28), col)
			var cap: int = p.get("tope_" + rp["clave"], 0)
			draw_string(Hud.font_b, Vector2(x + 34, 30), str(p["res"].get(rp["clave"], 0)), HORIZONTAL_ALIGNMENT_LEFT, -1, 19, col.lightened(0.3))
			draw_string(Hud.font, Vector2(x + 34 + 44, 30), "/%d" % cap if cap > 0 else "", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Palette.UI_DIM)
			x += 130
		draw_line(Vector2(x - 6, 10), Vector2(x - 6, size.y - 10), Palette.UI_LINE, 1)
		var full: bool = p["pop"] >= p["pop_cap"]
		Glyphs.draw(self, "pob", Rect2(x + 6, 9, 26, 28), Palette.UI_BAD if full else Palette.UI_TEXT)
		draw_string(Hud.font_b, Vector2(x + 38, 30), "%d/%d" % [p["pop"], p["pop_cap"]], HORIZONTAL_ALIGNMENT_LEFT, -1, 19, Palette.UI_BAD if full else Palette.UI_TEXT)


class ClockBar:
	extends Control
	var hud: Hud

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_STOP

	func _draw() -> void:
		draw_style_box(Hud.panel_box(), Rect2(Vector2.ZERO, size))
		var sim := hud.sim
		var age: int = sim.players[hud.local]["age"]
		var name: String = sim.dp(hud.local).edades[age - 1]["nombre"]
		draw_string(Hud.font_b, Vector2(16, 30), "Edad %s" % Sim._roman(age), HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Palette.UI_ACCENT)
		draw_string(Hud.font, Vector2(16 + 84, 30), name, HORIZONTAL_ALIGNMENT_LEFT, 150, 16, Palette.UI_TEXT)
		var total := 0
		var mine := 0
		for e in sim.actives:
			if e.def.get("sagrado", false):
				total += 1
				if e.holder == hud.local:
					mine += 1
		if total > 0:
			var left: int = (int(sim.data.reglas["sitios"]["victoria_ms"]) - int(sim.players[hud.local].get("sitios_ms", 0))) / 1000
			var txt := "Sitios %d/%d" % [mine, total]
			if mine == total:
				txt += " · victoria en %s" % Hud._fmt_time(left)
			for p in sim.players:
				if p["id"] != hud.local and int(p.get("sitios_ms", 0)) > 0:
					txt = "¡El rival controla todos los sitios! %s" % Hud._fmt_time((int(sim.data.reglas["sitios"]["victoria_ms"]) - int(p["sitios_ms"])) / 1000)
			draw_string(Hud.font, Vector2(16, 64), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Palette.UI_ACCENT if mine == total else Palette.UI_DIM)
		var secs := sim.tick * sim.tick_ms / 1000
		var t := Hud._fmt_time(secs)
		var speed: float = hud.main.speed
		if speed != 1.0:
			t = "×%s  %s" % [str(speed), t]
		draw_string(Hud.font_b, Vector2(0, 30), t, HORIZONTAL_ALIGNMENT_RIGHT, size.x - 16, 18, Palette.UI_TEXT)


# ---------------------------------------------------------------- Grilla de comandos

class CommandCard:
	extends Control
	var hud: Hud
	var _hover := -1

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_STOP
		mouse_exited.connect(func() -> void:
			_hover = -1
			hud.hide_tip())

	func _slot_rect(i: int) -> Rect2:
		var cx := i % 4
		var cy := i / 4
		return Rect2(Hud.GAP + cx * (Hud.SLOT + Hud.GAP), Hud.GAP + cy * (Hud.SLOT + Hud.GAP), Hud.SLOT, Hud.SLOT)

	func _cmd_at(i: int) -> Dictionary:
		for c in hud.ctrl.commands():
			if c["slot"] == i:
				return c
		return {}

	func _gui_input(event: InputEvent) -> void:
		if event is InputEventMouseMotion:
			var h := -1
			for i in 12:
				if _slot_rect(i).has_point(event.position):
					h = i
			if h != _hover:
				_hover = h
				var c := _cmd_at(h) if h >= 0 else {}
				if c.is_empty():
					hud.hide_tip()
				else:
					hud.show_tip(c, Rect2(global_position, size))
		elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			for i in 12:
				if _slot_rect(i).has_point(event.position):
					var c := _cmd_at(i)
					if not c.is_empty():
						hud.ctrl.run_command(c)
			accept_event()

	func _draw() -> void:
		draw_style_box(Hud.panel_box(), Rect2(Vector2.ZERO, size))
		var cmds := hud.ctrl.commands()
		var by_slot := {}
		for c in cmds:
			by_slot[c["slot"]] = c
		var res: Dictionary = hud.sim.players[hud.local]["res"]
		for i in 12:
			var r := _slot_rect(i)
			var c: Dictionary = by_slot.get(i, {})
			var sb := StyleBoxFlat.new()
			sb.set_corner_radius_all(6)
			if c.is_empty():
				sb.bg_color = Color(1, 1, 1, 0.025)
				draw_style_box(sb, r)
				continue
			var locked: bool = c["locked"] != ""
			var afford := true
			for k in c["cost"]:
				if res.get(k, 0) < c["cost"][k]:
					afford = false
			var active: bool = hud.ctrl.mode == "place" and hud.ctrl.place_type == c["id"] or hud.ctrl.mode == "amove" and c["kind"] == "amove"
			sb.bg_color = Color(1, 1, 1, 0.13 if i == _hover else 0.075)
			if active:
				sb.bg_color = Color(Palette.UI_ACCENT, 0.3)
			sb.border_color = Color(1, 1, 1, 0.1)
			sb.set_border_width_all(1)
			draw_style_box(sb, r)
			var col := Palette.UI_TEXT
			if locked:
				col = Color(Palette.UI_DIM, 0.45)
			elif not afford:
				col = Color(Palette.UI_DIM, 0.8)
			Glyphs.draw(self, c["icon"], r.grow(-12), col)
			draw_string(Hud.font_b, r.position + Vector2(5, 15), Controller.SLOT_LABELS[i], HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(Palette.UI_DIM, 0.9))
			if not afford and not locked:
				draw_rect(Rect2(r.position + Vector2(4, r.size.y - 6), Vector2(r.size.x - 8, 2)), Color(Palette.UI_BAD, 0.8))
		# Progreso de la cola en la ranura del producto actual.
		var sel := hud.ctrl.selected_entities()
		if sel.size() >= 1 and sel[0].is_building() and not sel[0].queue.is_empty():
			var b := sel[0]
			var head: String = b.queue[0].trim_prefix("@")
			for c in cmds:
				if c["id"] == head:
					var r := _slot_rect(c["slot"])
					var k := float(b.queue_progress) / float(hud.sim.dp(b.owner).queue_time(b.queue[0]))
					draw_rect(Rect2(r.position + Vector2(4, r.size.y - 6), Vector2((r.size.x - 8) * k, 3)), Palette.UI_ACCENT)
					var n := b.queue.count(b.queue[0])
					draw_string(Hud.font_b, r.position + Vector2(0, 16), str(n), HORIZONTAL_ALIGNMENT_RIGHT, r.size.x - 6, 14, Palette.UI_ACCENT)


class Tooltip:
	extends Control
	var hud: Hud
	var cmd: Dictionary

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func measure() -> Vector2:
		var w := 330.0
		var h := 44.0
		if not (cmd.get("cost", {}) as Dictionary).is_empty():
			h += 28
		if cmd.get("desc", "") != "":
			var lines := Hud.font.get_multiline_string_size(cmd["desc"], HORIZONTAL_ALIGNMENT_LEFT, w - 28, 15)
			h += lines.y + 6
		if cmd.get("locked", "") != "":
			h += 24
		return Vector2(w, h + 8)

	func _draw() -> void:
		if cmd.is_empty():
			return
		var sb := Hud.panel_box(8)
		sb.bg_color = Palette.UI_BG_2
		draw_style_box(sb, Rect2(Vector2.ZERO, size))
		var y := 28.0
		draw_string(Hud.font_b, Vector2(14, y), "%s  " % cmd["name"], HORIZONTAL_ALIGNMENT_LEFT, size.x - 60, 17, Palette.UI_TEXT)
		draw_string(Hud.font_b, Vector2(0, y), "[%s]" % Controller.SLOT_LABELS[cmd["slot"]], HORIZONTAL_ALIGNMENT_RIGHT, size.x - 14, 13, Palette.UI_DIM)
		y += 12
		var cost: Dictionary = cmd.get("cost", {})
		if not cost.is_empty():
			var res: Dictionary = hud.sim.players[hud.local]["res"]
			var x := 14.0
			var keys: Array = Sim.RES_KINDS.duplicate()
			for k in cost:
				if not keys.has(k):
					keys.append(k)
			for k in keys:
				if not cost.has(k):
					continue
				var rp: Dictionary = hud.sim.dp(hud.local).mod("recurso_propio")
				var col: Color = Palette.RES.get(k, Color(rp.get("color", "#cccccc")))
				Glyphs.draw(self, k if Palette.RES.has(k) else rp.get("icono", "riqueza"), Rect2(x, y + 2, 20, 20), col)
				var ok: bool = res.get(k, 0) >= cost[k]
				draw_string(Hud.font_b, Vector2(x + 24, y + 18), str(cost[k]), HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Palette.UI_TEXT if ok else Palette.UI_BAD)
				x += 78
			y += 28
		if cmd.get("desc", "") != "":
			draw_multiline_string(Hud.font, Vector2(14, y + 14), cmd["desc"], HORIZONTAL_ALIGNMENT_LEFT, size.x - 28, 15, -1, Palette.UI_DIM)
			y += Hud.font.get_multiline_string_size(cmd["desc"], HORIZONTAL_ALIGNMENT_LEFT, size.x - 28, 15).y + 6
		if cmd.get("locked", "") != "":
			draw_string(Hud.font_b, Vector2(14, y + 16), cmd["locked"], HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Palette.UI_BAD)


# ---------------------------------------------------------------- Panel de selección

class SelectionPanel:
	extends Control
	var hud: Hud
	var _hits: Array = [] # [Rect2, acción]

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_STOP

	func _gui_input(event: InputEvent) -> void:
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			for h in _hits:
				if (h[0] as Rect2).has_point(event.position):
					(h[1] as Callable).call()
					break
			accept_event()

	func _draw() -> void:
		_hits.clear()
		draw_style_box(Hud.panel_box(), Rect2(Vector2.ZERO, size))
		var sel := hud.ctrl.selected_entities()
		if sel.is_empty():
			draw_string(Hud.font, Vector2(0, size.y / 2 + 6), "Nada seleccionado", HORIZONTAL_ALIGNMENT_CENTER, size.x, 15, Color(Palette.UI_DIM, 0.6))
			return
		if sel.size() == 1:
			_single(sel[0])
		else:
			_multi(sel)

	func _portrait(r: Rect2, e: SimEntity) -> void:
		var sb := StyleBoxFlat.new()
		sb.set_corner_radius_all(8)
		var team := Palette.team(e.owner)
		sb.bg_color = Color(team, 0.22) if e.owner >= 0 else Color(1, 1, 1, 0.05)
		sb.border_color = Color(team, 0.7) if e.owner >= 0 else Palette.UI_LINE
		sb.set_border_width_all(1)
		draw_style_box(sb, r)
		var icon := Glyphs.resolve(e.def, e.type) if not e.is_resource() else e.res_kind
		var col: Color = Palette.UI_TEXT if not e.is_resource() else Palette.RES[e.res_kind]
		Glyphs.draw(self, icon, r.grow(-18), col)

	func _bar(r: Rect2, k: float, col: Color) -> void:
		draw_rect(r, Color(0, 0, 0, 0.45))
		draw_rect(Rect2(r.position, Vector2(r.size.x * clampf(k, 0, 1), r.size.y)), col)

	func _single(e: SimEntity) -> void:
		var sim := hud.sim
		_portrait(Rect2(14, 14, 112, 112), e)
		var x := 142.0
		var name: String = e.def.get("nombre", e.type)
		draw_string(Hud.font_b, Vector2(x, 36), name, HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Palette.UI_TEXT)
		var who := "Naturaleza" if e.owner < 0 else ("Tu pueblo" if e.owner == hud.local else "Rival · %s" % Palette.TEAM_NAMES[e.owner])
		draw_string(Hud.font, Vector2(x, 58), who, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Palette.UI_DIM)
		if e.is_resource():
			draw_string(Hud.font_b, Vector2(x, 96), "%d %s restantes" % [e.amount, Palette.RES_NAMES[e.res_kind].to_lower()], HORIZONTAL_ALIGNMENT_LEFT, -1, 17, Palette.RES[e.res_kind])
			return
		var hp_col := Palette.UI_GOOD if e.hp * 3 > e.hp_max else Palette.UI_BAD
		_bar(Rect2(14, 134, 112, 7), float(e.hp) / float(e.hp_max), hp_col)
		draw_string(Hud.font, Vector2(14, 160), "%d / %d" % [e.hp, e.hp_max], HORIZONTAL_ALIGNMENT_CENTER, 112, 13, Palette.UI_DIM)
		if e.is_unit():
			var stats := [["Ataque", str(e.def.get("ataque", 0))], ["Armadura", str(e.def.get("armadura", 0))], ["Alcance", "%.1f" % (e.def.get("alcance", 0) / 1000.0)], ["Velocidad", "%.2f" % (e.def.get("velocidad", 0) / 1000.0)]]
			var sx := x
			for s in stats:
				draw_string(Hud.font, Vector2(sx, 92), s[0], HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Palette.UI_DIM)
				draw_string(Hud.font_b, Vector2(sx, 112), s[1], HORIZONTAL_ALIGNMENT_LEFT, -1, 17, Palette.UI_TEXT)
				sx += 92
			var fn_names := {"civil": "Civil", "choque": "Choque", "distancia": "Distancia", "linea": "Línea", "explorador": "Exploración", "asedio": "Asedio"}
			draw_string(Hud.font_b, Vector2(0, 36), fn_names.get(e.fn, ""), HORIZONTAL_ALIGNMENT_RIGHT, size.x - 16, 14, Palette.UI_ACCENT)
			var status := _status(e)
			draw_string(Hud.font, Vector2(x, 146), status, HORIZONTAL_ALIGNMENT_LEFT, size.x - x - 16, 14, Palette.UI_TEXT)
			if e.carry > 0:
				Glyphs.draw(self, e.carry_res, Rect2(size.x - 70, 128, 22, 22), Palette.RES[e.carry_res])
				draw_string(Hud.font_b, Vector2(size.x - 44, 146), str(e.carry), HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Palette.UI_TEXT)
			return
		# Edificio.
		if not e.built:
			var k := float(e.progress) / float(maxi(1, e.build_time))
			draw_string(Hud.font, Vector2(x, 92), "En construcción · %d%%" % int(k * 100), HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Palette.UI_TEXT)
			_bar(Rect2(x, 104, size.x - x - 20, 8), k, Palette.UI_ACCENT)
			return
		if e.def.has("pob"):
			draw_string(Hud.font, Vector2(0, 36), "+%d población" % e.def["pob"], HORIZONTAL_ALIGNMENT_RIGHT, size.x - 16, 13, Palette.UI_DIM)
		var cap := sim.garrison_cap(e)
		if cap > 0:
			var shots: int = int(e.def.get("flechas", 1)) + e.garrison.size()
			draw_string(Hud.font_b, Vector2(0, 58), "Guarnición %d/%d · %d flechas" % [e.garrison.size(), cap, shots], HORIZONTAL_ALIGNMENT_RIGHT, size.x - 16, 13, Palette.UI_ACCENT if not e.garrison.is_empty() else Palette.UI_DIM)
		if e.def.get("fuente", "") != "":
			var f: SimEntity = sim.by_id.get(e.farmer)
			draw_string(Hud.font, Vector2(x, 96), "Trabajada por un aldeano" if f != null and f.alive and f.target == e.id else "Sin aldeano asignado", HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Palette.UI_TEXT)
		var dd := sim.dp(e.owner)
		if e.owner == hud.local and e.capital and dd.has_mod("acogida"):
			var ac: Dictionary = dd.mod("acogida")
			var have: int = sim.players[e.owner]["res"].get(ac["recurso"], 0)
			draw_string(Hud.font, Vector2(x, 140), "La gente llega sola: %d/%d de fama para la próxima persona" % [mini(have, ac["costo"]), ac["costo"]], HORIZONTAL_ALIGNMENT_LEFT, size.x - x - 16, 13, Palette.UI_ACCENT)
		if not e.queue.is_empty() or e.def.has("produce"):
			var qx := x
			for i in sim.data.reglas["cola_max"]:
				var r := Rect2(qx, 78, 52, 52)
				var sb := StyleBoxFlat.new()
				sb.set_corner_radius_all(6)
				sb.bg_color = Color(1, 1, 1, 0.08 if i < e.queue.size() else 0.03)
				draw_style_box(sb, r)
				if i < e.queue.size():
					Glyphs.draw(self, hud.queue_icon(e.queue[i]), r.grow(-9), Palette.UI_ACCENT if e.queue[i].begins_with("@") else Palette.UI_TEXT)
					if i == 0:
						var k := float(e.queue_progress) / float(sim.dp(e.owner).queue_time(e.queue[0]))
						_bar(Rect2(r.position.x + 3, r.end.y - 6, r.size.x - 6, 3), k, Palette.UI_ACCENT)
					var idx: int = i
					var bid := e.id
					_hits.append([r, func() -> void: sim.push_command({"t": "cancel", "player": hud.local, "building": bid, "index": idx})])
				qx += 58
			var p: Dictionary = sim.players[e.owner]
			if not e.queue.is_empty() and e.queue_progress == 0 and p["pop"] >= p["pop_cap"]:
				draw_string(Hud.font_b, Vector2(x, 152), "Población llena: construí casas", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Palette.UI_BAD)
			elif e.queue.is_empty():
				draw_string(Hud.font, Vector2(x, 152), "Clic derecho en el mapa: punto de reunión", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Palette.UI_DIM)

	func _status(e: SimEntity) -> String:
		match e.order:
			O.IDLE:
				return "Inactivo"
			O.MOVE:
				return "En marcha"
			O.ATTACK_MOVE:
				return "Avanzando en combate"
			O.ATTACK:
				return "Combatiendo"
			O.GATHER:
				return "Recolectando %s" % Palette.RES_NAMES.get(e.gather_kind, "").to_lower()
			O.RETURN:
				return "Llevando %s al depósito" % Palette.RES_NAMES.get(e.carry_res, "").to_lower()
			O.BUILD:
				return "Construyendo"
		return ""

	func _multi(sel: Array[SimEntity]) -> void:
		var groups := {}
		var order: Array[String] = []
		for e in sel:
			if not groups.has(e.type):
				groups[e.type] = []
				order.append(e.type)
			groups[e.type].append(e)
		var x := 14.0
		var y := 14.0
		for type in order:
			var list: Array = groups[type]
			var r := Rect2(x, y, 66, 66)
			var sb := StyleBoxFlat.new()
			sb.set_corner_radius_all(7)
			sb.bg_color = Color(Palette.team(hud.local), 0.18)
			sb.border_color = Color(1, 1, 1, 0.08)
			sb.set_border_width_all(1)
			draw_style_box(sb, r)
			Glyphs.draw(self, Glyphs.resolve((list[0] as SimEntity).def, type), r.grow(-12), Palette.UI_TEXT)
			draw_string(Hud.font_b, r.position + Vector2(0, r.size.y - 6), str(list.size()), HORIZONTAL_ALIGNMENT_RIGHT, r.size.x - 6, 16, Palette.UI_ACCENT)
			var hp := 0
			var hpm := 0
			for e: SimEntity in list:
				hp += e.hp
				hpm += e.hp_max
			_bar(Rect2(r.position.x + 4, r.end.y + 4, r.size.x - 8, 4), float(hp) / float(maxi(1, hpm)), Palette.UI_GOOD)
			var ids: Array[int] = []
			for e: SimEntity in list:
				ids.append(e.id)
			_hits.append([r, func() -> void: hud.ctrl.select_ids(ids)])
			x += 74
			if x + 66 > size.x:
				x = 14
				y += 80
		draw_string(Hud.font, Vector2(0, size.y - 14), "%d seleccionadas" % sel.size(), HORIZONTAL_ALIGNMENT_RIGHT, size.x - 16, 13, Palette.UI_DIM)
