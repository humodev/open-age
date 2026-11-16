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
##   --cam=x,z,zoom[,inclinación]  posición de cámara para la captura (bX,bZ: relativa a la base propia)
##   --select=tipo      selecciona entidades de ese tipo del jugador local antes de la captura
##   --demo=base|obras|hitos|animales|batalla|multitud|formacion|bloque|bosque  escena armada para revisar modelos, hitos, animales, combate, el costo de 200 unidades, un grupo en marcha o la gente entre los árboles
##   --menu             fuerza el menú de inicio (sin argumentos se abre solo)
##   --terreno=<clave de reglas.json "terrenos"> tipo de mapa (llano, valle, delta…)
##   --civ=clave        civilización propia (tawantinsuyu, mapuches, guaranies, etiopia, palmares, ayutthaya, azar)
##   --rival=clave      civilización de la IA rival
##   --civs=a,b,c,…     partida de 2 a 8 jugadores (el primero es el tuyo; "azar" vale)
##   --equipos=0,1,0,…  equipo de cada lugar (sin esto, todos contra todos)
##   --partida=N        en el menú, tipo de partida preelegido (0 = 1 contra 1, 2 = 3 contra 3…)
##   Opciones de partida (proceso/24, paso 4b; en el menú, "Opciones de partida"). La conquista vale siempre:
##   --sitios=si|no     victoria por sitios sagrados (con "no" los sitios siguen dando riqueza)
##   --hitos=si|no      victoria por hitos: perder la capital y los hitos (con "no", hay que arrasar todo)
##   --tiempo=0|30|45|60  tiempo límite en minutos (0 = sin límite); al cumplirse gana el equipo con más puntos
##   --recursos=normal|medios|altos  recursos iniciales (reglas.json → opciones_partida.recursos)
##   --ubicacion=juntos|mezclados  en partidas de 3 o más, aliados vecinos o alternados en el círculo
##   --campana=clave --mision=N  juega una misión de campaña (N desde 0)
##   --dificultad=facil|normal|dificil|experta  (en el menú, la preelige)
##   --nofog            sin niebla de guerra (automático en --aivai)
##   --autotest         prueba de punta a punta con eventos reales de mouse y teclado
##   --grilla=menu      abre el submenú del aldeano (economia, militar) antes de la captura
##   --banco=rec:n,…    fija recursos del jugador antes de la captura (alimento:0,mita:0)
##   --ayuda=N          muestra la ayuda de la casilla N de la grilla (8 = Z) en la captura
##   --colocar=tipo     entra a colocar ese edificio ("hito": el hito económico de la edad II) en el centro de la pantalla
##   --ventana=ANCHOxALTO  ventana de ese tamaño (capturas a otras resoluciones)
##   --escala=auto|0.8|1|1.25|1.5  escala de la interfaz (si no, la de user://opciones.cfg)
##   --paleta=normal|deuteranopia|protanopia|tritanopia|relativa  modo de colores
##   --barras=1         barras de vida siempre visibles
##   --nombres=1        nombres en la grilla de órdenes
##   --abrir=opciones   abre el diálogo de opciones (también campanas e intro en el menú)
##   --bengala=1        tira una bengala propia cerca de la base antes de la captura (con aliados)
##   --formacion=linea  elige la formación de la grilla y la aplica a lo seleccionado antes de la captura
##   --panel=a,b        abre paneles de información antes de la captura (economia, edad, pueblo, sucesos, puntaje, fin, fin-derrota, fin-tiempo)

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
var _errores := RegistroErrores.new() # SCRIPT ERROR → telemetría (proceso/20)
var _drift := 0.0
var audio: GameAudio
var _replay_meta := {}
var _perf_t := 0.0
const REPLAY := "user://ultima_partida.json"


func _ready() -> void:
	OS.add_logger(_errores)
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
	_opciones_al_arrancar() # --- opciones ---
	# En el menú, --dificultad preelige la dificultad (capturas); no se guarda en las opciones.
	if _menu_mode and _args.has("dificultad"):
		Opciones.dificultad = str(_args["dificultad"])
	if _args.has("shot") or _args.has("autotest") or _args.has("mute"):
		AudioServer.set_bus_mute(0, true)
	_new_game()


# --- opciones ---
## Lee user://opciones.cfg y lo aplica: escala, colores, sonido y pantalla completa.
## Las capturas y la prueba de punta a punta no leen ni escriben el archivo; para ellas
## están --escala=auto|0.8|1|1.25|1.5, --paleta=<modo> y --barras=1.
func _opciones_al_arrancar() -> void:
	var prueba := _args.has("shot") or _args.has("autotest")
	Opciones.solo_lectura = prueba
	if not prueba:
		Opciones.cargar()
	if _args.has("escala"):
		Opciones.escala = 0.0 if _args["escala"] == "auto" else float(_args["escala"])
	if _args.has("paleta"):
		Opciones.paleta = str(_args["paleta"])
	if _args.has("barras"):
		Opciones.barras_siempre = _args["barras"] == "1"
	if _args.has("nombres"): # --- aprender ---
		Opciones.nombres_grilla = _args["nombres"] == "1"
		EstadoCasilla.nombres = Opciones.nombres_grilla
	Palette.aplicar(Opciones.paleta)
	Opciones.aplicar_escala(get_window())
	get_window().size_changed.connect(func() -> void: Opciones.aplicar_escala(get_window()))
	Opciones.aplicar_sonido(self)
	if Opciones.pantalla_completa and not prueba and not _args.has("ventana"):
		Opciones.aplicar_pantalla()


## --abrir=opciones: abre el diálogo de opciones (para las capturas).
func _abrir_opciones() -> void:
	if _menu != null and is_instance_valid(_menu) and _menu.visible:
		_menu.open_options()
		if _args.get("abrir", "") == "teclas": # --- veterano ronda 4 ---
			(_menu._options.find_child("BotonTeclas", true, false) as Button).pressed.emit()
	elif hud != null:
		hud._options.visible = true
		if _args.get("abrir", "") == "teclas": # --- veterano ronda 4 ---
			(hud._options.find_child("BotonTeclas", true, false) as Button).pressed.emit()
# --- fin opciones ---


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
		var ropts: Dictionary = Sim.intify(r["opciones"])
		sim = Sim.new(_seed, (ropts.get("civs", [0, 0]) as Array).size(), null, ropts)
		sim.ais = []
		for pid in r["ias"]:
			var cfg: Dictionary = r.get("ia_cfg", {}).get(str(int(pid)), {})
			var rai := SimAI.new(sim, int(pid), cfg.get("dificultad", r.get("dificultad", "normal")))
			rai.personality = cfg.get("estilo", r.get("estilo", "normal"))
			sim.ais.append(rai)
		sim.schedule(Sim.intify(r["comandos"]))
		_build_scene(true)
		ctrl.enabled = false
		hud.notify("Repetición de la última partida", 4.0)
		return
	# Lugares (docs/11, paso 5): del menú, de --civs/--equipos o los dos de siempre.
	var slots: Array = _args.get("lugares", [])
	if slots.is_empty():
		var civs: Array = [mine, rival]
		if _args.has("civs"):
			civs = Array((_args["civs"] as String).split(","))
		var teams: Array = range(civs.size())
		if _args.has("equipos"):
			teams = Array((_args["equipos"] as String).split(",")).map(func(t: String) -> int: return int(t))
		for i in civs.size():
			slots.append({"civ": civs[i], "equipo": teams[i] if i < teams.size() else i, "ia": i != 0, "dificultad": _args.get("dificultad", "normal"), "estilo": _args.get("estilo", "normal")})
	for sl in slots:
		if sl["civ"] == "" or sl["civ"] == "azar":
			sl["civ"] = civ_keys[rng.randi() % civ_keys.size()]
	# --- veterano ronda 4 --- la demo de batalla sin --terreno caía a veces en un lago: llano.
	var terreno: String = _args.get("terreno", "")
	if terreno == "" and _args.has("demo"):
		var di: Dictionary = (JSON.parse_string(FileAccess.get_file_as_string("res://data/interfaz.json")) as Dictionary).get("demos", {})
		terreno = str((di.get("terreno", {}) as Dictionary).get(str(_args["demo"]), ""))
	# --- fin veterano ronda 4 ---
	var opts := {"terreno": terreno, "civs": slots.map(func(sl: Dictionary) -> String: return sl["civ"]), "equipos": slots.map(func(sl: Dictionary) -> int: return int(sl["equipo"]))}
	opts.merge(match_opts(_args))
	sim = Sim.new(_seed, slots.size(), null, opts)
	var aivai := _args.has("aivai") or _menu_mode
	sim.ais = []
	var ai_ids := []
	var ai_cfg := {}
	for pid in sim.players.size():
		if pid != local or aivai:
			var sl: Dictionary = slots[pid]
			var ai := SimAI.new(sim, pid, sl.get("dificultad", "normal"))
			ai.personality = sl.get("estilo", "normal")
			sim.ais.append(ai)
			ai_ids.append(pid)
			ai_cfg[str(pid)] = {"dificultad": sl.get("dificultad", "normal"), "estilo": ai.personality}
	opts["terreno"] = sim.terrain
	_replay_meta = {"semilla": _seed, "opciones": opts, "ias": ai_ids, "ia_cfg": ai_cfg, "dificultad": _args.get("dificultad", "normal"), "estilo": _args.get("estilo", "normal")}
	_build_scene(aivai)


## Opciones de partida (--sitios, --hitos, --tiempo, --recursos, --ubicacion; el menú pasa
## las mismas claves) traducidas a los opts de Sim.new. Lo que no se pide queda como siempre.
static func match_opts(args: Dictionary) -> Dictionary:
	var out := {}
	if str(args.get("sitios", "si")) == "no":
		out["sitios_sin_victoria"] = true
	if str(args.get("hitos", "si")) == "no":
		out["hitos_sin_victoria"] = true
	if int(args.get("tiempo", "0")) > 0:
		out["tiempo_limite_min"] = int(args["tiempo"])
	if str(args.get("recursos", "normal")) != "normal":
		out["recursos"] = str(args["recursos"])
	if args.has("ubicacion"):
		out["ubicacion_equipos"] = str(args["ubicacion"])
	return out


