extends Control
## Pantalla de fin de partida con estadísticas: comparación entre jugadores,
## gráfico en el tiempo (muestras de la interfaz cada 30 s), riqueza por origen
## y línea de tiempo de edades.

const C := preload("res://src/game/ui/panel_comun.gd")
const BOX := Vector2(1560, 900)
const CHARTS := [["pop", "Población"], ["vill", "Aldeanos"], ["army", "Ejército"], ["juntado", "Recursos juntados"], ["riqueza", "Riqueza juntada"], ["score", "Puntaje"]]
const ORIGIN_COLORS := {
	"casa": Color("c9a227"), "granja": Color("a9a066"), "recoleccion": Color("8c7258"), "disputado": Color("d4553a"),
	"sitios": Color("b07cc6"), "saqueo": Color("9b3d3d"), "mercado": Color("5aa0a8"), "renta": Color("6c9c5a"), "propio": Color("e3b23c"),
}

var hud: Hud
var datos # PanelDatos
var winner := -1
var _chart := 0
var _tabs: Array = [] # [Rect2, índice]
var _box := Rect2()


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP


func open(w: int) -> void:
	winner = w
	datos.close()
	visible = true
	for c in get_children():
		c.queue_free()
	var buttons := [
		["Seguir mirando", func() -> void: visible = false],
		["Nueva partida", func() -> void: hud.main.restart()],
		["Menú principal", func() -> void: hud.main.to_menu()],
		["Salir", func() -> void: get_tree().quit()],
	]
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 12)
	for b in buttons:
		var btn := Button.new()
		btn.text = b[0]
		btn.custom_minimum_size = Vector2(220, 0)
		btn.pressed.connect(b[1])
		hb.add_child(btn)
	add_child(hb)
	hb.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_place_buttons.call_deferred(hb)


func _place_buttons(hb: HBoxContainer) -> void:
	hb.reset_size()
	var r := _box_rect()
	hb.position = Vector2(r.position.x + (r.size.x - hb.size.x) / 2, r.end.y - hb.size.y - 22)


func _box_rect() -> Rect2:
	var s := size
	var bs := Vector2(minf(BOX.x, s.x - 40), minf(BOX.y, s.y - 40))
	return Rect2((s - bs) / 2, bs)


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		for t in _tabs:
			if (t[0] as Rect2).has_point(event.position):
				_chart = t[1]
				queue_redraw()
		accept_event()


func _process(_d: float) -> void:
	if visible:
		queue_redraw()


func _draw() -> void:
	_tabs.clear()
	draw_rect(Rect2(Vector2.ZERO, size), Color(0, 0, 0, 0.55))
	_box = _box_rect()
	var sb := Hud.panel_box(10)
	sb.bg_color = Color(0.07, 0.075, 0.085, 0.97)
	draw_style_box(sb, _box)
	var o := _box.position
	var sim := hud.sim
	var won := winner == hud.local
	var head := "Victoria" if won else ("Fin de la partida" if winner < 0 else "Derrota")
	C.text(self, o + Vector2(32, 56), head, 40, Palette.UI_ACCENT if won else Palette.UI_BAD, true)
	var secs: int = datos.now_s()
	var sub := "Duración %s · mapa %s" % [C.fmt_time(secs), sim.terrain]
	if winner >= 0 and winner != hud.local:
		sub += " · ganó %s" % C.player_name(sim, winner, hud.local)
	C.text(self, o + Vector2(36, 86), sub, 15, Palette.UI_DIM)

	var col_w := (_box.size.x - 96) / 2
	_table(Rect2(o + Vector2(32, 116), Vector2(col_w, 430)))
	_chart_box(Rect2(o + Vector2(64 + col_w, 116), Vector2(col_w, 430)))
	_origins(Rect2(o + Vector2(32, 572), Vector2(col_w, 220)))
	_timeline(Rect2(o + Vector2(64 + col_w, 572), Vector2(col_w, 220)))


