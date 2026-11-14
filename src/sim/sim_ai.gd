class_name SimAI
extends RefCounted
## IA de escaramuza (docs/08-ia-rival.md). Emite comandos como un jugador; corre dentro de la simulación.

const P := 1000
const O := SimEntity.Order

var sim: Sim
var player: int
var wave := 0
var last_attack := -100000
var last_raid := 0 # incursiones y control del mapa: por tiempo transcurrido, no por tick exacto
var last_spot := 0
var last_road := 0
var last_engine := -1000
var last_elephant := -1000
var last_mill := 0
var _eng_mark_tick := 0
var _eng_mark_val := 0
var _eng_rate := 0
var _no_route := {} # edificio -> tick desde el que se vuelve a intentar el camino
var last_site := 0
var last_tribute := 0
var focus := -1 # jugador enemigo al que apunta el ataque; los aliados se suman (docs/11)
var rally := Vector2i(-1, -1)
var calm_since := 0
var personality := "normal" # estilo: pacifica, normal, acosadora, agresiva (reglas.json → estilos_ia); pasiva en campañas
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
		# La base enemiga más cercana (con equipos, nunca la de un aliado).
		var enemy_base := sim.bases[(player + 1) % sim.bases.size()]
		var best_eb := 1 << 60
		for j in mini(sim.players.size(), sim.bases.size()):
			if sim.enemies(player, j):
				var eb := sim.bases[j]
				var d := Sim.dist(eb.x * P, eb.y * P, centro.x, centro.y)
				if d < best_eb:
					best_eb = d
					enemy_base = eb
		rally = Vector2i(centro.x + (enemy_base.x * P - centro.x) / 6, centro.y + (enemy_base.y * P - centro.y) / 6)

	var saving := _wants_hito(p, vill.size(), by_type)
	_economy(p, vill, centro, saving)
	_buildings(p, vill, centro, by_type, saving)
	_production(p, vill, army, centro, by_type, saving)
	_research(p, by_type, saving)
	_trade(p, by_type)
	_engine(p, vill, centro, by_type, saving)
	_alarm(p, vill, army, centro)
	_tribute(p, saving)
	_military(army, centro)


## Eje del hito según la edad: económico para la II, militar para la III y
## económico para la IV; el estilo agresivo va siempre por lo militar. Cada hito
## declara su eje en los datos ("eje"), así no depende del orden de la lista.
func _hito_type(p: Dictionary) -> String:
	var dd := sim.dp(player)
	var opts: Array = dd.hitos[clampi(p["age"] - 1, 0, 2)]
	var want := "militar" if p["age"] == 2 or personality == "agresiva" else "economia"
	for o: String in opts:
		if dd.edificios.get(o, {}).get("eje", "") == want:
			return o
	return opts[0]


