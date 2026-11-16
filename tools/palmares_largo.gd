extends SceneTree
## Por qué Palmares junta tanto en partidas largas de varios (proceso/24, 5c).
##
## --caso=ffa6   todos contra todos con las 6 civs (por defecto 60 minutos)
## --caso=3v3    3v3 con Palmares en el equipo 0
## --caso=2v2    2v2: palmares+mapuches contra ayutthaya+tawantinsuyu
## --caso=duelo  Palmares contra cada civ, 1 contra 1 de `--minutes` (30), `--seeds` por cruce,
##               alternando lados. Gana quien destruye; si no, el criterio del torneo
##               (edad, población, bajas).
##
## Cada `--cada` minutos (10) imprime, por jugador: población, aldeanos, edad, puntaje y lo
## juntado por origen (`players[pid].stats.origen`, todos los recursos sumados). Para
## Palmares, además: fama ganada por origen, gastada en acogida y en hitos, y tirada por el
## tope; gente acogida y liberada; riqueza de los oficios; minutos en el techo de población.
##
## --set=civ/ruta/a/la/clave=valor (separados por ;) cambia los datos de una civ antes de
## jugar, sin tocar data/. Ej.: --set="palmares/modulos/acogida/costo=40"
##
## Uso: godot --headless --path . -s tools/palmares_largo.gd -- --caso=ffa6 --minutes=60 [--seeds=61] [--terreno=llano] [--set=...] [--tiempo=45]

const CIVS := ["tawantinsuyu", "mapuches", "guaranies", "etiopia", "palmares", "ayutthaya"]


func _init() -> void:
	var caso := "ffa6"
	var minutes := -1
	var seeds: Array = []
	var nseeds := 2
	var terrain := "llano"
	var every := 10
	var sets := ""
	var limit := 0
	for a in OS.get_cmdline_user_args():
		var kv := a.trim_prefix("--").split("=", true, 1)
		match kv[0]:
			"caso": caso = kv[1]
			"minutes": minutes = int(kv[1])
			"seeds":
				for x in kv[1].split(","):
					seeds.append(int(x))
			"n": nseeds = int(kv[1])
			"terreno": terrain = kv[1]
			"cada": every = int(kv[1])
			"set": sets = kv[1]
			"tiempo": limit = int(kv[1])
	if minutes < 0:
		minutes = 30 if caso == "duelo" else 60
	var data := SimData.load_default()
	for s in sets.split(";", false):
		_apply(data, s)
	if caso == "duelo":
		_duels(data, minutes, nseeds, terrain)
		quit()
		return
	if seeds.is_empty():
		seeds = [61]
	var civs: Array = CIVS
	var teams: Array = [0, 1, 2, 3, 4, 5]
	if caso == "3v3":
		civs = ["palmares", "tawantinsuyu", "mapuches", "guaranies", "etiopia", "ayutthaya"]
		teams = [0, 1, 0, 1, 0, 1]
	elif caso == "2v2":
		civs = ["palmares", "ayutthaya", "mapuches", "tawantinsuyu"]
		teams = [0, 1, 0, 1]
	for sv in seeds:
		_long(data, civs, teams, int(sv), minutes, every, terrain, limit, caso)
	quit()


## "civ/a/b/c=valor": el valor se lee como JSON y los números pasan a enteros.
func _apply(data: SimData, spec: String) -> void:
	var kv := spec.split("=", true, 1)
	var path := kv[0].split("/")
	var civ: SimData = data.civs[path[0]]
	var d: Dictionary = civ.civ
	for i in range(1, path.size() - 1):
		d = d[path[i]]
	d[path[path.size() - 1]] = _ints(JSON.parse_string(kv[1]))
	print("cambio: ", spec)


func _ints(v: Variant) -> Variant:
	if v is float:
		return int(v)
	if v is Array:
		var out := []
		for x in v:
			out.append(_ints(x))
		return out
	if v is Dictionary:
		var out := {}
		for k in v:
			out[k] = _ints(v[k])
		return out
	return v


func _long(data: SimData, civs: Array, teams: Array, sv: int, minutes: int, every: int, terrain: String, limit: int, caso: String) -> void:
	var np := civs.size()
	var opts := {"civs": civs, "equipos": teams, "terreno": terrain, "ubicacion_equipos": "juntos"}
	if limit > 0:
		opts["tiempo_limite_min"] = limit
	var s := Sim.new(sv, np, data, opts)
	s.ais = []
	for pid in np:
		s.ais.append(SimAI.new(s, pid))
	print("== %s semilla %d terreno %s, %d minutos ==" % [caso, sv, terrain, minutes])
	var welcomed := {}
	var freed := {}
	var capped := {}
	while s.tick < minutes * 600 and not s.game_over:
		s.step()
		for ev in s.events:
			if ev["t"] == "trained" and ev.get("type", "") == "aldeano" and s.players[int(ev["player"])]["civ"] == "palmares":
				welcomed[int(ev["player"])] = int(welcomed.get(int(ev["player"]), 0)) + 1
			elif ev["t"] == "freed":
				freed[int(ev["player"])] = int(freed.get(int(ev["player"]), 0)) + 1
		if s.tick % 10 == 0:
			for p in s.players:
				if not p["defeated"] and int(p["pop"]) >= int(p["pop_cap"]):
					capped[p["id"]] = int(capped.get(p["id"], 0)) + 1
		if s.tick % (every * 600) == 0:
			_report(s, civs, welcomed, freed, capped)
	if s.tick % (every * 600) != 0:
		_report(s, civs, welcomed, freed, capped)
	if s.game_over:
		print("terminó a los %d:%02d, ganó el equipo %d" % [s.tick / 600, (s.tick / 10) % 60, s.winner_team])


