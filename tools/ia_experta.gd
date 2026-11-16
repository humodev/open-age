extends SceneTree
## IA por dificultad (proceso/24, paso 4a): partidas en espejo de una dificultad contra otra.
## Cada `--cada` minutos: aldeanos, centros, edad y ejército de cada uno; al final, quién ganó
## y el tiempo del tick (promedio y peor) por tramo.
## Uso: godot --headless --path . -s tools/ia_experta.gd -- [--civs=guaranies,etiopia] [--rival=normal]
##        [--dificultad=experta] [--terreno=llano] [--minutes=25] [--seed=41] [--cada=5] [--banco]
## Cada civ juega contra sí misma; --banco muestra el banco y los edificios en cada corte. Con --rival=experta se mide el tick con dos expertas.
func _init() -> void:
	var civs := ["tawantinsuyu", "mapuches", "guaranies", "etiopia", "palmares", "ayutthaya"]
	var terrain := "llano"
	var minutes := 25
	var seed_value := 41
	var mine := "experta"
	var rival := "normal"
	var every := 5
	var bank := false
	for a in OS.get_cmdline_user_args():
		var kv := a.trim_prefix("--").split("=")
		match kv[0]:
			"civs": civs = Array(kv[1].split(","))
			"terreno": terrain = kv[1]
			"minutes": minutes = int(kv[1])
			"seed": seed_value = int(kv[1])
			"dificultad": mine = kv[1]
			"rival": rival = kv[1]
			"cada": every = int(kv[1])
			"banco": bank = true
	print("%s contra %s · %s · semilla %d · %d minutos" % [mine, rival, terrain, seed_value, minutes])
	for civ in civs:
		var s := Sim.new(seed_value, 2, null, {"civs": [civ, civ], "terreno": terrain})
		s.ais = [SimAI.new(s, 0, mine), SimAI.new(s, 1, rival)]
		var total := 0
		var worst := 0
		var n := 0
		var line := "%-13s" % civ
		while s.tick < minutes * 600 and not s.game_over:
			var t0 := Time.get_ticks_usec()
			s.step()
			var dt := Time.get_ticks_usec() - t0
			total += dt
			worst = maxi(worst, dt)
			n += 1
			if s.tick % (every * 600) == 0 and (s.tick >= 10 * 600 or bank):
				line += " | %2d' %s · %s · %.1f/%.0f ms" % [s.tick / 600, _state(s, 0), _state(s, 1), total / 1000.0 / maxi(1, n), worst / 1000.0]
				if bank:
					for pid in 2:
						var b := {}
						for e in s.actives:
							if e.alive and e.owner == pid and e.is_building():
								b[e.type] = b.get(e.type, 0) + 1
							elif e.alive and e.owner == pid and e.is_unit() and e.fn == "civil":
								var k := "%s:%d" % [e.gather_kind, e.order]
								b[k] = b.get(k, 0) + 1
						print("  %d' J%d banco %s pob %d/%d edificios %s" % [s.tick / 600, pid, s.players[pid]["res"], s.players[pid]["pop"], s.players[pid]["pop_cap"], b])
				total = 0
				worst = 0
				n = 0
		var who := "nadie"
		if s.game_over:
			who = "%s (%d:%02d)" % [mine if s.winner == 0 else rival, s.tick / 600, (s.tick / 10) % 60]
		print(line, " | gana ", who)
	quit()


## "aldeanos/centros/edad/ejército" de un jugador.
func _state(s: Sim, pid: int) -> String:
	var v := 0
	var c := 0
	var army := 0
	for e in s.actives:
		if not e.alive or e.owner != pid:
			continue
		if e.is_unit() and e.fn == "civil":
			v += 1
		elif e.is_unit() and e.is_military():
			army += 1
		elif e.is_building() and e.built and (e.def.get("produce", []) as Array).has("aldeano"):
			c += 1
	return "%da %dc E%d %dm" % [v, c, s.players[pid]["age"], army]
