extends Control
## Puntaje en vivo (F8): chico, una fila por jugador, con su edad.
## La fórmula está en data/reglas.json → "puntaje" (Sim.score); con tiempo límite decide la partida.
## Con equipos (docs/11, paso 5) agrupa por equipo con su total, y en la fila de
## cada aliado hay cuatro botones de tributo: un clic manda `tributo_lote` del recurso.
## Debajo, otra fila para pedirle cada recurso (proceso/23, parte B): la IA aliada lo da si
## le sobra (reglas.equipos.pedido) y lo dice en el chat.

const C := preload("res://src/game/ui/panel_comun.gd")
const ROW := 20.0
const HEAD := 18.0
const TRIB := ["alimento", "madera", "piedra", "riqueza"]

var hud: Hud
var datos # PanelDatos
var _t := 0.0
var _scores: Array = []
var _hits: Array = [] # [Rect2, aliado, recurso, "dar" o "pedir"]
# --- fluidez 4 --- tributo con cantidad y periódico; qué hace cada aliado (data/interfaz.json → tributo, equipo)
var periodico := {} # "aliado:recurso" -> {a, recurso, n, prox (tick)}
var aliados := {} # aliado -> {aldeanos, ejercito, intencion}
var _cfg := {}
# --- fin fluidez 4 ---


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
	var h := 8.0 + hud.sim.players.size() * ROW + heads * HEAD + _ally_rows() * ROW * 2 # --- órdenes --- (fila de pedir) · --- fluidez 4 --- (fila del aliado)
	_periodico() # --- fluidez 4 ---
	if _t == 0.5:
		_ver_aliados() # --- fluidez 4 ---
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


## Aliados vivos (cada uno lleva una fila más, la de pedir).
func _ally_rows() -> int:
	var n := 0
	for p in hud.sim.players:
		if p["id"] != hud.local and not hud.sim.enemies(hud.local, p["id"]) and not p["defeated"]:
			n += 1
	return n


func _has_ally() -> bool:
	for p in hud.sim.players:
		if p["id"] != hud.local and not hud.sim.enemies(hud.local, p["id"]) and not p["defeated"]:
			return true
	return false


