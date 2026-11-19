extends RefCounted
## Órdenes en cola con mayúsculas (lado del cliente).
##
## La simulación guarda una sola orden por unidad. Con mayúsculas + clic derecho
## (o + ataque en movimiento) la orden queda en esta cola y se envía como un comando
## normal cuando la unidad termina la anterior: la repetición y la partida en red
## ven solo comandos comunes, así que el determinismo no cambia.

const P := 1000
const O := SimEntity.Order

var sim: Sim
var local: int
var colas := {} # id de unidad -> Array[Dictionary] de órdenes pendientes
var _sent := {} # id -> tick en que se le mandó la última orden (todavía sin procesar)
var _k := 0
# --- fluidez 2 --- obras en cola (proceso/30-fluidez/02-constructor.md)
var _obra := {} # id -> id del edificio que levanta o repara por la cola, o [tipo, tx, ty, tick] si el cimiento todavía no tiene id
var _cadena := {} # id -> true: al terminar la reparación sigue con lo dañado cerca (data/constructor.json)
var cfg: Dictionary = {}
# --- fin fluidez 2 ---


func _init(s: Sim, local_player: int) -> void:
	sim = s
	local = local_player
	cfg = (JSON.parse_string(FileAccess.get_file_as_string("res://data/constructor.json")) as Dictionary) # --- fluidez 2 ---


## Clic derecho del jugador sobre el mundo o el minimapa. Con mayúsculas encola y
## devuelve true (el controlador no manda nada más); sin mayúsculas vacía la cola.
func orden_derecha(ids: Array, t: SimEntity, g: Vector3, shift: bool) -> bool:
	if not shift:
		limpiar(ids)
		_marcar_obra(ids, t) # --- fluidez 2 --- reparar sigue en cadena
		return false
	var cmd := {}
	if t != null and t.id not in ids and not (t.is_unit() and t.owner == local):
		cmd = {"t": "target", "target": t.id, "x": t.x, "y": t.y}
	else:
		cmd = {"t": "move", "x": int(g.x * P), "y": int(g.z * P), "amove": false}
	encolar(ids, cmd)
	return true


## Ataque en movimiento con mayúsculas: se encola como un paso más.
func orden_amove(ids: Array, g: Vector3) -> void:
	encolar(ids, {"t": "move", "x": int(g.x * P), "y": int(g.z * P), "amove": true})


func encolar(ids: Array, cmd: Dictionary) -> void:
	_k += 1
	cmd["k"] = _k
	var now: Array = []
	for id in ids:
		var e: SimEntity = sim.by_id.get(id)
		if e == null or not e.alive:
			continue
		if not colas.has(id) and _free(e):
			now.append(id)
		else:
			(colas.get_or_add(id, []) as Array).append(cmd)
	if not now.is_empty():
		_send(now, cmd)


func limpiar(ids: Array) -> void:
	for id in ids:
		colas.erase(id)
		_obra.erase(id) # --- fluidez 2 ---
		_cadena.erase(id)


func _free(e: SimEntity) -> bool:
	if sim.tick <= int(_sent.get(e.id, -10)) + 1:
		return false
	# --- fluidez 2 --- quien levanta o repara por la cola queda libre al terminar esa obra, aunque
	# la simulación ya lo haya mandado sola al cimiento más cercano o a recolectar.
	if _obra.has(e.id):
		var st := _estado_obra(e.id)
		if st == 0:
			return false
		_obra.erase(e.id)
		return true
	# --- fin fluidez 2 ---
	return e.order == O.IDLE


