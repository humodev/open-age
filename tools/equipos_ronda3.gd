extends SceneTree
## Medidas del jugador de equipos, tercera ronda (proceso/24, paso 4l).
##
## --caso=bengalas  2v2 de IA en llano, aliados juntos y mezclados, varias semillas. El jugador 0
##                  tira una bengala de ataque sobre la capital rival más cercana a los 12 y 18
##                  minutos y le pide madera y alimento al aliado (2) a los 8, 14 y 20 minutos.
##                  Anota cuántos aliados hay junto a la bengala a los 45, 90, 150 y 240 s, qué
##                  dijo el aliado, los pedidos concedidos y los tributos que dio sin que se los pidan.
## --caso=fortines  2v2 en fortines (semilla 31, estilos pacífica, acosadora, agresiva y normal),
##                  `--minutes` (45): caminos imposibles y trabadas por jugador, tipo de unidad y
##                  destino. Con --telemetria=carpeta guarda el JSONL para tools/telemetria.gd.
## --caso=traza    la primera semilla, juntos: qué hacen las unidades que el aliado manda a la
##                  bengala de los 12 minutos (orden, distancia, destino) cada 15 s.
## --caso=bolsillos  el 2v2 de fortines hasta `--minutes`: cada vez que una unidad militar entra
##                  a un bolsillo (casillas libres encerradas, menos de 300, que el buscador de
##                  caminos no puede dejar), anota de dónde venía, su orden y si cortó una esquina.
## Uso: godot --headless --path . -s tools/equipos_ronda3.gd -- --caso=bengalas|fortines [--semillas=11,23] [--minutes=45]

const P := 1000
const NEAR := 12000 # "junto a la bengala": 12 casillas
const BASE := 25000 # "en la base rival": 25 casillas de la bengala (la capital y lo que la rodea)


func _init() -> void:
	var caso := "bengalas"
	var seeds := [11, 23, 41]
	var minutes := 45
	var tele_dir := ""
	var ub_arg := "juntos"
	var zona := [] # x0,y0,x1,y1 (fortines): dibuja esas casillas cada 10 minutos desde los 30
	for a in OS.get_cmdline_user_args():
		var kv := a.trim_prefix("--").split("=")
		match kv[0]:
			"caso":
				caso = kv[1]
			"semillas":
				seeds = []
				for s in kv[1].split(","):
					seeds.append(int(s))
			"minutes":
				minutes = int(kv[1])
			"telemetria":
				tele_dir = kv[1]
			"ub":
				ub_arg = kv[1]
			"zona":
				for v in kv[1].split(","):
					zona.append(int(v))
	if caso == "bengalas":
		_flares(seeds)
	elif caso == "bolsillos":
		_pockets(minutes)
	elif caso == "traza":
		_trace(seeds[0], ub_arg)
	else:
		_fortines(minutes, tele_dir, zona)
	quit()


func _new_sim(seed_value: int, opts: Dictionary, styles: Array = []) -> Sim:
	var s := Sim.new(seed_value, (opts["civs"] as Array).size(), null, opts)
	s.ais = []
	for pid in (opts["civs"] as Array).size():
		var ai := SimAI.new(s, pid)
		if pid < styles.size():
			ai.personality = styles[pid]
		s.ais.append(ai)
	return s


func _capital(s: Sim, pid: int) -> SimEntity:
	for e in s.actives:
		if e.alive and e.owner == pid and e.is_building() and e.capital:
			return e
	return null


