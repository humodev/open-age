extends SceneTree
## Retratos de las fichas (docs/07, "Interfaz"): renderiza fuera de pantalla cada unidad,
## edificio y recurso con los mismos modelos del juego (GLB generados o mallas de CivMeshes
## y Meshes) en un SubViewport con luz de estudio y fondo transparente.
##
## Salida: assets/generados/retratos/<civ>/<tipo>.png (256×256). "comun" guarda la capa
## común sin civilización (sitio sagrado, edificios de la naturaleza) y los recursos del mapa.
##
## Uso (necesita GPU: sin --headless):
##   godot --path . -s tools/render_retratos.gd [-- --civs=guaranies,mapuches --tipos=casa,aldeano]
## Después: godot --headless --path . --import  (genera los .import para cargarlos con load()).

const SIZE := 256
const OUT := "res://assets/generados/retratos"
## Color de equipo neutro: la ficha marca el dueño con su borde y su bandera.
const TEAM := Color("c8c2b4")

var _vp: SubViewport
var _cam: Camera3D
var _holder: Node3D
var _filter_civs: PackedStringArray = []
var _filter_types: PackedStringArray = []


func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		var kv := a.trim_prefix("--").split("=")
		if kv.size() < 2:
			continue
		match kv[0]:
			"civs":
				_filter_civs = kv[1].split(",")
			"tipos":
				_filter_types = kv[1].split(",")
	_build_stage()
	_run.call_deferred()


func _build_stage() -> void:
	_vp = SubViewport.new()
	_vp.size = Vector2i(SIZE, SIZE)
	_vp.transparent_bg = true
	_vp.own_world_3d = true
	_vp.msaa_3d = Viewport.MSAA_8X
	_vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(_vp)

	var env := Environment.new()
	env.background_mode = Environment.BG_CLEAR_COLOR
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("b9c4d6")
	env.ambient_light_energy = 0.55
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.tonemap_exposure = 0.95
	env.ssao_enabled = true
	env.ssao_radius = 0.6
	env.ssao_intensity = 1.6
	var we := WorldEnvironment.new()
	we.environment = env
	_vp.add_child(we)

	# Luz de estudio: principal cálida arriba a la izquierda, relleno frío y contraluz.
	var key := DirectionalLight3D.new()
	key.light_color = Color("fff1dc")
	key.light_energy = 1.15
	key.shadow_enabled = true
	key.directional_shadow_max_distance = 30.0
	key.rotation_degrees = Vector3(-42, -35, 0)
	_vp.add_child(key)
	var fill := DirectionalLight3D.new()
	fill.light_color = Color("aac4ff")
	fill.light_energy = 0.35
	fill.rotation_degrees = Vector3(-15, 70, 0)
	_vp.add_child(fill)
	var rim := DirectionalLight3D.new()
	rim.light_color = Color("ffe2b0")
	rim.light_energy = 0.7
	rim.rotation_degrees = Vector3(-25, 165, 0)
	_vp.add_child(rim)

	_cam = Camera3D.new()
	_cam.fov = 28.0
	_cam.near = 0.05
	_cam.far = 200.0
	_vp.add_child(_cam)
	_holder = Node3D.new()
	_vp.add_child(_holder)


func _run() -> void:
	var data := SimData.load_default()
	var count := 0
	var jobs: Array = [] # [carpeta, tipo, creador del Node3D, es unidad]
	for civ: String in data.civs:
		if not _filter_civs.is_empty() and not _filter_civs.has(civ):
			continue
		var dd: SimData = data.civs[civ]
		for type: String in dd.unidades:
			jobs.append([civ, type, _unit_node.bind(dd, type), true])
		for type: String in dd.edificios:
			if not dd.edificios[type].get("sagrado", false): # el sitio es de la naturaleza: va en "comun"
				jobs.append([civ, type, _building_node.bind(dd, type), false])
	if _filter_civs.is_empty() or _filter_civs.has("comun"):
		for type: String in data.unidades:
			jobs.append(["comun", type, _unit_node.bind(data, type), true])
		for type: String in data.edificios:
			jobs.append(["comun", type, _building_node.bind(data, type), false])
		for type: String in data.recursos:
			jobs.append(["comun", type, _resource_node.bind(type), false])
	for j in jobs:
		if not _filter_types.is_empty() and not _filter_types.has(j[1]):
			continue
		var node: Node3D = (j[2] as Callable).call()
		if node == null:
			continue
		await _shoot(node, j[0], j[1], j[3])
		count += 1
	print("RETRATOS: %d imágenes en %s" % [count, OUT])
	quit(0)


