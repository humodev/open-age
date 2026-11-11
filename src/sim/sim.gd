class_name Sim
extends RefCounted
## Simulación determinista. No usa nodos ni tiempo real (docs/06-arquitectura.md).

const P := 1000
const EC := 4000 # tamaño de celda de la tabla de búsqueda de enemigos
const INTERACT := 420 # distancia extra para recolectar, construir y entregar
const O := SimEntity.Order
const RES_KINDS: Array[String] = ["alimento", "madera", "piedra", "riqueza"]

var data: SimData
var tick: int = 0
var tick_ms: int
var map: SimMap
var rng: SimRng
var entities: Array[SimEntity] = [] # todas, en orden de id
var actives: Array[SimEntity] = [] # unidades y edificios, en orden de id
var by_id := {}
var next_id := 1
var players: Array[Dictionary] = []
var bases: Array[Vector2i] = []
var ais: Array = []
var events: Array[Dictionary] = []
var game_over := false
var winner := -1

var _pending := {} # tick -> Array[Dictionary]
var _in_step := false
var _grid := {} # celda de 1 casilla -> unidades (separación)
var _ehash := {} # celda de EC -> unidades y edificios (búsqueda)
var _res_cells := {} # celda de RC casillas -> recursos
var _dirty := false
const RC := 8


func _init(seed_value: int, num_players: int = 2, data_override: SimData = null) -> void:
	data = data_override if data_override != null else SimData.load_default()
	tick_ms = data.reglas["tick_ms"]
	rng = SimRng.new(seed_value)
	map = SimMap.new(data.reglas["mapa_tam"])
	for i in num_players:
		players.append({
			"id": i,
			"res": (data.reglas["recursos_iniciales"] as Dictionary).duplicate(),
			"age": 1,
			"pop": 0,
			"pop_cap": 0,
			"defeated": false,
			"alert_tick": -100000,
			"stats": {"recolectado": 0, "entrenadas": 0, "bajas": 0, "muertes": 0},
			"techs": {}, # investigaciones terminadas
			"pending": {}, # investigaciones en cola
			"mods": {}, # modificadores acumulados (docs/05, "Investigaciones")
			"alarm": false,
		})
	_generate_map()
	_update_players()


# ---------------------------------------------------------------- Comandos

## Programa un comando. Desde la IA (dentro de un tick) entra en el tick siguiente.
func push_command(cmd: Dictionary, delay: int = 0) -> void:
	var at := tick + delay
	if _in_step:
		at = maxi(at, tick + 1)
	cmd["tick"] = at
	if not _pending.has(at):
		_pending[at] = []
	_pending[at].append(cmd)


func _apply(c: Dictionary) -> void:
	var pid: int = c.get("player", -1)
	if pid < 0 or pid >= players.size() or players[pid]["defeated"]:
		return
	match c["t"]:
		"move":
			_cmd_move(pid, _own_units(pid, c.get("ids", [])), c["x"], c["y"], c.get("amove", false))
		"target":
			_cmd_target(pid, _own_units(pid, c.get("ids", [])), c["target"])
		"build":
			_cmd_build(pid, _own_units(pid, c.get("ids", [])), c["type"], c["tx"], c["ty"])
		"train":
			_cmd_train(pid, c["building"], c["type"])
		"cancel":
			_cmd_cancel(pid, c["building"], c.get("index", -1))
		"rally":
			_cmd_rally(pid, c["building"], c["x"], c["y"], c.get("target", -1))
		"research":
			_cmd_research(pid, c["building"], c["tech"])
		"garrison":
			_cmd_garrison(pid, _own_units(pid, c.get("ids", [])), c.get("building", -1))
		"ungarrison":
			_cmd_ungarrison(pid, c["building"])
		"alarm":
			_cmd_alarm(pid, c.get("on", true))
		"stop":
			for e in _own_units(pid, c.get("ids", [])):
				_set_idle(e)
		"delete":
			for id in c.get("ids", []):
				var e: SimEntity = by_id.get(id)
				if e != null and e.owner == pid and not e.is_resource():
					if e.is_building() and not e.built:
						_refund(pid, data.cost_of(e.type, players[pid]["age"]))
					_kill(e)
		"resign":
			_defeat(pid)


func _own_units(pid: int, ids: Array) -> Array[SimEntity]:
	var out: Array[SimEntity] = []
	var sorted := ids.duplicate()
	sorted.sort()
	for id in sorted:
		var e: SimEntity = by_id.get(id)
		if e != null and e.alive and e.owner == pid and e.is_unit() and e.inside < 0:
			out.append(e)
	return out


func _cmd_move(_pid: int, units: Array[SimEntity], x: int, y: int, amove: bool) -> void:
	var n := units.size()
	if n == 0:
		return
	var cols := 1
	while cols * cols < n:
		cols += 1
	var rows := (n + cols - 1) / cols
	var sp := 750
	for i in n:
		var e := units[i]
		var gx := x + (i % cols) * sp - (cols - 1) * sp / 2
		var gy := y + (i / cols) * sp - (rows - 1) * sp / 2
		var t := map.nearest_free(clampi(gx / P, 0, map.n - 1), clampi(gy / P, 0, map.n - 1), 8)
		if t.x >= 0 and map.is_solid(gx / P, gy / P):
			gx = t.x * P + P / 2
			gy = t.y * P + P / 2
		e.target = -1
		e.resume_amove = false
		e.order = O.ATTACK_MOVE if amove else O.MOVE
		e.amove_x = gx
		e.amove_y = gy
		_set_goal(e, gx, gy)


func _cmd_target(pid: int, units: Array[SimEntity], target_id: int) -> void:
	var t: SimEntity = by_id.get(target_id)
	if t == null or not t.alive:
		return
	var plain: Array[SimEntity] = []
	for e in units:
		if t.owner >= 0 and t.owner != pid:
			_order_attack(e, t)
		elif t.is_resource():
			if e.fn == "civil":
				_order_gather(e, t)
			else:
				plain.append(e)
		elif t.is_building() and t.owner == pid:
			if e.fn == "civil" and (not t.built or t.hp < t.hp_max):
				_order_build(e, t)
			elif e.fn == "civil" and t.def.get("fuente", "") != "":
				_order_gather(e, t)
			elif e.fn == "civil" and e.carry > 0 and _accepts(t, e.carry_res):
				e.order = O.RETURN
				e.aux = t.id
				e.path_target = -1
			elif garrison_cap(t) > 0:
				e.order = O.GARRISON
				e.target = t.id
				e.path_target = -1
			else:
				plain.append(e)
		else:
			plain.append(e)
	if plain.size() > 0:
		_cmd_move(pid, plain, t.x, t.y, false)