func _flares(seeds: Array) -> void:
	var tot_flares := 0
	var tot_base := 0
	var tot_reached := 0
	var tot_asked := 0
	var tot_given := 0
	var tot_given_wood := 0
	var tot_spont := 0
	var tot_other := 0
	var tot_sent := 0
	var tot_arrived := 0
	var tot_flare_ok := 0
	var tot_gifts := 0
	for seed_value in seeds:
		for ub in ["juntos", "mezclados"]:
			var s := _new_sim(seed_value, {"civs": ["etiopia", "mapuches", "palmares", "ayutthaya"], "equipos": [0, 1, 0, 1], "terreno": "llano", "ubicacion_equipos": ub})
			var flares := [] # [tick, x, y, muestras{seg: n}, frase]
			var asks := [] # [tick, recurso, concedido]
			var said: Array[String] = []
			var spont := 0
			var gifts := 0 # regalos del aliado (2) al jugador 0, sin pedido
			var end_tick := 24 * 600
			while s.tick < end_tick and not s.game_over:
				var t := s.tick
				if t == 12 * 600 or t == 18 * 600:
					var c0 := _capital(s, 0)
					if c0 != null:
						var best: SimEntity = null
						var bd := 1 << 60
						for e in s.actives:
							if e.alive and e.is_building() and e.capital and s.enemies(0, e.owner):
								var d := Sim.dist(e.x, e.y, c0.x, c0.y)
								if d < bd:
									bd = d
									best = e
						if best != null:
							s.push_command({"t": "bengala", "player": 0, "x": best.x, "y": best.y})
							flares.append([t, best.x, best.y, {}, "", {}, {}]) # ... enviados {id: true}, llegaron {id: true}
				if t == 8 * 600 or t == 14 * 600 or t == 20 * 600:
					for k in ["madera", "alimento"]:
						s.push_command({"t": "pedir", "player": 0, "a": 2, "recurso": k})
						asks.append([t, k, ""])
				s.step()
				for ev in s.events:
					if ev["t"] == "ia_dice" and int(ev["player"]) == 2:
						if str(ev["clave"]).begins_with("voy_atacar") or ev["clave"] in ["sin_tropa", "voy_oleada", "no_sobra", "mando_otro"]:
							said.append("%d:%02d %s %s" % [s.tick / 600, (s.tick / 10) % 60, ev["clave"], str(ev.get("n", ev.get("recurso", "")))])
							if not flares.is_empty() and s.tick - int(flares[-1][0]) < 300 and (flares[-1][4] as String) == "" and ev["clave"] in ["voy_atacar", "sin_tropa", "voy_oleada"]:
								flares[-1][4] = "%s %s" % [ev["clave"], str(ev.get("n", ""))]
					# Cada tributo de la IA va con su frase: "mando" (lo pedido o un regalo) o
					# "mando_otro" (otro recurso en lugar del pedido).
					if ev["t"] == "ia_dice" and ev["clave"] in ["mando", "mando_otro"]:
						var matched := false
						if int(ev["player"]) == 2 and int(ev.get("a", -1)) == 0:
							var want: String = ev["recurso"] if ev["clave"] == "mando" else ev.get("pedido", "")
							for q in asks:
								if q[2] == "" and q[1] == want and s.tick - int(q[0]) <= 1800:
									q[2] = "concedido" if ev["clave"] == "mando" else "otro (%s)" % ev["recurso"]
									matched = true
									break
						if not matched:
							spont += 1
							if int(ev["player"]) == 2 and int(ev.get("a", -1)) == 0:
								gifts += 1
				# Los enviados: las unidades que el aliado anota para la bengala (SimAI._flare_units).
				if not flares.is_empty() and s.tick % 10 == 0:
					var lf: Array = flares[-1]
					var ai2: SimAI = s.ais[2]
					for id in ai2._flare_units:
						if int(ai2._flare_units[id]) > int(lf[0]) and not _sent_before(flares, id):
							lf[5][id] = true
					for f in flares:
						if s.tick - int(f[0]) <= 2400:
							for id in f[5]:
								var u: SimEntity = s.by_id.get(id)
								if u != null and u.alive and Sim.dist(u.x, u.y, int(f[1]), int(f[2])) < BASE:
									f[6][id] = true
				# A los 45, 90, 150 y 240 s (como el informe) y el máximo cada 5 s en esos 4 minutos.
				for f in flares:
					var since := s.tick - int(f[0])
					if since > 0 and since <= 2400 and since % 50 == 0:
						var n := 0
						var nb := 0
						for e in s.actives:
							if e.alive and e.owner == 2 and e.is_military():
								var d := Sim.dist(e.x, e.y, int(f[1]), int(f[2]))
								n += 1 if d < NEAR else 0
								nb += 1 if d < BASE else 0
						if since / 10 in [45, 90, 150, 240]:
							f[3][since / 10] = "%d/%d" % [n, nb]
						f[3]["max"] = "%d/%d" % [maxi(n, int(str(f[3].get("max", "0/0")).split("/")[0])), maxi(nb, int(str(f[3].get("max", "0/0")).split("/")[1]))]
			print("semilla %d %-9s fin %d:%02d%s" % [seed_value, ub, s.tick / 600, (s.tick / 10) % 60, "  (terminó)" if s.game_over else ""])
			for f in flares:
				var best_n := 0
				var best_b := 0
				for k in f[3]:
					var parts: PackedStringArray = str(f[3][k]).split("/")
					best_n = maxi(best_n, int(parts[0]))
					best_b = maxi(best_b, int(parts[1]))
				tot_flares += 1
				if best_n > 0:
					tot_reached += 1
				if best_b > 0:
					tot_base += 1
				tot_sent += (f[5] as Dictionary).size()
				tot_arrived += (f[6] as Dictionary).size()
				if (f[6] as Dictionary).size() > 0:
					tot_flare_ok += 1
				print("  bengala %d:00 → %s · enviados %d, llegaron a 25 casillas %d · aliados a 12/25 casillas a los 45/90/150/240 s y máximo: %s" % [int(f[0]) / 600, f[4] if f[4] != "" else "(sin respuesta)", (f[5] as Dictionary).size(), (f[6] as Dictionary).size(), str(f[3])])
			for q in asks:
				tot_asked += 1
				if q[2] == "concedido":
					tot_given += 1
					if q[1] == "madera":
						tot_given_wood += 1
				elif q[2] != "":
					tot_other += 1
				print("  pedido %d:00 %-8s %s" % [int(q[0]) / 600, q[1], q[2] if q[2] != "" else "no"])
			print("  tributos no pedidos: %d (del aliado al jugador 0: %d) · frases del aliado: %s" % [spont, gifts, str(said)])
			tot_spont += spont
			tot_gifts += gifts
	print("TOTAL bengalas de ataque con aliados a 12 casillas: %d de %d; a 25 casillas: %d de %d" % [tot_reached, tot_flares, tot_base, tot_flares])
	print("TOTAL pedidos concedidos: %d de %d (madera %d); con otro recurso: %d" % [tot_given, tot_asked, tot_given_wood, tot_other])
	print("TOTAL tributos no pedidos: %d (del aliado al jugador 0: %d)" % [tot_spont, tot_gifts])
	print("TOTAL bengalas con al menos un enviado en la base rival (25 casillas): %d de %d · enviados %d, llegaron %d" % [tot_flare_ok, tot_flares, tot_sent, tot_arrived])


