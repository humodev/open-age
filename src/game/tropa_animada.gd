class_name TropaAnimada
extends RefCounted
## Equipo de los soldados a pie animados (proceso/27-animaciones/02-soldados.md): el arma en la
## mano derecha (hueso handslot.r), el escudo o el arco en la izquierda (handslot.l), el casco,
## el pectoral y la tela de la edad (data/arte_edades.json → tropa), sobre el mismo cuerpo que
## el aldeano (AldeanoAnimado.cuerpo). Qué arma lleva cada uno: data/arte_animaciones.json →
## tropas. Solo imagen.


static var _meshes := {}


## El equipo de un tipo de soldado: el de su tipo (o el de su función), con lo propio de la
## forma del pueblo y de cada pueblo encima.
static func equipo(civ: String, forma: String, type: String, fn: String) -> Dictionary:
	var tr: Dictionary = AldeanoAnimado.cfg().get("tropas", {})
	var tipos: Dictionary = tr.get("tipos", {})
	var eq: Dictionary = (tipos.get(type, tipos.get("_" + fn, {})) as Dictionary).duplicate()
	eq.merge(tr.get("por_forma", {}).get(forma, {}).get(type, {}), true)
	eq.merge(tr.get("por_civ", {}).get(civ, {}).get(type, {}), true)
	return eq


## Malla con piel de un soldado: cuerpo del pueblo con la tela de la edad, casco, pectoral,
## arma y escudo. Se arma una vez por combinación.
static func malla(style: Dictionary, team: Color, eq: Dictionary, tropa: Dictionary) -> ArrayMesh:
	var forma: String = style.get("forma", "")
	var key := "%s_%s_%s_%s_%s" % [forma, style.get("arcilla", ""), team.to_html(), str(eq).hash(), str(tropa).hash()]
	if _meshes.has(key):
		return _meshes[key]
	var sk: Skeleton3D = AldeanoAnimado._template()["sk"]
	var c := AldeanoAnimado.colores(style)
	var vest: Dictionary = c["vest"]
	var oscurecer := float(AldeanoAnimado.cfg().get("aspecto", {}).get("tela_tropa_pct", 18)) / 100.0
	var tela: Color = Color(tropa["tela"]).darkened(oscurecer) if tropa.has("tela") else c["tela"]
	if eq.has("tela"): # --- paso 6, par 3 --- el color propio de la unidad en su pueblo
		tela = Color(eq["tela"])
	var prenda := str(vest.get("prenda", "ninguna"))
	var prenda_col := Color(vest.get("prenda_color", tela.to_html()))
	if prenda == "poncho" and tropa.has("tela"):
		prenda_col = tela # el poncho mapuche toma el color de la edad, como en la maqueta
	var parts: Array = []
	var casco := tropa.has("casco")
	AldeanoAnimado.cuerpo(parts, sk, c, team, tela, prenda, prenda_col, not casco)
	var head := AldeanoAnimado._P(sk, "head")
	var hb := sk.find_bone("head")
	if casco:
		parts.append([AldeanoAnimado._sphere(0.077, 10), Transform3D(Basis.from_scale(Vector3(1.0, 0.68, 1.04)), head + Vector3(0, 0.112, -0.006)), Color(tropa["casco"]), hb, AldeanoAnimado.Pieza.METAL])
		parts.append([AldeanoAnimado._cyl(0.08, 0.08, 0.016, 12), Transform3D(Basis.IDENTITY, head + Vector3(0, 0.098, -0.004)), Color(tropa["casco"]).darkened(0.25), hb, AldeanoAnimado.Pieza.METAL])
	if tropa.get("oro", false):
		var ch := AldeanoAnimado._P(sk, "chest")
		parts.append([AldeanoAnimado._cyl(0.04, 0.04, 0.012, 10), Transform3D(Basis(Vector3.RIGHT, PI / 2), ch + Vector3(0, 0.08, 0.072)), Palette.WEALTH, sk.find_bone("chest"), AldeanoAnimado.Pieza.METAL])
	if eq.has("tocado") and not casco: # --- paso 6, par 3 --- el tocado propio de la unidad en su pueblo
		_tocado(parts, str(eq["tocado"]), Color(eq.get("tocado_color", "#a63a2a")), head, hb)
	var largo := float(eq.get("largo_pct", 100)) / 100.0
	_arma(parts, str(eq.get("arma", "maza")), sk, c, largo)
	var esc := str(eq.get("escudo", "ninguno"))
	if esc != "ninguno":
		_escudo(parts, esc, sk, team, Color(tropa.get("escudo_borde", (c["cuero"] as Color).to_html())), c)
	if eq.get("carcaj", false):
		_carcaj(parts, sk, c)
	var mesh := AldeanoAnimado._skinned(parts)
	_meshes[key] = mesh
	return mesh


