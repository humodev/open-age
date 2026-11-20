class_name SesionRed
extends Node
## Sesión de red 1v1 (proceso/37): la sala, el arranque, el lockstep durante la partida,
## la pausa limitada y la reconexión. Vive bajo /root, así sobrevive a los reinicios de main.
##
## Mensajes (diccionarios con "tipo"):
##   hola {civ, color, listo, inyectado}  cliente → anfitrión, al conectarse (también al volver;
##                                 inyectado: hasta qué turno tiene la partida, -1 si volvió de cero)
##   elijo {civ, color, listo}     cliente → anfitrión, al cambiar algo en la sala
##   sala {sala}                   anfitrión → cliente, el estado de la sala
##   empezar {args}                anfitrión → cliente, la partida (args de main.gd)
##   retomar {args, log, hashes, reanudado, foto, inyectado, pausas}  anfitrión → cliente que vuelve
##                                 en plena partida: si volvió de cero, la foto del estado (SimEstado)
##                                 y solo los turnos de después; si no, los turnos que le faltan
##   ping {t}, pong {t}            ida y vuelta para medir el ping y ajustar el retardo de entrada
##   turnos {log}                  cliente → anfitrión al volver: lo propio, por si se perdió algo
##   turno, hash, reanudar         del lockstep (lockstep.gd)
##
## --- caida anfitrion --- (proceso/37-red/03) Si se cae el anfitrión, el invitado reintenta
## y a los caida_anfitrion_s segundos puede seguir contra la IA (seguir_con_ia) o guardar y
## salir (guardar_y_salir); mientras tanto sigue reintentando. Si el anfitrión vuelve de cero
## (sala nueva en el mismo puerto), el invitado le manda «retomar» con su foto y el anfitrión
## sigue desde ella: la partida del invitado es la que vale.

signal sala_cambio
signal empezar(args: Dictionary)
signal aviso(texto: String)
signal anfitrion_caido_cambio(caido: bool) # --- caida anfitrion ---

static var activa: SesionRed = null

var cfg: Dictionary = {}
var transporte := RedTransporte.new()
var estado := "nada" # nada, conectando, sala, partida, fin
var local := 0
var sala := {}
var args: Dictionary = {}
var lock: Lockstep = null
var sim: Sim = null
var _pendiente: Array = []
var _reanudado := -1
var _ip := ""
var _puerto := 0
var _espera_desde := -1 # se cayó el otro: desde cuándo (ms)
var _reintento := 0
var _parado_desde := -1 # sin poder avanzar (falta el turno del otro)
var _texto := ""
var _capa: CanvasLayer
var _rotulo: Label
# --- instantaneas ---
var _foto := PackedByteArray() # la foto que mandó el anfitrión, hasta volcarla
var _foto_info := {} # inyectado y pausas de la foto
var _rtts: Array = [] # últimos pings (ms)
var _prox_ping := 0
var _prox_ajuste := 0
var rechazados := 0 # mensajes descartados por la validación
var ping_ms := -1
var recuperada_en := -1 # tick en que se volcó la foto del anfitrión (-1: no hizo falta)
var anfitrion_caido := false # --- caida anfitrion --- el invitado ya puede elegir qué hacer
var foto_mandada_en := -1 # --- caida anfitrion --- tick de la foto que el invitado le mandó al anfitrión que volvió
# --- retomar con identificador --- (proceso/30-fluidez/09) La última partida del anfitrión en
# user://: al volver de cero, solo acepta el «retomar» de esa partida y de ese jugador caído.
const RETOMABLE := "user://red/retomable.json"
var retomable := {} # {partida, jugador}: lo que este anfitrión puede retomar ({} si nada)
var _botones: HBoxContainer = null


