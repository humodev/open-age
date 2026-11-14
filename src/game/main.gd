extends Node3D
## Arranque y bucle de ticks (docs/06-arquitectura.md, "Bucle").
##
## Argumentos (después de `--`):
##   --aivai            IA contra IA, la cámara sigue al jugador 0
##   --seed=N           semilla del mapa
##   --speed=N          multiplicador de velocidad inicial
##   --shot=ruta.png    guarda una captura y sale
##   --shot-at=S        segundos de juego antes de la captura
##   --estilo=pacifica|normal|acosadora|agresiva  estilo de juego de la IA
##   --cam=x,z,zoom[,inclinación]  posición de cámara para la captura
##   --select=tipo      selecciona entidades de ese tipo del jugador local antes de la captura
##   --demo=base|batalla  escena armada para revisar modelos y combate
##   --menu             fuerza el menú de inicio (sin argumentos se abre solo)
##   --terreno=<clave de reglas.json "terrenos"> tipo de mapa (llano, valle, delta…)
##   --civ=clave        civilización propia (tawantinsuyu, mapuches, guaranies, etiopia, palmares, ayutthaya, azar)
##   --rival=clave      civilización de la IA rival
##   --campana=clave --mision=N  juega una misión de campaña (N desde 0)
##   --dificultad=facil|normal|dificil
##   --nofog            sin niebla de guerra (automático en --aivai)
##   --autotest         prueba de punta a punta con eventos reales de mouse y teclado
##   --panel=a,b        abre paneles de información antes de la captura (economia, edad, pueblo, sucesos, puntaje, fin)

const MAX_STEPS_PER_FRAME := 8

var sim: Sim
var view: WorldView
var cam: RtsCamera
var ctrl: Controller
var hud: Hud
var local := 0
var speed := 1.0
var paused := false
var _acc := 0.0
var _args := {}
var _seed := 0
var _shot_done := false
var _menu_mode := false
var _menu: MainMenu
var _drift := 0.0
var audio: GameAudio
var _replay_meta := {}
var _perf_t := 0.0
const REPLAY := "user://ultima_partida.json"


func _ready() -> void:
	for a in OS.get_cmdline_user_args():
		var kv := a.trim_prefix("--").split("=", true, 1)
		_args[kv[0]] = kv[1] if kv.size() > 1 else "1"
	_seed = int(_args.get("seed", str(randi() % 100000)))
	speed = float(_args.get("speed", "1"))
	_menu_mode = _args.is_empty() or _args.has("menu")
	# --- escala --- (--ventana=ANCHOxALTO: ventana de ese tamaño, para capturas a otras resoluciones)
	if _args.has("ventana"):
		_ventana(str(_args["ventana"]))
	# --- fin escala ---
	_build_environment()
	audio = GameAudio.new()
	audio.name = "Audio"
	add_child(audio)
	if _args.has("shot") or _args.has("autotest") or _args.has("mute"):
		AudioServer.set_bus_mute(0, true)
	_new_game()


# --- escala ---
## Pone la ventana en modo ventana con el tamaño pedido ("1366x768").
func _ventana(spec: String) -> void:
	var p := spec.to_lower().split("x")
	if p.size() != 2 or not p[0].is_valid_int() or not p[1].is_valid_int():
		push_warning("--ventana espera ANCHOxALTO, por ejemplo 1366x768")
		return
	var sz := Vector2i(int(p[0]), int(p[1]))
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	# Sin tope: una ventana de 3840×2160 en una pantalla de 1080 se sale de la pantalla,
	# pero se dibuja entera y la captura sale a esa resolución.
	DisplayServer.window_set_max_size(Vector2i.ZERO)
	DisplayServer.window_set_size(sz)
	get_window().size = sz
# --- fin escala ---


