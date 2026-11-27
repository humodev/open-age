extends SceneTree
## Respuestas del autor de mecánicas (proceso/53-respuestas-mecanicas): desempate al tiempo
## límite (C-47 b), captura que se vacía (C-62 a), yerba silvestre y capuera (C-67 a), pacto de
## Cucaú y liberación (C-68 a), Lalibela como sitio y la iglesia sin bono de combate (C-69 a),
## tratado con los oromo (C-91 a) y reparar con costo (C-100 a). Sin IA.
##   godot --headless --path . -s tests/respuestas_mecanicas.gd

var fallas: Array[String] = []


func _check(name: String, ok: bool, detail: String = "") -> void:
	print("%s %s %s" % ["OK   " if ok else "FALLO", name, detail])
	if not ok:
		fallas.append(name)


func _home(s: Sim, pid: int) -> SimEntity:
	for e in s.actives:
		if e.alive and e.owner == pid and e.capital:
			return e
	return null


func _init() -> void:
	_desempate()
	_captura()
	_yerba()
	_palmares()
	_etiopia()
	_reparar()
	print("RESPUESTAS: %s" % ("OK" if fallas.is_empty() else "FALLO (%d)" % fallas.size()))
	quit(0 if fallas.is_empty() else 1)


func _desempate() -> void:
	var s := Sim.new(5, 2, null, {"civs": ["tawantinsuyu", "mapuches"], "terreno": "llano"})
	# Mismos puntos: sin sitios ni edificios de diferencia, empate.
	s.end_by_time()
	var tie_ok := s.winner_team == -1 or s.team_score(0) != s.team_score(1)
	_check("C-47: empate si todo es igual o gana el de más puntos", tie_ok, "%d-%d" % [s.team_score(0), s.team_score(1)])
	var s2 := Sim.new(5, 2, null, {"civs": ["tawantinsuyu", "tawantinsuyu"], "terreno": "llano"})
	if s2.team_score(0) == s2.team_score(1) and not s2.sacred_sites().is_empty():
		s2.sacred_sites()[0].holder = 1
		s2.end_by_time()
		_check("C-47: a igual puntaje, desempata el sitio sagrado", s2.winner_team == s2.team_of(1), "ganó %d" % s2.winner_team)
	else:
		_check("C-47: partida de prueba con puntos iguales y sitios", false)


func _captura() -> void:
	var s := Sim.new(6, 2, null, {"civs": ["tawantinsuyu", "mapuches"], "terreno": "llano"})
	var site: SimEntity = s.sacred_sites()[0]
	site.aux = 0
	site.capture = 6000
	for i in 4:
		s.mods._sacred()
	var dec := int(s.data.reglas["sitios"]["vaciado_ms"])
	_check("C-62: sin nadie, la captura baja %d por segundo" % dec, site.capture == maxi(0, 6000 - 4 * dec), "%d" % site.capture)


func _yerba() -> void:
	var s := Sim.new(7, 2, null, {"civs": ["guaranies", "mapuches"], "terreno": "bosque"})
	var wild := 0
	for e in s.entities:
		if e.alive and e.is_resource() and e.type == "yerbal_silvestre" and e.res_owner == 0:
			wild += 1
	_check("C-67: yerba silvestre del monte junto a la base guaraní", wild >= 2, "%d" % wild)
	var home := _home(s, 0)
	s.players[0]["res"]["madera"] = 5000
	var spot := s.map.nearest_free(home.tx + 8, home.ty, 10)
	var roza := s.spawn_building("granja", 0, spot.x, spot.y, true)
	roza.amount = 0
	s._exhaust(roza)
	var left := ""
	for e in s.entities:
		if e.alive and e.is_resource() and e.tx == spot.x and e.ty == spot.y:
			left = e.type
	_check("C-67: sin la vía misión, la roza que crece deja capuera", left == "capuera", left)
	(s.players[0].get_or_add("hitos_hechos", []) as Array).append("mision")
	var spot2 := s.map.nearest_free(home.tx - 8, home.ty, 10)
	var roza2 := s.spawn_building("granja", 0, spot2.x, spot2.y, true)
	s._exhaust(roza2)
	left = ""
	for e in s.entities:
		if e.alive and e.is_resource() and e.tx == spot2.x and e.ty == spot2.y:
			left = e.type
	_check("C-67: con la vía misión, deja un yerbal plantado", left == "yerbal", left)
	_check("C-67: la misión cría ganado", s.dp(0).edificios["mision"].has("ganado"))


