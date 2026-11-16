extends SceneTree
## Por qué ganan los guaraníes (proceso/24, 5e). Juega las mismas partidas del torneo
## (tests/torneo.gd: mismas semillas, mismos lados, mismo terreno al azar) en las que están los
## guaraníes, y mide por cada una:
##
## - el ganador con el criterio del torneo (edad × 1000 + población × 10 + bajas) y con el
##   puntaje del juego (Sim.score), y de qué está hecho cada uno;
## - el minuto de cada edad de los dos lados, y cuánto tardó la obra de cada hito (con cuántos
##   constructores);
## - aldeanos y ejército cada 5 minutos;
## - lo juntado por origen y por recurso (el libro `stats.origen`), con la riqueza aparte;
## - las bajas: quién (tipo de unidad) mató a qué (militar, aldeano, edificio, animal), y si la
##   víctima estaba en el monte; los golpes guaraníes con emboscada y el daño de más que dieron;
## - el sigilo: qué parte del tiempo el ejército guaraní estuvo oculto y sin detectar, y qué
##   parte el rival tuvo su ejército en el monte;
## - el primer golpe militar de cada lado a algo del rival (minuto de ataque).
##
## Al final, totales por rival, por terreno y por vía de victoria.
##
## Opciones:
##   --seeds=10        semillas por cruce (las del torneo: 10 da los 50 cruces del torneo 30)
##   --minutes=30
##   --rival=etiopia   solo ese cruce
##   --terreno=llano   fuerza el terreno (si no, el del torneo)
##   --parte=i/n       reparte las partidas entre procesos, como el torneo
##   --set=civ/ruta=valor;...   cambia los datos antes de jugar, sin tocar data/
##                     (ej.: --set="guaranies/modulos/sigilo/emboscada_pct=35")
##   --breve           una línea por partida
##
##   --sumar=a.txt,b.txt  junta los totales de varias partes
##
## Uso: godot --headless --path . -s tools/guarani_diag.gd -- --seeds=10 [--parte=0/3] [--set=...]

const G := "guaranies"
const P := 1000

var brief := false


func _init() -> void:
	var minutes := 30
	var seeds := 10
	var only := ""
	var terrain := ""
	var part := 0
	var parts := 1
	var sets := ""
	for a in OS.get_cmdline_user_args():
		var kv := a.trim_prefix("--").split("=", true, 1)
		match kv[0]:
			"minutes": minutes = int(kv[1])
			"seeds": seeds = int(kv[1])
			"rival": only = kv[1]
			"terreno": terrain = kv[1]
			"parte":
				part = int(kv[1].split("/")[0])
				parts = int(kv[1].split("/")[1])
			"set": sets = kv[1]
			"breve": brief = true
			"sumar":
				_merge(kv[1].split(","))
				quit()
				return
	var data := SimData.load_default()
	for s in sets.split(";", false):
		_apply(data, s)
	var civs: Array = []
	for k in data.civs:
		if not data.civs[k].civ.get("solo_ia", false):
			civs.append(k)
	civs.sort()
	var tot := {}
	for i in civs.size():
		for j in range(i + 1, civs.size()):
			if civs[i] != G and civs[j] != G:
				continue
			var rival: String = civs[j] if civs[i] == G else civs[i]
			if only != "" and rival != only:
				continue
			for sd in seeds:
				var game_i := (i * civs.size() + j) * seeds + sd
				if game_i % parts != part:
					continue
				var pair: Array = [civs[i], civs[j]] if sd % 2 == 0 else [civs[j], civs[i]]
				var sv := 1000 + i * 37 + j * 11 + sd
				var r := _play(data, pair, sv, minutes, terrain)
				_sum(tot, r)
	_totals(tot)
	print("TOT_JSON ", JSON.stringify(tot))
	quit()


