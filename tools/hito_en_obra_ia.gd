extends SceneTree
## Hito en obra (proceso/24, paso 4f; veterano, ronda 3): IA contra IA, cuántos segundos pasa
## un enemigo militar a 12 casillas o menos de un hito en obra, cuántos hitos se pierden en obra
## y a qué hora sube cada uno de edad.
## Uso: godot --headless --path . -s tools/hito_en_obra_ia.gd -- [--dificultad=normal]
##        [--pares=tawantinsuyu:etiopia,guaranies:mapuches] [--seeds=7,8] [--minutes=16] [--terreno=llano] [--apagado]
## --apagado: con `ataca_hito_en_obra` en falso (como antes del paso 4f), para comparar.
func _init() -> void:
	var diff := "normal"
	var pairs := ["tawantinsuyu:etiopia", "guaranies:mapuches", "ayutthaya:palmares"]
	var seeds := [7, 8]
	var minutes := 16
	var terrain := "llano"
	var off := false
	for a in OS.get_cmdline_user_args():
		var kv := a.trim_prefix("--").split("=")
		match kv[0]:
			"dificultad": diff = kv[1]
			"pares": pairs = Array(kv[1].split(","))
			"seeds": seeds = Array(kv[1].split(",")).map(func(x): return int(x))
			"minutes": minutes = int(kv[1])
			"terreno": terrain = kv[1]
			"apagado": off = true
	print("hito en obra · %s contra %s · %s · %d minutos%s" % [diff, diff, terrain, minutes, " · apagado" if off else ""])
	var near := 12000
	for pair: String in pairs:
		for sd in seeds:
			var civs := pair.split(":")
			var data := SimData.load_default()
			data.reglas["dificultades"][diff]["ataca_hito_en_obra"] = not off
			var s := Sim.new(sd, 2, data, {"civs": [civs[0], civs[1]], "terreno": terrain})
			s.ais = [SimAI.new(s, 0, diff), SimAI.new(s, 1, diff)]
			var threat_t := [0, 0] # ticks con enemigo cerca de mi hito en obra
			var lost := [0, 0] # hitos perdidos en obra
			var ages := [[], []]
			var building := {} # id -> dueño de los hitos en obra vistos
			while s.tick < minutes * 600 and not s.game_over:
				s.step()
				var now := {}
				var hitos: Array[SimEntity] = []
				for e in s.actives:
					if e.alive and e.is_building() and not e.built and e.def.get("hito", false) and e.owner >= 0:
						now[e.id] = e.owner
						hitos.append(e)
				for id in building:
					var e: SimEntity = s.by_id.get(id)
					if not now.has(id) and (e == null or not e.alive):
						lost[building[id]] += 1
				building = now
				if s.tick % 10 == 0:
					for h in hitos:
						for e in s.actives:
							if e.alive and e.owner >= 0 and e.owner != h.owner and e.is_unit() and e.is_military() and s.dist_to(e, h) <= near:
								threat_t[h.owner] += 10
								break
				for pid in 2:
					if (ages[pid] as Array).size() < int(s.players[pid]["age"]) - 1:
						ages[pid].append("%d:%02d" % [s.tick / 600, (s.tick / 10) % 60])
			print("%-24s s%-3d  enemigo cerca del hito en obra (s): %d / %d · hitos perdidos en obra: %d / %d · edades %s / %s%s" % [pair, sd, threat_t[0] / 10, threat_t[1] / 10, lost[0], lost[1], ages[0], ages[1], " · gana %s" % civs[s.winner] if s.game_over and s.winner >= 0 else ""])
	quit()
