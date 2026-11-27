extends SceneTree
## Comparación de aldeanos para C-98/C-99 (proceso/55-comparar-aldeanos). Solo herramienta: no toca
## el juego. Por pueblo, lado a lado, con la misma luz:
##   1) el aldeano animado del juego (KayKit, AldeanoAnimado, vestido como hombre de la edad 1);
##   2) el GLB quieto de Meshy (assets/generados/modelos/<pueblo>_aldeano.glb);
##   3) el del pipeline local (assets/generados/modelos/local/<pueblo>_aldeano.glb) caminando con
##      Walking_A de KayKit retargeteado (el mismo retarget que tools/visor_rig.gd);
##   4) solo si existe: el Meshy riggeado por la API de Meshy (--meshy_rig=<civ>:<walking.glb>).
## Todos a la altura del juego (FIGURE_H × unidad_pct) y con el material mate del juego.
## Capturas: <civ>_rts.jpg (cámara del juego: inclinación 54°, giro 45°, zoom 28, fov 30; recorte
## ampliado 3× sin suavizar), <civ>_rts_real.jpg (el mismo recorte a tamaño real), <civ>_cerca.jpg
## y <civ>_caminata.jpg (seis cuadros del ciclo de caminar de 1, 3 y 4).
##
##   godot --path . --resolution 1920x1080 -s tools/comparar_aldeanos.gd -- --dir=<carpeta> [--civs=a,b] [--meshy_rig=tawantinsuyu:/ruta/walking.glb]

const CIVS := ["tawantinsuyu", "mapuches", "guaranies", "etiopia", "palmares", "ayutthaya"]
const KAYKIT := "res://assets/animaciones/kaykit/personas_kaykit.glb"
const TEAM := Color("2f6fd6")
const SEP := 0.9
const CICLO := [0.0, 0.167, 0.333, 0.5, 0.667, 0.833]

var args := {}
var dir := "screenshots/comparar"
var H := 0.75
var _src_sk: Skeleton3D
var _src_ap: AnimationPlayer
var _rig := {} # civ -> ruta del walking.glb de Meshy
var _w: Node3D
var cam: Camera3D
var _sc := 1.0


func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		var kv := a.trim_prefix("--").split("=", true, 1)
		args[kv[0]] = kv[1] if kv.size() > 1 else "1"
	dir = args.get("dir", dir)
	DirAccess.make_dir_recursive_absolute(dir)
	if args.has("meshy_rig"):
		var p: PackedStringArray = str(args["meshy_rig"]).split(":", true, 1)
		_rig[p[0]] = p[1]
	var reglas: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/reglas.json"))
	H = WorldView.FIGURE_H * float(reglas.get("escala_visual", {}).get("unidad_pct", 100)) / 100.0
	var src: Node3D = (load(KAYKIT) as PackedScene).instantiate()
	src.visible = false
	root.add_child(src)
	_src_sk = src.find_child("Skeleton3D", true, false)
	_src_ap = src.find_child("AnimationPlayer", true, false)
	if args.get("modo", "") == "meshy":
		_clips.call_deferred()
	elif args.get("modo", "") == "soldados":
		_soldados.call_deferred()
	else:
		_correr.call_deferred()


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


func _frames(n: int) -> void:
	for i in n:
		await process_frame


func _img() -> Image:
	await _frames(4)
	var img := root.get_texture().get_image()
	_sc = float(img.get_width()) / maxf(1.0, root.get_visible_rect().size.x)
	if not has_meta("dicho"):
		set_meta("dicho", true)
		print("captura %s, vista %s" % [img.get_size(), root.get_visible_rect().size])
	return img


## Punto de la escena en píxeles de la captura (la ventana puede estar escalada).
func _px(p: Vector3) -> Vector2:
	return cam.unproject_position(p) * _sc


func _guardar(img: Image, name: String) -> void:
	img.save_jpg("%s/%s.jpg" % [dir, name], 0.85)
	print("captura: %s/%s.jpg" % [dir, name])


# ---------------------------------------------------------------- Figuras

## Escala y apoya en el suelo un GLB (como WorldView._model_for con una figura de pie).
func _apoyar(inst: Node3D) -> Node3D:
	var box := WorldView._aabb(inst, Transform3D.IDENTITY)
	# Malla con piel (Meshy riggeado): el esqueleto viene en centímetros bajo un Armature a 0,01,
	# pero los vértices quedan en metros; la medida buena es la de la malla sola.
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
		WorldView._matte(g))
	var h := Node3D.new()
	h.add_child(inst)
	return h


