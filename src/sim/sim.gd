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
var fog: SimFog
var mods: SimMods
var rng: SimRng
var entities: Array[SimEntity] = [] # todas, en orden de id
var actives: Array[SimEntity] = [] # unidades y edificios, en orden de id
var by_id := {}
var next_id := 1
var players: Array[Dictionary] = []
var bases: Array[Vector2i] = []
var ais: Array = []
var scenario: SimScenario = null
var events: Array[Dictionary] = []
var game_over := false
var winner := -1
var terrain := ""
var _opts: Dictionary = {}

var _pending := {} # tick -> Array[Dictionary]
var recording: Array = [] # comandos externos (humanos) para repeticiones
var _in_step := false
var _grid := {} # celda de 1 casilla -> unidades (separación)
var _ehash := {} # celda de EC -> unidades y edificios (búsqueda)
var _res_cells := {} # celda de RC casillas -> recursos
var _dirty := false
const RC := 8


func _init(seed_value: int, num_players: int = 2, data_override: SimData = null, opts: Dictionary = {}) -> void:
	data = data_override if data_override != null else SimData.load_default()
	_opts = opts
	tick_ms = data.reglas["tick_ms"]
	rng = SimRng.new(seed_value)
	map = SimMap.new(data.reglas["mapa_tam"], num_players)
	fog = SimFog.new(data.reglas["mapa_tam"], num_players)
	fog.map = map
	fog.vision_per_level = data.reglas["vision_por_nivel"]
	mods = SimMods.new(self)
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
			"civ": (opts.get("civs", []) as Array)[i] if i < (opts.get("civs", []) as Array).size() else "",
		})
	for p in players:
		var dd := data.for_civ(p["civ"])
		if dd.has_mod("recurso_propio"):
			var rp: Dictionary = dd.mod("recurso_propio")
			p["res"][rp["clave"]] = int(rp.get("inicial", 0))
		for k in dd.civ.get("recursos_iniciales", {}):
			p["res"][k] = dd.civ["recursos_iniciales"][k]
	terrain = opts.get("terreno", "")
	if terrain == "":
		var kinds: Array = data.reglas["terrenos"].keys()
		terrain = kinds[rng.range_i(0, kinds.size() - 1)]
	_generate_map()
	_update_players()
	for pid in players.size():
		_update_fog(pid)


## Datos de la civilización del jugador (capa común si no tiene).
func dp(pid: int) -> SimData:
	if pid < 0 or pid >= players.size():
		return data
	return data.for_civ(players[pid]["civ"])


# ---------------------------------------------------------------- Comandos

## Programa un comando. Desde la IA (dentro de un tick) entra en el tick siguiente.
func push_command(cmd: Dictionary, delay: int = 0) -> void:
	var at := tick + delay
	if _in_step:
		at = maxi(at, tick + 1)
	cmd["tick"] = at
	if not _in_step:
		recording.append(cmd.duplicate(true))
	if not _pending.has(at):
		_pending[at] = []
	_pending[at].append(cmd)


## Convierte lo leído de JSON a enteros donde corresponde (JSON no distingue 5 de 5.0).
static func intify(v: Variant) -> Variant:
	if v is float and v == floorf(v):
		return int(v)
	if v is Array:
		var out := []
		for x in v:
			out.append(intify(x))
		return out
	if v is Dictionary:
		var d := {}
		for k in v:
			d[k] = intify(v[k])
		return d
	return v


## Repetición: programa comandos grabados en sus ticks originales.
func schedule(cmds: Array) -> void:
	for c: Dictionary in cmds:
		var at: int = c["tick"]
		if not _pending.has(at):
			_pending[at] = []
		_pending[at].append(c)


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
		"build_line":
			_cmd_build_line(pid, _own_units(pid, c.get("ids", [])), c["type"], c["tiles"])
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
		"trade":
			_cmd_trade(pid, c["building"], c["recurso"], c["op"])
		"pack":
			_cmd_pack(pid, c["building"])
		"unpack":
			_cmd_unpack(pid, c["unit"])
		"stop":
			for e in _own_units(pid, c.get("ids", [])):
				_set_idle(e)
		"delete":
			for id in c.get("ids", []):
				var e: SimEntity = by_id.get(id)
				if e != null and e.owner == pid and not e.is_resource():
					if e.is_building() and not e.built:
						_refund(pid, dp(pid).cost_of(e.type, players[pid]["age"]))
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


