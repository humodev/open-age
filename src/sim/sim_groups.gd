class_name SimGroups
extends RefCounted
## Movimiento en grupo (docs/diseno/jugabilidad/03-propuesta.md §1, proceso/21).
## Un ancla virtual sigue un solo camino A* a la velocidad del más lento; cada miembro
## camina hacia su lugar en la formación, relativo al ancla. Los rezagados corren, el
## grupo espera a quien quedó lejos y se disuelve al llegar. Todo en enteros, sin
## trigonometría: los rumbos salen de una tabla fija de 16 vectores.
##
## Un miembro sigue en el grupo mientras su orden sea la del grupo (mover, atacar en
## movimiento o pelear en camino): cualquier otra orden lo saca sola, sin avisar acá.

const P := 1000
const O := SimEntity.Order
## 16 rumbos, vectores unitarios × 1000 (constante geométrica, no de balance).
const DIRS: Array[Vector2i] = [Vector2i(1000, 0), Vector2i(924, 383), Vector2i(707, 707), Vector2i(383, 924),
	Vector2i(0, 1000), Vector2i(-383, 924), Vector2i(-707, 707), Vector2i(-924, 383),
	Vector2i(-1000, 0), Vector2i(-924, -383), Vector2i(-707, -707), Vector2i(-383, -924),
	Vector2i(0, -1000), Vector2i(383, -924), Vector2i(707, -707), Vector2i(924, -383)]
enum State { MARCHA, ESPERA, COMBATE, LLEGADA }

var sim: Sim
var groups := {} # id -> grupo (Dictionary); se recorren en orden de id
var _next_id := 1


func _init(s: Sim) -> void:
	sim = s


func cfg() -> Dictionary:
	return sim.data.reglas["grupo"]


## Rumbo (0..15) más parecido a la dirección (dx, dy): máximo producto escalar.
static func heading(dx: int, dy: int) -> int:
	var best := 0
	var best_v := -(1 << 60)
	for i in DIRS.size():
		var v := dx * DIRS[i].x + dy * DIRS[i].y
		if v > best_v:
			best_v = v
			best = i
	return best


## Lugar (lat, fwd) de un miembro, en coordenadas del mapa, con el ancla en (ax, ay).
static func slot_pos(ax: int, ay: int, rumbo: int, lat: int, fwd: int) -> Vector2i:
	var u: Vector2i = DIRS[rumbo]
	return Vector2i(ax + (u.x * fwd - u.y * lat) / 1000, ay + (u.y * fwd + u.x * lat) / 1000)


