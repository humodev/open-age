class_name CuadrupedoAnimado
extends RefCounted
## Caballos, elefantes y animales animados (proceso/63-montados-y-animales). Solo imagen: lee la
## simulación y no decide nada (docs/06).
##
## Cada modelo (data/arte_cuadrupedos.json → modelos, o la silueta riggeada de una especie) es un
## GLB con su esqueleto y siete clips hechos en Blender (tools/gen3d_rig_cuadrupedo.py): quieto,
## pastar, caminar, galope, ataque, golpeado y morir. La escena importada se carga una vez y sus
## animaciones (la AnimationLibrary) las comparten todas las instancias del mismo modelo; cada
## animal tiene su esqueleto y su reproductor, que se avanza a mano (fuera de la pantalla, no).
##
## El paso sigue a la distancia recorrida, como la gente: se mide en el clip a qué velocidad va
## para atrás el casco apoyado y el tiempo de animación es distancia / esa velocidad, con topes
## (juego.vel_min_pct y vel_max_pct del tipo). Más rápido que galope_desde, galope.
##
## Jinetes: una figura de AldeanoAnimado (crear_jinete) colgada del hueso «silla» del animal, con
## las animaciones sentadas («@m»); el mahout del elefante, del hueso «cuello_asiento». El jinete
## pega con el ritmo de la simulación; el animal hace su ataque cada juego.ataque_cada golpes.
## La manta (material «equipo» del GLB) toma el color del equipo.

const O := SimEntity.Order
const CLIPS := ["quieto", "pastar", "caminar", "galope", "ataque", "golpeado", "morir"]
const SIN_BUCLE := ["ataque", "golpeado", "morir"]

static var _cfg := {}
static var _mods := {} # clave del modelo -> {ps, h0, paso, len, tipo, silla, cuello}
static var _mats := {} # color -> material de la manta
static var forzar := -1 # --montados=0|1 (main.gd)
static var lejos_m := 46.0
static var max_por_cuadro := 40 # montados.rendimiento.max_por_cuadro
static var us_actualizar := 0


static func cfg() -> Dictionary:
	if _cfg.is_empty():
		var raw: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/arte_cuadrupedos.json"))
		_cfg = raw if raw is Dictionary else {"tipos": {}}
		lejos_m = float(montados().get("rendimiento", {}).get("lejos_m", 46))
		max_por_cuadro = maxi(1, int(montados().get("rendimiento", {}).get("max_por_cuadro", 40)))
	return _cfg


static func montados() -> Dictionary:
	return AldeanoAnimado.cfg().get("montados", {})


static func _on() -> bool:
	return bool(montados().get("activo", false)) if forzar < 0 else forzar == 1


## La línea de data/arte_animaciones.json → montados.unidades de una unidad («civ:tipo» o «tipo»),
## o {} si se dibuja como antes.
static func montado_de(civ: String, type: String, def: Dictionary) -> Dictionary:
	if not _on() or not (def.get("montado", false) == true or def.get("elefante", false)):
		return {}
	var u: Dictionary = montados().get("unidades", {})
	var m: Dictionary = u.get(civ + ":" + type, u.get(type, {}))
	if m.is_empty() or _modelo(str(m.get("montura", ""))).is_empty():
		return {}
	return m


## El modelo de una especie de animal (rebaño o caza), o {} (la silueta fija de antes).
static func especie(sp: String) -> Dictionary:
	if not _on() or not bool(montados().get("animales", {}).get("activo", false)):
		return {}
	var es: Dictionary = cfg().get("especies", {})
	if not bool(es.get("activo", true)):
		return {}
	var e: Dictionary = es.get(sp, {})
	if e.has("modelo"):
		return _modelo(str(e["modelo"]))
	var forma := str(Animales.data().get("especies", {}).get(sp, {}).get("forma", "camelido"))
	var tipo := str(cfg().get("forma_tipo", {}).get(forma, "buey"))
	return _modelo("animal:" + sp, "res://assets/generados/modelos/animales/%s.glb" % sp, tipo)


