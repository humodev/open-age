class_name AldeanoAnimado
extends RefCounted
## Gente animada con el esqueleto y las animaciones de KayKit Character Animations (CC0;
## proceso/27-animaciones): los aldeanos (paso 1) y los soldados a pie (paso 2; su equipo, en
## TropaAnimada). Solo imagen: lee la simulación y no decide nada (docs/06).
##
## El paquete trae un maniquí cabezón (proporciones de muñeco). Se usa su esqueleto con los
## huesos alargados o acortados a proporciones de persona (PROP) y, de cada animación, solo las
## rotaciones (más la altura de la cadera, escalada): así la misma animación sirve con otro largo
## de huesos, como el retargeting de Godot. El cuerpo es de maqueta, una pieza rígida por hueso,
## con la ropa y el tocado de cada pueblo (data/arte_animaciones.json → vestimenta).
##
## Rendimiento (paso 2): las figuras que hacen lo mismo (quieto, caminar al mismo paso, el mismo
## trabajo) comparten un esqueleto por animación, fase y paso (Coro); el esqueleto propio se arma
## recién cuando hace falta (de cerca, el golpe, la reacción, la muerte).
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
const SIN_BUCLE := ["Death_A", "Death_B", "Hit_A", "Hit_B", "PickUp", "Interact", "Melee_Block_Hit"]
## Tipo de cada pieza (UV2.x del vértice): cuánto se ve la trama y cuánto brilla.
enum Pieza { TELA, PIEL, METAL, MADERA, PELO }

static var _cfg := {}
static var _tpl := {}
static var _meshes := {}
static var _mat: ShaderMaterial
static var us_actualizar := 0 # medición (tools/aldeanos_animados.gd --modo=fps)
static var us_avance := 0
static var us_coros := 0
static var n_play := 0
static var n_malla := 0
static var n_propios := 0 # figuras con esqueleto propio (se arma recién cuando hace falta)
static var forzar := -1 # --animaciones=0|1 (main.gd): pisa data/arte_animaciones.json → activo
static var forzar_compartir := -1 # --compartir=0|1 (main.gd): pisa rendimiento.compartir
static var max_por_cuadro := 80 # data/arte_animaciones.json → rendimiento
static var lejos_m := 46.0
static var compartir := true
static var compartir_desde_m := 34.0
static var compartir_con_mas_de := 90
static var cerca_m := 18.0
static var _fases := 4
static var _paso_q := 1.06


static func cfg() -> Dictionary:
	if _cfg.is_empty():
		var raw: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/arte_animaciones.json"))
		_cfg = raw if raw is Dictionary else {"activo": false}
		var r: Dictionary = _cfg.get("rendimiento", {})
		max_por_cuadro = maxi(1, int(r.get("max_por_cuadro", 80)))
		lejos_m = float(r.get("lejos_m", 46))
		compartir = bool(r.get("compartir", false)) if forzar_compartir < 0 else forzar_compartir == 1
		compartir_desde_m = float(r.get("compartir_desde_m", 34))
		compartir_con_mas_de = int(r.get("compartir_con_mas_de", 90))
		cerca_m = float(r.get("cerca_m", 18))
		_fases = maxi(1, int(r.get("fases", 4)))
		_paso_q = 1.0 + maxf(0.5, float(r.get("paso_pct", 6))) / 100.0
		_fases_ataque = maxi(1, int(r.get("fases_ataque", 6)))
		_paso_q_caminar = 1.0 + maxf(0.5, float(r.get("paso_caminar_pct", 15))) / 100.0
		_ajuste_paso = float(r.get("ajuste_paso_pct", 12)) / 100.0
		_paso_min = float(r.get("paso_min_pct", 50)) / 100.0
	return _cfg


## Al cerrar el juego (main.gd, _exit_tree): el esqueleto molde nunca entra al árbol y, como
## es un nodo, nadie lo libera solo ("1 ObjectDB instance was leaked"). Paso 6e.
static func soltar() -> void:
	var sk: Variant = _tpl.get("sk")
	if sk is Skeleton3D and is_instance_valid(sk) and not (sk as Skeleton3D).is_inside_tree():
		(sk as Skeleton3D).free()
	_tpl = {}
	for md: Dictionary in _modelos.values(): # --- aldeanos de Meshy ---
		var msk: Variant = md.get("sk")
		if msk is Skeleton3D and is_instance_valid(msk) and not (msk as Skeleton3D).is_inside_tree():
			(msk as Skeleton3D).free()
	_modelos = {}


## Si esta unidad se dibuja animada: los aldeanos y, con tropas.activo, los soldados a pie de
## las funciones de tropas.funciones (el asedio, solo los tipos que tienen equipo, como los
## incendiarios). Caballos, elefantes, piezas y la corte móvil, no.
static func usa(def: Dictionary, type := "") -> bool:
	var on: bool = cfg().get("activo", false) if forzar < 0 else forzar == 1
	if not on or def.get("animal", false) or def.get("montado", false) or def.get("elefante", false) or def.has("despliega_en"):
		return false
	var fn: String = def.get("funcion", "")
	if fn != "civil" and fn != "comercio": # --- comercio --- el comerciante es la figura del aldeano con su carga
		var tr: Dictionary = cfg().get("tropas", {})
		if not tr.get("activo", false) or not fn in tr.get("funciones", []) or def.has("area_borde_pct"):
			return false
		if fn == "asedio" and not (tr.get("tipos", {}) as Dictionary).has(type):
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
	# Ciclos encadenados (acciones con "anims"): tensar y soltar el arco, disparar y recargar.
	var acts: Dictionary = cfg().get("acciones", {})
	for act: String in acts:
		var names: Array = acts[act].get("anims", [])
		if names.size() > 1:
			var joined := "+".join(PackedStringArray(names))
			if not lib.has_animation(joined):
				lib.add_animation(joined, _encadenar(lib, names))
	var skin := sk.create_skin_from_rest_transforms()
	_tpl = {"sk": sk, "lib": lib, "skin": skin}
	_tpl["paso"] = _paso(sk, lib, acts.get("caminar", {}).get("anim", "Walking_A"))
	_tpl["paso_correr"] = _paso(sk, lib, acts.get("correr", {}).get("anim", "Running_A"))
	return _tpl


## Una animación que es varias seguidas (en bucle). Se copian las claves con el tiempo corrido.
static func _encadenar(lib: AnimationLibrary, names: Array) -> Animation:
	var out := Animation.new()
	var t0 := 0.0
	for nm: String in names:
		if not lib.has_animation(nm):
			continue
		var a := lib.get_animation(nm)
		for t in a.get_track_count():
			var path := a.track_get_path(t)
			var ty := a.track_get_type(t)
			var o := out.find_track(path, ty)
			if o < 0:
				o = out.add_track(ty)
				out.track_set_path(o, path)
			for k in a.track_get_key_count(t):
				var kt := t0 + a.track_get_key_time(t, k)
				if ty == Animation.TYPE_ROTATION_3D:
					out.rotation_track_insert_key(o, kt, a.track_get_key_value(t, k))
				elif ty == Animation.TYPE_POSITION_3D:
					out.position_track_insert_key(o, kt, a.track_get_key_value(t, k))
		t0 += a.length
	out.length = t0
	out.loop_mode = Animation.LOOP_LINEAR
	return out


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


## Posición de un hueso (en el modelo) en el momento t de una animación.
static func _hueso_en(sk: Skeleton3D, a: Animation, chain: Array[int], t: float) -> Vector3:
	return _pose_en(sk, a, chain, t).origin


## Transformación de un hueso (en el modelo) en el momento t de una animación.
static func _pose_en(sk: Skeleton3D, a: Animation, chain: Array[int], t: float) -> Transform3D:
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
	return g


static func _cadena(sk: Skeleton3D, bone_name: String) -> Array[int]:
	var chain: Array[int] = []
	var b := sk.find_bone(bone_name)
	while b >= 0:
		chain.push_front(b)
		b = sk.get_bone_parent(b)
	return chain


## Velocidad del cuerpo que pide la animación de caminar (alto 1 por segundo), medida en el pie
## de apoyo: mientras está en el suelo, se corre hacia atrás a la velocidad a la que avanza el
## cuerpo. Con eso el paso sigue a la distancia recorrida y no patina. También devuelve los
## pasos por ciclo (2) para pasar a trote.
static func _paso(sk: Skeleton3D, lib: AnimationLibrary, an: String) -> Dictionary:
	if not lib.has_animation(an):
		return {"v": 1.0, "largo": 1.0}
	var a := lib.get_animation(an)
	var chain := _cadena(sk, "foot.l")
	var samples := 48
	var ys: Array[float] = []
	var zs: Array[float] = []
	for s in samples:
		var p := _hueso_en(sk, a, chain, a.length * float(s) / float(samples))
		ys.append(p.y)
		zs.append(p.z)
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


## En qué momento de una animación de ataque cae el golpe (o sale el tiro): cuando la mano del
## arma va más rápido. Se puede fijar en los datos (acciones.<x>.impacto_pct).
static func _impacto(an: String) -> float:
	var tp := _template()
	var lib: AnimationLibrary = tp["lib"]
	if not lib.has_animation(an):
		return 0.0
	var a := lib.get_animation(an)
	var chain := _cadena(tp["sk"], "handslot.r")
	var samples := 48
	var best := 0.0
	var best_t := 0.0
	var prev := _hueso_en(tp["sk"], a, chain, 0.0)
	for s in range(1, samples + 1):
		var t := a.length * float(s) / float(samples)
		var p := _hueso_en(tp["sk"], a, chain, t)
		var d := p.distance_to(prev)
		if d > best:
			best = d
			best_t = t
		prev = p
	return best_t


# ---------------------------------------------------------------- Aspecto (C-98)

