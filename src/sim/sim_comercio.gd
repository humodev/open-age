class_name SimComercio
extends RefCounted
## --- comercio --- Mercados neutrales, comerciante y rutas (proceso/33-comercio).
## Todo entero: distancia octil sin raíz, porcentajes y divisiones enteras. Los números en
## data/reglas.json → "comercio"; el comerciante en data/unidades.json → "comerciante".
##
## Ciclo del comerciante (orden TRADE): ida al destino (pasando por el punto de paso si hay),
## carga, vuelta al mercado propio (por el mismo punto), descarga y cobro. La ganancia se fija
## al cargar y se cobra al volver: si lo matan en el camino, se pierde.

const P := 1000
const O := SimEntity.Order
enum Leg { IDA, CARGA, VUELTA, DESCARGA }

var sim: Sim
var cfg: Dictionary
var neutrals: Array[SimEntity] = [] # mercados neutrales de la partida
var cut := {} # pid * 1_000_000 + id del destino -> true: «Ruta cortada» ya avisada (una vez hasta que se reabra)
var cuts_in_row := {} # igual, cortes seguidos (la IA cambia de destino a los dos)
var stats := {} # pid -> {"viajes", "cobrado", "cortes", "muertos"} (mediciones; no es estado)


func _init(s: Sim) -> void:
	sim = s
	cfg = s.data.reglas.get("comercio", {})


# ---------------------------------------------------------------- Generador

## ¿Sirve la casilla `t` (esquina de la huella de 3×3) para un mercado neutral? Tierra (se
## empareja al ponerlo), sin nada encima salvo árboles (se talan), con una casilla libre alrededor.
func _spot_ok(t: Vector2i) -> bool:
	var m := sim.map
	if t.x < 3 or t.y < 3 or t.x + 6 > m.n or t.y + 6 > m.n:
		return false
	for yy in range(t.y - 1, t.y + 4):
		for xx in range(t.x - 1, t.x + 4):
			if m.is_water(xx, yy):
				return false
			var occ := m.occupant(xx, yy)
			if occ < -1:
				return false
			if occ >= 0:
				var o: SimEntity = sim.by_id.get(occ)
				if o == null or not o.is_resource() or o.res_kind != "madera":
					return false
	return true


## ¿Hay un mercado neutral a menos de `r` casillas de `t`? (los bosques no se les ponen encima)
func near_neutral(t: Vector2i, r: int) -> bool:
	for m in neutrals:
		if absi(t.x - m.tx - 1) < r and absi(t.y - m.ty - 1) < r:
			return true
	return false


## Se llega por tierra desde la base `pid` (islas: si no, el neutral no sirve).
func _reachable(t: Vector2i, pid: int) -> bool:
	var b: Vector2i = sim.bases[pid] + Vector2i(2, 2)
	var from := sim.map.nearest_free(b.x, b.y + 3, 6)
	var to := sim.map.nearest_free(t.x + 1, t.y - 1, 3)
	if from.x < 0 or to.x < 0:
		return false
	var path := sim.map.find_path(from, to, pid)
	return not path.is_empty() and path[path.size() - 1] == to


## Tala los árboles alrededor y pone el mercado. `fill`: si cae en el agua o en un peñasco, se
## rellena (el puerto sobre la orilla; último recurso para no correrlo de la mediatriz).
func _spawn(t: Vector2i, fill := false) -> void:
	if fill:
		var m := sim.map
		for yy in range(t.y - 1, t.y + 4):
			for xx in range(t.x - 1, t.x + 4):
				if not m.in_bounds(xx, yy):
					continue
				var idx := yy * m.n + xx
				if m.water[idx] != 0 or m.rock[idx] != 0:
					m.water[idx] = 0
					m.rock[idx] = 0
					m.occupied[idx] = -1
					m.solid[idx] = 0
					m.astar.set_point_solid(Vector2i(xx, yy), false)
					for a in m.astars:
						a.set_point_solid(Vector2i(xx, yy), false)
	for yy in range(t.y - 2, t.y + 5):
		for xx in range(t.x - 2, t.x + 5):
			if not sim.map.in_bounds(xx, yy):
				continue
			var occ := sim.map.occupant(xx, yy)
			if occ < 0:
				continue
			var o: SimEntity = sim.by_id.get(occ)
			if o != null and o.alive and o.is_resource() and o.res_kind == "madera":
				sim.remove_quietly(o)
				sim.map.clear(o.tx, o.ty, o.w, o.h)
	var h0 := sim.map.h_at(t.x + 1, t.y + 1) # se empareja la huella a la altura del centro
	for yy in range(t.y, t.y + 3):
		for xx in range(t.x, t.x + 3):
			sim.map.height[yy * sim.map.n + xx] = h0
	var b := sim.spawn_building("mercado_neutral", -1, t.x, t.y, true)
	neutrals.append(b)


