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
# --- paso 7 --- maravillas (ver «Maravillas»)
var _wfx := {} # jugador -> {tipo: efecto} de su maravilla terminada en pie (se rehace cada segundo)
var _slow := {} # casilla -> [dueño, pct]: agua que frena a sus enemigos (inundación, crecida)
var _wmask := {} # clave -> [tick, {casilla: true}]: casillas bajas junto al agua (se rehace cada tanto)
var _protected: Array = [] # [dueño, x, y, radio] de los koyagtun sin enemigos dentro
var traps: Array[SimEntity] = [] # --- paso 6 --- hoyos con estacas (mapuches), ver «Trampas»


var site_guard := {} # --- esport 3a --- id de sitio -> población militar del equipo dueño a guarnicion_radio (cada segundo)
var mando := {} # --- paso 6, par 2 --- id de unidad -> ataque extra por un capitão de mocambo cerca (cada segundo)


## --- paso 6, par 3 --- Lo que cuenta como fuerte para los defensores de Suan Phlu.
const FUERTES := ["torre", "fortaleza", "fortaleza_rio"]

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
		if p.has("ruta_req"): # --- paso 6, par 2 --- pólvora de Massawa: ¿la ruta sigue abierta?
			p["ruta"] = sim.comercio.route_open(pid) if p.get("ruta_comercio", false) else _has_built(pid, p["ruta_req"]) # --- comercio ---
		_conversions(pid, p)
		_crafts_yield(pid)
		_herds(pid)
		if has(pid, "acogida"):
			_welcome(pid, p)
		if has(pid, "caminos") and sim.tick % 50 == 0:
			_update_connection(pid)
	_regen()
	_command_aura() # --- paso 6, par 2 ---
	_wonder_tick() # --- paso 7 --- antes de los sitios (koyagtun)
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
	for e in sim.owned(pid):
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
	# Lo que pasa del tope se pierde: tampoco cuenta como juntado (puntaje).
	var over := int(p["res"].get(key, 0)) - cap
	if not wonder_fx(pid, "fama_sin_tope").is_empty(): # --- paso 7 --- la Cerca de la Barriga en pie
		over = 0
		cap = maxi(cap, int(p["res"].get(key, 0)))
	if over > 0:
		sim.ledger(pid, "propio", key, -over)
	p["res"][key] = mini(p["res"].get(key, 0), cap)
	p["tope_" + key] = cap


## Tope extra de tributo por elefante (barrio chino, junco): el mayor, no se suman.
func tribute_cap_bonus(pid: int) -> int:
	var best := 0
	for e in sim.buildings_of(pid):
		if e.alive and e.owner == pid and e.is_building() and e.built:
			best = maxi(best, int(e.def.get("tributo_tope_extra", 0)))
	return best