## Material de toda la gente animada: el color de cada vértice por una trama de tela que se ve
## más en la ropa que en la piel, un poco de brillo en el metal, y un tono por figura.
static func _material() -> ShaderMaterial:
	if _mat == null:
		var asp: Dictionary = cfg().get("aspecto", {})
		var sh := Shader.new()
		sh.code = """
shader_type spatial;
render_mode cull_back;
uniform sampler2D trama : source_color, filter_linear_mipmap, repeat_enable;
uniform float fuerza = 0.55;
instance uniform float tono = 1.0;
void fragment() {
	vec3 t = texture(trama, UV).rgb;
	float k = UV2.x * fuerza;
	ALBEDO = COLOR.rgb * mix(vec3(1.0), t, k) * tono;
	METALLIC = UV2.y * 0.55;
	ROUGHNESS = 0.95 - UV2.y * 0.5;
	SPECULAR = 0.3 + UV2.y * 0.3;
}
"""
		_mat = ShaderMaterial.new()
		_mat.shader = sh
		_mat.set_shader_parameter("trama", _trama())
		_mat.set_shader_parameter("fuerza", float(asp.get("textura_pct", 55)) / 100.0)
	return _mat


## Trama de tela procedural (64×64, se repite): hilos cruzados con ruido, entre 0,55 y 1,15.
static func _trama() -> ImageTexture:
	var n := 64
	var img := Image.create(n, n, false, Image.FORMAT_RGB8)
	for y in n:
		for x in n:
			var h := ((x * 73856093) ^ (y * 19349663)) & 0xffff
			var r := float(h % 1000) / 1000.0
			var hilo := 1.0 if ((x / 2 + y / 2) % 2 == 0) else 0.0
			var fila := 0.9 if (y % 4 == 0) else 1.0
			var v := (0.72 + 0.22 * hilo + 0.2 * r) * fila
			img.set_pixel(x, y, Color(v, v * 0.98, v * 0.95))
	img.generate_mipmaps()
	return ImageTexture.create_from_image(img)


# ---------------------------------------------------------------- Cuerpo

## --- aldeanos por retrato --- (proceso/27-animaciones/04) Sexo de la figura de una unidad:
## «f», «m» o "" si no le toca (data/arte_animaciones.json → personas). Sale del id: la
## simulación no lo lee. También lo usa la interfaz para elegir el retrato (Retratos).
static func sexo(id: int, def: Dictionary) -> String:
	var p: Dictionary = cfg().get("personas", {})
	if not (p.get("funciones", []) as Array).has(str(def.get("funcion", ""))) or def.get("comerciante", false):
		return ""
	var x := (id * 2654435761) & 0xffffffff
	x ^= x >> 15
	return "f" if (x & 0x7fffffff) % 100 < int(p.get("mujeres_pct", 50)) else "m"


static var _personas := {}

## La ropa de un aldeano: base[sexo] → por_civ[civ][sexo] → su edad (la más alta que no pase
## `edad`). Lleva «_key» para la caché de mallas.
static func persona(civ: String, sx: String, edad: int) -> Dictionary:
	if sx == "":
		return {}
	var key := "%s_%s_%d" % [civ, sx, edad]
	if _personas.has(key):
		return _personas[key]
	var p: Dictionary = cfg().get("personas", {})
	var out: Dictionary = (p.get("base", {}) as Dictionary).get(sx, {}).duplicate(true)
	var pc: Dictionary = (p.get("por_civ", {}) as Dictionary).get(civ, {}).get(sx, {})
	for k in pc:
		if k != "edades":
			out[k] = pc[k]
	var eds: Dictionary = pc.get("edades", {})
	var mejor := 0
	for k: String in eds:
		if int(k) <= edad and int(k) > mejor:
			mejor = int(k)
	if mejor > 0:
		out.merge(eds[str(mejor)], true)
	out["_key"] = key
	_personas[key] = out
	return out


## Viste al aldeano según su sexo y la edad de su pueblo (y la vuelve a armar al cambiar de edad).
static func vestir(st: Estado, civ: String, sx: String, edad: int) -> void:
	st.per = persona(civ, sx, edad)
	if st.modelo.is_empty() and not st.tropa: # --- aldeanos de Meshy ---
		_poner_modelo(st, modelo_de(civ, sx))
	if not st.modelo.is_empty():
		st.extra.mesh = malla_modelo(st.modelo, st.style, "" if st.tool == "-" else st.tool, st.carga, st.per)
		return
	st.mi.mesh = malla(st.style, st.team, "" if st.tool == "-" else st.tool, st.carga, "", st.per)
# --- fin aldeanos por retrato ---


## Colores de la gente de un pueblo (data/arte_animaciones.json → vestimenta y colores); `per`,
## la ropa del aldeano por sexo y edad, pisa a la de la forma.
static func colores(style: Dictionary, per := {}) -> Dictionary:
	var forma: String = style.get("forma", "")
	var cols: Dictionary = cfg().get("colores", {})
	var vest_all: Dictionary = cfg().get("vestimenta", {})
	var vest: Dictionary = vest_all.get(forma, vest_all.get("_otro", {}))
	if not per.is_empty():
		vest = vest.merged(per, true)
	var tela := Color(vest["tela"]) if vest.has("tela") else Color(style.get("arcilla", "#8a7a62")).darkened(0.3)
	return {
		"vest": vest, "tela": tela,
		"piel": Color(vest.get("piel", cols.get("piel", "#9a6a48"))),
		"pelo": Color(vest.get("pelo", cols.get("pelo", "#231c17"))),
		"madera": Color(cols.get("madera", "#6e5034")), "piedra": Color(cols.get("piedra", "#5e5c58")),
		"fibra": Color(cols.get("fibra", "#9a7e4a")), "cuero": Color(cols.get("cuero", "#4e3828")),
		"metal": Color(cols.get("metal", "#7c7f84")), "cuerda": Color(cols.get("cuerda", "#8a7552")),
	}


## Malla con piel (una pieza rígida por hueso) del aldeano de un pueblo, con su herramienta y,
## si lleva carga, el atado a la espalda del color del recurso. `forma_carga` (comerciante):
## fardo, cantaro, barras, cesto o vara.
const CARGAS := {"fardo": "8a6a44", "cantaro": "b0603a", "barras": "e8e2d0", "cesto": "a8843e", "vara": "7a5a32"} # --- comercio ---
static func malla(style: Dictionary, team: Color, tool: String, carga: Color, forma_carga := "", per := {}) -> ArrayMesh:
	var forma: String = style.get("forma", "")
	var key := "%s_%s_%s_%s_%s_%s_%s" % [forma, style.get("arcilla", ""), team.to_html(), tool, carga.to_html(), forma_carga, per.get("_key", "")]
	if _meshes.has(key):
		return _meshes[key]
	var sk: Skeleton3D = _template()["sk"]
	var c := colores(style, per)
	var parts: Array = [] # [malla, transform en el modelo, color, hueso, Pieza]
	cuerpo(parts, sk, c, team, c["tela"], str(c["vest"].get("prenda", "ninguna")), Color(c["vest"].get("prenda_color", (c["tela"] as Color).to_html())), true)
	_herramienta(parts, tool, sk, c["madera"], c["piedra"], c["fibra"], c["vest"])
	if carga.a > 0.0 and forma_carga != "":
		_carga_comercio(parts, sk, forma_carga, carga, c)
	elif carga.a > 0.0:
		var ch: Vector3 = _P(sk, "chest")
		var bc := sk.find_bone("chest")
		parts.append([_box(Vector3(0.15, 0.13, 0.1)), Transform3D(Basis.IDENTITY, ch + Vector3(0, 0.08, -0.11)), carga.darkened(0.15), bc])
		parts.append([_box(Vector3(0.012, 0.15, 0.13)), Transform3D(Basis.IDENTITY, ch + Vector3(0.06, 0.07, -0.05)), c["cuero"], bc, Pieza.MADERA])
	var mesh := _skinned(parts)
	_meshes[key] = mesh
	return mesh


## --- comercio --- La carga del comerciante, a la espalda o al hombro (maqueta procedural, C-80 «b»).
static func _carga_comercio(parts: Array, sk: Skeleton3D, forma: String, col: Color, c: Dictionary) -> void:
	var ch: Vector3 = _P(sk, "chest")
	var bc := sk.find_bone("chest")
	var back := ch + Vector3(0, 0.06, -0.14)
	match forma:
		"cantaro":
			parts.append([_box(Vector3(0.16, 0.16, 0.14)), Transform3D(Basis.IDENTITY, back), col, bc])
			parts.append([_box(Vector3(0.07, 0.08, 0.07)), Transform3D(Basis.IDENTITY, back + Vector3(0, 0.12, 0)), col.darkened(0.2), bc])
		"barras":
			for i in 3:
				parts.append([_box(Vector3(0.2, 0.045, 0.08)), Transform3D(Basis.IDENTITY, back + Vector3(0, -0.05 + i * 0.05, 0)), col.darkened(i * 0.06), bc])
		"cesto":
			parts.append([_box(Vector3(0.2, 0.17, 0.15)), Transform3D(Basis.IDENTITY, back), col, bc])
			parts.append([_box(Vector3(0.22, 0.03, 0.17)), Transform3D(Basis.IDENTITY, back + Vector3(0, 0.09, 0)), col.lightened(0.2), bc])
		"vara":
			var sh := ch + Vector3(0, 0.16, 0)
			parts.append([_box(Vector3(0.7, 0.025, 0.025)), Transform3D(Basis.IDENTITY, sh), col, bc, Pieza.MADERA])
			for x in [-0.33, 0.33]:
				parts.append([_box(Vector3(0.11, 0.13, 0.11)), Transform3D(Basis.IDENTITY, sh + Vector3(x, -0.1, 0)), Color("c9a86a"), bc])
		_:
			parts.append([_box(Vector3(0.22, 0.2, 0.15)), Transform3D(Basis.IDENTITY, back), col, bc])
			parts.append([_box(Vector3(0.012, 0.2, 0.17)), Transform3D(Basis.IDENTITY, back + Vector3(0.06, 0, 0.04)), c["cuero"], bc, Pieza.MADERA])