func _cmd_move(pid: int, units: Array[SimEntity], x: int, y: int, amove: bool) -> void:
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
		var t := map.nearest_free(clampi(gx / P, 0, map.n - 1), clampi(gy / P, 0, map.n - 1), 8, pid)
		if t.x >= 0 and map.is_solid(gx / P, gy / P, pid):
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
			if t.is_unit() and e.def.get("solo_edificios", false):
				plain.append(e)
			else:
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
	if not dp(pid).edificios.has(type):
		return
	var def: Dictionary = dp(pid).edificios[type]
	if p["age"] < def.get("edad_min", 1):
		_notify(pid, "Requiere edad %s" % _roman(def.get("edad_min", 1)))
		return
	if def.get("avanza_edad", false):
		if p["age"] >= dp(pid).edades.size():
			return
		if hito_in_progress(pid):
			_notify(pid, "Ya hay un hito en obra")
			return
	var cost := dp(pid).cost_of(type, p["age"])
	if not can_afford(pid, cost):
		_notify(pid, "Recursos insuficientes")
		return
	if not can_place(type, tx, ty, pid):
		_notify(pid, "No se puede construir ahí")
		return
	_replace_wall(type, tx, ty, pid)
	_pay(pid, cost)
	var b := spawn_building(type, pid, tx, ty, false)
	b.build_time = dp(pid).build_time_of(type, p["age"])
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
	if p["age"] < dp(pid).unidades[type].get("edad_min", 1):
		_notify(pid, "Requiere edad %s" % _roman(dp(pid).unidades[type]["edad_min"]))
		return
	if b.queue.size() >= data.reglas["cola_max"]:
		_notify(pid, "Cola llena")
		return
	var cost := dp(pid).cost_of(type, p["age"])
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
	_refund(pid, dp(pid).cost_of(type, players[pid]["age"]))


## ¿Se puede investigar `tech` ahora? Devuelve "" o el motivo.
func research_block(pid: int, tech: String) -> String:
	var t: Dictionary = dp(pid).tecnologias.get(tech, {})
	var p := players[pid]
	if t.is_empty():
		return "Desconocida"
	if p["techs"].has(tech):
		return "Ya investigada"
	if p["pending"].has(tech):
		return "En investigación"
	if t.has("requiere") and not p["techs"].has(t["requiere"]):
		return "Requiere %s" % dp(pid).tecnologias[t["requiere"]]["nombre"]
	if p["age"] < t.get("edad_min", 1):
		return "Requiere edad %s" % _roman(t["edad_min"])
	return ""


func _cmd_research(pid: int, bid: int, tech: String) -> void:
	var b: SimEntity = by_id.get(bid)
	if b == null or not b.alive or b.owner != pid or not b.built:
		return
	var t: Dictionary = dp(pid).tecnologias.get(tech, {})
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


## Mercado: compra o vende un lote por riqueza; el precio sube al comprar y baja al vender.
func _cmd_trade(pid: int, bid: int, kind: String, op: String) -> void:
	var b: SimEntity = by_id.get(bid)
	if b == null or not b.alive or b.owner != pid or not b.built or not b.def.get("mercado", false):
		return
	if not kind in ["alimento", "madera", "piedra"]:
		return
	var cfg: Dictionary = data.reglas["mercado"]
	var p := players[pid]
	var price: int = trade_price(pid, kind)
	var lot: int = cfg["lote"]
	var res: Dictionary = p["res"]
	if op == "comprar":
		if int(res["riqueza"]) < price:
			_notify(pid, "Falta riqueza")
			return
		res["riqueza"] -= price
		res[kind] += lot
		p["precios"][kind] = mini(int(cfg["maximo"]), price + int(cfg["paso"]))
	else:
		if int(res[kind]) < lot:
			_notify(pid, "No alcanza para vender")
			return
		res[kind] -= lot
		res["riqueza"] += price * (100 - int(cfg["comision_pct"])) / 100
		p["precios"][kind] = maxi(int(cfg["minimo"]), price - int(cfg["paso"]))
	events.append({"t": "trade", "player": pid})


func trade_price(pid: int, kind: String) -> int:
	var p := players[pid]
	if not p.has("precios"):
		var start: int = data.reglas["mercado"]["precio_inicial"]
		p["precios"] = {"alimento": start, "madera": start, "piedra": start}
	return p["precios"][kind]


## Base móvil (kätäma etíope): el edificio se desarma en una unidad lenta que lo lleva.
func _cmd_pack(pid: int, bid: int) -> void:
	var b: SimEntity = by_id.get(bid)
	if b == null or not b.alive or b.owner != pid or not b.built or not b.def.has("empaca_en") or not b.queue.is_empty():
		return
	var kind: String = b.def["empaca_en"]
	var tile := Vector2i(b.tx + b.w / 2, b.ty + b.h / 2)
	var ratio := b.hp * 100 / b.hp_max
	var was_capital := b.capital
	b.capital = false
	_kill(b)
	var u := spawn_unit(kind, pid, tile.x * P + P / 2, tile.y * P + P / 2)
	u.hp = maxi(1, u.hp_max * ratio / 100)
	u.capital = was_capital
	events.append({"t": "packed", "id": u.id, "player": pid})