func _init() -> void:
	cfg = JSON.parse_string(FileAccess.get_file_as_string("res://data/red.json"))
	transporte.timeout_min_ms = int(cfg.get("timeout_min_ms", 3000))
	transporte.timeout_max_ms = int(cfg.get("timeout_max_ms", 8000))
	transporte.max_bytes = int((cfg.get("validacion", {}) as Dictionary).get("max_bytes", 16777216)) # --- instantaneas ---
	transporte.conectado.connect(_al_conectar)
	transporte.desconectado.connect(_al_desconectar)
	sala = {
		"jugadores": [
			{"civ": "azar", "color": 0, "listo": false, "conectado": true},
			{"civ": "azar", "color": 1, "listo": false, "conectado": false},
		],
		"opciones": {"terreno": "", "tamano": "normal", "recursos": "normal", "sitios": true, "hitos": true, "maravilla": true, "semilla": -1},
	}


## La sesión de esta máquina (una sola a la vez), colgada de /root.
static func nueva(tree: SceneTree) -> SesionRed:
	if activa != null and is_instance_valid(activa):
		activa.cerrar()
	var s := SesionRed.new()
	s.name = "SesionRed"
	tree.root.add_child(s)
	activa = s
	return s


func puerto_defecto() -> int:
	return int(cfg.get("puerto", 47800))


func crear(puerto: int) -> Error:
	local = 0
	_puerto = puerto
	retomable = leer_retomable() # --- retomar con identificador ---
	var err := transporte.crear(puerto)
	if err == OK:
		estado = "sala"
		_decir("Esperando rival en el puerto %d" % puerto)
	return err


func unirse(ip: String, puerto: int) -> Error:
	local = 1
	_ip = ip
	_puerto = puerto
	var err := transporte.unirse(ip, puerto)
	if err == OK:
		estado = "conectando"
		_reintento = Time.get_ticks_msec() + int(cfg.get("espera_conexion_s", 15)) * 1000
		_decir("Conectando con %s:%d…" % [ip, puerto])
	return err


func cerrar() -> void:
	_resumen()
	transporte.cerrar()
	if sim is SimRed:
		(sim as SimRed).red = null
	lock = null
	sim = null
	estado = "nada"
	if activa == self:
		activa = null
	queue_free()


## Al cerrar: hasta dónde los dos estuvieron de acuerdo (para las pruebas a mano).
func _resumen() -> void:
	if lock == null or sim == null:
		return
	var ult := -1
	for t in lock.hashes[0]:
		if lock.hashes[1].has(t) and lock.hashes[1][t] == lock.hashes[0][t]:
			ult = maxi(ult, int(t))
	print("RED: jugador %d · tick %d · hashes iguales hasta el tick %d · desincronización %s · pausas %s" % [local, sim.tick, ult, "en %d" % lock.desync_tick if lock.desync_tick >= 0 else "no", lock.pausas_usadas])


func _exit_tree() -> void:
	_resumen()
	transporte.cerrar() # --- soltar --- el par ENet y sus señales apuntan al transporte
	if sim is SimRed:
		(sim as SimRed).soltar()
	lock = null
	sim = null


func es_anfitrion() -> bool:
	return local == 0


func conectado() -> bool:
	return transporte.conectado_ahora()


# ---------------------------------------------------------------- Sala

## Cambia lo propio (pueblo, color, listo).
func elegir(civ: String, color: int, listo: bool) -> void:
	sala["jugadores"][local] = {"civ": civ, "color": color, "listo": listo, "conectado": true}
	if es_anfitrion():
		_mandar_sala()
	else:
		transporte.enviar({"tipo": "elijo", "civ": civ, "color": color, "listo": listo})
	sala_cambio.emit()


## Mapa y opciones (solo el anfitrión).
func opciones(op: Dictionary) -> void:
	if not es_anfitrion():
		return
	(sala["opciones"] as Dictionary).merge(op, true)
	_mandar_sala()
	sala_cambio.emit()


func puede_empezar() -> String:
	var js: Array = sala["jugadores"]
	if not js[1]["conectado"]:
		return "Falta el rival"
	if not js[0]["listo"] or not js[1]["listo"]:
		return "Falta que los dos estén listos"
	if int(js[0]["color"]) == int(js[1]["color"]):
		return "Los dos eligieron el mismo color"
	return ""


