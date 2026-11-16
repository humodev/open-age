extends Control
## Pantalla de fin de partida con estadísticas: comparación entre jugadores,
## gráfico en el tiempo (muestras de la interfaz cada 30 s), riqueza por origen
## y línea de tiempo de edades.

const C := preload("res://src/game/ui/panel_comun.gd")
const BOX := Vector2(1560, 900)
const BUTTONS_H := 70.0 # --- equipos ronda 3 --- alto reservado a los botones de abajo
const CHARTS := [["pop", "Población"], ["vill", "Aldeanos"], ["army", "Ejército"], ["juntado", "Recursos juntados"], ["riqueza", "Riqueza juntada"], ["age", "Edad"], ["score", "Puntaje"]]
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
var _why := "" # --- aprender --- por qué terminó (una línea)
var _tips: Array[String] = [] # consejos concretos si perdiste


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP


func open(w: int) -> void:
	winner = w
	datos.close()
	_explain() # --- aprender ---
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
	var head := "Victoria" if won else ("Empate" if winner < 0 and sim.end_reason == "tiempo" else ("Fin de la partida" if winner < 0 else "Derrota"))
	C.text(self, o + Vector2(32, 56), head, 40, Palette.UI_ACCENT if won else (Palette.UI_NEUTRAL if winner < 0 else Palette.UI_BAD), true)
	var secs: int = datos.now_s()
	var sub := "Duración %s · mapa %s" % [C.fmt_time(secs), sim.terrain]
	if winner >= 0 and winner != hud.local:
		sub += " · ganó %s" % _winner_name(winner) # --- equipos ronda 3 ---
	C.text(self, o + Vector2(36, 86), sub, 15, Palette.UI_DIM)
	# --- aprender --- por qué terminó y qué probar la próxima vez
	var dy := 0.0
	if _why != "":
		C.text(self, o + Vector2(36, 116), _why, 17, Palette.UI_TEXT, true, _box.size.x - 72)
		dy += 28
	for tip in _tips:
		C.text(self, o + Vector2(36, 116 + dy), "Consejo: " + tip, 15, Palette.UI_ACCENT, false, _box.size.x - 72)
		dy += 24
	dy = dy + 8.0 if dy > 0.0 else 0.0
	# --- fin aprender ---

	var col_w := (_box.size.x - 96) / 2
	_table(Rect2(o + Vector2(32, 116 + dy), Vector2(col_w, 430 - dy * 0.6)))
	_chart_box(Rect2(o + Vector2(64 + col_w, 116 + dy), Vector2(col_w, 430 - dy)))
	# --- equipos ronda 3 --- lo de abajo termina sobre los botones (con 6 a 8 jugadores los tapaba)
	var low_y := 572 + dy * 0.6
	var low_h := maxf(120.0, _box.size.y - low_y - BUTTONS_H)
	_origins(Rect2(o + Vector2(32, low_y), Vector2(col_w, low_h)))
	_timeline(Rect2(o + Vector2(64 + col_w, low_y), Vector2(col_w, low_h)))


# ---------------------------------------------------------------- Comparación

