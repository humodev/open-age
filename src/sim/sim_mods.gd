class_name SimMods
extends RefCounted
## Módulos de civilización (docs/01, "test del módulo"; docs/06). Cada civilización los activa
## con parámetros en data/civs/<clave>.json → "modulos". La simulación solo llama a estos ganchos.

const P := 1000
const O := SimEntity.Order

var sim: Sim
var _acc := {} # acumuladores en milésimas: "pid:clave" -> int
var _clay_linked := {} # jugador -> {id de arcilla: true} unidas por camino
var _respawns: Array = []
var _tambo_of := {} # tambo inca -> tipo de ingenio que vuelve si cae # [tipo, tx, ty, tick] de ingenios por rehacer
var _craft_hits := {} # edificio con oficios -> [[tick, daño], …] de los últimos 5 s
var _roads := PackedByteArray() # casillas con camino
var _connected := {} # id de edificio -> true si está conectado a la capital


func _init(s: Sim) -> void:
	sim = s
	_roads.resize(s.map.n * s.map.n)


func m(pid: int, name: String) -> Dictionary:
	return sim.dp(pid).mod(name)


func has(pid: int, name: String) -> bool:
	return pid >= 0 and sim.dp(pid).has_mod(name)


# ---------------------------------------------------------------- Cada segundo

func tick_second() -> void:
	for p in sim.players:
		var pid: int = p["id"]
		if p["defeated"]:
			continue
		_own_resource(pid, p)
		_rents(pid, p)
		_conversions(pid, p)
		_crafts_yield(pid)
		_herds(pid)
		if has(pid, "acogida"):
			_welcome(pid, p)
		if has(pid, "caminos") and sim.tick % 50 == 0:
			_update_connection(pid)
	_regen()
	_sacred()
	if not _respawns.is_empty():
		_respawn_neutrals()


## Recurso propio: generado por aldeanos y edificios, con tope por almacenamiento.
func _own_resource(pid: int, p: Dictionary) -> void:
	if not has(pid, "recurso_propio"):
		return
	var cfg := m(pid, "recurso_propio")
	var key: String = cfg["clave"]
	var per_min := 0
	var cap: int = cfg.get("tope", 999999)
	var vill := 0
	for e in sim.actives:
		if not e.alive or e.owner != pid:
			continue
		if e.fn == "civil":
			vill += 1
		elif e.is_building() and e.built:
			per_min += int(cfg.get("por_edificio", {}).get(e.type, 0))
			cap += int(cfg.get("tope_por_edificio", {}).get(e.type, 0))
			# Mocambo junto al monte (Palmares, §3.5.5): +N con suficientes árboles cerca.
			var monte: Dictionary = cfg.get("monte", {})
			if monte.has(e.type):
				var trees := 0
				for t in sim.resources_near(e.tx + e.w / 2, e.ty + e.h / 2, e.w / 2 + int(monte.get("radio", 4))):
					if t.type == "arbol":
						trees += 1
				if trees >= int(monte.get("arboles", 6)):
					per_min += int(monte[e.type])
	var per_v := int(cfg.get("por_aldeano", 0))
	var by_age: Array = cfg.get("por_aldeano_por_edad", [])
	if not by_age.is_empty():
		per_v = int(by_age[clampi(int(p["age"]) - 1, 0, by_age.size() - 1)])
	per_min += vill * per_v
	_gain(pid, key, per_min * P / 60)
	p["res"][key] = mini(p["res"].get(key, 0), cap)
	p["tope_" + key] = cap


## Tope extra de tributo por elefante (barrio chino, junco): el mayor, no se suman.
func tribute_cap_bonus(pid: int) -> int:
	var best := 0
	for e in sim.actives:
		if e.alive and e.owner == pid and e.is_building() and e.built:
			best = maxi(best, int(e.def.get("tributo_tope_extra", 0)))
	return best


## Piezas extra de motor que dan los hitos ("maximo_extra": {"tipo": n} en el hito).
func engine_max_bonus(pid: int, type: String) -> int:
	var extra := 0
	for e in sim.actives:
		if e.alive and e.owner == pid and e.is_building() and e.built and e.def.has("maximo_extra"):
			extra += int(e.def["maximo_extra"].get(type, 0))
	return extra


func _gain(pid: int, key: String, milli: int, origin: String = "propio") -> void:
	var k := "%d:%s:%s" % [pid, key, origin]
	var acc: int = _acc.get(k, 0) + milli
	var whole := acc / P
	_acc[k] = acc - whole * P
	if whole != 0 and key == "riqueza" and origin in ["sitios", "saqueo"]:
		whole = mini(whole, sim.disputed_room(pid)) # techo de lo disputado
		sim.disputed_add(pid, whole)
	if whole != 0:
		sim.players[pid]["res"][key] = int(sim.players[pid]["res"].get(key, 0)) + whole
		sim.ledger(pid, origin, key, whole)


