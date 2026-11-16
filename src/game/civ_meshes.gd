class_name CivMeshes
extends RefCounted
## Arquitectura y vestimenta propias de cada civilización (docs/07). Se reconocen por silueta:
## inca (piedra y paja a cuatro aguas), mapuche (ruka ovalada), guaraní (casa larga hasta el suelo),
## etiópica (tukul redondo), palmarista (choza de palma y cercas), siamesa (techos escalonados rojos).
## Rivales de campaña (solo IA): redonda (casa circular de piedra y paja de los Andes) y azotea
## (piedra y techo plano, como Harar).
## Cada pueblo cambia con la edad y tiene su torre (data/arte_edades.json); la obra se ve en
## tres etapas (`obra`, más el corte de Meshes.clip_below).

static var _cache := {}
static var _arte := {}
static var _cfg_cache := {}


static func _pal(style: Dictionary, cfg: Dictionary = {}) -> Array:
	return [Color(cfg.get("muro", style.get("arcilla", "#eee7da"))), Color(cfg.get("techo", style.get("techo", "#a9927a"))), Color(cfg.get("acento", style.get("acento", "#b8ab93")))]


# ---------------------------------------------------------------- Aspecto por edad

static func arte() -> Dictionary:
	if _arte.is_empty():
		var raw: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/arte_edades.json"))
		_arte = raw if raw is Dictionary else {"_vacio": true}
	return _arte


## Margen del cuerpo del edificio dentro de su huella, en casillas (docs/07, "Margen en la huella").
static func margin() -> float:
	return float(arte().get("margen_cm", 30)) / 100.0


## Aspecto de un pueblo en una edad (1 a 4). Las edades se acumulan: cada una hereda la
## anterior. Lo propio del pueblo pisa lo de su forma.
static func age_cfg(civ: String, forma: String, age: int) -> Dictionary:
	var key := "%s|%s|%d" % [civ, forma, age]
	if _cfg_cache.has(key):
		return _cfg_cache[key]
	var a := arte()
	var out := {}
	var torres: Dictionary = a.get("torres_por_forma", {})
	if torres.has(forma):
		out["torre"] = torres[forma]
	for src: Dictionary in [a.get("formas", {}).get(forma, {}), a.get("civs", {}).get(civ, {})]:
		_merge_age(out, src)
		var eds: Array = src.get("edades", [])
		for i in mini(age, eds.size()):
			_merge_age(out, eds[i])
	out.erase("edades")
	_cfg_cache[key] = out
	return out


static func _merge_age(out: Dictionary, e: Dictionary) -> void:
	for k: String in e:
		if k.begins_with("_") or k == "edades":
			continue
		if e[k] is Dictionary and out.get(k) is Dictionary:
			out[k] = (out[k] as Dictionary).merged(e[k], true)
		else:
			out[k] = e[k]


static func _f(cfg: Dictionary, key: String) -> float:
	return float(cfg.get(key, 100)) / 100.0


static func _is_center(type: String, def: Dictionary) -> bool:
	return (def.get("produce", []) as Array).has("aldeano") or def.get("cuenta_victoria", false) or def.get("acoge", false) or type == "centro"


# ---------------------------------------------------------------- Edificios

## `lev`: cómo levantar muros y techos hasta el alto de la categoría (Meshes.levante; proceso/24,
## 4p). Se calcula con el alto de la edad I (alto_cuerpo), así lo que crece con la edad se conserva.
static func building(type: String, def: Dictionary, team: Color, style: Dictionary, variant: int, tier: int, cfg: Dictionary = {}, lev: Dictionary = {}) -> ArrayMesh:
	var forma: String = style.get("forma", "")
	# La paleta entra en la clave: dos civs con la misma forma (Ayutthaya y Birmania) se ven distintas.
	var key := "%s_%s_%s_%s_%s_%d_%d_%d_%d" % [forma, style.get("arcilla", ""), style.get("techo", ""), type, team.to_html(), variant, tier, str(cfg).hash(), str(lev).hash()]
	if _cache.has(key):
		return _cache[key]
	var pal := _pal(style, cfg)
	var p: Array = []
	var w: float = def["tam"][0]
	var d: float = def["tam"][1]
	var iw := w - 2.0 * margin()
	var id := d - 2.0 * margin()
	var esc := _f(cfg, "escala_pct")
	var base_y := 0.0
	var turned := false # los hitos con forma propia ya vienen de frente (HitosMeshes.build)
	# Sin plinto: el suelo pintado (tierra pisada) ya asienta el edificio (docs/10).
	if def.get("avanza_edad", false):
		# Hitos con forma propia (data/arte_hitos.json); si no, el monumento genérico de la forma.
		if HitosMeshes.build(p, type, w, d, pal, team, cfg):
			turned = true
			for c: Vector2 in [Vector2(-1, -1), Vector2(1, 1)]:
				Meshes._banner(p, Vector3(c.x * w * 0.44, 0.1, c.y * d * 0.44), 1.4, team)
		else:
			_monument(p, forma, variant, tier, w, d, pal, team)
	elif def.get("camino", false):
		p.append([Meshes.box(0.98, 0.05, 0.98), Meshes.xf(Vector3(0, 0.025, 0)), pal[2].lightened(0.1)])
		for i in 4:
			p.append([Meshes.box(0.42, 0.06, 0.42), Meshes.xf(Vector3(-0.22 + (i % 2) * 0.44, 0.04, -0.22 + (i / 2) * 0.44), Vector3(0, i * 9, 0)), pal[2]])
	elif def.has("fuente"):
		_field(p, type, w, d, pal, team, def)
	elif def.get("linea", false) or def.get("puerta", false):
		return Meshes.building_mesh(type, team)
	elif def.has("renta") and def.get("transitable", false):
		_field(p, type, w, d, pal, team, def)
	elif _is_center(type, def):
		_center(p, forma, w, d, pal, team, base_y, cfg)
	elif type == "torre":
		_tower(p, str(cfg.get("torre", "almenada")), pal, team, cfg)
	elif def.get("mercado", false):
		_market(p, forma, w, d, pal, team, base_y, cfg) # --- veterano ronda 5 ---
	elif def.has("produce"):
		_barracks(p, forma, w, d, pal, team, base_y, type, cfg)
	elif def.has("deposito"):
		_store(p, forma, w, d, pal, team, base_y, cfg)
	else:
		_hut(p, forma, Vector3(0, base_y, 0), minf(w * 0.78, iw) * minf(esc, 1.0), minf(d * 0.72, id) * minf(esc, 1.0), 0.9, pal, cfg)
		Meshes._banner(p, Vector3(w * 0.38, base_y, d * 0.38), 1.5, team)
	# Todo se arma con la puerta en +z; media vuelta para que dé a la cámara (proceso/24, 4e).
	if not turned:
		Meshes.face_camera(p)
	var h := Meshes.alto_partes(p)
	Meshes.levantar(p, lev)
	var mesh := Meshes.merge(p)
	_cache[key] = mesh
	_alto[mesh.get_instance_id()] = h
	return mesh


static var _alto := {} # id de la malla -> alto del cuerpo antes de levantarlo, sin estandartes


## Alto del cuerpo de una malla de `building` antes de levantarla (sin estandartes ni figuras).
static func alto_cuerpo(mesh: Mesh) -> float:
	return float(_alto.get(mesh.get_instance_id(), mesh.get_aabb().end.y))