## Intenta mover `units` en grupo hacia (gx, gy). Devuelve las unidades que NO entraron
## (van solas, como antes); si no se forma grupo, devuelve todas.
## `then` ({"target": id}): al acercarse a `aldeanos_suelta_dist` del destino el grupo se
## disuelve y cada uno recibe esa orden (recolectar, construir, entregar). Solo se forma si el
## destino está lejos: cerca, cada uno va directo.
## `form`: "bloque" (por defecto), "linea", "abierta" o "columna" (reglas.grupo.formas); `rumbo`
## (0..15): hacia dónde mira al llegar, del arrastre del clic derecho; -1, el de la marcha.
func form(pid: int, units: Array[SimEntity], gx: int, gy: int, amove: bool, then: Dictionary = {}, shape: String = "", rumbo_final: int = -1) -> Array[SimEntity]:
	var c := cfg()
	var eligible: Array[SimEntity] = []
	var rest: Array[SimEntity] = []
	for e in units:
		if e.inside < 0 and (e.is_military() or e.fn == "civil") and e.def.get("agrupa", true):
			eligible.append(e)
		else:
			rest.append(e)
	if eligible.size() < int(c["min_unidades"]):
		return units
	# Núcleo: los que están cerca del centro de la selección; los de afuera van solos.
	var cx := 0
	var cy := 0
	for e in eligible:
		cx += e.x
		cy += e.y
	cx /= eligible.size()
	cy /= eligible.size()
	var core: Array[SimEntity] = []
	for e in eligible:
		if Sim.dist(e.x, e.y, cx, cy) <= int(c["formar_radio"]):
			core.append(e)
		else:
			rest.append(e)
	if core.size() < int(c["min_unidades"]):
		return units
	# Solo aldeanos: en bloque únicamente si el destino está lejos (cerca, cada uno corre).
	var all_civil := true
	for e in core:
		if e.fn != "civil":
			all_civil = false
	if (all_civil or not then.is_empty()) and Sim.dist(cx, cy, gx, gy) <= int(c["aldeanos_bloque_dist"]):
		return units
	var from := Vector2i(cx / P, cy / P)
	if sim.map.is_solid(from.x, from.y, pid):
		from = sim.map.nearest_free(from.x, from.y, 6, pid)
	var to := Vector2i(clampi(gx / P, 0, sim.map.n - 1), clampi(gy / P, 0, sim.map.n - 1))
	if sim.map.is_solid(to.x, to.y, pid):
		to = sim.map.nearest_free(to.x, to.y, 8, pid)
	if from.x < 0 or to.x < 0:
		return units
	var path := sim.map.find_path(from, to, pid)
	if path.is_empty():
		return units
	if not (c["formas"] as Array).has(shape):
		shape = c["formas"][0]
	# Sin rumbo pedido, mira hacia donde marcha; si no marcha (cambio de formación en el lugar), al 0.
	var rumbo := heading(gx - cx, gy - cy) if gx != cx or gy != cy else maxi(0, rumbo_final)
	var final_rumbo := rumbo_final if rumbo_final >= 0 and rumbo_final < DIRS.size() else rumbo
	# Lejos, la marcha mira al camino; en el lugar (o casi), ya mira al rumbo pedido.
	if Sim.dist(cx, cy, gx, gy) <= int(c["holgura"]) * 2:
		rumbo = final_rumbo
	var g := {"id": _next_id, "owner": pid, "members": [], "ax": from.x * P + P / 2, "ay": from.y * P + P / 2, "form": shape,
		"path": path, "path_i": 1, "spd": 0, "rumbo": rumbo, "final_rumbo": final_rumbo, "turn_tick": sim.tick,
		"state": State.MARCHA, "wait": 0, "calm": 0, "arrive_t": 0, "slots": {},
		"dest_x": path[path.size() - 1].x * P + P / 2, "dest_y": path[path.size() - 1].y * P + P / 2, "amove": amove, "then": then}
	if path[path.size() - 1] == Vector2i(gx / P, gy / P):
		g["dest_x"] = gx
		g["dest_y"] = gy
	_next_id += 1
	_assign_slots(g, core, cx, cy)
	for e in core:
		g["members"].append(e.id)
		e.group = g["id"]
		e.target = -1
		e.resume_amove = false
		e.order = O.ATTACK_MOVE if amove else O.MOVE
		e.amove_x = gx
		e.amove_y = gy
		e.path.clear()
		e.path_i = 0
		e.stuck = 0
		e.rumbo = final_rumbo
	groups[g["id"]] = g
	_update_speed(g)
	# Los de afuera del núcleo van solos a su lugar en el destino.
	return rest