## Casillas de la zona: . libre, # sólida (con la letra del dueño si es un edificio), ~ agua,
## ^ peñasco, P puerta; los números son unidades del jugador (cuántas, hasta 9) en la casilla.
func _dump(s: Sim, z: Array) -> void:
	print("zona %s a los %d:00" % [str(z), s.tick / 600])
	var units := {}
	for e in s.actives:
		if e.alive and e.is_unit() and e.owner >= 0:
			var k := (e.x / P) * 4096 + e.y / P
			units[k] = units.get(k, "") + str(e.owner)
	var kinds := {}
	for y in range(z[1], z[3]):
		var row := ""
		for x in range(z[0], z[2]):
			var k := x * 4096 + y
			var occ := s.map.occupant(x, y)
			if units.has(k):
				row += str(units[k])[0]
			elif s.map.gate_owner[y * s.map.n + x] >= 0:
				row += "P"
			elif s.map.is_solid(x, y):
				var b: SimEntity = s.by_id.get(occ)
				if b != null:
					var ch := b.type.left(1)
					kinds[ch + " " + b.type + "@" + str(b.owner)] = true
					row += ch
				elif s.map.water[y * s.map.n + x] == 1:
					row += "~"
				elif s.map.rock[y * s.map.n + x] == 1:
					row += "^"
				else:
					row += "#"
			else:
				row += "."
		print("  %3d %s" % [y, row])
	print("  ", kinds.keys())