## 1 contra 1: dos neutrales sobre la mediatriz entre las bases (la antidiagonal), a `borde`
## casillas del borde, uno en cada punta. Si no entra, se corre por la mediatriz hacia el centro
## (x + y constante: sigue a la misma distancia de las dos bases).
func place_1v1() -> void:
	var nc: Dictionary = cfg.get("neutrales", {})
	var n := sim.map.n
	var b := int(nc.get("borde", 8))
	for k in n / 2 - b - 4:
		var t := Vector2i(b + k, n - b - 3 - k)
		var mt := sim._mirror(t, 3, 3)
		if _spot_ok(t) and _spot_ok(mt) and _reachable(t, 0) and _reachable(mt, 1):
			_spawn(t)
			_spawn(mt)
			return
	var t0 := Vector2i(b, n - b - 3)
	_spawn(t0, true)
	_spawn(sim._mirror(t0, 3, 3), true)


## Mapas para N: un neutral por hueco elegido entre bases vecinas del anillo, sobre la bisectriz
## del hueco, a `lado/2 − radio_borde` del centro (un círculo: en cualquier rumbo queda igual de
## lejos). Con dos equipos, los dos huecos entre equipos (la mediatriz) y uno más en mapa grande;
## con tres o más equipos, los huecos entre equipos distintos (todos contra todos: tope, si se
## puede repartir parejo).
func place_n(ring_bases: Array, slot: Array) -> void:
	var nc: Dictionary = cfg.get("neutrales", {})
	var n := sim.map.n
	var np := ring_bases.size()
	var team_at := []
	team_at.resize(np)
	var teams := {}
	for pid in np:
		team_at[int(slot[pid])] = sim.team_of(pid)
		teams[sim.team_of(pid)] = true
	var cross: Array = []
	for i in np:
		if team_at[i] != team_at[(i + 1) % np]:
			cross.append(i)
	var gaps: Array = []
	var tope := int(nc.get("tope", 4))
	if teams.size() == 2:
		gaps = [cross[0], cross[cross.size() / 2]] if cross.size() >= 2 else cross
	elif cross.size() > tope and cross.size() % 2 == 0 and cross.size() == np:
		for i in range(0, np, 2):
			gaps.append(i) # todos contra todos con N par: uno cada dos huecos, cada base toca uno
	else:
		gaps = cross
	var r := n / 2 - int(nc.get("radio_borde", 10))
	var c := Vector2i(n / 2, n / 2)
	# Corrimiento (hacia el centro `k`, de costado `j`) por orden de costo. Primero se busca uno
	# que sirva para todos a la vez (la partida sigue pareja); si no hay, cada uno el suyo.
	var radial: Array = []
	var full: Array = []
	for cost in 40:
		radial.append(Vector2i(cost, 0))
		for k in cost + 1:
			var jj := cost - k
			if jj % 2 == 1:
				continue
			full.append(Vector2i(k, jj / 2))
			if jj > 0:
				full.append(Vector2i(k, -jj / 2))
	var spots := _spots(ring_bases, gaps, r)
	if teams.size() == 2:
		# Sobre la mediatriz (solo hacia el centro): igual de lejos de cada base y de su espejo.
		if str(sim._opts.get("tamano", "normal")) == "grande" and not spots.is_empty():
			for k in int(nc.get("grande_extra", 1)):
				var s0: Array = spots[k % spots.size()]
				spots.append([s0[0], r * 3 / 5, s0[2], Vector2i(n / 2, n / 2) * P])
		if not _place_common(c, spots, radial, slot):
			for sp in spots:
				if not _place_one(c, sp, radial, slot):
					_spawn(_at(c, sp, Vector2i.ZERO), true) # puerto: se rellena la orilla
		return
	if gaps.size() < cross.size() and _place_common(c, spots, radial, slot):
		return
	if gaps.size() < cross.size():
		spots = _spots(ring_bases, cross, r) # con un río por los huecos: todos, así cada base tiene uno a cada lado
	if not _place_common(c, spots, full, slot):
		for sp in spots:
			_place_one(c, sp, full, slot)


