extends SceneTree
## Qué cuesta qué (proceso/26, 09): partidas IA contra IA; por jugador y por minuto, el banco sin
## gastar de cada recurso, lo gastado por destino (aldeanos, tropa, edificios, hitos, economía,
## herrería, niveles, otras investigaciones, mercado) y lo juntado por origen (libro de la
## simulación: casa, disputado, propio, sitios, mercado…). No toca la simulación: mira las colas
## (lo que se paga al encolar), los edificios nuevos y los precios del mercado. Lo que no se ve
## así (acogida con fama, tributo, cancelaciones) queda en «otros», por diferencia con el libro.
## Imprime una línea «JSON {...}» por jugador y partida; la resume tools/bancos_resumen.py.
##
## Uso:
##   godot --headless --path . -s tools/bancos.gd -- --minutes=25 --seeds=1 --dificultad=experta --parte=0/3

const RES := ["alimento", "madera", "riqueza", "piedra"]
const CATS := ["aldeanos", "tropa", "edificios", "hitos", "economia", "herreria", "niveles", "otras_tec", "mercado"]


func _init() -> void:
	var minutes := 25
	var seeds := 1
	var diffs: Array = ["experta"]
	var part := 0
	var parts := 1
	for a in OS.get_cmdline_user_args():
		var kv := a.trim_prefix("--").split("=")
		match kv[0]:
			"minutes":
				minutes = int(kv[1])
			"seeds":
				seeds = int(kv[1])
			"dificultad":
				diffs = Array(kv[1].split(","))
			"parte":
				part = int(kv[1].split("/")[0])
				parts = int(kv[1].split("/")[1])
	var data := SimData.load_default()
	var civs: Array = []
	for k in data.civs:
		if not data.civs[k].civ.get("solo_ia", false):
			civs.append(k)
	civs.sort()
	var game_i := 0
	for diff: String in diffs:
		for sd in seeds:
			for i in civs.size():
				game_i += 1
				if (game_i - 1) % parts != part:
					continue
				var pair: Array = [civs[i], civs[(i + 1 + sd) % civs.size()]]
				_play(pair, 2000 + i * 13 + sd * 7, diff, minutes, sd)
	quit()