func _research(p: Dictionary, by_type: Dictionary, saving: bool) -> void:
	if saving or not level["investiga"]:
		return
	var reserve := 150
	var techs: Array = sim.dp(player).tecnologias.keys()
	# La tecnología del motor va primero (crítica 03, regla 5).
	techs.sort_custom(func(a: String, b: String) -> bool: return bool(sim.dp(player).tecnologias[a].get("motor", false)) and not bool(sim.dp(player).tecnologias[b].get("motor", false)))
	for tech: String in techs:
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
		if e.alive and e.owner >= 0 and sim.enemies(player, e.owner) and e.is_military() and sim.dist_to(e, centro) < 16000:
			enemies += 1
	var defenders := 0
	for u in army:
		if sim.dist_to(u, centro) < 20000:
			defenders += 1
	if enemies > 0:
		calm_since = sim.tick
	if not p["alarm"] and enemies >= 2 and enemies > defenders:
		sim.push_command({"t": "alarm", "player": player, "on": true, "max": enemies * int(sim.data.reglas.get("ia_campana_por_enemigo", 3))})
	elif p["alarm"] and enemies == 0 and sim.tick - calm_since > int(sim.data.reglas.get("ia_campana_calma_ticks", 50)):
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
		elif saving and k != "madera" and (not hito_cost.has(k) or p["res"][k] >= hito_cost[k]):
			ratio[k] = ratio[k] / 3 # lo que ya alcanza para el hito libera gente para lo que falta
	var counts := {"alimento": 0, "madera": 0, "piedra": 0, "riqueza": 0}
	var idle: Array[SimEntity] = []
	for v in vill:
		if (v.order == O.GATHER or v.order == O.RETURN) and counts.has(v.gather_kind):
			counts[v.gather_kind] += 1
		elif v.order == O.IDLE:
			idle.append(v)
	# Aldeanos virtuales (crítica 03, regla 3): la riqueza que da el motor propio cuenta
	# como gente ya puesta en riqueza, así la IA no carga la arcilla de más.
	var virt := _engine_rate(p) / 30
	counts["riqueza"] += virt
	# Reasignar uno si la proporción está muy desbalanceada.
	if idle.is_empty() and vill.size() >= 8:
		var tot := vill.size() + virt
		var over := _most(counts, ratio, tot, true)
		var under := _most(counts, ratio, tot, false)
		if over != under and counts[over] - tot * ratio[over] / 100 >= 2 and tot * ratio[under] / 100 - counts[under] >= 2:
			for v in vill:
				if v.order == O.GATHER and v.gather_kind == over and v.carry == 0:
					idle.append(v)
					counts[over] -= 1
					break
	for v in idle:
		var kind := _most(counts, ratio, vill.size() + virt + 1, false)
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
	# En la edad I se ahorra apenas hay aldeanos suficientes, como en AoE: el avance
	# a la II es la prioridad (compuerta de la etapa 1: edad II entre 6:30 y 9:00).
	if p["age"] == 1:
		return true
	# Después, solo si el hito está al alcance: cada recurso cubre al menos la mitad.
	var cost: Dictionary = sim.dp(player).cost_of(_hito_type(p), p["age"])
	for k in cost:
		if p["res"][k] * 2 < cost[k]:
			return sim.tick % 1200 < 400 # ahorro intermitente para no congelar el ejército
	return true


