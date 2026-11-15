extends SceneTree
## Pruebas de jugabilidad (proceso/21): comportamientos que se esperan al estilo AoE4.
## Uso: godot --headless --path . -s tests/jugabilidad.gd

var fails := 0


func _init() -> void:
	_almacen_recolecta()
	_tecnologias_con_lugar()
	_aldeanos_en_bloque()
	_animales()
	_carnear_en_cadena()
	print("JUGABILIDAD: ", "OK" if fails == 0 else "%d fallas" % fails)
	quit()


func _check(ok: bool, what: String) -> void:
	print(("  ok   " if ok else "  FALLA ") + what)
	if not ok:
		fails += 1


## Tres aldeanos levantan un almacén junto al bosque más cercano a su base:
## al terminar tienen que estar recolectando madera, no ociosos ni de vuelta a casa.
func _almacen_recolecta() -> void:
	var s := Sim.new(5, 2, null, {"civs": ["guaranies", "mapuches"], "terreno": "llano"})
	var c: Vector2i = s.bases[0] + Vector2i(2, 2)
	var tree: SimEntity = null
	var best := 1 << 60
	for e in s.entities:
		if e.alive and e.type == "arbol":
			var d := (Vector2i(e.tx, e.ty) - c).length_squared()
			if d > 64 and d < best:
				best = d
				tree = e
	var spot := Vector2i(-1, -1)
	for r in range(2, 8):
		for dy in range(-r, r + 1):
			for dx in range(-r, r + 1):
				if spot.x < 0 and s.can_place("almacen_madera", tree.tx + dx, tree.ty + dy, 0):
					spot = Vector2i(tree.tx + dx, tree.ty + dy)
	var ids := []
	for e in s.entities:
		if e.alive and e.owner == 0 and e.type == "aldeano" and ids.size() < 3:
			ids.append(e.id)
	s.players[0]["res"]["madera"] = 500
	s.push_command({"t": "build", "player": 0, "ids": ids, "type": "almacen_madera", "tx": spot.x, "ty": spot.y})
	for i in 900:
		s.step()
	var gathering := 0
	for id in ids:
		var v: SimEntity = s.by_id[id]
		if v.order in [SimEntity.Order.GATHER, SimEntity.Order.RETURN] and v.gather_kind == "madera":
			gathering += 1
	_check(gathering == ids.size(), "tapyi (leñera guaraní) junto al bosque: %d de %d aldeanos recolectan madera al terminar" % [gathering, ids.size()])


## Toda tecnología tiene algún edificio de la civ donde investigarse (antes Ayutthaya no
## tenía dónde investigar tala ni cantería, y los mapuches, cestas ni riego).
func _tecnologias_con_lugar() -> void:
	var data := SimData.load_default()
	var s := Sim.new(1, 2, null, {"civs": ["guaranies", "mapuches"], "terreno": "llano"})
	var missing := []
	for civ in data.civs:
		var dd: SimData = data.for_civ(civ)
		var cap: String = dd.civ.get("inicio_edificio", "centro")
		for tech in dd.tecnologias:
			var t: Dictionary = dd.tecnologias[tech]
			var ok := false
			for type in dd.edificios:
				var probe := SimEntity.new()
				probe.type = type
				probe.def = dd.edificios[type]
				probe.capital = type == cap
				if s.tech_here(t, probe):
					ok = true
					break
			if not ok:
				missing.append("%s:%s" % [civ, tech])
	_check(missing.is_empty(), "toda tecnología tiene dónde investigarse en cada civ %s" % ("" if missing.is_empty() else str(missing)))


## Ocho aldeanos mandados a una arcilla lejana: marchan en grupo (no en goteo) y al
## llegar cada uno recolecta. Cerca, en cambio, van directo sin grupo.
func _aldeanos_en_bloque() -> void:
	var s := Sim.new(5, 2, null, {"civs": ["guaranies", "mapuches"], "terreno": "llano"})
	var vill: Array = []
	for e in s.entities:
		if e.alive and e.owner == 0 and e.type == "aldeano":
			vill.append(e)
	var c: SimEntity = vill[0]
	var far: SimEntity = null
	var near: SimEntity = null
	for e in s.entities:
		if e.alive and e.is_resource() and e.type != "arbol":
			var d := Sim.dist(e.x, e.y, c.x, c.y)
			if d > 20000 and d < 70000 and (far == null or d < Sim.dist(far.x, far.y, c.x, c.y)):
				far = e
			if d < 10000 and near == null:
				near = e
	if far == null or near == null:
		_check(false, "hay recursos lejos y cerca para la prueba")
		return
	var ids := []
	for v in vill.slice(0, 6):
		ids.append(v.id)
	s.push_command({"t": "target", "player": 0, "ids": ids, "target": far.id})
	s.step()
	s.step()
	var grouped := 0
	for id in ids:
		if s.by_id[id].group >= 0:
			grouped += 1
	_check(grouped == ids.size(), "lejos (%d casillas): %d de %d marchan en grupo" % [Sim.dist(far.x, far.y, c.x, c.y) / 1000, grouped, ids.size()])
	var first := -1
	var last := -1
	for i in 900:
		s.step()
		var working := 0
		for id in ids:
			if s.by_id[id].order == SimEntity.Order.GATHER and s.by_id[id].group < 0:
				working += 1
		if working > 0 and first < 0:
			first = s.tick
		if working == ids.size():
			last = s.tick
			break
	_check(last > 0, "al llegar los %d recolectan; del primero al último, %.1f s" % [ids.size(), (last - first) / 10.0])
	# Cerca, en una partida nueva: los mismos aldeanos todavía en casa.
	s = Sim.new(5, 2, null, {"civs": ["guaranies", "mapuches"], "terreno": "llano"})
	var ids2 := []
	for v in vill.slice(0, 3):
		ids2.append(v.id)
	near = s.by_id[near.id]
	s.push_command({"t": "target", "player": 0, "ids": ids2, "target": near.id})
	s.step()
	s.step()
	var g2 := 0
	for id in ids2:
		if s.by_id[id].group >= 0:
			g2 += 1
	_check(g2 == 0, "cerca: van directo, sin grupo (%d en grupo)" % g2)