func _cmd_build(pid: int, units: Array[SimEntity], type: String, tx: int, ty: int) -> void:
	var p := players[pid]
	if not data.edificios.has(type):
		return
	var def: Dictionary = data.edificios[type]
	if p["age"] < def.get("edad_min", 1):
		_notify(pid, "Requiere edad %s" % _roman(def.get("edad_min", 1)))
		return
	if def.get("avanza_edad", false):
		if p["age"] >= data.edades.size():
			return
		if hito_in_progress(pid):
			_notify(pid, "Ya hay un hito en obra")
			return
	var cost := data.cost_of(type, p["age"])
	if not can_afford(pid, cost):
		_notify(pid, "Recursos insuficientes")
		return
	if not can_place(type, tx, ty):
		_notify(pid, "No se puede construir ahí")
		return
	_pay(pid, cost)
	var b := spawn_building(type, pid, tx, ty, false)
	b.build_time = data.build_time_of(type, p["age"])
	events.append({"t": "placed", "id": b.id, "player": pid})
	for e in units:
		if e.fn == "civil":
			_order_build(e, b)


func _cmd_train(pid: int, bid: int, type: String) -> void:
	var b: SimEntity = by_id.get(bid)
	if b == null or not b.alive or b.owner != pid or not b.built:
		return
	if not (b.def.get("produce", []) as Array).has(type):
		return
	var p := players[pid]
	if p["age"] < data.unidades[type].get("edad_min", 1):
		_notify(pid, "Requiere edad %s" % _roman(data.unidades[type]["edad_min"]))
		return
	if b.queue.size() >= data.reglas["cola_max"]:
		_notify(pid, "Cola llena")
		return
	var cost := data.cost_of(type, p["age"])
	if not can_afford(pid, cost):
		_notify(pid, "Recursos insuficientes")
		return
	_pay(pid, cost)
	b.queue.append(type)


func _cmd_cancel(pid: int, bid: int, index: int) -> void:
	var b: SimEntity = by_id.get(bid)
	if b == null or not b.alive or b.owner != pid or b.queue.is_empty():
		return
	if index < 0 or index >= b.queue.size():
		index = b.queue.size() - 1
	var type: String = b.queue[index]
	b.queue.remove_at(index)
	if index == 0:
		b.queue_progress = 0
	if type.begins_with("@"):
		players[pid]["pending"].erase(type.substr(1))
		type = type.substr(1)
	_refund(pid, data.cost_of(type, players[pid]["age"]))


## ¿Se puede investigar `tech` ahora? Devuelve "" o el motivo.
func research_block(pid: int, tech: String) -> String:
	var t: Dictionary = data.tecnologias.get(tech, {})
	var p := players[pid]
	if t.is_empty():
		return "Desconocida"
	if p["techs"].has(tech):
		return "Ya investigada"
	if p["pending"].has(tech):
		return "En investigación"
	if t.has("requiere") and not p["techs"].has(t["requiere"]):
		return "Requiere %s" % data.tecnologias[t["requiere"]]["nombre"]
	if p["age"] < t.get("edad_min", 1):
		return "Requiere edad %s" % _roman(t["edad_min"])
	return ""


func _cmd_research(pid: int, bid: int, tech: String) -> void:
	var b: SimEntity = by_id.get(bid)
	if b == null or not b.alive or b.owner != pid or not b.built:
		return
	var t: Dictionary = data.tecnologias.get(tech, {})
	if t.is_empty() or t["edificio"] != b.type:
		return
	var why := research_block(pid, tech)
	if why != "":
		_notify(pid, why)
		return
	if b.queue.size() >= data.reglas["cola_max"]:
		_notify(pid, "Cola llena")
		return
	if not can_afford(pid, t["costo"]):
		_notify(pid, "Recursos insuficientes")
		return
	_pay(pid, t["costo"])
	players[pid]["pending"][tech] = true
	b.queue.append("@" + tech)


func _cmd_garrison(_pid: int, units: Array[SimEntity], bid: int) -> void:
	for e in units:
		e.order = O.GARRISON
		e.target = bid
		e.path_target = -1


func _cmd_ungarrison(pid: int, bid: int) -> void:
	var b: SimEntity = by_id.get(bid)
	if b == null or b.owner != pid:
		return
	_eject(b)


## Campana: los aldeanos cercanos se refugian; al apagarla vuelven a trabajar.
func _cmd_alarm(pid: int, on: bool) -> void:
	players[pid]["alarm"] = on
	if not on:
		for e in actives:
			if e.alive and e.owner == pid and e.fn == "civil" and e.order == O.GARRISON:
				_set_idle(e)
				var res := find_resource(pid, e.gather_kind, e.x, e.y, data.reglas["radio_retomar"], -1, e.id) if e.gather_kind != "" else null
				if res != null:
					_order_gather(e, res)
		for b in actives:
			if b.alive and b.owner == pid and b.is_building() and not b.garrison.is_empty():
				_eject(b)
		return
	var radius: int = data.reglas["radio_campana"]
	for e in actives:
		if e.alive and e.owner == pid and e.fn == "civil" and e.inside < 0:
			var b := nearest_shelter(pid, e.x, e.y, e.id)
			if b != null and dist_to(e, b) <= radius:
				e.order = O.GARRISON
				e.target = b.id
				e.path_target = -1
	events.append({"t": "alarm", "player": pid})


func garrison_cap(b: SimEntity) -> int:
	return int(b.def.get("guarnicion", 0)) if b.built else 0


## Edificio propio con lugar libre más cercano, contando a quienes ya van en camino.
func nearest_shelter(pid: int, x: int, y: int, exclude_walker: int = -1) -> SimEntity:
	var incoming := {}
	for e in actives:
		if e.alive and e.owner == pid and e.order == O.GARRISON and e.id != exclude_walker and e.target >= 0:
			incoming[e.target] = incoming.get(e.target, 0) + 1
	var best: SimEntity = null
	var best_d := 1 << 60
	var probe := SimEntity.new()
	probe.x = x
	probe.y = y
	for b in actives:
		if not b.alive or b.owner != pid or not b.is_building():
			continue
		if b.garrison.size() + int(incoming.get(b.id, 0)) >= garrison_cap(b):
			continue
		var d := dist_to(probe, b)
		if d < best_d:
			best = b
			best_d = d
	return best


func _do_garrison(e: SimEntity) -> void:
	var b: SimEntity = by_id.get(e.target)
	if b == null or not b.alive or b.owner != e.owner or b.garrison.size() >= garrison_cap(b):
		b = nearest_shelter(e.owner, e.x, e.y, e.id)
		if b == null:
			_set_idle(e)
			return
		e.target = b.id
		e.path_target = -1
	if not _approach(e, b, e.radius + INTERACT):
		if e.stuck > 25:
			_set_idle(e)
		return
	e.inside = b.id
	e.order = O.IDLE
	e.path.clear()
	e.x = b.x
	e.y = b.y
	b.garrison.append(e.id)
	events.append({"t": "garrison", "id": e.id, "building": b.id})