## Casa típica de cada civilización, apoyada en `at`. `cfg`: aspecto de la edad.
static func _hut(p: Array, forma: String, at: Vector3, w: float, d: float, h: float, pal: Array, cfg: Dictionary = {}) -> void:
	var walls: Color = pal[0]
	var roof: Color = pal[1]
	var rf := _f(cfg, "techo_alto_pct")
	h *= _f(cfg, "alto_pct")
	var gold := Palette.WEALTH
	var top := at.y + h * 1.6
	var is_round := false
	var wall_h := h * 0.75
	match forma:
		"inca":
			# Muros de piedra en hiladas, puerta trapezoidal y techo de paja a cuatro aguas.
			p.append([Meshes.box(w, wall_h, d), Meshes.xf(at + Vector3(0, wall_h / 2.0, 0)), walls])
			if cfg.get("aparejo", "") != "canteria":
				p.append([Meshes.box(w + 0.02, 0.05, d + 0.02), Meshes.xf(at + Vector3(0, h * 0.25, 0)), walls.darkened(0.12)])
				p.append([Meshes.box(w + 0.02, 0.05, d + 0.02), Meshes.xf(at + Vector3(0, h * 0.5, 0)), walls.darkened(0.12)])
			if cfg.get("dorado", false):
				p.append([Meshes.box(w + 0.04, 0.07, d + 0.04), Meshes.xf(at + Vector3(0, wall_h - 0.05, 0)), gold])
			var rh := h * 0.85 * rf
			p.append([Meshes.cyl(0.0, maxf(w, d) * 0.78, rh, 4), Meshes.xf(at + Vector3(0, wall_h + rh / 2.0, 0), Vector3(0, 45, 0), Vector3(w / maxf(w, d), 1, d / maxf(w, d))), roof])
			# Puerta trapezoidal (más angosta arriba) y, con cantería, hornacinas a los lados.
			p.append([Meshes.cyl(0.08, 0.13, h * 0.45, 4), Meshes.xf(at + Vector3(0, h * 0.22, d * 0.5), Vector3(0, 45, 0), Vector3(1, 1, 0.25)), roof.darkened(0.5)])
			if cfg.get("aparejo", "") == "canteria":
				for sx in [-1, 1]:
					p.append([Meshes.cyl(0.05, 0.08, h * 0.25, 4), Meshes.xf(at + Vector3(sx * w * 0.3, h * 0.32, d * 0.5), Vector3(0, 45, 0), Vector3(1, 1, 0.25)), walls.darkened(0.35)])
			top = at.y + wall_h + rh
		"mapuche":
			# Ruka: domo ovalado de paja que llega al suelo.
			p.append([Meshes.sphere(0.5, 14), Meshes.xf(at + Vector3(0, h * 0.15, 0), Vector3.ZERO, Vector3(w, h * 2.0 * rf, d)), roof])
			p.append([Meshes.cyl(w * 0.47, w * 0.5, 0.18, 14), Meshes.xf(at + Vector3(0, 0.09, 0), Vector3.ZERO, Vector3(1, 1, d / w)), walls.darkened(0.2)])
			p.append([Meshes.box(0.28, h * 0.5, 0.05), Meshes.xf(at + Vector3(0, h * 0.25, d * 0.48)), roof.darkened(0.55)])
			p.append([Meshes.cyl(0.04, 0.06, 0.25, 6), Meshes.xf(at + Vector3(0, h * 0.15 + h * rf + 0.05, 0)), roof.darkened(0.3)])
			top = at.y + h * 0.15 + h * rf
			wall_h = 0.18
		"guarani":
			# Casa larga: techo a dos aguas hasta el suelo y frentes de barro (o de tabla labrada).
			var rh := h * 1.25 * rf
			p.append([Meshes.prism(d * 1.05, rh, w), Meshes.xf(at + Vector3(0, rh / 2.0, 0), Vector3(0, 90, 0)), roof])
			p.append([Meshes.box(0.06, h * 0.9, d * 0.8), Meshes.xf(at + Vector3(w * 0.5, h * 0.42, 0)), walls])
			p.append([Meshes.box(0.07, h * 0.5, 0.26), Meshes.xf(at + Vector3(w * 0.51, h * 0.25, 0)), roof.darkened(0.55)])
			if cfg.get("horcones", false):
				# Frente de tabla con dibujos pintados en rojo y negro.
				for i in 3:
					p.append([Meshes.box(0.07, 0.06, d * 0.7), Meshes.xf(at + Vector3(w * 0.5 + 0.01, h * (0.2 + i * 0.22), 0)), Color("8c2e1e") if i % 2 == 0 else Color("2a2420")])
			top = at.y + rh
			wall_h = h * 0.9
		"etiopia", "redonda":
			# Tukul (y casa redonda andina): muro redondo y techo cónico con remate.
			var r := minf(w, d) * 0.48
			var rh := h * 0.9 * rf
			wall_h = h * 0.6
			p.append([Meshes.cyl(r, r, wall_h, 16), Meshes.xf(at + Vector3(0, wall_h / 2.0, 0)), walls])
			p.append([Meshes.cyl(0.0, r * 1.3, rh, 16), Meshes.xf(at + Vector3(0, wall_h + rh / 2.0, 0)), roof])
			if not cfg.has("remate"):
				p.append([Meshes.cyl(0.02, 0.02, 0.3, 4), Meshes.xf(at + Vector3(0, wall_h + rh + 0.1, 0)), pal[2]])
			p.append([Meshes.box(0.24, h * 0.4, 0.05), Meshes.xf(at + Vector3(0, h * 0.2, r - 0.01)), roof.darkened(0.55)])
			top = at.y + wall_h + rh
			is_round = true
		"palmares":
			# Choza de pau-a-pique y palma, alero bajo y amplio.
			wall_h = h * 0.6
			var rh := h * 0.55 * rf
			p.append([Meshes.box(w * 0.92, wall_h, d * 0.85), Meshes.xf(at + Vector3(0, wall_h / 2.0, 0)), walls])
			p.append([Meshes.prism(w * 1.1, rh, d * 1.1), Meshes.xf(at + Vector3(0, wall_h + rh / 2.0, 0)), roof])
			for i in 5:
				p.append([Meshes.box(w * 1.08, 0.03, 0.06), Meshes.xf(at + Vector3(0, wall_h + 0.02 + i * rh * 0.16, -d * 0.52 + i * d * 0.1), Vector3(-25, 0, 0)), roof.darkened(0.12)])
			p.append([Meshes.box(0.24, h * 0.42, 0.05), Meshes.xf(at + Vector3(0, h * 0.21, d * 0.43)), roof.darkened(0.55)])
			top = at.y + wall_h + rh
		"ayutthaya":
			# Pabellón sobre pilotes; techos escalonados (más pisos con la edad) y remates dorados.
			for c in [Vector2(-1, -1), Vector2(1, -1), Vector2(-1, 1), Vector2(1, 1)]:
				p.append([Meshes.cyl(0.05, 0.05, h * 0.3, 6), Meshes.xf(at + Vector3(c.x * w * 0.4, h * 0.15, c.y * d * 0.38)), pal[2].darkened(0.3)])
			p.append([Meshes.box(w * 0.85, h * 0.45, d * 0.75), Meshes.xf(at + Vector3(0, h * 0.52, 0)), walls])
			var tiers := int(cfg.get("pisos_techo", 2))
			var y := h * 0.75
			var rh := h * 0.5 * rf
			for i in tiers:
				var k := 1.0 - i * 0.25
				p.append([Meshes.prism(w * k, rh * (1.0 - i * 0.12), d * 0.95 * k), Meshes.xf(at + Vector3(0, y + rh * 0.5, 0), Vector3(0, 90, 0)), roof.lightened(i * 0.06)])
				y += rh * 0.62
			var crest := y + rh * 0.3
			var trim: Color = gold if cfg.get("dorado", false) else pal[2]
			p.append([Meshes.box(0.05, 0.05, d * 0.7), Meshes.xf(at + Vector3(0, crest - rh * 0.05, 0)), trim])
			for z in [-1, 1]:
				p.append([Meshes.cyl(0.0, 0.04, 0.25 + (0.12 if cfg.get("dorado", false) else 0.0), 5), Meshes.xf(at + Vector3(0, crest + 0.08, z * d * 0.33), Vector3(z * 25, 0, 0)), trim])
			top = at.y + crest
			wall_h = h * 0.75
		"azotea":
			# Piedra revocada y techo plano con pretil, como las casas de patio de Harar.
			wall_h = h * 0.85
			p.append([Meshes.box(w, wall_h, d), Meshes.xf(at + Vector3(0, wall_h / 2.0, 0)), walls])
			p.append([Meshes.box(w + 0.06, 0.07, d + 0.06), Meshes.xf(at + Vector3(0, h * 0.88, 0)), roof])
			for side in [Vector2(0, -1), Vector2(0, 1), Vector2(-1, 0), Vector2(1, 0)]:
				var sz := Vector3(w + 0.06, 0.12, 0.06) if side.x == 0 else Vector3(0.06, 0.12, d + 0.06)
				p.append([Meshes.box(sz.x, sz.y, sz.z), Meshes.xf(at + Vector3(side.x * (w * 0.5), h * 0.97, side.y * (d * 0.5))), walls.darkened(0.08)])
			p.append([Meshes.box(0.24, h * 0.45, 0.05), Meshes.xf(at + Vector3(0, h * 0.22, d * 0.5 + 0.01)), pal[2]])
			top = at.y + h * 1.03
		_:
			p.append([Meshes.box(w, wall_h, d), Meshes.xf(at + Vector3(0, wall_h / 2.0, 0)), walls])
			var rh := h * 0.6 * rf
			p.append([Meshes.prism(w * 1.1, rh, d * 1.1), Meshes.xf(at + Vector3(0, wall_h + rh / 2.0, 0), Vector3(0, 90, 0)), roof])
			top = at.y + wall_h + rh
	# Lo que suma la edad, igual para todas las formas.
	var zc := float(cfg.get("zocalo_cm", 0)) / 100.0
	if zc > 0.0:
		var zcol := Color(cfg.get("zocalo", "#8c8478"))
		if is_round:
			var r2 := minf(w, d) * 0.48 + 0.04
			p.append([Meshes.cyl(r2, r2 + 0.03, zc, 16), Meshes.xf(at + Vector3(0, zc / 2.0, 0)), zcol])
		else:
			p.append([Meshes.box(w + 0.06, zc, d + 0.06), Meshes.xf(at + Vector3(0, zc / 2.0, 0)), zcol])
	_aparejo(p, str(cfg.get("aparejo", "")), at, w, d, wall_h, walls, is_round, forma)
	if cfg.get("horcones", false) and forma != "mapuche":
		_horcones(p, at, w, d, wall_h + 0.15)
	_remate(p, str(cfg.get("remate", "")), at + Vector3(0, top, 0) - Vector3(0, at.y, 0))


## Textura de piedra de los muros: pirca (piedra de campo saliente, irregular), piedra (bloques
## grises más grandes) o cantería (hiladas finas y parejas).
static func _aparejo(p: Array, kind: String, at: Vector3, w: float, d: float, wall_h: float, walls: Color, is_round: bool, forma: String) -> void:
	if kind == "" or kind == "adobe" or forma in ["mapuche", "guarani"] or wall_h < 0.25:
		return
	if kind == "canteria":
		var rows := int(wall_h / 0.16)
		for i in range(1, rows):
			var y := i * wall_h / rows
			if is_round:
				var r := minf(w, d) * 0.48 + 0.008
				p.append([Meshes.cyl(r, r, 0.02, 16), Meshes.xf(at + Vector3(0, y, 0)), walls.darkened(0.14)])
			else:
				p.append([Meshes.box(w + 0.016, 0.018, d + 0.016), Meshes.xf(at + Vector3(0, y, 0)), walls.darkened(0.14)])
		return
	var big := kind == "piedra"
	var n := 7 if big else 10
	for i in n:
		var hsh := (i * 2654435761) & 0xffff
		var u := float(hsh % 97) / 97.0
		var v := float((hsh / 97) % 89) / 89.0
		var sz := Vector3(0.16 + u * 0.1, 0.09 + v * 0.06, 0.05) * (1.4 if big else 1.0)
		var y := 0.08 + v * maxf(0.05, wall_h - 0.2)
		var col := walls.darkened(0.12 + 0.1 * u) if i % 2 == 0 else walls.lightened(0.06)
		if is_round:
			var r := minf(w, d) * 0.48
			var a := TAU * (float(i) + u * 0.6) / float(n)
			p.append([Meshes.box(sz.x, sz.y, sz.z), Meshes.xf(at + Vector3(sin(a) * r, y, cos(a) * r), Vector3(0, rad_to_deg(a), 0)), col])
		else:
			var side := i % 4
			var t := (u - 0.5) * 0.8
			var pos := Vector3(t * w, y, d * 0.5) if side == 0 else (Vector3(w * 0.5, y, t * d) if side == 1 else (Vector3(t * w, y, -d * 0.5) if side == 2 else Vector3(-w * 0.5, y, t * d)))
			p.append([Meshes.box(sz.x, sz.y, sz.z), Meshes.xf(at + pos, Vector3(0, 90.0 * side, 0)), col])


## Horcones tallados: postes de esquina con bandas pintadas (guaraníes en la edad III).
static func _horcones(p: Array, at: Vector3, w: float, d: float, hgt: float) -> void:
	for c in [Vector2(-1, -1), Vector2(1, -1), Vector2(-1, 1), Vector2(1, 1)]:
		var o := at + Vector3(c.x * w * 0.5, 0, c.y * d * 0.5)
		p.append([Meshes.cyl(0.05, 0.06, hgt, 6), Meshes.xf(o + Vector3(0, hgt / 2.0, 0)), Color("6e4a2a")])
		for i in 3:
			p.append([Meshes.cyl(0.064, 0.064, 0.05, 6), Meshes.xf(o + Vector3(0, hgt * (0.35 + i * 0.22), 0)), Color("8c2e1e") if i % 2 == 0 else Color("e8d8b0")])
		p.append([Meshes.sphere(0.08, 6), Meshes.xf(o + Vector3(0, hgt + 0.04, 0)), Color("6e4a2a")])


