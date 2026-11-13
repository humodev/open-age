extends SceneTree
## Humo: las seis civilizaciones juegan entre sí unos minutos sin errores (docs/08).

func _init() -> void:
	var pairs := [["tawantinsuyu", "mapuches"], ["etiopia", "palmares"], ["guaranies", "ayutthaya"]]
	var minutes := 12
	for args in OS.get_cmdline_user_args():
		if args.begins_with("--minutes="):
			minutes = int(args.split("=")[1])
	for pair in pairs:
		var s := Sim.new(77, 2, null, {"civs": pair})
		s.ais = [SimAI.new(s, 0), SimAI.new(s, 1)]
		for i in minutes * 600:
			s.step()
		var line := ""
		for pid in 2:
			var p: Dictionary = s.players[pid]
			var kinds := {}
			for e in s.actives:
				if e.owner == pid:
					kinds[e.type] = kinds.get(e.type, 0) + 1
			line += "%s edad %d pob %d/%d res %s tipos %s\n" % [p["civ"], p["age"], p["pop"], p["pop_cap"], p["res"], kinds]
		print("=== ", pair, " terreno=", s.terrain, " ganador=", s.winner, "\n", line)
	quit()