func _cmd_unpack(pid: int, uid: int) -> void:
	var u: SimEntity = by_id.get(uid)
	if u == null or not u.alive or u.owner != pid or not u.def.has("despliega_en"):
		return
	var kind: String = u.def["despliega_en"]
	var tam: Array = dp(pid).edificios[kind]["tam"]
	var tx: int = u.x / P - int(tam[0]) / 2
	var ty: int = u.y / P - int(tam[1]) / 2
	if not can_place(kind, tx, ty, pid):
		_notify(pid, "No hay lugar parejo para armar la corte")
		return
	var ratio := u.hp * 100 / u.hp_max
	var was_capital := u.capital
	_kill(u)
	var b := spawn_building(kind, pid, tx, ty, true)
	b.hp = maxi(1, b.hp_max * ratio / 100)
	b.capital = was_capital
	events.append({"t": "built", "id": b.id, "player": pid})


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
		if ai.thinks_now() and not players[ai.player]["defeated"]:
			ai.think()
	_rebuild_hashes()
	_update_players()
	for b in actives:
		if b.is_building() and not b.built:
			b.workers_prev = b.workers_now
			b.workers_now = 0
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
	if tick % 10 == 0:
		mods.tick_second()
	var every: int = data.reglas["niebla_cada_ticks"]
	for pid in players.size():
		if (tick + pid) % every == 0:
			_update_fog(pid)
	if _dirty:
		_cleanup()
	if tick % 10 == 5 and not game_over:
		_check_victory()
	if scenario != null:
		scenario.on_step()
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


func _update_fog(pid: int) -> void:
	var sources: Array = []
	for e in actives:
		if e.alive and e.owner == pid and e.inside < 0:
			sources.append(e)
	fog.update(pid, sources)


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
	var rate_key: String = String(t.def.get("tasa_clave", "granja")) if t.is_building() else kind
	var rate: int = int(e.def["tasa"].get(rate_key, e.def["tasa"].get("granja", 0))) * (100 + mod(e.owner, "tasa:" + rate_key) + _site_bonus(t)) / 100
	e.carry_res = kind
	e.gather_acc += rate * tick_ms / 1000
	while e.gather_acc >= 1000 and e.carry < cap:
		e.gather_acc -= 1000
		e.carry += 1
		if t.is_resource() or t.def.has("cantidad"):
			t.amount -= 1
			if t.amount <= 0:
				_exhaust(t)
				break


## Bonificación por sitio de una granja: ladera (andenes) o agua cercana (arrozales).
func _site_bonus(t: SimEntity) -> int:
	if not t.is_building():
		return 0
	var bonus := 0
	if t.def.has("bono_ladera_pct"):
		for yy in range(t.ty, t.ty + t.h):
			for xx in range(t.tx, t.tx + t.w):
				if map.is_slope(xx, yy) or map.h_at(xx, yy) > 0:
					return int(t.def["bono_ladera_pct"])
	if t.def.has("bono_agua_pct") and _near_water(t.tx, t.ty, t.w, t.h, 2):
		bonus += int(t.def["bono_agua_pct"])
	return bonus


func _near_water(tx: int, ty: int, w: int, h: int, r: int) -> bool:
	for yy in range(ty - r, ty + h + r):
		for xx in range(tx - r, tx + w + r):
			if map.is_water(xx, yy):
				return true
	return false


## Fuente agotada. Una chacra de roza deja otra fuente en su lugar (sucesión del monte).
func _exhaust(t: SimEntity) -> void:
	var leaves: String = t.def.get("deja", "")
	var tx := t.tx
	var ty := t.ty
	_kill(t)
	if leaves != "" and data.recursos.has(leaves):
		spawn_resource(leaves, tx, ty)
		events.append({"t": "succession", "x": tx, "y": ty, "type": leaves})


## Aparece una unidad junto a un edificio (acogida, liberación, refuerzos).
func spawn_near(b: SimEntity, type: String, owner: int = -2) -> SimEntity:
	var tile := _spawn_tile(b)
	return spawn_unit(type, b.owner if owner == -2 else owner, tile.x * P + P / 2, tile.y * P + P / 2)


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
		var t_rep: int = maxi(1, dp(b.owner).build_time_of(b.type, 1))
		b.hp = mini(b.hp_max, b.hp + maxi(1, b.hp_max * tick_ms / t_rep))
		return
	if b.build_time <= 0:
		_complete(b)
		return
	# La vida sube en proporción exacta al progreso; el daño recibido se conserva.
	# Rendimiento decreciente (P-006): con n constructores la obra tarda tiempo × 3/(n+2).
	b.workers_now += 1
	var step_ms := mods.build_step(b, maxi(1, b.workers_prev))
	var before := (b.hp_max - 1) * b.progress / b.build_time
	b.progress = mini(b.build_time, b.progress + step_ms)
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
		p["age"] = mini(dp(b.owner).edades.size(), p["age"] + 1)
		_apply_effects(b.owner, b.def.get("efectos", []))
		events.append({"t": "age", "player": b.owner, "age": p["age"], "hito": b.type})


