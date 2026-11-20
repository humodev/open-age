extends RefCounted
## Autotest de selección, órdenes y lectura (proceso/30-fluidez, frente 5), con eventos reales:
## Ctrl + clic elige a todos los de ese tipo en pantalla; patrulla de 3 puntos con Mayús; clic
## derecho sobre una unidad propia la escolta; Mayús + mantener entra en la cola; números de
## daño apagados en el perfil «aoe4»; ficha compacta; hoja de atajos sin «girar»; fondo por
## función en los retratos. Deja screenshots/fluidez5_retratos.png. Lo llama main.gd → _autotest.

const P := 1000


static func _tecla(code: int, on: bool) -> void:
	var k := InputEventKey.new()
	k.physical_keycode = code
	k.keycode = code
	k.pressed = on
	k.shift_pressed = on and code == KEY_SHIFT
	k.ctrl_pressed = on and code == KEY_CTRL
	Input.parse_input_event(k)


static func _clic(m: Node, sp: Vector2, button: int = MOUSE_BUTTON_LEFT) -> void:
	m._mouse(sp, button, true)
	await m._frames(1)
	m._mouse(sp, button, false)
	await m._frames(2)


static func _hasta(m: Node, cond: Callable, max: int = 300) -> bool:
	for i in max:
		if cond.call():
			return true
		await m._frames(1)
	return cond.call()


## Punto de pantalla de suelo libre y alcanzable cerca de la casilla (cx, cy), con la cámara
## centrada ahí: como main._suelo_libre (mapa libre, nada que el cursor tome, fuera de la interfaz)
## y, además, con camino desde `desde`. Con mapuches, un punto fijo de la ronda caía bajo la
## interfaz y el clic no entraba (proceso/30-fluidez/09-autotest-y-red.md).
static func _suelo(m: Node, cx: float, cy: float, desde: Vector2i) -> Vector2:
	m.cam.look_at_point(Vector3(cx, 0, cy))
	await m._frames(2)
	var mapa: SimMap = m.sim.map
	for r in range(0, 8):
		for dy in range(-r, r + 1):
			for dx in range(-r, r + 1):
				if maxi(absi(dx), absi(dy)) != r:
					continue
				var t := Vector2i(int(cx) + dx, int(cy) + dy)
				var sp: Vector2 = m._screen(t.x + 0.5, t.y + 0.5)
				if not mapa.is_free_rect(t.x - 1, t.y - 1, 3, 3) or m.ctrl.pick(sp) >= 0 or m.ctrl._over_hud(sp):
					continue
				# El A* de la grilla, sin el caché de find_path (no toca el estado de la simulación).
				var cam_: Array[Vector2i] = mapa._grid(m.local).get_id_path(desde, t, true)
				if not cam_.is_empty() and cam_[cam_.size() - 1] == t:
					return sp
	return m._suelo_libre(cx, cy)


## Primer tipo de unidad del pueblo con esa función en la edad I.
static func _tipo(sim: Sim, local: int, fn: String) -> String:
	var dd := sim.dp(local)
	var keys: Array = dd.unidades.keys()
	keys.sort()
	for k in keys:
		var d: Dictionary = dd.unidades[k]
		if str(d.get("funcion", "")) == fn and int(d.get("edad_min", 1)) <= 1 and not d.get("navega", false):
			return k
	return ""