static func _P(sk: Skeleton3D, bone: String) -> Vector3:
	return sk.get_bone_global_rest(sk.find_bone(bone)).origin


## El cuerpo de una persona: cabeza, tronco con la tela, faja del equipo, piernas, brazos y
## la prenda del pueblo; con `tocado`, también el tocado (los soldados con casco no lo llevan).
static func cuerpo(parts: Array, sk: Skeleton3D, c: Dictionary, team: Color, tela: Color, prenda: String, prenda_col: Color, tocado: bool) -> void:
	var piel: Color = c["piel"]
	var pelo: Color = c["pelo"]
	var cuero: Color = c["cuero"]
	var B := func(bone: String) -> int: return sk.find_bone(bone)
	var P := func(bone: String) -> Vector3: return _P(sk, bone)
	# Cabeza, cuello y pelo.
	var head: Vector3 = P.call("head")
	parts.append([_sphere(0.068), Transform3D(Basis.from_scale(Vector3(0.92, 1.0, 0.98)), head + Vector3(0, 0.078, 0.005)), piel, B.call("head"), Pieza.PIEL])
	parts.append([_sphere(0.071), Transform3D(Basis.from_scale(Vector3(1.0, 0.72, 1.0)), head + Vector3(0, 0.105, -0.012)), pelo, B.call("head"), Pieza.PELO])
	parts.append([_cyl(0.03, 0.033, 0.06), Transform3D(Basis.IDENTITY, head + Vector3(0, 0.0, 0)), piel, B.call("head"), Pieza.PIEL])
	# Tronco: pecho, vientre y cadera, de la tela del pueblo; faja del color del equipo.
	parts.append([_cyl(0.112, 0.095, 0.14), Transform3D(Basis.from_scale(Vector3(1, 1, 0.62)), P.call("chest") + Vector3(0, 0.07, 0)), tela, B.call("chest")])
	parts.append([_cyl(0.095, 0.088, 0.12), Transform3D(Basis.from_scale(Vector3(1, 1, 0.66)), P.call("spine") + Vector3(0, 0.04, 0)), tela, B.call("spine")])
	parts.append([_cyl(0.092, 0.1, 0.12), Transform3D(Basis.from_scale(Vector3(1, 1, 0.7)), P.call("hips") + Vector3(0, 0.02, 0)), tela, B.call("hips")])
	parts.append([_cyl(0.103, 0.103, 0.035), Transform3D(Basis.from_scale(Vector3(1, 1, 0.74)), P.call("hips") + Vector3(0, 0.08, 0)), team, B.call("hips"), Pieza.PIEL])
	# Piernas y pies.
	for s in ["l", "r"]:
		parts.append(_seg(P.call("upperleg." + s), P.call("lowerleg." + s), 0.05, 0.04, piel, B.call("upperleg." + s), Pieza.PIEL))
		parts.append(_seg(P.call("lowerleg." + s), P.call("foot." + s), 0.038, 0.028, piel, B.call("lowerleg." + s), Pieza.PIEL))
		var f: Vector3 = P.call("foot." + s)
		parts.append([_box(Vector3(0.055, 0.035, 0.115)), Transform3D(Basis.IDENTITY, Vector3(f.x, 0.018, f.z + 0.03)), cuero, B.call("foot." + s), Pieza.MADERA])
		# Brazos y manos.
		parts.append(_seg(P.call("upperarm." + s), P.call("lowerarm." + s), 0.036, 0.03, piel, B.call("upperarm." + s), Pieza.PIEL))
		parts.append(_seg(P.call("lowerarm." + s), P.call("wrist." + s), 0.029, 0.024, piel, B.call("lowerarm." + s), Pieza.PIEL))
		parts.append([_sphere(0.03), Transform3D(Basis.from_scale(Vector3(1.0, 0.8, 1.0)), P.call("hand." + s)), piel, B.call("hand." + s), Pieza.PIEL])
	var vest: Dictionary = c["vest"]
	_prenda(parts, prenda, prenda_col, tela, P, B, vest)
	if vest.has("pelo_forma") or vest.has("manta"): # --- aldeanos por retrato ---
		_persona(parts, vest, pelo, c["metal"], head, B.call("head"), P.call("chest"), B.call("chest"))
	if tocado:
		_tocado(parts, str(vest.get("tocado", "ninguno")), Color(vest.get("tocado_color", "#8e3226")), head, B.call("head"), vest)


## --- aldeanos por retrato --- (proceso/27-animaciones/04) Damero de tocapu: `filas` × `cols`
## cuadritos de los `colores` del retrato, en un plano frente a `centro` (mirando a +z).
static func _tocapu(parts: Array, centro: Vector3, t: Dictionary, lado: float, bone: int) -> void:
	var cols_c: Array = t.get("colores", [])
	if cols_c.is_empty():
		return
	var filas := int(t.get("filas", 1))
	var cols := int(t.get("cols", 4))
	var paso := lado * 1.18
	for j in filas:
		for i in cols:
			var col := Color(str(cols_c[(i + j * 2) % cols_c.size()]))
			var pos := centro + Vector3((i - (cols - 1) * 0.5) * paso, ((filas - 1) * 0.5 - j) * paso, 0)
			parts.append([_box(Vector3(lado, lado, 0.008)), Transform3D(Basis.IDENTITY, pos), col, bone])


## Pelo largo o con flequillo, y la manta sobre los hombros con su orilla y su tupu.
static func _persona(parts: Array, vest: Dictionary, pelo: Color, metal: Color, head: Vector3, hb: int, chest: Vector3, cb: int) -> void:
	match str(vest.get("pelo_forma", "")):
		"flequillo": # corte parejo a la altura de la oreja, con flequillo
			parts.append([_sphere(0.074), Transform3D(Basis.from_scale(Vector3(1.0, 0.8, 1.0)), head + Vector3(0, 0.088, -0.014)), pelo, hb, Pieza.PELO])
			parts.append([_box(Vector3(0.1, 0.026, 0.02)), Transform3D(Basis.IDENTITY, head + Vector3(0, 0.118, 0.056)), pelo, hb, Pieza.PELO])
		"trenza": # raya al medio, recogido atrás y una trenza larga a la espalda
			parts.append([_sphere(0.073), Transform3D(Basis.from_scale(Vector3(0.98, 0.78, 1.04)), head + Vector3(0, 0.098, -0.016)), pelo, hb, Pieza.PELO])
			for i in 5:
				var y := 0.07 - i * 0.045
				parts.append([_sphere(0.021 - i * 0.0018, 6), Transform3D(Basis.from_scale(Vector3(1, 1.3, 1)), head + Vector3(0.025, y, -0.078 - i * 0.004)), pelo, hb, Pieza.PELO])
		"largo": # suelto hasta los hombros
			parts.append([_sphere(0.073), Transform3D(Basis.from_scale(Vector3(1.0, 0.8, 1.04)), head + Vector3(0, 0.096, -0.016)), pelo, hb, Pieza.PELO])
			parts.append([_box(Vector3(0.12, 0.17, 0.03)), Transform3D(Basis.IDENTITY, head + Vector3(0, 0.02, -0.066)), pelo, hb, Pieza.PELO])
	if vest.has("manta"): # lliklla (o yacolla) sobre los hombros
		var manta := Color(str(vest["manta"]))
		var borde := Color(str(vest.get("manta_borde", manta.darkened(0.25).to_html())))
		parts.append([_cyl(0.085, 0.152, 0.15, 12), Transform3D(Basis.from_scale(Vector3(1, 1, 0.72)), chest + Vector3(0, 0.075, -0.004)), manta, cb])
		parts.append([_cyl(0.154, 0.154, 0.026, 12), Transform3D(Basis.from_scale(Vector3(1, 1, 0.73)), chest + Vector3(0, 0.0, -0.004)), borde, cb])
		if vest.has("tocapu"):
			_tocapu(parts, chest + Vector3(0, 0.012, 0.118), vest["tocapu"], 0.016, cb)
		if vest.has("tupu"): # el alfiler que cierra la manta al pecho
			var tc := Color(str(vest["tupu"]))
			parts.append([_sphere(0.017, 6), Transform3D(Basis.from_scale(Vector3(1, 1, 0.5)), chest + Vector3(0, 0.1, 0.098)), tc, cb, Pieza.METAL])
			parts.append([_cyl(0.003, 0.004, 0.07, 4), Transform3D(Basis.IDENTITY, chest + Vector3(0, 0.07, 0.1)), tc, cb, Pieza.METAL])
# --- fin aldeanos por retrato ---