## El anfitrión arranca: arma los argumentos con la partida a medida y los manda.
func empezar_partida() -> void:
	if not es_anfitrion() or estado != "sala" or puede_empezar() != "":
		return
	var data := SimData.load_default()
	var civ_keys: Array = data.civs.keys().filter(func(k: String) -> bool: return not data.civs[k].civ.get("solo_ia", false))
	civ_keys.sort()
	var pc := PartidaConfig.defecto()
	var op: Dictionary = sala["opciones"]
	for k in ["terreno", "tamano", "recursos", "sitios", "hitos", "maravilla"]:
		pc[k] = op[k]
	var semilla := int(op.get("semilla", -1))
	pc["semilla"] = semilla if semilla >= 0 else randi() % 100000
	for i in PartidaConfig.MAX:
		pc["jugadores"][i]["tipo"] = "cerrado"
	for i in 2:
		var j: Dictionary = sala["jugadores"][i]
		var civ := str(j["civ"])
		if civ == "" or civ == "azar":
			civ = civ_keys[randi() % civ_keys.size()]
		pc["jugadores"][i] = {"tipo": "vos", "civ": civ, "dificultad": "normal", "estilo": "normal", "equipo": 0, "color": int(j["color"])}
	var a := PartidaConfig.a_args(pc)
	a["red"] = "1"
	a["red_partida"] = "%d-%d" % [int(Time.get_unix_time_from_system()), randi() % 1000000] # --- retomar con identificador ---
	transporte.enviar({"tipo": "empezar", "args": a})
	_arrancar(a)


func _mandar_sala() -> void:
	transporte.enviar({"tipo": "sala", "sala": sala})


func _arrancar(a: Dictionary) -> void:
	args = a
	estado = "partida"
	if es_anfitrion(): # --- retomar con identificador --- por si me caigo y vuelvo de cero
		_guardar_retomable(str(a.get("red_partida", "")), local)
	var b := a.duplicate(true)
	b["red_jugador"] = str(local)
	empezar.emit(b)


# ---------------------------------------------------------------- Partida

## SimRed._init: la simulación nueva se engancha a la red (y si vuelve, recupera lo jugado).
func adjuntar(s: Sim) -> void:
	if estado != "partida":
		return
	sim = s
	lock = Lockstep.new(s, local, [0, 1], cfg)
	lock.desincronizado.connect(func(t: int) -> void:
		push_error("Desincronización en el tick %d" % t)
		_decir("Desincronización en el tick %d" % t))
	(s as SimRed).red = lock
	lock.reanudado_hasta = _reanudado
	if not _foto.is_empty():
		return # --- instantaneas --- se importa al volcar la foto (volcar_foto)
	lock.importar(_pendiente)
	_pendiente = []


# --- instantaneas ---
## Vuelve de cero con la foto del anfitrión: la vuelca en la simulación recién armada (con sus
## IA) y sigue desde ese tick, sin re-simular. main.gd la llama antes de armar la vista; si
## no, la primera vez que se pregunta si se puede avanzar.
func volcar_foto() -> void:
	if _foto.is_empty() or sim == null or lock == null:
		return
	var t0 := Time.get_ticks_msec()
	var ok := SimEstado.cargar(sim, _foto)
	_foto = PackedByteArray()
	if not ok:
		estado = "fin"
		transporte.cerrar()
		_decir("No se pudo recuperar la partida (¿otra versión del juego?)")
		return
	lock.desde_foto(int(_foto_info.get("inyectado", -1)), _foto_info.get("pausas", {}))
	recuperada_en = sim.tick
	lock.importar(_pendiente)
	_pendiente = []
	_decir("Partida recuperada en el tick %d (foto en %d ms)" % [sim.tick, Time.get_ticks_msec() - t0])


## Retardo de entrada según el ping: lo que tarda en llegar un turno (la mitad del peor ping
## reciente) más un margen, en turnos, dentro de [retardo_min_turnos, retardo_max_turnos].
func retardo_para(rtt_ms: int, tick_ms: int) -> int:
	var turno_ms := maxi(1, int(cfg.get("ticks_por_turno", 1)) * tick_ms)
	var d := (rtt_ms / 2 + int(cfg.get("retardo_margen_ms", 60)) + turno_ms - 1) / turno_ms
	return clampi(d, int(cfg.get("retardo_min_turnos", 2)), int(cfg.get("retardo_max_turnos", 10)))


