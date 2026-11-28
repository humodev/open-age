class_name Recintos
extends RefCounted
## Recintos compuestos (proceso/65-recintos-locales): los edificios con patio, muro en anillo o
## varias piezas que el pipeline 3D cierra en barriles o cajas se arman en el juego por partes:
##   1. el cerco (pirca, piedra fina, adobe, ladrillo encalado o empalizada) siguiendo la huella,
##      recto, curvo o poligonal, con su puerta; uno o varios anillos, en terrazas o sobre un cerro;
##   2. de una a seis piezas GLB del pipeline local (casas, salas, depósitos) puestas en el patio;
##   3. el suelo (patio y tierra pisada) y la utilería (puestos, pilas, troncos, lanzas, vasijas).
## Todo sale de data/arte_recintos.json. En data/civs/<pueblo>.json → estilo.modelos, el renglón
## "<tipo>": "recinto/<clave>" lo activa; borrarlo vuelve a la maqueta.
##
## El color del equipo va en una faja sobre el muro y en los paños de la puerta (y en lo que el
## dato marque "equipo"); lo sagrado no lleva color: el cerco va sin faja y las piezas con
## "equipo": false (o con un color fijo, "equipo": "#rrggbb", para las telas rojas de su textura).
##
## Los muros son mallas procedurales con color por vértice, una por recinto y tamaño (en caché);
## cada material de muro es una función (`_tramo`), así que se puede cambiar por las piezas
## modulares de muralla cuando existan sin tocar los datos.
## Convención: puerta en +z, como los GLB (WorldView les da media vuelta hacia la cámara).

static var _datos := {}
static var _mallas := {} # "<clave>_<tamaño en cm>" -> {base: ArrayMesh, equipo: ArrayMesh, suelo: ArrayMesh}
static var _mat_base: StandardMaterial3D
static var _mat_suelo: StandardMaterial3D


static func datos() -> Dictionary:
	if _datos.is_empty():
		var raw: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/arte_recintos.json"))
		_datos = raw if raw is Dictionary else {"_vacio": true}
	return _datos


static func es_recinto(nombre: String) -> bool:
	return nombre.begins_with("recinto/")


static func existe(nombre: String) -> bool:
	return (datos().get("recintos", {}) as Dictionary).has(nombre.trim_prefix("recinto/"))


## El recinto armado a `size` casillas (el cuerpo del edificio, el lado menor de la huella menos
## el margen), con el color `team`. Null si la clave no está en los datos.
static func armar(nombre: String, size: float, team: Color) -> Node3D:
	var clave := nombre.trim_prefix("recinto/")
	var cfg: Dictionary = (datos().get("recintos", {}) as Dictionary).get(clave, {})
	if cfg.is_empty():
		return null
	var key := "%s_%d" % [clave, roundi(size * 100.0)]
	if not _mallas.has(key):
		_mallas[key] = _construir(cfg, size)
	var m: Dictionary = _mallas[key]
	var holder := Node3D.new()
	holder.set_meta("recinto", clave)
	holder.position.y = -0.02
	var base := MeshInstance3D.new()
	base.mesh = m["base"]
	holder.add_child(base)
	if m["equipo"] != null:
		var eq := MeshInstance3D.new()
		eq.mesh = m["equipo"]
		eq.material_override = _mat_equipo(team)
		holder.add_child(eq)
	if m["suelo"] != null:
		var sl := MeshInstance3D.new()
		sl.mesh = m["suelo"]
		sl.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		holder.add_child(sl)
	var suelo_y: Callable = m["alto_en"]
	for pz: Dictionary in cfg.get("piezas", []):
		var n := _pieza(pz, size, team, suelo_y)
		if n != null:
			holder.add_child(n)
	return holder


static var _mats_equipo := {}


static func _mat_equipo(team: Color) -> StandardMaterial3D:
	var k := team.to_html()
	if not _mats_equipo.has(k):
		var m := StandardMaterial3D.new()
		m.albedo_color = team
		m.vertex_color_use_as_albedo = true
		m.roughness = 0.9
		m.metallic_specular = 0.2
		_mats_equipo[k] = m
	return _mats_equipo[k]


## Una pieza GLB del pipeline local, escalada a `lado` × size en su lado horizontal mayor.
static func _pieza(pz: Dictionary, size: float, team: Color, suelo_y: Callable) -> Node3D:
	var nombre := str(pz.get("modelo", ""))
	var eq: Variant = pz.get("equipo", true)
	var color := team
	var con_equipo := true
	if eq is bool:
		con_equipo = eq
	elif eq is String:
		color = Color(eq)
	var lado := float(pz.get("lado", 0.3)) * size
	var n := WorldView.glb_edificio(nombre, lado, color, con_equipo)
	if n == null:
		return null
	var x := float(pz.get("x", 0.0)) * size
	var z := float(pz.get("z", 0.0)) * size
	var y := float(suelo_y.call(x, z)) + float(pz.get("y_cm", 0)) / 100.0
	n.position += Vector3(x, y, z)
	var giro: Variant = pz.get("giro", 0)
	if giro is String and giro == "centro":
		n.rotation.y = atan2(-x, -z) if Vector2(x, z).length() > 0.01 else 0.0
	else:
		n.rotation.y = deg_to_rad(float(giro))
	var esc: Array = pz.get("escala", [1, 1, 1])
	var alto := float(pz.get("alto", 1.0))
	n.scale = Vector3(float(esc[0]), float(esc[1]) * alto, float(esc[2]))
	if pz.has("tinte"): # proceso/66: la misma pieza con otro material (ladrillo holandés, piedra gris francesa)
		WorldView._tint(n, Color(str(pz["tinte"])))
	return n


# ------------------------------------------------------------------ Construcción

## Arma las tres mallas de un recinto: base (color por vértice), equipo y suelo.
static func _construir(cfg: Dictionary, size: float) -> Dictionary:
	var b := _Obra.new()
	var monte: Dictionary = cfg.get("monte", {})
	var alto_en := func(x: float, z: float) -> float: return 0.0
	if not monte.is_empty():
		alto_en = _monte(b, monte, size)
	b.alto_en = alto_en
	var suelo := _Obra.new()
	for s: Dictionary in cfg.get("suelos", []):
		_suelo(suelo, b, s, size, alto_en)
	for an: Dictionary in cfg.get("anillos", []):
		_anillo(b, an, size, alto_en)
	for pr: Dictionary in cfg.get("utileria", []):
		_utileria(b, pr, size, alto_en)
	if _mat_base == null:
		_mat_base = StandardMaterial3D.new()
		_mat_base.vertex_color_use_as_albedo = true
		_mat_base.vertex_color_is_srgb = true
		_mat_base.albedo_color = Color(1.05, 1.03, 1.0)
		_mat_base.roughness = 0.92
		_mat_base.metallic_specular = 0.2
		_mat_suelo = StandardMaterial3D.new()
		_mat_suelo.vertex_color_use_as_albedo = true
		_mat_suelo.vertex_color_is_srgb = true
		_mat_suelo.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		_mat_suelo.roughness = 1.0
		_mat_suelo.metallic_specular = 0.0
		_mat_suelo.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_DISABLED
		_mat_suelo.render_priority = -1
	return {
		"base": b.malla(_mat_base),
		"equipo": b.malla_equipo(),
		"suelo": suelo.malla(_mat_suelo),
		"alto_en": alto_en,
	}


