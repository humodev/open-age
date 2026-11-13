class_name SimAI
extends RefCounted
## IA de escaramuza (docs/08-ia-rival.md). Emite comandos como un jugador; corre dentro de la simulación.

const P := 1000
const O := SimEntity.Order

var sim: Sim
var player: int
var wave := 0
var last_attack := -100000
var rally := Vector2i(-1, -1)
var calm_since := 0
var personality := "normal" # pasiva, normal, agresiva (campañas)
var level: Dictionary = {} # dificultad (reglas.json → dificultades)

# Perfil equilibrado de H1. En H2 pasa a data/ia/ (docs/08).
var ratio_early := {"alimento": 52, "madera": 33, "riqueza": 10, "piedra": 5}
var ratio_late := {"alimento": 42, "madera": 25, "riqueza": 23, "piedra": 10}
var max_villagers := 42


func _init(s: Sim, pid: int, difficulty: String = "normal") -> void:
	sim = s
	player = pid
	set_difficulty(difficulty)


func set_difficulty(key: String) -> void:
	level = sim.data.reglas["dificultades"].get(key, sim.data.reglas["dificultades"]["normal"])
	max_villagers = level["max_aldeanos"]


func thinks_now() -> bool:
	return (sim.tick + player * 5) % int(level["piensa_cada_ticks"]) == 0


func think() -> void:
	var p: Dictionary = sim.players[player]
	var vill: Array[SimEntity] = []
	var army: Array[SimEntity] = []
	var by_type := {}
	var centro: SimEntity = null
	for e in sim.actives:
		if not e.alive or e.owner != player:
			continue
		if e.is_unit():
			if e.inside >= 0:
				continue
			if e.fn == "civil":
				vill.append(e)
			elif e.is_military():
				army.append(e)
		elif e.is_building():
			if not by_type.has(e.type):
				by_type[e.type] = []
			by_type[e.type].append(e)
			if e.built and (e.capital or centro == null and (e.def.get("produce", []) as Array).has("aldeano")):
				centro = e
	if centro == null:
		if not army.is_empty():
			_attack(army)
		return
	if rally.x < 0:
		var enemy_base := sim.bases[(player + 1) % sim.bases.size()]
		rally = Vector2i(centro.x + (enemy_base.x * P - centro.x) / 6, centro.y + (enemy_base.y * P - centro.y) / 6)

	var saving := _wants_hito(p, vill.size(), by_type)
	_economy(p, vill, centro, saving)
	_buildings(p, vill, centro, by_type, saving)
	_production(p, vill, army, centro, by_type, saving)
	_research(p, by_type, saving)
	_trade(p, by_type)
	_alarm(p, vill, army, centro)
	_military(army, centro)


## Opción económica para la edad II, militar para la III, económica para la IV (de la civilización).
func _hito_type(p: Dictionary) -> String:
	var opts: Array = sim.dp(player).hitos[clampi(p["age"] - 1, 0, 2)]
	return opts[1] if p["age"] == 2 and opts.size() > 1 else opts[0]


func _research(p: Dictionary, by_type: Dictionary, saving: bool) -> void:
	if saving or not level["investiga"]:
		return
	var reserve := 150
	for tech: String in sim.dp(player).tecnologias:
		var t: Dictionary = sim.dp(player).tecnologias[tech]
		if sim.research_block(player, tech) != "":
			continue
		var surplus := true
		for k in t["costo"]:
			if p["res"][k] < t["costo"][k] + reserve:
				surplus = false
		if not surplus:
			continue
		for b: SimEntity in by_type.get(t["edificio"], []):
			if b.built and b.queue.size() < 2:
				sim.push_command({"t": "research", "player": player, "building": b.id, "tech": tech})
				return