## Devuelve [nodo, callable que lo pone en la fracción `fr` del ciclo de caminar (ya en el árbol)].
func _figura(kind: String, civ: String, fr: float) -> Array:
	match kind:
		"kaykit":
			var civd: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/civs/%s.json" % civ))
			var av := AldeanoAnimado.crear(civd.get("estilo", {}), TEAM, H, civ)
			AldeanoAnimado.vestir(av, civ, "m", 1)
			av.mi.set_instance_shader_parameter("tono", 1.0)
			av.node.scale = Vector3.ONE * H
			var pose := func() -> void:
				AldeanoAnimado._propio(av)
				av.ap.play("Walking_A")
				av.ap.advance(fr * av.ap.current_animation_length)
			return [av.node, pose]
		"meshy":
			var ps: PackedScene = load("res://assets/generados/modelos/%s_aldeano.glb" % civ)
			return [_apoyar(ps.instantiate()), func() -> void: pass]
		"local":
			var ps: PackedScene = load("res://assets/generados/modelos/local/%s_aldeano.glb" % civ)
			var inst: Node3D = ps.instantiate()
			var sks := inst.find_children("*", "Skeleton3D", true, false)
			if sks.is_empty():
				# GLB sin esqueleto (los huesos llegaron como nodos sueltos): queda quieto.
				print("sin esqueleto: local/%s_aldeano" % civ)
				return [_apoyar(inst), func() -> void: pass]
			var sk: Skeleton3D = sks[0]
			var a := _retarget(_src_sk, _src_ap.get_animation("Walking_A"), sk)
			var ap := AnimationPlayer.new()
			var lib := AnimationLibrary.new()
			lib.add_animation("caminar", a)
			var h := _apoyar(inst)
			h.add_child(ap)
			ap.root_node = ap.get_path_to(sk.get_parent())
			ap.add_animation_library("", lib)
			return [h, _pausar.bind(ap, "caminar", fr)]
		"meshy_rig":
			return _meshy(_rig[civ], "", fr)
	return [Node3D.new(), func() -> void: pass]


## Un GLB animado de Meshy (riggeado por su API) en el clip `clip` (o el primero).
func _meshy(path: String, clip: String, fr: float, banda := false) -> Array:
	var doc := GLTFDocument.new()
	var st := GLTFState.new()
	if doc.append_from_file(path, st) != OK:
		return [Node3D.new(), func() -> void: pass]
	var inst: Node3D = doc.generate_scene(st)
	var ap: AnimationPlayer = inst.find_children("*", "AnimationPlayer", true, false)[0]
	var an: String = clip if clip != "" else ap.get_animation_list()[0]
	ap.get_animation(an).loop_mode = Animation.LOOP_LINEAR
	if banda:
		# Color del equipo: la faja del juego (WorldView._model_for), colgada del hueso de la cadera.
		var sk: Skeleton3D = inst.find_children("*", "Skeleton3D", true, false)[0]
		var ba := BoneAttachment3D.new()
		ba.bone_name = "Hips"
		sk.add_child(ba)
		var band := MeshInstance3D.new()
		var tm := TorusMesh.new()
		tm.inner_radius = 0.86
		tm.outer_radius = 1.0
		band.mesh = tm
		band.scale = Vector3(21.0, 50.0, 19.0) # en centímetros, como el esqueleto
		band.position = Vector3(0, 8.0, 0)
		band.material_override = Meshes.mat(TEAM, 0.7)
		ba.add_child(band)
	return [_apoyar(inst), _pausar.bind(ap, an, fr)]


func _pausar(ap: AnimationPlayer, an: String, fr: float) -> void:
	ap.play(an)
	ap.seek(ap.get_animation(an).length * fr, true)
	ap.pause()


func _tipos(civ: String) -> Array:
	var t := ["kaykit", "meshy", "local"]
	if _rig.has(civ):
		t.append("meshy_rig")
	return t


func _etiqueta(txt: String, pos: Vector3, rot: float) -> void:
	var l := Label3D.new()
	l.text = txt
	l.font_size = 40
	l.pixel_size = 0.0022
	l.outline_size = 10
	l.position = pos
	l.rotation = Vector3(-PI / 2.4, rot, 0)
	_w.add_child(l)


# ---------------------------------------------------------------- Capturas