## Piezas extra de motor que dan los hitos ("maximo_extra": {"tipo": n} en el hito).
func engine_max_bonus(pid: int, type: String) -> int:
	var extra := 0
	for e in sim.buildings_of(pid):
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
	for e in sim.buildings_of(pid):
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
	for e in sim.buildings_of(pid):
		if e.alive and e.owner == pid and e.is_building() and e.capital:
			capital = e
			break
	for e in sim.buildings_of(pid):
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
			# --- paso 7 --- Fasil Gəbbi en pie: los gult de todo el mapa rinden más.
			var wr := wonder_fx(pid, "renta_pct")
			var wpct := 100 + int(wr["pct"]) if not wr.is_empty() and (wr.get("tipos", []) as Array).has(e.type) else 100
			wpct = wpct * (100 + sim.mod(pid, "renta_pct:" + e.type)) / 100 # --- paso 6, par 2 --- actas de tierra (gult)
			for k in r:
				_gain(pid, k, int(r[k]) * mult * P / 60 * (boost if k == "riqueza" else 100) / 100 * wpct / 100, origin)
	# --- paso 6 --- Renta que dan las mejoras a un tipo de edificio (makuñ: cada lof da riqueza).
	var extra: Dictionary = sim.players[pid].get("renta_tipos", {})
	if not extra.is_empty():
		for e in sim.buildings_of(pid):
			if e.alive and e.owner == pid and e.is_building() and e.built and extra.has(e.type):
				var r2: Dictionary = extra[e.type]
				for k in r2:
					_gain(pid, k, int(r2[k]) * P / 60, "renta")
	if has(pid, "corte_extrae") and capital != null:
		var src := capital
		for e in sim.buildings_of(pid):
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
	var wa := wonder_fx(pid, "acogida_pct") # --- paso 7 --- la Cerca de la Barriga: la acogida cuesta menos
	if not wa.is_empty():
		cost = cost * int(wa["pct"]) / 100
	if int(p["res"].get(key, 0)) < cost or p["pop"] >= p["pop_cap"] or p.get("acogida_pausa", false):
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
	# --- paso 6, par 2 --- Kilombo: de cada `cada` que llegan, uno entra como gente de guerra.
	var kind := "aldeano"
	if p.has("kilombo"):
		var kb: Dictionary = p["kilombo"]
		kb["n"] = int(kb["n"]) + 1
		if int(kb["n"]) % int(kb["cada"]) == 0:
			kind = kb["tipo"]
	var u := sim.spawn_near(home, kind)
	sim.events.append({"t": "trained", "id": u.id, "player": pid, "type": kind})
	if kind == "aldeano" and has(pid, "oficios"):
		craft_assign(u)


# ---------------------------------------------------------------- Ganado (mapuches)

## Corrales: cría, renta por cabeza y cabezas arreadas que llegan
## (docs/diseno/revision-economia/v3/04, §3.5.2).
func _herds(pid: int) -> void:
	var boost := 100 + sim.mod(pid, "motor")
	var heads_total := 0
	var breed_bonus_ms := 0
	for e in sim.buildings_of(pid):
		if e.alive and e.owner == pid and e.is_building() and e.built and e.def.has("cria_ms"):
			breed_bonus_ms = int(e.def["cria_ms"])
	for e in sim.buildings_of(pid):
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
		for e in sim.owned(pid):
			if e.alive and e.owner == pid and e.def.has("ganado"):
				per = int(e.def["ganado"]["riqueza_por_cabeza"])
				break
		_gain(pid, "riqueza", heads_total * per * P / 60 * boost / 100, "propio")
	# Cabezas arreadas: al llegar a un corral propio entran, o dan alimento si no hay lugar.
	if has(pid, "arreo"):
		var cfg := m(pid, "arreo")
		for u in sim.owned(pid):
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
	var cap := mini(6, int(g["max_pradera"] if open_land else g["max"]))
	return cap * (100 + sim.mod(e.owner, "corral_pct")) / 100 # --- paso 6 --- arreo en tropilla


func _nearest_corral(pid: int, x: int, y: int, with_room: bool) -> SimEntity:
	var best: SimEntity = null
	var best_d := 1 << 60
	for e in sim.buildings_of(pid):
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
	for e in sim.buildings_of(pid):
		if e.alive and e.owner == pid and e.is_building():
			total += e.crafts.size()
			if e.capital:
				cap_b = e
	if total >= cap:
		return false
	var best: SimEntity = null
	var best_d := 1 << 60
	for e in sim.buildings_of(pid):
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
	var boost := 100 + sim.mod(pid, "motor") + sim.mod(pid, "oficios_pct") # --- paso 6, par 2 --- forja de los mocambos
	var per := int(cfg["por_min"])
	var working := 0
	for e in sim.buildings_of(pid):
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
	for o in sim.military():
		if o.alive and o.owner >= 0 and sim.enemies(e.owner, o.owner) and o.is_military() and o.inside < 0 and absi(o.x - e.x) <= r and absi(o.y - e.y) <= r:
			n += 1
	return n >= int(cfg.get("para_enemigos", 3))


