extends SceneTree
## --- relevo --- (proceso/37-red/04) Dos clientes juegan por el relevo (server/relevo.py) en 127.0.0.1.
## Esta instancia levanta el relevo, crea la sala, recibe el código y lanza al cliente
## (--rol=cliente --codigo=XXXXXX). Las dos corren la IA de los dos jugadores, y SimRed deja pasar
## por la red solo lo propio, como en tests/red.gd. Al final se comparan los hashes.
##
## Además:
##   - el cliente se cae en el tick 400, vuelve de cero con el código y sigue desde la foto;
##   - un cliente con otra versión (otro data/) no entra a la sala;
##   - un mensaje más grande que el tope corta la conexión;
##   - un código que no existe se rechaza.
##
##   godot --headless --path . -s tests/red_relevo.gd [-- --ticks=1200 --python=python3]

const PUERTO := 47990
const PASOS_POR_CUADRO := 200
const ESPERA_MS := 240000
const CAIDA := 400

var _a := {}
var s: SesionRed = null
var sim: SimRed = null


func _init() -> void:
	for x in OS.get_cmdline_user_args():
		var kv := x.trim_prefix("--").split("=", true, 1)
		_a[kv[0]] = kv[1] if kv.size() > 1 else "1"
	_correr.call_deferred()


func _correr() -> void:
	var fin := int(_a.get("ticks", "1200")) # 2 minutos de juego
	if _a.get("rol", "") == "cliente":
		quit(0 if await _cliente(str(_a["codigo"]), fin) else 1)
		return
	var py := str(_a.get("python", "python3"))
	var relevo := OS.create_process(py, [ProjectSettings.globalize_path("res://server/relevo.py"), "--ip", "127.0.0.1", "--puerto", str(PUERTO), "--max-bytes", "4194304"])
	var ok := relevo > 0
	if ok:
		await _esperar(800) # que abra el puerto
		ok = await _rechazos()
		var t0 := Time.get_ticks_msec()
		ok = await _anfitrion(fin) and ok
		print("RELEVO: partida de %d ticks en %.1f s" % [fin, (Time.get_ticks_msec() - t0) / 1000.0])
		OS.kill(relevo)
	print("RED RELEVO: %s" % ("OK" if ok else "FALLO"))
	quit(0 if ok else 1)


func _esperar(ms: int) -> void:
	var t := Time.get_ticks_msec()
	while Time.get_ticks_msec() - t < ms:
		await process_frame


func _arrancar(args: Dictionary) -> void:
	var opts := SesionRed.opts_de(args)
	sim = SimRed.new(int(args["seed"]), (args["lugares"] as Array).size(), null, opts)
	sim.ais = [SimAI.new(sim, 0), SimAI.new(sim, 1)]


func _avanzar(tope: int) -> void:
	if sim == null:
		return
	var n := 0
	while n < PASOS_POR_CUADRO and sim.tick < tope and s.antes_del_paso():
		sim.step()
		s.despues_del_paso()
		n += 1


## Lo que el relevo no deja pasar: otra versión, un código que no existe y un mensaje gigante.
func _rechazos() -> bool:
	var a := RedRelevo.new()
	a.puerto = PUERTO
	a.crear(0)
	var t := Time.get_ticks_msec()
	while a.codigo == "" and Time.get_ticks_msec() - t < 5000:
		a.poll()
		await process_frame
	var buena := RedRelevo.version()
	RedRelevo._version = "otra-version"
	var b := RedRelevo.new()
	b.puerto = PUERTO
	b.codigo = a.codigo
	b.unirse("", 0)
	var c := RedRelevo.new()
	c.puerto = PUERTO
	c.codigo = "ZZZZZZ"
	c.unirse("", 0)
	t = Time.get_ticks_msec()
	while (b.error_relevo == "" or c.error_relevo == "") and Time.get_ticks_msec() - t < 5000:
		a.poll()
		b.poll()
		c.poll()
		await process_frame
	# La misma otra versión por la sesión: el aviso que ve el jugador en la sala (proceso/44).
	var avisos: Array = []
	var sd := SesionRed.nueva(self)
	sd.aviso.connect(func(x: String) -> void: avisos.append(x))
	sd.usar_relevo("127.0.0.1", PUERTO, a.codigo)
	sd.unirse("", 0)
	t = Time.get_ticks_msec()
	while not avisos.any(func(x: String) -> bool: return x.begins_with("Tu amigo tiene otra versión")) and Time.get_ticks_msec() - t < 5000:
		a.poll()
		await process_frame
	var aviso_version: String = avisos.back() if not avisos.is_empty() else ""
	sd.cerrar()
	RedRelevo._version = buena
	# Un marco de 64 MB (más que --max-bytes): el relevo corta sin leerlo.
	var g := StreamPeerTCP.new()
	g.connect_to_host("127.0.0.1", PUERTO)
	var cortado := false
	var mandado := false
	t = Time.get_ticks_msec()
	while Time.get_ticks_msec() - t < 5000:
		g.poll()
		var st := g.get_status()
		if st == StreamPeerTCP.STATUS_CONNECTED and not mandado:
			mandado = true
			g.put_data(PackedByteArray([4, 0, 0, 0, 1]))
		elif mandado and (st == StreamPeerTCP.STATUS_NONE or st == StreamPeerTCP.STATUS_ERROR):
			cortado = true
			break
		elif mandado and st == StreamPeerTCP.STATUS_CONNECTED:
			g.put_partial_data(PackedByteArray([0])) # escribir en un socket cerrado lo delata
		await process_frame
	print("relevo: aviso en la sala: «%s»" % aviso_version)
	print("relevo: sala %s · otra versión: «%s» · código falso: «%s» · mensaje gigante cortado: %s · otra versión no se cuela: %s" % [a.codigo, b.error_relevo, c.error_relevo, cortado, not a.conectado_ahora()])
	var ok := a.codigo.length() == 6 and b.error_relevo.contains("versión") and aviso_version.begins_with("Tu amigo tiene otra versión") and c.error_relevo != "" and cortado and not a.conectado_ahora()
	a.cerrar()
	b.cerrar()
	c.cerrar()
	g.disconnect_from_host()
	return ok