## Remate sobre el techo: punta de madera, cruz o aguja dorada.
static func _remate(p: Array, kind: String, at: Vector3) -> void:
	match kind:
		"punta":
			p.append([Meshes.cyl(0.0, 0.05, 0.4, 5), Meshes.xf(at + Vector3(0, 0.15, 0)), Palette.WOOD_BEAM])
		"cruz":
			p.append([Meshes.cyl(0.025, 0.025, 0.5, 4), Meshes.xf(at + Vector3(0, 0.2, 0)), Palette.WEALTH])
			p.append([Meshes.box(0.26, 0.04, 0.04), Meshes.xf(at + Vector3(0, 0.34, 0)), Palette.WEALTH])
			p.append([Meshes.sphere(0.06, 6), Meshes.xf(at + Vector3(0, 0.0, 0)), Color("f2ecdf")]) # huevo de avestruz
		"dorado":
			p.append([Meshes.cyl(0.0, 0.07, 0.6, 6), Meshes.xf(at + Vector3(0, 0.25, 0)), Palette.WEALTH, 0.3])


static func _center(p: Array, forma: String, w: float, d: float, pal: Array, team: Color, by: float, cfg: Dictionary = {}) -> void:
	var m := margin()
	var esc := minf(_f(cfg, "escala_pct"), 1.0)
	var cerco: Dictionary = cfg.get("cerco", {})
	var inner := 0.16 if not cerco.is_empty() else 0.0 # lo que ocupa el cerco
	if cerco.is_empty() and not cfg.has("tola_cm"):
		# Patio apisonado apenas elevado, con borde de piedras sueltas en lugar de una losa.
		for i in 16:
			var a := TAU * i / 16.0
			p.append([Meshes.sphere(0.12, 6), Meshes.xf(Vector3(cos(a) * w * 0.44, by + 0.05, sin(a) * d * 0.44), Vector3.ZERO, Vector3(1.3, 0.6, 1.0)), Palette.STONE.darkened(0.1)])
	var tola := float(cfg.get("tola_cm", 0)) / 100.0
	if tola > 0.0:
		# Tola caranqui: montículo de tierra bajo la casa principal.
		p.append([Meshes.cyl(w * 0.3, w * 0.42, tola, 14), Meshes.xf(Vector3(0, by + tola / 2.0, -d * 0.08)), Palette.DIRT.darkened(0.15)])
	var half_w := w / 2.0 - m - inner
	var half_d := d / 2.0 - m - inner
	var side := minf(w * 0.28, half_w * 0.6) * esc
	if str(cfg.get("centro_forma", "")) == "castillo":
		# La corte se asienta (Gondar): castillo de piedra en lugar de la casa principal, solo
		# dentro del cerco (las casas de los lados le tapaban el frente).
		HitosMeshes.castillo(p, Vector3(0, by, -d * 0.1), minf(w * 0.6, 2.0 * half_w - 0.7), d * 0.34, pal, cfg)
	else:
		# Casa principal ancha (proceso/24, 4p): casi todo el ancho útil y contra el fondo, así el
		# centro se lee más grande que un cuartel; las dos casas chicas quedan adelante.
		var mw := minf(w * 0.78, 2.0 * half_w - 0.1) * esc
		var md := minf(d * 0.58, 2.0 * half_d - side * 0.93 - 0.1) * esc
		_hut(p, forma, Vector3(0, by + tola, -half_d + md / 2.0), mw, md, 1.5, pal, cfg)
		var sx := half_w - side * 0.5
		var sz := half_d - side * 0.5
		_hut(p, forma, Vector3(-sx, by, sz), side, side * 0.93, 0.9, pal, cfg)
		_hut(p, forma, Vector3(sx, by, sz), side, side * 0.93, 0.9, pal, cfg)
	Meshes._banner(p, Vector3(w * 0.38, by, -d * 0.38), 2.6, team)
	Meshes._banner(p, Vector3(-w * 0.38, by, -d * 0.38), 2.6, team)
	decor_parts(p, w, d, team, cfg, true)


## Lo que suma la edad alrededor de un centro o un modelo generado: cerco, rewe y estandartes.
## `whole`: centro (cerco y rewe); si no, solo estandartes.
static func decor_parts(p: Array, w: float, d: float, team: Color, cfg: Dictionary, whole: bool) -> void:
	var m := margin()
	var cerco: Dictionary = cfg.get("cerco", {})
	if whole and not cerco.is_empty():
		_cerco(p, str(cerco.get("tipo", "pirca")), float(cerco.get("alto_cm", 60)) / 100.0, w / 2.0 - m, d / 2.0 - m, str(cerco.get("color", "")))
	var rewe := float(cfg.get("rewe_cm", 0)) / 100.0
	if whole and rewe > 0.0:
		# Rewe: poste escalonado tallado con canelo al lado (mapuches, desde la edad II).
		var at := Vector3(w / 2.0 - m - 0.25, 0, d / 2.0 - m - 0.25)
		p.append([Meshes.cyl(0.1, 0.13, rewe, 8), Meshes.xf(at + Vector3(0, rewe / 2.0, 0)), Palette.WOOD_BEAM])
		for i in 5:
			p.append([Meshes.box(0.26, 0.05, 0.1), Meshes.xf(at + Vector3(0, 0.3 + i * rewe / 6.0, 0.1)), Palette.TRUNK])
		p.append([Meshes.sphere(0.1, 8), Meshes.xf(at + Vector3(0, rewe + 0.06, 0)), Palette.WOOD_BEAM])
		p.append([Meshes.cyl(0.0, 0.22, 0.8, 7), Meshes.xf(at + Vector3(-0.3, 0.55, 0.0)), Palette.FOLIAGE])
		p.append([Meshes.cyl(0.03, 0.04, 0.25, 5), Meshes.xf(at + Vector3(-0.3, 0.12, 0.0)), Palette.TRUNK])
	var extra := int(cfg.get("estandartes", 0)) if whole else 0
	for i in extra:
		var sx := -1.0 if i % 2 == 0 else 1.0
		Meshes._banner(p, Vector3(sx * (w / 2.0 - m - 0.1), 0, d / 2.0 - m - 0.1), 2.2 + 0.3 * (i / 2), team)


## Cerco alrededor del centro, en el borde del margen (el pasillo de la huella queda libre).
## Deja una entrada al frente (+z, antes de la media vuelta de Meshes.face_camera).
## `color`: tono propio de la piedra (data/arte_edades.json → cerco.color); vacío, el del tipo.
static func _cerco(p: Array, tipo: String, hgt: float, hx: float, hz: float, color := "") -> void:
	var gap := 0.55
	var segs: Array = [] # [desde, hasta] en coordenadas: lados como [a, b]
	segs.append([Vector3(-hx, 0, -hz), Vector3(hx, 0, -hz)])
	segs.append([Vector3(-hx, 0, -hz), Vector3(-hx, 0, hz)])
	segs.append([Vector3(hx, 0, -hz), Vector3(hx, 0, hz)])
	segs.append([Vector3(-hx, 0, hz), Vector3(-gap, 0, hz)])
	segs.append([Vector3(gap, 0, hz), Vector3(hx, 0, hz)])
	match tipo:
		"empalizada", "empalizada_doble":
			for ring in (2 if tipo == "empalizada_doble" else 1):
				var inset := ring * 0.22
				var hh := hgt * (1.0 - ring * 0.25)
				for s: Array in segs:
					var a: Vector3 = s[0]
					var b: Vector3 = s[1]
					a = Vector3(signf(a.x) * (absf(a.x) - inset) if absf(a.x) >= hx - 0.01 else a.x, 0, signf(a.z) * (absf(a.z) - inset) if absf(a.z) >= hz - 0.01 else a.z)
					b = Vector3(signf(b.x) * (absf(b.x) - inset) if absf(b.x) >= hx - 0.01 else b.x, 0, signf(b.z) * (absf(b.z) - inset) if absf(b.z) >= hz - 0.01 else b.z)
					var n := maxi(1, int(a.distance_to(b) / 0.17))
					for i in n + 1:
						var o := a.lerp(b, float(i) / n)
						var lh := hh * (0.92 + 0.08 * float((i * 7) % 3) / 2.0)
						p.append([Meshes.cyl(0.07, 0.08, lh, 5), Meshes.xf(o + Vector3(0, lh / 2.0, 0)), Palette.WOOD_BEAM])
						p.append([Meshes.cyl(0.0, 0.07, 0.14, 5), Meshes.xf(o + Vector3(0, lh + 0.07, 0)), Palette.TRUNK])
		"tacuara":
			for s: Array in segs:
				var a: Vector3 = s[0]
				var b: Vector3 = s[1]
				var n := maxi(1, int(a.distance_to(b) / 0.3))
				for i in n + 1:
					p.append([Meshes.cyl(0.025, 0.025, hgt, 4), Meshes.xf(a.lerp(b, float(i) / n) + Vector3(0, hgt / 2.0, 0)), Color("b8a660")])
				var mid := (a + b) / 2.0
				var seg_len := a.distance_to(b)
				var along_x := absf(a.z - b.z) < 0.01
				for y in [hgt * 0.4, hgt * 0.8]:
					p.append([Meshes.box(seg_len if along_x else 0.03, 0.03, 0.03 if along_x else seg_len), Meshes.xf(mid + Vector3(0, y, 0)), Color("9a8a4a")])
		_:
			var col := Color("8f8778")
			if tipo == "canteria":
				col = Color("d6ccb6")
			elif tipo == "muro_blanco":
				col = Color("eee8dc")
			elif tipo == "pirca":
				col = Color("9a8c78")
			if color != "":
				col = Color(color)
			for s: Array in segs:
				var a: Vector3 = s[0]
				var b: Vector3 = s[1]
				var mid := (a + b) / 2.0
				var seg_len := a.distance_to(b) + 0.16
				var along_x := absf(a.z - b.z) < 0.01
				p.append([Meshes.box(seg_len if along_x else 0.16, hgt, 0.16 if along_x else seg_len), Meshes.xf(mid + Vector3(0, hgt / 2.0, 0)), col])
				if tipo == "muro_blanco":
					# Almenas en hoja (bai sema), no las cuadradas europeas.
					var n := maxi(1, int(seg_len / 0.32))
					for i in n:
						var o := a.lerp(b, (float(i) + 0.5) / n)
						p.append([Meshes.cyl(0.0, 0.09, 0.2, 4), Meshes.xf(o + Vector3(0, hgt + 0.1, 0), Vector3(0, 45, 0), Vector3(1, 1, 0.45)), col])
				elif tipo == "pirca":
					p.append([Meshes.box((seg_len if along_x else 0.16) + 0.02, 0.05, (0.16 if along_x else seg_len) + 0.02), Meshes.xf(mid + Vector3(0, hgt * 0.5, 0)), col.darkened(0.15)])
				else:
					p.append([Meshes.box((seg_len if along_x else 0.16) + 0.02, 0.04, (0.16 if along_x else seg_len) + 0.02), Meshes.xf(mid + Vector3(0, hgt, 0)), col.lightened(0.08)])