## Relevo: las unidades fuera de combate se curan. --- paso 6 --- El lawen mapuche cura más
## (`relevo_pct`); los remedios del monte guaraníes (`regen_monte`) curan a la tropa junto al monte.
func _regen() -> void:
	for e in sim.all_units():
		if not e.alive or not e.is_unit() or e.hp >= e.hp_max or e.owner < 0:
			continue
		if has(e.owner, "relevo"):
			var cfg := m(e.owner, "relevo")
			if sim.tick - e.last_combat >= int(cfg["espera_ms"]) / sim.tick_ms:
				e.hp = mini(e.hp_max, e.hp + maxi(1, e.hp_max * int(cfg["pct_por_seg"]) * (100 + sim.mod(e.owner, "relevo_pct")) / 10000))
				continue
		# --- paso 6, par 3 --- Recetario de Narai y nuat (Ayutthaya): la tropa fuera de combate sana.
		var rt := sim.mod(e.owner, "regen_tropa")
		if rt > 0 and e.is_military() and sim.tick - e.last_combat >= int(sim.players[e.owner].get("regen_tropa_espera", 0)) / sim.tick_ms:
			e.hp = mini(e.hp_max, e.hp + rt)
			continue
		var rm := sim.mod(e.owner, "regen_monte")
		if rm > 0 and e.is_military() and e.inside < 0 and sim.tick - e.last_combat >= int(sim.players[e.owner].get("regen_monte_espera", 0)) / sim.tick_ms and in_forest(e):
			e.hp = mini(e.hp_max, e.hp + rm)


## --- paso 6 --- ¿Hay árboles en las 8 casillas de alrededor de la unidad (o en la suya)?
func in_forest(e: SimEntity) -> bool:
	var tx := e.x / P
	var ty := e.y / P
	for dy in [-1, 0, 1]:
		for dx in [-1, 0, 1]:
			var o: SimEntity = sim.by_id.get(sim.map.occupant(tx + dx, ty + dy))
			if o != null and o.is_resource() and o.res_kind == "madera":
				return true
	return false


## --- paso 6, par 2 --- Sanguar: la tropa que se mueve esquiva parte del daño de la distancia.
func dodge(a: SimEntity, t: SimEntity, dmg: int) -> int:
	if t.owner < 0 or not t.is_unit() or t.path.is_empty() or not sim.is_ranged(a):
		return dmg
	var pct := sim.mod(t.owner, "esquiva:" + t.type)
	return dmg * (100 - pct) / 100 if pct > 0 else dmg


## --- paso 6, par 2 --- ¿Hay una cerca, puerta o fortaleza propia a `r` casillas? (guarnição da cerca)
func near_wall(e: SimEntity, r: int, fuertes := false) -> bool:
	var tx := e.x / P
	var ty := e.y / P
	for yy in range(ty - r, ty + r + 1):
		for xx in range(tx - r, tx + r + 1):
			var o: SimEntity = sim.by_id.get(sim.map.occupant(xx, yy))
			if o != null and o.owner == e.owner and o.is_building() and o.built and (o.def.has("espinas") or o.type in ["empalizada", "puerta"] or (fuertes and o.type in FUERTES)):
				return true
	return false


## --- paso 6, par 2 --- ¿`pid` tiene en pie alguno de esos edificios terminado?
func _has_built(pid: int, types: Array) -> bool:
	for e in sim.buildings_of(pid):
		if e.alive and e.owner == pid and e.is_building() and e.built and types.has(e.type):
			return true
	return false


## --- paso 6, par 2 --- Mando de los capitães de mocambo: la tropa propia a `radio` pega `n` más.
func _command_aura() -> void:
	if not mando.is_empty():
		mando.clear()
	var caps: Array[SimEntity] = []
	for e in sim.all_units():
		if e.alive and e.is_unit() and e.inside < 0 and e.def.has("mando"):
			caps.append(e)
	if caps.is_empty():
		return
	for u in sim.military():
		if not u.alive or not u.is_unit() or u.owner < 0 or not u.is_military():
			continue
		for c in caps:
			var md: Dictionary = c.def["mando"]
			if c != u and c.owner == u.owner and absi(c.x - u.x) <= int(md["radio"]) and absi(c.y - u.y) <= int(md["radio"]):
				mando[u.id] = int(md["n"])
				break


