extends SceneTree
## Capturas y medición de la información en el mundo (src/game/ui/mundo_*.gd).
##
##   godot --path . -s tests/mundo_capturas.gd -- --escena=incas --civ=tawantinsuyu --terreno=montana --nofog --mute
##   godot --path . -s tests/mundo_capturas.gd -- --escena=arrozal --civ=ayutthaya --terreno=delta --nofog --mute
##   godot --path . -s tests/mundo_capturas.gd -- --escena=batalla --civ=guaranies --terreno=llano --nofog --mute
##
## Guarda las imágenes en --dir (por defecto screenshots/) y, en la escena "batalla",
## mide los cuadros por segundo con 200 unidades con la capa encendida y apagada.

var main: Node
var args := {}
var dir := "screenshots"


func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		var kv := a.trim_prefix("--").split("=", true, 1)
		args[kv[0]] = kv[1] if kv.size() > 1 else "1"
	dir = args.get("dir", dir)
	DirAccess.make_dir_recursive_absolute(dir)
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	main = load("res://src/game/main.tscn").instantiate()
	root.add_child(main)
	_run.call_deferred()


func _frames(n: int) -> void:
	for i in n:
		await process_frame


func _game_secs(s: float) -> void:
	var until: int = main.sim.tick + int(s * 1000.0 / main.sim.tick_ms)
	while main.sim.tick < until:
		await process_frame


func _shot(name: String) -> void:
	await _frames(4)
	var img := root.get_texture().get_image()
	var path := "%s/%s.png" % [dir, name]
	img.save_png(path)
	print("captura: ", path)


func _look(x: float, z: float, zoom: float = 30.0) -> void:
	main.cam.look_at_point(Vector3(x, 0, z))
	main.cam.zoom = zoom
	main.cam.set("_zoom_target", zoom)


func _screen(x: float, z: float) -> Vector2:
	return main.cam.cam.unproject_position(Vector3(x, WorldView.height_at(x, z), z))


func _rich() -> void:
	for k in main.sim.players[0]["res"]:
		main.sim.players[0]["res"][k] = 5000


func _villagers() -> Array[int]:
	var ids: Array[int] = []
	for e in main.sim.actives:
		if e.owner == 0 and e.fn == "civil" and e.inside < 0:
			ids.append(e.id)
	return ids


## Entra en modo de colocación sin pasar por la grilla (para tipos de otra edad).
func _place_mode(type: String) -> void:
	var ctrl: Controller = main.ctrl
	ctrl.select_ids(_villagers())
	ctrl.mode = "place"
	ctrl.place_type = type
	ctrl._ghost.mesh = ctrl.view.building_mesh_for(0, type, main.sim.dp(0).edificios[type])
	ctrl._ghost.visible = true
	ctrl.view.set_grid(true)


func _hover_tile(tx: int, ty: int, type: String) -> void:
	var tam: Array = main.sim.dp(0).edificios[type]["tam"]
	main.ctrl.mouse_override = _screen(tx + tam[0] / 2.0, ty + tam[1] / 2.0)
	await _frames(3)


func _key(code: int, pressed: bool) -> void:
	var k := InputEventKey.new()
	k.physical_keycode = code
	k.keycode = code
	k.pressed = pressed
	Input.parse_input_event(k)


func _find_spot(type: String, cond: Callable, r_max: int = 22) -> Vector2i:
	var b: Vector2i = main.sim.bases[0]
	for r in range(4, r_max):
		for dy in range(-r, r + 1):
			for dx in range(-r, r + 1):
				if maxi(absi(dx), absi(dy)) != r:
					continue
				var t := Vector2i(b.x + dx, b.y + dy)
				if cond.call(t):
					return t
	return Vector2i(-1, -1)


func _run() -> void:
	await _frames(30)
	var kind: String = args.get("escena", "batalla")
	match kind:
		"incas":
			await _incas()
		"arrozal":
			await _arrozal()
		_:
			await _batalla()
	quit(0)


