extends Control
## Fila de grupos de control (docs/diseno/interfaz/00-auditoria.md, P11 y mejora 9).
##
## Una pestaña por grupo con unidades vivas: número, ícono del tipo más numeroso y cantidad.
## Clic selecciona el grupo; doble clic además centra la cámara. Ctrl + n asigna,
## Mayús + n suma la selección (Controller._key). Va encima del panel de selección.

const ANCHO := 58.0
const ALTO := 40.0
const SEP := 4.0

var hud: Control
var _hits: Array = [] # [Rect2, n]
var _ultimo := -1
var _ultimo_ms := 0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP


## Grupos con unidades vivas: [[n, ids vivos, tipo mayoritario, def]].
func grupos() -> Array:
	var out := []
	var ctrl: Controller = hud.ctrl
	for n in range(1, 10):
		if not ctrl.groups.has(n):
			continue
		var vivos: Array[int] = []
		var cuenta := {}
		var defs := {}
		for id in ctrl.groups[n]:
			var e: SimEntity = hud.sim.by_id.get(id)
			if e == null or not e.alive:
				continue
			vivos.append(id)
			cuenta[e.type] = int(cuenta.get(e.type, 0)) + 1
			defs[e.type] = e.def
		if vivos.is_empty():
			continue
		var top := ""
		for t in cuenta:
			if top == "" or int(cuenta[t]) > int(cuenta[top]):
				top = t
		out.append([n, vivos, top, defs[top]])
	return out


func _has_point(p: Vector2) -> bool:
	for h in _hits:
		if (h[0] as Rect2).has_point(p):
			return true
	return false


func _gui_input(ev: InputEvent) -> void:
	if not (ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT):
		return
	for h in _hits:
		if (h[0] as Rect2).has_point(ev.position):
			var n: int = h[1]
			for g in grupos():
				if g[0] == n:
					hud.ctrl.select_ids(g[1])
			var now := Time.get_ticks_msec()
			if _ultimo == n and now - _ultimo_ms < 350:
				hud.ctrl.center_on_selection()
			_ultimo = n
			_ultimo_ms = now
			accept_event()
			return


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	_hits.clear()
	var x := 0.0
	var sel := {}
	for id in hud.ctrl.selection:
		sel[id] = true
	for g in grupos():
		var r := Rect2(x, size.y - ALTO, ANCHO, ALTO)
		var activo := true
		for id in g[1]:
			if not sel.has(id):
				activo = false
				break
		activo = activo and g[1].size() == sel.size()
		var sb := StyleBoxFlat.new()
		sb.set_corner_radius_all(6)
		sb.bg_color = Color(Palette.UI_ACCENT, 0.28) if activo else Color(Palette.UI_BG, 0.92)
		sb.border_color = Color(Palette.UI_ACCENT, 0.8) if activo else Color(1, 1, 1, 0.12)
		sb.set_border_width_all(1)
		draw_style_box(sb, r)
		draw_string(Hud.font_b, r.position + Vector2(6, 15), str(g[0]), HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Palette.UI_ACCENT)
		Glyphs.draw(self, Glyphs.resolve(g[3], g[2]), Rect2(r.position + Vector2(18, 4), Vector2(22, 22)), Palette.UI_TEXT)
		draw_string(Hud.font_b, r.position + Vector2(0, r.size.y - 4), str((g[1] as Array).size()), HORIZONTAL_ALIGNMENT_RIGHT, r.size.x - 6, 13, Palette.UI_TEXT)
		_hits.append([r, g[0]])
		x += ANCHO + SEP
