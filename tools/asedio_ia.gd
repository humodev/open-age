extends SceneTree
## Paso 4 del juego tardío (docs/diseno/27, §4.2; proceso/26-juego-tardio/08): ¿la IA usa el
## asedio nuevo y levanta la defensa? ¿Cuánto tarda en caer una base con fortaleza? ¿Terminan
## las partidas? Partidas IA contra IA, cada pueblo contra el siguiente (como niveles_ia.gd).
##
## Uso:
##   godot --headless --path . -s tools/asedio_ia.gd -- --minutes=45 --seeds=1 --dificultad=normal --parte=0/3
##
## Por partida: ganador, minuto y motivo del final, y por jugador: edades III y IV, asedio
## entrenado (contra edificios y de área), disparos de área, nivel del asedio, fortaleza (minuto
## en que se termina, primer golpe, caída) y de dónde vino el daño que recibió.

var types := {} # id -> [tipo, dueño]


func _init() -> void:
	var minutes := 45
	var seeds := 1
	var diffs: Array = ["normal"]
	var part := 0
	var parts := 1
	for a in OS.get_cmdline_user_args():
		var kv := a.trim_prefix("--").split("=")
		match kv[0]:
			"minutes":
				minutes = int(kv[1])
			"seeds":
				seeds = int(kv[1])
			"dificultad":
				diffs = Array(kv[1].split(","))
			"parte":
				part = int(kv[1].split("/")[0])
				parts = int(kv[1].split("/")[1])
	if OS.get_cmdline_user_args().has("--caida"):
		_falls()
		quit()
		return
	var data := SimData.load_default()
	var civs: Array = []
	for k in data.civs:
		if not data.civs[k].civ.get("solo_ia", false):
			civs.append(k)
	civs.sort()
	var game_i := 0
	for diff: String in diffs:
		for sd in seeds:
			for i in civs.size():
				game_i += 1
				if (game_i - 1) % parts != part:
					continue
				_game(diff, sd, civs[i], civs[(i + 1 + sd) % civs.size()], 3000 + i * 17 + sd * 11, minutes)
	quit()


## --caida: cuánto tarda en caer una defensa sola (sin ejército que la defienda), en la edad III
## con los niveles comprados, según el asedio que la ataca y la gente que tiene adentro.
func _falls() -> void:
	print("defensor | edificio | adentro | atacante | segundos hasta caer | atacantes perdidos")
	var cases := [
		["", "torre", 0, "ariete:3"], ["", "fortaleza", 0, "ariete:3"], ["", "fortaleza", 10, "ariete:3"],
		["", "fortaleza", 10, "ariete:3+lancero:10"], ["", "fortaleza", 0, "catapulta:3"], ["", "fortaleza", 0, "guerrero:15"],
		["mapuches", "fortaleza", 0, "incendiarios:6"], ["etiopia", "fortaleza", 0, "incendiarios:6"],
		["palmares", "fortaleza", 0, "guerrero:15"], ["guaranies", "fortaleza", 0, "catapulta:3"]]
	for c in cases:
		var att := "mapuches" if String(c[3]).begins_with("incendiarios") else ("guaranies" if c[0] == "guaranies" else "")
		var s := Sim.new(3, 2, null, {"civs": [c[0], att] if c[0] != "" or att != "" else [], "terreno": "llano", "sin_sitios": true})
		for e in s.actives.duplicate():
			if e.owner >= 0 and e.is_unit(): # las capitales quedan (sin ellas, la partida termina)
				s.remove_quietly(e)
		for pid in 2:
			s.players[pid]["age"] = 3
			s.grant_age_purchases(pid, 3)
		var cx := s.map.n / 2
		var t := s.map.nearest_free(cx - 6, cx, 10, 0) # como micro_matriz: la semilla 3 en llano deja el paso libre
		var b := s.spawn_building(c[1], 0, t.x, t.y, true)
		for i in int(c[2]):
			b.garrison.append(s.spawn_unit("aldeano", 0, b.x, b.y).id)
			s.by_id[b.garrison[-1]].inside = b.id
		var ids := []
		for part in String(c[3]).split("+"):
			var kv := part.split(":")
			for i in int(kv[1]):
				var u := s.map.nearest_free(cx + 5 + i % 4, cx - 1 + i / 4, 8, 1)
				ids.append(s.spawn_unit(kv[0], 1, u.x * 1000 + 500, u.y * 1000 + 500).id)
		s.push_command({"t": "move", "player": 1, "ids": ids, "x": b.x, "y": b.y, "amove": true})
		var lost := 0
		while s.tick < 6000 and b.alive:
			s.step()
		for id in ids:
			if not (s.by_id.has(id) and s.by_id[id].alive):
				lost += 1
		print("%s | %s | %d | %s | %s | %d de %d" % [c[0] if c[0] != "" else "común", b.def["nombre"], c[2], c[3], ("%d" % (s.tick / 10)) if not b.alive else "no cae en 600", lost, ids.size()])