## --- paso 6 --- ¿Hay agua a `r` casillas o menos de la unidad? (Mbororé: los arqueros junto al río.)
func near_water(e: SimEntity, r: int) -> bool:
	var tx := e.x / P
	var ty := e.y / P
	for yy in range(ty - r, ty + r + 1):
		for xx in range(tx - r, tx + r + 1):
			if sim.map.is_water(xx, yy):
				return true
	return false


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
		# Presencia por equipo: los aliados no se disputan un sitio. Lo toma el jugador
		# de menor id del equipo presente.
		var present := {}
		for u in sim.all_units(): # mismas unidades que actives, en el mismo orden; la caja primero
			if absi(u.x - site.x) <= r and absi(u.y - site.y) <= r and u.alive and u.owner >= 0 and u.inside < 0:
				var tm := sim.team_of(u.owner)
				present[tm] = mini(int(present.get(tm, u.owner)), u.owner)
		if present.size() != 1:
			continue
		var who: int = present.values()[0]
		if _site_protected(site, who): # --- paso 7 --- el koyagtun: los rivales no toman los sitios cercanos
			continue
		if site.holder >= 0 and sim.team_of(site.holder) == sim.team_of(who):
			who = site.holder
		if site.holder == who:
			site.capture = 0
			continue
		if not sim.can_take_sites(who): # --- esport 1a --- se toman desde la II: antes, solo se disputan
			continue
		if site.aux != who:
			site.aux = who
			site.capture = 0
		site.capture += 1000
		if site.capture >= int(cfg["captura_ms"]):
			site.holder = who
			site.capture = 0
			sim.events.append({"t": "sitio", "id": site.id, "player": who})
	# --- esport 3a --- Guarnición (proceso/34-hacia-esport/04, §4, alternativa B): el sitio rinde
	# solo con guarnicion_pob o más de población militar del equipo dueño a guarnicion_radio. Sin
	# ella, la renta y la cuenta de victoria se congelan (no pasan al rival). guarnicion_pob 0 apaga la regla.
	var need_pob := int(cfg.get("guarnicion_pob", 0))
	var gr := int(cfg.get("guarnicion_radio", r))
	site_guard.clear()
	for site in sites:
		if site.holder < 0:
			continue
		var tm_h := sim.team_of(site.holder)
		var pob := 0
		for u in sim.all_units():
			if u.alive and u.owner >= 0 and u.inside < 0 and u.is_military() and absi(u.x - site.x) <= gr and absi(u.y - site.y) <= gr and sim.team_of(u.owner) == tm_h:
				pob += int(u.def.get("pob", 1))
		site_guard[site.id] = pob
	var unguarded := {} # equipo -> sitios propios sin guarnición
	var holds := {}
	for site in sites:
		if site.holder >= 0:
			if int(site_guard.get(site.id, 0)) < need_pob:
				var tmu := sim.team_of(site.holder)
				unguarded[tmu] = int(unguarded.get(tmu, 0)) + 1
				continue
			holds[site.holder] = int(holds.get(site.holder, 0)) + 1
			# Renta decreciente: 18 / 12 / 8 por el 1.º, 2.º y 3.º sitio del mismo jugador.
			var rank := int(holds[site.holder]) - 1
			var rents: Array = cfg.get("renta_por_cantidad", [cfg["renta_riqueza"]])
			# --- paso 3 --- En la IV los sitios rinden más (docs/diseno/27, §4.3).
			var by_age: Array = cfg.get("renta_edad_pct", [])
			var age_pct := int(by_age[mini(int(sim.players[site.holder]["age"]), by_age.size()) - 1]) if not by_age.is_empty() else 0
			_gain(site.holder, "riqueza", int(rents[mini(rank, rents.size() - 1)]) * (100 + age_pct) / 100 * P / 60, "sitios")
	# Victoria por sitios: cuenta el equipo, no el jugador.
	var team_holds := {}
	for pid2 in holds:
		team_holds[sim.team_of(pid2)] = int(team_holds.get(sim.team_of(pid2), 0)) + int(holds[pid2])
	# Misiones que enseñan los sitios sin que ganen la partida (el tutorial): sin cuenta.
	var no_win: bool = sim._opts.get("sitios_sin_victoria", false)
	# Que se juegue el final (proceso/26-juego-tardio/14): la cuenta no corre antes de
	# `cuenta_desde_ms` de partida ni con el equipo por debajo de la edad `cuenta_edad_min`
	# (estilo AoE4, donde los sitios se toman desde la edad de los castillos).
	var early: bool = sim.tick * sim.tick_ms <= int(cfg.get("cuenta_desde_ms", 0))
	var age_min := int(cfg.get("cuenta_edad_min", 1))
	for p in sim.players:
		var pid: int = p["id"]
		var team_age := 0
		for q in sim.players:
			if sim.team_of(int(q["id"])) == sim.team_of(pid) and not q["defeated"]:
				team_age = maxi(team_age, int(q["age"]))
		var tm_p := sim.team_of(pid)
		var held_all := int(team_holds.get(tm_p, 0)) + int(unguarded.get(tm_p, 0)) == sites.size()
		if held_all and int(unguarded.get(tm_p, 0)) > 0 and not p["defeated"]:
			pass # --- esport 3a --- todos suyos, alguno sin guarnición: la cuenta se congela
		elif held_all and not p["defeated"] and not no_win and not early and team_age >= age_min:
			p["sitios_ms"] = int(p.get("sitios_ms", 0)) + 1000
			if p["sitios_ms"] >= int(cfg["victoria_ms"]) and not sim.game_over:
				sim.win(pid)
		else:
			p["sitios_ms"] = 0


