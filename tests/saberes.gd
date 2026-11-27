extends SceneTree
## --- paso 6 --- Saberes propios del primer par (mapuches y guaraníes; docs/diseno/27, §3.2 y §3.3;
## proceso/26-juego-tardio/11): la cantidad (8 mejoras y 3 unidades por pueblo, por edad), la ficha
## (saber y evidencia), nada sagrado en los nombres, y que cada mejora y cada unidad nueva haga lo
## que dice. Sin IA: un jugador con todo a mano.
##   godot --headless --path . -s tests/saberes.gd

var fallas: Array[String] = []
const NIVELES := ["Documentado", "Arqueológico", "Debatido", "Tradición"]
const SAGRADO := ["machi", "rewe", "kultrun", "foye", "canelo", "opy", "mbaraka", "takuapu", "karai", "ngillatun",
	"tabot", "kebero", "lalibela", "iglesia", "calundu", "nganga", "kimbanda", "capoeira", # --- paso 6, par 2 ---
	"huaca", "wak'a", "inti", "qorikancha", "wat", "buda", "phra si", "sak yant"] # --- paso 6, par 3 ---


func _check(name: String, ok: bool, detail: String = "") -> void:
	print("%s %s %s" % ["OK   " if ok else "FALLO", name, detail])
	if not ok:
		fallas.append(name)


func _init() -> void:
	var s := Sim.new(11, 2, null, {"civs": ["mapuches", "guaranies"], "terreno": "rio"})
	for pid in 2:
		s.players[pid]["age"] = 4
		for k in ["alimento", "madera", "piedra", "riqueza"]:
			s.players[pid]["res"][k] = 20000
	_cantidades(s)
	_mapuches(s)
	_guaranies(s)
	# --- paso 6, par 2 --- Etiopía y Palmares (proceso/26-juego-tardio/12)
	var s2 := Sim.new(12, 2, null, {"civs": ["etiopia", "palmares"], "terreno": "llano"})
	for pid in 2:
		s2.players[pid]["age"] = 4
		for k in ["alimento", "madera", "piedra", "riqueza"]:
			s2.players[pid]["res"][k] = 20000
	_cantidades(s2)
	_etiopia(s2)
	_palmares(s2)
	# --- paso 6, par 3 --- Tawantinsuyu y Ayutthaya (proceso/26-juego-tardio/13)
	var s3 := Sim.new(13, 2, null, {"civs": ["tawantinsuyu", "ayutthaya"], "terreno": "llano"})
	for pid in 2:
		s3.players[pid]["age"] = 4
		for k in ["alimento", "madera", "piedra", "riqueza"]:
			s3.players[pid]["res"][k] = 20000
	_cantidades(s3)
	_tawantinsuyu(s3)
	_ayutthaya(s3)
	print("SABERES: %s" % ("OK" if fallas.is_empty() else "FALLO (%d)" % fallas.size()))
	quit(0 if fallas.is_empty() else 1)


## 8 mejoras (2, 3 y 3 por edad; las de la vía guaraní cuentan una vez) y 3 unidades (II, III y IV),
## todas con su ficha: saber (desc) y evidencia con nivel; ningún nombre sagrado.
func _cantidades(s: Sim) -> void:
	var propias_u := {"mapuches": ["infanteria_montada", "incendiarios", "kona_waiki"], "guaranies": ["yga", "catapulta", "caballeria_mision", "kaaguygua"],
		"etiopia": ["guerrero_gasa", "farasanna", "caballeria_corte"], "palmares": ["zagaieiro", "guarnicao_cerca", "capitao_mocambo"],
		"tawantinsuyu": ["boleador", "galgueros", "jinete_manco"], "ayutthaya": ["chang_suek", "ngao", "defensores_suan_phlu"]}
	for pid in 2:
		var dd := s.dp(pid)
		var civ := dd.clave
		var por_edad := {}
		var vias := {}
		for k: String in dd.tecnologias:
			var t: Dictionary = dd.tecnologias[k]
			if not t.get("propia", false):
				continue
			var e := int(t["edad_min"])
			var key := "%d:%s" % [e, t.get("eje", "")] if t.has("via") else k
			if t.has("via"):
				if vias.has(key):
					continue
				vias[key] = true
			por_edad[e] = int(por_edad.get(e, 0)) + 1
			var ev: String = t.get("evidencia", "")
			_check("%s %s: saber y evidencia" % [civ, k], String(t.get("desc", "")).length() > 40 and NIVELES.any(func(n: String) -> bool: return ev.begins_with(n)), ev.substr(0, 30))
			for w in SAGRADO:
				if String(t["nombre"]).to_lower().contains(w):
					_check("%s %s: nada sagrado en el nombre (%s)" % [civ, k, w], false)
		_check("%s: 8 mejoras propias (2 · 3 · 3)" % civ, por_edad.get(2, 0) == 2 and por_edad.get(3, 0) == 3 and por_edad.get(4, 0) == 3, str(por_edad))
		var edades := {}
		for u: String in propias_u[civ]:
			var d: Dictionary = dd.unidades.get(u, {})
			_check("%s: la unidad %s existe" % [civ, u], not d.is_empty())
			edades[int(d.get("edad_min", 0))] = true
			if d.get("propia", false):
				var ev: String = d.get("evidencia", "")
				_check("%s %s: saber y evidencia" % [civ, u], String(d.get("desc", "")).length() > 40 and NIVELES.any(func(n: String) -> bool: return ev.begins_with(n)))
				_check("%s %s: glifo propio" % [civ, u], Iconos.de_tipo(u) != "" and Iconos.conocido(Iconos.de_tipo(u)), Iconos.de_tipo(u))
		_check("%s: unidades propias en la II, la III y la IV" % civ, edades.has(2) and edades.has(3) and edades.has(4), str(edades.keys()))


