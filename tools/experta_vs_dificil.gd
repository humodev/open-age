extends SceneTree
## Experta contra difícil (proceso/24, paso 4f): partidas en espejo (cada civ contra sí misma),
## varias semillas y terrenos, con tiempo límite (`tiempo_limite_min`: si nadie termina, gana
## por puntos, Sim.score). La experta cambia de lado con la semilla. Da el % de victorias de la
## experta por civ y, por partida, aldeanos/ejército/edad de cada una a los 10, 15 y 20 minutos.
## Uso: godot --headless --path . -s tools/experta_vs_dificil.gd -- [--civs=a,b] [--seeds=41,42]
##        [--terrenos=llano,rio] [--minutes=30] [--dificultad=experta] [--rival=dificil] [--parte=i/n]
##        [--ajuste=clave=valor ...]
## --ajuste cambia una clave de la dificultad propia sin tocar reglas.json (valor en JSON; clave con
## puntos para lo anidado: `--ajuste=expansion.edad_min=3`). Sirve para medir una idea por vez.
## Con --parte=i/n juega solo una parte de las partidas (para correr en paralelo y juntar a mano).
func _init() -> void:
	var civs := ["tawantinsuyu", "mapuches", "guaranies", "etiopia", "palmares", "ayutthaya"]
	var seeds := [41, 42]
	var terrains := ["llano"]
	var minutes := 30
	var mine := "experta"
	var rival := "dificil"
	var part := 0
	var parts := 1
	var tweaks := []
	for a in OS.get_cmdline_user_args():
		var kv := a.trim_prefix("--").split("=")
		match kv[0]:
			"civs": civs = Array(kv[1].split(","))
			"seeds": seeds = Array(kv[1].split(",")).map(func(x): return int(x))
			"terrenos": terrains = Array(kv[1].split(","))
			"minutes": minutes = int(kv[1])
			"dificultad": mine = kv[1]
			"rival": rival = kv[1]
			"ajuste":
				var eq := a.find("=", a.find("=") + 1)
				tweaks.append([a.substr(9, eq - 9), _ints(JSON.parse_string(a.substr(eq + 1)))])
			"parte":
				part = int(kv[1].split("/")[0])
				parts = int(kv[1].split("/")[1])
	print("%s contra %s · %d minutos (límite, por puntos) · semillas %s · terrenos %s · ajustes %s" % [mine, rival, minutes, seeds, terrains, tweaks])
	var won := {}
	var played := {}
	var gi := 0
	for civ in civs:
		won[civ] = 0
		played[civ] = 0
		for terrain in terrains:
			for sd in seeds:
				gi += 1
				if (gi - 1) % parts != part:
					continue
				var me: int = sd % 2 # la experta cambia de lado con la semilla
				var data := SimData.load_default()
				for tw in tweaks:
					var node: Dictionary = data.reglas["dificultades"][mine]
					var keys: PackedStringArray = (tw[0] as String).split(".")
					for i in keys.size() - 1:
						node = node[keys[i]]
					node[keys[keys.size() - 1]] = tw[1]
				var s := Sim.new(sd, 2, data, {"civs": [civ, civ], "terreno": terrain, "tiempo_limite_min": minutes})
				s.ais = [null, null]
				s.ais[me] = SimAI.new(s, me, mine)
				s.ais[1 - me] = SimAI.new(s, 1 - me, rival)
				var cuts := ""
				while not s.game_over and s.tick < (minutes + 1) * 600:
					s.step()
					if s.tick % 3000 == 0 and s.tick >= 6000 and s.tick <= 12000:
						cuts += " %2d' %s / %s" % [s.tick / 600, _state(s, me), _state(s, 1 - me)]
				var how := "nadie"
				if s.winner >= 0:
					how = "%s %s" % ["EXPERTA" if s.winner == me else "dificil", "por puntos" if s.end_reason == "tiempo" else "(%s)" % s.end_reason]
					if s.winner == me:
						won[civ] += 1
				played[civ] += 1
				print("%-13s %-9s s%-3d %5s  gana %-22s pts %d-%d |%s" % [civ, terrain, sd, "%d:%02d" % [s.tick / 600, (s.tick / 10) % 60], how, s.score(me), s.score(1 - me), cuts])
	print("\n% de victorias de la experta:")
	var tw := 0
	var tp := 0
	for civ in civs:
		if played[civ] > 0:
			print("  %-13s %d / %d  %3d %%" % [civ, won[civ], played[civ], won[civ] * 100 / played[civ]])
			tw += won[civ]
			tp += played[civ]
	if tp > 0:
		print("  %-13s %d / %d  %3d %%" % ["total", tw, tp, tw * 100 / tp])
	quit()


## JSON da números con coma: los enteros vuelven a ser enteros (como en SimData).
func _ints(v: Variant) -> Variant:
	if v is float and float(int(v)) == v:
		return int(v)
	if v is Array:
		return (v as Array).map(func(x): return _ints(x))
	if v is Dictionary:
		var out := {}
		for k in v:
			out[k] = _ints(v[k])
		return out
	return v


## "aldeanos a, ejército m, edad E" de un jugador (experta / rival).
func _state(s: Sim, pid: int) -> String:
	var v := 0
	var army := 0
	for e in s.actives:
		if e.alive and e.owner == pid and e.is_unit():
			if e.fn == "civil":
				v += 1
			elif e.is_military():
				army += 1
	return "%da%dmE%d" % [v, army, s.players[pid]["age"]]
