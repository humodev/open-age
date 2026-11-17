class_name AldeanoAnimado
extends RefCounted
## Aldeano animado con el esqueleto y las animaciones de KayKit Character Animations (CC0;
## proceso/27-animaciones). Solo imagen: lee la simulación y no decide nada (docs/06).
##
## El paquete trae un maniquí cabezón (proporciones de muñeco). Se usa su esqueleto con los
## huesos alargados o acortados a proporciones de persona (PROP) y, de cada animación, solo las
## rotaciones (más la altura de la cadera, escalada): así la misma animación sirve con otro largo
## de huesos, como el retargeting de Godot. El cuerpo es de maqueta, una pieza rígida por hueso,
## con la ropa y el tocado de cada pueblo (data/arte_animaciones.json → vestimenta).
##
## Para retargetear modelos de Meshy cuando estén riggeados: ver proceso/27-animaciones/README.md.

const O := SimEntity.Order

## Posición de cada hueso con el cuerpo de pie en T, en una persona de alto 1 (los pies en 0,
## la coronilla en 1), mirando a +z; .l es el lado +x. Los que no están (la raíz y los handslot,
## donde se cuelga la herramienta) guardan su distancia al padre de KayKit, por RESTO.
const PROP := {
	"hips": Vector3(0, 0.50, 0), "spine": Vector3(0, 0.60, 0), "chest": Vector3(0, 0.70, 0), "head": Vector3(0, 0.845, 0),
	"upperarm.l": Vector3(0.13, 0.815, 0), "lowerarm.l": Vector3(0.30, 0.815, -0.005), "wrist.l": Vector3(0.45, 0.815, 0),
	"hand.l": Vector3(0.48, 0.815, 0),
	"upperarm.r": Vector3(-0.13, 0.815, 0), "lowerarm.r": Vector3(-0.30, 0.815, -0.005), "wrist.r": Vector3(-0.45, 0.815, 0),
	"hand.r": Vector3(-0.48, 0.815, 0),
	"upperleg.l": Vector3(0.085, 0.50, 0), "lowerleg.l": Vector3(0.085, 0.275, 0.01), "foot.l": Vector3(0.085, 0.07, -0.005), "toes.l": Vector3(0.085, 0.005, 0.06),
	"upperleg.r": Vector3(-0.085, 0.50, 0), "lowerleg.r": Vector3(-0.085, 0.275, 0.01), "foot.r": Vector3(-0.085, 0.07, -0.005), "toes.r": Vector3(-0.085, 0.005, 0.06),
}
const RESTO := 0.45
const SIN_BUCLE := ["Death_A", "Hit_A", "PickUp", "Interact"]

static var _cfg := {}
static var _tpl := {}
static var _meshes := {}
static var _mat: StandardMaterial3D
static var us_actualizar := 0 # medición (tools/aldeanos_animados.gd --modo=fps)
static var us_avance := 0
static var n_play := 0
static var n_malla := 0
static var forzar := -1
static var max_por_cuadro := 80 # data/arte_animaciones.json → rendimiento
static var lejos_m := 46.0 # --animaciones=0|1 (main.gd): pisa data/arte_animaciones.json → activo


static func cfg() -> Dictionary:
	if _cfg.is_empty():
		var raw: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/arte_animaciones.json"))
		_cfg = raw if raw is Dictionary else {"activo": false}
		var r: Dictionary = _cfg.get("rendimiento", {})
		max_por_cuadro = maxi(1, int(r.get("max_por_cuadro", 80)))
		lejos_m = float(r.get("lejos_m", 46))
	return _cfg


## Si esta unidad se dibuja animada.
static func usa(def: Dictionary) -> bool:
	var on: bool = cfg().get("activo", false) if forzar < 0 else forzar == 1
	if not on or def.get("funcion", "") != "civil" or def.get("animal", false) or def.get("montado", false):
		return false
	return not _template().is_empty()


# ---------------------------------------------------------------- Esqueleto y animaciones