## Lugar de cada hueco: sobre la mediatriz de las dos bases vecinas (igual de lejos de las dos,
## salvo el redondeo a casillas), hacia afuera, a `r` casillas del centro del mapa (más o menos).
## [rumbo en milésimas, casillas desde el origen, hueco, origen en milésimas de casilla]
func _spots(ring_bases: Array, gaps: Array, r: int) -> Array:
	var out: Array = []
	var c := Vector2i(sim.map.n / 2, sim.map.n / 2) * P
	for i in gaps:
		var a: Vector2i = (ring_bases[int(i)] + Vector2i(2, 2)) * P
		var b: Vector2i = (ring_bases[(int(i) + 1) % ring_bases.size()] + Vector2i(2, 2)) * P
		var mid := (a + b) / 2
		var ab := b - a
		var d := Vector2i(-ab.y, ab.x)
		var out_v := mid - c
		if d.x * out_v.x + d.y * out_v.y < 0:
			d = -d
		var l := Sim.isqrt(d.x * d.x + d.y * d.y)
		d = d * 1000 / maxi(1, l)
		var dm := Sim.isqrt(out_v.x * out_v.x + out_v.y * out_v.y) / P
		out.append([d, r - dm, int(i), mid])
	return out


func _place_common(c: Vector2i, spots: Array, steps: Array, slot: Array) -> bool:
	for st: Vector2i in steps:
		var all_ok := true
		for sp in spots:
			if not _ok_at(c, sp, st, slot):
				all_ok = false
				break
		if all_ok:
			for sp in spots:
				_spawn(_at(c, sp, st))
			return true
	return false


func _place_one(c: Vector2i, sp: Array, steps: Array, slot: Array) -> bool:
	for st: Vector2i in steps:
		if _ok_at(c, sp, st, slot):
			_spawn(_at(c, sp, st))
			return true
	return false


func _at(_c: Vector2i, sp: Array, st: Vector2i) -> Vector2i:
	var d: Vector2i = sp[0]
	var rr: int = int(sp[1]) - st.x
	var perp := Vector2i(-d.y, d.x)
	var o: Vector2i = sp[3]
	var pm := o + d * rr + perp * st.y
	return Vector2i((pm.x - 1000) / P, (pm.y - 1000) / P)


func _ok_at(c: Vector2i, sp: Array, st: Vector2i, slot: Array) -> bool:
	if st.x * 3 > int(sp[1]) * 2:
		return false
	var t := _at(c, sp, st)
	return _spot_ok(t) and _reachable(t, maxi(0, slot.find(sp[2])))


# ---------------------------------------------------------------- Rutas y ganancia

## Distancia en línea, en casillas, entre los centros de dos edificios. El diseño la pedía octil
## (sin raíz); se usa la raíz entera (`Sim.isqrt`, determinista): la octil no es igual en todos
## los rumbos y con 3, 5, 6 o 7 bases en círculo daba hasta 8 % de diferencia entre jugadores.
static func octil(a: SimEntity, b: SimEntity) -> int:
	var dx := a.x - b.x
	var dy := a.y - b.y
	return Sim.isqrt(dx * dx + dy * dy) / P