## Conversión (taller de tejido inca y otros motores): cada edificio consume por
## minuto un recurso que esté por encima de la reserva del jugador y produce otro.
## Si falta y la reserva es 0, rinde el piso (`piso_pct`); con reserva, nada.
## La tecnología de motor suma su porcentaje (mod "motor"). Orden por id: determinista.
func _conversions(pid: int, p: Dictionary) -> void:
	var boost := 100 + sim.mod(pid, "motor")
	for e in sim.actives:
		if not (e.alive and e.owner == pid and e.is_building() and e.built and e.def.has("conversion")):
			continue
		var cv: Dictionary = e.def["conversion"]
		var src: String = cv["de"]
		var need := int(cv["consume_min"]) * P / 60 # milésimas por segundo
		var reserve := int(p.get("reserva_" + src, 0))
		var acc_k := "%d:conv:%d" % [pid, e.id]
		var owed := int(_acc.get(acc_k, 0)) # milésimas consumidas que todavía no se descontaron
		var pct := 100
		if (int(p["res"].get(src, 0)) - reserve) * P - owed >= need:
			owed += need
			var whole := owed / P
			p["res"][src] = int(p["res"][src]) - whole
			_acc[acc_k] = owed - whole * P
		elif reserve == 0:
			pct = int(cv.get("piso_pct", 0))
		else:
			pct = 0
		if pct > 0:
			for k in cv["da"]:
				_gain(pid, k, int(cv["da"][k]) * P / 60 * pct / 100 * boost / 100, "propio")


## Renta: edificios que producen sin aldeanos (gult etíope, barrios del puerto).
func _rents(pid: int, _p: Dictionary) -> void:
	var capital: SimEntity = null
	for e in sim.actives:
		if e.alive and e.owner == pid and e.is_building() and e.capital:
			capital = e
			break
	for e in sim.actives:
		if e.alive and e.owner == pid and e.is_building() and e.built and e.def.has("renta") and e.mode != "regimiento":
			var r: Dictionary = e.def["renta"]
			# Renta mejor cerca de la capital (gult etíope junto a la corte).
			var mult := 1
			if e.def.has("renta_cerca_capital") and capital != null and Sim.dist(e.x, e.y, capital.x, capital.y) <= int(e.def.get("radio_capital", 14000)):
				r = e.def["renta_cerca_capital"]
				if sim.tick < int(sim.players[pid].get("fiesta_until", 0)):
					mult = 2 # fiesta de llegada de la corte
			var origin := "propio" if e.def.get("motor", false) else "renta"
			var boost := 100 + sim.mod(pid, "motor") if e.def.get("motor", false) else 100
			for k in r:
				_gain(pid, k, int(r[k]) * mult * P / 60 * (boost if k == "riqueza" else 100) / 100, origin)
	if has(pid, "corte_extrae") and capital != null:
		var src := capital
		for e in sim.actives:
			if e.alive and e.owner == pid and e.is_building() and e.built and e.def.get("capital_fija", false):
				src = e # Gondar extrae desde su lugar, con su propio radio y ritmo
				break
		_court_extract(pid, src)


## La corte etíope extrae riqueza sin aldeanos de la arcilla propia o del centro
## cercana (nunca de la del rival). Lo del centro cuenta para el techo de lo disputado.
func _court_extract(pid: int, court: SimEntity) -> void:
	var cfg := m(pid, "corte_extrae")
	var by_age: Array = cfg["por_edad"]
	var per_min := int(by_age[clampi(int(sim.players[pid]["age"]) - 1, 0, by_age.size() - 1)])
	var radius := int(cfg.get("radio", 12000))
	if court.def.get("capital_fija", false):
		per_min = int(court.def.get("extrae_min", per_min))
		radius = int(court.def.get("extrae_radio", radius))
	var r := radius + court.w * P / 2 + 1000 # borde a borde, aproximado
	var best: SimEntity = null
	var best_d := 1 << 60
	for t in sim.entities:
		if t.alive and t.is_resource() and t.type == "riqueza" and t.amount > 0 and (t.res_owner == pid or t.res_owner < 0):
			var d := Sim.dist(t.x, t.y, court.x, court.y)
			if d <= r and (d < best_d or (d == best_d and best != null and t.id < best.id)):
				best = t
				best_d = d
	if best == null:
		return
	var k := "%d:corte" % pid
	var acc: int = int(_acc.get(k, 0)) + per_min * P / 60
	var whole := mini(acc / P, best.amount)
	if best.res_owner < 0:
		whole = mini(whole, sim.disputed_room(pid))
	_acc[k] = acc - (acc / P) * P
	if whole <= 0:
		return
	best.amount -= whole
	sim.players[pid]["res"]["riqueza"] = int(sim.players[pid]["res"]["riqueza"]) + whole
	sim.ledger(pid, "disputado" if best.res_owner < 0 else "propio", "riqueza", whole)
	if best.res_owner < 0:
		sim.disputed_add(pid, whole)
	if best.amount <= 0:
		sim._exhaust(best)