## Formación por bandas (§1.3): línea, choque, distancia, asedio, apoyo de adelante hacia
## atrás; los montados en las alas. Dentro de cada banda, sin cruces. Formas (§1.9):
## bloque (ancho ~2:1), línea (`linea_filas` de fondo, hasta `ancho_max_linea`), abierta (el
## bloque con `abierta_hueco_pct` del hueco) y columna (`columna_ancho` de ancho, sin alas).
func _assign_slots(g: Dictionary, units: Array[SimEntity], cx: int, cy: int) -> void:
	var c := cfg()
	var u: Vector2i = DIRS[g["rumbo"]]
	var order: Array = c["orden_funciones"]
	var shape: String = g.get("form", "bloque")
	var bands := {}
	var wings: Array[SimEntity] = []
	for e in units:
		if shape != "columna" and e.fn == "choque" and (e.def.get("montado", false) or e.def.get("elefante", false)):
			wings.append(e)
			continue
		var k: String = e.fn if order.has(e.fn) else "apoyo"
		if not bands.has(k):
			bands[k] = []
		bands[k].append(e)
	var n := units.size() - wings.size()
	var w := mini(Sim.isqrt(maxi(1, 2 * n - 1)) + 1, int(c["ancho_max"]))
	var hueco := int(c["hueco"])
	match shape:
		"linea":
			var filas := maxi(1, int(c["linea_filas"]))
			w = clampi((n + filas - 1) / filas, 1, int(c["ancho_max_linea"]))
		"abierta":
			hueco = hueco * int(c["abierta_hueco_pct"]) / 100
		"columna":
			w = maxi(1, int(c["columna_ancho"]))
	var slots := {}
	var fwd := 0
	var half_w := 0
	var first := true
	for k in order:
		if not bands.has(k):
			continue
		var list: Array = bands[k]
		var r := 0
		for e: SimEntity in list:
			r = maxi(r, e.radius)
		var sep := 2 * r + hueco
		if not first:
			fwd -= sep
		first = false
		# Adelante primero (proyección sobre el rumbo), después de izquierda a derecha.
		list.sort_custom(func(a: SimEntity, b: SimEntity) -> bool:
			var pa := (a.x - cx) * u.x + (a.y - cy) * u.y
			var pb := (b.x - cx) * u.x + (b.y - cy) * u.y
			return pa > pb if pa != pb else a.id < b.id)
		var i := 0
		while i < list.size():
			var row: Array = list.slice(i, i + w)
			row.sort_custom(func(a: SimEntity, b: SimEntity) -> bool:
				var la := -(a.x - cx) * u.y + (a.y - cy) * u.x
				var lb := -(b.x - cx) * u.y + (b.y - cy) * u.x
				return la < lb if la != lb else a.id < b.id)
			var cnt := row.size()
			for j in cnt:
				var lat := (2 * j - (cnt - 1)) * sep / 2
				slots[(row[j] as SimEntity).id] = [lat, fwd]
				half_w = maxi(half_w, absi(lat) + sep / 2)
			i += w
			if i < list.size():
				fwd -= sep
	# Alas: montados a los costados de las primeras filas, alternando lados.
	var wr := 0
	for e in wings:
		wr = maxi(wr, e.radius)
	var wsep := 2 * wr + hueco
	var aw := int(c["ala_ancho"])
	for i in wings.size():
		var side := 1 if i % 2 == 0 else -1
		var k := i / 2
		var col := k % aw
		var row := k / aw
		slots[wings[i].id] = [side * (half_w + wsep / 2 + col * wsep), -row * wsep]
	# El ancla queda en el medio de la formación (de adelante hacia atrás).
	var tot := 0
	for id in slots:
		tot += int(slots[id][1])
	var mid := tot / maxi(1, slots.size())
	for id in slots:
		slots[id][1] = int(slots[id][1]) - mid
	g["slots"] = slots


