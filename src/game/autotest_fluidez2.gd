extends RefCounted
## Autotest del constructor (proceso/30-fluidez, frente 2), con mouse y teclado de verdad: tres
## casas con Mayús que se terminan en el orden puesto, el muro con un árbol en el medio que avisa
## el hueco (con su costo y la puerta en el trazo), la granja que se pega al depósito, la huella
## fantasma que reconstruye y «Reparar (zona)». Deja screenshots/fluidez2_muro.png.
## Lo llama main.gd → _autotest.

const MundoColocacion := preload("res://src/game/ui/mundo_colocacion.gd")


static func _shift(m: Node, on: bool) -> void:
	var k := InputEventKey.new()
	k.physical_keycode = KEY_SHIFT
	k.keycode = KEY_SHIFT
	k.pressed = on
	Input.parse_input_event(k)


static func _libre(sim: Sim, local: int, type: String, cx: int, cy: int, usadas: Array) -> Vector2i:
	for r in range(0, 6):
		for dy in range(-r, r + 1):
			for dx in range(-r, r + 1):
				var t := Vector2i(cx + dx, cy + dy)
				var lejos := true
				for u: Vector2i in usadas:
					lejos = lejos and maxi(absi(u.x - t.x), absi(u.y - t.y)) >= 4
				if lejos and sim.can_place(type, t.x, t.y, local):
					return t
	return Vector2i(-1, -1)


## 2. El muro (los pueblos sin muros, como el Tawantinsuyu, no la corren).
static func _muro(m: Node, check: Callable, muro: String) -> SimEntity:
	var sim: Sim = m.sim
	var ctrl: Controller = m.ctrl
	var cam: RtsCamera = m.cam
	var local: int = m.local
	var base = sim.bases[local]
	var vs: Array[int] = m._vill_ids()
	var arbol: SimEntity = null
	var best := 1 << 60
	for e in sim.entities:
		if not e.alive or not e.is_resource() or e.res_kind != "madera" or e.w != 1 or e.h != 1:
			continue
		var ok := true
		for dx in [-3, -2, -1, 1, 2, 3]:
			ok = ok and sim.can_place(muro, e.tx + dx, e.ty, local)
		var d := Sim.dist(e.x, e.y, int(base.x) * 1000, int(base.y) * 1000)
		if ok and d < best:
			arbol = e
			best = d
	check.call("fluidez 2: hay un árbol suelto para el muro", arbol != null)
	if arbol == null:
		return null
	ctrl.select_ids([vs[3]] as Array[int])
	await m._frames(2)
	ctrl.run_command({"kind": "build", "id": muro, "cost": sim.build_cost(local, muro)})
	cam.look_at_point(Vector3(arbol.tx + 0.5, 0, arbol.ty + 0.5))
	await m._frames(4)
	var a: Vector2 = m._screen(arbol.tx - 3 + 0.5, arbol.ty + 0.5)
	var b2: Vector2 = m._screen(arbol.tx + 3 + 0.5, arbol.ty + 0.5)
	m._mouse(a, 0, false)
	await m._frames(2)
	m._mouse(a, MOUSE_BUTTON_LEFT, true)
	await m._frames(2)
	m._mouse(b2, 0, false)
	await m._frames(3)
	var puerta_sp: Vector2 = m._screen(arbol.tx + 2 + 0.5, arbol.ty + 0.5)
	m._mouse(puerta_sp, 0, false)
	await m._frames(2)
	m._key_tap(Teclas.tecla("puerta_muro"))
	await m._frames(2)
	m._mouse(b2, 0, false)
	await m._frames(4)
	var info: String = ctrl.linea_info[0][0] if not ctrl.linea_info.is_empty() else ""
	# El costo en el recurso del muro de ese pueblo (madera la empalizada; el Tawantinsuyu ahora levanta uno de piedra).
	var con_costo := false
	for r: String in (sim.build_cost(local, muro) as Dictionary).keys():
		con_costo = con_costo or info.contains(r)
	check.call("fluidez 2: el muro dice tramos, costo y cuántos alcanzan (%s)" % info, info.contains("tramos") and info.contains("alcanzan") and con_costo)
	var info2: String = ctrl.linea_info[1][0] if ctrl.linea_info.size() > 1 else ""
	check.call("fluidez 2: el trazo avisa el hueco antes de soltar (%s)" % info2, info2.contains("hueco") and info2.contains("árboles"))
	check.call("fluidez 2: G marca la puerta en el trazo (%s)" % str(ctrl._line_gate), ctrl._line_gate == Vector2i(arbol.tx + 2, arbol.ty))
	m.get_viewport().get_texture().get_image().save_png("screenshots/fluidez2_muro.png")
	m._mouse(b2, MOUSE_BUTTON_LEFT, false)
	await m._frames(4)
	check.call("fluidez 2: el hueco queda marcado (%s)" % str(ctrl.huecos), ctrl.huecos.size() == 1 and ctrl.huecos[0][0] == arbol.tx)
	var aviso := ""
	for av in m.hud.avisos.lista:
		aviso += String(av["texto"]) + " / "
	check.call("fluidez 2: aviso del hueco al soltar (%s)" % aviso, aviso.contains("hueco"))
	await m._frames(6)
	var pu: SimEntity = sim.by_id.get(sim.map.occupant(arbol.tx + 2, arbol.ty))
	check.call("fluidez 2: la puerta quedó en el trazo (%s)" % (pu.type if pu != null else "nada"), pu != null and pu.def.get("puerta", false))
	var pm: SimEntity = sim.by_id.get(sim.map.occupant(arbol.tx - 3, arbol.ty))
	check.call("fluidez 2: el resto del muro quedó puesto", pm != null and pm.type == muro)
	ctrl.cancel_mode()
	return arbol