## Acogida: la población llega sola según la fama (Palmares).
func _welcome(pid: int, p: Dictionary) -> void:
	var cfg := m(pid, "acogida")
	var key: String = cfg["recurso"]
	var cost: int = cfg["costo"]
	if int(p["res"].get(key, 0)) < cost or p["pop"] >= p["pop_cap"]:
		return
	# "Guardar fama para el hito" (prendido por defecto): no gasta la fama que pide el próximo hito.
	if p.get("guardar_" + key, true) and int(p["res"].get(key, 0)) - cost < sim.hito_extra_need(pid, key):
		return
	var home: SimEntity = null
	for e in sim.actives:
		if e.alive and e.owner == pid and e.is_building() and e.built and (e.capital or e.def.get("acoge", false)):
			home = e
			break
	if home == null:
		return
	p["res"][key] -= cost
	var u := sim.spawn_near(home, "aldeano")
	sim.events.append({"t": "trained", "id": u.id, "player": pid, "type": "aldeano"})
	if has(pid, "oficios"):
		craft_assign(u)


# ---------------------------------------------------------------- Ganado (mapuches)

## Corrales: cría, renta por cabeza y cabezas arreadas que llegan
## (docs/diseno/revision-economia/v3/04, §3.5.2).
func _herds(pid: int) -> void:
	var boost := 100 + sim.mod(pid, "motor")
	var heads_total := 0
	var breed_bonus_ms := 0
	for e in sim.actives:
		if e.alive and e.owner == pid and e.is_building() and e.built and e.def.has("cria_ms"):
			breed_bonus_ms = int(e.def["cria_ms"])
	for e in sim.actives:
		if not (e.alive and e.owner == pid and e.is_building() and e.def.has("ganado")):
			continue
		var g: Dictionary = e.def["ganado"]
		if not e.built:
			continue
		if e.heads == 0 and e.breed_ms == 0 and e.feast_age == 0:
			e.heads = int(g.get("inicial", 1)) # recién terminado
		var cap := corral_cap(e)
		var every := breed_bonus_ms if breed_bonus_ms > 0 else int(g["cria_ms"])
		if e.heads < cap and sim.tick >= e.feast_until:
			e.breed_ms += 1000
			if e.breed_ms >= every:
				e.breed_ms = 0
				e.heads += 1
		heads_total += e.heads
	if heads_total > 0:
		var per := 4
		for e in sim.actives:
			if e.alive and e.owner == pid and e.def.has("ganado"):
				per = int(e.def["ganado"]["riqueza_por_cabeza"])
				break
		_gain(pid, "riqueza", heads_total * per * P / 60 * boost / 100, "propio")
	# Cabezas arreadas: al llegar a un corral propio entran, o dan alimento si no hay lugar.
	if has(pid, "arreo"):
		var cfg := m(pid, "arreo")
		for u in sim.actives:
			if not (u.alive and u.owner == pid and u.type == cfg["unidad"]):
				continue
			var c := _nearest_corral(pid, u.x, u.y, false)
			if c == null:
				continue
			if Sim.dist(u.x, u.y, c.x, c.y) <= 2500:
				var room := _nearest_corral(pid, u.x, u.y, true)
				if room != null and Sim.dist(u.x, u.y, room.x, room.y) <= 2500:
					room.heads += 1
				else:
					sim.players[pid]["res"]["alimento"] = int(sim.players[pid]["res"]["alimento"]) + int(cfg["comida_si_lleno"])
					sim.ledger(pid, "arreo", "alimento", int(cfg["comida_si_lleno"]))
				sim.remove_quietly(u)
			elif u.order == SimEntity.Order.IDLE:
				var dest := _nearest_corral(pid, u.x, u.y, true)
				if dest == null:
					dest = c
				sim.order_move(u, dest.x, dest.y)


## Tope de cabezas: más en pradera abierta (sin árboles a 3 casillas).
func corral_cap(e: SimEntity) -> int:
	var g: Dictionary = e.def["ganado"]
	var open_land := true
	for t in sim.resources_near(e.tx + e.w / 2, e.ty + e.h / 2, e.w / 2 + 3):
		if t.type == "arbol":
			open_land = false
			break
	return mini(6, int(g["max_pradera"] if open_land else g["max"]))