func _build_environment() -> void:
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-52, 150, 0)
	sun.light_color = Color(1.0, 0.95, 0.86)
	sun.light_energy = 1.35
	sun.shadow_enabled = true
	sun.shadow_blur = 1.6
	sun.directional_shadow_max_distance = 110.0
	sun.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_4_SPLITS
	sun.shadow_bias = 0.03
	sun.shadow_normal_bias = 1.2
	add_child(sun)
	var fill := DirectionalLight3D.new()
	fill.rotation_degrees = Vector3(-35, -40, 0)
	fill.light_color = Color(0.7, 0.8, 1.0)
	fill.light_energy = 0.25
	add_child(fill)

	var env := Environment.new()
	var sky_mat := ProceduralSkyMaterial.new()
	sky_mat.sky_top_color = Color(0.36, 0.5, 0.68)
	sky_mat.sky_horizon_color = Color(0.74, 0.78, 0.8)
	sky_mat.ground_horizon_color = Color(0.5, 0.52, 0.48)
	sky_mat.ground_bottom_color = Color(0.25, 0.27, 0.24)
	var sky := Sky.new()
	sky.sky_material = sky_mat
	env.background_mode = Environment.BG_SKY
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.ambient_light_energy = 0.75
	env.tonemap_mode = Environment.TONE_MAPPER_AGX
	env.tonemap_exposure = 1.05
	env.ssao_enabled = true
	env.ssao_radius = 1.4
	env.ssao_intensity = 2.2
	env.ssao_power = 1.4
	env.glow_enabled = true
	env.glow_intensity = 0.25
	env.glow_bloom = 0.04
	env.fog_enabled = true
	env.fog_light_color = Color(0.68, 0.74, 0.8)
	env.fog_density = 0.0012
	env.fog_sky_affect = 0.0
	env.adjustment_enabled = true
	env.adjustment_saturation = 1.12
	env.adjustment_contrast = 1.04
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)
	_sun = sun
	_fill = fill
	_env = env
	_sky_mat = sky_mat


# --- ambiente por bioma (etapa 16, paisaje) ---
# Luz, cielo, niebla y posproceso según el tipo de mapa (data/ambiente.json).
var _sun: DirectionalLight3D
var _fill: DirectionalLight3D
var _env: Environment
var _sky_mat: ProceduralSkyMaterial


func _apply_ambiente(terrain: String) -> void:
	var a := Ambiente.of(terrain)
	var so: Dictionary = a["sol"]
	_sun.rotation_degrees = Vector3(-float(so["altura"]), float(so["rumbo"]), 0)
	_sun.light_color = Ambiente.col(so["color"])
	_sun.light_energy = Ambiente.pct(so["energia"])
	# Sombras suaves: el desenfoque es casi gratis; el tamaño del sol (sombras que se
	# abren con la distancia, PCSS) cuesta un 25 % de cuadros, así que va en 0.
	_sun.light_angular_distance = Ambiente.pct(so["tamano"])
	_sun.shadow_blur = Ambiente.pct(so["desenfoque"])
	_fill.light_color = Ambiente.col(a["relleno"]["color"])
	_fill.light_energy = Ambiente.pct(a["relleno"]["energia"])
	var ci: Dictionary = a["cielo"]
	_sky_mat.sky_top_color = Ambiente.col(ci["cenit"])
	_sky_mat.sky_horizon_color = Ambiente.col(ci["horizonte"])
	_sky_mat.ground_horizon_color = Ambiente.col(ci["suelo"])
	_sky_mat.ground_bottom_color = Ambiente.col(ci["suelo"]).darkened(0.5)
	_sky_mat.sun_angle_max = 20.0
	_env.ambient_light_energy = Ambiente.pct(a["ambiente"])
	_env.tonemap_exposure = Ambiente.pct(a["exposicion"])
	_env.adjustment_saturation = Ambiente.pct(a["saturacion"])
	_env.adjustment_contrast = Ambiente.pct(a["contraste"])
	# Niebla de distancia: empieza lejos de la cámara y crece suave hasta el horizonte.
	var ni: Dictionary = a["niebla"]
	_env.fog_mode = Environment.FOG_MODE_DEPTH
	_env.fog_light_color = Ambiente.col(ni["color"])
	_env.fog_density = Ambiente.pct(ni["maxima"])
	_env.fog_depth_begin = float(ni["desde"])
	_env.fog_depth_end = float(ni["hasta"])
	_env.fog_depth_curve = 1.6
	_env.fog_aerial_perspective = 0.3
	_env.fog_sky_affect = 0.0
	# Oclusión ambiental y brillo moderados.
	_env.ssao_radius = 1.2
	_env.ssao_intensity = 1.8
	_env.ssao_power = 1.5
	_env.ssao_detail = 0.6
	_env.glow_intensity = 0.3
	_env.glow_bloom = 0.05
	_env.glow_hdr_threshold = 1.1