func _correr() -> void:
	var civs: Array = str(args.get("civs", ",".join(CIVS))).split(",")
	var nombres := {"kaykit": "1 KayKit", "meshy": "2 Meshy quieto", "local": "3 Local", "meshy_rig": "4 Meshy riggeado"}
	for civ: String in civs:
		# Lado a lado: cámara del juego y de cerca.
		_escena()
		var tipos := _tipos(civ)
		var yaw := deg_to_rad(RtsCamera.YAW_DEG)
		var fwd := Vector3(sin(yaw), 0, cos(yaw))
		var right := Vector3(-fwd.z, 0, fwd.x)
		var poses: Array = []
		for j in tipos.size():
			var f := _figura(tipos[j], civ, 0.25)
			var n: Node3D = f[0]
			n.position = right * (j - (tipos.size() - 1) / 2.0) * SEP
			n.rotation.y = atan2(-fwd.x, -fwd.z) + 0.35
			_w.add_child(n)
			poses.append(f[1])
		for p: Callable in poses:
			p.call()
		var pitch := deg_to_rad(RtsCamera.PITCH_DEG)
		var zoom := 28.0
		cam.fov = 30
		cam.position = -fwd * cos(pitch) * zoom + Vector3(0, sin(pitch) * zoom, 0)
		cam.look_at(Vector3.ZERO, Vector3.UP)
		var img := await _img()
		var c := _px(Vector3(0, H * 0.5, 0))
		var rw := int(SEP * tipos.size() * 80) + 80
		var rect := Rect2i(int(c.x) - rw / 2, int(c.y) - 55, rw, 110)
		var real := img.get_region(Rect2i(int(c.x) - 320, int(c.y) - 180, 640, 360))
		_guardar(real, "%s_rts_real" % civ)
		var zo := img.get_region(rect)
		zo.resize(rect.size.x * 3, rect.size.y * 3, Image.INTERPOLATE_NEAREST)
		_guardar(zo, "%s_rts" % civ)
		# De cerca, de frente a la cámara con un cuarto de giro.
		var cpos := -fwd * (3.4 + tipos.size() * 0.9) + Vector3(0, 1.3, 0)
		cam.fov = 22
		cam.position = cpos
		cam.look_at(Vector3(0, H * 0.5, 0), Vector3.UP)
		for j in tipos.size():
			_etiqueta(nombres[tipos[j]], right * (j - (tipos.size() - 1) / 2.0) * SEP - fwd * 0.45 + Vector3(0, 0.01, 0), atan2(-fwd.x, -fwd.z))
		var cerca := await _img()
		var cc := _px(Vector3(0, H * 0.45, 0))
		var izq := _px(-right * (tipos.size() / 2.0) * SEP)
		var cw := clampi(int(2.0 * (cc.x - izq.x)) + 120, 600, cerca.get_width())
		var ch := mini(cerca.get_height(), int(cw * 0.5))
		var reg := cerca.get_region(Rect2i(clampi(int(cc.x) - cw / 2, 0, cerca.get_width() - cw), clampi(int(cc.y) - ch / 2 - 40, 0, cerca.get_height() - ch), cw, ch))
		if cw > 1400:
			reg.resize(1400, int(ch * 1400.0 / cw), Image.INTERPOLATE_LANCZOS)
		_guardar(reg, "%s_cerca" % civ)
		await _caminata(civ)
	quit(0)


## Tira de seis cuadros del ciclo de caminar, de costado: una fila por tipo animado.
func _caminata(civ: String) -> void:
	var filas: Array = []
	for kind: String in _tipos(civ):
		if kind == "meshy":
			continue
		_escena()
		var poses: Array = []
		for i in CICLO.size():
			var f := _figura(kind, civ, CICLO[i])
			var n: Node3D = f[0]
			n.position = Vector3((i - (CICLO.size() - 1) / 2.0) * 0.55, 0, 0)
			n.rotation.y = PI / 2 # camina hacia la derecha de la pantalla
			_w.add_child(n)
			poses.append(f[1])
		for p: Callable in poses:
			p.call()
		cam.fov = 20
		cam.position = Vector3(0, 0.7, 9.5)
		cam.look_at(Vector3(0, H * 0.5, 0), Vector3.UP)
		var img := await _img()
		var c := _px(Vector3(0, H * 0.5, 0))
		var row := img.get_region(Rect2i(int(c.x) - 620, int(c.y) - 190, 1240, 380))
		filas.append(row)
	var out := Image.create(1240, 380 * filas.size(), false, filas[0].get_format())
	for i in filas.size():
		out.blit_rect(filas[i], Rect2i(0, 0, 1240, 380), Vector2i(0, 380 * i))
	_guardar(out, "%s_caminata" % civ)