## El contorno de un anillo en coordenadas del cuerpo (casillas), cerrado, con puntos cada ~0,12.
static func contorno(an: Dictionary, size: float) -> PackedVector2Array:
	var e := float(an.get("escala", 1.0))
	var ax := float(an.get("ancho", 1.0)) * e * size / 2.0
	var az := float(an.get("fondo", an.get("ancho", 1.0))) * e * size / 2.0
	var cx := float(an.get("x", 0.0)) * size
	var cz := float(an.get("z", 0.0)) * size
	var pts := PackedVector2Array()
	match str(an.get("forma", "rect")):
		"elipse":
			var n := maxi(16, int(TAU * maxf(ax, az) / 0.14))
			for i in n:
				var a := TAU * i / n
				pts.append(Vector2(cx + sin(a) * ax, cz + cos(a) * az))
		"poligono":
			var n := int(an.get("lados", 8))
			var rot := deg_to_rad(float(an.get("rot", 180.0 / n)))
			for i in n:
				var a := rot + TAU * i / n
				pts.append(Vector2(cx + sin(a) * ax, cz + cos(a) * az))
		"irregular":
			# Polígono de radios dados (fracción del radio), empezando por el frente (+z).
			var rr: Array = an.get("radios", [1, 0.9, 1, 0.85, 1, 0.95, 0.9])
			for i in rr.size():
				var a := TAU * i / rr.size()
				pts.append(Vector2(cx + sin(a) * ax * float(rr[i]), cz + cos(a) * az * float(rr[i])))
		"D":
			# Frente recto y fondo en medio círculo (el muro curvo del Qorikancha).
			pts.append(Vector2(cx - ax, cz + az))
			pts.append(Vector2(cx + ax, cz + az))
			var rz := az * float(an.get("curva", 0.5)) * 2.0
			var zc := cz - az + rz
			pts.append(Vector2(cx + ax, zc))
			for i in range(1, 16):
				var a := PI * i / 16.0
				pts.append(Vector2(cx + cos(a) * ax, zc - sin(a) * rz))
			pts.append(Vector2(cx - ax, zc))
		"zigzag":
			# Rectángulo con el frente y el fondo en dientes (los muros de Saqsaywaman).
			var d := int(an.get("dientes", 5))
			var p := float(an.get("profundo", 0.08)) * size
			pts.append(Vector2(cx - ax, cz + az))
			for i in d:
				var x0 := -ax + 2.0 * ax * i / d
				pts.append(Vector2(cx + x0 + ax / d, cz + az + p))
				pts.append(Vector2(cx + x0 + 2.0 * ax / d, cz + az))
			pts.append(Vector2(cx + ax, cz - az))
			for i in d:
				var x0 := ax - 2.0 * ax * i / d
				pts.append(Vector2(cx + x0 - ax / d, cz - az - p))
				pts.append(Vector2(cx + x0 - 2.0 * ax / d, cz - az))
		_:
			var r := minf(float(an.get("esquina", 0.0)) * size, minf(ax, az))
			if r <= 0.01:
				pts.append_array([Vector2(cx - ax, cz + az), Vector2(cx + ax, cz + az), Vector2(cx + ax, cz - az), Vector2(cx - ax, cz - az)])
			else:
				for c: Vector3 in [Vector3(1, 1, 0), Vector3(1, -1, 1), Vector3(-1, -1, 2), Vector3(-1, 1, 3)]:
					var o := Vector2(cx + c.x * (ax - r), cz + c.y * (az - r))
					for i in 5:
						var a := PI / 2.0 * (c.z + i / 4.0)
						pts.append(o + Vector2(sin(a), cos(a)) * r)
	# Subdivide los lados largos.
	var out := PackedVector2Array()
	for i in pts.size():
		var a := pts[i]
		var bb := pts[(i + 1) % pts.size()]
		var n := maxi(1, ceili(a.distance_to(bb) / 0.14))
		for k in n:
			out.append(a.lerp(bb, float(k) / n))
	return out


## Un anillo: el muro por tramos, la puerta, las torres, la faja y, si es terraza, el relleno.
static func _anillo(b: _Obra, an: Dictionary, size: float, alto_en: Callable) -> void:
	var pts := contorno(an, size)
	var mat := str(an.get("material", "pirca"))
	var est: Dictionary = (datos().get("materiales", {}) as Dictionary).get(mat, {})
	var h := float(an.get("alto_cm", est.get("alto_cm", 100))) / 100.0
	var g := float(an.get("grueso_cm", est.get("grueso_cm", 22))) / 100.0
	var y0 := float(an.get("y_cm", 0)) / 100.0
	var pu: Dictionary = an.get("puerta", {"ancho": 0.16})
	var con_puerta: bool = not an.get("sin_puerta", false)
	var pw := float(pu.get("ancho", 0.16)) * size
	var px := float(pu.get("x", 0.0)) * size
	# Punto del contorno más cercano al frente (+z) en x = px: ahí va la puerta.
	var front_z := -INF
	for p in pts:
		if absf(p.x - px) < pw and p.y > front_z:
			front_z = p.y
	var col := Color(str(an.get("color", est.get("color", "#9a8c78"))))
	var faja: bool = an.get("faja", false)
	var faja_h := float(an.get("faja_pct", 70)) / 100.0
	var centro := Vector2(float(an.get("x", 0.0)), float(an.get("z", 0.0))) * size
	var ext := Vector2.ZERO
	var u_largo := 0.0
	for i in pts.size():
		var a := pts[i]
		var c := pts[(i + 1) % pts.size()]
		var mid := (a + c) / 2.0
		if con_puerta and absf(mid.x - px) < pw / 2.0 and mid.y > front_z - 0.25:
			continue
		var ya := y0 + float(alto_en.call(a.x, a.y))
		var yc := y0 + float(alto_en.call(c.x, c.y))
		var salida := (mid - centro).normalized()
		b.u_muro = u_largo
		_tramo(b, mat, est, a, c, ya, yc, h, g, col, salida, i)
		if faja:
			b.equipo_tira(a, c, ya + h * faja_h, yc + h * faja_h, h * 0.16, g / 2.0 + 0.012, salida)
		ext = ext.max(mid.abs())
		u_largo += a.distance_to(c)
	if an.get("terraza", false):
		var top := PackedVector2Array()
		for p in pts:
			top.append(p - (p - centro).normalized() * g * 0.4)
		b.poligono(top, y0 + h - 0.01, Color(str(an.get("color_terraza", "#8c8a5a"))))
	if con_puerta:
		_puerta(b, mat, est, Vector2(px, front_z), pw, y0 + float(alto_en.call(px, front_z)), h, g, col, an)
	var torres: Dictionary = an.get("torres", {})
	if not torres.is_empty():
		var n := int(torres.get("n", 4))
		var desde := float(torres.get("desde_deg", 45))
		var r := float(torres.get("radio_cm", 30)) / 100.0
		var th := h + float(torres.get("mas_alto_cm", 40)) / 100.0
		for i in n:
			var a := deg_to_rad(desde + 360.0 * i / n)
			var dir := Vector2(sin(a), cos(a))
			# El punto del contorno en esa dirección.
			var best := pts[0]
			var bd := -INF
			for p in pts:
				var d := (p - centro).normalized().dot(dir)
				if d > bd:
					bd = d
					best = p
			var ty := y0 + float(alto_en.call(best.x, best.y))
			_torre(b, mat, est, best, ty, r, th, col, torres)
			if faja:
				b.equipo_anillo(best, ty + th * 0.72, r + 0.015, th * 0.12)