## ¿Puede `pid` comerciar con `t`? Neutral, mercado aliado terminado o mercado propio (otro).
func is_market(t: SimEntity) -> bool:
	return t != null and t.alive and t.is_building() and t.built and (t.def.get("mercado_neutral", false) or t.def.get("mercado", false))


func dest_kind(pid: int, t: SimEntity) -> String:
	if not is_market(t):
		return ""
	if t.owner < 0:
		return "neutral" if t.def.get("mercado_neutral", false) else ""
	if t.owner == pid:
		return "propio"
	if not sim.enemies(pid, t.owner) and not sim.players[t.owner]["defeated"]:
		return "aliado"
	return ""


## G = d·(d·A/L + B)/100: riqueza de un viaje a `d` casillas en un mapa de lado `l`, antes de
## la edad, el tipo de destino, el pueblo y la saturación.
func formula(d: int, l: int) -> int:
	return d * (d * int(cfg.get("A", 220)) / maxi(1, l) + int(cfg.get("B", 10))) / 100


## Ganancia de un viaje sin la saturación (la ayuda y la medición la usan).
func gain(pid: int, home: SimEntity, dest: SimEntity, age: int = -1) -> int:
	var kind := dest_kind(pid, dest)
	if kind == "" or home == null:
		return 0
	var g := formula(octil(home, dest), sim.map.n)
	var ap: Array = cfg.get("edad_pct", [0, 0, 70, 100])
	var a := int(sim.players[pid]["age"]) if age < 0 else age
	g = g * int(ap[clampi(a - 1, 0, ap.size() - 1)]) / 100
	g = g * int((cfg.get("tipo_pct", {}) as Dictionary).get(kind, 100)) / 100
	g = g * (100 + sim.mod(pid, "comercio_pct")) / 100
	return g


## Rendimiento por saturación de la ruta de `pid` a `dest` con `n` comerciantes.
func saturation(n: int) -> int:
	var sc: Dictionary = cfg.get("saturacion", {})
	var free := int(sc.get("libres", 10))
	if n <= free:
		return 100
	return maxi(int(sc.get("piso", 60)), 100 - int(sc.get("paso", 3)) * (n - free))


func traders_on(pid: int, dest_id: int) -> int:
	var n := 0
	for e in sim.owned(pid):
		if e.alive and e.is_unit() and e.order == O.TRADE and e.trade_dest == dest_id:
			n += 1
	return n


## Duración estimada de ida y vuelta en ms (en línea; la ayuda y la IA).
func trip_ms(pid: int, home: SimEntity, dest: SimEntity) -> int:
	var spd := int(sim.dp(pid).unidades.get("comerciante", {}).get("velocidad", 1400))
	return 2 * octil(home, dest) * 1000 * P / maxi(1, spd) + 2 * int(cfg.get("carga_ms", 2000))


## Mercado propio terminado más cercano a (x, y), sin `except`.
func nearest_own_market(pid: int, x: int, y: int, except: int = -1) -> SimEntity:
	var best: SimEntity = null
	var bd := 1 << 60
	for b in sim.buildings_of(pid):
		if b.alive and b.owner == pid and b.built and b.def.get("mercado", false) and b.id != except:
			var d := Sim.dist(b.x, b.y, x, y)
			if d < bd:
				bd = d
				best = b
	return best


## Orden de ruta: los comerciantes de `units` van y vienen entre su mercado y `dest`.
## `wp` (casilla en milésimas) es el punto de paso; (-1, -1) sin punto.
func order_route(pid: int, units: Array, dest: SimEntity, wp := Vector2i(-1, -1)) -> int:
	var kind := dest_kind(pid, dest)
	if kind == "":
		return 0
	var n := 0
	for e: SimEntity in units:
		if not e.alive or e.owner != pid or not e.def.get("comerciante", false):
			continue
		var home: SimEntity = sim.by_id.get(e.trade_home)
		if home == null or not home.alive or home.owner != pid or not home.built:
			home = nearest_own_market(pid, e.x, e.y, dest.id)
		if home == dest:
			home = nearest_own_market(pid, e.x, e.y, dest.id)
		if home == null:
			continue
		e.trade_home = home.id
		e.trade_dest = dest.id
		e.trade_leg = Leg.IDA
		e.trade_gain = 0
		e.trade_wx = wp.x
		e.trade_wy = wp.y
		e.trade_wpd = wp.x < 0
		e.order = O.TRADE
		e.target = dest.id
		e.group = -1
		e.path.clear()
		e.path_target = -1
		n += 1
	return n


