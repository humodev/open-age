extends SceneTree
## Paso 4 del juego tardío (docs/diseno/27, §4.2; proceso/26-juego-tardio/08): pruebas de la
## mecánica, sin IA.
##   godot --headless --path . -s tests/asedio.gd
## 1. El asedio sin bono por edad pega lo mismo que antes con sus niveles (ariete de cada pueblo).
## 2. El asedio de área daña a varios enemigos cerca del blanco, menos en el borde, y a ningún propio.
## 3. El hondero de piedra caliente y el cañón de tacuara reemplazan al ariete desde la III.
## 4. El hito militar de la III da su bono de combate solo en su aura.
## 5. Aspilleras y fortaleza reforzada suman flechas y vida a la fortaleza.
## 6. Los incendiarios mapuches pegan más contra la madera que contra la piedra.
## 7. Muralla de piedra (proceso/32-ronda-8/06): reforzar la empalizada arrastrando encima, la
##    torre solo sobre un tramo, la puerta de piedra; la tropa le saca el mínimo y el asedio no.

const P := 1000
var fails := 0


func check(what: String, ok: bool, extra: String = "") -> void:
	print("%s %s %s" % ["OK  " if ok else "FALLA", what, extra])
	if not ok:
		fails += 1


func _sim(civs: Array) -> Sim:
	var s := Sim.new(5, 2, null, {"civs": civs})
	# Sin nadie en el mapa: las pruebas ponen lo suyo lejos de las bases.
	for e in s.actives.duplicate():
		if e.owner >= 0:
			s.remove_quietly(e)
	return s


func _free_spot(s: Sim) -> Vector2i:
	var c := s.map.n / 2
	return s.map.nearest_free(c, c, 20, 0)


func _old_bonus(age: int) -> int:
	return [0, 10, 20, 35][age - 1]