## Un tramo de muro de `a` a `c` según el material. `i`: índice para variar las piedras.
static func _tramo(b: _Obra, mat: String, est: Dictionary, a: Vector2, c: Vector2, ya: float, yc: float, h: float, g: float, col: Color, salida: Vector2, i: int) -> void:
	var largo := a.distance_to(c)
	var dir := (c - a) / maxf(largo, 0.001)
	var mid := (a + c) / 2.0
	var y := minf(ya, yc)
	var yaw := atan2(dir.x, dir.y) + PI / 2.0
	match str(est.get("tipo", mat)):
		"empalizada":
			var n := maxi(1, int(largo / 0.11))
			for k in n:
				var t := (k + 0.5) / n
				var p := a.lerp(c, t)
				var py := lerpf(ya, yc, t)
				var lh := h * (0.9 + 0.1 * float((i * 7 + k * 3) % 4) / 3.0)
				var r := 0.05 + 0.008 * float((i + k) % 3)
				b.cil(Vector3(p.x, py - 0.1, p.y), r, r * 0.92, lh + 0.1, 6, col.darkened(0.06 * float((i * 3 + k) % 3)))
				b.cil(Vector3(p.x, py + lh, p.y), r * 0.92, 0.0, 0.13, 6, col.darkened(0.2))
			for f: float in [0.3, 0.75]:
				b.caja(Vector3(mid.x, y + h * f, mid.y) - Vector3(salida.x, 0, salida.y) * 0.06, Vector3(largo + 0.04, 0.05, 0.04), yaw, col.darkened(0.3))
			if est.get("estrepes", false):
				for k in maxi(1, int(largo / 0.22)):
					var p := a.lerp(c, (k + 0.5) / maxi(1, int(largo / 0.22))) + salida * 0.2
					b.cil(Vector3(p.x, lerpf(ya, yc, 0.5) - 0.02, p.y), 0.02, 0.0, 0.18, 4, col.darkened(0.25), Vector3(salida.x, 1.2, salida.y).normalized())
			if est.get("foso", false):
				var q := salida * 0.38
				b.poligono(PackedVector2Array([a + q - salida * 0.12, c + q - salida * 0.12, c + q + salida * 0.12, a + q + salida * 0.12]), lerpf(ya, yc, 0.5) + 0.012, Color(str(est.get("color_foso", "#4a3c2c"))))
		"palos":
			# Cerco bajo de palos sin labrar con dos travesaños (mapuche).
			var n := maxi(1, int(largo / 0.4))
			for k in n + 1:
				var p := a.lerp(c, float(k) / n)
				b.cil(Vector3(p.x, lerpf(ya, yc, float(k) / n) - 0.05, p.y), 0.035, 0.03, h + 0.05, 5, col)
			for f: float in [0.45, 0.85]:
				b.caja(Vector3(mid.x, y + h * f, mid.y), Vector3(largo + 0.06, 0.035, 0.035), yaw, col.darkened(0.15))
		_:
			# Muro macizo: cuerpo en talud y, según el material, piedras, hiladas o almenas.
			var talud := float(est.get("talud", 0.25))
			var gb := g
			var gt := g * (1.0 - talud)
			var y_bot := y - 0.08
			var hh := h + (absf(ya - yc)) + 0.08
			var junta := Color(str(est.get("junta", col.darkened(0.25).to_html())))
			var patron := str(est.get("patron", ""))
			# Con `patron`, la cara del muro es la de las piezas modulares de muralla (proceso/64,
			# Piezas.mat_muro: sillar, pirca, ladrillo, revoque) y no se suman piedras sueltas.
			b.muro(a, c, y_bot, hh, gb, gt, col, patron, junta)
			match str(est.get("aparejo", "liso")) if patron == "" else "patron":
				"piedras":
					var filas := int(est.get("filas", 4))
					for f in filas:
						var fy := y + h * (f + 0.5) / filas
						var gw := lerpf(gb, gt, (f + 0.5) / filas)
						var nn := maxi(1, int(largo / 0.13))
						for k in nn:
							var t := (k + 0.5 + (0.5 if f % 2 == 1 else 0.0)) / nn
							if t > 1.0:
								continue
							var p := a.lerp(c, t)
							var sw := largo / nn * (0.8 + 0.15 * float((i + k * 5 + f * 3) % 3) / 2.0)
							var sh := h / filas * 0.86
							var tone := col.darkened(0.05 * float((i * 5 + k * 3 + f * 7) % 4)).lightened(0.03 * float((i + k + f) % 2))
							b.caja(Vector3(p.x, fy, p.y), Vector3(sw, sh, gw + 0.025), yaw + deg_to_rad(float((i + k * 3 + f) % 5 - 2) * 3.0), tone)
					b.caja(Vector3(mid.x, y + h + 0.025, mid.y), Vector3(largo + 0.02, 0.05, gt + 0.03), yaw, col.darkened(0.12))
				"hiladas":
					var filas := int(est.get("filas", 5))
					for f in range(1, filas):
						var fy := y + h * f / filas
						b.caja(Vector3(mid.x, fy, mid.y), Vector3(largo + 0.005, 0.012, lerpf(gb, gt, float(f) / filas) + 0.008), yaw, junta)
				"patron":
					pass
				_:
					b.caja(Vector3(mid.x, y + h + 0.025, mid.y), Vector3(largo + 0.01, 0.05, gt + 0.04), yaw, Color(str(est.get("color_remate", col.darkened(0.1).to_html()))))
			if est.has("friso"):
				# Faja fija (sagrada o de oficio, no del equipo): el oro del Qorikancha.
				var fc := Color(str(est["friso"]))
				var fh := float(est.get("friso_pct", 75)) / 100.0
				b.caja(Vector3(mid.x, y + h * fh, mid.y), Vector3(largo + 0.01, h * 0.1, lerpf(gb, gt, fh) + 0.025), yaw, fc)
			match str(est.get("almena", "")):
				"hoja":
					var n := maxi(1, int(largo / 0.16))
					for k in n:
						var p := a.lerp(c, (k + 0.5) / n)
						b.cil(Vector3(p.x, y + h + 0.05, p.y), 0.05, 0.05, 0.06, 4, col)
						b.cil(Vector3(p.x, y + h + 0.11, p.y), 0.055, 0.0, 0.14, 4, col)
				"techo":
					# Albardilla de paja o teja sobre el muro (tapia).
					var rc := Color(str(est.get("color_techo", "#8a6a40")))
					b.caja(Vector3(mid.x, y + h + 0.07, mid.y), Vector3(largo + 0.04, 0.07, gt + 0.12), yaw, rc)


## La puerta: jambas más altas que el muro, dintel y, en la empalizada, dos postes y hojas
## abiertas. Los paños del color del equipo cuelgan de las jambas si el anillo lleva banderas.
static func _puerta(b: _Obra, mat: String, est: Dictionary, at: Vector2, ancho: float, y: float, h: float, g: float, col: Color, an: Dictionary) -> void:
	var tipo := str(est.get("tipo", mat))
	var jh := h + float(est.get("puerta_mas_cm", 25)) / 100.0
	var jw := maxf(0.14, g * 1.1)
	var paños: bool = an.get("banderas", false)
	for sx: float in [-1.0, 1.0]:
		var jx := at.x + sx * (ancho / 2.0 + jw / 2.0 - 0.02)
		if tipo == "empalizada" or tipo == "palos":
			b.cil(Vector3(jx, y - 0.1, at.y), 0.08, 0.075, jh + 0.12, 7, col.darkened(0.08))
			b.cil(Vector3(jx, y + jh + 0.02, at.y), 0.075, 0.0, 0.16, 7, col.darkened(0.2))
			# Hoja abierta hacia adentro.
			b.caja(Vector3(jx - sx * 0.04, y + h * 0.45, at.y - ancho * 0.25), Vector3(0.04, h * 0.85, ancho * 0.48), 0.0, col.darkened(0.18))
		else:
			b.caja(Vector3(jx, y + jh / 2.0 - 0.04, at.y), Vector3(jw, jh + 0.08, g * 1.25), 0.0, col.lightened(0.03))
		if paños:
			b.equipo_caja(Vector3(jx, y + jh * 0.62, at.y + g * 0.7 + 0.02), Vector3(jw * 0.8, jh * 0.42, 0.025), 0.0)
	if tipo == "empalizada":
		b.caja(Vector3(at.x, y + jh - 0.05, at.y), Vector3(ancho + jw * 2.0, 0.08, 0.1), 0.0, col.darkened(0.25))
	elif tipo == "palos":
		pass
	else:
		# Dintel; en la piedra inca, la puerta es trapezoidal (las jambas se cierran arriba).
		b.caja(Vector3(at.x, y + h * 0.86, at.y), Vector3(ancho * (0.8 if est.get("trapecio", false) else 1.0) + jw * 2.0, h * 0.2, g * 1.25), 0.0, col.darkened(0.05))
		if str(est.get("almena", "")) == "hoja":
			for k in 3:
				var x := at.x + (k - 1) * ancho * 0.4
				b.cil(Vector3(x, y + h * 0.96, at.y), 0.06, 0.0, 0.18, 4, col)
	if paños and an.get("estandarte", true):
		b.cil(Vector3(at.x + ancho / 2.0 + jw, y + jh, at.y + 0.04), 0.018, 0.018, 0.6, 5, Palette.WOOD_BEAM)
		b.equipo_caja(Vector3(at.x + ancho / 2.0 + jw + 0.13, y + jh + 0.45, at.y + 0.04), Vector3(0.24, 0.16, 0.015), 0.0)