## Saca a todas las unidades alojadas. Los aldeanos vuelven a recolectar.
func _eject(b: SimEntity) -> void:
	var ids := b.garrison.duplicate()
	b.garrison.clear()
	for id in ids:
		var e: SimEntity = by_id.get(id)
		if e == null or not e.alive:
			continue
		e.inside = -1
		var tile := _spawn_tile(b)
		e.x = tile.x * P + P / 2
		e.y = tile.y * P + P / 2
		_set_idle(e)
		if e.fn == "civil" and e.gather_kind != "":
			var res := find_resource(e.owner, e.gather_kind, e.x, e.y, data.reglas["radio_retomar"], -1, e.id)
			if res != null:
				_order_gather(e, res)
		events.append({"t": "ungarrison", "id": e.id})


# ---------------------------------------------------------------- Modificadores

func mod(pid: int, key: String) -> int:
	if pid < 0:
		return 0
	return players[pid]["mods"].get(key, 0)


func _add_mod(pid: int, key: String, v: int) -> void:
	players[pid]["mods"][key] = mod(pid, key) + v


func _apply_effects(pid: int, efectos: Array) -> void:
	for ef: Dictionary in efectos:
		match ef["tipo"]:
			"tasa":
				var keys: Array = ["alimento", "granja", "madera", "piedra", "riqueza"] if ef["recurso"] == "*" else [ef["recurso"]]
				for k in keys:
					_add_mod(pid, "tasa:" + k, ef["pct"])
			"carga":
				_add_mod(pid, "carga", ef["n"])
			"ataque":
				for f in ef["funciones"]:
					_add_mod(pid, "ataque:" + f, ef["n"])
			"armadura":
				for f in ef["funciones"]:
					_add_mod(pid, "armadura:" + f, ef["n"])
			"vida_pct":
				for f in ef["funciones"]:
					_add_mod(pid, "vida:" + f, ef["pct"])
			"velocidad_pct":
				for f in ef["funciones"]:
					_add_mod(pid, "vel:" + f, ef["pct"])
			"edificio_vida_pct":
				_add_mod(pid, "b_vida", ef["pct"])
			"edificio_ataque":
				_add_mod(pid, "b_ataque", ef["n"])
			"edificio_alcance":
				_add_mod(pid, "b_alcance", ef["n"])
	for e in actives:
		if e.alive and e.owner == pid:
			_apply_stats(e)


## Vida máxima y velocidad según datos y modificadores; conserva la proporción de vida.
func _apply_stats(e: SimEntity) -> void:
	var base: int = e.def["pv"]
	var pct := mod(e.owner, "b_vida") if e.is_building() else mod(e.owner, "vida:" + e.fn)
	var new_max := base * (100 + pct) / 100
	if e.hp_max > 0 and new_max != e.hp_max:
		e.hp = maxi(1, e.hp * new_max / e.hp_max)
	e.hp_max = new_max
	if e.is_unit():
		e.speed = int(e.def["velocidad"]) * (100 + mod(e.owner, "vel:" + e.fn)) / 100 * tick_ms / 1000


func _cmd_rally(pid: int, bid: int, x: int, y: int, target_id: int) -> void:
	var b: SimEntity = by_id.get(bid)
	if b == null or not b.alive or b.owner != pid:
		return
	b.rally_set = true
	b.rally_x = x
	b.rally_y = y
	b.rally_target = target_id


# ---------------------------------------------------------------- Paso

func step() -> void:
	_in_step = true
	events.clear()
	var cmds: Array = _pending.get(tick, [])
	_pending.erase(tick)
	for c in cmds:
		_apply(c)
	for ai in ais:
		if (tick + ai.player * 5) % 10 == 0 and not players[ai.player]["defeated"]:
			ai.think()
	_rebuild_hashes()
	_update_players()
	var count := actives.size()
	for i in count:
		var e := actives[i]
		if not e.alive:
			continue
		if e.is_unit():
			if e.inside < 0:
				_update_unit(e)
		elif e.is_building():
			_update_building(e)
	_separate()
	if _dirty:
		_cleanup()
	if tick % 10 == 5 and not game_over:
		_check_victory()
	tick += 1
	_in_step = false


func _update_players() -> void:
	for p in players:
		p["pop"] = 0
		p["pop_cap"] = 0
	for e in actives:
		if not e.alive or e.owner < 0:
			continue
		if e.is_unit():
			players[e.owner]["pop"] += e.def.get("pob", 1)
		elif e.is_building() and e.built:
			players[e.owner]["pop_cap"] += e.def.get("pob", 0)
	for p in players:
		p["pop_cap"] = mini(p["pop_cap"], data.reglas["pob_max"])


func _rebuild_hashes() -> void:
	_grid.clear()
	_ehash.clear()
	for e in actives:
		if not e.alive or e.inside >= 0:
			continue
		if e.is_unit():
			var k := (e.x / P) * 4096 + e.y / P
			if not _grid.has(k):
				_grid[k] = []
			_grid[k].append(e)
			var ek := (e.x / EC) * 1024 + e.y / EC
			if not _ehash.has(ek):
				_ehash[ek] = []
			_ehash[ek].append(e)
		elif e.is_building():
			for cx in range(e.tx * P / EC, ((e.tx + e.w) * P - 1) / EC + 1):
				for cy in range(e.ty * P / EC, ((e.ty + e.h) * P - 1) / EC + 1):
					var ek := cx * 1024 + cy
					if not _ehash.has(ek):
						_ehash[ek] = []
					_ehash[ek].append(e)


# ---------------------------------------------------------------- Unidades

func _update_unit(e: SimEntity) -> void:
	if e.cooldown > 0:
		e.cooldown -= tick_ms
	match e.order:
		O.IDLE:
			_do_idle(e)
		O.MOVE:
			e.anchored = false
			if _follow(e):
				_set_idle(e)
		O.ATTACK_MOVE:
			e.anchored = false
			if (tick + e.id) % 3 == 0:
				var t := find_enemy(e, e.def["vision"], false)
				if t != null:
					e.order = O.ATTACK
					e.target = t.id
					e.resume_amove = true
					e.path_target = -1
					return
			if _follow(e):
				_set_idle(e)
		O.ATTACK:
			_do_attack(e)
		O.GATHER:
			_do_gather(e)
		O.RETURN:
			_do_return(e)
		O.BUILD:
			_do_build(e)
		O.GARRISON:
			_do_garrison(e)


func _set_idle(e: SimEntity) -> void:
	e.order = O.IDLE
	e.target = -1
	e.path.clear()
	e.path_i = 0
	e.path_target = -1
	e.anchored = false
	e.resume_amove = false


