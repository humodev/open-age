extends SceneTree
## proceso/56-rig-y-color: comparación de arreglos del rig de Meshy y prueba del color del equipo en 3D.
## No toca el juego. Los GLB se cargan con GLTFDocument (pueden estar fuera de res://, p. ej. en .cache/).
##
## --modo=rig: filas con la misma luz y el mismo tamaño (FIGURE_H × unidad_pct):
##   --filas=Nombre|ruta.glb|meshy;Nombre|ruta.glb|kaykit;...
##   «meshy» usa los clips de Meshy que trae el GLB; «kaykit» retargetea los de KayKit
##   (assets/animaciones/kaykit/personas_kaykit.glb, mismo retarget que tools/visor_rig.gd).
## --modo=color: el mismo aldeano en cuatro colores del equipo y la máscara, de cerca y a la
##   distancia del juego. --glb=<modelo> --mascara=<png> --luz=<luz_ref> [--clip=Idle] [--nombre=x]
##
##   godot --path . --resolution 1600x900 -s tools/rig_y_color.gd -- --dir=<carpeta> --modo=...

const KAYKIT := "res://assets/animaciones/kaykit/personas_kaykit.glb"
const SHADER := "res://src/game/shaders/equipo_3d.gdshader"
# Poses comparables: [clip de Meshy, clip de KayKit, fracción, rótulo].
const POSES := [
	["Idle", "Idle_A", 0.5, "quieto"],
	["Charged_Axe_Chop", "Chopping", 0.45, "talar"],
	["Heavy_Hammer_Swing", "Pickaxing", 0.5, "picar"],
	["Pull_Radish", "Working_A", 0.5, "cosechar"],
	["Collect_Object", "PickUp", 0.4, "juntar"],
	["Attack", "Interact", 0.5, "pegar/usar"],
]

var dir := "user://"
var args := {}
var H := 0.9
var cam: Camera3D
var _w: Node3D
var _src_sk: Skeleton3D
var _src_ap: AnimationPlayer
var _poses: Array = []


func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--") and "=" in a:
			var kv := a.substr(2).split("=", true, 1)
			args[kv[0]] = kv[1]
	dir = str(args.get("dir", dir))
	DirAccess.make_dir_recursive_absolute(dir)
	var reglas: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/reglas.json")) if FileAccess.file_exists("res://data/reglas.json") else {}
	H = WorldView.FIGURE_H * float(reglas.get("escala_visual", {}).get("unidad_pct", 100)) / 100.0
	var src: Node3D = (load(KAYKIT) as PackedScene).instantiate()
	src.visible = false
	root.add_child(src)
	_src_sk = src.find_child("Skeleton3D", true, false)
	_src_ap = src.find_child("AnimationPlayer", true, false)
	if args.get("modo", "rig") == "color":
		_color.call_deferred()
	else:
		_rig.call_deferred()


func _escena() -> void:
	if _w != null:
		_w.free()
	_w = Node3D.new()
	root.add_child(_w)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-50, 150, 0)
	sun.shadow_enabled = true
	_w.add_child(sun)
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR
	env.environment.background_color = Color(0.62, 0.7, 0.76)
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color(0.7, 0.72, 0.75)
	env.environment.ambient_light_energy = 0.8
	_w.add_child(env)
	var floor := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(80, 80)
	floor.mesh = pm
	var fm := StandardMaterial3D.new()
	fm.albedo_color = Color(0.45, 0.52, 0.32)
	floor.material_override = fm
	_w.add_child(floor)
	cam = Camera3D.new()
	_w.add_child(cam)
	_poses.clear()


func _img() -> Image:
	for p in _poses:
		var ap: AnimationPlayer = p[0]
		ap.play(p[1])
		ap.seek(p[2], true)
		ap.pause()
	for i in 8:
		await process_frame
	return root.get_texture().get_image()


func _guardar(img: Image, name: String) -> void:
	img.save_jpg("%s/%s.jpg" % [dir, name], 0.85)
	print("captura: %s/%s.jpg" % [dir, name])


