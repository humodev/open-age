extends RefCounted
## --- fluidez 4 --- Autotest de avisos y equipo (proceso/30-fluidez/04-avisos-y-equipo.md):
## dos ataques en zonas distintas avisan los dos (y cada uno con su lugar), el tipo sale bien
## (aldeanos, edificio), una veta chica avisa que se agota y después que se acabó, la granja vacía
## se marca y «Llenar granjas» manda a alguien, el tributo con Mayús es ×5 y con Ctrl ×10, la rueda
## de la bengala elige por dirección y el filtro del minimapa apaga lo suyo.
## Deja screenshots/avisos_granja.png. Lo llama main.gd → _autotest.


static func _hasta(m: Node, cond: Callable, max: int = 240) -> bool:
	for i in max:
		if cond.call():
			return true
		await m._frames(1)
	return cond.call()


static func _lugar_libre(sim: Sim, cx: int, cy: int, w: int, h: int) -> Vector2i:
	for r in range(4, 22):
		for dy in range(-r, r + 1):
			for dx in range(-r, r + 1):
				if absi(dx) != r and absi(dy) != r:
					continue
				var tx := cx + dx
				var ty := cy + dy
				if tx < 2 or ty < 2 or tx + w >= sim.map.n - 2 or ty + h >= sim.map.n - 2:
					continue
				if sim.map.is_free_rect(tx - 1, ty - 1, w + 2, h + 2):
					return Vector2i(tx, ty)
	return Vector2i(-1, -1)


## Avisos de recurso que empiezan con `prefijo` y llevan la cámara a `veta`.
static func _avisos_en(al, veta: SimEntity, prefijo: String) -> int:
	var aca := WorldView.to_world(veta.x, veta.y)
	var n := 0
	for a in al.avisos_recurso:
		if String(a.get("texto", "")).begins_with(prefijo) and a.get("lugar") is Vector3 and (a["lugar"] as Vector3).distance_to(aca) < 0.01:
			n += 1
	return n