static func _prenda(parts: Array, kind: String, col: Color, tela: Color, P: Callable, B: Callable, vest := {}) -> void:
	var hips: Vector3 = P.call("hips")
	var chest: Vector3 = P.call("chest")
	match kind:
		"unku": # túnica hasta la rodilla con la franja de tocapus
			if vest.has("pelo_forma"): # --- aldeanos por retrato --- el del retrato, hasta la rodilla
				parts.append([_cyl(0.1, 0.14, 0.23), Transform3D(Basis.from_scale(Vector3(1, 1, 0.75)), hips + Vector3(0, -0.1, 0)), tela, B.call("hips")])
				parts.append([_cyl(0.142, 0.142, 0.02), Transform3D(Basis.from_scale(Vector3(1, 1, 0.76)), hips + Vector3(0, -0.205, 0)), col, B.call("hips")])
				if vest.has("tocapu"):
					_tocapu(parts, chest + Vector3(0, 0.02, 0.07), vest["tocapu"], 0.019, B.call("chest"))
					if vest.get("tocapu_falda", false): # el unku de tocapu, también abajo
						_tocapu(parts, hips + Vector3(0, -0.12, 0.1), vest["tocapu"], 0.019, B.call("hips"))
				elif vest.has("franjas"): # unku listado: dos franjas de arriba abajo
					var fc := Color(str(vest["franjas"]))
					for fx in [-0.035, 0.035]:
						parts.append([_box(Vector3(0.028, 0.16, 0.01)), Transform3D(Basis.IDENTITY, chest + Vector3(fx, 0.0, 0.066)), fc, B.call("chest")])
						parts.append([_box(Vector3(0.03, 0.2, 0.01)), Transform3D(Basis(Vector3.RIGHT, -0.16), hips + Vector3(fx * 1.2, -0.1, 0.092)), fc, B.call("hips")])
				else:
					parts.append([_box(Vector3(0.14, 0.035, 0.012)), Transform3D(Basis.IDENTITY, chest + Vector3(0, 0.02, 0.066)), col, B.call("chest")])
				return
			parts.append([_cyl(0.1, 0.135, 0.17), Transform3D(Basis.from_scale(Vector3(1, 1, 0.75)), hips + Vector3(0, -0.07, 0)), tela, B.call("hips")])
			parts.append([_box(Vector3(0.14, 0.035, 0.012)), Transform3D(Basis.IDENTITY, chest + Vector3(0, 0.02, 0.066)), col, B.call("chest")])
		"acsu", "vestido": # --- aldeanos por retrato --- vestido largo hasta el tobillo con faja
			var cuerpo_c := tela if kind == "acsu" else col
			var faja := col if kind == "acsu" else tela
			parts.append([_cyl(0.1, 0.165, 0.4, 10), Transform3D(Basis.from_scale(Vector3(1, 1, 0.78)), hips + Vector3(0, -0.18, 0)), cuerpo_c, B.call("hips")])
			parts.append([_cyl(0.1, 0.1, 0.045, 10), Transform3D(Basis.from_scale(Vector3(1, 1, 0.72)), hips + Vector3(0, 0.02, 0)), faja, B.call("hips")])
			if kind == "acsu" and vest.has("tocapu"):
				_tocapu(parts, hips + Vector3(0, 0.02, 0.074), vest["tocapu"], 0.014, B.call("hips"))
		"poncho":
			parts.append([_cyl(0.06, 0.17, 0.2, 10), Transform3D(Basis.from_scale(Vector3(1, 1, 0.68)), chest + Vector3(0, 0.05, 0)), col, B.call("chest")])
			parts.append([_cyl(0.095, 0.12, 0.13), Transform3D(Basis.from_scale(Vector3(1, 1, 0.75)), hips + Vector3(0, -0.05, 0)), tela, B.call("hips")])
		"tipoy": # túnica larga sin mangas
			parts.append([_cyl(0.1, 0.14, 0.22), Transform3D(Basis.from_scale(Vector3(1, 1, 0.75)), hips + Vector3(0, -0.09, 0)), col, B.call("hips")])
		"shamma": # manto cruzado sobre un hombro
			parts.append([_box(Vector3(0.23, 0.17, 0.135)), Transform3D(Basis(Vector3(0, 0, 1), deg_to_rad(14)), chest + Vector3(0.0, 0.06, 0)), col, B.call("chest")])
			parts.append([_cyl(0.1, 0.14, 0.22), Transform3D(Basis.from_scale(Vector3(1, 1, 0.75)), hips + Vector3(0, -0.09, 0)), col, B.call("hips")])
		"pano": # paño atado a la cintura
			parts.append([_cyl(0.1, 0.125, 0.14), Transform3D(Basis.from_scale(Vector3(1, 1, 0.75)), hips + Vector3(0, -0.06, 0)), col, B.call("hips")])
		_:
			parts.append([_cyl(0.096, 0.112, 0.09), Transform3D(Basis.from_scale(Vector3(1, 1, 0.74)), hips + Vector3(0, -0.04, 0)), tela, B.call("hips")])


static func _tocado(parts: Array, kind: String, col: Color, head: Vector3, bone: int, vest := {}) -> void:
	match kind:
		"vincha":
			var vy := 0.115 if vest.has("pelo_forma") else 0.1 # --- aldeanos por retrato --- en el nacimiento del pelo
			parts.append([_cyl(0.07, 0.07, 0.022, 12), Transform3D(Basis.from_scale(Vector3(0.95, 1, 1.0)), head + Vector3(0, vy, 0.0)), col, bone])
			if vest.has("vincha_tocapu"): # --- aldeanos por retrato --- el tejido al frente y la borla
				_tocapu(parts, head + Vector3(0, vy, 0.068), {"colores": vest["vincha_tocapu"], "filas": 1, "cols": 5}, 0.009, bone)
			if vest.has("borla"):
				var bc := Color(str(vest["borla"]))
				parts.append([_cyl(0.004, 0.004, 0.06, 4), Transform3D(Basis.IDENTITY, head + Vector3(0.066, 0.07, 0.01)), bc, bone])
				parts.append([_cyl(0.008, 0.014, 0.035, 6), Transform3D(Basis.IDENTITY, head + Vector3(0.066, 0.03, 0.01)), bc, bone])
		"plumas":
			var amarillo := Color("c9a23e")
			parts.append([_cyl(0.07, 0.07, 0.02, 12), Transform3D(Basis.IDENTITY, head + Vector3(0, 0.1, 0)), amarillo, bone])
			for i in 7:
				var a := -0.9 + i * 0.3
				var b := Basis(Vector3.UP, a) * Basis(Vector3.RIGHT, deg_to_rad(-18))
				parts.append([_cyl(0.0, 0.016, 0.12, 4), Transform3D(b, head + Vector3(sin(a) * 0.06, 0.16, -cos(a) * 0.045)), col if i % 2 == 0 else amarillo, bone, Pieza.PIEL])
		"turbante":
			parts.append([_cyl(0.078, 0.072, 0.06, 12), Transform3D(Basis.IDENTITY, head + Vector3(0, 0.12, -0.005)), col, bone])


## Herramienta en la mano derecha (hueso handslot.r): el mango sale del puño hacia adelante y
## arriba, como lo esperan las animaciones de KayKit.
static func _herramienta(parts: Array, tool: String, sk: Skeleton3D, wood: Color, stone: Color, fibra: Color, vest := {}) -> void:
	if tool == "" or tool == "ninguna":
		return
	var slot := sk.find_bone("handslot.r")
	var g := sk.get_bone_global_rest(slot)
	var X := func(pos: Vector3, b := Basis.IDENTITY) -> Transform3D: return g * Transform3D(b, pos)
	var M := Pieza.MADERA
	# Como las armas de KayKit Adventurers: el mango por el +y del hueso, desde el puño, y la
	# hoja hacia +x.
	match tool:
		"hacha":
			parts.append([_cyl(0.011, 0.012, 0.38), X.call(Vector3(0, 0.1, 0)), wood, slot, M])
			parts.append([_box(Vector3(0.08, 0.075, 0.016)), X.call(Vector3(0.035, 0.25, 0)), stone, slot, M])
		"pico":
			parts.append([_cyl(0.011, 0.012, 0.4), X.call(Vector3(0, 0.1, 0)), wood, slot, M])
			parts.append([_cyl(0.006, 0.016, 0.28, 6), X.call(Vector3(0.0, 0.28, 0), Basis(Vector3.BACK, PI / 2)), stone, slot, M])
		"martillo":
			parts.append([_cyl(0.01, 0.011, 0.26), X.call(Vector3(0, 0.07, 0)), wood, slot, M])
			parts.append([_box(Vector3(0.1, 0.045, 0.045)), X.call(Vector3(0.0, 0.19, 0)), stone, slot, M])
		"azada":
			parts.append([_cyl(0.011, 0.012, 0.6), X.call(Vector3(0, 0.16, 0)), wood, slot, M])
			parts.append([_box(Vector3(0.09, 0.014, 0.075)), X.call(Vector3(0.04, 0.45, 0)), stone, slot, M])
		"cuchillo":
			parts.append([_box(Vector3(0.022, 0.13, 0.01)), X.call(Vector3(0, 0.08, 0)), stone, slot, M])
		"pushka": # --- aldeanos por retrato --- huso de hilar con su tortera y el ovillo de lana
			var lana := Color(str(vest.get("manta_borde", "#d8ccb0")))
			parts.append([_cyl(0.004, 0.005, 0.2, 5), X.call(Vector3(0, 0.03, 0)), wood, slot, M])
			parts.append([_cyl(0.026, 0.026, 0.01, 8), X.call(Vector3(0, -0.06, 0)), wood, slot, M])
			parts.append([_cyl(0.017, 0.017, 0.05, 8), X.call(Vector3(0, 0.07, 0)), lana, slot])
		"chakitaqlla": # --- aldeanos por retrato --- arado de pie: palo largo con el estribo y la punta
			parts.append([_cyl(0.012, 0.014, 0.72, 6), X.call(Vector3(0, 0.2, 0)), wood, slot, M])
			parts.append([_box(Vector3(0.11, 0.022, 0.022)), X.call(Vector3(0.04, 0.42, 0)), wood, slot, M])
			parts.append([_cyl(0.002, 0.014, 0.08, 5), X.call(Vector3(0, 0.6, 0)), stone, slot, M])
		"ejes": # para revisar a mano la orientación de los huesos de las manos (x rojo, y verde, z azul)
			for nm in ["handslot.r", "handslot.l"]:
				var b2 := sk.find_bone(nm)
				var g2 := sk.get_bone_global_rest(b2)
				parts.append([_box(Vector3(0.3, 0.012, 0.012)), g2 * Transform3D(Basis.IDENTITY, Vector3(0.15, 0, 0)), Color.RED, b2, Pieza.PIEL])
				parts.append([_box(Vector3(0.012, 0.3, 0.012)), g2 * Transform3D(Basis.IDENTITY, Vector3(0, 0.15, 0)), Color.GREEN, b2, Pieza.PIEL])
				parts.append([_box(Vector3(0.012, 0.012, 0.3)), g2 * Transform3D(Basis.IDENTITY, Vector3(0, 0, 0.15)), Color.BLUE, b2, Pieza.PIEL])
		"canasta": # cesto colgado de la cadera, del lado izquierdo
			var hips := sk.find_bone("hips")
			var hp := sk.get_bone_global_rest(hips).origin
			parts.append([_cyl(0.06, 0.045, 0.08, 10), Transform3D(Basis.IDENTITY, hp + Vector3(0.13, -0.04, 0.02)), fibra, hips])
			parts.append([_cyl(0.062, 0.062, 0.012, 10), Transform3D(Basis.IDENTITY, hp + Vector3(0.13, 0.0, 0.02)), wood, hips, M])


