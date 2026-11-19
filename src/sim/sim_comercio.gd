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
enum Leg { IDA, CARGA, VUELTA, DESCARGA, ESPERA }

var sim: Sim
var cfg: Dictionary
var neutrals: Array[SimEntity] = [] # mercados neutrales de la partida
var cut := {} # pid * 1_000_000 + id del destino -> true: «Ruta cortada» ya avisada (una vez hasta que se reabra)
var cut_tick := {} # igual -> tick del último aviso (un corte nuevo avisa pasados aviso_ms)
var cuts_in_row := {} # igual, cortes seguidos (la IA cambia de destino a los dos)
var stats := {} # pid -> {"viajes", "cobrado", "cortes", "muertos"} (mediciones; no es estado)


func _init(s: Sim) -> void:
	sim = s
	cfg = s.data.reglas.get("comercio", {})


# ---------------------------------------------------------------- Generador

## ¿Sirve la casilla `t` (esquina de la huella de 3×3) para un mercado neutral? Tierra (se
## empareja al ponerlo), sin nada encima salvo árboles (se talan), con una casilla libre alrededor.
func _spot_ok(t: Vector2i, trees := true) -> bool:
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
				if o == null or not o.is_resource() or o.res_kind != "madera" or not trees:
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
	sim.id_aparte = Sim.ID_APARTE + neutrals.size() # sin correr los ids del resto (proceso/34, 01d)
	var b := sim.spawn_building("mercado_neutral", -1, t.x, t.y, true)
	sim.id_aparte = 0
	var tn := str((sim.terrain_def().get("neutral", {}) as Dictionary).get("nombre", ""))
	if tn != "": # el nombre del terreno: feria, puerto de río, feria de altura
		b.def = b.def.duplicate()
		b.def["nombre"] = tn
	neutrals.append(b)
	# Todos saben dónde están (como los puestos de AoE4): explorados desde el principio.
	for g in sim.fog.grids:
		for yy in range(t.y - 1, t.y + 4):
			for xx in range(t.x - 1, t.x + 4):
				if sim.map.in_bounds(xx, yy) and g[yy * sim.map.n + xx] == 0:
					g[yy * sim.map.n + xx] = 1


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
		# Sin talar (se pone después de los bosques): el mapa queda como sin mercados.
		if _spot_ok(t, false) and _spot_ok(mt, false) and _reachable(t, 0) and _reachable(mt, 1):
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
	var ap: Array = (cfg.get("uno_contra_uno", {}) as Dictionary).get("edad_pct", cfg.get("edad_pct")) if duel() else cfg.get("edad_pct", [0, 0, 70, 100])
	var a := int(sim.players[pid]["age"]) if age < 0 else age
	g = g * int(ap[clampi(a - 1, 0, ap.size() - 1)]) / 100
	g = g * int((cfg.get("tipo_pct", {}) as Dictionary).get(kind, 100)) / 100
	g = g * (100 + sim.mod(pid, "comercio_pct")) / 100
	return g


## --- esport 2b --- ¿Uno contra uno? (comerciante desde la II: reglas.comercio.uno_contra_uno)
func duel() -> bool:
	return sim.players.size() == 2


## Edad desde la que `pid` entrena `type`: el comerciante, en el 1v1, desde uno_contra_uno.edad_min.
func unit_age_min(pid: int, type: String) -> int:
	var a := int(sim.dp(pid).unidades.get(type, {}).get("edad_min", 1))
	if duel() and sim.dp(pid).unidades.get(type, {}).get("comerciante", false):
		a = int((cfg.get("uno_contra_uno", {}) as Dictionary).get("edad_min", a))
	return a


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
			# --- esport 2b --- tropa enemiga en el camino o en el destino: espera a distancia.
			if (sim.tick + e.id) % maxi(1, int(_bc().get("chequeo_ticks", 10))) == 0 and _threat(e, dest, home):
				return
			if not e.trade_wpd:
				if _go_point(e, e.trade_wx, e.trade_wy):
					e.trade_wpd = true
					e.path_target = -1
				return
			if not sim._approach(e, dest, e.radius + Sim.INTERACT):
				if e.stuck > 25 or (e.path_tick == sim.tick and e.path_target == dest.id and _short(e, dest)):
					_cut(e, dest, "cerrado", dest.x, dest.y)
					_turn_back(e, false)
				return
			if blocked(pid, dest):
				_wait(e, dest, home, "tomado", dest.x, dest.y, int(_bc().get("radio", 8000)) + P * 3 / 2)
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
		Leg.ESPERA:
			_waiting(e, dest, home, dest_ok)


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


