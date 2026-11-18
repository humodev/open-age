extends RefCounted
## Autotest de la respuesta inmediata (proceso/30-fluidez, frente 3): el sonido al elegir con un clic
## de verdad, la categoría y la función de la orden, el error del clic que no hace nada, el destello
## del blanco que aparece y se va, el pulso de la cámara, el polvo del cimiento y la estela de los
## proyectiles. Deja screenshots/fluidez3_destello.png. Lo llama main.gd → _autotest.


static func correr(m: Node, check: Callable) -> void:
	var sim: Sim = m.sim
	var ctrl: Controller = m.ctrl
	var view: WorldView = m.view
	var cam: RtsCamera = m.cam
	var local: int = m.local
	var base = sim.bases[local]
	var vs: Array[int] = m._vill_ids()
	m.speed = 1.0
	cam.look_at_point(Vector3(base.x + 2, 0, base.y + 2))
	ctrl.select_ids([] as Array[int])
	await m._frames(12)
	Respuesta.cuenta.clear()

	# 1. Elegir un aldeano con un clic de verdad: suena el de aldeano.
	var v: SimEntity = sim.by_id.get(vs[0])
	var sp := cam.cam.unproject_position(WorldView.to_world(v.x, v.y, 0.4))
	m._mouse(sp, MOUSE_BUTTON_LEFT, true)
	await m._frames(1)
	m._mouse(sp, MOUSE_BUTTON_LEFT, false)
	await m._frames(12)
	check.call("fluidez 3: el clic que elige suena (%d, elegidos %d)" % [int(Respuesta.cuenta.get("elegir", 0)), ctrl.selection.size()], int(Respuesta.cuenta.get("elegir", 0)) >= 1 and not ctrl.selection.is_empty())
	check.call("fluidez 3: categoría de los aldeanos (%s)" % Respuesta.categoria(ctrl, vs), Respuesta.categoria(ctrl, vs) == "aldeano")
	var capital: SimEntity = null
	for e in sim.actives:
		if e.owner == local and e.is_building() and e.built:
			capital = e
			break
	if capital != null:
		check.call("fluidez 3: categoría de un edificio", Respuesta.categoria(ctrl, [capital.id] as Array[int]) == "edificio")

	# 2. El clic derecho sin nada propio elegido no hace nada: suena el error.
	ctrl.select_ids([] as Array[int])
	await m._frames(2)
	var empty_sp: Vector2 = m._suelo_libre(base.x - 6.0, base.y + 10.0)
	m._mouse(empty_sp, MOUSE_BUTTON_RIGHT, true)
	m._mouse(empty_sp, MOUSE_BUTTON_RIGHT, false)
	await m._frames(4)
	check.call("fluidez 3: clic derecho sin selección suena a error (%d)" % int(Respuesta.cuenta.get("error", 0)), int(Respuesta.cuenta.get("error", 0)) >= 1)

	# 3. Clic derecho en un arbusto con los aldeanos: la orden civil y el destello, que se va.
	ctrl.select_ids(vs)
	await m._frames(12)
	check.call("fluidez 3: función de la orden de los aldeanos (%s)" % Respuesta.funcion(ctrl), Respuesta.funcion(ctrl) == "civil")
	# El arbusto más cercano que el cursor tome a él (no a un aldeano parado encima ni a un árbol).
	var arbustos: Array = sim.entities.filter(func(e: SimEntity) -> bool: return e.alive and e.type == "arbusto")
	arbustos.sort_custom(func(p: SimEntity, q: SimEntity) -> bool: return Sim.dist(p.x, p.y, base.x * 1000, base.y * 1000) < Sim.dist(q.x, q.y, base.x * 1000, base.y * 1000))
	var bush: SimEntity = null
	var bush_sp := Vector2.ZERO
	for e: SimEntity in arbustos.slice(0, 12):
		cam.look_at_point(WorldView.to_world(e.x, e.y))
		await m._frames(1)
		bush_sp = cam.cam.unproject_position(WorldView.to_world(e.x, e.y, 0.2))
		if ctrl.pick(bush_sp, true) == e.id:
			bush = e
			break
	if bush == null:
		check.call("fluidez 3: hay un arbusto para el destello", false)
		return
	var antes := int(Respuesta.cuenta.get("orden", 0))
	m._mouse(bush_sp, MOUSE_BUTTON_RIGHT, true)
	m._mouse(bush_sp, MOUSE_BUTTON_RIGHT, false)
	await m._frames(2)
	var vivos := view.fx_vivos("destello")
	check.call("fluidez 3: el arbusto destella al ordenar juntar (%d)" % vivos, vivos >= 1)
	check.call("fluidez 3: suena la orden (%d)" % int(Respuesta.cuenta.get("orden", 0)), int(Respuesta.cuenta.get("orden", 0)) > antes or antes > 0)
	# Polvo de un cimiento al lado, para la misma captura.
	var cim := cam.ground_at(bush_sp + Vector2(260, 60))
	Respuesta.cimiento(ctrl, cim, "casa")
	ctrl.select_ids([] as Array[int])
	await m._frames(10)
	m.get_viewport().get_texture().get_image().save_png("screenshots/fluidez3_destello.png")
	check.call("fluidez 3: polvo del cimiento (%d nubes)" % view.fx_vivos("dust"), view.fx_vivos("dust") >= 3 and int(Respuesta.cuenta.get("cimiento", 0)) >= 1)
	var t0 := Time.get_ticks_msec()
	while view.fx_vivos("destello") > 0 and Time.get_ticks_msec() - t0 < 3000:
		await m._frames(1)
	check.call("fluidez 3: el destello se va solo (%d ms)" % (Time.get_ticks_msec() - t0), view.fx_vivos("destello") == 0)

	# 4. Pulso al centrar la cámara en la selección (doble toque de grupo, aldeano inactivo).
	ctrl.select_ids(vs)
	ctrl.center_on_selection()
	await m._frames(1)
	check.call("fluidez 3: pulso al saltar con la cámara", view.fx_vivos("pulso") >= 1)

	# 5. Estela: la flecha lleva su estela pegada.
	var a := WorldView.to_world(base.x * 1000, base.y * 1000, 1.0)
	view._projectile(a, a + Vector3(6, 0, 3), true)
	var proj: Node3D = view._fx[view._fx.size() - 1]["node"]
	check.call("fluidez 3: la flecha tiene estela", proj.get_child_count() >= 1)

	# 6. Se apagan desde los datos.
	var d: Dictionary = Respuesta.cfg()["efectos"]["destello"]
	d["activo"] = false
	check.call("fluidez 3: el destello se apaga en data/respuesta.json", not view.destello(bush, Color.WHITE))
	d["activo"] = true
	ctrl.select_ids([] as Array[int])
	await m._frames(30)