func _play(pair: Array, seed_value: int, diff: String, minutes: int, sd: int) -> void:
	var s := Sim.new(seed_value, 2, null, {"civs": pair})
	s.ais = [SimAI.new(s, 0, diff), SimAI.new(s, 1, diff)]
	var start: Array = [(s.players[0]["res"] as Dictionary).duplicate(), (s.players[1]["res"] as Dictionary).duplicate()]
	var spent: Array = [{}, {}] # cat -> res -> n
	var log: Array = [[], []]
	var ages: Array = [{}, {}]
	var seen_q := {} # id de edificio -> Array de dicts pagados (por identidad)
	var last_id := s.next_id - 1
	var prices: Array = [(s.players[0].get("precios", {}) as Dictionary).duplicate(), (s.players[1].get("precios", {}) as Dictionary).duplicate()]
	while s.tick < minutes * 600 and not s.game_over:
		var age_before: Array = [int(s.players[0]["age"]), int(s.players[1]["age"])]
		s.step()
		for ev in s.events:
			if ev["t"] == "age":
				ages[ev["player"]][str(ev["age"])] = s.tick
		# Edificios nuevos (cimientos, rozas que se reabren, tramos de muro).
		for id in range(last_id + 1, s.next_id):
			var e: SimEntity = s.by_id.get(id)
			if e == null or not e.is_building() or e.owner < 0 or e.owner > 1:
				continue
			var cost: Dictionary = s.dp(e.owner).cost_of(e.type, age_before[e.owner])
			_add(spent[e.owner], "hitos" if s.dp(e.owner).is_hito(e.type) else "edificios", cost)
		last_id = s.next_id - 1
		# Colas: lo que se paga al encolar (unidades e investigaciones).
		for e in s.actives:
			if not e.alive or not e.is_building() or e.owner < 0 or e.owner > 1:
				continue
			if e.queue_paid.is_empty() and not seen_q.has(e.id):
				continue
			var prev: Array = seen_q.get(e.id, [])
			for qi in e.queue_paid.size():
				var paid: Dictionary = e.queue_paid[qi]
				var known := false
				for o in prev:
					if is_same(o, paid):
						known = true
						break
				if not known and qi < e.queue.size():
					_add(spent[e.owner], _cat(s, e.owner, e.queue[qi]), paid)
			seen_q[e.id] = e.queue_paid.duplicate()
		# Mercado, por el libro (el precio vuelve solo al inicial y no sirve para contar): cada
		# compra suma un lote a «mercado:<recurso>» y se paga en riqueza el precio de antes
		# (el de ahora menos el paso); cada venta suma riqueza y se paga un lote del recurso cuyo
		# precio, menos la comisión, da lo cobrado.
		var cfg: Dictionary = s.data.reglas["mercado"]
		for pid in 2:
			var book: Dictionary = s.players[pid]["stats"].get("origen", {}).get("mercado", {})
			var pr: Dictionary = s.players[pid].get("precios", {})
			for k in ["alimento", "madera", "piedra"]:
				var buys := (int(book.get(k, 0)) - int(prices[pid].get("lib:" + k, 0))) / int(cfg["lote"])
				for _i in buys:
					_add(spent[pid], "mercado", {"riqueza": maxi(int(cfg["minimo"]), int(pr.get(k, cfg["precio_inicial"])) - int(cfg["paso"]) * (buys - _i))})
			var got := int(book.get("riqueza", 0)) - int(prices[pid].get("lib:riqueza", 0))
			if got > 0:
				var best := "alimento"
				var gap := 1 << 30
				for k in ["alimento", "madera", "piedra"]:
					var d := absi((int(pr.get(k, cfg["precio_inicial"])) + int(cfg["paso"])) * (100 - int(cfg["comision_pct"])) / 100 - got)
					if d < gap:
						gap = d
						best = k
				_add(spent[pid], "mercado", {best: int(cfg["lote"])})
			for k in book:
				prices[pid]["lib:" + k] = int(book[k])
		if s.tick % 600 == 0:
			for pid in 2:
				log[pid].append(_snap(s, pid, start[pid], spent[pid]))
	for pid in 2:
		var out := {"civ": pair[pid], "rival": pair[1 - pid], "semilla": sd, "dificultad": diff, "edades": ages[pid], "ganador": s.winner, "fin_min": s.tick / 600, "min": log[pid]}
		print("JSON ", JSON.stringify(out))


func _cat(s: Sim, pid: int, item: String) -> String:
	if item.begins_with("@"):
		var k := item.substr(1)
		var t: Dictionary = s.dp(pid).tecnologias.get(k, {})
		if k.begins_with("ataque_") or k.begins_with("armadura_"):
			return "herreria"
		if k.begins_with("veterano_") or k.begins_with("elite_"):
			return "niveles"
		for ef in t.get("efectos", []):
			if ef.get("tipo", "") in ["tasa", "carga", "motor_pct"]:
				return "economia"
		return "otras_tec"
	var u: Dictionary = s.dp(pid).unidades.get(item, {})
	return "aldeanos" if u.get("funcion", "") == "civil" else "tropa"


func _add(book: Dictionary, cat: String, cost: Dictionary) -> void:
	var row: Dictionary = book.get_or_add(cat, {})
	for k in cost:
		row[k] = int(row.get(k, 0)) + int(cost[k])


func _snap(s: Sim, pid: int, start: Dictionary, spent: Dictionary) -> Dictionary:
	var p: Dictionary = s.players[pid]
	var book: Dictionary = p["stats"].get("origen", {})
	var bank := {}
	var got := {}
	for r in RES:
		bank[r] = int(p["res"].get(r, 0))
	for o in book:
		for r in book[o]:
			if r in RES:
				got[o + ":" + r] = int(book[o][r])
	var vill := 0
	var mil := 0
	for e in s.actives:
		if e.alive and e.owner == pid and e.is_unit():
			if e.fn == "civil":
				vill += 1
			elif e.is_military():
				mil += 1
	return {"t": s.tick / 600, "edad": int(p["age"]), "banco": bank, "inicial": start, "gastado": spent.duplicate(true), "origen": got, "aldeanos": vill, "tropa": mil}