## Adornos de la edad para un modelo generado (GLB): cerco y rewe si es el centro, estandartes,
## remate a la altura `top` y horcones en las esquinas del cuerpo.
static func decor(type: String, def: Dictionary, team: Color, cfg: Dictionary, w: float, d: float, top: float, body: float) -> ArrayMesh:
	var key := "decor_%s_%s_%d_%d_%d_%d_%d" % [type, team.to_html(), str(cfg).hash(), int(w), int(d), int(top * 20.0), int(body * 20.0)]
	if _cache.has(key):
		return _cache[key]
	var p: Array = []
	decor_parts(p, w, d, team, cfg, _is_center(type, def))
	_remate(p, str(cfg.get("remate", "")), Vector3(0, top, 0))
	var zc := float(cfg.get("zocalo_cm", 0)) / 100.0
	if zc > 0.0 and not _is_center(type, def):
		# Zócalo de piedra bajo el modelo (tukul etíope desde la edad II).
		p.append([Meshes.cyl(body * 0.47, body * 0.5, zc, 16), Meshes.xf(Vector3(0, zc / 2.0, 0)), Color(cfg.get("zocalo", "#8c8478"))])
	if cfg.get("horcones", false):
		_horcones(p, Vector3.ZERO, body * 0.86, body * 0.86, minf(top * 0.45, 1.4))
	Meshes.face_camera(p) # la entrada del cerco, como el modelo, del lado de la cámara
	var mesh: ArrayMesh = Meshes.merge(p) if not p.is_empty() else null
	_cache[key] = mesh
	return mesh


static func _barracks(p: Array, forma: String, w: float, d: float, pal: Array, team: Color, by: float, type: String, cfg: Dictionary = {}) -> void:
	var iw := w - 2.0 * margin()
	var esc := minf(_f(cfg, "escala_pct"), 1.0)
	# Galpón hondo (proceso/24, 4p): al subir muros y techos no queda una lámina.
	_hut(p, forma, Vector3(0, by, -d * 0.14), minf(w * 0.85, iw) * esc, d * 0.52 * esc, 1.1, pal, cfg)
	for i in 5:
		p.append([Meshes.box(0.08, 0.42, 0.08), Meshes.xf(Vector3(-iw * 0.5 + i * iw * 0.25, by + 0.21, d * 0.38)), pal[1].darkened(0.3)])
	p.append([Meshes.box(iw, 0.06, 0.06), Meshes.xf(Vector3(0, by + 0.38, d * 0.38)), pal[1].darkened(0.3)])
	if type == "kraal":
		p.append([Meshes.box(iw, 0.06, 0.06), Meshes.xf(Vector3(0, by + 0.6, d * 0.38)), pal[1].darkened(0.3)])
		p.append([Meshes.cyl(0.22, 0.22, 0.6, 10), Meshes.xf(Vector3(w * 0.25, by + 0.3, d * 0.15)), Color("8c8478")])
	Meshes._banner(p, Vector3(-w * 0.4, by, d * 0.2), 2.0, team)
	Meshes._banner(p, Vector3(w * 0.4, by, d * 0.2), 2.0, team)


# --- veterano ronda 5 ---
## Mercado (proceso/24-tras-la-segunda-ronda/4r-veterano-ronda-5.md): un galpón de feria con la
## casa del pueblo al fondo, que se levanta al alto de su categoría (reglas.escala_visual →
## altura_min_cm.mercado), y adelante tres puestos con toldo a la escala de la gente: van
## marcados como fijos (Meshes.FIJO) para que no se estiren con el galpón.
static func _market(p: Array, forma: String, w: float, d: float, pal: Array, team: Color, by: float, cfg: Dictionary = {}) -> void:
	var iw := w - 2.0 * margin()
	var esc := minf(_f(cfg, "escala_pct"), 1.0)
	_hut(p, forma, Vector3(0, by, -d * 0.16), minf(w * 0.82, iw) * esc, d * 0.42 * esc, 1.15, pal, cfg)
	var sw := iw / 3.0
	for i in 3:
		var o := Vector3(-sw + i * sw, by, d * 0.27 - (i % 2) * d * 0.05)
		for c in [Vector2(-1, -1), Vector2(1, -1), Vector2(-1, 1), Vector2(1, 1)]:
			p.append([Meshes.box(0.05, 0.62, 0.05), Meshes.xf(o + Vector3(c.x * sw * 0.4, 0.31, c.y * 0.24)), pal[1].darkened(0.35), 0.0, Meshes.FIJO])
		p.append([Meshes.prism(sw * 0.98, 0.2, 0.6), Meshes.xf(o + Vector3(0, 0.72, 0)), [pal[1], Palette.WEALTH.darkened(0.2), team][i], 0.0, Meshes.FIJO])
		p.append([Meshes.box(sw * 0.7, 0.24, 0.3), Meshes.xf(o + Vector3(0, 0.12, 0)), pal[0].darkened(0.1), 0.0, Meshes.FIJO])
		# Mercadería sobre la mesa: un canasto y un fardo, del color de lo que se vende.
		p.append([Meshes.cyl(0.07, 0.06, 0.08, 8), Meshes.xf(o + Vector3(-sw * 0.15, 0.28, 0)), [Color("b0603c"), Color("8a6a3e"), Color("8c8478")][i], 0.0, Meshes.FIJO])
		p.append([Meshes.box(0.12, 0.08, 0.1), Meshes.xf(o + Vector3(sw * 0.15, 0.28, 0)), pal[2], 0.0, Meshes.FIJO])
	Meshes._banner(p, Vector3(w * 0.42, by, -d * 0.42), 1.8, team)
# --- fin veterano ronda 5 ---


static func _store(p: Array, forma: String, w: float, d: float, pal: Array, team: Color, by: float, cfg: Dictionary = {}) -> void:
	var hx := w / 2.0 - margin() - 0.05
	var hz := d / 2.0 - margin() - 0.05
	var hk := _f(cfg, "alto_pct")
	for c in [Vector2(-1, -1), Vector2(1, -1), Vector2(-1, 1), Vector2(1, 1)]:
		p.append([Meshes.box(0.1, 0.9 * hk, 0.1), Meshes.xf(Vector3(c.x * hx, by + 0.45 * hk, c.y * hz)), pal[1].darkened(0.35)])
	match forma:
		"etiopia", "mapuche", "redonda":
			p.append([Meshes.cyl(0.0, w * 0.5, 0.55 * _f(cfg, "techo_alto_pct"), 14), Meshes.xf(Vector3(0, by + 0.9 * hk + 0.25, 0)), pal[1]])
		"inca":
			p.append([Meshes.cyl(w * 0.24, w * 0.26, 0.7 * hk, 12), Meshes.xf(Vector3(-w * 0.1, by + 0.35 * hk, 0)), pal[0]])
			p.append([Meshes.cyl(0.0, w * 0.3, 0.45, 12), Meshes.xf(Vector3(-w * 0.1, by + 0.7 * hk + 0.22, 0)), pal[1]])
		"ayutthaya":
			p.append([Meshes.prism(w * 0.95, 0.45, d * 0.95), Meshes.xf(Vector3(0, by + 0.9 * hk + 0.2, 0)), pal[1]])
			if int(cfg.get("pisos_techo", 1)) >= 2:
				p.append([Meshes.prism(w * 0.6, 0.35, d * 0.6), Meshes.xf(Vector3(0, by + 0.9 * hk + 0.5, 0)), pal[1].lightened(0.06)])
		_:
			p.append([Meshes.prism(w * 0.95, 0.45, d * 0.95), Meshes.xf(Vector3(0, by + 0.9 * hk + 0.2, 0)), pal[1]])
	p.append([Meshes.box(0.45, 0.38, 0.45), Meshes.xf(Vector3(w * 0.12, by + 0.2, d * 0.08), Vector3(0, 15, 0)), pal[0].darkened(0.1)])
	p.append([Meshes.cyl(0.17, 0.19, 0.4), Meshes.xf(Vector3(-w * 0.1, by + 0.2, d * 0.15)), pal[2]])
	Meshes._banner(p, Vector3(w * 0.42, by, d * 0.42), 1.6, team)


