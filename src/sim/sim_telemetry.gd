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
##   recursos_flotando  un jugador tiene más de `telemetria.flotando` de algo sin gastar dos revisiones seguidas
##   produccion_ociosa  edificios que entrenan tropa con la cola vacía, dos revisiones seguidas (detalle: cuántos)

const MAX_EVENTS := 30000
const IDLE_CHECK_TICKS := 150 # 15 s: ocioso en dos revisiones seguidas = más de 15 s, menos de 30

var on := true
var events: Array = [] # [tick, tipo, jugador, casilla x, casilla y, detalle]
var counts := {} # tipo -> cantidad, también los que no entraron por el tope
var _last := {} # clave -> tick del último registro (para no repetir el mismo suceso)
var _idle_prev := {} # id de aldeano ocioso en la revisión anterior
var _float_prev := {} # "jugador:recurso" que ya flotaba en la revisión anterior
var _prod_prev := {} # id de edificio de producción ocioso en la revisión anterior
var viajes := {} # "jugador:recurso" -> [viajes, suma de distancias, máxima] en casillas, del recurso al depósito


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


## Un aldeano lleno vuelve a depositar: distancia (en casillas) al depósito más cercano.
## Mide la eficiencia de la economía (proceso/24, paso 1b): viajes largos = faltan almacenes.
func trip(pid: int, kind: String, tiles: int) -> void:
	if not on or pid < 0:
		return
	var key := "%d:%s" % [pid, kind]
	var v: Array = viajes.get(key, [0, 0, 0])
	v[0] += 1
	v[1] += tiles
	v[2] = maxi(v[2], tiles)
	viajes[key] = v


## Distancia media de viaje de un jugador a un recurso (-1 si no hubo viajes).
func mean_trip(pid: int, kind: String) -> int:
	var v: Array = viajes.get("%d:%s" % [pid, kind], [0, 0, 0])
	return -1 if v[0] == 0 else v[1] / v[0]


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
	_check_economy(sim)


## Recursos sin gastar y producción militar parada: lo que hundía a la IA etíope (proceso/21, paso 16).
func _check_economy(sim: Sim) -> void:
	var cfg: Dictionary = sim.data.reglas.get("telemetria", {})
	var limit := int(cfg.get("flotando", 800))
	var fl := {}
	for p in sim.players:
		if p["defeated"]:
			continue
		for k in ["alimento", "madera", "piedra", "riqueza"]:
			if int(p["res"].get(k, 0)) > limit:
				var key := "%d:%s" % [p["id"], k]
				fl[key] = true
				if _float_prev.has(key):
					add(sim.tick, "recursos_flotando", p["id"], -1, -1, {"recurso": k, "cantidad": int(p["res"][k])}, "rf:" + key, 600)
	_float_prev = fl
	var idle := {}
	var count := {}
	for b in sim.actives:
		if not (b.alive and b.owner >= 0 and b.is_building() and b.built and b.queue.is_empty() and not b.capital):
			continue
		var military := false
		for u in b.def.get("produce", []):
			if sim.dp(b.owner).unidades.get(u, {}).get("funcion", "") in ["choque", "distancia", "linea", "asedio"]:
				military = true
		if not military:
			continue
		idle[b.id] = true
		if _prod_prev.has(b.id):
			count[b.owner] = int(count.get(b.owner, 0)) + 1
	_prod_prev = idle
	for pid in count:
		if not sim.players[pid]["defeated"] and sim.players[pid]["pop"] < sim.players[pid]["pop_cap"]:
			add(sim.tick, "produccion_ociosa", pid, -1, -1, {"edificios": count[pid]}, "po:%d" % pid, 600)


func header(sim: Sim, seed_value: int, opts: Dictionary) -> Dictionary:
	var civs := []
	for p in sim.players:
		civs.append(p["civ"])
	return {"telemetria": 1, "semilla": seed_value, "jugadores": sim.players.size(), "civs": civs, "equipos": opts.get("equipos", []), "terreno": sim.terrain, "mapa": sim.map.n, "ticks": sim.tick, "tick_ms": sim.tick_ms, "totales": counts, "viajes": viajes}


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
