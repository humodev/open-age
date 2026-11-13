extends Control
## Panel de economía (F2): ingreso por minuto, aldeanos por tarea, riqueza por
## origen, lo disputado, recurso propio y sitios sagrados. No pausa la partida.

const C := preload("res://src/game/ui/panel_comun.gd")
const TASK_ORDER: Array[String] = ["alimento", "madera", "piedra", "riqueza", "construyendo", "en marcha", "refugiados", "otros", "ociosos"]
const TASK_NAMES := {"construyendo": "Construyendo", "en marcha": "En marcha", "refugiados": "Refugiados", "otros": "Otras tareas", "ociosos": "Ociosos"}

var hud: Hud
var datos # PanelDatos
var _h := 600.0


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
	var w := size.x
	C.frame(self, size, "Economía", "F2")
	var keys := C.res_keys(sim, pid)
	var vill: Dictionary = datos.villagers(pid)

	# Ingreso por minuto.
	var y := 64.0
	C.title(self, Vector2(16, y), "INGRESO POR MINUTO · últimos %d s" % datos.window_s)
	y += 12
	var cw := (w - 28) / keys.size()
	for i in keys.size():
		var k: String = keys[i]
		var x := 14.0 + i * cw
		var col := C.res_color(sim, pid, k)
		Glyphs.draw(self, C.res_icon(sim, pid, k), Rect2(x, y + 4, 24, 24), col)
		var r: int = datos.rate(pid, k)
		C.text(self, Vector2(x + 30, y + 22), C.fmt_rate(r), 18, Palette.UI_TEXT if r > 0 else Palette.UI_DIM, true)
		C.text(self, Vector2(x, y + 44), "%d en banco" % int(p["res"].get(k, 0)), 12, Palette.UI_DIM)
		if vill.has(k):
			C.text(self, Vector2(x, y + 60), "%d aldeano%s" % [vill[k], "" if int(vill[k]) == 1 else "s"], 12, Palette.UI_DIM)
	y += 72
	C.sep(self, y, w)

	# Aldeanos por tarea.
	y += 22
	var total: int = vill["total"]
	C.title(self, Vector2(16, y), "ALDEANOS · %d" % total)
	var idle: int = vill.get("ociosos", 0)
	if idle > 0:
		C.text(self, Vector2(0, y), "%d ociosos (tecla .)" % idle, 13, Palette.UI_BAD, true, w - 16, HORIZONTAL_ALIGNMENT_RIGHT)
	y += 10
	var bx := 14.0
	var bw := w - 28
	draw_rect(Rect2(bx, y, bw, 14), Color(0, 0, 0, 0.45))
	var legend: Array = []
	for k in TASK_ORDER:
		var n: int = vill.get(k, 0)
		if n <= 0:
			continue
		var col := _task_color(k)
		var seg := bw * n / maxf(1.0, total)
		draw_rect(Rect2(bx, y, seg, 14), col)
		bx += seg
		legend.append([k, n, col])
	y += 22
	var lx := 14.0
	for l in legend:
		var label := "%s %d" % [TASK_NAMES.get(l[0], C.res_name(sim, pid, l[0])), l[1]]
		var lw := Hud.font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, 12).x + 26
		if lx + lw > w - 14:
			lx = 14.0
			y += 18
		draw_rect(Rect2(lx, y + 2, 10, 10), l[2])
		C.text(self, Vector2(lx + 14, y + 12), label, 12, Palette.UI_TEXT)
		lx += lw
	y += 26
	C.sep(self, y, w)

	# Riqueza por origen.
	y += 22
	C.title(self, Vector2(16, y), "RIQUEZA POR ORIGEN · total y por minuto")
	y += 8
	var book: Dictionary = datos.origin_book(pid)
	var rows: Array = []
	var best := 1
	for o in C.ORIGIN_ORDER:
		var n := int(book.get(o, {}).get("riqueza", 0))
		if n > 0:
			rows.append([o, n])
			best = maxi(best, n)
	if rows.is_empty():
		y += 18
		C.text(self, Vector2(16, y), "Todavía no entró riqueza.", 13, Palette.UI_DIM)
	for r in rows:
		y += 22
		C.text(self, Vector2(16, y), C.ORIGIN_NAMES.get(r[0], r[0]), 13, Palette.UI_TEXT)
		C.bar(self, Rect2(160, y - 10, w - 160 - 130, 10), float(r[1]) / best, Palette.RES["riqueza"])
		C.text(self, Vector2(0, y), str(r[1]), 13, Palette.UI_TEXT, true, w - 70, HORIZONTAL_ALIGNMENT_RIGHT)
		var rr: int = datos.origin_rate(r[0], "riqueza")
		C.text(self, Vector2(0, y), "%s/min" % C.fmt_rate(rr), 12, Palette.UI_ACCENT if rr > 0 else Palette.UI_DIM, false, w - 14, HORIZONTAL_ALIGNMENT_RIGHT)
	# Lo juntado de cada recurso, por origen (tabla compacta).
	y += 26 if not book.is_empty() else 0
	if not book.is_empty():
		C.text(self, Vector2(16, y), "Todo lo juntado", 12, Palette.UI_DIM)
	var tx0 := 160.0
	var tcw := (w - tx0 - 14) / keys.size()
	for i in keys.size():
		if book.is_empty():
			break
		Glyphs.draw(self, C.res_icon(sim, pid, keys[i]), Rect2(tx0 + i * tcw + tcw - 18, y - 13, 16, 16), C.res_color(sim, pid, keys[i]))
	for o in C.ORIGIN_ORDER:
		if not book.has(o):
			continue
		y += 17
		C.text(self, Vector2(16, y), C.ORIGIN_NAMES.get(o, o), 12, Palette.UI_DIM)
		for i in keys.size():
			var n := int(book[o].get(keys[i], 0))
			C.text(self, Vector2(tx0 + i * tcw, y), str(n) if n != 0 else "·", 12, Palette.UI_TEXT if n != 0 else Palette.UI_DIM, false, tcw, HORIZONTAL_ALIGNMENT_RIGHT)
	y += 14
	C.sep(self, y, w)

	# Lo disputado.
	var dsp: Array = datos.disputed(pid)
	if int(dsp[1]) > 0:
		y += 22
		var full: bool = int(dsp[0]) >= int(dsp[1])
		C.title(self, Vector2(16, y), "LO DISPUTADO")
		C.text(self, Vector2(0, y), "%d / %d" % [dsp[0], dsp[1]], 15, Palette.UI_BAD if full else Palette.UI_TEXT, true, w - 16, HORIZONTAL_ALIGNMENT_RIGHT)
		y += 8
		C.bar(self, Rect2(14, y, w - 28, 10), float(dsp[0]) / float(dsp[1]), Palette.UI_BAD if full else Palette.RES["riqueza"])
		y += 26
		var msg := "Riqueza del centro, de los sitios y del botín. Tope de esta edad: %d por minuto, contado en los últimos %d minutos." % [dsp[2], int(dsp[1]) / maxi(1, int(dsp[2]))]
		if full:
			msg = "Llegaste al tope: lo disputado no rinde más hasta que se vacíe la ventana. Subir de edad sube el tope. " + msg
		y += C.multiline(self, Vector2(16, y), msg, w - 32, 12, Palette.UI_DIM) - 12
		y += 12
		C.sep(self, y, w)

	# Recurso propio.
	var dd := sim.dp(pid)
	if dd.has_mod("recurso_propio"):
		var rp: Dictionary = dd.mod("recurso_propio")
		var key: String = rp["clave"]
		var col := Color(rp.get("color", "#cccccc"))
		var have := int(p["res"].get(key, 0))
		var cap := int(p.get("tope_" + key, rp.get("tope", 0)))
		y += 22
		C.title(self, Vector2(16, y), String(rp["nombre"]).to_upper())
		var r2: int = datos.rate(pid, key)
		C.text(self, Vector2(0, y), "%d / %d · %s/min" % [have, cap, C.fmt_rate(r2)], 15, col.lightened(0.3), true, w - 16, HORIZONTAL_ALIGNMENT_RIGHT)
		y += 8
		C.bar(self, Rect2(14, y, w - 28, 10), float(have) / maxf(1.0, cap), col)
		y += 26
		y += C.multiline(self, Vector2(16, y), "Se gana: " + _own_sources(dd, rp), w - 32, 12, Palette.UI_DIM)
		y += 4
		y += C.multiline(self, Vector2(16, y), "Se gasta en: " + _own_sinks(dd, key), w - 32, 12, Palette.UI_DIM)
		if have >= cap and cap > 0:
			y += 4
			y += C.multiline(self, Vector2(16, y), "Al tope: lo que se genera ahora se pierde.", w - 32, 12, Palette.UI_BAD)
		y += 2
		C.sep(self, y, w)

	# Sitios sagrados.
	var sites: Array[SimEntity] = []
	for e in sim.actives:
		if e.alive and e.def.get("sagrado", false):
			sites.append(e)
	if not sites.is_empty():
		y += 22
		C.title(self, Vector2(16, y), "SITIOS SAGRADOS")
		var cap_ms := int(sim.data.reglas["sitios"]["captura_ms"])
		var sx := 14.0
		var sw := (w - 28) / sites.size()
		y += 10
		for s in sites:
			var owner_col := Palette.team(s.holder) if s.holder >= 0 else Palette.UI_DIM
			var sb := StyleBoxFlat.new()
			sb.set_corner_radius_all(6)
			sb.bg_color = Color(owner_col, 0.18)
			sb.border_color = Color(owner_col, 0.6)
			sb.set_border_width_all(1)
			draw_style_box(sb, Rect2(sx, y, sw - 8, 40))
			var who := "Libre" if s.holder < 0 else ("Tuyo" if s.holder == pid else Palette.TEAM_NAMES[s.holder % Palette.TEAM_NAMES.size()])
			C.text(self, Vector2(sx + 10, y + 17), who, 13, Palette.UI_TEXT, true)
			if s.capture > 0 and s.aux >= 0:
				C.bar(self, Rect2(sx + 10, y + 26, sw - 28, 5), float(s.capture) / cap_ms, Palette.team(s.aux))
			else:
				C.text(self, Vector2(sx + 10, y + 33), "en disputa" if s.holder < 0 else "", 11, Palette.UI_DIM)
			sx += sw
		y += 50
	_h = y + 10