## Cada cuadro: a quien terminó su orden le llega la siguiente. Las unidades que
## reciben el mismo paso a la vez van en un solo comando (mantienen la formación).
func tick() -> void:
	_tick_cadena() # --- fluidez 2 ---
	if colas.is_empty():
		return
	var groups := {} # k -> [cmd, ids]
	for id in colas.keys():
		var e: SimEntity = sim.by_id.get(id)
		var q: Array = colas[id]
		if e == null or not e.alive or q.is_empty():
			colas.erase(id)
			continue
		if not _free(e):
			continue
		# --- fluidez 2 --- un cimiento encolado se manda cuando ya tiene id; si no aparece, se salta
		if q[0]["t"] == "obra":
			var ob := _cimiento(q[0])
			if ob == null and sim.tick <= int(q[0]["at"]) + ESPERA_CIMIENTO:
				continue
			var oc: Dictionary = q.pop_front()
			if q.is_empty():
				colas.erase(id)
			if ob == null or (ob.built and ob.hp >= ob.hp_max):
				continue
			var og: Array = groups.get_or_add(oc["k"], [{"t": "target", "target": ob.id, "x": ob.x, "y": ob.y, "k": oc["k"]}, []])
			(og[1] as Array).append(id)
			continue
		# --- fin fluidez 2 ---
		var cmd: Dictionary = q.pop_front()
		if q.is_empty():
			colas.erase(id)
		if cmd["t"] == "target":
			var t: SimEntity = sim.by_id.get(cmd["target"])
			if t == null or not t.alive:
				continue
		var g: Array = groups.get_or_add(cmd["k"], [cmd, []])
		(g[1] as Array).append(id)
	for k in groups:
		_send(groups[k][1], groups[k][0])


func _send(ids: Array, cmd: Dictionary) -> void:
	for id in ids:
		_sent[id] = sim.tick
	if cmd["t"] == "target":
		_marcar_obra(ids, sim.by_id.get(cmd["target"])) # --- fluidez 2 ---
		sim.push_command({"t": "target", "player": local, "ids": ids, "target": cmd["target"]})
	elif cmd["t"] == "mantener": # --- fluidez 5 --- Mayús + mantener posición
		sim.push_command({"t": "mantener", "player": local, "ids": ids})
	else:
		sim.push_command({"t": "move", "player": local, "ids": ids, "x": cmd["x"], "y": cmd["y"], "amove": cmd["amove"]})


## Puntos pendientes de una unidad, en casillas del mundo, para dibujar la línea.
func puntos(id: int) -> Array:
	var out := []
	for cmd: Dictionary in colas.get(id, []):
		# --- fluidez 2 --- cimiento en cola: su centro
		if cmd["t"] == "obra":
			var tam: Array = sim.dp(local).edificios[cmd["type"]]["tam"]
			out.append([int(cmd["tx"]) * P + int(tam[0]) * P / 2, int(cmd["ty"]) * P + int(tam[1]) * P / 2, true])
			continue
		# --- fin fluidez 2 ---
		if cmd["t"] == "mantener": # --- fluidez 5 --- sin lugar propio: se queda donde termine
			continue
		var x: int = cmd["x"]
		var y: int = cmd["y"]
		if cmd["t"] == "target":
			var t: SimEntity = sim.by_id.get(cmd["target"])
			if t != null:
				x = t.x
				y = t.y
		out.append([x, y, cmd["t"] == "target" or cmd.get("amove", false)])
	return out


# --- fluidez 2 --- obras en orden, reparar en cadena y por zona (proceso/30-fluidez/02-constructor.md)
## Ticks que se espera a que el cimiento encolado aparezca en la simulación (la orden de
## colocarlo puede llegar con demora en red). No es balance: es la paciencia del cliente.
const ESPERA_CIMIENTO := 30