func _incas() -> void:
	var sim: Sim = main.sim
	_rich()
	var Col := preload("res://src/game/ui/mundo_colocacion.gd")
	# Andén en ladera: rinde más.
	var slope := _find_spot("anden", func(t: Vector2i) -> bool: return sim.can_place("anden", t.x, t.y, 0) and Col.bono_sitio(sim, 0, "anden", t.x, t.y) > 0, 30)
	if slope.x >= 0:
		_look(slope.x + 1.5, slope.y + 1.5, 26.0)
		await _frames(5)
		_place_mode("anden")
		await _hover_tile(slope.x, slope.y, "anden")
		await _shot("mundo_anden_ladera")
	# Lugar ocupado: rojo con el motivo.
	var b: Vector2i = sim.bases[0]
	_look(b.x + 2, b.y + 2, 26.0)
	await _frames(5)
	_place_mode("taller_tejido")
	await _hover_tile(b.x + 1, b.y + 1, "taller_tejido")
	await _shot("mundo_colocacion_invalida")
	# Torre: alcance, campana y conexión por caminos.
	main.ctrl.cancel_mode()
	var tower := _find_spot("torre", func(t: Vector2i) -> bool: return sim.can_place("torre", t.x, t.y, 0), 12)
	_look(tower.x + 1, tower.y + 1, 40.0)
	await _frames(5)
	_place_mode("torre")
	await _hover_tile(tower.x, tower.y, "torre")
	await _shot("mundo_torre_alcance")
	main.ctrl.cancel_mode()


func _arrozal() -> void:
	var sim: Sim = main.sim
	_rich()
	var Col := preload("res://src/game/ui/mundo_colocacion.gd")
	var wet := _find_spot("granja", func(t: Vector2i) -> bool: return sim.can_place("granja", t.x, t.y, 0) and Col.bono_sitio(sim, 0, "granja", t.x, t.y) > 0, 40)
	if wet.x < 0:
		print("sin agua cerca de la base")
		return
	_look(wet.x + 1.5, wet.y + 1.5, 28.0)
	await _frames(5)
	_place_mode("granja")
	await _hover_tile(wet.x, wet.y, "granja")
	await _shot("mundo_arrozal_agua")
	main.ctrl.cancel_mode()