## Campana si el enemigo llega a la base con más tropas que las propias; calma pasado el peligro.
func _alarm(p: Dictionary, vill: Array[SimEntity], army: Array[SimEntity], centro: SimEntity) -> void:
	var enemies := 0
	for e in sim.actives:
		if e.alive and e.owner >= 0 and e.owner != player and e.is_military() and sim.dist_to(e, centro) < 16000:
			enemies += 1
	var defenders := 0
	for u in army:
		if sim.dist_to(u, centro) < 20000:
			defenders += 1
	if enemies > 0:
		calm_since = sim.tick
	if not p["alarm"] and enemies >= 2 and enemies > defenders:
		sim.push_command({"t": "alarm", "player": player, "on": true})
	elif p["alarm"] and enemies == 0 and sim.tick - calm_since > 100:
		sim.push_command({"t": "alarm", "player": player, "on": false})


# ---------------------------------------------------------------- Economía

func _economy(p: Dictionary, vill: Array[SimEntity], centro: SimEntity, saving: bool) -> void:
	var ratio: Dictionary = (ratio_early if p["age"] < 2 else ratio_late).duplicate()
	# Ajuste por banco: menos gente en lo que sobra, más en lo que falta para el hito.
	var hito_cost: Dictionary = sim.dp(player).cost_of(_hito_type(p), p["age"]) if saving else {}
	for k in Sim.RES_KINDS:
		if p["res"][k] > 600:
			ratio[k] = ratio[k] / 3
		if hito_cost.has(k) and p["res"][k] < hito_cost[k]:
			ratio[k] += 12
	var counts := {"alimento": 0, "madera": 0, "piedra": 0, "riqueza": 0}
	var idle: Array[SimEntity] = []
	for v in vill:
		if (v.order == O.GATHER or v.order == O.RETURN) and counts.has(v.gather_kind):
			counts[v.gather_kind] += 1
		elif v.order == O.IDLE:
			idle.append(v)
	# Reasignar uno si la proporción está muy desbalanceada.
	if idle.is_empty() and vill.size() >= 8:
		var over := _most(counts, ratio, vill.size(), true)
		var under := _most(counts, ratio, vill.size(), false)
		if over != under and counts[over] - vill.size() * ratio[over] / 100 >= 2 and vill.size() * ratio[under] / 100 - counts[under] >= 2:
			for v in vill:
				if v.order == O.GATHER and v.gather_kind == over and v.carry == 0:
					idle.append(v)
					counts[over] -= 1
					break
	for v in idle:
		var kind := _most(counts, ratio, vill.size() + 1, false)
		var t := sim.find_resource(player, kind, centro.x, centro.y, 40000, -1, v.id)
		if t == null and kind == "alimento":
			if sim.can_afford(player, sim.dp(player).cost_of("granja", p["age"])):
				var site := _site("granja", centro, 0)
				if site.x >= 0:
					sim.push_command({"t": "build", "player": player, "ids": [v.id], "type": "granja", "tx": site.x, "ty": site.y})
					counts[kind] += 1
					continue
			kind = "madera"
			t = sim.find_resource(player, kind, centro.x, centro.y, 60000, -1, v.id)
		if t == null:
			for k in Sim.RES_KINDS:
				t = sim.find_resource(player, k, v.x, v.y, 60000, -1, v.id)
				if t != null:
					kind = k
					break
		if t != null:
			sim.push_command({"t": "target", "player": player, "ids": [v.id], "target": t.id})
			counts[kind] += 1


func _most(counts: Dictionary, ratio: Dictionary, total: int, over: bool) -> String:
	var best := "alimento"
	var best_v: int = -(1 << 40)
	for k in Sim.RES_KINDS:
		var diff: int = (counts[k] * 100 - total * ratio[k]) if over else (total * ratio[k] - counts[k] * 100)
		if diff > best_v:
			best_v = diff
			best = k
	return best


# ---------------------------------------------------------------- Construcción

func _wants_hito(p: Dictionary, n_vill: int, by_type: Dictionary) -> bool:
	if p["age"] >= sim.dp(player).edades.size() or sim.hito_in_progress(player):
		return false
	var need: int = 13 + 8 * (int(p["age"]) - 1)
	if p["age"] >= 2 and not by_type.has("cuartel"):
		return false
	if n_vill < need:
		return false
	# Solo ahorra si el hito está al alcance: cada recurso cubre al menos la mitad.
	var cost: Dictionary = sim.dp(player).cost_of(_hito_type(p), p["age"])
	for k in cost:
		if p["res"][k] * 2 < cost[k]:
			return sim.tick % 1200 < 400 # ahorro intermitente para no congelar el ejército
	return true


