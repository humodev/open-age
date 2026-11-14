extends SceneTree
## Partidas por equipos (docs/11, paso 1): 2v2 de IA. Nadie debe matar a un aliado
## y la partida termina con un equipo ganador (o sigue abierta al tiempo límite).
## Uso: godot --headless --path . -s tests/equipos.gd -- --minutes=30

func _init() -> void:
	var minutes := 30
	for a in OS.get_cmdline_user_args():
		var kv := a.trim_prefix("--").split("=")
		if kv[0] == "minutes":
			minutes = int(kv[1])
	var fails := 0
	var setups := [
		[["tawantinsuyu", "mapuches", "guaranies", "etiopia"], [0, 1, 0, 1]],
		[["palmares", "ayutthaya", "mapuches", "tawantinsuyu"], [0, 1, 0, 1]],
	]
	for st in setups:
		var s := Sim.new(321, 4, null, {"civs": st[0], "equipos": st[1], "terreno": "llano"})
		s.ais = []
		for pid in 4:
			s.ais.append(SimAI.new(s, pid))
		var friendly := 0
		var kills := 0
		while s.tick < minutes * 600 and not s.game_over:
			s.step()
			for ev in s.events:
				if ev["t"] == "died" and int(ev.get("by", -1)) >= 0 and int(ev.get("owner", -1)) >= 0:
					kills += 1
					if not s.enemies(int(ev["by"]), int(ev["owner"])) and int(ev["by"]) != int(ev["owner"]):
						friendly += 1
		var line := "%s equipos %s  %d:%02d  bajas %d  fuego amigo %d" % [str(st[0]), str(st[1]), s.tick / 600, (s.tick / 10) % 60, kills, friendly]
		if s.game_over:
			line += "  ganó el equipo %d" % s.winner_team
		for pid in 4:
			line += "  | j%d edad %d %s" % [pid, s.players[pid]["age"], "derrotado" if s.players[pid]["defeated"] else "en pie"]
		print(line)
		if friendly > 0:
			fails += 1
	print("EQUIPOS: ", "OK" if fails == 0 else "%d partidas con fuego amigo" % fails)
	quit()