static func _sphere(r: float, seg := 8) -> SphereMesh:
	var m := SphereMesh.new()
	m.radius = r
	m.height = r * 2.0
	m.radial_segments = seg
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
static func _seg(a: Vector3, b: Vector3, ra: float, rb: float, col: Color, bone: int, kind := Pieza.TELA) -> Array:
	var d := b - a
	var y := d.normalized()
	var x := y.cross(Vector3.FORWARD if absf(y.dot(Vector3.FORWARD)) < 0.9 else Vector3.RIGHT).normalized()
	var z := x.cross(y)
	# El +y del cilindro apunta de `a` a `b`: el radio de arriba es el de `b`.
	return [_cyl(rb, ra, d.length() + ra * 0.6, 8), Transform3D(Basis(x, y, z), (a + b) * 0.5), col, bone, kind]


## Junta las piezas en una superficie con piel rígida (cada vértice, 100 % de su hueso). Cada
## vértice lleva el color de la pieza con la sombra horneada (más oscuro hacia los pies y hacia
## abajo de cada pieza), la trama proyectada desde el cuerpo en reposo (UV) y el tipo de pieza
## (UV2: cuánta trama y cuánto brillo).
static func _skinned(parts: Array) -> ArrayMesh:
	var asp: Dictionary = cfg().get("aspecto", {})
	var pies := float(asp.get("sombra_pies_pct", 26)) / 100.0
	var verts := PackedVector3Array()
	var norms := PackedVector3Array()
	var colors := PackedColorArray()
	var uvs := PackedVector2Array()
	var uv2s := PackedVector2Array()
	var bones := PackedInt32Array()
	var weights := PackedFloat32Array()
	var idx := PackedInt32Array()
	const TRAMA := [1.0, 0.35, 0.15, 0.6, 0.5] # TELA, PIEL, METAL, MADERA, PELO
	const BRILLO := [0.0, 0.05, 1.0, 0.0, 0.1]
	for p in parts:
		var arr: Array = (p[0] as PrimitiveMesh).get_mesh_arrays()
		var xf: Transform3D = p[1]
		var c: Color = p[2]
		var bone: int = p[3]
		var kind: int = p[4] if p.size() > 4 else Pieza.TELA
		var base := verts.size()
		var pv: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
		var pn: PackedVector3Array = arr[Mesh.ARRAY_NORMAL]
		var nb := xf.basis.inverse().transposed()
		var ymin := INF
		var ymax := -INF
		for v in pv:
			ymin = minf(ymin, v.y)
			ymax = maxf(ymax, v.y)
		var uv2 := Vector2(TRAMA[kind], BRILLO[kind])
		for i in pv.size():
			var w := xf * pv[i]
			verts.append(w)
			norms.append((nb * pn[i]).normalized())
			# Sombra horneada: hacia los pies y hacia abajo de la pieza.
			var lk := (pv[i].y - ymin) / maxf(0.0001, ymax - ymin)
			var sh := (1.0 - pies * (1.0 - clampf(w.y / 0.6, 0.0, 1.0))) * lerpf(0.86, 1.0, lk)
			colors.append(Color(c.r * sh, c.g * sh, c.b * sh))
			uvs.append(Vector2(w.x * 0.8 + w.z * 0.8, w.y) * 9.0)
			uv2s.append(uv2)
			bones.append_array([bone, 0, 0, 0])
			weights.append_array([1.0, 0.0, 0.0, 0.0])
		for i: int in arr[Mesh.ARRAY_INDEX]:
			idx.append(base + i)
	var a := []
	a.resize(Mesh.ARRAY_MAX)
	a[Mesh.ARRAY_VERTEX] = verts
	a[Mesh.ARRAY_NORMAL] = norms
	a[Mesh.ARRAY_COLOR] = colors
	a[Mesh.ARRAY_TEX_UV] = uvs
	a[Mesh.ARRAY_TEX_UV2] = uv2s
	a[Mesh.ARRAY_BONES] = bones
	a[Mesh.ARRAY_WEIGHTS] = weights
	a[Mesh.ARRAY_INDEX] = idx
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, a)
	mesh.surface_set_material(0, _material())
	return mesh


# ---------------------------------------------------------------- Aldeanos de Meshy (proceso/57)

## Modelos de Meshy con nuestro rig (data/arte_animaciones.json → modelos): por id, el
## esqueleto (con los nombres de KayKit), la biblioteca retargeteada (una sola por modelo, la
## comparten todas las figuras y los coros), la malla con su piel y un material por color de
## equipo. Se arma la primera vez que un aldeano lo pide.
static var _modelos := {}
static var us_retarget := 0 # medición: cuánto tardó armar los modelos (µs)


## El modelo del aldeano de un pueblo y sexo, o {} (la figura de KayKit).
static func modelo_de(civ: String, sx: String) -> Dictionary:
	var mc: Dictionary = cfg().get("modelos", {})
	if not mc.get("activo", false) or sx == "":
		return {}
	var id := str((mc.get("por_civ", {}) as Dictionary).get(civ, {}).get(sx, ""))
	if id == "":
		return {}
	if _modelos.has(id):
		return _modelos[id]
	var t0 := Time.get_ticks_usec()
	var md := _armar_modelo(id, (mc.get("lista", {}) as Dictionary).get(id, {}))
	us_retarget += Time.get_ticks_usec() - t0
	_modelos[id] = md
	return md


static func _armar_modelo(id: String, d: Dictionary) -> Dictionary:
	var path := str(d.get("glb", ""))
	if path == "" or not ResourceLoader.exists(path) or _template().is_empty():
		push_warning("AldeanoAnimado: falta el modelo %s (%s); queda la figura de KayKit" % [id, path])
		return {}
	var src: Node = (load(path) as PackedScene).instantiate()
	var sks := src.find_children("*", "Skeleton3D", true, false)
	var mis := src.find_children("*", "MeshInstance3D", true, false)
	if sks.is_empty() or mis.is_empty() or (mis[0] as MeshInstance3D).skin == null:
		push_warning("AldeanoAnimado: el modelo %s no trae esqueleto ni piel" % id)
		src.free()
		return {}
	var sk0: Skeleton3D = sks[0]
	var mi0: MeshInstance3D = mis[0]
	# Esqueleto propio (copia de huesos y reposos), con el nombre que esperan las pistas.
	var sk := Skeleton3D.new()
	sk.name = "Skeleton3D"
	for i in sk0.get_bone_count():
		sk.add_bone(sk0.get_bone_name(i))
	for i in sk0.get_bone_count():
		sk.set_bone_parent(i, sk0.get_bone_parent(i))
		sk.set_bone_rest(i, sk0.get_bone_rest(i))
	sk.reset_bone_poses()
	var mesh: Mesh = mi0.mesh
	var skin: Skin = mi0.skin # por nombre de hueso: sirve con cualquier copia del esqueleto
	var base_mat := mesh.surface_get_material(0)
	src.free()
	var tp := _template()
	var tsk: Skeleton3D = tp["sk"]
	var corr := _correccion(tsk, sk)
	var lib := AnimationLibrary.new()
	var tlib: AnimationLibrary = tp["lib"]
	for an in tlib.get_animation_list():
		lib.add_animation(an, _retarget(tsk, tlib.get_animation(an), sk, corr))
	var tex: Texture2D = (base_mat as StandardMaterial3D).albedo_texture if base_mat is StandardMaterial3D else null
	var mask: Texture2D = load(str(d["mascara"])) if d.has("mascara") and ResourceLoader.exists(str(d["mascara"])) else null
	return {
		"id": id + ":", "sk": sk, "lib": lib, "skin": skin, "mesh": mesh, "corr": corr,
		"skin_extra": sk.create_skin_from_rest_transforms(), "tex": tex, "mascara": mask,
		"luz_ref": float(d.get("luz_ref", 0.08)), "mats": {}, "mallas": {},
	}


## Pone el modelo en una figura recién creada (la malla, la piel y el material del equipo) y
## la pieza aparte para la herramienta y la carga.
static func _poner_modelo(st: Estado, md: Dictionary) -> void:
	if md.is_empty():
		return
	st.modelo = md
	st.mi.mesh = md["mesh"]
	st.mi.skin = md["skin"]
	st.mi.set_surface_override_material(0, _material_modelo(md, st.team))
	st.extra = MeshInstance3D.new()
	st.extra.skin = md["skin_extra"]
	st.node.add_child(st.extra)
	st.extra.set_instance_shader_parameter("tono", 1.0)
	st.tool = "-"


## La malla y la pieza aparte miran al mismo esqueleto (propio o compartido).
static func _apuntar(st: Estado, sk: Skeleton3D) -> void:
	st.mi.skeleton = st.mi.get_path_to(sk)
	if st.extra != null:
		st.extra.skeleton = st.extra.get_path_to(sk)


static func _material_modelo(md: Dictionary, team: Color) -> ShaderMaterial:
	var key := team.to_html()
	var mats: Dictionary = md["mats"]
	if not mats.has(key):
		var m := ShaderMaterial.new()
		m.shader = load("res://src/game/shaders/equipo_3d.gdshader")
		m.set_shader_parameter("textura", md["tex"])
		m.set_shader_parameter("mascara", md["mascara"])
		m.set_shader_parameter("equipo", team)
		m.set_shader_parameter("luz_ref", md["luz_ref"])
		mats[key] = m
	return mats[key]