func _buildings(p: Dictionary, vill: Array[SimEntity], centro: SimEntity, by_type: Dictionary, saving: bool) -> void:
	if vill.is_empty():
		return
	var unbuilt := {}
	for k in by_type:
		for b: SimEntity in by_type[k]:
			if not b.built:
				unbuilt[k] = true
	# Casas.
	var margin: int = 3 + (by_type.get("cuartel", []) as Array).size() * 2
	if p["pop_cap"] < sim.data.reglas["pob_max"] and p["pop_cap"] - p["pop"] <= margin and not unbuilt.has("casa"):
		_try_build("casa", p, vill, centro, 1)
	# Hito.
	if saving and sim.can_afford(player, sim.dp(player).cost_of(_hito_type(p), p["age"])):
		_try_build(_hito_type(p), p, vill, centro, 4)
		return
	# Cuartel.
	var n_cuartel: int = by_type.get("cuartel", []).size()
	var rich: bool = p["res"]["alimento"] > 800 and p["res"]["madera"] > 300 and n_cuartel < 5
	if (n_cuartel == 0 and vill.size() >= 11) or (n_cuartel == 1 and p["age"] >= 2 and vill.size() >= 24) or rich:
		if not unbuilt.has("cuartel"):
			_try_build("cuartel", p, vill, centro, 2)
	# Depósitos cerca de recursos lejanos.
	if not unbuilt.has("deposito") and by_type.get("deposito", []).size() < 4:
		for kind in ["alimento", "madera", "riqueza", "piedra"]:
			var far := _far_gather_point(vill, kind)
			if far != null:
				var site := _site_near("deposito", Vector2i(far.x / P, far.y / P), 1)
				if site.x >= 0 and sim.can_afford(player, sim.dp(player).cost_of("deposito", p["age"])):
					sim.push_command({"t": "build", "player": player, "ids": [_nearest_villager(vill, far.x, far.y).id], "type": "deposito", "tx": site.x, "ty": site.y})
				break
	# Edificios propios de la civilización (corral, gult, mocambo, kraal...), uno por paso.
	var wanted := {}
	for t: String in sim.dp(player).civ.get("ia_edificios", []):
		wanted[t] = int(wanted.get(t, 0)) + 1
	for t: String in wanted:
		var have: int = (by_type.get(t, []) as Array).size()
		var def: Dictionary = sim.dp(player).edificios.get(t, {})
		if have < int(wanted[t]) and not unbuilt.has(t) and int(def.get("edad_min", 1)) <= p["age"] and vill.size() >= 10 + have * 6:
			_try_build(t, p, vill, centro, 2)
			break
	# Caminos (módulo caminos): une a la capital el primer edificio desconectado.
	if sim.dp(player).has_mod("caminos") and sim.tick % 200 == player * 20 and not unbuilt.has("camino"):
		for k in by_type:
			if k == "camino":
				continue
			for bb: SimEntity in by_type[k]:
				if bb.built and not bb.capital and not sim.mods.connected(bb):
					var tiles := _road_tiles(Vector2i(bb.tx + bb.w / 2, bb.ty + bb.h / 2), Vector2i(centro.tx + centro.w / 2, centro.ty + centro.h / 2))
					if not tiles.is_empty():
						var v := _nearest_villager(vill, bb.x, bb.y)
						sim.push_command({"t": "build_line", "player": player, "ids": [v.id], "type": "camino", "tiles": tiles})
					return
	# Mercado desde la edad II.
	if p["age"] >= 2 and not by_type.has("mercado") and vill.size() >= 20:
		_try_build("mercado", p, vill, centro, 2)
	# Torre.
	if p["age"] >= 2 and sim.dp(player).edificios.has("torre") and by_type.get("torre", []).size() < 1 and p["res"]["piedra"] >= 250:
		_try_build("torre", p, vill, centro, 1)