# ---------------------------------------------------------------- Caminos

func on_building_placed(b: SimEntity) -> void:
	if b.def.has("trampa"): # --- paso 6 ---
		traps.append(b)
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
	for e in sim.owned(pid):
		if e.alive and e.owner == pid and e.capital:
			start = e
			break
	for e in sim.buildings_of(pid):
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
	var mv: Dictionary = sim.data.reglas["movimiento"]
	if e.slow_until > sim.tick:
		s = s * int(mv["frenado_pct"]) / 100
	if not _slow.is_empty() and e.owner >= 0: # --- paso 7 --- inundación de Ollantaytambo, crecida de Ayutthaya
		var sl: Array = _slow.get(clampi(e.y / P, 0, sim.map.n - 1) * sim.map.n + clampi(e.x / P, 0, sim.map.n - 1), [])
		if not sl.is_empty() and sim.enemies(int(sl[0]), e.owner):
			s = s * (100 - int(sl[1])) / 100
	# --- paso 6 --- Ygá: las tropas propias cruzan los vados más rápido (guaraníes).
	if e.owner >= 0:
		var vv := sim.mod(e.owner, "vel_vado")
		if vv > 0 and sim.map.in_bounds(e.x / P, e.y / P) and sim.map.water[(e.y / P) * sim.map.n + e.x / P] == 2:
			s = s * (100 + vv) / 100
	if _roads[clampi(e.y / P, 0, sim.map.n - 1) * sim.map.n + clampi(e.x / P, 0, sim.map.n - 1)] != 0:
		var pct := int(mv["camino_pct"])
		for p in sim.players:
			if has(p["id"], "caminos"):
				pct = int(m(p["id"], "caminos")["velocidad_pct"])
		if e.owner >= 0:
			pct += sim.mod(e.owner, "camino_pct") # --- paso 6, par 3 --- q'eswa chaka
		s = s * (100 + pct) / 100
	return s