func _home(s: Sim, pid: int) -> SimEntity:
	for e in s.actives:
		if e.alive and e.owner == pid and e.capital:
			return e
	return null


## Una casilla libre de tierra cerca de (tx, ty), lejos del agua (`seca`) o junto a ella.
func _land(s: Sim, tx: int, ty: int, seca: bool) -> Vector2i:
	for r in range(0, 30):
		for dy in range(-r, r + 1):
			for dx in range(-r, r + 1):
				var x := tx + dx
				var y := ty + dy
				if not s.map.in_bounds(x, y) or s.map.is_solid(x, y) or s.map.is_water(x, y) or s.map.occupant(x, y) != -1:
					continue
				if s._near_water(x, y, 1, 1, 3) != (not seca):
					continue
				var trees := false
				for t in s.resources_near(x, y, 2):
					trees = trees or t.type == "arbol"
				if not trees:
					return Vector2i(x, y)
	return Vector2i(-1, -1)


func _mapuches(s: Sim) -> void:
	var t: Dictionary = s.dp(0).tecnologias
	var lof := _home(s, 0)
	# Coseletes de cuero: +1 de armadura cuerpo a cuerpo al choque, no contra la distancia.
	var w := s.spawn_unit("guerrero", 0, lof.x + 6000, lof.y)
	var a0 := s.effective_armor(w, false)
	var ad0 := s.effective_armor(w, true)
	s._finish_tech(0, "coseletes_cuero")
	_check("coseletes: +1 contra cuerpo a cuerpo", s.effective_armor(w, false) == a0 + 1 and s.effective_armor(w, true) == ad0, "%d -> %d" % [a0, s.effective_armor(w, false)])
	# Trigo y manzana: +15 % en las granjas.
	s._finish_tech(0, "trigo_manzana")
	_check("trigo y manzana: +15 % granjas", s.mod(0, "tasa:granja") == 15)
	# Hoyos y estacas: sin la mejora no se cava; con ella, el hoyo daña, frena y se pierde.
	_check("hoyo: pide la mejora", s.build_block(0, "hoyo") != "", s.build_block(0, "hoyo"))
	s._finish_tech(0, "hoyos_estacas")
	_check("hoyo: con la mejora se cava", s.build_block(0, "hoyo") == "")
	var g := _home(s, 1)
	var spot := _land(s, (lof.tx + g.tx) / 2, (lof.ty + g.ty) / 2, true)
	var hoyo := s.spawn_building("hoyo", 0, spot.x, spot.y, true)
	_check("hoyo: oculto al rival lejos", s.mods.is_hidden_now(hoyo) and not s.mods.detected_by(hoyo, 1))
	var foe := s.spawn_unit("guerrero", 1, hoyo.x + 1500, hoyo.y)
	_check("hoyo: se ve a 2 casillas", s.mods.detected_by(hoyo, 1))
	foe.x = hoyo.x
	foe.y = hoyo.y
	var hp0 := foe.hp
	s.step()
	s.step()
	_check("hoyo: daña y frena", foe.hp == hp0 - int(hoyo.def["trampa"]["danio"]) and foe.slow_until > s.tick, "%d -> %d" % [hp0, foe.hp])
	_check("hoyo: se pierde", not hoyo.alive)
	foe.hp = 0
	s._kill(foe)
	var hoyo2 := s.spawn_building("hoyo", 0, spot.x, spot.y, true)
	var horse := s.spawn_unit("caballeria_mision", 1, hoyo2.x, hoyo2.y)
	var hh0 := horse.hp
	s.step()
	s.step()
	_check("hoyo: el doble al montado", hh0 - horse.hp == int(hoyo2.def["trampa"]["danio"]) * 2, "%d" % (hh0 - horse.hp))
	horse.hp = 0
	s._kill(horse)
	# Lawen: el relevo cura 25 % más.
	var k := s.spawn_unit("guerrero", 0, lof.x + 7000, lof.y)
	k.hp = 10
	k.last_combat = -100000
	s.mods._regen()
	var h1 := k.hp - 10
	k.hp = 10
	s._finish_tech(0, "lawen")
	s.mods._regen()
	_check("lawen: el relevo cura más", k.hp - 10 > h1, "%d -> %d por segundo" % [h1, k.hp - 10])
	# Arreo en tropilla: más cabezas por corral y una más por minuto.
	var corral := s.spawn_building("corral", 0, lof.tx + 8, lof.ty + 8, true)
	var c0 := s.mods.corral_cap(corral)
	s._finish_tech(0, "arreo_tropilla")
	_check("arreo: el corral guarda más", s.mods.corral_cap(corral) > c0, "%d -> %d" % [c0, s.mods.corral_cap(corral)])
	_check("arreo: una cabeza más por minuto", s.mod(0, "arreo_extra") == 1)
	# Makuñ: cada lof da riqueza; lo vendido rinde más.
	var r0 := int(s.players[0]["res"]["riqueza"])
	for i in 600:
		s.mods._rents(0, s.players[0])
	var sin_makun := int(s.players[0]["res"]["riqueza"]) - r0
	s._finish_tech(0, "makun")
	r0 = int(s.players[0]["res"]["riqueza"])
	for i in 600:
		s.mods._rents(0, s.players[0])
	var lofs := 0
	for e in s.actives:
		lofs += 1 if e.alive and e.owner == 0 and e.type == "lof" and e.built else 0
	var gan := int(s.players[0]["res"]["riqueza"]) - r0 - sin_makun
	_check("makuñ: 4 de riqueza por minuto por lof", absi(gan - 40 * lofs) <= 1, "%d lof, +%d en 10 minutos" % [lofs, gan])
	_check("makuñ: el mercado paga más", s.mod(0, "venta_pct") == 20)
	# Kawellu: +5 % de vida a los montados y −10 % de costo.
	var j := s.spawn_unit("jinete", 0, lof.x + 7000, lof.y + 2000)
	var jh := j.hp_max
	var jc := s.train_cost(0, corral, "jinete")
	s._finish_tech(0, "kawellu")
	_check("kawellu: vida de los montados", j.hp_max == jh * 105 / 100, "%d -> %d" % [jh, j.hp_max])
	_check("kawellu: el jinete cuesta menos", int(s.train_cost(0, corral, "jinete")["alimento"]) == int(jc["alimento"]) * 90 / 100, "%s -> %s" % [jc, s.train_cost(0, corral, "jinete")])
	# Werken y pron: la tropa va más rápido.
	var v0 := w.speed
	s._finish_tech(0, "werken_pron")
	_check("werken y pron: +10 % de velocidad", w.speed > v0, "%d -> %d" % [v0, w.speed])
	# Weichafe montado: más rápido que el de a pie y tarda en bajarse a pelear.
	var im := s.spawn_unit("infanteria_montada", 0, lof.x + 9000, lof.y)
	var wf := s.spawn_unit("guerrero", 0, lof.x + 9000, lof.y + 1000)
	_check("weichafe montado: anda como jinete", im.speed > wf.speed, "%d > %d" % [im.speed, wf.speed])
	for e in s.actives:
		if e.alive and e.is_unit() and e.is_military() and e != im and e != wf:
			e.hp = 0
			s._kill(e)
	# Un blanco que no devuelve el golpe (una casa): si le pegan en el camino, ya está en combate y no
	# desmonta de nuevo (desmonta_tras_ms).
	var dummy := s.spawn_building("casa", 1, im.x / 1000 + 3, im.y / 1000, true)
	s.push_command({"t": "target", "player": 0, "ids": [im.id], "target": dummy.id})
	var first_hit := -1
	var reach_tick := -1
	for i in 120:
		s.step()
		if reach_tick < 0 and s.dist_to(im, dummy) <= s.reach_of(im):
			reach_tick = s.tick
		for ev in s.events:
			if ev["t"] == "hit" and ev["a"] == im.id and first_hit < 0:
				first_hit = s.tick
	_check("weichafe montado: tarda en desmontar", reach_tick >= 0 and first_hit - reach_tick >= int(im.def["desmonta_ms"]) / s.tick_ms - 1, "llega %d, pega %d" % [reach_tick, first_hit])
	var lz := s.spawn_unit("lancero", 1, im.x, im.y + 3000)
	_check("weichafe montado: la lanza no le hace el extra contra caballería", s.attack_bonus(lz, im) == s.attack_bonus(lz, wf))
	# Kona de waiki: la carga pega más y derriba; +8 contra los montados.
	var kw := s.spawn_unit("kona_waiki", 0, lof.x + 12000, lof.y)
	var tg := s.spawn_unit("jinete", 1, kw.x + 500, kw.y)
	kw.last_combat = -100000
	var t0 := tg.hp
	s._hit(kw, tg)
	var d_carga := t0 - tg.hp
	var slowed := tg.slow_until > s.tick
	t0 = tg.hp
	s._hit(kw, tg)
	var d_comun := t0 - tg.hp
	_check("kona de waiki: la carga pega más y derriba", d_carga > d_comun and slowed, "%d contra %d" % [d_carga, d_comun])
	_check("kona de waiki: +8 contra montados", s.attack_bonus(kw, tg) >= 8)


