extends SceneTree
## Calidad del movimiento (proceso/60): situaciones apretadas que medían los atascos, los
## temblores y los rodeos. Cada caso arma un lugar despejado en el medio del mapa, da las órdenes
## y mide, por unidad y por tick:
##   - trabada: tiene orden (no está quieta ni trabajando) y no se movió `TRABA_DIST` en
##     `TRABA_TICKS` ticks; se suman los segundos de unidad trabada y la peor racha;
##   - vaivén: el paso de este tick va contra el anterior (producto escalar negativo, los dos de
##     más de `VAIVEN_MIN`) y ya había vuelto atrás hace `VAIVEN_TICKS` o menos: caminar, frenar
##     y volver, girar en el lugar, bailar junto al depósito (por unidad y minuto caminando);
##   - temblor: lo que se mueve una unidad ya quieta (orden inactiva), en casillas;
##   - cumplidas: órdenes terminadas (llegó, o entregas de recursos);
##   - asentarse: segundos desde que todas tienen la orden cumplida (inactivas) hasta que ninguna
##     se mueve más (los empujones de después de llegar).
## Uso: godot --headless --path . -s tests/movimiento_qol.gd [-- --caso=nombre] [--estricto]
##   --estricto falla si algún caso supera los topes de `TOPES` (los de después de proceso/60).

const P := 1000
const O := SimEntity.Order
const TRABA_TICKS := 20 # 2 s
const TRABA_DIST := 300
const VAIVEN_MIN := 15
const VAIVEN_TICKS := 10
## caso -> [trabada máx. (s de unidad), vaivenes máx. por unidad y minuto, cumplidas mín. (%)]
const TOPES := {
	"deposito_40": [5.0, 12.0, 100.0],
	"hueco_60": [300.0, 20.0, 100.0],
	"multitud_40": [5.0, 4.0, 100.0],
	"multitud_suelta_40": [5.0, 4.0, 100.0],
	"bosque_centro": [5.0, 12.0, 100.0],
	"puerta_30": [20.0, 8.0, 100.0],
	"reunion_izq": [5.0, 8.0, 100.0],
}

var _only := ""


func _init() -> void:
	var strict := false
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--caso="):
			_only = a.substr(7)
		elif a == "--estricto":
			strict = true
	var fails := 0
	var cases := ["deposito_40", "hueco_60", "multitud_40", "multitud_suelta_40", "bosque_centro", "puerta_30", "reunion_izq"]
	print("%-20s %8s %8s %8s %8s %9s %9s %s" % ["caso", "trabada", "racha", "vaivén", "temblor", "cumplidas", "asentar", "extra"])
	for c in cases:
		if _only != "" and c != _only:
			continue
		var r: Dictionary = call("_c_" + c)
		var line := "%-20s %7.1fs %7.1fs %8.2f %7.2fc %8.0f%% %8.1fs %s" % [c, r["trabada_s"], r["racha_s"], r["vaiven"], r["temblor"], r["cumplidas"], r["asentar_s"], r.get("extra", "")]
		var lim: Array = TOPES[c]
		var bad: bool = r["trabada_s"] > lim[0] or r["vaiven"] > lim[1] or r["cumplidas"] < lim[2] or int(r.get("lado", 1)) < int(r.get("lado_de", 0))
		if bad:
			line += "  <- sobre el tope"
			if strict:
				fails += 1
		print(line)
	print("MOVIMIENTO: ", "OK" if fails == 0 else "%d fallas" % fails)
	quit(1 if fails > 0 else 0)


# ------------------------------------------------------------------ lugar y medición

func _clear_sim() -> Sim:
	var s := Sim.new(3, 2, null, {"terreno": "llano", "sin_sitios": true}) # capa común: todos los edificios
	var c := s.map.n / 2
	for e in s.entities.duplicate():
		var ex: int = e.x / P if e.is_unit() else e.tx
		var ey: int = e.y / P if e.is_unit() else e.ty
		if e.alive and absi(ey - c) < 34 and absi(ex - c) < 34:
			s.remove_quietly(e)
			if not e.is_unit():
				s.map.clear(e.tx, e.ty, e.w, e.h)
	s.step() # limpieza de los sacados
	for pid in 2:
		for k in s.players[pid]["res"]:
			s.players[pid]["res"][k] = 100000
	return s