func _build_scene(aivai: bool) -> void:
	if _args.has("demo"):
		_demo(_args["demo"])

	view = WorldView.new()
	view.name = "World"
	view.fog_on = not (aivai or _args.has("nofog") or _args.get("demo", "") == "batalla")
	add_child(view)
	view.setup(sim, local)
	_apply_ambiente(sim.terrain) # --- ambiente por bioma ---
	if _args.get("demo", "") == "animales":
		_vitrina_animales()

	cam = RtsCamera.new()
	cam.name = "Camera"
	cam.map_size = sim.map.n
	add_child(cam)
	cam.edge_pan = Opciones.bordes # --- opciones ---
	Palette.local = local # --- opciones --- (modo de colores "yo, aliados y rivales")
	Palette.es_aliado = func(a: int, b: int) -> bool: return a != b and not sim.enemies(a, b)
	var base := sim.bases[local]
	cam.look_at_point(Vector3(base.x + 6, 0, base.y + 6))
	# --- hud --- (cámara inicial sobre la capital, un poco por encima del centro: el panel no la tapa)
	for e in sim.actives:
		if e.owner == local and e.is_building() and (e.capital or e.type == "centro"):
			var cc := WorldView.to_world(e.x, e.y)
			cam.look_at_point(Vector3(cc.x, 0, cc.z) - cam.forward_xz() * 1.0)
			break
	# --- fin hud ---
	if sim.has_meta("demo_cam") and not _args.has("cam"):
		var dc: Vector2 = sim.get_meta("demo_cam")
		cam.look_at_point(Vector3(dc.x, 0, dc.y))
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
		_menu.play.connect(func(sd: int, civ: String, rival: String) -> void: _start(_menu.match_args().merged({"seed": str(sd), "civ": civ, "rival": rival, "dificultad": _menu.difficulty(), "estilo": _menu.style(), "terreno": _menu.terrain(), "lugares": _menu.slots()})))
		_menu.watch.connect(func(sd: int, civ: String, rival: String) -> void: _start(_menu.match_args().merged({"aivai": "1", "seed": str(sd), "civ": civ, "rival": rival, "estilo": _menu.style(), "dificultad": _menu.difficulty(), "terreno": _menu.terrain(), "lugares": _menu.slots()})))
		_menu.campaigns.connect(_open_campaigns.bind(layer))
		_menu.replay.connect(func() -> void: _start({"replay": "1"}))
		if _args.get("abrir", "") == "campanas":
			_open_campaigns.call_deferred(layer)
		elif _args.get("abrir", "") == "intro":
			layer.add_child(CampaignUI.story(_mission_data("palmares", 0), false, [["Comenzar", func() -> void: pass], ["Volver", func() -> void: pass]], "palmares"))
	if _args.get("abrir", "") in ["opciones", "teclas"]: # --- opciones --- (teclas: veterano ronda 4)
		_abrir_opciones.call_deferred()
	if _args.has("autotest"):
		cam.edge_pan = false
		_autotest.call_deferred()
	if _args.has("shot"):
		# Captura reproducible: ninguna entrada real afecta la partida.
		ctrl.enabled = false
		get_viewport().gui_disable_input = true


func _demo(kind: String) -> void:
	var b := sim.bases[0]
	if _args.has("edad"): # --edad=N: la base de muestra en esa edad (aspecto por edad, proceso/24)
		sim.players[0]["age"] = clampi(int(_args["edad"]), 1, 4)
	if kind == "obras":
		# Obras en marcha en sus tres etapas (cimientos, estructura, casi terminado): una fila
		# por edificio, columnas al 15, 50 y 85 % (proceso/24, 4c). Cámara: --cam=b6,b6,16.
		var types: Array = [sim.dp(0).civ.get("casa", "casa"), "cuartel", "torre", "almacen_mina", sim.dp(0).civ.get("inicio_edificio", "centro")]
		for row in types.size():
			var type: String = types[row]
			if not sim.dp(0).edificios.has(type):
				continue
			for col in 3:
				var tx0: int = b.x - 6 + col * 6
				var ty0: int = b.y + 5 + row * 5
				for r in 4:
					var found := false
					for dy in range(-r, r + 1):
						for dx in range(-r, r + 1):
							if not found and sim.can_place(type, tx0 + dx, ty0 + dy, 0):
								var e := sim.spawn_building(type, 0, tx0 + dx, ty0 + dy, false)
								e.build_time = sim.dp(0).build_time_of(type, 1)
								e.progress = e.build_time * [15, 50, 85][col] / 100
								e.hp = maxi(1, e.hp_max * [15, 50, 85][col] / 100)
								found = true
					if found:
						break
		sim.set_meta("demo_cam", Vector2(b.x + 1, b.y + 13))
	elif kind == "hitos":
		# Los seis hitos del pueblo terminados, en dos filas (una por eje, económico y militar)
		# y una columna por edad de destino (proceso/24, 4d). Cámara: --cam=b9,b6,24.
		for row in sim.dp(0).hitos.size():
			for col in (sim.dp(0).hitos[row] as Array).size():
				var type: String = sim.dp(0).hitos[row][col]
				var tx0: int = b.x + 2 + row * 6
				var ty0: int = b.y + 5 + col * 6
				var done := false
				for r in 6:
					for dy in range(-r, r + 1):
						for dx in range(-r, r + 1):
							if not done and sim.can_place(type, tx0 + dx, ty0 + dy, 0):
								sim.spawn_building(type, 0, tx0 + dx, ty0 + dy, true)
								done = true
		sim.set_meta("demo_cam", Vector2(b.x + 9, b.y + 9))
	elif kind == "animales":
		# El rebaño propio, animales sueltos y caza junto a la base; la vitrina con todas las
		# especies la arma _vitrina_animales (proceso/24, 4d). Cámara: --cam=b6,b10,12 (vitrina: --cam=b9.6,b16.8,15,46).
		for i in 3:
			var t := sim.map.nearest_free(b.x + 4 + i, b.y + 7, 6, 0)
			sim.spawn_unit("rebano", 0, t.x * 1000 + 500, t.y * 1000 + 500)
		for i in 3:
			var t := sim.map.nearest_free(b.x + 4 + i, b.y + 9, 6, 0)
			if t.x >= 0:
				sim.spawn_resource("rebano_salvaje", t.x, t.y)
		for i in 4:
			var t := sim.map.nearest_free(b.x + 4 + i, b.y + 11, 6, 0)
			if t.x >= 0:
				sim.spawn_resource("venado", t.x, t.y)
		sim.set_meta("demo_cam", Vector2(b.x + 6, b.y + 10))
	elif kind == "base":
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
	elif kind == "multitud":
		# 200 aldeanos que se cruzan en el centro: mide el costo de los modelos generados
		# (proceso/19-arte-y-sonido). Con --perf imprime los cuadros por segundo.
		var c := sim.map.n / 2
		for pid in 2:
			var ids := []
			for i in 100:
				var x := (c - 12 + pid * 24 + (i % 10) * (1 if pid == 0 else -1)) * 1000 + 500
				var y := (c - 5 + i / 10) * 1000 + 500
				ids.append(sim.spawn_unit("aldeano", pid, x, y).id)
			sim.push_command({"t": "move", "player": pid, "ids": ids, "x": (c + 14 - pid * 28) * 1000, "y": c * 1000})
	elif kind == "formacion":
		# Ejército mixto desparramado junto a la base, mandado lejos: muestra el grupo en
		# marcha (proceso/21). Cámara: --cam=b14,b10,14 sigue la salida.
		var fb := sim.bases[local]
		var types: Array = ["lancero", "guerrero", "hondero", "jinete", "lancero", "hondero"]
		var ids := []
		for i in 24:
			var t := sim.map.nearest_free(fb.x + 8 + (i * 7) % 9, fb.y + 6 + (i * 5) % 8, 6, local)
			ids.append(sim.spawn_unit(types[i % types.size()], local, t.x * 1000 + 500, t.y * 1000 + 500).id)
		var c := sim.map.n / 2
		sim.push_command({"t": "move", "player": local, "ids": ids, "x": c * 1000, "y": c * 1000})
	elif kind == "bloque":
		# Diez aldeanos mandados a recolectar lejos: marchan en bloque y se sueltan cerca (proceso/21).
		var bb := sim.bases[local]
		var vids := []
		for i in 10:
			var t := sim.map.nearest_free(bb.x + 8 + i % 4, bb.y + 8 + i / 4, 6, local)
			vids.append(sim.spawn_unit("aldeano", local, t.x * 1000 + 500, t.y * 1000 + 500).id)
		var c := sim.map.n / 2
		var far: SimEntity = null
		for e in sim.entities:
			if e.alive and e.is_resource() and e.type == "riqueza" and (far == null or Sim.dist(e.x, e.y, c * 1000, c * 1000) < Sim.dist(far.x, far.y, c * 1000, c * 1000)):
				far = e
		if far != null:
			sim.push_command({"t": "target", "player": local, "ids": vids, "target": far.id})
			# Cámara a un tercio del camino, donde va el bloque a los 8-10 s.
			sim.set_meta("demo_cam", Vector2(bb.x + 10 + (far.x / 1000 - bb.x - 10) / 3, bb.y + 10 + (far.y / 1000 - bb.y - 10) / 3))
	elif kind == "bosque":
		# Lectura de la gente entre los árboles (proceso/24, 4p): aldeanos talando del lado lejano
		# de un bosque (la cámara mira hacia +x+z) y una tropa que pasa por detrás.
		var fb := sim.bases[local]
		var tree: SimEntity = null
		for e in sim.entities:
			if e.alive and e.is_resource() and e.type == "arbol" and Sim.dist(e.x, e.y, fb.x * 1000, fb.y * 1000) > 9000 and (tree == null or Sim.dist(e.x, e.y, fb.x * 1000, fb.y * 1000) < Sim.dist(tree.x, tree.y, fb.x * 1000, fb.y * 1000)):
				tree = e
		if tree != null:
			# El árbol del borde lejano del mismo bosque.
			var far := tree
			for e in sim.entities:
				if e.alive and e.is_resource() and e.type == "arbol" and absi(e.tx - tree.tx) + absi(e.ty - tree.ty) < 10 and e.tx + e.ty > far.tx + far.ty and sim.map.occupant(e.tx + 1, e.ty + 1) == -1:
					far = e
			var vids := []
			for i in 8:
				var t := sim.map.nearest_free(far.tx + 1 + i % 3, far.ty + 1 + i / 3, 6, local)
				vids.append(sim.spawn_unit("aldeano", local, t.x * 1000 + 500, t.y * 1000 + 500).id)
			sim.push_command({"t": "target", "player": local, "ids": vids, "target": far.id})
			var tids := []
			var types: Array = ["lancero", "guerrero", "hondero"]
			for i in 9:
				var t := sim.map.nearest_free(far.tx - 4 + i % 3, far.ty + 3 + i / 3, 6, local)
				tids.append(sim.spawn_unit(types[i % 3], local, t.x * 1000 + 500, t.y * 1000 + 500).id)
			sim.push_command({"t": "move", "player": local, "ids": tids, "x": (far.tx + 4) * 1000, "y": (far.ty - 3) * 1000})
			sim.set_meta("demo_cam", Vector2(far.tx, far.ty))
	elif kind == "batalla":
		var c := sim.map.n / 2
		var cy := c # --- veterano ronda 4 --- campo seco y abierto más cercano al centro del mapa
		var seco := func(x0: int, y0: int) -> bool:
			var tapadas := 0
			for ty in range(y0 - 6, y0 + 7):
				for tx in range(x0 - 10, x0 + 11):
					if tx < 0 or ty < 0 or tx >= sim.map.n or ty >= sim.map.n or sim.map.is_water(tx, ty):
						return false
					if sim.map.occupied[ty * sim.map.n + tx] != -1:
						tapadas += 1
			return tapadas <= 6
		var hallado := false
		for r in range(0, sim.map.n / 2 - 12, 2):
			for d in [Vector2i(0, 0), Vector2i(r, 0), Vector2i(-r, 0), Vector2i(0, r), Vector2i(0, -r), Vector2i(r, r), Vector2i(-r, -r), Vector2i(r, -r), Vector2i(-r, r)]:
				if not hallado and seco.call(c + d.x, c + d.y):
					hallado = true
					cy = c + d.y
					c += d.x
			if hallado:
				break
		# --- fin veterano ronda 4 ---
		var ids := [[], []]
		for pid in 2:
			var types: Array = ["guerrero", "hondero", "lancero"]
			for k in sim.dp(pid).civ.get("unidades_nuevas", {}):
				var ud: Dictionary = sim.dp(pid).unidades[k]
				if ud.get("funcion", "") in ["choque", "distancia", "linea"]:
					types.append(k)
			for i in 30:
				var x := (c - 7 + pid * 14 + (i % 5) * (1 if pid == 0 else -1)) * 1000 + 500
				var y := (cy - 4 + i / 5) * 1000 + 500
				var u := sim.spawn_unit(types[i % 3], pid, x, y)
				ids[pid].append(u.id)
		sim.push_command({"t": "move", "player": 0, "ids": ids[0], "x": (c + 6) * 1000, "y": cy * 1000, "amove": true})
		sim.push_command({"t": "move", "player": 1, "ids": ids[1], "x": (c - 6) * 1000, "y": cy * 1000, "amove": true})
		sim.set_meta("demo_cam", Vector2(c, cy)) # --- veterano ronda 4 ---
	# --- demos --- (proceso/24, 4k) la escena de muestra no arranca por encima del tope
	# ("33/10"): el exceso queda como población extra, como en las misiones (sim_scenario),
	# más un margen para seguir entrenando (data/interfaz.json → demos.pob_margen).
	var margen := int((JSON.parse_string(FileAccess.get_file_as_string("res://data/interfaz.json")) as Dictionary).get("demos", {}).get("pob_margen", 0))
	sim._update_players()
	for p in sim.players:
		if int(p["pop"]) + margen > int(p["pop_cap"]):
			p["pob_extra"] = int(p.get("pob_extra", 0)) + int(p["pop"]) + margen - int(p["pop_cap"])
	sim._update_players()
	# --- fin demos ---