# --- fin ambiente por bioma ---


func _new_game() -> void:
	if _args.has("campana"):
		_new_mission()
		return
	var civ_keys: Array = SimData.load_default().civs.keys().filter(func(k: String) -> bool: return not SimData.load_default().civs[k].civ.get("solo_ia", false))
	civ_keys.sort()
	var mine: String = _args.get("civ", "")
	var rival: String = _args.get("rival", "")
	var rng := RandomNumberGenerator.new()
	rng.seed = _seed
	if mine == "" or mine == "azar":
		mine = civ_keys[rng.randi() % civ_keys.size()]
	if rival == "" or rival == "azar":
		rival = civ_keys[rng.randi() % civ_keys.size()]
	if _args.has("replay") and FileAccess.file_exists(REPLAY):
		var r: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(REPLAY))
		_seed = int(r["semilla"])
		sim = Sim.new(_seed, 2, null, Sim.intify(r["opciones"]))
		sim.ais = []
		for pid in r["ias"]:
			var rai := SimAI.new(sim, int(pid), r.get("dificultad", "normal"))
			rai.personality = r.get("estilo", "normal")
			sim.ais.append(rai)
		sim.schedule(Sim.intify(r["comandos"]))
		_build_scene(true)
		ctrl.enabled = false
		hud.notify("Repetición de la última partida", 4.0)
		return
	var opts := {"terreno": _args.get("terreno", ""), "civs": [mine, rival]}
	sim = Sim.new(_seed, 2, null, opts)
	var aivai := _args.has("aivai") or _menu_mode
	sim.ais = []
	var ai_ids := []
	for pid in sim.players.size():
		if pid != local or aivai:
			var ai := SimAI.new(sim, pid, _args.get("dificultad", "normal"))
			ai.personality = _args.get("estilo", "normal")
			sim.ais.append(ai)
			ai_ids.append(pid)
	opts["terreno"] = sim.terrain
	_replay_meta = {"semilla": _seed, "opciones": opts, "ias": ai_ids, "dificultad": _args.get("dificultad", "normal"), "estilo": _args.get("estilo", "normal")}
	_build_scene(aivai)


func _build_scene(aivai: bool) -> void:
	if _args.has("demo"):
		_demo(_args["demo"])

	view = WorldView.new()
	view.name = "World"
	view.fog_on = not (aivai or _args.has("nofog") or _args.get("demo", "") == "batalla")
	add_child(view)
	view.setup(sim, local)
	_apply_ambiente(sim.terrain) # --- ambiente por bioma ---

	cam = RtsCamera.new()
	cam.name = "Camera"
	cam.map_size = sim.map.n
	add_child(cam)
	var base := sim.bases[local]
	cam.look_at_point(Vector3(base.x + 6, 0, base.y + 6))
	if _args.has("cam") and not _args.has("shot"):
		var cc: PackedStringArray = (_args["cam"] as String).split(",")
		cam.look_at_point(Vector3(float(cc[0]), 0, float(cc[1])))
		if cc.size() > 2:
			cam.zoom = float(cc[2])
			cam.set("_zoom_target", float(cc[2]))
	if _args.has("shot"):
		cam.edge_pan = false

	ctrl = Controller.new()
	ctrl.name = "Controller"
	add_child(ctrl)
	ctrl.setup(sim, view, cam, local)

	var layer := CanvasLayer.new()
	layer.name = "UI"
	add_child(layer)
	hud = Hud.new()
	layer.add_child(hud)
	hud.setup(self, sim, ctrl, cam, local)
	ctrl.hud = hud
	audio.sim = sim
	audio.cam = cam
	audio.local = local
	audio.ambient(true)
	audio.music("menu" if _menu_mode else "paz")
	if _menu_mode:
		hud.visible = false
		ctrl.enabled = false
		cam.edge_pan = false
		speed = 1.0
		_menu = MainMenu.new()
		layer.add_child(_menu)
		_menu.play.connect(func(sd: int, civ: String, rival: String) -> void: _start({"seed": str(sd), "civ": civ, "rival": rival, "dificultad": _menu.difficulty(), "estilo": _menu.style(), "terreno": _menu.terrain()}))
		_menu.watch.connect(func(sd: int, civ: String, rival: String) -> void: _start({"aivai": "1", "seed": str(sd), "civ": civ, "rival": rival, "estilo": _menu.style(), "dificultad": _menu.difficulty(), "terreno": _menu.terrain()}))
		_menu.campaigns.connect(_open_campaigns.bind(layer))
		_menu.replay.connect(func() -> void: _start({"replay": "1"}))
		if _args.get("abrir", "") == "campanas":
			_open_campaigns.call_deferred(layer)
		elif _args.get("abrir", "") == "intro":
			layer.add_child(CampaignUI.story(_mission_data("palmares", 0), false, [["Comenzar", func() -> void: pass], ["Volver", func() -> void: pass]], "palmares"))
	if _args.has("autotest"):
		cam.edge_pan = false
		_autotest.call_deferred()
	if _args.has("shot"):
		# Captura reproducible: ninguna entrada real afecta la partida.
		ctrl.enabled = false
		get_viewport().gui_disable_input = true