# ---------------------------------------------------------------- Soldados (C-99)

## --modo=soldados [--civs=a,b] [--edad=3] [--accion=quieto|golpe]: por pueblo, cada tipo a pie
## con su arma (TropaAnimada) y un cartel con el tipo y el arma, en una fila.
func _soldados() -> void:
	var civs: Array = str(args.get("civs", ",".join(CIVS))).split(",")
	var edad := int(args.get("edad", "3"))
	var acts: Dictionary = AldeanoAnimado.cfg().get("acciones", {})
	for civ: String in civs:
		_escena()
		var civd: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/civs/%s.json" % civ))
		var st: Dictionary = civd.get("estilo", {})
		var tropa: Dictionary = CivMeshes.age_cfg(civ, str(st.get("forma", "")), edad).get("tropa", {})
		var tipos := _tipos_a_pie(civd)
		var por_fila := tipos.size()
		for j in tipos.size():
			var av := AldeanoAnimado.crear(st, TEAM, 1.0, civ, tipos[j][0], tipos[j][1], tropa)
			var col := j % por_fila
			var fila := j / por_fila
			av.node.position = Vector3((col - (por_fila - 1) / 2.0) * 0.85, 0, -fila * 1.6)
			av.node.rotation.y = 0.45
			_w.add_child(av.node)
			AldeanoAnimado._propio(av)
			var act: String = av.golpe_act if args.get("accion", "quieto") == "golpe" else av.quieto_act
			var a: Dictionary = acts.get(act, {})
			av.ap.play("+".join(PackedStringArray(a.get("anims", [a.get("anim", "Idle_A")]))))
			av.ap.advance(0.5 * av.ap.current_animation_length)
			var eq: Dictionary = av.eq
			var arma := str(eq.get("arma", ""))
			if str(eq.get("escudo", "ninguno")) != "ninguno" and eq.has("escudo"):
				arma += " + escudo " + str(eq["escudo"])
			var l := Label3D.new()
			l.text = "%s\n%s" % [tipos[j][0], arma]
			l.font_size = 30
			l.pixel_size = 0.0021
			l.outline_size = 8
			l.position = av.node.position + Vector3(0, 0.02, 0.36)
			l.rotation = Vector3(-PI / 2.6, 0, 0)
			_w.add_child(l)
		var filas := ceili(float(tipos.size()) / por_fila)
		var ancho := por_fila * 0.85
		cam.fov = 30
		var d := ancho * 1.05 + 0.8
		cam.position = Vector3(0, 0.6 + d * 0.22, d)
		cam.look_at(Vector3(0, 0.3, 0.2), Vector3.UP)
		var img := await _img()
		var top := _px(Vector3(0, 1.25, -(filas - 1) * 1.6)).y
		var bot := _px(Vector3(0, 0, 1.4)).y
		var y0 := clampi(int(top) - 20, 0, img.get_height() - 10)
		var reg := img.get_region(Rect2i(0, y0, img.get_width(), clampi(int(bot) - y0 + 10, 10, img.get_height() - y0)))
		if reg.get_width() > 1500:
			reg.resize(1500, int(reg.get_height() * 1500.0 / reg.get_width()), Image.INTERPOLATE_LANCZOS)
		_guardar(reg, "soldados_%s" % civ)
	print("FIN")
	quit(0)


## Los tipos de soldado a pie de un pueblo (copia de tools/aldeanos_animados.gd).
func _tipos_a_pie(civ: Dictionary) -> Array:
	var base: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/unidades.json"))
	var out := []
	var all: Dictionary = {}
	for k in base:
		if base[k] is Dictionary:
			all[k] = (base[k] as Dictionary).duplicate()
	for src in [civ.get("unidades", {}), civ.get("unidades_nuevas", {})]:
		for k in src:
			var d: Dictionary = all.get(src[k].get("reemplaza", k), {}).duplicate()
			d.merge(src[k], true)
			all[k] = d
	for k in all:
		var fn := str(all[k].get("funcion", "civil"))
		if fn != "civil" and fn != "comercio" and AldeanoAnimado.usa(all[k], k):
			out.append([k, all[k]])
	return out