## --- soldados de Meshy (proceso/62) --- Solo el arma, el escudo (centro del color del equipo) y
## el carcaj, armados en la plantilla y llevados al esqueleto del modelo (AldeanoAnimado.llevar).
## La ropa, el tocado y el casco ya vienen en el modelo.
static func malla_modelo(md: Dictionary, style: Dictionary, team: Color, eq: Dictionary) -> ArrayMesh:
	var key := "tropa_%s_%s_%s" % [team.to_html(), str(eq).hash(), style.get("forma", "")]
	var cache: Dictionary = md["mallas"]
	if cache.has(key):
		return cache[key]
	var sk: Skeleton3D = AldeanoAnimado._template()["sk"]
	var c := AldeanoAnimado.colores(style)
	var parts: Array = []
	_arma(parts, str(eq.get("arma", "maza")), sk, c, float(eq.get("largo_pct", 100)) / 100.0)
	var esc := str(eq.get("escudo", "ninguno"))
	if esc != "ninguno":
		_escudo(parts, esc, sk, team, c["cuero"], c)
	if eq.get("carcaj", false):
		_carcaj(parts, sk, c)
	var mesh := AldeanoAnimado.llevar(md, parts)
	cache[key] = mesh
	return mesh


## Arma en la mano derecha. Como las de KayKit Adventurers: el mango por el +y del hueso
## handslot.r, desde el puño, y el filo hacia +x. El arco va en la izquierda.
## --- paso 6, par 3 --- Tocado propio (data/arte_animaciones.json → tropas.por_civ): «llawtu» (la
## banda andina), «lomphok» (el gorro alto siamés) o «pano» (paño atado a la cabeza).
static func _tocado(parts: Array, kind: String, col: Color, head: Vector3, hb: int) -> void:
	var T := AldeanoAnimado.Pieza.TELA
	match kind:
		"llawtu":
			parts.append([AldeanoAnimado._cyl(0.082, 0.082, 0.028, 12), Transform3D(Basis.IDENTITY, head + Vector3(0, 0.07, -0.004)), col, hb, T])
		"lomphok":
			parts.append([AldeanoAnimado._cyl(0.0, 0.07, 0.17, 10), Transform3D(Basis.IDENTITY, head + Vector3(0, 0.19, -0.004)), col, hb, T])
		"pano":
			parts.append([AldeanoAnimado._sphere(0.08, 10), Transform3D(Basis.from_scale(Vector3(1.05, 0.6, 1.08)), head + Vector3(0, 0.1, -0.008)), col, hb, T])


