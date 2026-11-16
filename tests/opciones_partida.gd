extends SceneTree
## Opciones de partida (proceso/24, paso 4b; jugadores de prueba, ronda 2): cada opción hace lo
## que dice.
## - Sitios sin victoria: tener todos los sitios no gana (y con la victoria activa, sí).
## - Hitos sin victoria: perder la capital no alcanza; hay que arrasar todo (salvo muros).
## - Tiempo límite: termina en el minuto pedido y gana el equipo con más puntos; empate, nadie.
## - Recursos: cada jugador arranca con lo de reglas.json → opciones_partida.recursos.
## - Ubicación: "juntos" deja vecinos a los del mismo equipo, "mezclados" los alterna.
## Uso: godot --headless --path . -s tests/opciones_partida.gd [-- --minutos=5]

var fails := 0


func _init() -> void:
	var minutes := 5
	for a in OS.get_cmdline_user_args():
		var kv := a.trim_prefix("--").split("=")
		if kv[0] == "minutos":
			minutes = int(kv[1])
	_recursos()
	_ubicacion()
	_hitos()
	_sitios()
	_tiempo(minutes)
	print("OPCIONES DE PARTIDA: ", "OK" if fails == 0 else "%d fallas" % fails)
	quit(1 if fails > 0 else 0)


func _check(ok: bool, what: String) -> void:
	print("  %s %s" % ["ok   " if ok else "FALLA", what])
	if not ok:
		fails += 1


func _recursos() -> void:
	print("Recursos iniciales")
	var data := SimData.load_default()
	var tbl: Dictionary = data.reglas["opciones_partida"]["recursos"]
	for key in ["normal", "medios", "altos"]:
		var want: Dictionary = data.reglas["recursos_iniciales"] if key == "normal" else tbl[key]
		var s := Sim.new(7, 2, null, {"civs": ["mapuches", "etiopia"], "terreno": "llano", "recursos": key})
		var ok := true
		for p in s.players:
			for k in want:
				if int(p["res"][k]) != int(want[k]):
					ok = false
		_check(ok, "%s: %s" % [key, str(s.players[0]["res"])])


## Distancia entre las bases de dos jugadores (casillas al cuadrado).
func _d2(s: Sim, a: int, b: int) -> int:
	return (s.bases[a] - s.bases[b]).length_squared()


func _ubicacion() -> void:
	print("Ubicación de los equipos")
	var civs := ["tawantinsuyu", "mapuches", "guaranies", "etiopia", "palmares", "ayutthaya"]
	for setup in [[0, 1, 0, 1], [0, 1, 0, 1, 0, 1], [0, 0, 1, 1, 2, 2]]:
		for terrain in ["llano", "islas", "fortines"]:
			for mode in ["juntos", "mezclados"]:
				var np: int = setup.size()
				var s := Sim.new(11, np, null, {"civs": civs.slice(0, np), "equipos": setup, "terreno": terrain, "ubicacion_equipos": mode})
				# Los dos vecinos de cada base en el círculo son las dos más cercanas.
				var allies_next := 0
				var ok_site := 0
				for pid in np:
					var others: Array = range(np).filter(func(q: int) -> bool: return q != pid)
					others.sort_custom(func(a: int, b: int) -> bool: return _d2(s, pid, a) < _d2(s, pid, b))
					for q in others.slice(0, 2):
						if not s.enemies(pid, q):
							allies_next += 1
				for e in s.entities:
					if e.alive and e.def.get("sagrado", false):
						ok_site += 1
				# Cercos de los fortines: cada empalizada, más cerca de la base de su dueño.
				var walls_ok := true
				for e in s.actives:
					if e.alive and e.owner >= 0 and (e.type == "empalizada" or e.type == "puerta"):
						var mine := (Vector2i(e.tx, e.ty) - s.bases[e.owner]).length_squared()
						for q in np:
							if q != e.owner and (Vector2i(e.tx, e.ty) - s.bases[q]).length_squared() < mine:
								walls_ok = false
				# Juntos: cada jugador tiene un aliado al lado. Mezclados: ninguno (con equipos de 2 o 3
				# en 4 o 6 lugares, alternar siempre deja rivales a los dos lados).
				var want_ok := allies_next >= np if mode == "juntos" else allies_next == 0
				_check(want_ok and walls_ok and ok_site >= np, "%s %s %s: aliados al lado %d, sitios %d, cercos %s" % [str(setup), terrain, mode, allies_next, ok_site, "bien" if walls_ok else "MAL"])
	# Sin la opción, el orden de siempre (repeticiones y pruebas viejas no cambian).
	var a := Sim.new(11, 4, null, {"civs": civs.slice(0, 4), "equipos": [0, 1, 0, 1], "terreno": "llano"})
	var b := Sim.new(11, 4, null, {"civs": civs.slice(0, 4), "equipos": [0, 1, 0, 1], "terreno": "llano", "ubicacion_equipos": "mezclados"})
	_check(a.bases == b.bases, "sin opción = el orden dado (en [0,1,0,1], mezclados)")


