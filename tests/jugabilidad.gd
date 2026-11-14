extends SceneTree
## Pruebas de jugabilidad (proceso/21): comportamientos que se esperan al estilo AoE4.
## Uso: godot --headless --path . -s tests/jugabilidad.gd

var fails := 0


func _init() -> void:
	_almacen_recolecta()
	_tecnologias_con_lugar()
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
