extends SceneTree
## Pruebas de jugabilidad (proceso/21): comportamientos que se esperan al estilo AoE4.
## Uso: godot --headless --path . -s tests/jugabilidad.gd

var fails := 0


func _init() -> void:
	_almacen_recolecta()
	_tecnologias_con_lugar()
	_aldeanos_en_bloque()
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
				if spot.x < 0 and s.can_place("deposito", tree.tx + dx, tree.ty + dy, 0):
					spot = Vector2i(tree.tx + dx, tree.ty + dy)
	var ids := []
	for e in s.entities:
		if e.alive and e.owner == 0 and e.type == "aldeano" and ids.size() < 3:
			ids.append(e.id)
	s.players[0]["res"]["madera"] = 500
	s.push_command({"t": "build", "player": 0, "ids": ids, "type": "deposito", "tx": spot.x, "ty": spot.y})
	for i in 900:
		s.step()
	var gathering := 0
	for id in ids:
		var v: SimEntity = s.by_id[id]
		if v.order in [SimEntity.Order.GATHER, SimEntity.Order.RETURN] and v.gather_kind == "madera":
			gathering += 1
	_check(gathering == ids.size(), "almacén junto al bosque: %d de %d aldeanos recolectan madera al terminar" % [gathering, ids.size()])


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