func _guaranies(s: Sim) -> void:
	var t: Dictionary = s.dp(1).tecnologias
	var oga := _home(s, 1)
	# Kokue: las rozas rinden más y duran más.
	var r1 := s.spawn_building("granja", 1, oga.tx + 8, oga.ty + 8, true)
	s._finish_tech(1, "kokue")
	var r2 := s.spawn_building("granja", 1, oga.tx + 8, oga.ty + 12, true)
	_check("kokue: +15 % en las rozas", s.mod(1, "tasa:roza") == 15)
	_check("kokue: la roza dura 25 % más", r2.amount == r1.amount * 125 / 100, "%d -> %d" % [r1.amount, r2.amount])
	# Ygá (mejora): más rápido en los vados; carga junto al agua.
	var ford := Vector2i(-1, -1)
	for i in s.map.n * s.map.n:
		if s.map.water[i] == 2:
			ford = Vector2i(i % s.map.n, i / s.map.n)
			break
	var u := s.spawn_unit("guerrero", 1, ford.x * 1000 + 500, ford.y * 1000 + 500)
	var sp0 := s.mods.speed(u)
	s._finish_tech(1, "canoas_rio")
	_check("ygá: más rápido en el vado", ford.x >= 0 and s.mods.speed(u) > sp0, "%d -> %d" % [sp0, s.mods.speed(u)])
	_check("ygá: carga junto al agua", s.mod(1, "carga_rio") == 2)
	u.hp = 0
	s._kill(u)
	# Pohã ñana: la tropa junto al monte sana fuera de combate.
	var tree: SimEntity = null
	for e in s.entities:
		if e.alive and e.is_resource() and e.type == "arbol":
			tree = e
			break
	var m := s.spawn_unit("guerrero", 1, tree.x + 1000, tree.y)
	m.hp = 20
	m.last_combat = -100000
	s.mods._regen()
	var sin := m.hp
	s._finish_tech(1, "poha_nana")
	s.mods._regen()
	_check("pohã ñana: sana junto al monte", sin == 20 and m.hp == 21 and s.mods.in_forest(m), "%d -> %d" % [sin, m.hp])
	# Óga de takuára: casas más baratas y más rápidas, potirõ más fuerte.
	var c0 := s.build_cost(1, "casa")
	s._finish_tech(1, "oga_takuara")
	_check("óga de takuára: casa con menos madera", int(s.build_cost(1, "casa")["madera"]) == int(c0["madera"]) * 80 / 100, "%s -> %s" % [c0, s.build_cost(1, "casa")])
	_check("óga de takuára: obra y potirõ", s.mod(1, "obra_t:casa") == -30 and s.mod(1, "potiro") == 2)
	# Defensa de Mbororé: el cañón de tacuara pega más y llega más lejos; arqueros junto al agua.
	var cn := s.spawn_unit("catapulta", 1, oga.x + 6000, oga.y)
	var at0 := s.effective_attack(cn)
	var rc0 := s.reach_of(cn)
	var wet := _land(s, ford.x, ford.y, false)
	var arq := s.spawn_unit("hondero", 1, wet.x * 1000 + 500, wet.y * 1000 + 500)
	var dry := _land(s, oga.tx, oga.ty, true)
	var arq2 := s.spawn_unit("hondero", 1, dry.x * 1000 + 500, dry.y * 1000 + 500)
	var ar0 := s.effective_armor(arq, true)
	s._finish_tech(1, "defensa_mborore")
	_check("Mbororé: cañón +25 %", s.effective_attack(cn) == at0 * 125 / 100, "%d -> %d" % [at0, s.effective_attack(cn)])
	_check("Mbororé: cañón +1 casilla", s.reach_of(cn) == rc0 + 1000)
	_check("Mbororé: arquero junto al agua +1", s.effective_armor(arq, true) == ar0 + 1 and s.effective_armor(arq2, true) == ar0, "%d, %d" % [s.effective_armor(arq, true), s.effective_armor(arq2, true)])
	# U'y hatã: +1 a la distancia.
	var a1 := s.effective_attack(arq2)
	s._finish_tech(1, "uy_hata")
	_check("u'y hatã: +1 de ataque", s.effective_attack(arq2) == a1 + 1)
	# La vía: la imprenta pide la misión; el ka'a plantado se investiga en la misión.
	var taller := s.spawn_building("taller", 1, oga.tx - 10, oga.ty, true)
	_check("imprenta: pide el hito de la misión", s.research_block(1, "imprenta") != "", s.research_block(1, "imprenta"))
	var mis := s.spawn_building("mision", 1, oga.tx + 14, oga.ty - 10, true)
	_check("imprenta: con la misión, en el taller", s.research_block(1, "imprenta") == "" and s.tech_here(t["imprenta"], taller))
	_check("ka'a plantada: en la misión", s.tech_here(t["kaa_plantada"], mis) and not s.tech_here(t["kaa_plantada"], oga))
	var c_antes := s.tech_cost(1, "kaa_plantada")
	s._finish_tech(1, "imprenta")
	_check("imprenta: −15 % en las mejoras", int(s.tech_cost(1, "kaa_plantada")["madera"]) == int(c_antes["madera"]) * 85 / 100, "%s -> %s" % [c_antes, s.tech_cost(1, "kaa_plantada")])
	s._finish_tech(1, "kaa_plantada")
	_check("ka'a plantada: +25 % yerba", s.mod(1, "tasa:yerba") == 25)
	s._finish_tech(1, "aty")
	_check("aty: emboscada +25 %", s.mod(1, "emboscada") == 25)
	# Ka'aguygua: +2 de armadura junto al monte.
	var kg := s.spawn_unit("kaaguygua", 1, tree.x + 1000, tree.y + 1000)
	var kg2 := s.spawn_unit("kaaguygua", 1, dry.x * 1000 + 500, dry.y * 1000 + 500)
	_check("ka'aguygua: +2 junto al monte", s.effective_armor(kg, false) == s.effective_armor(kg2, false) + 2, "%d, %d" % [s.effective_armor(kg, false), s.effective_armor(kg2, false)])
	# Ygá (canoa): sin agua cerca no se hace; anda por el agua, sube y baja gente.
	var tapyi_seco := s.spawn_building("almacen_madera", 1, dry.x, dry.y, true)
	_check("canoa: hace falta agua cerca", s.train_block(1, tapyi_seco, "yga") != "", s.train_block(1, tapyi_seco, "yga"))
	var deep := Vector2i(-1, -1)
	for i in s.map.n * s.map.n:
		var x := i % s.map.n
		var y := i / s.map.n
		if s.map.water[i] == 1 and _land(s, x, y, false).distance_to(Vector2i(x, y)) <= 1.5:
			deep = Vector2i(x, y)
			break
	var boat := s.spawn_unit("yga", 1, deep.x * 1000 + 500, deep.y * 1000 + 500)
	var shore := _land(s, deep.x, deep.y, false)
	var p1 := s.spawn_unit("guerrero", 1, shore.x * 1000 + 500, shore.y * 1000 + 500)
	var p2 := s.spawn_unit("aldeano", 1, shore.x * 1000 + 500, shore.y * 1000 + 700)
	s.push_command({"t": "target", "player": 1, "ids": [p1.id, p2.id], "target": boat.id})
	for i in 60:
		s.step()
	_check("canoa: suben", p1.inside == boat.id and p2.inside == boat.id and boat.garrison.size() == 2, "%d %d" % [p1.inside, p2.inside])
	# Por el agua: un tramo de río más lejos.
	var far := Vector2i(-1, -1)
	for i in s.map.n * s.map.n:
		var x := i % s.map.n
		var y := i / s.map.n
		if s.map.is_water(x, y) and absi(x - deep.x) + absi(y - deep.y) >= 12 and not s.map.find_boat_path(deep, Vector2i(x, y)).is_empty() and s.map.find_boat_path(deep, Vector2i(x, y))[-1] == Vector2i(x, y):
			far = Vector2i(x, y)
			break
	s.push_command({"t": "move", "player": 1, "ids": [boat.id], "x": far.x * 1000 + 500, "y": far.y * 1000 + 500})
	var on_water := true
	for i in 400:
		s.step()
		on_water = on_water and s.map.is_water(boat.x / 1000, boat.y / 1000)
	_check("canoa: llega por el agua", far.x >= 0 and on_water and Sim.dist(boat.x, boat.y, far.x * 1000 + 500, far.y * 1000 + 500) < 1500, "a %d de %s" % [Sim.dist(boat.x, boat.y, far.x * 1000 + 500, far.y * 1000 + 500), far])
	s.push_command({"t": "ungarrison", "player": 1, "building": boat.id})
	s.step()
	s.step()
	_check("canoa: bajan en la orilla", p1.inside < 0 and not s.map.is_water(p1.x / 1000, p1.y / 1000) and boat.garrison.is_empty(), "%d,%d" % [p1.x / 1000, p1.y / 1000])
	# Se hunde con gente: nadan a la orilla.
	s.push_command({"t": "target", "player": 1, "ids": [p1.id], "target": boat.id})
	for i in 60:
		s.step()
	boat.hp = 0
	s._kill(boat)
	_check("canoa: si se hunde, nadan", p1.alive and p1.inside < 0)


