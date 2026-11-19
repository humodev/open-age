extends SceneTree
## Ataques de un equipo de IA y uso del mercado (proceso/32-ronda-8/01).
##
## 1vN IA contra IA en llano: el jugador 0 (solo) contra N IA de un mismo equipo. Anota a qué
## minuto sale cada oleada de cada IA del equipo, a qué minuto llega a la base del 0 (4 o más
## de sus soldados a 30 casillas de la capital) y cuántos rivales hay ahí a la vez, minuto a minuto; y por jugador, lo que
## compró y vendió en el mercado, la edad a la que llegó y cuándo, y cuánto estuvo trabada
## por piedra (le falta para el hito y tiene más de 1000 de madera o alimento).
## --caso=2v2 sirve para mirar el mercado en una partida larga.
## Uso: godot --headless --path . -s tools/ataques_equipo.gd -- --caso=1v3|1v6|2v2 [--minutes=30] [--seed=7]
##      [--solo=dificil] [--rivales=normal] [--traza]

const P := 1000
const RADIO := 30000


func _init() -> void:
	var caso := "1v3"
	var minutes := 30
	var seed_v := 7
	var solo := "dificil"
	var rivales := ""
	var traza := false
	for a in OS.get_cmdline_user_args():
		var kv := a.trim_prefix("--").split("=")
		match kv[0]:
			"caso": caso = kv[1]
			"minutes": minutes = int(kv[1])
			"seed": seed_v = int(kv[1])
			"solo": solo = kv[1]
			"rivales": rivales = kv[1]
			"traza": traza = true
	var civs := ["guaranies", "tawantinsuyu", "mapuches", "etiopia"]
	var teams := [0, 1, 1, 1]
	if rivales == "":
		rivales = "normal"
	if caso == "2v2":
		civs = ["guaranies", "tawantinsuyu", "mapuches", "etiopia"]
		teams = [0, 1, 0, 1]
	if caso == "1v6":
		civs = ["guaranies", "tawantinsuyu", "mapuches", "etiopia", "palmares", "ayutthaya", "tupies"]
		teams = [0, 1, 1, 1, 1, 1, 1]
		if rivales == "normal" and not "--rivales" in str(OS.get_cmdline_user_args()):
			rivales = "facil"
	var np := civs.size()
	var s := Sim.new(seed_v, np, null, {"civs": civs, "equipos": teams, "terreno": "llano", "tamano": "grande" if np > 4 else "normal"})
	s.ais = []
	for pid in np:
		s.ais.append(SimAI.new(s, pid, solo if pid == 0 else rivales))
	var cap: SimEntity = null
	for e in s.actives:
		if e.alive and e.owner == 0 and e.is_building() and e.capital:
			cap = e
	var last_att := {}
	var launches := {}
	var arrivals := {}
	var ages := {}
	var peak := 0
	var peak_t := 0
	for pid in np:
		last_att[pid] = s.ais[pid].last_attack
		launches[pid] = []
		arrivals[pid] = []
		ages[pid] = []
	var per_min: Array = [] # lo más que hubo junto a la capital del 0 en cada minuto
	var stuck := {} # segundos con piedra de menos para el hito y más de 1000 de madera o alimento
	var waves: Array = [] # {pid, ids, sale, n, llega}
	while s.tick < minutes * 600 and not s.game_over:
		s.step()
		if s.tick % 10 != 0:
			continue
		for pid in np:
			var ai: SimAI = s.ais[pid]
			if ai.last_attack != last_att[pid]:
				last_att[pid] = ai.last_attack
				launches[pid].append("%d:%02d>%d~%d:%02d" % [s.tick / 600, (s.tick / 10) % 60, ai.focus, ai.eta / 600, (ai.eta / 10) % 60])
				if pid > 0 and cap != null and cap.alive:
					var ids := {}
					for e in s.actives:
						if e.alive and e.owner == pid and e.is_military() and Sim.dist(e.amove_x, e.amove_y, cap.x, cap.y) < 45000 and Sim.dist(e.x, e.y, cap.x, cap.y) >= RADIO:
							ids[e.id] = true
					if ids.size() >= 3:
						waves.append({"pid": pid, "ids": ids, "sale": s.tick, "n": ids.size(), "llega": -1})
			# Trabada: le falta piedra para la meta y le sobran 1000 de otra cosa.
			var pp: Dictionary = s.players[pid]
			var has_center := false
			for e in s.actives:
				if e.alive and e.owner == pid and e.is_building() and e.built and (e.def.get("produce", []) as Array).has("aldeano"):
					has_center = true
					break
			if has_center and int(pp["age"]) < 4 and not s.hito_in_progress(pid):
				var hc: Dictionary = s.dp(pid).cost_of(ai._hito_type(pp), pp["age"])
				var rs: Dictionary = pp["res"]
				if int(rs["piedra"]) < int(hc.get("piedra", 0)) and (int(rs["madera"]) > 1000 or int(rs["alimento"]) > 1000):
					stuck[pid] = int(stuck.get(pid, 0)) + 1
			var age := int(s.players[pid]["age"])
			if ages[pid].size() < age - 1:
				ages[pid].append("%d:%02d" % [s.tick / 600, (s.tick / 10) % 60])
		if traza and s.tick % 600 == 0:
			var line := "%d'" % (s.tick / 600)
			for pid in range(1, np):
				var ai: SimAI = s.ais[pid]
				var mk := 0
				var nv := 0
				for e in s.actives:
					if e.alive and e.owner == pid and e.def.get("mercado", false) and e.built:
						mk += 1
					if e.alive and e.owner == pid and e.fn == "civil":
						nv += 1
				var pp: Dictionary = s.players[pid]
				line += "\n  J%d lista %s ej %d ald %d mercados %d meta %s %s res %s" % [pid, ai.ready_since / 10 if ai.ready_since >= 0 else -1, ai._army_n, nv, mk, ai._goal, str(s.dp(pid).cost_of(ai._goal, pp["age"])), str(pp["res"])]
			print(line)
		if cap == null or not cap.alive:
			continue
		var tot := 0
		for e in s.actives:
			if e.alive and e.owner > 0 and e.is_military() and Sim.dist(e.x, e.y, cap.x, cap.y) < RADIO:
				tot += 1
		var mi := s.tick / 600
		while per_min.size() <= mi:
			per_min.append(0)
		per_min[mi] = maxi(int(per_min[mi]), tot)
		if tot > peak:
			peak = tot
			peak_t = s.tick
		for w in waves:
			if int(w["llega"]) >= 0:
				continue
			var inn := 0
			for id in w["ids"]:
				var u: SimEntity = s.by_id.get(id)
				if u != null and u.alive and Sim.dist(u.x, u.y, cap.x, cap.y) < RADIO:
					inn += 1
			if inn >= maxi(3, int(w["n"]) / 3):
				w["llega"] = s.tick
				arrivals[w["pid"]].append("%d:%02d(%d)" % [s.tick / 600, (s.tick / 10) % 60, int(w["n"])])
	print("%s semilla %d, %s contra %s, %d:%02d%s" % [caso, seed_v, solo, rivales, s.tick / 600, (s.tick / 10) % 60, ("  ganó el equipo %d" % s.winner_team) if s.game_over else ""])
	var times: Array = []
	for w in waves:
		if int(w["llega"]) >= 0:
			times.append(int(w["llega"]))
	times.sort()
	var gaps: Array = []
	for i in range(1, times.size()):
		gaps.append((times[i] - times[i - 1]) / 10)
	print("llegadas a la base del 0 (s entre una y la siguiente): %s" % str(gaps))
	print("soldados rivales junto a la capital del 0, lo más en cada minuto: %s" % str(per_min))
	print("pico junto a la capital del 0: %d soldados a los %d:%02d" % [peak, peak_t / 600, (peak_t / 10) % 60])
	for pid in np:
		var ai: SimAI = s.ais[pid]
		var res: Dictionary = s.players[pid]["res"]
		print("J%d %-12s edades %s  sale %s" % [pid, civs[pid], str(ages[pid]), str(launches[pid])])
		if pid > 0:
			print("    llega %s" % str(arrivals[pid]))
		print("    trabada por piedra %d s" % int(stuck.get(pid, 0)))
		print("    mercado compra %s vende %s  recursos a/m/p/r %d/%d/%d/%d" % [str(ai.mercado_compra), str(ai.mercado_venta), res["alimento"], res["madera"], res["piedra"], res["riqueza"]])
	quit()