static func correr(m: Node, check: Callable) -> void:
	var sim: Sim = m.sim
	var ctrl: Controller = m.ctrl
	var cam: RtsCamera = m.cam
	var local: int = m.local
	var base = sim.bases[local]
	var res: Dictionary = sim.players[local]["res"]
	for k in ["madera", "piedra", "alimento", "riqueza"]:
		res[k] = int(res.get(k, 0)) + 2000
	var vs: Array[int] = m._vill_ids()
	var dd := sim.dp(local)

	# 1. Tres casas con Mayús: se terminan en el orden en que se pusieron (y la lejana no queda sola).
	var casa := ""
	for k in dd.unidades["aldeano"].get("construye", []):
		var d: Dictionary = dd.edificios.get(k, {})
		if d.has("pob") and int(d.get("edad_min", 1)) <= 1 and not d.has("deposito") and not d.has("produce"):
			casa = k
			break
	var tam: Array = dd.edificios[casa]["tam"]
	var lugares: Array = []
	for off: Vector2i in [Vector2i(11, 2), Vector2i(2, 8), Vector2i(-9, 1)]:
		var t := _libre(sim, local, casa, int(base.x) + off.x, int(base.y) + off.y, lugares)
		lugares.append(t)
	check.call("fluidez 2: hay lugar para tres casas (%s)" % str(lugares), lugares.all(func(t: Vector2i) -> bool: return t.x >= 0))
	var tres: Array[int] = [vs[0], vs[1], vs[2]]
	ctrl.select_ids(tres)
	ctrl.open_submenu(Grilla.ECONOMIA)
	await m._frames(2)
	ctrl.run_command({"kind": "build", "id": casa, "cost": sim.build_cost(local, casa)})
	cam.look_at_point(Vector3(base.x + 1, 0, base.y + 4))
	await m._frames(3)
	_shift(m, true)
	for t: Vector2i in lugares:
		# La cámara sobre cada lugar, como haría el jugador: con el giro que dejan las pruebas de
		# antes, una casa caía en el borde de la pantalla, debajo del panel, y el clic no llegaba.
		cam.look_at_point(Vector3(t.x + tam[0] / 2.0, 0, t.y + tam[1] / 2.0))
		await m._frames(2)
		var sp: Vector2 = m._screen(t.x + tam[0] / 2.0, t.y + tam[1] / 2.0)
		m._mouse(sp, 0, false)
		await m._frames(2)
		m._mouse(sp, MOUSE_BUTTON_LEFT, true)
		m._mouse(sp, MOUSE_BUTTON_LEFT, false)
		await m._frames(2)
	_shift(m, false)
	ctrl.cancel_mode()
	# El último cimiento sale en el próximo paso de la simulación, que no siempre cae dentro de
	# unos pocos cuadros: se esperan dos pasos.
	var t_casas: int = sim.tick
	for i in 60:
		if sim.tick >= t_casas + 2:
			break
		await m._frames(1)
	var casas: Array = []
	for t: Vector2i in lugares:
		casas.append(sim.by_id.get(sim.map.occupant(t.x, t.y)))
	check.call("fluidez 2: los tres cimientos están puestos", casas.all(func(b) -> bool: return b != null and b.type == casa))
	var en_cola: int = (ctrl.cola.colas.get(vs[0], []) as Array).size()
	check.call("fluidez 2: dos obras en la cola del aldeano (%d)" % en_cola, en_cola == 2)
	var orden: Array = []
	m.speed = 8.0
	for i in 2400:
		await m._frames(1)
		for b in casas:
			if b != null and b.built and not orden.has(b.id):
				orden.append(b.id)
		if orden.size() == 3:
			break
	m.speed = 1.0
	var puesto: Array = casas.map(func(b) -> int: return b.id if b != null else -1)
	check.call("fluidez 2: las tres casas se terminan en el orden puesto (%s, puestas %s)" % [str(orden), str(puesto)], orden == puesto)

	# 2. Empalizada arrastrada con un árbol en el medio: cifras junto al cursor, puerta con G y
	#    el hueco avisado y marcado.
	var muro := ""
	for k in dd.edificios:
		# Un muro: el camino del Tawantinsuyu también es `linea`, pero no lleva puerta.
		if dd.edificios[k].get("linea", false) and not dd.edificios[k].get("transitable", false) and (dd.unidades["aldeano"].get("construye", []) as Array).has(k) and int(dd.edificios[k].get("edad_min", 1)) <= int(sim.players[local]["age"]):
			muro = k
			break
	var arbol: SimEntity = null
	if muro != "":
		arbol = await _muro(m, check, muro)
	else:
		print("(fluidez 2: este pueblo no levanta muros; sin la prueba del muro)")
		var best := 1 << 60
		for e in sim.entities:
			if e.alive and e.is_resource() and e.res_kind == "madera" and Sim.dist(e.x, e.y, int(base.x) * 1000, int(base.y) * 1000) < best:
				arbol = e
				best = Sim.dist(e.x, e.y, int(base.x) * 1000, int(base.y) * 1000)

	# 3. Granja que se pega al depósito de alimento, con «x de 8 libres».
	var granja := ""
	for k in dd.unidades["aldeano"].get("construye", []):
		if String(dd.edificios.get(k, {}).get("fuente", "")) != "" and int(dd.edificios[k].get("edad_min", 1)) <= int(sim.players[local]["age"]):
			granja = k
			break
	var dep: SimEntity = null
	for e in sim.actives:
		if e.alive and e.owner == local and e.is_building() and e.built and (e.def.get("deposito", []) as Array).has("alimento"):
			dep = e
			break
	if granja != "" and dep != null:
		var gt: Array = dd.edificios[granja]["tam"]
		var slot := Vector2i(-1, -1)
		for l: Vector2i in MundoColocacion.ocho_lugares(dep.tx, dep.ty, dep.w, dep.h, gt[0], gt[1]):
			if sim.can_place(granja, l.x, l.y, local):
				slot = l
				break
		check.call("fluidez 2: hay un lugar para la granja junto a %s" % dep.type, slot.x >= 0)
		if slot.x >= 0:
			ctrl.select_ids([vs[4]] as Array[int])
			await m._frames(2)
			ctrl.run_command({"kind": "build", "id": granja, "cost": sim.build_cost(local, granja)})
			cam.look_at_point(Vector3(dep.tx, 0, dep.ty))
			await m._frames(3)
			# El cursor una casilla afuera del lugar (alejado del depósito): la granja se corre y se pega.
			var away := Vector2i(signi(slot.x - dep.tx), signi(slot.y - dep.ty))
			m._mouse(m._screen(slot.x + away.x + gt[0] / 2.0, slot.y + away.y + gt[1] / 2.0), 0, false)
			await m._frames(4)
			var gtile: Vector2i = ctrl._ghost.get_meta("tile", Vector2i(-1, -1))
			check.call("fluidez 2: la granja se pega al depósito (%s → %s)" % [str(slot + away), str(gtile)], gtile == slot)
			var tip := ""
			for l in MundoColocacion.detalles(sim, local, granja, gtile.x, gtile.y):
				tip += String(l[0]) + " / "
			check.call("fluidez 2: la granja dice los lugares libres (%s)" % tip, tip.contains("de 8 lugares libres") and tip.contains("Pegada"))
			ctrl.cancel_mode()
	# El almacén informa los recursos cerca y la distancia al depósito.
	var almacen := ""
	for k in dd.unidades["aldeano"].get("construye", []):
		var d2: Dictionary = dd.edificios.get(k, {})
		if (d2.get("deposito", []) as Array).has("madera") and not d2.get("hito", false) and not d2.has("produce"):
			almacen = k
			break
	if almacen != "" and arbol != null:
		var al := ""
		for l in MundoColocacion.detalles(sim, local, almacen, arbol.tx + 1, arbol.ty + 2):
			al += String(l[0]) + " / "
		check.call("fluidez 2: el almacén dice qué hay cerca y el depósito (%s)" % al, al.contains("árboles") and al.contains("depósito más cercano"))

	# 4. Huella fantasma: una casa propia que tira el rival deja su huella; clic derecho de un
	#    aldeano y el cimiento vuelve a estar.
	var rival: SimEntity = null
	for e in sim.actives:
		if e.alive and e.owner >= 0 and e.owner != local and sim.hostile(local, e):
			rival = e
			break
	var ht := _libre(sim, local, casa, int(base.x) - 2, int(base.y) + 10, lugares)
	if rival != null and ht.x >= 0:
		var hb := sim.spawn_building(casa, local, ht.x, ht.y, true)
		var n0 := sim.events.size()
		sim._kill(hb, rival)
		m.hud.on_events(sim.events.slice(n0))
		check.call("fluidez 2: queda la huella de la casa", ctrl.cola.huellas.size() >= 1)
		ctrl.select_ids([vs[5]] as Array[int])
		cam.look_at_point(Vector3(ht.x + 1, 0, ht.y + 1))
		await m._frames(6) # que la simulación limpie la casa caída
		var hp: Vector2 = m._screen(ht.x + tam[0] / 2.0, ht.y + tam[1] / 2.0)
		m._mouse(hp, 0, false)
		await m._frames(2)
		check.call("fluidez 2: sobre la huella, el cursor es de construir (%s)" % ctrl.cursor_action(hp), ctrl.cursor_action(hp) == "construir")
		m._mouse(hp, MOUSE_BUTTON_RIGHT, true)
		m._mouse(hp, MOUSE_BUTTON_RIGHT, false)
		await m._frames(30)
		var nb: SimEntity = sim.by_id.get(sim.map.occupant(ht.x, ht.y))
		check.call("fluidez 2: la huella reconstruye el cimiento", nb != null and nb.type == casa and not nb.built)
		check.call("fluidez 2: el aldeano va a levantarlo", nb != null and (sim.by_id[vs[5]] as SimEntity).target == nb.id)
	else:
		check.call("fluidez 2: hay un rival y lugar para la huella", false)

	# 5. «Reparar (zona)»: los aldeanos van a lo dañado cerca y siguen en cadena.
	var dan: Array = []
	for b in casas:
		if b != null and b.alive and b.built:
			b.hp = maxi(1, b.hp - b.hp_max / 2)
			dan.append(b.id)
	var cerca: Array[int] = [vs[0], vs[1]]
	ctrl.select_ids(cerca)
	await m._frames(2)
	var rz := Controller.cmd_at(ctrl.commands(), Grilla.fija("reparar_zona", 6))
	check.call("fluidez 2: botón «Reparar (zona)» en la grilla (%s)" % rz.get("locked", "?"), rz.get("id", "") == "reparar_zona" and rz.get("locked", "x") == "")
	ctrl.run_command(rz)
	await m._frames(30)
	var t0: int = (sim.by_id[vs[0]] as SimEntity).target
	check.call("fluidez 2: reparar (zona) los manda a lo dañado (%d en %s)" % [t0, str(dan)], dan.has(t0))
	ctrl.select_ids([] as Array[int])
	await m._frames(2)