func _do_idle(e: SimEntity) -> void:
	e.anchored = false
	if e.is_military() and (tick + e.id) % 4 == 0:
		var t := find_enemy(e, e.def["vision"], false)
		if t != null:
			_order_attack(e, t)


func _order_attack(e: SimEntity, t: SimEntity) -> void:
	e.order = O.ATTACK
	e.target = t.id
	e.path_target = -1
	e.resume_amove = false


func _order_gather(e: SimEntity, t: SimEntity) -> void:
	e.order = O.GATHER
	e.target = t.id
	e.path_target = -1
	e.gather_kind = resource_kind_of(t)


func _order_build(e: SimEntity, b: SimEntity) -> void:
	e.order = O.BUILD
	e.target = b.id
	e.path_target = -1


func _do_attack(e: SimEntity) -> void:
	var t: SimEntity = by_id.get(e.target)
	if t == null or not t.alive:
		if e.resume_amove:
			e.order = O.ATTACK_MOVE
			e.target = -1
			_set_goal(e, e.amove_x, e.amove_y)
		else:
			_set_idle(e)
			_do_idle(e)
		return
	var reach: int = e.def["alcance"]
	if _approach(e, t, reach):
		e.anchored = true
		if e.cooldown <= 0:
			_hit(e, t)
			e.cooldown = e.def["cadencia_ms"]
	elif e.stuck > 25:
		_set_idle(e)


func _do_gather(e: SimEntity) -> void:
	var cap: int = int(e.def.get("carga", 10)) + mod(e.owner, "carga")
	var t: SimEntity = by_id.get(e.target)
	if not _valid_source(e, t):
		t = find_resource(e.owner, e.gather_kind, e.x, e.y, data.reglas["radio_rebusca"], -1, e.id)
		if t == null:
			if e.carry > 0:
				e.order = O.RETURN
				e.aux = -1
				e.path_target = -1
			else:
				_set_idle(e)
			return
		e.target = t.id
		e.path_target = -1
	var kind := resource_kind_of(t)
	if e.carry >= cap or (e.carry > 0 and e.carry_res != kind):
		e.order = O.RETURN
		e.aux = -1
		e.path_target = -1
		return
	var in_range: bool
	if t.def.get("transitable", false):
		in_range = _approach(e, t, 0)
	else:
		in_range = _approach(e, t, e.radius + INTERACT)
	if not in_range:
		if e.stuck > 25:
			var alt := find_resource(e.owner, e.gather_kind, e.x, e.y, data.reglas["radio_rebusca"], t.id, e.id)
			if alt != null:
				e.target = alt.id
				e.path_target = -1
			else:
				_set_idle(e)
		return
	e.anchored = true
	if t.is_building():
		t.farmer = e.id
	var rate_key: String = "granja" if t.is_building() else kind
	var rate: int = int(e.def["tasa"].get(rate_key, 0)) * (100 + mod(e.owner, "tasa:" + rate_key)) / 100
	e.carry_res = kind
	e.gather_acc += rate * tick_ms / 1000
	while e.gather_acc >= 1000 and e.carry < cap:
		e.gather_acc -= 1000
		e.carry += 1
		if t.is_resource():
			t.amount -= 1
			if t.amount <= 0:
				_kill(t)
				break


func _do_return(e: SimEntity) -> void:
	var d: SimEntity = by_id.get(e.aux)
	if d == null or not d.alive or not d.built or not _accepts(d, e.carry_res):
		d = nearest_dropoff(e.owner, e.carry_res, e.x, e.y)
		if d == null:
			_set_idle(e)
			return
		e.aux = d.id
		e.path_target = -1
	if not _approach(e, d, e.radius + INTERACT):
		if e.stuck > 25:
			_set_idle(e)
		return
	players[e.owner]["res"][e.carry_res] += e.carry
	players[e.owner]["stats"]["recolectado"] += e.carry
	events.append({"t": "deposit", "id": e.id, "res": e.carry_res, "n": e.carry})
	e.carry = 0
	e.gather_acc = 0
	e.order = O.GATHER
	e.path_target = -1


func _do_build(e: SimEntity) -> void:
	var b: SimEntity = by_id.get(e.target)
	if b == null or not b.alive or (b.built and b.hp >= b.hp_max):
		if b != null and b.alive and b.built and b.def.get("fuente", "") != "" and _farm_free(b, e.id):
			_order_gather(e, b)
			return
		var next := _nearest_unbuilt(e.owner, e.x, e.y, 10000)
		if next != null:
			_order_build(e, next)
			return
		# Vuelve a lo que recolectaba antes de construir.
		var res: SimEntity = null
		if e.gather_kind != "":
			res = find_resource(e.owner, e.gather_kind, e.x, e.y, data.reglas["radio_retomar"], -1, e.id)
		if res != null:
			_order_gather(e, res)
		else:
			_set_idle(e)
		return
	if not _approach(e, b, e.radius + INTERACT):
		if e.stuck > 25:
			_set_idle(e)
		return
	e.anchored = true
	if b.built:
		# Reparación: a la velocidad de construcción, sin costo en H1.
		var t_rep: int = maxi(1, data.build_time_of(b.type, 1))
		b.hp = mini(b.hp_max, b.hp + maxi(1, b.hp_max * tick_ms / t_rep))
		return
	if b.build_time <= 0:
		_complete(b)
		return
	# La vida sube en proporción exacta al progreso; el daño recibido se conserva.
	var before := (b.hp_max - 1) * b.progress / b.build_time
	b.progress = mini(b.build_time, b.progress + tick_ms)
	var after := (b.hp_max - 1) * b.progress / b.build_time
	b.hp = mini(b.hp_max, b.hp + after - before)
	if b.progress >= b.build_time:
		_complete(b)


func _complete(b: SimEntity) -> void:
	b.built = true
	b.progress = b.build_time
	events.append({"t": "built", "id": b.id, "player": b.owner})
	_apply_stats(b)
	if b.def.get("avanza_edad", false):
		var p := players[b.owner]
		p["age"] = mini(data.edades.size(), p["age"] + 1)
		_apply_effects(b.owner, b.def.get("efectos", []))
		events.append({"t": "age", "player": b.owner, "age": p["age"], "hito": b.type})


