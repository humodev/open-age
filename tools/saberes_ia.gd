extends SceneTree
## --- paso 6 --- ¿La IA usa los saberes propios? (proceso/26-juego-tardio/11). Partidas IA contra IA
## (normal) de un pueblo contra cada rival, con mapa al azar como el torneo. Por partida: el minuto
## en que compra cada mejora propia, cuántas unidades propias entrena y cuántas mueren, los hoyos
## que cava y cuántos enemigos caen en ellos, y el resultado.
##   godot --headless --path . -s tools/saberes_ia.gd -- --civ=mapuches [--minutes=40] [--seeds=1] [--rival=guaranies]

const RIVALES := ["tawantinsuyu", "mapuches", "guaranies", "etiopia", "palmares", "ayutthaya"]


func _init() -> void:
	var civ := "mapuches"
	var minutes := 40
	var seeds := 1
	var only := ""
	for a in OS.get_cmdline_user_args():
		var kv := a.trim_prefix("--").split("=", true, 1)
		match kv[0]:
			"civ": civ = kv[1]
			"minutes": minutes = int(kv[1])
			"seeds": seeds = int(kv[1])
			"rival": only = kv[1]
	var tot_tecs := {}
	var tot_units := {}
	var n_games := 0
	for rival in RIVALES:
		if rival == civ or (only != "" and rival != only):
			continue
		for sd in seeds:
			var seed := 7000 + sd * 31 + RIVALES.find(rival) * 7
			var s := Sim.new(seed, 2, null, {"civs": [civ, rival]})
			s.ais = [SimAI.new(s, 0), SimAI.new(s, 1)]
			var own: Array = []
			for k: String in s.dp(0).tecnologias:
				if s.dp(0).tecnologias[k].get("propia", false):
					own.append(k)
			var units: Array = []
			for k: String in s.dp(0).unidades:
				if s.dp(0).unidades[k].get("propia", false) or k in ["incendiarios", "catapulta"]:
					units.append(k)
			var bought := {}
			var trained := {}
			var lost := {}
			var traps := 0
			var trapped := 0
			var ages := [0, 0, 0, 0]
			for t in minutes * 600:
				s.step()
				for ev in s.events:
					match ev["t"]:
						"tech":
							if ev["player"] == 0 and own.has(ev["tech"]):
								bought[ev["tech"]] = s.tick / 600
						"trained":
							if ev["player"] == 0 and units.has(ev["type"]):
								trained[ev["type"]] = int(trained.get(ev["type"], 0)) + 1
						"died":
							if ev["owner"] == 0 and units.has(ev["type"]):
								lost[ev["type"]] = int(lost.get(ev["type"], 0)) + 1
						"placed":
							var b: SimEntity = s.by_id.get(ev["id"])
							if b != null and b.owner == 0 and b.def.has("trampa"):
								traps += 1
						"trampa":
							trapped += 1
						"age":
							if ev.get("player", -1) == 0:
								ages[clampi(int(ev.get("age", 1)) - 1, 0, 3)] = s.tick / 600
				if s.game_over:
					break
			n_games += 1
			var res := "gana %s" % (civ if s.winner == 0 else rival) if s.game_over and s.winner >= 0 else "sin terminar (edades %d-%d)" % [s.players[0]["age"], s.players[1]["age"]]
			print("%s vs %-12s semilla %d terreno %-15s %s · %d min" % [civ, rival, seed, s.terrain, res, s.tick / 600])
			var bl: Array = bought.keys()
			bl.sort_custom(func(a: String, b: String) -> bool: return bought[a] < bought[b])
			print("   mejoras: %s" % (", ".join(bl.map(func(k: String) -> String: return "%s (min %d)" % [k, bought[k]])) if not bl.is_empty() else "ninguna"))
			print("   unidades: %s" % (", ".join(trained.keys().map(func(k: String) -> String: return "%s %d (mueren %d)" % [k, trained[k], int(lost.get(k, 0))])) if not trained.is_empty() else "ninguna"))
			if traps > 0 or trapped > 0:
				print("   hoyos: %d cavados, %d enemigos cayeron" % [traps, trapped])
			for k in bought:
				tot_tecs[k] = int(tot_tecs.get(k, 0)) + 1
			for k in trained:
				tot_units[k] = int(tot_units.get(k, 0)) + int(trained[k])
	print("\nTOTAL %d partidas · mejoras compradas (en cuántas partidas): %s" % [n_games, tot_tecs])
	print("TOTAL unidades propias entrenadas: %s" % tot_units)
	quit()