class Meter:
	var ids: Array = []
	var last := {} # id -> [x, y]
	var vprev := {} # id -> [dx, dy] del último paso que contó
	var anchor := {} # id -> [x, y, tick]
	var stuck_ticks := 0
	var worst := 0
	var flips := 0
	var moving_ticks := 0
	var idle_move := 0
	var first_arrive := -1
	var all_still := -1
	var still_run := 0
	var walked := {} # id -> milésimas caminadas
	var last_flip := {} # id -> tick de la última vuelta atrás
	var all_idle_t := -1 # primer tick con todas quietas (orden inactiva)

	func add(e: SimEntity, tick: int) -> void:
		ids.append(e.id)
		last[e.id] = [e.x, e.y]
		anchor[e.id] = [e.x, e.y, tick]
		walked[e.id] = 0

	func sample(s: Sim) -> void:
		var any_move := false
		var all_idle := true
		for id in ids:
			var e: SimEntity = s.by_id.get(id)
			if e == null or not e.alive or e.inside >= 0:
				continue
			var l: Array = last[id]
			var dx: int = e.x - l[0]
			var dy: int = e.y - l[1]
			last[id] = [e.x, e.y]
			var idle := e.order == O.IDLE or e.order == O.HOLD
			var working := e.anchored and (e.order == O.GATHER or e.order == O.BUILD)
			if not idle:
				all_idle = false
			if idle:
				idle_move += Sim.isqrt(dx * dx + dy * dy)
				if absi(dx) + absi(dy) > 4:
					any_move = true
			var m := Sim.isqrt(dx * dx + dy * dy)
			walked[id] = int(walked[id]) + m
			if m >= VAIVEN_MIN:
				if vprev.has(id):
					var v: Array = vprev[id]
					if dx * int(v[0]) + dy * int(v[1]) < 0:
						# vaivén: dos vueltas atrás seguidas en menos de VAIVEN_TICKS (no la vuelta de
						# un viaje de ida y vuelta al depósito)
						if s.tick - int(last_flip.get(id, -1000)) <= VAIVEN_TICKS:
							flips += 1
						last_flip[id] = s.tick
				vprev[id] = [dx, dy]
			if not idle and not working:
				moving_ticks += 1
				var a: Array = anchor[id]
				if Sim.dist(e.x, e.y, a[0], a[1]) > TRABA_DIST:
					anchor[id] = [e.x, e.y, s.tick]
				elif s.tick - int(a[2]) > TRABA_TICKS:
					stuck_ticks += 1
					worst = maxi(worst, s.tick - int(a[2]))
			else:
				anchor[id] = [e.x, e.y, s.tick]
		if all_idle and all_idle_t < 0:
			all_idle_t = s.tick
		elif not all_idle:
			all_idle_t = -1
		if all_idle and not any_move:
			still_run += 1
			if still_run == 10 and all_still < 0:
				all_still = s.tick - 9
		else:
			still_run = 0
			if not all_idle:
				all_still = -1

	func result(done_pct: float, t0: int, extra := "") -> Dictionary:
		var settle := -1.0
		if all_idle_t >= 0 and all_still >= 0:
			settle = maxi(0, all_still - all_idle_t) / 10.0
		var minutes := maxf(moving_ticks / 600.0, 0.05)
		return {"trabada_s": stuck_ticks / 10.0, "racha_s": worst / 10.0, "vaiven": flips / minutes,
			"vaiven_tot": flips, "temblor": idle_move / 1000.0, "cumplidas": done_pct, "asentar_s": settle, "extra": extra}


func _run(s: Sim, m: Meter, ticks: int, done: Callable) -> int:
	for t in ticks:
		s.step()
		m.sample(s)
		if m.first_arrive < 0:
			for id in m.ids:
				var e: SimEntity = s.by_id.get(id)
				if e != null and e.order == O.IDLE:
					m.first_arrive = s.tick
					break
		if done.call():
			return t
	return ticks


func _units(s: Sim, types: Array, n: int, x0: int, y0: int, cols: int, pid := 0) -> Array:
	var out := []
	for i in n:
		var u := s.spawn_unit(types[i % types.size()], pid, (x0 + i % cols) * P + P / 2, (y0 + i / cols) * P + P / 2)
		out.append(u)
	return out


func _ids(list: Array) -> Array:
	var out := []
	for e in list:
		out.append(e.id)
	return out


