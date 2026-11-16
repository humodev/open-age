extends SceneTree
## De qué está hecho el puntaje de cada civ al minuto pedido (Sim.score, reglas.puntaje):
## recursos juntados por origen, bajas, edificios destruidos, edad e investigaciones.
## Uso: godot --headless --path . -s tools/puntaje_partes.gd -- --civs=guaranies,mapuches [--terreno=llano] [--minutes=30] [--seed=1]

func _init() -> void:
	var civs := ["guaranies", "mapuches"]
	var terrain := "llano"
	var minutes := 30
	var seed_value := 1
	for a in OS.get_cmdline_user_args():
		var kv := a.trim_prefix("--").split("=")
		match kv[0]:
			"civs": civs = Array(kv[1].split(","))
			"terreno": terrain = kv[1]
			"minutes": minutes = int(kv[1])
			"seed": seed_value = int(kv[1])
	var s := Sim.new(seed_value, 2, null, {"civs": civs, "terreno": terrain})
	s.ais = [SimAI.new(s, 0), SimAI.new(s, 1)]
	while s.tick < minutes * 600 and not s.game_over:
		s.step()
	var pc: Dictionary = s.data.reglas["puntaje"]
	for pid in 2:
		var p: Dictionary = s.players[pid]
		var book: Dictionary = p["stats"].get("origen", {})
		var by_origin := {}
		var tot := 0
		for o in book:
			var n := 0
			for k in book[o]:
				n += int(book[o][k])
			by_origin[o] = n
			tot += n
		var res_pts := tot / maxi(1, int(pc["recursos_por_punto"]))
		var kills := int(p["stats"]["bajas"]) * int(pc["por_baja"])
		var bld := int(p["stats"].get("edificios_destruidos", 0)) * int(pc["por_edificio_destruido"])
		var age := (int(p["age"]) - 1) * int(pc["por_edad"])
		var tech := (p["techs"] as Dictionary).size() * int(pc["por_investigacion"])
		print("%-13s total %5d · recursos %5d · bajas %4d · edificios %4d · edad %4d · investigaciones %4d · fin %s" % [civs[pid], s.score(pid), res_pts, kills, bld, age, tech, "%d:%02d" % [s.tick / 600, (s.tick / 10) % 60]])
		var keys := by_origin.keys()
		keys.sort_custom(func(a, b) -> bool: return by_origin[a] > by_origin[b])
		var parts := []
		for k in keys.slice(0, 8):
			parts.append("%s %d" % [k, by_origin[k]])
		print("    juntado por origen: ", ", ".join(parts))
	quit()