## ¿Son todos comerciantes y `t` un destino de comercio? (la orden de ruta no arma grupo)
func all_traders_to(pid: int, units: Array, t: SimEntity) -> bool:
	if units.is_empty() or dest_kind(pid, t) == "":
		return false
	for e: SimEntity in units:
		if not e.def.get("comerciante", false):
			return false
	return true


## Punto de paso nuevo para comerciantes que ya tienen ruta.
func set_waypoint(pid: int, units: Array, x: int, y: int) -> void:
	for e: SimEntity in units:
		if e.alive and e.owner == pid and e.def.get("comerciante", false) and e.trade_dest >= 0:
			e.trade_wx = x
			e.trade_wy = y
			e.trade_wpd = false
			if e.order != O.TRADE:
				e.order = O.TRADE
			e.path_target = -1


# ---------------------------------------------------------------- Cada tick

func update(e: SimEntity) -> void:
	var pid := e.owner
	var home: SimEntity = sim.by_id.get(e.trade_home)
	if home == null or not home.alive or home.owner != pid or not home.built:
		# Sin mercado propio: corta todas sus rutas (lo cargado se pierde).
		e.trade_gain = 0
		sim._set_idle(e)
		return
	var dest: SimEntity = sim.by_id.get(e.trade_dest)
	var dest_ok := dest_kind(pid, dest) != ""
	match e.trade_leg:
		Leg.IDA:
			if not dest_ok:
				_turn_back(e, false)
				return
			if not e.trade_wpd:
				if _go_point(e, e.trade_wx, e.trade_wy):
					e.trade_wpd = true
					e.path_target = -1
				return
			if not sim._approach(e, dest, e.radius + Sim.INTERACT):
				if e.stuck > 25 or (e.path_tick == sim.tick and e.path_target == dest.id and _short(e, dest)):
					_cut(e, dest, "cerrado")
					_turn_back(e, false)
				return
			if blocked(pid, dest):
				_cut(e, dest, "tomado")
				_turn_back(e, false)
				return
			e.trade_leg = Leg.CARGA
			e.cooldown = int(cfg.get("carga_ms", 2000))
		Leg.CARGA:
			e.anchored = true
			if e.cooldown > 0:
				return
			var g := gain(pid, home, dest) if dest_ok else 0
			if g > 0:
				g = g * saturation(traders_on(pid, dest.id)) / 100
				cut.erase(pid * 1000000 + dest.id)
				cuts_in_row.erase(pid * 1000000 + dest.id)
			_turn_back(e, true, g)
		Leg.VUELTA:
			if not e.trade_wpd:
				if _go_point(e, e.trade_wx, e.trade_wy):
					e.trade_wpd = true
					e.path_target = -1
				return
			if not sim._approach(e, home, e.radius + Sim.INTERACT):
				if e.stuck > 25:
					e.trade_gain = 0
					sim._set_idle(e)
				return
			e.trade_leg = Leg.DESCARGA
			e.cooldown = int(cfg.get("carga_ms", 2000))
		Leg.DESCARGA:
			e.anchored = true
			if e.cooldown > 0:
				return
			_pay(e, dest)
			e.trade_leg = Leg.IDA
			e.trade_wpd = e.trade_wx < 0
			e.path_target = -1


## El camino recién buscado no llega al lado del mercado (muralla que lo cierra del todo).
func _short(e: SimEntity, t: SimEntity) -> bool:
	if e.path.is_empty():
		return true
	var last: Vector2i = e.path[e.path.size() - 1]
	return last.x < t.tx - 2 or last.x > t.tx + t.w + 1 or last.y < t.ty - 2 or last.y > t.ty + t.h + 1