## Ajuste del daño por módulos del atacante y del objetivo.
func damage(a: SimEntity, t: SimEntity, dmg: int) -> int:
	if t.owner >= 0 and has(t.owner, "defensa_altura") and t.is_unit():
		var dh := sim.map.h_at(t.x / P, t.y / P) - sim.map.h_at(a.x / P, a.y / P)
		if dh > 0:
			dmg = dmg * (100 - int(m(t.owner, "defensa_altura")["pct"]) - sim.mod(t.owner, "altura_pct")) / 100 # --- paso 6, par 2 --- amba
	if a.is_unit() and has(a.owner, "sigilo") and a.last_combat < sim.tick - 50 and is_hidden_now(a):
		dmg = dmg * (100 + int(m(a.owner, "sigilo").get("emboscada_pct", 0)) + sim.mod(a.owner, "emboscada")) / 100 # --- paso 6 --- aty
	if a.def.has("galga") and sim.map.h_at(a.x / P, a.y / P) <= sim.map.h_at(t.x / P, t.y / P): # --- paso 6, par 3 --- galgas: cuesta abajo, enteras
		dmg = dmg * int(a.def["galga"]["llano_pct"]) / 100
	if t.owner >= 0 and has(t.owner, "oficios"): # --- paso 6, par 2 --- sanguar (solo Palmares tiene esquiva)
		dmg = dodge(a, t, dmg)
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
	if a.owner >= 0 and t.owner >= 0 and sim.enemies(a.owner, t.owner) and has(a.owner, "arreo") and t.is_building() and (t.def.get("fuente", "") == "alimento" or int(t.def.get("pob", 0)) > 0 or t.def.has("ganado")):
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
	for e in sim.all_buildings():
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
	sim._close_corridors_of(tx, ty, t.w, t.h, t.id)
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
		for u in sim.all_units():
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
	if int(used[1]) >= int(cfg["max_por_min"]) + sim.mod(a.owner, "arreo_extra") or sim.disputed_room(a.owner) < int(cfg["cuenta_disputado"]):
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
	if killer == null or killer.owner < 0 or e.owner < 0 or not sim.enemies(killer.owner, e.owner):
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
		for b in sim.all_buildings():
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
	if e.def.has("deteccion"): # --- paso 6 --- el hoyo con estacas se ve recién de cerca
		r = int(e.def["deteccion"])
	var ws := wonder_fx(e.owner, "sigilo_monte") # --- paso 7 --- la aldea grande del monte en pie
	if not ws.is_empty():
		r = r * int(ws["deteccion_pct"]) / 100
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
		pct += int(wonder_fx(b.owner, "obra_colectiva").get("pct_por_constructor", 0)) # --- paso 7 --- el cabildo de la tava
		pct += sim.mod(b.owner, "potiro") # --- paso 6 --- óga de takuára
		return t * (100 + pct * (nb - 1)) / (100 * nb)
	if sim.data.reglas["construccion_decreciente"]:
		return t * (nb + 2) / (3 * nb)
	return t


# ---------------------------------------------------------------- Trampas (paso 6)

## Hoyos con estacas (mapuches, `trampa` en el edificio): cada tick, el primer enemigo de a pie o a
## caballo que pisa el hoyo terminado recibe el daño (más a los montados) y queda frenado; el hoyo
## se pierde. Solo corre si hay hoyos (Sim.step).
func tick_traps() -> void:
	var keep: Array[SimEntity] = []
	for b in traps:
		if not b.alive:
			continue
		keep.append(b)
		if not b.built:
			continue
		var victim: SimEntity = null
		for ox in range(b.tx - 1, b.tx + 2):
			for oy in range(b.ty - 1, b.ty + 2):
				for o: SimEntity in sim._grid.get(ox * 4096 + oy, []):
					if victim == null and o.alive and o.owner >= 0 and sim.enemies(b.owner, o.owner) and (o.is_military() or o.fn == "civil") \
							and absi(o.x - b.x) <= 600 and absi(o.y - b.y) <= 600:
						victim = o
		if victim == null:
			continue
		var tr: Dictionary = b.def["trampa"]
		var dmg := int(tr["danio"])
		if victim.def.get("montado", false) or victim.def.get("a_caballo", false):
			dmg = dmg * int(tr.get("montado_pct", 100)) / 100
		victim.slow_until = sim.tick + int(tr.get("frena_ms", 0)) / sim.tick_ms
		victim.hp -= dmg
		victim.last_combat = sim.tick
		sim.events.append({"t": "trampa", "id": b.id, "player": b.owner, "victima": victim.id, "dmg": dmg, "x": b.x, "y": b.y})
		sim.events.append({"t": "hit", "a": b.id, "b": victim.id, "ranged": false, "dmg": dmg})
		if victim.hp <= 0:
			sim.players[victim.owner]["stats"]["muertes"] += 1
			sim.players[b.owner]["stats"]["bajas"] += 1
			on_kill(victim, b)
			sim._kill(victim, b)
		sim._kill(b)
		keep.pop_back()
	traps = keep