static func _arma(parts: Array, arma: String, sk: Skeleton3D, c: Dictionary, largo: float) -> void:
	var slot := sk.find_bone("handslot.r")
	var g := sk.get_bone_global_rest(slot)
	var X := func(pos: Vector3, b := Basis.IDENTITY) -> Transform3D: return g * Transform3D(b, pos)
	var wood: Color = c["madera"]
	var dark: Color = (c["madera"] as Color).darkened(0.35)
	var stone: Color = c["piedra"]
	var metal: Color = c["metal"]
	var cuerda: Color = c["cuerda"]
	var M := AldeanoAnimado.Pieza.MADERA
	match arma:
		"maza": # porra de mango de madera y cabeza de piedra
			parts.append([AldeanoAnimado._cyl(0.012, 0.014, 0.42), X.call(Vector3(0, 0.12, 0)), wood, slot, M])
			parts.append([AldeanoAnimado._sphere(0.042), X.call(Vector3(0, 0.33, 0)), stone, slot, AldeanoAnimado.Pieza.METAL])
		"macana": # garrote plano de madera dura, a dos manos
			parts.append([AldeanoAnimado._cyl(0.013, 0.015, 0.34), X.call(Vector3(0, 0.08, 0)), dark, slot, M])
			parts.append([AldeanoAnimado._box(Vector3(0.075, 0.36, 0.022)), X.call(Vector3(0.01, 0.42, 0)), dark, slot, M])
		"hacha":
			parts.append([AldeanoAnimado._cyl(0.012, 0.013, 0.46), X.call(Vector3(0, 0.13, 0)), wood, slot, M])
			parts.append([AldeanoAnimado._box(Vector3(0.11, 0.1, 0.018)), X.call(Vector3(0.05, 0.32, 0)), stone, slot, AldeanoAnimado.Pieza.METAL])
		"lanza": # asta que sale atrás del puño y punta de piedra o metal
			var L := 1.05 * largo
			parts.append([AldeanoAnimado._cyl(0.01, 0.011, L), X.call(Vector3(0, L * 0.5 - 0.3, 0)), wood, slot, M])
			parts.append([AldeanoAnimado._cyl(0.0, 0.022, 0.1, 6), X.call(Vector3(0, L - 0.25, 0)), metal, slot, AldeanoAnimado.Pieza.METAL])
		"espada", "katana":
			var hoja := 0.42 if arma == "katana" else 0.34
			parts.append([AldeanoAnimado._cyl(0.012, 0.012, 0.1), X.call(Vector3(0, 0.0, 0)), c["cuero"], slot, M])
			if arma == "espada":
				parts.append([AldeanoAnimado._box(Vector3(0.1, 0.014, 0.02)), X.call(Vector3(0, 0.055, 0)), metal, slot, AldeanoAnimado.Pieza.METAL])
			parts.append([AldeanoAnimado._box(Vector3(0.032, hoja, 0.007)), X.call(Vector3(0, 0.06 + hoja * 0.5, 0)), metal, slot, AldeanoAnimado.Pieza.METAL])
		"dap": # una espada recta en cada mano
			_arma(parts, "espada", sk, c, largo)
			var sl := sk.find_bone("handslot.l")
			var gl := sk.get_bone_global_rest(sl)
			parts.append([AldeanoAnimado._cyl(0.012, 0.012, 0.1), gl * Transform3D(Basis.IDENTITY, Vector3(0, 0.0, 0)), c["cuero"], sl, M])
			parts.append([AldeanoAnimado._box(Vector3(0.032, 0.3, 0.007)), gl * Transform3D(Basis.IDENTITY, Vector3(0, 0.21, 0)), metal, sl, AldeanoAnimado.Pieza.METAL])
		"guja": # --- paso 6, par 3 --- ngao: asta con hoja curva de un filo
			var L := 1.05 * largo
			parts.append([AldeanoAnimado._cyl(0.01, 0.011, L), X.call(Vector3(0, L * 0.5 - 0.3, 0)), dark, slot, M])
			parts.append([AldeanoAnimado._box(Vector3(0.05, 0.2, 0.01)), X.call(Vector3(0.02, L - 0.2, 0), Basis(Vector3.FORWARD, -0.25)), metal, slot, AldeanoAnimado.Pieza.METAL])
		"galga": # --- paso 6, par 3 --- galgueros: la piedra que se suelta ladera abajo
			parts.append([AldeanoAnimado._sphere(0.07, 8), X.call(Vector3(0, 0.02, 0.04)), stone, slot, AldeanoAnimado.Pieza.METAL])
		"honda": # cuerda que cuelga del puño con la piedra en la bolsa
			parts.append([AldeanoAnimado._cyl(0.004, 0.004, 0.26, 4), X.call(Vector3(0, -0.13, 0)), cuerda, slot])
			parts.append([AldeanoAnimado._sphere(0.026, 6), X.call(Vector3(0, -0.27, 0)), stone, slot, AldeanoAnimado.Pieza.METAL])
		"jabalina":
			parts.append([AldeanoAnimado._cyl(0.008, 0.009, 0.8), X.call(Vector3(0, 0.15, 0)), wood, slot, M])
			parts.append([AldeanoAnimado._cyl(0.0, 0.016, 0.07, 6), X.call(Vector3(0, 0.58, 0)), metal, slot, AldeanoAnimado.Pieza.METAL])
		"estolica": # propulsor de madera con el dardo encima
			parts.append([AldeanoAnimado._box(Vector3(0.02, 0.32, 0.012)), X.call(Vector3(0, 0.12, 0)), dark, slot, M])
			parts.append([AldeanoAnimado._cyl(0.006, 0.006, 0.7), X.call(Vector3(0.018, 0.2, 0)), wood, slot, M])
		"boleadoras": # tres piedras atadas
			for i in 3:
				var a := float(i) * TAU / 3.0
				var p := Vector3(cos(a) * 0.05, -0.2, sin(a) * 0.05)
				parts.append([AldeanoAnimado._cyl(0.003, 0.003, 0.2, 4), X.call(p * 0.5 + Vector3(0, -0.0, 0)), cuerda, slot])
				parts.append([AldeanoAnimado._sphere(0.022, 6), X.call(p), stone, slot, AldeanoAnimado.Pieza.METAL])
		"arco":
			_arco(parts, sk, c)
		"ballesta", "arcabuz":
			_tiro(parts, arma, sk, c)
		"antorcha":
			parts.append([AldeanoAnimado._cyl(0.012, 0.014, 0.36), X.call(Vector3(0, 0.1, 0)), wood, slot, M])
			parts.append([AldeanoAnimado._sphere(0.045, 6), X.call(Vector3(0, 0.3, 0), Basis.from_scale(Vector3(1, 1.5, 1))), Color("d8641e"), slot, AldeanoAnimado.Pieza.PIEL])
			parts.append([AldeanoAnimado._sphere(0.025, 6), X.call(Vector3(0, 0.34, 0)), Color("f2c14a"), slot, AldeanoAnimado.Pieza.PIEL])
		"vara":
			parts.append([AldeanoAnimado._cyl(0.01, 0.011, 0.95), X.call(Vector3(0, 0.15, 0)), wood, slot, M])


