extends SceneTree
## --- paso 3 --- Economía del final y escuela de la IV (proceso/26-juego-tardio/07): cada mejora
## nueva hace lo que dice. Sin IA: un jugador con todo a mano.
##   godot --headless --path . -s tests/juego_tardio.gd

var fallas: Array[String] = []


func _check(name: String, ok: bool, detail: String = "") -> void:
	print("%s %s %s" % ["OK   " if ok else "FALLO", name, detail])
	if not ok:
		fallas.append(name)


func _init() -> void:
	var s := Sim.new(11, 2, null, {"civs": ["guaranies", "palmares"]})
	var p: Dictionary = s.players[0]
	p["age"] = 4
	for k in ["alimento", "madera", "piedra", "riqueza"]:
		p["res"][k] = 20000
	var capital: SimEntity = null
	for e in s.actives:
		if e.alive and e.owner == 0 and e.capital:
			capital = e
	var t: Dictionary = s.dp(0).tecnologias

	# La escuela: en la capital, en la tava (hito de la IV) y no en una casa.
	var tava := s.spawn_building("tava", 0, capital.tx + 12, capital.ty, true)
	var casa := s.spawn_building("casa", 0, capital.tx - 6, capital.ty, true)
	_check("escuela en la capital", s.tech_here(t["escuela_registros"], capital))
	_check("escuela en la tava", s.tech_here(t["escuela_registros"], tava))
	_check("escuela no en una casa", not s.tech_here(t["escuela_registros"], casa))
	_check("nombre propio de los registros", t["escuela_registros"]["nombre"] == "Actas del cabildo", t["escuela_registros"]["nombre"])

	# Registros: −10 % en las mejoras de la IV, no en las de antes.
	var antes := s.tech_cost(0, "hachas_3")
	var antes_ii := s.tech_cost(0, "vel_aldeano")
	s._finish_tech(0, "escuela_registros")
	var despues := s.tech_cost(0, "hachas_3")
	_check("registros: descuento en la IV", int(despues["alimento"]) == int(antes["alimento"]) * 90 / 100, "%s -> %s" % [antes, despues])
	_check("registros: nada en la II", s.tech_cost(0, "vel_aldeano") == antes_ii)
	var res_antes := int(p["res"]["madera"])
	s.push_command({"t": "research", "player": 0, "building": capital.id, "tech": "escuela_alcance"})
	s.step()
	_check("se paga con descuento", res_antes - int(p["res"]["madera"]) == int(t["escuela_alcance"]["costo"]["madera"]) * 90 / 100, "%d" % (res_antes - int(p["res"]["madera"])))

	# Aldeano: velocidad y vida.
	var ald: SimEntity = null
	for e in s.actives:
		if e.alive and e.owner == 0 and e.is_unit() and e.fn == "civil":
			ald = e
			break
	var v0 := ald.speed
	var h0 := ald.hp_max
	s._finish_tech(0, "vel_aldeano")
	s._finish_tech(0, "vida_aldeano")
	_check("velocidad del aldeano", ald.speed > v0, "%d -> %d" % [v0, ald.speed])
	_check("vida del aldeano", ald.hp_max == h0 * 130 / 100, "%d -> %d" % [h0, ald.hp_max])

	# Asedio: +15 % de ataque y reparación en el campo.
	var ram := s.spawn_unit("ariete", 0, capital.x + 6000, capital.y + 6000)
	var foe := s.spawn_building("casa", 1, capital.tx + 20, capital.ty + 20, true)
	var h_a := foe.hp
	s._hit(ram, foe)
	var d0 := h_a - foe.hp
	s._finish_tech(0, "escuela_asedio")
	var h_b := foe.hp
	s._hit(ram, foe)
	var d1 := h_b - foe.hp
	_check("asedio +15 % contra edificios", d1 > d0, "%d -> %d de daño" % [d0, d1])
	ram.hp = ram.hp_max / 2
	_check("sin la mejora no se repara", not s.can_repair_unit(0, ram))
	s._finish_tech(0, "escuela_reparar")
	_check("con la mejora se repara", s.can_repair_unit(0, ram))
	s.push_command({"t": "target", "player": 0, "ids": [ald.id], "target": ram.id, "suelto": true})
	var hp_before := ram.hp
	for i in 400:
		s.step()
	_check("el aldeano repara el asedio", ram.hp > hp_before, "%d -> %d de %d" % [hp_before, ram.hp, ram.hp_max])

	# Pólvora y choque: la línea correcta.
	var arc := s.spawn_unit("arcabucero", 0, capital.x + 5000, capital.y)
	var g := s.spawn_unit("guerrero", 0, capital.x + 5000, capital.y + 1000)
	var arc0 := s.effective_attack(arc)
	var g0 := g.hp_max
	s._finish_tech(0, "escuela_polvora")
	s._finish_tech(0, "escuela_choque")
	_check("pólvora +10 %", s.effective_attack(arc) > arc0, "%d -> %d" % [arc0, s.effective_attack(arc)])
	_check("choque +10 % de vida", g.hp_max == g0 * 110 / 100, "%d -> %d" % [g0, g.hp_max])

	# Sitios: +50 % de renta en la IV (renta_edad_pct).
	var cfg: Dictionary = s.data.reglas["sitios"]
	_check("renta de los sitios por edad en los datos", (cfg.get("renta_edad_pct", []) as Array).size() == 4)

	print("JUEGO TARDÍO: %s" % ("OK" if fallas.is_empty() else "FALLO (%d)" % fallas.size()))
	quit(0 if fallas.is_empty() else 1)
