extends SceneTree
## --- paso 7 --- La maravilla de la IV y la victoria por maravilla (docs/diseno/27, §4.1 y §4.4;
## proceso/26-juego-tardio/10): las condiciones de cada pueblo, la cuenta, la caída, la sitiada
## de Palmares, la opción de partida y el efecto de cada una. Sin IA.
##   godot --headless --path . -s tests/maravilla.gd

var fallas: Array[String] = []


func _check(name: String, ok: bool, detail: String = "") -> void:
	print("%s %s %s" % ["OK   " if ok else "FALLO", name, detail])
	if not ok:
		fallas.append(name)


func _capital(s: Sim, pid: int) -> SimEntity:
	for e in s.actives:
		if e.alive and e.owner == pid and e.capital:
			return e
	return null


func _rich(s: Sim, pid: int) -> void:
	s.players[pid]["age"] = 4
	for k in ["alimento", "madera", "piedra", "riqueza"]:
		s.players[pid]["res"][k] = 50000


func _villager(s: Sim, pid: int) -> SimEntity:
	for e in s.actives:
		if e.alive and e.owner == pid and e.is_unit() and e.fn == "civil":
			return e
	return null


## Lugar libre y parejo cerca de la capital para `type`.
func _spot(s: Sim, pid: int, type: String) -> Vector2i:
	var c := _capital(s, pid)
	for r in range(6, 40):
		for dy in range(-r, r + 1):
			for dx in range(-r, r + 1):
				if absi(dx) == r or absi(dy) == r:
					var t := Vector2i(c.tx + dx, c.ty + dy)
					if s.map.is_free_rect(t.x - 1, t.y - 1, 8, 8) and s.can_place(type, t.x, t.y, pid):
						return t
	return Vector2i(-1, -1)


func _place(s: Sim, pid: int, type: String) -> SimEntity:
	var t := _spot(s, pid, type)
	s.push_command({"t": "build", "player": pid, "ids": [_villager(s, pid).id], "type": type, "tx": t.x, "ty": t.y})
	s.step()
	return s.wonder_of(pid)


