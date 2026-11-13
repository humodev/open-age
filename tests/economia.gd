extends SceneTree
## Medición de la economía (etapa 0 de docs/diseno/revision-economia/v3/04, §9).
## Por civ: riqueza acumulada por origen, edades y órdenes por minuto.
## Uso: godot --headless --path . -s tests/economia.gd -- [--paz] [--minutes=30] [--seeds=2] [--terreno=llano]

const CIVS := ["tawantinsuyu", "mapuches", "guaranies", "etiopia", "palmares", "ayutthaya"]
const MARKS := [5, 10, 20, 30]

func _init() -> void:
	var minutes := 30
	var seeds := 2
	var peace := false
	var terrain := "llano"
	for a in OS.get_cmdline_user_args():
		var kv := a.trim_prefix("--").split("=")
		match kv[0]:
			"minutes":
				minutes = int(kv[1])
			"seeds":
				seeds = int(kv[1])
			"paz":
				peace = true
			"terreno":
				terrain = kv[1]
	var acc := {} # civ -> {"riq": {mark: total}, "orig": {origin: n}, "age2": [], "age3": [], "ord": {type: n}, "games": n}
	for c in CIVS:
		acc[c] = {"riq": {}, "orig": {}, "age2": [], "age3": [], "ord": {}, "games": 0}
	for i in CIVS.size():
		for sd in seeds:
			var pair: Array = [CIVS[i], CIVS[(i + 1 + sd) % CIVS.size()]]
			var s := Sim.new(900 + i * 31 + sd * 7, 2, null, {"civs": pair, "terreno": terrain})
			s.ais = [SimAI.new(s, 0), SimAI.new(s, 1)]
			if peace:
				for ai in s.ais:
					ai.personality = "paz"
			var ages := [{}, {}]
			while s.tick < minutes * 600 and not s.game_over:
				s.step()
				if s.tick % 100 == 0:
					for pid in 2:
						var ag: int = s.players[pid]["age"]
						if ag >= 2 and not ages[pid].has(2):
							ages[pid][2] = s.tick
						if ag >= 3 and not ages[pid].has(3):
							ages[pid][3] = s.tick
				if s.tick % 600 == 0 and (s.tick / 600) in MARKS:
					for pid in 2:
						var tot := 0
						for o in s.players[pid]["stats"].get("origen", {}):
							tot += int(s.players[pid]["stats"]["origen"][o].get("riqueza", 0))
						var r: Dictionary = acc[pair[pid]]["riq"]
						r[s.tick / 600] = int(r.get(s.tick / 600, 0)) + tot
			for pid in 2:
				var a: Dictionary = acc[pair[pid]]
				a["games"] += 1
				for o in s.players[pid]["stats"].get("origen", {}):
					a["orig"][o] = int(a["orig"].get(o, 0)) + int(s.players[pid]["stats"]["origen"][o].get("riqueza", 0))
				for o in s.players[pid]["stats"].get("ordenes", {}):
					a["ord"][o] = int(a["ord"].get(o, 0)) + int(s.players[pid]["stats"]["ordenes"][o])
				if ages[pid].has(2):
					a["age2"].append(ages[pid][2])
				if ages[pid].has(3):
					a["age3"].append(ages[pid][3])
	print("ECONOMÍA %s, %d min, terreno %s" % ["en paz" if peace else "con guerra", minutes, terrain])
	print("%-13s %8s %8s %8s %8s  %6s %6s  %s" % ["civ", "riq@5", "@10", "@20", "@30", "edadII", "III", "riqueza por origen"])
	for c in CIVS:
		var a: Dictionary = acc[c]
		var g: int = maxi(1, a["games"])
		var cols := []
		for mk in MARKS:
			cols.append(str(int(a["riq"].get(mk, 0)) / g))
		var orig_tot := 0
		for o in a["orig"]:
			orig_tot += int(a["orig"][o])
		var parts := []
		for o in a["orig"]:
			parts.append("%s %d%%" % [o, int(a["orig"][o]) * 100 / maxi(1, orig_tot)])
		print("%-13s %8s %8s %8s %8s  %6s %6s  %s" % [c, cols[0], cols[1], cols[2], cols[3], _avg_time(a["age2"]), _avg_time(a["age3"]), ", ".join(parts)])
	print("\nÓrdenes por minuto (sin mover ni recolectar):")
	for c in CIVS:
		var a: Dictionary = acc[c]
		var g: int = maxi(1, a["games"])
		var parts := []
		var keys: Array = a["ord"].keys()
		keys.sort()
		for o in keys:
			if o == "move" or o == "target":
				continue
			var per := float(a["ord"][o]) / g / minutes
			if per >= 0.05:
				parts.append("%s %.2f" % [o, per])
		print("%-13s %s" % [c, ", ".join(parts)])
	quit()


func _avg_time(list: Array) -> String:
	if list.is_empty():
		return "-"
	var t := 0
	for x in list:
		t += int(x)
	t /= list.size()
	return "%d:%02d" % [t / 600, (t / 10) % 60]