func _report(s: Sim, civs: Array, welcomed: Dictionary, freed: Dictionary, capped: Dictionary) -> void:
	print("-- minuto %d --" % (s.tick / 600))
	for pid in civs.size():
		var p: Dictionary = s.players[pid]
		var book: Dictionary = p["stats"].get("origen", {})
		var tot := 0
		var parts := ""
		for o in book:
			var sub := 0
			for k in book[o]:
				sub += int(book[o][k])
			tot += sub
			parts += " %s %d" % [o, sub]
		var vill := 0
		var mil := 0
		for e in s.actives:
			if e.alive and e.owner == pid and e.is_unit():
				if e.fn == "civil":
					vill += 1
				elif e.is_military():
					mil += 1
		print("j%d %-12s %s edad %d pob %3d/%3d ald %3d mil %3d  puntaje %5d  juntado %6d |%s" % [pid, civs[pid], "caído " if p["defeated"] else "", p["age"], p["pop"], p["pop_cap"], vill, mil, s.score(pid), tot, parts])
		if civs[pid] == "palmares":
			var fame_in := 0
			var fame_by := ""
			for o in book:
				var f := int(book[o].get("fama", 0))
				if f > 0:
					fame_in += f
					fame_by += " %s %d" % [o, f]
			var cost := int(s.data.civs["palmares"].mod("acogida")["costo"])
			var start := int(s.data.civs["palmares"].mod("recurso_propio").get("inicial", 0))
			var w := int(welcomed.get(pid, 0))
			var hitos := 0
			for e in s.actives:
				if e.alive and e.owner == pid and e.is_building() and e.def.has("costo_extra"):
					hitos += int(e.def["costo_extra"].get("fama", 0))
			var now := int(p["res"].get("fama", 0))
			var crafts := 0
			var b := {}
			for e in s.actives:
				if e.alive and e.owner == pid and e.is_building():
					crafts += e.crafts.size()
					if e.built and e.type in ["centro", "mocambo", "casa"]:
						b[e.type] = int(b.get(e.type, 0)) + 1
			var sin_fama := tot - fame_in
			print("   fama ganada %d (%s) · acogida %d personas = %d · hitos %d · ahora %d · tirada por el tope %d" % [fame_in, fame_by.strip_edges(), w, w * cost, hitos, now, start + fame_in - w * cost - hitos - now])
			print("   liberados %d · oficios %d puestos, riqueza propia %d · edificios %s · juntado sin fama %d · %d s en el techo de población" % [int(freed.get(pid, 0)), crafts, int(book.get("propio", {}).get("riqueza", 0)), str(b), sin_fama, int(capped.get(pid, 0))])


func _duels(data: SimData, minutes: int, nseeds: int, terrain: String) -> void:
	var won := 0
	var total := 0
	for rival in CIVS:
		if rival == "palmares":
			continue
		var w_r := 0
		for sd in nseeds:
			var pair: Array = ["palmares", rival] if sd % 2 == 0 else [rival, "palmares"]
			var sv := 5000 + CIVS.find(rival) * 37 + sd
			var s := Sim.new(sv, 2, data, {"civs": pair, "terreno": terrain} if terrain != "azar" else {"civs": pair})
			s.ais = [SimAI.new(s, 0), SimAI.new(s, 1)]
			while s.tick < minutes * 600 and not s.game_over:
				s.step()
			var w := -1
			var how := "destrucción"
			if s.winner >= 0:
				w = s.winner
			else:
				how = "puntos"
				var sc := []
				for pid in 2:
					var p: Dictionary = s.players[pid]
					sc.append(int(p["age"]) * 1000 + int(p["pop"]) * 10 + int(p["stats"]["bajas"]))
				w = 0 if sc[0] > sc[1] else 1
			var pal := pair.find("palmares")
			var tot := [0, 0]
			for pid in 2:
				var book: Dictionary = s.players[pid]["stats"].get("origen", {})
				for o in book:
					for k in book[o]:
						tot[pid] += int(book[o][k])
			if w == pal:
				w_r += 1
			var vills := [0, 0]
			for e in s.actives:
				if e.alive and e.owner >= 0 and e.is_unit() and e.fn == "civil":
					vills[e.owner] += 1
			print("%-12s vs %-12s %5s ganador %s (%s)  juntado %d-%d  aldeanos %d-%d  edades %d-%d" % [pair[0], pair[1], "%d:%02d" % [s.tick / 600, (s.tick / 10) % 60], pair[w], how, tot[0], tot[1], vills[0], vills[1], s.players[0]["age"], s.players[1]["age"]])
		print("  Palmares contra %s: %d / %d" % [rival, w_r, nseeds])
		won += w_r
		total += nseeds
	print("PALMARES EN 1 CONTRA 1: %d / %d (%d %%)" % [won, total, won * 100 / maxi(1, total)])