## Un tick de todos los grupos: membresía, velocidad, espera, marcha del ancla y llegada.
func tick() -> void:
	if groups.is_empty():
		return
	var c := cfg()
	var ids := groups.keys()
	ids.sort()
	for gid in ids:
		var g: Dictionary = groups[gid]
		var members: Array = []
		var fighting := false
		for id in g["members"]:
			var e: SimEntity = sim.by_id.get(id)
			if e == null or not e.alive or e.group != gid:
				continue
			if not (e.order == O.MOVE or e.order == O.ATTACK_MOVE or (e.order == O.ATTACK and e.resume_amove)):
				e.group = -1
				continue
			members.append(id)
			if e.order == O.ATTACK:
				fighting = true
		g["members"] = members
		if members.is_empty():
			groups.erase(gid)
			continue
		if sim.tick % int(c["vel_cada_ticks"]) == 0:
			_update_speed(g)
		# Combate: el ancla se planta mientras alguien pelea.
		if fighting:
			g["calm"] = 0
			if g["state"] != State.LLEGADA:
				g["state"] = State.COMBATE
		else:
			g["calm"] = int(g["calm"]) + 1
			if g["state"] == State.COMBATE and int(g["calm"]) >= int(c["combate_calma_ticks"]):
				g["state"] = State.MARCHA
		# Grupo con tarea: se suelta cerca del destino y cada uno hace lo pedido.
		if not (g["then"] as Dictionary).is_empty() and (g["state"] == State.LLEGADA or Sim.dist(g["ax"], g["ay"], g["dest_x"], g["dest_y"]) <= int(c["aldeanos_suelta_dist"])):
			_release_then(g)
			groups.erase(gid)
			continue
		if g["state"] == State.MARCHA or g["state"] == State.ESPERA:
			_check_wait(g, c)
		if g["state"] == State.MARCHA:
			_advance(g, c)
		elif g["state"] == State.LLEGADA:
			g["arrive_t"] = int(g["arrive_t"]) + 1
			if int(g["arrive_t"]) > int(c["llegada_max_ticks"]):
				_release(g)
				groups.erase(gid)


func _update_speed(g: Dictionary) -> void:
	var spd := 1 << 30
	for id in g["members"]:
		var e: SimEntity = sim.by_id.get(id)
		if e != null and e.order != O.ATTACK and e.slow_until <= sim.tick:
			spd = mini(spd, sim.mods.speed(e))
	g["spd"] = spd if spd < (1 << 30) else 0


## Espera: si alguien quedó lejos de su lugar, el ancla se detiene; si tarda demasiado, se lo suelta.
func _check_wait(g: Dictionary, c: Dictionary) -> void:
	if sim.tick % 5 != 0 and g["state"] == State.MARCHA:
		return
	var worst := 0
	var worst_id := -1
	for id in g["members"]:
		var e: SimEntity = sim.by_id[id]
		if e.order == O.ATTACK or e.slow_until > sim.tick:
			continue
		var s: Array = g["slots"].get(id, [0, 0])
		var t := slot_pos(g["ax"], g["ay"], g["rumbo"], s[0], s[1])
		var lag := Sim.dist(e.x, e.y, t.x, t.y)
		if lag > worst:
			worst = lag
			worst_id = id
	if g["state"] == State.MARCHA and worst > int(c["espera_dist"]):
		g["state"] = State.ESPERA
		g["wait"] = 0
	elif g["state"] == State.ESPERA:
		g["wait"] = int(g["wait"]) + 1
		if worst < int(c["reanuda_dist"]):
			g["state"] = State.MARCHA
		elif int(g["wait"]) > int(c["espera_max_ticks"]) and worst_id >= 0:
			# Se lo suelta: va solo al destino y el grupo sigue.
			var e: SimEntity = sim.by_id[worst_id]
			e.group = -1
			g["members"].erase(worst_id)
			var s: Array = g["slots"].get(worst_id, [0, 0])
			var t := slot_pos(g["dest_x"], g["dest_y"], g["final_rumbo"], s[0], s[1])
			sim.order_move(e, t.x, t.y)
			g["state"] = State.MARCHA