func _medir_ping(ahora: int) -> void:
	if estado != "partida" or lock == null or not transporte.conectado_ahora():
		return
	if ahora >= _prox_ping:
		_prox_ping = ahora + int(cfg.get("ping_cada_ms", 500))
		transporte.enviar({"tipo": "ping", "t": ahora})
	if ahora >= _prox_ajuste and not _rtts.is_empty():
		_prox_ajuste = ahora + int(cfg.get("retardo_ajuste_cada_ms", 2000))
		# El peor ping reciente sin el pico más alto (un tirón al cargar no fija el retardo).
		var orden := _rtts.duplicate()
		orden.sort()
		var peor: int = orden[-2] if orden.size() >= 4 else orden[-1]
		ping_ms = peor
		var d := retardo_para(peor, sim.tick_ms if sim != null else 100)
		if d != lock.D:
			print("RED: ping %d ms · retardo de entrada %d → %d turnos" % [peor, lock.D, d])
			lock.ajustar_retardo(d)
# --- fin instantaneas ---


## Antes de sim.step(): ¿se puede avanzar un tick?
func antes_del_paso() -> bool:
	if lock == null:
		return false
	if not _foto.is_empty(): # --- instantaneas ---
		volcar_foto()
		if lock == null or estado != "partida":
			return false
	var ok := lock.listo()
	_enviar_salida()
	if ok:
		_parado_desde = -1
	elif _parado_desde < 0:
		_parado_desde = Time.get_ticks_msec()
	return ok


func despues_del_paso() -> void:
	if lock != null:
		lock.despues()
		_enviar_salida()


## Pasos por cuadro: los de siempre o muchos más si hay que alcanzar (reconexión, tirón).
func pasos_por_cuadro(base: int) -> int:
	if lock != null and lock.atraso() > int(cfg.get("atraso_para_alcanzar_turnos", 6)):
		return int(cfg.get("pasos_por_cuadro_al_alcanzar", 120))
	return base


## La pausa del juego (Esc / Pausa) en red: pide una de las limitadas o la levanta.
func pausa_local(p: bool) -> void:
	if lock == null:
		return
	if p:
		if not lock.pedir_pausa():
			_decir("Sin pausas: quedan 0 de %d" % lock.pausas_max if int(lock.pausas_usadas[local]) >= lock.pausas_max else "")
	else:
		lock.reanudar()
		_enviar_salida()


func _enviar_salida() -> void:
	if lock == null:
		return
	for m in lock.salida:
		transporte.enviar(m)
	lock.salida.clear()


# ---------------------------------------------------------------- Red

func _process(_delta: float) -> void:
	for m: Dictionary in transporte.poll():
		_recibir(m)
	var ahora := Time.get_ticks_msec()
	_medir_ping(ahora) # --- instantaneas ---
	if estado == "conectando" and not transporte.conectado_ahora() and ahora >= _reintento:
		transporte.cerrar()
		estado = "nada"
		_decir("No se pudo conectar con %s:%d" % [_ip, _puerto])
	if estado == "partida" and _espera_desde >= 0:
		# --- caida anfitrion --- el invitado no da la partida por terminada: elige
		if not es_anfitrion() and not anfitrion_caido and lock != null and ahora - _espera_desde > int(cfg.get("caida_anfitrion_s", 20)) * 1000:
			anfitrion_caido = true
			_decir("El anfitrión no vuelve: seguí contra la IA o guardá y salí")
			anfitrion_caido_cambio.emit(true)
		if es_anfitrion() and ahora - _espera_desde > int(cfg.get("reconexion_s", 60)) * 1000:
			estado = "fin"
			_espera_desde = -1
			transporte.cerrar()
			_decir("El rival no volvió: partida terminada")
		elif not es_anfitrion() and not transporte.conectado_ahora() and ahora >= _reintento:
			_reintento = ahora + int(cfg.get("reintento_s", 2)) * 1000
			transporte.unirse(_ip, _puerto)
	_enviar_salida()
	_rotular()