func _turn_back(e: SimEntity, loaded: bool, g: int = 0) -> void:
	e.trade_gain = g if loaded else 0
	e.trade_leg = Leg.VUELTA
	e.trade_wpd = e.trade_wx < 0
	e.path_target = -1
	e.stuck = 0


func _go_point(e: SimEntity, x: int, y: int) -> bool:
	if e.path_target != -7 or e.goal_x != x or e.goal_y != y:
		sim._set_goal(e, x, y, -7)
	if Sim.dist(e.x, e.y, x, y) < 600:
		return true
	return sim._follow(e)


func _pay(e: SimEntity, dest: SimEntity) -> void:
	var g := e.trade_gain
	e.trade_gain = 0
	if g <= 0:
		return
	var pid := e.owner
	var p: Dictionary = sim.players[pid]
	p["res"]["riqueza"] += g
	p["stats"]["recolectado"] += g
	p["ruta_tick"] = sim.tick
	sim.ledger(pid, "comercio", "riqueza", g)
	var st: Dictionary = stats.get_or_add(pid, {"viajes": 0, "cobrado": 0, "cortes": 0, "muertos": 0, "aliado": 0})
	st["viajes"] = int(st["viajes"]) + 1
	st["cobrado"] = int(st["cobrado"]) + g
	sim.events.append({"t": "deposit", "id": e.id, "res": "riqueza", "n": g})
	# Mercado aliado: el aliado recibe un extra creado (no descontado).
	if dest != null and dest.alive and dest.owner >= 0 and dest.owner != pid and not sim.players[dest.owner]["defeated"]:
		var x := g * int(cfg.get("aliado_extra_pct", 20)) / 100
		if x > 0:
			sim.players[dest.owner]["res"]["riqueza"] += x
			sim.ledger(dest.owner, "comercio", "riqueza", x)
			var sa: Dictionary = stats.get_or_add(dest.owner, {"viajes": 0, "cobrado": 0, "cortes": 0, "muertos": 0, "aliado": 0})
			sa["aliado"] = int(sa["aliado"]) + x


## Mercado tomado por presencia: `pob_min` o más de población militar enemiga a `radio` del
## destino y ninguna tropa propia o aliada.
func blocked(pid: int, dest: SimEntity) -> bool:
	var bc: Dictionary = cfg.get("bloqueo", {})
	var r := int(bc.get("radio", 6000)) + P * 3 / 2
	var need := int(bc.get("pob_min", 6))
	var foes := 0
	for u in sim.military():
		if not u.alive or u.inside >= 0 or u.owner < 0:
			continue
		if Sim.dist(u.x, u.y, dest.x, dest.y) > r:
			continue
		if sim.enemies(pid, u.owner):
			foes += int(u.def.get("pob", 1))
		else:
			return false
	return foes >= need


func _cut(e: SimEntity, dest: SimEntity, why: String) -> void:
	var k := e.owner * 1000000 + dest.id
	cuts_in_row[k] = int(cuts_in_row.get(k, 0)) + 1
	var st: Dictionary = stats.get_or_add(e.owner, {"viajes": 0, "cobrado": 0, "cortes": 0, "muertos": 0, "aliado": 0})
	st["cortes"] = int(st["cortes"]) + 1
	if cut.has(k):
		return
	cut[k] = true
	sim.events.append({"t": "ruta_cortada", "player": e.owner, "dest": dest.id, "x": dest.x, "y": dest.y, "motivo": why})


## ¿Tiene `pid` una ruta abierta (un viaje cobrado hace poco)? Pólvora de Massawa.
func route_open(pid: int) -> bool:
	var t := int(sim.players[pid].get("ruta_tick", -1))
	return t >= 0 and sim.tick - t <= int(cfg.get("ruta_abierta_ms", 180000)) / sim.tick_ms


## Un comerciante murió (mediciones).
func on_died(e: SimEntity) -> void:
	if e.owner < 0:
		return
	var st: Dictionary = stats.get_or_add(e.owner, {"viajes": 0, "cobrado": 0, "cortes": 0, "muertos": 0, "aliado": 0})
	st["muertos"] = int(st["muertos"]) + 1