## Arco en la mano izquierda (handslot.l). Con el arco tenso, el +z del hueso apunta arriba y
## el +x, hacia el arquero: las palas van por ±z y se curvan hacia +x, donde va la cuerda.
static func _arco(parts: Array, sk: Skeleton3D, c: Dictionary) -> void:
	var slot := sk.find_bone("handslot.l")
	var g := sk.get_bone_global_rest(slot)
	var wood: Color = (c["madera"] as Color).darkened(0.2)
	var curva := float(AldeanoAnimado.cfg().get("tropas", {}).get("arco_curva", 0.07))
	var L := 0.42
	for s in [1.0, -1.0]:
		for i in 3:
			var z0 := float(i) / 3.0
			var z1 := float(i + 1) / 3.0
			var a := Vector3(curva * z0 * z0, 0, s * z0 * L)
			var b := Vector3(curva * z1 * z1, 0, s * z1 * L)
			var seg := AldeanoAnimado._seg(a, b, 0.012 - i * 0.002, 0.01 - i * 0.002, wood, slot, AldeanoAnimado.Pieza.MADERA)
			seg[1] = g * (seg[1] as Transform3D)
			parts.append(seg)
	var cu := AldeanoAnimado._seg(Vector3(curva, 0, L), Vector3(curva, 0, -L), 0.0025, 0.0025, c["cuerda"], slot)
	cu[1] = g * (cu[1] as Transform3D)
	parts.append(cu)


## Ballesta o arcabuz, a dos manos, en la mano derecha (handslot.r): el caño va de la mano
## derecha hacia la izquierda tal como quedan al apuntar (Ranged_2H_Aiming), medido en la
## animación, así las dos manos quedan sobre el arma.
static func _tiro(parts: Array, arma: String, sk: Skeleton3D, c: Dictionary) -> void:
	var slot := sk.find_bone("handslot.r")
	var g := sk.get_bone_global_rest(slot)
	var d := _apunte(sk)
	var y := d.normalized()
	var x := y.cross(Vector3.BACK if absf(y.dot(Vector3.BACK)) < 0.9 else Vector3.RIGHT).normalized()
	var b := Basis(x, y, x.cross(y))
	var X := func(pos: float, size: Vector3) -> Transform3D: return g * Transform3D(b, y * pos)
	var wood: Color = c["madera"]
	if arma == "arcabuz":
		parts.append([AldeanoAnimado._box(Vector3(0.022, 0.26, 0.032)), X.call(0.02, Vector3.ZERO), wood, slot, AldeanoAnimado.Pieza.MADERA])
		parts.append([AldeanoAnimado._cyl(0.009, 0.009, 0.5, 6), X.call(0.36, Vector3.ZERO), Color("3e3a36"), slot, AldeanoAnimado.Pieza.METAL])
	else:
		parts.append([AldeanoAnimado._box(Vector3(0.024, 0.36, 0.034)), X.call(0.1, Vector3.ZERO), wood, slot, AldeanoAnimado.Pieza.MADERA])
		parts.append([AldeanoAnimado._box(Vector3(0.4, 0.022, 0.022)), g * Transform3D(Basis(x.cross(y), y, -x), y * 0.3), (c["madera"] as Color).darkened(0.3), slot, AldeanoAnimado.Pieza.MADERA])