## --sumar=a.txt,b.txt: junta los totales de varias partes (la línea TOT_JSON de cada salida).
func _merge(files: PackedStringArray) -> void:
	var tot := {}
	for f in files:
		var fa := FileAccess.open(f, FileAccess.READ)
		if fa == null:
			print("no se pudo abrir ", f)
			continue
		while not fa.eof_reached():
			var line := fa.get_line()
			if line.begins_with("TOT_JSON "):
				var d: Dictionary = JSON.parse_string(line.trim_prefix("TOT_JSON "))
				for k in d:
					_add(tot, k, int(d[k]))
	_totals(tot)


## "civ/a/b/c=valor": el valor se lee como JSON y los números pasan a enteros.
func _apply(data: SimData, spec: String) -> void:
	var kv := spec.split("=", true, 1)
	var path := kv[0].split("/")
	var d: Dictionary = data.civs[path[0]].civ
	for i in range(1, path.size() - 1):
		d = d[path[i]]
	d[path[path.size() - 1]] = _ints(JSON.parse_string(kv[1]))
	# Unidades y edificios se mezclan con la capa común al cargar: se vuelve a mezclar.
	data.civs[path[0]] = data._merge(data.civs[path[0]].civ)
	print("cambio: ", spec)


func _ints(v: Variant) -> Variant:
	if v is float:
		return int(v)
	if v is Array:
		return v.map(_ints)
	if v is Dictionary:
		var out := {}
		for k in v:
			out[k] = _ints(v[k])
		return out
	return v


func _in_forest(s: Sim, x: int, y: int) -> bool:
	var tx := x / P
	var ty := y / P
	for dy in [-1, 0, 1]:
		for dx in [-1, 0, 1]:
			var o: SimEntity = s.by_id.get(s.map.occupant(tx + dx, ty + dy))
			if o != null and o.is_resource() and o.res_kind == "madera":
				return true
	return false


func _kind(e_owner: int, e_cat: int, e_type: String, s: Sim) -> String:
	if e_owner < 0:
		return "animal"
	if e_cat == SimEntity.Cat.BUILDING:
		return "hito" if s.dp(e_owner).is_hito(e_type) else "edificio"
	var fn: String = s.data.unidades.get(e_type, {}).get("funcion", "")
	if e_type == "aldeano" or fn == "civil":
		return "aldeano"
	return "militar"


