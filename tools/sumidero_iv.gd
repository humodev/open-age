extends SceneTree
## Sumidero de la IV y maravilla (proceso/32-ronda-8/05). Partida IA contra IA a medida, sin
## vista (2v2 experta por defecto, 45 minutos). Cada minuto en la IV anota lo que cada jugador
## tiene sin gastar; al final dice el promedio y el máximo de alimento y madera sin gastar en la
## IV, el camino de la escuela que eligió, las repetibles compradas, la guardia entrenada y qué
## pasó con cada maravilla (cuándo empezó, cuánto tardó la obra, si se terminó o cayó).
##   godot --headless --path . -s tools/sumidero_iv.gd -- [--min=45] [--seed=7]
##        [--terreno=llano] [--tamano=normal] [--dif=experta] [--equipos=0,1,0,1]

const KINDS := ["alimento", "madera", "piedra", "riqueza"]


func _init() -> void:
	var minutes := 45
	var sd := 7
	var terr := "llano"
	var tam := "normal"
	var dif := "experta"
	var teams: Array = [0, 1, 0, 1]
	for a in OS.get_cmdline_user_args():
		var kv := a.trim_prefix("--").split("=")
		if kv.size() < 2:
			continue
		match kv[0]:
			"min": minutes = int(kv[1])
			"seed": sd = int(kv[1])
			"terreno": terr = kv[1]
			"tamano": tam = kv[1]
			"dif": dif = kv[1]
			"equipos": teams = Array(kv[1].split(",")).map(func(x: String) -> int: return int(x))
	var pool := ["tawantinsuyu", "mapuches", "guaranies", "etiopia", "palmares", "ayutthaya", "tupies", "birmanos"]
	var np := teams.size()
	var civs: Array = pool.slice(0, np)
	var s := Sim.new(sd, np, null, {"civs": civs, "equipos": teams, "terreno": terr, "tamano": tam})
	s.ais = []
	for pid in np:
		s.ais.append(SimAI.new(s, pid, dif))
	var iv_min := []
	var iv_sum := []
	var iv_max := []
	var guard := []
	for pid in np:
		iv_min.append(0)
		iv_sum.append({"alimento": 0, "madera": 0})
		iv_max.append({"alimento": 0, "madera": 0})
		guard.append(0)
	var wonders := {} # id -> {player, obra, fin, cae, terminada}
	print("2v2 %s %s %s %s semilla %d, mapa %d" % [str(teams), str(civs), terr, dif, sd, s.map.n])
	while s.tick < minutes * 600 and not s.game_over:
		s.step()
		for ev in s.events:
			match String(ev["t"]):
				"maravilla_obra":
					wonders[int(ev["id"])] = {"player": int(ev["player"]), "obra": s.tick}
					print("  %s j%d empieza la maravilla" % [_t(s.tick), ev["player"]])
				"maravilla":
					if wonders.has(int(ev["id"])):
						wonders[int(ev["id"])]["fin"] = s.tick
					print("  %s j%d termina la maravilla" % [_t(s.tick), ev["player"]])
				"maravilla_cae":
					if wonders.has(int(ev["id"])):
						wonders[int(ev["id"])]["cae"] = s.tick
					print("  %s j%d pierde la maravilla (%s)" % [_t(s.tick), ev["player"], "terminada" if ev.get("terminada", false) else "en obra"])
				"trained":
					if String(ev.get("type", "")) == "guardia":
						guard[int(ev["player"])] += 1
				"tech":
					var tk := String(ev.get("tech", ""))
					if tk.begins_with("camino_"):
						print("  %s j%d elige %s" % [_t(s.tick), ev["player"], tk])
		if s.tick % 100 == 0:
			for id in wonders:
				var we: SimEntity = s.by_id.get(id)
				if we != null and we.alive and we.built:
					var lost := we.hp_max - we.hp
					wonders[id]["dano"] = maxi(int(wonders[id].get("dano", 0)), lost * 100 / maxi(1, we.hp_max))
		if s.tick % 600 != 0:
			continue
		for pid in np:
			var p: Dictionary = s.players[pid]
			if p["defeated"] or int(p["age"]) < 4:
				continue
			iv_min[pid] += 1
			for k in ["alimento", "madera"]:
				iv_sum[pid][k] += int(p["res"].get(k, 0))
				iv_max[pid][k] = maxi(int(iv_max[pid][k]), int(p["res"].get(k, 0)))
	print("Fin a los %s%s%s" % [_t(s.tick), " (terminó: %s, gana el equipo %d)" % [s.end_reason, s.winner_team] if s.game_over else "", ""])
	for pid in np:
		var p: Dictionary = s.players[pid]
		var cam := "-"
		var reps := {}
		for tk in p["techs"]:
			if String(tk).begins_with("camino_"):
				cam = String(tk)
		for tk in p.get("repetidas", {}):
			reps[tk] = p["repetidas"][tk]
		var n := maxi(1, int(iv_min[pid]))
		print("j%d %-12s eq%d edad %d %s | min en la IV %d | sin gastar en la IV: alimento prom %d máx %d, madera prom %d máx %d | al final %s | camino %s | repetidas %s | guardia %d | pob %d/%d" % [pid, civs[pid], teams[pid], p["age"], "derrotado" if p["defeated"] else "en pie", iv_min[pid], int(iv_sum[pid]["alimento"]) / n, iv_max[pid]["alimento"], int(iv_sum[pid]["madera"]) / n, iv_max[pid]["madera"], str(p["res"]), cam, str(reps), guard[pid], int(p["pop"]), int(p["pop_cap"])])
	for id in wonders:
		var w: Dictionary = wonders[id]
		var dur := "obra %s" % (_t(int(w["fin"]) - int(w["obra"])) if w.has("fin") else "sin terminar")
		print("maravilla j%d: empieza %s, %s%s, daño máximo terminada %d %%" % [w["player"], _t(int(w["obra"])), dur, ", cae %s" % _t(int(w["cae"])) if w.has("cae") else "", int(w.get("dano", 0))])
	s.soltar()
	quit()


func _t(tick: int) -> String:
	return "%d:%02d" % [tick / 600, tick % 600 / 10]