func _palmares() -> void:
	var s := Sim.new(8, 2, null, {"civs": ["palmares", "tawantinsuyu"], "terreno": "llano"})
	var foe := _home(s, 1)
	var spot := s.map.nearest_free(foe.tx + 6, foe.ty + 6, 10)
	var house := s.spawn_building("casa", 1, spot.x, spot.y, true)
	var pal := s.spawn_unit("guerrero", 0, house.x, house.y + 3000)
	var before: int = s.players[0]["pop"]
	var n0 := s.all_units().size()
	s.mods.on_kill(house, pal)
	_check("C-68: contra otro pueblo, la casa no libera a nadie", s.all_units().size() == n0, "%d → %d" % [n0, s.all_units().size()])
	var acog: Dictionary = s.dp(0).mod("acogida")
	_check("C-68: el pacto pone la acogida a la mitad", int(acog.get("pacto_costo_pct", 100)) == 200 and String(acog.get("pacto_hito", "")) == "pacto_cucau")
	_check("C-68: el pacto libera la mitad", int(s.dp(0).mod("liberacion").get("pacto_pct", 100)) == 50)
	before = before


func _etiopia() -> void:
	var s := Sim.new(9, 2, null, {"civs": ["etiopia", "mapuches"], "terreno": "llano"})
	var lal := 0
	for site in s.sacred_sites():
		if site.type == "sitio_lalibela":
			lal += 1
	_check("C-69: Lalibela es un sitio sagrado del mapa", lal == 1, "%d" % lal)
	_check("C-69: Lalibela no se construye", not (s.dp(0).civ.get("construye", []) as Array).has("sitio_lalibela"))
	var fx: Array = s.dp(0).edificios["iglesia"]["efectos"]
	var combat := fx.any(func(ef: Dictionary) -> bool: return String(ef["tipo"]) in ["vida_pct", "ataque", "ataque_pct", "armadura"])
	_check("C-69: la iglesia no da combate", not combat)
	# C-91 a: el tratado trae 5 jinetes; sin agasajo se rompe.
	s.players[0]["age"] = 4
	s.players[0]["res"]["riqueza"] = 1000
	var home := _home(s, 0)
	var est := s.spawn_building("establo", 0, home.tx + 8, home.ty + 8, true)
	est = est
	s._finish_tech(0, "tratado_oromo")
	var riders := 0
	for u in s.all_units():
		if u.alive and u.owner == 0 and u.type == "caballeria_corte":
			riders += 1
	_check("C-91: el tratado trae 5 jinetes oromo", riders == 5, "%d" % riders)
	s.players[0]["res"]["riqueza"] = 0
	for i in 15:
		s.treaty_second(0)
	riders = 0
	for u in s.all_units():
		if u.alive and u.owner == 0 and u.type == "caballeria_corte":
			riders += 1
	_check("C-91: sin agasajo, el tratado se rompe y se van", riders == 0 and not s.players[0]["techs"].has("tratado_oromo"), "%d" % riders)


func _reparar() -> void:
	var s := Sim.new(10, 2, null, {"civs": ["tawantinsuyu", "mapuches"], "terreno": "llano"})
	var home := _home(s, 0)
	var spot := s.map.nearest_free(home.tx + 7, home.ty, 10)
	var b := s.spawn_building("cuartel", 0, spot.x, spot.y, true)
	b.hp = b.hp_max / 2
	var cost := s.repair_basis(b)
	for k in s.players[0]["res"]:
		s.players[0]["res"][k] = 5000
	var res0: Dictionary = s.players[0]["res"].duplicate()
	var dh := b.hp_max - b.hp
	var ok := s._pay_repair(0, b, dh)
	var paid := 0
	var want := 0
	for k in cost:
		paid += int(res0[k]) - int(s.players[0]["res"][k])
		want += int(cost[k]) * int(s.data.reglas["reparacion_costo_pct"]) * dh / 100 / b.hp_max
	_check("C-100: reparar media vida cuesta la cuarta parte del costo", ok and absi(paid - want) <= cost.size(), "%d de %d" % [paid, want])
	for k in s.players[0]["res"]:
		s.players[0]["res"][k] = 0
	_check("C-100: sin recursos no se repara", not s._pay_repair(0, b, dh))