func _hit(a: SimEntity, t: SimEntity) -> void:
	var atk: int = a.def.get("ataque", 0)
	if a.is_building():
		atk += mod(a.owner, "b_ataque")
	else:
		atk += mod(a.owner, "ataque:" + a.fn)
	if a.owner >= 0 and (a.is_military() or a.is_building()):
		var bonus: int = data.edades[players[a.owner]["age"] - 1].get("bono_ataque", 0)
		atk = atk * (100 + bonus) / 100
	var mult: int = data.reglas["contadores"].get(a.fn, {}).get(t.fn, 100)
	var armor: int = int(t.def.get("armadura", 0)) + (mod(t.owner, "armadura:" + t.fn) if t.is_unit() else 0)
	var dmg := maxi(data.reglas["danio_minimo"], atk * mult / 100 - armor)
	t.hp -= dmg
	var ranged: bool = a.def.get("alcance", 0) > 1500
	events.append({"t": "hit", "a": a.id, "b": t.id, "ranged": ranged, "dmg": dmg})
	if t.owner >= 0:
		if t.is_unit() and t.is_military() and t.order == O.IDLE:
			_order_attack(t, a)
		var p := players[t.owner]
		if tick - p["alert_tick"] > 150:
			p["alert_tick"] = tick
			events.append({"t": "alert", "player": t.owner, "x": t.x, "y": t.y})
	if t.hp <= 0:
		if t.owner >= 0:
			players[t.owner]["stats"]["muertes"] += 1
		if a.owner >= 0:
			players[a.owner]["stats"]["bajas"] += 1
		_kill(t)


func _kill(e: SimEntity) -> void:
	if not e.alive:
		return
	e.alive = false
	e.hp = 0
	_dirty = true
	if e.is_building() or e.is_resource():
		map.clear(e.tx, e.ty, e.w, e.h)
	if e.is_building():
		_eject(e)
		for item in e.queue:
			if item.begins_with("@"):
				players[e.owner]["pending"].erase(item.substr(1))
	events.append({"t": "died", "id": e.id})


func _cleanup() -> void:
	_dirty = false
	var keep: Array[SimEntity] = []
	for e in entities:
		if e.alive:
			keep.append(e)
		else:
			by_id.erase(e.id)
	entities = keep
	var keep_a: Array[SimEntity] = []
	for e in actives:
		if e.alive:
			keep_a.append(e)
	actives = keep_a


# ---------------------------------------------------------------- Edificios

func _update_building(b: SimEntity) -> void:
	if not b.built:
		return
	if not b.queue.is_empty():
		var item: String = b.queue[0]
		var p := players[b.owner]
		var is_tech := item.begins_with("@")
		if not is_tech and b.queue_progress == 0 and p["pop"] + int(data.unidades[item].get("pob", 1)) > p["pop_cap"]:
			if (tick + b.id) % 100 == 0:
				_notify(b.owner, "Población llena")
		else:
			b.queue_progress += tick_ms
			if b.queue_progress >= data.queue_time(item):
				b.queue.remove_at(0)
				b.queue_progress = 0
				if is_tech:
					_finish_tech(b.owner, item.substr(1))
				else:
					_spawn_from(b, item)
	if b.def.has("ataque"):
		if b.cooldown > 0:
			b.cooldown -= tick_ms
		else:
			# Andanada: flechas propias más una por unidad alojada.
			var reach: int = int(b.def["alcance"]) + mod(b.owner, "b_alcance")
			var shots: int = int(b.def.get("flechas", 1)) + b.garrison.size()
			var t := find_enemy(b, reach, true)
			if t != null:
				for i in shots:
					if not t.alive:
						t = find_enemy(b, reach, true)
						if t == null:
							break
					_hit(b, t)
				b.cooldown = b.def["cadencia_ms"]


func _finish_tech(pid: int, tech: String) -> void:
	var p := players[pid]
	p["pending"].erase(tech)
	p["techs"][tech] = true
	_apply_effects(pid, data.tecnologias[tech]["efectos"])
	events.append({"t": "tech", "player": pid, "tech": tech})


func _spawn_from(b: SimEntity, type: String) -> void:
	var tile := _spawn_tile(b)
	var u := spawn_unit(type, b.owner, tile.x * P + P / 2, tile.y * P + P / 2)
	players[b.owner]["stats"]["entrenadas"] += 1
	events.append({"t": "trained", "id": u.id, "player": b.owner})
	if not b.rally_set:
		return
	var rt: SimEntity = by_id.get(b.rally_target)
	if rt != null and rt.alive and u.fn == "civil" and (rt.is_resource() or (rt.is_building() and rt.owner == b.owner and rt.def.get("fuente", "") != "")):
		_order_gather(u, rt)
	elif rt != null and rt.alive and u.fn == "civil" and rt.is_building() and rt.owner == b.owner and not rt.built:
		_order_build(u, rt)
	else:
		_cmd_move(b.owner, [u] as Array[SimEntity], b.rally_x, b.rally_y, u.is_military())


func _spawn_tile(b: SimEntity) -> Vector2i:
	for r in range(1, 6):
		for xx in range(b.tx - r, b.tx + b.w + r):
			if not map.is_solid(xx, b.ty + b.h - 1 + r):
				return Vector2i(xx, b.ty + b.h - 1 + r)
		for yy in range(b.ty - r, b.ty + b.h + r):
			if not map.is_solid(b.tx + b.w - 1 + r, yy):
				return Vector2i(b.tx + b.w - 1 + r, yy)
			if not map.is_solid(b.tx - r, yy):
				return Vector2i(b.tx - r, yy)
		for xx in range(b.tx - r, b.tx + b.w + r):
			if not map.is_solid(xx, b.ty - r):
				return Vector2i(xx, b.ty - r)
	return Vector2i(b.tx, b.ty + b.h)


# ---------------------------------------------------------------- Movimiento

func _set_goal(e: SimEntity, gx: int, gy: int, target_id: int = -1) -> void:
	gx = clampi(gx, 100, map.n * P - 100)
	gy = clampi(gy, 100, map.n * P - 100)
	e.goal_x = gx
	e.goal_y = gy
	e.path_target = target_id
	e.path_tick = tick
	e.stuck = 0
	var from := Vector2i(e.x / P, e.y / P)
	var to := Vector2i(gx / P, gy / P)
	if map.is_solid(from.x, from.y):
		var f2 := map.nearest_free(from.x, from.y, 6)
		e.path = [from] as Array[Vector2i]
		if f2.x >= 0:
			e.path.append_array(map.find_path(f2, to))
		e.path_i = 1
	else:
		e.path = map.find_path(from, to)
		e.path_i = 1


## Avanza por el camino. Devuelve true al llegar (o al rendirse si está trabado).
func _follow(e: SimEntity) -> bool:
	if e.stuck > 15:
		return true
	var goal_tile := Vector2i(e.goal_x / P, e.goal_y / P)
	while e.path_i < e.path.size():
		var wp := e.path[e.path_i]
		var last := e.path_i == e.path.size() - 1
		var px := wp.x * P + P / 2
		var py := wp.y * P + P / 2
		if last and wp == goal_tile and not map.is_solid(wp.x, wp.y):
			px = e.goal_x
			py = e.goal_y
		if not last and dist(e.x, e.y, px, py) < 380:
			e.path_i += 1
			continue
		if _step_toward(e, px, py):
			e.path_i += 1
			return e.path_i >= e.path.size()
		return false
	if map.is_solid(goal_tile.x, goal_tile.y):
		return true
	return _step_toward(e, e.goal_x, e.goal_y)