func _cargar(path: String) -> Node3D:
	var doc := GLTFDocument.new()
	var st := GLTFState.new()
	if doc.append_from_file(path, st) != OK:
		push_error("no carga " + path)
		return Node3D.new()
	return doc.generate_scene(st)


## Escala y apoya en el suelo (la medida es la de la malla sola, en la pose de reposo).
func _apoyar(inst: Node3D, matte := true) -> Node3D:
	var box := WorldView._aabb(inst, Transform3D.IDENTITY)
	for mi: MeshInstance3D in inst.find_children("*", "MeshInstance3D", true, false):
		if mi.skin != null or mi.get_parent() is Skeleton3D:
			box = mi.mesh.get_aabb()
			break
	var k := H / maxf(0.001, box.size.y)
	var c := Vector2(box.position.x + box.size.x / 2.0, box.position.z + box.size.z / 2.0)
	inst.scale = Vector3.ONE * k
	inst.position = Vector3(-c.x * k, -box.position.y * k, -c.y * k)
	WorldView._each_geo(inst, func(g: GeometryInstance3D) -> void:
		g.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
		if matte:
			WorldView._matte(g))
	var h := Node3D.new()
	h.add_child(inst)
	return h


## Figura en la pose `i` de POSES: clips propios (Meshy) o KayKit retargeteado.
func _figura(path: String, tipo: String, i: int) -> Node3D:
	var inst := _cargar(path)
	var sk: Skeleton3D = inst.find_children("*", "Skeleton3D", true, false)[0]
	var p: Array = POSES[i]
	if tipo == "meshy":
		var ap: AnimationPlayer = inst.find_children("*", "AnimationPlayer", true, false)[0]
		if ap.has_animation(p[0]):
			_poses.append([ap, p[0], ap.get_animation(p[0]).length * float(p[2])])
	else:
		var a := _retarget(_src_sk, _src_ap.get_animation(p[1]), sk)
		var ap := AnimationPlayer.new()
		inst.add_child(ap)
		ap.root_node = ap.get_path_to(sk.get_parent())
		var lib := AnimationLibrary.new()
		lib.add_animation(p[1], a)
		ap.add_animation_library("", lib)
		_poses.append([ap, p[1], a.length * float(p[2])])
	return _apoyar(inst)


func _etiqueta(txt: String, pos: Vector3, tam := 22) -> void:
	var l := Label3D.new()
	l.text = txt
	l.font_size = tam
	l.pixel_size = 0.004
	l.outline_size = 8
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l.position = pos
	_w.add_child(l)


func _rig() -> void:
	var filas: Array = []
	for f in str(args.get("filas", "")).split(";", false):
		filas.append(f.split("|"))
	var sep := 0.85
	var n := POSES.size()
	var tiras: Array[Image] = []
	# Una toma por fila (de frente, un poco desde arriba) y después se apilan.
	for r in filas.size():
		_escena()
		var fila: Array = filas[r]
		for i in n:
			var f := _figura(fila[1], fila[2], i)
			f.position = Vector3((i - (n - 1) / 2.0) * sep, 0, 0)
			f.rotation.y = deg_to_rad(30)
			_w.add_child(f)
			_etiqueta(POSES[i][3], Vector3(f.position.x, 0.06, 0.42), 26)
		_etiqueta(fila[0], Vector3(0, H + 0.42, -0.3), 30)
		cam.fov = 30
		var asp := root.get_visible_rect().size.x / maxf(1.0, root.get_visible_rect().size.y)
		var d := (n * sep + 0.5) / 2.0 / (tan(deg_to_rad(cam.fov * 0.5)) * asp)
		cam.position = Vector3(0, 0.3 + d * 0.3, d)
		cam.look_at(Vector3(0, 0.3, 0.12), Vector3.UP)
		var im := await _img()
		var hh := im.get_height()
		tiras.append(im.get_region(Rect2i(0, int(hh * 0.12), im.get_width(), int(hh * 0.58))))
	var w := tiras[0].get_width()
	var th := tiras[0].get_height()
	var out := Image.create(w, th * tiras.size(), false, tiras[0].get_format())
	for i in tiras.size():
		out.blit_rect(tiras[i], Rect2i(0, 0, w, th), Vector2i(0, i * th))
	out.resize(w * 2 / 3, th * tiras.size() * 2 / 3, Image.INTERPOLATE_LANCZOS)
	_guardar(out, str(args.get("nombre", "rig")))
	quit(0)