func _table(r: Rect2) -> void:
	var sim := hud.sim
	C.title(self, r.position + Vector2(0, 0), "COMPARACIÓN")
	var n := sim.players.size()
	var label_w := 230.0 if n <= 4 else 170.0
	var cw := (r.size.x - label_w) / n
	var y := r.position.y + 28
	# --- equipos ronda 3 --- columnas agrupadas por equipo (el tuyo primero), con el nombre y el
	# puntaje del equipo arriba de sus columnas.
	var order := _order()
	var col_of := {}
	for i in order.size():
		col_of[order[i]] = i
	if _teams():
		var i0 := 0
		while i0 < order.size():
			var t := sim.team_of(order[i0])
			var i1 := i0
			while i1 + 1 < order.size() and sim.team_of(order[i1 + 1]) == t:
				i1 += 1
			var gx: float = r.position.x + label_w + i0 * cw
			var gw: float = (i1 - i0 + 1) * cw
			draw_rect(Rect2(gx + 4, y - 8, gw - 8, 1), Palette.UI_LINE)
			var gl := "%s · %d" % [_team_name(t), sim.team_score(t)]
			if Hud.font_b.get_string_size(gl, HORIZONTAL_ALIGNMENT_LEFT, -1, 12).x > gw - 8:
				gl = "Equipo %d · %d" % [t + 1, sim.team_score(t)]
			C.text(self, Vector2(gx, y + 6), gl, 12, Palette.UI_ACCENT if t == sim.team_of(hud.local) else Palette.UI_DIM, true, gw - 6, HORIZONTAL_ALIGNMENT_RIGHT)
			i0 = i1 + 1
		y += 28
	for pid in order:
		var x: float = r.position.x + label_w + int(col_of[pid]) * cw
		draw_rect(Rect2(x + 6, y - 12, cw - 12, 3), Palette.team(pid))
		C.text(self, Vector2(x, y + 8), C.player_name(sim, pid, hud.local) if n <= 4 else _short_name(pid), 13, Palette.UI_TEXT, true, cw - 6, HORIZONTAL_ALIGNMENT_RIGHT)
	y += 18
	var row_h := 25.0 if n <= 4 else 23.0
	# --- fin equipos ronda 3 ---
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
	rows.append(["Edificios destruidos", func(pid: int) -> int: return int(sim.players[pid]["stats"].get("edificios_destruidos", 0)), ""])
	rows.append(["Edificios perdidos", func(pid: int) -> int: return int(datos.lost_b[pid]), "low"])
	rows.append(["Investigaciones", func(pid: int) -> int: return (sim.players[pid]["techs"] as Dictionary).size(), ""])
	rows.append(["Órdenes por minuto", func(pid: int) -> int: return datos.orders(pid) * 60 / secs, "none"])
	for row in rows:
		y += row_h
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
			C.text(self, Vector2(r.position.x + label_w + int(col_of[pid]) * cw, y), txt, 15, Palette.UI_ACCENT if hi else Palette.UI_TEXT, hi, cw - 6, HORIZONTAL_ALIGNMENT_RIGHT)


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
	# --- equipos ronda 3 --- por equipo, y más apretado con muchos jugadores (deja lugar a la leyenda)
	var step := clampf((r.size.y - 18 - 48) / maxf(1.0, sim.players.size()), 20.0, 30.0)
	for pid: int in _order():
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
		y += step
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
	# --- equipos ronda 3 --- filas por equipo, del alto que entra en el recuadro: con 6 a 8
	# jugadores tapaban los botones. Si no entra el nombre del hito, queda solo la edad.
	var row_h := clampf((r.size.y - 34 - 22) / maxf(1.0, sim.players.size()), 22.0, 50.0)
	var roomy := row_h >= 44.0
	for pid: int in _order():
		var p: Dictionary = sim.players[pid]
		C.text(self, Vector2(r.position.x, y + 14), C.player_name(sim, pid, hud.local), 13, Palette.UI_TEXT, pid == hud.local, 200)
		draw_line(Vector2(ax0, y + 9), Vector2(ax0 + aw, y + 9), Color(1, 1, 1, 0.12), 2)
		for a in datos.ages:
			if a["player"] != pid:
				continue
			var x := ax0 + aw * float(a["t"]) / t_max
			draw_circle(Vector2(x, y + 9), 5, Palette.team(pid))
			if roomy:
				C.text(self, Vector2(x - 20, y - 1), Sim._roman(a["age"]), 12, Palette.UI_TEXT, true, 40, HORIZONTAL_ALIGNMENT_CENTER)
			else:
				C.text(self, Vector2(x + 7, y + 14), Sim._roman(a["age"]), 11, Palette.UI_TEXT, true, 30)
			var hdef: Dictionary = sim.dp(pid).edificios.get(a["hito"], {})
			if not hdef.is_empty() and roomy:
				var eje := C.eje_of(hdef, a["hito"])
				C.text(self, Vector2(x - 70, y + 30), "%s %s" % [C.fmt_time(a["t"]), hdef.get("nombre", "")], 11, C.eje_color(eje), false, 140, HORIZONTAL_ALIGNMENT_CENTER)
		if p["defeated"]:
			C.text(self, Vector2(ax0 + aw - 10, y + 14), "✗", 14, Palette.UI_BAD, true)
		y += row_h
	# Eje de tiempo.
	var step_min := maxi(1, int(ceil(t_max / 60.0 / 6.0)))
	var m := 0
	while m * 60 <= t_max:
		var x := ax0 + aw * (m * 60.0) / t_max
		C.text(self, Vector2(x - 20, y + 4), "%d'" % m, 11, Palette.UI_DIM, false, 40, HORIZONTAL_ALIGNMENT_CENTER)
		m += step_min