func _anfitrion(fin: int) -> bool:
	s = SesionRed.nueva(self)
	s.usar_relevo("127.0.0.1", PUERTO)
	if s.crear(0) != OK:
		push_error("no se pudo conectar con el relevo")
		return false
	s.elegir("guaranies", 0, true)
	s.opciones({"terreno": "llano", "semilla": 4321})
	s.empezar.connect(_arrancar)
	var t0 := Time.get_ticks_msec()
	while s.codigo_relevo() == "":
		await process_frame
		if Time.get_ticks_msec() - t0 > 10000:
			push_error("el relevo no dio código")
			return false
	print("anfitrión: sala %s en el relevo" % s.codigo_relevo())
	var pid := OS.create_process(OS.get_executable_path(), ["--headless", "--path", ProjectSettings.globalize_path("res://"), "-s", "res://tests/red_relevo.gd", "--",
		"--rol=cliente", "--codigo=%s" % s.codigo_relevo(), "--ticks=%d" % fin])
	while s.puede_empezar() != "":
		await process_frame
		if Time.get_ticks_msec() - t0 > 30000:
			push_error("el cliente no llegó a la sala")
			OS.kill(pid)
			return false
	s.empezar_partida()
	var ok := false
	while Time.get_ticks_msec() - t0 < ESPERA_MS:
		await process_frame
		_avanzar(fin)
		if sim == null or s.lock == null:
			continue
		if s.lock.desync_tick >= 0:
			print("anfitrión: desincronización en el tick %d" % s.lock.desync_tick)
			break
		var hs: Dictionary = s.lock.hashes
		if hs[0].has(fin) and hs[1].has(fin):
			var por := [0, 0]
			for cm: Dictionary in sim.recording:
				por[int(cm["player"])] += 1
			print("anfitrión: tick %d hash %d · cliente %d · comandos por el relevo %s · retardo %d turnos (ping %d ms)" % [fin, hs[0][fin], hs[1][fin], por, s.lock.D, s.ping_ms])
			ok = hs[0][fin] == hs[1][fin] and por[0] > 0 and por[1] > 0
			break
	var t1 := Time.get_ticks_msec()
	while OS.is_process_running(pid) and Time.get_ticks_msec() - t1 < 15000:
		await process_frame
	if OS.is_process_running(pid):
		OS.kill(pid)
		ok = false
	elif OS.get_process_exit_code(pid) != 0:
		print("anfitrión: el cliente salió con %d" % OS.get_process_exit_code(pid))
		ok = false
	s.cerrar()
	s = null
	if sim != null:
		sim.soltar()
	sim = null
	return ok


func _cliente(codigo: String, fin: int) -> bool:
	_conectar(codigo)
	var cayo := false
	var t0 := Time.get_ticks_msec()
	while Time.get_ticks_msec() - t0 < ESPERA_MS:
		await process_frame
		_avanzar(CAIDA if not cayo else fin)
		if sim == null or s.lock == null:
			continue
		if not cayo and sim.tick >= CAIDA:
			# Se cae: pierde todo y vuelve de cero con el código de la sala.
			cayo = true
			print("cliente: me caigo en el tick %d" % sim.tick)
			s.cerrar()
			sim.soltar()
			sim = null
			await _esperar(1500)
			_conectar(codigo)
			continue
		if s.lock.desync_tick >= 0:
			print("cliente: desincronización en el tick %d" % s.lock.desync_tick)
			return false
		var hs: Dictionary = s.lock.hashes
		if hs[0].has(fin) and hs[1].has(fin):
			print("cliente: tick %d hash %d · anfitrión %d · recuperada por foto en el tick %d" % [fin, hs[1][fin], hs[0][fin], s.recuperada_en])
			await _esperar(500)
			return hs[0][fin] == hs[1][fin] and s.recuperada_en >= CAIDA
	print("cliente: no llegó al tick %d" % fin)
	return false


func _conectar(codigo: String) -> void:
	s = SesionRed.nueva(self)
	s.usar_relevo("127.0.0.1", PUERTO, codigo)
	s.sala["jugadores"][1] = {"civ": "mapuches", "color": 1, "listo": true, "conectado": true}
	s.empezar.connect(_arrancar)
	s.unirse("", 0)


func _finalize() -> void:
	Sim.soltar_todas()