static func correr(m: Node, check0: Callable) -> void:
	var check := func(n: String, c: bool) -> void:
		print(("OK    " if c else "FALLO ") + n)
		check0.call(n, c)
	var sim: Sim = m.sim
	var ctrl: Controller = m.ctrl
	var cam: RtsCamera = m.cam
	var hud = m.hud
	var local: int = m.local
	var base = sim.bases[local]
	m.speed = 1.0
	var choque := _tipo(sim, local, "choque")
	var otro := _tipo(sim, local, "distancia")
	if otro == "":
		otro = _tipo(sim, local, "linea")
	if choque == "" or otro == "":
		check.call("fluidez 5: tipos de tropa para la prueba (%s, %s)" % [choque, otro], false)
		return
	# Tropa en un lugar libre al lado de la base.
	var cx := float(base.x) - 6.0
	var cy := float(base.y) + 9.0
	cam.look_at_point(Vector3(cx, 0, cy))
	await m._frames(4)
	var ga: Array[int] = []
	for i in 4:
		var sp: Vector2 = m._suelo_libre(cx + (i % 2) * 2.0, cy + (i / 2) * 2.0)
		var g := cam.ground_at(sp)
		ga.append(sim.spawn_unit(choque, local, int(g.x * P), int(g.z * P)).id)
	var sp2: Vector2 = m._suelo_libre(cx + 5.0, cy + 1.0)
	var g2 := cam.ground_at(sp2)
	var escolta: SimEntity = sim.spawn_unit(otro, local, int(g2.x * P), int(g2.z * P))
	ctrl.select_ids([] as Array[int])
	await m._frames(10)

	# 1. Ctrl + clic en uno: quedan todos los de su tipo que se ven.
	var g0: SimEntity = sim.by_id[ga[0]]
	var sp0 := cam.cam.unproject_position(WorldView.to_world(g0.x, g0.y, 0.4))
	_tecla(KEY_CTRL, true)
	await m._frames(1)
	await _clic(m, sp0)
	_tecla(KEY_CTRL, false)
	await m._frames(3)
	var todos_tipo := ctrl.selection.size() >= 4
	for id in ctrl.selection:
		todos_tipo = todos_tipo and (sim.by_id[id] as SimEntity).type == choque
	check.call("fluidez 5: Ctrl + clic elige a los %d %s en pantalla" % [ctrl.selection.size(), choque], todos_tipo and ctrl.selection.has(ga[3]))

	# 2. Patrulla de 3 puntos: modo patrullar y tres clics con Mayús.
	ctrl.select_ids(ga)
	await m._frames(3)
	ctrl.run_command({"kind": "patrol"})
	_tecla(KEY_SHIFT, true)
	await m._frames(1)
	# Cada punto, con la cámara encima (como el jugador) y en suelo libre y alcanzable.
	var g_0: SimEntity = sim.by_id[ga[0]]
	var desde := Vector2i(g_0.x / P, g_0.y / P)
	var sp_ult := Vector2.ZERO
	for q: Vector2 in [Vector2(cx + 10.0, cy), Vector2(cx + 10.0, cy + 8.0), Vector2(cx, cy + 8.0)]:
		sp_ult = await _suelo(m, q.x, q.y, desde)
		await _clic(m, sp_ult)
	var sigue: bool = ctrl.mode == "patrol"
	_tecla(KEY_SHIFT, false)
	await m._frames(1)
	await _clic(m, sp_ult, MOUSE_BUTTON_RIGHT) # sale del modo
	var ronda := await _hasta(m, func() -> bool: return (sim.by_id[ga[0]] as SimEntity).pat_pts.size() == 4, 60)
	check.call("fluidez 5: patrulla de 3 puntos con Mayús (sigue en el modo: %s, ronda de %d)" % [sigue, (sim.by_id[ga[0]] as SimEntity).pat_pts.size()], sigue and ronda and (sim.by_id[ga[0]] as SimEntity).patrol and ctrl.mode == "")

	# 3. Escolta: el otro elegido y clic derecho sobre uno de la patrulla.
	ctrl.select_ids([escolta.id] as Array[int])
	await m._frames(3)
	# El líder: uno de la patrulla que el cursor tome a él y no a otro (van juntos y se tapan).
	var lider: SimEntity = sim.by_id[ga[1]]
	var spl := Vector2.ZERO
	for k in 30:
		var cand: SimEntity = sim.by_id[ga[(1 + k) % ga.size()]]
		cam.look_at_point(WorldView.to_world(cand.x, cand.y))
		await m._frames(1)
		spl = cam.cam.unproject_position(WorldView.to_world(cand.x, cand.y, 0.4))
		if ctrl.pick(spl, true) == cand.id and not ctrl._over_hud(spl):
			lider = cand
			break
		await m._frames(2)
	await _clic(m, spl, MOUSE_BUTTON_RIGHT)
	var sigue_lider := await _hasta(m, func() -> bool: return escolta.order == SimEntity.Order.FOLLOW and escolta.esc == lider.id, 60)
	check.call("fluidez 5: clic derecho en una unidad propia la escolta (orden %d, sigue a %d)" % [escolta.order, escolta.esc], sigue_lider)
	# Espera en ticks de la simulación, no en cuadros: con la máquina cargada 90 cuadros no alcanzan.
	await _hasta(m, func() -> bool: return Sim.dist(escolta.x, escolta.y, lider.x, lider.y) <= 4000, 600)
	var d := Sim.dist(escolta.x, escolta.y, lider.x, lider.y)
	check.call("fluidez 5: el escolta va con la patrulla (a %d)" % d, d <= 4000 and escolta.order == SimEntity.Order.FOLLOW)
	m.get_viewport().get_texture().get_image().save_png("screenshots/fluidez5_escolta.png")

	# 4. Mayús + mantener: después del movimiento, no en lugar de él.
	var g3: SimEntity = sim.by_id[ga[3]]
	ctrl.select_ids([g3.id] as Array[int])
	await m._frames(2)
	var dest := WorldView.to_world(g3.x, g3.y) + Vector3(3, 0, 0)
	sim.push_command({"t": "move", "player": local, "ids": [g3.id], "x": int(dest.x * P), "y": int(dest.z * P)})
	await _hasta(m, func() -> bool: return g3.order == SimEntity.Order.MOVE, 60) # la orden ya llegó
	_tecla(KEY_SHIFT, true)
	await m._frames(1) # el evento de la tecla se procesa en el cuadro siguiente
	ctrl.run_command({"kind": "hold"})
	_tecla(KEY_SHIFT, false)
	await m._frames(2)
	var en_cola: bool = g3.order == SimEntity.Order.MOVE and ctrl.cola.colas.has(g3.id)
	var mantiene := await _hasta(m, func() -> bool: return g3.order == SimEntity.Order.HOLD, 400)
	check.call("fluidez 5: Mayús + mantener entra en la cola (en cola: %s, después mantiene: %s)" % [en_cola, mantiene], en_cola and mantiene)

	# 5. Números de daño: el perfil «aoe4» los apaga; el de fábrica los prende.
	var mapa: Dictionary = Teclas.mapa.duplicate()
	var excl := Teclas.grupos_exclusivos
	var nd := Teclas.numeros_danio
	Teclas.perfil("aoe4")
	var aoe4 := Teclas.numeros_danio
	Teclas.perfil("fabrica")
	var fab := Teclas.numeros_danio
	Teclas.mapa = mapa
	Teclas._reindexar()
	Teclas.grupos_exclusivos = excl
	Teclas.numeros_danio = nd
	check.call("fluidez 5: números de daño apagados en «aoe4» (%s) y prendidos de fábrica (%s)" % [aoe4, fab], not aoe4 and fab)

	# 6. Ficha compacta: sin estadísticas ni descripción; el detalle, con Mayús o Alt.
	var ficha: Ficha = hud.ficha
	var full := ficha._type_content(local, choque)
	var corta := ficha._compactar(ficha._type_content(local, choque))
	var pie_ok := false
	for f: Array in corta["foot"]:
		pie_ok = pie_ok or str(f[0]).contains("Mayús o Alt")
	check.call("fluidez 5: ficha compacta (estadísticas %d → %d, con el aviso de Mayús o Alt)" % [(full["stats"] as Array).size(), (corta["stats"] as Array).size()], not (full["stats"] as Array).is_empty() and (corta["stats"] as Array).is_empty() and str(corta.get("desc", "")) == "" and pie_ok and not corta["cost"].is_empty())

	# 7. Hoja de atajos: el botón del medio arrastra, no gira.
	var hoja := str(preload("res://src/game/ui/hoja_atajos.gd").secciones())
	check.call("fluidez 5: la hoja de atajos dice que el botón del medio arrastra", hoja.contains("botón del medio la arrastra") and not hoja.contains("girar") and hoja.contains("Ctrl + clic"))

	# 8. Retratos con fondo por función: aldeanos, a pie y el otro, en el panel de varias.
	var mezcla: Array[int] = []
	mezcla.append_array(ga)
	mezcla.append(escolta.id)
	var vs: Array[int] = m._vill_ids()
	mezcla.append_array(vs.slice(0, 4))
	var clases := {}
	for id in mezcla:
		clases[hud._sel.clase_funcion((sim.by_id[id] as SimEntity).def)] = true
	ctrl.select_ids(mezcla)
	await m._frames(8)
	m.get_viewport().get_texture().get_image().save_png("screenshots/fluidez5_retratos.png")
	check.call("fluidez 5: retratos por función (%s)" % [clases.keys()], clases.has("civil") and clases.has("a_pie"))
	var tropa: Array = ga.duplicate()
	tropa.append(escolta.id)
	sim.push_command({"t": "stop", "player": local, "ids": tropa})
	ctrl.select_ids([] as Array[int])
	await m._frames(4)