static var _apunte_dir := Vector3.ZERO


## Dirección de la mano derecha a la izquierda al apuntar, en el espacio de handslot.r.
static func _apunte(sk: Skeleton3D) -> Vector3:
	if _apunte_dir != Vector3.ZERO:
		return _apunte_dir
	_apunte_dir = Vector3.UP
	var lib: AnimationLibrary = AldeanoAnimado._template()["lib"]
	var an := str(AldeanoAnimado.cfg().get("acciones", {}).get("quieto_fuego", {}).get("anim", "Ranged_2H_Aiming"))
	if lib.has_animation(an):
		var a := lib.get_animation(an)
		var t := a.length * 0.5
		var gr := AldeanoAnimado._pose_en(sk, a, AldeanoAnimado._cadena(sk, "handslot.r"), t)
		var gl := AldeanoAnimado._pose_en(sk, a, AldeanoAnimado._cadena(sk, "handslot.l"), t)
		_apunte_dir = (gr.basis.orthonormalized().inverse() * (gl.origin - gr.origin)).normalized()
	return _apunte_dir


## Escudo en el antebrazo izquierdo (handslot.l): la cara mira por el +z del hueso, como el
## escudo redondo del Bárbaro de KayKit Adventurers. Centro del color del equipo, borde de la
## edad (o de cuero).
static func _escudo(parts: Array, kind: String, sk: Skeleton3D, team: Color, borde: Color, c: Dictionary) -> void:
	var slot := sk.find_bone("handslot.l")
	var g := sk.get_bone_global_rest(slot)
	var cara := Basis(Vector3.RIGHT, PI / 2) # el eje del cilindro, hacia +z
	var z := float(AldeanoAnimado.cfg().get("tropas", {}).get("escudo_z", 0.06))
	if kind == "cuadrado":
		parts.append([AldeanoAnimado._box(Vector3(0.25, 0.25, 0.014)), g * Transform3D(Basis.IDENTITY, Vector3(0, 0.02, z)), borde, slot, AldeanoAnimado.Pieza.MADERA])
		parts.append([AldeanoAnimado._box(Vector3(0.2, 0.2, 0.01)), g * Transform3D(Basis.IDENTITY, Vector3(0, 0.02, z + 0.008)), team.darkened(0.15), slot])
	else:
		parts.append([AldeanoAnimado._cyl(0.14, 0.14, 0.016, 14), g * Transform3D(cara, Vector3(0, 0.02, z)), borde, slot, AldeanoAnimado.Pieza.MADERA])
		parts.append([AldeanoAnimado._cyl(0.115, 0.115, 0.012, 14), g * Transform3D(cara, Vector3(0, 0.02, z + 0.008)), team.darkened(0.15), slot])
		parts.append([AldeanoAnimado._sphere(0.025, 6), g * Transform3D(Basis.from_scale(Vector3(1, 1, 0.6)), Vector3(0, 0.02, z + 0.016)), c["metal"], slot, AldeanoAnimado.Pieza.METAL])


## Carcaj a la espalda, con las plumas de las flechas.
static func _carcaj(parts: Array, sk: Skeleton3D, c: Dictionary) -> void:
	var b := sk.find_bone("chest")
	var ch := AldeanoAnimado._P(sk, "chest")
	var inc := Basis(Vector3.BACK, deg_to_rad(-20))
	parts.append([AldeanoAnimado._cyl(0.032, 0.028, 0.28, 8), Transform3D(inc, ch + Vector3(0.04, 0.06, -0.085)), c["cuero"], b, AldeanoAnimado.Pieza.MADERA])
	parts.append([AldeanoAnimado._cyl(0.03, 0.0, 0.05, 6), Transform3D(inc, ch + Vector3(-0.01, 0.22, -0.085)), Color("c9bfa8"), b, AldeanoAnimado.Pieza.PIEL])