## Avanza en línea recta. Devuelve true si llegó al punto.
func _step_toward(e: SimEntity, px: int, py: int) -> bool:
	var dx := px - e.x
	var dy := py - e.y
	var d := isqrt(dx * dx + dy * dy)
	if d == 0:
		return true
	var nx := px
	var ny := py
	if d > e.speed:
		nx = e.x + dx * e.speed / d
		ny = e.y + dy * e.speed / d
	var moved := _try_move(e, nx, ny)
	if moved == 2:
		e.stuck = 0
		return d <= e.speed
	if moved == 0:
		e.stuck += 1
	return false


## 2 = movimiento completo, 1 = deslizó por un eje, 0 = bloqueado.
func _try_move(e: SimEntity, nx: int, ny: int) -> int:
	var lim := map.n * P - 50
	nx = clampi(nx, 50, lim)
	ny = clampi(ny, 50, lim)
	if map.is_solid(e.x / P, e.y / P) or not map.is_solid(nx / P, ny / P):
		e.x = nx
		e.y = ny
		return 2
	if not map.is_solid(nx / P, e.y / P):
		e.x = nx
		return 1
	if not map.is_solid(e.x / P, ny / P):
		e.y = ny
		return 1
	return 0


## Se acerca a la entidad hasta `reach`. Devuelve true si ya está en alcance.
func _approach(e: SimEntity, t: SimEntity, reach: int) -> bool:
	var d := dist_to(e, t)
	if d <= reach:
		e.path.clear()
		e.path_i = 0
		e.stuck = 0
		return true
	e.anchored = false
	if t.is_unit():
		if d < 2500:
			_step_toward(e, t.x, t.y)
			return false
		var ttile := Vector2i(t.x / P, t.y / P)
		if e.path_target != t.id or (tick - e.path_tick >= 8 and ttile != Vector2i(e.goal_x / P, e.goal_y / P)):
			_set_goal(e, t.x, t.y, t.id)
		_follow(e)
		return false
	if e.path_target != t.id:
		_set_goal(e, t.x, t.y, t.id)
	if _follow(e):
		var cx := clampi(e.x, t.tx * P, (t.tx + t.w) * P)
		var cy := clampi(e.y, t.ty * P, (t.ty + t.h) * P)
		_step_toward(e, cx, cy)
	return false


func _separate() -> void:
	for e in actives:
		if not e.alive or not e.is_unit() or e.inside >= 0:
			continue
		var cx := e.x / P
		var cy := e.y / P
		for ox in range(cx - 1, cx + 2):
			for oy in range(cy - 1, cy + 2):
				var cell: Array = _grid.get(ox * 4096 + oy, [])
				for o: SimEntity in cell:
					if o.id <= e.id or not o.alive:
						continue
					var rr := e.radius + o.radius
					var dx := o.x - e.x
					var dy := o.y - e.y
					if absi(dx) >= rr or absi(dy) >= rr:
						continue
					var d2 := dx * dx + dy * dy
					if d2 >= rr * rr:
						continue
					var d := isqrt(d2)
					if d == 0:
						dx = 1 if (e.id & 1) == 0 else -1
						dy = 0
						d = 1
					var push := mini((rr - d), 160)
					var we := 50
					if e.anchored and not o.anchored:
						we = 15
					elif o.anchored and not e.anchored:
						we = 85
					var pe := push * we / 100
					var po := push - pe
					_try_move(o, o.x + dx * po / d, o.y + dy * po / d)
					_try_move(e, e.x - dx * pe / d, e.y - dy * pe / d)


# ---------------------------------------------------------------- Consultas

func find_enemy(e: SimEntity, radius: int, units_only: bool) -> SimEntity:
	var best: SimEntity = null
	var best_score := 1 << 60
	var x0 := maxi(0, (e.x - radius) / EC)
	var x1 := (e.x + radius) / EC
	var y0 := maxi(0, (e.y - radius) / EC)
	var y1 := (e.y + radius) / EC
	for cx in range(x0, x1 + 1):
		for cy in range(y0, y1 + 1):
			var cell: Array = _ehash.get(cx * 1024 + cy, [])
			for o: SimEntity in cell:
				if not o.alive or o.owner < 0 or o.owner == e.owner:
					continue
				if units_only and not o.is_unit():
					continue
				var d := dist_to(e, o)
				if d > radius:
					continue
				var score := d
				if not o.is_unit():
					score += 6000
				elif not o.is_military():
					score += 3000
				if score < best_score or (score == best_score and o.id < best.id):
					best = o
					best_score = score
	return best


func find_resource(owner: int, kind: String, x: int, y: int, max_d: int, exclude: int = -1, worker: int = -1) -> SimEntity:
	var best: SimEntity = null
	var best_d := max_d + 1
	var probe := SimEntity.new()
	probe.x = x
	probe.y = y
	if kind == "alimento":
		for t in actives:
			if t.alive and t.is_building() and t.owner == owner and t.built and t.id != exclude and t.def.get("fuente", "") == kind and _farm_free(t, worker):
				var d := dist_to(probe, t)
				if d < best_d:
					best = t
					best_d = d
	# Recursos del mapa: anillos de celdas hasta que no puedan mejorar.
	var cx := x / P / RC
	var cy := y / P / RC
	var max_r := max_d / P / RC + 1
	for r in range(0, max_r + 1):
		if best != null and (r - 1) * RC * P > best_d:
			break
		for dy in range(-r, r + 1):
			for dx in range(-r, r + 1):
				if absi(dx) != r and absi(dy) != r:
					continue
				var cell: Array = _res_cells.get((cx + dx) * 1024 + cy + dy, [])
				for t: SimEntity in cell:
					if not t.alive or t.id == exclude or t.res_kind != kind or t.amount <= 0:
						continue
					var d := dist_to(probe, t)
					if d < best_d or (d == best_d and best != null and t.id < best.id):
						if not map.has_free_neighbor(t.tx, t.ty, t.w, t.h):
							continue
						best = t
						best_d = d
	return best

func nearest_dropoff(owner: int, kind: String, x: int, y: int) -> SimEntity:
	var best: SimEntity = null
	var best_d := 1 << 60
	var probe := SimEntity.new()
	probe.x = x
	probe.y = y
	for b in actives:
		if not b.alive or not b.is_building() or b.owner != owner or not b.built:
			continue
		if not _accepts(b, kind):
			continue
		var d := dist_to(probe, b)
		if d < best_d:
			best = b
			best_d = d
	return best