func _batalla() -> void:
	var sim: Sim = main.sim
	var ctrl: Controller = main.ctrl
	var b: Vector2i = sim.bases[0]
	# 1. Aldeanos ociosos, trabajando y punto de reunión del centro.
	_look(b.x + 2, b.y + 2, 28.0)
	var vill := _villagers()
	var res: SimEntity = sim.find_resource(0, "madera", b.x * 1000, b.y * 1000, 30000)
	if res != null:
		sim.push_command({"t": "target", "player": 0, "ids": vill.slice(0, 3), "target": res.id})
	var centro: SimEntity = null
	for e in sim.actives:
		if e.owner == 0 and e.capital:
			centro = e
	sim.push_command({"t": "rally", "player": 0, "building": centro.id, "x": (b.x + 9) * 1000, "y": (b.y - 3) * 1000, "target": -1})
	await _game_secs(6.0)
	ctrl.select_ids([centro.id] as Array[int])
	await _shot("mundo_aldeanos_y_reunion")

	# 2. Órdenes en cola con mayúsculas.
	var squad: Array[int] = []
	for i in 6:
		var u := sim.spawn_unit(["guerrero", "hondero", "lancero"][i % 3], 0, (b.x + 6 + i % 3) * 1000 + 500, (b.y + 6 + i / 3) * 1000 + 500)
		squad.append(u.id)
	await _frames(2)
	ctrl.select_ids(squad)
	sim.push_command({"t": "move", "player": 0, "ids": squad, "x": (b.x + 14) * 1000, "y": (b.y + 4) * 1000})
	await _game_secs(0.3)
	# Mayúsculas + clic derecho con eventos reales: encola en vez de reemplazar.
	_look(b.x + 10, b.y + 9, 30.0)
	await _frames(3)
	_key(KEY_SHIFT, true)
	await _frames(1)
	var at := _screen(b.x + 16.5, b.y + 12.5)
	for pressed in [true, false]:
		var mb := InputEventMouseButton.new()
		mb.position = at
		mb.global_position = at
		mb.button_index = MOUSE_BUTTON_RIGHT
		mb.pressed = pressed
		Input.parse_input_event(mb)
	await _frames(3)
	_key(KEY_SHIFT, false)
	print(("OK    " if ctrl.cola.colas.size() == squad.size() else "FALLO ") + "mayúsculas + clic derecho encola la orden (%d)" % ctrl.cola.colas.size())
	ctrl.cola.encolar(squad, {"t": "move", "x": (b.x + 8) * 1000, "y": (b.y + 16) * 1000, "amove": true})
	await _game_secs(1.0)
	await _shot("mundo_ordenes_en_cola")
	await _game_secs(20.0)
	print("cola pendiente tras 20 s: ", ctrl.cola.colas.size(), " unidades")

	# 3. Sitio sagrado en captura.
	var site: SimEntity = null
	for e in sim.actives:
		if e.def.get("sagrado", false) and (site == null or Sim.dist(e.x, e.y, b.x * 1000, b.y * 1000) < Sim.dist(site.x, site.y, b.x * 1000, b.y * 1000)):
			site = e
	if site != null:
		var cap: Array[int] = []
		for i in 3:
			cap.append(sim.spawn_unit("guerrero", 0, site.x + (i - 1) * 800, site.y + 2500).id)
		_look(site.x / 1000.0, site.y / 1000.0, 24.0)
		await _game_secs(5.0)
		ctrl.select_ids(cap)
		await _shot("mundo_sitio_captura")

	# 4. Batalla de 200 unidades: alcances con Alt, golpes fuertes y destellos en el minimapa.
	var c := sim.map.n / 2
	var ids := [[], []]
	var types := ["guerrero", "hondero", "lancero"]
	for pid in 2:
		for i in 100:
			var x := (c - 9 + pid * 18 + (i % 10) * (1 if pid == 0 else -1)) * 1000 + 500
			var y := (c - 5 + i / 10) * 1000 + 500
			ids[pid].append(sim.spawn_unit(types[i % 3], pid, x, y).id)
	sim.push_command({"t": "move", "player": 0, "ids": ids[0], "x": (c + 6) * 1000, "y": c * 1000, "amove": true})
	sim.push_command({"t": "move", "player": 1, "ids": ids[1], "x": (c - 6) * 1000, "y": c * 1000, "amove": true})
	var sel: Array[int] = []
	for id in ids[0]:
		sel.append(id)
	ctrl.select_ids(sel)
	_look(c, c, 34.0)
	await _game_secs(2.0)
	# Se alterna encendida y apagada para que la pelea pese igual en las dos mediciones.
	var fps_on := 0.0
	var fps_off := 0.0
	for r in 3:
		fps_on += await _measure(1.0) / 3.0
		main.hud._mundo.visible = false
		fps_off += await _measure(1.0) / 3.0
		main.hud._mundo.visible = true
	print("perf mundo: %.1f fps con la capa · %.1f fps sin la capa (%d entidades activas)" % [fps_on, fps_off, sim.actives.size()])
	_key(KEY_ALT, true)
	await _frames(3)
	await _shot("mundo_batalla_alt")
	_key(KEY_ALT, false)
	main.hud._mundo.on_events([{"t": "age", "player": 0, "age": 2, "hito": ""}])
	_look(b.x + 2, b.y + 2, 28.0)
	await _frames(20)
	await _shot("mundo_edad")


func _measure(secs: float) -> float:
	var t0 := Time.get_ticks_usec()
	var n := 0
	while Time.get_ticks_usec() - t0 < int(secs * 1000000.0):
		await process_frame
		n += 1
	return n / ((Time.get_ticks_usec() - t0) / 1000000.0)