func _arrived(s: Sim, list: Array, x: int, y: int, r: int) -> int:
	var n := 0
	for e: SimEntity in list:
		if e.alive and e.order == O.IDLE and Sim.dist(e.x, e.y, x, y) <= r:
			n += 1
	return n


# ------------------------------------------------------------------ casos

## 40 aldeanos talando una franja de bosque a 5 casillas de un solo depósito: ida, vuelta y entrega.
func _c_deposito_40() -> Dictionary:
	var s := _clear_sim()
	var c := s.map.n / 2
	var dep := s.spawn_building("deposito", 0, c, c, true)
	var trees := []
	# Una franja de bosque de 2 de ancho a 5 casillas del depósito: 48 árboles, todos con un lado libre.
	for yy in range(c - 11, c + 13):
		for xx in range(c + 6, c + 8):
			trees.append(s.spawn_resource("arbol", xx, yy))
	var vs := _units(s, ["aldeano"], 40, c - 8, c - 3, 5)
	var m := Meter.new()
	for e in vs:
		m.add(e, s.tick)
	for i in vs.size():
		s.push_command({"t": "target", "player": 0, "ids": [vs[i].id], "target": trees[(i * 7) % trees.size()].id, "suelto": true})
	var wood0: int = s.players[0]["res"]["madera"]
	_run(s, m, 1800, func() -> bool: return false)
	var wood: int = s.players[0]["res"]["madera"] - wood0
	var working := 0
	for e: SimEntity in vs:
		if e.order == O.GATHER or e.order == O.RETURN:
			working += 1
	var r := m.result(100.0 * working / vs.size(), 0, "madera %d en 3 min" % wood)
	r["madera"] = wood
	return r


## 60 militares cruzan un hueco de 2 casillas entre dos filas de casas.
func _c_hueco_60() -> Dictionary:
	var s := _clear_sim()
	var c := s.map.n / 2
	for yy in range(c - 16, c + 16, 2):
		if yy >= c - 1 and yy <= c:
			continue
		s.spawn_building("torre", 0, c, yy, true)
	# Torres (no abren pasillo entre ellas): una pared con un hueco de 2 casillas (filas c y c+1).
	var us := _units(s, ["guerrero", "lancero", "hondero"], 60, c - 18, c - 5, 6)
	var m := Meter.new()
	for e in us:
		m.add(e, s.tick)
	var gx := (c + 12) * P
	var gy := c * P
	s.push_command({"t": "move", "player": 0, "ids": _ids(us), "x": gx, "y": gy})
	var t := _run(s, m, 1500, func() -> bool: return _arrived(s, us, gx, gy, 9000) == us.size() and m.all_still >= 0)
	var r := m.result(100.0 * _arrived(s, us, gx, gy, 9000) / us.size(), 0, "todas en %.1f s" % (t / 10.0))
	return r


## 40 militares mandados a un solo punto en grupo: cuánto tardan en quedarse quietos.
func _c_multitud_40() -> Dictionary:
	return _crowd(false)


func _c_multitud_suelta_40() -> Dictionary:
	return _crowd(true)


func _crowd(loose: bool) -> Dictionary:
	var s := _clear_sim()
	var c := s.map.n / 2
	var us := _units(s, ["guerrero", "lancero", "hondero", "jinete"], 40, c - 20, c - 4, 8)
	var m := Meter.new()
	for e in us:
		m.add(e, s.tick)
	var gx := (c + 10) * P + P / 2
	var gy := c * P + P / 2
	s.push_command({"t": "move", "player": 0, "ids": _ids(us), "x": gx, "y": gy, "suelto": loose})
	var t := _run(s, m, 900, func() -> bool: return m.all_still >= 0 and s.tick - m.all_still > 30)
	return m.result(100.0 * _arrived(s, us, gx, gy, 8000) / us.size(), 0, "fin %.1f s" % (t / 10.0))