## --- paso 6, par 2 --- Etiopía (§3.4): cada mejora y unidad hace lo que dice.
func _etiopia(s: Sim) -> void:
	var home := _home(s, 0)
	s._finish_tech(0, "maresha_tef")
	_check("maresha y ṭef: +15 % granjas", s.mod(0, "tasa:granja") == 15)
	s._finish_tech(0, "actas_geez")
	_check("actas en ge'ez: gult +15 %", s.mod(0, "renta_pct:gult") == 15)
	s._finish_tech(0, "faws_kosso")
	_check("fäws y kosso: relevo +25 %", s.mod(0, "relevo_pct") == 25)
	var j := s.spawn_unit("guerrero", 0, home.x + 6000, home.y)
	var a0 := s.effective_armor(j, false)
	s._finish_tech(0, "cota_malla")
	_check("cota de malla: +1 cuerpo a cuerpo al choque", s.effective_armor(j, false) == a0 + 1)
	s._finish_tech(0, "amba_fortaleza")
	_check("amba: la altura defiende 35 %", int(s.mods.m(0, "defensa_altura")["pct"]) + s.mod(0, "altura_pct") == 35)
	s._finish_tech(0, "caravanas_amole")
	_check("amole: el comerciante rinde 20 % más", s.mod(0, "comercio_pct") == 20) # comercio, paso 5: de venta_pct a comercio_pct
	# Pólvora de Massawa: solo con un mercado propio en pie.
	var mq := s.spawn_unit("arcabucero", 0, home.x + 7000, home.y)
	var atk0 := s.effective_attack(mq)
	s._finish_tech(0, "polvora_massawa")
	s.mods.tick_second()
	_check("massawa: sin ruta abierta no suma", s.effective_attack(mq) == atk0, "%d" % s.effective_attack(mq))
	var spot := _land(s, home.tx + 9, home.ty, true)
	var mk := s.spawn_building("mercado", 0, spot.x, spot.y, true)
	s.players[0]["ruta_tick"] = s.tick # comercio, paso 5: un viaje cobrado hace poco abre la ruta
	s.mods.tick_second()
	_check("massawa: con la ruta abierta, +10 %", s.effective_attack(mq) == atk0 * 110 / 100, "%d -> %d" % [atk0, s.effective_attack(mq)])
	s._kill(mk)
	s.players[0]["ruta_tick"] = s.tick - 1 - int(s.comercio.cfg.get("ruta_abierta_ms", 180000)) / s.tick_ms
	s.mods.tick_second()
	_check("massawa: sin viaje en los últimos 3 minutos, se corta", s.effective_attack(mq) == atk0)
	s._finish_tech(0, "orden_katama")
	_check("kätäma: la corte en la mitad del tiempo", s.mod(0, "obra_t:corte_nueva") == -50)
	# Unidades: la jabalina al cerrar y el escudo; la cota; la caballería contra la distancia.
	var g := s.spawn_unit("guerrero_gasa", 0, home.x + 6000, home.y + 2000)
	_check("gaša: +1 de armadura a distancia", s.effective_armor(g, true) >= 1)
	var foe := s.spawn_unit("lancero", 1, g.x + 400, g.y)
	var hp0 := foe.hp
	s.tick += 100
	s._hit(g, foe)
	var first := hp0 - foe.hp
	var hp1 := foe.hp
	s._hit(g, foe)
	_check("gaša: la jabalina al cerrar pega más", first > hp1 - foe.hp, "%d contra %d" % [first, hp1 - foe.hp])
	s._kill(foe)
	var f := s.spawn_unit("farasanna", 0, home.x + 6000, home.y - 2000)
	_check("färäsäñña: 220 de vida, armadura 3", f.hp_max == 220 and int(f.def["armadura"]) == 3, "%d" % f.hp_max)
	var cc := s.spawn_unit("caballeria_corte", 0, home.x + 6000, home.y - 3000)
	var ar := s.spawn_unit("hondero", 1, cc.x + 400, cc.y)
	_check("caballería de la corte: +6 contra la distancia", s.attack_bonus(cc, ar) >= 6)
	for e in [j, mq, g, f, cc, ar]:
		s._kill(e)