## Torres según el pueblo (data/arte_edades.json → torres_por_forma y civs.*.torre). Solo
## la de los invasores europeos lleva almenas cuadradas. Huella de 2×2: el cuerpo no pasa de
## 1,4 de lado (margen de 0,3).
static func _tower(p: Array, kind: String, pal: Array, team: Color, cfg: Dictionary) -> void:
	var hk := _f(cfg, "torre_alto_pct")
	var stone: Color = pal[2]
	var r := 1.0 - margin() - 0.02 # medio lado útil
	var wood := Palette.WOOD_BEAM
	var flag_at := Vector3(0, 2.6 * hk, 0)
	match kind:
		"pukara":
			# Pukara inca: plataforma escalonada de pirca (o cantería), parapeto bajo sin almenas
			# y un refugio de vigía con techo de paja.
			var y := 0.0
			for i in 3:
				var s := (r - i * 0.16) * 2.0
				var th := 0.62 * hk
				p.append([Meshes.box(s, th, s), Meshes.xf(Vector3(0, y + th / 2.0, 0)), stone if i % 2 == 0 else stone.darkened(0.06)])
				_aparejo(p, str(cfg.get("aparejo", "pirca")), Vector3(0, y, 0), s, s, th, stone, false, "inca")
				y += th
			var s2 := (r - 0.32) * 2.0
			for side in [Vector2(0, -1), Vector2(0, 1), Vector2(-1, 0), Vector2(1, 0)]:
				var sz := Vector3(s2, 0.22, 0.1) if side.x == 0 else Vector3(0.1, 0.22, s2)
				p.append([Meshes.box(sz.x, sz.y, sz.z), Meshes.xf(Vector3(side.x * (s2 / 2.0 - 0.05), y + 0.11, side.y * (s2 / 2.0 - 0.05))), stone.lightened(0.05)])
			_hut(p, "inca", Vector3(-0.15, y, -0.15), 0.5, 0.5, 0.75, pal, {"aparejo": cfg.get("aparejo", "")})
			if cfg.get("dorado", false):
				p.append([Meshes.box(s2 + 0.04, 0.06, s2 + 0.04), Meshes.xf(Vector3(0, y - 0.03, 0)), Palette.WEALTH])
			flag_at = Vector3(0.35, y, 0.35)
		"cresta":
			# Fuerte de cresta andino: montículo de tierra, anillo de pirca y vigía de palos.
			stone = Color("9a8c78").lerp(pal[0], 0.25)
			p.append([Meshes.cyl(r * 0.75, r, 0.7 * hk, 12), Meshes.xf(Vector3(0, 0.35 * hk, 0)), Palette.DIRT.darkened(0.1)])
			p.append([Meshes.cyl(r * 0.72, r * 0.75, 0.45, 12), Meshes.xf(Vector3(0, 0.7 * hk + 0.22, 0)), stone])
			_aparejo(p, "pirca", Vector3(0, 0.7 * hk, 0), r * 1.45, r * 1.45, 0.45, stone, true, "redonda")
			var y := 0.7 * hk + 0.45
			for c in [Vector2(-1, -1), Vector2(1, -1), Vector2(-1, 1), Vector2(1, 1)]:
				p.append([Meshes.cyl(0.04, 0.05, 1.5 * hk, 5), Meshes.xf(Vector3(c.x * 0.28, y + 0.75 * hk, c.y * 0.28)), wood])
			p.append([Meshes.box(0.75, 0.06, 0.75), Meshes.xf(Vector3(0, y + 1.2 * hk, 0)), wood])
			p.append([Meshes.cyl(0.0, 0.55, 0.5, 8), Meshes.xf(Vector3(0, y + 1.5 * hk + 0.25, 0)), pal[1]])
			flag_at = Vector3(0, y + 1.5 * hk + 0.4, 0)
		"mangrullo":
			# Mangrullo: cuatro postes inclinados, travesaños en cruz, plataforma con baranda,
			# escalera y techito de paja. Madera y tacuara, nada de piedra.
			var top := 2.5 * hk
			var foot := r * 0.9
			var head := 0.38
			for c in [Vector2(-1, -1), Vector2(1, -1), Vector2(-1, 1), Vector2(1, 1)]:
				var a := Vector3(c.x * foot, 0, c.y * foot)
				var b := Vector3(c.x * head, top, c.y * head)
				_pole(p, a, b, 0.055, wood)
			for lvl in 2:
				var y0 := top * (0.18 + lvl * 0.38)
				var y1 := top * (0.52 + lvl * 0.38)
				var f0 := lerpf(foot, head, y0 / top)
				var f1 := lerpf(foot, head, minf(y1, top) / top)
				for side in 4:
					var dir := [Vector2(1, 0), Vector2(0, 1), Vector2(-1, 0), Vector2(0, -1)][side] as Vector2
					var nrm := Vector2(-dir.y, dir.x)
					var a := Vector3(nrm.x * f0 - dir.x * f0, y0, nrm.y * f0 - dir.y * f0)
					var b := Vector3(nrm.x * f1 + dir.x * f1, minf(y1, top), nrm.y * f1 + dir.y * f1)
					_pole(p, a, b, 0.025, wood.lightened(0.08))
			p.append([Meshes.box(head * 2.6, 0.07, head * 2.6), Meshes.xf(Vector3(0, top, 0)), wood.darkened(0.1)])
			for side in [Vector2(0, -1), Vector2(0, 1), Vector2(-1, 0), Vector2(1, 0)]:
				var sz := Vector3(head * 2.6, 0.04, 0.04) if side.x == 0 else Vector3(0.04, 0.04, head * 2.6)
				p.append([Meshes.box(sz.x, sz.y, sz.z), Meshes.xf(Vector3(side.x * head * 1.3, top + 0.35, side.y * head * 1.3)), wood])
			for c in [Vector2(-1, -1), Vector2(1, -1), Vector2(-1, 1), Vector2(1, 1)]:
				p.append([Meshes.cyl(0.025, 0.025, 0.85, 4), Meshes.xf(Vector3(c.x * head * 1.25, top + 0.42, c.y * head * 1.25)), wood])
			p.append([Meshes.prism(head * 3.0, 0.45, head * 3.0), Meshes.xf(Vector3(0, top + 1.05, 0)), pal[1]])
			# Escalera al frente.
			_pole(p, Vector3(-0.12, 0, foot + 0.05), Vector3(-0.12, top, head + 0.12), 0.02, wood)
			_pole(p, Vector3(0.12, 0, foot + 0.05), Vector3(0.12, top, head + 0.12), 0.02, wood)
			for i in 6:
				var t := (i + 0.5) / 6.0
				p.append([Meshes.box(0.26, 0.025, 0.025), Meshes.xf(Vector3(0, t * top, lerpf(foot + 0.05, head + 0.12, t))), wood])
			flag_at = Vector3(head * 1.25, top + 0.85, -head * 1.25)
		"amba":
			# Torre de la amba: piedra, cuadrada y algo ahusada, con vigas a la vista (cabezas de
			# mono, como en Aksum), techo plano con pretil y vigía de paja; en Gondar, cúpula.
			var hgt := 2.6 * hk
			p.append([Meshes.cyl(r * 0.92, r * 1.18, hgt, 4), Meshes.xf(Vector3(0, hgt / 2.0, 0), Vector3(0, 45, 0)), stone])
			_aparejo(p, str(cfg.get("aparejo", "piedra")), Vector3(0, 0, 0), r * 1.45, r * 1.45, hgt * 0.9, stone, false, "etiopia")
			for lvl in 3:
				var y := hgt * (0.3 + lvl * 0.25)
				var half := lerpf(r * 0.83, r * 0.65, y / hgt)
				for i in 3:
					var t := -0.5 + i * 0.5
					for side in [Vector2(0, 1), Vector2(0, -1), Vector2(1, 0), Vector2(-1, 0)]:
						var pos := Vector3(side.x * half + side.y * t * half, y, side.y * half + side.x * t * half)
						p.append([Meshes.cyl(0.035, 0.035, 0.1, 5), Meshes.xf(pos, Vector3(90, 0, 0) if side.x == 0 else Vector3(0, 0, 90)), Palette.WOOD_BEAM.darkened(0.2)])
			var tw := r * 1.32
			for side in [Vector2(0, -1), Vector2(0, 1), Vector2(-1, 0), Vector2(1, 0)]:
				var sz := Vector3(tw, 0.2, 0.08) if side.x == 0 else Vector3(0.08, 0.2, tw)
				p.append([Meshes.box(sz.x, sz.y, sz.z), Meshes.xf(Vector3(side.x * tw / 2.0, hgt + 0.1, side.y * tw / 2.0)), stone.lightened(0.06)])
			if cfg.get("torre_cupula", false):
				p.append([Meshes.sphere(0.42, 12), Meshes.xf(Vector3(0, hgt + 0.05, 0), Vector3.ZERO, Vector3(1, 0.9, 1)), stone.lightened(0.12)])
			else:
				p.append([Meshes.cyl(0.3, 0.3, 0.35, 10), Meshes.xf(Vector3(0, hgt + 0.18, 0)), pal[0]])
				p.append([Meshes.cyl(0.0, 0.45, 0.55 * _f(cfg, "techo_alto_pct"), 10), Meshes.xf(Vector3(0, hgt + 0.35 + 0.27 * _f(cfg, "techo_alto_pct"), 0)), pal[1]])
			p.append([Meshes.box(0.22, 0.4, 0.05), Meshes.xf(Vector3(0, 0.2, r * 1.1)), Palette.WOOD_BEAM])
			_remate(p, str(cfg.get("remate", "")), Vector3(0, hgt + (0.42 if cfg.get("torre_cupula", false) else 0.9), 0))
			flag_at = Vector3(tw / 2.0 - 0.05, hgt, tw / 2.0 - 0.05)
		"fortin_rio":
			# Fortín de río siamés: baluarte bajo de ladrillo encalado, almenas en hoja (bai sema)
			# y un pabellón con techo escalonado.
			var hgt := 1.5 * hk
			p.append([Meshes.cyl(r * 0.95, r * 1.08, hgt, 8), Meshes.xf(Vector3(0, hgt / 2.0, 0), Vector3(0, 22.5, 0)), Color("eee6d6")])
			p.append([Meshes.cyl(r * 1.1, r * 1.1, 0.12, 8), Meshes.xf(Vector3(0, hgt, 0), Vector3(0, 22.5, 0)), Color("e2d8c4")])
			for i in 12:
				var a := TAU * i / 12.0
				p.append([Meshes.cyl(0.0, 0.11, 0.26, 4), Meshes.xf(Vector3(cos(a) * r * 0.98, hgt + 0.18, sin(a) * r * 0.98), Vector3(0, -rad_to_deg(a) + 45, 0), Vector3(1, 1, 0.45)), Color("eee6d6")])
			p.append([Meshes.box(0.3, 0.45, 0.05), Meshes.xf(Vector3(0, 0.22, r * 1.0)), Palette.WOOD_BEAM.darkened(0.2)])
			_hut(p, "ayutthaya", Vector3(0, hgt - 0.1, 0), 0.85, 0.85, 1.0, pal, cfg)
			flag_at = Vector3(r * 0.7, hgt, -r * 0.7)
		"troncos":
			# Fuerte de troncos birmano: cerco cuadrado de troncos aguzados, plataforma y techito.
			var hgt := 2.2 * hk
			var half := r * 0.85
			for side in 4:
				for i in 7:
					var t := -1.0 + i * (2.0 / 6.0)
					var pos := [Vector3(t * half, 0, half), Vector3(half, 0, t * half), Vector3(t * half, 0, -half), Vector3(-half, 0, t * half)][side] as Vector3
					var lh := hgt * (0.95 + 0.05 * float(i % 2))
					p.append([Meshes.cyl(0.09, 0.1, lh, 6), Meshes.xf(pos + Vector3(0, lh / 2.0, 0)), pal[1].lightened(0.15)])
					p.append([Meshes.cyl(0.0, 0.09, 0.16, 6), Meshes.xf(pos + Vector3(0, lh + 0.08, 0)), Palette.TRUNK])
			p.append([Meshes.box(half * 2.0, 0.08, half * 2.0), Meshes.xf(Vector3(0, hgt * 0.8, 0)), wood])
			_hut(p, "ayutthaya", Vector3(0, hgt * 0.8, 0), 0.7, 0.7, 0.9, pal, cfg)
			flag_at = Vector3(half, hgt, -half)
		"jugol":
			# Torre del Jugol (Harar): piedra y argamasa revocada, cuadrada, techo plano con
			# pretil y ventanas pequeñas.
			var hgt := 2.7 * hk
			p.append([Meshes.cyl(r * 0.95, r * 1.12, hgt, 4), Meshes.xf(Vector3(0, hgt / 2.0, 0), Vector3(0, 45, 0)), pal[0]])
			var tw := r * 1.38
			p.append([Meshes.box(tw + 0.06, 0.08, tw + 0.06), Meshes.xf(Vector3(0, hgt, 0)), pal[1]])
			for side in [Vector2(0, -1), Vector2(0, 1), Vector2(-1, 0), Vector2(1, 0)]:
				var sz := Vector3(tw, 0.18, 0.07) if side.x == 0 else Vector3(0.07, 0.18, tw)
				p.append([Meshes.box(sz.x, sz.y, sz.z), Meshes.xf(Vector3(side.x * tw / 2.0, hgt + 0.12, side.y * tw / 2.0)), pal[0].darkened(0.06)])
				for lvl in 2:
					var y := hgt * (0.45 + lvl * 0.28)
					var half := lerpf(r * 0.8, r * 0.68, y / hgt)
					p.append([Meshes.box(0.12 if side.x == 0 else 0.04, 0.2, 0.04 if side.x == 0 else 0.12), Meshes.xf(Vector3(side.x * half, y, side.y * half)), pal[2].darkened(0.3)])
			p.append([Meshes.box(0.28, 0.5, 0.05), Meshes.xf(Vector3(0, 0.25, r * 1.08)), pal[2]])
			_remate(p, str(cfg.get("remate", "")), Vector3(0, hgt + 0.1, 0))
			flag_at = Vector3(tw / 2.0 - 0.05, hgt, -tw / 2.0 + 0.05)
		_:
			# Torre almenada europea (solo los invasores: el baluarte).
			var c0: Color = pal[0]
			p.append([Meshes.cyl(r * 0.85, r, 2.5 * hk, 10), Meshes.xf(Vector3(0, 1.25 * hk, 0)), c0])
			p.append([Meshes.cyl(r * 1.02, r * 0.92, 0.3, 10), Meshes.xf(Vector3(0, 2.5 * hk + 0.1, 0)), c0.lightened(0.08)])
			for i in 8:
				var a := TAU * i / 8.0
				p.append([Meshes.box(0.2, 0.25, 0.2), Meshes.xf(Vector3(cos(a) * r * 0.9, 2.5 * hk + 0.37, sin(a) * r * 0.9)), c0.lightened(0.08)])
			flag_at = Vector3(0, 2.5 * hk + 0.25, 0)
	Meshes._banner(p, flag_at, 1.2, team)


