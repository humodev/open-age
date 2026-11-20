extends SceneTree
## Prueba de los modelos 3D locales (proceso/43-3d-local) junto a los de hoy, con la cámara
## del RTS (pitch 54°, yaw 45°, fov 30, como RtsCamera). No toca la simulación ni el arte
## del juego: lee los GLB de assets/ui/arte/tawantinsuyu/modelos_prueba/.
##
## Fila de atrás: kancha (casa) maqueta · casa GLB de hoy (Meshy) · casa nueva ·
##                kallanka (cuartel) maqueta · kallanka nueva.
## Fila de adelante: aldeano maqueta · aldeano GLB de hoy · aldeano nuevo ·
##                   llama (maqueta) · jinete etíope (GLB de hoy) · caballo nuevo.
## Escala como WorldView._model_for: las personas a FIGURE_H × escala_visual.unidad_pct; los
## edificios con su lado mayor = tam − 2 × margen (sin el estiramiento a altura_min_cm).
##
## Uso (necesita GPU, sin --headless; antes, godot --headless --path . --import):
##   godot --path . -s tools/visor_3d_local.gd -- --shot=proceso/43-3d-local/img/juego.jpg [--zoom=14] [--cerca]
##   [--antes-despues]: solo las piezas de proceso/43 junto a las del pipeline (proceso/47,
##   assets/generados/modelos/local/), con el caballo caminando.

const NUEVOS := "res://assets/ui/arte/tawantinsuyu/modelos_prueba/%s.glb"
const HOY := "res://assets/generados/modelos/%s.glb"
const LOCAL := "res://assets/generados/modelos/local/%s.glb"
const TEAM := Color("c8c2b4")

var _shot := "user://visor_3d_local.jpg"
var _zoom := 15.0
var _cerca := false
var _antes_despues := false
var _dd: SimData
var _unit_h := 0.75


func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--shot="):
			_shot = a.substr(7)
		elif a.begins_with("--zoom="):
			_zoom = float(a.substr(7))
		elif a == "--cerca":
			_cerca = true
		elif a == "--antes-despues":
			_antes_despues = true
	var reglas: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/reglas.json"))
	_unit_h = WorldView.FIGURE_H * float(reglas["escala_visual"]["unidad_pct"]) / 100.0
	_dd = SimData.load_default().civs["tawantinsuyu"]
	_escenario()
	_tomar.call_deferred()


func _escenario() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("9fb3c8")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("c9d3e0")
	env.ambient_light_energy = 0.6
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.ssao_enabled = true
	var we := WorldEnvironment.new()
	we.environment = env
	root.add_child(we)
	var sol := DirectionalLight3D.new()
	sol.light_color = Color("fff1dc")
	sol.light_energy = 1.2
	sol.shadow_enabled = true
	sol.rotation_degrees = Vector3(-50, -20, 0)
	root.add_child(sol)
	var suelo := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(60, 60)
	suelo.mesh = pm
	suelo.material_override = Meshes.mat(Color("8d9461"), 1.0)
	root.add_child(suelo)

	# Ejes de la cámara del RTS: mira hacia +x+z; "derecha" en pantalla = (-f.z, 0, f.x).
	var f := Vector3(sin(deg_to_rad(RtsCamera.YAW_DEG)), 0, cos(deg_to_rad(RtsCamera.YAW_DEG)))
	var der := Vector3(-f.z, 0, f.x)
	var atras := [
		["Kancha · maqueta", _maqueta_edificio("casa")],
		["Casa · GLB de hoy", _glb_edificio(HOY % "tawantinsuyu_casa", "casa")],
		["Kancha · Hunyuan", _glb_edificio(NUEVOS % "casa", "casa")],
		["Kallanka · maqueta", _maqueta_edificio("cuartel")],
		["Kallanka · Hunyuan", _glb_edificio(NUEVOS % "kallanka", "cuartel")],
	]
	var adelante := [
		["Aldeano · maqueta", _maqueta_unidad("aldeano")],
		["Aldeano · GLB de hoy", _glb_unidad(HOY % "tawantinsuyu_aldeano", _unit_h)],
		["Aldeano · Hunyuan", _glb_unidad(NUEVOS % "aldeano", _unit_h)],
		["Llama · maqueta", _llama()],
		["Jinete etíope · GLB de hoy", _glb_unidad(HOY % "etiopia_jinete", _unit_h * 1.45)],
		["Caballo · Hunyuan", _glb_unidad(NUEVOS % "caballo", _unit_h * 1.1)],
	]
	if _antes_despues:
		atras = [
			["Kancha · 43", _glb_edificio(NUEVOS % "casa", "casa")],
			["Kancha · pipeline", _glb_edificio(LOCAL % "tawantinsuyu_casa", "casa")],
			["Kallanka · 43", _glb_edificio(NUEVOS % "kallanka", "cuartel")],
			["Kallanka · pipeline", _glb_edificio(LOCAL % "tawantinsuyu_kallanka", "cuartel")],
		]
		adelante = [
			["Aldeano · 43", _glb_unidad(NUEVOS % "aldeano", _unit_h)],
			["Aldeano · pipeline", _glb_unidad(LOCAL % "tawantinsuyu_aldeano", _unit_h)],
			["Caballo · 43", _glb_unidad(NUEVOS % "caballo", _unit_h * 1.1)],
			["Caballo · pipeline", _glb_unidad(LOCAL % "caballo_criollo", _unit_h * 1.05)],
		]
		var ap: AnimationPlayer = (adelante[3][1] as Node).find_child("AnimationPlayer", true, false) if adelante[3][1] != null else null
		if ap != null and ap.has_animation("caminar"):
			ap.play("caminar")
	var paso_b := 3.4
	var paso_u := 1.15 if not _cerca else 0.9
	for i in atras.size():
		_poner(atras[i][1], atras[i][0], der * (float(i) - (atras.size() - 1) / 2.0) * paso_b + f * 2.6, true)
	for i in adelante.size():
		_poner(adelante[i][1], adelante[i][0], der * (float(i) - (adelante.size() - 1) / 2.0) * paso_u - f * 0.6, false)

	var cam := Camera3D.new()
	cam.fov = 30.0
	root.add_child(cam)
	var foco := Vector3.ZERO if not _cerca else -f * 0.6
	var pitch := deg_to_rad(RtsCamera.PITCH_DEG)
	cam.look_at_from_position(foco - f * cos(pitch) * _zoom + Vector3(0, sin(pitch) * _zoom, 0), foco, Vector3.UP)


