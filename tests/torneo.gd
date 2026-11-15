extends SceneTree
## Torneo de balance: todas contra todas, IA contra IA, con varias semillas (docs/08, "Pruebas").
## Uso: godot --headless --path . -s tests/torneo.gd -- --minutes=30 --seeds=2 [--telemetria=carpeta] [--parte=i/n]

func _init() -> void:
	var minutes := 30
	var seeds := 2
	var tele_dir := ""
	var part := 0
	var parts := 1
	for a in OS.get_cmdline_user_args():
		var kv := a.trim_prefix("--").split("=")
		if kv[0] == "minutes":
			minutes = int(kv[1])
		elif kv[0] == "seeds":
			seeds = int(kv[1])
		elif kv[0] == "telemetria":
			tele_dir = kv[1]
		elif kv[0] == "parte":
			part = int(kv[1].split("/")[0])
			parts = int(kv[1].split("/")[1])
	var civs: Array = []
	var data := SimData.load_default()
	for k in data.civs:
		if not data.civs[k].civ.get("solo_ia", false):
			civs.append(k)
	civs.sort()
	var wins := {}
	var played := {}
	for c in civs:
		wins[c] = 0
		played[c] = 0
	for i in civs.size():
		for j in range(i + 1, civs.size()):
			for sd in seeds:
				# En paralelo (tools/torneo_paralelo.sh): cada proceso juega una parte de los cruces.
				var game_i := (i * civs.size() + j) * seeds + sd
				if game_i % parts != part:
					continue
				# Alterna posiciones para no favorecer un lado.
				var pair: Array = [civs[i], civs[j]] if sd % 2 == 0 else [civs[j], civs[i]]
				var sv := 1000 + i * 37 + j * 11 + sd
				var s := Sim.new(sv, 2, null, {"civs": pair})
				s.ais = [SimAI.new(s, 0), SimAI.new(s, 1)]
				while s.tick < minutes * 600 and not s.game_over:
					var t0 := Time.get_ticks_usec()
					s.step()
					var us := Time.get_ticks_usec() - t0
					if us > 25000:
						s.tele.add(s.tick, "tick_lento", -1, -1, -1, {"ms": us / 1000}, "tl", 50)
				if tele_dir != "":
					s.tele.save("%s/%s-%s-%d.jsonl" % [tele_dir, pair[0], pair[1], sv], s.tele.header(s, sv, {"civs": pair}))
				var w := "empate"
				if s.winner >= 0:
					w = pair[s.winner]
					wins[w] += 1
				else:
					# Sin ganador: gana por puntos quien tiene más población militar y edad.
					var score := []
					for pid in 2:
						var p: Dictionary = s.players[pid]
						score.append(int(p["age"]) * 1000 + int(p["pop"]) * 10 + int(p["stats"]["bajas"]))
					w = "(%s por puntos)" % pair[0 if score[0] > score[1] else 1]
				played[pair[0]] += 1
				played[pair[1]] += 1
				print("%-12s vs %-12s terreno=%-7s %5s  ganador: %s  edades %d-%d" % [pair[0], pair[1], s.terrain, "%d:%02d" % [s.tick / 600, (s.tick / 10) % 60], w, s.players[0]["age"], s.players[1]["age"]])
	print("\nVictorias por destrucción de hitos:")
	for c in civs:
		print("  %-12s %d / %d" % [c, wins[c], played[c]])
	quit()
