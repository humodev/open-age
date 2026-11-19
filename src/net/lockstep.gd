class_name Lockstep
extends RefCounted
## Lockstep determinista (proceso/37, docs/06 «Multijugador»).
##
## - Un turno son T ticks. Al empezar el turno n, el jugador local cierra lo que juntó y lo
##   manda como sus comandos del turno n + D (D = retardo de entrada).
## - El turno n se ejecuta solo con los mensajes de todos los jugadores; los turnos 0..D-1
##   están vacíos por definición. Los comandos se inyectan en orden de jugador, en el primer
##   tick del turno: las dos máquinas arman la misma cola.
## - Cada M ticks se manda el hash del estado; si dos hashes del mismo tick difieren, queda
##   la desincronización con su tick.
## - La pausa viaja en el mensaje de turno (las dos máquinas la cuentan igual); la vuelta
##   es un mensaje aparte o el fin del plazo.
## No usa la red: lo que hay que mandar queda en `salida` y lo recibido entra por recibir().

signal desincronizado(tick: int)

var sim: Sim
var local := 0
var jugadores: Array = [] # los de la red, en orden
var T := 1
var D := 3
var D0 := 3 # --- instantaneas --- el retardo de arranque: los turnos 0..D0-1 están vacíos (D cambia con el ping)
var M := 50
var pausas_max := 3
var pausa_ms := 60000

var turnos := {} # turno -> {jugador: mensaje}
var enviados_hasta := -1 # último turno con mensaje local
var inyectado_hasta := -1 # último turno ya puesto en la simulación
var buffer: Array = [] # comandos locales del turno que corre
var hashes := {} # jugador -> {tick: hash}
var desync_tick := -1
var pausas_usadas := {}
var pausa_de := -1 # jugador que pausó (-1: sin pausa)
var pausa_turno := -1
var pausa_desde := 0
var reanudado_hasta := -1 # pausas de turnos <= esto ya se levantaron (llegó «reanudar»)
var _pedir_pausa := false
var _propios_importados_hasta := -1 # --- instantaneas --- último turno propio que vino de afuera (re-simulación)
var salida: Array = []


func _init(s: Sim, pid_local: int, pids: Array, cfg: Dictionary) -> void:
	sim = s
	local = pid_local
	jugadores = pids.duplicate()
	jugadores.sort()
	T = maxi(1, int(cfg.get("ticks_por_turno", 1)))
	D = maxi(1, int(cfg.get("retardo_turnos", 3)))
	D0 = D
	M = maxi(1, int(cfg.get("hash_cada_ticks", 50)))
	pausas_max = int(cfg.get("pausas_por_jugador", 3))
	pausa_ms = int(cfg.get("pausa_s", 60)) * 1000
	enviados_hasta = D0 - 1
	for p in jugadores:
		hashes[p] = {}
		pausas_usadas[p] = 0


func es_de_red(pid: int) -> bool:
	return pid in jugadores


## Entrada de comandos (SimRed.push_command): los propios esperan al cierre del turno;
## los del otro jugador de la red llegan por la red.
func comando(cmd: Dictionary) -> void:
	if int(cmd.get("player", -1)) == local:
		var c := cmd.duplicate(true)
		c.erase("tick")
		buffer.append(c)


func turno() -> int:
	return sim.tick / T


## Antes de cada sim.step(): cierra el turno si empieza uno, inyecta lo que toca y dice si
## se puede avanzar (falta un mensaje, pausa o desincronización: no).
func listo() -> bool:
	if sim.tick % T == 0:
		var n := sim.tick / T
		_cerrar(n)
		if inyectado_hasta < n:
			if not completo(n):
				return false
			_inyectar(n)
	if pausa_de >= 0 and Time.get_ticks_msec() - pausa_desde >= pausa_ms:
		pausa_de = -1
	return pausa_de < 0 and desync_tick < 0


## Después de cada sim.step(): el hash cada M ticks.
func despues() -> void:
	if sim.tick % M != 0:
		return
	var h := sim.state_hash()
	hashes[local][sim.tick] = h
	salida.append({"tipo": "hash", "j": local, "t": sim.tick, "h": h})
	_comparar(sim.tick)


func completo(n: int) -> bool:
	if n < D0:
		return true
	if not turnos.has(n):
		return false
	for p in jugadores:
		if not (turnos[n] as Dictionary).has(p):
			return false
	return true


## Turnos completos por delante del actual (para alcanzar tras una reconexión o un tirón).
func atraso() -> int:
	var n := turno()
	var k := n
	while completo(k + 1):
		k += 1
	return k - n


func recibir(msg: Dictionary) -> void:
	match str(msg.get("tipo", "")):
		"turno":
			_guardar(msg)
		"hash":
			var j := int(msg["j"])
			if hashes.has(j):
				hashes[j][int(msg["t"])] = int(msg["h"])
				_comparar(int(msg["t"]))
		"reanudar":
			reanudado_hasta = maxi(reanudado_hasta, int(msg.get("n", -1)))
			if pausa_de >= 0 and pausa_turno <= reanudado_hasta:
				pausa_de = -1