func _play(data: SimData, pair: Array, sv: int, minutes: int, terrain: String) -> Dictionary:
	var opts := {"civs": pair}
	if terrain != "":
		opts["terreno"] = terrain
	var s := Sim.new(sv, 2, data, opts)
	s.ais = [SimAI.new(s, 0), SimAI.new(s, 1)]
	var g := pair.find(G)
	var rv := 1 - g
	var rival: String = pair[rv]
	# Estado por partida.
	var ages := [[0, 0, 0, 0], [0, 0, 0, 0]] # tick en que llegó a la edad 1..4
	var placed := {} # id del hito -> tick
	var hito_obra := [[], []] # [edad destino, segundos de obra, constructores máx]
	var builders := {} # id del hito -> máximo de constructores a la vez
	var last_hit := {} # id de la víctima -> [dueño, tipo del atacante]
	var kills := [{}, {}] # por jugador: "tipo atacante>tipo víctima" -> n
	var kills_forest := [0, 0] # víctimas (unidades) en el monte
	var kills_units := [0, 0]
	var amb_hits := 0
	var amb_extra := 0
	var g_hits := 0
	var g_dmg := 0
	var first_atk := [-1, -1]
	var hidden_samples := 0
	var hidden_undet := 0
	var g_army_samples := 0
	var r_forest := 0
	var r_army_samples := 0
	var timeline := [[], []]
	var amb_ready := {}
	var trained := [{}, {}] # tipo -> entrenadas (sin aldeanos)
	while s.tick < minutes * 600 and not s.game_over:
		# Antes del paso: qué unidades guaraníes pegarían con emboscada (la condición de
		# SimMods.damage: sin combate en 5 s y ocultas ahora).
		amb_ready.clear()
		if s.tick % 2 == 0:
			for e in s.actives:
				if e.alive and e.owner == g and e.is_unit() and e.is_military() and e.cooldown <= 1:
					if e.last_combat < s.tick + 1 - 50 and s.mods.is_hidden_now(e):
						amb_ready[e.id] = true
		s.step()
		for ev in s.events:
			match ev["t"]:
				"trained":
					var tt := str(ev.get("type", ""))
					if tt != "aldeano":
						var tp := int(ev["player"])
						trained[tp][tt] = int(trained[tp].get(tt, 0)) + 1
				"age":
					ages[int(ev["player"])][int(ev["age"]) - 1] = s.tick
				"placed":
					var b: SimEntity = s.by_id.get(int(ev["id"]))
					if b != null and s.dp(b.owner).is_hito(b.type):
						placed[b.id] = s.tick
				"built":
					if placed.has(int(ev["id"])):
						var b: SimEntity = s.by_id.get(int(ev["id"]))
						var who := int(ev["player"])
						hito_obra[who].append([int(s.players[who]["age"]), (s.tick - int(placed[int(ev["id"])])) / 10, int(builders.get(int(ev["id"]), 0))])
				"hit":
					var a: SimEntity = s.by_id.get(int(ev["a"]))
					var t: SimEntity = s.by_id.get(int(ev["b"]))
					if a == null or t == null:
						continue
					last_hit[t.id] = [a.owner, a.type]
					if a.owner >= 0 and t.owner >= 0 and a.owner != t.owner and a.is_military() and first_atk[a.owner] < 0:
						first_atk[a.owner] = s.tick
					if a.owner == g and a.is_military() and t.owner >= 0:
						g_hits += 1
						g_dmg += int(ev["dmg"])
						if amb_ready.has(a.id):
							amb_hits += 1
							var pct := int(s.dp(g).mod("sigilo").get("emboscada_pct", 0))
							amb_extra += int(ev["dmg"]) - int(ev["dmg"]) * 100 / (100 + pct)
				"died":
					var by := int(ev["by"])
					if by < 0 or by == int(ev["owner"]):
						continue
					var lh: Array = last_hit.get(int(ev["id"]), [by, "?"])
					var vk := _kind(int(ev["owner"]), int(ev["cat"]), str(ev["type"]), s)
					var key := "%s>%s" % [lh[1], vk]
					kills[by][key] = int(kills[by].get(key, 0)) + 1
					if vk == "militar" or vk == "aldeano":
						kills_units[by] += 1
						if _in_forest(s, int(ev["x"]), int(ev["y"])):
							kills_forest[by] += 1
		# Constructores a la vez en cada hito en obra.
		if s.tick % 10 == 0:
			for id in placed:
				var b: SimEntity = s.by_id.get(id)
				if b != null and b.alive and not b.built:
					builders[id] = maxi(int(builders.get(id, 0)), b.workers_prev)
		# Sigilo: muestras cada 2 s.
		if s.tick % 20 == 0:
			for e in s.actives:
				if not e.alive or not e.is_unit() or not e.is_military() or e.inside >= 0:
					continue
				if e.owner == g:
					g_army_samples += 1
					if s.mods.is_hidden_now(e):
						hidden_samples += 1
						if not s.mods.detected_by(e, rv):
							hidden_undet += 1
				elif e.owner == rv:
					r_army_samples += 1
					if _in_forest(s, e.x, e.y):
						r_forest += 1
		if s.tick % 3000 == 0:
			for pid in 2:
				var vill := 0
				var mil := 0
				for e in s.actives:
					if e.alive and e.owner == pid and e.is_unit():
						if e.fn == "civil":
							vill += 1
						elif e.is_military():
							mil += 1
				timeline[pid].append([s.tick / 600, vill, mil])
	# Edificios de producción militar al final.
	var prods := [{}, {}]
	for e in s.actives:
		if e.alive and e.owner >= 0 and e.is_building() and e.built and not e.def.get("avanza_edad", false):
			for u in e.def.get("produce", []):
				if s.dp(e.owner).unidades.get(u, {}).get("funcion", "") in ["choque", "distancia", "linea", "asedio"]:
					prods[e.owner][e.type] = int(prods[e.owner].get(e.type, 0)) + 1
					break
	# Ganador.
	var how := "destrucción"
	var w := s.winner
	var crit := [0, 0]
	for pid in 2:
		var p: Dictionary = s.players[pid]
		crit[pid] = int(p["age"]) * 1000 + int(p["pop"]) * 10 + int(p["stats"]["bajas"])
	if w < 0:
		how = "puntos"
		w = 0 if crit[0] > crit[1] else 1
	var by_score := 0 if s.score(0) > s.score(1) else 1
	var r := {"rival": rival, "terreno": s.terrain, "gana": w == g, "como": how, "fin": s.tick,
		"edad_g": int(s.players[g]["age"]), "edad_r": int(s.players[rv]["age"]),
		"gana_por_puntaje_juego": by_score == g, "ages": ages, "g": g,
		"kills": kills, "kills_forest": kills_forest, "kills_units": kills_units,
		"amb_hits": amb_hits, "amb_extra": amb_extra, "g_hits": g_hits, "g_dmg": g_dmg,
		"hidden": hidden_samples, "hidden_undet": hidden_undet, "g_army": g_army_samples,
		"r_forest": r_forest, "r_army": r_army_samples, "first_atk": first_atk,
		"book": [s.players[0]["stats"].get("origen", {}), s.players[1]["stats"].get("origen", {})],
		"bajas": [int(s.players[0]["stats"]["bajas"]), int(s.players[1]["stats"]["bajas"])],
		"pop": [int(s.players[0]["pop"]), int(s.players[1]["pop"])], "crit": crit,
		"score": [s.score(0), s.score(1)], "trained": trained, "prods": prods, "hito_obra": hito_obra, "timeline": timeline}
	_print_game(s, pair, r)
	return r