## Motor propio de cada civ (docs/diseno/revision-economia/v3/04, §9.3).
func _engine(p: Dictionary, vill: Array[SimEntity], centro: SimEntity, by_type: Dictionary, saving: bool) -> void:
	if sim.tick - last_engine < 50:
		return
	last_engine = sim.tick
	var dd := sim.dp(player)
	match dd.clave:
		"guaranies":
			# Quemar (roza otra vez, sin yerbal) solo si falta alimento para el próximo hito.
			var need := int(dd.cost_of(_hito_type(p), p["age"]).get("alimento", 0)) if p["age"] < dd.edades.size() else 0
			var mode := "quemar" if saving and int(p["res"]["alimento"]) < need else "crecer"
			if str(p.get("modo_monte", "crecer")) != mode:
				sim.push_command({"t": "modo_monte", "player": player, "modo": mode})
			# Rozas para la gente del alimento: las que se agotan pasan a yerbal o capuera.
			# Una roza nueva solo si hay gente del alimento sin roza y el alimento no sobra.
			var food_people := 0
			for v in vill:
				if v.gather_kind == "alimento" and (v.order == O.GATHER or v.order == O.RETURN or v.order == O.IDLE):
					food_people += 1
			var rozas: int = (by_type.get("granja", []) as Array).size()
			if rozas < food_people and int(p["res"]["alimento"]) < 600 and int(p["res"]["madera"]) >= int(dd.cost_of("granja", p["age"]).get("madera", 0)) + 30:
				_try_build("granja", p, vill, centro, 1)
		"ayutthaya":
			_elephants(p, vill, centro)
		"etiopia":
			_found_court(p, vill, centro, by_type)
		"mapuches":
			# Kawiñ solo si se ahorra para el hito y falta alimento: el corral más lleno, una vez por edad.
			if saving and p["age"] < dd.edades.size():
				var need := int(dd.cost_of(_hito_type(p), p["age"]).get("alimento", 0))
				if int(p["res"]["alimento"]) < need:
					var best: SimEntity = null
					for c: SimEntity in by_type.get("corral", []):
						if c.built and c.heads >= 4 and c.feast_age != int(p["age"]) and (best == null or c.heads > best.heads):
							best = c
					if best != null and int(p["res"]["alimento"]) + (best.heads - 1) * 30 >= need - 100:
						sim.push_command({"t": "kawin", "player": player, "building": best.id})
		"palmares":
			# Guarda fama para el hito solo mientras ahorra para él; si no, la gente sigue llegando.
			if bool(p.get("guardar_fama", true)) != saving:
				sim.push_command({"t": "guardar", "player": player, "res": "fama", "on": saving})
		"tawantinsuyu":
			var want_res := 60 if saving else 0
			if int(p.get("reserva_mita", 0)) != want_res:
				sim.push_command({"t": "reserve", "player": player, "res": "mita", "n": want_res})
			# Regalo de cumbi en la edad III, si sobra mit'a por encima de la reserva.
			if dd.has_mod("regalo_cumbi") and int(p["age"]) >= int(dd.mod("regalo_cumbi").get("edad", 3)) and int(p["res"]["mita"]) >= int(dd.mod("regalo_cumbi")["costo"]) + 60 and sim.mods.cumbi_target(player) != null:
				sim.push_command({"t": "cumbi", "player": player})
			var shops: Array = by_type.get("taller_tejido", [])
			# En la edad I, un solo taller antes del hito II (aunque se esté ahorrando: rinde riqueza para el hito).
			if vill.size() < 10 or not dd.edificios.has("taller_tejido") or (p["age"] == 1 and shops.size() >= 1):
				return
			var cfg: Dictionary = dd.mod("recurso_propio")
			var by_age: Array = cfg.get("por_aldeano_por_edad", [cfg.get("por_aldeano", 4)])
			var income := vill.size() * int(by_age[clampi(int(p["age"]) - 1, 0, by_age.size() - 1)])
			var cost: Dictionary = dd.cost_of("taller_tejido", p["age"])
			if income - 30 * shops.size() >= 30 and int(p["res"]["madera"]) >= int(cost.get("madera", 0)) + 60:
				_try_build("taller_tejido", p, vill, centro, 1)


## Corte etíope (§9.3): cuando a la arcilla junto a la corte le quedan menos de 100,
## fundar la corte junto a la arcilla propia con más riqueza (o la del centro desde la III).
func _found_court(p: Dictionary, vill: Array[SimEntity], centro: SimEntity, by_type: Dictionary) -> void:
	var dd := sim.dp(player)
	if not dd.edificios.has("corte_nueva") or by_type.has("corte_nueva") or by_type.has("gondar") or vill.is_empty():
		return
	if not sim.can_afford(player, dd.cost_of("corte_nueva", p["age"])):
		return
	var near_left := 0
	var best: SimEntity = null
	for t in sim.entities:
		if not (t.alive and t.is_resource() and t.type == "riqueza" and t.amount > 0):
			continue
		var d := Sim.dist(t.x, t.y, centro.x, centro.y)
		if d <= 14000 and (t.res_owner == player or t.res_owner < 0):
			near_left += t.amount
		var ok_owner := t.res_owner == player or (t.res_owner < 0 and int(p["age"]) >= 3)
		if ok_owner and d > 14000 and t.amount >= 300 and (best == null or t.amount > best.amount or (t.amount == best.amount and t.id < best.id)):
			best = t
	if near_left >= 100 or best == null:
		return
	for r in range(5, 9):
		for dy in range(-r, r + 1):
			for dx in range(-r, r + 1):
				if absi(dx) != r and absi(dy) != r:
					continue
				var tx := best.tx + dx
				var ty := best.ty + dy
				if sim.can_place("corte_nueva", tx, ty, player):
					var v := _nearest_villager(vill, tx * P, ty * P)
					sim.push_command({"t": "build", "player": player, "ids": [v.id], "type": "corte_nueva", "tx": tx, "ty": ty})
					return


