extends SceneTree
## Prueba de los rigs del pipeline 3D (proceso/47-pipeline-3d), sin tocar el juego:
## - el aldeano generado (19 huesos con los nombres de KayKit) con las animaciones de
##   assets/animaciones/kaykit/personas_kaykit.glb, retargeteadas al vuelo;
## - el caballo con sus propios ciclos (caminar y quieto, hechos en Blender).
##
## Retarget (lo que hace el BoneMap de Godot con «Fix Silhouette», a mano): por cada hueso del
## mismo nombre, el giro de la animación respecto del reposo de KayKit, en el espacio del
## esqueleto, se aplica sobre el reposo del aldeano corregido para que cada hueso apunte como
## en el reposo de KayKit (pose T); así la pose A del aldeano no deja los brazos 45° más abajo.
## La cadera se mueve como en KayKit, escalada por el alto de la cadera.
##
## Uso (con GPU, sin --headless):
##   godot --path . -s tools/visor_rig.gd -- --shot=proceso/47-pipeline-3d/img/rig.jpg [--modo=caminar|trabajo|caballo|todo]

const KAYKIT := "res://assets/animaciones/kaykit/personas_kaykit.glb"
const ALDEANO := "res://assets/generados/modelos/local/tawantinsuyu_aldeano.glb"
const CABALLO := "res://assets/generados/modelos/local/caballo_criollo.glb"

var _shot := "user://visor_rig.jpg"
var _modo := "todo"
var _src_sk: Skeleton3D
var _src_ap: AnimationPlayer
var _poses: Array = [] # [AnimationPlayer, animación, segundo]: se aplican ya dentro del árbol


func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--shot="):
			_shot = a.substr(7)
		elif a.begins_with("--modo="):
			_modo = a.substr(7)
	var src: Node3D = (load(KAYKIT) as PackedScene).instantiate()
	src.visible = false
	root.add_child(src)
	_src_sk = src.find_child("Skeleton3D", true, false)
	_src_ap = src.find_child("AnimationPlayer", true, false)
	_escenario()
	_tomar.call_deferred()


func _escenario() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("cfc8ba")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("d8dce4")
	env.ambient_light_energy = 0.7
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	var we := WorldEnvironment.new()
	we.environment = env
	root.add_child(we)
	var sol := DirectionalLight3D.new()
	sol.light_energy = 1.3
	sol.shadow_enabled = true
	sol.rotation_degrees = Vector3(-50, -30, 0)
	root.add_child(sol)
	var suelo := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(20, 20)
	suelo.mesh = pm
	suelo.material_override = Meshes.mat(Color("8d9461"), 1.0)
	root.add_child(suelo)

	var filas: Array = []
	if _modo in ["caminar", "todo"]:
		filas.append(["Walking_A", [0.0, 0.25, 0.5, 0.75]])
	if _modo in ["trabajo", "todo"]:
		filas.append(["Chopping", [0.15, 0.45]])
		filas.append(["Pickaxing", [0.3]])
	var x := 0.0
	var items: Array = []
	for f in filas:
		for fr: float in f[1]:
			items.append([ALDEANO, f[0], fr, false])
	if _modo in ["caballo", "todo"]:
		for fr: float in [0.0, 0.25, 0.5, 0.75]:
			items.append([CABALLO, "caminar", fr, true])
		items.append([CABALLO, "quieto", 0.5, true])
	var ancho := 0.0
	for it in items:
		ancho += 1.05 if it[3] else 0.55
	x = -ancho / 2.0
	for it in items:
		var paso := 1.05 if it[3] else 0.55
		var n := _figura(it[0], it[1], it[2], it[3])
		if n != null:
			n.position = Vector3(x + paso / 2.0, 0, 0)
			root.add_child(n)
			var l := Label3D.new()
			l.text = "%s %.2f" % [it[1], it[2]]
			l.font_size = 11
			l.pixel_size = 0.004
			l.outline_size = 5
			l.position = Vector3(x + paso / 2.0, 0.02, 0.6)
			l.rotation_degrees = Vector3(-60, 0, 0)
			root.add_child(l)
		x += paso
	var cam := Camera3D.new()
	cam.fov = 30.0
	root.add_child(cam)
	var dist := ancho * 1.05 + 0.7
	cam.look_at_from_position(Vector3(0, dist * 0.3, dist * 1.0), Vector3(0, 0.33, 0), Vector3.UP)