func _poner(n: Node3D, nombre: String, at: Vector3, edificio: bool) -> void:
	if n == null:
		print("falta: ", nombre)
		return
	n.position = at
	root.add_child(n)
	var l := Label3D.new()
	l.text = nombre
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l.font_size = 40 if edificio else 22
	l.pixel_size = 0.004
	l.outline_size = 6
	l.no_depth_test = true
	l.position = at + Vector3(0, -0.15, 0) - Vector3(sin(deg_to_rad(45)), 0, cos(deg_to_rad(45))) * (1.6 if edificio else 0.45)
	root.add_child(l)


func _cargar(path: String) -> Node3D:
	if not ResourceLoader.exists(path):
		return null
	var inst: Node3D = (load(path) as PackedScene).instantiate()
	WorldView._each_geo(inst, func(g: GeometryInstance3D) -> void:
		g.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
		WorldView._matte(g))
	return inst


## Apoyado en el suelo, centrado y escalado: por alto (`alto` > 0) o por el lado mayor.
func _encajar(inst: Node3D, alto: float, lado: float) -> Node3D:
	var box := WorldView._aabb(inst, Transform3D.IDENTITY)
	var k := alto / box.size.y if alto > 0.0 else lado / maxf(box.size.x, box.size.z)
	var c := box.get_center()
	inst.scale = Vector3.ONE * k
	inst.position = Vector3(-c.x * k, -box.position.y * k, -c.z * k)
	var holder := Node3D.new()
	holder.add_child(inst)
	return holder


func _glb_unidad(path: String, alto: float) -> Node3D:
	var inst := _cargar(path)
	if inst == null:
		return null
	var h := _encajar(inst, alto, 0)
	# El frente del GLB es +z; la cámara está hacia −x−z: −135° lo pone de frente, +20° de tres cuartos.
	h.rotation.y = deg_to_rad(-135.0 + 20.0)
	return h


func _glb_edificio(path: String, tipo: String) -> Node3D:
	var inst := _cargar(path)
	if inst == null:
		return null
	var tam: Array = _dd.edificios[tipo].get("tam", [2, 2])
	var lado := maxf(0.8, minf(float(tam[0]), float(tam[1])) - 2.0 * CivMeshes.margin())
	var h := _encajar(inst, 0, lado)
	h.rotation.y = WorldView.GLB_FRENTE_YAW
	return h


func _maqueta_edificio(tipo: String) -> Node3D:
	var def: Dictionary = _dd.edificios[tipo]
	var mi := MeshInstance3D.new()
	mi.mesh = CivMeshes.building(tipo, def, TEAM, _dd.civ.get("estilo", {}), 0, 0)
	return mi


func _maqueta_unidad(tipo: String) -> Node3D:
	var mi := MeshInstance3D.new()
	mi.mesh = CivMeshes.unit(tipo, _dd.unidades[tipo], TEAM, _dd.civ.get("estilo", {}))
	var h := Node3D.new()
	h.add_child(mi)
	h.scale = Vector3.ONE * (_unit_h / WorldView.MAQUETA_H)
	h.rotation.y = deg_to_rad(45.0 + 20.0) # la maqueta tiene el frente en −z
	return h


func _llama() -> Node3D:
	var mi := MeshInstance3D.new()
	mi.mesh = Animales.mesh("llama")
	return mi


func _tomar() -> void:
	for i in 30:
		await process_frame
	var img := root.get_viewport().get_texture().get_image()
	var ruta := ProjectSettings.globalize_path(_shot) if _shot.begins_with("res://") or _shot.begins_with("user://") else _shot
	img.save_jpg(ruta, 0.85)
	print("VISOR: ", ruta)
	quit(0)