func _fortines(minutes: int, tele_dir: String, zona: Array = []) -> void:
	var opts := {"civs": ["tawantinsuyu", "mapuches", "guaranies", "etiopia"], "equipos": [0, 1, 0, 1], "terreno": "fortines"}
	var s := _new_sim(31, opts, ["pacifica", "acosadora", "agresiva", "normal"])
	while s.tick < minutes * 600 and not s.game_over:
		s.step()
		if zona.size() == 4 and s.tick % 6000 == 0 and s.tick >= 18000:
			_dump(s, zona)
	var by := {} # jugador:tipo:clase -> n
	var dest := {} # jugador:destino (celda de 8) -> n
	for ev in s.tele.events:
		if ev[1] != "sin_camino" and ev[1] != "trabada":
			continue
		var k := "j%d %s %s" % [ev[2], ev[1], (ev[5] as Dictionary).get("tipo", "?")]
		by[k] = int(by.get(k, 0)) + 1
		var d := "j%d %s → (%d,%d)" % [ev[2], ev[1], int(ev[3]) / 8 * 8, int(ev[4]) / 8 * 8]
		dest[d] = int(dest.get(d, 0)) + 1
	print("fortines 2v2 semilla 31, %d:%02d%s · totales %s" % [s.tick / 600, (s.tick / 10) % 60, " (terminó)" if s.game_over else "", str(s.tele.counts)])
	for pid in 4:
		print("  j%d %s en pie=%s bases %s" % [pid, opts["civs"][pid], str(not s.players[pid]["defeated"]), str(s.bases[pid])])
	var keys := by.keys()
	keys.sort_custom(func(a, b): return by[a] > by[b])
	for k in keys.slice(0, 14):
		print("  %5d  %s" % [by[k], k])
	var dk := dest.keys()
	dk.sort_custom(func(a, b): return dest[a] > dest[b])
	print("  destinos más pedidos:")
	for k in dk.slice(0, 14):
		print("  %5d  %s" % [dest[k], k])
	if tele_dir != "":
		s.tele.save(tele_dir.path_join("fortines-2v2-31.jsonl"), s.tele.header(s, 31, opts))


func _trace(seed_value: int, ub: String) -> void:
	var s := _new_sim(seed_value, {"civs": ["etiopia", "mapuches", "palmares", "ayutthaya"], "equipos": [0, 1, 0, 1], "terreno": "llano", "ubicacion_equipos": ub})
	var fx := 0
	var fy := 0
	var ally: SimAI = s.ais[2]
	while s.tick < 23 * 600 and not s.game_over:
		if s.tick == 8 * 600 or s.tick == 14 * 600 or s.tick == 20 * 600:
			for k in ["madera", "alimento"]:
				s.push_command({"t": "pedir", "player": 0, "a": 2, "recurso": k})
		if s.tick == 18 * 600:
			s.push_command({"t": "bengala", "player": 0, "x": fx, "y": fy})
			print("bengala 18:00; ejército del aliado %d" % _army(s, 2))
		if s.tick == 12 * 600:
			var c0 := _capital(s, 0)
			var bd := 1 << 60
			for e in s.actives:
				if e.alive and e.is_building() and e.capital and s.enemies(0, e.owner):
					var d := Sim.dist(e.x, e.y, c0.x, c0.y)
					if d < bd:
						bd = d
						fx = e.x
						fy = e.y
			s.push_command({"t": "bengala", "player": 0, "x": fx, "y": fy})
			var c2 := _capital(s, 2)
			print("bengala en (%d,%d); capital aliada a %d casillas; ejército del aliado %d; oleada %d" % [fx / P, fy / P, Sim.dist(c2.x, c2.y, fx, fy) / P, _army(s, 2), ally.wave])
		s.step()
		for ev in s.events:
			if ev["t"] == "ia_dice" and int(ev["player"]) == 2:
				print("  %d:%02d dice %s %s" % [s.tick / 600, (s.tick / 10) % 60, ev["clave"], str(ev.get("n", ""))])
		if s.tick > 12 * 600 and (s.tick - 12 * 600) % 150 == 0:
			var line := "%d:%02d" % [s.tick / 600, (s.tick / 10) % 60]
			for id in ally._flare_units:
				var e: SimEntity = s.by_id.get(id)
				if e == null or not e.alive:
					line += " [muerto]"
					continue
				var tgt: SimEntity = s.by_id.get(e.target)
				var g: Dictionary = s.groups.groups.get(e.group, {})
				line += " [%s o%d d%d g%s%s]" % [e.type.left(5), int(e.order), Sim.dist(e.x, e.y, fx, fy) / P, str(g.get("state", "-")), (" →" + tgt.type + "@" + str(tgt.owner) + " " + str(Sim.dist(e.x, e.y, tgt.x, tgt.y) / P)) if tgt != null and tgt.alive else ""]
			var free := 0
			var fighting := 0
			for e in s.actives:
				if e.alive and e.owner == 2 and e.is_unit() and e.is_military():
					if e.order == SimEntity.Order.ATTACK:
						fighting += 1
					elif not ally._at_flare(e):
						free += 1
			print(line.left(300), "  oleada %d libres %d peleando %d espera %s marcha %s" % [ally.wave, free, fighting, str(not ally._flare_wave.is_empty()), str(not ally._flare_march.is_empty())])