## Esqueleto con las proporciones de PROP, la biblioteca de animaciones (solo rotaciones) y la
## velocidad del paso. Se arma una vez.
static func _template() -> Dictionary:
	if _tpl.has("_falla"):
		return {}
	if not _tpl.is_empty():
		return _tpl
	var path: String = cfg().get("archivo", "")
	if not ResourceLoader.exists(path):
		push_warning("AldeanoAnimado: falta %s; se usa la figura de antes" % path)
		_tpl = {"_falla": true}
		return {}
	var src: Node = (load(path) as PackedScene).instantiate()
	var sk0: Skeleton3D = src.find_child("Skeleton3D", true, false)
	var ap0: AnimationPlayer = src.find_child("AnimationPlayer", true, false)
	var sk := Skeleton3D.new()
	sk.name = "Skeleton3D"
	var n := sk0.get_bone_count()
	var pos: Array[Vector3] = []
	for i in n:
		sk.add_bone(sk0.get_bone_name(i))
		var bn := sk0.get_bone_name(i)
		var par := sk0.get_bone_parent(i)
		if PROP.has(bn):
			pos.append(PROP[bn])
		elif par >= 0:
			pos.append(pos[par] + (sk0.get_bone_global_rest(i).origin - sk0.get_bone_global_rest(par).origin) * RESTO)
		else:
			pos.append(sk0.get_bone_global_rest(i).origin)
	for i in n:
		var par := sk0.get_bone_parent(i)
		sk.set_bone_parent(i, par)
		var rest := sk0.get_bone_rest(i)
		if par >= 0:
			rest.origin = sk0.get_bone_global_rest(par).basis.inverse() * (pos[i] - pos[par])
		else:
			rest.origin = pos[i]
		sk.set_bone_rest(i, rest)
	sk.reset_bone_poses()
	var hips := sk0.find_bone("hips")
	var hips_k: float = PROP["hips"].y / maxf(0.001, sk0.get_bone_global_rest(hips).origin.y)
	var lib := AnimationLibrary.new()
	for an in ap0.get_animation_list():
		if an == "RESET":
			continue
		var a: Animation = ap0.get_animation(an).duplicate(true)
		for t in range(a.get_track_count() - 1, -1, -1):
			var np := a.track_get_path(t)
			var bone := String(np.get_concatenated_subnames())
			var ty := a.track_get_type(t)
			if ty == Animation.TYPE_ROTATION_3D:
				a.track_set_path(t, NodePath("Skeleton3D:" + bone))
			elif ty == Animation.TYPE_POSITION_3D and bone == "hips":
				a.track_set_path(t, NodePath("Skeleton3D:" + bone))
				for k in a.track_get_key_count(t):
					a.track_set_key_value(t, k, (a.track_get_key_value(t, k) as Vector3) * hips_k)
			else:
				a.remove_track(t) # largos de hueso y escalas: quedan los del esqueleto nuevo
		_cerrar(a, an)
		a.loop_mode = Animation.LOOP_NONE if an in SIN_BUCLE else Animation.LOOP_LINEAR
		lib.add_animation(an, a)
	src.free()
	var skin := sk.create_skin_from_rest_transforms()
	_tpl = {"sk": sk, "lib": lib, "skin": skin}
	_tpl["paso"] = _paso(sk, lib, cfg().get("acciones", {}).get("caminar", {}).get("anim", "Walking_A"))
	_tpl["paso_correr"] = _paso(sk, lib, cfg().get("acciones", {}).get("correr", {}).get("anim", "Running_A"))
	return _tpl


## El maniquí de KayKit abre piernas y brazos para esquivar su cuerpo ancho; con proporciones de
## persona eso se ve como un paso de vaquero. Se cierra el ángulo hacia afuera de las piernas
## (en todas) y de los brazos que cuelgan (quieto, caminar y correr), alrededor del eje que mira
## adelante del padre: el resto del movimiento queda igual.
const CERRAR_PIERNAS := 0.45
const CERRAR_BRAZOS := 0.5
const BRAZOS_SUELTOS := ["Idle_A", "Walking_A", "Running_A"]


static func _cerrar(a: Animation, an: String) -> void:
	for t in a.get_track_count():
		if a.track_get_type(t) != Animation.TYPE_ROTATION_3D:
			continue
		var bone := String(a.track_get_path(t).get_concatenated_subnames())
		var k := 1.0
		if bone.begins_with("upperleg."):
			k = CERRAR_PIERNAS
		elif bone.begins_with("upperarm.") and an in BRAZOS_SUELTOS:
			k = CERRAR_BRAZOS
		else:
			continue
		for i in a.track_get_key_count(t):
			var q: Quaternion = a.track_get_key_value(t, i)
			var d := q * Vector3.UP # hacia dónde apunta el hueso, en el espacio del padre
			if d.y > (0.25 if k == CERRAR_BRAZOS else -0.2):
				continue # brazo levantado o pierna muy alzada: se deja
			var phi := atan2(d.x, -d.y)
			a.track_set_key_value(t, i, Quaternion(Vector3.BACK, (k - 1.0) * phi) * q)