## Elefantes del rey (§9.3): entrenar hasta el máximo de la edad y llevar cada uno
## junto a su grupo de aldeanos: el 1.º a la madera, el 2.º al alimento, el 3.º a la piedra.
func _elephants(p: Dictionary, vill: Array[SimEntity], centro: SimEntity) -> void:
	var dd := sim.dp(player)
	if not dd.unidades.has("elefante_rey"):
		return
	var eles: Array[SimEntity] = []
	for e in sim.actives:
		if e.alive and e.owner == player and e.type == "elefante_rey":
			eles.append(e)
	var maxes: Array = dd.unidades["elefante_rey"]["maximo_por_edad"]
	var want := int(maxes[clampi(int(p["age"]) - 1, 0, maxes.size() - 1)]) + sim.mods.engine_max_bonus(player, "elefante_rey")
	var queued := 0
	for q in centro.queue:
		if q == "elefante_rey":
			queued += 1
	if eles.size() + queued < want and centro.queue.size() < 2 and vill.size() >= 8 and sim.can_afford(player, dd.cost_of("elefante_rey", p["age"])):
		sim.push_command({"t": "train", "player": player, "building": centro.id, "type": "elefante_rey"})
	if sim.tick - last_elephant < 300:
		return
	last_elephant = sim.tick
	var kinds := ["madera", "alimento", "piedra"]
	for i in eles.size():
		var kind: String = kinds[mini(i, kinds.size() - 1)]
		var sx := 0
		var sy := 0
		var n := 0
		for v in vill:
			if v.gather_kind == kind and (v.order == O.GATHER or v.order == O.RETURN):
				var t: SimEntity = sim.by_id.get(v.target)
				if t != null:
					sx += t.x
					sy += t.y
					n += 1
		if n < 2:
			continue
		var tx := sx / n
		var ty := sy / n
		var el := eles[i]
		if Sim.dist(el.x, el.y, tx, ty) > 6000 and el.order == O.IDLE:
			sim.push_command({"t": "move", "player": player, "ids": [el.id], "x": tx, "y": ty})


## Riqueza por minuto del motor propio (último minuto), según el libro de ingresos.
func _engine_rate(p: Dictionary) -> int:
	var now := int(p["stats"].get("origen", {}).get("propio", {}).get("riqueza", 0))
	if sim.tick - _eng_mark_tick >= 600:
		_eng_rate = maxi(0, now - _eng_mark_val) * 600 / maxi(1, sim.tick - _eng_mark_tick)
		_eng_mark_tick = sim.tick
		_eng_mark_val = now
	return _eng_rate


