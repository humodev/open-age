extends SceneTree
## Multijugador en red (proceso/37): dos instancias sin ventana en 127.0.0.1, en lockstep.
## Esta hace de anfitrión y lanza la otra (--rol=cliente). Las dos corren la IA de los dos
## jugadores dentro de su simulación, pero SimRed solo deja pasar los comandos propios por la
## red: los del rival se descartan y llegan por la red. Al final se comparan los hashes.
##
## Casos:
##   directo     3 minutos de juego (1800 ticks) sin demora; el anfitrión pausa en el tick 300 y sigue a 1,5 s
##   latencia    1 minuto con 80 ms de demora por mensaje más hasta 40 de vaivén
##   reconexion  1,5 minutos; el cliente se cae en el tick 300, vuelve de cero y sigue desde la
##               foto del anfitrión (proceso/37-red/02), sin re-simular
##   desincronizacion  el cliente se suma madera en el tick 120: los dos ven la desincronización en el 150
##   ping        1 minuto con 250 ms de demora más hasta 50 de vaivén: el retardo de entrada sube solo
##   basura      el cliente manda mensajes rotos en el tick 100 (paquete que no es un diccionario,
##               turno a nombre del anfitrión, tipos cambiados, demasiados comandos): el anfitrión los
##               descarta y la partida sigue igual
##   anfitrion_vuelve     el anfitrión se cae en el tick 300 (pierde todo) y abre una sala nueva:
##               el invitado le manda su foto y siguen desde ahí (proceso/37-red/03)
##   anfitrion_no_vuelve  el anfitrión se cae en el tick 300 y no vuelve: a los 3 s el invitado
##               guarda (el guardado se carga con el mismo hash) y sigue contra la IA, que
##               toma al anfitrión y entrena aldeanos
##
##   godot --headless --path . -s tests/red.gd [-- --caso=directo]

const PUERTO := 47911
const CASOS := [
	{"nombre": "directo", "ticks": 1800, "lat": 0, "vaiven": 0, "caida": 0, "pausa": 300},
	{"nombre": "latencia", "ticks": 600, "lat": 80, "vaiven": 40, "caida": 0},
	{"nombre": "reconexion", "ticks": 900, "lat": 0, "vaiven": 0, "caida": 300},
	{"nombre": "desincronizacion", "ticks": 300, "lat": 0, "vaiven": 0, "caida": -120}, # trampa: el cliente toca su estado en el tick 120
	{"nombre": "ping", "ticks": 600, "lat": 250, "vaiven": 50, "caida": 0, "retardo_min": 4},
	{"nombre": "basura", "ticks": 600, "lat": 0, "vaiven": 0, "caida": 0, "basura": 100},
	{"nombre": "anfitrion_vuelve", "ticks": 900, "lat": 0, "vaiven": 0, "caida": 0, "anfitrion": 300, "vuelve": true},
	{"nombre": "anfitrion_no_vuelve", "ticks": 900, "lat": 0, "vaiven": 0, "caida": 0, "anfitrion": 300},
]
const PASOS_POR_CUADRO := 200
const ESPERA_MS := 240000

var _a := {}
var s: SesionRed = null
var sim: SimRed = null


func _init() -> void:
	for x in OS.get_cmdline_user_args():
		var kv := x.trim_prefix("--").split("=", true, 1)
		_a[kv[0]] = kv[1] if kv.size() > 1 else "1"
	_correr.call_deferred()


func _correr() -> void:
	if _a.get("rol", "") == "cliente":
		var ok := await _cliente(int(_a["puerto"]), int(_a["ticks"]), int(_a["lat"]), int(_a["vaiven"]), int(_a["caida"]), int(_a.get("basura", "0")))
		quit(0 if ok else 1)
		return
	var todo_ok := true
	for i in CASOS.size():
		var c: Dictionary = CASOS[i]
		if _a.has("caso") and _a["caso"] != c["nombre"]:
			continue
		var t0 := Time.get_ticks_msec()
		var r := await _anfitrion(PUERTO + i, c)
		print("CASO %s: %s · %d ticks · %.1f s" % [c["nombre"], "OK" if r else "FALLO", int(c["ticks"]), (Time.get_ticks_msec() - t0) / 1000.0])
		todo_ok = todo_ok and r
	print("RED: %s" % ("OK" if todo_ok else "FALLO"))
	quit(0 if todo_ok else 1)