func _gui_input(event: InputEvent) -> void:
	var mb := event as InputEventMouseButton
	# --- fluidez 4 --- (clic derecho en un tributo: prende o apaga el periódico)
	if mb != null and mb.pressed and mb.button_index == MOUSE_BUTTON_RIGHT:
		for h in _hits:
			if (h[0] as Rect2).has_point(mb.position) and h[3] == "dar":
				alternar_periodico(h[1], h[2], mb.shift_pressed or Input.is_key_pressed(KEY_SHIFT), mb.ctrl_pressed or Input.is_key_pressed(KEY_CTRL))
				accept_event()
				return
	# --- fin fluidez 4 ---
	if mb == null or not mb.pressed or mb.button_index != MOUSE_BUTTON_LEFT:
		return
	for h in _hits:
		if (h[0] as Rect2).has_point(mb.position):
			if h[3] == "pedir":
				hud.sim.push_command({"t": "pedir", "player": hud.local, "a": h[1], "recurso": h[2]})
			else:
				tributar(h[1], h[2], mb.shift_pressed or Input.is_key_pressed(KEY_SHIFT), mb.ctrl_pressed or Input.is_key_pressed(KEY_CTRL)) # --- fluidez 4 ---
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
		while name.length() > 3 and f.get_string_size(name, HORIZONTAL_ALIGNMENT_LEFT, -1, Hud.ts(12)).x > name_w - 22:
			name = name.left(-2) + "…"
		C.text(self, Vector2(22, y + 15), name, 12, Palette.UI_TEXT if pid == hud.local else Palette.UI_DIM, pid == hud.local, name_w)
		if ally:
			# Botones de tributo: un ícono por recurso, antes de la edad.
			for i in TRIB.size():
				var r := Rect2(size.x - 222 + i * 22, y + 2, 18, ROW - 4)
				draw_rect(r, Color(0, 0, 0, 0.35))
				Glyphs.draw(self, C.res_icon(sim, hud.local, TRIB[i]), r.grow(-2), C.res_color(sim, hud.local, TRIB[i]))
				_hits.append([r, pid, TRIB[i], "dar"])
				if periodico.has("%d:%s" % [pid, TRIB[i]]): # --- fluidez 4 --- (periódico: borde y punto)
					draw_rect(r, Palette.UI_GOOD, false, 1.5)
					draw_circle(r.position + Vector2(r.size.x - 2, 2), 3.0, Palette.UI_GOOD)
		C.text(self, Vector2(size.x - 128, y + 15), Sim._roman(p["age"]), 12, Palette.UI_DIM, true)
		var sc: int = _scores[pid] if pid < _scores.size() else 0
		C.bar(self, Rect2(size.x - 104, y + 9, 40, 4), float(sc) / best, col)
		C.text(self, Vector2(0, y + 15), "✗" if p["defeated"] else str(sc), 13, Palette.UI_TEXT, true, size.x - 10, HORIZONTAL_ALIGNMENT_RIGHT)
		y += ROW
		# --- órdenes --- (pedirle recursos al aliado: misma columna que el tributo, con borde)
		if ally:
			C.text(self, Vector2(0, y + 14), "pedirle →", 11, Palette.UI_DIM, false, size.x - 228, HORIZONTAL_ALIGNMENT_RIGHT)
			for i in TRIB.size():
				var r := Rect2(size.x - 222 + i * 22, y + 2, 18, ROW - 4)
				draw_rect(r, Color(1, 1, 1, 0.08))
				draw_rect(r, Color(Palette.UI_ACCENT, 0.6), false, 1.0)
				Glyphs.draw(self, C.res_icon(sim, hud.local, TRIB[i]), r.grow(-3), C.res_color(sim, hud.local, TRIB[i]))
				_hits.append([r, pid, TRIB[i], "pedir"])
			y += ROW
			# --- fluidez 4 --- (qué hace el aliado: aldeanos, ejército e intención)
			var info: Dictionary = aliados.get(pid, {})
			if not info.is_empty():
				var line := "%d aldeanos · %d de tropa · %s" % [int(info["aldeanos"]), int(info["ejercito"]), info["intencion"]]
				C.text(self, Vector2(22, y + 14), line, 11, Palette.UI_TEXT.darkened(0.1), false, size.x - 32)
			y += ROW
			# --- fin fluidez 4 ---
		# --- fin órdenes ---


func _get_tooltip(at: Vector2) -> String:
	for h in _hits:
		if (h[0] as Rect2).has_point(at):
			if h[3] == "pedir":
				return "Pedirle %d de %s a %s (si le sobra, te lo manda)" % [int(hud.sim.data.reglas["equipos"]["pedido"]["lote"]), C.res_name(hud.sim, hud.local, h[2]), Palette.team_name(h[1])]
			var n := int(hud.sim.data.reglas["equipos"].get("tributo_lote", 100))
			var com := int(hud.sim.data.reglas["equipos"]["tributo_comision_pct"])
			# --- fluidez 4 ---
			var tc := cfg_tributo()
			var per := periodico.get("%d:%s" % [h[1], h[2]], {}) as Dictionary
			var extra := "\nMayús: ×%d · Ctrl: ×%d · clic derecho: cada %d s" % [int(tc.get("mayus", 5)), int(tc.get("ctrl", 10)), int(tc.get("periodo_s", 60))]
			if not per.is_empty():
				extra += "\nPeriódico: %d cada %d s (clic derecho lo apaga)" % [int(per["n"]), int(tc.get("periodo_s", 60))]
			# --- fin fluidez 4 ---
			return "Mandar %d de %s a %s (llega %d: %d %% de comisión)" % [n, C.res_name(hud.sim, hud.local, h[2]), Palette.team_name(h[1]), n * (100 - com) / 100, com] + extra
	return ""


# --- fluidez 4 ---
func cfg_tributo() -> Dictionary:
	if _cfg.is_empty():
		var path := "res://data/interfaz.json"
		_cfg = JSON.parse_string(FileAccess.get_file_as_string(path)) if FileAccess.file_exists(path) else {}
	return _cfg.get("tributo", {})


## Cuánto manda un clic: el lote, ×mayus con Mayús o ×ctrl con Ctrl.
func cantidad(shift: bool, ctrl: bool) -> int:
	var n := int(hud.sim.data.reglas["equipos"].get("tributo_lote", 100))
	var tc := cfg_tributo()
	if ctrl:
		return n * int(tc.get("ctrl", 10))
	if shift:
		return n * int(tc.get("mayus", 5))
	return n