func _nearest_corral(pid: int, x: int, y: int, with_room: bool) -> SimEntity:
	var best: SimEntity = null
	var best_d := 1 << 60
	for e in sim.actives:
		if e.alive and e.owner == pid and e.is_building() and e.built and e.def.has("ganado"):
			if with_room and e.heads >= corral_cap(e):
				continue
			var d := Sim.dist(x, y, e.x, e.y)
			if d < best_d or (d == best_d and best != null and e.id < best.id):
				best = e
				best_d = d
	return best


## Kawiñ: alimento por cada cabeza menos una; 120 s sin cría; una vez por corral y por
## edad; no en combate.
func feast(e: SimEntity) -> void:
	if not e.def.has("ganado") or not e.built:
		return
	var age := int(sim.players[e.owner]["age"])
	if e.feast_age == age or e.heads <= 1 or sim.tick - e.last_combat < 100:
		return
	var g: Dictionary = e.def["ganado"]
	var eaten := e.heads - 1
	e.heads = 1
	e.feast_age = age
	e.feast_until = sim.tick + int(g["fiesta_pausa_ms"]) / sim.tick_ms
	var food := eaten * int(g["fiesta_alimento"])
	sim.players[e.owner]["res"]["alimento"] = int(sim.players[e.owner]["res"]["alimento"]) + food
	sim.ledger(e.owner, "kawin", "alimento", food)
	sim.events.append({"t": "kawin", "id": e.id, "player": e.owner, "n": eaten})


# ---------------------------------------------------------------- Oficios (Palmares)

## Puesto libre en el edificio que acoge más cercano a la capital (empate por id),
## dentro del tope por edad. Devuelve true si la persona entró a trabajar.
func craft_assign(u: SimEntity) -> bool:
	var pid := u.owner
	var cfg := m(pid, "oficios")
	var tops: Array = cfg["tope_por_edad"]
	var cap := int(tops[clampi(int(sim.players[pid]["age"]) - 1, 0, tops.size() - 1)])
	var total := 0
	var cap_b: SimEntity = null
	for e in sim.actives:
		if e.alive and e.owner == pid and e.is_building():
			total += e.crafts.size()
			if e.capital:
				cap_b = e
	if total >= cap:
		return false
	var best: SimEntity = null
	var best_d := 1 << 60
	for e in sim.actives:
		if not (e.alive and e.owner == pid and e.is_building() and e.built):
			continue
		var slots := int(cfg["puestos"].get(e.type, 0))
		if slots <= e.crafts.size():
			continue
		var d := Sim.dist(e.x, e.y, cap_b.x, cap_b.y) if cap_b != null else 0
		if d < best_d or (d == best_d and best != null and e.id < best.id):
			best = e
			best_d = d
	if best == null:
		return false
	u.inside = best.id
	u.order = SimEntity.Order.IDLE
	u.path.clear()
	u.x = best.x
	u.y = best.y
	best.crafts.append(u.id)
	sim.events.append({"t": "garrison", "id": u.id, "building": best.id})
	return true


## Los oficios rinden riqueza salvo que el edificio esté bajo asedio de verdad:
## perdió el 2 % de la vida en 5 s o tiene 3 o más enemigos a 6 casillas.
func _crafts_yield(pid: int) -> void:
	if not has(pid, "oficios"):
		return
	var cfg := m(pid, "oficios")
	var boost := 100 + sim.mod(pid, "motor")
	var per := int(cfg["por_min"])
	var working := 0
	for e in sim.actives:
		if not (e.alive and e.owner == pid and e.is_building() and not e.crafts.is_empty()):
			continue
		if craft_stopped(e):
			continue
		working += e.crafts.size()
	if working > 0:
		_gain(pid, "riqueza", working * per * P / 60 * boost / 100, "propio")


func craft_stopped(e: SimEntity) -> bool:
	var cfg := m(e.owner, "oficios")
	var hits: Array = _craft_hits.get(e.id, [])
	var dmg := 0
	for h in hits:
		if sim.tick - int(h[0]) <= 50:
			dmg += int(h[1])
	if dmg * 100 >= e.hp_max * int(cfg.get("para_pct", 2)):
		return true
	var r := int(cfg.get("para_radio", 6000))
	var n := 0
	for o in sim.actives:
		if o.alive and o.owner >= 0 and o.owner != e.owner and o.is_military() and o.inside < 0 and absi(o.x - e.x) <= r and absi(o.y - e.y) <= r:
			n += 1
	return n >= int(cfg.get("para_enemigos", 3))


## Relevo: las unidades fuera de combate se curan.
func _regen() -> void:
	for e in sim.actives:
		if not e.alive or not e.is_unit() or e.hp >= e.hp_max or not has(e.owner, "relevo"):
			continue
		var cfg := m(e.owner, "relevo")
		if sim.tick - e.last_combat < int(cfg["espera_ms"]) / sim.tick_ms:
			continue
		e.hp = mini(e.hp_max, e.hp + maxi(1, e.hp_max * int(cfg["pct_por_seg"]) / 100))