## Velocidad del cuerpo que pide la animación de caminar (alto 1 por segundo), medida en el pie
## de apoyo: mientras está en el suelo, se corre hacia atrás a la velocidad a la que avanza el
## cuerpo. Con eso el paso sigue a la distancia recorrida y no patina. También devuelve los
## pasos por ciclo (2) para pasar a trote.
static func _paso(sk: Skeleton3D, lib: AnimationLibrary, an: String) -> Dictionary:
	if not lib.has_animation(an):
		return {"v": 1.0, "largo": 1.0}
	var a := lib.get_animation(an)
	var chain: Array[int] = []
	var b := sk.find_bone("foot.l")
	while b >= 0:
		chain.push_front(b)
		b = sk.get_bone_parent(b)
	var samples := 48
	var ys: Array[float] = []
	var zs: Array[float] = []
	for s in samples:
		var t := a.length * float(s) / float(samples)
		var g := Transform3D.IDENTITY
		for bone in chain:
			var rest := sk.get_bone_rest(bone)
			var q := rest.basis.get_rotation_quaternion()
			var o := rest.origin
			var name := sk.get_bone_name(bone)
			var tr := a.find_track(NodePath("Skeleton3D:" + name), Animation.TYPE_ROTATION_3D)
			if tr >= 0:
				q = a.rotation_track_interpolate(tr, t)
			var tp := a.find_track(NodePath("Skeleton3D:" + name), Animation.TYPE_POSITION_3D)
			if tp >= 0:
				o = a.position_track_interpolate(tp, t)
			g = g * Transform3D(Basis(q), o)
		ys.append(g.origin.y)
		zs.append(g.origin.z)
	var ymin: float = ys.min()
	var vel := 0.0
	var cnt := 0
	for s in samples:
		var s2 := (s + 1) % samples
		if ys[s] < ymin + 0.02 and ys[s2] < ymin + 0.02:
			vel += (zs[s] - zs[s2]) / (a.length / samples)
			cnt += 1
	var v := vel / cnt if cnt > 0 else 1.0
	return {"v": maxf(0.1, v), "largo": a.length}


# ---------------------------------------------------------------- Cuerpo

static func _material() -> StandardMaterial3D:
	if _mat == null:
		_mat = StandardMaterial3D.new()
		_mat.vertex_color_use_as_albedo = true
		_mat.roughness = 0.9
		_mat.metallic_specular = 0.25
	return _mat