## Palo entre dos puntos (cilindro orientado).
static func _pole(p: Array, a: Vector3, b: Vector3, r: float, col: Color) -> void:
	var dir := b - a
	var seg_len := dir.length()
	if seg_len < 0.001:
		return
	var y := dir / seg_len
	var x := y.cross(Vector3.FORWARD)
	if x.length() < 0.01:
		x = y.cross(Vector3.RIGHT)
	x = x.normalized()
	var z := x.cross(y).normalized()
	p.append([Meshes.cyl(r, r, seg_len, 5), Transform3D(Basis(x, y, z), (a + b) / 2.0), col])


# ---------------------------------------------------------------- Obra

## Lo que acompaña la obra en cada etapa: 0 = cimientos (pilas de material), 1 = estructura
## (andamio y material), 2 = casi terminado (andamio arriba y material del techo). `hgt`: alto
## al que llega la obra. El cuerpo cortado lo pone Meshes.clip_below.
static func obra(stage: int, w: float, d: float, hgt: float, cfg: Dictionary) -> ArrayMesh:
	var mats: Array = cfg.get("obra_material", ["madera", "paja"])
	var key := "obra_%d_%d_%d_%d_%s" % [stage, int(w), int(d), int(hgt * 10.0), str(mats)]
	if _cache.has(key):
		return _cache[key]
	var p: Array = []
	var hx := w / 2.0 - margin() + 0.08
	var hz := d / 2.0 - margin() + 0.08
	var wood := Palette.WOOD_BEAM
	if stage >= 1:
		var top := maxf(0.6, hgt + 0.25)
		var posts: Array = [Vector2(-hx, -hz), Vector2(hx, -hz), Vector2(-hx, hz), Vector2(hx, hz)]
		if w >= 3:
			posts.append_array([Vector2(0, -hz), Vector2(0, hz)])
		if d >= 3:
			posts.append_array([Vector2(-hx, 0), Vector2(hx, 0)])
		for c: Vector2 in posts:
			p.append([Meshes.cyl(0.03, 0.035, top, 5), Meshes.xf(Vector3(c.x, top / 2.0, c.y)), wood.lightened(0.1)])
		var levels := maxi(1, int(top / 0.7))
		for i in levels:
			var y := (i + 1) * top / (levels + 0.3)
			p.append([Meshes.box(hx * 2.0, 0.035, 0.035), Meshes.xf(Vector3(0, y, hz)), wood])
			p.append([Meshes.box(hx * 2.0, 0.035, 0.035), Meshes.xf(Vector3(0, y, -hz)), wood])
			p.append([Meshes.box(0.035, 0.035, hz * 2.0), Meshes.xf(Vector3(hx, y, 0)), wood])
			p.append([Meshes.box(0.035, 0.035, hz * 2.0), Meshes.xf(Vector3(-hx, y, 0)), wood])
		# Tablón del andamio al frente.
		p.append([Meshes.box(hx * 1.6, 0.03, 0.18), Meshes.xf(Vector3(0, top * 0.7, hz - 0.1)), wood.lightened(0.2)])
	# Pilas de material junto a la obra (dentro de la huella, en el pasillo del frente).
	var mat: String = mats[0] if stage < 2 else mats[mini(1, mats.size() - 1)]
	var spots: Array = [Vector3(-hx * 0.55, 0, hz - 0.05), Vector3(hx * 0.6, 0, hz - 0.08)]
	if stage == 0:
		spots.append(Vector3(hx * 0.1, 0, -hz + 0.1))
	for s: Vector3 in spots:
		_pile(p, mat, s)
	Meshes.face_camera(p) # el tablón y las pilas, del lado de la puerta
	var mesh := Meshes.merge(p)
	_cache[key] = mesh
	return mesh


static func _pile(p: Array, mat: String, at: Vector3) -> void:
	match mat:
		"piedra", "adobe", "ladrillo":
			var col := Color("9a948a") if mat == "piedra" else (Color("a8744a") if mat == "adobe" else Color("a24a32"))
			var sz := Vector3(0.18, 0.1, 0.14) if mat != "piedra" else Vector3(0.2, 0.14, 0.18)
			for i in 6:
				var row := 0 if i < 3 else (1 if i < 5 else 2)
				var col_i := i - (0 if row == 0 else (3 if row == 1 else 5))
				p.append([Meshes.box(sz.x, sz.y, sz.z), Meshes.xf(at + Vector3(-0.2 + col_i * 0.2 + row * 0.1, sz.y * (row + 0.5), 0), Vector3(0, (i * 13) % 20 - 10, 0)), col.darkened(0.08 * (i % 2))])
		"madera", "tacuara":
			var col := Palette.WOOD_BEAM if mat == "madera" else Color("b8a660")
			var r := 0.06 if mat == "madera" else 0.03
			for i in 5:
				var row := 0 if i < 3 else 1
				var col_i := i - (0 if row == 0 else 3)
				p.append([Meshes.cyl(r, r, 0.7, 6), Meshes.xf(at + Vector3(0, r * (1 + row * 1.8), -0.12 + col_i * r * 2.1 + row * r), Vector3(0, 0, 90)), col.darkened(0.06 * (i % 2))])
		"paja":
			for i in 3:
				p.append([Meshes.cyl(0.08, 0.1, 0.5, 6), Meshes.xf(at + Vector3(-0.15 + i * 0.15, 0.09, 0), Vector3(0, 0, 90 + (i - 1) * 8)), Color("c9b06a").darkened(0.05 * i)])
## Campos: granjas, andenes, arrozales, chacras de roza, corrales y gult.
static func _field(p: Array, type: String, w: float, d: float, pal: Array, team: Color, def: Dictionary) -> void:
	var a := Palette.FIELD_A
	var b := Palette.FIELD_B
	if def.get("bono_agua_pct", 0) > 0:
		a = Color("6f9a7a")
		b = Color("4f7d6a")
	elif def.get("tasa_clave", "") == "roza":
		a = Color("8a7a4a")
		b = Color("6d7a3a")
	if def.get("permite_ladera", false):
		for i in 3:
			p.append([Meshes.box(w - 0.2 - i * 0.5, 0.25, d - 0.2 - i * 0.5), Meshes.xf(Vector3(0, 0.12 + i * 0.25, 0)), pal[2] if i % 2 == 0 else pal[2].darkened(0.1)])
			p.append([Meshes.box(w - 0.3 - i * 0.5, 0.06, d - 0.3 - i * 0.5), Meshes.xf(Vector3(0, 0.27 + i * 0.25, 0)), a if i % 2 == 0 else b])
		return
	if type == "corral" or def.has("renta"):
		p.append([Meshes.box(w - 0.1, 0.05, d - 0.1), Meshes.xf(Vector3(0, 0.025, 0)), b if type == "corral" else a])
		var n := 8
		for i in n:
			var t := float(i) / n
			for side in 4:
				var pos := Vector3(lerpf(-w / 2, w / 2, t) if side < 2 else (-w / 2 if side == 2 else w / 2), 0.25, (-d / 2 if side == 0 else d / 2) if side < 2 else lerpf(-d / 2, d / 2, t))
				p.append([Meshes.box(0.07, 0.5, 0.07), Meshes.xf(pos), pal[1].darkened(0.35)])
		if type == "corral":
			for i in 3:
				p.append([Meshes.capsule(0.16, 0.5), Meshes.xf(Vector3(-0.6 + i * 0.6, 0.25, (i % 2) * 0.5 - 0.2), Vector3(0, 0, 90)), Color("8a6a4a") if i != 1 else Color("e8e0d0")])
		else:
			_hut(p, "", Vector3(w * 0.3, 0.0, -d * 0.3), 0.8, 0.8, 0.7, pal)
		Meshes._banner(p, Vector3(w / 2 - 0.1, 0.0, d / 2 - 0.1), 1.3, team)
		return
	p.append([Meshes.box(w - 0.1, 0.06, d - 0.1), Meshes.xf(Vector3(0, 0.03, 0)), b])
	for i in 6:
		p.append([Meshes.box(w - 0.4, 0.09, 0.22), Meshes.xf(Vector3(0, 0.07, -d * 0.38 + i * d * 0.153)), a])
	p.append([Meshes.box(0.08, 0.12, 0.2), Meshes.xf(Vector3(w / 2 - 0.1, 0.32, -d / 2 + 0.1)), team])