## Vitrina de --demo=animales: todas las especies de data/arte_animales.json en fila, con su
## nombre, al lado de la base (solo imagen; no son entidades de la partida).
func _vitrina_animales() -> void:
	var b := sim.bases[local]
	var esp: Dictionary = Animales.data().get("especies", {})
	# Filas a lo ancho de la pantalla: la cámara mira hacia +x+z (RtsCamera.YAW_DEG).
	var right := Vector3(1, 0, -1).normalized()
	var fwd := Vector3(1, 0, 1).normalized()
	var o := Vector3(b.x + 10.4, 0, b.y + 17.6)
	var i := 0
	for sp: String in esp:
		var mi := MeshInstance3D.new()
		mi.mesh = Animales.mesh(sp)
		var at := o + right * ((i % 8) - 3.5) * 1.7 - fwd * (i / 8) * 2.4
		mi.position = at + Vector3(0, WorldView.height_at(at.x, at.z), 0)
		mi.rotation.y = deg_to_rad(150.0) # de perfil, mirando a la derecha de la pantalla
		view.add_child(mi)
		var lb := Label3D.new()
		lb.text = str(esp[sp].get("nombre", sp))
		lb.font_size = 56
		lb.pixel_size = 0.0045
		lb.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		lb.no_depth_test = true
		lb.outline_size = 8
		lb.position = mi.position - fwd * 0.75 + Vector3(0, 0.1, 0) # en el suelo, del lado de la cámara
		view.add_child(lb)
		i += 1


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
		# --- aprender --- (por qué se perdió la misión, si el motor de escenarios lo sabe)
		var why: String = sim.scenario.motivo if sim != null and sim.scenario != null else ""
		m["epilogo"] = ([why] if why != "" else []) + ["La historia no terminó así. Volvé a intentarlo."]
		# --- fin aprender ---
	buttons.append(["Menú principal", func() -> void: to_menu()])
	paused = true
	hud.get_parent().add_child(CampaignUI.story(m, true, buttons, civ))


## Guarda la partida como repetición (solo escaramuzas con jugador humano).
## Telemetría de la partida en user://telemetria/ (proceso/20). Se guarda junto con la repetición.
func save_telemetry() -> void:
	if sim == null or _menu_mode or sim.tick < 600 or sim.get_meta("tele_tick", -1) == sim.tick:
		return
	sim.set_meta("tele_tick", sim.tick) # fin de partida y después "Nueva partida": una sola vez
	var path := "user://telemetria/%s-%d.jsonl" % [Time.get_datetime_string_from_system().replace(":", "-"), _seed]
	var opts: Dictionary = _replay_meta.get("opciones", {})
	if sim.tele.save(path, sim.tele.header(sim, _seed, opts)):
		print("Telemetría: ", ProjectSettings.globalize_path(path))


func save_replay() -> void:
	save_telemetry()
	if _replay_meta.is_empty() or _menu_mode or _args.has("aivai") or _args.has("replay") or sim == null or sim.recording.is_empty():
		return
	var r := _replay_meta.duplicate()
	r["comandos"] = sim.recording
	var f := FileAccess.open(REPLAY, FileAccess.WRITE)
	if f != null:
		f.store_string(JSON.stringify(r))


func _exit_tree() -> void:
	# Sin esto Godot y el script liberan el registro de errores dos veces al salir
	# ("double free or corruption", código 134 al terminar cada --shot).
	OS.remove_logger(_errores)


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
	# --- veterano ronda 4 --- teclas de Opciones → Teclas (Pausa del teclado, siempre)
	if Teclas.es(k.physical_keycode, "ayuda"):
		hud._toggle_help()
	elif Teclas.es(k.physical_keycode, "velocidad"):
		speed = 2.0 if speed == 1.0 else (4.0 if speed == 2.0 else 1.0)
	elif k.physical_keycode == KEY_PAUSE or Teclas.es(k.physical_keycode, "pausa"):
		hud.toggle_menu()


func _process(delta: float) -> void:
	_errores.flush(sim)
	if not paused:
		_acc += delta * speed
		var tick_s := sim.tick_ms / 1000.0
		var steps := 0
		while _acc >= tick_s and steps < MAX_STEPS_PER_FRAME:
			var t0 := Time.get_ticks_usec()
			sim.step()
			# Telemetría: un tick que no entra en su parte del cuadro a la velocidad actual.
			var us := Time.get_ticks_usec() - t0
			if us > int(sim.tick_ms * 1000 / maxf(1.0, speed)):
				sim.tele.add(sim.tick, "tick_lento", -1, -1, -1, {"ms": us / 1000, "x": speed}, "tl", 50)
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
		var at_base := Vector3.ZERO
		if c[0].begins_with("b"): # --cam=b3,b-2,…: relativo a la base propia (cambia con la semilla)
			at_base = Vector3(sim.bases[local].x, 0, sim.bases[local].y)
		cam.look_at_point(at_base + Vector3(float(c[0].trim_prefix("b")), 0, float(c[1].trim_prefix("b"))))
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
	# --- órdenes ---
	if _args.has("formacion"):
		ctrl.formacion = _args["formacion"]
		sim.push_command({"t": "formar", "player": local, "ids": ctrl.selection.duplicate(), "form": ctrl.formacion})
	if _args.has("bengala"):
		var bb := sim.bases[local]
		ctrl.flare(Vector3(bb.x + 6, 0, bb.y + 6))
		for i in 2:
			sim.step()
			hud.on_events(sim.events)
	# --- fin órdenes ---
	# --- veterano --- (--banco=recurso:n,…; --colocar=tipo|hito: modo de colocación en el
	# centro de la pantalla; --ayuda=N: ayuda de la casilla N de la grilla)
	if _args.has("banco"):
		for kv in (_args["banco"] as String).split(","):
			var par := kv.split(":")
			if par.size() == 2:
				sim.players[local]["res"][par[0]] = int(par[1])
	if _args.has("colocar"):
		var ptype: String = _args["colocar"]
		if ptype == "hito":
			ptype = sim.dp(local).hitos[0][0]
		var pcost := sim.dp(local).cost_of(ptype, int(sim.players[local]["age"]))
		for k in pcost:
			sim.players[local]["res"][k] = maxi(int(sim.players[local]["res"].get(k, 0)), int(pcost[k]))
		var vids: Array[int] = []
		for e in sim.actives:
			if e.owner == local and e.fn == "civil" and e.inside < 0:
				vids.append(e.id)
		ctrl.select_ids(vids)
		ctrl.run_command({"kind": "build", "id": ptype, "cost": pcost, "locked": ""})
		ctrl.mouse_override = Vector2(960, 430)
		ctrl.enabled = true # solo para que siga al cursor fijo; la entrada real sigue apagada
	if _args.has("ayuda"):
		await get_tree().process_frame
		var slot := int(_args["ayuda"])
		var c := Controller.cmd_at(ctrl.commands(), slot)
		if not c.is_empty():
			var card: Control = hud._card
			var sr: Rect2 = card.call("_slot_rect", slot)
			hud.show_tip(c, Rect2(card.global_position + sr.position, sr.size))
	# --- fin veterano ---
	if _args.has("grilla"): # --- grilla --- (--grilla=economia|militar abre ese submenú para la captura)
		ctrl.open_submenu(_args["grilla"])
	# --- paneles --- (--panel=economia,edad,pueblo,sucesos,puntaje,fin para las capturas)
	if _args.has("panel") and hud.paneles != null:
		for w in (_args["panel"] as String).split(","):
			if w == "fin":
				hud.paneles.show_end(local)
			elif w == "fin-derrota": # --- aprender --- (la partida termina ahí, ganada por el primer rival)
				var foe := 1 if local == 0 else 0
				sim.win(foe, "conquista")
				hud.paneles.show_end(foe)
			elif w == "fin-tiempo": # --- opciones de partida --- (termina ya por tiempo límite y puntos)
				if int(sim._opts.get("tiempo_limite_min", 0)) == 0:
					sim._opts["tiempo_limite_min"] = 30
				sim.end_by_time()
				var tw := sim.winner
				hud.paneles.show_end(local if tw >= 0 and not sim.enemies(local, tw) else tw)
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
	save_telemetry() # las partidas que terminan con --shot también dejan su telemetría
	get_tree().quit()