func _bc() -> Dictionary:
	return cfg.get("bloqueo", {})


## Mercado tomado por presencia: `pob_min` o más de población militar enemiga a `radio` del
## destino (+1,5 casillas por la huella) y ninguna tropa propia o aliada.
func blocked(pid: int, dest: SimEntity) -> bool:
	return blocked_at(pid, dest.x, dest.y, int(_bc().get("radio", 8000)) + P * 3 / 2)


## ¿Corta la ruta de `pid` la tropa a `r` de (x, y)? `pob_min` o más de población militar
## enemiga y ninguna tropa propia o aliada.
func blocked_at(pid: int, x: int, y: int, r: int) -> bool:
	var need := int(_bc().get("pob_min", 3))
	var foes := 0
	for u in sim.military():
		if not u.alive or u.inside >= 0 or u.owner < 0:
			continue
		if absi(u.x - x) > r or absi(u.y - y) > r or Sim.dist(u.x, u.y, x, y) > r:
			continue
		if sim.enemies(pid, u.owner):
			foes += int(u.def.get("pob", 1))
		else:
			return false
	return foes >= need


## De ida: ¿hay tropa que corta la ruta cerca del comerciante, o el destino está tomado y ya
## está a la vista (a `radio` + `aviso_casillas`)? Entonces espera y devuelve true.
func _threat(e: SimEntity, dest: SimEntity, home: SimEntity) -> bool:
	var bc := _bc()
	var rr := int(bc.get("ruta_radio", 8000))
	if blocked_at(e.owner, e.x, e.y, rr):
		_wait(e, dest, home, "ruta", e.x, e.y, rr)
		return true
	var rd := int(bc.get("radio", 8000)) + P * 3 / 2
	if Sim.dist(e.x, e.y, dest.x, dest.y) <= rd + int(bc.get("aviso_casillas", 6)) * P and blocked(e.owner, dest):
		_wait(e, dest, home, "tomado", dest.x, dest.y, rd)
		return true
	return false


## Empieza a esperar: el corte en (bx, by) con radio `r`; espera a `espera_casillas` más allá,
## hacia su mercado (o donde está, si ya está fuera).
func _wait(e: SimEntity, dest: SimEntity, home: SimEntity, why: String, bx: int, by: int, r: int) -> void:
	_cut(e, dest, why, bx, by)
	e.trade_leg = Leg.ESPERA
	e.trade_bx = bx
	e.trade_by = by
	e.trade_since = sim.tick
	_wait_point(e, home, r)


## Punto de espera: sobre la línea del corte a su mercado, a r + espera_casillas del corte.
func _wait_point(e: SimEntity, home: SimEntity, r: int) -> void:
	var d := r + int(_bc().get("espera_casillas", 5)) * P
	var vx := home.x - e.trade_bx
	var vy := home.y - e.trade_by
	var l := Sim.isqrt(vx * vx + vy * vy)
	if Sim.dist(e.x, e.y, e.trade_bx, e.trade_by) >= d:
		e.trade_px = e.x
		e.trade_py = e.y
	elif l > d:
		e.trade_px = e.trade_bx + vx * d / l
		e.trade_py = e.trade_by + vy * d / l
	else: # el mercado propio queda más cerca: espera a su lado
		var k := maxi(0, l - 3 * P)
		e.trade_px = e.trade_bx + vx * k / maxi(1, l)
		e.trade_py = e.trade_by + vy * k / maxi(1, l)
	e.path_target = -1
	e.stuck = 0


