extends RefCounted
## Autotest de la muralla de piedra (proceso/32-ronda-8/06), con mouse y teclado de verdad: en la
## edad II se arrastra la muralla por encima de una empalizada propia; junto al cursor dice los
## tramos, el costo en piedra, cuántos alcanzan y cuántos refuerza; G pone la puerta de piedra.
## Al soltar, la empalizada quedó reemplazada, la puerta es la de piedra y se cobró la piedra.
## Después levanta un lienzo terminado con su torre y deja screenshots/muralla.png.
## Lo llama main.gd → _autotest.


static func correr(m: Node, check: Callable) -> void:
	var sim: Sim = m.sim
	var ctrl: Controller = m.ctrl
	var cam: RtsCamera = m.cam
	var local: int = m.local
	var dd := sim.dp(local)
	var wall := ""
	for k: String in dd.unidades["aldeano"].get("construye", []):
		var d: Dictionary = dd.edificios.get(k, {})
		if d.get("linea", false) and not d.get("transitable", false) and Sim.material_of(d) == "piedra":
			wall = k
			break
	if wall == "":
		print("(muralla: este pueblo no levanta muralla de piedra; sin la prueba)")
		return
	sim.players[local]["age"] = maxi(2, int(sim.players[local]["age"]))
	var res: Dictionary = sim.players[local]["res"]
	res["piedra"] = int(res.get("piedra", 0)) + 1000
	res["madera"] = int(res.get("madera", 0)) + 500
	# Una fila de 9 casillas libres cerca de la base; las 3 del medio, de empalizada propia.
	var base = sim.bases[local]
	var fila := Vector2i(-1, -1)
	for r in range(6, 26):
		for dx in range(-r, r + 1):
			for dy: int in [-r, r]:
				var t := Vector2i(int(base.x) + dx, int(base.y) + dy)
				var ok := true
				for i in 9:
					ok = ok and sim.can_place(wall, t.x + i, t.y, local) and sim.can_place(wall, t.x + i, t.y + 4, local)
				if ok:
					fila = t
					break
			if fila.x >= 0:
				break
		if fila.x >= 0:
			break
	check.call("muralla: hay una fila libre (%s)" % str(fila), fila.x >= 0)
	if fila.x < 0:
		return
	var palo := ""
	for k: String in (dd.edificios[wall].get("sobre", []) as Array):
		if dd.edificios.has(k):
			palo = k
	for i in range(3, 6):
		if palo != "":
			sim.spawn_building(palo, local, fila.x + i, fila.y, true)
	var vs: Array[int] = m._vill_ids()
	ctrl.select_ids([vs[4]] as Array[int])
	await m._frames(2)
	ctrl.run_command({"kind": "build", "id": wall, "cost": sim.build_cost(local, wall)})
	cam.look_at_point(Vector3(fila.x + 4.5, 0, fila.y + 0.5))
	await m._frames(4)
	var a: Vector2 = m._screen(fila.x + 0.5, fila.y + 0.5)
	var b: Vector2 = m._screen(fila.x + 8.5, fila.y + 0.5)
	m._mouse(a, 0, false)
	await m._frames(2)
	m._mouse(a, MOUSE_BUTTON_LEFT, true)
	await m._frames(2)
	m._mouse(b, 0, false)
	await m._frames(3)
	m._mouse(m._screen(fila.x + 1.5, fila.y + 0.5), 0, false)
	await m._frames(2)
	m._key_tap(KEY_G)
	await m._frames(2)
	m._mouse(b, 0, false)
	await m._frames(4)
	var info := ""
	for l: Array in ctrl.linea_info:
		info += String(l[0]) + " / "
	var costo: Dictionary = sim.build_cost(local, wall)
	check.call("muralla: el trazo dice tramos, costo en piedra y cuántos alcanzan (%s)" % info, info.contains("tramos") and info.contains("alcanzan") and info.contains("piedra"))
	if palo != "":
		check.call("muralla: avisa que refuerza la empalizada (%s)" % info, info.contains("Refuerza 3"))
	var gate := String(dd.edificios[wall].get("su_puerta", ""))
	check.call("muralla: G marca la puerta de piedra (%s)" % str(ctrl._line_gate), ctrl._line_gate == Vector2i(fila.x + 1, fila.y))
	m.get_viewport().get_texture().get_image().save_png("screenshots/muralla_trazo.png")
	var piedra0 := int(res["piedra"])
	m._mouse(b, MOUSE_BUTTON_LEFT, false)
	var t0: int = sim.tick
	for i in 60:
		if sim.tick >= t0 + 2:
			break
		await m._frames(1)
	var tramos := 0
	for i in 9:
		var e: SimEntity = sim.by_id.get(sim.map.occupant(fila.x + i, fila.y))
		if e != null and e.alive and e.type == wall:
			tramos += 1
	check.call("muralla: quedaron 8 tramos de piedra, también encima de la empalizada (%d)" % tramos, tramos == 8)
	var pu: SimEntity = sim.by_id.get(sim.map.occupant(fila.x + 1, fila.y))
	check.call("muralla: la puerta es la de piedra (%s)" % (pu.type if pu != null else "nada"), pu != null and pu.type == gate)
	var pagado := piedra0 - int(res["piedra"])
	var esperado := 8 * int(costo.get("piedra", 0)) + int(sim.build_cost(local, gate).get("piedra", 0))
	check.call("muralla: cobró la piedra de 8 tramos y la puerta (%d de %d)" % [pagado, esperado], pagado == esperado)
	ctrl.cancel_mode()
	# Lienzo terminado con la puerta y una torre encima, para la captura.
	var tower := ""
	for k: String in dd.unidades["aldeano"].get("construye", []):
		if dd.edificios.get(k, {}).get("solo_sobre", false):
			tower = k
	for i in 9:
		sim.spawn_building(gate if i == 4 else wall, local, fila.x + i, fila.y + 4, true)
	if tower != "":
		check.call("muralla: la torre va sobre un tramo propio y no en el suelo", sim.can_place(tower, fila.x + 7, fila.y + 4, local) and not sim.can_place(tower, fila.x + 7, fila.y + 6, local))
		sim.push_command({"t": "build", "player": local, "ids": [], "type": tower, "tx": fila.x + 7, "ty": fila.y + 4})
		t0 = sim.tick
		for i in 60:
			if sim.tick >= t0 + 2:
				break
			await m._frames(1)
		var tw: SimEntity = sim.by_id.get(sim.map.occupant(fila.x + 7, fila.y + 4))
		check.call("muralla: la torre quedó encima del tramo (%s)" % (tw.type if tw != null else "nada"), tw != null and tw.type == tower)
		if tw != null and not tw.built:
			tw.progress = tw.build_time
			tw.hp = tw.hp_max
			sim._complete(tw)
	cam.look_at_point(Vector3(fila.x + 4.5, 0, fila.y + 2.5))
	await m._frames(8)
	m.get_viewport().get_texture().get_image().save_png("screenshots/muralla.png")