func _far_gather_point(vill: Array[SimEntity], kind: String) -> SimEntity:
	var n := 0
	var sample: SimEntity = null
	for v in vill:
		if v.order == O.GATHER and v.gather_kind == kind:
			var t: SimEntity = sim.by_id.get(v.target)
			if t == null or t.is_building():
				continue
			var d := sim.nearest_dropoff(player, kind, t.x, t.y)
			if d == null or sim.dist_to(t, d) > 4500:
				n += 1
				sample = t
	return sample if n >= 3 else null


func _try_build(type: String, p: Dictionary, vill: Array[SimEntity], centro: SimEntity, workers: int) -> void:
	if not sim.can_afford(player, sim.dp(player).cost_of(type, p["age"])):
		return
	var site := _site(type, centro, 1)
	if site.x < 0:
		return
	var ids := []
	var used := {}
	for i in workers:
		var best: SimEntity = null
		var best_d := 1 << 60
		for v in vill:
			if used.has(v.id) or v.order == O.BUILD or v.carry > 4:
				continue
			var d := Sim.dist(v.x, v.y, site.x * P, site.y * P)
			if d < best_d:
				best = v
				best_d = d
		if best == null:
			break
		used[best.id] = true
		ids.append(best.id)
	if ids.is_empty():
		return
	sim.push_command({"t": "build", "player": player, "ids": ids, "type": type, "tx": site.x, "ty": site.y})


func _nearest_villager(vill: Array[SimEntity], x: int, y: int) -> SimEntity:
	var best := vill[0]
	var best_d := 1 << 60
	for v in vill:
		var d := Sim.dist(v.x, v.y, x, y)
		if d < best_d and v.order != O.BUILD:
			best = v
			best_d = d
	return best


func _site(type: String, centro: SimEntity, margin: int) -> Vector2i:
	return _site_near(type, Vector2i(centro.tx + 2, centro.ty + 2), margin, 4)


## Busca un lugar libre en anillos alrededor de `c`, dejando `margin` casillas de paso.
func _site_near(type: String, c: Vector2i, margin: int, min_r: int = 1) -> Vector2i:
	if not sim.dp(player).edificios.has(type):
		return Vector2i(-1, -1)
	var tam: Array = sim.dp(player).edificios[type]["tam"]
	var w: int = tam[0]
	var h: int = tam[1]
	for r in range(min_r, 30):
		for dy in range(-r, r + 1):
			for dx in range(-r, r + 1):
				if absi(dx) != r and absi(dy) != r:
					continue
				var tx := c.x + dx - w / 2
				var ty := c.y + dy - h / 2
				if tx < 2 or ty < 2 or tx + w > sim.map.n - 2 or ty + h > sim.map.n - 2:
					continue
				if sim.map.is_free_rect(tx - margin, ty - margin, w + margin * 2, h + margin * 2) and sim.can_place(type, tx, ty, player):
					return Vector2i(tx, ty)
	return Vector2i(-1, -1)


# ---------------------------------------------------------------- Producción

func _production(p: Dictionary, vill: Array[SimEntity], army: Array[SimEntity], centro: SimEntity, by_type: Dictionary, saving: bool) -> void:
	if centro.queue.is_empty() and vill.size() < max_villagers and (centro.def.get("produce", []) as Array).has("aldeano"):
		sim.push_command({"t": "train", "player": player, "building": centro.id, "type": "aldeano"})
	var threatened := _threat(centro) != null
	if saving and not threatened:
		return
	var order := _counter_order(p)
	var producers: Array = []
	for k in by_type:
		for b: SimEntity in by_type[k]:
			if b.built and b.capital == false and _makes_military(b):
				producers.append(b)
	for b: SimEntity in producers:
		if not b.built:
			continue
		if not b.rally_set:
			sim.push_command({"t": "rally", "player": player, "building": b.id, "x": rally.x, "y": rally.y})
		if b.queue.size() >= 2:
			continue
		# Arietes desde la edad II: sin asedio los ataques no derriban edificios.
		if p["age"] >= 2 and b.type == "cuartel" and _count(army, "ariete") < 1 + wave / 2 and army.size() >= 6:
			if sim.can_afford(player, sim.dp(player).cost_of("ariete", p["age"])):
				sim.push_command({"t": "train", "player": player, "building": b.id, "type": "ariete"})
				continue
		# La preferida si alcanza; si no, la siguiente que se pueda pagar.
		for type in order:
			if sim.can_afford(player, sim.dp(player).cost_of(type, p["age"])):
				sim.push_command({"t": "train", "player": player, "building": b.id, "type": type})
				break