## Esperando: va al punto y mira cada `chequeo_ticks`. Retoma cuando el corte se libera; si
## la tropa se le viene encima, se aleja más; pasados `espera_max_ms`, vuelve vacío.
func _waiting(e: SimEntity, dest: SimEntity, home: SimEntity, dest_ok: bool) -> void:
	if not dest_ok:
		_turn_back(e, false)
		return
	if Sim.dist(e.x, e.y, e.trade_px, e.trade_py) > 600 and e.stuck <= 25:
		e.anchored = false
		_go_point(e, e.trade_px, e.trade_py)
	else:
		e.anchored = true
	var bc := _bc()
	if (sim.tick + e.id) % maxi(1, int(bc.get("chequeo_ticks", 10))) != 0:
		return
	var rr := int(bc.get("ruta_radio", 8000))
	var rd := int(bc.get("radio", 8000)) + P * 3 / 2
	var at_dest := e.trade_bx == dest.x and e.trade_by == dest.y
	var still := blocked(e.owner, dest) if at_dest else blocked_at(e.owner, e.trade_bx, e.trade_by, rr)
	if not still:
		e.trade_leg = Leg.IDA
		e.anchored = false
		e.path_target = -1
		e.stuck = 0
		cut.erase(e.owner * 1000000 + dest.id) # reabierta: un corte nuevo vuelve a avisar
		return
	if sim.tick - e.trade_since >= int(bc.get("espera_max_ms", 120000)) / sim.tick_ms:
		_turn_back(e, false)
		e.anchored = false
		return
	if blocked_at(e.owner, e.x, e.y, rr): # se le vinieron encima: más atrás
		e.trade_bx = e.x
		e.trade_by = e.y
		_wait_point(e, home, rr)
	elif not at_dest and blocked(e.owner, dest):
		e.trade_bx = dest.x
		e.trade_by = dest.y
		_wait_point(e, home, rd)


func _cut(e: SimEntity, dest: SimEntity, why: String, x: int, y: int) -> void:
	var k := e.owner * 1000000 + dest.id
	var st: Dictionary = stats.get_or_add(e.owner, {"viajes": 0, "cobrado": 0, "cortes": 0, "muertos": 0, "aliado": 0})
	st["cortes"] = int(st["cortes"]) + 1
	if why == "cerrado" or not cut.has(k): # el camino cerrado cuenta cada vez (la IA cambia de destino)
		cuts_in_row[k] = int(cuts_in_row.get(k, 0)) + 1
	if cut.has(k):
		return
	cut[k] = true
	# Cortado otra vez antes de aviso_ms (la tropa que pasa y vuelve): el mismo corte, sin otro aviso.
	if sim.tick - int(cut_tick.get(k, -1000000)) < int(cfg.get("aviso_ms", 30000)) / sim.tick_ms:
		return
	cut_tick[k] = sim.tick
	st["episodios"] = int(st.get("episodios", 0)) + 1
	sim.events.append({"t": "ruta_cortada", "player": e.owner, "dest": dest.id, "x": x, "y": y, "motivo": why})


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


# ---------------------------------------------------------------- IA (§6)

var _ai := {} # jugador -> {"torres": {destino: true}, "def": tick, "corte": tick, "torre_tick": tick}