func _army(s: Sim, pid: int) -> int:
	var n := 0
	for e in s.actives:
		if e.alive and e.owner == pid and e.is_unit() and e.is_military():
			n += 1
	return n


## Componentes de casillas libres para el jugador `pid`, con la regla del buscador (diagonal solo
## si las dos casillas de al lado están libres). Devuelve el tamaño del componente de cada casilla.
func _components(s: Sim, pid: int) -> PackedInt32Array:
	var n := s.map.n
	var comp := PackedInt32Array()
	comp.resize(n * n)
	comp.fill(-1)
	var sizes: Array[int] = []
	for start in n * n:
		if comp[start] >= 0 or s.map.is_solid(start % n, start / n, pid):
			continue
		var id := sizes.size()
		var q: Array[int] = [start]
		comp[start] = id
		var cnt := 0
		while not q.is_empty():
			var c: int = q.pop_back()
			cnt += 1
			var cx := c % n
			var cy := c / n
			for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1), Vector2i(1, 1), Vector2i(1, -1), Vector2i(-1, 1), Vector2i(-1, -1)]:
				var x: int = cx + d.x
				var y: int = cy + d.y
				if not s.map.in_bounds(x, y) or comp[y * n + x] >= 0 or s.map.is_solid(x, y, pid):
					continue
				if d.x != 0 and d.y != 0 and (s.map.is_solid(cx + d.x, cy, pid) or s.map.is_solid(cx, cy + d.y, pid)):
					continue
				comp[y * n + x] = id
				q.append(y * n + x)
		sizes.append(cnt)
	var out := PackedInt32Array()
	out.resize(n * n)
	for i in n * n:
		out[i] = sizes[comp[i]] if comp[i] >= 0 else 0
	return out


func _pockets(minutes: int) -> void:
	var opts := {"civs": ["tawantinsuyu", "mapuches", "guaranies", "etiopia"], "equipos": [0, 1, 0, 1], "terreno": "fortines"}
	var s := _new_sim(31, opts, ["pacifica", "acosadora", "agresiva", "normal"])
	var sizes := {}
	var prev := {}
	var inside := {}
	var entries := {}
	var n := s.map.n
	while s.tick < minutes * 600 and not s.game_over:
		s.step()
		if s.tick % 300 == 0:
			for pid in 4:
				sizes[pid] = _components(s, pid)
		if s.tick % 2 != 0 or sizes.is_empty():
			continue
		for e in s.actives:
			if not (e.alive and e.is_unit() and e.owner >= 0 and e.inside < 0):
				continue
			var tx := e.x / P
			var ty := e.y / P
			var sz: int = (sizes[e.owner] as PackedInt32Array)[ty * n + tx]
			var was: Vector2i = prev.get(e.id, Vector2i(tx, ty))
			prev[e.id] = Vector2i(tx, ty)
			if sz > 0 and sz < 300 and not inside.has(e.id):
				inside[e.id] = true
				var diag := was.x != tx and was.y != ty
				var corner := diag and (s.map.is_solid(tx, was.y, e.owner) or s.map.is_solid(was.x, ty, e.owner))
				var g: Dictionary = s.groups.groups.get(e.group, {})
				var k := "j%d %s orden %d grupo %s esquina %s" % [e.owner, e.fn, int(e.order), "-" if g.is_empty() else str(g["state"]), str(corner)]
				entries[k] = int(entries.get(k, 0)) + 1
				if entries.size() <= 40 and int(entries[k]) <= 2:
					print("%d:%02d entra j%d %s %s a (%d,%d) de (%d,%d) bolsillo de %d · orden %d grupo %s esquina %s" % [s.tick / 600, (s.tick / 10) % 60, e.owner, e.type, e.fn, tx, ty, was.x, was.y, sz, int(e.order), "-" if g.is_empty() else str(g["state"]), str(corner)])
			elif (sz == 0 or sz >= 300) and inside.has(e.id):
				inside.erase(e.id)
	print("entradas a bolsillos por tipo:")
	for k in entries:
		print("  %5d  %s" % [entries[k], k])
	print("totales de telemetría ", str(s.tele.counts))


func _sent_before(flares: Array, id: int) -> bool:
	for f in flares:
		if (f[5] as Dictionary).has(id):
			return true
	return false