func _hit(a: SimEntity, t: SimEntity) -> void:
	var atk: int = a.def.get("ataque", 0)
	if a.is_building():
		atk += mod(a.owner, "b_ataque")
	else:
		atk += mod(a.owner, "ataque:" + a.fn)
	if a.owner >= 0 and (a.is_military() or a.is_building()):
		var bonus: int = dp(a.owner).edades[players[a.owner]["age"] - 1].get("bono_ataque", 0)
		atk = atk * (100 + bonus) / 100
	var mult: int = data.reglas["contadores"].get(a.fn, {}).get(t.fn, 100)
	var armor: int = int(t.def.get("armadura", 0)) + (mod(t.owner, "armadura:" + t.fn) if t.is_unit() else 0)
	# Altura (D-027): quien dispara desde más arriba pega más fuerte.
	if int(a.def.get("alcance", 0)) > 1500:
		var dh := map.h_at(a.x / P, a.y / P) - map.h_at(t.x / P, t.y / P)
		if dh > 0:
			atk = atk * (100 + dh * int(data.reglas["bono_altura_pct"])) / 100
	var dmg := maxi(data.reglas["danio_minimo"], atk * mult / 100 - armor)
	dmg = mods.damage(a, t, dmg)
	t.hp -= dmg
	# Espinas (cerca con estrepes de Palmares): devuelve daño al atacante cuerpo a cuerpo.
	if t.def.has("espinas") and a.is_unit() and int(a.def.get("alcance", 0)) <= 1500:
		a.hp -= int(t.def["espinas"])
		if a.hp <= 0:
			mods.on_kill(a, t)
			_kill(a)
	mods.on_hit(a, t, dmg)
	# Daño en área (elefantes): una fracción a los enemigos cercanos al objetivo.
	if a.def.has("area") and t.is_unit():
		var r: int = a.def["area"]
		for o in actives:
			if o != t and o.alive and o.is_unit() and o.inside < 0 and o.owner >= 0 and o.owner != a.owner and absi(o.x - t.x) <= r and absi(o.y - t.y) <= r:
				o.hp -= maxi(1, dmg * int(a.def.get("area_pct", 50)) / 100)
				if o.hp <= 0:
					mods.on_kill(o, a)
					_kill(o)
	# Munición limitada (cañón de tacuara): se rompe tras n disparos.
	if a.def.has("municion"):
		a.shots += 1
		if a.shots >= int(a.def["municion"]):
			a.hp = 0
			_kill(a)
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
		mods.on_kill(t, a)
		_kill(t, a)


func _kill(e: SimEntity, killer: SimEntity = null) -> void:
	if not e.alive:
		return
	e.alive = false
	e.hp = 0
	_dirty = true
	if e.is_building() or e.is_resource():
		map.clear(e.tx, e.ty, e.w, e.h)
	if e.is_building():
		mods.on_building_removed(e)
		_eject(e)
		for item in e.queue:
			if item.begins_with("@"):
				players[e.owner]["pending"].erase(item.substr(1))
	events.append({"t": "died", "id": e.id, "owner": e.owner, "type": e.type, "cat": e.cat, "by": killer.owner if killer != null else -1, "x": e.x, "y": e.y})


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
		if not is_tech and b.queue_progress == 0 and p["pop"] + int(dp(b.owner).unidades[item].get("pob", 1)) > p["pop_cap"]:
			if (tick + b.id) % 100 == 0:
				_notify(b.owner, "Población llena")
		else:
			b.queue_progress += tick_ms * mods.production_pct(b) / 100
			if b.queue_progress >= dp(b.owner).queue_time(item):
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
	_apply_effects(pid, dp(pid).tecnologias[tech]["efectos"])
	events.append({"t": "tech", "player": pid, "tech": tech})


