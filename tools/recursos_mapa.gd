extends SceneTree
## Recursos del mapa por jugador (proceso/32-ronda-8/02): para cada terreno, cantidad de
## jugadores y tamaño, cuánto hay de madera, alimento (arbustos, caza, rebaño), piedra y
## riqueza, y a qué distancia de la base más cercana: cerca (hasta `--cerca` casillas),
## media (hasta `--media`) y lejos o disputado (el resto). También casillas por jugador
## (todas y las que se caminan). Promedia `--seeds` semillas.
##   godot --headless --path . -s tools/recursos_mapa.gd -- [--terrenos=llano,rio] [--jug=2,4,8]
##        [--tam=chico,normal,grande] [--seeds=1,2] [--resumen=1]
## --resumen=1: una línea por (jugadores, tamaño) con el promedio de todos los terrenos.

const KINDS := ["madera", "alimento", "piedra", "riqueza"]
const BANDS := ["cerca", "media", "lejos"]


func _init() -> void:
	var terrs: Array = []
	var jugs: Array = [2, 4, 8]
	var tams: Array = ["chico", "normal", "grande"]
	var seeds: Array = [1, 2]
	var cerca := 20
	var media := 40
	var resumen := false
	for a in OS.get_cmdline_user_args():
		var kv := a.trim_prefix("--").split("=")
		if kv.size() < 2:
			continue
		match kv[0]:
			"terrenos": terrs = Array(kv[1].split(","))
			"jug": jugs = Array(kv[1].split(",")).map(func(x: String) -> int: return int(x))
			"tam": tams = Array(kv[1].split(","))
			"seeds": seeds = Array(kv[1].split(",")).map(func(x: String) -> int: return int(x))
			"cerca": cerca = int(kv[1])
			"media": media = int(kv[1])
			"resumen": resumen = kv[1] == "1"
	var data := SimData.load_default()
	if terrs.is_empty():
		terrs = data.reglas["terrenos"].keys()
	print("Por jugador. cerca <= %d casillas de la base, media <= %d, lejos el resto. c/m/l en cientos. Alimento: arbustos/caza(venado, sueltos)/rebaño propio." % [cerca, media])
	print("%-16s %2s %-6s %4s %6s %5s | %-20s | %-20s | %-17s | %-17s | %s" % ["terreno", "j", "tam", "lado", "cas/j", "camin", "madera c/m/l", "alimento c/m/l", "piedra c/m/l", "riqueza c/m/l", "arb/caza/reb"])
	for np in jugs:
		for tam in tams:
			if np == 2 and tam != tams[0] and not _tam_en_1v1(data):
				continue # el 1 contra 1 no cambia de tamaño
			var acc := {}
			for terr in terrs:
				var row := {}
				for sd in seeds:
					var m := _measure(int(sd), np, terr, tam, cerca, media)
					for k in m:
						row[k] = int(row.get(k, 0)) + int(m[k])
				for k in row:
					row[k] = int(row[k]) / seeds.size()
					acc[k] = int(acc.get(k, 0)) + int(row[k])
				if not resumen:
					print(_line(terr, np, tam, row))
			if resumen:
				for k in acc:
					acc[k] = int(acc[k]) / terrs.size()
				print(_line("PROMEDIO", np, tam, acc))
	quit()


func _tam_en_1v1(data: SimData) -> bool:
	return bool(data.reglas["opciones_partida"].get("tamano_en_1v1", false))


func _line(name: String, np: int, tam: String, r: Dictionary) -> String:
	var parts: Array = []
	for k in KINDS:
		var t := 0
		for b in BANDS:
			t += int(r.get(k + "_" + b, 0))
		parts.append("%5d %4d/%4d/%4d" % [t / 100 * 100, int(r.get(k + "_cerca", 0)) / 100, int(r.get(k + "_media", 0)) / 100, int(r.get(k + "_lejos", 0)) / 100])
	return "%-16s %2d %-6s %4d %6d %4d%% | %s | %s | %s | %s | %d/%d/%d" % [name, np, tam, r.get("lado", 0), r.get("casillas", 0), r.get("caminables_pct", 0), parts[0], parts[1], parts[2], parts[3], int(r.get("arbustos", 0)), int(r.get("caza", 0)), int(r.get("rebano", 0))]


## Cantidades por jugador (enteros); las bandas en unidades de recurso.
func _measure(sd: int, np: int, terr: String, tam: String, cerca: int, media: int) -> Dictionary:
	var civs: Array = []
	for i in np:
		civs.append("mapuches")
	var s := Sim.new(sd, np, null, {"terreno": terr, "tamano": tam, "civs": civs})
	var out := {}
	var n := s.map.n
	out["lado"] = n
	out["casillas"] = n * n / np
	var walk := 0
	for ty in n:
		for tx in n:
			if not s.map.is_rock(tx, ty) and s.map.water[ty * n + tx] != 1:
				walk += 1
	out["caminables_pct"] = walk * 100 / (n * n)
	for e in s.entities:
		if not e.alive:
			continue
		var amount := 0
		var kind := ""
		if e.is_resource():
			kind = e.res_kind
			amount = e.amount
			if e.type == "arbusto":
				out["arbustos"] = int(out.get("arbustos", 0)) + amount
			elif kind == "alimento":
				out["caza"] = int(out.get("caza", 0)) + amount
		elif e.type == "rebano":
			kind = "alimento"
			amount = int(e.def.get("carne", 0))
			out["rebano"] = int(out.get("rebano", 0)) + amount
		if kind == "" or not kind in KINDS:
			continue
		var tx := e.x / Sim.P
		var ty := e.y / Sim.P
		var bd := 1 << 30
		for b in s.bases:
			var c: Vector2i = b + Vector2i(2, 2)
			bd = mini(bd, (tx - c.x) * (tx - c.x) + (ty - c.y) * (ty - c.y))
		var band := "lejos"
		if bd <= cerca * cerca:
			band = "cerca"
		elif bd <= media * media:
			band = "media"
		out[kind + "_" + band] = int(out.get(kind + "_" + band, 0)) + amount
	for k in out.keys():
		if k != "lado" and k != "casillas" and k != "caminables_pct":
			out[k] = int(out[k]) / np
	s.soltar()
	return out