func _t(tk: int) -> String:
	return "--:--" if tk <= 0 else "%d:%02d" % [tk / 600, (tk / 10) % 60]


func _book_line(book: Dictionary) -> String:
	var by_o := {}
	var tot := 0
	for o in book:
		var n := 0
		for k in book[o]:
			n += int(book[o][k])
		by_o[o] = n
		tot += n
	var keys := by_o.keys()
	keys.sort_custom(func(a, b) -> bool: return by_o[a] > by_o[b])
	var parts := []
	for k in keys:
		parts.append("%s %d" % [k, by_o[k]])
	return "%d (%s)" % [tot, ", ".join(parts)]


func _res_by_origin(book: Dictionary, res: String) -> String:
	var parts := []
	for o in book:
		var n := int(book[o].get(res, 0))
		if n != 0:
			parts.append("%s %d" % [o, n])
	return ", ".join(parts)


func _print_game(s: Sim, pair: Array, r: Dictionary) -> void:
	var g: int = r["g"]
	var rv := 1 - g
	print("%-12s vs %-12s %-15s %s  ganador %s (%s)  edades %d-%d  criterio %d-%d  puntaje %d-%d" % [
		pair[0], pair[1], r["terreno"], _t(r["fin"]), pair[g] if r["gana"] else pair[rv], r["como"],
		s.players[0]["age"], s.players[1]["age"], r["crit"][0], r["crit"][1], r["score"][0], r["score"][1]])
	if brief:
		return
	for pid in [g, rv]:
		var a: Array = r["ages"][pid]
		var tl := ""
		for x in r["timeline"][pid]:
			tl += " %d':%d/%d" % x
		print("  %-12s edades II %s III %s IV %s · primer ataque %s · bajas %d · pob %d · ald/ejército%s" % [
			pair[pid], _t(a[1]), _t(a[2]), _t(a[3]), _t(r["first_atk"][pid]), r["bajas"][pid], r["pop"][pid], tl])
		print("     juntado %s" % _book_line(r["book"][pid]))
		print("     entrenó %s · productores al final %s" % [str(r["trained"][pid]), str(r["prods"][pid])])
		print("     riqueza: %s" % _res_by_origin(r["book"][pid], "riqueza"))
		print("     alimento: %s" % _res_by_origin(r["book"][pid], "alimento"))
		var obra := ""
		for h in r["hito_obra"][pid]:
			obra += " ed%d %ds/%d" % h
		var kl: Dictionary = r["kills"][pid]
		var keys := kl.keys()
		keys.sort_custom(func(x, y) -> bool: return kl[x] > kl[y])
		var ks := []
		for k in keys.slice(0, 8):
			ks.append("%s %d" % [k, kl[k]])
		print("     hitos (edad, obra, constructores):%s · bajas: %s · unidades muertas en el monte %d/%d" % [obra, ", ".join(ks), r["kills_forest"][pid], r["kills_units"][pid]])
	print("  sigilo: ejército guaraní oculto %d %%, oculto y sin detectar %d %% · rival en el monte %d %% · emboscada %d de %d golpes (+%d de %d daño)" % [
		r["hidden"] * 100 / maxi(1, r["g_army"]), r["hidden_undet"] * 100 / maxi(1, r["g_army"]),
		r["r_forest"] * 100 / maxi(1, r["r_army"]), r["amb_hits"], r["g_hits"], r["amb_extra"], r["g_dmg"]])