## Reserva del próximo hito: no gastar un recurso propio (mit'a, fama, kulliñ)
## por debajo de lo que pide el hito siguiente (crítica 03, regla 2).
func _keeps_reserve(p: Dictionary, cost: Dictionary) -> bool:
	if p["age"] >= sim.dp(player).edades.size():
		return true
	var need: Dictionary = sim.dp(player).cost_of(_hito_type(p), p["age"])
	for k in cost:
		if k in Sim.RES_KINDS or not need.has(k):
			continue
		if int(p["res"].get(k, 0)) - int(cost[k]) < int(need[k]):
			return false
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
		# Piezas de motor: hasta el máximo de la edad (y no la lista fija de los datos).
		if def.has("maximo_por_edad"):
			var maxes: Array = def["maximo_por_edad"]
			wanted[t] = int(maxes[clampi(int(p["age"]) - 1, 0, maxes.size() - 1)]) + sim.mods.engine_max_bonus(player, t)
		if have < int(wanted[t]) and not unbuilt.has(t) and int(def.get("edad_min", 1)) <= p["age"] and vill.size() >= 10 + have * (3 if def.has("maximo_por_edad") else 6):
			_try_build(t, p, vill, centro, 2)
			break
	# Caminos (módulo caminos): une a la capital el primer edificio desconectado.
	if sim.dp(player).has_mod("caminos") and sim.tick - last_road >= 200 and not unbuilt.has("camino"):
		last_road = sim.tick
		for k in by_type:
			if k == "camino":
				continue
			for bb: SimEntity in by_type[k]:
				if bb.built and not bb.capital and not sim.mods.connected(bb) and sim.tick >= int(_no_route.get(bb.id, 0)):
					var tiles := _road_tiles(bb, centro)
					if not tiles.is_empty():
						var v := _nearest_villager(vill, bb.x, bb.y)
						sim.push_command({"t": "build_line", "player": player, "ids": [v.id], "type": "camino", "tiles": tiles})
						return
					_no_route[bb.id] = sim.tick + 1200 # sin paso: se reintenta en 2 minutos
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
	if not sim.engine_room(type, player):
		return Vector2i(-1, -1) # sin cupo en la edad: ningún lugar va a servir
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
		var makes: Array = b.def.get("produce", [])
		if p["age"] >= 2 and makes.has("ariete") and _count(army, "ariete") < 1 + wave / 2 and army.size() >= 6:
			if sim.can_afford(player, sim.dp(player).cost_of("ariete", p["age"])):
				sim.push_command({"t": "train", "player": player, "building": b.id, "type": "ariete"})
				continue
		# La preferida si alcanza; si no, la siguiente que se pueda pagar.
		for type in order:
			if not makes.has(type) or p["age"] < int(sim.dp(player).unidades.get(type, {}).get("edad_min", 1)):
				continue # solo lo que este edificio produce y la edad permite (antes repetía órdenes rechazadas)
			var c := sim.dp(player).cost_of(type, p["age"])
			if sim.can_afford(player, c) and _keeps_reserve(p, c):
				sim.push_command({"t": "train", "player": player, "building": b.id, "type": type})
				break


## Unidades en orden de preferencia: primero la que vence a la función enemiga más numerosa (triángulo, docs/05).
func _counter_order(p: Dictionary) -> Array[String]:
	var counts := {"choque": 0, "distancia": 0, "linea": 0}
	for e in sim.actives:
		if e.alive and e.owner >= 0 and sim.enemies(player, e.owner) and e.is_military() and counts.has(e.fn):
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
		if e.alive and e.owner >= 0 and sim.enemies(player, e.owner) and (e.is_military() or e.fn == "explorador"):
			var d := sim.dist_to(e, centro)
			if d < best_d:
				best = e
				best_d = d
	return best


