extends Control
## Puntaje en vivo (F6): chico, una fila por jugador, con su edad.
## La fórmula está en data/interfaz.json → "puntaje"; es solo informativa.
## Con equipos (docs/11, paso 5) agrupa por equipo con su total, y en la fila de
## cada aliado hay cuatro botones de tributo: un clic manda `tributo_lote` del recurso.

const C := preload("res://src/game/ui/panel_comun.gd")
const ROW := 20.0
const HEAD := 18.0
const TRIB := ["alimento", "madera", "piedra", "riqueza"]

var hud: Hud
var datos # PanelDatos
var _t := 0.0
var _scores: Array = []
var _hits: Array = [] # [Rect2, aliado, recurso]


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	tooltip_text = " " # sin texto Godot no pide `_get_tooltip`


func _teams() -> bool:
	for p in hud.sim.players:
		if p["id"] != hud.local and not hud.sim.enemies(hud.local, p["id"]):
			return true
	var seen := {}
	for p in hud.sim.players:
		var t: int = hud.sim.team_of(p["id"])
		if seen.has(t):
			return true
		seen[t] = true
	return false


## Orden de las filas: por equipo (el tuyo primero) y, dentro, por jugador.
func _order() -> Array:
	var sim := hud.sim
	var ids: Array = range(sim.players.size())
	var mine := sim.team_of(hud.local)
	ids.sort_custom(func(a: int, b: int) -> bool:
		var ta := -1 if sim.team_of(a) == mine else sim.team_of(a)
		var tb := -1 if sim.team_of(b) == mine else sim.team_of(b)
		return ta < tb if ta != tb else a < b)
	return ids


func _process(delta: float) -> void:
	_t -= delta
	if _t <= 0.0 or _scores.size() != hud.sim.players.size():
		_t = 0.5
		_scores.clear()
		for p in hud.sim.players:
			_scores.append(datos.score(p["id"]))
	var teams := _teams()
	var heads := 0
	if teams:
		var last := -99
		for pid in _order():
			if hud.sim.team_of(pid) != last:
				heads += 1
				last = hud.sim.team_of(pid)
	var h := 8.0 + hud.sim.players.size() * ROW + heads * HEAD
	if size.y != h:
		size.y = h
	# Con aliados el panel tiene botones: entonces sí toma los clics.
	var allies := teams and _has_ally()
	mouse_filter = Control.MOUSE_FILTER_STOP if allies else Control.MOUSE_FILTER_IGNORE
	if allies and visible and not hud._blockers.has(self):
		hud._blockers.append(self)
	elif (not allies or not visible) and hud._blockers.has(self):
		hud._blockers.erase(self)
	queue_redraw()


func _has_ally() -> bool:
	for p in hud.sim.players:
		if p["id"] != hud.local and not hud.sim.enemies(hud.local, p["id"]) and not p["defeated"]:
			return true
	return false


func _gui_input(event: InputEvent) -> void:
	var mb := event as InputEventMouseButton
	if mb == null or not mb.pressed or mb.button_index != MOUSE_BUTTON_LEFT:
		return
	for h in _hits:
		if (h[0] as Rect2).has_point(mb.position):
			var n := int(hud.sim.data.reglas["equipos"].get("tributo_lote", 100))
			hud.sim.push_command({"t": "tributo", "player": hud.local, "a": h[1], "recurso": h[2], "n": n})
			accept_event()
			return


func _draw() -> void:
	var sim := hud.sim
	var sb := Hud.panel_box(8)
	sb.shadow_size = 4
	draw_style_box(sb, Rect2(Vector2.ZERO, size))
	_hits.clear()
	var y := 4.0
	var best := 1
	for s in _scores:
		best = maxi(best, s)
	var teams := _teams()
	var last := -99
	for pid in _order():
		var p: Dictionary = sim.players[pid]
		var tm := sim.team_of(pid)
		if teams and tm != last:
			last = tm
			var tot := 0
			for q in sim.players.size():
				if sim.team_of(q) == tm and q < _scores.size():
					tot += _scores[q]
			var label := "Tu equipo" if tm == sim.team_of(hud.local) else "Equipo %d" % (tm + 1)
			C.text(self, Vector2(10, y + 13), label, 11, Palette.UI_ACCENT, true, size.x - 80)
			C.text(self, Vector2(0, y + 13), str(tot), 11, Palette.UI_ACCENT, true, size.x - 10, HORIZONTAL_ALIGNMENT_RIGHT)
			y += HEAD
		var col := Palette.team(pid)
		draw_rect(Rect2(10, y + 5, 4, ROW - 10), col)
		var name := C.player_name(sim, pid, hud.local)
		var ally: bool = pid != hud.local and not sim.enemies(hud.local, pid) and not p["defeated"]
		var name_w := size.x - (230.0 if ally else 150.0)
		var f := Hud.font_b if pid == hud.local else Hud.font
		while name.length() > 3 and f.get_string_size(name, HORIZONTAL_ALIGNMENT_LEFT, -1, 12).x > name_w - 22:
			name = name.left(-2) + "…"
		C.text(self, Vector2(22, y + 15), name, 12, Palette.UI_TEXT if pid == hud.local else Palette.UI_DIM, pid == hud.local, name_w)
		if ally:
			# Botones de tributo: un ícono por recurso, antes de la edad.
			for i in TRIB.size():
				var r := Rect2(size.x - 222 + i * 22, y + 2, 18, ROW - 4)
				draw_rect(r, Color(0, 0, 0, 0.35))
				Glyphs.draw(self, C.res_icon(sim, hud.local, TRIB[i]), r.grow(-2), C.res_color(sim, hud.local, TRIB[i]))
				_hits.append([r, pid, TRIB[i]])
		C.text(self, Vector2(size.x - 128, y + 15), Sim._roman(p["age"]), 12, Palette.UI_DIM, true)
		var sc: int = _scores[pid] if pid < _scores.size() else 0
		C.bar(self, Rect2(size.x - 104, y + 9, 40, 4), float(sc) / best, col)
		C.text(self, Vector2(0, y + 15), "✗" if p["defeated"] else str(sc), 13, Palette.UI_TEXT, true, size.x - 10, HORIZONTAL_ALIGNMENT_RIGHT)
		y += ROW


func _get_tooltip(at: Vector2) -> String:
	for h in _hits:
		if (h[0] as Rect2).has_point(at):
			var n := int(hud.sim.data.reglas["equipos"].get("tributo_lote", 100))
			var com := int(hud.sim.data.reglas["equipos"]["tributo_comision_pct"])
			return "Mandar %d de %s a %s (llega %d: %d %% de comisión)" % [n, C.res_name(hud.sim, hud.local, h[2]), Palette.team_name(h[1]), n * (100 - com) / 100, com]
	return ""