## La IA comercia, protege la ruta y corta la del rival (reglas.ia_comercio y
## dificultades.<n>.comercio). La llama SimAI.think después del mercado.
func ai_think(ai: SimAI, p: Dictionary, by_type: Dictionary, vill: Array[SimEntity], army: Array[SimEntity], centro: SimEntity, saving: bool) -> void:
	var ic: Dictionary = sim.data.reglas.get("ia_comercio", {})
	var lc: Dictionary = ai.level.get("comercio", {})
	var pid := ai.player
	if ic.is_empty() or lc.is_empty() or (sim.tick / maxi(1, int(ai.level["piensa_cada_ticks"]))) % maxi(1, int(ic.get("cada_ticks", 50)) / maxi(1, int(ai.level["piensa_cada_ticks"]))) != 0:
		return
	var st: Dictionary = _ai.get_or_add(pid, {"torres": {}, "def": -100000, "corte": -100000, "torre_tick": -100000})
	_ai_cut_rival(ai, ic, lc, army, centro, st)
	var age := int(p["age"])
	if age < unit_age_min(pid, "comerciante"):
		return
	var home: SimEntity = null
	for m in by_type.get("mercado", []):
		if m.alive and m.built:
			home = m
			break
	if home == null:
		return
	var traders: Array[SimEntity] = []
	var queued := 0
	for e in sim.owned(pid):
		if e.alive and e.is_unit() and e.def.get("comerciante", false):
			traders.append(e)
	for m in by_type.get("mercado", []):
		queued += (m.queue as Array).count("comerciante")
	# Destinos: neutrales y mercados aliados.
	var dests: Array[SimEntity] = []
	var far := false
	for t in neutrals:
		dests.append(t)
	for q in sim.players.size():
		if q != pid and not sim.enemies(pid, q) and not sim.players[q]["defeated"]:
			for b in sim.buildings_of(q):
				if b.alive and b.built and b.def.get("mercado", false):
					dests.append(b)
	for t in dests:
		if octil(home, t) >= int(ic.get("dist_min", 60)):
			far = true
	var clay := 0
	for r in sim.resources_near(centro.tx, centro.ty, int(ic.get("radio_arcilla", 30))):
		if r.res_kind == "riqueza":
			clay += r.amount
	if not far and clay >= int(ic.get("arcilla_baja", 1500)):
		return
	var pe: Array = ic.get("por_edad_1v1", ic.get("por_edad")) if duel() else ic.get("por_edad", [0, 0, 4, 10])
	var want := int(pe[clampi(age - 1, 0, pe.size() - 1)])
	if clay == 0:
		want = maxi(want, int(ic.get("sin_arcilla", 16)))
	want = mini(want, int(lc.get("max", 16)))
	# --- esport 2b --- en el 1v1, unos pocos aunque ahorre para el hito (el que va atrás también comercia)
	var while_saving := 0
	if duel():
		for q in sim.players.size():
			if sim.enemies(pid, q) and int(sim.players[q]["age"]) > age:
				while_saving = int(ic.get("ahorrando_1v1", 0)) # solo el que va atrás en edad
	if (not saving or traders.size() + queued < while_saving) and traders.size() + queued < want and queued == 0:
		var cost := sim.dp(pid).cost_of("comerciante", age)
		if sim.can_afford(pid, cost) and (sim.dp(pid).edificios.get("mercado", {}).get("produce", []) as Array).has("comerciante"):
			sim.push_command({"t": "train", "player": pid, "building": home.id, "type": "comerciante"})
	# Los que no tienen ruta (o la tienen cortada dos veces seguidas): a la mejor, con la saturación.
	var load := {}
	for e in traders:
		if e.order == O.TRADE:
			load[e.trade_dest] = int(load.get(e.trade_dest, 0)) + 1
	for e in traders:
		var bad := e.order == O.TRADE and int(cuts_in_row.get(pid * 1000000 + e.trade_dest, 0)) >= 2
		if (e.order == O.TRADE and not bad) or e.inside >= 0:
			continue
		if e.order == O.TRADE:
			load[e.trade_dest] = int(load.get(e.trade_dest, 0)) - 1
		var best: SimEntity = null
		var bv := 0
		for t in dests:
			if t == home or int(cuts_in_row.get(pid * 1000000 + t.id, 0)) >= 2:
				continue
			var v := gain(pid, home, t, 4) * saturation(int(load.get(t.id, 0)) + 1) * 1000 / maxi(1, trip_ms(pid, home, t))
			if v > bv:
				bv = v
				best = t
		if best == null:
			continue
		load[best.id] = int(load.get(best.id, 0)) + 1
		if bad:
			cuts_in_row.erase(pid * 1000000 + e.trade_dest)
		sim.push_command({"t": "ruta", "player": pid, "ids": [e.id], "mercado": best.id})
	_ai_tower(ai, ic, lc, vill, home, traders, load, st)
	_ai_defend(ic, army, traders, st)
	_ai_clear(ai, ic, army, traders, st)


## Una torre a mitad de la ruta más usada (una por ruta).
func _ai_tower(ai: SimAI, ic: Dictionary, lc: Dictionary, vill: Array[SimEntity], home: SimEntity, traders: Array[SimEntity], load: Dictionary, st: Dictionary) -> void:
	if not bool(lc.get("torre", false)) or traders.size() < int(ic.get("torre_desde", 4)):
		return
	if sim.tick - int(st["torre_tick"]) < int(ic.get("torre_cada_ticks", 1800)):
		return
	var top := -1
	var tn := 0
	for k in load:
		if int(load[k]) > tn:
			tn = int(load[k])
			top = int(k)
	var dest: SimEntity = sim.by_id.get(top)
	if dest == null or (st["torres"] as Dictionary).has(top) or not sim.dp(ai.player).edificios.has("torre"):
		return
	if not sim.can_afford(ai.player, sim.dp(ai.player).cost_of("torre", int(sim.players[ai.player]["age"]))):
		return
	st["torre_tick"] = sim.tick
	var mid := Vector2i((home.x + dest.x) / 2 / P, (home.y + dest.y) / 2 / P)
	var site: Vector2i = ai._site_near("torre", mid, 1, 2)
	if site.x < 0:
		return
	st["torres"][top] = true
	ai._build_at("torre", site, vill, 2)


