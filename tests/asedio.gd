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
	var hurt := 0
	var center_loss := foes[4].hp_max - foes[4].hp
	var corner_loss := foes[0].hp_max - foes[0].hp
	for f in foes:
		if f.hp < f.hp_max:
			hurt += 1
	check("el área daña a los 9 honderos del bloque", hurt == 9, "(%d dañados)" % hurt)
	check("pega más en el centro que en el borde", center_loss > corner_loss and corner_loss > 0, "(centro %d, esquina %d)" % [center_loss, corner_loss])
	check("no daña a los propios", mine.hp == mine.hp_max)

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

	print("ASEDIO: %s" % ("OK" if fails == 0 else "%d FALLAS" % fails))
	quit(1 if fails > 0 else 0)