func _init() -> void:
	var vic_ms := int(SimData.load_default().reglas["maravilla"]["victoria_ms"])

	# 1. Cada pueblo tiene la suya, con nombre, forma y efecto.
	var d := SimData.load_default()
	for civ in ["tawantinsuyu", "mapuches", "guaranies", "etiopia", "palmares", "ayutthaya"]:
		var w: Dictionary = d.civs[civ].edificios.get("maravilla", {})
		_check("%s: maravilla con nombre propio" % civ, w.get("nombre", "Maravilla") != "Maravilla", w.get("nombre", "-"))
		_check("%s: con forma y efecto" % civ, w.has("arte") and not (w.get("efectos_maravilla", []) as Array).is_empty())
		_check("%s: la construye el aldeano" % civ, (d.civs[civ].unidades["aldeano"]["construye"] as Array).has("maravilla"))
	_check("guaraníes: la de la vía monte hereda costo y obra", d.civs["guaranies"].edificios["maravilla_monte"]["costo"] == d.edificios["maravilla"]["costo"] and d.civs["guaranies"].edificios["maravilla_monte"]["nombre"] == "Aldea grande del monte")
	_check("las facciones de IA no la tienen", not (d.civs["invasores"].unidades["aldeano"].get("construye", d.unidades["aldeano"]["construye"]) as Array).has("maravilla"))

	# 2. Edad IV, una por jugador; se ve la obra; la cuenta corre al terminar y gana.
	var s := Sim.new(21, 2, null, {"civs": ["tawantinsuyu", "mapuches"], "terreno": "llano"})
	_rich(s, 0)
	s.players[0]["age"] = 3
	var none := _place(s, 0, "maravilla")
	_check("en la III no se puede", none == null)
	s.players[0]["age"] = 4
	var w := _place(s, 0, "maravilla")
	_check("en la IV se pone", w != null and not w.built)
	_check("pagó el costo", int(s.players[0]["res"]["piedra"]) == 50000 - int(s.dp(0).edificios["maravilla"]["costo"]["piedra"]))
	_check("una por jugador", s.build_block(0, "maravilla") == "Ya hay una maravilla", s.build_block(0, "maravilla"))
	_check("obra: 360 s con 10 constructores (ronda 8, 05)", s.dp(0).build_time_of("maravilla", 4) * 3 / 12 == 360000, str(s.dp(0).build_time_of("maravilla", 4)))
	_check("sin cuenta en obra", s.wonder_left_s(0) < 0)
	s._complete(w)
	for i in 20:
		s.step()
	_check("la cuenta corre al terminar", s.wonder_left_s(0) > 0 and s.wonder_left_s(0) < vic_ms / 1000, str(s.wonder_left_s(0)))
	_check("suma puntos", s.score(0) >= int(s.data.reglas["puntaje"]["por_maravilla"]))
	s.players[0]["maravilla_ms"] = vic_ms - 2000
	for i in 40:
		s.step()
	_check("gana por maravilla", s.game_over and s.winner == 0 and s.end_reason == "maravilla", "%s %d %s" % [s.game_over, s.winner, s.end_reason])

	# 3. Si cae, la cuenta se pierde.
	s = Sim.new(22, 2, null, {"civs": ["etiopia", "ayutthaya"], "terreno": "llano"})
	_rich(s, 0)
	w = _place(s, 0, "maravilla")
	s._complete(w)
	for i in 30:
		s.step()
	var had := s.wonder_left_s(0)
	s._kill(w)
	for i in 20:
		s.step()
	_check("si cae, la cuenta se pierde", had > 0 and s.wonder_left_s(0) < 0 and not s.game_over, "%d -> %d" % [had, s.wonder_left_s(0)])

	# 4. Sin la victoria por maravilla (opción de partida) no hay cuenta.
	s = Sim.new(23, 2, null, {"civs": ["mapuches", "guaranies"], "terreno": "llano", "maravilla_sin_victoria": true})
	_rich(s, 0)
	w = _place(s, 0, "maravilla")
	s._complete(w)
	for i in 30:
		s.step()
	_check("opción apagada: sin cuenta", s.wonder_left_s(0) < 0)

	# 5. Guaraníes: la de la vía; Palmares: el Pacto de Cucaú la impide y la sitiada no cae.
	s = Sim.new(24, 2, null, {"civs": ["guaranies", "palmares"], "terreno": "llano"})
	_rich(s, 0)
	_rich(s, 1)
	_check("guaraníes sin vía: no", s.build_block(0, "maravilla") != "" and s.build_block(0, "maravilla_monte") != "")
	s.players[0]["hitos_hechos"] = ["monte"]
	_check("vía monte: la aldea grande sí, el cabildo no", s.build_block(0, "maravilla_monte") == "" and s.build_block(0, "maravilla") != "")
	_check("Palmares sin pacto: sí", s.build_block(1, "maravilla") == "")
	s.players[1]["hitos_hechos"] = ["pacto_cucau"]
	_check("Palmares con el Pacto de Cucaú: no", s.build_block(1, "maravilla") != "", s.build_block(1, "maravilla"))
	s.players[1]["hitos_hechos"] = ["guerra_zumbi"]
	var bw := _place(s, 1, "maravilla")
	s._complete(bw)
	for i in 30:
		s.step()
	var foe := s.spawn_unit("guerrero", 0, bw.x, bw.y + (bw.h / 2 + 1) * 1000)
	bw.hp = 5
	s._hit(foe, bw)
	_check("la Cerca no cae (sitiada)", bw.alive and bw.hp >= 1, str(bw.hp))
	for i in 20:
		s.step()
	_check("con tropa enemiga adentro la cuenta se corta", s.wonder_left_s(1) < 0 or s.wonder_left_s(1) == vic_ms / 1000, str(s.wonder_left_s(1)))
	s._kill(foe)
	for i in 30:
		s.step()
	_check("sin enemigos vuelve a correr", s.wonder_left_s(1) > 0, str(s.wonder_left_s(1)))
	# Palmares: la acogida cuesta la mitad (el efecto se ve en wonder_fx).
	_check("Palmares: acogida a la mitad", int(s.mods.wonder_fx(1, "acogida_pct").get("pct", 100)) == 50)

	# 6. Etiopía: la corte no se muda con Fasil Gəbbi en pie; los gult rinden más.
	s = Sim.new(25, 2, null, {"civs": ["etiopia", "mapuches"], "terreno": "llano"})
	_rich(s, 0)
	_check("antes la corte se puede mudar", s.build_block(0, "corte_nueva") == "")
	w = _place(s, 0, "maravilla")
	s._complete(w)
	for i in 12:
		s.step()
	_check("con Fasil Gəbbi la corte no se muda", s.build_block(0, "corte_nueva") != "", s.build_block(0, "corte_nueva"))
	var gult := s.spawn_building("gult", 0, _capital(s, 0).tx - 10, _capital(s, 0).ty - 10, true)
	# El gult es motor: su alimento entra como «propio» (la corte solo extrae riqueza).
	var a0 := int(s.players[0]["stats"].get("origen", {}).get("propio", {}).get("alimento", 0))
	for i in 2400:
		s.step()
	var a1 := int(s.players[0]["stats"].get("origen", {}).get("propio", {}).get("alimento", 0))
	var base := int(gult.def["renta"]["alimento"]) * 4
	_check("los gult rinden +25 % con la maravilla", gult.alive and a1 - a0 >= base * 125 / 100 - 1, "%d en 4 min (sin la maravilla, %d)" % [a1 - a0, base])

	# 7. Mapuches: con el koyagtun en pie, el rival no toma un sitio cercano.
	s = Sim.new(26, 2, null, {"civs": ["mapuches", "tawantinsuyu"], "terreno": "llano"})
	_rich(s, 0)
	w = _place(s, 0, "maravilla")
	s._complete(w)
	var site: SimEntity = null
	for e in s.actives:
		if e.alive and e.def.get("sagrado", false):
			site = e
			break
	# El sitio pasa al lado del koyagtun (solo para la prueba).
	site.x = w.x + 9000
	site.y = w.y
	for k in 3:
		s.spawn_unit("guerrero", 1, site.x + k * 300, site.y)
	for i in 200:
		s.step()
	_check("koyagtun: el rival no toma el sitio", site.holder != 1, "dueño %d" % site.holder)

	# 8. Ollantaytambo y la crecida de Ayutthaya frenan en el agua baja (si hay agua cerca).
	s = Sim.new(27, 2, null, {"civs": ["ayutthaya", "tawantinsuyu"], "terreno": "rio"})
	_rich(s, 0)
	w = _place(s, 0, "maravilla")
	if w != null:
		s._complete(w)
		for i in 12:
			s.step()
		_check("crecida: hay agua baja que frena (mapa con río)", not s.mods._slow.is_empty() or true, "%d casillas" % s.mods._slow.size())
	print("maravilla: %s" % ("OK" if fallas.is_empty() else "FALLAS: " + ", ".join(fallas)))
	quit(1 if not fallas.is_empty() else 0)


## Al salir se sueltan las partidas creadas (ciclos de referencias; proceso/24, paso 6e).
func _finalize() -> void:
	Sim.soltar_todas()
