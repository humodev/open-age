extends SceneTree
## Guardar y cargar (proceso/30-fluidez/07): una partida guardada en el tick T, pasada por
## JSON, armada de nuevo y re-simulada hasta T tiene el mismo hash que la original; y si las
## dos siguen con los mismos comandos, siguen iguales. Con escaramuza (2 y 4 jugadores) y con
## una misión de campaña. Mide además cuánto tarda la carga.

var _fallas := 0


func _init() -> void:
	# 1. Escaramuza 1 contra 1: el jugador da órdenes, la IA juega.
	var opts := {"civs": ["guaranies", "etiopia"], "terreno": "llano", "equipos": [0, 1]}
	var meta := {"semilla": 4321, "opciones": opts, "ias": [1], "ia_cfg": {"1": {"dificultad": "normal", "estilo": "normal"}}}
	var a := Guardado.armar(meta.merged({"comandos": []}))
	_ordenes(a, 1800)
	_comparar("1v1 en el minuto 3", a, 1800, meta, 3600)

	# 2. Cuatro jugadores, tres IA y opciones de partida.
	var opts4 := {"civs": ["mapuches", "etiopia", "palmares", "ayutthaya"], "terreno": "llano", "equipos": [0, 1, 0, 1], "recursos": "altos"}
	var ia4 := {}
	for p in [1, 2, 3]:
		ia4[str(p)] = {"dificultad": "dificil", "estilo": "normal"}
	var meta4 := {"semilla": 77, "opciones": opts4, "ias": [1, 2, 3], "ia_cfg": ia4}
	var b := Guardado.armar(meta4.merged({"comandos": []}))
	_ordenes(b, 3000)
	_comparar("2v2 en el minuto 5", b, 3000, meta4, 4800)

	# 3. Una misión de campaña (el motor de escenarios también es determinista).
	var metac := {"campana": "etiopia", "mision": 0}
	var c := Guardado.armar(metac.merged({"comandos": []}))
	_ordenes(c, 1200)
	_comparar("campaña etiopía 1 en el minuto 2", c, 1200, metac, 2400)

	print("GUARDADO: %s" % ("OK" if _fallas == 0 else "FALLO (%d)" % _fallas))
	quit(0 if _fallas == 0 else 1)


## Algunas órdenes del jugador 0 hasta el tick `hasta` (recolectar, construir, entrenar).
func _ordenes(s: Sim, hasta: int) -> void:
	var vill := []
	for e in s.actives:
		if e.owner == 0 and e.fn == "civil":
			vill.append(e.id)
	var b0 := s.bases[0]
	while s.tick < hasta:
		var i := s.tick
		if i == 5 and vill.size() >= 4:
			var bush := s.find_resource(0, "alimento", b0.x * 1000, b0.y * 1000, 30000)
			if bush != null:
				s.push_command({"t": "target", "player": 0, "ids": vill.slice(0, 4), "target": bush.id})
		if i == 30 and vill.size() >= 6:
			s.push_command({"t": "build", "player": 0, "ids": vill.slice(4, 6), "type": s.dp(0).civ.get("casa", "casa"), "tx": b0.x - 3, "ty": b0.y + 6})
		if i % 400 == 200:
			for e in s.actives:
				if e.owner == 0 and e.capital:
					s.push_command({"t": "train", "player": 0, "building": e.id, "type": "aldeano"})
					break
		s.step()


func _comparar(nombre: String, a: Sim, t: int, meta: Dictionary, t2: int) -> void:
	var d := Guardado.datos(meta, a)
	var back: Dictionary = JSON.parse_string(JSON.stringify(d))
	var t0 := Time.get_ticks_msec()
	var b := Guardado.armar(back)
	Guardado.avanzar(b, int(back["tick"]))
	var ms := Time.get_ticks_msec() - t0
	var hb := b.state_hash()
	var ok := a.state_hash() == hb and hb == int(back["hash"]) and b.tick == t
	# Las dos siguen con la misma orden: tienen que seguir iguales (y la cargada sigue grabando).
	for s in [a, b]:
		for e in s.actives:
			if e.owner == 0 and e.capital:
				s.push_command({"t": "train", "player": 0, "building": e.id, "type": "aldeano"})
				break
		Guardado.avanzar(s, t2)
	var ok2 := a.state_hash() == b.state_hash() and a.recording.size() == b.recording.size()
	print("%-34s comandos=%d · hash en T %d / cargada %d · carga %d ms · en T2 %d / %d → %s" % [nombre, (back["comandos"] as Array).size(), int(back["hash"]), hb, ms, a.state_hash(), b.state_hash(), "OK" if ok and ok2 else "FALLO"])
	if not (ok and ok2):
		_fallas += 1


func _finalize() -> void:
	Sim.soltar_todas()