func tributar(a: int, recurso: String, shift: bool, ctrl: bool) -> int:
	var n := cantidad(shift, ctrl)
	hud.sim.push_command({"t": "tributo", "player": hud.local, "a": a, "recurso": recurso, "n": n})
	return n


## Prende (con la cantidad de los modificadores) o apaga el tributo periódico a `a` de `recurso`.
func alternar_periodico(a: int, recurso: String, shift: bool, ctrl: bool) -> bool:
	var k := "%d:%s" % [a, recurso]
	var name := C.res_name(hud.sim, hud.local, recurso).to_lower()
	if periodico.has(k):
		periodico.erase(k)
		hud.notify("Tributo periódico de %s a %s: apagado" % [name, Palette.team_name(a)], -1.0, "info")
		return false
	var n := cantidad(shift, ctrl)
	periodico[k] = {"a": a, "recurso": recurso, "n": n, "prox": hud.sim.tick}
	hud.notify("Tributo periódico: %d de %s a %s cada %d s" % [n, name, Palette.team_name(a), int(cfg_tributo().get("periodo_s", 60))], -1.0, "info")
	return true


func _periodico() -> void:
	if periodico.is_empty():
		return
	var sim := hud.sim
	var cada := int(cfg_tributo().get("periodo_s", 60)) * 1000 / maxi(1, sim.tick_ms)
	for k in periodico.keys():
		var p: Dictionary = periodico[k]
		var a := int(p["a"])
		if sim.players[a]["defeated"] or sim.players[hud.local]["defeated"]:
			periodico.erase(k)
			continue
		if sim.tick >= int(p["prox"]):
			p["prox"] = sim.tick + cada
			if int(sim.players[hud.local]["res"].get(p["recurso"], 0)) >= int(p["n"]):
				sim.push_command({"t": "tributo", "player": hud.local, "a": a, "recurso": p["recurso"], "n": int(p["n"])})


## Aldeanos, ejército e intención de cada aliado: su bengala viva si tiró una; si no, dónde
## está el grueso de su tropa (atacando junto a un rival, en casa o en marcha).
func _ver_aliados() -> void:
	var sim := hud.sim
	cfg_tributo()
	aliados.clear()
	var cerca := int((_cfg.get("equipo", {}) as Dictionary).get("cerca_casillas", 18)) * 1000
	var cuenta := {}
	for p in sim.players:
		var pid: int = p["id"]
		if pid != hud.local and not sim.enemies(hud.local, pid) and not p["defeated"]:
			cuenta[pid] = {"aldeanos": 0, "ejercito": 0, "sx": 0, "sy": 0}
	if cuenta.is_empty():
		return
	for e in sim.actives:
		if not e.is_unit() or not cuenta.has(e.owner):
			continue
		var c: Dictionary = cuenta[e.owner]
		if e.fn == "civil":
			c["aldeanos"] += 1
		elif e.is_military():
			c["ejercito"] += 1
			c["sx"] += e.x / 1000
			c["sy"] += e.y / 1000
	for pid in cuenta:
		var c: Dictionary = cuenta[pid]
		var intencion := "sin tropa"
		var bengala := ""
		if hud.ordenes_capa != null:
			for f in hud.ordenes_capa.flares:
				if int(f["player"]) == pid:
					bengala = String(f["tipo"])
		if bengala != "":
			intencion = "bengala: " + bengala
		elif int(c["ejercito"]) > 0:
			var mx: int = int(c["sx"]) / int(c["ejercito"]) * 1000
			var my: int = int(c["sy"]) / int(c["ejercito"]) * 1000
			var rival := -1
			var propio := false
			for e in sim.actives:
				if not e.is_building() or e.owner < 0 or Sim.dist(e.x, e.y, mx, my) > cerca:
					continue
				if sim.enemies(pid, e.owner):
					rival = e.owner
					break
				if e.owner == pid:
					propio = true
			if rival >= 0:
				intencion = "ataca a " + Palette.team_name(rival)
			elif propio:
				intencion = "en su base"
			else:
				intencion = "en marcha"
		aliados[pid] = {"aldeanos": c["aldeanos"], "ejercito": c["ejercito"], "intencion": intencion}
# --- fin fluidez 4 ---
