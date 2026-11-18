extends RefCounted
## Autotest de la producción que se maneja sola (proceso/30, frente 1): Ctrl + clic en la
## casilla prende la repetición, que no toca lo apartado y no pasa el tope de aldeanos; cola de
## 10; clic derecho en la casilla saca una y Mayús + clic derecho saca 5; el centro parado se ve
## gris en la cola global; aviso anticipado de población; ingreso por minuto en la barra.
## Deja screenshots/produccion_cola_global.png. Lo llama main.gd → _autotest.


static func _tecla(code: int, on: bool) -> void:
	var k := InputEventKey.new()
	k.physical_keycode = code
	k.keycode = code
	k.pressed = on
	Input.parse_input_event(k)


static func _boton(m: Node, pos: Vector2, button: int, shift_on: bool) -> void:
	m._mouse(pos, 0, false)
	await m._frames(2)
	var wp: Vector2 = m.get_viewport().get_final_transform() * pos
	for pressed in [true, false]:
		var mb := InputEventMouseButton.new()
		mb.position = wp
		mb.global_position = wp
		mb.button_index = button
		mb.pressed = pressed
		mb.shift_pressed = shift_on
		Input.parse_input_event(mb)
	await m._frames(3)


## Espera hasta que `cond` se cumpla (o `max` cuadros).
static func _hasta(m: Node, cond: Callable, max: int = 240) -> bool:
	for i in max:
		if cond.call():
			return true
		await m._frames(1)
	return cond.call()


