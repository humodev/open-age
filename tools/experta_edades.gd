extends SceneTree
## Edades de la experta (proceso/24, paso 6b; veterano, ronda 6): partidas IA contra IA (por
## defecto experta contra experta, cada civ contra sí misma) y, por jugador, a qué hora pone cada
## hito y a qué hora llega a cada edad, y aldeanos/ejército/centros/edad a los 5, 10, 15 y 20
## minutos. Al final, cuántos llegaron a la edad II antes de los 6:00 y a la III antes de los 15:00.
## Uso: godot --headless --path . -s tools/experta_edades.gd -- [--civs=a,b] [--pares=a:b,c:d]
##        [--seeds=41] [--terreno=llano] [--minutes=20] [--dificultad=experta] [--rival=experta]
##        [--parte=i/n] [--ajuste=clave=valor ...]
## --ajuste: como en tools/experta_vs_dificil.gd, cambia una clave de la dificultad (las dos IA si
## son la misma) sin tocar reglas.json.
func _init() -> void:
	var pairs := []
	for c in ["tawantinsuyu", "mapuches", "guaranies", "etiopia", "palmares", "ayutthaya"]:
		pairs.append([c, c])
	var seeds := [41]
	var terrain := "llano"
	var minutes := 20
	var mine := "experta"
	var rival := "experta"
	var part := 0
	var parts := 1
	var tweaks := []
	for a in OS.get_cmdline_user_args():
		var kv := a.trim_prefix("--").split("=")
		match kv[0]:
			"civs":
				pairs = []
				for c in kv[1].split(","):
					pairs.append([c, c])
			"pares":
				pairs = []
				for pr in kv[1].split(","):
					pairs.append(Array(pr.split(":")))
			"seeds": seeds = Array(kv[1].split(",")).map(func(x): return int(x))
			"terreno": terrain = kv[1]
			"minutes": minutes = int(kv[1])
			"dificultad": mine = kv[1]
			"rival": rival = kv[1]
			"ajuste":
				var eq := a.find("=", a.find("=") + 1)
				tweaks.append([a.substr(9, eq - 9), _ints(JSON.parse_string(a.substr(eq + 1)))])
			"parte":
				part = int(kv[1].split("/")[0])
				parts = int(kv[1].split("/")[1])
	print("edades · %s contra %s · %s · %d minutos · semillas %s · ajustes %s" % [mine, rival, terrain, minutes, seeds, tweaks])
	var gi := 0
	var n := 0
	var ii_ok := 0
	var iii_ok := 0
	var iii_any := 0
	var ii_sum := 0
	var iii_list := []
	for pr in pairs:
		for sd in seeds:
			gi += 1
			if (gi - 1) % parts != part:
				continue
			var data := SimData.load_default()
			for tw in tweaks:
				var node: Dictionary = data.reglas["dificultades"][mine]
				var keys: PackedStringArray = (tw[0] as String).split(".")
				for i in keys.size() - 1:
					node = node[keys[i]]
				node[keys[keys.size() - 1]] = tw[1]
			var s := Sim.new(sd, 2, data, {"civs": [pr[0], pr[1]], "terreno": terrain})
			s.ais = [SimAI.new(s, 0, mine), SimAI.new(s, 1, rival)]
			var placed := [{}, {}]
			var reached := [{}, {}]
			var cuts := ["", ""]
			while s.tick < minutes * 600 and not s.game_over:
				s.step()
				if s.tick % 10 != 0:
					continue
				for pid in 2:
					var age := int(s.players[pid]["age"])
					if s.hito_in_progress(pid) and not placed[pid].has(age + 1):
						placed[pid][age + 1] = s.tick
					if age >= 2 and not reached[pid].has(age):
						reached[pid][age] = s.tick
					if s.tick % 3000 == 0:
						cuts[pid] += " %2d' %s" % [s.tick / 600, _state(s, pid)]
			for pid in 2:
				var ages := ""
				for a in [2, 3, 4]:
					ages += " %s→%s" % [_t(placed[pid].get(a, -1)), _t(reached[pid].get(a, -1))]
				print("%-13s %-13s s%-3d P%d %-7s hito→edad II/III/IV:%s |%s%s" % [pr[0], pr[1], sd, pid, [mine, rival][pid], ages, cuts[pid], " · gana P%d (%s, %s)" % [s.winner, s.end_reason, _t(s.tick)] if s.game_over else ""])
				if [mine, rival][pid] == mine:
					n += 1
					var r2: int = reached[pid].get(2, -1)
					var r3: int = reached[pid].get(3, -1)
					ii_sum += r2 if r2 >= 0 else minutes * 600
					if r2 >= 0 and r2 <= 3600:
						ii_ok += 1
					if r3 >= 0:
						iii_any += 1
						iii_list.append(_t(r3))
					if r3 >= 0 and r3 <= 9000:
						iii_ok += 1
	if n > 0:
		print("\n%s: %d jugadores · edad II antes de 6:00: %d (promedio %s) · edad III antes de 15:00: %d · edad III en %d': %d %s" % [mine, n, ii_ok, _t(ii_sum / n), iii_ok, minutes, iii_any, iii_list])
	quit()


func _t(tick: int) -> String:
	if tick < 0:
		return "--:--"
	return "%d:%02d" % [tick / 600, (tick / 10) % 60]


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


## "aldeanos a, ejército m, centros c, torres t, edad E".
func _state(s: Sim, pid: int) -> String:
	var v := 0
	var army := 0
	var cs := 0
	var tw := 0
	for e in s.actives:
		if e.alive and e.owner == pid:
			if e.is_unit():
				if e.fn == "civil":
					v += 1
				elif e.is_military():
					army += 1
			elif e.is_building() and e.built and (e.def.get("produce", []) as Array).has("aldeano"):
				cs += 1
			elif e.is_building() and e.built and e.type == "torre":
				tw += 1
	return "%da%dm%dc%dtE%d" % [v, army, cs, tw, s.players[pid]["age"]]