## Carga un modelo (una vez): la escena, su alto, el paso de caminar y galope medido en los clips,
## y el lugar de la silla.
static func _modelo(id: String, glb := "", tipo := "") -> Dictionary:
	if _mods.has(id):
		return _mods[id]
	var d: Dictionary = cfg().get("modelos", {}).get(id, {})
	if glb == "":
		glb = str(d.get("glb", ""))
		tipo = str(d.get("tipo", "caballo"))
	if glb == "" or not ResourceLoader.exists(glb):
		_mods[id] = {}
		return {}
	var ps: PackedScene = load(glb)
	var inst: Node = ps.instantiate()
	var lsk := inst.find_children("*", "Skeleton3D", true, false)
	var lap := inst.find_children("*", "AnimationPlayer", true, false)
	var sk: Skeleton3D = lsk[0] if not lsk.is_empty() else null
	var ap: AnimationPlayer = lap[0] if not lap.is_empty() else null
	if sk == null or ap == null:
		inst.free()
		_mods[id] = {}
		return {}
	var h0 := 0.0
	for mi: MeshInstance3D in inst.find_children("*", "MeshInstance3D", true, false):
		if mi.mesh != null:
			h0 = maxf(h0, mi.mesh.get_aabb().end.y)
	var md := {"ps": ps, "h0": maxf(0.01, h0), "tipo": cfg().get("tipos", {}).get(tipo, {}), "len": {}, "paso": {},
		"alto_persona": float(d.get("alto_persona", 1.0)), "tinte": Color(str(d.get("tinte", "#ffffff")))}
	for an in CLIPS:
		if ap.has_animation(an):
			var a := ap.get_animation(an)
			a.loop_mode = Animation.LOOP_NONE if an in SIN_BUCLE else Animation.LOOP_LINEAR
			md["len"][an] = a.length
	var root_path := ap.get_node(ap.root_node).get_path_to(sk)
	for an in ["caminar", "galope"]:
		if ap.has_animation(an):
			md["paso"][an] = paso(sk, ap.get_animation(an), root_path)
	for b in ["silla", "cuello_asiento"]:
		var bi := sk.find_bone(b)
		if bi >= 0:
			md[b] = sk.get_bone_global_rest(bi)
	inst.free()
	_mods[id] = md
	return md


## Velocidad del cuerpo que pide un clip de andar (unidades del modelo por segundo, hacia +x,
## que es adonde mira el animal en el GLB), medida en los menudillos: la pata apoyada es la que
## va hacia atrás, y lo hace a la velocidad a la que avanza el cuerpo (recorrido hacia atrás /
## tiempo yendo hacia atrás, de las cuatro patas juntas).
static func paso(sk: Skeleton3D, a: Animation, root_path: NodePath) -> float:
	var n := 48
	var suma := 0.0
	var cuenta := 0
	for pata in ["front_l", "front_r", "back_l", "back_r"]:
		var bi := sk.find_bone("leg_%s.hoof" % pata)
		if bi < 0:
			continue
		var chain: Array[int] = []
		var b := bi
		while b >= 0:
			chain.push_front(b)
			b = sk.get_bone_parent(b)
		var ps: Array[Vector3] = []
		for s in n:
			ps.append(_pose(sk, a, chain, root_path, a.length * float(s) / float(n), 0.0))
		for s in n:
			var dx := ps[(s + 1) % n].x - ps[s].x
			if dx < 0.0: # la mitad en que la pata va hacia atrás es la que apoya
				suma += -dx
				cuenta += 1
	return maxf(0.01, suma / (float(cuenta) * a.length / float(n))) if cuenta > 0 else 1.0


## Posición de un hueso (en el esqueleto) en el momento t, con las pistas del clip (más `largo`
## sobre su eje y).
static func _pose(sk: Skeleton3D, a: Animation, chain: Array[int], root_path: NodePath, t: float, largo: float) -> Vector3:
	var g := Transform3D.IDENTITY
	for bone in chain:
		var rest := sk.get_bone_rest(bone)
		var q := rest.basis.get_rotation_quaternion()
		var o := rest.origin
		var path := NodePath(str(root_path) + ":" + sk.get_bone_name(bone))
		var tr := a.find_track(path, Animation.TYPE_ROTATION_3D)
		if tr >= 0:
			q = a.rotation_track_interpolate(tr, t)
		var tp := a.find_track(path, Animation.TYPE_POSITION_3D)
		if tp >= 0:
			o = a.position_track_interpolate(tp, t)
		g = g * Transform3D(Basis(q), o)
	return g * Vector3(0, largo, 0)