## Coloca un cimiento. Sin Mayús, la orden de siempre (y se vacía la cola). Con Mayús, el
## primero lo empiezan los aldeanos ya; los siguientes se pagan y quedan en su cola, y se
## levantan en el orden en que se pusieron, sin límite de distancia.
func colocar(ids: Array, type: String, tx: int, ty: int, shift: bool) -> void:
	if not shift:
		limpiar(ids)
	var ocupados := false
	if shift:
		for id in ids:
			if colas.has(id) or (_obra.has(id) and _estado_obra(id) == 0):
				ocupados = true
	if not ocupados:
		sim.push_command({"t": "build", "player": local, "ids": ids, "type": type, "tx": tx, "ty": ty})
		for id in ids:
			_obra[id] = [type, tx, ty, sim.tick]
			_sent[id] = sim.tick
		return
	sim.push_command({"t": "build", "player": local, "ids": [], "type": type, "tx": tx, "ty": ty})
	_k += 1
	var cmd := {"t": "obra", "type": type, "tx": tx, "ty": ty, "at": sim.tick, "k": _k}
	for id in ids:
		var e: SimEntity = sim.by_id.get(id)
		if e != null and e.alive:
			(colas.get_or_add(id, []) as Array).append(cmd)


## Cimiento propio de ese tipo en esa casilla (null si todavía no está o ya no está).
func _cimiento(cmd: Dictionary) -> SimEntity:
	var b: SimEntity = sim.by_id.get(sim.map.occupant(int(cmd["tx"]), int(cmd["ty"])))
	if b == null or not b.alive or b.owner != local or b.type != cmd["type"] or b.tx != int(cmd["tx"]) or b.ty != int(cmd["ty"]):
		return null
	return b


## 0: la obra sigue (falta construir o reparar); 1: terminó, cayó o no llegó a ponerse.
func _estado_obra(id: int) -> int:
	var o = _obra[id]
	var b: SimEntity = null
	if o is Array:
		b = _cimiento({"type": o[0], "tx": o[1], "ty": o[2]})
		if b == null:
			return 0 if sim.tick <= int(o[3]) + ESPERA_CIMIENTO else 1
		_obra[id] = b.id
	else:
		b = sim.by_id.get(o)
	if b == null or not b.alive or (b.built and b.hp >= b.hp_max):
		return 1
	return 0


## Si la orden va a un edificio propio sin terminar o dañado, se anota: al terminarlo, el
## aldeano sigue con lo que tenga en la cola, y si era una reparación, con lo dañado cerca.
func _marcar_obra(ids: Array, t: SimEntity) -> void:
	if t == null or not t.alive or not t.is_building() or t.owner != local or (t.built and t.hp >= t.hp_max):
		return
	for id in ids:
		var e: SimEntity = sim.by_id.get(id)
		if e == null or e.fn != "civil":
			continue
		_obra[id] = t.id
		if t.built:
			_cadena[id] = true


## Reparar en cadena: quien terminó una reparación ordenada y no tiene nada en la cola va al
## edificio propio dañado más cercano (data/constructor.json → reparar_cadena_radio).
func _tick_cadena() -> void:
	if _cadena.is_empty():
		return
	for id in _cadena.keys():
		var e: SimEntity = sim.by_id.get(id)
		if e == null or not e.alive:
			_cadena.erase(id)
			continue
		if not _obra.has(id):
			_cadena.erase(id)
			continue
		if colas.has(id) or sim.tick <= int(_sent.get(id, -10)) + 1 or _estado_obra(id) == 0:
			continue
		_obra.erase(id)
		var b := danado_cerca(e.x, e.y, int(cfg.get("reparar_cadena_radio", 10)) * P)
		if b == null:
			_cadena.erase(id)
			continue
		_send([id], {"t": "target", "target": b.id})


## Edificio propio terminado y dañado más cercano a (x, y) dentro de `rad` (milésimas).
func danado_cerca(x: int, y: int, rad: int, salvo: Array = []) -> SimEntity:
	var best: SimEntity = null
	var best_d := rad + 1
	for b in sim.actives:
		if b.alive and b.is_building() and b.owner == local and b.built and b.hp < b.hp_max and not salvo.has(b.id):
			var d := Sim.dist(x, y, b.x, b.y)
			if d < best_d:
				best = b
				best_d = d
	return best