## Sitios sagrados: captura por presencia exclusiva, renta de riqueza y victoria por control total.
func _sacred() -> void:
	var cfg: Dictionary = sim.data.reglas["sitios"]
	var sites: Array[SimEntity] = []
	for b in sim.actives:
		if b.alive and b.def.get("sagrado", false):
			sites.append(b)
	if sites.is_empty():
		return
	var r: int = cfg["radio"]
	for site in sites:
		var present := {}
		for u in sim.actives:
			if u.alive and u.is_unit() and u.owner >= 0 and u.inside < 0 and absi(u.x - site.x) <= r and absi(u.y - site.y) <= r:
				present[u.owner] = true
		if present.size() != 1:
			continue
		var who: int = present.keys()[0]
		if site.holder == who:
			site.capture = 0
			continue
		if site.aux != who:
			site.aux = who
			site.capture = 0
		site.capture += 1000
		if site.capture >= int(cfg["captura_ms"]):
			site.holder = who
			site.capture = 0
			sim.events.append({"t": "sitio", "id": site.id, "player": who})
	var holds := {}
	for site in sites:
		if site.holder >= 0:
			holds[site.holder] = int(holds.get(site.holder, 0)) + 1
			# Renta decreciente: 18 / 12 / 8 por el 1.º, 2.º y 3.º sitio del mismo jugador.
			var rank := int(holds[site.holder]) - 1
			var rents: Array = cfg.get("renta_por_cantidad", [cfg["renta_riqueza"]])
			_gain(site.holder, "riqueza", int(rents[mini(rank, rents.size() - 1)]) * P / 60, "sitios")
	for p in sim.players:
		var pid: int = p["id"]
		if int(holds.get(pid, 0)) == sites.size() and not p["defeated"]:
			p["sitios_ms"] = int(p.get("sitios_ms", 0)) + 1000
			if p["sitios_ms"] >= int(cfg["victoria_ms"]) and not sim.game_over:
				sim.win(pid)
		else:
			p["sitios_ms"] = 0


# ---------------------------------------------------------------- Caminos

func on_building_placed(b: SimEntity) -> void:
	if b.def.get("camino", false):
		for yy in range(b.ty, b.ty + b.h):
			for xx in range(b.tx, b.tx + b.w):
				_roads[yy * sim.map.n + xx] = 1


func on_building_removed(b: SimEntity) -> void:
	if _tambo_of.has(b.id):
		_respawns.append([_tambo_of[b.id], b.tx, b.ty, sim.tick + 360000 / sim.tick_ms])
		_tambo_of.erase(b.id)
	if b.def.get("camino", false):
		for yy in range(b.ty, b.ty + b.h):
			for xx in range(b.tx, b.tx + b.w):
				_roads[yy * sim.map.n + xx] = 0
	_connected.erase(b.id)


func on_road(e: SimEntity) -> bool:
	var tx := e.x / P
	var ty := e.y / P
	return sim.map.in_bounds(tx, ty) and _roads[ty * sim.map.n + tx] != 0


## Edificios unidos a la capital por caminos u otros edificios propios (8 vecinos).
func _update_connection(pid: int) -> void:
	var n := sim.map.n
	var start: SimEntity = null
	for e in sim.actives:
		if e.alive and e.owner == pid and e.capital:
			start = e
			break
	for e in sim.actives:
		if e.owner == pid and e.is_building():
			_connected.erase(e.id)
	var linked := {}
	_clay_linked[pid] = linked
	if start == null:
		return
	var seen := PackedByteArray()
	seen.resize(n * n)
	var queue: Array[Vector2i] = []
	for yy in range(start.ty, start.ty + start.h):
		for xx in range(start.tx, start.tx + start.w):
			queue.append(Vector2i(xx, yy))
			seen[yy * n + xx] = 1
	var head := 0
	while head < queue.size():
		var c := queue[head]
		head += 1
		var occ := sim.map.occupant(c.x, c.y)
		if occ >= 0:
			_connected[occ] = true
		for dy in [-1, 0, 1]:
			for dx in [-1, 0, 1]:
				var nx: int = c.x + dx
				var ny: int = c.y + dy
				if not sim.map.in_bounds(nx, ny) or seen[ny * n + nx] != 0:
					continue
				var o := sim.map.occupant(nx, ny)
				var ob: SimEntity = sim.by_id.get(o)
				if ob != null and ob.is_resource() and ob.type == "riqueza":
					linked[ob.id] = true # arcilla tocada por la red de caminos
				if ob == null or ob.owner != pid or not ob.is_building():
					continue
				seen[ny * n + nx] = 1
				queue.append(Vector2i(nx, ny))