func _advance(g: Dictionary, c: Dictionary) -> void:
	var path: Array = g["path"]
	var budget := int(g["spd"])
	while budget > 0:
		var i := int(g["path_i"])
		var tx: int
		var ty: int
		if i < path.size():
			tx = path[i].x * P + P / 2
			ty = path[i].y * P + P / 2
			if i == path.size() - 1:
				tx = g["dest_x"]
				ty = g["dest_y"]
		else:
			tx = g["dest_x"]
			ty = g["dest_y"]
		var dx := tx - int(g["ax"])
		var dy := ty - int(g["ay"])
		var d := Sim.isqrt(dx * dx + dy * dy)
		if d > 0 and sim.tick - int(g["turn_tick"]) >= int(c["giro_min_ticks"]) and d > P / 2:
			var h := heading(dx, dy)
			var diff := absi(h - int(g["rumbo"]))
			if mini(diff, 16 - diff) >= 2:
				g["rumbo"] = h
				g["turn_tick"] = sim.tick
		if d <= budget:
			g["ax"] = tx
			g["ay"] = ty
			budget -= d
			if i >= path.size() - 1:
				g["state"] = State.LLEGADA
				g["rumbo"] = g["final_rumbo"]
				return
			g["path_i"] = i + 1
		else:
			g["ax"] = int(g["ax"]) + dx * budget / d
			g["ay"] = int(g["ay"]) + dy * budget / d
			budget = 0


func _release_then(g: Dictionary) -> void:
	var units: Array[SimEntity] = []
	for id in g["members"]:
		var e: SimEntity = sim.by_id.get(id)
		if e != null and e.alive:
			e.group = -1
			units.append(e)
	var t: SimEntity = sim.by_id.get(int(g["then"].get("target", -1)))
	if t != null and t.alive:
		sim.order_target(g["owner"], units, t.id)
	else:
		for e in units:
			sim.order_move(e, g["dest_x"], g["dest_y"])


## Los que no llegaron a tiempo quedan con su orden individual hacia su lugar final.
func _release(g: Dictionary) -> void:
	for id in g["members"]:
		var e: SimEntity = sim.by_id.get(id)
		if e == null or not e.alive:
			continue
		e.group = -1
		var s: Array = g["slots"].get(id, [0, 0])
		var t := slot_pos(g["dest_x"], g["dest_y"], g["final_rumbo"], s[0], s[1])
		sim.order_move(e, t.x, t.y)


## Paso de un miembro hacia su lugar. Devuelve true si el grupo llegó y él está en su lugar.
func member_step(e: SimEntity) -> bool:
	var g: Dictionary = groups.get(e.group, {})
	if g.is_empty():
		e.group = -1
		return true
	var c := cfg()
	var s: Array = g["slots"].get(e.id, [0, 0])
	var t := slot_pos(g["ax"], g["ay"], g["rumbo"], s[0], s[1])
	# Paso angosto o lugar sobre algo sólido: sigue al ancla, y al llegar busca la casilla libre más cercana.
	if sim.map.is_solid(t.x / P, t.y / P, e.owner) or e.stuck > int(c["trabado_sigue_ancla"]):
		if g["state"] == State.LLEGADA:
			var f := sim.map.nearest_free(t.x / P, t.y / P, 3, e.owner)
			t = Vector2i(f.x * P + P / 2, f.y * P + P / 2) if f.x >= 0 else Vector2i(g["ax"], g["ay"])
		else:
			t = Vector2i(g["ax"], g["ay"])
	var lag := Sim.dist(e.x, e.y, t.x, t.y)
	var spd := sim.mods.speed(e)
	if lag > int(c["holgura"]) and e.cooldown <= 0:
		spd = spd * (100 + int(c["corrida_aldeano_pct"] if e.fn == "civil" else c["corrida_pct"])) / 100
	if lag > 0:
		sim.step_toward_speed(e, t.x, t.y, spd)
	return g["state"] == State.LLEGADA and lag <= int(c["holgura"])


func hash_into(h: int) -> int:
	var ids := groups.keys()
	ids.sort()
	for gid in ids:
		var g: Dictionary = groups[gid]
		for v in [gid, g["ax"], g["ay"], g["path_i"], g["state"], g["wait"], g["rumbo"], g["final_rumbo"], (g["members"] as Array).size()]:
			h = ((h ^ (int(v) & 0xffffffff)) * 16777619) & 0xffffffff
	return h