func _al_conectar(_id: int) -> void:
	_rtts.clear() # --- instantaneas ---
	if not es_anfitrion():
		if estado == "conectando":
			estado = "sala"
		var yo: Dictionary = sala["jugadores"][local]
		transporte.enviar({"tipo": "hola", "civ": yo["civ"], "color": yo["color"], "listo": yo["listo"], "inyectado": lock.inyectado_hasta if lock != null else -1})
		if estado == "partida":
			_decir("Conexión recuperada")


func _al_desconectar(_id: int) -> void:
	if estado == "sala":
		if es_anfitrion():
			sala["jugadores"][1]["conectado"] = false
			sala["jugadores"][1]["listo"] = false
			sala_cambio.emit()
			_decir("El rival se fue de la sala")
		else:
			estado = "nada"
			transporte.cerrar()
			_decir("Se cortó la conexión con el anfitrión")
			sala_cambio.emit()
	elif estado == "partida":
		_espera_desde = Time.get_ticks_msec()
		_reintento = _espera_desde + int(cfg.get("reintento_s", 2)) * 1000
		_decir("Se cortó la conexión: esperando hasta %d s" % int(cfg.get("reconexion_s", 60)))


func _recibir(m: Dictionary) -> void:
	# --- instantaneas --- lo que no pasa la validación se descarta (y se cuenta)
	var por := RedValidar.motivo(m, local, cfg.get("validacion", {}))
	if por != "":
		rechazados += 1
		if rechazados <= 5:
			push_warning("RED: mensaje descartado: %s" % por)
		return
	match str(m.get("tipo", "")):
		"ping":
			transporte.enviar({"tipo": "pong", "t": m["t"]})
		"pong":
			_rtts.append(maxi(0, Time.get_ticks_msec() - int(m["t"])))
			if _rtts.size() > int(cfg.get("ping_muestras", 8)):
				_rtts.pop_front()
		"hola":
			if not es_anfitrion():
				return
			if estado == "sala":
				sala["jugadores"][1] = {"civ": m["civ"], "color": int(m["color"]), "listo": bool(m["listo"]), "conectado": true}
				_mandar_sala()
				sala_cambio.emit()
				_decir("Se unió un rival")
			elif estado == "partida":
				_espera_desde = -1
				var rean := -1
				if lock != null:
					rean = lock.pausa_turno - 1 if lock.pausa_de >= 0 else lock.inyectado_hasta
				# --- instantaneas --- si volvió de cero, la foto y lo de después; si no, lo que le falta
				var r := {"tipo": "retomar", "args": args, "log": [], "hashes": [], "reanudado": rean}
				if lock != null and sim != null:
					var tiene := int(m.get("inyectado", -1))
					if tiene < 0:
						r["foto"] = SimEstado.tomar(sim)
						r["inyectado"] = lock.inyectado_hasta
						r["pausas"] = lock.pausas_usadas.duplicate()
						tiene = lock.inyectado_hasta
					r["log"] = lock.registro(false, tiene + 1)
					r["hashes"] = lock.hashes_de(local, (tiene + 1) * lock.T)
				transporte.enviar(r)
				_decir("El rival volvió")
		"elijo":
			if es_anfitrion() and estado == "sala":
				sala["jugadores"][1] = {"civ": m["civ"], "color": int(m["color"]), "listo": bool(m["listo"]), "conectado": true}
				_mandar_sala()
				sala_cambio.emit()
		"sala":
			if not es_anfitrion() and estado == "partida" and lock != null: # --- caida anfitrion ---
				_mandar_foto() # el anfitrión volvió de cero: abrió una sala nueva
				return
			if not es_anfitrion():
				sala = m["sala"]
				sala_cambio.emit()
		"empezar":
			if not es_anfitrion():
				_arrancar(m["args"])
		"retomar":
			if es_anfitrion():
				if estado == "sala" and m.has("foto"): # --- caida anfitrion --- vuelvo de cero
					if retomar_aceptable(m): # --- retomar con identificador ---
						_retomar_de_invitado(m)
					else:
						rechazados += 1
						_decir("Un invitado quiso retomar otra partida: no se acepta")
				return
			_espera_desde = -1
			_reanudado = int(m.get("reanudado", -1))
			var todo: Array = (m.get("log", []) as Array) + (m.get("hashes", []) as Array)
			if lock != null: # se cortó un rato: se completa lo que falte y se devuelve lo propio
				lock.reanudado_hasta = maxi(lock.reanudado_hasta, _reanudado)
				lock.importar(todo)
				transporte.enviar({"tipo": "turnos", "log": lock.registro(true) + lock.hashes_de(local)})
			else: # volvió de cero: partida nueva y la foto (o re-simulación hasta el turno actual)
				_pendiente = todo
				_foto = m.get("foto", PackedByteArray()) # --- instantaneas ---
				_foto_info = {"inyectado": int(m.get("inyectado", -1)), "pausas": m.get("pausas", {})}
				_decir("Recuperando la partida…")
				_arrancar(m["args"])
		"turnos":
			if lock != null:
				lock.importar(m.get("log", []))
		"turno", "hash", "reanudar":
			if lock != null:
				lock.recibir(m)
			else:
				_pendiente.append(m)


