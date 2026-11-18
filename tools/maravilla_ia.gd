extends SceneTree
## --- paso 7 --- Edad IV, maravilla y final de partida (proceso/26-juego-tardio/10; docs/diseno/27,
## §4 y §6). Partidas IA contra IA, como el torneo (seis pueblos, cada uno contra el siguiente
## según la semilla, mapa al azar), y por partida: el minuto de cada edad de cada jugador, cuándo
## se puso, se terminó o cayó cada maravilla, cuánto le faltó a su cuenta, quién ganó, cómo y a
## qué minuto. Al final, el resumen: partidas con la IV, mediana de la IV, maravillas puestas,
## terminadas, caídas y ganadas, y cómo terminan las partidas.
##
## --sin-paso7 apaga lo del paso 7 en la IA (sube_a_la_iv, maravilla, ataca_maravilla y la
## rendición nueva) y la victoria por maravilla, con el mismo código: la comparación con las
## mismas semillas.
##
## Uso:
##   godot --headless --path . -s tools/maravilla_ia.gd -- --minutes=45 --seeds=3 --parte=0/3
##   godot --headless --path . -s tools/maravilla_ia.gd -- --minutes=60 --sin-paso7

func _init() -> void:
	var minutes := 45
	var seeds := 1
	var seed0 := 0
	var diff := "normal"
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
			"semilla0":
				seed0 = int(kv[1])
			"dificultad":
				diff = kv[1]
			"parte":
				part = int(kv[1].split("/")[0])
				parts = int(kv[1].split("/")[1])
			"sin-paso7":
				off = true
	var data := SimData.load_default()
	var civs: Array = []
	for k in data.civs:
		if not data.civs[k].civ.get("solo_ia", false):
			civs.append(k)
	civs.sort()
	print("modo | semilla | pueblo A | pueblo B | II A | III A | IV A | II B | III B | IV B | maravillas | ganador | motivo | fin")
	var game_i := 0
	for sd in range(seed0, seed0 + seeds):
		for i in civs.size():
			game_i += 1
			if (game_i - 1) % parts != part:
				continue
			var pair: Array = [civs[i], civs[(i + 1 + sd) % civs.size()]]
			var opts := {"civs": pair}
			if off:
				opts["maravilla_sin_victoria"] = true
			var s := Sim.new(5000 + i * 13 + sd * 7, 2, null, opts)
			if off:
				_turn_off(s.data)
			s.ais = [SimAI.new(s, 0, diff), SimAI.new(s, 1, diff)]
			var ages := [{}, {}]
			var wonders := [] # [jugador, puesta, terminada, cayó, restante al terminar la partida]
			var by_id := {}
			# Lo propio de cada pueblo: [minuto de cada mejora propia], {unidad propia: entrenadas}.
			var own_t := [[], []]
			var own_u := [{}, {}]
			while s.tick < minutes * 600 and not s.game_over:
				s.step()
				for ev in s.events:
					match ev["t"]:
						"age":
							ages[ev["player"]][int(ev["age"])] = s.tick
						"maravilla_obra":
							by_id[ev["id"]] = wonders.size()
							wonders.append([ev["player"], s.tick, -1, -1, -1])
						"maravilla":
							if by_id.has(ev["id"]):
								wonders[by_id[ev["id"]]][2] = s.tick
						"tech":
							if s.dp(ev["player"]).tecnologias.get(ev["tech"], {}).get("propia", false):
								own_t[ev["player"]].append(s.tick)
						"trained":
							if ev["player"] >= 0 and s.dp(ev["player"]).unidades.get(ev["type"], {}).get("propia", false):
								own_u[ev["player"]][ev["type"]] = int(own_u[ev["player"]].get(ev["type"], 0)) + 1
						"maravilla_cae":
							if by_id.has(ev["id"]):
								wonders[by_id[ev["id"]]][3] = s.tick
			var wt := []
			for w in wonders:
				var left := s.wonder_left_s(int(w[0])) if int(w[3]) < 0 and int(w[2]) >= 0 else -1
				wt.append("J%d puesta %s terminada %s cae %s%s" % [w[0], _m(w[1]), _m(w[2]), _m(w[3]), (" (le faltaban %d:%02d)" % [left / 60, left % 60]) if left >= 0 else ""])
			var reason := s.end_reason if s.game_over else "abierta"
			print("%s | %d | %s | %s | %s | %s | %s | %s | %s | %s | %s | %d | %s | %s" % ["sin" if off else "con", sd, pair[0], pair[1], _m(ages[0].get(2, -1)), _m(ages[0].get(3, -1)), _m(ages[0].get(4, -1)), _m(ages[1].get(2, -1)), _m(ages[1].get(3, -1)), _m(ages[1].get(4, -1)), "; ".join(wt) if not wt.is_empty() else "-", s.winner, reason, _m(s.tick)])
			for pj in 2:
				var t15 := 0
				for t: int in own_t[pj]:
					t15 += 1 if t <= 9000 else 0
				print("   propias J%d %s: mejoras %d (hasta el 15: %d; primera %s) · unidades %s" % [pj, pair[pj], own_t[pj].size(), t15, _m(own_t[pj][0]) if not own_t[pj].is_empty() else "-", own_u[pj] if not own_u[pj].is_empty() else "-"])
	quit()


## Lo del paso 7 apagado en la IA (la victoria por maravilla se apaga con el opt).
func _turn_off(d: SimData) -> void:
	for lv: String in d.reglas["dificultades"]:
		var l: Dictionary = d.reglas["dificultades"][lv]
		for k in ["sube_a_la_iv", "maravilla", "ataca_maravilla"]:
			l.erase(k)
		if (l.get("rendicion", {}) as Dictionary).has("ejercito_rival_pct"):
			l.erase("rendicion")


func _m(tick: int) -> String:
	if tick < 0:
		return "-"
	return "%d:%02d" % [tick / 600, tick / 10 % 60]