func _hitos() -> void:
	print("Victoria por hitos")
	for off in [false, true]:
		var s := Sim.new(5, 2, null, {"civs": ["mapuches", "guaranies"], "terreno": "llano", "hitos_sin_victoria": off})
		var b1 := s.bases[1]
		var house := _place(s, "casa", 1, b1 + Vector2i(-6, -6))
		var wall := _place(s, "empalizada", 1, b1 + Vector2i(-9, 0))
		for e in s.actives.duplicate():
			if e.alive and e.owner == 1 and e.is_building() and e.capital:
				s._kill(e)
		for i in 20:
			s.step()
		var after_capital: bool = s.players[1]["defeated"]
		if off:
			_check(not after_capital, "sin hitos: sin capital pero con una casa, sigue en pie")
			s._kill(house)
			for i in 20:
				s.step()
			_check(wall != null and wall.alive, "  queda una empalizada en pie")
			_check(s.players[1]["defeated"] and s.game_over and s.winner == 0 and s.end_reason == "conquista", "sin hitos: arrasada la casa (la empalizada no cuenta), pierde por conquista")
		else:
			_check(after_capital and s.end_reason == "conquista", "con hitos: sin capital ni hitos, pierde aunque tenga una casa")


func _place(s: Sim, type: String, pid: int, at: Vector2i) -> SimEntity:
	for r in 8:
		for dy in range(-r, r + 1):
			for dx in range(-r, r + 1):
				if s.can_place(type, at.x + dx, at.y + dy, pid):
					return s.spawn_building(type, pid, at.x + dx, at.y + dy, true)
	return null


func _sitios() -> void:
	print("Victoria por sitios")
	var win_ticks := int(SimData.load_default().reglas["sitios"]["victoria_ms"]) / 100
	for off in [false, true]:
		var s := Sim.new(9, 2, null, {"civs": ["etiopia", "palmares"], "terreno": "llano", "sitios_sin_victoria": off})
		var n := 0
		for e in s.actives:
			if e.alive and e.def.get("sagrado", false):
				e.holder = 0
				n += 1
		while s.tick < win_ticks + 60 and not s.game_over:
			s.step()
		var rent := int(s.players[0]["stats"].get("origen", {}).get("sitios", {}).get("riqueza", 0))
		if off:
			_check(n > 0 and not s.game_over and rent > 0, "sin sitios: %d sitios de 0 durante %d min, sigue la partida (y rinden %d de riqueza)" % [n, s.tick / 600, rent])
		else:
			_check(s.game_over and s.winner == 0 and s.end_reason == "sitios", "con sitios: gana el 0 a los %s" % _clock(s.tick))


func _tiempo(minutes: int) -> void:
	print("Tiempo límite (%d min)" % minutes)
	# Con IA: termina justo al minuto, gana el equipo con más puntos. Estilo pacífico: no ataca la
	# base, así ninguna partida termina antes por conquista (con 30 minutos pasaba).
	for setup in [[["tawantinsuyu", "palmares"], [0, 1]], [["mapuches", "etiopia", "guaranies", "ayutthaya"], [0, 1, 0, 1]]]:
		var civs: Array = setup[0]
		var s := Sim.new(21, civs.size(), null, {"civs": civs, "equipos": setup[1], "terreno": "llano", "tiempo_limite_min": minutes})
		s.ais = []
		for pid in civs.size():
			var ai := SimAI.new(s, pid)
			ai.personality = "pacifica"
			s.ais.append(ai)
		var ev_motivo := ""
		while not s.game_over and s.tick < minutes * 600 + 50:
			s.step()
			for ev in s.events:
				if ev["t"] == "victory":
					ev_motivo = str(ev.get("motivo", ""))
		var t0 := s.team_score(0)
		var t1 := s.team_score(1)
		var best := 0 if t0 > t1 else (1 if t1 > t0 else -1)
		# El paso del tick N deja el reloj en N + 1: termina en el paso del minuto exacto.
		_check(s.game_over and s.tick - 1 == minutes * 600 and s.end_reason == "tiempo" and ev_motivo == "tiempo", "%d jugadores: termina a los %s (motivo: %s)" % [civs.size(), _clock(s.tick - 1), s.end_reason])
		_check(s.winner_team == best and (best < 0 or s.team_of(s.winner) == best), "  gana el equipo %d por puntos: %d contra %d" % [s.winner_team, t0, t1])
	# Sin nada que sume, empate: nadie gana.
	var e := Sim.new(3, 2, null, {"civs": ["mapuches", "guaranies"], "terreno": "llano", "tiempo_limite_min": 1})
	while not e.game_over and e.tick < 700:
		e.step()
	_check(e.game_over and e.tick - 1 == 600 and e.winner == -1 and e.end_reason == "tiempo", "empate en 0 puntos al minuto: sin ganador")
	# Sin la opción, sigue.
	var f := Sim.new(3, 2, null, {"civs": ["mapuches", "guaranies"], "terreno": "llano"})
	while f.tick < 700:
		f.step()
	_check(not f.game_over, "sin tiempo límite, sigue después del minuto")


func _clock(t: int) -> String:
	return "%d:%02d" % [t / 600, (t / 10) % 60]
