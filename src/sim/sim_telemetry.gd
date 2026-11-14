class_name SimTelemetry
extends RefCounted
## Telemetría de la partida (proceso/20-telemetria): anota sucesos problemáticos con
## lugar y momento para encontrar mapas que traban, órdenes que fallan y una IA que
## se repite sin avanzar. Solo mira: no es estado, no entra en el hash ni cambia nada.
## Se guarda como JSONL (una línea de cabecera y una por suceso) y lo lee tools/telemetria.gd.
##
## Tipos:
##   trabada        una unidad se rindió en el camino (detalle: orden, destino)
##   sin_camino     el camino calculado no llega al destino pedido
##   rechazo        una orden rechazada por la simulación (detalle: mensaje)
##   ia_sin_lugar   la IA no encontró lugar para un edificio
##   ia_sin_ruta    la IA no pudo trazar un camino de caminos (inca)
##   ocioso         un aldeano lleva más de 30 s sin hacer nada
##   tick_lento     un tick tardó más de lo que entra en el cuadro (lo mide quien corre la simulación)

const MAX_EVENTS := 30000
const IDLE_CHECK_TICKS := 150 # 15 s: ocioso en dos revisiones seguidas = más de 15 s, menos de 30

var on := true
var events: Array = [] # [tick, tipo, jugador, casilla x, casilla y, detalle]
var counts := {} # tipo -> cantidad, también los que no entraron por el tope
var _last := {} # clave -> tick del último registro (para no repetir el mismo suceso)
var _idle_prev := {} # id de aldeano ocioso en la revisión anterior


## Registra un suceso. `key` y `every` evitan repetir el mismo suceso en menos de `every` ticks.
func add(tick: int, tipo: String, pid: int, tx: int, ty: int, det: Dictionary = {}, key: String = "", every: int = 0) -> void:
	if not on:
		return
	if key != "":
		if tick - int(_last.get(key, -(1 << 30))) < every:
			return
		_last[key] = tick
	counts[tipo] = int(counts.get(tipo, 0)) + 1
	if events.size() < MAX_EVENTS:
		events.append([tick, tipo, pid, tx, ty, det])


## Revisión periódica de aldeanos ociosos: los que estaban ociosos en la anterior también.
func check_idle(sim: Sim) -> void:
	if not on or sim.tick % IDLE_CHECK_TICKS != 0:
		return
	var now := {}
	for e in sim.actives:
		if e.alive and e.is_unit() and e.owner >= 0 and e.fn == "civil" and e.inside < 0 and e.order == SimEntity.Order.IDLE:
			now[e.id] = true
			if _idle_prev.has(e.id):
				add(sim.tick, "ocioso", e.owner, e.x / Sim.P, e.y / Sim.P, {}, "ocioso:%d" % e.id, 600)
	_idle_prev = now


func header(sim: Sim, seed_value: int, opts: Dictionary) -> Dictionary:
	var civs := []
	for p in sim.players:
		civs.append(p["civ"])
	return {"telemetria": 1, "semilla": seed_value, "jugadores": sim.players.size(), "civs": civs, "equipos": opts.get("equipos", []), "terreno": sim.terrain, "mapa": sim.map.n, "ticks": sim.tick, "tick_ms": sim.tick_ms, "totales": counts}


## Guarda la partida en `path` (JSONL). Devuelve false si no pudo escribir.
func save(path: String, head: Dictionary) -> bool:
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		return false
	f.store_line(JSON.stringify(head))
	for ev in events:
		f.store_line(JSON.stringify(ev))
	return true
