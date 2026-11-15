extends SceneTree
## Salud de la IA (proceso/21): antes de un torneo, mira que cada IA siga jugando bien con la
## estructura actual. Atrapa en ~5 minutos lo que en el torneo aparece como "desbalance"
## (sin mercado, sin una función, sin ejército, recursos parados). Los umbrales son de la
## prueba, no de balance.
## Uso: godot --headless --path . -s tests/salud_ia.gd

const PAIRS := [["tawantinsuyu", "mapuches"], ["guaranies", "etiopia"], ["palmares", "ayutthaya"]]
const AGE2_MAX_S := 570 # edad II antes de las 9:30
const CHECK_AT_S := 720 # revisión al minuto 12
const ARMY_MIN := 10
const FLOAT_MAX := 4 # sucesos de recursos flotando (uno por minuto como mucho)
const TRIP_MAX := 12 # viaje medio a depositar madera, en casillas (proceso/24, paso 1b)


func _init() -> void:
	var fails := 0
	for pair in PAIRS:
		var s := Sim.new(901, 2, null, {"civs": pair, "terreno": "llano"})
		s.ais = [SimAI.new(s, 0), SimAI.new(s, 1)]
		var age2 := [-1, -1]
		var funcs := [{}, {}]
		var snap := [{}, {}]
		var market_15 := [false, false]
		while s.tick < 15 * 600 and not s.game_over:
			s.step()
			for pid in 2:
				if age2[pid] < 0 and int(s.players[pid]["age"]) >= 2:
					age2[pid] = s.tick / 10
			if s.tick % 50 == 0 and s.tick <= CHECK_AT_S * 10:
				for e in s.actives:
					if e.alive and e.owner >= 0 and e.is_unit() and e.is_military():
						funcs[e.owner][e.fn] = true
			if s.tick % 100 == 0:
				for e in s.actives:
					if e.alive and e.owner >= 0 and e.is_building() and e.built and e.def.get("mercado", false):
						market_15[e.owner] = true
			if s.tick == CHECK_AT_S * 10:
				for pid in 2:
					var army := 0
					var prod := 0
					var market := false
					for e in s.actives:
						if not e.alive or e.owner != pid:
							continue
						if e.is_unit() and e.is_military():
							army += 1
						elif e.is_building() and e.built:
							if e.def.get("mercado", false):
								market = true
							for u in e.def.get("produce", []):
								if s.dp(pid).unidades.get(u, {}).get("funcion", "") in ["choque", "distancia", "linea", "asedio"] and not e.capital:
									prod += 1
									break
					snap[pid] = {"army": army, "prod": prod, "market": market}
		for pid in 2:
			var civ: String = pair[pid]
			var floats := 0
			var idle := 0
			for ev in s.tele.events:
				if ev[2] == pid and ev[0] <= CHECK_AT_S * 10:
					if ev[1] == "recursos_flotando":
						floats += 1
					elif ev[1] == "produccion_ociosa":
						idle += 1
			var problems := []
			if age2[pid] < 0 or age2[pid] > AGE2_MAX_S:
				problems.append("edad II tarde (%s)" % ("nunca" if age2[pid] < 0 else "%d:%02d" % [age2[pid] / 60, age2[pid] % 60]))
			# Al menos dos funciones: la tercera depende de qué tiene el rival (contraataque).
			if (funcs[pid] as Dictionary).size() < 2:
				problems.append("solo %s al minuto 12" % str(funcs[pid].keys()))
			var sn: Dictionary = snap[pid]
			if sn.is_empty():
				problems.append("la partida terminó antes del minuto 12")
			else:
				if int(sn["army"]) < ARMY_MIN:
					problems.append("ejército de %d" % sn["army"])
				if int(sn["prod"]) < 2:
					problems.append("%d edificios de producción" % sn["prod"])
				if s.dp(pid).edificios.has("mercado") and not market_15[pid]:
					problems.append("sin mercado al minuto 15")
			var trips := []
			for kind in ["alimento", "madera", "riqueza", "piedra"]:
				var m := s.tele.mean_trip(pid, kind)
				trips.append("-" if m < 0 else str(m))
			if s.tele.mean_trip(pid, "madera") > TRIP_MAX:
				problems.append("madera a %d casillas del depósito" % s.tele.mean_trip(pid, "madera"))
			if floats > FLOAT_MAX:
				problems.append("%d veces con recursos parados" % floats)
			print("%-13s edad II %s · ejército %s · producción %s · mercado %s · parados %d · ociosa %d · viajes a/m/r/p %s  %s" % [civ,
				"-" if age2[pid] < 0 else "%d:%02d" % [age2[pid] / 60, age2[pid] % 60],
				str(sn.get("army", "-")), str(sn.get("prod", "-")), "sí" if market_15[pid] else "no", floats, idle, "/".join(trips),
				"OK" if problems.is_empty() else "⚠ " + ", ".join(problems)])
			if not problems.is_empty():
				fails += 1
	print("SALUD IA: ", "OK" if fails == 0 else "%d civs con problemas" % fails)
	quit()
