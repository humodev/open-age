extends SceneTree
## IA contra IA con y sin victoria por hitos (proceso/24, pasos 4b y 4a): hasta cuándo dura la
## partida y cuántos edificios que cuentan para la victoria le quedan a cada uno al final.
## Uso: godot --headless --path . -s tools/sin_hitos_ia.gd -- [--sitios=si|no|ambos] [--hitos=si|no|ambos] [--minutes=45] [--seed=321]
func _init() -> void:
	var minutes := 45
	var seed_value := 321
	var sites := ["si", "no"]
	var hitos_off := [false, true]
	for a in OS.get_cmdline_user_args():
		var kv := a.trim_prefix("--").split("=")
		match kv[0]:
			"minutes": minutes = int(kv[1])
			"seed": seed_value = int(kv[1])
			"sitios": sites = ["si", "no"] if kv[1] == "ambos" else [kv[1]]
			"hitos": hitos_off = [false, true] if kv[1] == "ambos" else [kv[1] == "no"]
	print("IA contra IA, llano, semilla %d, hasta %d minutos. edificios = en pie al final [j0, j1]; cuentan = los que cuentan para la victoria." % [seed_value, minutes])
	for site_win in sites:
		print("\n%s" % ("Con victoria por sitios:" if site_win == "si" else "Sin victoria por sitios (solo conquista):"))
		for pair in [["tawantinsuyu", "mapuches"], ["etiopia", "palmares"]]:
			for off in hitos_off:
				var s := Sim.new(seed_value, 2, null, {"civs": pair, "terreno": "llano", "hitos_sin_victoria": off, "sitios_sin_victoria": site_win == "no"})
				s.ais = [SimAI.new(s, 0), SimAI.new(s, 1)]
				while s.tick < minutes * 600 and not s.game_over:
					s.step()
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
				for pid in 2:
					if nc[pid] > 0 and nc[pid] <= 15:
						print("   quedan de j%d: %s" % [pid, ", ".join(left[pid].keys())])
				print("%s hitos=%s fin=%d:%02d motivo=%s ganador=%d edificios=%s cuentan=%s" % [str(pair), "no" if off else "si", s.tick / 600, (s.tick / 10) % 60, s.end_reason, s.winner, str(nb), str(nc)])
	quit()