static func _torre(b: _Obra, mat: String, est: Dictionary, at: Vector2, y: float, r: float, h: float, col: Color, cfg: Dictionary) -> void:
	var tipo := str(est.get("tipo", mat))
	if tipo == "empalizada":
		# Atalaya de palos: cuatro postes, plataforma y techo de paja.
		for c: Vector2 in [Vector2(-1, -1), Vector2(1, -1), Vector2(-1, 1), Vector2(1, 1)]:
			b.cil(Vector3(at.x + c.x * r * 0.7, y - 0.05, at.y + c.y * r * 0.7), 0.04, 0.04, h + 0.05, 5, col.darkened(0.1))
		b.caja(Vector3(at.x, y + h * 0.75, at.y), Vector3(r * 1.8, 0.06, r * 1.8), 0.0, col.darkened(0.2))
		b.cil(Vector3(at.x, y + h, at.y), r * 1.35, 0.0, r * 1.3, 6, Color(str(cfg.get("color_techo", "#9a7c4a"))), Vector3.UP, PI / 4.0)
		return
	if cfg.get("redonda", true):
		b.cil(Vector3(at.x, y - 0.06, at.y), r * 1.08, r, h + 0.06, 12, col.lightened(0.04))
		b.cil(Vector3(at.x, y + h, at.y), r + 0.03, r + 0.03, 0.05, 12, col.darkened(0.1))
	else:
		b.caja(Vector3(at.x, y + h / 2.0 - 0.03, at.y), Vector3(r * 2.0, h + 0.06, r * 2.0), 0.0, col.lightened(0.04))
	match str(cfg.get("remate", "")):
		"cupula":
			b.cil(Vector3(at.x, y + h + 0.05, at.y), r * 0.8, r * 0.5, r * 0.4, 10, col.darkened(0.08))
			b.cil(Vector3(at.x, y + h + 0.05 + r * 0.4, at.y), r * 0.5, 0.0, r * 0.4, 10, col.darkened(0.08))
		"paja":
			b.cil(Vector3(at.x, y + h, at.y), r * 1.3, 0.0, r * 1.5, 10, Color(str(cfg.get("color_techo", "#8a6d45"))))
		"hoja":
			for k in 6:
				var a := TAU * k / 6.0
				b.cil(Vector3(at.x + sin(a) * r * 0.8, y + h + 0.05, at.y + cos(a) * r * 0.8), 0.05, 0.0, 0.16, 4, col)


## Cerro (Palmares): un domo de perfil suave con la cima plana. Devuelve el alto del terreno
## en (x, z), que usan los anillos, las piezas y la utilería que van encima.
static func _monte(b: _Obra, m: Dictionary, size: float) -> Callable:
	var R := float(m.get("radio", 0.5)) * size
	var rt := float(m.get("cima", 0.2)) * size
	var H := float(m.get("alto_cm", 120)) / 100.0
	var f := func(x: float, z: float) -> float:
		var r := Vector2(x, z).length()
		if r >= R:
			return 0.0
		if r <= rt:
			return H
		var t := (R - r) / (R - rt)
		return H * t * t * (3.0 - 2.0 * t)
	var col_a := Color(str(m.get("color", "#7d7448")))
	var col_b := Color(str(m.get("color_cima", "#9a8a5c")))
	var anillos := 10
	var seg := 28
	for k in anillos:
		var r0 := R * (1.0 - float(k) / anillos)
		var r1 := R * (1.0 - float(k + 1) / anillos)
		for s in seg:
			var a0 := TAU * s / seg
			var a1 := TAU * (s + 1) / seg
			var p00 := Vector3(sin(a0) * r0, 0, cos(a0) * r0)
			var p01 := Vector3(sin(a1) * r0, 0, cos(a1) * r0)
			var p10 := Vector3(sin(a0) * r1, 0, cos(a0) * r1)
			var p11 := Vector3(sin(a1) * r1, 0, cos(a1) * r1)
			p00.y = f.call(p00.x, p00.z) - (0.05 if k == 0 else 0.0)
			p01.y = f.call(p01.x, p01.z) - (0.05 if k == 0 else 0.0)
			p10.y = f.call(p10.x, p10.z)
			p11.y = f.call(p11.x, p11.z)
			var c := col_a.lerp(col_b, float(k) / anillos).darkened(0.03 * float((s * 7 + k * 3) % 3))
			b.quad(p00, p01, p11, p10, Vector3.UP, c)
	return f


## Suelo: patio (polígono del anillo, a ras) o tierra pisada (con el borde que se esfuma).
static func _suelo(sb: _Obra, b: _Obra, s: Dictionary, size: float, alto_en: Callable) -> void:
	var pts := contorno(s, size)
	var col := Color(str(s.get("color", "#a08c68")))
	var borde := float(s.get("borde", 0.25)) * size
	var y := float(s.get("y_cm", 2)) / 100.0
	var centro := Vector2(float(s.get("x", 0.0)), float(s.get("z", 0.0))) * size
	if str(s.get("tipo", "pisado")) == "patio":
		var top := PackedVector2Array()
		for p in pts:
			top.append(p)
		b.poligono(top, y + float(alto_en.call(0.0, 0.0)), col)
		return
	# Tierra pisada: centro opaco, borde que se esfuma hacia afuera con ruido.
	var n := pts.size()
	for i in n:
		var a := pts[i]
		var c := pts[(i + 1) % n]
		var ja := 1.0 + 0.35 * float((i * 7) % 5) / 4.0
		var jc := 1.0 + 0.35 * float(((i + 1) % n * 7) % 5) / 4.0
		var ao := a + (a - centro).normalized() * borde * ja
		var co := c + (c - centro).normalized() * borde * jc
		var A := Vector3(a.x, y + float(alto_en.call(a.x, a.y)), a.y)
		var C := Vector3(c.x, y + float(alto_en.call(c.x, c.y)), c.y)
		var AO := Vector3(ao.x, y + float(alto_en.call(ao.x, ao.y)), ao.y)
		var CO := Vector3(co.x, y + float(alto_en.call(co.x, co.y)), co.y)
		var O := Vector3(centro.x, y + float(alto_en.call(centro.x, centro.y)), centro.y)
		var opaco := Color(col, float(s.get("alfa", 0.85)))
		var nada := Color(col, 0.0)
		sb.tri_c(O, A, C, opaco, opaco, opaco)
		sb.tri_c(A, AO, CO, opaco, nada, nada)
		sb.tri_c(A, CO, C, opaco, nada, opaco)


# ------------------------------------------------------------------ Utilería

static func _utileria(b: _Obra, pr: Dictionary, size: float, alto_en: Callable) -> void:
	var lista: Array = pr.get("en", [[pr.get("x", 0.0), pr.get("z", 0.0)]])
	var esc := float(pr.get("escala", 1.0))
	for k in lista.size():
		var pos: Array = lista[k]
		var x := float(pos[0]) * size
		var z := float(pos[1]) * size
		var yaw := deg_to_rad(float(pos[2])) if pos.size() > 2 else (atan2(-x, -z) if pr.get("mirar_centro", false) else 0.0)
		var y := float(alto_en.call(x, z)) + float(pr.get("y_cm", 0)) / 100.0
		_prop(b, str(pr.get("tipo", "")), Vector3(x, y, z), yaw, esc, pr, k)