## --------------------------------------------------------------- Color del equipo

func _material(inst: Node3D, mask: Texture2D, color: Color, ver: bool) -> void:
	for mi: MeshInstance3D in inst.find_children("*", "MeshInstance3D", true, false):
		for s in mi.mesh.get_surface_count():
			var m := mi.mesh.surface_get_material(s)
			if not m is StandardMaterial3D:
				continue
			var sm := ShaderMaterial.new()
			sm.shader = load(SHADER)
			sm.set_shader_parameter("textura", (m as StandardMaterial3D).albedo_texture)
			sm.set_shader_parameter("mascara", mask)
			sm.set_shader_parameter("equipo", color)
			sm.set_shader_parameter("luz_ref", float(args.get("luz", "0.08")))
			sm.set_shader_parameter("ver_mascara", ver)
			mi.set_surface_override_material(s, sm)


func _color() -> void:
	var img := Image.load_from_file(str(args["mascara"]))
	img.generate_mipmaps()
	var mask := ImageTexture.create_from_image(img)
	var colores: Array = [Palette.TEAM[0], Palette.TEAM[1], Color("e8c020"), Palette.TEAM[5]]
	var clip := str(args.get("clip", "Idle"))
	var nombre := str(args.get("nombre", "color"))
	_escena()
	var yaw := deg_to_rad(RtsCamera.YAW_DEG)
	var fwd := Vector3(sin(yaw), 0, cos(yaw))
	var right := Vector3(-fwd.z, 0, fwd.x)
	var items: Array = colores.duplicate()
	items.append(null) # máscara
	items.append("sin") # original
	for i in items.size():
		var inst := _cargar(str(args["glb"]))
		var aps := inst.find_children("*", "AnimationPlayer", true, false)
		if aps.size() > 0:
			var ap: AnimationPlayer = aps[0]
			var an := clip if ap.has_animation(clip) else ap.get_animation_list()[0]
			_poses.append([ap, an, ap.get_animation(an).length * 0.4])
		var it = items[i]
		var h := _apoyar(inst, it is String)
		if not it is String:
			_material(inst, mask, it if it is Color else Color.WHITE, it == null)
		h.position = right * (i - (items.size() - 1) / 2.0) * 0.8
		h.rotation.y = atan2(-fwd.x, -fwd.z) + 0.5
		_w.add_child(h)
	# De cerca.
	cam.fov = 30
	cam.position = -fwd * 5.2 + Vector3(0, 1.9, 0)
	cam.look_at(Vector3(0, H * 0.5, 0), Vector3.UP)
	_guardar(await _img(), "color_%s_cerca" % nombre)
	# A la distancia del juego (inclinación y giro de RtsCamera, zoom 28): recorte 3× y tamaño real.
	var pitch := deg_to_rad(RtsCamera.PITCH_DEG)
	cam.position = -fwd * cos(pitch) * 28.0 + Vector3(0, sin(pitch) * 28.0, 0)
	cam.look_at(Vector3.ZERO, Vector3.UP)
	var im := await _img()
	var sc := float(im.get_width()) / maxf(1.0, root.get_visible_rect().size.x)
	var c := cam.unproject_position(Vector3(0, H * 0.5, 0)) * sc
	var zo := im.get_region(Rect2i(int(c.x) - 160, int(c.y) - 60, 320, 120))
	_guardar(zo, "color_%s_rts_real" % nombre)
	zo.resize(960, 360, Image.INTERPOLATE_NEAREST)
	_guardar(zo, "color_%s_rts" % nombre)
	quit(0)


## --------------------------------------------------------------- Retarget (copia de tools/visor_rig.gd)

func _pista(a: Animation, bone: String, ty: int) -> int:
	for t in a.get_track_count():
		if a.track_get_type(t) == ty and String(a.track_get_path(t).get_concatenated_subnames()) == bone:
			return t
	return -1