## Herramienta y carga del modelo: las piezas de siempre (malla(), en el esqueleto de plantilla)
## llevadas al hueso del modelo «como en el reposo de la plantilla» (corrección × reposo), así
## reciben la misma rotación de la animación que en el juego (tools/rig_y_color.gd, _colgar).
static func malla_modelo(md: Dictionary, style: Dictionary, tool: String, carga: Color, per := {}) -> ArrayMesh:
	var key := "%s_%s_%s" % [tool, carga.to_html(), per.get("_key", "")]
	var cache: Dictionary = md["mallas"]
	if cache.has(key):
		return cache[key]
	var tsk: Skeleton3D = _template()["sk"]
	var sk: Skeleton3D = md["sk"]
	var c := colores(style, per)
	var parts: Array = []
	_herramienta(parts, tool, tsk, c["madera"], c["piedra"], c["fibra"], c["vest"])
	if carga.a > 0.0:
		var ch: Vector3 = _P(tsk, "chest")
		var bc := tsk.find_bone("chest")
		parts.append([_box(Vector3(0.15, 0.13, 0.1)), Transform3D(Basis.IDENTITY, ch + Vector3(0, 0.08, -0.11)), carga.darkened(0.15), bc])
		parts.append([_box(Vector3(0.012, 0.15, 0.13)), Transform3D(Basis.IDENTITY, ch + Vector3(0.06, 0.07, -0.05)), c["cuero"], bc, Pieza.MADERA])
	var mesh: ArrayMesh = null
	if not parts.is_empty():
		var corr: Dictionary = md["corr"]
		var s := _P(sk, "head").y / maxf(0.001, _P(tsk, "head").y)
		for p: Array in parts:
			var nm := tsk.get_bone_name(int(p[3]))
			var j := sk.find_bone(nm)
			if j < 0:
				j = sk.find_bone("chest")
			var g := sk.get_bone_global_rest(j)
			var ancla := _P(tsk, nm)
			var inv := Basis((corr.get(sk.get_bone_name(j), Quaternion()) as Quaternion) * g.basis.orthonormalized().get_rotation_quaternion()).inverse()
			var tf: Transform3D = p[1]
			p[1] = g * Transform3D(inv * tf.basis.scaled(Vector3.ONE * s), inv * ((tf.origin - ancla) * s))
			p[3] = j
		mesh = _skinned(parts)
	cache[key] = mesh
	return mesh


## Corrección de cada hueso del destino: la rotación que lleva su dirección en reposo (hacia el
## primer hijo) a la del mismo hueso en la plantilla. La muñeca se orienta por el brazo, no por
## el punto de la herramienta (handslot).
static func _correccion(src: Skeleton3D, dst: Skeleton3D) -> Dictionary:
	var out := {}
	for j in dst.get_bone_count():
		var c := Quaternion()
		var i := src.find_bone(dst.get_bone_name(j))
		if i >= 0:
			for h in dst.get_bone_children(j):
				var hi := src.find_bone(dst.get_bone_name(h))
				if hi < 0 or dst.get_bone_name(h).begins_with("handslot"):
					continue
				var dt := dst.get_bone_global_rest(h).origin - dst.get_bone_global_rest(j).origin
				var ds := src.get_bone_global_rest(hi).origin - src.get_bone_global_rest(i).origin
				if dt.length() > 0.0001 and ds.length() > 0.0001:
					c = Quaternion(dt.normalized(), ds.normalized())
				break
			if c == Quaternion() and dst.get_bone_parent(j) >= 0:
				c = out[dst.get_bone_name(dst.get_bone_parent(j))]
		out[dst.get_bone_name(j)] = c
	return out


static func _rq(b: Basis) -> Quaternion:
	return b.orthonormalized().get_rotation_quaternion()


## Una animación de la plantilla en el esqueleto del modelo (tools/visor_rig.gd): a 30 cuadros
## por segundo, la rotación global de cada hueso de la plantilla respecto de su reposo, aplicada
## al reposo corregido del hueso del modelo; la cadera, además, se mueve escalada a su altura.
static func _retarget(src: Skeleton3D, a: Animation, dst: Skeleton3D, corr: Dictionary) -> Animation:
	var out := Animation.new()
	out.length = a.length
	out.loop_mode = a.loop_mode
	var n := dst.get_bone_count()
	var ns := src.get_bone_count()
	var map: Array[int] = []
	var cq: Array[Quaternion] = []
	var dg: Array[Quaternion] = []
	for j in n:
		map.append(src.find_bone(dst.get_bone_name(j)))
		cq.append(corr[dst.get_bone_name(j)])
		dg.append(_rq(dst.get_bone_global_rest(j).basis))
	var sr: Array[int] = []
	var sp: Array[int] = []
	var sgi: Array[Quaternion] = []
	for i in ns:
		var np := NodePath("Skeleton3D:" + src.get_bone_name(i))
		sr.append(a.find_track(np, Animation.TYPE_ROTATION_3D))
		sp.append(a.find_track(np, Animation.TYPE_POSITION_3D))
		sgi.append(_rq(src.get_bone_global_rest(i).basis).inverse())
	var hips_s := src.find_bone("hips")
	var hips_d := dst.find_bone("hips")
	var k := dst.get_bone_global_rest(hips_d).origin.y / maxf(0.001, src.get_bone_global_rest(hips_s).origin.y) if hips_s >= 0 and hips_d >= 0 else 1.0
	var tr: Array[int] = []
	for j in n:
		var t := out.add_track(Animation.TYPE_ROTATION_3D)
		out.track_set_path(t, NodePath("Skeleton3D:" + dst.get_bone_name(j)))
		tr.append(t)
	var tp := out.add_track(Animation.TYPE_POSITION_3D)
	out.track_set_path(tp, NodePath("Skeleton3D:hips"))
	var frames := int(ceil(a.length * 30.0))
	for f in frames + 1:
		var t := minf(a.length, f / 30.0)
		var sg: Array[Transform3D] = []
		for i in ns:
			var rest := src.get_bone_rest(i)
			var q: Quaternion = a.rotation_track_interpolate(sr[i], t) if sr[i] >= 0 else rest.basis.get_rotation_quaternion()
			var o: Vector3 = a.position_track_interpolate(sp[i], t) if sp[i] >= 0 else rest.origin
			var loc := Transform3D(Basis(q), o)
			var par := src.get_bone_parent(i)
			sg.append(sg[par] * loc if par >= 0 else loc)
		var g: Array[Quaternion] = []
		for j in n:
			var i := map[j]
			var q: Quaternion
			var par := dst.get_bone_parent(j)
			if i >= 0:
				q = _rq(sg[i].basis) * sgi[i] * cq[j] * dg[j]
			else:
				q = (g[par] if par >= 0 else Quaternion()) * _rq(dst.get_bone_rest(j).basis)
			g.append(q)
			out.rotation_track_insert_key(tr[j], t, ((g[par].inverse() * q) if par >= 0 else q).normalized())
		if hips_s >= 0 and hips_d >= 0:
			var gpos := dst.get_bone_global_rest(hips_d).origin + (sg[hips_s].origin - src.get_bone_global_rest(hips_s).origin) * k
			var par := dst.get_bone_parent(hips_d)
			out.position_track_insert_key(tp, t, dst.get_bone_global_rest(par).affine_inverse() * gpos if par >= 0 else gpos)
	return out


# ---------------------------------------------------------------- Esqueletos compartidos

## Un esqueleto que mueven todas las figuras que hacen lo mismo, en la misma fase y al mismo
## paso: el costo depende de cuántas animaciones distintas hay en pantalla, no de cuántas
## figuras. Una malla con piel se dibuja donde está su MeshInstance3D, no donde está el
## esqueleto, así que cada figura sigue en su lugar.
##
## Los coros de una misma animación y un mismo paso forman un grupo con un reloj común; cada
## coro del grupo va corrido una fracción del ciclo (su fase). Para los golpes, cada figura toma
## el coro cuya fase está más cerca de su propio ciclo de ataque, así el golpe cae a tiempo.
class Coro:
	extends RefCounted
	var sk: Skeleton3D
	var ap: AnimationPlayer
	var anim := ""
	var q := 0 # paso (rate = paso_q ^ q)
	var rate := 1.0 # segundos de animación por segundo de juego
	var off := 0.0 # corrimiento respecto del reloj del grupo (s)
	var grupo := ""
	var largo := 1.0
	var usado := -1000 # último cuadro en que alguna figura lo usó

static var _coros := {}
static var _relojes := {} # grupo (animación|paso) -> [tiempo, rate, largo]
static var _raiz: Node3D
static var _cuadro := 0
static var _retener := 12 # cuadros que un esqueleto compartido sigue andando sin que nadie lo use
static var _fases_ataque := 6
static var _paso_q_caminar := 1.15
static var _ajuste_paso := 0.12
static var _paso_min := 0.5
static var n_coros_activos := 0


## WorldView le da un nodo donde colgar los esqueletos compartidos (uno por partida).
static func preparar_coros(parent: Node) -> void:
	if _raiz != null and is_instance_valid(_raiz) and _raiz.get_parent() == parent:
		return
	_coros.clear()
	_relojes.clear()
	_raiz = Node3D.new()
	_raiz.name = "EsqueletosCompartidos"
	parent.add_child(_raiz)


## Avanza los relojes y los esqueletos compartidos que se usaron hace poco (`dt`: tiempo de
## juego).
static func avanzar_coros(dt: float) -> void:
	_cuadro += 1
	var t0 := Time.get_ticks_usec()
	for g: Array in _relojes.values():
		g[0] = fposmod(float(g[0]) + dt * float(g[1]), float(g[2]))
	n_coros_activos = 0
	for c: Coro in _coros.values():
		if _cuadro - c.usado <= _retener:
			c.ap.advance(dt * c.rate)
			n_coros_activos += 1
	us_coros += Time.get_ticks_usec() - t0