# ---------------------------------------------------------------- Comparación

func _table(r: Rect2) -> void:
	var sim := hud.sim
	C.title(self, r.position + Vector2(0, 0), "COMPARACIÓN")
	var n := sim.players.size()
	var label_w := 230.0
	var cw := (r.size.x - label_w) / n
	var y := r.position.y + 28
	for p in sim.players:
		var pid: int = p["id"]
		var x: float = r.position.x + label_w + pid * cw
		draw_rect(Rect2(x + 6, y - 12, cw - 12, 3), Palette.team(pid))
		C.text(self, Vector2(x, y + 8), C.player_name(sim, pid, hud.local), 13, Palette.UI_TEXT, true, cw - 6, HORIZONTAL_ALIGNMENT_RIGHT)
	y += 18
	var secs := maxi(1, datos.now_s())
	var rows: Array = []
	rows.append(["Edad final", func(pid: int) -> int: return int(sim.players[pid]["age"]), "roman"])
	rows.append(["Puntaje", func(pid: int) -> int: return datos.score(pid), ""])
	rows.append(["Población final", func(pid: int) -> int: return int(sim.players[pid]["pop"]), ""])
	rows.append(["Población máxima", func(pid: int) -> int: return _max_of(pid, "pop"), ""])
	rows.append(["Recursos juntados", func(pid: int) -> int: return _sum(datos.totals(pid)), ""])
	rows.append(["Riqueza juntada", func(pid: int) -> int: return int(datos.totals(pid).get("riqueza", 0)), ""])
	rows.append(["Unidades entrenadas", func(pid: int) -> int: return int(sim.players[pid]["stats"]["entrenadas"]), ""])
	rows.append(["Bajas causadas", func(pid: int) -> int: return int(sim.players[pid]["stats"]["bajas"]), ""])
	rows.append(["Unidades perdidas", func(pid: int) -> int: return int(sim.players[pid]["stats"]["muertes"]), "low"])
	rows.append(["Edificios construidos", func(pid: int) -> int: return int(datos.built[pid]), ""])
	rows.append(["Edificios destruidos", func(pid: int) -> int: return int(datos.razed[pid]), ""])
	rows.append(["Edificios perdidos", func(pid: int) -> int: return int(datos.lost_b[pid]), "low"])
	rows.append(["Investigaciones", func(pid: int) -> int: return (sim.players[pid]["techs"] as Dictionary).size(), ""])
	rows.append(["Órdenes por minuto", func(pid: int) -> int: return datos.orders(pid) * 60 / secs, "none"])
	for row in rows:
		y += 25
		draw_line(Vector2(r.position.x, y + 7), Vector2(r.end.x, y + 7), Palette.UI_LINE, 1)
		C.text(self, Vector2(r.position.x, y), row[0], 14, Palette.UI_DIM)
		var vals: Array[int] = []
		for p in sim.players:
			vals.append((row[1] as Callable).call(p["id"]))
		var best: int = vals.max() if row[2] != "low" else vals.min()
		for pid in n:
			var v: int = vals[pid]
			var txt := Sim._roman(v) if row[2] == "roman" else str(v)
			var hi: bool = row[2] != "none" and v == best and n > 1 and vals.count(best) < n
			C.text(self, Vector2(r.position.x + label_w + pid * cw, y), txt, 15, Palette.UI_ACCENT if hi else Palette.UI_TEXT, hi, cw - 6, HORIZONTAL_ALIGNMENT_RIGHT)


func _sum(d: Dictionary) -> int:
	var s := 0
	for k in d:
		s += int(d[k])
	return s


func _max_of(pid: int, key: String) -> int:
	var m := 0
	for s in datos.samples:
		if pid < (s["p"] as Array).size():
			m = maxi(m, int(s["p"][pid][key]))
	return m


# ---------------------------------------------------------------- Gráfico