func _task_color(k: String) -> Color:
	if Palette.RES.has(k):
		return Palette.RES[k]
	match k:
		"construyendo":
			return Color("c8b48a")
		"en marcha":
			return Color("8aa0b8")
		"refugiados":
			return Color("6f6a62")
		"ociosos":
			return Palette.UI_BAD
	var rp: Dictionary = hud.sim.dp(hud.local).mod("recurso_propio")
	if rp.get("clave", "") == k:
		return Color(rp.get("color", "#cccccc"))
	return Color("5d5a55")


## De dónde sale el recurso propio, leído de los datos.
func _own_sources(dd: SimData, rp: Dictionary) -> String:
	var parts: Array[String] = []
	var per_v := int(rp.get("por_aldeano", 0))
	var by_age: Array = rp.get("por_aldeano_por_edad", [])
	if not by_age.is_empty():
		per_v = int(by_age[clampi(int(hud.sim.players[hud.local]["age"]) - 1, 0, by_age.size() - 1)])
	if per_v > 0:
		parts.append("%d por minuto por aldeano" % per_v)
	var pe: Dictionary = rp.get("por_edificio", {})
	for t in pe:
		parts.append("%d por minuto por %s" % [pe[t], dd.def_of(t).get("nombre", t).to_lower()])
	for t in dd.edificios:
		var rent: Dictionary = dd.edificios[t].get("renta", {})
		if rent.has(rp["clave"]):
			parts.append("%d por minuto del %s" % [rent[rp["clave"]], dd.edificios[t]["nombre"]])
	var sq: Dictionary = dd.mod("saqueo")
	if sq.get("recurso", "") == rp["clave"]:
		parts.append("saqueo de edificios enemigos")
	var tops: Dictionary = rp.get("tope_por_edificio", {})
	var ttxt := ""
	for t in tops:
		ttxt += "%s%s +%d" % [", " if ttxt != "" else "", dd.def_of(t).get("nombre", t), tops[t]]
	var out := ", ".join(parts) + "."
	out += " Tope base %d%s." % [int(rp.get("tope", 0)), (" (sube con: " + ttxt + ")") if ttxt != "" else ""]
	return out