## Capa 1 inca (§3.5.1): la arcilla que toca la red de caminos unida a la llaqta
## se saca más rápido.
func clay_bonus(pid: int, t: SimEntity) -> int:
	if not has(pid, "caminos") or not (_clay_linked.get(pid, {}) as Dictionary).has(t.id):
		return 0
	return int(m(pid, "caminos").get("arcilla_pct", 0))


func connected(b: SimEntity) -> bool:
	return _connected.has(b.id)


## Multiplicador de producción e investigación (porcentaje).
func production_pct(b: SimEntity) -> int:
	if not has(b.owner, "caminos"):
		return 100
	var cfg := m(b.owner, "caminos")
	return 100 + int(cfg["bono_conectado_pct"]) if connected(b) else 100 - int(cfg.get("penal_desconectado_pct", 0))


# ---------------------------------------------------------------- Movimiento y combate

func speed(e: SimEntity) -> int:
	var s := e.speed
	if e.slow_until > sim.tick:
		s = s * 55 / 100
	if _roads[clampi(e.y / P, 0, sim.map.n - 1) * sim.map.n + clampi(e.x / P, 0, sim.map.n - 1)] != 0:
		var pct := 30
		for p in sim.players:
			if has(p["id"], "caminos"):
				pct = int(m(p["id"], "caminos")["velocidad_pct"])
		s = s * (100 + pct) / 100
	return s


## Ajuste del daño por módulos del atacante y del objetivo.
func damage(a: SimEntity, t: SimEntity, dmg: int) -> int:
	if t.owner >= 0 and has(t.owner, "defensa_altura") and t.is_unit():
		var dh := sim.map.h_at(t.x / P, t.y / P) - sim.map.h_at(a.x / P, a.y / P)
		if dh > 0:
			dmg = dmg * (100 - int(m(t.owner, "defensa_altura")["pct"])) / 100
	if a.is_unit() and has(a.owner, "sigilo") and a.last_combat < sim.tick - 50 and is_hidden_now(a):
		dmg = dmg * (100 + int(m(a.owner, "sigilo").get("emboscada_pct", 0))) / 100
	return maxi(1, dmg)


func on_hit(a: SimEntity, t: SimEntity, dmg: int) -> void:
	a.last_combat = sim.tick
	t.last_combat = sim.tick
	if t.is_building() and t.def.has("ganado") and t.hp_max > 0:
		# Cada 25 % de vida perdida mata una cabeza (nunca por debajo de 1; reparar no las devuelve).
		var q := (t.hp_max - maxi(0, t.hp - dmg)) * 4 / t.hp_max
		if q > t.dmg_q:
			t.heads = maxi(mini(t.heads, 1), t.heads - (q - t.dmg_q))
			t.dmg_q = q
	if a.owner >= 0 and t.owner >= 0 and a.owner != t.owner and has(a.owner, "arreo") and t.is_building() and (t.def.get("fuente", "") == "alimento" or int(t.def.get("pob", 0)) > 0 or t.def.has("ganado")):
		_drive(a, t, dmg)
	if t.is_building() and not t.crafts.is_empty():
		var hits: Array = _craft_hits.get_or_add(t.id, [])
		hits.append([sim.tick, dmg])
		while not hits.is_empty() and sim.tick - int(hits[0][0]) > 50:
			hits.pop_front()
	if a.def.has("frena_ms") and t.is_unit():
		t.slow_until = sim.tick + int(a.def["frena_ms"]) / sim.tick_ms
	if a.owner >= 0 and t.owner >= 0 and has(a.owner, "saqueo") and t.is_building():
		var cfg := m(a.owner, "saqueo")
		_gain(a.owner, cfg["recurso"], dmg * int(cfg["pct_danio_edificio"]) * P / 100, "saqueo")


# ---------------------------------------------------------------- Ingenios neutrales (§3.2)

## Botín único del ingenio, según la edad de quien lo destruye; cuenta para el techo de
## lo disputado. Los mapuches arrean cabezas y Palmares libera gente. Se rehace solo.
func _neutral_loot(e: SimEntity, pid: int) -> void:
	var age := int(sim.players[pid]["age"])
	var table: Array = e.def["botin_por_edad"]
	var loot := mini(int(table[clampi(age - 1, 0, table.size() - 1)]), sim.disputed_room(pid))
	if loot > 0:
		sim.players[pid]["res"]["riqueza"] = int(sim.players[pid]["res"]["riqueza"]) + loot
		sim.disputed_add(pid, loot)
		sim.ledger(pid, "ingenio", "riqueza", loot)
	if has(pid, "arreo"):
		for i in int(e.def.get("cabezas", 2)):
			var u := sim.spawn_near(e, m(pid, "arreo")["unidad"], pid)
			sim.events.append({"t": "arreo", "id": u.id, "player": pid})
	if has(pid, "liberacion"):
		var people: Array = e.def.get("liberados_por_edad", [])
		var n := int(people[clampi(age - 1, 0, people.size() - 1)]) if not people.is_empty() else 0
		var kp: Dictionary = sim.players[pid]
		for i in n:
			if int(kp["pop"]) + i < int(kp["pop_cap"]):
				var u := sim.spawn_near(e, "aldeano", pid)
				sim.events.append({"t": "freed", "id": u.id, "player": pid})
	sim.events.append({"t": "notice", "player": pid, "text": "Ingenio destruido: +%d de riqueza" % loot})
	_respawns.append([e.type, e.tx, e.ty, sim.tick + int(e.def.get("rehace_ms", 360000)) / sim.tick_ms])