# --- caida anfitrion ---
## Invitado: el anfitrión volvió sin la partida. Le manda la foto de su simulación (parada en
## el último turno completo, el mismo estado en las dos máquinas hasta ahí) y lo suyo de después.
func _mandar_foto() -> void:
	var iny := lock.inyectado_hasta
	var caido := -1 # --- retomar con identificador --- el anfitrión: el otro jugador
	for p: int in lock.jugadores:
		if p != local:
			caido = p
	transporte.enviar({"tipo": "retomar", "args": args, "log": lock.registro(false, iny + 1), "hashes": lock.hashes_de(local, (iny + 1) * lock.T),
		"reanudado": lock.reanudado_hasta, "foto": SimEstado.tomar(sim), "inyectado": iny, "pausas": lock.pausas_usadas.duplicate(),
		"partida": str(args.get("red_partida", "")), "caido": caido})
	foto_mandada_en = sim.tick
	_espera_desde = -1
	if anfitrion_caido:
		anfitrion_caido = false
		anfitrion_caido_cambio.emit(false)
	_decir("El anfitrión volvió: sigue desde mi foto (tick %d)" % sim.tick)


# --- retomar con identificador ---
## Anfitrión con la sala abierta: el «retomar» de un invitado vale solo si es de la última
## partida de este anfitrión (mismo identificador, también en sus args) y el jugador caído es
## el que este anfitrión era en ella.
func retomar_aceptable(m: Dictionary) -> bool:
	var id := str(retomable.get("partida", ""))
	if id == "" or str(m.get("partida", "")) != id:
		return false
	if str((m.get("args", {}) as Dictionary).get("red_partida", "")) != id:
		return false
	return int(m.get("caido", -1)) == int(retomable.get("jugador", -2))


static func leer_retomable() -> Dictionary:
	if not FileAccess.file_exists(RETOMABLE):
		return {}
	var d: Variant = JSON.parse_string(FileAccess.get_file_as_string(RETOMABLE))
	return d if d is Dictionary else {}


func _guardar_retomable(id: String, jugador: int) -> void:
	if id == "":
		return
	DirAccess.make_dir_recursive_absolute(RETOMABLE.get_base_dir())
	var f := FileAccess.open(RETOMABLE, FileAccess.WRITE)
	if f != null:
		f.store_string(JSON.stringify({"partida": id, "jugador": jugador}))
	retomable = {"partida": id, "jugador": jugador}
# --- fin retomar con identificador ---


## Anfitrión que volvió de cero: arma la partida con la foto del invitado (como el invitado
## que vuelve de cero con la del anfitrión, en adjuntar y volcar_foto).
func _retomar_de_invitado(m: Dictionary) -> void:
	sala["jugadores"][1]["conectado"] = true
	_reanudado = int(m.get("reanudado", -1))
	_pendiente = (m.get("log", []) as Array) + (m.get("hashes", []) as Array)
	_foto = m["foto"]
	_foto_info = {"inyectado": int(m.get("inyectado", -1)), "pausas": m.get("pausas", {})}
	_decir("El invitado tenía la partida: sigo desde su foto")
	_arrancar(m["args"])