func _init() -> void:
	# 1. Ariete: antes (45, 32, 38 con el bono de la edad) y ahora (49, 35, 41 con los niveles).
	var old_atk := {"": 45, "tawantinsuyu": 32, "guaranies": 38}
	for civ: String in old_atk:
		var s := _sim([civ, ""] if civ != "" else [])
		var c := _free_spot(s)
		for age in [2, 3, 4]:
			s.players[0]["age"] = age
			s.grant_age_purchases(0, age)
			var r := s.spawn_unit("ariete", 0, c.x * P, c.y * P)
			var before := int(old_atk[civ]) * (100 + _old_bonus(age)) / 100
			var now := s.effective_attack(r)
			check("ariete %s edad %d: %d (antes %d)" % [civ if civ != "" else "común", age, now, before], absi(now - before) <= 1)
			s.remove_quietly(r)

	# 2. Área: catapulta común contra un bloque de honderos.
	var s2 := _sim([])
	var c2 := _free_spot(s2)
	s2.players[0]["age"] = 3
	var cat := s2.spawn_unit("catapulta", 0, c2.x * P, (c2.y + 6) * P)
	var foes: Array[SimEntity] = []
	for i in 9:
		foes.append(s2.spawn_unit("hondero", 1, c2.x * P + (i % 3 - 1) * 500, c2.y * P + (i / 3 - 1) * 500))
	var mine := s2.spawn_unit("hondero", 0, c2.x * P + 300, c2.y * P + 300)
	s2._rebuild_hashes()
	s2._hit(cat, foes[4])
	# --- esport 1a --- el tiro vuela (D-031): no pega al salir, pega en el punto al llegar
	var hurt0 := 0
	for f in foes:
		hurt0 += 1 if f.hp < f.hp_max else 0
	check("el tiro de área no pega al salir (vuela %d ticks)" % s2.shell_ticks(cat), hurt0 == 0 and s2.shells.size() == 1)
	s2.tick += s2.shell_ticks(cat)
	s2._land_shells()
	var hurt := 0
	var center_loss := foes[4].hp_max - foes[4].hp
	var corner_loss := foes[0].hp_max - foes[0].hp
	for f in foes:
		if f.hp < f.hp_max:
			hurt += 1
	check("el área daña a los 9 honderos del bloque", hurt == 9, "(%d dañados)" % hurt)
	check("pega más en el centro que en el borde", center_loss > corner_loss and corner_loss > 0, "(centro %d, esquina %d)" % [center_loss, corner_loss])
	check("no daña a los propios", mine.hp == mine.hp_max)
	# --- esport 1a --- esquivar: el bloque se corre 2 casillas mientras vuela y el tiro no le pega
	var s2b := _sim([])
	var c2b := _free_spot(s2b)
	var cat_b := s2b.spawn_unit("catapulta", 0, c2b.x * P, (c2b.y + 6) * P)
	var foes_b: Array[SimEntity] = []
	for i in 9:
		foes_b.append(s2b.spawn_unit("hondero", 1, c2b.x * P + (i % 3 - 1) * 500, c2b.y * P + (i / 3 - 1) * 500))
	s2b._rebuild_hashes()
	s2b._hit(cat_b, foes_b[4])
	for f in foes_b:
		f.x -= 2500
	s2b._rebuild_hashes()
	s2b.tick += s2b.shell_ticks(cat_b)
	s2b._land_shells()
	var hurt_b := 0
	for f in foes_b:
		hurt_b += 1 if f.hp < f.hp_max else 0
	check("esquivar: el bloque que se corrió 2,5 casillas no recibe el tiro", hurt_b == 0, "(%d dañados)" % hurt_b)
	# --- esport 1a --- atacar el suelo: tira al punto aunque no haya nadie, y el ariete no puede
	var s2c := _sim([])
	var c2c := _free_spot(s2c)
	s2c.players[0]["age"] = 3
	var cat_c := s2c.spawn_unit("catapulta", 0, c2c.x * P, c2c.y * P)
	var ram_c := s2c.spawn_unit("ariete", 0, c2c.x * P + 1000, c2c.y * P)
	s2c.push_command({"t": "suelo", "player": 0, "ids": [cat_c.id, ram_c.id], "x": c2c.x * P + 9000, "y": c2c.y * P})
	var fired := 0
	for k in 120:
		s2c.step()
		for ev in s2c.events:
			if ev["t"] == "tiro" and int(ev["a"]) == cat_c.id:
				fired += 1
	check("atacar el suelo: la catapulta se acerca y tira al punto (%d tiros en 12 s)" % fired, fired >= 1 and cat_c.order == SimEntity.Order.GROUND)
	check("atacar el suelo: el ariete no lo hace", ram_c.order != SimEntity.Order.GROUND)

	# 3. Reemplazo del ariete inca y guaraní en la III.
	for civ in ["tawantinsuyu", "guaranies"]:
		var s3 := _sim([civ, "mapuches"])
		var dd := s3.dp(0)
		check("%s: el ariete se entrena en la II" % civ, dd.replaced_by("ariete", 2) == "")
		check("%s: desde la III lo reemplaza %s" % [civ, dd.unidades["catapulta"]["nombre"]], dd.replaced_by("ariete", 3) == "catapulta")
	var s3b := _sim(["mapuches", "palmares"])
	check("mapuches: incendiarios en la III, sin catapulta", s3b.dp(0).unidades.has("incendiarios") and not s3b.dp(0).unidades.has("catapulta"))
	check("Palmares: sin asedio de área ni niveles de asedio", not s3b.dp(1).unidades.has("catapulta") and not s3b.dp(1).tecnologias.has("veterano_asedio"))

	# 4. Aura del hito militar de la III (kallanka real inca: +2 de ataque).
	var s4 := _sim(["tawantinsuyu", "mapuches"])
	var c4 := _free_spot(s4)
	s4.players[0]["age"] = 2
	var h := s4.spawn_building("kallanka_real", 0, c4.x, c4.y, false)
	s4._complete(h)
	var near := s4.spawn_unit("guerrero", 0, h.x + 3000, h.y)
	var far := s4.spawn_unit("guerrero", 0, h.x + 30000, h.y)
	s4._aura_combat()
	check("la kallanka real llevó a la III", int(s4.players[0]["age"]) == 3)
	check("cerca del hito, +2 de ataque", s4.effective_attack(near) == s4.effective_attack(far) + 2, "(cerca %d, lejos %d)" % [s4.effective_attack(near), s4.effective_attack(far)])
	far.x = h.x + 2000
	s4._aura_combat()
	check("al entrar al aura, lo gana", s4.effective_attack(far) == s4.effective_attack(near))
	# El hito de la II (pukara de frontera, +1 de armadura) sigue siendo global.
	var s4b := _sim(["tawantinsuyu", "mapuches"])
	var c4b := _free_spot(s4b)
	var h2 := s4b.spawn_building("pukara_mayor", 0, c4b.x, c4b.y, false)
	s4b._complete(h2)
	var far2 := s4b.spawn_unit("guerrero", 0, h2.x + 30000, h2.y)
	check("el hito militar de la II sigue global", s4b.effective_armor(far2) == int(far2.def["armadura"]) + 1)

	# 5. Fortaleza: aspilleras y reforzada.
	var s5 := _sim(["etiopia", "ayutthaya"])
	var c5 := _free_spot(s5)
	s5.players[0]["age"] = 4
	var f := s5.spawn_building("fortaleza", 0, c5.x, c5.y, true)
	var shots0 := s5.volley_shots(f)
	var hp0 := f.hp_max
	s5._finish_tech(0, "aspilleras")
	s5._finish_tech(0, "fortaleza_reforzada")
	check("aspilleras y reforzada: +3 flechas", s5.volley_shots(f) == shots0 + 3, "(%d → %d)" % [shots0, s5.volley_shots(f)])
	check("reforzada: +30 % de vida", f.hp_max == hp0 * 130 / 100, "(%d → %d)" % [hp0, f.hp_max])

	# 6. Incendiarios contra madera y piedra.
	var s6 := _sim(["mapuches", "etiopia"])
	var c6 := _free_spot(s6)
	s6.players[0]["age"] = 3
	var inc := s6.spawn_unit("incendiarios", 0, c6.x * P, c6.y * P)
	var casa := s6.spawn_building("casa", 1, c6.x + 2, c6.y, true)
	var torre := s6.spawn_building("torre", 1, c6.x + 6, c6.y, true)
	var m_wood := s6.counter_mult(inc, casa)
	var m_stone := s6.counter_mult(inc, torre)
	check("incendiarios: madera ×%d %%, piedra ×%d %%" % [m_wood, m_stone], m_wood > 3 * m_stone)

	_muralla()

	print("ASEDIO: %s" % ("OK" if fails == 0 else "%d FALLAS" % fails))
	quit(1 if fails > 0 else 0)