# ---------------------------------------------------------------- Instancia

class Estado:
	extends RefCounted
	var node: Node3D # lo que se escala y gira (el cuerpo de la unidad)
	var inst: Node3D
	var sk: Skeleton3D
	var ap: AnimationPlayer
	var md := {}
	var juego := {}
	var s := 1.0 # escala del modelo en el mundo
	var accion := ""
	var vel := 0.0
	var jinetes: Array = [] # AldeanoAnimado.Estado
	var golpes := 0
	var ataque_left := 0.0
	var hit_left := 0.0
	var quieto_t := 0.0 # para alternar quieto y pastar
	var pastar := false
	var acc_t := 0.0
	var walk_acc := 0.0
	var dt_acc := 0.0
	var golpe := false
	var recibe := false
	var muerto := false


## Animal de la unidad: `md` es el modelo (montado_de → _modelo, o especie); `alto` su alto en el
## mundo. `team` tiñe la manta. Para montados, `m` es la línea de montados.unidades y lo demás
## sirve para vestir a los jinetes como soldados de su pueblo.
static func crear(md: Dictionary, alto: float, team: Color, tinte := Color.WHITE) -> Estado:
	var st := Estado.new()
	st.md = md
	st.juego = (md.get("tipo", {}) as Dictionary).get("juego", {})
	st.node = Node3D.new()
	st.node.name = "CuadrupedoAnimado"
	st.inst = (md["ps"] as PackedScene).instantiate()
	st.s = alto / float(md["h0"])
	st.inst.scale = Vector3.ONE * st.s
	st.inst.rotation.y = -PI / 2.0 # el GLB mira a +x; la unidad, a +z
	st.node.add_child(st.inst)
	st.sk = st.inst.find_children("*", "Skeleton3D", true, false)[0]
	st.ap = st.inst.find_children("*", "AnimationPlayer", true, false)[0]
	st.ap.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
	for mi: MeshInstance3D in st.inst.find_children("*", "MeshInstance3D", true, false):
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
		if mi.mesh == null:
			continue
		for i in mi.mesh.get_surface_count():
			var m := mi.mesh.surface_get_material(i)
			var nm := m.resource_name if m != null else ""
			if nm.begins_with("equipo_borde"):
				continue
			if nm.begins_with("equipo"):
				mi.set_surface_override_material(i, _manta(team))
			elif tinte != Color.WHITE and m is StandardMaterial3D:
				var t := (m as StandardMaterial3D).duplicate() as StandardMaterial3D
				t.albedo_color = t.albedo_color * tinte
				mi.set_surface_override_material(i, t)
	st.ap.play("quieto")
	st.ap.seek(randf() * float(md["len"].get("quieto", 1.0)), true)
	st.quieto_t = randf() * 20.0
	return st


static func _manta(team: Color) -> StandardMaterial3D:
	var key := team.to_html()
	if not _mats.has(key):
		var m := StandardMaterial3D.new()
		m.albedo_color = team
		m.roughness = 0.85
		m.cull_mode = BaseMaterial3D.CULL_DISABLED
		_mats[key] = m
	return _mats[key]


## Sienta a un jinete (AldeanoAnimado.crear_jinete) en el hueso `hueso` («silla» o
## «cuello_asiento»). `k` es el alto de la persona en el mundo.
static func montar(st: Estado, j: AldeanoAnimado.Estado, hueso: String, k: float) -> void:
	if not st.md.has(hueso):
		return
	var att := BoneAttachment3D.new()
	att.bone_name = hueso
	st.sk.add_child(att)
	var holder := Node3D.new()
	var rest: Transform3D = st.md[hueso]
	# en el reposo del hueso, el jinete queda derecho y mirando adonde mira el animal (+x)
	holder.transform = Transform3D(rest.basis.inverse(), Vector3.ZERO) * Transform3D(Basis(Vector3.UP, PI / 2.0).scaled(Vector3.ONE * (k / st.s)), Vector3.ZERO)
	att.add_child(holder)
	j.node.position = Vector3(0, -0.5, 0) # la cadera (a 0,5 de la persona) sobre la silla
	holder.add_child(j.node)
	st.jinetes.append(j)


