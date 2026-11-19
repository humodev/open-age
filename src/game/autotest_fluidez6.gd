extends RefCounted
## Autotest del frente 6 de fluidez (proceso/30-fluidez/07): guardar la partida en juego,
## armarla de nuevo desde el archivo y re-simularla llega al mismo hash; la pausa ofrece
## «Guardar partida»; el panel «Mi base» abre con su tecla, cuenta los edificios propios y el
## clic elige y centra. Deja screenshots/mi_base.png. Lo llama main.gd → _autotest.


static func correr(m: Node, check: Callable) -> void:
	var sim: Sim = m.sim
	# 1. Guardar y cargar: mismo estado en el tick guardado. El guardado se hizo al principio,
	# después de las órdenes con clics y antes de que el autotest toque la partida a mano.
	check.call("se puede guardar la escaramuza", m.puede_guardar())
	var path: String = m.get_meta("guardado_autotest", "")
	var d := Guardado.leer(path)
	var ok := not d.is_empty() and (d["comandos"] as Array).size() > 0
	var igual := false
	if ok:
		var b := Guardado.armar(d)
		Guardado.avanzar(b, int(d["tick"]))
		igual = b.state_hash() == int(d["hash"])
		b.soltar()
	check.call("guardar en el tick %d (%d órdenes con clics) y cargar llega al mismo hash" % [int(d.get("tick", -1)), (d.get("comandos", []) as Array).size()], ok and igual)
	# --- instantaneas --- (proceso/37-red/02) y con la foto: sin re-simular, al mismo hash
	var con_foto := false
	if ok:
		var f := Guardado.armar(d, int(d["tick"]))
		con_foto = f.tick == int(d["tick"]) and f.state_hash() == int(d["hash"])
		f.soltar()
		Guardado.borrar(path)
	check.call("cargar con la foto (.foto) llega al mismo tick y hash sin re-simular", con_foto)
	var hud: Hud = m.hud
	var tiene := false
	for b in hud._menu.find_children("*", "Button", true, false):
		if (b as Button).text == "Guardar partida":
			tiene = true
	check.call("la pausa ofrece «Guardar partida»", tiene)

	# 2. Panel «Mi base».
	var pb: PanelBase = hud.panel_base
	var k := InputEventKey.new()
	k.physical_keycode = Teclas.tecla("mi_base")
	k.keycode = k.physical_keycode
	k.pressed = true
	Input.parse_input_event(k)
	k = k.duplicate()
	k.pressed = false
	Input.parse_input_event(k)
	await m._frames(40)
	check.call("%s abre el panel «Mi base»" % Teclas.texto("mi_base"), pb.visible)
	var capital: SimEntity = null
	var n := 0
	for e in sim.actives:
		if e.owner == m.local and e.is_building():
			n += 1
			if e.capital:
				capital = e
	var total := 0
	for t in pb._listas:
		total += (pb._listas[t][0] as Array).size()
	check.call("«Mi base» cuenta los %d edificios propios (%d)" % [n, total], total == n and n > 0)
	if capital != null:
		pb._ir(capital.type, 0)
		await m._frames(3)
		var sel: Array = m.ctrl.selected_entities()
		check.call("el clic en «Mi base» elige la capital", sel.size() == 1 and sel[0].id == capital.id)
	await m._frames(10)
	m.get_viewport().get_texture().get_image().save_png("screenshots/mi_base.png")
	pb.visible = false
	m.ctrl.select_ids([] as Array[int])
