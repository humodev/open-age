extends SceneTree
## Órdenes y comodidades de la simulación (proceso/23, parte B):
##   - mantener posición: no se mueve aunque el enemigo esté a la vista, y pega al que entra en alcance;
##   - patrullar: va y vuelve entre dos puntos;
##   - formaciones: línea (2 filas), columna (2 de ancho), abierta (más ancha que el bloque) y rumbo pedido;
##   - bengala: la IA aliada manda parte de su ejército y lo dice en el chat;
##   - pedido de recursos: la IA aliada da si le sobra.
## Uso: godot --headless --path . -s tests/ordenes.gd

var fails: Array[String] = []


func _init() -> void:
	_hold()
	_patrol()
	_formations()
	_flare_and_ask()
	for f in fails:
		print("FALLO ", f)
	print("ORDENES: ", "OK" if fails.is_empty() else "FALLO (%d)" % fails.size())
	quit(0 if fails.is_empty() else 1)


func _check(name: String, cond: bool) -> void:
	print(("OK    " if cond else "FALLO ") + name)
	if not cond:
		fails.append(name)


## Un lugar despejado en el medio del mapa.
func _clear_sim() -> Sim:
	var s := Sim.new(3, 2, null, {"civs": ["mapuches", "guaranies"], "terreno": "llano", "sin_sitios": true})
	var y0 := s.map.n / 2
	for e in s.entities.duplicate():
		if e.alive and (e.is_resource() or e.is_building()) and absi(e.ty - y0) < 16 and e.tx > 4 and e.tx < 80:
			s.remove_quietly(e)
			s.map.clear(e.tx, e.ty, e.w, e.h)
	return s


func _hold() -> void:
	var s := _clear_sim()
	var y := s.map.n / 2 * 1000
	var a := s.spawn_unit("hondero", 0, 20500, y)
	var b := s.spawn_unit("guerrero", 0, 21500, y)
	# Un enemigo a la vista pero fuera del alcance de los dos.
	var foe := s.spawn_unit("lancero", 1, 26500, y)
	s.push_command({"t": "mantener", "player": 0, "ids": [a.id, b.id]})
	var ax := a.x
	var bx := b.x
	for i in 40:
		foe.order = SimEntity.Order.IDLE # quieto: no se acerca solo
		foe.x = 26500
		foe.y = y
		s.step()
	_check("mantener posición: no salen a buscar al enemigo a la vista (%d, %d milésimas)" % [absi(a.x - ax), absi(b.x - bx)], absi(a.x - ax) < 300 and absi(b.x - bx) < 300 and a.order == SimEntity.Order.HOLD)
	# El enemigo entra en el alcance del hondero: le pega sin moverse.
	foe.x = 20500 + int(a.def["alcance"]) - 300
	var hp := foe.hp
	for i in 40:
		foe.order = SimEntity.Order.IDLE
		foe.x = 20500 + int(a.def["alcance"]) - 300
		s.step()
	_check("mantener posición: pega al que entra en alcance (vida %d → %d)" % [hp, foe.hp], foe.hp < hp and absi(a.x - ax) < 300)
	s.push_command({"t": "move", "player": 0, "ids": [a.id], "x": 15000, "y": y})
	s.step()
	_check("otra orden corta mantener posición", a.order != SimEntity.Order.HOLD)


func _patrol() -> void:
	var s := _clear_sim()
	var y := s.map.n / 2 * 1000
	var u := s.spawn_unit("guerrero", 0, 20500, y)
	s.push_command({"t": "patrullar", "player": 0, "ids": [u.id], "x": 32500, "y": y})
	var far := 0
	var back := false
	for i in 400:
		s.step()
		far = maxi(far, u.x)
		if far > 31500 and u.x < 22000:
			back = true
			break
	_check("patrullar: llega a la otra punta (%d) y vuelve (%s)" % [far, back], far > 31500 and back and u.patrol)
	s.push_command({"t": "stop", "player": 0, "ids": [u.id]})
	s.step()
	_check("detener corta la patrulla", not u.patrol)


func _spread(s: Sim, ids: Array) -> Vector2i:
	# Ancho y fondo de la formación sobre los ejes x e y (rumbo 0: mira hacia +x).
	var lo := Vector2i(1 << 30, 1 << 30)
	var hi := Vector2i(-(1 << 30), -(1 << 30))
	for id in ids:
		var e: SimEntity = s.by_id[id]
		lo = Vector2i(mini(lo.x, e.x), mini(lo.y, e.y))
		hi = Vector2i(maxi(hi.x, e.x), maxi(hi.y, e.y))
	return hi - lo


