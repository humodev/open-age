extends SceneTree
## Mira cómo juega la IA de una civ contra otra cada 3 minutos: ejército, productores, aldeanos
## por recurso y edificios; al final, sus rechazos (proceso/21). Uso: godot --headless --path . -s tools/ia_por_dentro.gd
func _init() -> void:
	var s := Sim.new(41, 2, null, {"civs": ["etiopia", "mapuches"], "terreno": "llano"})
	s.ais = [SimAI.new(s, 0), SimAI.new(s, 1)]
	while s.tick < 14 * 600 and not s.game_over:
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
				print("%d:%02d %s aldeanos %s edificios %s" % [s.tick / 600, (s.tick / 10) % 60, ["etiopia", "mapuches"][pid], g, allb])
	print("fin ", s.tick / 600, " ganador ", s.winner)
	for ev in s.tele.events:
		if ev[2] == 0 and ev[1] in ["ia_sin_lugar", "rechazo"]:
			print("tele ", ev)
	quit()
