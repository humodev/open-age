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


func _init(s: Sim, local_player: int) -> void:
	sim = s
	local = local_player


## Clic derecho del jugador sobre el mundo o el minimapa. Con mayúsculas encola y
## devuelve true (el controlador no manda nada más); sin mayúsculas vacía la cola.
func orden_derecha(ids: Array, t: SimEntity, g: Vector3, shift: bool) -> bool:
	if not shift:
		limpiar(ids)
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


func _free(e: SimEntity) -> bool:
	return e.order == O.IDLE and sim.tick > int(_sent.get(e.id, -10)) + 1


## Cada cuadro: a quien terminó su orden le llega la siguiente. Las unidades que
## reciben el mismo paso a la vez van en un solo comando (mantienen la formación).
func tick() -> void:
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
		sim.push_command({"t": "target", "player": local, "ids": ids, "target": cmd["target"]})
	else:
		sim.push_command({"t": "move", "player": local, "ids": ids, "x": cmd["x"], "y": cmd["y"], "amove": cmd["amove"]})


## Puntos pendientes de una unidad, en casillas del mundo, para dibujar la línea.
func puntos(id: int) -> Array:
	var out := []
	for cmd: Dictionary in colas.get(id, []):
		var x: int = cmd["x"]
		var y: int = cmd["y"]
		if cmd["t"] == "target":
			var t: SimEntity = sim.by_id.get(cmd["target"])
			if t != null:
				x = t.x
				y = t.y
		out.append([x, y, cmd["t"] == "target" or cmd.get("amove", false)])
	return out