## En qué se gasta el recurso propio: costos, conversiones y acogida.
func _own_sinks(dd: SimData, key: String) -> String:
	var names: Array[String] = []
	for t in dd.unidades:
		if dd.unidades[t].get("costo", {}).has(key):
			names.append("%s (%d)" % [dd.unidades[t]["nombre"], dd.unidades[t]["costo"][key]])
	for t in dd.edificios:
		var d: Dictionary = dd.edificios[t]
		if d.get("costo", {}).has(key):
			names.append("%s (%d)" % [d["nombre"], d["costo"][key]])
		if d.get("conversion", {}).get("de", "") == key:
			var cv: Dictionary = d["conversion"]
			var gives: Array[String] = []
			for g in cv["da"]:
				gives.append("%d de %s" % [cv["da"][g], C.res_name(hud.sim, hud.local, g).to_lower()])
			names.append("cada %s consume %d por minuto y da %s" % [String(d["nombre"]).to_lower(), cv["consume_min"], ", ".join(gives)])
	for t in dd.tecnologias:
		if dd.tecnologias[t].get("costo", {}).has(key):
			names.append("%s (%d)" % [dd.tecnologias[t]["nombre"], dd.tecnologias[t]["costo"][key]])
	var ac: Dictionary = dd.mod("acogida")
	if ac.get("recurso", "") == key:
		names.push_front("cada %d llega una persona sola, si hay lugar" % ac["costo"])
	for i in dd.edades.size():
		if dd.edades[i].get("hito_costo", {}).has(key):
			names.append("hito de la edad %s (%d)" % [Sim._roman(i + 1), dd.edades[i]["hito_costo"][key]])
	if names.is_empty():
		return "nada todavía."
	return ", ".join(names) + "."