static func correr(m: Node, check: Callable) -> void:
	var sim: Sim = m.sim
	var ctrl: Controller = m.ctrl
	var hud: Hud = m.hud
	var local: int = m.local
	var p: Dictionary = sim.players[local]
	var saved_res: Dictionary = (p["res"] as Dictionary).duplicate()
	var saved_extra: int = int(p.get("pob_extra", 0))
	var capital: SimEntity = null
	for e in sim.actives:
		if e.alive and e.owner == local and e.is_building() and e.built and e.capital and (e.def.get("produce", []) as Array).has("aldeano"):
			capital = e
			break
	if capital == null:
		check.call("hay un centro que entrena aldeanos", false)
		return
	var b := sim.bases[local]
	m.cam.look_at_point(Vector3(b.x + 2, 0, b.y + 2))
	ctrl.open_submenu(Grilla.RAIZ)
	ctrl.select_ids([capital.id] as Array[int])
	for k in sim.RES_KINDS:
		p["res"][k] = 5000
	p["pob_extra"] = saved_extra + 60
	await m._frames(4)
	var cmd := {}
	for c in ctrl.commands():
		if c.get("kind", "") == "train" and c["id"] == "aldeano":
			cmd = c
	var slot_c: Vector2 = hud._card.global_position + hud._card._slot_rect(int(cmd.get("slot", 0))).get_center()

	# 1. Ctrl + clic en la casilla: se repite (comando de la simulación, queda grabado).
	var n_rec := sim.recording.size()
	_tecla(KEY_CTRL, true)
	await m._click(slot_c)
	_tecla(KEY_CTRL, false)
	await _hasta(m, func() -> bool: return capital.repeat == "aldeano", 60)
	check.call("Ctrl + clic en la casilla prende la repetición (comando grabado)", capital.repeat == "aldeano" and sim.recording.size() > n_rec)
	var c2 := Controller.cmd_at(ctrl.commands(), int(cmd.get("slot", 0)))
	check.call("la casilla dice que se repite", c2.get("repite", false))
	await m._frames(4)
	m.get_viewport().get_texture().get_image().save_png("screenshots/produccion_repite.png")
	await _hasta(m, func() -> bool: return not capital.queue.is_empty(), 60)
	check.call("con la cola vacía, la repetición encola sola", not capital.queue.is_empty())

	# 2. Lo apartado no se toca.
	var cola_antes := capital.queue.size()
	sim.push_command({"t": "cancel", "player": local, "building": capital.id, "index": -1})
	await _hasta(m, func() -> bool: return capital.queue.size() < cola_antes, 60)
	p["reserva_alimento"] = int(p["res"]["alimento"])
	check.call("con todo el alimento apartado, la repetición se frena (%s)" % sim.repeat_block(capital), sim.repeat_block(capital) == "recursos")
	p["reserva_alimento"] = 0

	# 3. El tope de aldeanos: con 10 de tope y 8 aldeanos, para en 10.
	var rep: Dictionary = sim.data.reglas["repeticion"]
	var ald := sim.villagers_and_queued(local)
	var tope := maxi(int(rep["tope_min"]), ald + 2)
	sim.push_command({"t": "tope_aldeanos", "player": local, "n": tope})
	for i in maxi(0, tope - 2 - ald):
		sim.spawn_unit("aldeano", local, (b.x + 3) * 1000 + (i % 5) * 600, (b.y + 7) * 1000 + (i / 5) * 600)
	m.speed = 16.0
	var llego := await _hasta(m, func() -> bool: return sim.villagers_and_queued(local) >= tope and capital.queue.is_empty(), 900)
	await m._frames(120)
	var n_ald := sim.villagers_and_queued(local)
	m.speed = 1.0
	check.call("la repetición llega al tope y no lo pasa (%d de %d)" % [n_ald, tope], llego and n_ald == tope and sim.villager_cap(local) == tope and capital.queue.is_empty() and sim.repeat_block(capital) == "tope")

	# 4. Ctrl + clic otra vez: se apaga.
	_tecla(KEY_CTRL, true)
	await m._click(slot_c)
	_tecla(KEY_CTRL, false)
	await _hasta(m, func() -> bool: return capital.repeat == "", 60)
	check.call("Ctrl + clic otra vez apaga la repetición", capital.repeat == "")
	sim.push_command({"t": "tope_aldeanos", "player": local, "n": int(rep["tope_aldeanos"])})

	# 5. Cola de 10.
	for i in 12:
		sim.push_command({"t": "train", "player": local, "building": capital.id, "type": "aldeano"})
	await _hasta(m, func() -> bool: return capital.queue.size() >= 10, 60)
	await m._frames(3)
	check.call("la cola llega a 10 y no pasa (%d)" % capital.queue.size(), capital.queue.size() == 10 and int(sim.data.reglas["cola_max"]) == 10)

	m.get_viewport().get_texture().get_image().save_png("screenshots/produccion_cola10.png")
	# 6. Clic derecho en la casilla saca una; Mayús + clic derecho, 5.
	await _boton(m, slot_c, MOUSE_BUTTON_RIGHT, false)
	await _hasta(m, func() -> bool: return capital.queue.size() == 9, 30)
	check.call("clic derecho en la casilla saca una de la cola (%d)" % capital.queue.size(), capital.queue.size() == 9)
	_tecla(KEY_SHIFT, true)
	await _boton(m, slot_c, MOUSE_BUTTON_RIGHT, true)
	_tecla(KEY_SHIFT, false)
	await _hasta(m, func() -> bool: return capital.queue.size() == 4, 30)
	check.call("Mayús + clic derecho saca 5 (%d)" % capital.queue.size(), capital.queue.size() == 4)
	check.call("el clic derecho sobre una unidad no cambia de submenú", ctrl.submenu == Grilla.RAIZ)

	# 7. Aviso anticipado de población: un lugar libre y cuatro en cola.
	var base_cap := int(p["pop_cap"]) - int(p["pob_extra"])
	p["pob_extra"] = int(p["pop"]) + 1 - base_cap
	await _hasta(m, func() -> bool: return hud.pob_eta > 0, 30)
	var aviso := int(hud.COLA_GLOBAL.cfg()["aviso_pob_s"])
	check.call("aviso anticipado de población: sin lugar en ~%d s" % hud.pob_eta, hud.pob_eta > 0 and hud.pob_eta <= aviso)
	p["pob_extra"] = saved_extra + 60

	# 8. Parado en gris: sin cola durante parado_s, el centro va gris a la cola global.
	for i in 12:
		sim.push_command({"t": "cancel", "player": local, "building": capital.id, "index": -1})
	await _hasta(m, func() -> bool: return capital.queue.is_empty(), 30)
	ctrl.select_ids([] as Array[int])
	m.speed = 8.0
	var gris := await _hasta(m, func() -> bool: return hud.cola_global.parado(capital) and hud.cola_global.items().has(capital), 600)
	m.speed = 1.0
	check.call("el centro parado aparece gris en la cola global", gris)
	# Para la captura: un edificio militar que repite su tropa (el bucle) junto al centro gris.
	var dd := sim.dp(local)
	var mil: SimEntity = null
	for t: String in dd.edificios:
		var d: Dictionary = dd.edificios[t]
		var prod: Array = d.get("produce", [])
		if t == capital.type or prod.is_empty() or int(d.get("edad_min", 1)) > 1 or prod.has("aldeano") or dd.is_hito(t):
			continue
		for dy in range(-12, 13, 4):
			for dx in range(-12, 13, 4):
				if mil == null and sim.can_place(t, b.x + dx, b.y + dy, local):
					mil = sim.spawn_building(t, local, b.x + dx, b.y + dy, true)
		if mil != null:
			break
	if mil != null:
		sim.push_command({"t": "repetir", "player": local, "building": mil.id, "type": str((mil.def["produce"] as Array)[0]), "on": true})
		await _hasta(m, func() -> bool: return not mil.queue.is_empty(), 60)
	await m._frames(30)
	m.get_viewport().get_texture().get_image().save_png("screenshots/produccion_cola_global.png")
	check.call("el cuartel que repite está en la cola global con el bucle", mil != null and mil.repeat != "" and hud.cola_global.items().has(mil))
	if mil != null:
		sim.push_command({"t": "repetir", "player": local, "building": mil.id, "type": "", "on": false})
		sim.push_command({"t": "delete", "player": local, "ids": [mil.id]})
	var antes_op := Opciones.aviso_parados
	hud.cola_global.alternar_aviso()
	var apagado := Opciones.aviso_parados != antes_op
	hud.cola_global.alternar_aviso()
	check.call("el consejo de parados se apaga y se prende", apagado and Opciones.aviso_parados == antes_op)

	# 9. Ingreso por minuto al pasar por un recurso de la barra.
	m._mouse(hud._top.global_position + Vector2(40, 12), 0, false)
	await m._frames(4)
	var tip_desc := str(hud._tip.cmd.get("desc", "")) if hud.get("_tip") != null and hud._tip.get("cmd") != null else ""
	check.call("la ayuda del recurso dice el ingreso por minuto", tip_desc.contains("por minuto"))
	m._mouse(Vector2(960, 540), 0, false)

	# Limpieza.
	await m._frames(4)
	for i in 12:
		sim.push_command({"t": "cancel", "player": local, "building": capital.id, "index": -1})
	await m._frames(4)
	p["res"] = saved_res
	p["pob_extra"] = saved_extra
	ctrl.select_ids([] as Array[int])
	await m._frames(2)