func _m(tick: int) -> String:
	if tick < 0:
		return "—"
	return "%d:%02d" % [tick / 600, (tick / 10) % 60]


func _game(diff: String, sd: int, a: String, b: String, seed_v: int, minutes: int) -> void:
	types.clear()
	var s := Sim.new(seed_v, 2, null, {"civs": [a, b]})
	s.ais = [SimAI.new(s, 0, diff), SimAI.new(s, 1, diff)]
	for e in s.entities:
		types[e.id] = [e.type, e.owner]
	var log := [{}, {}]
	for pid in 2:
		log[pid] = {"ram": 0, "area": 0, "shots": 0, "fort": [], "fort_hit": {}, "fort_dmg": {}, "fort_died": {}, "lvl": {}, "def": {}}
	while s.tick < minutes * 600 and not s.game_over:
		s.step()
		for ev in s.events:
			match ev["t"]:
				"trained":
					types[ev["id"]] = [ev["type"], ev["player"]]
					var ud: Dictionary = s.dp(ev["player"]).unidades.get(ev["type"], {})
					if ud.get("funcion", "") == "asedio":
						log[ev["player"]]["area" if ud.has("area_borde_pct") else "ram"] += 1
				"built":
					var be: SimEntity = s.by_id.get(ev["id"])
					if be != null:
						types[ev["id"]] = [be.type, be.owner]
						if be.def.get("fortaleza", false):
							log[be.owner]["fort"].append([ev["id"], s.tick])
				"age":
					log[ev["player"]]["edad%d" % int(ev["age"])] = s.tick
				"tech":
					var k: String = ev["tech"]
					if k.ends_with("_asedio"):
						log[ev["player"]]["lvl"][k] = s.tick
					elif k in ["aspilleras", "mamposteria_2", "fortaleza_reforzada", "reparacion_rapida"]:
						log[ev["player"]]["def"][k] = s.tick
				"area":
					var t: Array = types.get(ev["a"], ["?", -1])
					if int(t[1]) >= 0:
						log[int(t[1])]["shots"] += 1
				"hit":
					var tb: Array = types.get(ev["b"], ["?", -1])
					if int(tb[1]) >= 0 and s.dp(int(tb[1])).edificios.get(tb[0], {}).get("fortaleza", false):
						var l: Dictionary = log[int(tb[1])]
						if not l["fort_hit"].has(ev["b"]):
							l["fort_hit"][ev["b"]] = s.tick
						var ta: Array = types.get(ev["a"], ["?", -1])
						var who := "?"
						if int(ta[1]) >= 0:
							var ad: Dictionary = s.dp(int(ta[1])).unidades.get(ta[0], {})
							who = "asedio" if ad.get("funcion", "") == "asedio" else ("tropa" if not ad.is_empty() else "edificio")
						l["fort_dmg"][who] = int(l["fort_dmg"].get(who, 0)) + int(ev["dmg"])
				"died":
					if types.has(ev["id"]):
						var td: Array = types[ev["id"]]
						if int(td[1]) >= 0 and s.dp(int(td[1])).edificios.get(td[0], {}).get("fortaleza", false):
							log[int(td[1])]["fort_died"][ev["id"]] = s.tick
	print("=== %s s%d %s contra %s · ganador %s · fin %s (%s)" % [diff, sd, a, b, [a, b][s.winner] if s.winner >= 0 else "nadie", _m(s.tick) if s.game_over else "%d:00 sin terminar" % minutes, s.end_reason if s.game_over else "-"])
	for pid in 2:
		var l: Dictionary = log[pid]
		var forts := []
		for f in l["fort"]:
			var id: int = f[0]
			var hit: int = l["fort_hit"].get(id, -1)
			var died: int = l["fort_died"].get(id, -1)
			forts.append("hecha %s, primer golpe %s, cae %s%s" % [_m(f[1]), _m(hit), _m(died), (" (aguantó %s)" % _m(died - hit)) if died >= 0 and hit >= 0 else ""])
		var lv := []
		for k in l["lvl"]:
			lv.append("%s %s" % [k, _m(l["lvl"][k])])
		var df := []
		for k in l["def"]:
			df.append("%s %s" % [k, _m(l["def"][k])])
		print("  %s: III %s · IV %s · asedio contra edificios %d · de área %d (%d disparos) · niveles [%s] · fortaleza [%s] · daño a la fortaleza %s · defensa [%s]%s" % [
			[a, b][pid], _m(l.get("edad3", -1)), _m(l.get("edad4", -1)), l["ram"], l["area"], l["shots"], ", ".join(lv), "; ".join(forts), l["fort_dmg"], ", ".join(df),
			" · derrotado" if s.players[pid]["defeated"] else ""])