# ---------------------------------------------------------------- Prueba de punta a punta

func _frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame


func _mouse(pos: Vector2, button: int, pressed: bool) -> void:
	ctrl.mouse_override = pos
	# --- escala --- los eventos inyectados llegan en píxeles de la ventana; `pos` está en
	# unidades de la interfaz (estirada desde 1920×1080), así que se convierte.
	var wp := get_viewport().get_final_transform() * pos
	# --- fin escala ---
	var mv := InputEventMouseMotion.new()
	mv.position = wp
	mv.global_position = wp
	Input.parse_input_event(mv)
	if button == 0:
		return
	var mb := InputEventMouseButton.new()
	mb.position = wp
	mb.global_position = wp
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


# --- órdenes ---
func _key_mod(code: int, ctrl_on: bool, shift_on: bool = false, alt_on: bool = false) -> void:
	for pressed in [true, false]:
		var k := InputEventKey.new()
		k.physical_keycode = code
		k.keycode = code
		k.ctrl_pressed = ctrl_on
		k.shift_pressed = shift_on
		k.alt_pressed = alt_on
		k.pressed = pressed
		Input.parse_input_event(k)


func _click(pos: Vector2, button: int = MOUSE_BUTTON_LEFT) -> void:
	_mouse(pos, 0, false)
	await _frames(2)
	_mouse(pos, button, true)
	_mouse(pos, button, false)
	await _frames(3)


## Órdenes y comodidades como AoE4 (proceso/23, parte B): ociosos, atajos, marcadores,
## cola global, mantener posición, patrullar, formaciones y rumbo con arrastre.
func _autotest_ordenes(check: Callable) -> void:
	speed = 1.0
	var base := sim.bases[local]
	var at = ctrl.atajos
	cam.look_at_point(Vector3(base.x + 2, 0, base.y + 2))
	await _frames(3)
	# Barra de recursos: aldeanos por recurso y botón de ociosos.
	var vill: Array[int] = []
	for e in sim.actives:
		if e.owner == local and e.fn == "civil" and e.inside < 0:
			vill.append(e.id)
	sim.push_command({"t": "stop", "player": local, "ids": vill.slice(0, 2)})
	await get_tree().create_timer(0.3).timeout
	var idle_n: int = at.ociosos_aldeanos().size()
	check.call("hay aldeanos ociosos para el botón (%d)" % idle_n, idle_n >= 2)
	var boton := Rect2()
	for h in hud._top._hits:
		if String(h[2]).begins_with("Aldeanos ociosos"):
			boton = h[0]
	check.call("la barra de recursos tiene el botón de aldeanos ociosos", boton.size.x > 0)
	await _click(hud._top.global_position + boton.get_center())
	var s1 := ctrl.selected_entities()
	check.call("clic en el botón: selecciona un aldeano ocioso (%d)" % s1.size(), s1.size() == 1 and s1[0].fn == "civil" and s1[0].order == SimEntity.Order.IDLE)
	_key_mod(KEY_PERIOD, false, true)
	await _frames(3)
	check.call("Mayús + «.»: todos los aldeanos ociosos (%d de %d)" % [ctrl.selection.size(), idle_n], ctrl.selection.size() == idle_n)
	var con_trabajo := 0
	for h in hud._top._hits:
		if String(h[2]).begins_with("Aldeanos en"):
			con_trabajo += 1
	check.call("aldeanos por recurso debajo de cada recurso (%d)" % con_trabajo, con_trabajo == 4)
	# Militares: M todos, «,» el siguiente ocioso.
	var mil: Array[int] = []
	for i in 6:
		mil.append(sim.spawn_unit("guerrero" if i % 2 == 0 else "hondero", local, (base.x + 6) * 1000 + (i % 3) * 800, (base.y + 9) * 1000 + (i / 3) * 800).id)
	await _frames(4)
	_key_tap(KEY_M)
	await _frames(3)
	check.call("M selecciona todos los militares (%d)" % ctrl.selection.size(), ctrl.selection.size() == 6)
	_key_tap(KEY_COMMA)
	await _frames(3)
	check.call("«,» selecciona el siguiente militar ocioso", ctrl.selection.size() == 1 and mil.has(ctrl.selection[0]))
	_key_mod(KEY_COMMA, true)
	await _frames(3)
	check.call("Ctrl + «,»: todos los militares ociosos (%d)" % ctrl.selection.size(), ctrl.selection.size() == 6)
	# Grilla militar: formación en línea (X), mantener posición (D) y patrullar (E + clic).
	var slots := {}
	for c in ctrl.commands():
		slots[c["id"]] = c["slot"]
	check.call("la grilla militar tiene mantener, patrullar y las cuatro formaciones", slots.has("mantener") and slots.has("patrullar") and slots.has("form_linea") and slots.has("form_columna"))
	_key_tap(Controller.SLOT_KEYS[slots.get("form_linea", 9)])
	await get_tree().create_timer(0.3).timeout
	check.call("X elige la formación en línea y la arma en el lugar", ctrl.formacion == "linea" and not sim.groups.groups.is_empty())
	await get_tree().create_timer(1.5).timeout
	_key_tap(Controller.SLOT_KEYS[slots.get("mantener", 6)])
	await get_tree().create_timer(0.3).timeout
	var hold := 0
	for id in mil:
		if sim.by_id[id].order == SimEntity.Order.HOLD:
			hold += 1
	check.call("D: mantener posición (%d de 6)" % hold, hold == 6)
	_key_tap(Controller.SLOT_KEYS[slots.get("patrullar", 2)])
	await _frames(2)
	check.call("E entra en modo patrullar", ctrl.mode == "patrol")
	await _click(_screen(base.x + 14.0, base.y + 9.0))
	await get_tree().create_timer(0.3).timeout
	var pat := 0
	for id in mil:
		if sim.by_id[id].patrol:
			pat += 1
	check.call("clic: patrullan (%d de 6)" % pat, pat == 6 and ctrl.mode == "")
	# Rumbo arrastrando el clic derecho: la orden lleva el rumbo de la tabla de enteros.
	# Un lugar libre (sin recurso ni unidad debajo): si no, el clic derecho sería recolectar o atacar.
	var a := _screen(base.x + 8.0, base.y + 12.0)
	var b := _screen(base.x + 8.0, base.y + 16.0)
	for dx in range(-10, 11, 2):
		var ca := _screen(base.x + 8.0 + dx, base.y + 12.0)
		if ctrl.pick(ca) < 0:
			a = ca
			b = _screen(base.x + 8.0 + dx, base.y + 16.0)
			break
	_mouse(a, 0, false)
	await _frames(2)
	_mouse(a, MOUSE_BUTTON_RIGHT, true)
	await _frames(2)
	_mouse(b, 0, false)
	await _frames(3)
	check.call("se dibuja la flecha del rumbo mientras se arrastra", ctrl.rpressing)
	_mouse(b, MOUSE_BUTTON_RIGHT, false)
	await _frames(3)
	var last: Dictionary = sim.recording[-1] if not sim.recording.is_empty() else {}
	var want := SimGroups.heading(0, 4000)
	check.call("arrastrar el clic derecho manda mover en línea con rumbo %d (%s)" % [want, str(last.get("rumbo", "?"))], last.get("t", "") == "move" and last.get("form", "") == "linea" and absi(int(last.get("rumbo", -9)) - want) <= 1)
	await get_tree().create_timer(0.3).timeout
	var patrol_left := 0
	for id in mil:
		if sim.by_id[id].patrol:
			patrol_left += 1
	check.call("la orden nueva corta la patrulla", patrol_left == 0)
	# Marcadores de cámara: Ctrl + F7 guarda, F7 vuelve (atajo del marcador 1).
	cam.look_at_point(Vector3(base.x + 3, 0, base.y + 3))
	await _frames(2)
	_key_mod(KEY_F7, true)
	await _frames(2)
	cam.look_at_point(Vector3(base.x + 30, 0, base.y + 30))
	await _frames(2)
	_key_tap(KEY_F7)
	await _frames(2)
	check.call("Ctrl + F7 guarda la cámara y F7 vuelve (%.0f, %.0f)" % [cam.focus.x, cam.focus.z], Vector2(cam.focus.x, cam.focus.z).distance_to(Vector2(base.x + 3, base.y + 3)) < 1.5)
	# Tab recorre los edificios de producción; T todos los del tipo.
	_key_tap(KEY_TAB)
	await _frames(3)
	var sb := ctrl.selected_entities()
	check.call("Tab selecciona un edificio de producción", sb.size() == 1 and sb[0].is_building() and not (sb[0].def.get("produce", []) as Array).is_empty())
	ctrl.select_ids([mil[0]] as Array[int])
	_key_tap(KEY_T)
	await _frames(3)
	check.call("T: todos los del tipo de lo seleccionado (%d)" % ctrl.selection.size(), ctrl.selection.size() == 3)
	# Cola global: un ícono por edificio que produce; clic lleva al edificio.
	var centro: SimEntity = null
	for e in sim.actives:
		if e.owner == local and e.is_building() and e.capital:
			centro = e
	sim.players[local]["res"]["alimento"] = int(sim.players[local]["res"]["alimento"]) + 500
	sim.players[local]["pob_extra"] = 10 # que no la frene el tope (el tope se recalcula cada tick)
	sim.push_command({"t": "train", "player": local, "building": centro.id, "type": "aldeano"})
	# La orden entra en el próximo tick: esperar hasta un segundo (con carga, los cuadros no son ticks).
	for i in 60:
		await _frames(1)
		if not centro.queue.is_empty():
			break
	var items: Array = hud.cola_global.items()
	check.call("la cola global muestra lo que se produce (%d)" % items.size(), items.size() >= 1)
	ctrl.select_ids([] as Array[int])
	cam.look_at_point(Vector3(base.x + 30, 0, base.y + 30))
	await _frames(3)
	if not hud.cola_global._hits.is_empty():
		await _click(hud.cola_global.global_position + (hud.cola_global._hits[0][0] as Rect2).get_center())
	check.call("clic en la cola global selecciona el edificio", ctrl.selection.size() == 1 and sim.by_id[ctrl.selection[0]].is_building())
	# Bengala sin aliados: no se manda nada.
	var n_cmd := sim.recording.size()
	var fl := _screen(base.x + 6.0, base.y + 6.0)
	Input.parse_input_event(_alt(true))
	await _click(fl)
	Input.parse_input_event(_alt(false))
	await _frames(2)
	check.call("Alt + clic sin aliados no tira bengala", sim.recording.size() == n_cmd)
	ctrl.select_ids(vill)
	await _frames(2)