## Golpean a un comerciante: hasta defensa_n tropas ociosas al lugar.
func _ai_defend(ic: Dictionary, army: Array[SimEntity], traders: Array[SimEntity], st: Dictionary) -> void:
	if sim.tick - int(st["def"]) < int(ic.get("defensa_cada_ticks", 300)):
		return
	var hit: SimEntity = null
	for e in traders:
		if sim.tick - e.last_combat < 30:
			hit = e
			break
	if hit == null:
		return
	var ids := []
	for u in army:
		if u.order == O.IDLE and ids.size() < int(ic.get("defensa_n", 4)):
			ids.append(u.id)
	if ids.is_empty():
		return
	st["def"] = sim.tick
	sim.push_command({"t": "move", "player": hit.owner, "ids": ids, "x": hit.x, "y": hit.y, "amove": true})


## --- esport 2b --- Despeja la ruta: comerciantes esperando un corte → hasta despeja.n tropas
## (ociosas o yendo a ningún ataque) al lugar del corte, en ataque en movimiento.
func _ai_clear(ai: SimAI, ic: Dictionary, army: Array[SimEntity], traders: Array[SimEntity], st: Dictionary) -> void:
	var dc: Dictionary = ic.get("despeja", {})
	if dc.is_empty() or sim.tick - int(st.get("despeja", -100000)) < int(dc.get("cada_ticks", 300)):
		return
	var w: SimEntity = null
	for e in traders:
		if e.order == O.TRADE and e.trade_leg == Leg.ESPERA:
			w = e
			break
	if w == null:
		return
	var wave: Array = ai._wave_ids
	var ids := []
	for u in army:
		if ids.size() >= int(dc.get("n", 8)):
			break
		if u.order == O.IDLE and not wave.has(u.id):
			ids.append(u.id)
	if ids.size() < int(dc.get("min", 3)):
		return
	st["despeja"] = sim.tick
	sim.push_command({"t": "move", "player": ai.player, "ids": ids, "x": w.trade_bx, "y": w.trade_by, "amove": true})


## Corta la ruta rival: con `corta` = si, a la mitad de una ruta con `ver` o más comerciantes
## enemigos a la vista; con `cerca`, solo los que pasan cerca de su capital.
func _ai_cut_rival(ai: SimAI, ic: Dictionary, lc: Dictionary, army: Array[SimEntity], centro: SimEntity, st: Dictionary) -> void:
	var mode := str(lc.get("corta", "no"))
	var cc: Dictionary = ic.get("corte", {})
	if mode == "no" or army.is_empty() or sim.tick - int(st["corte"]) < int(cc.get("cada_ticks", 1200)):
		return
	var pid := ai.player
	# No mientras un aliado está en una oleada (los turnos de ataque de la etapa 32).
	for other in sim.ais:
		if other != null and other != ai and not sim.enemies(pid, other.player) and not (other._wave_ids as Array).is_empty():
			return
	var routes := {} # [dueño, casa, destino] -> [n, x, y]
	var near_r := int(cc.get("cerca_casillas", 40)) * P
	for e in sim.actives:
		if not e.is_unit() or e.order != O.TRADE or e.owner < 0 or not sim.enemies(pid, e.owner):
			continue
		if not sim.fog.is_visible(pid, e):
			continue
		if mode == "cerca" and Sim.dist(e.x, e.y, centro.x, centro.y) > near_r:
			continue
		var k := [e.owner, e.trade_home, e.trade_dest]
		var r: Array = routes.get_or_add(k, [0, e.x, e.y])
		r[0] = int(r[0]) + 1
	var best: Array = []
	var bn := 0
	for k in routes:
		if int(routes[k][0]) > bn:
			bn = int(routes[k][0])
			best = k
	if best.is_empty() or (mode == "si" and bn < int(cc.get("ver", 6))):
		return
	var x: int = routes[best][1]
	var y: int = routes[best][2]
	if mode == "si":
		# --- esport 2b --- al mercado destino de esa ruta (lo toma por presencia: el rival espera);
		# si es el mercado de un aliado del rival, a la mitad de la ruta.
		var h: SimEntity = sim.by_id.get(best[1])
		var d: SimEntity = sim.by_id.get(best[2])
		if d != null and d.owner < 0:
			x = d.x
			y = d.y
		elif h != null and d != null:
			x = (h.x + d.x) / 2
			y = (h.y + d.y) / 2
	var ids := []
	var fast := int(cc.get("montado_vel", 1800))
	for u in army:
		if ids.size() >= int(cc.get("grupo_max", 6)):
			break
		if int(u.def.get("velocidad", 0)) >= fast and u.order == O.IDLE:
			ids.append(u.id)
	if ids.size() < (int(cc.get("grupo_min", 3)) if mode == "si" else 1):
		return
	st["corte"] = sim.tick
	sim.push_command({"t": "move", "player": pid, "ids": ids, "x": x, "y": y, "amove": true})
