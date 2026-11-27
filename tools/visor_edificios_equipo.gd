extends SceneTree
## Color del equipo en edificios generados (proceso/58-edificios-locales): cada modelo en cuatro
## colores (de Palette.TEAM) y con la máscara en magenta, con la cámara del RTS. Usa lo mismo que
## el juego: WorldView._matte y WorldView._equipo_edificio (data/modelos_equipo.json y
## <modelo>_mascara.png), así que lo que se ve acá es lo que se ve en la partida.
##
## Uso (con GPU, sin --headless):
##   godot --path . -s tools/visor_edificios_equipo.gd -- --modelos=local/tawantinsuyu_casa:casa,local/tawantinsuyu_cuartel:cuartel \
##       --civ=tawantinsuyu --shot=proceso/58-edificios-locales/img/x.jpg [--zoom=16] [--sin-mascara]

const COLORES := [0, 1, 2, 5] # azul, rojo, violeta, verde
var _shot := "user://visor_edificios_equipo.jpg"
var _zoom := 16.0
var _modelos: Array = []
var _civ := "tawantinsuyu"
var _ver_mascara := true


func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--shot="):
			_shot = a.substr(7)
		elif a.begins_with("--zoom="):
			_zoom = float(a.substr(7))
		elif a.begins_with("--civ="):
			_civ = a.substr(6)
		elif a.begins_with("--modelos="):
			_modelos = Array(a.substr(10).split(","))
		elif a == "--sin-mascara":
			_ver_mascara = false
	_escenario()
	_tomar.call_deferred()


func _escenario() -> void:
	var dd: SimData = SimData.load_default().civs[_civ]
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
	pm.size = Vector2(120, 120)
	suelo.mesh = pm
	suelo.material_override = Meshes.mat(Color("8d9461"), 1.0)
	root.add_child(suelo)
	var f := Vector3(sin(deg_to_rad(RtsCamera.YAW_DEG)), 0, cos(deg_to_rad(RtsCamera.YAW_DEG)))
	var der := Vector3(-f.z, 0, f.x)
	var cols := COLORES.size() + (1 if _ver_mascara else 0)
	for fi in _modelos.size():
		var partes: PackedStringArray = str(_modelos[fi]).split(":")
		var nombre := partes[0]
		var tipo := partes[1] if partes.size() > 1 else "casa"
		var tam: Array = dd.edificios.get(tipo, {}).get("tam", [3, 3])
		var lado := maxf(0.8, minf(float(tam[0]), float(tam[1])) - 2.0 * CivMeshes.margin())
		var paso := float(tam[0]) + 0.6
		for ci in cols:
			var team: Color = Palette.TEAM[COLORES[ci]] if ci < COLORES.size() else Color(1, 0, 1)
			var n := _edificio(nombre, lado, team, ci >= COLORES.size())
			if n == null:
				print("falta: ", nombre)
				continue
			n.position = der * (float(ci) - (cols - 1) / 2.0) * paso + f * (float(fi) - (_modelos.size() - 1) / 2.0) * -paso * 2.2
			root.add_child(n)
	var cam := Camera3D.new()
	cam.fov = 30.0
	root.add_child(cam)
	var pitch := deg_to_rad(RtsCamera.PITCH_DEG)
	cam.look_at_from_position(-f * cos(pitch) * _zoom + Vector3(0, sin(pitch) * _zoom, 0), Vector3.ZERO, Vector3.UP)


func _edificio(nombre: String, lado: float, team: Color, mascara: bool) -> Node3D:
	var path := "res://assets/generados/modelos/%s.glb" % nombre
	if not ResourceLoader.exists(path):
		return null
	var inst: Node3D = (load(path) as PackedScene).instantiate()
	WorldView._each_geo(inst, func(g: GeometryInstance3D) -> void:
		g.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
		WorldView._matte(g))
	WorldView._equipo_edificio(inst, nombre, path, team)
	if mascara:
		WorldView._each_geo(inst, func(g: GeometryInstance3D) -> void:
			var mi := g as MeshInstance3D
			for i in mi.mesh.get_surface_count():
				var m := mi.get_surface_override_material(i)
				if m is ShaderMaterial:
					var c := (m as ShaderMaterial).duplicate() as ShaderMaterial
					c.set_shader_parameter("ver_mascara", true)
					mi.set_surface_override_material(i, c))
	var box := WorldView._aabb(inst, Transform3D.IDENTITY)
	var k := lado / maxf(box.size.x, box.size.z)
	var c := box.get_center()
	inst.scale = Vector3.ONE * k
	inst.position = Vector3(-c.x * k, -box.position.y * k, -c.z * k)
	var h := Node3D.new()
	h.add_child(inst)
	h.rotation.y = WorldView.GLB_FRENTE_YAW
	return h


func _tomar() -> void:
	for i in 30:
		await process_frame
	var img := root.get_viewport().get_texture().get_image()
	var ruta := ProjectSettings.globalize_path(_shot) if _shot.begins_with("res://") or _shot.begins_with("user://") else _shot
	img.save_jpg(ruta, 0.85)
	print("VISOR: ", ruta)
	quit(0)