static func correr(m: Node, check: Callable) -> void:
	var sim: Sim = m.sim
	var hud: Hud = m.hud
	var local: int = m.local
	var al = hud.alertas
	var capital: SimEntity = null
	var vill: SimEntity = null
	var foe: SimEntity = null
	for e in sim.actives:
		if e.owner == local and e.is_building() and e.def.has("produce") and capital == null:
			capital = e
		if e.owner == local and e.fn == "civil" and vill == null:
			vill = e
		if e.owner >= 0 and sim.enemies(local, e.owner) and foe == null:
			foe = e
	if capital == null or vill == null or foe == null:
		check.call("fluidez 4: hay capital, aldeano y rival", false)
		return

	# --- ataques por zona y tipo ---
	hud.avisos.lista.clear()
	al._zonas.clear()
	al.conteo.clear()
	var zc := int(al.cfg.get("zona_casillas", 12))
	var lejos_t := Vector2i(clampi(vill.x / 1000 + zc * 3, 3, sim.map.n - 4), clampi(vill.y / 1000 + zc * 3, 3, sim.map.n - 4))
	if Vector2(lejos_t).distance_to(Vector2(vill.x / 1000.0, vill.y / 1000.0)) < zc * 2:
		lejos_t = Vector2i(clampi(vill.x / 1000 - zc * 3, 3, sim.map.n - 4), clampi(vill.y / 1000 - zc * 3, 3, sim.map.n - 4))
	var otro := sim.spawn_unit(vill.type, local, lejos_t.x * 1000 + 500, lejos_t.y * 1000 + 500)
	hud.on_events([{"t": "hit", "a": foe.id, "b": vill.id, "ranged": false, "dmg": 1}])
	await m._frames(2)
	hud.on_events([{"t": "hit", "a": foe.id, "b": otro.id, "ranged": false, "dmg": 1}])
	await m._frames(2)
	var con_lugar := 0
	for a in hud.avisos.lista:
		if a["tipo"] == "ataque" and a.get("lugar") is Vector3:
			con_lugar += 1
	check.call("fluidez 4: dos ataques en zonas distintas avisan los dos (%d avisos, %d con lugar)" % [int(al.conteo.get("ataque_aldeanos", 0)), con_lugar], int(al.conteo.get("ataque_aldeanos", 0)) == 2 and con_lugar >= 2)
	hud.on_events([{"t": "hit", "a": foe.id, "b": vill.id, "ranged": false, "dmg": 1}])
	await m._frames(1)
	check.call("fluidez 4: la misma zona no repite enseguida", int(al.conteo.get("ataque_aldeanos", 0)) == 2)
	hud.on_events([{"t": "hit", "a": foe.id, "b": capital.id, "ranged": false, "dmg": 1}])
	await m._frames(1)
	check.call("fluidez 4: golpe a un edificio avisa como edificio", int(al.conteo.get("ataque_edificio", 0)) == 1)
	var at: Variant = hud.avisos.saltar(false)
	check.call("fluidez 4: Espacio va al último ataque", at is Vector3 and Vector2(at.x, at.z).distance_to(Vector2(capital.x / 1000.0, capital.y / 1000.0)) < 1.0)
	sim.push_command({"t": "delete", "player": local, "ids": [otro.id]})

	# --- veta chica que se agota ---
	var roca := ""
	for k in sim.data.recursos:
		if String(sim.data.recursos[k].get("recurso", "")) == "piedra":
			roca = k
			break
	var def: Dictionary = sim.data.recursos.get(roca, {})
	var tam: Array = def.get("tam", [1, 1])
	var pos := _lugar_libre(sim, capital.tx, capital.ty, int(tam[0]), int(tam[1]))
	if roca == "" or pos.x < 0:
		check.call("fluidez 4: lugar para una veta de prueba", false)
	else:
		var veta := sim.spawn_resource(roca, pos.x, pos.y)
		# Lejos de otras: lo que queda cerca es solo esta.
		veta.amount = int((al.cfg.get("umbral_recurso", {}) as Dictionary).get("piedra", 300)) / 2
		al._avisado_veta.clear()
		al._seguidos.clear()
		# Los otros aldeanos siguen juntando y lo que se agota cerca de ellos también avisa
		# (en guaraníes, el monte se raleaba). Esa revisión va antes, y se cuentan solo los avisos
		# con lugar en la veta.
		al.revisar()
		hud.avisos.lista.clear()
		al.avisos_recurso.clear()
		al.conteo.clear()
		sim.push_command({"t": "target", "player": local, "ids": [vill.id], "target": veta.id})
		await _hasta(m, func() -> bool: return vill.target == veta.id and vill.order == SimEntity.Order.GATHER, 120)
		al.revisar()
		var poco := _avisos_en(al, veta, "Se agota")
		check.call("fluidez 4: la veta chica avisa que se agota (%d de %d)" % [poco, int(al.conteo.get("recurso", 0))], poco == 1)
		veta.amount = 1
		# --- ronda 8 --- el aldeano a veces se iba (lleno, a dejar, o asustado) y la veta no se
		# acababa en 1200 cuadros: se lo vuelve a mandar y se acelera.
		var agotada := false
		m.speed = 4.0
		for intento in 10:
			if vill.alive and veta.alive and vill.target != veta.id:
				sim.push_command({"t": "target", "player": local, "ids": [vill.id], "target": veta.id})
			agotada = await _hasta(m, func() -> bool: return not veta.alive or veta.amount <= 0, 240)
			if agotada:
				break
		m.speed = 1.0
		al.revisar()
		var fin := _avisos_en(al, veta, "Se acabó")
		var txt: String = al.ultimo_recurso.get("texto", "")
		check.call("fluidez 4: cuando se acaba, avisa con lugar («%s», %d, agotada %s)" % [txt, fin, agotada], agotada and fin == 1 and _avisos_en(al, veta, "Se agota") == 1)

	# --- granja vacía ---
	var granja := ""
	for k in sim.dp(local).edificios:
		if String(sim.dp(local).edificios[k].get("fuente", "")) != "":
			granja = k
			break
	var gdef: Dictionary = sim.dp(local).edificios.get(granja, {})
	var gt: Array = gdef.get("tam", [3, 3])
	var gp := _lugar_libre(sim, capital.tx, capital.ty, int(gt[0]), int(gt[1]))
	if granja == "" or gp.x < 0:
		check.call("fluidez 4: lugar para una granja de prueba", false)
	else:
		var f := sim.spawn_building(granja, local, gp.x, gp.y, true)
		var espera: float = al.cfg.get("granja_espera_s", 4.0)
		al.cfg["granja_espera_s"] = 0.0
		al.revisar()
		await m._frames(2)
		al.revisar()
		check.call("fluidez 4: la granja vacía se marca (%d) y aparece el botón" % al.vacias.size(), al.vacias.has(f) and al.boton.visible)
		hud.cam.look_at_point(WorldView.to_world(f.x, f.y))
		await m._frames(6)
		m.get_viewport().get_texture().get_image().save_png("screenshots/avisos_granja.png")
		var n: int = al.llenar_granjas()
		await _hasta(m, func() -> bool: return f.farmer >= 0 or sim.by_id.get(f.farmer) != null, 300)
		var w: SimEntity = null
		for e in sim.actives:
			if e.owner == local and e.fn == "civil" and e.target == f.id:
				w = e
		check.call("fluidez 4: «Llenar granjas» manda un aldeano (%d)" % n, n >= 1 and w != null)
		al.cfg["granja_espera_s"] = espera

	# --- tributo con cantidad ---
	var pp = hud.paneles.puntaje
	var lote := int(sim.data.reglas["equipos"].get("tributo_lote", 100))
	check.call("fluidez 4: tributo ×5 con Mayús y ×10 con Ctrl", pp.cantidad(true, false) == lote * 5 and pp.cantidad(false, true) == lote * 10 and pp.cantidad(false, false) == lote)
	var nrec := sim.recording.size()
	pp.tributar(foe.owner, "madera", true, false)
	var last: Dictionary = sim.recording[-1] if sim.recording.size() > nrec else {}
	check.call("fluidez 4: el clic con Mayús manda %d" % int(last.get("n", 0)), int(last.get("n", 0)) == lote * 5)
	pp.alternar_periodico(foe.owner, "madera", false, false)
	check.call("fluidez 4: el tributo periódico se prende y se apaga", pp.periodico.size() == 1 and not pp.alternar_periodico(foe.owner, "madera", false, false) and pp.periodico.is_empty())

	# --- rueda de la bengala ---
	var oc = hud.ordenes_capa
	oc.abrir_rueda(Vector2(500, 500), Vector3(10, 0, 10))
	var dirs := [oc.intencion(Vector2(500, 420)), oc.intencion(Vector2(580, 500)), oc.intencion(Vector2(500, 580)), oc.intencion(Vector2(420, 500)), oc.intencion(Vector2(503, 502))]
	oc.cerrar_rueda(Vector2(500, 500))
	check.call("fluidez 4: la rueda elige atacar, defender, juntarse, mirar o automática (%s)" % str(dirs), dirs == ["atacar", "defender", "juntarse", "mirar", ""])

	# --- minimapa: filtros y tamaño ---
	var mini: Minimap = hud._mini
	mini.filtrar("recursos", false)
	var px_res := 0
	for e in sim.entities:
		if e.alive and e.is_resource():
			var c := mini._img.get_pixel(e.tx, e.ty)
			if c.is_equal_approx(Palette.STONE.lightened(0.2)) or c.is_equal_approx(Palette.FOLIAGE.darkened(0.25)):
				px_res += 1
	check.call("fluidez 4: el filtro de recursos los saca del minimapa (%d)" % px_res, px_res == 0)
	mini.filtrar("recursos", true)
	var l0: float = mini.lado()
	mini.cambiar_tamano()
	await m._frames(2)
	check.call("fluidez 4: el minimapa cambia de tamaño (%.0f → %.0f)" % [l0, mini.size.x], absf(mini.size.x - l0) > 1.0)
	while absf(mini.lado() - l0) > 0.5:
		mini.cambiar_tamano()
	await m._frames(2)