# ---------------------------------------------------------------- Por qué terminó (--- aprender ---)

## Tiempo límite (opciones de partida): quién ganó y por cuántos puntos (Sim.team_score).
func _why_time(real: int, me: int) -> String:
	var sim := hud.sim
	var mins := int(sim._opts.get("tiempo_limite_min", 0))
	var mine_s := sim.team_score(sim.team_of(me))
	var best_foe := -1
	for p in sim.players:
		if sim.enemies(me, p["id"]):
			best_foe = maxi(best_foe, sim.team_score(sim.team_of(p["id"])))
	var head := "Se cumplió el tiempo límite (%d minutos)" % mins
	if real < 0:
		return "%s con empate: %d puntos para cada lado." % [head, mine_s]
	if not sim.enemies(me, real):
		return "%s y ganaste por puntos: %d contra %d." % [head, mine_s, best_foe]
	return "%s y ganó %s por puntos: %d contra tus %d." % [head, _winner_name(real), sim.team_score(sim.team_of(real)), mine_s] # --- equipos ronda 3 ---


## Una línea con el motivo del final y, si perdiste, uno o dos consejos que salen de las
## muestras de la partida (proceso/23-como-aoe4/03-aprender-a-jugar.md).
func _explain() -> void:
	var sim := hud.sim
	var me := hud.local
	var cfg: Dictionary = datos.cfg.get("fin", {})
	_why = ""
	_tips.clear()
	var win_ms := int(sim.data.reglas["sitios"]["victoria_ms"])
	var real := sim.winner if sim.game_over else -1
	if not sim.game_over:
		_why = "La partida sigue: esto es un resumen de lo jugado hasta ahora."
	elif sim.end_reason == "tiempo":
		_why = _why_time(real, me)
	elif real < 0:
		_why = "La partida terminó sin ganador."
	else:
		var by_sites := false
		for p in sim.players:
			if not sim.enemies(real, p["id"]) and int(p.get("sitios_ms", 0)) >= win_ms:
				by_sites = true
		var mine := not sim.enemies(me, real)
		var who := _winner_name(real) # --- equipos ronda 3 ---
		if by_sites:
			_why = ("Ganaste por sitios sagrados: los tuviste todos durante %s." if mine else "Perdiste por sitios sagrados: %s los tuvo todos durante %s seguidos.") % ([C.fmt_time(win_ms / 1000)] if mine else [who, C.fmt_time(win_ms / 1000)])
		elif sim._opts.get("hitos_sin_victoria", false):
			_why = "Ganaste por conquista: arrasaste todos los edificios del rival." if mine else "Perdiste por conquista: %s arrasó todos tus edificios." % who
		else:
			_why = "Ganaste por conquista: el rival se quedó sin capital ni hitos." if mine else "Perdiste por conquista: %s destruyó tu capital y tus hitos." % who
	var lost := sim.game_over and real >= 0 and sim.enemies(me, real)
	if not lost:
		return
	# El rival de referencia: el ganador.
	var rv := real
	var samples: Array = datos.samples
	var n := maxi(1, samples.size())
	var idle_sum := 0
	var bank_sum := 0
	var site_s := 0
	var vill_me := 0
	var vill_rv := 0
	var army_me := 0
	var army_rv := 0
	for smp in samples:
		var row: Array = smp["p"]
		if me < row.size():
			idle_sum += int(row[me].get("ociosos", 0))
			bank_sum += int(row[me].get("banco", 0))
			vill_me = maxi(vill_me, int(row[me]["vill"]))
			army_me = maxi(army_me, int(row[me]["army"]))
		if rv < row.size():
			vill_rv = maxi(vill_rv, int(row[rv]["vill"]))
			army_rv = maxi(army_rv, int(row[rv]["army"]))
		for q in row.size():
			if sim.enemies(me, q) and int(row[q].get("sitios_ms", 0)) > 0:
				site_s += datos.sample_s
				break
	if site_s >= 60:
		_tips.append("el rival tuvo todos los sitios sagrados unos %d minutos. Cuando aparece la cuenta grande arriba al centro, llevá tropas a pararse en un sitio: con tener uno se corta." % maxi(1, site_s / 60))
	if idle_sum / n >= int(cfg.get("ociosos_prom", 3)):
		_tips.append("tuviste %d aldeanos ociosos en promedio. La tecla punto (.) elige uno sin trabajo; el aviso «aldeanos sin trabajo» te lo recuerda." % (idle_sum / n))
	if vill_rv > 0 and vill_me * 100 < vill_rv * int(cfg.get("aldeanos_pct", 70)):
		_tips.append("el rival llegó a %d aldeanos y vos a %d. Entrená aldeanos sin parar desde el centro: son los que juntan todo." % [vill_rv, vill_me])
	var t_me: int = datos.age_time(me, 2)
	var t_rv: int = datos.age_time(rv, 2)
	if t_rv >= 0 and (t_me < 0 or t_me - t_rv >= int(cfg.get("edad_tarde_s", 120))):
		_tips.append("el rival llegó a la edad II a los %s; vos, %s. El panel de Edad (F4) dice qué falta para el hito." % [C.fmt_time(t_rv), C.fmt_time(t_me) if t_me >= 0 else "nunca"])
	if bank_sum / n >= int(cfg.get("banco_prom", 1200)):
		_tips.append("tuviste %d recursos sin gastar en promedio. Lo que se guarda no pelea ni junta: gastalo en aldeanos, tropas o la próxima edad." % (bank_sum / n))
	if army_rv >= 2 * maxi(1, army_me):
		_tips.append("tu ejército más grande fue de %d; el del rival, de %d. Tené siempre un edificio militar entrenando." % [army_me, army_rv])
	if _tips.is_empty():
		_tips.append("mirá el gráfico de Aldeanos: casi siempre la diferencia empieza ahí.")
	_tips = _tips.slice(0, 2)