# --- veterano ---
## Pedidos de interfaz del veterano en la tercera ronda (proceso/24, 4k): costo real del hito,
## aura al colocarlo, ficha del hito en obra, ocho marcadores y barras al pelear.
## --- depósitos de comida --- (proceso/24, 4m) tres aldeanos cazan lejos del centro: el aviso
## nombra el almacén del pueblo («levantá un Tapyi junto a la caza»); con uno en obra junto a la
## caza, se calla.
## --- pelea --- (4q) Un ataque perdido lejos de casa: 6 guerreros caen ante honderos mientras le
## pegan a un edificio y 5 ante el centro rival con guarnición. Los sucesos se le pasan al aviso
## como los da la simulación; después de la calma, el resumen dice cuántos, qué los mató y qué llevar.
func _autotest_pelea(check: Callable, cs, said: Callable) -> void:
	var rival := 1 if local == 0 else 0
	var rb: Vector2i = sim.bases[rival]
	var shooter := sim.spawn_unit("hondero", rival, rb.x * 1000 - 9000, rb.y * 1000)
	var rcen: SimEntity = null
	for e in sim.actives:
		if e.alive and e.owner == rival and e.capital:
			rcen = e
	var rbuild: SimEntity = null
	for e in sim.actives:
		if e.alive and e.owner == rival and e.is_building() and not e.capital:
			rbuild = e
	hud.avisos.lista.clear()
	cs._said.erase("pelea")
	cs._deaths.clear()
	var evs: Array = []
	for i in 11:
		var g := sim.spawn_unit("guerrero", local, rb.x * 1000 - 8000 + i * 300, rb.y * 1000 + 2000)
		var by: SimEntity = shooter if i < 6 else rcen
		if i >= 6 and rcen != null and rcen.garrison.is_empty():
			rcen.garrison.append(-1) # solo para la prueba: cuenta como «con guarnición»
		if i < 6 and rbuild != null:
			g.order = SimEntity.Order.ATTACK
			g.target = rbuild.id
		evs.append({"t": "hit", "a": by.id, "b": g.id, "ranged": true, "dmg": 10})
		cs.on_events(evs)
		evs.clear()
		cs.on_events([{"t": "died", "id": g.id, "owner": local, "type": "guerrero", "cat": SimEntity.Cat.UNIT, "by": rival, "x": g.x, "y": g.y}])
		sim._kill(g)
	if rcen != null:
		rcen.garrison.erase(-1)
	var calma := int(cs.cfg.get("pelea", {}).get("calma_s", 12))
	for d in cs._deaths:
		d[0] = int(d[0]) - calma - 1
	cs._fight()
	var txt := ""
	for a in hud.avisos.lista:
		if String(a["texto"]).begins_with("Perdiste"):
			txt = a["texto"]
	print("aviso de la pelea: ", txt.replace("\n", " | "))
	check.call("aviso de la pelea perdida: «Perdiste 11 soldados…»", said.call("Perdiste 11 soldados"))
	check.call("el aviso de la pelea nombra a los honderos y al centro con guarnición", txt.contains("(6)") and txt.contains("con guarnición (5)"))
	check.call("el aviso de la pelea dice qué llevar: asedio, la tropa que les gana y que A y clic ataca lo primero", txt.contains("clic derecho sobre el edificio") and txt.contains("ontra los ") and txt.contains("A y clic"))
	await _frames(2)
	get_viewport().get_texture().get_image().save_png("screenshots/autotest_pelea.png")
	sim._kill(shooter)
	hud.avisos.lista.clear()


func _autotest_lejos(check: Callable, cs, said: Callable, capital: SimEntity, vill_ids: Array[int]) -> void:
	var c: Dictionary = cs.cfg.get("lejos", {})
	var dist := int(c.get("casillas", 12)) + 10
	var dir := 1 if capital.tx < sim.map.n / 2 else -1
	var spot := sim.map.nearest_free(capital.tx + dir * dist, capital.ty, 8)
	var meat: Array[SimEntity] = []
	var hunters: Array[SimEntity] = []
	for id in vill_ids:
		var v: SimEntity = sim.by_id.get(id)
		if v != null and v.alive and hunters.size() < int(c.get("aldeanos_min", 3)):
			var m := sim.spawn_resource("carne", spot.x + hunters.size(), spot.y)
			meat.append(m)
			sim._order_gather(v, m)
			hunters.append(v)
	hud.avisos.lista.clear()
	cs._said.erase("lejos_alimento")
	cs._since.erase("lejos_alimento")
	cs.check(0)
	cs.check(int(c.get("durante_s", 30)) + 1)
	var dd := sim.dp(local)
	var store: String = hud.CONSEJOS.best_store(dd, "alimento", int(sim.players[local]["age"]))
	var name: String = dd.edificios[store]["nombre"] if store != "" else "elefante del rey"
	check.call("aviso de viaje largo con la caza a %d casillas: nombra «%s»" % [dist, name], said.call("junto a la caza") and said.call(name))
	await _frames(2)
	get_viewport().get_texture().get_image().save_png("screenshots/autotest_lejos.png")
	# Con el almacén en obra junto a la caza, no vuelve a avisar.
	var obra: SimEntity = null
	if store != "":
		var at := sim.map.nearest_free(spot.x, spot.y - 3, 6)
		obra = sim.spawn_building(store, local, at.x, at.y, false)
		hud.avisos.lista.clear()
		cs._said.erase("lejos_alimento")
		cs._since.erase("lejos_alimento")
		cs.check(0)
		cs.check(int(c.get("durante_s", 30)) + 1)
		check.call("con %s en obra junto a la caza, el aviso se calla" % name, not said.call("junto a la caza"))
	for m in meat:
		sim._kill(m)
	if obra != null:
		sim._kill(obra)
	var ids: Array[int] = []
	for v in hunters:
		ids.append(v.id)
	sim.push_command({"t": "stop", "player": local, "ids": ids})
	hud.avisos.lista.clear()
	await _frames(3)
# --- fin depósitos de comida ---


func _autotest_veterano(check: Callable) -> void:
	speed = 1.0
	var base := sim.bases[local]
	var dd := sim.dp(local)
	var hito: String = dd.hitos[0][0]
	var age := int(sim.players[local]["age"])
	# 1. Costo del hito: sin recursos, la casilla nombra cada recurso que falta, sin "+".
	var saved: Dictionary = (sim.players[local]["res"] as Dictionary).duplicate()
	for k in sim.players[local]["res"]:
		sim.players[local]["res"][k] = 0
	var cost := dd.cost_of(hito, age)
	var items := EstadoCasilla.faltan_textos(EstadoCasilla.faltante(cost, sim.players[local]["res"]))
	var sin_mas := items.all(func(it: Array) -> bool: return not String(it[1]).contains("+"))
	check.call("la casilla del hito muestra cada recurso que falta (%d de %d, %s)" % [items.size(), cost.size(), str(items)], items.size() == cost.size() and sin_mas)
	var one := EstadoCasilla.faltan_textos({"madera": 40})
	check.call("si falta uno solo, «−40»", one.size() == 1 and one[0][1] == "−40")
	var tip = hud._tip
	tip.set("cmd", {"name": "hito", "cost": cost, "desc": "", "locked": ""})
	var ft: String = tip.call("_falta_texto")
	var todos := true
	for k in cost:
		todos = todos and ft.contains(str(cost[k]))
	check.call("la ayuda dice cuánto falta de cada uno (%s)" % ft, todos)
	ctrl.select_ids(_vill_ids())
	await _frames(3)
	get_viewport().get_texture().get_image().save_png("screenshots/autotest_costo_hito.png")
	for k in saved:
		sim.players[local]["res"][k] = saved[k]
	# 2. Al colocar el hito: aura en el suelo y qué queda adentro.
	for k in cost:
		sim.players[local]["res"][k] = int(sim.players[local]["res"].get(k, 0)) + int(cost[k])
	ctrl.open_submenu(Grilla.RAIZ)
	ctrl.run_command({"kind": "build", "id": hito, "cost": cost, "locked": ""})
	cam.look_at_point(Vector3(base.x + 8, 0, base.y + 8))
	await _frames(2)
	_mouse(_screen(base.x + 10, base.y + 10), 0, false)
	await _frames(4)
	var tile: Vector2i = ctrl._ghost.get_meta("tile", Vector2i(-1, -1))
	var lines := preload("res://src/game/ui/mundo_colocacion.gd").detalles(sim, local, hito, tile.x, tile.y)
	var aura_line := ""
	for l in lines:
		if String(l[0]).begins_with("Aura") or String(l[0]).begins_with("En el aura"):
			aura_line += String(l[0]) + " / "
	check.call("al colocar el hito se ve el aura (%s)" % aura_line, ctrl.mode == "place" and aura_line.contains("casillas"))
	get_viewport().get_texture().get_image().save_png("screenshots/autotest_aura_hito.png")
	ctrl.cancel_mode()
	for k in saved:
		sim.players[local]["res"][k] = saved[k]
	# 3. Ficha del hito en obra: lo que falta con los constructores y el rendimiento decreciente.
	var spot := Vector2i(-1, -1)
	for r in 8:
		for dy in range(-r, r + 1):
			for dx in range(-r, r + 1):
				if spot.x < 0 and sim.can_place(hito, base.x + 12 + dx, base.y + 2 + dy, local):
					spot = Vector2i(base.x + 12 + dx, base.y + 2 + dy)
	var h := sim.spawn_building(hito, local, spot.x, spot.y, false)
	h.build_time = dd.build_time_of(hito, age)
	h.progress = h.build_time / 4
	h.workers_prev = 4
	h.workers_now = 4
	# Con 4: tiempo × 3/(4+2) (P-006), o la obra colectiva guaraní (+pct por constructor extra).
	var per_tick := sim.tick_ms * 6 / 3
	if dd.has_mod("obra_colectiva"):
		per_tick = sim.tick_ms * (100 + int(dd.mod("obra_colectiva")["pct_por_constructor"]) * 3) / 100
	var want_ms := (h.build_time - h.progress) * sim.tick_ms / per_tick
	var txt := Hud.obra_restante(sim, h)
	var want_txt := "%d:%02d" % [want_ms / 60000, (want_ms / 1000) % 60]
	check.call("la ficha del hito en obra dice cuánto falta con 4 (%s; esperado %s)" % [txt, want_txt], txt.begins_with("Faltan") and txt.contains(want_txt))
	h.workers_prev = 0
	h.workers_now = 0
	check.call("sin constructores, «Parada» (%s)" % Hud.obra_restante(sim, h), Hud.obra_restante(sim, h).begins_with("Parada"))
	h.workers_prev = 4
	h.workers_now = 4
	ctrl.select_ids([h.id] as Array[int])
	cam.look_at_point(Vector3(spot.x + 1, 0, spot.y + 4))
	await _frames(4)
	get_viewport().get_texture().get_image().save_png("screenshots/autotest_hito_obra.png")
	sim.remove_quietly(h)
	await _frames(2)
	# 5. Ocho marcadores: Ctrl + Alt + n guarda, Alt + n vuelve; Ctrl + n sigue siendo el grupo.
	var groups_before: Dictionary = ctrl.groups.duplicate()
	for n in [1, 8]:
		cam.look_at_point(Vector3(base.x + n, 0, base.y + 2))
		await _frames(2)
		_key_mod(KEY_0 + n, true, false, true)
		await _frames(2)
	cam.look_at_point(Vector3(base.x + 30, 0, base.y + 30))
	await _frames(2)
	_key_mod(KEY_8, false, false, true)
	await _frames(2)
	check.call("Ctrl + Alt + 8 guarda y Alt + 8 vuelve (%.0f, %.0f)" % [cam.focus.x, cam.focus.z], Vector2(cam.focus.x, cam.focus.z).distance_to(Vector2(base.x + 8, base.y + 2)) < 1.5)
	check.call("Ctrl + Alt + número no pisa los grupos de control", ctrl.groups.keys() == groups_before.keys())
	_key_tap(KEY_F7)
	await _frames(2)
	check.call("F7 es atajo del marcador 1 (%.0f, %.0f)" % [cam.focus.x, cam.focus.z], Vector2(cam.focus.x, cam.focus.z).distance_to(Vector2(base.x + 1, base.y + 2)) < 1.5)
	# 6. Barras al pelear sin la opción: una unidad que acaba de recibir un golpe.
	var u: SimEntity = null
	for e in sim.actives:
		if e.owner == local and e.is_unit() and e.hp == e.hp_max:
			u = e
			break
	if u != null:
		var was := u.last_combat
		check.call("sin pelear, no hay barra por combate", not Overlay.en_combate(sim, u) or was > sim.tick - Overlay.combat_ticks(sim))
		u.last_combat = sim.tick
		check.call("al pelear se ve la barra aunque esté sana y sin la opción", Overlay.en_combate(sim, u) and not Opciones.barras_siempre)
		u.last_combat = was