## Malla con piel (una pieza rígida por hueso) del aldeano de un pueblo, con su herramienta y,
## si lleva carga, el atado a la espalda del color del recurso.
static func malla(style: Dictionary, team: Color, tool: String, carga: Color) -> ArrayMesh:
	var forma: String = style.get("forma", "")
	var key := "%s_%s_%s_%s_%s" % [forma, style.get("arcilla", ""), team.to_html(), tool, carga.to_html()]
	if _meshes.has(key):
		return _meshes[key]
	var tp := _template()
	var sk: Skeleton3D = tp["sk"]
	var cols: Dictionary = cfg().get("colores", {})
	var vest_all: Dictionary = cfg().get("vestimenta", {})
	var vest: Dictionary = vest_all.get(forma, vest_all.get("_otro", {}))
	var piel := Color(vest.get("piel", cols.get("piel", "#c99c76")))
	var pelo := Color(vest.get("pelo", cols.get("pelo", "#2a221c")))
	var tela := Color(vest["tela"]) if vest.has("tela") else Color(style.get("arcilla", "#eee7da")).lightened(0.2)
	var wood := Color(cols.get("madera", "#7a5a3a"))
	var stone := Color(cols.get("piedra", "#6c6a66"))
	var fibra := Color(cols.get("fibra", "#b99a5a"))
	var cuero := Color(cols.get("cuero", "#5a4030"))
	var parts: Array = [] # [malla, transform en el modelo, color, hueso]
	var P := func(bone: String) -> Vector3: return sk.get_bone_global_rest(sk.find_bone(bone)).origin
	var B := func(bone: String) -> int: return sk.find_bone(bone)
	# Cabeza, cuello y pelo.
	var head: Vector3 = P.call("head")
	parts.append([_sphere(0.068), Transform3D(Basis.from_scale(Vector3(0.92, 1.0, 0.98)), head + Vector3(0, 0.078, 0.005)), piel, B.call("head")])
	parts.append([_sphere(0.071), Transform3D(Basis.from_scale(Vector3(1.0, 0.72, 1.0)), head + Vector3(0, 0.105, -0.012)), pelo, B.call("head")])
	parts.append([_cyl(0.03, 0.033, 0.06), Transform3D(Basis.IDENTITY, head + Vector3(0, 0.0, 0)), piel, B.call("head")])
	# Tronco: pecho, vientre y cadera, de la tela del pueblo; faja del color del equipo.
	parts.append([_cyl(0.112, 0.095, 0.14), Transform3D(Basis.from_scale(Vector3(1, 1, 0.62)), P.call("chest") + Vector3(0, 0.07, 0)), tela, B.call("chest")])
	parts.append([_cyl(0.095, 0.088, 0.12), Transform3D(Basis.from_scale(Vector3(1, 1, 0.66)), P.call("spine") + Vector3(0, 0.04, 0)), tela, B.call("spine")])
	parts.append([_cyl(0.092, 0.1, 0.12), Transform3D(Basis.from_scale(Vector3(1, 1, 0.7)), P.call("hips") + Vector3(0, 0.02, 0)), tela, B.call("hips")])
	parts.append([_cyl(0.103, 0.103, 0.035), Transform3D(Basis.from_scale(Vector3(1, 1, 0.74)), P.call("hips") + Vector3(0, 0.08, 0)), team, B.call("hips")])
	# Piernas y pies.
	for s in ["l", "r"]:
		parts.append(_seg(P.call("upperleg." + s), P.call("lowerleg." + s), 0.05, 0.04, piel, B.call("upperleg." + s)))
		parts.append(_seg(P.call("lowerleg." + s), P.call("foot." + s), 0.038, 0.028, piel, B.call("lowerleg." + s)))
		var f: Vector3 = P.call("foot." + s)
		parts.append([_box(Vector3(0.055, 0.035, 0.115)), Transform3D(Basis.IDENTITY, Vector3(f.x, 0.018, f.z + 0.03)), cuero, B.call("foot." + s)])
		# Brazos y manos.
		parts.append(_seg(P.call("upperarm." + s), P.call("lowerarm." + s), 0.036, 0.03, piel, B.call("upperarm." + s)))
		parts.append(_seg(P.call("lowerarm." + s), P.call("wrist." + s), 0.029, 0.024, piel, B.call("lowerarm." + s)))
		parts.append([_sphere(0.03), Transform3D(Basis.from_scale(Vector3(1.0, 0.8, 1.0)), P.call("hand." + s)), piel, B.call("hand." + s)])
	_prenda(parts, str(vest.get("prenda", "ninguna")), Color(vest.get("prenda_color", tela.to_html())), tela, P, B)
	_tocado(parts, str(vest.get("tocado", "ninguno")), Color(vest.get("tocado_color", "#a63a2a")), head, B.call("head"))
	_herramienta(parts, tool, sk, wood, stone, fibra)
	if carga.a > 0.0:
		var ch: Vector3 = P.call("chest")
		parts.append([_box(Vector3(0.15, 0.13, 0.1)), Transform3D(Basis.IDENTITY, ch + Vector3(0, 0.08, -0.11)), carga, B.call("chest")])
		parts.append([_box(Vector3(0.012, 0.15, 0.13)), Transform3D(Basis.IDENTITY, ch + Vector3(0.06, 0.07, -0.05)), cuero, B.call("chest")])
	var mesh := _skinned(parts)
	_meshes[key] = mesh
	return mesh