# ---------------------------------------------------------------- Equipos (--- equipos ronda 3 ---)

## Hay equipos de más de uno (si no, es 1 contra 1 o todos contra todos y nada cambia).
func _teams() -> bool:
	var sim := hud.sim
	var seen := {}
	for p in sim.players:
		var t := sim.team_of(p["id"])
		if seen.has(t):
			return true
		seen[t] = true
	return false


## Jugadores por equipo (el tuyo primero) y, dentro, por número: así se agrupan la tabla, la
## riqueza y la línea de tiempo.
func _order() -> Array:
	var sim := hud.sim
	var ids: Array = range(sim.players.size())
	var mine := sim.team_of(hud.local)
	ids.sort_custom(func(a: int, b: int) -> bool:
		var ta := -1 if sim.team_of(a) == mine else sim.team_of(a)
		var tb := -1 if sim.team_of(b) == mine else sim.team_of(b)
		return ta < tb if ta != tb else a < b)
	return ids


## "Equipo 1: Vos y Verde" (por color; "Vos" para el que mira).
func _team_name(t: int) -> String:
	var sim := hud.sim
	var who: Array[String] = []
	for p in sim.players:
		if sim.team_of(p["id"]) == t:
			who.append("Vos" if p["id"] == hud.local else Palette.team_name(p["id"]))
	var names := who[0] if who.size() == 1 else ", ".join(who.slice(0, who.size() - 1)) + " y " + who[-1]
	return "Equipo %d: %s" % [t + 1, names]


## Quién ganó: el equipo entero si es de más de uno; si no, el jugador ("Rojo · Mapuches").
func _winner_name(pid: int) -> String:
	var sim := hud.sim
	if _teams():
		var t := sim.team_of(pid)
		var size := 0
		for p in sim.players:
			if sim.team_of(p["id"]) == t:
				size += 1
		if size > 1:
			return "el " + _team_name(t)
	return C.player_name(sim, pid, hud.local)


## Nombre corto para las columnas cuando son muchas: el color (o "Vos") y la civ en la línea de abajo no entra.
func _short_name(pid: int) -> String:
	return "Vos" if pid == hud.local else Palette.team_name(pid)