## Invitado con el anfitrión caído: la IA toma al jugador caído desde donde quedó la partida
## (el último turno que los dos jugaron) y la partida sigue sin red. Lo propio que ya se había
## mandado y no llegó a jugarse entra en su turno; lo juntado, ahora.
func seguir_con_ia() -> void:
	if sim == null or lock == null:
		return
	var s := sim
	var ks := lock.turnos.keys()
	ks.sort()
	for n: int in ks:
		var msg: Dictionary = (lock.turnos[n] as Dictionary).get(local, {})
		if n <= lock.inyectado_hasta or msg.is_empty():
			continue
		for c: Dictionary in msg.get("c", []):
			var cc := c.duplicate(true)
			cc["player"] = local
			cc["tick"] = maxi(n * lock.T, s.tick)
			s.recording.append(cc.duplicate(true))
			s.schedule([cc])
	var juntado := lock.buffer.duplicate(true)
	var dif := str(cfg.get("ia_toma_dificultad", "normal"))
	for p: int in lock.jugadores:
		if p == local:
			continue
		var tiene := false
		for ai in s.ais:
			tiene = tiene or ai.player == p
		if not tiene:
			s.ais.append(SimAI.new(s, p, dif))
	anfitrion_caido = false
	cerrar() # suelta el lockstep: SimRed vuelve a dejar pasar los comandos
	for c: Dictionary in juntado:
		s.push_command(c)
	print("RED: la IA toma al jugador caído en el tick %d" % s.tick)


## Invitado con el anfitrión caído: guarda la partida en user://partidas/ (al cargarla, la
## IA toma al jugador caído) y, si `salir`, vuelve al menú. Devuelve la ruta ("" si falló).
func guardar_y_salir(ruta := "", salir := true) -> String:
	if sim == null or lock == null:
		return ""
	if ruta == "":
		ruta = Guardado.DIR_PARTIDAS + "red-%s.json" % Time.get_datetime_string_from_system().replace(":", "-")
	var suelta := _partida_suelta()
	if suelta == null:
		_decir("No se pudo guardar la partida")
		return ""
	var a := Guardado.args_limpios(args)
	a.erase("red")
	a["red_jugador"] = str(local)
	var ias: Array = []
	var cfg_ia := {}
	for ai in suelta.ais:
		ias.append(int(ai.player))
		cfg_ia[str(ai.player)] = {"dificultad": str(cfg.get("ia_toma_dificultad", "normal")), "estilo": str(ai.personality)}
	var meta := {"semilla": int(args.get("seed", 0)), "opciones": opts_de(args), "ias": ias, "ia_cfg": cfg_ia,
		"dificultad": str(cfg.get("ia_toma_dificultad", "normal")), "estilo": "normal", "colores": Palette.colores, "args": a}
	var ok := Guardado.escribir(ruta, Guardado.datos(meta, suelta))
	suelta.soltar()
	if not ok:
		_decir("No se pudo guardar la partida")
		return ""
	_decir("Partida guardada: %s" % ruta)
	if salir:
		cerrar()
		var m := get_tree().current_scene if is_inside_tree() else null
		if m != null and m.has_method("to_menu"):
			m.call_deferred("to_menu")
	return ruta


## La partida de esta máquina como una partida suelta (Sim, sin red) con una IA más por cada
## jugador caído: es lo que Guardado.armar sabe cargar (la foto tiene que tener las mismas IA
## que la partida que se arma al cargar). null si la copia no da el mismo hash.
func _partida_suelta() -> Sim:
	var sr := sim as SimRed
	var red_antes: Lockstep = sr.red if sr != null else null
	if sr != null:
		sr.red = null # la red no va en la foto
	var f := SimEstado.foto(sim)
	if sr != null:
		sr.red = red_antes
	for g: Array in f["guiones"]:
		if str(g[0]) == "res://src/net/sim_red.gd":
			g[0] = "res://src/sim/sim.gd"
	var t := Sim.new(int(args.get("seed", 0)), sim.players.size(), null, opts_de(args))
	t.ais = []
	for ai in sim.ais:
		t.ais.append(SimAI.new(t, int(ai.player)))
	if not SimEstado.restaurar(t, f) or t.state_hash() != sim.state_hash():
		push_error("RED: la copia de la partida no dio el mismo estado")
		t.soltar()
		return null
	for p: int in lock.jugadores:
		var tiene := false
		for ai in t.ais:
			tiene = tiene or int(ai.player) == p
		if p != local and not tiene:
			t.ais.append(SimAI.new(t, p, str(cfg.get("ia_toma_dificultad", "normal"))))
	return t