static func _prenda(parts: Array, kind: String, col: Color, tela: Color, P: Callable, B: Callable) -> void:
	var hips: Vector3 = P.call("hips")
	var chest: Vector3 = P.call("chest")
	match kind:
		"unku": # túnica hasta la rodilla con la franja de tocapus
			parts.append([_cyl(0.1, 0.135, 0.17), Transform3D(Basis.from_scale(Vector3(1, 1, 0.75)), hips + Vector3(0, -0.07, 0)), tela, B.call("hips")])
			parts.append([_box(Vector3(0.14, 0.035, 0.012)), Transform3D(Basis.IDENTITY, chest + Vector3(0, 0.02, 0.066)), col, B.call("chest")])
		"poncho":
			parts.append([_cyl(0.06, 0.17, 0.2, 10), Transform3D(Basis.from_scale(Vector3(1, 1, 0.68)), chest + Vector3(0, 0.05, 0)), col, B.call("chest")])
			parts.append([_cyl(0.095, 0.12, 0.13), Transform3D(Basis.from_scale(Vector3(1, 1, 0.75)), hips + Vector3(0, -0.05, 0)), tela, B.call("hips")])
		"tipoy": # túnica larga sin mangas
			parts.append([_cyl(0.1, 0.14, 0.22), Transform3D(Basis.from_scale(Vector3(1, 1, 0.75)), hips + Vector3(0, -0.09, 0)), col, B.call("hips")])
		"shamma": # manto blanco cruzado sobre un hombro
			parts.append([_box(Vector3(0.23, 0.17, 0.135)), Transform3D(Basis(Vector3(0, 0, 1), deg_to_rad(14)), chest + Vector3(0.0, 0.06, 0)), col, B.call("chest")])
			parts.append([_cyl(0.1, 0.14, 0.22), Transform3D(Basis.from_scale(Vector3(1, 1, 0.75)), hips + Vector3(0, -0.09, 0)), col, B.call("hips")])
		"pano": # paño atado a la cintura
			parts.append([_cyl(0.1, 0.125, 0.14), Transform3D(Basis.from_scale(Vector3(1, 1, 0.75)), hips + Vector3(0, -0.06, 0)), col, B.call("hips")])
		_:
			parts.append([_cyl(0.096, 0.112, 0.09), Transform3D(Basis.from_scale(Vector3(1, 1, 0.74)), hips + Vector3(0, -0.04, 0)), tela, B.call("hips")])


static func _tocado(parts: Array, kind: String, col: Color, head: Vector3, bone: int) -> void:
	match kind:
		"vincha":
			parts.append([_cyl(0.07, 0.07, 0.022, 12), Transform3D(Basis.from_scale(Vector3(0.95, 1, 1.0)), head + Vector3(0, 0.1, 0.0)), col, bone])
		"plumas":
			parts.append([_cyl(0.07, 0.07, 0.02, 12), Transform3D(Basis.IDENTITY, head + Vector3(0, 0.1, 0)), Color("f2c94a"), bone])
			for i in 7:
				var a := -0.9 + i * 0.3
				var b := Basis(Vector3.UP, a) * Basis(Vector3.RIGHT, deg_to_rad(-18))
				parts.append([_cyl(0.0, 0.016, 0.12, 4), Transform3D(b, head + Vector3(sin(a) * 0.06, 0.16, -cos(a) * 0.045)), col if i % 2 == 0 else Color("f2c94a"), bone])
		"turbante":
			parts.append([_cyl(0.078, 0.072, 0.06, 12), Transform3D(Basis.IDENTITY, head + Vector3(0, 0.12, -0.005)), col, bone])


