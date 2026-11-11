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

# Perfil equilibrado de H1. En H2 pasa a data/ia/ (docs/08).
var ratio_early := {"alimento": 52, "madera": 33, "riqueza": 10, "piedra": 5}
var ratio_late := {"alimento": 42, "madera": 25, "riqueza": 23, "piedra": 10}
var max_villagers := 42


func _init(s: Sim, pid: int) -> void:
	sim = s
	player = pid


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
			if e.fn == "civil":
				vill.append(e)
			else:
				army.append(e)
		elif e.is_building():
			if not by_type.has(e.type):
				by_type[e.type] = []
			by_type[e.type].append(e)
			if e.type == "centro" and e.built and centro == null:
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
	_military(army, centro)


# ---------------------------------------------------------------- Economía

func _economy(p: Dictionary, vill: Array[SimEntity], centro: SimEntity, saving: bool) -> void:
	var ratio: Dictionary = (ratio_early if p["age"] < 2 else ratio_late).duplicate()
	# Ajuste por banco: menos gente en lo que sobra, más en lo que falta para el hito.
	var hito_cost: Dictionary = sim.data.cost_of("hito", p["age"]) if saving else {}
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
			if sim.can_afford(player, sim.data.cost_of("granja", p["age"])):
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
	if p["age"] >= sim.data.edades.size() or sim.hito_in_progress(player):
		return false
	var need: int = 13 + 8 * (int(p["age"]) - 1)
	if p["age"] >= 2 and not by_type.has("cuartel"):
		return false
	if n_vill < need:
		return false
	# Solo ahorra si el hito está al alcance: cada recurso cubre al menos la mitad.
	var cost: Dictionary = sim.data.cost_of("hito", p["age"])
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
	if saving and sim.can_afford(player, sim.data.cost_of("hito", p["age"])):
		_try_build("hito", p, vill, centro, 4)
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
				if site.x >= 0 and sim.can_afford(player, sim.data.cost_of("deposito", p["age"])):
					sim.push_command({"t": "build", "player": player, "ids": [_nearest_villager(vill, far.x, far.y).id], "type": "deposito", "tx": site.x, "ty": site.y})
				break
	# Torre.
	if p["age"] >= 2 and by_type.get("torre", []).size() < 1 and p["res"]["piedra"] >= 250:
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
	if not sim.can_afford(player, sim.data.cost_of(type, p["age"])):
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
	var tam: Array = sim.data.edificios[type]["tam"]
	var w: int = tam[0]
	var h: int = tam[1]
	for r in range(min_r, 24):
		for dy in range(-r, r + 1):
			for dx in range(-r, r + 1):
				if absi(dx) != r and absi(dy) != r:
					continue
				var tx := c.x + dx - w / 2
				var ty := c.y + dy - h / 2
				if tx < 2 or ty < 2 or tx + w > sim.map.n - 2 or ty + h > sim.map.n - 2:
					continue
				if sim.map.is_free_rect(tx - margin, ty - margin, w + margin * 2, h + margin * 2):
					return Vector2i(tx, ty)
	return Vector2i(-1, -1)


# ---------------------------------------------------------------- Producción

func _production(p: Dictionary, vill: Array[SimEntity], army: Array[SimEntity], centro: SimEntity, by_type: Dictionary, saving: bool) -> void:
	if centro.queue.is_empty() and vill.size() < max_villagers:
		sim.push_command({"t": "train", "player": player, "building": centro.id, "type": "aldeano"})
	var threatened := _threat(centro) != null
	if saving and not threatened:
		return
	var order := _counter_order(p)
	for b: SimEntity in by_type.get("cuartel", []):
		if not b.built:
			continue
		if not b.rally_set:
			sim.push_command({"t": "rally", "player": player, "building": b.id, "x": rally.x, "y": rally.y})
		if b.queue.size() >= 2:
			continue
		# La preferida si alcanza; si no, la siguiente que se pueda pagar.
		for type in order:
			if sim.can_afford(player, sim.data.cost_of(type, p["age"])):
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
	var out: Array[String] = [pick]
	for t: String in ["hondero", "guerrero", "lancero"]:
		if not out.has(t):
			out.append(t)
	return out.filter(func(t: String) -> bool: return sim.data.unidades[t]["edad_min"] <= p["age"])


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
	if army.size() >= 7 + 4 * wave and sim.tick - last_attack > 500:
		wave += 1
		last_attack = sim.tick
		_attack(army)
		return
	# Reagrupar a las unidades inactivas en el punto de reunión.
	var idle := []
	for u in army:
		if u.order == O.IDLE and Sim.dist(u.x, u.y, rally.x, rally.y) > 6000 and sim.tick - last_attack > 900:
			idle.append(u.id)
	if not idle.is_empty():
		sim.push_command({"t": "move", "player": player, "ids": idle, "x": rally.x, "y": rally.y})


func _attack(army: Array[SimEntity]) -> void:
	var target: SimEntity = null
	var best_d := 1 << 60
	var ref := army[0]
	for e in sim.actives:
		if e.alive and e.is_building() and e.owner >= 0 and e.owner != player and e.def.get("hito", false):
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