## El coro de una animación a un paso, en la fase k de n. Si estuvo parado, se pone en hora con
## el reloj de su grupo.
static func _coro(anim: String, q: int, k: int, n: int, base := 0.0, md := {}) -> Coro:
	var key := "%s%s|%d|%d/%d" % [md.get("id", ""), anim, q, k, n]
	var c: Coro = _coros.get(key)
	if c == null:
		var tp := _template() if md.is_empty() else md
		c = Coro.new()
		# El AnimationPlayer busca "Skeleton3D:<hueso>" desde su root_node: cada coro cuelga de
		# un nodo propio, con el esqueleto y el reproductor adentro.
		var holder := Node3D.new()
		holder.name = "coro_%d" % _coros.size()
		_raiz.add_child(holder)
		c.sk = (tp["sk"] as Skeleton3D).duplicate()
		holder.add_child(c.sk)
		c.ap = AnimationPlayer.new()
		holder.add_child(c.ap)
		c.ap.root_node = NodePath("..")
		c.ap.add_animation_library("", tp["lib"])
		c.ap.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
		c.anim = anim
		c.q = q
		c.rate = pow(base if base > 0.0 else _paso_q, q)
		c.largo = float(_len.get(anim, 1.0))
		c.off = c.largo * float(k) / float(n)
		c.grupo = "%s|%d" % [anim, q]
		c.ap.play(anim)
		_coros[key] = c
	if _cuadro - c.usado > _retener:
		c.ap.seek(fposmod(float(_reloj(c.grupo, c.rate, c.largo)[0]) + c.off, c.largo), true)
	c.usado = _cuadro
	return c


static func _reloj(grupo: String, rate: float, largo: float) -> Array:
	if not _relojes.has(grupo):
		_relojes[grupo] = [0.0, rate, largo]
	return _relojes[grupo]


static func _q(rate: float, base := 0.0) -> int:
	return roundi(log(maxf(rate, 0.05)) / log(base if base > 0.0 else _paso_q))


## Coro para un estado que se repite (quieto, caminar, un trabajo): por paso, con un margen
## para no saltar de uno a otro, y por la fase de la figura.
static func _coro_lazo(st: Estado, anim: String, rate: float, caminar: bool) -> Coro:
	# Caminando con el paso de la simulación, pasos finos (todos los de la tropa van al mismo);
	# con el paso medido, gruesos (así no hay un esqueleto por cada velocidad).
	var base := _paso_q_caminar if caminar and not st.ajustado else _paso_q
	if caminar:
		rate = maxf(rate, _paso_min) # empujados en un montón: todos al mismo paso lento
	var q := _q(rate, base)
	if st.coro != null and st.coro.anim == anim and absi(st.coro.q - q) <= 1:
		q = st.coro.q
	return _coro(anim, q, st.fase, _fases, base, st.modelo)


## Coro para el golpe: el de la fase más cercana al ciclo de ataque de la figura.
static func _coro_golpe(st: Estado, anim: String, rate: float) -> Coro:
	var q := _q(rate)
	var largo := float(_len.get(anim, 1.0))
	var r := _reloj("%s|%d" % [anim, q], pow(_paso_q, q), largo)
	var k := posmod(roundi((st.atk_t - float(r[0])) / largo * _fases_ataque), _fases_ataque)
	return _coro(anim, q, k, _fases_ataque, 0.0, st.modelo)


# ---------------------------------------------------------------- Instancia

## Estado de una figura animada (una por unidad; WorldView lo guarda en visual["anim"]).
class Estado:
	extends RefCounted
	var node: Node3D
	var sk: Skeleton3D # propio; se arma recién cuando hace falta
	var mi: MeshInstance3D
	var ap: AnimationPlayer
	var coro: Coro # compartido (null si usa el propio)
	var en_propio := false # la malla apunta al esqueleto propio
	var k := 1.0 # alto en el mundo
	var style: Dictionary
	var team: Color
	var tropa := false
	var eq := {} # equipo del soldado (TropaAnimada.equipo)
	var per := {} # ropa del aldeano por sexo y edad (personas); vacío: la de la forma
	var modelo := {} # --- aldeanos de Meshy --- el modelo (modelo_de); vacío: la figura de KayKit
	var extra: MeshInstance3D # herramienta y carga del modelo de Meshy (piel aparte)
	var golpe_act := "pegar"
	var quieto_act := "quieto"
	var accion := ""
	var anim := ""
	var tool := "-"
	var carga := Color(0, 0, 0, 0)
	var acc_t := 0.0 # tiempo de animación pendiente (se aplica cuando le toca actualizarse)
	var walk_acc := 0.0 # distancia y tiempo juntados entre turnos (WorldView._render_anim)
	var dt_acc := 0.0
	var golpe := false
	var recibe := false
	var pend := ""
	var pend_t := 0.0
	var sps := 0.0 # pasos por segundo, suavizados
	var vel := 0.0 # velocidad en el mundo, suavizada
	var ajustado := false # el paso de la figura es el que manda la simulación
	var atk_t := 0.0 # reloj del ciclo de ataque (sigue aunque la animación sea otra)
	var hit_left := 0.0 # lo que falta de la reacción a un golpe
	var fase := 0
	var work_order := -1 # orden y blanco de los que salió la herramienta guardada
	var work_target := -2
	var work_tool := ""

	func sin_pose() -> bool:
		return not en_propio and coro == null


## Lo de data/arte_animaciones.json que se mira en cada cuadro, leído una vez.
static var _anim_of := {} # acción -> nombre de la animación
static var _tool_of := {} # acción -> herramienta
static var _vel_of := {} # acción -> factor de velocidad
static var _imp_of := {} # acción de ataque -> momento del golpe (s)
static var _por_recurso := {}
static var _por_clase := {}
static var _mezcla := 0.18
static var _cambio := 0.2
static var _correr := 99.0
static var _bloquear := 0.6
static var _len := {} # animación -> largo
const LOOPS := ["quieto", "caminar", "correr", "talar", "picar", "juntar", "cosechar", "carnear", "construir", "quieto_2m", "quieto_arco", "quieto_fuego"]


static func _prep() -> void:
	if not _anim_of.is_empty():
		return
	var c := cfg()
	for act: String in c.get("acciones", {}):
		var a: Dictionary = c["acciones"][act]
		var names: Array = a.get("anims", [])
		_anim_of[act] = "+".join(PackedStringArray(names)) if names.size() > 1 else str(a.get("anim", names[0] if names.size() == 1 else "Idle_A"))
		_tool_of[act] = str(a.get("herramienta", ""))
		_vel_of[act] = float(a.get("vel_pct", 100)) / 100.0
	_tool_of[""] = ""
	_por_recurso = c.get("por_recurso", {})
	_por_clase = c.get("por_clase", {})
	_mezcla = float(c.get("mezcla_s", 0.18))
	_cambio = float(c.get("cambio_s", 0.2))
	_correr = float(c.get("correr_desde_pasos", 99.0))
	_bloquear = float(c.get("reaccion", {}).get("bloquear_pct", 60)) / 100.0
	var lib: AnimationLibrary = _template()["lib"]
	for an in lib.get_animation_list():
		_len[String(an)] = lib.get_animation(an).length


## Momento del golpe de una acción de ataque (en segundos de su animación).
static func _imp(act: String) -> float:
	if not _imp_of.has(act):
		var a: Dictionary = cfg().get("acciones", {}).get(act, {})
		var an: String = _anim_of.get(act, "")
		if a.has("impacto_pct"):
			_imp_of[act] = float(a["impacto_pct"]) / 100.0 * float(_len.get(an, 1.0))
		else:
			_imp_of[act] = _impacto(an)
	return _imp_of[act]


## Cuerpo animado de una unidad: raíz con la malla (el esqueleto, propio o compartido, se le da
## en la primera actualización). `k`: alto en el mundo. Para un soldado: `civ`, `type`, `def` y
## `tropa` (el aspecto de la edad, data/arte_edades.json → tropa).
static func crear(style: Dictionary, team: Color, k: float, civ := "", type := "", def := {}, tropa := {}) -> Estado:
	var tp := _template()
	_prep()
	var st := Estado.new()
	st.node = Node3D.new()
	st.node.name = "AldeanoAnimado"
	st.mi = MeshInstance3D.new()
	st.mi.skin = tp["skin"]
	st.node.add_child(st.mi)
	st.k = k
	st.style = style
	st.team = team
	var fn: String = def.get("funcion", "civil")
	if fn == "comercio": # --- comercio --- la carga de su pueblo (tropas.por_civ.<civ>.comerciante.carga)
		st.eq = TropaAnimada.equipo(civ, str(style.get("forma", "")), type, fn)
		st.mi.mesh = malla(style, team, "", Color(0, 0, 0, 0))
	elif fn != "civil":
		st.tropa = true
		st.eq = TropaAnimada.equipo(civ, str(style.get("forma", "")), type, fn)
		st.golpe_act = str(st.eq.get("golpe", "golpe_1m"))
		st.quieto_act = str(st.eq.get("quieto", "quieto"))
		st.mi.mesh = TropaAnimada.malla(style, team, st.eq, tropa)
	else:
		st.mi.mesh = malla(style, team, "", Color(0, 0, 0, 0))
	var var_pct := float(cfg().get("aspecto", {}).get("variacion_pct", 7)) / 100.0
	st.mi.set_instance_shader_parameter("tono", 1.0 + randf_range(-var_pct, var_pct))
	st.acc_t = randf() * 2.0 # cada uno en otro momento del ciclo
	st.fase = randi() % _fases
	return st


