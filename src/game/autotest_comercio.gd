extends RefCounted
## --- comercio --- Autotest de las rutas (proceso/33-comercio, §3 y §4), con eventos reales:
## Mayús + clic derecho en el suelo marca el punto de paso; clic derecho en el mercado neutral
## abre la ruta por ese punto; con el cursor sobre el neutral, la ganancia esperada junto al
## cursor; el botón «Rutas» del minimapa; el aviso «Atacan a tus comerciantes» uno por ruta.
## Deja screenshots/comercio_ruta.png. Lo llama main.gd → _autotest.

const P := 1000


static func _tecla(code: int, on: bool) -> void:
	var k := InputEventKey.new()
	k.physical_keycode = code
	k.keycode = code
	k.pressed = on
	k.shift_pressed = on and code == KEY_SHIFT
	Input.parse_input_event(k)


static func _hasta(m: Node, cond: Callable, max: int = 240) -> bool:
	for i in max:
		if cond.call():
			return true
		await m._frames(1)
	return cond.call()


static func correr(m: Node, check: Callable) -> void:
	var sim: Sim = m.sim
	var ctrl = m.ctrl
	var local: int = m.local
	m.speed = 1.0
	sim.players[local]["age"] = 4
	var base: Vector2i = sim.bases[local]
	var neu: SimEntity = null
	var bd := 1 << 30
	for n in sim.comercio.neutrals:
		var d := Sim.dist(n.x, n.y, base.x * P, base.y * P)
		if d < bd:
			bd = d
			neu = n
	check.call("hay %d mercados neutrales en el mapa" % sim.comercio.neutrals.size(), sim.comercio.neutrals.size() >= 2)
	if neu == null:
		return
	# Mercado propio y dos comerciantes, hacia el neutral.
	var home: SimEntity = null
	var dir := Vector2i(signi(neu.tx - base.x), signi(neu.ty - base.y))
	var c0 := base + Vector2i(2, 2) + dir * 9
	for r in 14:
		for dy in range(-r, r + 1):
			for dx in range(-r, r + 1):
				var t := c0 + Vector2i(dx, dy)
				if home == null and maxi(absi(dx), absi(dy)) == r and sim.map.is_free_rect(t.x - 1, t.y - 1, 5, 5) and not sim.map.is_water(t.x, t.y):
					home = sim.spawn_building("mercado", local, t.x, t.y, true)
	check.call("mercado propio puesto", home != null)
	if home == null:
		return
	var ids: Array[int] = []
	for i in 2:
		var ft := sim.map.nearest_free(home.tx + 1 + i, home.ty + 4, 5, local)
		ids.append(sim.spawn_unit("comerciante", local, ft.x * P + P / 2, ft.y * P + P / 2).id)
	await m._frames(3)
	ctrl.select_ids(ids)
	# Punto de paso: a mitad de camino, corrido de costado.
	var mid := Vector2((home.x + neu.x) / 2.0 / P, (home.y + neu.y) / 2.0 / P) + Vector2(dir.y, -dir.x) * 8.0
	m.cam.look_at_point(Vector3(mid.x, 0, mid.y))
	await m._frames(4)
	_tecla(KEY_SHIFT, true)
	await m._frames(1)
	await m._click(m._suelo_libre(mid.x, mid.y), MOUSE_BUTTON_RIGHT)
	_tecla(KEY_SHIFT, false)
	check.call("Mayús + clic derecho en el suelo: punto de paso marcado (%s)" % str(ctrl.ruta_paso), ctrl.ruta_paso.x >= 0)
	var wp: Vector2i = ctrl.ruta_paso
	# Clic derecho en el neutral: ruta por el punto de paso.
	m.cam.look_at_point(Vector3(neu.x / float(P), 0, neu.y / float(P)))
	await m._frames(4)
	var nsp: Vector2 = m._screen(neu.x / float(P), neu.y / float(P))
	m._mouse(nsp, 0, false)
	await m._frames(3)
	var tip: Array = m.hud._mundo._tip_lines
	var tip_txt := ""
	for l in tip:
		tip_txt += String(l[0]) + " / "
	check.call("cursor sobre el neutral: ganancia esperada junto al cursor (%s)" % tip_txt, tip_txt.contains("por viaje") and tip_txt.contains("por minuto"))
	await m._click(nsp, MOUSE_BUTTON_RIGHT)
	var u: SimEntity = sim.by_id[ids[0]]
	await _hasta(m, func() -> bool: return u.order == SimEntity.Order.TRADE, 120)
	check.call("clic derecho en el neutral: ruta abierta (orden %d, destino %d)" % [u.order, u.trade_dest], u.order == SimEntity.Order.TRADE and u.trade_dest == neu.id and u.trade_home == home.id)
	check.call("la ruta pasa por el punto de paso (%d, %d)" % [u.trade_wx, u.trade_wy], u.trade_wx == wp.x and u.trade_wy == wp.y)
	# Minimapa: botón «Rutas».
	var mini = m.hud._mini
	var chip := Rect2()
	for c in mini._chips:
		if c[1] == "rutas":
			chip = c[0]
	check.call("el minimapa tiene el botón «Rutas»", chip.size.x > 0)
	if chip.size.x > 0:
		await m._click(mini.global_position + chip.get_center())
		check.call("clic en «Rutas»: se ven todas las rutas", bool(mini.filtros.get("rutas", false)))
	# Que avance y las capturas con la ruta seleccionada: en el punto de paso y en el neutral.
	m.speed = 8.0
	await _hasta(m, func() -> bool: return u.trade_wpd or not u.alive, 600)
	m.speed = 1.0
	ctrl.select_ids(ids)
	m.cam.look_at_point(Vector3(mid.x, 0, mid.y))
	await m._frames(8)
	m.get_viewport().get_texture().get_image().save_png("screenshots/comercio_ruta.png")
	m.speed = 16.0
	var cargo := await _hasta(m, func() -> bool: return u.trade_gain > 0 or not u.alive, 1500)
	m.speed = 1.0
	check.call("el comerciante carga en el neutral (%d de riqueza)" % u.trade_gain, cargo and u.trade_gain > 0)
	ctrl.select_ids(ids)
	m.cam.look_at_point(Vector3(neu.x / float(P), 0, neu.y / float(P)))
	await m._frames(10)
	m.get_viewport().get_texture().get_image().save_png("screenshots/comercio_neutral.png")
	# Aviso: uno por ruta cada 30 s.
	var al = m.hud.alertas
	var a1: bool = al.atacado("comerciantes", u)
	var a2: bool = al.atacado("comerciantes", sim.by_id[ids[1]])
	check.call("«Atacan a tus comerciantes»: avisa una vez por ruta (%s, %s)" % [a1, a2], a1 and not a2)
	if chip.size.x > 0:
		mini.filtrar("rutas", false)