func _demo(kind: String) -> void:
	var b := sim.bases[0]
	if kind == "base":
		var place := func(type: String, tx0: int, ty0: int, built: bool) -> void:
			if not sim.dp(0).edificios.has(type):
				return
			var spot := Vector2i(-1, -1)
			for r in 8:
				for dy in range(-r, r + 1):
					for dx in range(-r, r + 1):
						if spot.x < 0 and sim.can_place(type, tx0 + dx, ty0 + dy, 0):
							spot = Vector2i(tx0 + dx, ty0 + dy)
			if spot.x >= 0:
				var e := sim.spawn_building(type, 0, spot.x, spot.y, built)
				if not built:
					e.build_time = sim.dp(0).build_time_of(type, 1)
					e.progress = e.build_time / 2
					e.hp = e.hp_max / 2
		place.call("casa", b.x - 3, b.y + 6, true)
		place.call("casa", b.x - 3, b.y + 9, true)
		place.call("cuartel", b.x + 6, b.y + 7, true)
		place.call("granja", b.x + 5, b.y - 1, true)
		place.call("granja", b.x + 5, b.y + 3, true)
		place.call("torre", b.x + 1, b.y + 8, true)
		place.call("deposito", b.x - 4, b.y - 2, true)
		var extra_i := 0
		for k in sim.dp(0).civ.get("edificios_nuevos", {}):
			var kd: Dictionary = sim.dp(0).edificios[k]
			if kd.get("avanza_edad", false) or kd.get("linea", false):
				continue
			place.call(k, b.x - 8 + extra_i * 5, b.y + 14, true)
			extra_i += 1
		place.call(sim.dp(0).hitos[0][0], b.x + 10, b.y + 1, false)
		place.call(sim.dp(0).hitos[0][1], b.x - 6, b.y + 12, true)
		for i in 9:
			var wt := Vector2i(b.x - 8 + i, b.y - 5)
			if sim.dp(0).edificios.has("empalizada") and sim.can_place("empalizada", wt.x, wt.y, 0):
				sim.spawn_building("puerta" if i == 4 else "empalizada", 0, wt.x, wt.y, true)
		var showcase: Array = ["guerrero", "hondero", "lancero"]
		for k in sim.dp(0).civ.get("unidades_nuevas", {}):
			showcase.append(k)
		if sim.dp(0).unidades.has("jinete"):
			showcase.append("jinete")
		for i in showcase.size():
			sim.spawn_unit(showcase[i], 0, (b.x + 10 + i % 4) * 1000 + 500, (b.y + 7 + i / 4) * 1000 + 500)
		for i in 0:
			sim.spawn_unit(["guerrero", "hondero", "lancero"][i % 3], 0, (b.x + 10 + i % 3) * 1000 + 500, (b.y + 7 + i / 3) * 1000 + 500)
	elif kind == "batalla":
		var c := sim.map.n / 2
		var ids := [[], []]
		for pid in 2:
			var types: Array = ["guerrero", "hondero", "lancero"]
			for k in sim.dp(pid).civ.get("unidades_nuevas", {}):
				var ud: Dictionary = sim.dp(pid).unidades[k]
				if ud.get("funcion", "") in ["choque", "distancia", "linea"]:
					types.append(k)
			for i in 30:
				var x := (c - 7 + pid * 14 + (i % 5) * (1 if pid == 0 else -1)) * 1000 + 500
				var y := (c - 4 + i / 5) * 1000 + 500
				var u := sim.spawn_unit(types[i % 3], pid, x, y)
				ids[pid].append(u.id)
		sim.push_command({"t": "move", "player": 0, "ids": ids[0], "x": (c + 6) * 1000, "y": c * 1000, "amove": true})
		sim.push_command({"t": "move", "player": 1, "ids": ids[1], "x": (c - 6) * 1000, "y": c * 1000, "amove": true})