# ---------------------------------------------------------------- Modelos (como WorldView)

func _glb(dd: SimData, type: String) -> Node3D:
	var name: String = dd.civ.get("estilo", {}).get("modelos", {}).get(type, "")
	if name == "":
		return null
	var path := "res://assets/generados/modelos/%s.glb" % name
	if not ResourceLoader.exists(path):
		return null
	var inst: Node3D = (load(path) as PackedScene).instantiate()
	WorldView._each_geo(inst, func(g: GeometryInstance3D) -> void: WorldView._matte(g))
	return inst


func _unit_node(dd: SimData, type: String) -> Node3D:
	var n := _glb(dd, type)
	if n != null:
		return n
	var def: Dictionary = dd.unidades[type]
	var style: Dictionary = dd.civ.get("estilo", {})
	var mi := MeshInstance3D.new()
	mi.mesh = Meshes.unit_mesh(type, TEAM) if style.is_empty() else CivMeshes.unit(type, def, TEAM, style)
	return mi


func _building_node(dd: SimData, type: String) -> Node3D:
	var n := _glb(dd, type)
	if n != null:
		return n
	var def: Dictionary = dd.edificios[type]
	var style: Dictionary = dd.civ.get("estilo", {})
	var mi := MeshInstance3D.new()
	if style.is_empty():
		mi.mesh = Meshes.building_mesh(type, TEAM)
	else:
		var variant := 0
		var tier := 0
		for row in dd.hitos.size():
			var idx: int = (dd.hitos[row] as Array).find(type)
			if idx >= 0:
				variant = idx
				tier = row
		mi.mesh = CivMeshes.building(type, def, TEAM, style, variant, tier)
	if def.get("sagrado", false):
		var root := Node3D.new()
		root.add_child(mi)
		var pole := MeshInstance3D.new()
		pole.mesh = Meshes.cyl(0.03, 0.03, 0.6, 6)
		pole.position = Vector3(0, 1.75, 0)
		pole.material_override = Meshes.mat(Palette.WOOD_BEAM)
		root.add_child(pole)
		var flag := MeshInstance3D.new()
		flag.mesh = Meshes.box(0.05, 0.5, 0.6)
		flag.position = Vector3(0.18, 1.75, 0.3)
		flag.material_override = Meshes.mat(Palette.UI_ACCENT)
		root.add_child(flag)
		return root
	return mi


func _resource_node(type: String) -> Node3D:
	var mi := MeshInstance3D.new()
	match type:
		"arbol":
			mi.mesh = Meshes.tree_mesh(0)
		"arbusto":
			mi.mesh = Meshes.bush_mesh()
		_:
			mi.mesh = Meshes.rock_mesh(type)
	return mi


# ---------------------------------------------------------------- Toma

func _shoot(node: Node3D, folder: String, type: String, unit: bool) -> void:
	for c in _holder.get_children():
		c.queue_free()
	_holder.add_child(node)
	var box := WorldView._aabb(node, Transform3D.IDENTITY)
	var center := box.get_center()
	var radius := maxf(box.size.length() * 0.5, 0.05)
	# Tres cuartos: las unidades un poco más de frente, los edificios más desde arriba.
	var yaw := deg_to_rad(28.0)
	var pitch := deg_to_rad(14.0 if unit else 26.0)
	var dir := Vector3(sin(yaw) * cos(pitch), sin(pitch), cos(yaw) * cos(pitch))
	var dist := radius / sin(deg_to_rad(_cam.fov * 0.5)) * (0.92 if unit else 0.98)
	_cam.position = center + dir * dist
	_cam.look_at(center, Vector3.UP)
	# Dos cuadros: el primero compila sombreadores y asienta las sombras.
	await process_frame
	await RenderingServer.frame_post_draw
	await process_frame
	await RenderingServer.frame_post_draw
	var img := _vp.get_texture().get_image()
	img.convert(Image.FORMAT_RGBA8)
	var dir_path := "%s/%s" % [OUT, folder]
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(dir_path))
	img.save_png("%s/%s.png" % [dir_path, type])