## Regalo de cumbi (Tawantinsuyu, §3.5.1): en la edad III, mit'a por el ingenio de su
## mitad del mapa. Cobra el botín sin pelear y queda un tambo inca sin flechas; si lo
## destruyen, el ingenio vuelve a los 6 minutos.
func cumbi_target(pid: int) -> SimEntity:
	if not has(pid, "regalo_cumbi"):
		return null
	var cap: SimEntity = null
	var rivals: Array[SimEntity] = []
	for e in sim.actives:
		if e.alive and e.is_building() and e.capital:
			if e.owner == pid:
				cap = e
			elif e.owner >= 0:
				rivals.append(e)
	if cap == null:
		return null
	var best: SimEntity = null
	var best_d := 1 << 60
	for e in sim.actives:
		if not (e.alive and e.owner < 0 and e.def.has("botin_por_edad")):
			continue
		var mine := Sim.dist(e.x, e.y, cap.x, cap.y)
		var theirs := 1 << 60
		for r in rivals:
			theirs = mini(theirs, Sim.dist(e.x, e.y, r.x, r.y))
		if mine < theirs and mine < best_d:
			best = e
			best_d = mine
	return best


func cumbi_gift(pid: int) -> void:
	var cfg := m(pid, "regalo_cumbi")
	var p: Dictionary = sim.players[pid]
	var t := cumbi_target(pid)
	if t == null or int(p["age"]) < int(cfg.get("edad", 3)) or int(p["res"].get(cfg["recurso"], 0)) < int(cfg["costo"]):
		return
	p["res"][cfg["recurso"]] = int(p["res"][cfg["recurso"]]) - int(cfg["costo"])
	var age := int(p["age"])
	var table: Array = t.def["botin_por_edad"]
	var loot := mini(int(table[clampi(age - 1, 0, table.size() - 1)]), sim.disputed_room(pid))
	if loot > 0:
		p["res"]["riqueza"] = int(p["res"]["riqueza"]) + loot
		sim.disputed_add(pid, loot)
		sim.ledger(pid, "cumbi", "riqueza", loot)
	var tx := t.tx
	var ty := t.ty
	var kind := t.type
	sim.remove_quietly(t)
	sim.map.clear(tx, ty, t.w, t.h)
	var tambo := sim.spawn_building(str(cfg["edificio"]), pid, tx, ty, true)
	_tambo_of[tambo.id] = kind
	sim.events.append({"t": "notice", "player": pid, "text": "Regalo de cumbi: el ingenio pasa a ser un tambo (+%d de riqueza)" % loot})


## Los ingenios destruidos vuelven si no hay soldados a 12 casillas.
func _respawn_neutrals() -> void:
	var keep: Array = []
	for r in _respawns:
		if sim.tick < int(r[3]):
			keep.append(r)
			continue
		var c := Vector2i(int(r[1]) * P + P, int(r[2]) * P + P)
		var busy := false
		for u in sim.actives:
			if u.alive and u.is_unit() and u.owner >= 0 and absi(u.x - c.x) <= 12 * P and absi(u.y - c.y) <= 12 * P:
				busy = true
				break
		if busy or not sim.map.is_free_rect(int(r[1]), int(r[2]), 3, 3):
			keep.append(r)
			continue
		sim.spawn_building(r[0], -1, int(r[1]), int(r[2]), true)
	_respawns = keep


## Malón = arreo: cada `danio_por_cabeza` de daño real a granjas, casas o corrales
## suelta una cabeza que camina al corral propio (máximo por minuto y techo de lo
## disputado: cada cabeza cuenta como riqueza disputada).
func _drive(a: SimEntity, t: SimEntity, dmg: int) -> void:
	var cfg := m(a.owner, "arreo")
	var k := "%d:arreo" % a.owner
	var acc: int = int(_acc.get(k, 0)) + dmg
	var per := int(cfg["danio_por_cabeza"])
	if acc < per:
		_acc[k] = acc
		return
	_acc[k] = acc - per
	var mk := "%d:arreo_min" % a.owner
	var minute := sim.tick / 600
	var used: Array = _acc.get(mk, [minute, 0])
	if int(used[0]) != minute:
		used = [minute, 0]
	if int(used[1]) >= int(cfg["max_por_min"]) or sim.disputed_room(a.owner) < int(cfg["cuenta_disputado"]):
		_acc[mk] = used
		return
	used[1] = int(used[1]) + 1
	_acc[mk] = used
	sim.disputed_add(a.owner, int(cfg["cuenta_disputado"]))
	var u := sim.spawn_near(t, cfg["unidad"], a.owner)
	sim.ledger(a.owner, "arreo", "cabezas", 1)
	sim.events.append({"t": "arreo", "id": u.id, "player": a.owner})


