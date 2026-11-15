extends SceneTree
## Eficiencia de la economía de la IA (proceso/24, paso 1b): viaje medio del recurso al
## depósito, por jugador, recurso y tramo de 5 minutos, y los depósitos de cada uno.
## Uso: godot --headless --path . -s tools/viajes.gd -- --civs=palmares,ayutthaya --terreno=bosque --minutes=30 [--seed=901]

func _init() -> void:
	var civs := ["tawantinsuyu", "mapuches"]
	var terrain := "llano"
	var minutes := 30
	var seed_value := 901
	for a in OS.get_cmdline_user_args():
		var kv := a.trim_prefix("--").split("=")
		match kv[0]:
			"civs": civs = Array(kv[1].split(","))
			"terreno": terrain = kv[1]
			"minutes": minutes = int(kv[1])
			"seed": seed_value = int(kv[1])
	var s := Sim.new(seed_value, 2, null, {"civs": civs, "terreno": terrain})
	s.ais = [SimAI.new(s, 0), SimAI.new(s, 1)]
	var prev := {}
	while s.tick < minutes * 600 and not s.game_over:
		s.step()
		if s.tick % 3000 == 0:
			for pid in 2:
				var line := "%2d min  %-13s" % [s.tick / 600, civs[pid]]
				for kind in ["alimento", "madera", "riqueza", "piedra"]:
					var key := "%d:%s" % [pid, kind]
					var v: Array = s.tele.viajes.get(key, [0, 0, 0])
					var p: Array = prev.get(key, [0, 0, 0])
					var n: int = v[0] - p[0]
					line += "  %s %s" % [kind.left(4), "-" if n == 0 else "%d (%d, máx %d)" % [(v[1] - p[1]) / n, n, v[2]]]
					prev[key] = v.duplicate()
				var stores := {}
				for e in s.actives:
					if e.alive and e.owner == pid and e.is_building() and e.built and not (e.def.get("deposito", []) as Array).is_empty():
						stores[e.type] = int(stores.get(e.type, 0)) + 1
				print(line, "  depósitos ", stores)
	if s.game_over:
		print("terminó a los %d:%02d" % [s.tick / 600, (s.tick / 10) % 60])
	quit()