func _spawn_from(b: SimEntity, type: String) -> void:
	var tile := _spawn_tile(b)
	var u := spawn_unit(type, b.owner, tile.x * P + P / 2, tile.y * P + P / 2)
	players[b.owner]["stats"]["entrenadas"] += 1
	events.append({"t": "trained", "id": u.id, "player": b.owner, "type": type})
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
			if not map.is_solid(xx, b.ty + b.h - 1 + r, b.owner):
				return Vector2i(xx, b.ty + b.h - 1 + r)
		for yy in range(b.ty - r, b.ty + b.h + r):
			if not map.is_solid(b.tx + b.w - 1 + r, yy, b.owner):
				return Vector2i(b.tx + b.w - 1 + r, yy)
			if not map.is_solid(b.tx - r, yy, b.owner):
				return Vector2i(b.tx - r, yy)
		for xx in range(b.tx - r, b.tx + b.w + r):
			if not map.is_solid(xx, b.ty - r, b.owner):
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
	if map.is_solid(from.x, from.y, e.owner):
		var f2 := map.nearest_free(from.x, from.y, 6, e.owner)
		e.path = [from] as Array[Vector2i]
		if f2.x >= 0:
			e.path.append_array(map.find_path(f2, to, e.owner))
		e.path_i = 1
	else:
		e.path = map.find_path(from, to, e.owner)
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
		if last and wp == goal_tile and not map.is_solid(wp.x, wp.y, e.owner):
			px = e.goal_x
			py = e.goal_y
		if not last and dist(e.x, e.y, px, py) < 380:
			e.path_i += 1
			continue
		if _step_toward(e, px, py):
			e.path_i += 1
			return e.path_i >= e.path.size()
		return false
	if map.is_solid(goal_tile.x, goal_tile.y, e.owner):
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
	var spd := mods.speed(e)
	if d > spd:
		nx = e.x + dx * spd / d
		ny = e.y + dy * spd / d
	var moved := _try_move(e, nx, ny)
	if moved == 2:
		e.stuck = 0
		return d <= spd
	if moved == 0:
		e.stuck += 1
	return false


## 2 = movimiento completo, 1 = deslizó por un eje, 0 = bloqueado.
func _try_move(e: SimEntity, nx: int, ny: int) -> int:
	var lim := map.n * P - 50
	nx = clampi(nx, 50, lim)
	ny = clampi(ny, 50, lim)
	if map.is_solid(e.x / P, e.y / P, e.owner) or not map.is_solid(nx / P, ny / P, e.owner):
		e.x = nx
		e.y = ny
		return 2
	if not map.is_solid(nx / P, e.y / P, e.owner):
		e.x = nx
		return 1
	if not map.is_solid(e.x / P, ny / P, e.owner):
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
	var buildings_only: bool = e.is_unit() and e.def.get("solo_edificios", false)
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
				if buildings_only and not o.is_building():
					continue
				if mods.is_hidden_now(o) and not mods.detected_by(o, e.owner):
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


func can_place(type: String, tx: int, ty: int, pid: int = -1) -> bool:
	if not dp(pid).edificios.has(type):
		return false
	var tam: Array = dp(pid).edificios[type]["tam"]
	if tx < 0 or ty < 0 or tx + tam[0] > map.n or ty + tam[1] > map.n:
		return false
	if dp(pid).edificios[type].get("puerta", false) and _own_wall_at(tx, ty, pid) != null:
		return true
	var def: Dictionary = dp(pid).edificios.get(type, data.edificios.get(type, {}))
	if not map.is_free_rect(tx, ty, tam[0], tam[1]):
		return false
	if def.get("requiere_agua", false) and not _near_water(tx, ty, tam[0], tam[1], 2):
		return false
	if def.get("permite_ladera", false):
		for yy in range(ty, ty + tam[1]):
			for xx in range(tx, tx + tam[0]):
				if map.is_water(xx, yy):
					return false
		return true
	return map.is_flat(tx, ty, tam[0], tam[1])


## Empalizada propia en la casilla (una puerta puede reemplazarla).
func _own_wall_at(tx: int, ty: int, pid: int) -> SimEntity:
	var w: SimEntity = by_id.get(map.occupant(tx, ty))
	if w != null and w.alive and w.owner == pid and w.def.get("linea", false):
		return w
	return null


func _replace_wall(type: String, tx: int, ty: int, pid: int) -> void:
	if not dp(pid).edificios[type].get("puerta", false):
		return
	var w := _own_wall_at(tx, ty, pid)
	if w != null:
		_kill(w)


## Construcción en línea (empalizadas): un cimiento por casilla; los aldeanos siguen de uno al siguiente.
func _cmd_build_line(pid: int, units: Array[SimEntity], type: String, tiles: Array) -> void:
	var def: Dictionary = dp(pid).edificios.get(type, {})
	if not def.get("linea", false):
		return
	var cost := dp(pid).cost_of(type, players[pid]["age"])
	var first: SimEntity = null
	var placed := 0
	for t in tiles:
		if not can_afford(pid, cost):
			_notify(pid, "Recursos insuficientes")
			break
		if not can_place(type, t[0], t[1], pid):
			continue
		_pay(pid, cost)
		var b := spawn_building(type, pid, t[0], t[1], false)
		placed += 1
		if first == null:
			first = b
	if first == null:
		return
	events.append({"t": "placed", "id": first.id, "player": pid})
	for e in units:
		if e.fn == "civil":
			_order_build(e, first)


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
		if b.alive and b.is_building() and b.owner >= 0 and b.built and (b.def.get("hito", false) or b.capital or b.def.get("cuenta_victoria", false)):
			has_hito[b.owner] = true
	for p in players:
		if not p["defeated"] and not has_hito[p["id"]]:
			_defeat(p["id"])


