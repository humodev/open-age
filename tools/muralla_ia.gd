extends SceneTree
## Muralla de la IA (proceso/32-ronda-8/06): la experta y la difícil, con un pueblo que tiene
## muralla de piedra contra uno que no, ¿amurallan, en qué edad y con cuánto?
##   godot --headless --path . -s tools/muralla_ia.gd -- --minutes=25 --seeds=2

func _init() -> void:
	var minutes := 25
	var seeds := 2
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--minutes="):
			minutes = int(a.split("=")[1])
		elif a.begins_with("--seeds="):
			seeds = int(a.split("=")[1])
	var pairs := [["etiopia", "mapuches", "experta", "experta"], ["tawantinsuyu", "palmares", "dificil", "experta"], ["ayutthaya", "guaranies", "experta", "dificil"], ["etiopia", "tawantinsuyu", "experta", "experta"]]
	var walls := 0
	var games := 0
	for seed in range(1, seeds + 1):
		for pr: Array in pairs:
			var s := Sim.new(seed * 101, 2, null, {"civs": [pr[0], pr[1]]})
			s.ais = [SimAI.new(s, 0, pr[2]), SimAI.new(s, 1, pr[3])]
			var first := {}
			for i in minutes * 600:
				s.step()
				if i % 600 == 0:
					for pid in 2:
						if not first.has(pid) and not s.ais[pid]._wall_tiles.is_empty():
							first[pid] = [i / 600, int(s.players[pid]["age"]), s.ais[pid]._wall_alert]
			var line := "semilla %d %s(%s) vs %s(%s) ganador=%d\n" % [seed, pr[0], pr[2], pr[1], pr[3], s.winner]
			for pid in 2:
				var n := {}
				for e in s.actives:
					if e.alive and e.owner == pid and e.is_building() and (e.def.get("linea", false) and Sim.material_of(e.def) == "piedra" or e.type in ["puerta_piedra", "torre_muralla"]):
						var k := e.type + ("" if e.built else "*")
						n[k] = int(n.get(k, 0)) + 1
				if not n.is_empty():
					walls += 1
				games += 1
				var cap: SimEntity = null
				for e in s.actives:
					if e.alive and e.owner == pid and e.is_building() and e.capital:
						cap = e
				var libres: int = s.ais[pid]._wall_line(cap, 16, 13).size() if cap != null and s.ais[pid]._wall_type(s.dp(pid)) != "" else -1
				line += "  (casillas libres para el lienzo: %d, alerta %s)\n" % [libres, s.ais[pid]._wall_alert]
				line += "  %s: edad %d, lienzo %s, piezas %s, piedra %d\n" % [s.players[pid]["civ"], s.players[pid]["age"], str(first.get(pid, "no")), n, int(s.players[pid]["res"]["piedra"])]
			print(line)
	print("MURALLA_IA: %d de %d jugadores con muralla" % [walls, games])
	quit()


func _finalize() -> void:
	Sim.soltar_todas()
