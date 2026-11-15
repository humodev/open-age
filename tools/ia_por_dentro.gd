extends SceneTree
## Mira cómo juega la IA de una civ contra otra cada 3 minutos: ejército, productores, aldeanos
## por recurso y edificios; al final, sus rechazos (proceso/21).
## Uso: godot --headless --path . -s tools/ia_por_dentro.gd -- [--civs=etiopia,mapuches] [--terreno=llano] [--minutes=14] [--seed=41]
func _init() -> void:
	var civs := ["etiopia", "mapuches"]
	var terrain := "llano"
	var minutes := 14
	var seed_value := 41
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
		if s.tick % 1800 == 0:
			for pid in 2:
				var u := {}
				var b := {}
				for e in s.actives:
					if e.alive and e.owner == pid:
						if e.is_unit() and e.is_military(): u[e.type] = u.get(e.type, 0) + 1
						elif e.is_building() and not e.def.get("produce", []).is_empty(): b[e.type] = b.get(e.type, 0) + 1
				var g := {}
				var allb := {}
				for e in s.actives:
					if e.alive and e.owner == pid and e.fn == "civil" and e.is_unit(): g[e.gather_kind + ":" + str(e.order)] = g.get(e.gather_kind + ":" + str(e.order), 0) + 1
					if e.alive and e.owner == pid and e.is_building(): allb[e.type] = allb.get(e.type, 0) + 1
				var p: Dictionary = s.players[pid]
				print("%d:%02d %s edad %d · ejército %s · banco %s" % [s.tick / 600, (s.tick / 10) % 60, civs[pid], p["age"], u, p["res"]])
				print("      aldeanos %s edificios %s" % [g, allb])
	print("fin ", s.tick / 600, " ganador ", s.winner)
	for ev in s.tele.events:
		if ev[2] == 0 and ev[1] in ["ia_sin_lugar", "rechazo"]:
			print("tele ", ev)
	quit()