func on_kill(e: SimEntity, killer: SimEntity) -> void:
	if killer != null and killer.owner >= 0 and e.owner < 0 and e.def.has("botin_por_edad"):
		_neutral_loot(e, killer.owner)
		return
	if killer == null or killer.owner < 0 or e.owner < 0 or killer.owner == e.owner:
		return
	if has(killer.owner, "saqueo") and e.fn == "civil":
		var cfg := m(killer.owner, "saqueo")
		var loot := int(cfg.get("por_aldeano", 0))
		if cfg["recurso"] == "riqueza":
			loot = mini(loot, sim.disputed_room(killer.owner))
			sim.disputed_add(killer.owner, loot)
		sim.players[killer.owner]["res"][cfg["recurso"]] = int(sim.players[killer.owner]["res"].get(cfg["recurso"], 0)) + loot
		sim.ledger(killer.owner, "saqueo", cfg["recurso"], loot)
	# Liberación (Palmares): solo de edificios habitados (casas, centros, los que suman
	# población). Por encima del techo de población, cada persona da fama; los
	# liberados vuelven a pie a la capital (docs/diseno/revision-economia/v3/04, §3.5.5).
	var inhabited: bool = e.capital or int(e.def.get("pob", 0)) > 0 or bool(e.def.get("acoge", false))
	if has(killer.owner, "liberacion") and e.is_building() and e.built and inhabited:
		var lib := m(killer.owner, "liberacion")
		var n: int = lib.get("por_edificio", {}).get(e.type, int(lib.get("aldeanos", 1)))
		var kp: Dictionary = sim.players[killer.owner]
		var home: SimEntity = null
		for b in sim.actives:
			if b.alive and b.owner == killer.owner and b.is_building() and b.capital:
				home = b
				break
		for i in n:
			if int(kp["pop"]) + i >= int(kp["pop_cap"]):
				var fame := int(lib.get("fama_si_lleno", 28))
				kp["res"]["fama"] = int(kp["res"].get("fama", 0)) + fame
				sim.ledger(killer.owner, "liberacion", "fama", fame)
				continue
			var u := sim.spawn_near(e, "aldeano", killer.owner)
			sim.events.append({"t": "freed", "id": u.id, "player": killer.owner})
			if home != null:
				sim.push_command({"t": "move", "player": killer.owner, "ids": [u.id], "x": home.x, "y": home.y})


# ---------------------------------------------------------------- Sigilo

## Oculta por su civilización ahora: unidades junto a árboles o edificios marcados como ocultos.
func is_hidden_now(e: SimEntity) -> bool:
	if e.owner < 0 or not has(e.owner, "sigilo"):
		return false
	if e.is_building():
		return e.def.get("oculto", false)
	if not e.is_unit():
		return false
	var tx := e.x / P
	var ty := e.y / P
	for dy in [-1, 0, 1]:
		for dx in [-1, 0, 1]:
			var o: SimEntity = sim.by_id.get(sim.map.occupant(tx + dx, ty + dy))
			if o != null and o.is_resource() and o.res_kind == "madera":
				return true
	return false


## ¿`viewer` detecta a `e`? Solo si alguna entidad suya está dentro del radio de detección.
func detected_by(e: SimEntity, viewer: int) -> bool:
	if not is_hidden_now(e):
		return true
	var r: int = m(e.owner, "sigilo").get("radio_deteccion", 3000)
	for o in sim.actives:
		if o.alive and o.owner == viewer and (o.is_unit() or o.is_building()) and o.inside < 0:
			if absi(o.x - e.x) <= r + 2000 and absi(o.y - e.y) <= r + 2000 and sim.dist_to(o, e) <= r:
				return true
	return false


# ---------------------------------------------------------------- Construcción

## Paso de obra por constructor con n constructores (común: decreciente; potirõ: creciente).
func build_step(b: SimEntity, nb: int) -> int:
	var t := sim.tick_ms
	if has(b.owner, "obra_colectiva"):
		var pct: int = m(b.owner, "obra_colectiva")["pct_por_constructor"]
		return t * (100 + pct * (nb - 1)) / (100 * nb)
	if sim.data.reglas["construccion_decreciente"]:
		return t * (nb + 2) / (3 * nb)
	return t