func _add(d: Dictionary, k: String, n: int) -> void:
	d[k] = int(d.get(k, 0)) + n


func _sum(tot: Dictionary, r: Dictionary) -> void:
	var g: int = r["g"]
	var rv := 1 - g
	_add(tot, "partidas", 1)
	_add(tot, "gana", 1 if r["gana"] else 0)
	_add(tot, "gana_" + r["como"], 1 if r["gana"] else 0)
	_add(tot, "fin_" + r["como"], 1)
	if r["como"] == "puntos" and r["gana"]:
		_add(tot, "puntos_con_mas_edad", 1 if r["edad_g"] > r["edad_r"] else 0)
		_add(tot, "puntos_misma_edad", 1 if r["edad_g"] == r["edad_r"] else 0)
	if r["como"] == "puntos":
		_add(tot, "puntos_y_puntaje_juego", 1 if r["gana"] == r["gana_por_puntaje_juego"] else 0)
	for side in [["g", g], ["r", rv]]:
		var a: Array = r["ages"][side[1]]
		for k in range(1, 4):
			if a[k] > 0:
				_add(tot, "%s_edad%d_n" % [side[0], k + 1], 1)
				_add(tot, "%s_edad%d_t" % [side[0], k + 1], a[k])
		_add(tot, "%s_bajas" % side[0], r["bajas"][side[1]])
		for k in r["kills"][side[1]]:
			_add(tot, "%s_k_%s" % [side[0], k], r["kills"][side[1]][k])
		var book: Dictionary = r["book"][side[1]]
		for o in book:
			for res in book[o]:
				_add(tot, "%s_lib_%s_%s" % [side[0], o, res], int(book[o][res]))
		if r["first_atk"][side[1]] > 0:
			_add(tot, "%s_ataque_n" % side[0], 1)
			_add(tot, "%s_ataque_t" % side[0], r["first_atk"][side[1]])
		for x in r["timeline"][side[1]]:
			_add(tot, "%s_ald_%d" % [side[0], x[0]], x[1])
			_add(tot, "%s_mil_%d" % [side[0], x[0]], x[2])
			_add(tot, "%s_tl_n_%d" % [side[0], x[0]], 1)
		for h in r["hito_obra"][side[1]]:
			_add(tot, "%s_obra_%d_s" % [side[0], h[0]], h[1])
			_add(tot, "%s_obra_%d_c" % [side[0], h[0]], h[2])
			_add(tot, "%s_obra_%d_n" % [side[0], h[0]], 1)
		for k in r["trained"][side[1]]:
			_add(tot, "%s_tr_%s" % [side[0], k], r["trained"][side[1]][k])
		for k in r["prods"][side[1]]:
			_add(tot, "%s_pr_%s" % [side[0], k], r["prods"][side[1]][k])
		_add(tot, "%s_kforest" % side[0], r["kills_forest"][side[1]])
		_add(tot, "%s_kunits" % side[0], r["kills_units"][side[1]])
	for k in ["amb_hits", "amb_extra", "g_hits", "g_dmg", "hidden", "hidden_undet", "g_army", "r_forest", "r_army"]:
		_add(tot, k, r[k])
	_add(tot, "riv_n_" + r["rival"], 1)
	_add(tot, "riv_w_" + r["rival"], 1 if r["gana"] else 0)
	_add(tot, "ter_n_" + r["terreno"], 1)
	_add(tot, "ter_w_" + r["terreno"], 1 if r["gana"] else 0)
	_add(tot, "edadfin_g_%d" % r["edad_g"], 1)
	_add(tot, "edadfin_r_%d" % r["edad_r"], 1)


