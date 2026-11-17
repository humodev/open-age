extends SceneTree
## --- paso 3 --- Economía del final y escuela de la IV (proceso/26-juego-tardio/07;
## docs/diseno/27, §1.1, §1.3 y §4.3). Partidas IA contra IA: por jugador, el minuto de cada
## edad, el de cada compra del paso 3 (y del primer élite), cuánto recolectó por minuto en la
## IV y si llegó a la IV. Con --sin-paso3 se borra lo del paso 3 (las tecnologías con
## `paso: 3`, la renta de los sitios por edad y el orden de compra de la IA) para comparar con las mismas semillas.
## Las partidas se reparten como en el torneo (--parte=i/n).
##
## Uso:
##   godot --headless --path . -s tools/economia_tardia_ia.gd -- --minutes=45 --seeds=2
##   godot --headless --path . -s tools/economia_tardia_ia.gd -- --sin-paso3 --parte=0/3

func _init() -> void:
	var minutes := 45
	var seeds := 1
	var diffs: Array = ["normal"]
	var part := 0
	var parts := 1
	var off := false
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
			"sin-paso3":
				off = true
	var data := SimData.load_default()
	var civs: Array = []
	for k in data.civs:
		if not data.civs[k].civ.get("solo_ia", false):
			civs.append(k)
	civs.sort()
	print("modo | dificultad | semilla | pueblo | rival | II | III | IV | compras del paso 3 (min) | 1.er élite | recolectado por min en la IV | aldeanos al final | ganador | fin")
	var game_i := 0
	for diff: String in diffs:
		for sd in seeds:
			for i in civs.size():
				game_i += 1
				if (game_i - 1) % parts != part:
					continue
				var pair: Array = [civs[i], civs[(i + 1 + sd) % civs.size()]]
				var s := Sim.new(3000 + i * 13 + sd * 7, 2, null, {"civs": pair})
				if off:
					_turn_off(s.data)
				s.ais = [SimAI.new(s, 0, diff), SimAI.new(s, 1, diff)]
				var log := [{}, {}]
				while s.tick < minutes * 600 and not s.game_over:
					s.step()
					for ev in s.events:
						if ev["t"] == "age":
							log[ev["player"]]["edad%d" % int(ev["age"])] = s.tick
							if int(ev["age"]) == 4:
								log[ev["player"]]["rec4"] = int(s.players[ev["player"]]["stats"]["recolectado"])
						elif ev["t"] == "tech":
							var k: String = ev["tech"]
							var t: Dictionary = s.dp(ev["player"]).tecnologias.get(k, {})
							if int(t.get("paso", 0)) == 3:
								log[ev["player"]][k] = s.tick
							elif k.begins_with("elite_") and not log[ev["player"]].has("elite"):
								log[ev["player"]]["elite"] = s.tick
				for pid in 2:
					var l: Dictionary = log[pid]
					var buys := []
					for k: String in l:
						if not k.begins_with("edad") and k != "rec4" and k != "elite":
							buys.append([l[k], k])
					buys.sort()
					var txt := []
					for b in buys:
						txt.append("%s %s" % [b[1], _m(b[0])])
					var per_min := "-"
					if l.has("edad4") and s.tick > int(l["edad4"]) + 600:
						per_min = str((int(s.players[pid]["stats"]["recolectado"]) - int(l["rec4"])) * 600 / (s.tick - int(l["edad4"])))
					var vill := 0
					for e in s.actives:
						if e.alive and e.owner == pid and e.is_unit() and e.fn == "civil":
							vill += 1
					print("%s | %s | %d | %s | %s | %s | %s | %s | %s | %s | %s | %d | %d | %s" % ["sin" if off else "con", diff, sd, pair[pid], pair[1 - pid], _m(l.get("edad2", -1)), _m(l.get("edad3", -1)), _m(l.get("edad4", -1)), ", ".join(txt) if not txt.is_empty() else "-", _m(l.get("elite", -1)), per_min, vill, s.winner, _m(s.tick)])
	quit()


## Borra lo del paso 3 de la tabla base y de las de cada pueblo.
func _turn_off(d: SimData) -> void:
	for dd: SimData in [d] + d.civs.values():
		for k in dd.tecnologias.keys():
			if int(dd.tecnologias[k].get("paso", 0)) == 3:
				dd.tecnologias.erase(k)
	(d.reglas["sitios"] as Dictionary).erase("renta_edad_pct")
	d.reglas.erase("ia_compras_tardias")


func _m(tick: int) -> String:
	if tick < 0:
		return "-"
	return "%d:%02d" % [tick / 600, tick / 10 % 60]