## Cambia el equipo de un soldado (la edad nueva trae otro casco, otro escudo).
static func equipar(st: Estado, tropa: Dictionary) -> void:
	if st.tropa:
		st.mi.mesh = TropaAnimada.malla(st.style, st.team, st.eq, tropa)


## El esqueleto propio, armado la primera vez que hace falta. Si venía de uno compartido, sigue
## desde la misma pose.
static func _propio(st: Estado) -> void:
	if st.sk == null:
		var tp := _template() if st.modelo.is_empty() else st.modelo
		st.sk = (tp["sk"] as Skeleton3D).duplicate()
		st.node.add_child(st.sk)
		st.ap = AnimationPlayer.new()
		st.node.add_child(st.ap)
		st.ap.root_node = NodePath("..")
		st.ap.add_animation_library("", tp["lib"])
		st.ap.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
		n_propios += 1
	if not st.en_propio:
		st.en_propio = true
		var from := st.coro
		_apuntar(st, st.sk)
		st.coro = null
		if from != null and from.ap.current_animation != "":
			st.ap.play(from.ap.current_animation, 0.0)
			st.ap.seek(from.ap.current_animation_position, true)
			st.anim = from.ap.current_animation


## Qué hace la figura ahora (solo lectura de la simulación).
static func accion(e: SimEntity, sim: Sim, moving: bool, st: Estado = null) -> String:
	if moving:
		return "caminar"
	if st != null and st.tropa:
		return st.golpe_act if e.order == O.ATTACK else st.quieto_act
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


## Avanza la animación de una figura cuando le toca (presupuesto de rendimiento, WorldView).
## `walked`: distancia recorrida desde la última vez (mundo); `dt`: tiempo de juego desde la
## última vez (real × velocidad del juego; 0 en pausa); `golpe`: pegó o tiró en el medio;
## `recibe`: le pegaron; `lejos`: puede usar un esqueleto compartido.
static func actualizar(st: Estado, e: SimEntity, sim: Sim, moving: bool, walked: float, dt: float, golpe: bool, recibe := false, lejos := false) -> void:
	var act := accion(e, sim, moving, st)
	if not st.tropa:
		_herramienta_y_carga(st, e, sim, act)
	# Histéresis: en un montón las figuras se empujan y el "se mueve / está quieto" titila de un
	# tick a otro; el estado nuevo tiene que durar cambio_s antes de cambiar de animación.
	var cur := st.accion
	var base := "caminar" if cur == "correr" else cur
	var ataque := act == st.golpe_act
	if act != base and cur != "" and not (golpe and ataque):
		if act == st.pend:
			st.pend_t += dt
		else:
			st.pend = act
			st.pend_t = 0.0
		if st.pend_t < _cambio:
			act = base
			ataque = act == st.golpe_act
		else:
			st.pend = ""
	if dt > 0.0:
		st.vel = lerpf(st.vel, walked / dt, clampf(dt * 4.0, 0.0, 1.0))
	# Reloj del ataque: el ciclo dura la cadencia y cada golpe lo lleva al momento del impacto,
	# así el siguiente cae justo cuando la simulación pega.
	var rate := 1.0
	var anim_dt := dt
	if ataque:
		var alen := float(_len.get(_anim_of.get(act, ""), 1.0))
		var cad := maxf(0.2, float(e.def.get("cadencia_ms", 1000)) / 1000.0)
		rate = alen / cad
		st.atk_t = fposmod(st.atk_t + dt * rate, alen)
		if golpe:
			st.atk_t = _imp(act)
		anim_dt = dt * rate
	# Reacción a un golpe recibido: si no camina y, si está peleando, si le da el tiempo antes de
	# su propio golpe.
	if st.hit_left > 0.0:
		st.hit_left -= dt
	elif recibe and not moving and not (lejos and compartir) and _puede_reaccionar(st, act, ataque, rate):
		var r := "bloquear" if str(st.eq.get("escudo", "ninguno")) != "ninguno" and randf() < _bloquear else "golpeado"
		var rn: String = _anim_of.get(r, "Hit_A")
		if _len.has(rn):
			_propio(st)
			st.ap.play(rn, 0.06)
			n_play += 1
			st.anim = rn
			st.hit_left = float(_len[rn])
			st.accion = act
			return
	if st.hit_left > 0.0:
		_avanzar(st, dt)
		return
	var name: String = _anim_of.get(act, "Idle_A")
	if act == "caminar":
		# El paso sigue a la distancia: tiempo de animación = distancia / velocidad de la animación.
		var paso: Dictionary = _tpl["paso"]
		var v: float = float(paso["v"]) * st.k
		if dt > 0.0:
			# Pasos por segundo (dos por ciclo), suavizados; trote por encima del umbral, con margen.
			var sps := (walked / dt) / v * 2.0 / float(paso["largo"])
			st.sps = lerpf(st.sps, sps, clampf(dt * 4.0, 0.0, 1.0))
		if st.sps > (_correr * 0.85 if cur == "correr" else _correr) and _anim_of.has("correr"):
			act = "correr"
			name = _anim_of["correr"]
			paso = _tpl["paso_correr"]
			v = float(paso["v"]) * st.k
		anim_dt = walked / v
		var esperado := _paso_esperado(e, sim, st.vel)
		st.ajustado = esperado != st.vel
		rate = esperado / v
	elif not ataque:
		rate = float(_vel_of.get(act, 1.0))
		anim_dt = dt * rate
	if not _len.has(name):
		name = "Idle_A"
	# Esqueleto compartido: lejos de la cámara (o con mucha gente en pantalla), en los estados
	# que se repiten igual en todos y en el golpe (por la fase del ataque).
	if lejos and compartir and (ataque or act in LOOPS):
		var c := _coro_golpe(st, name, rate) if ataque else _coro_lazo(st, name, rate, act == "caminar" or act == "correr")
		if st.coro != c:
			st.coro = c
			st.en_propio = false
			_apuntar(st, c.sk)
		st.accion = act
		st.anim = name
		st.acc_t = 0.0
		return
	_propio(st)
	if act != cur or name != st.anim or (golpe and ataque):
		st.accion = act
		if ataque:
			if st.anim != name:
				st.ap.play(name, _mezcla if cur != "" else 0.0)
				n_play += 1
			st.ap.seek(st.atk_t, false)
			anim_dt = 0.0
		elif name != st.anim:
			st.ap.play(name, _mezcla if cur != "" else 0.0)
			n_play += 1
		st.anim = name
	st.acc_t += anim_dt
	_avanzar(st, st.acc_t)
	st.acc_t = 0.0


## La velocidad a la que camina la figura, para elegir el esqueleto compartido: si la medida
## está cerca de la que manda la simulación (la del grupo en marcha, o la propia), esa; así una
## tropa en marcha comparte uno solo. Si no (empujado, arrancando), la medida.
static func _paso_esperado(e: SimEntity, sim: Sim, vel: float) -> float:
	var spd := e.speed
	if e.group >= 0 and sim.groups.groups.has(e.group):
		spd = int(sim.groups.groups[e.group].get("spd", spd))
	var esperado := float(spd) / float(maxi(1, sim.tick_ms)) # casillas (mundo) por segundo de juego
	if esperado > 0.0 and absf(vel - esperado) <= esperado * _ajuste_paso:
		return esperado
	return vel


static func _avanzar(st: Estado, t: float) -> void:
	var t0 := Time.get_ticks_usec()
	st.ap.advance(t)
	us_avance += Time.get_ticks_usec() - t0


static func _puede_reaccionar(st: Estado, act: String, ataque: bool, rate: float) -> bool:
	if not ataque:
		return act != "caminar" and act != "correr"
	var alen := float(_len.get(_anim_of.get(act, ""), 1.0))
	var falta := fposmod(_imp(act) - st.atk_t, alen) / maxf(0.01, rate)
	return falta > 0.75


## Herramienta del aldeano: la del trabajo; caminando o quieto, la del trabajo al que va o del
## que vuelve. Y el atado a la espalda del color del recurso que carga.
static func _herramienta_y_carga(st: Estado, e: SimEntity, sim: Sim, act: String) -> void:
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
	if st.per.has("herramientas"): # --- aldeanos por retrato --- las herramientas de su retrato
		var hs: Dictionary = st.per["herramientas"]
		if hs.has(act):
			tool = hs[act]
		elif tool == "" and act == "quieto":
			tool = hs.get("quieto", "")
		else:
			for w: String in hs:
				if w != "quieto" and _tool_of.get(w, "") == tool and tool != "":
					tool = hs[w] # caminando al trabajo, la herramienta propia de ese trabajo
					break
	var carga := Color(0, 0, 0, 0)
	if e.carry > 0:
		carga = Palette.RES.get(e.carry_res, Color.WHITE)
	var forma := ""
	if e.def.get("comerciante", false): # --- comercio --- vacío a la ida, cargado a la vuelta
		tool = ""
		forma = str(st.eq.get("carga", "fardo"))
		carga = Color(str(CARGAS.get(forma, "8a6a44"))) if e.trade_gain > 0 else Color(0, 0, 0, 0)
	if tool != st.tool or carga != st.carga:
		st.tool = tool
		st.carga = carga
		if not st.modelo.is_empty(): # --- aldeanos de Meshy ---
			st.extra.mesh = malla_modelo(st.modelo, st.style, tool, carga, st.per)
		else:
			st.mi.mesh = malla(st.style, st.team, tool, carga, forma, st.per)
		n_malla += 1


## Muerte: la animación de caer (una de dos), con el esqueleto propio; sigue avanzando desde
## los efectos (WorldView._render_fx). Devuelve el reproductor.
static func morir(st: Estado) -> AnimationPlayer:
	_propio(st)
	var an: String = _anim_of.get("morir_b" if st.tropa and st.fase % 2 == 1 else "morir", "Death_A")
	if _len.has(an):
		st.ap.play(an, 0.08)
	return st.ap
