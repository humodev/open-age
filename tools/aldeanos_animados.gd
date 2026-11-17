extends SceneTree
## Revisión de los aldeanos animados (proceso/27-animaciones).
##
##   godot --path . -s tools/aldeanos_animados.gd -- --modo=poses [--dir=screenshots/anim]
##       Vitrina: los seis pueblos en fila, cada uno en una acción, sin partida.
##   godot --path . -s tools/aldeanos_animados.gd -- --modo=trabajo --civ=guaranies --terreno=llano --nofog --mute [--mirar=madera|piedra|alimento|riqueza] [--seguir=S]
##       Partida: aldeanos talando, picando, cosechando y construyendo de cerca; captura y, con
##       --seguir, S segundos más (para grabar con --write-movie).
##   godot --path . -s tools/aldeanos_animados.gd -- --modo=fps --civ=guaranies --terreno=llano --nofog --mute [--animaciones=0]
##       200 aldeanos en pantalla (100 caminando, 100 trabajando): cuadros por segundo.

var args := {}
var dir := "screenshots/anim"
var main: Node


func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		var kv := a.trim_prefix("--").split("=", true, 1)
		args[kv[0]] = kv[1] if kv.size() > 1 else "1"
	dir = args.get("dir", dir)
	DirAccess.make_dir_recursive_absolute(dir)
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	RenderingServer.viewport_set_measure_render_time(root.get_viewport_rid(), true)
	match args.get("modo", "poses"):
		"poses":
			_poses.call_deferred()
		_:
			main = load("res://src/game/main.tscn").instantiate()
			root.add_child(main)
			_partida.call_deferred()


func _frames(n: int) -> void:
	for i in n:
		await process_frame


func _shot(name: String) -> void:
	await _frames(3)
	var img := root.get_texture().get_image()
	img.save_png("%s/%s.png" % [dir, name])
	print("captura: %s/%s.png" % [dir, name])


# ---------------------------------------------------------------- Vitrina sin partida

func _poses() -> void:
	var w := Node3D.new()
	root.add_child(w)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-50, 150, 0)
	sun.shadow_enabled = true
	w.add_child(sun)
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR
	env.environment.background_color = Color(0.62, 0.7, 0.76)
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color(0.7, 0.72, 0.75)
	env.environment.ambient_light_energy = 0.8
	w.add_child(env)
	var floor := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(40, 40)
	floor.mesh = pm
	var fm := StandardMaterial3D.new()
	fm.albedo_color = Color(0.45, 0.52, 0.32)
	floor.material_override = fm
	w.add_child(floor)
	var cam := Camera3D.new()
	w.add_child(cam)
	cam.fov = 30
	var civs: Array = str(args.get("civs", "tawantinsuyu,mapuches,guaranies,etiopia,palmares,ayutthaya")).split(",")
	var acts: Array = str(args.get("acciones", "quieto,caminar,talar,picar,cosechar,construir,juntar,pegar,morir")).split(",")
	# --tiempos=0.1,0.3,…: una sola acción en varios momentos del ciclo (para revisar herramientas).
	var tiempos: Array = str(args.get("tiempos", "")).split(",", false)
	if not tiempos.is_empty():
		var one: String = acts[0]
		acts = []
		for x in tiempos:
			acts.append(one)
	var team := [Color("2f6fd6"), Color("d63a2f"), Color("e0b21c"), Color("3aa04a"), Color("8a4ad6"), Color("e07a1c")]
	var avs: Array = []
	for i in civs.size():
		var civ: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/civs/%s.json" % civs[i]))
		var st: Dictionary = civ.get("estilo", {})
		for j in acts.size():
			var av := AldeanoAnimado.crear(st, team[i], 1.0)
			var n: Node3D = av.node
			n.position = Vector3((j - acts.size() / 2.0) * 0.9, 0, -i * 1.2)
			n.rotation.y = 0.5
			w.add_child(n)
			avs.append([av, acts[j], st, team[i], float(tiempos[j]) if not tiempos.is_empty() else -1.0])
	cam.position = Vector3(0.5, 4.2, 7.5)
	cam.look_at(Vector3(0, 0.3, -3.0))
	var t := float(args.get("t", "0.55"))
	for a in avs:
		_pose(a[0], a[1], a[2], a[3], t if a[4] < 0.0 else a[4])
	if args.has("lado"):
		for a in avs:
			(a[0].node as Node3D).rotation.y = -PI / 2
	await _shot("poses")
	# De cerca, un pueblo por vez: el primero de la fila de cada acción.
	cam.fov = 22
	cam.position = Vector3(0.0, 1.6, 4.6)
	cam.look_at(Vector3(0, 0.45, 0))
	await _shot("poses_cerca")
	quit(0)


