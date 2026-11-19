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


static func correr(m: Node, check: Callable) -> void:
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
	var pts: Array[Vector2] = [m._suelo_libre(cx + 10.0, cy), m._suelo_libre(cx + 10.0, cy + 8.0), m._suelo_libre(cx, cy + 8.0)]
	for p in pts:
		await _clic(m, p)
	var sigue: bool = ctrl.mode == "patrol"
	_tecla(KEY_SHIFT, false)
	await m._frames(1)
	await _clic(m, pts[0], MOUSE_BUTTON_RIGHT) # sale del modo
	var ronda := await _hasta(m, func() -> bool: return (sim.by_id[ga[0]] as SimEntity).pat_pts.size() == 4, 60)
	check.call("fluidez 5: patrulla de 3 puntos con Mayús (sigue en el modo: %s, ronda de %d)" % [sigue, (sim.by_id[ga[0]] as SimEntity).pat_pts.size()], sigue and ronda and (sim.by_id[ga[0]] as SimEntity).patrol and ctrl.mode == "")

	# 3. Escolta: el otro elegido y clic derecho sobre uno de la patrulla.
	ctrl.select_ids([escolta.id] as Array[int])
	await m._frames(3)
	var lider: SimEntity = sim.by_id[ga[1]]
	cam.look_at_point(WorldView.to_world(lider.x, lider.y))
	await m._frames(2)
	var spl := cam.cam.unproject_position(WorldView.to_world(lider.x, lider.y, 0.4))
	await _clic(m, spl, MOUSE_BUTTON_RIGHT)
	var sigue_lider := await _hasta(m, func() -> bool: return escolta.order == SimEntity.Order.FOLLOW and escolta.esc == lider.id, 60)
	check.call("fluidez 5: clic derecho en una unidad propia la escolta (orden %d, sigue a %d)" % [escolta.order, escolta.esc], sigue_lider)
	await m._frames(90)
	var d := Sim.dist(escolta.x, escolta.y, lider.x, lider.y)
	check.call("fluidez 5: el escolta va con la patrulla (a %d)" % d, d <= 4000 and escolta.order == SimEntity.Order.FOLLOW)
	m.get_viewport().get_texture().get_image().save_png("screenshots/fluidez5_escolta.png")

	# 4. Mayús + mantener: después del movimiento, no en lugar de él.
	var g3: SimEntity = sim.by_id[ga[3]]
	ctrl.select_ids([g3.id] as Array[int])
	await m._frames(2)
	var dest := WorldView.to_world(g3.x, g3.y) + Vector3(3, 0, 0)
	sim.push_command({"t": "move", "player": local, "ids": [g3.id], "x": int(dest.x * P), "y": int(dest.z * P)})
	await m._frames(2)
	_tecla(KEY_SHIFT, true)
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
