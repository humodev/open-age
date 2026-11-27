extends SceneTree
## IA contra IA con y sin victoria por hitos (proceso/24, pasos 4b y 4a): hasta cuándo dura la
## partida y cuántos edificios que cuentan para la victoria le quedan a cada uno al final.
## Uso: godot --headless --path . -s tools/sin_hitos_ia.gd -- [--sitios=si|no|ambos] [--hitos=si|no|ambos] [--minutes=45] [--seed=321]
func _init() -> void:
	var minutes := 45
	var seed_value := 321
	var sites := ["si", "no"]
	var hitos_off := [false, true]
	var pairs := [["tawantinsuyu", "mapuches"], ["etiopia", "palmares"]]
	for a in OS.get_cmdline_user_args():
		var kv := a.trim_prefix("--").split("=")
		match kv[0]:
			"minutes": minutes = int(kv[1])
			"seed": seed_value = int(kv[1])
			"sitios": sites = ["si", "no"] if kv[1] == "ambos" else [kv[1]]
			"hitos": hitos_off = [false, true] if kv[1] == "ambos" else [kv[1] == "no"]
			"par": pairs = [Array(kv[1].split(","))] # proceso/53: un solo cruce, --par=a,b
	print("IA contra IA, llano, semilla %d, hasta %d minutos. edificios = en pie al final [j0, j1]; cuentan = los que cuentan para la victoria." % [seed_value, minutes])
	for site_win in sites:
		print("\n%s" % ("Con victoria por sitios:" if site_win == "si" else "Sin victoria por sitios (solo conquista):"))
		for pair in pairs:
			for off in hitos_off:
				var s := Sim.new(seed_value, 2, null, {"civs": pair, "terreno": "llano", "hitos_sin_victoria": off, "sitios_sin_victoria": site_win == "no"})
				s.ais = [SimAI.new(s, 0), SimAI.new(s, 1)]
				while s.tick < minutes * 600 and not s.game_over:
					s.step()
					if OS.get_cmdline_user_args().has("--detalle") and s.tick % 1800 == 0:
						var lc := [0, 0]
						var lm := [0, 0]
						for e in s.actives:
							if e.alive and e.owner >= 0 and e.is_building() and s.counts_for_victory(e):
								lc[e.owner] += 1
							elif e.alive and e.owner >= 0 and e.is_unit() and e.is_military():
								lm[e.owner] += 1
						print("   min %d: cuentan %s ejército %s edad %s caza %s oleada %s" % [s.tick / 600, str(lc), str(lm), str([s.players[0]["age"], s.players[1]["age"]]), str([s.tick - s.ais[0].last_hunt, s.tick - s.ais[1].last_hunt]), str([s.ais[0].wave, s.ais[1].wave])])
				var nb := [0, 0]
				var nc := [0, 0]
				var left := [{}, {}] # tipos que siguen contando, por jugador (proceso/51)
				for e in s.actives:
					if e.alive and e.owner >= 0 and e.is_building():
						nb[e.owner] += 1
						if s.counts_for_victory(e):
							nc[e.owner] += 1
							var cell := "%s%s@%d,%d" % [e.type, "" if e.built else "(obra)", e.x / 1000, e.y / 1000]
							left[e.owner][cell] = 1
				var mil := [0, 0]
				var idle := [0, 0]
				var det := [{}, {}]
				for u in s.all_units():
					if u.alive and u.owner >= 0 and u.is_military():
						mil[u.owner] += 1
						if u.order == SimEntity.Order.IDLE:
							idle[u.owner] += 1
						if OS.get_cmdline_user_args().has("--detalle"):
							var tg: SimEntity = s.by_id.get(u.target)
							var key := "%s/%d/%s" % [u.type, u.order, tg.type if tg != null and tg.alive else "-"]
							det[u.owner][key] = int(det[u.owner].get(key, 0)) + 1
							if u.order == SimEntity.Order.ATTACK_MOVE and u.owner == 1 and int(det[1].get("am", 0)) < 8:
								det[1]["am"] = int(det[1].get("am", 0)) + 1
								print("   am %s en %d,%d hacia %d,%d grupo %d atasco %d" % [u.type, u.x / 1000, u.y / 1000, u.goal_x / 1000, u.goal_y / 1000, u.group, u.stuck])
				print("   ejército al final %s (quietos %s)" % [str(mil), str(idle)])
				if OS.get_cmdline_user_args().has("--detalle"):
					print("   tropa (tipo/orden/blanco): ", det)
				for pid in 2:
					if nc[pid] > 0 and nc[pid] <= 15:
						print("   quedan de j%d: %s" % [pid, ", ".join(left[pid].keys())])
				print("%s hitos=%s fin=%d:%02d motivo=%s ganador=%d edificios=%s cuentan=%s" % [str(pair), "no" if off else "si", s.tick / 600, (s.tick / 10) % 60, s.end_reason, s.winner, str(nb), str(nc)])
	quit()