# ---------------------------------------------------------------- Maravillas (paso 7)

## Efecto `tipo` de la maravilla terminada y en pie de `pid` (data/civs → edificios.maravilla →
## efectos_maravilla), o vacío. Se rehace una vez por segundo (`_wonder_tick`).
func wonder_fx(pid: int, tipo: String) -> Dictionary:
	return (_wfx.get(pid, {}) as Dictionary).get(tipo, {})


## Una vez por segundo: qué efectos dan las maravillas en pie, el agua que frena al enemigo
## (inundación inca, crecida de Ayutthaya) y los sitios que protege el koyagtun mapuche.
func _wonder_tick() -> void:
	_wfx.clear()
	_slow.clear()
	_protected.clear()
	for w in sim.all_buildings():
		if not (w.alive and w.owner >= 0 and w.is_building() and w.built and w.def.get("maravilla", false)):
			continue
		var fx := {}
		for ef: Dictionary in w.def.get("efectos_maravilla", []):
			fx[ef["tipo"]] = ef
		_wfx[w.owner] = fx
		if fx.has("inundacion"):
			_flood(w, fx["inundacion"])
		if fx.has("crecida"):
			_rising(w, fx["crecida"])
		if fx.has("sitios_protegidos"):
			var sp: Dictionary = fx["sitios_protegidos"]
			if not sim._enemy_troops_near(w, int(sp["libre_radio"])):
				_protected.append([w.owner, w.x, w.y, int(sp["radio"]) * P])


## ¿El koyagtun de un rival de `who` protege este sitio?
func _site_protected(site: SimEntity, who: int) -> bool:
	for pr: Array in _protected:
		if sim.enemies(int(pr[0]), who) and Sim.dist(site.x, site.y, int(pr[1]), int(pr[2])) <= int(pr[3]):
			return true
	return false


## Casillas bajas (altura ≤ `altura_max`) a `radio` de (cx, cy) con agua a `agua_radio` o menos.
## Se guardan medio minuto: el agua casi no cambia (los khlong de Ayutthaya, sí).
func _low_water(key: String, cx: int, cy: int, cfg: Dictionary) -> Dictionary:
	var c: Array = _wmask.get(key, [])
	if not c.is_empty() and sim.tick - int(c[0]) < 300:
		return c[1]
	var out := {}
	var n := sim.map.n
	var r := int(cfg["radio"])
	var ar := int(cfg["agua_radio"])
	var hmax := int(cfg["altura_max"])
	for dy in range(-r, r + 1):
		for dx in range(-r, r + 1):
			var x := cx + dx
			var y := cy + dy
			if dx * dx + dy * dy > r * r or x < 0 or y < 0 or x >= n or y >= n or sim.map.is_water(x, y) or sim.map.h_at(x, y) > hmax:
				continue
			var wet := false
			for yy in range(maxi(0, y - ar), mini(n, y + ar + 1)):
				for xx in range(maxi(0, x - ar), mini(n, x + ar + 1)):
					if not wet and sim.map.is_water(xx, yy):
						wet = true
			if wet:
				out[y * n + x] = true
	_wmask[key] = [sim.tick, out]
	return out