# --- fin caida anfitrion ---


func _decir(t: String) -> void:
	if t == "":
		return
	_texto = t
	print("RED: " + t)
	aviso.emit(t)


# ---------------------------------------------------------------- Rótulo

func _rotular() -> void:
	if DisplayServer.get_name() == "headless":
		return
	if _capa == null:
		_capa = CanvasLayer.new()
		_capa.layer = 50
		add_child(_capa)
		_rotulo = Label.new()
		_rotulo.add_theme_font_override("font", Hud.font_b)
		_rotulo.add_theme_font_size_override("font_size", 20)
		_rotulo.add_theme_color_override("font_color", Palette.UI_ACCENT)
		_rotulo.add_theme_color_override("font_outline_color", Color.BLACK)
		_rotulo.add_theme_constant_override("outline_size", 6)
		_rotulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_rotulo.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
		_rotulo.offset_top = 70
		_rotulo.grow_horizontal = Control.GROW_DIRECTION_BOTH
		_rotulo.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_capa.add_child(_rotulo)
	var t := ""
	if estado in ["partida", "fin"] and lock != null:
		var nombres := Palette.TEAM_NAMES
		if lock.desync_tick >= 0:
			t = "Desincronización en el tick %d" % lock.desync_tick
		elif estado == "fin":
			t = _texto
		elif anfitrion_caido: # --- caida anfitrion ---
			t = "El anfitrión no vuelve (se sigue esperando)"
		elif _espera_desde >= 0:
			t = "Se cortó la conexión: esperando %d s" % maxi(0, int(cfg.get("reconexion_s" if es_anfitrion() else "caida_anfitrion_s", 60)) - (Time.get_ticks_msec() - _espera_desde) / 1000)
		elif lock.pausa_de >= 0:
			var quien := nombres[Palette.color_idx(lock.pausa_de) % nombres.size()]
			t = "Pausa de %s: %d s · te quedan %d pausas (Esc para seguir)" % [quien, lock.pausa_restante_s(), lock.pausas_max - int(lock.pausas_usadas[local])]
		elif lock.atraso() > int(cfg.get("atraso_para_alcanzar_turnos", 6)):
			t = "Alcanzando la partida… (turno %d)" % lock.turno()
		elif _parado_desde >= 0 and Time.get_ticks_msec() - _parado_desde > 500:
			t = "Esperando al rival…"
	_rotulo.text = t
	_rotulo.visible = t != ""
	# --- caida anfitrion --- las dos salidas del invitado
	if anfitrion_caido and _botones == null:
		_botones = HBoxContainer.new()
		_botones.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
		_botones.offset_top = 110
		_botones.grow_horizontal = Control.GROW_DIRECTION_BOTH
		_botones.add_theme_constant_override("separation", 16)
		for par in [["Seguir contra la IA", seguir_con_ia], ["Guardar y salir", guardar_y_salir]]:
			var b := Button.new()
			b.text = par[0]
			b.pressed.connect(par[1] as Callable)
			_botones.add_child(b)
		_capa.add_child(_botones)
	if _botones != null:
		_botones.visible = anfitrion_caido


## Las opciones de Sim.new para estos argumentos, como las arma main._new_game (para las pruebas).
static func opts_de(a: Dictionary) -> Dictionary:
	var lug: Array = a.get("lugares", [])
	var o := {"terreno": str(a.get("terreno", "")), "civs": lug.map(func(sl: Dictionary) -> String: return sl["civ"]), "equipos": lug.map(func(sl: Dictionary) -> int: return int(sl["equipo"]))}
	o.merge(load("res://src/game/main.gd").match_opts(a))
	return o