func _chart_box(r: Rect2) -> void:
	var sim := hud.sim
	C.title(self, r.position, "EN EL TIEMPO · cada %d s" % datos.sample_s)
	# Pestañas.
	var x := r.position.x
	var ty := r.position.y + 12
	for i in CHARTS.size():
		var label: String = CHARTS[i][1]
		var tw := Hud.font_b.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, 12).x + 20
		var tr := Rect2(x, ty, tw, 24)
		var tsb := StyleBoxFlat.new()
		tsb.set_corner_radius_all(5)
		tsb.bg_color = Color(Palette.UI_ACCENT, 0.3) if i == _chart else Color(1, 1, 1, 0.06)
		draw_style_box(tsb, tr)
		C.text(self, Vector2(x + 10, ty + 17), label, 12, Palette.UI_TEXT, true)
		_tabs.append([tr, i])
		x += tw + 6
	var key: String = CHARTS[_chart][0]
	var plot := Rect2(r.position.x + 48, r.position.y + 54, r.size.x - 60, r.size.y - 84)
	draw_rect(plot, Color(1, 1, 1, 0.025))
	var samples: Array = datos.samples
	var t_max := maxi(1, int(samples[-1]["t"])) if not samples.is_empty() else 1
	var v_max := 1
	for s in samples:
		for pv in s["p"]:
			v_max = maxi(v_max, int(pv[key]))
	v_max = _nice(v_max)
	# Grilla y ejes.
	for i in 5:
		var gy := plot.end.y - plot.size.y * i / 4.0
		draw_line(Vector2(plot.position.x, gy), Vector2(plot.end.x, gy), Color(1, 1, 1, 0.06), 1)
		C.text(self, Vector2(plot.position.x - 48, gy + 4), str(v_max * i / 4), 11, Palette.UI_DIM, false, 42, HORIZONTAL_ALIGNMENT_RIGHT)
	var step_min := maxi(1, int(ceil(t_max / 60.0 / 8.0)))
	var m := 0
	while m * 60 <= t_max:
		var gx := plot.position.x + plot.size.x * (m * 60.0) / t_max
		draw_line(Vector2(gx, plot.end.y), Vector2(gx, plot.end.y + 4), Palette.UI_DIM, 1)
		C.text(self, Vector2(gx - 20, plot.end.y + 18), "%d'" % m, 11, Palette.UI_DIM, false, 40, HORIZONTAL_ALIGNMENT_CENTER)
		m += step_min
	# Edades como líneas verticales finas.
	for a in datos.ages:
		var ax := plot.position.x + plot.size.x * float(a["t"]) / t_max
		draw_line(Vector2(ax, plot.position.y), Vector2(ax, plot.end.y), Color(Palette.team(a["player"]), 0.35), 1)
	# Una línea por jugador.
	for pid in sim.players.size():
		var pts := PackedVector2Array()
		for s in samples:
			if pid >= (s["p"] as Array).size():
				continue
			var px := plot.position.x + plot.size.x * float(s["t"]) / t_max
			var py := plot.end.y - plot.size.y * float(s["p"][pid][key]) / v_max
			pts.append(Vector2(px, py))
		if pts.size() >= 2:
			draw_polyline(pts, Palette.team(pid), 2.5 if pid == hud.local else 2.0, true)
		for pt in pts:
			draw_circle(pt, 2.5, Palette.team(pid))


func _nice(v: int) -> int:
	var mag := 1
	while mag * 10 <= v:
		mag *= 10
	for k in [1, 2, 4, 5, 10]:
		if v <= k * mag:
			return k * mag
	return v


# ---------------------------------------------------------------- Riqueza por origen