## Victoria directa (sitios sagrados): todos los demás pierden.
func win(pid: int) -> void:
	for p in players:
		if p["id"] != pid:
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
	var def: Dictionary = dp(owner).unidades[type]
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
	var def: Dictionary = dp(owner).edificios[type]
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
	e.build_time = dp(owner).build_time_of(type, players[owner]["age"]) if owner >= 0 else 0
	if owner < 0:
		e.hp = 1
		e.hp_max = 1
	map.mark(tx, ty, e.w, e.h, e.id, not def.get("transitable", false), owner if def.get("puerta", false) else -1)
	if def.has("cantidad"):
		e.amount = def["cantidad"]
	mods.on_building_placed(e)
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
	bases = [b0, Vector2i(n - 4 - b0.x, n - 4 - b0.y), Vector2i(b0.x, n - 4 - b0.y), Vector2i(n - 4 - b0.x, b0.y)]
	_generate_terrain()
	for pid in players.size():
		var base := bases[pid % 4]
		var dd := dp(pid)
		var start: String = dd.civ.get("inicio_edificio", "centro")
		var sb := spawn_building(start, pid, base.x, base.y, true)
		sb.capital = true
		var count: int = dd.civ.get("aldeanos_iniciales", data.reglas["aldeanos_iniciales"])
		for i in count:
			var ux := (base.x + i % 3 + (5 if pid == 0 else -2)) * P + P / 2
			var uy := (base.y + i / 3 + (1 if pid == 0 else 1)) * P + P / 2
			spawn_unit("aldeano", pid, ux, uy)
		for i in int(data.reglas["exploradores_iniciales"]):
			var sx := (base.x + (5 if pid == 0 else -2)) * P + P / 2
			var sy := (base.y + 4 + i) * P + P / 2
			spawn_unit(dd.civ.get("explorador", "explorador"), pid, sx, sy)

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

	# Bases extra (campañas con tres o cuatro jugadores): recursos propios sin simetría.
	for extra in range(2, mini(players.size(), 4)):
		var ce := bases[extra] + Vector2i(2, 2)
		var dirx := Vector2i(signi(n / 2 - ce.x), signi(n / 2 - ce.y))
		_cluster_sym("arbusto", ce + Vector2i(dirx.x * 7, 0), 6)
		_res_sym("roca", ce + Vector2i(0, dirx.y * 9))
		_res_sym("riqueza", ce + Vector2i(dirx.x * 9, dirx.y * 5))
		_blob_sym(ce + Vector2i(dirx.x * 4, dirx.y * 13), 3, 80)

	# Sitios sagrados: uno al centro y pares simétricos (docs/05, "Victoria").
	if players.size() == 2 and not _opts.get("sin_sitios", false):
		var sites: int = data.reglas["sitios"]["cantidad"]
		var spots: Array[Vector2i] = [Vector2i(n / 2 - 1, n / 2 - 1), Vector2i(n / 2 - 18, n / 2 + 14), Vector2i(n / 2 + 16, n / 2 - 16)]
		for i in mini(sites, spots.size()):
			var t := map.nearest_free(spots[i].x, spots[i].y, 8)
			if t.x >= 0 and map.is_free_rect(t.x, t.y, 2, 2):
				spawn_building("sitio_sagrado", -1, t.x, t.y, true)

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
	var td := terrain_def()
	var forests := int(td.get("bosques", 13))
	while made < forests and tries < 300:
		tries += 1
		var c := Vector2i(rng.range_i(5, n - 6), rng.range_i(5, n - 6))
		if _near_base(c, 17) or absi(c.x - c.y) < 6 and absi(c.x + c.y - n) < 20:
			continue
		_blob_sym(c, rng.range_i(3, 6), 78)
		made += 1
	# Matorral suelto en mapas secos.
	for k in int(td.get("arbustos_extra", 0)):
		var c := Vector2i(rng.range_i(8, n - 9), rng.range_i(8, n - 9))
		if not _near_base(c, 16):
			_cluster_sym("arbusto", c, 5)
	# Bordes boscosos.
	for i in n:
		for depth in int(td.get("borde", 3)):
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
	for i in mini(maxi(players.size(), 2), bases.size()):
		var b := bases[i]
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
	for yy in range(t.y, t.y + tam[1]):
		for xx in range(t.x, t.x + tam[0]):
			if map.is_water(xx, yy) or map.is_water(m.x + xx - t.x, m.y + yy - t.y):
				return
	spawn_resource(type, t.x, t.y)
	spawn_resource(type, m.x, m.y)