## Avanza la animación (WorldView la llama cuando le toca). `walked`: distancia recorrida en el
## mundo desde la última vez; `dt`: tiempo de juego; `golpe`: pegó; `recibe`: le pegaron.
static func actualizar(st: Estado, e: SimEntity, sim: Sim, moving: bool, walked: float, dt: float, golpe: bool, recibe: bool, lejos: bool) -> void:
	if st.muerto:
		return
	var t0 := Time.get_ticks_usec()
	if dt > 0.0:
		st.vel = lerpf(st.vel, walked / dt, clampf(dt * 4.0, 0.0, 1.0))
	for j: AldeanoAnimado.Estado in st.jinetes:
		AldeanoAnimado.actualizar(j, e, sim, false, 0.0, dt, golpe, recibe, lejos)
	var lens: Dictionary = st.md["len"]
	if golpe and e.order == O.ATTACK:
		st.golpes += 1
		if st.golpes % maxi(1, int(st.juego.get("ataque_cada", 1))) == 0 and lens.has("ataque"):
			st.ataque_left = float(lens["ataque"])
			_poner(st, "ataque", 0.1)
			st.ap.seek(0.0, true)
	if st.ataque_left > 0.0 and not moving:
		st.ataque_left -= dt
		st.ap.advance(dt)
		us_actualizar += Time.get_ticks_usec() - t0
		return
	st.ataque_left = 0.0
	if st.hit_left > 0.0:
		st.hit_left -= dt
		st.ap.advance(dt)
		us_actualizar += Time.get_ticks_usec() - t0
		return
	if recibe and not moving and lens.has("golpeado") and not (lejos and e.order == O.ATTACK):
		st.hit_left = float(lens["golpeado"])
		_poner(st, "golpeado", 0.06)
		st.ap.seek(0.0, true)
		us_actualizar += Time.get_ticks_usec() - t0
		return
	var anim_dt := dt
	if moving:
		var gd := float(st.juego.get("galope_desde", 1.8))
		var gal: bool = st.vel > (gd * 0.85 if st.accion == "galope" else gd) and (st.md["paso"] as Dictionary).has("galope")
		var an := "galope" if gal else "caminar"
		var v := float(st.md["paso"].get(an, 1.0)) * st.s
		var lo := float(st.juego.get("vel_min_pct", 60)) / 100.0
		var hi := float(st.juego.get("vel_max_pct", 170)) / 100.0
		anim_dt = clampf(walked / v, dt * lo, dt * hi) if dt > 0.0 else walked / v
		_poner(st, an, 0.2)
		st.quieto_t = 0.0
	else:
		# quieto: alterna con pastar (los animales sin jinete), pastar_pct de cada 100 s
		var an := "quieto"
		if st.jinetes.is_empty() and lens.has("pastar") and e.order != O.ATTACK:
			st.quieto_t += dt
			var ciclo := 12.0
			var pct := float(montados().get("animales", {}).get("pastar_pct", 45)) / 100.0
			an = "pastar" if fposmod(st.quieto_t, ciclo) < ciclo * pct else "quieto"
		_poner(st, an, 0.4)
	st.ap.advance(anim_dt)
	us_actualizar += Time.get_ticks_usec() - t0


## Quieto o pastando, para los animales del mapa (caza y sueltos): sin simulación detrás.
static func pasear(st: Estado, dt: float) -> void:
	if st.muerto:
		st.ap.advance(dt)
		return
	st.quieto_t += dt
	var ciclo := 14.0
	var pct := float(montados().get("animales", {}).get("pastar_pct", 45)) / 100.0
	_poner(st, "pastar" if fposmod(st.quieto_t, ciclo) < ciclo * pct else "quieto", 0.5)
	st.ap.advance(dt)


static func _poner(st: Estado, an: String, mezcla: float) -> void:
	if st.accion == an or not st.md["len"].has(an):
		return
	st.accion = an
	st.ap.play(an, mezcla)


## Muerte: el animal cae de costado y los jinetes con él. Devuelve los reproductores que hay que
## seguir avanzando (WorldView._render_fx).
static func morir(st: Estado) -> Array:
	st.muerto = true
	var out: Array = []
	if st.md["len"].has("morir"):
		st.ap.play("morir", 0.1)
		out.append(st.ap)
	for j: AldeanoAnimado.Estado in st.jinetes:
		out.append(AldeanoAnimado.morir(j))
	return out