func _start(args: Dictionary) -> void:
	_args = args
	_menu_mode = false
	speed = 1.0
	restart(int(args.get("seed", str(randi() % 100000))))


# ---------------------------------------------------------------- Campañas

func _open_campaigns(layer: CanvasLayer) -> void:
	var ui := CampaignUI.new()
	layer.add_child(ui)
	_menu.visible = false
	ui.back.connect(func() -> void:
		ui.queue_free()
		_menu.visible = true)
	ui.start_mission.connect(func(civ: String, idx: int) -> void:
		var m: Dictionary = _mission_data(civ, idx)
		var intro := CampaignUI.story(m, false, [["Comenzar", func() -> void: _start({"campana": civ, "mision": str(idx)})], ["Volver", func() -> void: layer.get_child(layer.get_child_count() - 1).queue_free()]], civ)
		layer.add_child(intro))


static func _mission_data(civ: String, idx: int) -> Dictionary:
	var camp: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/campanas/%s.json" % civ))
	return camp["misiones"][idx]


func _campaign_size(civ: String) -> int:
	var camp: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/campanas/%s.json" % civ))
	return (camp["misiones"] as Array).size()


## Arma una misión de campaña: la simulación la crea el motor de escenarios.
func _new_mission() -> void:
	var key: String = _args["campana"]
	var idx := int(_args.get("mision", "0"))
	var camp: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/campanas/%s.json" % key))
	sim = SimScenario.create(camp["misiones"][idx], camp["civ"])
	_build_scene(false)


## Fin de misión: epílogo si se gana, y opciones para seguir.
func mission_over(result: String) -> void:
	var civ: String = _args["campana"]
	var idx := int(_args.get("mision", "0"))
	var m := _mission_data(civ, idx)
	var buttons: Array = []
	if result == "victoria":
		CampaignUI.mark_won(civ, idx)
		if idx + 1 < _campaign_size(civ):
			buttons.append(["Siguiente misión", func() -> void: _start({"campana": civ, "mision": str(idx + 1)})])
	else:
		buttons.append(["Reintentar", func() -> void: _start({"campana": civ, "mision": str(idx)})])
		m = m.duplicate()
		m["epilogo"] = ["La historia no terminó así. Volvé a intentarlo."]
	buttons.append(["Menú principal", func() -> void: to_menu()])
	paused = true
	hud.get_parent().add_child(CampaignUI.story(m, true, buttons, civ))


## Guarda la partida como repetición (solo escaramuzas con jugador humano).
func save_replay() -> void:
	if _replay_meta.is_empty() or _menu_mode or _args.has("aivai") or _args.has("replay") or sim == null or sim.recording.is_empty():
		return
	var r := _replay_meta.duplicate()
	r["comandos"] = sim.recording
	var f := FileAccess.open(REPLAY, FileAccess.WRITE)
	if f != null:
		f.store_string(JSON.stringify(r))


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		save_replay()


func to_menu() -> void:
	_args = {}
	_menu_mode = true
	restart()


func restart(seed_value: int = -1) -> void:
	save_replay()
	for n in [view, cam, ctrl, hud.get_parent()]:
		n.queue_free()
	_seed = seed_value if seed_value >= 0 else randi() % 100000
	paused = false
	_acc = 0.0
	await get_tree().process_frame
	_new_game()


func set_paused(p: bool) -> void:
	paused = p


func _unhandled_key_input(event: InputEvent) -> void:
	var k := event as InputEventKey
	if not k.pressed or k.echo or _menu_mode:
		return
	if k.physical_keycode == KEY_F1:
		hud._toggle_help()
	elif k.physical_keycode == KEY_F3:
		speed = 2.0 if speed == 1.0 else (4.0 if speed == 2.0 else 1.0)
	elif k.physical_keycode == KEY_PAUSE or k.physical_keycode == KEY_F10:
		hud.toggle_menu()


