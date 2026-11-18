extends SceneTree
## ¿Alguien se traba por un recurso? (proceso/32-ronda-8/02). Partida IA contra IA a medida
## (1v3 por defecto, experta), sin vista. Cada minuto mira, por jugador, lo que pide lo próximo
## grande (el hito de la edad siguiente o, en la IV, la maravilla) y anota qué recurso falta;
## al final dice minutos de falta por recurso, edad, lo juntado, lo que queda en el mapa y las
## vetas nuevas.
##   godot --headless --path . -s tools/recursos_partida.gd -- [--min=45] [--seed=7]
##        [--terreno=llano] [--tamano=normal] [--dif=experta] [--equipos=0,1,1,1]

const KINDS := ["alimento", "madera", "piedra", "riqueza"]


func _init() -> void:
	var minutes := 45
	var sd := 7
	var terr := "llano"
	var tam := "normal"
	var dif := "experta"
	var teams: Array = [0, 1, 1, 1]
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
	var short := []
	var ages := []
	for pid in np:
		short.append({})
		ages.append([0, 0, 0, 0])
	var veins := 0
	var map0 := _map_left(s)
	print("1v%d %s %s %s semilla %d, mapa %d (%d casillas por jugador). En el mapa al empezar: %s" % [np - 1, terr, tam, dif, sd, s.map.n, s.map.n * s.map.n / np, str(map0)])
	while s.tick < minutes * 600 and not s.game_over:
		s.step()
		for ev in s.events:
			if ev["t"] == "recurso_nuevo":
				var ne: SimEntity = s.by_id.get(int(ev["id"]))
				if ne != null and (ne.type == "roca" or ne.type == "riqueza"):
					veins += 1
					print("  %d min: veta nueva %s %d en %d,%d" % [s.tick / 600, ne.type, ne.amount, ne.tx, ne.ty])
		if s.tick % 600 != 0:
			continue
		for pid in np:
			var p: Dictionary = s.players[pid]
			if p["defeated"]:
				continue
			var age := int(p["age"])
			var dd := s.dp(pid)
			var cost: Dictionary = {}
			if age < dd.edades.size():
				cost = (dd.edades[age] as Dictionary).get("hito_costo", {})
			elif not _has_wonder(s, pid):
				cost = dd.cost_of("maravilla", age)
			for k in cost:
				if int(p["res"].get(k, 0)) < int(cost[k]):
					short[pid][k] = int(short[pid].get(k, 0)) + 1
			if age >= 2 and ages[pid][age - 1] == 0:
				ages[pid][age - 1] = s.tick / 600
		if s.tick % 9000 == 0:
			var line := "%2d min |" % (s.tick / 600)
			for pid in np:
				var r: Dictionary = s.players[pid]["res"]
				line += " j%d e%d a%d m%d p%d r%d |" % [pid, s.players[pid]["age"], r["alimento"], r["madera"], r["piedra"], r["riqueza"]]
			print(line)
	print("Fin a los %d min%s. Vetas nuevas: %d" % [s.tick / 600, " (terminó)" if s.game_over else "", veins])
	for pid in np:
		var p: Dictionary = s.players[pid]
		var got := {}
		var book: Dictionary = p["stats"].get("origen", {})
		for o in book:
			for k in book[o]:
				got[k] = int(got.get(k, 0)) + int(book[o][k])
		print("j%d %-12s eq%d edad %d (II %s, III %s, IV %s) %s maravilla %s | min sin alcanzar por recurso %s | juntó %s | tiene %s" % [pid, civs[pid], teams[pid], p["age"], ages[pid][1], ages[pid][2], ages[pid][3], "derrotado" if p["defeated"] else "en pie", "sí" if _has_wonder(s, pid) else "no", str(short[pid]), str(got), str(p["res"])])
	print("En el mapa al final: %s" % str(_map_left(s)))
	s.soltar()
	quit()


func _has_wonder(s: Sim, pid: int) -> bool:
	for e in s.actives:
		if e.alive and e.owner == pid and e.def.get("maravilla", false):
			return true
	return false


func _map_left(s: Sim) -> Dictionary:
	var out := {}
	for e in s.entities:
		if e.alive and e.is_resource() and e.res_kind in KINDS and e.type != "arbol":
			out[e.res_kind] = int(out.get(e.res_kind, 0)) + e.amount
	return out