func _arrancar(args: Dictionary) -> void:
	var opts := SesionRed.opts_de(args)
	sim = SimRed.new(int(args["seed"]), (args["lugares"] as Array).size(), null, opts)
	sim.ais = [SimAI.new(sim, 0), SimAI.new(sim, 1)]


## Avanza todo lo que deja el lockstep (hasta `tope`).
func _avanzar(tope: int) -> void:
	if sim == null:
		return
	var n := 0
	while n < PASOS_POR_CUADRO and sim.tick < tope and s.antes_del_paso():
		sim.step()
		s.despues_del_paso()
		n += 1


func _anfitrion(puerto: int, c: Dictionary) -> bool:
	s = SesionRed.nueva(self)
	s.transporte.latencia_ms = int(c["lat"])
	s.transporte.vaiven_ms = int(c["vaiven"])
	if s.crear(puerto) != OK:
		push_error("no se pudo abrir el puerto %d" % puerto)
		return false
	s.elegir("guaranies", 0, true)
	s.opciones({"terreno": "llano", "semilla": 4321})
	s.empezar.connect(_arrancar)
	var exe := OS.get_executable_path()
	var pid := OS.create_process(exe, ["--headless", "--path", ProjectSettings.globalize_path("res://"), "-s", "res://tests/red.gd", "--",
		"--rol=cliente", "--puerto=%d" % puerto, "--ticks=%d" % int(c["ticks"]), "--lat=%d" % int(c["lat"]), "--vaiven=%d" % int(c["vaiven"]), "--caida=%d" % int(c["caida"]), "--basura=%d" % int(c.get("basura", 0)),
		"--anfitrion=%s" % ("" if not c.has("anfitrion") else ("vuelve" if c.get("vuelve", false) else "no_vuelve"))])
	var t0 := Time.get_ticks_msec()
	while s.puede_empezar() != "":
		await process_frame
		if Time.get_ticks_msec() - t0 > 30000:
			push_error("el cliente no llegó a la sala")
			OS.kill(pid)
			return false
	s.empezar_partida()
	var fin := int(c["ticks"])
	var ok := false
	var pausa := int(c.get("pausa", 0))
	var pausa_t := -1
	var cae := int(c.get("anfitrion", 0)) # --- caida anfitrion ---
	var espera_cliente := 15000
	while Time.get_ticks_msec() - t0 < ESPERA_MS:
		await process_frame
		_avanzar(cae if cae > 0 else fin)
		if cae > 0 and sim != null and sim.tick >= cae:
			# Se cae el anfitrión: pierde la sesión y la partida.
			print("anfitrión: me caigo en el tick %d" % sim.tick)
			cae = 0
			s.cerrar()
			sim.soltar()
			sim = null
			if not c.get("vuelve", false):
				ok = true # lo comprueba el invitado (sale con 0 si guardó y la IA siguió)
				espera_cliente = 90000
				break
			var t2 := Time.get_ticks_msec()
			while Time.get_ticks_msec() - t2 < 1500:
				await process_frame
			s = SesionRed.nueva(self)
			s.crear(puerto)
			s.empezar.connect(_arrancar)
			continue
		if pausa > 0 and sim != null and sim.tick >= pausa and pausa_t < 0:
			pausa_t = Time.get_ticks_msec()
			s.pausa_local(true)
		if pausa_t > 0 and Time.get_ticks_msec() - pausa_t > 1500:
			print("anfitrión: pausa en el tick %d (de %d), sigo" % [sim.tick, s.lock.pausa_de])
			ok = s.lock.pausa_de == 0 # la pausa tiene que estar en curso
			pausa_t = 0
			s.pausa_local(false)
		if sim != null and s.lock != null:
			if s.lock.desync_tick >= 0:
				break
			var hs: Dictionary = s.lock.hashes
			if hs[0].has(fin) and hs[1].has(fin):
				ok = hs[0][fin] == hs[1][fin] and (pausa == 0 or (ok and int(s.lock.pausas_usadas[0]) == 1))
				var por := [0, 0]
				for cm: Dictionary in sim.recording:
					por[int(cm["player"])] += 1
				print("anfitrión: tick %d hash %d · cliente %d · comandos por la red %s · edades %d/%d" % [fin, hs[0][fin], hs[1][fin], por, int(sim.players[0]["age"]), int(sim.players[1]["age"])])
				ok = ok and por[0] > 0 and por[1] > 0
				# --- instantaneas --- retardo adaptable y validación
				print("anfitrión: retardo de entrada %d turnos (ping %d ms) · descartados %d mensajes y %d paquetes" % [s.lock.D, s.ping_ms, s.rechazados, s.transporte.rechazados])
				if c.has("retardo_min"):
					ok = ok and s.lock.D >= int(c["retardo_min"])
				if c.has("basura"):
					ok = ok and s.rechazados >= 4 and s.transporte.rechazados >= 1
				if c.has("anfitrion"): # --- caida anfitrion --- siguió desde la foto del invitado
					print("anfitrión: volví de cero y seguí desde la foto del invitado en el tick %d" % s.recuperada_en)
					ok = ok and s.recuperada_en >= int(c["anfitrion"])
				break
	if sim != null and s.lock != null and s.lock.desync_tick >= 0:
		print("anfitrión: desincronización en el tick %d" % s.lock.desync_tick)
		ok = int(c["caida"]) < 0 and s.lock.desync_tick == _primer_hash(-int(c["caida"]))
	# El cliente termina solo; se le da un rato y si no, se lo corta.
	var t1 := Time.get_ticks_msec()
	while OS.is_process_running(pid) and Time.get_ticks_msec() - t1 < espera_cliente:
		await process_frame
	if OS.is_process_running(pid):
		OS.kill(pid)
		ok = false
	elif OS.get_process_exit_code(pid) != 0:
		print("anfitrión: el cliente salió con %d" % OS.get_process_exit_code(pid))
		ok = false
	if s != null:
		s.cerrar()
	s = null
	if sim != null:
		sim.soltar()
	sim = null
	return ok