## Centro con el bosque pegado en tres lados y en la esquina; la reunión, afuera del bosque.
func _c_bosque_centro() -> Dictionary:
	var s := _clear_sim()
	var c := s.map.n / 2
	var tc := s.spawn_building("centro", 0, c, c, true)
	# Bosque alrededor, con un claro de 1 casilla entre el centro y los árboles, abierto solo en la
	# esquina noroeste. Dos árboles en el claro (abajo y a la derecha) arman un bolsillo cerrado.
	for yy in range(c - 7, c + 11):
		for xx in range(c - 7, c + 11):
			var inside := xx >= c - 1 and xx <= c + 4 and yy >= c - 1 and yy <= c + 4
			if inside and not (Vector2i(xx, yy) in [Vector2i(c + 2, c + 4), Vector2i(c + 4, c + 2)]):
				continue
			if xx < c and yy < c:
				continue # la esquina abierta
			s.spawn_resource("arbol", xx, yy)
	var rx := (c - 9) * P
	var ry := (c - 7) * P
	s.push_command({"t": "rally", "player": 0, "building": tc.id, "x": rx, "y": ry, "target": -1})
	s.step()
	var m := Meter.new()
	var us := []
	for k in 12:
		s._spawn_from(tc, "aldeano")
		var u: SimEntity = s.entities[s.entities.size() - 1]
		us.append(u)
		m.add(u, s.tick)
		_run(s, m, 15, func() -> bool: return false)
	var t := _run(s, m, 600, func() -> bool: return _arrived(s, us, rx, ry, 4000) == us.size())
	return m.result(100.0 * _arrived(s, us, rx, ry, 4000) / us.size(), 0, "última en %.1f s" % (t / 10.0))


## Muralla norte-sur con una puerta; 30 de adentro salen al otro lado.
func _c_puerta_30() -> Dictionary:
	var s := _clear_sim()
	var c := s.map.n / 2
	for yy in range(c - 14, c + 15):
		if yy == c:
			s.spawn_building("puerta", 0, c, yy, true)
		else:
			s.spawn_building("empalizada", 0, c, yy, true)
	var us := _units(s, ["guerrero", "aldeano", "hondero"], 30, c - 12, c - 3, 6)
	var m := Meter.new()
	for e in us:
		m.add(e, s.tick)
	var gx := (c + 10) * P
	var gy := c * P
	s.push_command({"t": "move", "player": 0, "ids": _ids(us), "x": gx, "y": gy})
	var t := _run(s, m, 1500, func() -> bool: return _arrived(s, us, gx, gy, 8000) == us.size() and m.all_still >= 0)
	return m.result(100.0 * _arrived(s, us, gx, gy, 8000) / us.size(), 0, "todas en %.1f s" % (t / 10.0))


## Reunión a la izquierda de cada edificio que entrena: dónde aparece y cuánto rodea.
func _c_reunion_izq() -> Dictionary:
	var s := _clear_sim()
	var c := s.map.n / 2
	var specs := [["centro", "aldeano", -22], ["cuartel", "guerrero", -8], ["campo_tiro", "hondero", 6], ["establo", "jinete", 20]]
	var m := Meter.new()
	var all := []
	var ratio_sum := 0.0
	var ratio_n := 0
	var side_ok := 0
	var info := []
	for sp in specs:
		var b := s.spawn_building(sp[0], 0, c, c + int(sp[2]), true)
		var rx := (b.tx - 7) * P + P / 2
		var ry := b.y
		s.push_command({"t": "rally", "player": 0, "building": b.id, "x": rx, "y": ry, "target": -1})
		s.step()
		for k in 3:
			s._spawn_from(b, sp[1])
			var u: SimEntity = s.entities[s.entities.size() - 1]
			all.append([u, b, rx, ry, u.x, u.y])
			m.add(u, s.tick)
			if u.x < b.tx * P and u.y >= b.ty * P and u.y < (b.ty + b.h) * P:
				side_ok += 1 # en la columna de la izquierda, a la altura del edificio
			_run(s, m, 10, func() -> bool: return false)
	_run(s, m, 400, func() -> bool: return false)
	var arrived := 0
	for a in all:
		var u: SimEntity = a[0]
		var b: SimEntity = a[1]
		if Sim.dist(u.x, u.y, a[2], a[3]) <= 3000:
			arrived += 1
		# lo caminado contra la recta del borde izquierdo del edificio al punto de reunión
		var straight := maxi(1, Sim.dist(b.tx * P - P / 2, int(a[3]), int(a[2]), int(a[3])))
		ratio_sum += float(m.walked[u.id]) / straight
		ratio_n += 1
	var r := m.result(100.0 * arrived / all.size(), 0, "salen del lado de la reunión %d/%d · recorrido/recta %.2f" % [side_ok, all.size(), ratio_sum / ratio_n])
	r["lado"] = side_ok
	r["lado_de"] = all.size()
	return r
