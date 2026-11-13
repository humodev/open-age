extends SceneTree
## Cada tipo de mapa con IA contra IA: que nadie se trabe por falta de llano o de paso (docs/10).
## Uso: godot --headless --path . -s tests/mapas_smoke.gd -- --minutes=20

func _init() -> void:
	var minutes := 20
	for a in OS.get_cmdline_user_args():
		var kv := a.trim_prefix("--").split("=")
		if kv[0] == "minutes":
			minutes = int(kv[1])
	var data := SimData.load_default()
	var civs: Array = ["tawantinsuyu", "mapuches", "guaranies", "etiopia", "palmares", "ayutthaya"]
	var k := 0
	var fails := 0
	for t in data.reglas["terrenos"]:
		var pair: Array = [civs[k % civs.size()], civs[(k + 3) % civs.size()]]
		k += 1
		var s := Sim.new(500 + k * 13, 2, null, {"civs": pair, "terreno": t})
		s.ais = [SimAI.new(s, 0), SimAI.new(s, 1)]
		while s.tick < minutes * 600 and not s.game_over:
			s.step()
		var line := "%-16s %-12s vs %-12s %5s" % [t, pair[0], pair[1], "%d:%02d" % [s.tick / 600, (s.tick / 10) % 60]]
		for pid in 2:
			var p: Dictionary = s.players[pid]
			var blds := 0
			for e in s.actives:
				if e.owner == pid and e.is_building():
					blds += 1
			line += "  | edad %d pob %d edif %d" % [p["age"], p["pop"], blds]
			# Una IA trabada no pasa de la edad I ni levanta una aldea en todo ese tiempo.
			if not s.game_over and (int(p["age"]) < 2 or blds < 6):
				fails += 1
				line += " ⚠"
		if s.game_over:
			line += "  ganó " + str(pair[s.winner])
		print(line)
	print("MAPAS: ", "OK" if fails == 0 else "%d jugadores trabados" % fails)
	quit()