## Herramienta en la mano derecha (hueso handslot.r): el mango sale del puño hacia adelante y
## arriba, como lo esperan las animaciones de KayKit.
static func _herramienta(parts: Array, tool: String, sk: Skeleton3D, wood: Color, stone: Color, fibra: Color) -> void:
	if tool == "" or tool == "ninguna":
		return
	var slot := sk.find_bone("handslot.r")
	var g := sk.get_bone_global_rest(slot)
	var X := func(pos: Vector3, b := Basis.IDENTITY) -> Transform3D: return g * Transform3D(b, pos)
	# Como las armas de KayKit Adventurers: el mango por el +y del hueso, desde el puño, y la
	# hoja hacia +x.
	match tool:
		"hacha":
			parts.append([_cyl(0.011, 0.012, 0.38), X.call(Vector3(0, 0.1, 0)), wood, slot])
			parts.append([_box(Vector3(0.08, 0.075, 0.016)), X.call(Vector3(0.035, 0.25, 0)), stone, slot])
		"pico":
			parts.append([_cyl(0.011, 0.012, 0.4), X.call(Vector3(0, 0.1, 0)), wood, slot])
			parts.append([_cyl(0.006, 0.016, 0.28, 6), X.call(Vector3(0.0, 0.28, 0), Basis(Vector3.BACK, PI / 2)), stone, slot])
		"martillo":
			parts.append([_cyl(0.01, 0.011, 0.26), X.call(Vector3(0, 0.07, 0)), wood, slot])
			parts.append([_box(Vector3(0.1, 0.045, 0.045)), X.call(Vector3(0.0, 0.19, 0)), stone, slot])
		"azada":
			parts.append([_cyl(0.011, 0.012, 0.6), X.call(Vector3(0, 0.16, 0)), wood, slot])
			parts.append([_box(Vector3(0.09, 0.014, 0.075)), X.call(Vector3(0.04, 0.45, 0)), stone, slot])
		"cuchillo":
			parts.append([_box(Vector3(0.022, 0.13, 0.01)), X.call(Vector3(0, 0.08, 0)), stone, slot])
		"ejes": # para revisar a mano la orientación del hueso de la mano (x rojo, y verde, z azul)
			parts.append([_box(Vector3(0.3, 0.012, 0.012)), X.call(Vector3(0.15, 0, 0)), Color.RED, slot])
			parts.append([_box(Vector3(0.012, 0.3, 0.012)), X.call(Vector3(0, 0.15, 0)), Color.GREEN, slot])
			parts.append([_box(Vector3(0.012, 0.012, 0.3)), X.call(Vector3(0, 0, 0.15)), Color.BLUE, slot])
		"canasta": # cesto colgado de la cadera, del lado izquierdo
			var hips := sk.find_bone("hips")
			var hp := sk.get_bone_global_rest(hips).origin
			parts.append([_cyl(0.06, 0.045, 0.08, 10), Transform3D(Basis.IDENTITY, hp + Vector3(0.13, -0.04, 0.02)), fibra, hips])
			parts.append([_cyl(0.062, 0.062, 0.012, 10), Transform3D(Basis.IDENTITY, hp + Vector3(0.13, 0.0, 0.02)), wood, hips])


static func _sphere(r: float) -> SphereMesh:
	var m := SphereMesh.new()
	m.radius = r
	m.height = r * 2.0
	m.radial_segments = 8
	m.rings = 5
	return m


static func _cyl(rt: float, rb: float, h: float, seg := 8) -> CylinderMesh:
	var m := CylinderMesh.new()
	m.top_radius = rt
	m.bottom_radius = rb
	m.height = h
	m.radial_segments = seg
	m.rings = 1
	return m


static func _box(s: Vector3) -> BoxMesh:
	var m := BoxMesh.new()
	m.size = s
	return m


## Cilindro de `a` a `b` (radios ra en a y rb en b) pegado al hueso `bone`.
static func _seg(a: Vector3, b: Vector3, ra: float, rb: float, col: Color, bone: int) -> Array:
	var d := b - a
	var y := d.normalized()
	var x := y.cross(Vector3.FORWARD if absf(y.dot(Vector3.FORWARD)) < 0.9 else Vector3.RIGHT).normalized()
	var z := x.cross(y)
	# El +y del cilindro apunta de `a` a `b`: el radio de arriba es el de `b`.
	return [_cyl(rb, ra, d.length() + ra * 0.6), Transform3D(Basis(x, y, z), (a + b) * 0.5), col, bone]


## Junta las piezas en una superficie con piel rígida (cada vértice, 100 % de su hueso).
static func _skinned(parts: Array) -> ArrayMesh:
	var verts := PackedVector3Array()
	var norms := PackedVector3Array()
	var colors := PackedColorArray()
	var bones := PackedInt32Array()
	var weights := PackedFloat32Array()
	var idx := PackedInt32Array()
	for p in parts:
		var arr: Array = (p[0] as PrimitiveMesh).get_mesh_arrays()
		var xf: Transform3D = p[1]
		var c: Color = p[2]
		var bone: int = p[3]
		var base := verts.size()
		var pv: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
		var pn: PackedVector3Array = arr[Mesh.ARRAY_NORMAL]
		var nb := xf.basis.inverse().transposed()
		for i in pv.size():
			verts.append(xf * pv[i])
			norms.append((nb * pn[i]).normalized())
			colors.append(c)
			bones.append_array([bone, 0, 0, 0])
			weights.append_array([1.0, 0.0, 0.0, 0.0])
		for i: int in arr[Mesh.ARRAY_INDEX]:
			idx.append(base + i)
	var a := []
	a.resize(Mesh.ARRAY_MAX)
	a[Mesh.ARRAY_VERTEX] = verts
	a[Mesh.ARRAY_NORMAL] = norms
	a[Mesh.ARRAY_COLOR] = colors
	a[Mesh.ARRAY_BONES] = bones
	a[Mesh.ARRAY_WEIGHTS] = weights
	a[Mesh.ARRAY_INDEX] = idx
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, a)
	mesh.surface_set_material(0, _material())
	return mesh