## --- paso 6, par 2 --- Palmares (§3.5).
func _palmares(s: Sim) -> void:
	var home := _home(s, 1)
	s._finish_tech(1, "rocas_palmeiras")
	_check("roças e palmeiras: +15 % granjas y renta del mocambo", s.mod(1, "tasa:granja") == 15 and int(s.players[1]["renta_tipos"]["mocambo"]["riqueza"]) == 4)
	s._finish_tech(1, "aviso_mocambos")
	_check("aviso: los mocambos ven 3 casillas más", int(s.fog.vision_extra[1]["mocambo"]) == 3000)
	s._finish_tech(1, "forja_mocambos")
	_check("forja: oficios +25 % y estrepes +50 %", s.mod(1, "oficios_pct") == 25 and s.mod(1, "espinas_pct") == 50)
	# Sanguar: la gente de guerra que se mueve recibe menos de la distancia; quieta, igual.
	var w := s.spawn_unit("guerrero", 1, home.x + 6000, home.y)
	var arq := s.spawn_unit("hondero", 0, w.x + 4000, w.y)
	var d0 := s.mods.damage(arq, w, 100)
	s._finish_tech(1, "sanguar")
	var d1 := s.mods.damage(arq, w, 100)
	w.path.append(Vector2i(w.x / 1000 + 3, w.y / 1000))
	var d2 := s.mods.damage(arq, w, 100)
	_check("sanguar: -15 % de la distancia en movimiento", d1 == d0 and d2 == d0 * 85 / 100, "%d %d %d" % [d0, d1, d2])
	w.path.clear()
	# Kilombo: de cada 4 que llegan, uno es gente de guerra.
	s._finish_tech(1, "kilombo")
	s.players[1]["res"]["fama"] = 5000
	s.players[1]["pop_cap"] = 500
	var guerra0 := 0
	for e in s.actives:
		guerra0 += 1 if e.alive and e.owner == 1 and e.type == "guerrero" else 0
	for i in 4:
		s.mods._welcome(1, s.players[1])
	var guerra1 := 0
	for e in s.actives:
		guerra1 += 1 if e.alive and e.owner == 1 and e.type == "guerrero" else 0
	_check("kilombo: 1 de cada 4 llega como gente de guerra", guerra1 - guerra0 == 1, "%d" % (guerra1 - guerra0))
	s._finish_tech(1, "trato_moradores")
	_check("trato: el mercado casi sin comisión", s.mod(1, "venta_pct") == 40)
	var atk0 := s.effective_attack(w)
	s._finish_tech(1, "hierro_angola_janga")
	_check("hierro de Angola Janga: +1 al choque", s.effective_attack(w) == atk0 + 1)
	_check("fojo: pide la mejora", s.build_block(1, "hoyo") != "")
	s._finish_tech(1, "fojos_estrepes")
	_check("fojo: con la mejora se cava", s.build_block(1, "hoyo") == "", s.build_block(1, "hoyo"))
	# Guarnição: +2 de armadura junto a una cerca propia.
	var spot := _land(s, home.tx - 10, home.ty, true)
	var gc := s.spawn_unit("guarnicao_cerca", 1, spot.x * 1000 + 500, spot.y * 1000 + 500)
	var a0 := s.effective_armor(gc, false)
	s.spawn_building("empalizada", 1, spot.x + 1, spot.y, true)
	_check("guarnição: +2 junto a la cerca", s.effective_armor(gc, false) == a0 + 2, "%d -> %d" % [a0, s.effective_armor(gc, false)])
	# Capitão: la tropa propia a 5 casillas pega 1 más; la lejana, no.
	var cap := s.spawn_unit("capitao_mocambo", 1, w.x + 1000, w.y)
	var far := s.spawn_unit("guerrero", 1, w.x + 20000, w.y + 20000)
	var aw := s.effective_attack(w)
	var af := s.effective_attack(far)
	s.mods._command_aura()
	_check("capitão: +1 a la tropa cerca", s.effective_attack(w) == aw + 1 and s.effective_attack(far) == af)
	var z := s.spawn_unit("zagaieiro", 1, home.x + 5000, home.y + 3000)
	_check("zagaieiro: tiro corto (3 casillas)", s.reach_of(z) == 3000)