func _tree_sym(t: Vector2i) -> void:
	var m := _mirror(t, 1, 1)
	if not map.in_bounds(t.x, t.y) or _near_base(t, 9) or _near_base(m, 9):
		return
	if map.occupant(t.x, t.y) != -1 or map.occupant(m.x, m.y) != -1 or map.is_water(t.x, t.y) or map.is_water(m.x, m.y):
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
		if map.occupant(t.x, t.y) == -1 and map.occupant(m.x, m.y) == -1 and map.in_bounds(t.x, t.y) and not map.is_water(t.x, t.y) and not map.is_water(m.x, m.y):
			spawn_resource(type, t.x, t.y)
			spawn_resource(type, m.x, m.y)


## Parámetros del tipo de mapa (reglas.json, "terrenos").
func terrain_def() -> Dictionary:
	return data.reglas["terrenos"].get(terrain, data.reglas["terrenos"]["llano"])


## Relieve y agua con simetría puntual; las bases quedan llanas (D-027, docs/10).
func _generate_terrain() -> void:
	var td := terrain_def()
	if _opts.has("relieve"):
		_relief_real(_opts["relieve"], td.get("relieve", {}).get("umbrales", [72, 90]))
		return
	if td.has("relieve"):
		_relief_noise(td["relieve"])
	else:
		_relief_hills(int(td.get("colinas", 4)), int(td.get("nivel_max", 2)))
	if td.has("rio"):
		var rd: Dictionary = td["rio"]
		_river(0, int(rd.get("ancho", 1)), int(rd.get("vados", 22)))
		if rd.has("brazos"):
			_river(int(rd["brazos"]), maxi(1, int(rd.get("ancho", 1)) - 1), maxi(6, int(rd.get("vados", 22)) - 3))
	var lakes := int(td.get("lagunas", 0))
	var lr: Array = td.get("laguna_radio", [2, 3])
	for k in lakes:
		var c := Vector2i(rng.range_i(10, map.n - 11), rng.range_i(10, map.n - 11))
		if _near_base(c, 18):
			continue
		var r := rng.range_i(int(lr[0]), int(lr[1]))
		for dy in range(-r, r + 1):
			for dx in range(-r, r + 1):
				if dx * dx + dy * dy <= r * r + rng.range_i(0, r) - r / 2:
					var t := c + Vector2i(dx, dy)
					var m := _mirror(t, 1, 1)
					if map.in_bounds(t.x, t.y) and not _near_base(t, 13) and not _near_base(m, 13):
						map.set_water(t.x, t.y, 1)
						map.set_water(m.x, m.y, 1)


## Colinas redondas en mesetas de nivel 1..top (mapas clásicos).
func _relief_hills(hills: int, top: int) -> void:
	var n := map.n
	var made := 0
	var tries := 0
	while made < hills and tries < 200:
		tries += 1
		var c := Vector2i(rng.range_i(6, n - 7), rng.range_i(6, n - 7))
		if _near_base(c, 15):
			continue
		var r := rng.range_i(4, 9)
		var lvl := rng.range_i(1, top)
		for l in range(1, lvl + 1):
			var rr := r - (l - 1) * 2
			if rr < 2:
				break
			for dy in range(-rr, rr + 1):
				for dx in range(-rr, rr + 1):
					if dx * dx + dy * dy > rr * rr + rng.range_i(0, rr):
						continue
					var t := c + Vector2i(dx, dy)
					var m := _mirror(t, 1, 1)
					if not map.in_bounds(t.x, t.y) or _near_base(t, 11) or _near_base(m, 11):
						continue
					if map.h_at(t.x, t.y) < l:
						map.height[t.y * n + t.x] = l
						map.height[m.y * n + m.x] = l
		made += 1


## Relieve orgánico: ruido de valor entero en dos octavas, cortado en niveles
## por umbrales. Umbrales juntos hacen paredes (amba); separados, terrazas.
func _relief_noise(rd: Dictionary) -> void:
	var n := map.n
	var sc := int(rd.get("escala", 14))
	var cuts: Array = rd.get("umbrales", [60, 80])
	var bias: String = rd.get("sesgo", "")
	var s1 := rng.range_i(1, 1 << 20)
	var s2 := rng.range_i(1, 1 << 20)
	for ty in n:
		for tx in n:
			var idx := ty * n + tx
			var m := _mirror(Vector2i(tx, ty), 1, 1)
			if idx > m.y * n + m.x:
				continue # la mitad espejada se copia
			var v := (_vnoise(tx, ty, sc, s1) * 2 + _vnoise(tx, ty, maxi(3, sc / 2), s2)) / 30 # 0..100
			if bias == "esquinas":
				# Cordillera en las dos esquinas sin base (la antidiagonal).
				var dc := mini(tx + (n - 1 - ty), (n - 1 - tx) + ty)
				v += maxi(0, 46 - dc * 46 / (n * 6 / 10))
			# Las bases quedan llanas, con rampa suave alrededor.
			var db := 1 << 20
			for i in mini(maxi(players.size(), 2), bases.size()):
				var c := bases[i] + Vector2i(2, 2)
				db = mini(db, maxi(absi(tx - c.x), absi(ty - c.y)))
				var cm := _mirror(c, 1, 1)
				db = mini(db, maxi(absi(tx - cm.x), absi(ty - cm.y)))
			v -= maxi(0, (19 - db) * 9)
			var lvl := 0
			for cut in cuts:
				if v >= int(cut):
					lvl += 1
			map.height[idx] = lvl
			map.height[m.y * n + m.x] = lvl