func _totals(t: Dictionary) -> void:
	var n := int(t.get("partidas", 0))
	if n == 0:
		return
	print("\n==== TOTALES (%d partidas) ====" % n)
	print("Guaraníes ganan %d (%d %%): por destrucción %d, por puntos %d (con más edad %d, misma edad %d)" % [
		t.get("gana", 0), int(t.get("gana", 0)) * 100 / n, t.get("gana_destrucción", 0), t.get("gana_puntos", 0), t.get("puntos_con_mas_edad", 0), t.get("puntos_misma_edad", 0)])
	print("Partidas por puntos: %d; el puntaje del juego (Sim.score) da el mismo ganador en %d" % [t.get("fin_puntos", 0), t.get("puntos_y_puntaje_juego", 0)])
	print("Edad al final: guaraníes %s · rivales %s" % [_hist(t, "edadfin_g_"), _hist(t, "edadfin_r_")])
	var keys := t.keys()
	keys.sort()
	var line := "Por rival:"
	for k in keys:
		if k.begins_with("riv_n_"):
			var c: String = k.trim_prefix("riv_n_")
			line += " %s %d/%d" % [c, t.get("riv_w_" + c, 0), t[k]]
	print(line)
	line = "Por terreno:"
	for k in keys:
		if k.begins_with("ter_n_"):
			var c: String = k.trim_prefix("ter_n_")
			line += " %s %d/%d" % [c, t.get("ter_w_" + c, 0), t[k]]
	print(line)
	for side in [["g", "Guaraníes"], ["r", "Rivales  "]]:
		var s: String = side[0]
		var ag := ""
		for k in range(2, 5):
			var m := int(t.get("%s_edad%d_n" % [s, k], 0))
			ag += " %s %s (%d de %d)" % [["", "", "II", "III", "IV"][k], _t(int(t.get("%s_edad%d_t" % [s, k], 0)) / maxi(1, m)), m, n]
		print("%s edades promedio:%s · primer ataque %s (%d) · bajas %d" % [side[1], ag, _t(int(t.get(s + "_ataque_t", 0)) / maxi(1, int(t.get(s + "_ataque_n", 0)))), t.get(s + "_ataque_n", 0), t.get(s + "_bajas", 0)])
		var tl := ""
		for mnt in [5, 10, 15, 20, 25, 30]:
			var c := int(t.get("%s_tl_n_%d" % [s, mnt], 0))
			if c > 0:
				tl += " %d':%d/%d" % [mnt, int(t.get("%s_ald_%d" % [s, mnt], 0)) / c, int(t.get("%s_mil_%d" % [s, mnt], 0)) / c]
		print("   aldeanos/ejército promedio:%s" % tl)
		var ob := ""
		for e in range(2, 5):
			var c := int(t.get("%s_obra_%d_n" % [s, e], 0))
			if c > 0:
				ob += " ed%d %ds con %d constructores (%d)" % [e, int(t.get("%s_obra_%d_s" % [s, e], 0)) / c, int(t.get("%s_obra_%d_c" % [s, e], 0)) / c, c]
		print("   obra de los hitos, promedio:%s" % ob)
		# Libro: por origen y recurso, promedio por partida.
		var lib := {}
		var by_res := {}
		for k in keys:
			if k.begins_with(s + "_lib_"):
				var parts: PackedStringArray = k.trim_prefix(s + "_lib_").rsplit("_", true, 1)
				_add(lib, parts[0], int(t[k]))
				_add(by_res, parts[1], int(t[k]))
		var ls := []
		var lk := lib.keys()
		lk.sort_custom(func(a, b) -> bool: return lib[a] > lib[b])
		var total := 0
		for k in lk:
			ls.append("%s %d" % [k, int(lib[k]) / n])
			total += int(lib[k])
		print("   juntado promedio %d: %s" % [total / n, ", ".join(ls)])
		var rs := []
		for k in ["alimento", "madera", "piedra", "riqueza", "fama"]:
			if by_res.has(k):
				rs.append("%s %d" % [k, int(by_res[k]) / n])
		print("   por recurso: %s" % ", ".join(rs))
		var rq := []
		for k in keys:
			if k.begins_with(s + "_lib_") and k.ends_with("_riqueza"):
				rq.append("%s %d" % [k.trim_prefix(s + "_lib_").trim_suffix("_riqueza"), int(t[k]) / n])
		print("   riqueza por origen: %s" % ", ".join(rq))
		var kl := {}
		for k in keys:
			if k.begins_with(s + "_k_"):
				kl[k.trim_prefix(s + "_k_")] = t[k]
		var kk := kl.keys()
		kk.sort_custom(func(a, b) -> bool: return kl[a] > kl[b])
		var ks := []
		for k in kk.slice(0, 12):
			ks.append("%s %d" % [k, kl[k]])
		print("   bajas por tipo (atacante>víctima): %s" % ", ".join(ks))
		var tr := []
		var pr := []
		for k in keys:
			if k.begins_with(s + "_tr_"):
				tr.append("%s %d" % [k.trim_prefix(s + "_tr_"), int(t[k]) / n])
			elif k.begins_with(s + "_pr_"):
				pr.append("%s %d" % [k.trim_prefix(s + "_pr_"), int(t[k]) * 10 / n])
		print("   entrenadas por partida: %s · productores al final (x10, promedio): %s" % [", ".join(tr), ", ".join(pr)])
		print("   unidades que mató en el monte: %d de %d" % [t.get(s + "_kforest", 0), t.get(s + "_kunits", 0)])
	print("Sigilo: ejército guaraní oculto %d %% del tiempo, oculto y sin detectar %d %% · ejército rival en el monte %d %%" % [
		int(t.get("hidden", 0)) * 100 / maxi(1, int(t.get("g_army", 0))), int(t.get("hidden_undet", 0)) * 100 / maxi(1, int(t.get("g_army", 0))), int(t.get("r_forest", 0)) * 100 / maxi(1, int(t.get("r_army", 0)))])
	print("Emboscada: %d de %d golpes guaraníes a algo del rival (%d %%), %d de daño de más sobre %d (%d %%)" % [
		t.get("amb_hits", 0), t.get("g_hits", 0), int(t.get("amb_hits", 0)) * 100 / maxi(1, int(t.get("g_hits", 0))), t.get("amb_extra", 0), t.get("g_dmg", 0), int(t.get("amb_extra", 0)) * 100 / maxi(1, int(t.get("g_dmg", 0)))])


func _hist(t: Dictionary, pre: String) -> String:
	var out := []
	for k in range(1, 5):
		if t.has(pre + str(k)):
			out.append("%s %d" % [["", "I", "II", "III", "IV"][k], t[pre + str(k)]])
	return ", ".join(out)