## Golpe de `a` a `t` sin la altura ni los efectos propios: como Sim._hit.
func _golpe(s: Sim, a: SimEntity, t: SimEntity) -> int:
	var atk := s.effective_attack(a) + s.attack_bonus(a, t)
	if a.fn == "asedio" and t.is_building():
		atk = atk * (100 + s.mod(a.owner, "asedio_pct")) / 100
	return maxi(int(s.data.reglas["danio_minimo"]), atk * s.counter_mult(a, t) / 100 - s.effective_armor(t, s.is_ranged(a)))


func _muralla() -> void:
	var s := _sim(["etiopia", "mapuches"])
	var c := _free_spot(s)
	s.players[0]["age"] = 2
	s.players[0]["res"]["piedra"] = 5000
	var tiles := []
	for i in 6:
		s.spawn_building("empalizada", 0, c.x + i, c.y, true)
		tiles.append([c.x + i, c.y])
	tiles.append([c.x + 6, c.y])
	var none: Array[SimEntity] = []
	var piedra0 := int(s.players[0]["res"]["piedra"])
	s._cmd_build_line(0, none, "muralla", tiles)
	var reforzados := 0
	for t: Array in tiles:
		var b: SimEntity = s.by_id.get(s.map.occupant(t[0], t[1]))
		if b != null and b.alive and b.type == "muralla":
			reforzados += 1
	var costo := int(s.dp(0).cost_of("muralla", 2)["piedra"])
	check("muralla: arrastrada encima de la empalizada la refuerza", reforzados == 7, "(%d de 7)" % reforzados)
	check("muralla: cobra la piedra de cada tramo", piedra0 - int(s.players[0]["res"]["piedra"]) == 7 * costo, "(%d)" % (piedra0 - int(s.players[0]["res"]["piedra"])))
	check("torre de muralla: no va en el suelo", not s.can_place("torre_muralla", c.x, c.y + 3, 0))
	check("torre de muralla: va sobre un tramo propio", s.can_place("torre_muralla", c.x + 2, c.y, 0))
	check("torre de muralla: no sobre el tramo de otro", not s.can_place("torre_muralla", c.x + 2, c.y, 1))
	check("puerta de piedra: va sobre un tramo propio", s.can_place("puerta_piedra", c.x + 4, c.y, 0))
	var pm := s.spawn_building("puerta", 0, c.x, c.y + 6, true)
	check("puerta de piedra: refuerza la de madera", s.can_place("puerta_piedra", pm.tx, pm.ty, 0))
	s.players[0]["age"] = 1
	var antes := int(s.players[0]["res"]["piedra"])
	s._cmd_build_line(0, none, "muralla", [[c.x, c.y + 12], [c.x + 1, c.y + 12]])
	check("muralla: en la edad I no se traza", s.map.occupant(c.x, c.y + 12) == -1 and int(s.players[0]["res"]["piedra"]) == antes)
	s.players[0]["age"] = 2
	var tramo: SimEntity = s.by_id.get(s.map.occupant(c.x + 1, c.y))
	s.players[1]["age"] = 3
	var u := c + Vector2i(0, 2)
	var guerrero := s.spawn_unit("guerrero", 1, u.x * P, u.y * P)
	var arquero := s.spawn_unit("hondero", 1, u.x * P, u.y * P)
	var inc := s.spawn_unit("incendiarios", 1, u.x * P, u.y * P)
	var emp := s.spawn_building("empalizada", 0, c.x, c.y + 9, true)
	var ar := s.spawn_unit("ariete", 0, u.x * P, u.y * P)
	var g_m := _golpe(s, guerrero, tramo)
	var h_m := _golpe(s, arquero, tramo)
	var i_m := _golpe(s, inc, tramo)
	var i_e := _golpe(s, inc, emp)
	var a_m := _golpe(s, ar, tramo)
	var a_e := _golpe(s, ar, emp)
	print("      golpes contra la muralla (%d de vida): choque %d, distancia %d, incendiarios %d (empalizada %d), ariete %d (empalizada %d)" % [tramo.hp_max, g_m, h_m, i_m, i_e, a_m, a_e])
	check("muralla: la tropa le saca el daño mínimo", g_m <= 2 and h_m <= 2)
	check("muralla: el ariete la rompe en menos de 15 golpes", a_m * 15 >= tramo.hp_max)
	check("muralla: los incendiarios le pegan poco a la piedra", i_m * 4 < i_e)
	check("muralla: vale más vida por piedra que la empalizada por madera, y mucha más obra",
		tramo.hp_max > 5 * emp.hp_max and s.dp(0).build_time_of("muralla", 2) >= 4 * s.dp(0).build_time_of("empalizada", 2))
	var s2 := _sim(["tawantinsuyu", "ayutthaya"])
	check("Tawantinsuyu: la pirca es su muro, sin empalizada", s2.dp(0).edificios["muralla"]["nombre"] == "Pirca" and not s2.dp(0).edificios.has("empalizada") and (s2.dp(0).unidades["aldeano"]["construye"] as Array).has("muralla"))
	check("Ayutthaya: el kamphaeng de ladrillo pide madera", int(s2.dp(1).cost_of("muralla", 2).get("madera", 0)) > 0 and (s2.dp(1).unidades["aldeano"]["construye"] as Array).has("muralla"))
	check("mapuches, guaraníes y Palmares: sin muralla de piedra", not s.dp(1).edificios.has("muralla") and not s.data.for_civ("guaranies").edificios.has("muralla") and not s.data.for_civ("palmares").edificios.has("muralla"))


## Al salir se sueltan las partidas creadas (ciclos de referencias; proceso/24, paso 6e).
func _finalize() -> void:
	Sim.soltar_todas()