# ---------------------------------------------------------------- Hitos

## Monumento por civilización: variante 0 = opción económica, 1 = militar; `tier` = edad de destino.
static func _monument(p: Array, forma: String, variant: int, tier: int, w: float, d: float, pal: Array, team: Color) -> void:
	var stone: Color = pal[2]
	var gold := Palette.WEALTH
	match forma:
		"inca":
			if variant == 0:
				var steps := 3 + tier
				for i in steps:
					var s := w - 0.2 - i * (w - 1.2) / steps
					p.append([Meshes.box(s, 0.38, s), Meshes.xf(Vector3(0, 0.19 + i * 0.38, 0)), stone if i % 2 == 0 else stone.darkened(0.08)])
				p.append([Meshes.box(0.7, 0.2, 0.7), Meshes.xf(Vector3(0, steps * 0.38 + 0.1, 0)), gold, 0.3])
			else:
				_walls(p, w, d, stone, 0.9)
				_hut(p, "inca", Vector3(0, 0, -0.2), w * 0.45, d * 0.4, 1.6, pal)
		"mapuche":
			# Rewe: poste escalonado tallado, canelo y círculo de piedras.
			p.append([Meshes.cyl(w * 0.45, w * 0.48, 0.1, 18), Meshes.xf(Vector3(0, 0.05, 0)), Palette.DIRT])
			var hgt := 2.2 + tier * 0.3
			p.append([Meshes.cyl(0.14, 0.18, hgt, 8), Meshes.xf(Vector3(0, hgt / 2, 0)), Palette.WOOD_BEAM])
			for i in 5:
				p.append([Meshes.box(0.36, 0.05, 0.12), Meshes.xf(Vector3(0, 0.3 + i * hgt / 6.0, 0.14)), Palette.TRUNK])
			p.append([Meshes.sphere(0.13, 8), Meshes.xf(Vector3(0, hgt + 0.08, 0)), Palette.WOOD_BEAM])
			p.append([Meshes.cyl(0.0, 0.45, 1.3, 8), Meshes.xf(Vector3(0.7, 1.1, 0.3)), Palette.FOLIAGE])
			p.append([Meshes.cyl(0.05, 0.06, 0.5, 6), Meshes.xf(Vector3(0.7, 0.25, 0.3)), Palette.TRUNK])
			for i in 12:
				var a := TAU * i / 12.0
				p.append([Meshes.sphere(0.12, 6), Meshes.xf(Vector3(cos(a) * w * 0.4, 0.08, sin(a) * d * 0.4)), Palette.STONE])
			if variant == 1:
				_hut(p, "mapuche", Vector3(-0.6, 0, -0.8), 1.6, 1.1, 1.0, pal)
				for i in 3:
					Meshes._banner(p, Vector3(-w * 0.35 + i * w * 0.35, 0, -d * 0.42), 1.8, team)
		"guarani":
			if variant == 0:
				_hut(p, "guarani", Vector3(0, 0, 0), w * 0.85, d * 0.7, 1.9 + tier * 0.2, pal)
			else:
				# Iglesia de misión: nave, frente con frontón y campanario.
				p.append([Meshes.box(w * 0.5, 1.6, d * 0.8), Meshes.xf(Vector3(0, 0.8, 0)), pal[0].lightened(0.15)])
				p.append([Meshes.prism(w * 0.56, 0.8, d * 0.84), Meshes.xf(Vector3(0, 2.0, 0)), Color("9e4a32")])
				p.append([Meshes.box(0.65, 2.6, 0.65), Meshes.xf(Vector3(w * 0.36, 1.3, d * 0.25)), pal[0].lightened(0.1)])
				p.append([Meshes.cyl(0.0, 0.45, 0.6, 4), Meshes.xf(Vector3(w * 0.36, 2.9, d * 0.25), Vector3(0, 45, 0)), Color("9e4a32")])
				p.append([Meshes.box(0.05, 0.4, 0.05), Meshes.xf(Vector3(0, 2.6, d * 0.42)), Palette.WOOD_BEAM])
				p.append([Meshes.box(0.25, 0.05, 0.05), Meshes.xf(Vector3(0, 2.68, d * 0.42)), Palette.WOOD_BEAM])
		"etiopia":
			if variant == 0:
				# Iglesia redonda con tambor y cruz.
				p.append([Meshes.cyl(w * 0.45, w * 0.48, 0.3, 20), Meshes.xf(Vector3(0, 0.15, 0)), stone])
				p.append([Meshes.cyl(w * 0.36, w * 0.36, 1.3, 20), Meshes.xf(Vector3(0, 0.95, 0)), pal[0]])
				p.append([Meshes.cyl(0.0, w * 0.48, 1.2, 20), Meshes.xf(Vector3(0, 2.2, 0)), pal[1]])
				p.append([Meshes.cyl(0.03, 0.03, 0.6, 4), Meshes.xf(Vector3(0, 3.1, 0)), gold])
				p.append([Meshes.box(0.35, 0.04, 0.04), Meshes.xf(Vector3(0, 3.2, 0)), gold])
			else:
				# Castillo de Gondar: torre cuadrada con cúpulas en las esquinas.
				_walls(p, w, d, stone, 0.8)
				p.append([Meshes.box(w * 0.45, 2.4, d * 0.45), Meshes.xf(Vector3(0, 1.2, 0)), stone.lightened(0.05)])
				for c in [Vector2(-1, -1), Vector2(1, -1), Vector2(-1, 1), Vector2(1, 1)]:
					p.append([Meshes.cyl(0.32, 0.32, 2.7, 10), Meshes.xf(Vector3(c.x * w * 0.24, 1.35, c.y * d * 0.24)), stone.lightened(0.1)])
					p.append([Meshes.sphere(0.34, 10), Meshes.xf(Vector3(c.x * w * 0.24, 2.75, c.y * d * 0.24)), pal[2].darkened(0.2)])
		"palmares":
			# Cercas en anillo con mocambos adentro; la variante militar suma la herrería.
			for ring in 1 + mini(tier, 2):
				var r := w * (0.48 - ring * 0.1)
				for i in 22:
					var a := TAU * i / 22.0
					if variant == 0 and i == 5:
						continue
					p.append([Meshes.cyl(0.07, 0.08, 1.0 - ring * 0.1, 5), Meshes.xf(Vector3(cos(a) * r, 0.5, sin(a) * r)), Palette.WOOD_BEAM])
			_hut(p, "palmares", Vector3(-0.3, 0, -0.3), 1.4, 1.1, 1.1, pal)
			if variant == 1:
				p.append([Meshes.box(0.6, 0.6, 0.6), Meshes.xf(Vector3(0.7, 0.3, 0.6)), Color("6f6a64")])
				p.append([Meshes.cyl(0.12, 0.15, 1.0, 6), Meshes.xf(Vector3(0.7, 1.0, 0.6)), Color("5f5a54")])
			Meshes._banner(p, Vector3(0.9, 0, -0.9), 2.2, team)
		"ayutthaya":
			if variant == 0:
				# Chedi: base escalonada blanca, campana y aguja dorada.
				for i in 3:
					var s := w * (0.9 - i * 0.18)
					p.append([Meshes.box(s, 0.3, s), Meshes.xf(Vector3(0, 0.15 + i * 0.3, 0)), Color("ede6d6")])
				p.append([Meshes.sphere(0.5, 16), Meshes.xf(Vector3(0, 1.5, 0), Vector3.ZERO, Vector3(w * 0.42, 1.6, w * 0.42)), Color("f2ecdf")])
				p.append([Meshes.cyl(0.0, 0.3, 1.8 + tier * 0.3, 12), Meshes.xf(Vector3(0, 3.0 + tier * 0.15, 0)), gold, 0.35])
			else:
				_walls(p, w, d, Color("e6dfcf"), 0.8)
				_hut(p, "ayutthaya", Vector3(0, 0.1, -0.2), w * 0.55, d * 0.45, 1.6, pal)
		_:
			p.append([Meshes.box(w - 0.1, 0.5, d - 0.1), Meshes.xf(Vector3(0, 0.25, 0)), stone])
	for c in [Vector2(-1, -1), Vector2(1, 1)]:
		Meshes._banner(p, Vector3(c.x * w * 0.44, 0.1, c.y * d * 0.44), 1.4, team)


static func _walls(p: Array, w: float, d: float, col: Color, hgt: float) -> void:
	# El lado de afuera del muro queda en el borde del margen (docs/07).
	var e := margin() + 0.15
	for side in [Vector3(0, 0, -1), Vector3(0, 0, 1)]:
		p.append([Meshes.box(w - 2.0 * margin(), hgt, 0.3), Meshes.xf(Vector3(0, hgt / 2, side.z * (d / 2 - e))), col])
	for side in [Vector3(-1, 0, 0), Vector3(1, 0, 0)]:
		p.append([Meshes.box(0.3, hgt, d - 2.0 * margin()), Meshes.xf(Vector3(side.x * (w / 2 - e), hgt / 2, 0)), col])
	for i in 6:
		var o := -w / 2 + e + 0.15 + i * (w - 2.0 * e - 0.3) / 5.0
		for c in [Vector3(o, hgt + 0.1, -(d / 2 - e)), Vector3(o, hgt + 0.1, d / 2 - e)]:
			p.append([Meshes.box(0.22, 0.2, 0.22), Meshes.xf(c), col.lightened(0.06)])


# ---------------------------------------------------------------- Unidades

## Unidad de maqueta; `cfg`: aspecto de la edad (data/arte_edades.json → tropa).
static func unit(type: String, def: Dictionary, team: Color, style: Dictionary, cfg: Dictionary = {}) -> ArrayMesh:
	var forma: String = style.get("forma", "")
	var tropa: Dictionary = cfg.get("tropa", {}) if def.get("funcion", "civil") != "civil" else {}
	var key := "u_%s_%s_%s_%s_%d" % [forma, style.get("arcilla", ""), type, team.to_html(), str(tropa).hash()]
	if _cache.has(key):
		return _cache[key]
	var p: Array = []
	var pal := _pal(style)
	var fn: String = def.get("funcion", "civil")
	var rider_y := 0.0
	if def.get("elefante", false):
		_elephant(p, team, pal)
		rider_y = 1.55
	elif def.get("montado", false):
		_horse(p, team)
		rider_y = 0.62
	if def.has("despliega_en"):
		_mobile_court(p, team, pal)
	else:
		_person(p, fn, Vector3(0, rider_y, 0), team, pal, forma, def, tropa)
	var mesh := Meshes.merge(p)
	_cache[key] = mesh
	return mesh


