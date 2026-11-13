extends Control
## Avance de edad (F4): qué falta para el próximo hito, las dos opciones con su
## eje (economía o militar) y su efecto, y en qué edad anda cada rival.

const C := preload("res://src/game/ui/panel_comun.gd")

var hud: Hud
var datos # PanelDatos
var _h := 500.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT and C.close_rect(size).has_point(event.position):
			visible = false
		accept_event()


func _process(_d: float) -> void:
	if size.y != _h:
		size.y = _h
	queue_redraw()


func _draw() -> void:
	var sim := hud.sim
	var pid := hud.local
	var p: Dictionary = sim.players[pid]
	var dd := sim.dp(pid)
	var age: int = p["age"]
	var w := size.x
	C.frame(self, size, "Avance de edad", "F4")
	var y := 70.0
	C.text(self, Vector2(16, y), "Edad %s · %s" % [Sim._roman(age), dd.edades[age - 1]["nombre"]], 17, Palette.UI_ACCENT, true)
	var since: int = datos.age_time(pid, age)
	if since >= 0:
		C.text(self, Vector2(0, y), "desde %s" % C.fmt_time(since), 13, Palette.UI_DIM, false, w - 16, HORIZONTAL_ALIGNMENT_RIGHT)
	if age >= dd.edades.size():
		y += 30
		C.text(self, Vector2(16, y), "Edad máxima alcanzada.", 15, Palette.UI_TEXT)
		y += 16
		y = _rivals(y, w)
		_h = y + 12
		return
	var target: Dictionary = dd.edades[age]
	y += 24
	C.text(self, Vector2(16, y), "Próxima: edad %s · %s" % [Sim._roman(age + 1), target["nombre"]], 15, Palette.UI_TEXT)
	y += 10
	C.sep(self, y, w)

	# Qué falta.
	y += 24
	C.title(self, Vector2(16, y), "QUÉ FALTA")
	var opts: Array = dd.hitos[mini(age, dd.hitos.size()) - 1] if age <= dd.hitos.size() else dd.hitos[-1]
	var cost: Dictionary = dd.cost_of(opts[0], age) if not opts.is_empty() else {}
	var res: Dictionary = p["res"]
	var ok_res := true
	var eta := 0
	var eta_known := true
	y += 8
	var x := 16.0
	for k in cost:
		var need := int(cost[k])
		var have := int(res.get(k, 0))
		var col := C.res_color(sim, pid, k)
		Glyphs.draw(self, C.res_icon(sim, pid, k), Rect2(x, y + 2, 22, 22), col)
		C.text(self, Vector2(x + 28, y + 19), "%d / %d" % [mini(have, need), need], 15, Palette.UI_TEXT if have >= need else Palette.UI_BAD, true)
		C.bar(self, Rect2(x + 28, y + 26, 90, 4), float(have) / maxf(1.0, need), col)
		if have < need:
			ok_res = false
			var r: int = datos.rate(pid, k)
			if r <= 0:
				eta_known = false
			else:
				eta = maxi(eta, (need - have) * 60 / r)
		x += 136
	y += 44
	var in_progress: SimEntity = null
	for b in sim.actives:
		if b.alive and b.owner == pid and b.def.get("avanza_edad", false) and not b.built:
			in_progress = b
	var vill: Dictionary = datos.villagers(pid)
	var checks: Array = []
	if ok_res:
		checks.append([true, "Recursos: alcanzan."])
	elif eta_known:
		checks.append([false, "Recursos: al ritmo de ahora, en unos %s." % C.fmt_time(eta)])
	else:
		checks.append([false, "Recursos: falta un recurso que hoy no estás juntando."])
	if in_progress != null:
		var k := float(in_progress.progress) / float(maxi(1, in_progress.build_time))
		checks.append([true, "Hito en obra: %s, %d %%. Mandá más aldeanos para terminarlo antes." % [in_progress.def.get("nombre", ""), int(k * 100)]])
	else:
		checks.append([vill["total"] > 0, "Un aldeano que lo construya (tenés %d, %d ociosos). Obra: %s." % [vill["total"], vill.get("ociosos", 0), C.fmt_time(dd.build_time_of(opts[0], age) / 1000) if not opts.is_empty() else "—"]])
	checks.append([true, "Población: %d / %d. El hito suma lugar." % [p["pop"], p["pop_cap"]]])
	for c in checks:
		C.text(self, Vector2(16, y), "✓" if c[0] else "✗", 15, Palette.UI_GOOD if c[0] else Palette.UI_BAD, true)
		y += C.multiline(self, Vector2(38, y), c[1], w - 54, 13, Palette.UI_TEXT) + 4
	y += 4
	C.sep(self, y, w)

	# Las dos opciones.
	y += 24
	C.title(self, Vector2(16, y), "ELEGÍ UN HITO · se construye con el aldeano (Z o X)")
	y += 10
	var cw := (w - 28 - 10) / maxf(1.0, opts.size())
	var card_h := 0.0
	var texts: Array = []
	for i in opts.size():
		var key: String = opts[i]
		var def: Dictionary = dd.edificios.get(key, {})
		var body := String(def.get("desc", ""))
		var ef: String = hud.ctrl.effects_text(def.get("efectos", []))
		var extra: Array[String] = []
		if ef != "":
			extra.append(ef)
		var rent: Dictionary = def.get("renta", {})
		for r in rent:
			extra.append("+%d de %s por minuto" % [rent[r], C.res_name(sim, pid, r).to_lower()])
		var mx: Dictionary = def.get("maximo_extra", {})
		for t in mx:
			extra.append("+%d %s como máximo" % [mx[t], dd.def_of(t).get("nombre", t).to_lower()])
		var prod: Array[String] = []
		for u in def.get("produce", []):
			prod.append(dd.unidades.get(u, {}).get("nombre", u))
		if not prod.is_empty():
			extra.append("Entrena: " + ", ".join(prod))
		var full := body + ("\n" + "\n".join(extra) if not extra.is_empty() else "")
		texts.append(full)
		card_h = maxf(card_h, C.text_h(full, cw - 24, 13) + 96)
	for i in opts.size():
		var key: String = opts[i]
		var def: Dictionary = dd.edificios.get(key, {})
		var eje: String = C.eje_of(def, key)
		var r := Rect2(14 + i * (cw + 10), y, cw, card_h)
		var sb := StyleBoxFlat.new()
		sb.set_corner_radius_all(7)
		sb.bg_color = Color(C.eje_color(eje), 0.08)
		sb.border_color = Color(C.eje_color(eje), 0.45)
		sb.set_border_width_all(1)
		draw_style_box(sb, r)
		Glyphs.draw(self, Glyphs.resolve(def, key), Rect2(r.position.x + 10, r.position.y + 10, 30, 30), Palette.UI_TEXT)
		C.text(self, r.position + Vector2(48, 24), def.get("nombre", key), 15, Palette.UI_TEXT, true, cw - 60)
		C.text(self, r.position + Vector2(48, 42), C.EJE_NAMES.get(eje, eje).to_upper() + "  ·  " + Controller.SLOT_LABELS[8 + i], 11, C.eje_color(eje), true)
		C.multiline(self, r.position + Vector2(12, 64), texts[i], cw - 24, 13, Palette.UI_DIM)
		var cx := r.position.x + 12
		var oc: Dictionary = dd.cost_of(key, age)
		for k in oc:
			var ok: bool = int(res.get(k, 0)) >= int(oc[k])
			Glyphs.draw(self, C.res_icon(sim, pid, k), Rect2(cx, r.end.y - 28, 18, 18), C.res_color(sim, pid, k))
			C.text(self, Vector2(cx + 22, r.end.y - 14), str(oc[k]), 13, Palette.UI_TEXT if ok else Palette.UI_BAD, true)
			cx += 74
	y += card_h + 12
	var unl: String = hud.ctrl.unlocks_text(age + 1)
	y += C.multiline(self, Vector2(16, y + 10), unl, w - 32, 13, Palette.UI_TEXT) + 4
	C.sep(self, y, w)
	y = _rivals(y + 6, w)
	_h = y + 12


func _rivals(y: float, w: float) -> float:
	var sim := hud.sim
	y += 18
	C.title(self, Vector2(16, y), "EDADES")
	for p in sim.players:
		var pid: int = p["id"]
		y += 20
		draw_rect(Rect2(16, y - 10, 10, 10), Palette.team(pid))
		var txt := "%s: edad %s" % [C.player_name(sim, pid, hud.local), Sim._roman(p["age"])]
		if p["defeated"]:
			txt += " · derrotado"
		C.text(self, Vector2(34, y), txt, 13, Palette.UI_TEXT if pid == hud.local else Palette.UI_DIM)
		var times: Array[String] = []
		for a in range(2, int(p["age"]) + 1):
			var t: int = datos.age_time(pid, a)
			if t >= 0:
				times.append("%s %s" % [Sim._roman(a), C.fmt_time(t)])
		C.text(self, Vector2(0, y), "  ".join(times), 12, Palette.UI_DIM, false, w - 16, HORIZONTAL_ALIGNMENT_RIGHT)
	return y + 8