# --- veterano ronda 4 ---
func _key_shift(code: int) -> void:
	# Mayús de verdad (Input.is_key_pressed), no solo la marca del evento: así lo lee la grilla.
	var sh := InputEventKey.new()
	sh.physical_keycode = KEY_SHIFT
	sh.keycode = KEY_SHIFT
	sh.pressed = true
	Input.parse_input_event(sh)
	_key_mod(code, false, true)
	sh = sh.duplicate()
	sh.pressed = false
	Input.parse_input_event(sh)


func _click_mod(pos: Vector2, shift_on: bool, ctrl_on: bool) -> void:
	_mouse(pos, 0, false)
	await _frames(2)
	var wp := get_viewport().get_final_transform() * pos
	for pressed in [true, false]:
		var mb := InputEventMouseButton.new()
		mb.position = wp
		mb.global_position = wp
		mb.button_index = MOUSE_BUTTON_LEFT
		mb.pressed = pressed
		mb.shift_pressed = shift_on
		mb.ctrl_pressed = ctrl_on
		Input.parse_input_event(mb)
	await _frames(3)


func _lugar_libre(type: String, cerca: Vector2i) -> Vector2i:
	for r in 12:
		for dy in range(-r, r + 1):
			for dx in range(-r, r + 1):
				if sim.can_place(type, cerca.x + dx, cerca.y + dy, local):
					return Vector2i(cerca.x + dx, cerca.y + dy)
	return Vector2i(-1, -1)


## Cuarta ronda del veterano: producir con varios edificios, H por los centros, M y «,» que
## centran, grupos exclusivos y grupo 0, una tecla reasignada y el panel de varias unidades.
func _autotest_veterano4(check: Callable) -> void:
	speed = 1.0
	var base := sim.bases[local]
	var dd := sim.dp(local)
	var saved: Dictionary = (sim.players[local]["res"] as Dictionary).duplicate()
	for k in sim.players[local]["res"]:
		sim.players[local]["res"][k] = 5000
	sim.players[local]["pob_extra"] = 40
	# 1. Producción con dos cuarteles: Q encola UNA unidad; Mayús + Q, cinco en total, repartidas.
	var tipo := "cuartel" if dd.edificios.has("cuartel") else ""
	var nuevos: Array[SimEntity] = []
	if tipo != "":
		for i in 2:
			var at := _lugar_libre(tipo, Vector2i(base.x - 10 + i * 5, base.y + 10))
			if at.x >= 0:
				nuevos.append(sim.spawn_building(tipo, local, at.x, at.y, true))
	await _frames(2)
	if nuevos.size() == 2:
		var ids: Array[int] = [nuevos[0].id, nuevos[1].id]
		ctrl.select_ids(ids)
		await _frames(2)
		var slot := -1
		for c in ctrl.commands():
			if c["kind"] == "train" and c["locked"] == "":
				slot = c["slot"]
				break
		var cola := func() -> Array:
			return [nuevos[0].queue.size(), nuevos[1].queue.size()]
		_key_tap(Teclas.tecla("grilla_%d" % slot))
		for i in 60:
			await _frames(1)
			if nuevos[0].queue.size() + nuevos[1].queue.size() > 0:
				break
		await _frames(2)
		var c1: Array = cola.call()
		check.call("dos cuarteles elegidos: una pulsación entrena UNA unidad (%s)" % str(c1), c1[0] + c1[1] == 1)
		_key_shift(Teclas.tecla("grilla_%d" % slot))
		for i in 60:
			await _frames(1)
			if nuevos[0].queue.size() + nuevos[1].queue.size() > 1:
				break
		await _frames(3)
		var c2: Array = cola.call()
		check.call("Mayús: cinco en total, en el de cola más corta (%s)" % str(c2), c2[0] + c2[1] == 6 and absi(c2[0] - c2[1]) <= 1)
		# 4. Panel de varias unidades: un retrato por unidad; Mayús + clic saca, Ctrl + clic deja el tipo.
	else:
		check.call("hay lugar para dos cuarteles de prueba", false)
	var mil: Array[int] = []
	for e in sim.actives:
		if e.owner == local and e.is_military() and e.inside < 0:
			mil.append(e.id)
	cam.look_at_point(Vector3(base.x + 2, 0, base.y + 2))
	ctrl.select_ids(mil)
	await _frames(3)
	var hits: Array = hud._sel._hits
	check.call("panel de varias: un retrato con su vida por unidad (%d de %d)" % [hits.size(), mil.size()], mil.size() >= 2 and hits.size() == mil.size())
	if not mil.is_empty():
		var u0: SimEntity = sim.by_id[mil[0]]
		u0.hp = maxi(1, u0.hp_max / 4)
		ctrl.center_on_selection()
		_mouse(Vector2(960, 300), 0, false)
		await _frames(4)
		get_viewport().get_texture().get_image().save_png("screenshots/autotest_varias.png")
		u0.hp = u0.hp_max
	if hits.size() >= 2:
		var antes := ctrl.selection.size()
		await _click_mod(hud._sel.global_position + (hits[0][0] as Rect2).get_center(), true, false)
		check.call("Mayús + clic en un retrato saca esa unidad (%d → %d)" % [antes, ctrl.selection.size()], ctrl.selection.size() == antes - 1)
		var r1: Rect2 = hud._sel._hits[0][0]
		var t1: String = sim.by_id[ctrl.selection[0]].type
		await _click_mod(hud._sel.global_position + r1.get_center(), false, true)
		var solo := ctrl.selected_entities().all(func(e: SimEntity) -> bool: return e.type == t1)
		check.call("Ctrl + clic deja solo ese tipo (%s, %d)" % [t1, ctrl.selection.size()], solo and ctrl.selection.size() >= 1)
	# 5. M y «,» llevan la cámara a lo elegido.
	cam.look_at_point(Vector3(base.x + 40, 0, base.y + 40))
	await _frames(2)
	_key_tap(Teclas.tecla("ejercito"))
	await _frames(3)
	var cerca := func() -> bool:
		for e in ctrl.selected_entities():
			if Vector2(cam.focus.x, cam.focus.z).distance_to(Vector2(e.x / 1000.0, e.y / 1000.0)) < 2.0:
				return true
		return false
	check.call("M elige el ejército y centra la cámara en él", ctrl.selection.size() == mil.size() and cerca.call())
	cam.look_at_point(Vector3(base.x + 40, 0, base.y + 40))
	await _frames(2)
	sim.push_command({"t": "stop", "player": local, "ids": mil})
	await get_tree().create_timer(0.3).timeout
	_key_tap(Teclas.tecla("ocioso_militar"))
	await _frames(3)
	check.call("«,» elige un militar ocioso y centra la cámara", ctrl.selection.size() == 1 and cerca.call())
	# 6. Grupos exclusivos y grupo 0.
	if mil.size() >= 3:
		Teclas.grupos_exclusivos = true
		ctrl.select_ids(mil.slice(0, 3))
		_key_mod(Teclas.tecla("grupo_2"), true)
		await _frames(2)
		ctrl.select_ids([mil[0]] as Array[int])
		_key_mod(Teclas.tecla("grupo_3"), true)
		await _frames(2)
		check.call("grupos exclusivos: asignar al 3 saca del 2 (%d en el 2)" % (ctrl.groups[2] as Array).size(), not (ctrl.groups[2] as Array).has(mil[0]) and (ctrl.groups[2] as Array).size() == 2)
		Teclas.grupos_exclusivos = false
		ctrl.select_ids([mil[1]] as Array[int])
		_key_mod(Teclas.tecla("grupo_3"), false, true)
		await _frames(2)
		check.call("sin la opción, una unidad queda en dos grupos", (ctrl.groups[2] as Array).has(mil[1]) and (ctrl.groups[3] as Array).has(mil[1]))
		ctrl.select_ids(mil.slice(0, 2))
		_key_mod(KEY_0, true)
		await _frames(2)
		ctrl.select_ids([] as Array[int])
		_key_tap(KEY_0)
		await _frames(2)
		check.call("grupo 0: Ctrl + 0 asigna y 0 lo elige (%d)" % ctrl.selection.size(), ctrl.groups.has(0) and ctrl.selection.size() == 2)
		check.call("la fila de grupos muestra el 0", hud.grupos.grupos().any(func(g: Array) -> bool: return g[0] == 0) if hud.get("grupos") != null else true)
	# 3. H recorre los centros; dos toques o Mayús + H centran la cámara.
	var c2_at := _lugar_libre("centro", Vector2i(base.x + 22, base.y - 14)) if dd.edificios.has("centro") else Vector2i(-1, -1)
	var otro: SimEntity = sim.spawn_building("centro", local, c2_at.x, c2_at.y, true) if c2_at.x >= 0 else null
	await _frames(2)
	ctrl.select_ids([] as Array[int])
	cam.look_at_point(Vector3(base.x + 40, 0, base.y + 40))
	await _frames(2)
	var foco := cam.focus
	_key_tap(Teclas.tecla("centro"))
	await _frames(3)
	var s1 := ctrl.selected_entities()
	check.call("H elige la capital sin mover la cámara", s1.size() == 1 and s1[0].capital and cam.focus.distance_to(foco) < 0.5)
	await get_tree().create_timer(0.5).timeout
	_key_tap(Teclas.tecla("centro"))
	await _frames(3)
	var s2 := ctrl.selected_entities()
	check.call("otra H lleva al centro siguiente", otro != null and s2.size() == 1 and s2[0].id == otro.id)
	_key_tap(Teclas.tecla("centro"))
	await _frames(3)
	var s3 := ctrl.selected_entities()
	check.call("H dos veces seguidas centra la cámara en ese centro", otro != null and s3.size() == 1 and s3[0].id == otro.id and Vector2(cam.focus.x, cam.focus.z).distance_to(Vector2(otro.x / 1000.0, otro.y / 1000.0)) < 2.5)
	await get_tree().create_timer(0.5).timeout
	cam.look_at_point(Vector3(base.x + 40, 0, base.y + 40))
	await _frames(2)
	_key_shift(Teclas.tecla("centro"))
	await _frames(3)
	var s4 := ctrl.selected_entities()
	check.call("Mayús + H: vuelve a la capital y centra", s4.size() == 1 and s4[0].capital and Vector2(cam.focus.x, cam.focus.z).distance_to(Vector2(s4[0].x / 1000.0, s4[0].y / 1000.0)) < 2.5)
	# 8. El panel explica el círculo del centro.
	_mouse(Vector2(960, 300), 0, false)
	await _frames(3)
	get_viewport().get_texture().get_image().save_png("screenshots/autotest_circulo_centro.png")
	if otro != null:
		sim.remove_quietly(otro)
	# 1b. Reasignar una tecla: J pasa a recorrer los centros y H queda libre.
	await get_tree().create_timer(0.5).timeout
	# Por el diálogo de verdad: Opciones → Teclas, clic en la tecla del centro y J.
	hud._options.visible = true
	await _frames(2)
	(hud._options.find_child("BotonTeclas", true, false) as Button).pressed.emit()
	await _frames(2)
	var bc := hud._options.find_child("centro", true, false) as Button
	bc.grab_focus()
	bc.pressed.emit()
	await _frames(2)
	var espera := bc.text
	_key_tap(KEY_J)
	await _frames(3)
	check.call("Opciones → Teclas: clic en H, apretar J (%s → %s)" % [espera, bc.text], espera.begins_with("Apretá") and bc.text == "J" and Teclas.tecla("centro") == KEY_J)
	get_viewport().get_texture().get_image().save_png("screenshots/autotest_teclas.png")
	hud._options.visible = false
	await _frames(2)
	ctrl.select_ids([] as Array[int])
	_key_tap(KEY_H)
	await _frames(3)
	var libre := ctrl.selection.is_empty()
	_key_tap(KEY_J)
	await _frames(3)
	var sj := ctrl.selected_entities()
	check.call("tecla reasignada: J elige el centro y H ya no", libre and sj.size() == 1 and sj[0].capital)
	check.call("la ayuda de la grilla muestra la tecla asignada", Controller.etiqueta(0) == "Q")
	Teclas.de_fabrica()
	for b in nuevos:
		sim.remove_quietly(b)
	for k in saved:
		sim.players[local]["res"][k] = saved[k]
	ctrl.select_ids(_vill_ids())
	await _frames(2)