func _cliente(puerto: int, fin: int, lat: int, vaiven: int, caida: int, basura := 0) -> bool:
	await _conectar(puerto, lat, vaiven, "mapuches")
	var anf := str(_a.get("anfitrion", "")) # --- caida anfitrion ---
	if anf == "no_vuelve":
		s.cfg["caida_anfitrion_s"] = 3
	var t0 := Time.get_ticks_msec()
	var cayo := false
	while Time.get_ticks_msec() - t0 < ESPERA_MS:
		await process_frame
		if anf == "no_vuelve" and s != null and s.anfitrion_caido:
			return await _sin_anfitrion(fin)
		_avanzar(caida if caida > 0 and not cayo else fin)
		if sim == null or s.lock == null:
			continue
		if basura > 0 and sim.tick >= basura:
			basura = 0
			_basura()
		if caida < 0 and not cayo and sim.tick >= -caida:
			cayo = true # trampa: un cambio de estado que el anfitrión no tiene
			sim.players[1]["res"]["madera"] = int(sim.players[1]["res"]["madera"]) + 7
		if caida > 0 and not cayo and sim.tick >= caida:
			# Se cae: se pierde todo (sesión y partida) y vuelve de cero por la sala.
			cayo = true
			print("cliente: me caigo en el tick %d" % sim.tick)
			s.cerrar()
			sim.soltar()
			sim = null
			var t2 := Time.get_ticks_msec()
			while Time.get_ticks_msec() - t2 < 1500:
				await process_frame
			await _conectar(puerto, lat, vaiven, "mapuches")
			continue
		if s.lock.desync_tick >= 0:
			print("cliente: desincronización en el tick %d" % s.lock.desync_tick)
			var t4 := Time.get_ticks_msec()
			while Time.get_ticks_msec() - t4 < 500: # que salga el hash para el anfitrión
				await process_frame
			return caida < 0 and s.lock.desync_tick == _primer_hash(-caida)
		var hs: Dictionary = s.lock.hashes
		if hs[0].has(fin) and hs[1].has(fin):
			print("cliente: tick %d hash %d · anfitrión %d · retardo %d turnos · recuperada por foto en el tick %d" % [fin, hs[1][fin], hs[0][fin], s.lock.D, s.recuperada_en])
			# Se queda un momento para que salga lo último (con demora simulada).
			var t3 := Time.get_ticks_msec()
			while Time.get_ticks_msec() - t3 < 500 + lat + vaiven:
				await process_frame
			if anf == "vuelve":
				print("cliente: le mandé la foto al anfitrión en el tick %d" % s.foto_mandada_en)
			return hs[0][fin] == hs[1][fin] and (caida <= 0 or s.recuperada_en >= caida) and (anf != "vuelve" or s.foto_mandada_en > 0)
	print("cliente: no llegó al tick %d" % fin)
	return false


