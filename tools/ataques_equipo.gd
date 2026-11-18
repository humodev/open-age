extends SceneTree
## Ataques de un equipo de IA y uso del mercado (proceso/32-ronda-8/01).
##
## 1vN IA contra IA en llano: el jugador 0 (solo) contra N IA de un mismo equipo. Anota a qué
## minuto sale cada oleada de cada IA del equipo, a qué minuto llega a la base del 0 (4 o más
## de sus soldados a 30 casillas de la capital) y cuántos hay a la vez; y por jugador, lo que
## compró y vendió en el mercado, la edad a la que llegó y cuándo.
## Uso: godot --headless --path . -s tools/ataques_equipo.gd -- --caso=1v3|1v6 [--minutes=30] [--seed=7]
##      [--solo=dificil] [--rivales=normal]

const P := 1000
const RADIO := 30000


func _init() -> void:
	var caso := "1v3"
	var minutes := 30
	var seed_v := 7
	var solo := "dificil"
	var rivales := ""
	for a in OS.get_cmdline_user_args():
		var kv := a.trim_prefix("--").split("=")
		match kv[0]:
			"caso": caso = kv[1]
			"minutes": minutes = int(kv[1])
			"seed": seed_v = int(kv[1])
			"solo": solo = kv[1]
			"rivales": rivales = kv[1]
	var civs := ["guaranies", "tawantinsuyu", "mapuches", "etiopia"]
	var teams := [0, 1, 1, 1]
	if rivales == "":
		rivales = "normal"
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
	var waves: Array = [] # {pid, ids, sale, n, llega}
	while s.tick < minutes * 600 and not s.game_over:
		s.step()
		if s.tick % 10 != 0:
			continue
		for pid in np:
			var ai: SimAI = s.ais[pid]
			if ai.last_attack != last_att[pid]:
				last_att[pid] = ai.last_attack
				launches[pid].append("%d:%02d>%d" % [s.tick / 600, (s.tick / 10) % 60, ai.focus])
				if pid > 0 and cap != null and cap.alive:
					var ids := {}
					for e in s.actives:
						if e.alive and e.owner == pid and e.is_military() and Sim.dist(e.amove_x, e.amove_y, cap.x, cap.y) < 45000 and Sim.dist(e.x, e.y, cap.x, cap.y) >= RADIO:
							ids[e.id] = true
					if ids.size() >= 3:
						waves.append({"pid": pid, "ids": ids, "sale": s.tick, "n": ids.size(), "llega": -1})
			var age := int(s.players[pid]["age"])
			if ages[pid].size() < age - 1:
				ages[pid].append("%d:%02d" % [s.tick / 600, (s.tick / 10) % 60])
		if cap == null or not cap.alive:
			continue
		var tot := 0
		for e in s.actives:
			if e.alive and e.owner > 0 and e.is_military() and Sim.dist(e.x, e.y, cap.x, cap.y) < RADIO:
				tot += 1
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
	print("pico junto a la capital del 0: %d soldados a los %d:%02d" % [peak, peak_t / 600, (peak_t / 10) % 60])
	for pid in np:
		var ai: SimAI = s.ais[pid]
		var res: Dictionary = s.players[pid]["res"]
		print("J%d %-12s edades %s  sale %s" % [pid, civs[pid], str(ages[pid]), str(launches[pid])])
		if pid > 0:
			print("    llega %s" % str(arrivals[pid]))
		print("    mercado compra %s vende %s  recursos a/m/p/r %d/%d/%d/%d" % [str(ai.mercado_compra), str(ai.mercado_venta), res["alimento"], res["madera"], res["piedra"], res["riqueza"]])
	quit()