func _process(delta: float) -> void:
	if not paused:
		_acc += delta * speed
		var tick_s := sim.tick_ms / 1000.0
		var steps := 0
		while _acc >= tick_s and steps < MAX_STEPS_PER_FRAME:
			sim.step()
			view.on_tick(sim.events)
			hud.on_events(sim.events)
			audio.on_events(sim.events)
			_acc -= tick_s
			steps += 1
		if steps == MAX_STEPS_PER_FRAME:
			_acc = 0.0
		view.render(_acc / tick_s, delta)
		if _menu_mode:
			# Cámara de fondo que recorre el mapa despacio.
			_drift += delta * 0.035
			var c := sim.map.n / 2.0
			cam.look_at_point(Vector3(c + cos(_drift) * 30.0, 0, c + sin(_drift * 1.3) * 30.0))
	else:
		view.render(1.0, 0.0)
	_maybe_shot()
	if _args.has("perf"):
		_perf_t += delta
		if _perf_t >= 5.0:
			_perf_t = 0.0
			print("perf: %d fps · tick %d · %d entidades activas · %d objetos dibujados" % [Engine.get_frames_per_second(), sim.tick, sim.actives.size(), RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_OBJECTS_IN_FRAME)])


func _maybe_shot() -> void:
	if not _args.has("shot") or _shot_done:
		return
	var at := float(_args.get("shot-at", "2"))
	if sim.tick * sim.tick_ms / 1000.0 < at:
		return
	_shot_done = true
	if _args.has("cam"):
		var c: PackedStringArray = (_args["cam"] as String).split(",")
		cam.look_at_point(Vector3(float(c[0]), 0, float(c[1])))
		if c.size() > 2:
			cam.zoom = float(c[2])
			cam.set("_zoom_target", float(c[2]))
		if c.size() > 3:
			cam.pitch_deg = float(c[3])
	if _args.has("select"):
		var ids: Array[int] = []
		for e in sim.actives:
			if e.owner == local and e.type == _args["select"]:
				ids.append(e.id)
		ctrl.select_ids(ids)
	# --- paneles --- (--panel=economia,edad,pueblo,sucesos,puntaje,fin para las capturas)
	if _args.has("panel") and hud.paneles != null:
		for w in (_args["panel"] as String).split(","):
			if w == "fin":
				hud.paneles.show_end(local)
			else:
				hud.paneles.toggle(w)
	# --- fin paneles ---
	paused = true
	for i in 12:
		await get_tree().process_frame
	var img := get_viewport().get_texture().get_image()
	var path: String = _args["shot"]
	img.save_png(path)
	print("captura: ", path)
	get_tree().quit()


# ---------------------------------------------------------------- Prueba de punta a punta

func _frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame


func _mouse(pos: Vector2, button: int, pressed: bool) -> void:
	ctrl.mouse_override = pos
	var mv := InputEventMouseMotion.new()
	mv.position = pos
	mv.global_position = pos
	Input.parse_input_event(mv)
	if button == 0:
		return
	var mb := InputEventMouseButton.new()
	mb.position = pos
	mb.global_position = pos
	mb.button_index = button
	mb.pressed = pressed
	Input.parse_input_event(mb)


func _key_tap(code: int) -> void:
	for pressed in [true, false]:
		var k := InputEventKey.new()
		k.physical_keycode = code
		k.keycode = code
		k.pressed = pressed
		Input.parse_input_event(k)


func _screen(x_tiles: float, z_tiles: float) -> Vector2:
	return cam.cam.unproject_position(Vector3(x_tiles, 0, z_tiles))