## Unidades en orden de preferencia: primero la que vence a la función enemiga más numerosa (triángulo, docs/05).
func _counter_order(p: Dictionary) -> Array[String]:
	var counts := {"choque": 0, "distancia": 0, "linea": 0}
	for e in sim.actives:
		if e.alive and e.owner >= 0 and e.owner != player and e.is_military() and counts.has(e.fn):
			counts[e.fn] += 1
	var top := "choque"
	for k in counts:
		if counts[k] > counts[top]:
			top = k
	var pick := {"choque": "lancero", "distancia": "guerrero", "linea": "hondero"}[top] as String
	if counts[top] == 0:
		pick = ["hondero", "guerrero", "lancero"][(sim.tick / 160) % 3]
	var out: Array[String] = []
	for t: String in sim.dp(player).civ.get("ia_unidades", []):
		if (sim.tick / 50 + out.size()) % 3 == 0:
			out.append(t)
	out.append(pick)
	for t: String in ["hondero", "guerrero", "lancero"]:
		if not out.has(t):
			out.append(t)
	var dd := sim.dp(player)
	return out.filter(func(t: String) -> bool: return dd.unidades.has(t) and dd.unidades[t]["edad_min"] <= p["age"])


# ---------------------------------------------------------------- Ejército

func _threat(centro: SimEntity) -> SimEntity:
	var best: SimEntity = null
	var best_d := 22000
	for e in sim.actives:
		if e.alive and e.owner >= 0 and e.owner != player and e.is_unit():
			var d := sim.dist_to(e, centro)
			if d < best_d:
				best = e
				best_d = d
	return best


func _military(army: Array[SimEntity], centro: SimEntity) -> void:
	if army.is_empty():
		return
	var threat := _threat(centro)
	if threat != null:
		var ids := []
		for u in army:
			if u.order != O.ATTACK:
				ids.append(u.id)
		if not ids.is_empty():
			sim.push_command({"t": "move", "player": player, "ids": ids, "x": threat.x, "y": threat.y, "amove": true})
		return
	var need: int = int(level["ataque_base"]) + int(level["ataque_paso"]) * wave
	var gap: int = level["ataque_espera_ticks"]
	if personality == "agresiva":
		need = 4 + 3 * wave
		gap = 320
	if personality != "pasiva" and army.size() >= need and sim.tick - last_attack > gap:
		wave += 1
		last_attack = sim.tick
		_attack(army)
		return
	# Incursiones (malón, correría): las unidades más rápidas golpean la economía rival.
	if sim.dp(player).civ.get("ia_incursiones", false) and sim.tick % 900 == (player * 97) % 900 and army.size() >= 5:
		var prey: SimEntity = null
		var best_d := 1 << 60
		for e in sim.actives:
			if e.alive and e.owner >= 0 and e.owner != player and e.inside < 0 and (e.fn == "civil" or e.def.has("fuente") or e.def.has("deposito")):
				var d := Sim.dist(e.x, e.y, rally.x, rally.y)
				if d < best_d:
					best_d = d
					prey = e
		if prey != null:
			var fast := army.duplicate()
			fast.sort_custom(func(a: SimEntity, b: SimEntity) -> bool: return a.speed > b.speed)
			var ids := []
			for u in fast:
				if ids.size() >= 5:
					break
				if u.order == O.IDLE or u.order == O.MOVE:
					ids.append(u.id)
			if not ids.is_empty():
				sim.push_command({"t": "move", "player": player, "ids": ids, "x": prey.x, "y": prey.y, "amove": true})
	# Sitios sagrados: un grupo chico va a tomar el más cercano que no controla.
	if sim.tick % 300 == player * 50 and army.size() >= 6:
		var site: SimEntity = null
		var best := 1 << 60
		for e in sim.actives:
			if e.alive and e.def.get("sagrado", false) and e.holder != player:
				var d := Sim.dist(e.x, e.y, rally.x, rally.y)
				if d < best:
					best = d
					site = e
		if site != null:
			var ids := []
			for u in army:
				if u.order == O.IDLE and ids.size() < 4:
					ids.append(u.id)
			if not ids.is_empty():
				sim.push_command({"t": "move", "player": player, "ids": ids, "x": site.x, "y": site.y, "amove": true})
	# Reagrupar a las unidades inactivas en el punto de reunión.
	var idle := []
	for u in army:
		if u.order == O.IDLE and Sim.dist(u.x, u.y, rally.x, rally.y) > 6000 and sim.tick - last_attack > 900 and not _near_site(u):
			idle.append(u.id)
	if not idle.is_empty():
		sim.push_command({"t": "move", "player": player, "ids": idle, "x": rally.x, "y": rally.y})


