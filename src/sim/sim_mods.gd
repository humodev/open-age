class_name SimMods
extends RefCounted
## Módulos de civilización (docs/01, "test del módulo"; docs/06). Cada civilización los activa
## con parámetros en data/civs/<clave>.json → "modulos". La simulación solo llama a estos ganchos.

const P := 1000
const O := SimEntity.Order

var sim: Sim
var _acc := {} # acumuladores en milésimas: "pid:clave" -> int
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
		if has(pid, "acogida"):
			_welcome(pid, p)
		if has(pid, "caminos") and sim.tick % 50 == 0:
			_update_connection(pid)
	_regen()
	_sacred()


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
	var per_v := int(cfg.get("por_aldeano", 0))
	var by_age: Array = cfg.get("por_aldeano_por_edad", [])
	if not by_age.is_empty():
		per_v = int(by_age[clampi(int(p["age"]) - 1, 0, by_age.size() - 1)])
	per_min += vill * per_v
	_gain(pid, key, per_min * P / 60)
	p["res"][key] = mini(p["res"].get(key, 0), cap)
	p["tope_" + key] = cap


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
	for e in sim.actives:
		if e.alive and e.owner == pid and e.is_building() and e.built and e.def.has("renta"):
			var r: Dictionary = e.def["renta"]
			for k in r:
				_gain(pid, k, int(r[k]) * P / 60, "renta")


## Acogida: la población llega sola según la fama (Palmares).
func _welcome(pid: int, p: Dictionary) -> void:
	var cfg := m(pid, "acogida")
	var key: String = cfg["recurso"]
	var cost: int = cfg["costo"]
	if int(p["res"].get(key, 0)) < cost or p["pop"] >= p["pop_cap"]:
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
				if ob == null or ob.owner != pid or not ob.is_building():
					continue
				seen[ny * n + nx] = 1
				queue.append(Vector2i(nx, ny))


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
	if a.def.has("frena_ms") and t.is_unit():
		t.slow_until = sim.tick + int(a.def["frena_ms"]) / sim.tick_ms
	if a.owner >= 0 and t.owner >= 0 and has(a.owner, "saqueo") and t.is_building():
		var cfg := m(a.owner, "saqueo")
		_gain(a.owner, cfg["recurso"], dmg * int(cfg["pct_danio_edificio"]) * P / 100, "saqueo")


func on_kill(e: SimEntity, killer: SimEntity) -> void:
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
	if has(killer.owner, "liberacion") and e.is_building() and e.built:
		var n: int = m(killer.owner, "liberacion").get("por_edificio", {}).get(e.type, int(m(killer.owner, "liberacion").get("aldeanos", 1)))
		for i in n:
			var u := sim.spawn_near(e, "aldeano", killer.owner)
			sim.events.append({"t": "freed", "id": u.id, "player": killer.owner})


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