## Ollantaytambo: cuando entra en el llano junto al agua tropa enemiga (al menos `enemigos_min`),
## se inunda: el enemigo anda más lento durante `dura_ms`, una vez cada `cada_ms`.
func _flood(w: SimEntity, cfg: Dictionary) -> void:
	var p: Dictionary = sim.players[w.owner]
	var tiles := _low_water("i%d" % w.id, w.x / P, w.y / P, cfg)
	if tiles.is_empty():
		return
	if sim.tick >= int(p.get("inundacion_hasta", 0)):
		if sim.tick < int(p.get("inundacion_lista", 0)):
			return
		var n := 0
		for u in sim.military():
			if u.alive and u.is_unit() and u.inside < 0 and u.owner >= 0 and u.is_military() and sim.enemies(w.owner, u.owner) and tiles.has(u.y / P * sim.map.n + u.x / P):
				n += 1
		if n < int(cfg["enemigos_min"]):
			return
		p["inundacion_hasta"] = sim.tick + int(cfg["dura_ms"]) / sim.tick_ms
		p["inundacion_lista"] = sim.tick + int(cfg["cada_ms"]) / sim.tick_ms
		sim.events.append({"t": "inundacion", "id": w.id, "player": w.owner})
	for idx in tiles:
		_slow[idx] = [w.owner, int(cfg["frenado_pct"])]


## Krung Si Ayutthaya: la crecida como muralla. El agua baja cerca de la capital frena al enemigo,
## salvo a `torre_radio` casillas de una torre o un fuerte suyo (la respuesta de 1766).
func _rising(w: SimEntity, cfg: Dictionary) -> void:
	var cap: SimEntity = null
	for e in sim.all_buildings():
		if e.alive and e.owner == w.owner and e.is_building() and e.capital:
			cap = e
			break
	if cap == null:
		return
	var tiles := _low_water("c%d" % cap.id, cap.x / P, cap.y / P, cfg)
	var forts: Array[SimEntity] = []
	var reach := (int(cfg["radio"]) + int(cfg["torre_radio"]) + 3) * P
	for e in sim.actives:
		if e.alive and e.owner >= 0 and e.is_building() and e.built and sim.enemies(w.owner, e.owner) and (e.type == "torre" or e.def.get("torre", false) or e.def.get("fortaleza", false)) \
				and Sim.dist(e.x, e.y, cap.x, cap.y) <= reach:
			forts.append(e)
	var tr := int(cfg["torre_radio"]) * P
	var n := sim.map.n
	for idx: int in tiles:
		var free := true
		for f in forts:
			if free and Sim.dist(f.x, f.y, (idx % n) * P + P / 2, (idx / n) * P + P / 2) <= tr + f.w * P / 2:
				free = false
		if free:
			_slow[idx] = [w.owner, int(cfg["frenado_pct"])]


## --- paso 6, par 3 --- Cirugía de cráneo (Tawantinsuyu, docs/diseno/27 §3.1): de cada 100 que caen
## a golpes (no por pólvora ni asedio) de los `tipos`, a `radio` casillas de uno de los `edificios`
## propios, `pct` no mueren: quedan con `vida_pct` de la vida y vuelven a ese edificio. Sin azar:
## una cuenta por jugador.
func trepan(a: SimEntity, t: SimEntity) -> void:
	var cfg: Dictionary = sim.players[t.owner]["trepanacion"]
	if not (cfg["tipos"] as Array).has(t.type) or a.def.get("polvora", false) or a.fn == "asedio":
		return
	var r := int(cfg["radio"]) * P
	var home: SimEntity = null
	for b in sim.all_buildings():
		if b.alive and b.owner == t.owner and b.is_building() and b.built and (cfg["edificios"] as Array).has(b.type) and absi(b.x - t.x) <= r and absi(b.y - t.y) <= r:
			home = b
			break
	if home == null:
		return
	cfg["n"] = int(cfg["n"]) + int(cfg["pct"])
	if int(cfg["n"]) < 100:
		return
	cfg["n"] = int(cfg["n"]) - 100
	t.hp = maxi(1, t.hp_max * int(cfg["vida_pct"]) / 100)
	t.target = -1
	sim.order_move(t, home.x, home.y)
	sim.events.append({"t": "trepanacion", "player": t.owner, "x": t.x, "y": t.y})