## Comida temprana como AoE4 (proceso/23, C-32): animales propios al arrancar (los guaraníes,
## no: son cazadores), el explorador reclama un animal suelto y un aldeano carnea y junta.
func _animales() -> void:
	var s := Sim.new(5, 2, null, {"civs": ["tawantinsuyu", "guaranies"], "terreno": "llano"})
	var own := [0, 0]
	var wild: SimEntity = null
	for e in s.entities:
		if e.alive and e.def.get("animal", false):
			own[e.owner] += 1
		if e.alive and e.is_resource() and e.def.get("reclamable", false) and wild == null:
			wild = e
	_check(own[0] == 5 and own[1] == 0, "animales al arrancar: incas %d (llamas), guaraníes %d" % own)
	var scout: SimEntity = null
	var vill: SimEntity = null
	for e in s.entities:
		if e.alive and e.owner == 0 and e.fn == "explorador":
			scout = e
		if e.alive and e.owner == 0 and e.type == "aldeano" and vill == null:
			vill = e
	s.push_command({"t": "move", "player": 0, "ids": [scout.id], "x": wild.x, "y": wild.y})
	for i in 600:
		s.step()
		if not wild.alive:
			break
	var now := 0
	for e in s.entities:
		if e.alive and e.owner == 0 and e.def.get("animal", false):
			now += 1
	_check(not wild.alive and now > 5, "el explorador reclama el rebaño suelto (ahora %d propios, eran 5)" % now)
	var beast: SimEntity = null
	for e in s.entities:
		if e.alive and e.owner == 0 and e.def.get("animal", false):
			beast = e
	var food0 := int(s.players[0]["res"]["alimento"])
	s.push_command({"t": "target", "player": 0, "ids": [vill.id], "target": beast.id})
	for i in 600:
		s.step()
	_check(not beast.alive and int(s.players[0]["res"]["alimento"]) > food0, "el aldeano carnea y junta: alimento de %d a %d" % [food0, int(s.players[0]["res"]["alimento"])])


## Ronda 2 de los jugadores: carnear en cadena (al terminarse la carne, el animal siguiente
## y no los arbustos) y el aldeano mandado a un animal suelto lo carnea al llegar.
func _carnear_en_cadena() -> void:
	var s := Sim.new(5, 2, null, {"civs": ["tawantinsuyu", "guaranies"], "terreno": "llano"})
	var llama: SimEntity = null
	var ids := []
	for e in s.entities:
		if e.alive and e.owner == 0 and e.def.get("animal", false) and llama == null:
			llama = e
		if e.alive and e.owner == 0 and e.type == "aldeano" and ids.size() < 4:
			ids.append(e.id)
	s.push_command({"t": "target", "player": 0, "ids": ids, "target": llama.id})
	for i in 1500:
		s.step()
	var left := 0
	for e in s.entities:
		if e.alive and e.owner == 0 and e.def.get("animal", false):
			left += 1
	_check(left == 0, "carnear en cadena: 4 aldeanos terminan las 5 llamas sin volver a mandarlos (quedan %d)" % left)
	var s2 := Sim.new(5, 2, null, {"civs": ["tawantinsuyu", "guaranies"], "terreno": "llano"})
	var wild: SimEntity = null
	var v: SimEntity = null
	for e in s2.entities:
		if e.alive and e.owner == 0 and e.type == "aldeano" and v == null:
			v = e
	for e in s2.entities:
		if e.alive and e.is_resource() and e.def.get("reclamable", false) and (wild == null or Sim.dist(e.x, e.y, v.x, v.y) < Sim.dist(wild.x, wild.y, v.x, v.y)):
			wild = e
	s2.push_command({"t": "target", "player": 0, "ids": [v.id], "target": wild.id})
	for i in 300:
		s2.step()
	var tg: SimEntity = s2.by_id.get(v.target)
	_check(v.order in [SimEntity.Order.GATHER, SimEntity.Order.RETURN] and v.carry_res == "alimento" or (tg != null and tg.type == "carne"), "aldeano a un animal suelto: lo reclama y lo carnea (orden %d)" % v.order)