static func _prop(b: _Obra, tipo: String, at: Vector3, yaw: float, e: float, pr: Dictionary, k: int) -> void:
	var rot := Basis(Vector3.UP, yaw)
	var P := func(v: Vector3) -> Vector3: return at + rot * (v * e)
	var madera := Palette.WOOD_BEAM
	match tipo:
		"puesto":
			# Puesto de mercado: cuatro horcones, techo de paja o tela y mostrador con mercadería.
			var techo := Color(str(pr.get("color_techo", "#a88a52")))
			for c: Vector2 in [Vector2(-1, -1), Vector2(1, -1), Vector2(-1, 1), Vector2(1, 1)]:
				b.cil(P.call(Vector3(c.x * 0.22, 0, c.y * 0.16)), 0.022 * e, 0.022 * e, (0.42 if c.y > 0 else 0.34) * e, 5, madera)
			var paño: bool = pr.get("equipo", false) and k % 2 == 0
			var tc: Vector3 = P.call(Vector3(0, 0.4, 0))
			if paño:
				b.equipo_caja(tc, Vector3(0.56, 0.03, 0.44) * e, yaw, Vector3(deg_to_rad(-10), 0, 0))
			else:
				b.caja(tc, Vector3(0.56, 0.06, 0.44) * e, yaw, techo, Vector3(deg_to_rad(-10), 0, 0))
			b.caja(P.call(Vector3(0, 0.1, 0.1)), Vector3(0.4, 0.2, 0.14) * e, yaw, madera.darkened(0.1))
			var bienes: Array = pr.get("bienes", ["#c9a64a", "#8a5a3a", "#b8c070"])
			for j in 3:
				b.cil(P.call(Vector3(-0.12 + j * 0.12, 0.2, 0.1)), 0.045 * e, 0.035 * e, 0.06 * e, 6, Color(str(bienes[(j + k) % bienes.size()])))
		"pila_lena":
			var y := 0.04
			for capa in 3:
				var n := 4 - capa
				for i in n:
					var x := (i - (n - 1) / 2.0) * 0.09
					b.cil(P.call(Vector3(x, y, -0.2)), 0.04 * e, 0.04 * e, 0.4 * e, 6, Palette.TRUNK.darkened(0.05 * float((i + capa) % 2)), rot * Vector3(0, 0, 1))
				y += 0.075
		"piedras":
			for i in 5:
				var o := Vector3(float(i % 3) * 0.1 - 0.1, 0.05 + 0.06 * float(i / 3), float(i % 2) * 0.1 - 0.05)
				b.caja(P.call(o), Vector3(0.11, 0.09, 0.12) * e, yaw + i * 0.6, Palette.STONE.darkened(0.06 * float(i % 3)))
		"vasijas":
			for i in 3:
				var o := Vector3(float(i) * 0.11 - 0.11, 0, float(i % 2) * 0.08)
				b.cil(P.call(o), 0.045 * e, 0.06 * e, 0.07 * e, 8, Palette.CLAY_DARK.darkened(0.25))
				b.cil(P.call(o + Vector3(0, 0.07, 0)), 0.06 * e, 0.03 * e, 0.06 * e, 8, Palette.CLAY_DARK.darkened(0.3))
		"fardos":
			for i in 3:
				var o := Vector3(float(i % 2) * 0.2 - 0.1, 0.06 + 0.12 * float(i / 2), 0)
				b.caja(P.call(o), Vector3(0.18, 0.12, 0.12) * e, yaw, Color("c2a560").darkened(0.05 * i))
		"abrevadero":
			b.caja(P.call(Vector3(0, 0.05, 0)), Vector3(0.5, 0.1, 0.14) * e, yaw, madera.darkened(0.15))
			b.caja(P.call(Vector3(0, 0.095, 0)), Vector3(0.44, 0.01, 0.09) * e, yaw, Color("5a7480"))
		"tronco":
			# Banco de tronco acostado (parlamento).
			b.cil(P.call(Vector3(-0.3, 0.06, 0)), 0.06 * e, 0.06 * e, 0.6 * e, 7, Palette.TRUNK, rot * Vector3(1, 0, 0))
		"lanza":
			b.cil(P.call(Vector3.ZERO), 0.012 * e, 0.012 * e, 0.95 * e, 4, Color("b8a070"))
			b.cil(P.call(Vector3(0, 0.95, 0)), 0.022 * e, 0.0, 0.08 * e, 4, Color("6a6a6a"))
			b.equipo_caja(P.call(Vector3(0.07, 0.82, 0)), Vector3(0.14, 0.09, 0.012) * e, yaw)
		"estandarte":
			b.cil(P.call(Vector3.ZERO), 0.02 * e, 0.02 * e, 1.0 * e, 5, madera)
			b.equipo_caja(P.call(Vector3(0.12, 0.82, 0)), Vector3(0.24, 0.2, 0.012) * e, yaw)
		"rewe":
			# Poste escalonado de madera (sagrado: sin color del equipo) con ramas de canelo.
			b.cil(P.call(Vector3.ZERO), 0.05 * e, 0.045 * e, 0.8 * e, 6, Color("8a6a48"))
			for j in 4:
				b.caja(P.call(Vector3(0, 0.15 + j * 0.15, 0.05)), Vector3(0.08, 0.03, 0.05) * e, yaw, Color("6a5038"))
			for j in 3:
				var a := TAU * j / 3.0
				b.cil(P.call(Vector3(sin(a) * 0.05, 0.6, cos(a) * 0.05)), 0.01 * e, 0.0, 0.35 * e, 4, Color("4f7040"), Vector3(sin(a), 2.0, cos(a)).normalized())
		"canelo":
			b.cil(P.call(Vector3.ZERO), 0.035 * e, 0.03 * e, 0.5 * e, 6, Palette.TRUNK)
			b.cil(P.call(Vector3(0, 0.4, 0)), 0.2 * e, 0.0, 0.55 * e, 7, Color("4a6e3e"))
		"fogon":
			for i in 6:
				var a := TAU * i / 6.0
				b.caja(P.call(Vector3(sin(a) * 0.1, 0.025, cos(a) * 0.1)), Vector3(0.06, 0.05, 0.06) * e, a, Palette.STONE_DARK)
			b.cil(P.call(Vector3(0, 0.0, 0)), 0.08 * e, 0.08 * e, 0.02 * e, 8, Color("3a3430"))
		"fuente":
			# Pila de piedra con borde de oro (sagrada).
			b.cil(P.call(Vector3.ZERO), 0.2 * e, 0.22 * e, 0.12 * e, 10, Color("b8ad98"))
			b.cil(P.call(Vector3(0, 0.12, 0)), 0.17 * e, 0.17 * e, 0.012 * e, 10, Color("4f6e7a"))
			b.cil(P.call(Vector3(0, 0.11, 0)), 0.215 * e, 0.215 * e, 0.025 * e, 10, Color("d6a62e"))
		"telar":
			# Telar de cintura: dos estacas y la tela tendida (de colores, no del equipo).
			b.cil(P.call(Vector3(-0.15, 0, 0)), 0.012 * e, 0.012 * e, 0.22 * e, 4, madera)
			b.cil(P.call(Vector3(0.15, 0, 0)), 0.012 * e, 0.012 * e, 0.22 * e, 4, madera)
			b.caja(P.call(Vector3(0, 0.12, 0.04)), Vector3(0.28, 0.01, 0.2) * e, yaw, Color(str(pr.get("color_tela", "#b0743a"))), Vector3(deg_to_rad(20), 0, 0))
		"canon":
			b.cil(P.call(Vector3(0, 0.08, -0.12)), 0.035 * e, 0.045 * e, 0.34 * e, 8, Color("3a3a3a"), rot * Vector3(0, 0, 1))
			for sx: float in [-1.0, 1.0]:
				b.cil(P.call(Vector3(sx * 0.07, 0.065, 0.0)), 0.065 * e, 0.065 * e, 0.025 * e, 8, madera.darkened(0.2), rot * Vector3(1, 0, 0))
		"caballo":
			var coat := Color(str(pr.get("color", ["#7a5a3e", "#5a4030", "#9a8068", "#3e342c"][k % 4])))
			b.caja(P.call(Vector3(0, 0.27, 0)), Vector3(0.12, 0.13, 0.36) * e, yaw, coat)
			b.caja(P.call(Vector3(0, 0.38, 0.2)), Vector3(0.06, 0.16, 0.07) * e, yaw, coat, Vector3(deg_to_rad(-25), 0, 0))
			b.caja(P.call(Vector3(0, 0.45, 0.26)), Vector3(0.06, 0.06, 0.13) * e, yaw, coat.darkened(0.1))
			for c: Vector2 in [Vector2(-1, -1), Vector2(1, -1), Vector2(-1, 1), Vector2(1, 1)]:
				b.cil(P.call(Vector3(c.x * 0.04, 0, c.y * 0.13)), 0.018 * e, 0.018 * e, 0.22 * e, 4, coat.darkened(0.25))
			b.cil(P.call(Vector3(0, 0.3, -0.18)), 0.015 * e, 0.0, 0.18 * e, 4, coat.darkened(0.4), rot * Vector3(0, -1, -0.6).normalized())
		"llama":
			var lana := Color(str(["#e6dccb", "#8a6a4a", "#d8c8a8"][k % 3]))
			b.caja(P.call(Vector3(0, 0.22, 0)), Vector3(0.1, 0.1, 0.22) * e, yaw, lana)
			b.caja(P.call(Vector3(0, 0.36, 0.1)), Vector3(0.05, 0.2, 0.05) * e, yaw, lana)
			b.caja(P.call(Vector3(0, 0.46, 0.13)), Vector3(0.05, 0.05, 0.08) * e, yaw, lana.darkened(0.1))
			for c: Vector2 in [Vector2(-1, -1), Vector2(1, -1), Vector2(-1, 1), Vector2(1, 1)]:
				b.cil(P.call(Vector3(c.x * 0.03, 0, c.y * 0.08)), 0.014 * e, 0.014 * e, 0.18 * e, 4, lana.darkened(0.2))
		# --- proceso/66-todo-en-3d-local ---
		"bandera":
			# Bandera de colores fijos (no del equipo): franjas `colores` horizontales o verticales
			# (`franjas`: "h"|"v") y, si se pide, una cruz en aspa (`aspa`: color), en un mástil.
			var cols: Array = pr.get("colores", ["#e8e2d0"])
			var alto := float(pr.get("alto", 1.25))
			b.cil(P.call(Vector3.ZERO), 0.018 * e, 0.014 * e, alto * e, 5, madera.darkened(0.2))
			var fw := 0.34
			var fh := 0.22
			var n := cols.size()
			for j in n:
				var c := Color(str(cols[j]))
				if str(pr.get("franjas", "h")) == "v":
					b.caja(P.call(Vector3(0.02 + fw * (j + 0.5) / n, alto - 0.13, 0)), Vector3(fw / n, fh, 0.012) * e, yaw, c)
				else:
					b.caja(P.call(Vector3(0.02 + fw / 2.0, alto - 0.13 + fh / 2.0 - fh * (j + 0.5) / n, 0)), Vector3(fw, fh / n, 0.012) * e, yaw, c)
			if pr.has("aspa"):
				var ca := Color(str(pr["aspa"]))
				var ang := atan2(fh, fw)
				for sg: float in [1.0, -1.0]:
					b.caja(P.call(Vector3(0.02 + fw / 2.0, alto - 0.13, 0.008)), Vector3(sqrt(fw * fw + fh * fh) * 0.95, 0.03, 0.006) * e, yaw, ca, Vector3(0, 0, sg * ang))
		"estacas":
			# Hoyo con estacas (trampa): un pozo oscuro con puntas afiladas que asoman apenas.
			b.cil(P.call(Vector3(0, 0.005, 0)), 0.3 * e, 0.3 * e, 0.012 * e, 10, Color(str(pr.get("color", "#3a2e24"))))
			for i in 7:
				var a := TAU * i / 7.0 + 0.3
				var r := 0.16 if i % 2 == 0 else 0.07
				b.cil(P.call(Vector3(sin(a) * r, 0.0, cos(a) * r)), 0.018 * e, 0.0, (0.16 + 0.04 * float(i % 3)) * e, 4, Color("9a8058"), Vector3(sin(a) * 0.25, 1.0, cos(a) * 0.25).normalized())
			for i in 5:
				var a := TAU * i / 5.0
				b.caja(P.call(Vector3(sin(a) * 0.3, 0.01, cos(a) * 0.3)), Vector3(0.12, 0.02, 0.05) * e, a, Color("6a5a3a"))
		"oveja":
			var lana := Color(str(["#e8e2d2", "#d8cfbc", "#5a4a3a"][k % 3]))
			b.caja(P.call(Vector3(0, 0.14, 0)), Vector3(0.12, 0.1, 0.18) * e, yaw, lana)
			b.caja(P.call(Vector3(0, 0.17, 0.11)), Vector3(0.05, 0.05, 0.06) * e, yaw, lana.darkened(0.35))
			for c: Vector2 in [Vector2(-1, -1), Vector2(1, -1), Vector2(-1, 1), Vector2(1, 1)]:
				b.cil(P.call(Vector3(c.x * 0.035, 0, c.y * 0.06)), 0.012 * e, 0.012 * e, 0.1 * e, 4, lana.darkened(0.4))
		"cana":
			# Haz de caña de azúcar: cañas verdes y amarillas acostadas.
			for i in 7:
				var o := Vector3(float(i % 4) * 0.05 - 0.08, 0.025 + 0.04 * float(i / 4), 0)
				b.cil(P.call(o + Vector3(0, 0, -0.22)), 0.018 * e, 0.016 * e, 0.44 * e, 5, Color("a8b060").darkened(0.08 * float(i % 3)), rot * Vector3(0, 0, 1))
		"barriles":
			for i in 3:
				var o := Vector3(float(i) * 0.11 - 0.11, 0, float(i % 2) * 0.06)
				b.cil(P.call(o), 0.045 * e, 0.045 * e, 0.12 * e, 8, Color("7a5638"))
				b.cil(P.call(o + Vector3(0, 0.03, 0)), 0.048 * e, 0.048 * e, 0.012 * e, 8, Color("3a3430"))
				b.cil(P.call(o + Vector3(0, 0.09, 0)), 0.048 * e, 0.048 * e, 0.012 * e, 8, Color("3a3430"))
		"tienda":
			# Tienda de campaña: cono de tela clara sobre un palo, con un paño del equipo si se pide.
			var tela := Color(str(pr.get("color", "#d8ccb0")))
			b.cil(P.call(Vector3.ZERO), 0.2 * e, 0.0, 0.34 * e, 8, tela)
			b.cil(P.call(Vector3(0, 0.3, 0)), 0.008 * e, 0.008 * e, 0.12 * e, 4, madera)
			if pr.get("equipo", false):
				b.equipo_caja(P.call(Vector3(0.05, 0.38, 0)), Vector3(0.09, 0.05, 0.008) * e, yaw)
		"surcos":
			# Surcos de un campo (tef, maíz chico): hileras bajas de `color` sobre el patio.
			var col := Color(str(pr.get("color", "#9a9a4a")))
			var nf := int(pr.get("filas", 5))
			for i in nf:
				b.caja(P.call(Vector3(0, 0.02, (float(i) - (nf - 1) / 2.0) * 0.12)), Vector3(0.7, 0.04, 0.06) * e, yaw, col.darkened(0.06 * float(i % 2)))
		"monolito":
			# Piedra parada de un círculo sagrado (sin color del equipo).
			var alto_m := 0.4 + 0.12 * float(k % 3)
			b.caja(P.call(Vector3(0, alto_m / 2.0, 0)), Vector3(0.11, alto_m, 0.08) * e, yaw + 0.3 * float(k % 2), Color(str(pr.get("color", "#8c8578"))).darkened(0.05 * float(k % 3)), Vector3(0, 0, deg_to_rad(4.0 * float(k % 3 - 1))))
		"muelle":
			# Muelle de tablas sobre pilotes, para el puerto de río.
			b.caja(P.call(Vector3(0, 0.08, 0)), Vector3(0.3, 0.03, 0.8) * e, yaw, madera.lightened(0.1))
			for i in 4:
				for sx: float in [-1.0, 1.0]:
					b.cil(P.call(Vector3(sx * 0.13, -0.1, -0.35 + i * 0.23)), 0.02 * e, 0.02 * e, 0.2 * e, 5, madera.darkened(0.2))
		"canoa":
			b.caja(P.call(Vector3(0, 0.04, 0)), Vector3(0.12, 0.06, 0.6) * e, yaw, Palette.TRUNK)
			b.caja(P.call(Vector3(0, 0.065, 0)), Vector3(0.08, 0.02, 0.5) * e, yaw, Palette.TRUNK.darkened(0.35))
		"agua":
			# Lámina de agua (orilla del puerto): una losa baja azul verdosa.
			b.caja(P.call(Vector3(0, 0.005, 0)), Vector3(float(pr.get("ancho", 1.0)), 0.01, float(pr.get("fondo", 0.4))) * e, yaw, Color(str(pr.get("color", "#4f6e72"))))
		"iglesia_cruz":
			# Iglesia monolítica en cruz griega (Bete Giyorgis, Lalibela): zócalo de tres escalones, el
			# bloque en cruz, ventanas en dos hileras y la cruz escalonada en relieve en el techo.
			# Sagrada: sin color del equipo. El pipeline la daba como torre o como losa (proceso/66).
			var toba := Color(str(pr.get("color", "#9a6448")))
			var brazo := 0.34
			var largo := 0.86
			var alto_i := 0.46
			for j in 3:
				var lj := largo + 0.12 - j * 0.04
				b.caja(P.call(Vector3(0, 0.025 + j * 0.05, 0)), Vector3(brazo + 0.12 - j * 0.04, 0.05, lj) * e, yaw, toba.darkened(0.08))
				b.caja(P.call(Vector3(0, 0.025 + j * 0.05, 0)), Vector3(lj, 0.05, brazo + 0.12 - j * 0.04) * e, yaw, toba.darkened(0.08))
			b.caja(P.call(Vector3(0, 0.15 + alto_i / 2.0, 0)), Vector3(brazo, alto_i, largo) * e, yaw, toba)
			b.caja(P.call(Vector3(0, 0.15 + alto_i / 2.0, 0)), Vector3(largo, alto_i, brazo) * e, yaw, toba)
			var techo_y := 0.15 + alto_i
			for sg: float in [1.0, -1.0]:
				for fila in 2:
					var wy := 0.27 + fila * 0.17
					b.caja(P.call(Vector3(0, wy, sg * (largo / 2.0 + 0.002))), Vector3(0.07, 0.08, 0.01) * e, yaw, Color("2e2420"))
					b.caja(P.call(Vector3(sg * (largo / 2.0 + 0.002), wy, 0)), Vector3(0.01, 0.08, 0.07) * e, yaw, Color("2e2420"))
			for j in 3:
				var w := brazo * (0.8 - j * 0.22)
				var l := largo * (0.8 - j * 0.22)
				b.caja(P.call(Vector3(0, techo_y + 0.006 + j * 0.012, 0)), Vector3(w, 0.012, l) * e, yaw, toba.lightened(0.04 + 0.03 * j))
				b.caja(P.call(Vector3(0, techo_y + 0.006 + j * 0.012, 0)), Vector3(l, 0.012, w) * e, yaw, toba.lightened(0.04 + 0.03 * j))
		# --- fin proceso/66 ---
		"platea":
			# Plataforma baja de piedra (ushnu chico, altar del patio).
			b.caja(P.call(Vector3(0, 0.06, 0)), Vector3(0.5, 0.12, 0.5) * e, yaw, Color(str(pr.get("color", "#b3a690"))))
			b.caja(P.call(Vector3(0, 0.16, 0)), Vector3(0.3, 0.08, 0.3) * e, yaw, Color(str(pr.get("color", "#b3a690"))).lightened(0.05))