## «Reparar (zona)»: reparte a los aldeanos entre los edificios propios dañados cerca de ellos,
## del más cercano al más lejano; cada uno sigue después en cadena. Devuelve cuántos hay.
func reparar_zona(ids: Array) -> int:
	var vs: Array[SimEntity] = []
	var cx := 0
	var cy := 0
	for id in ids:
		var e: SimEntity = sim.by_id.get(id)
		if e != null and e.alive and e.fn == "civil" and e.owner == local:
			vs.append(e)
			cx += e.x
			cy += e.y
	if vs.is_empty():
		return 0
	cx /= vs.size()
	cy /= vs.size()
	var rad := int(cfg.get("reparar_zona_radio", 12)) * P
	var danados: Array[SimEntity] = []
	var b := danado_cerca(cx, cy, rad)
	while b != null:
		danados.append(b)
		b = danado_cerca(cx, cy, rad, danados.map(func(d: SimEntity) -> int: return d.id))
	if danados.is_empty():
		return 0
	limpiar(ids)
	var grupos := {}
	for i in vs.size():
		(grupos.get_or_add(danados[i % danados.size()].id, []) as Array).append(vs[i].id)
	for bid in grupos:
		_send(grupos[bid], {"t": "target", "target": bid})
	return danados.size()


## Huellas fantasma de los edificios propios que tiró el rival: {type, tx, ty, hasta (tick)}.
var huellas: Array = []


func on_died(ev: Dictionary) -> void:
	if int(ev.get("owner", -1)) != local or int(ev.get("cat", -1)) != SimEntity.Cat.BUILDING:
		return
	var by := int(ev.get("by", -1))
	if by < 0 or by == local:
		return # lo demolió el dueño o no hubo atacante: no queda huella
	var def: Dictionary = sim.dp(local).edificios.get(String(ev["type"]), {})
	if def.is_empty() or def.get("linea", false) or def.get("avanza_edad", false) or def.get("maravilla", false) or def.get("camino", false):
		return
	var tam: Array = def["tam"]
	var tx := (int(ev["x"]) - int(tam[0]) * P / 2) / P
	var ty := (int(ev["y"]) - int(tam[1]) * P / 2) / P
	var dur := int(cfg.get("huella_s", 180)) * 1000 / sim.tick_ms
	huellas.append({"type": String(ev["type"]), "tx": tx, "ty": ty, "hasta": sim.tick + dur})


## Huella bajo la casilla (x, y en milésimas), o {}. De paso olvida las vencidas o ya ocupadas.
func huella_en(x: int, y: int) -> Dictionary:
	var keep := []
	var hit := {}
	for h: Dictionary in huellas:
		if sim.tick > int(h["hasta"]):
			continue
		var b: SimEntity = sim.by_id.get(sim.map.occupant(int(h["tx"]), int(h["ty"])))
		if b != null and b.alive and b.owner == local and b.type == h["type"]:
			continue # ya se volvió a poner
		keep.append(h)
		var tam: Array = sim.dp(local).edificios[h["type"]]["tam"]
		if x >= int(h["tx"]) * P and x < (int(h["tx"]) + int(tam[0])) * P and y >= int(h["ty"]) * P and y < (int(h["ty"]) + int(tam[1])) * P:
			hit = h
	huellas = keep
	return hit


## Vuelve a poner el cimiento de la huella con los aldeanos `ids`. Devuelve "" o el motivo.
func reconstruir(ids: Array, h: Dictionary, shift: bool) -> String:
	var type: String = h["type"]
	if not sim.can_place(type, int(h["tx"]), int(h["ty"]), local):
		return "No se puede reconstruir: el lugar está ocupado"
	var cost := sim.build_cost(local, type)
	if not sim.can_afford(local, cost):
		return "Faltan recursos para reconstruir"
	colocar(ids, type, int(h["tx"]), int(h["ty"]), shift)
	huellas.erase(h)
	return ""
# --- fin fluidez 2 ---