## --- paso 6, par 3 --- Tawantinsuyu (§3.1).
func _tawantinsuyu(s: Sim) -> void:
	var home := _home(s, 0)
	s._finish_tech(0, "chunu_charki")
	_check("ch'uñu y ch'arki: +10 % granjas y andenes", s.mod(0, "tasa:granja") == 10)
	s._finish_tech(0, "khipukamayuq")
	_check("khipukamayuq: el taller de tejido rinde +10 %", s.mod(0, "motor") == 10)
	s._finish_tech(0, "qeswa_chaka")
	_check("q'eswa chaka: caminos +5 %", s.mod(0, "camino_pct") == 5)
	var g := s.spawn_unit("guerrero", 0, home.x + 6000, home.y)
	var atk0 := s.effective_attack(g)
	s._finish_tech(0, "champi")
	_check("champi: +1 al choque", s.effective_attack(g) == atk0 + 1)
	s._finish_tech(0, "wayrachina")
	_check("wayrachina: riqueza +20 %", s.mod(0, "tasa:riqueza") == 20)
	var h := s.spawn_unit("hondero", 0, home.x + 6000, home.y + 2000)
	var r0 := s.reach_of(h)
	s._finish_tech(0, "waraka_trenzada")
	_check("warak'a: +media casilla a los honderos", s.reach_of(h) == r0 + 500, "%d -> %d" % [r0, s.reach_of(h)])
	s._finish_tech(0, "chaski")
	_check("chaski: los caminos ven 3 casillas más", int(s.fog.vision_extra[0]["camino"]) == 3000)
	# Cirugía de cráneo: 1 de cada 5 que caen a golpes junto a la kallanka vuelve herido; lejos, no.
	s._finish_tech(0, "trepanacion")
	var spot := _land(s, home.tx + 10, home.ty + 6, true)
	var k := s.spawn_building("cuartel", 0, spot.x, spot.y, true)
	var salvos := 0
	for i in 5:
		var w := s.spawn_unit("guerrero", 0, k.x + 2000, k.y + 2000)
		var foe := s.spawn_unit("guerrero", 1, w.x + 400, w.y)
		w.hp = 1
		s._hit(foe, w)
		salvos += 1 if w.alive and w.hp == w.hp_max / 2 else 0
		s._kill(foe)
		if w.alive:
			s._kill(w)
	_check("trepanación: 1 de cada 5 junto a la kallanka", salvos == 1, "%d" % salvos)
	var lejos := 0
	for i in 5:
		var w2 := s.spawn_unit("guerrero", 0, k.x + 20000, k.y + 20000)
		var foe2 := s.spawn_unit("guerrero", 1, w2.x + 400, w2.y)
		w2.hp = 1
		s._hit(foe2, w2)
		lejos += 1 if w2.alive else 0
		s._kill(foe2)
		if w2.alive:
			s._kill(w2)
	_check("trepanación: lejos de la kallanka, no", lejos == 0, "%d" % lejos)
	# Galgueros: cuesta abajo enteros; en el llano, la mitad.
	var gl := s.spawn_unit("galgueros", 0, home.x + 5000, home.y + 4000)
	var t1 := s.spawn_unit("guerrero", 1, gl.x + 3000, gl.y)
	_check("galgueros: en el llano, la mitad", s.mods.damage(gl, t1, 100) == 50 or s.map.h_at(gl.x / 1000, gl.y / 1000) > s.map.h_at(t1.x / 1000, t1.y / 1000))
	var jm := s.spawn_unit("jinete_manco", 0, home.x + 6000, home.y - 3000)
	var jn := s.spawn_unit("jinete", 1, jm.x + 400, jm.y)
	_check("jinete de Manco: +4 contra los montados y tope de 8 en la IV", s.attack_bonus(jm, jn) >= 4 and int(jm.def["maximo_por_edad"][3]) == 8)
	for e in [g, h, gl, t1, jm, jn]:
		if e.alive:
			s._kill(e)