func _nearest_unbuilt(owner: int, x: int, y: int, max_d: int) -> SimEntity:
	var best: SimEntity = null
	var best_d := max_d + 1
	var probe := SimEntity.new()
	probe.x = x
	probe.y = y
	for b in actives:
		if b.alive and b.is_building() and b.owner == owner and not b.built:
			var d := dist_to(probe, b)
			if d < best_d:
				best = b
				best_d = d
	return best


func _valid_source(e: SimEntity, t: SimEntity) -> bool:
	if t == null or not t.alive:
		return false
	if t.is_resource():
		return t.amount > 0
	return t.is_building() and t.owner == e.owner and t.built and t.def.get("fuente", "") != "" and _farm_free(t, e.id)


func _farm_free(farm: SimEntity, worker: int) -> bool:
	if farm.farmer == -1 or farm.farmer == worker:
		return true
	var f: SimEntity = by_id.get(farm.farmer)
	if f == null or not f.alive or f.target != farm.id or not (f.order == O.GATHER or f.order == O.RETURN):
		farm.farmer = -1
		return true
	return false


func _accepts(b: SimEntity, kind: String) -> bool:
	return b.built and (b.def.get("deposito", []) as Array).has(kind)


func resource_kind_of(t: SimEntity) -> String:
	if t.is_resource():
		return t.res_kind
	return t.def.get("fuente", "")


func dist_to(e: SimEntity, t: SimEntity) -> int:
	if t.is_unit():
		return maxi(0, dist(e.x, e.y, t.x, t.y) - t.radius)
	var cx := clampi(e.x, t.tx * P, (t.tx + t.w) * P)
	var cy := clampi(e.y, t.ty * P, (t.ty + t.h) * P)
	return dist(e.x, e.y, cx, cy)


static func dist(ax: int, ay: int, bx: int, by: int) -> int:
	var dx := bx - ax
	var dy := by - ay
	return isqrt(dx * dx + dy * dy)


## Raíz cuadrada entera con corrección (determinista).
static func isqrt(n: int) -> int:
	if n <= 0:
		return 0
	var r := int(sqrt(float(n)))
	while r * r > n:
		r -= 1
	while (r + 1) * (r + 1) <= n:
		r += 1
	return r


func can_afford(pid: int, cost: Dictionary) -> bool:
	var res: Dictionary = players[pid]["res"]
	for k in cost:
		if res.get(k, 0) < cost[k]:
			return false
	return true


func _pay(pid: int, cost: Dictionary) -> void:
	for k in cost:
		players[pid]["res"][k] -= cost[k]


func _refund(pid: int, cost: Dictionary) -> void:
	for k in cost:
		players[pid]["res"][k] += cost[k]


func can_place(type: String, tx: int, ty: int) -> bool:
	var tam: Array = data.edificios[type]["tam"]
	if tx < 0 or ty < 0 or tx + tam[0] > map.n or ty + tam[1] > map.n:
		return false
	return map.is_free_rect(tx, ty, tam[0], tam[1])


func hito_in_progress(pid: int) -> bool:
	for b in actives:
		if b.alive and b.owner == pid and b.def.get("avanza_edad", false) and not b.built:
			return true
	return false


func _notify(pid: int, msg: String) -> void:
	events.append({"t": "notify", "player": pid, "msg": msg})


static func _roman(n: int) -> String:
	return ["", "I", "II", "III", "IV"][clampi(n, 0, 4)]


# ---------------------------------------------------------------- Victoria

func _check_victory() -> void:
	var has_hito := []
	has_hito.resize(players.size())
	has_hito.fill(false)
	for b in actives:
		if b.alive and b.is_building() and b.owner >= 0 and b.built and b.def.get("hito", false):
			has_hito[b.owner] = true
	for p in players:
		if not p["defeated"] and not has_hito[p["id"]]:
			_defeat(p["id"])


func _defeat(pid: int) -> void:
	if players[pid]["defeated"]:
		return
	players[pid]["defeated"] = true
	events.append({"t": "defeat", "player": pid})
	var left := []
	for p in players:
		if not p["defeated"]:
			left.append(p["id"])
	if left.size() <= 1 and not game_over:
		game_over = true
		winner = left[0] if left.size() == 1 else -1
		events.append({"t": "victory", "player": winner})


# ---------------------------------------------------------------- Creación

func _new_entity(cat: int, type: String, owner: int, def: Dictionary) -> SimEntity:
	var e := SimEntity.new()
	e.id = next_id
	next_id += 1
	e.cat = cat
	e.type = type
	e.owner = owner
	e.def = def
	entities.append(e)
	if cat != SimEntity.Cat.RESOURCE:
		actives.append(e)
	by_id[e.id] = e
	return e


func spawn_unit(type: String, owner: int, x: int, y: int) -> SimEntity:
	var def: Dictionary = data.unidades[type]
	var e := _new_entity(SimEntity.Cat.UNIT, type, owner, def)
	e.x = x
	e.y = y
	e.fn = def["funcion"]
	e.radius = def["radio"]
	_apply_stats(e)
	e.hp = e.hp_max
	e.goal_x = x
	e.goal_y = y
	return e


func spawn_building(type: String, owner: int, tx: int, ty: int, built: bool) -> SimEntity:
	var def: Dictionary = data.edificios[type]
	var e := _new_entity(SimEntity.Cat.BUILDING, type, owner, def)
	e.tx = tx
	e.ty = ty
	e.w = def["tam"][0]
	e.h = def["tam"][1]
	e.x = tx * P + e.w * P / 2
	e.y = ty * P + e.h * P / 2
	e.fn = "edificio"
	_apply_stats(e)
	e.built = built
	e.hp = e.hp_max if built else 1
	e.build_time = data.build_time_of(type, players[owner]["age"]) if owner >= 0 else 0
	map.mark(tx, ty, e.w, e.h, e.id, not def.get("transitable", false))
	return e


func spawn_resource(type: String, tx: int, ty: int) -> SimEntity:
	var def: Dictionary = data.recursos[type]
	var e := _new_entity(SimEntity.Cat.RESOURCE, type, -1, def)
	e.tx = tx
	e.ty = ty
	e.w = def["tam"][0]
	e.h = def["tam"][1]
	e.x = tx * P + e.w * P / 2
	e.y = ty * P + e.h * P / 2
	e.res_kind = def["recurso"]
	e.amount = def["cantidad"]
	e.hp = 1
	e.hp_max = 1
	map.mark(tx, ty, e.w, e.h, e.id, true)
	var k := (tx / RC) * 1024 + ty / RC
	if not _res_cells.has(k):
		_res_cells[k] = []
	_res_cells[k].append(e)
	return e


# ---------------------------------------------------------------- Mapa