# --- fin veterano ronda 4 ---


func _vill_ids() -> Array[int]:
	var ids: Array[int] = []
	for e in sim.actives:
		if e.owner == local and e.fn == "civil" and e.inside < 0:
			ids.append(e.id)
	return ids
# --- fin veterano ---


func _alt(pressed: bool) -> InputEventKey:
	var k := InputEventKey.new()
	k.physical_keycode = KEY_ALT
	k.keycode = KEY_ALT
	k.pressed = pressed
	return k
# --- fin órdenes ---


## Hay hoja de cursores (no la hay sin ventana). --- cursores ---
func cursores_sheet() -> bool:
	return hud.cursores != null and hud.cursores.hoja() != null


func _autotest() -> void:
	var results: Array[String] = []
	var ok := true
	var check := func(name: String, cond: bool) -> void:
		results.append(("OK    " if cond else "FALLO ") + name)
	await _frames(20)
	var base := sim.bases[local]
	cam.look_at_point(Vector3(base.x + 2, 0, base.y + 2))
	await _frames(5)

	# 0. Ayuda de la barra de recursos (tiraba el juego: la ayuda pedía una casilla de grilla).
	for i in 4:
		_mouse(Vector2(60 + i * 115, 30), 0, false)
		await _frames(3)
	check.call("ayuda de la barra de recursos visible", hud._tip.visible if hud.get("_tip") != null else true)
	_mouse(Vector2(960, 540), 0, false)
	await _frames(2)

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
	# Un arbusto de verdad: "el alimento más cercano" ahora puede ser un venado o un animal suelto.
	var bush: SimEntity = null
	for e in sim.entities:
		if e.alive and e.type == "arbusto" and (bush == null or Sim.dist(e.x, e.y, base.x * 1000, base.y * 1000) < Sim.dist(bush.x, bush.y, base.x * 1000, base.y * 1000)):
			bush = e
	var bush_sp := cam.cam.unproject_position(WorldView.to_world(bush.x, bush.y, 0.2))
	# --- cursores --- (el cursor anticipa la orden: recolectar sobre el arbusto, mover sobre el suelo)
	_mouse(bush_sp, 0, false)
	await _frames(3)
	check.call("cursor de recolectar alimento sobre el arbusto (%s)" % ctrl.cursor_action(bush_sp), ctrl.cursor_action(bush_sp) == "recolectar_alimento")
	var empty_sp := _screen(base.x - 6.0, base.y + 10.0)
	_mouse(empty_sp, 0, false)
	await _frames(3)
	check.call("cursor de mover sobre el suelo (%s)" % ctrl.cursor_action(empty_sp), ctrl.cursor_action(empty_sp) in ["mover", ""])
	if cursores_sheet():
		check.call("se dibujaron los cursores (%d)" % hud.cursores.texturas.size(), hud.cursores.texturas.size() >= 12)
	# --- fin cursores ---
	_mouse(bush_sp, MOUSE_BUTTON_RIGHT, true)
	_mouse(bush_sp, MOUSE_BUTTON_RIGHT, false)
	await _frames(40)
	var gathering := 0
	for e in sim.actives:
		if e.owner == local and e.fn == "civil" and e.order == SimEntity.Order.GATHER:
			gathering += 1
	check.call("clic derecho en arbustos pone a recolectar (%d)" % gathering, gathering >= ctrl.selection.size() - 1 and gathering > 0)
	# --- animal propio --- (el autor: "mis aldeanos no matan las llamas porque son aliados")
	var beast := sim.spawn_unit("rebano", local, (base.x - 4) * 1000, (base.y + 6) * 1000)
	var butcher: SimEntity = null
	for e in sim.actives:
		if e.owner == local and e.fn == "civil" and e.is_unit():
			butcher = e
			break
	ctrl.select_ids([butcher.id] as Array[int])
	await _frames(4)
	var beast_sp := cam.cam.unproject_position(WorldView.to_world(beast.x, beast.y, 0.4))
	_mouse(beast_sp, 0, false)
	await _frames(3)
	check.call("cursor de juntar alimento sobre un animal propio (%s)" % ctrl.cursor_action(beast_sp), ctrl.cursor_action(beast_sp) == "recolectar_alimento")
	# Con el aldeano elegido pegado al animal (el tester lo vio fallar según por dónde caminaba).
	# El cursor entre los dos, más cerca del aldeano: antes ganaba el aldeano y decía «mover».
	sim.push_command({"t": "stop", "player": local, "ids": [butcher.id]})
	await _frames(3)
	butcher.x = beast.x + 500
	butcher.y = beast.y
	butcher.goal_x = butcher.x
	butcher.goal_y = butcher.y
	await _frames(30) # que el modelo llegue a donde quedó
	var b_sp := cam.cam.unproject_position((view.visuals[butcher.id]["node"] as Node3D).position + Vector3(0, 0.45, 0))
	var a_sp := cam.cam.unproject_position((view.visuals[beast.id]["node"] as Node3D).position + Vector3(0, 0.45, 0))
	beast_sp = b_sp.lerp(a_sp, 0.4)
	_mouse(beast_sp, 0, false)
	await _frames(3)
	check.call("con el aldeano pegado al animal (a %.0f px), el cursor sigue en juntar (%s; bajo el cursor: %s)" % [b_sp.distance_to(a_sp), ctrl.cursor_action(beast_sp), sim.by_id[ctrl.pick(beast_sp, true)].type if ctrl.pick(beast_sp, true) >= 0 else "nada"], ctrl.cursor_action(beast_sp) == "recolectar_alimento")
	_mouse(beast_sp, MOUSE_BUTTON_RIGHT, true)
	_mouse(beast_sp, MOUSE_BUTTON_RIGHT, false)
	await _frames(90)
	check.call("clic derecho en un animal propio: el aldeano lo carnea (vivo %s, orden %d, junta %s)" % [beast.alive, butcher.order, butcher.gather_kind], not beast.alive and butcher.gather_kind == "alimento")
	# --- fin animal propio ---

	# 3. Q (Economía), Q (casa) y clic. --- grilla ---
	var spot := Vector2i(-1, -1)
	for r in range(5, 12):
		for d in range(-r, r + 1):
			if spot.x < 0 and sim.can_place("casa", base.x + d, base.y + r):
				spot = Vector2i(base.x + d, base.y + r)
	_key_tap(KEY_Q)
	await _frames(2)
	check.call("Q abre el submenú de economía", ctrl.submenu == "economia")
	_key_tap(KEY_ESCAPE)
	await _frames(2)
	check.call("Esc vuelve a la raíz sin deseleccionar", ctrl.submenu == "" and not ctrl.selection.is_empty())
	_key_tap(KEY_Q)
	await _frames(2)
	_key_tap(KEY_Q)
	await _frames(2)
	check.call("Q, Q entra en modo de construcción de casa", ctrl.mode == "place" and ctrl.place_type == "casa")
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
	# --- casillas --- (jugador nuevo, ronda 4: en Q se dibujaba «Herramientas de tala» y entrenaba un aldeano)
	await _frames(2)
	var dib: Dictionary = hud._card.dibujadas
	var en_q: Dictionary = dib.get(0, {})
	var en_w: Dictionary = dib.get(1, {})
	var quiere_q := centro != null and (centro.def.get("produce", []) as Array).has("aldeano")
	check.call("la grilla del centro dibuja «%s» en Q y «%s» en W" % [en_q.get("name", "—"), en_w.get("name", "—")], (not quiere_q or en_q.get("id", "") == "aldeano") and ((centro == null or not (centro.def.get("produce", []) as Array).has("explorador")) or en_w.get("id", "") == "explorador"))
	var repetidas := 0
	var vistas := {}
	for c in ctrl.commands():
		repetidas += 1 if vistas.has(int(c["slot"])) else 0
		vistas[int(c["slot"])] = true
	check.call("ninguna casilla del centro tiene dos comandos (%d repetidas)" % repetidas, repetidas == 0)
	# --- fin casillas ---
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
	await _frames(2)
	check.call("la fila de grupos muestra el grupo 1", hud.grupos.grupos().size() == 1 and hud.grupos.visible) # --- avisos ---

	speed = 4.0
	# Espera hasta que entre el primer alimento (máximo 40 s reales: con la máquina cargada,
	# 20 no alcanzaban y la prueba fallaba de a ratos).
	for i in 80:
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
	# --- grilla --- (W militar y la casilla fija de la empalizada)
	var wall_slot: Variant = ctrl.villager_slots("militar").find_key("empalizada")
	if wall_slot != null:
		_key_tap(KEY_W)
		await _frames(2)
		_key_tap(Controller.SLOT_KEYS[wall_slot])
	# --- fin grilla ---
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
	if wall_slot != null:
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
	# --- avisos --- (Espacio va al último ataque; sin selección el panel y la grilla no tapan)
	var far := Vector3(base.x + 18, 0, base.y + 14)
	hud.notify("¡Nos atacan! (prueba)", -1.0, "ataque", far)
	hud.notify("Aviso de información (prueba)", -1.0, "info")
	await _frames(2)
	_key_tap(KEY_SPACE)
	await _frames(3)
	check.call("Espacio lleva la cámara al último ataque (%.0f, %.0f)" % [cam.focus.x, cam.focus.z], Vector2(cam.focus.x, cam.focus.z).distance_to(Vector2(far.x, far.z)) < 1.5)
	check.call("los avisos se apilan sin pisarse (%d)" % hud.avisos.lista.size(), hud.avisos.lista.size() >= 2)
	ctrl.select_ids([] as Array[int])
	await _frames(3)
	check.call("sin selección se ocultan el panel y la grilla", not hud._sel.visible and not hud._card.visible)
	ctrl.select_ids(vill_ids)
	await _frames(3)
	check.call("con selección vuelven", hud._sel.visible and hud._card.visible)
	if cursores_sheet():
		hud.cursores.hoja().save_png("screenshots/cursores.png")
	# --- fin avisos ---
	await _autotest_ordenes(check) # --- órdenes ---
	await _autotest_veterano(check) # --- veterano ---
	await _autotest_veterano4(check) # --- veterano ronda 4 ---
	# --- aprender --- (avisos que enseñan, cuenta de sitios, nombres en la grilla, registro de la Guía y fin)
	var cs = hud.consejos
	Opciones.consejos = true
	hud.avisos.lista.clear()
	sim.push_command({"t": "stop", "player": local, "ids": vill_ids})
	await _frames(6)
	cs._said.clear() # el aviso real pudo haber salido antes (los aldeanos estuvieron quietos)
	cs._since.clear()
	cs.check(0)
	cs.check(int(cs.cfg.get("ociosos_s", 20)) + 1)
	var said := func(part: String) -> bool:
		for a in hud.avisos.lista:
			if String(a["texto"]).contains(part):
				return true
		return false
	check.call("aviso de aldeanos sin trabajo", said.call("sin trabajo"))
	hud.avisos.lista.clear()
	Opciones.consejos = false
	cs._said.clear()
	cs._last_check = -1
	await _frames(3)
	check.call("con los avisos apagados en Opciones no avisa", not said.call("sin trabajo"))
	Opciones.consejos = true
	var rival := 1 if local == 0 else 0
	sim.players[rival]["sitios_ms"] = 60000 # solo para la prueba: la simulación lo recalcula cada segundo
	cs.check(1)
	await _frames(2)
	check.call("cuenta grande de sitios del rival (jugador %d)" % CuentaGrande.sites_holder(sim), CuentaGrande.sites_holder(sim) == rival and hud.cuenta.visible)
	check.call("aviso «perdés en M:SS»", said.call("perdés en"))
	get_viewport().get_texture().get_image().save_png("screenshots/autotest_sitios.png")
	sim.players[rival]["sitios_ms"] = 0
	# Empujón (4j): ejército grande en casa y recursos de sobra → «atacá o subí de edad».
	var emp: Dictionary = cs.cfg.get("empujon", {})
	var capital: SimEntity = null
	for e in sim.actives:
		if e.alive and e.owner == local and e.capital:
			capital = e
	var extra: Array[SimEntity] = []
	for ki in int(emp.get("ejercito_min", 15)):
		extra.append(sim.spawn_unit("guerrero", local, capital.x + 3000 + (ki % 5) * 800, capital.y + 3000 + (ki / 5) * 800))
	var bank_before: Dictionary = (sim.players[local]["res"] as Dictionary).duplicate()
	sim.players[local]["res"]["madera"] = int(sim.players[local]["res"]["madera"]) + int(emp.get("recursos_min", 2000))
	hud.avisos.lista.clear()
	cs._said.erase("empujon")
	cs._since.erase("empujon")
	cs.check(0)
	cs.check(int(emp.get("durante_s", 90)) + 1)
	check.call("aviso «atacá o subí de edad» con ejército en casa y recursos de sobra", said.call("atacá o subí de edad"))
	check.call("el aviso dice hacia dónde está la base rival y la marca en el minimapa", said.call("hacia el ") and not hud._mini.senalado.is_empty())
	check.call("el aviso dice que los edificios caen con asedio", said.call("hace falta asedio"))
	await _frames(2)
	get_viewport().get_texture().get_image().save_png("screenshots/autotest_empujon.png")
	for e in extra:
		sim._kill(e)
	sim.players[local]["res"] = bank_before
	await _autotest_lejos(check, cs, said, capital, vill_ids) # --- depósitos de comida --- (4m)
	await _autotest_pelea(check, cs, said) # --- pelea --- (4q)
	EstadoCasilla.nombres = true
	ctrl.select_ids(vill_ids)
	await _frames(3)
	get_viewport().get_texture().get_image().save_png("screenshots/autotest_nombres.png")
	check.call("nombres en la grilla sin errores", hud._card.visible)
	# --- depósitos de comida --- (4m) el submenú Economía con nombres: el almacén dice qué recibe.
	ctrl.open_submenu(Grilla.ECONOMIA)
	await _frames(3)
	get_viewport().get_texture().get_image().save_png("screenshots/autotest_grilla_economia.png")
	var food_store: String = hud.CONSEJOS.best_store(sim.dp(local), "alimento", int(sim.players[local]["age"]))
	if food_store != "":
		ctrl.open_submenu(Grilla.menu_de(sim.dp(local), food_store)) # la qollqa va en Militar
		await _frames(2)
		var cmd_food: Dictionary = {}
		for cmd in ctrl.commands():
			if cmd["id"] == food_store:
				cmd_food = cmd
		check.call("en la grilla, %s dice que recibe alimento (común «%s», ícono %s)" % [food_store, cmd_food.get("common", ""), cmd_food.get("icon", "")], String(cmd_food.get("icon", "")).contains("alimento") and cmd_food.get("common", "") != "Leñera")
		if not cmd_food.is_empty():
			var vs := get_viewport().get_visible_rect().size
			hud.show_tip(cmd_food, Rect2(vs - Vector2(200, 200), Vector2(60, 60)))
			await _frames(3)
			get_viewport().get_texture().get_image().save_png("screenshots/autotest_grilla_ayuda.png")
			hud.hide_tip()
	ctrl.open_submenu(Grilla.RAIZ)
	# --- fin depósitos de comida ---
	EstadoCasilla.nombres = Opciones.nombres_grilla
	var rg = hud.REGISTRO_GUIA.new()
	hud.add_child(rg)
	rg.setup(hud)
	rg.add({"quien": "Guía", "texto": "Mensaje de prueba"})
	# G (de Guía): F7 a F9 son los marcadores de cámara de la parte B.
	_key_tap(KEY_G)
	await _frames(3)
	check.call("G abre el registro de la Guía", rg.is_open())
	_key_tap(KEY_G)
	await _frames(2)
	check.call("G lo cierra", not rg.is_open())
	rg.queue_free()
	hud.paneles.show_end(rival)
	await _frames(3)
	var fin = hud.paneles.fin
	check.call("la pantalla de fin explica por qué terminó (%s)" % fin._why, fin.visible and fin._why != "")
	check.call("la pantalla de fin tiene el gráfico de edad", fin.CHARTS.any(func(c: Array) -> bool: return c[0] == "age"))
	fin.visible = false
	# --- fin aprender ---
	var img := get_viewport().get_texture().get_image()
	img.save_png("screenshots/autotest.png")
	for r in results:
		print(r)
		if r.begins_with("FALLO"):
			ok = false
	print("AUTOTEST: ", "OK" if ok else "FALLO")
	get_tree().quit(0 if ok else 1)