# ---------------------------------------------------------------- Prueba de Meshy (C-98 a)

## --modo=meshy --glb=<acciones.glb> [--caminar=<walking.glb>] [--correr=<running.glb>] [--nombre=aldeano]
## Hoja de clips (cuatro cuadros por clip, de costado) y una tropa a la distancia del juego, con
## la faja del equipo colgada de la cadera, junto a dos aldeanos KayKit de referencia.
func _clips() -> void:
	var glb: String = args["glb"]
	var nombre: String = args.get("nombre", "aldeano")
	var doc := GLTFDocument.new()
	var st := GLTFState.new()
	doc.append_from_file(glb, st)
	var tmp: Node = doc.generate_scene(st)
	var ap0: AnimationPlayer = tmp.find_children("*", "AnimationPlayer", true, false)[0]
	var clips: Array = [] # [ruta, clip]
	for extra in ["caminar", "correr"]:
		if args.has(extra):
			clips.append([args[extra], ""])
	for a in ap0.get_animation_list():
		clips.append([glb, a])
		print("clip %s %.2f s" % [a, ap0.get_animation(a).length])
	tmp.free()
	var filas: Array = []
	for c: Array in clips:
		_escena()
		var poses: Array = []
		for i in 4:
			var f := _meshy(c[0], c[1], [0.1, 0.35, 0.6, 0.85][i], true)
			var n: Node3D = f[0]
			n.position = Vector3((i - 1.5) * 0.75 + 0.4, 0, 0)
			n.rotation.y = 0.6
			_w.add_child(n)
			poses.append(f[1])
		var l := Label3D.new()
		l.text = (c[1] if c[1] != "" else str(c[0]).get_file().get_basename())
		l.font_size = 30
		l.pixel_size = 0.0016
		l.outline_size = 8
		l.position = Vector3(-1.55, 0.95, 0)
		_w.add_child(l)
		for p: Callable in poses:
			p.call()
		cam.fov = 20
		cam.position = Vector3(0, 0.9, 9.0)
		cam.look_at(Vector3(0, H * 0.5, 0), Vector3.UP)
		var img := await _img()
		var cc := _px(Vector3(0, H * 0.5, 0))
		filas.append(img.get_region(Rect2i(int(cc.x) - 620, int(cc.y) - 150, 1240, 300)))
	var out := Image.create(1240, 300 * filas.size(), false, filas[0].get_format())
	for i in filas.size():
		out.blit_rect(filas[i], Rect2i(0, 0, 1240, 300), Vector2i(0, 300 * i))
	_guardar(out, "meshy_%s_clips" % nombre)
	# Tropa a la distancia del juego: seis Meshy en clips distintos y dos KayKit.
	_escena()
	var yaw := deg_to_rad(RtsCamera.YAW_DEG)
	var fwd := Vector3(sin(yaw), 0, cos(yaw))
	var right := Vector3(-fwd.z, 0, fwd.x)
	var poses: Array = []
	var civ := str(args.get("civ", "tawantinsuyu"))
	for i in 8:
		var f: Array
		if i < 6:
			var c: Array = clips[i % clips.size()]
			f = _meshy(c[0], c[1], 0.3 + i * 0.07, true)
		else:
			f = _figura("kaykit", civ, 0.25)
		var n: Node3D = f[0]
		n.position = right * ((i % 4) - 1.5) * SEP - fwd * (i / 4) * SEP
		n.rotation.y = atan2(-fwd.x, -fwd.z) + 0.35
		_w.add_child(n)
		poses.append(f[1])
	for p: Callable in poses:
		p.call()
	var pitch := deg_to_rad(RtsCamera.PITCH_DEG)
	cam.fov = 30
	cam.position = -fwd * cos(pitch) * 28.0 + Vector3(0, sin(pitch) * 28.0, 0)
	cam.look_at(Vector3.ZERO, Vector3.UP)
	var img := await _img()
	var c := _px(Vector3(0, H * 0.5, 0) - fwd * 0.45)
	var zo := img.get_region(Rect2i(int(c.x) - 200, int(c.y) - 90, 400, 180))
	zo.resize(1200, 540, Image.INTERPOLATE_NEAREST)
	_guardar(zo, "meshy_%s_rts" % nombre)
	print("FIN")
	quit(0)


# ---------------------------------------------------------------- Retarget (copia de tools/visor_rig.gd)

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