func _military(army: Array[SimEntity], centro: SimEntity) -> void:
	if army.is_empty():
		return
	var threat := _threat(centro)
	if threat == null:
		threat = _ally_threat(centro)
	if threat != null:
		var ids := []
		for u in army:
			if u.order != O.ATTACK:
				ids.append(u.id)
		if not ids.is_empty():
			sim.push_command({"t": "move", "player": player, "ids": ids, "x": threat.x, "y": threat.y, "amove": true})
		return
	var st: Dictionary = sim.data.reglas.get("estilos_ia", {}).get(personality, {})
	if personality == "paz": # solo para las pruebas de economía: no pelea fuera de su base
		st = {"ataca_base": false, "incursiones": "no", "controla_mapa": false}
	var need: int = int(st.get("ataque_base", level["ataque_base"])) + int(st.get("ataque_paso", level["ataque_paso"])) * wave
	var gap: int = int(st.get("ataque_espera_ticks", level["ataque_espera_ticks"]))
	var attacks: bool = st.get("ataca_base", personality != "pasiva")
	if attacks and army.size() >= need and sim.tick - last_attack > gap:
		wave += 1
		last_attack = sim.tick
		_attack(army)
		return
	# Los estilos que no atacan la base no entran en ella: quien quede adentro vuelve.
	if not attacks and st.has("respeta_radio"):
		# Las incursiones entran y salen: solo vuelve quien ya terminó (está ocioso).
		_leash(army, int(st["respeta_radio"]), st.get("incursiones", "no") == "si")
	# Incursiones (malón, correría, acoso): las unidades más rápidas golpean la economía rival.
	var raids: String = st.get("incursiones", "civ")
	var raid_on: bool = raids == "si" or (raids == "civ" and bool(sim.dp(player).civ.get("ia_incursiones", false)))
	var every := int(st.get("incursion_cada_ticks", 900))
	if raid_on and sim.tick - last_raid >= every and army.size() >= 5:
		last_raid = sim.tick
		var prey: SimEntity = null
		var best_d := 1 << 60
		for e in sim.actives:
			if e.alive and e.owner >= 0 and sim.enemies(player, e.owner) and e.inside < 0 and (e.fn == "civil" or e.def.has("fuente") or e.def.has("deposito")):
				var d := Sim.dist(e.x, e.y, rally.x, rally.y)
				if d < best_d:
					best_d = d
					prey = e
		if prey != null:
			var fast := army.duplicate()
			fast.sort_custom(func(a: SimEntity, b: SimEntity) -> bool: return a.speed > b.speed)
			var ids := []
			for u in fast:
				if ids.size() >= int(st.get("incursion_tam", 5)):
					break
				if u.order == O.IDLE or u.order == O.MOVE:
					ids.append(u.id)
			if not ids.is_empty():
				sim.push_command({"t": "move", "player": player, "ids": ids, "x": prey.x, "y": prey.y, "amove": true})
	# Control del mapa: la mitad del ejército ocioso ocupa un punto disputado.
	if st.get("controla_mapa", false) and sim.tick - last_spot >= 600 and army.size() >= 6:
		last_spot = sim.tick
		var spot := _map_spot(int(st.get("respeta_radio", 0)))
		if spot.x >= 0:
			var ids := []
			for u in army:
				if u.order == O.IDLE and ids.size() < army.size() / 2:
					ids.append(u.id)
			if not ids.is_empty():
				sim.push_command({"t": "move", "player": player, "ids": ids, "x": spot.x, "y": spot.y, "amove": true})
	# Ingenios neutrales: desde la edad II, un grupo los asalta por el botín (§3.2).
	if personality != "paz" and sim.players[player]["age"] >= 2 and army.size() >= 8 and sim.tick - last_mill >= 900:
		last_mill = sim.tick
		var mill: SimEntity = null
		var best_m := 1 << 60
		for e in sim.actives:
			if e.alive and e.owner < 0 and e.def.has("botin_por_edad"):
				var d := Sim.dist(e.x, e.y, rally.x, rally.y)
				if d < best_m:
					best_m = d
					mill = e
		if mill != null and sim.disputed_room(player) >= 50:
			var ids := []
			for u in army:
				if u.order == O.IDLE and ids.size() < maxi(6, army.size() * 2 / 3):
					ids.append(u.id)
			if ids.size() >= 6:
				sim.push_command({"t": "move", "player": player, "ids": ids, "x": mill.x, "y": mill.y, "amove": true})
	# Sitios sagrados: un grupo chico va a tomar el más cercano que no controla.
	if sim.tick - last_site >= 300 and army.size() >= 6:
		last_site = sim.tick
		var site: SimEntity = null
		var best := 1 << 60
		for e in sim.actives:
			if e.alive and e.def.get("sagrado", false) and (e.holder < 0 or sim.enemies(player, e.holder)):
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


## Base rival: sus edificios principales (capital, centros e hitos).
func _enemy_cores() -> Array[SimEntity]:
	var out: Array[SimEntity] = []
	for e in sim.actives:
		if e.alive and e.is_building() and e.owner >= 0 and sim.enemies(player, e.owner) and (e.capital or e.def.get("hito", false) or e.def.has("produce") and e.def.get("deposito", []).size() > 2):
			out.append(e)
	return out


## Vuelve al punto de reunión quien haya entrado a la base rival.
func _leash(army: Array[SimEntity], radius: int, idle_only: bool = false) -> void:
	var cores := _enemy_cores()
	var back := []
	for u in army:
		if idle_only and u.order != O.IDLE:
			continue
		for c in cores:
			if Sim.dist(u.x, u.y, c.x, c.y) < radius:
				back.append(u.id)
				break
	if not back.is_empty():
		sim.push_command({"t": "move", "player": player, "ids": back, "x": rally.x, "y": rally.y})