static func _person(p: Array, fn: String, at: Vector3, team: Color, pal: Array, forma: String, def: Dictionary, tropa: Dictionary = {}) -> void:
	var clay := Palette.CLAY
	var cloth: Color = Color(tropa["tela"]) if tropa.has("tela") else pal[0].lightened(0.2)
	var big := fn == "choque" or fn == "linea"
	var r := 0.2 if big else 0.16
	p.append([Meshes.capsule(r, 0.68), Meshes.xf(at + Vector3(0, 0.34, 0)), cloth])
	p.append([Meshes.sphere(0.12), Meshes.xf(at + Vector3(0, 0.8, 0)), clay])
	p.append([Meshes.cyl(r + 0.006, r + 0.006, 0.09), Meshes.xf(at + Vector3(0, 0.48, 0)), team])
	match forma:
		"inca":
			p.append([Meshes.cyl(0.125, 0.125, 0.05, 10), Meshes.xf(at + Vector3(0, 0.86, 0)), Color("a63a2a")]) # llawtu
			p.append([Meshes.box(r * 1.6, 0.12, 0.05), Meshes.xf(at + Vector3(0, 0.3, r * 0.9)), Color("e2b13c")]) # tocapu del unku
		"mapuche":
			p.append([Meshes.cyl(0.126, 0.126, 0.035, 10), Meshes.xf(at + Vector3(0, 0.86, 0)), Color("c9ccd2")]) # trarilonko
			p.append([Meshes.box(r * 2.6, 0.32, r * 1.8), Meshes.xf(at + Vector3(0, 0.58, 0)), Color(tropa.get("tela", "#3b3a44"))]) # poncho
		"guarani":
			for i in 7:
				var a := -0.9 + i * 0.3
				p.append([Meshes.cyl(0.0, 0.025, 0.22, 4), Meshes.xf(at + Vector3(sin(a) * 0.1, 0.98, -cos(a) * 0.06), Vector3(-15, rad_to_deg(a), 0)), Color("d94a2a") if i % 2 == 0 else Color("f2c94a")])
		"etiopia":
			p.append([Meshes.box(r * 2.3, 0.5, r * 1.6), Meshes.xf(at + Vector3(0, 0.45, 0), Vector3(0, 0, 12)), Color("f2eee4")]) # shamma
		"palmares":
			p.append([Meshes.cyl(0.13, 0.12, 0.08, 10), Meshes.xf(at + Vector3(0, 0.88, 0)), Color("c9a24a")]) # turbante
		"ayutthaya":
			if fn != "civil":
				p.append([Meshes.cyl(0.0, 0.12, 0.35, 10), Meshes.xf(at + Vector3(0, 1.02, 0)), Palette.WEALTH]) # lomphok
	# Equipo de la edad: casco (cuero, metal, fibra), pectoral de oro.
	if tropa.has("casco") and fn != "explorador":
		p.append([Meshes.sphere(0.135, 10), Meshes.xf(at + Vector3(0, 0.84, 0), Vector3.ZERO, Vector3(1, 0.62, 1)), Color(tropa["casco"])])
	if tropa.get("oro", false):
		p.append([Meshes.cyl(0.075, 0.075, 0.02, 10), Meshes.xf(at + Vector3(0, 0.6, r + 0.005), Vector3(90, 0, 0)), Palette.WEALTH, 0.25])
	var wood := Palette.WOOD_BEAM
	match fn:
		"choque":
			p.append([Meshes.cyl(0.025, 0.03, 0.5, 6), Meshes.xf(at + Vector3(0.27, 0.55, 0.12), Vector3(35, 0, 0)), wood])
			p.append([Meshes.sphere(0.09, 8) if forma != "ayutthaya" else Meshes.box(0.06, 0.06, 0.4), Meshes.xf(at + Vector3(0.27, 0.74, 0.27)), Palette.CLAY_DARK])
		"distancia":
			if def.get("polvora", false):
				p.append([Meshes.cyl(0.025, 0.025, 0.7, 6), Meshes.xf(at + Vector3(0.12, 0.62, 0.22), Vector3(80, 0, 0)), Color("4a4540")])
			elif def.has("frena_ms"):
				for i in 3:
					p.append([Meshes.sphere(0.04, 5), Meshes.xf(at + Vector3(0.12 + i * 0.05, 0.85, 0.32)), Palette.STONE_DARK])
				p.append([Meshes.cyl(0.01, 0.01, 0.35, 4), Meshes.xf(at + Vector3(0.12, 0.72, 0.2), Vector3(60, 0, 0)), wood])
			elif forma in ["guarani", "mapuche", "ayutthaya", "palmares"]:
				p.append([Meshes.cyl(0.015, 0.015, 0.9, 6), Meshes.xf(at + Vector3(0.18, 0.55, 0.12), Vector3(0, 0, 8)), wood]) # arco
			else:
				p.append([Meshes.cyl(0.018, 0.018, 0.42, 6), Meshes.xf(at + Vector3(0.12, 0.66, 0.2), Vector3(70, 0, 0)), wood])
				p.append([Meshes.sphere(0.05, 6), Meshes.xf(at + Vector3(0.12, 0.74, 0.4)), Palette.STONE_DARK])
		"linea":
			if tropa.has("escudo_borde"):
				p.append([Meshes.cyl(0.3, 0.3, 0.04, 16) if forma != "inca" else Meshes.box(0.52, 0.52, 0.04), Meshes.xf(at + Vector3(0.02, 0.48, 0.21), Vector3(90, 0, 0) if forma != "inca" else Vector3.ZERO), Color(tropa["escudo_borde"])])
			p.append([Meshes.cyl(0.26, 0.26, 0.05, 16) if forma != "inca" else Meshes.box(0.45, 0.45, 0.05), Meshes.xf(at + Vector3(0.02, 0.48, 0.24), Vector3(90, 0, 0) if forma != "inca" else Vector3.ZERO), team])
			p.append([Meshes.cyl(0.018, 0.018, 1.7, 6), Meshes.xf(at + Vector3(-0.24, 0.85, 0.05)), wood])
			p.append([Meshes.cyl(0.0, 0.045, 0.16, 6), Meshes.xf(at + Vector3(-0.24, 1.75, 0.05)), Palette.CLAY_DARK])
		"asedio":
			p.append([Meshes.box(0.3, 0.3, 0.6), Meshes.xf(at + Vector3(0, 0.15, 0.5)), wood])
		"explorador":
			p.append([Meshes.cyl(0.015, 0.015, 1.0, 6), Meshes.xf(at + Vector3(0.16, 0.5, 0.12), Vector3(18, 0, 0)), wood])


static func _horse(p: Array, team: Color) -> void:
	var coat := Color("7a5a3e")
	p.append([Meshes.capsule(0.2, 0.95), Meshes.xf(Vector3(0, 0.55, 0), Vector3(90, 0, 0)), coat])
	p.append([Meshes.capsule(0.09, 0.45), Meshes.xf(Vector3(0, 0.78, 0.48), Vector3(-30, 0, 0)), coat])
	p.append([Meshes.box(0.12, 0.14, 0.28), Meshes.xf(Vector3(0, 0.93, 0.62)), coat.darkened(0.1)])
	for c in [Vector2(-1, -1), Vector2(1, -1), Vector2(-1, 1), Vector2(1, 1)]:
		p.append([Meshes.cyl(0.04, 0.045, 0.45, 6), Meshes.xf(Vector3(c.x * 0.1, 0.22, c.y * 0.3)), coat.darkened(0.25)])
	p.append([Meshes.box(0.42, 0.06, 0.4), Meshes.xf(Vector3(0, 0.74, 0)), team])


static func _elephant(p: Array, team: Color, pal: Array) -> void:
	var hide := Color("8c8478")
	p.append([Meshes.capsule(0.55, 1.6), Meshes.xf(Vector3(0, 1.0, 0), Vector3(90, 0, 0), Vector3(1, 1, 1)), hide])
	p.append([Meshes.sphere(0.42, 12), Meshes.xf(Vector3(0, 1.25, 0.8)), hide])
	p.append([Meshes.cyl(0.07, 0.15, 0.9, 8), Meshes.xf(Vector3(0, 0.75, 1.15), Vector3(20, 0, 0)), hide.darkened(0.08)])
	for x in [-1, 1]:
		p.append([Meshes.cyl(0.0, 0.05, 0.5, 6), Meshes.xf(Vector3(x * 0.2, 0.95, 1.15), Vector3(70, 0, 0)), Color("f2ecdf")])
		p.append([Meshes.box(0.06, 0.5, 0.45), Meshes.xf(Vector3(x * 0.45, 1.3, 0.7)), hide.darkened(0.12)])
	for c in [Vector2(-1, -1), Vector2(1, -1), Vector2(-1, 1), Vector2(1, 1)]:
		p.append([Meshes.cyl(0.16, 0.18, 0.75, 8), Meshes.xf(Vector3(c.x * 0.3, 0.37, c.y * 0.5)), hide])
	p.append([Meshes.box(0.75, 0.35, 0.7), Meshes.xf(Vector3(0, 1.7, -0.1)), Palette.WOOD_BEAM])
	p.append([Meshes.box(0.85, 0.08, 0.8), Meshes.xf(Vector3(0, 1.55, -0.1)), team])
	p.append([Meshes.prism(0.8, 0.35, 0.75), Meshes.xf(Vector3(0, 2.05, -0.1)), pal[1]])


static func _mobile_court(p: Array, team: Color, pal: Array) -> void:
	for x in [-1, 1]:
		p.append([Meshes.cyl(0.25, 0.25, 0.1, 12), Meshes.xf(Vector3(x * 0.55, 0.25, 0.4), Vector3(0, 0, 90)), Palette.TRUNK])
		p.append([Meshes.cyl(0.25, 0.25, 0.1, 12), Meshes.xf(Vector3(x * 0.55, 0.25, -0.4), Vector3(0, 0, 90)), Palette.TRUNK])
	p.append([Meshes.box(1.1, 0.2, 1.4), Meshes.xf(Vector3(0, 0.45, 0)), Palette.WOOD_BEAM])
	p.append([Meshes.cyl(0.0, 0.75, 1.0, 12), Meshes.xf(Vector3(0, 1.05, 0)), Color("e8dcc6")])
	p.append([Meshes.cyl(0.45, 0.6, 0.3, 12), Meshes.xf(Vector3(0, 0.7, 0)), pal[1]])
	Meshes._banner(p, Vector3(0, 0.5, -0.6), 1.6, team)