## Mapa con simetría puntual para dos jugadores (docs/05, justo para ambos).
func _generate_map() -> void:
	var n := map.n
	var b0 := Vector2i(22, 22)
	bases = [b0, Vector2i(n - 4 - b0.x, n - 4 - b0.y)]
	for pid in players.size():
		var base := bases[pid % 2]
		spawn_building("centro", pid, base.x, base.y, true)
		var count: int = data.reglas["aldeanos_iniciales"]
		for i in count:
			var ux := (base.x + i % 3 + (5 if pid == 0 else -2)) * P + P / 2
			var uy := (base.y + i / 3 + (1 if pid == 0 else 1)) * P + P / 2
			spawn_unit("aldeano", pid, ux, uy)

	var c0 := Vector2i(b0.x + 2, b0.y + 2) # centro de la base 0
	var dirs: Array[Vector2i] = [Vector2i(1, 0), Vector2i(1, 1), Vector2i(0, 1), Vector2i(-1, 1), Vector2i(-1, 0), Vector2i(-1, -1), Vector2i(0, -1), Vector2i(1, -1)]
	# Barajar direcciones con el generador de la partida.
	for i in range(dirs.size() - 1, 0, -1):
		var j := rng.range_i(0, i)
		var tmp := dirs[i]
		dirs[i] = dirs[j]
		dirs[j] = tmp
	# Preferir direcciones hacia el centro del mapa para los recursos clave.
	var inward: Array[Vector2i] = []
	var outward: Array[Vector2i] = []
	for d in dirs:
		if d.x + d.y >= 0:
			inward.append(d)
		else:
			outward.append(d)
	var picks: Array[Vector2i] = inward + outward

	_cluster_sym("arbusto", c0 + _scale_dir(picks[0], 7), 8)
	_blob_sym(c0 + _scale_dir(picks[1], 13), 4, 85)
	_res_sym("roca", c0 + _scale_dir(picks[2], 10))
	_res_sym("roca", c0 + _scale_dir(picks[2], 10) + Vector2i(2, -1))
	_res_sym("riqueza", c0 + _scale_dir(picks[3], 10))
	_res_sym("riqueza", c0 + _scale_dir(picks[3], 10) + Vector2i(-1, 2))
	_blob_sym(c0 + _scale_dir(picks[4], 15), 3, 80)

	# Recursos disputados en el centro.
	var mid := n / 2
	_res_sym("riqueza", Vector2i(mid - 9, mid + 5))
	_res_sym("riqueza", Vector2i(mid - 6, mid + 7))
	_res_sym("riqueza", Vector2i(mid + 14, mid + 12))
	_res_sym("riqueza", c0 + _scale_dir(picks[5], 18))
	_res_sym("roca", Vector2i(mid + 8, mid - 16))
	_cluster_sym("arbusto", Vector2i(mid - 18, mid + 2), 6)

	# Bosques.
	var tries := 0
	var made := 0
	while made < 13 and tries < 200:
		tries += 1
		var c := Vector2i(rng.range_i(5, n - 6), rng.range_i(5, n - 6))
		if _near_base(c, 17) or absi(c.x - c.y) < 6 and absi(c.x + c.y - n) < 20:
			continue
		_blob_sym(c, rng.range_i(3, 6), 78)
		made += 1
	# Bordes boscosos.
	for i in n:
		for depth in 3:
			var chance := 70 - depth * 25
			if rng.range_i(0, 99) < chance:
				_tree_sym(Vector2i(i, depth))
			if rng.range_i(0, 99) < chance:
				_tree_sym(Vector2i(depth, i))


func _scale_dir(d: Vector2i, dist_tiles: int) -> Vector2i:
	if d.x != 0 and d.y != 0:
		return d * (dist_tiles * 7 / 10)
	return d * dist_tiles


func _near_base(t: Vector2i, r: int) -> bool:
	for b in bases:
		var c := b + Vector2i(2, 2)
		if absi(t.x - c.x) < r and absi(t.y - c.y) < r:
			return true
	return false


func _mirror(t: Vector2i, w: int, h: int) -> Vector2i:
	return Vector2i(map.n - t.x - w, map.n - t.y - h)


func _res_sym(type: String, t: Vector2i) -> void:
	var tam: Array = data.recursos[type]["tam"]
	var m := _mirror(t, tam[0], tam[1])
	if t.x < 1 or t.y < 1 or t.x + tam[0] > map.n - 1 or t.y + tam[1] > map.n - 1:
		return
	if not map.is_free_rect(t.x - 1, t.y - 1, tam[0] + 2, tam[1] + 2) or not map.is_free_rect(m.x - 1, m.y - 1, tam[0] + 2, tam[1] + 2):
		return
	spawn_resource(type, t.x, t.y)
	spawn_resource(type, m.x, m.y)


func _tree_sym(t: Vector2i) -> void:
	var m := _mirror(t, 1, 1)
	if not map.in_bounds(t.x, t.y) or _near_base(t, 9) or _near_base(m, 9):
		return
	if map.occupant(t.x, t.y) != -1 or map.occupant(m.x, m.y) != -1:
		return
	spawn_resource("arbol", t.x, t.y)
	spawn_resource("arbol", m.x, m.y)


func _blob_sym(c: Vector2i, r: int, density: int) -> void:
	for dy in range(-r, r + 1):
		for dx in range(-r, r + 1):
			var d2 := dx * dx + dy * dy
			if d2 > r * r + rng.range_i(0, r):
				continue
			if rng.range_i(0, 99) < density:
				_tree_sym(c + Vector2i(dx, dy))


func _cluster_sym(type: String, c: Vector2i, count: int) -> void:
	var offs: Array[Vector2i] = [Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1), Vector2i(-1, 0), Vector2i(0, -1), Vector2i(2, 1), Vector2i(1, 2), Vector2i(-1, 1), Vector2i(2, 0)]
	for i in mini(count, offs.size()):
		var t := c + offs[i]
		var m := _mirror(t, 1, 1)
		if map.occupant(t.x, t.y) == -1 and map.occupant(m.x, m.y) == -1 and map.in_bounds(t.x, t.y):
			spawn_resource(type, t.x, t.y)
			spawn_resource(type, m.x, m.y)


# ---------------------------------------------------------------- Hash

func state_hash() -> int:
	var h := 2166136261
	for e in entities:
		for v in [e.id, e.x, e.y, e.hp, e.order, e.target, e.carry, e.amount, e.progress, e.queue.size(), e.queue_progress, e.inside]:
			h = ((h ^ (v & 0xffffffff)) * 16777619) & 0xffffffff
	for p in players:
		for k in RES_KINDS:
			h = ((h ^ (int(p["res"][k]) & 0xffffffff)) * 16777619) & 0xffffffff
		h = ((h ^ int(p["age"])) * 16777619) & 0xffffffff
	return h