func _rot_q(b: Basis) -> Quaternion:
	return b.orthonormalized().get_rotation_quaternion()


func _retarget(src: Skeleton3D, a: Animation, dst: Skeleton3D) -> Animation:
	var out := Animation.new()
	out.length = a.length
	out.loop_mode = Animation.LOOP_LINEAR
	var n := dst.get_bone_count()
	var map: Array[int] = []
	for j in n:
		map.append(src.find_bone(dst.get_bone_name(j)))
	var corr: Array[Quaternion] = []
	for j in n:
		var c := Quaternion()
		var i := map[j]
		if i >= 0:
			for h in dst.get_bone_children(j):
				var hi := map[h]
				if hi < 0:
					continue
				var dt := dst.get_bone_global_rest(h).origin - dst.get_bone_global_rest(j).origin
				var ds := src.get_bone_global_rest(hi).origin - src.get_bone_global_rest(i).origin
				if dt.length() > 0.0001 and ds.length() > 0.0001:
					c = Quaternion(dt.normalized(), ds.normalized())
				break
			if c == Quaternion() and dst.get_bone_parent(j) >= 0:
				c = corr[dst.get_bone_parent(j)]
		corr.append(c)
	var hips_s := src.find_bone("hips")
	var hips_d := dst.find_bone("hips")
	var k := dst.get_bone_global_rest(hips_d).origin.y / maxf(0.001, src.get_bone_global_rest(hips_s).origin.y) if hips_s >= 0 and hips_d >= 0 else 1.0
	var tr: Array[int] = []
	for j in n:
		var t := out.add_track(Animation.TYPE_ROTATION_3D)
		out.track_set_path(t, NodePath("%s:%s" % [dst.name, dst.get_bone_name(j)]))
		tr.append(t)
	var tp := out.add_track(Animation.TYPE_POSITION_3D)
	out.track_set_path(tp, NodePath("%s:hips" % dst.name))
	var fps := 30.0
	var frames := int(ceil(a.length * fps))
	for f in frames + 1:
		var t := minf(a.length, f / fps)
		var sg: Array[Transform3D] = []
		for i in src.get_bone_count():
			var bn := src.get_bone_name(i)
			var r := _pista(a, bn, Animation.TYPE_ROTATION_3D)
			var p := _pista(a, bn, Animation.TYPE_POSITION_3D)
			var rest := src.get_bone_rest(i)
			var q: Quaternion = a.rotation_track_interpolate(r, t) if r >= 0 else rest.basis.get_rotation_quaternion()
			var o: Vector3 = a.position_track_interpolate(p, t) if p >= 0 else rest.origin
			var loc := Transform3D(Basis(q), o)
			var par := src.get_bone_parent(i)
			sg.append(sg[par] * loc if par >= 0 else loc)
		var g: Array[Quaternion] = []
		for j in n:
			var i := map[j]
			var q: Quaternion
			if i >= 0:
				var off := _rot_q(sg[i].basis) * _rot_q(src.get_bone_global_rest(i).basis).inverse()
				q = off * corr[j] * _rot_q(dst.get_bone_global_rest(j).basis)
			else:
				var par := dst.get_bone_parent(j)
				q = (g[par] if par >= 0 else Quaternion()) * _rot_q(dst.get_bone_rest(j).basis)
			g.append(q)
			var par := dst.get_bone_parent(j)
			var local := (g[par].inverse() * q) if par >= 0 else q
			out.rotation_track_insert_key(tr[j], t, local.normalized())
		if hips_s >= 0 and hips_d >= 0:
			var dpos := (sg[hips_s].origin - src.get_bone_global_rest(hips_s).origin) * k
			var gpos := dst.get_bone_global_rest(hips_d).origin + dpos
			var par := dst.get_bone_parent(hips_d)
			var lpos := gpos
			if par >= 0:
				lpos = dst.get_bone_global_rest(par).affine_inverse() * gpos
			out.position_track_insert_key(tp, t, lpos)
	return out