## Relieve de un lugar real: percentiles 00..99 por casilla y agua (0, 1 o 2),
## como filas de texto. Sin simetría: las misiones no la necesitan.
func _relief_real(rd: Dictionary, cuts: Array) -> void:
	var n := map.n
	var rows: Array = rd["alturas"]
	var wrows: Array = rd["agua"]
	for ty in mini(n, rows.size()):
		var row: String = rows[ty]
		var wrow: String = wrows[ty]
		for tx in mini(n, row.length() / 2):
			var v := row.substr(tx * 2, 2).to_int()
			var db := 1 << 20
			for i in mini(maxi(players.size(), 2), bases.size()):
				var c := bases[i] + Vector2i(2, 2)
				db = mini(db, maxi(absi(tx - c.x), absi(ty - c.y)))
			v -= maxi(0, (19 - db) * 9)
			var lvl := 0
			for cut in cuts:
				if v >= int(cut):
					lvl += 1
			map.height[ty * n + tx] = lvl
	for ty in mini(n, wrows.size()):
		var wrow: String = wrows[ty]
		for tx in mini(n, wrow.length()):
			var k := wrow.unicode_at(tx) - 48
			if k > 0 and not _near_base(Vector2i(tx, ty), 9):
				map.set_water(tx, ty, k)
				map.height[ty * n + tx] = 0


## Ruido de valor entero (0..1000) con interpolación suavizada; determinista.
func _vnoise(x: int, y: int, sc: int, sd: int) -> int:
	var gx := x / sc
	var gy := y / sc
	var fx := (x % sc) * 1000 / sc
	var fy := (y % sc) * 1000 / sc
	fx = fx * fx * (3000 - 2 * fx) / 1000000
	fy = fy * fy * (3000 - 2 * fy) / 1000000
	var a := _lattice(gx, gy, sd)
	var b := _lattice(gx + 1, gy, sd)
	var c := _lattice(gx, gy + 1, sd)
	var d := _lattice(gx + 1, gy + 1, sd)
	var top := a + (b - a) * fx / 1000
	var bot := c + (d - c) * fx / 1000
	return top + (bot - top) * fy / 1000


static func _lattice(x: int, y: int, sd: int) -> int:
	var h := (x * 374761393 + y * 668265263 + sd * 2147483647) & 0x7fffffff
	h = ((h ^ (h >> 13)) * 1274126177) & 0x7fffffff
	return (h ^ (h >> 16)) % 1001


## Río por la antidiagonal (que la simetría deja fija), corrido `shift` casillas.
func _river(shift: int, width: int, ford_every: int) -> void:
	var n := map.n
	var off := 0
	for i in range(0, n / 2 + 1 if shift == 0 else n + shift):
		if rng.range_i(0, 3) == 0:
			off = clampi(off + rng.range_i(-1, 1), -6, 6)
		var x := i + off + shift
		var y := n - 1 - i + off + shift
		for w in range(-width, width + 1):
			for d in [Vector2i(w, 0), Vector2i(0, w)]:
				var t: Vector2i = Vector2i(x, y) + d
				var m := _mirror(t, 1, 1)
				if not map.in_bounds(t.x, t.y) or _near_base(t, 12) or _near_base(m, 12):
					continue
				var kind := 2 if (i % ford_every) < 3 else 1
				map.set_water(t.x, t.y, kind)
				map.set_water(m.x, m.y, kind)
		# El río baja el terreno a su alrededor: cauce llano y barranca escalonada.
		for dy in range(-width - 4, width + 5):
			for dx in range(-width - 4, width + 5):
				var t := Vector2i(x + dx, y + dy)
				if not map.in_bounds(t.x, t.y):
					continue
				var cap := 0 if maxi(absi(dx), absi(dy)) <= width + 2 else 1
				var m := _mirror(t, 1, 1)
				map.height[t.y * n + t.x] = mini(map.height[t.y * n + t.x], cap)
				map.height[m.y * n + m.x] = mini(map.height[m.y * n + m.x], cap)


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