# --- instantaneas ---
## Retardo de entrada nuevo (turnos). Subirlo llena los turnos del medio con mensajes vacíos;
## bajarlo deja lo juntado para el primer turno que todavía no se mandó. Cada jugador tiene
## el suyo: los turnos llevan su número, así que las dos máquinas inyectan lo mismo.
func ajustar_retardo(nuevo: int) -> void:
	D = maxi(1, nuevo)


## Después de volcar una foto en el tick de la simulación: lo inyectado hasta `inyectado` ya
## está en la foto (también los comandos pendientes), y las pausas usadas vienen aparte.
func desde_foto(inyectado: int, pausas: Dictionary) -> void:
	inyectado_hasta = inyectado
	enviados_hasta = maxi(enviados_hasta, inyectado)
	for p in pausas:
		if pausas_usadas.has(int(p)):
			pausas_usadas[int(p)] = int(pausas[p])
# --- fin instantaneas ---


func pedir_pausa() -> bool:
	if pausa_de >= 0 or _pedir_pausa or int(pausas_usadas.get(local, 0)) >= pausas_max:
		return false
	_pedir_pausa = true
	return true


func reanudar() -> void:
	if pausa_de < 0:
		return
	reanudado_hasta = maxi(reanudado_hasta, pausa_turno)
	salida.append({"tipo": "reanudar", "n": pausa_turno})
	pausa_de = -1


func pausa_restante_s() -> int:
	return maxi(0, (pausa_ms - (Time.get_ticks_msec() - pausa_desde)) / 1000) if pausa_de >= 0 else 0


## Todo lo jugado: los mensajes de turno de todos (para el que vuelve) o solo los propios.
func registro(solo_local := false, desde := 0) -> Array:
	var out: Array = []
	var ks := turnos.keys()
	ks.sort()
	for n in ks:
		if n < desde: # --- instantaneas --- lo anterior va en la foto
			continue
		for p in jugadores:
			if turnos[n].has(p) and (not solo_local or p == local):
				out.append(turnos[n][p])
	return out


func hashes_de(pid: int, desde_tick := 0) -> Array:
	var out: Array = []
	for t in hashes.get(pid, {}):
		if t < desde_tick: # --- instantaneas ---
			continue
		out.append({"tipo": "hash", "j": pid, "t": t, "h": hashes[pid][t]})
	return out


func importar(msgs: Array) -> void:
	for m: Dictionary in msgs:
		if str(m.get("tipo", "")) == "turno" and int(m.get("j", -1)) == local:
			_propios_importados_hasta = maxi(_propios_importados_hasta, int(m.get("n", -1)))
		recibir(m)
	# Lo propio que ya estaba jugado no se vuelve a mandar ni a cerrar.
	var n := enviados_hasta
	while turnos.has(n + 1) and (turnos[n + 1] as Dictionary).has(local):
		n += 1
	enviados_hasta = n


func _guardar(msg: Dictionary) -> void:
	var n := int(msg["n"])
	var j := int(msg["j"])
	if not j in jugadores or n <= inyectado_hasta:
		return
	if not turnos.has(n):
		turnos[n] = {}
	if not (turnos[n] as Dictionary).has(j):
		turnos[n][j] = msg


func _cerrar(n: int) -> void:
	var meta := n + D
	if turnos.has(meta) and (turnos[meta] as Dictionary).has(local):
		# --- instantaneas --- re-simulación: el turno ya estaba jugado y registrado, y lo
		# juntado ahora ya está en él. Si no (el retardo bajó), lo juntado espera al próximo.
		if meta <= _propios_importados_hasta:
			buffer.clear()
		enviados_hasta = maxi(enviados_hasta, meta)
		return
	while enviados_hasta < meta:
		var k := enviados_hasta + 1
		var msg := {"tipo": "turno", "j": local, "n": k, "c": [] as Array}
		if k == meta:
			msg["c"] = buffer
			buffer = []
			if _pedir_pausa:
				msg["pausa"] = true
				_pedir_pausa = false
		_guardar(msg)
		salida.append(msg)
		enviados_hasta = k


func _inyectar(n: int) -> void:
	inyectado_hasta = n
	if not turnos.has(n):
		return
	var at := n * T
	for p in jugadores:
		var msg: Dictionary = turnos[n][p]
		for c: Dictionary in msg.get("c", []):
			var cc := c.duplicate(true)
			cc["player"] = p # cada uno manda solo por sí mismo
			cc["tick"] = at
			sim.recording.append(cc.duplicate(true))
			sim.schedule([cc])
		if msg.get("pausa", false) and int(pausas_usadas[p]) < pausas_max:
			pausas_usadas[p] = int(pausas_usadas[p]) + 1
			if n > reanudado_hasta:
				pausa_de = p
				pausa_turno = n
				pausa_desde = Time.get_ticks_msec()


func _comparar(t: int) -> void:
	var h0 = null
	for p in jugadores:
		if not hashes[p].has(t):
			return
		if h0 == null:
			h0 = hashes[p][t]
		elif hashes[p][t] != h0:
			if desync_tick < 0 or t < desync_tick:
				desync_tick = t
				desincronizado.emit(t)
			return