func _formations() -> void:
	var sizes := {}
	for shape in ["bloque", "linea", "abierta", "columna"]:
		var s := _clear_sim()
		var y := s.map.n / 2 * 1000
		var ids := []
		for i in 16:
			ids.append(s.spawn_unit("lancero", 0, (20 + i % 4) * 1000 + 500, y - 2000 + (i / 4) * 1000).id)
		# Rumbo 0 (mirar hacia +x): el ancho de la formación queda sobre el eje y.
		s.push_command({"t": "move", "player": 0, "ids": ids, "x": 50000, "y": y, "form": shape, "rumbo": 0})
		for t in 600:
			s.step()
			if s.groups.groups.is_empty() and t > 20:
				break
		sizes[shape] = _spread(s, ids)
		print("  %-8s fondo %5d · ancho %5d (milésimas)" % [shape, sizes[shape].x, sizes[shape].y])
	var b: Vector2i = sizes["bloque"]
	var l: Vector2i = sizes["linea"]
	var c: Vector2i = sizes["columna"]
	var o: Vector2i = sizes["abierta"]
	_check("línea: más ancha y menos profunda que el bloque", l.y > b.y and l.x < b.x)
	_check("columna: más profunda y angosta que el bloque", c.x > b.x and c.y < b.y)
	_check("abierta: más separada que el bloque", o.y > b.y)
	# Rumbo 4 (mirar hacia +y): la línea queda ancha sobre el eje x.
	var s2 := _clear_sim()
	var y2 := s2.map.n / 2 * 1000
	var ids2 := []
	for i in 16:
		ids2.append(s2.spawn_unit("lancero", 0, (20 + i % 4) * 1000 + 500, y2 - 2000 + (i / 4) * 1000).id)
	s2.push_command({"t": "move", "player": 0, "ids": ids2, "x": 40000, "y": y2, "form": "linea", "rumbo": 4})
	for t in 600:
		s2.step()
		if s2.groups.groups.is_empty() and t > 20:
			break
	var r := _spread(s2, ids2)
	_check("el rumbo del arrastre gira la línea (ancho en x %d > fondo en y %d)" % [r.x, r.y], r.x > r.y)
	# Cambiar de formación en el lugar.
	s2.push_command({"t": "formar", "player": 0, "ids": ids2, "form": "columna"})
	for t in 300:
		s2.step()
		if s2.groups.groups.is_empty() and t > 20:
			break
	var r2 := _spread(s2, ids2)
	_check("formar: pasa a columna en el lugar, mirando igual (fondo en y %d > ancho en x %d)" % [r2.y, r2.x], r2.y > r2.x)


func _flare_and_ask() -> void:
	var s := Sim.new(321, 4, null, {"civs": ["tawantinsuyu", "mapuches", "guaranies", "etiopia"], "equipos": [0, 1, 0, 1], "terreno": "llano"})
	s.ais = []
	for pid in [1, 2, 3]:
		s.ais.append(SimAI.new(s, pid))
	# El aliado (2) junta ejército; el jugador 0 es "humano" y no hace nada.
	var said := {}
	var sent := false
	var ally_start := 0
	for e in s.actives:
		if e.owner == 2 and e.is_building() and e.capital:
			ally_start = e.id
	var c: SimEntity = s.by_id[ally_start]
	for i in 8:
		s.spawn_unit("guerrero", 2, c.x + 4000 + i * 600, c.y + 4000)
	s.players[2]["res"]["madera"] = 2000
	var fx := s.map.n * 1000 / 2
	var fy := s.map.n * 1000 / 2
	s.push_command({"t": "bengala", "player": 0, "x": fx, "y": fy})
	s.push_command({"t": "pedir", "player": 0, "a": 2, "recurso": "madera"})
	var wood := int(s.players[0]["res"]["madera"])
	var got := 0
	var went := {}
	var reached := {}
	# 3 minutos: las tropas tienen que llegar, no quedarse a mitad de camino (ronda 2, equipos).
	for t in 1800:
		s.step()
		for ev in s.events:
			if ev["t"] == "ia_dice":
				said["%d:%s" % [ev["player"], ev["clave"]]] = true
			if ev["t"] == "tributo" and int(ev["a"]) == 0 and ev["recurso"] == "madera":
				got += int(ev["n"])
		for e in s.actives:
			if e.alive and e.owner == 2 and e.is_military():
				if e.order == SimEntity.Order.ATTACK_MOVE and e.amove_x > 0 and Sim.dist(e.amove_x, e.amove_y, fx, fy) < 4000:
					sent = true
					went[e.id] = true
				if went.has(e.id) and Sim.dist(e.x, e.y, fx, fy) < 8000:
					reached[e.id] = true
	_check("bengala: el aliado manda tropa al punto", sent)
	_check("bengala: llegan %d de %d" % [reached.size(), went.size()], went.size() > 0 and reached.size() * 4 >= went.size() * 3)
	_check("bengala: el aliado lo dice en el chat (%s)" % str(said.keys()), said.has("2:voy_atacar") or said.has("2:voy_defender"))
	_check("pedido: el aliado manda madera (%d, banco %d → %d)" % [got, wood, int(s.players[0]["res"]["madera"])], got > 0 and said.has("2:mando"))
	_check("las bengalas vencen", s.flares.is_empty())