# --- caida anfitrion ---
## El anfitrión no volvió: guarda (y comprueba que el guardado se carga igual), sigue contra
## la IA hasta `fin` y comprueba que la IA maneja al anfitrión (entrena).
func _sin_anfitrion(fin: int) -> bool:
	var ruta := "user://red_prueba_caida.json"
	var r := s.guardar_y_salir(ruta, false)
	var d := Guardado.leer(r) if r != "" else {}
	var ok_g := false
	if not d.is_empty():
		var s2 := Guardado.armar(d, int(d["tick"]))
		# (acá el invitado ya corría las dos IA: en el juego, solo la del caído)
		ok_g = s2.tick == sim.tick and s2.state_hash() == sim.state_hash() and s2.ais.any(func(ai: SimAI) -> bool: return ai.player == 0)
		print("cliente: cargado tick %d/%d hash %d/%d ias %s" % [s2.tick, sim.tick, s2.state_hash(), sim.state_hash(), d["ias"]])
		s2.soltar()
		Guardado.borrar(r)
	print("cliente: anfitrión caído en el tick %d · guardado %s · se carga igual %s" % [sim.tick, r, ok_g])
	var antes := int(sim.players[0]["stats"]["entrenadas"])
	var t_toma := sim.tick
	s.seguir_con_ia()
	s = null
	while sim.tick < fin:
		for i in PASOS_POR_CUADRO:
			if sim.tick >= fin:
				break
			sim.step()
		await process_frame
	var despues := int(sim.players[0]["stats"]["entrenadas"])
	print("cliente: la IA tomó al anfitrión en el tick %d · entrenó %d unidades hasta el tick %d" % [t_toma, despues - antes, sim.tick])
	return ok_g and despues > antes and SesionRed.activa == null


## Mensajes rotos al anfitrión (caso basura): ninguno tiene que entrar ni romper nada.
func _basura() -> void:
	print("cliente: mando basura en el tick %d" % sim.tick)
	s.transporte.peer.put_packet(PackedByteArray([1, 2, 3, 4, 5, 6, 7, 8])) # no es un diccionario
	s.transporte.peer.put_packet(var_to_bytes([1, 2, 3])) # tampoco
	var n := s.lock.turno() + 50
	s.transporte.enviar({"tipo": "turno", "j": 0, "n": n, "c": []}) # a nombre del anfitrión
	s.transporte.enviar({"tipo": "turno", "j": 1, "n": "x", "c": []}) # tipo cambiado
	s.transporte.enviar({"tipo": "turno", "j": 1, "n": n, "c": [{"t": "move", "player": 1, "ids": [1], "x": "lejos", "y": 3}]})
	var muchos: Array = []
	for i in 500:
		muchos.append({"t": "stop", "player": 1, "ids": [i]})
	s.transporte.enviar({"tipo": "turno", "j": 1, "n": n, "c": muchos})
	s.transporte.enviar({"tipo": "hash", "j": 1, "t": 50, "h": 1.5}) # hash que no es entero
	s.transporte.enviar({"tipo": "lo_que_sea"})


## Primer tick con hash después de `t` (cada hash_cada_ticks de data/red.json).
func _primer_hash(t: int) -> int:
	var m := int(s.cfg.get("hash_cada_ticks", 50))
	return (t / m + 1) * m


func _conectar(puerto: int, lat: int, vaiven: int, civ: String) -> void:
	s = SesionRed.nueva(self)
	s.transporte.latencia_ms = lat
	s.transporte.vaiven_ms = vaiven
	s.sala["jugadores"][1] = {"civ": civ, "color": 1, "listo": true, "conectado": true}
	s.empezar.connect(_arrancar)
	s.unirse("127.0.0.1", puerto)
	await process_frame


## Al salir se sueltan las partidas creadas (ciclos de referencias; proceso/24, paso 6e).
func _finalize() -> void:
	Sim.soltar_todas()