## Punto del mapa para ocupar: un sitio sagrado ajeno, o el centro del mapa,
## siempre fuera del radio de las bases rivales si el estilo lo pide.
func _map_spot(radius: int) -> Vector2i:
	var cores := _enemy_cores()
	var options: Array[Vector2i] = []
	for e in sim.actives:
		if e.alive and e.def.get("sagrado", false) and (e.holder < 0 or sim.enemies(player, e.holder)):
			options.append(Vector2i(e.x, e.y))
	var c := sim.map.n * P / 2
	options.append(Vector2i(c, c))
	for o in options:
		var ok := true
		for core in cores:
			if radius > 0 and Sim.dist(o.x, o.y, core.x, core.y) < radius:
				ok = false
		if ok:
			return o
	return Vector2i(-1, -1)


func _attack(army: Array[SimEntity]) -> void:
	var target: SimEntity = null
	var best_d := 1 << 60
	var ref := army[0]
	focus = _pick_rival(ref)
	for e in sim.actives:
		if e.alive and e.is_building() and e.owner >= 0 and sim.enemies(player, e.owner) and (e.def.get("hito", false) or e.capital):
			if focus >= 0 and e.owner != focus:
				continue
			var d := sim.dist_to(ref, e)
			if d < best_d:
				target = e
				best_d = d
	if target == null:
		return
	var ids := []
	for u in army:
		ids.append(u.id)
	# Se para del lado de quien llega, a 3 casillas del blanco.
	var dx := ref.x - target.x
	var dy := ref.y - target.y
	var l := maxi(1, Sim.isqrt(dx * dx + dy * dy))
	sim.push_command({"t": "move", "player": player, "ids": ids, "x": target.x + dx * 3000 / l, "y": target.y + dy * 3000 / l, "amove": true})


## Rival del próximo ataque. Si un aliado ya va contra alguien, se suma; si no,
## el estilo elige: el más cercano o el de menos ejército.
func _pick_rival(ref: SimEntity) -> int:
	for ai in sim.ais:
		if ai != self and ai.focus >= 0 and not sim.enemies(player, ai.player) and ai.player != player:
			if sim.enemies(player, ai.focus) and not sim.players[ai.focus]["defeated"]:
				return ai.focus
	var st: Dictionary = sim.data.reglas.get("estilos_ia", {}).get(personality, {})
	var how: String = st.get("objetivo", "cercano")
	var best := -1
	var best_v := 1 << 60
	for j in sim.players.size():
		if not sim.enemies(player, j) or sim.players[j]["defeated"] or j >= sim.bases.size():
			continue
		var v := 0
		if how == "debil":
			for e in sim.actives:
				if e.alive and e.owner == j and e.is_military():
					v += 1
		else:
			var b := sim.bases[j]
			v = Sim.dist(b.x * P, b.y * P, ref.x, ref.y)
		if v < best_v:
			best_v = v
			best = j
	return best


## Amenaza en la base de un aliado cercano: el ejército va a ayudar.
func _ally_threat(centro: SimEntity) -> SimEntity:
	var eq: Dictionary = sim.data.reglas.get("equipos", {})
	var radius := int(eq.get("ia_ayuda_radio", 0))
	var near := int(eq.get("ia_ayuda_amenaza", 22000))
	if radius <= 0:
		return null
	for e in sim.actives:
		if not e.alive or not e.is_building() or not e.capital or e.owner == player or e.owner < 0 or sim.enemies(player, e.owner):
			continue
		if Sim.dist(e.x, e.y, centro.x, centro.y) > radius:
			continue
		for t in sim.actives:
			if t.alive and t.owner >= 0 and sim.enemies(player, t.owner) and t.is_military() and sim.dist_to(t, e) < near:
				return t
	return null