## --- paso 6, par 3 --- Ayutthaya (§3.6).
func _ayutthaya(s: Sim) -> void:
	var home := _home(s, 1)
	var el := s.spawn_unit("chang_suek", 1, home.x + 6000, home.y)
	var hp0 := el.hp_max
	s._finish_tech(1, "khotchasat")
	_check("khotchasat: +10 % de vida a los elefantes", el.hp_max == hp0 * 110 / 100, "%d -> %d" % [hp0, el.hp_max])
	s._finish_tech(1, "ceramica_satchanalai")
	_check("cerámica: suai +15 % y renta del mercado", s.mod(1, "suai_pct") == 15 and int(s.players[1]["renta_tipos"]["mercado"]["riqueza"]) == 4)
	s._finish_tech(1, "arroz_crecida")
	_check("arroz de crecida: +10 % arrozales", s.mod(1, "tasa:granja") == 10)
	s._finish_tech(1, "barrio_chino")
	_check("barrio chino: los barrios pagan más", int(s.players[1]["renta_tipos"]["barrio_japones"]["riqueza"]) == 6)
	s._finish_tech(1, "khlong_lat")
	_check("khlong lat: +25 % por el agua baja", s.mod(1, "vel_vado") == 25)
	s._finish_tech(1, "astilleros_juncos")
	_check("astilleros: el mercado paga más", s.mod(1, "venta_pct") == 15)
	var mq := s.spawn_unit("arcabucero", 1, home.x + 7000, home.y)
	var a0 := s.effective_attack(mq)
	s._finish_tech(1, "fundicion_real")
	_check("fundición: +10 % a la pólvora", s.effective_attack(mq) == a0 * 110 / 100)
	# Recetario de Narai: fuera de combate, la tropa sana; peleando, no.
	s._finish_tech(1, "recetario_narai")
	var w := s.spawn_unit("guerrero", 1, home.x + 8000, home.y + 3000)
	w.hp = 10
	w.last_combat = s.tick
	s.mods._regen()
	var peleando := w.hp
	s.tick += 200
	s.mods._regen()
	_check("recetario: sana fuera de combate", peleando == 10 and w.hp == 11, "%d %d" % [peleando, w.hp])
	var ng := s.spawn_unit("ngao", 1, home.x + 5000, home.y + 5000)
	var foe := s.spawn_unit("jinete", 0, ng.x + 400, ng.y)
	_check("ngao: +6 contra los montados", s.attack_bonus(ng, foe) >= 6)
	var spot := _land(s, home.tx - 10, home.ty + 4, true)
	var d := s.spawn_unit("defensores_suan_phlu", 1, spot.x * 1000 + 500, spot.y * 1000 + 500)
	var ar0 := s.effective_armor(d, false)
	s.spawn_building("torre", 1, spot.x + 1, spot.y, true)
	_check("Suan Phlu: +2 junto a una torre", s.effective_armor(d, false) == ar0 + 2, "%d -> %d" % [ar0, s.effective_armor(d, false)])
	for e in [el, mq, w, ng, foe, d]:
		if e.alive:
			s._kill(e)