func _autotest() -> void:
	var results: Array[String] = []
	var ok := true
	var check := func(name: String, cond: bool) -> void:
		results.append(("OK    " if cond else "FALLO ") + name)
	await _frames(20)
	var base := sim.bases[local]
	cam.look_at_point(Vector3(base.x + 2, 0, base.y + 2))
	await _frames(5)

	# 1. Selección por arrastre.
	var lo := Vector2(INF, INF)
	var hi := Vector2(-INF, -INF)
	for e in sim.actives:
		if e.owner == local and e.fn == "civil":
			var sp := cam.cam.unproject_position(WorldView.to_world(e.x, e.y, 0.3))
			lo = lo.min(sp)
			hi = hi.max(sp)
	_mouse(lo - Vector2(30, 30), MOUSE_BUTTON_LEFT, true)
	await _frames(2)
	_mouse((lo + hi) / 2, 0, false)
	await _frames(2)
	_mouse(hi + Vector2(30, 30), 0, false)
	await _frames(2)
	_mouse(hi + Vector2(30, 30), MOUSE_BUTTON_LEFT, false)
	await _frames(3)
	var n_vill := 0
	for e in sim.actives:
		if e.owner == local and e.fn == "civil" and e.inside < 0:
			n_vill += 1
	var sel_vill := 0
	for e in ctrl.selected_entities():
		if e.fn == "civil":
			sel_vill += 1
	check.call("selección por arrastre de los %d aldeanos (%d)" % [n_vill, sel_vill], sel_vill == n_vill)

	# 2. Clic derecho en arbustos: recolectar.
	var bush: SimEntity = sim.find_resource(local, "alimento", base.x * 1000, base.y * 1000, 30000)
	var bush_sp := cam.cam.unproject_position(WorldView.to_world(bush.x, bush.y, 0.2))
	_mouse(bush_sp, MOUSE_BUTTON_RIGHT, true)
	_mouse(bush_sp, MOUSE_BUTTON_RIGHT, false)
	await _frames(40)
	var gathering := 0
	for e in sim.actives:
		if e.owner == local and e.fn == "civil" and e.order == SimEntity.Order.GATHER:
			gathering += 1
	check.call("clic derecho en arbustos pone a recolectar (%d)" % gathering, gathering >= ctrl.selection.size() - 1 and gathering > 0)

	# 3. Tecla Q y clic: casa.
	var spot := Vector2i(-1, -1)
	for r in range(5, 12):
		for d in range(-r, r + 1):
			if spot.x < 0 and sim.can_place("casa", base.x + d, base.y + r):
				spot = Vector2i(base.x + d, base.y + r)
	_key_tap(KEY_Q)
	await _frames(2)
	check.call("Q entra en modo de construcción", ctrl.mode == "place" and ctrl.place_type == "casa")
	var house_sp := _screen(spot.x + 1.0, spot.y + 1.0)
	_mouse(house_sp, 0, false)
	await _frames(3)
	_mouse(house_sp, MOUSE_BUTTON_LEFT, true)
	_mouse(house_sp, MOUSE_BUTTON_LEFT, false)
	await get_tree().create_timer(0.4).timeout
	var houses := 0
	for e in sim.actives:
		if e.owner == local and e.type == "casa":
			houses += 1
	check.call("clic coloca el cimiento de la casa", houses == 1)
	check.call("se descontó la madera (%d)" % sim.players[local]["res"]["madera"], sim.players[local]["res"]["madera"] == 150)

	# 4. Tecla H selecciona el centro; Q entrena un aldeano.
	_key_tap(KEY_H)
	await _frames(3)
	var centro: SimEntity = sim.by_id.get(ctrl.selection[0]) if ctrl.selection.size() == 1 else null
	check.call("H selecciona la capital", centro != null and (centro.capital or centro.type == "centro"))
	_key_tap(KEY_Q)
	await get_tree().create_timer(0.3).timeout
	check.call("Q en el centro encola un aldeano", centro != null and centro.queue.size() == 1)

	# 5. Grupo de control.
	var k := InputEventKey.new()
	k.physical_keycode = KEY_1
	k.keycode = KEY_1
	k.ctrl_pressed = true
	k.pressed = true
	Input.parse_input_event(k)
	k = k.duplicate()
	k.pressed = false
	Input.parse_input_event(k)
	await _frames(2)
	check.call("Ctrl+1 asigna el grupo", ctrl.groups.has(1))

	speed = 4.0
	# Espera hasta que entre el primer alimento (máximo 20 s reales).
	for i in 40:
		if sim.players[local]["stats"]["recolectado"] > 0:
			break
		await get_tree().create_timer(0.5).timeout
	var house_progress := 0
	for e in sim.actives:
		if e.owner == local and e.type == "casa":
			house_progress = e.progress
	check.call("los aldeanos construyen la casa (%d ms)" % house_progress, house_progress > 0)
	check.call("entra alimento al banco (%d)" % sim.players[local]["res"]["alimento"], sim.players[local]["stats"]["recolectado"] > 0)
	# 6. Empalizada por arrastre (C): un cimiento por casilla.
	var vill_ids: Array[int] = []
	for e in sim.actives:
		if e.owner == local and e.fn == "civil" and e.inside < 0:
			vill_ids.append(e.id)
	ctrl.select_ids(vill_ids)
	await _frames(2)
	if ctrl.villager_slots().get(10, "") == "empalizada":
		_key_tap(KEY_C)
	await _frames(2)
	# Una fila libre delante de la base (lejos del panel inferior).
	var row := base.y + 8
	for r in range(8, 14):
		var free := 0
		for dx in 6:
			if sim.can_place("empalizada", base.x + 4 + dx, base.y + r, local):
				free += 1
		if free == 6:
			row = base.y + r
			break
	var w0 := _screen(base.x + 4.5, row + 0.5)
	var w1 := _screen(base.x + 9.5, row + 0.5)
	_mouse(w0, 0, false)
	await _frames(3)
	_mouse(w0, MOUSE_BUTTON_LEFT, true)
	await _frames(2)
	_mouse(w1, 0, false)
	await _frames(3)
	_mouse(w1, MOUSE_BUTTON_LEFT, false)
	await get_tree().create_timer(0.4).timeout
	var walls := 0
	for e in sim.actives:
		if e.owner == local and e.type == "empalizada":
			walls += 1
	if ctrl.villager_slots().get(10, "") == "empalizada":
		check.call("arrastrar coloca una línea de empalizada (%d)" % walls, walls >= 5)

	# 7. Campana desde el centro (Z): los aldeanos se refugian y el centro dispara más.
	_key_tap(KEY_H)
	await _frames(3)
	_key_tap(KEY_Z)
	await get_tree().create_timer(3.0).timeout
	var inside := 0
	for e in sim.actives:
		if e.owner == local and e.inside >= 0:
			inside += 1
	check.call("la campana refugia aldeanos (%d)" % inside, inside >= 5)
	_key_tap(KEY_Z)
	await get_tree().create_timer(1.0).timeout
	inside = 0
	for e in sim.actives:
		if e.owner == local and e.inside >= 0:
			inside += 1
	check.call("el toque de calma los saca (%d)" % inside, inside == 0)
	# --- paneles --- (teclas, botón de cierre y clic en el registro)
	var pn = hud.paneles
	_key_tap(KEY_F2)
	await _frames(3)
	check.call("F2 abre el panel de economía", pn.economia.visible)
	var close_at: Vector2 = pn.economia.global_position + Vector2(pn.economia.size.x - 30, 20)
	_mouse(close_at, MOUSE_BUTTON_LEFT, true)
	_mouse(close_at, MOUSE_BUTTON_LEFT, false)
	await _frames(3)
	check.call("el ✕ cierra el panel de economía", not pn.economia.visible)
	_key_tap(KEY_F4)
	await _frames(3)
	check.call("F4 abre el avance de edad", pn.edad.visible)
	_key_tap(KEY_F4)
	_key_tap(KEY_F1)
	await _frames(3)
	check.call("F1 abre la ficha del pueblo", pn.pueblo.visible)
	_key_tap(KEY_F1)
	await _frames(3)
	check.call("F1 la cierra", not pn.pueblo.visible)
	pn.datos.add_log("prueba", Palette.UI_TEXT, base.x * 1000 + 20000, base.y * 1000 + 20000)
	_key_tap(KEY_F5)
	await _frames(3)
	var row_at: Vector2 = pn.sucesos.global_position + Vector2(100, 40)
	_mouse(row_at, MOUSE_BUTTON_LEFT, true)
	_mouse(row_at, MOUSE_BUTTON_LEFT, false)
	await _frames(3)
	var want := Vector2(base.x + 20, base.y + 20)
	check.call("F5 despliega el registro y el clic lleva la cámara (%.0f, %.0f)" % [cam.focus.x, cam.focus.z], pn.sucesos.expanded and Vector2(cam.focus.x, cam.focus.z).distance_to(want) < 2.0)
	_key_tap(KEY_F5)
	await _frames(2)
	# --- fin paneles ---
	var img := get_viewport().get_texture().get_image()
	img.save_png("screenshots/autotest.png")
	for r in results:
		print(r)
		if r.begins_with("FALLO"):
			ok = false
	print("AUTOTEST: ", "OK" if ok else "FALLO")
	get_tree().quit(0 if ok else 1)