# ------------------------------------------------------------------ Geometría

## Acumula triángulos con color por vértice en dos superficies: la base y la del equipo (que
## el juego pinta con el color del jugador).
class _Obra:
	var st := SurfaceTool.new()
	var eq := SurfaceTool.new()
	var n_base := 0
	var n_eq := 0
	var alto_en: Callable
	var u_muro := 0.0 # largo recorrido del anillo: el dibujo de la piedra sigue de un tramo al otro
	var pat := {} # "<patron>_<color>_<junta>" -> SurfaceTool (con Piezas.mat_muro)
	var pat_mat := {}

	func _init() -> void:
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		eq.begin(Mesh.PRIMITIVE_TRIANGLES)

	func malla(m: Material) -> ArrayMesh:
		if n_base == 0 and pat.is_empty():
			return null
		var out := ArrayMesh.new()
		if n_base > 0:
			st.generate_normals()
			st.commit(out)
			out.surface_set_material(0, m)
		for k in pat:
			(pat[k] as SurfaceTool).generate_normals()
			(pat[k] as SurfaceTool).commit(out)
			out.surface_set_material(out.get_surface_count() - 1, pat_mat[k])
		return out

	func _sup(patron: String, col: Color, junta: Color) -> SurfaceTool:
		var k := "%s_%s_%s" % [patron, col.to_html(), junta.to_html()]
		if not pat.has(k):
			var t := SurfaceTool.new()
			t.begin(Mesh.PRIMITIVE_TRIANGLES)
			pat[k] = t
			pat_mat[k] = Piezas.mat_muro(patron, col, junta)
		return pat[k]

	## Cuadrilátero con UV (x: a lo largo del muro, y: alto en el mundo), para el dibujo del muro.
	func quad_uv(t: SurfaceTool, q: Array, uv: Array, out: Vector3, col: Color) -> void:
		var tris := [[0, 1, 2], [0, 2, 3]]
		for tr: Array in tris:
			var a: Vector3 = q[tr[0]]
			var b: Vector3 = q[tr[1]]
			var c: Vector3 = q[tr[2]]
			var orden: Array = tr if (b - a).cross(c - a).dot(out) <= 0.0 else [tr[0], tr[2], tr[1]]
			for i: int in orden:
				t.set_color(col)
				t.set_uv(uv[i])
				t.add_vertex(q[i])

	func malla_equipo() -> ArrayMesh:
		if n_eq == 0:
			return null
		eq.generate_normals()
		return eq.commit()

	## Triángulo de cara a `out` (Godot: el frente gira en sentido horario visto de afuera).
	func _tri(t: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, out: Vector3, col: Color) -> void:
		if (b - a).cross(c - a).dot(out) > 0.0:
			var tmp := b
			b = c
			c = tmp
		for v: Vector3 in [a, b, c]:
			t.set_color(col)
			t.add_vertex(v)

	func tri_c(a: Vector3, b: Vector3, c: Vector3, ca: Color, cb: Color, cc: Color) -> void:
		var vs := [a, b, c]
		var cs := [ca, cb, cc]
		if (b - a).cross(c - a).y > 0.0:
			vs = [a, c, b]
			cs = [ca, cc, cb]
		for i in 3:
			st.set_color(cs[i])
			st.add_vertex(vs[i])
		n_base += 1

	func quad(a: Vector3, b: Vector3, c: Vector3, d: Vector3, out: Vector3, col: Color, equipo := false) -> void:
		var t := eq if equipo else st
		_tri(t, a, b, c, out, col)
		_tri(t, a, c, d, out, col)
		if equipo:
			n_eq += 2
		else:
			n_base += 2

	## Caja de `tam` centrada en `c`, girada `yaw` en y (y opcionalmente `rot` en x, y, z locales).
	func caja(c: Vector3, tam: Vector3, yaw: float, col: Color, rot := Vector3.ZERO, equipo := false) -> void:
		var bs := Basis(Vector3.UP, yaw) * Basis.from_euler(rot)
		var h := tam / 2.0
		var v := func(x: float, y: float, z: float) -> Vector3: return c + bs * Vector3(x * h.x, y * h.y, z * h.z)
		var caras := [
			[Vector3(1, 0, 0), [Vector3(1, -1, -1), Vector3(1, 1, -1), Vector3(1, 1, 1), Vector3(1, -1, 1)]],
			[Vector3(-1, 0, 0), [Vector3(-1, -1, 1), Vector3(-1, 1, 1), Vector3(-1, 1, -1), Vector3(-1, -1, -1)]],
			[Vector3(0, 1, 0), [Vector3(-1, 1, -1), Vector3(-1, 1, 1), Vector3(1, 1, 1), Vector3(1, 1, -1)]],
			[Vector3(0, 0, 1), [Vector3(-1, -1, 1), Vector3(1, -1, 1), Vector3(1, 1, 1), Vector3(-1, 1, 1)]],
			[Vector3(0, 0, -1), [Vector3(1, -1, -1), Vector3(-1, -1, -1), Vector3(-1, 1, -1), Vector3(1, 1, -1)]],
		]
		for cara: Array in caras:
			var q: Array = cara[1]
			var p: Array = []
			for w: Vector3 in q:
				p.append(v.call(w.x, w.y, w.z))
			var sombra := col if (cara[0] as Vector3).y > 0.5 else col.darkened(0.04)
			quad(p[0], p[1], p[2], p[3], bs * (cara[0] as Vector3), sombra, equipo)

	func equipo_caja(c: Vector3, tam: Vector3, yaw: float, rot := Vector3.ZERO) -> void:
		caja(c, tam, yaw, Color.WHITE, rot, true)

	## Cilindro o cono de `base` hacia `eje`, `n` lados (sin tapa de abajo).
	func cil(base: Vector3, r0: float, r1: float, h: float, n: int, col: Color, eje := Vector3.UP, giro := 0.0) -> void:
		var up := eje.normalized()
		var side := up.cross(Vector3.FORWARD if absf(up.dot(Vector3.FORWARD)) < 0.9 else Vector3.RIGHT).normalized()
		var fwd := side.cross(up)
		var top := base + up * h
		for i in n:
			var a0 := giro + TAU * i / n
			var a1 := giro + TAU * (i + 1) / n
			var d0 := side * cos(a0) + fwd * sin(a0)
			var d1 := side * cos(a1) + fwd * sin(a1)
			var out := (d0 + d1).normalized()
			if r1 > 0.0005:
				quad(base + d0 * r0, base + d1 * r0, top + d1 * r1, top + d0 * r1, out, col)
				_tri(st, top, top + d0 * r1, top + d1 * r1, up, col.lightened(0.04))
				n_base += 1
			else:
				_tri(st, base + d0 * r0, base + d1 * r0, top, out + up * (r0 / maxf(h, 0.01)), col)
				n_base += 1

	## Muro de `a` a `c` (en planta) con talud: grueso `gb` abajo y `gt` arriba.
	func muro(a: Vector2, c: Vector2, y: float, h: float, gb: float, gt: float, col: Color, patron := "", junta := Color.BLACK) -> void:
		var d := (c - a).normalized()
		var nrm := Vector2(-d.y, d.x)
		var A := Vector3(a.x, y, a.y)
		var C := Vector3(c.x, y, c.y)
		var n3 := Vector3(nrm.x, 0, nrm.y)
		var up := Vector3(0, h, 0)
		if patron != "":
			var t := _sup(patron, col, junta)
			var u0 := u_muro
			var u1 := u_muro + a.distance_to(c)
			for s: float in [1.0, -1.0]:
				var q := [A + n3 * s * gb / 2.0, C + n3 * s * gb / 2.0, C + up + n3 * s * gt / 2.0, A + up + n3 * s * gt / 2.0]
				var uv := [Vector2(u0, y), Vector2(u1, y), Vector2(u1, y + h), Vector2(u0, y + h)]
				# El pie un poco más oscuro, como las piezas modulares.
				quad_uv(t, q, uv, n3 * s + Vector3(0, 0.2, 0), Color(1, 1, 1))
			var qt := [A + up + n3 * gt / 2.0, C + up + n3 * gt / 2.0, C + up - n3 * gt / 2.0, A + up - n3 * gt / 2.0]
			quad_uv(t, qt, [Vector2(u0, 0), Vector2(u1, 0), Vector2(u1, gt), Vector2(u0, gt)], Vector3.UP, Color(1.05, 1.05, 1.05))
			return
		var lados := [1.0, -1.0]
		for s: float in lados:
			var bot0 := A + n3 * s * gb / 2.0
			var bot1 := C + n3 * s * gb / 2.0
			var top0 := A + up + n3 * s * gt / 2.0
			var top1 := C + up + n3 * s * gt / 2.0
			quad(bot0, bot1, top1, top0, n3 * s + Vector3(0, 0.2, 0), col.darkened(0.03 if s < 0 else 0.0))
		quad(A + up + n3 * gt / 2.0, C + up + n3 * gt / 2.0, C + up - n3 * gt / 2.0, A + up - n3 * gt / 2.0, Vector3.UP, col.lightened(0.05))

	## Faja del equipo sobre las dos caras del muro, de `a` a `c`.
	func equipo_tira(a: Vector2, c: Vector2, ya: float, yc: float, alto: float, sep: float, salida: Vector2) -> void:
		var d := (c - a).normalized()
		var nrm := Vector2(-d.y, d.x)
		if nrm.dot(salida) < 0.0:
			nrm = -nrm
		for s: float in [1.0, -1.0]:
			var o := nrm * sep * s
			var n3 := Vector3(nrm.x, 0, nrm.y) * s
			quad(Vector3(a.x + o.x, ya - alto / 2.0, a.y + o.y), Vector3(c.x + o.x, yc - alto / 2.0, c.y + o.y), Vector3(c.x + o.x, yc + alto / 2.0, c.y + o.y), Vector3(a.x + o.x, ya + alto / 2.0, a.y + o.y), n3, Color.WHITE, true)

	## Faja del equipo alrededor de una torre redonda.
	func equipo_anillo(at: Vector2, y: float, r: float, alto: float) -> void:
		for i in 12:
			var a0 := TAU * i / 12.0
			var a1 := TAU * (i + 1) / 12.0
			var d0 := Vector3(sin(a0), 0, cos(a0))
			var d1 := Vector3(sin(a1), 0, cos(a1))
			var c := Vector3(at.x, y, at.y)
			quad(c + d0 * r - Vector3(0, alto / 2.0, 0), c + d1 * r - Vector3(0, alto / 2.0, 0), c + d1 * r + Vector3(0, alto / 2.0, 0), c + d0 * r + Vector3(0, alto / 2.0, 0), (d0 + d1).normalized(), Color.WHITE, true)

	## Polígono horizontal (patio, terraza, foso) a la altura `y`.
	func poligono(pts: PackedVector2Array, y: float, col: Color) -> void:
		var idx := Geometry2D.triangulate_polygon(pts)
		for i in range(0, idx.size(), 3):
			var a := pts[idx[i]]
			var b := pts[idx[i + 1]]
			var c := pts[idx[i + 2]]
			_tri(st, Vector3(a.x, y, a.y), Vector3(b.x, y, b.y), Vector3(c.x, y, c.y), Vector3.UP, col)
			n_base += 1
