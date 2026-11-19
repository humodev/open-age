class_name SesionRed
extends Node
## Sesión de red 1v1 (proceso/37): la sala, el arranque, el lockstep durante la partida,
## la pausa limitada y la reconexión. Vive bajo /root, así sobrevive a los reinicios de main.
##
## Mensajes (diccionarios con "tipo"):
##   hola {civ, color, listo}      cliente → anfitrión, al conectarse (también al volver)
##   elijo {civ, color, listo}     cliente → anfitrión, al cambiar algo en la sala
##   sala {sala}                   anfitrión → cliente, el estado de la sala
##   empezar {args}                anfitrión → cliente, la partida (args de main.gd)
##   retomar {args, log, hashes, reanudado}  anfitrión → cliente que vuelve en plena partida
##   turnos {log}                  cliente → anfitrión al volver: lo propio, por si se perdió algo
##   turno, hash, reanudar         del lockstep (lockstep.gd)

signal sala_cambio
signal empezar(args: Dictionary)
signal aviso(texto: String)

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


func _init() -> void:
	cfg = JSON.parse_string(FileAccess.get_file_as_string("res://data/red.json"))
	transporte.timeout_min_ms = int(cfg.get("timeout_min_ms", 3000))
	transporte.timeout_max_ms = int(cfg.get("timeout_max_ms", 8000))
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
		_reintento = Time.get_ticks_msec() + 5000
		_decir("Conectando con %s:%d…" % [ip, puerto])
	return err


func cerrar() -> void:
	transporte.cerrar()
	if sim is SimRed:
		(sim as SimRed).red = null
	lock = null
	sim = null
	estado = "nada"
	if activa == self:
		activa = null
	queue_free()


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
	if not es_anfitrion() or puede_empezar() != "":
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
	transporte.enviar({"tipo": "empezar", "args": a})
	_arrancar(a)


func _mandar_sala() -> void:
	transporte.enviar({"tipo": "sala", "sala": sala})


func _arrancar(a: Dictionary) -> void:
	args = a
	estado = "partida"
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
	lock.importar(_pendiente)
	_pendiente = []


## Antes de sim.step(): ¿se puede avanzar un tick?
func antes_del_paso() -> bool:
	if lock == null:
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
	if estado == "conectando" and not transporte.conectado_ahora() and ahora >= _reintento:
		transporte.cerrar()
		estado = "nada"
		_decir("No se pudo conectar con %s:%d" % [_ip, _puerto])
	if estado == "partida" and _espera_desde >= 0:
		if ahora - _espera_desde > int(cfg.get("reconexion_s", 60)) * 1000:
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
	if not es_anfitrion():
		if estado == "conectando":
			estado = "sala"
		var yo: Dictionary = sala["jugadores"][local]
		transporte.enviar({"tipo": "hola", "civ": yo["civ"], "color": yo["color"], "listo": yo["listo"]})
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
	match str(m.get("tipo", "")):
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
				transporte.enviar({"tipo": "retomar", "args": args, "log": lock.registro() if lock != null else [], "hashes": lock.hashes_de(local) if lock != null else [], "reanudado": rean})
				_decir("El rival volvió")
		"elijo":
			if es_anfitrion() and estado == "sala":
				sala["jugadores"][1] = {"civ": m["civ"], "color": int(m["color"]), "listo": bool(m["listo"]), "conectado": true}
				_mandar_sala()
				sala_cambio.emit()
		"sala":
			if not es_anfitrion():
				sala = m["sala"]
				sala_cambio.emit()
		"empezar":
			if not es_anfitrion():
				_arrancar(m["args"])
		"retomar":
			if es_anfitrion():
				return
			_espera_desde = -1
			_reanudado = int(m.get("reanudado", -1))
			var todo: Array = (m.get("log", []) as Array) + (m.get("hashes", []) as Array)
			if lock != null: # se cortó un rato: se completa lo que falte y se devuelve lo propio
				lock.reanudado_hasta = maxi(lock.reanudado_hasta, _reanudado)
				lock.importar(todo)
				transporte.enviar({"tipo": "turnos", "log": lock.registro(true) + lock.hashes_de(local)})
			else: # volvió de cero: partida nueva y re-simulación hasta el turno actual
				_pendiente = todo
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
		elif _espera_desde >= 0:
			t = "Se cortó la conexión: esperando %d s" % maxi(0, int(cfg.get("reconexion_s", 60)) - (Time.get_ticks_msec() - _espera_desde) / 1000)
		elif lock.pausa_de >= 0:
			var quien := nombres[Palette.color_idx(lock.pausa_de) % nombres.size()]
			t = "Pausa de %s: %d s · te quedan %d pausas (Esc para seguir)" % [quien, lock.pausa_restante_s(), lock.pausas_max - int(lock.pausas_usadas[local])]
		elif lock.atraso() > int(cfg.get("atraso_para_alcanzar_turnos", 6)):
			t = "Alcanzando la partida… (turno %d)" % lock.turno()
		elif _parado_desde >= 0 and Time.get_ticks_msec() - _parado_desde > 500:
			t = "Esperando al rival…"
	_rotulo.text = t
	_rotulo.visible = t != ""


## Las opciones de Sim.new para estos argumentos, como las arma main._new_game (para las pruebas).
static func opts_de(a: Dictionary) -> Dictionary:
	var lug: Array = a.get("lugares", [])
	var o := {"terreno": str(a.get("terreno", "")), "civs": lug.map(func(sl: Dictionary) -> String: return sl["civ"]), "equipos": lug.map(func(sl: Dictionary) -> int: return int(sl["equipo"]))}
	o.merge(load("res://src/game/main.gd").match_opts(a))
	return o