func _attack(army: Array[SimEntity]) -> void:
	var target: SimEntity = null
	var best_d := 1 << 60
	var ref := army[0]
	for e in sim.actives:
		if e.alive and e.is_building() and e.owner >= 0 and e.owner != player and (e.def.get("hito", false) or e.capital):
			var d := sim.dist_to(ref, e)
			if d < best_d:
				target = e
				best_d = d
	if target == null:
		return
	var ids := []
	for u in army:
		ids.append(u.id)
	sim.push_command({"t": "move", "player": player, "ids": ids, "x": target.x, "y": target.y + 3000 * (1 if player == 1 else -1), "amove": true})


func _count(list: Array[SimEntity], type: String) -> int:
	var n := 0
	for e in list:
		if e.type == type:
			n += 1
	return n


func _makes_military(b: SimEntity) -> bool:
	for t: String in b.def.get("produce", []):
		var u: Dictionary = sim.dp(player).unidades.get(t, {})
		if not u.is_empty() and u["funcion"] in ["choque", "distancia", "linea"]:
			return true
	return false


## Mercado: vende excedentes cuando falta riqueza y compra lo que falta cuando sobra riqueza.
func _trade(p: Dictionary, by_type: Dictionary) -> void:
	var markets: Array = by_type.get("mercado", [])
	if markets.is_empty() or not (markets[0] as SimEntity).built:
		return
	var m: SimEntity = markets[0]
	var res: Dictionary = p["res"]
	for k in ["alimento", "madera", "piedra"]:
		if int(res[k]) > 900 and int(res["riqueza"]) < 400:
			sim.push_command({"t": "trade", "player": player, "building": m.id, "recurso": k, "op": "vender"})
			return
	for k in ["alimento", "madera"]:
		if int(res[k]) < 100 and int(res["riqueza"]) > 700:
			sim.push_command({"t": "trade", "player": player, "building": m.id, "recurso": k, "op": "comprar"})
			return


func _near_site(u: SimEntity) -> bool:
	for e in sim.actives:
		if e.def.get("sagrado", false) and absi(e.x - u.x) < 5000 and absi(e.y - u.y) < 5000:
			return true
	return false


## Casillas libres de un camino recto (4-conexo) entre dos puntos; las ocupadas se saltean.
func _road_tiles(a: Vector2i, b: Vector2i) -> Array:
	var out := []
	var x := a.x
	var y := a.y
	var guard := 0
	while (x != b.x or y != b.y) and guard < 80:
		guard += 1
		if absi(b.x - x) >= absi(b.y - y):
			x += signi(b.x - x)
		else:
			y += signi(b.y - y)
		if sim.can_place("camino", x, y, player):
			out.append([x, y])
	return out