# ---------------------------------------------------------------- Instancia

## Estado de un aldeano animado (uno por unidad; WorldView lo guarda en visual["anim"]).
class Estado:
	extends RefCounted
	var node: Node3D
	var sk: Skeleton3D
	var mi: MeshInstance3D
	var ap: AnimationPlayer
	var k := 1.0 # alto en el mundo
	var style: Dictionary
	var team: Color
	var accion := ""
	var tool := "-"
	var carga := Color(0, 0, 0, 0)
	var acc_t := 0.0 # tiempo de animación pendiente (se aplica cuando le toca actualizarse)
	var walk_acc := 0.0 # distancia y tiempo juntados entre turnos (WorldView._render_anim)
	var dt_acc := 0.0
	var golpe := false
	var pend := ""
	var pend_t := 0.0
	var sps := 0.0 # pasos por segundo, suavizados
	var work_order := -1 # orden y blanco de los que salió la herramienta guardada
	var work_target := -2
	var work_tool := ""


## Lo de data/arte_animaciones.json que se mira en cada cuadro, leído una vez.
static var _anim_of := {} # acción -> nombre de la animación
static var _tool_of := {} # acción -> herramienta
static var _vel_of := {} # acción -> factor de velocidad
static var _por_recurso := {}
static var _por_clase := {}
static var _mezcla := 0.18
static var _cambio := 0.2
static var _correr := 99.0
static var _len := {} # animación -> largo


static func _prep() -> void:
	if not _anim_of.is_empty():
		return
	var c := cfg()
	for act: String in c.get("acciones", {}):
		var a: Dictionary = c["acciones"][act]
		_anim_of[act] = str(a.get("anim", "Idle_A"))
		_tool_of[act] = str(a.get("herramienta", ""))
		_vel_of[act] = float(a.get("vel_pct", 100)) / 100.0
	_tool_of[""] = ""
	_por_recurso = c.get("por_recurso", {})
	_por_clase = c.get("por_clase", {})
	_mezcla = float(c.get("mezcla_s", 0.18))
	_cambio = float(c.get("cambio_s", 0.2))
	_correr = float(c.get("correr_desde_pasos", 99.0))
	var lib: AnimationLibrary = _template()["lib"]
	for an in lib.get_animation_list():
		_len[String(an)] = lib.get_animation(an).length


## Cuerpo animado de un aldeano: raíz con el esqueleto, la malla y el reproductor. `k`: alto en
## el mundo.
static func crear(style: Dictionary, team: Color, k: float) -> Estado:
	var tp := _template()
	_prep()
	var st := Estado.new()
	st.node = Node3D.new()
	st.node.name = "AldeanoAnimado"
	st.sk = (tp["sk"] as Skeleton3D).duplicate()
	st.node.add_child(st.sk)
	st.mi = MeshInstance3D.new()
	st.mi.mesh = malla(style, team, "", Color(0, 0, 0, 0))
	st.mi.skin = tp["skin"]
	st.sk.add_child(st.mi)
	st.mi.skeleton = NodePath("..")
	st.ap = AnimationPlayer.new()
	st.node.add_child(st.ap)
	st.ap.root_node = NodePath("..")
	st.ap.add_animation_library("", tp["lib"])
	st.ap.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
	st.k = k
	st.style = style
	st.team = team
	st.acc_t = randf() * 2.0 # cada uno en otro momento del ciclo
	return st


## Qué hace el aldeano ahora (solo lectura de la simulación).
static func accion(e: SimEntity, sim: Sim, moving: bool) -> String:
	if moving:
		return "caminar"
	if e.order == O.ATTACK:
		return "pegar"
	if e.anchored and e.order == O.BUILD:
		return "construir"
	if e.anchored and e.order == O.GATHER:
		return _trabajo(e, sim)
	return "quieto"