## Tributo: lo que sobra va al aliado al que le falta (reglas.equipos.ia_tributo).
func _tribute(p: Dictionary, saving: bool) -> void:
	var cfg: Dictionary = sim.data.reglas.get("equipos", {}).get("ia_tributo", {})
	if cfg.is_empty() or saving or sim.tick - last_tribute < int(cfg["cada_ticks"]):
		return
	last_tribute = sim.tick
	for kind in ["alimento", "madera", "piedra", "riqueza"]:
		if int(p["res"].get(kind, 0)) <= int(cfg["sobra"]):
			continue
		for j in sim.players.size():
			if j == player or sim.enemies(player, j) or sim.team_of(j) != sim.team_of(player) or sim.players[j]["defeated"]:
				continue
			if int(sim.players[j]["res"].get(kind, 0)) < int(cfg["falta"]):
				sim.push_command({"t": "tributo", "player": player, "a": j, "recurso": kind, "n": int(cfg["lote"])})
				return


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
	# Lo que falta para el hito se compra con la riqueza que sobra por encima de lo que pide el hito.
	if p["age"] < sim.dp(player).edades.size():
		var hc: Dictionary = sim.dp(player).cost_of(_hito_type(p), p["age"])
		var spare := int(res["riqueza"]) - int(hc.get("riqueza", 0))
		for k in ["piedra", "alimento", "madera"]:
			if int(res[k]) < int(hc.get(k, 0)) and spare >= sim.trade_price(player, k) + 50:
				sim.push_command({"t": "trade", "player": player, "building": m.id, "recurso": k, "op": "comprar"})
				return
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
## Camino de un edificio a la capital por búsqueda en anchura: rodea lo ocupado,
## aprovecha los caminos que ya existen y devuelve solo las casillas nuevas.
## Vacío si no hay paso (antes trazaba en línea recta y dejaba huecos: caso F).
func _road_tiles(from_b: SimEntity, to_b: SimEntity) -> Array:
	var n := sim.map.n
	var lo := Vector2i(maxi(0, mini(from_b.tx, to_b.tx) - 8), maxi(0, mini(from_b.ty, to_b.ty) - 8))
	var hi := Vector2i(mini(n - 1, maxi(from_b.tx + from_b.w, to_b.tx + to_b.w) + 8), mini(n - 1, maxi(from_b.ty + from_b.h, to_b.ty + to_b.h) + 8))
	var prev := {}
	var queue: Array[Vector2i] = []
	for t in _ring(from_b):
		if _road_ok(t):
			prev[t] = t
			queue.append(t)
	var goal := {}
	for t in _ring(to_b):
		goal[t] = true
	var head := 0
	var end := Vector2i(-1, -1)
	while head < queue.size():
		var c: Vector2i = queue[head]
		head += 1
		if goal.has(c):
			end = c
			break
		for d: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			var q: Vector2i = c + d
			if q.x < lo.x or q.y < lo.y or q.x > hi.x or q.y > hi.y or prev.has(q) or not _road_ok(q):
				continue
			prev[q] = c
			queue.append(q)
	var out := []
	if end.x < 0:
		return out
	var cur := end
	while true:
		if not _is_road(cur):
			out.append([cur.x, cur.y])
		var back: Vector2i = prev[cur]
		if back == cur:
			break
		cur = back
	return out


func _ring(b: SimEntity) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	for x in range(b.tx, b.tx + b.w):
		out.append(Vector2i(x, b.ty - 1))
		out.append(Vector2i(x, b.ty + b.h))
	for y in range(b.ty, b.ty + b.h):
		out.append(Vector2i(b.tx - 1, y))
		out.append(Vector2i(b.tx + b.w, y))
	return out


func _is_road(t: Vector2i) -> bool:
	var id := sim.map.occupant(t.x, t.y)
	var e: SimEntity = sim.by_id.get(id) if id >= 0 else null
	return e != null and e.type == "camino"


func _road_ok(t: Vector2i) -> bool:
	return _is_road(t) or sim.can_place("camino", t.x, t.y, player)