## Una figura quieta en la fracción `fr` de la animación `an`.
func _figura(path: String, an: String, fr: float, propia: bool) -> Node3D:
	if not ResourceLoader.exists(path):
		print("falta: ", path)
		return null
	var inst: Node3D = (load(path) as PackedScene).instantiate()
	var holder := Node3D.new()
	holder.add_child(inst)
	var sk: Skeleton3D = inst.find_child("Skeleton3D", true, false)
	if sk == null:
		sk = inst.find_children("*", "Skeleton3D", true, false)[0] if inst.find_children("*", "Skeleton3D", true, false).size() > 0 else null
	if propia:
		var ap: AnimationPlayer = inst.find_child("AnimationPlayer", true, false)
		print("caballo: animaciones ", ap.get_animation_list() if ap else [])
		if ap and ap.has_animation(an):
			_poses.append([ap, an, ap.get_animation(an).length * fr])
		holder.rotation.y = deg_to_rad(-25.0)
		return holder
	if sk == null:
		print("sin esqueleto: ", path)
		return holder
	var a := _retarget(_src_sk, _src_ap.get_animation(an), sk)
	var ap := AnimationPlayer.new()
	holder.add_child(ap)
	ap.root_node = ap.get_path_to(sk.get_parent())
	var lib := AnimationLibrary.new()
	lib.add_animation(an, a)
	ap.add_animation_library("", lib)
	_poses.append([ap, an, a.length * fr])
	holder.rotation.y = deg_to_rad(-20.0)
	return holder


func _pista(a: Animation, bone: String, ty: int) -> int:
	for t in a.get_track_count():
		if a.track_get_type(t) == ty and String(a.track_get_path(t).get_concatenated_subnames()) == bone:
			return t
	return -1


func _rot_q(b: Basis) -> Quaternion:
	return b.orthonormalized().get_rotation_quaternion()


## Animación de KayKit llevada al esqueleto `dst` (huesos con los mismos nombres).
func _retarget(src: Skeleton3D, a: Animation, dst: Skeleton3D) -> Animation:
	var out := Animation.new()
	out.length = a.length
	out.loop_mode = Animation.LOOP_LINEAR
	var n := dst.get_bone_count()
	var map: Array[int] = []
	for j in n:
		map.append(src.find_bone(dst.get_bone_name(j)))
	# Corrección de reposo: que cada hueso apunte hacia su primer hijo como en KayKit.
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
				c = corr[dst.get_bone_parent(j)] # hojas (cabeza, muñecas, dedos): como el padre
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
		# Pose global de KayKit armada a mano (fuera del árbol el esqueleto no la actualiza).
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
				# El padre (root) no se anima: su pose global es la de reposo.
				lpos = dst.get_bone_global_rest(par).affine_inverse() * gpos
			out.position_track_insert_key(tp, t, lpos)
	return out


func _tomar() -> void:
	await process_frame
	for p in _poses:
		var ap: AnimationPlayer = p[0]
		ap.play(p[1])
		ap.seek(p[2], true)
		ap.pause()
	for i in 20:
		await process_frame
	var img := root.get_viewport().get_texture().get_image()
	var ruta := ProjectSettings.globalize_path(_shot) if _shot.begins_with("res://") or _shot.begins_with("user://") else _shot
	img.save_jpg(ruta, 0.88)
	print("VISOR_RIG: ", ruta)
	quit(0)