## El trabajo de una recolección: por el tipo de recurso, o por su clase; un edificio (granja,
## corral) es cosechar.
static func _trabajo(e: SimEntity, sim: Sim) -> String:
	var t: SimEntity = sim.by_id.get(e.target)
	if t != null and t.is_building():
		return "cosechar"
	if t != null and _por_recurso.has(t.type):
		return _por_recurso[t.type]
	return _por_clase.get(e.gather_kind, "juntar")


## Avanza la animación de un aldeano cuando le toca (presupuesto de rendimiento, WorldView).
## `walked`: distancia recorrida desde la última vez (mundo); `dt`: tiempo de juego desde la
## última vez (real × velocidad del juego; 0 en pausa); `golpe`: pegó en el medio.
static func actualizar(st: Estado, e: SimEntity, sim: Sim, moving: bool, walked: float, dt: float, golpe: bool) -> void:
	var act := accion(e, sim, moving)
	# Herramienta: la del trabajo; caminando o quieto, la del trabajo al que va o del que vuelve.
	var tool: String = _tool_of.get(act, "")
	if act == "caminar" or act == "quieto":
		if e.order != st.work_order or e.target != st.work_target:
			st.work_order = e.order
			st.work_target = e.target
			var work := ""
			if e.order == O.GATHER or e.order == O.RETURN:
				work = _trabajo(e, sim)
			elif e.order == O.BUILD:
				work = "construir"
			st.work_tool = _tool_of.get(work, "")
		tool = st.work_tool
	var carga := Color(0, 0, 0, 0)
	if e.carry > 0:
		carga = Palette.RES.get(e.carry_res, Color.WHITE)
	if tool != st.tool or carga != st.carga:
		st.tool = tool
		st.carga = carga
		st.mi.mesh = malla(st.style, st.team, tool, carga)
		n_malla += 1
	# Histéresis: en un montón los aldeanos se empujan y el "se mueve / está quieto" titila de un
	# tick a otro; el estado nuevo tiene que durar cambio_s antes de cambiar de animación.
	var cur := st.accion
	var base := "caminar" if cur == "correr" else cur
	if act != base and cur != "" and not (golpe and act == "pegar"):
		if act == st.pend:
			st.pend_t += dt
		else:
			st.pend = act
			st.pend_t = 0.0
		if st.pend_t < _cambio:
			act = base
		else:
			st.pend = ""
	var anim_dt := dt
	if act == "caminar":
		# El paso sigue a la distancia: tiempo de animación = distancia / velocidad de la animación.
		var tp := _tpl
		var paso: Dictionary = tp["paso"]
		var v: float = float(paso["v"]) * st.k
		if dt > 0.0:
			# Pasos por segundo (dos por ciclo), suavizados; trote por encima del umbral, con margen.
			var sps := (walked / dt) / v * 2.0 / float(paso["largo"])
			st.sps = lerpf(st.sps, sps, clampf(dt * 4.0, 0.0, 1.0))
		if st.sps > (_correr * 0.85 if cur == "correr" else _correr) and _anim_of.has("correr"):
			act = "correr"
			paso = tp["paso_correr"]
			v = float(paso["v"]) * st.k
		anim_dt = walked / v
	elif act == "pegar":
		var cad := float(e.def.get("cadencia_ms", 1000)) / 1000.0
		anim_dt = dt * float(_len.get(_anim_of.get("pegar", ""), 1.0)) / maxf(0.2, cad)
	else:
		anim_dt = dt * float(_vel_of.get(act, 1.0))
	if act != cur or (golpe and act == "pegar"):
		st.accion = act
		var name: String = _anim_of.get(act, "Idle_A")
		if _len.has(name):
			if golpe and act == "pegar" and st.ap.current_animation == name:
				st.ap.seek(0.0, false)
			else:
				st.ap.play(name, _mezcla if cur != "" else 0.0)
				n_play += 1
	st.acc_t += anim_dt
	var t0 := Time.get_ticks_usec()
	st.ap.advance(st.acc_t)
	us_avance += Time.get_ticks_usec() - t0
	st.acc_t = 0.0


## Muerte: la animación de caer, que sigue avanzando desde los efectos (WorldView._render_fx).
static func morir(st: Estado) -> void:
	var an: String = _anim_of.get("morir", "Death_A")
	if _len.has(an):
		st.ap.play(an, 0.08)