func _origins(r: Rect2) -> void:
	var sim := hud.sim
	C.title(self, r.position, "RIQUEZA POR ORIGEN")
	var y := r.position.y + 18
	var best := 1
	for p in sim.players:
		best = maxi(best, int(datos.totals(p["id"]).get("riqueza", 0)))
	var used := {}
	for p in sim.players:
		var pid: int = p["id"]
		var book: Dictionary = datos.origin_book(pid)
		C.text(self, Vector2(r.position.x, y + 16), C.player_name(sim, pid, hud.local), 13, Palette.UI_TEXT, pid == hud.local, 200)
		var bx := r.position.x + 210
		var bw := r.size.x - 210 - 60
		draw_rect(Rect2(bx, y + 4, bw, 16), Color(0, 0, 0, 0.45))
		var total := 0
		for o in C.ORIGIN_ORDER:
			var n := int(book.get(o, {}).get("riqueza", 0))
			if n <= 0:
				continue
			total += n
			used[o] = true
			var seg := bw * n / float(best)
			draw_rect(Rect2(bx, y + 4, seg, 16), ORIGIN_COLORS.get(o, Palette.UI_DIM))
			bx += seg
		C.text(self, Vector2(r.position.x, y + 17), str(total), 13, Palette.UI_TEXT, true, r.size.x, HORIZONTAL_ALIGNMENT_RIGHT)
		y += 30
	# Leyenda.
	var lx := r.position.x
	y += 8
	for o in C.ORIGIN_ORDER:
		if not used.has(o):
			continue
		var label: String = C.ORIGIN_NAMES[o]
		var lw := Hud.font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, 12).x + 30
		if lx + lw > r.end.x:
			lx = r.position.x
			y += 20
		draw_rect(Rect2(lx, y + 3, 11, 11), ORIGIN_COLORS[o])
		C.text(self, Vector2(lx + 16, y + 13), label, 12, Palette.UI_DIM)
		lx += lw
	if used.is_empty():
		C.text(self, Vector2(r.position.x, y + 13), "Nadie juntó riqueza.", 13, Palette.UI_DIM)


# ---------------------------------------------------------------- Edades

func _timeline(r: Rect2) -> void:
	var sim := hud.sim
	C.title(self, r.position, "LÍNEA DE TIEMPO DE EDADES")
	var t_max := maxi(60, datos.now_s())
	var ax0 := r.position.x + 210
	var aw := r.size.x - 220
	var y := r.position.y + 34
	for p in sim.players:
		var pid: int = p["id"]
		C.text(self, Vector2(r.position.x, y + 14), C.player_name(sim, pid, hud.local), 13, Palette.UI_TEXT, pid == hud.local, 200)
		draw_line(Vector2(ax0, y + 9), Vector2(ax0 + aw, y + 9), Color(1, 1, 1, 0.12), 2)
		for a in datos.ages:
			if a["player"] != pid:
				continue
			var x := ax0 + aw * float(a["t"]) / t_max
			draw_circle(Vector2(x, y + 9), 5, Palette.team(pid))
			C.text(self, Vector2(x - 20, y - 1), Sim._roman(a["age"]), 12, Palette.UI_TEXT, true, 40, HORIZONTAL_ALIGNMENT_CENTER)
			var hdef: Dictionary = sim.dp(pid).edificios.get(a["hito"], {})
			if not hdef.is_empty():
				var eje := C.eje_of(hdef, a["hito"])
				C.text(self, Vector2(x - 70, y + 30), "%s %s" % [C.fmt_time(a["t"]), hdef.get("nombre", "")], 11, C.eje_color(eje), false, 140, HORIZONTAL_ALIGNMENT_CENTER)
		if p["defeated"]:
			C.text(self, Vector2(ax0 + aw - 10, y + 14), "✗", 14, Palette.UI_BAD, true)
		y += 50
	# Eje de tiempo.
	var step_min := maxi(1, int(ceil(t_max / 60.0 / 6.0)))
	var m := 0
	while m * 60 <= t_max:
		var x := ax0 + aw * (m * 60.0) / t_max
		C.text(self, Vector2(x - 20, y + 4), "%d'" % m, 11, Palette.UI_DIM, false, 40, HORIZONTAL_ALIGNMENT_CENTER)
		m += step_min