## Pone un aldeano de la vitrina en una acción, avanzado `t` segundos.
func _pose(av: AldeanoAnimado.Estado, act: String, st: Dictionary, team: Color, t: float) -> void:
	var acts: Dictionary = AldeanoAnimado.cfg().get("acciones", {})
	var tool: String = acts.get(act, {}).get("herramienta", "") if not args.has("herramienta") else str(args["herramienta"])
	av.mi.mesh = AldeanoAnimado.malla(st, team, tool, Palette.RES.get("madera", Color.WHITE) if act == "caminar" else Color(0, 0, 0, 0))
	var ap: AnimationPlayer = av.ap
	ap.play(acts.get(act, {}).get("anim", "Idle_A"))
	ap.advance(t * ap.current_animation_length if act != "morir" else 2.0)


# ---------------------------------------------------------------- En partida

func _partida() -> void:
	await _frames(5)
	var sim: Sim = main.sim
	var b: Vector2i = sim.bases[0]
	for k in sim.players[0]["res"]:
		sim.players[0]["res"][k] = 5000
	if args.get("modo") == "fps":
		await _fps(sim, b)
		quit(0)
		return
	# Aldeanos a cada trabajo, cerca de la base.
	var vill: Array[int] = []
	for e in sim.actives:
		if e.owner == 0 and e.fn == "civil" and e.inside < 0:
			vill.append(e.id)
	for i in 8:
		var t := sim.map.nearest_free(b.x + 4 + i % 4, b.y + 4 + i / 4, 6, 0)
		vill.append(sim.spawn_unit("aldeano", 0, t.x * 1000 + 500, t.y * 1000 + 500).id)
	var groups := {"madera": vill.slice(0, 4), "piedra": vill.slice(4, 7), "riqueza": vill.slice(7, 9), "alimento": vill.slice(9, 11)}
	var spot := Vector2(b.x + 2, b.y + 2)
	for kind in groups:
		var r: SimEntity = sim.find_resource(0, kind, b.x * 1000, b.y * 1000, 40000)
		if r != null:
			# Cada uno a un recurso distinto cerca del primero (árboles vecinos), para que no se amontonen.
			var ids: Array = groups[kind]
			for n in ids.size():
				var rr: SimEntity = sim.find_resource(0, kind, r.x + (n % 2) * 2500 - 1200, r.y + (n / 2) * 2500 - 1200, 4000) if kind == "madera" else r
				sim.push_command({"t": "target", "player": 0, "ids": [ids[n]], "target": (rr if rr != null else r).id})
			if kind == "madera":
				spot = Vector2(r.x / 1000.0, r.y / 1000.0)
	# Una casa en obra con tres constructores.
	var bt := sim.map.nearest_free(b.x + 6, b.y - 4, 8, 0)
	var builders: Array = vill.slice(11, 14)
	sim.push_command({"t": "build", "player": 0, "ids": builders, "type": "casa", "tx": bt.x, "ty": bt.y})
	await _game_secs(sim, 14.0)
	var cam_at: String = args.get("mirar", "madera")
	var focus := spot
	if cam_at != "madera":
		var r2: SimEntity = sim.find_resource(0, cam_at, b.x * 1000, b.y * 1000, 40000)
		if r2 != null:
			focus = Vector2(r2.x / 1000.0, r2.y / 1000.0)
	main.cam.look_at_point(Vector3(focus.x, 0, focus.y))
	main.cam.zoom = float(args.get("zoom", "9"))
	main.cam.set("_zoom_target", main.cam.zoom)
	await _frames(6)
	var civ: String = args.get("civ", "x")
	await _shot("trabajo_%s_%s" % [civ, cam_at])
	# Video: correr con --write-movie video.avi --fixed-fps 30 y --seguir=S (segundos de juego
	# después de la captura); después se recorta con ffmpeg (proceso/27-animaciones/README.md).
	var seguir := float(args.get("seguir", "0"))
	if seguir > 0.0:
		print("video desde el cuadro ", Engine.get_frames_drawn())
		await _game_secs(sim, seguir)
	quit(0)


func _game_secs(sim: Sim, s: float) -> void:
	var until: int = sim.tick + int(s * 1000.0 / sim.tick_ms)
	while sim.tick < until:
		await process_frame


## 200 aldeanos en pantalla: la mitad camina de un lado a otro y la otra mitad tala.
func _fps(sim: Sim, b: Vector2i) -> void:
	var c := b + Vector2i(10, 10)
	var walkers := []
	var workers := []
	for i in 200:
		var t := sim.map.nearest_free(c.x - 7 + i % 14, c.y - 7 + i / 14, 10, 0)
		var u := sim.spawn_unit("aldeano", 0, t.x * 1000 + 500, t.y * 1000 + 500)
		(walkers if i % 2 == 0 else workers).append(u.id)
	var tree: SimEntity = sim.find_resource(0, "madera", c.x * 1000, c.y * 1000, 40000)
	if tree != null:
		sim.push_command({"t": "target", "player": 0, "ids": workers, "target": tree.id})
	main.cam.look_at_point(Vector3(c.x, 0, c.y))
	main.cam.zoom = float(args.get("zoom", "34"))
	main.cam.set("_zoom_target", main.cam.zoom)
	var go := true
	var frames := 0
	var t0 := 0
	var times: Array[float] = []
	var view_ms: Array[float] = []
	var gpu_ms: Array[float] = []
	for round in 6:
		sim.push_command({"t": "move", "player": 0, "ids": walkers, "x": (c.x + (8 if go else -8)) * 1000, "y": (c.y + (6 if go else -6)) * 1000})
		go = not go
		var t1 := Time.get_ticks_usec()
		var f0 := Engine.get_process_frames()
		main.view.render_us = 0
		AldeanoAnimado.us_actualizar = 0
		AldeanoAnimado.us_avance = 0
		AldeanoAnimado.n_play = 0
		AldeanoAnimado.n_malla = 0
		var proc := 0.0
		var until: int = sim.tick + int(4.0 * 1000.0 / sim.tick_ms)
		while sim.tick < until:
			await process_frame
			proc += Performance.get_monitor(Performance.TIME_PROCESS)
		var fr := Engine.get_process_frames() - f0
		var secs := (Time.get_ticks_usec() - t1) / 1000000.0
		if round >= 1:
			times.append(fr / secs)
			view_ms.append(main.view.render_us / 1000.0 / fr)
			print("  ronda %d: %.1f fps · proceso %.2f ms · vista %.2f ms · actualizar %.2f ms (avance %.2f ms) por cuadro" % [round, fr / secs, proc * 1000.0 / fr, main.view.render_us / 1000.0 / fr, AldeanoAnimado.us_actualizar / 1000.0 / fr, AldeanoAnimado.us_avance / 1000.0 / fr])
			print("    play por cuadro %.1f · malla por cuadro %.1f" % [AldeanoAnimado.n_play / float(fr), AldeanoAnimado.n_malla / float(fr)])
			gpu_ms.append(RenderingServer.viewport_get_measured_render_time_gpu(root.get_viewport_rid()))
	var vis := 0
	for v in main.view.visuals.values():
		if v.has("anim"):
			vis += 1
	await _shot("fps_%s" % ("anim" if AldeanoAnimado.usa({"funcion": "civil"}) else "maqueta"))
	times.sort()
	view_ms.sort()
	print("vista (WorldView.render) ms por cuadro: mediana=%.2f %s · GPU ms: %s" % [view_ms[view_ms.size() / 2], str(view_ms), str(gpu_ms)])
	print("FPS animaciones=%s aldeanos animados=%d mediana=%.1f min=%.1f max=%.1f muestras=%s" % [args.get("animaciones", "data"), vis, times[times.size() / 2], times[0], times[-1], str(times)])
