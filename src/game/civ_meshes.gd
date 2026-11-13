class_name CivMeshes
extends RefCounted
## Arquitectura y vestimenta propias de cada civilización (docs/07). Se reconocen por silueta:
## inca (piedra y paja a cuatro aguas), mapuche (ruka ovalada), guaraní (casa larga hasta el suelo),
## etiópica (tukul redondo), palmarista (choza de palma y cercas), siamesa (techos escalonados rojos).

static var _cache := {}



static func _pal(style: Dictionary) -> Array:
	return [Color(style.get("arcilla", "#eee7da")), Color(style.get("techo", "#a9927a")), Color(style.get("acento", "#b8ab93"))]


# ---------------------------------------------------------------- Edificios

static func building(type: String, def: Dictionary, team: Color, style: Dictionary, variant: int, tier: int) -> ArrayMesh:
	var forma: String = style.get("forma", "")
	var key := "%s_%s_%s_%d_%d" % [forma, type, team.to_html(), variant, tier]
	if _cache.has(key):
		return _cache[key]
	var pal := _pal(style)
	var p: Array = []
	var w: float = def["tam"][0]
	var d: float = def["tam"][1]
	var base_y := 0.0
	if not def.get("transitable", false) and not def.get("camino", false):
		p.append([Meshes.box(w - 0.15, 0.14, d - 0.15), Meshes.xf(Vector3(0, 0.07, 0)), Palette.DIRT.lerp(pal[0], 0.35).darkened(0.1)])
		base_y = 0.14
	if def.get("avanza_edad", false):
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
	elif (def.get("produce", []) as Array).has("aldeano") or def.get("cuenta_victoria", false) or def.get("acoge", false) or type == "centro":
		_center(p, forma, w, d, pal, team, base_y)
	elif type == "torre":
		_tower(p, forma, pal, team, base_y)
	elif def.get("mercado", false):
		for i in 3:
			var o := Vector3(-w * 0.3 + i * w * 0.3, base_y, d * 0.1 - (i % 2) * d * 0.25)
			for c in [Vector2(-1, -1), Vector2(1, -1), Vector2(-1, 1), Vector2(1, 1)]:
				p.append([Meshes.box(0.06, 0.8, 0.06), Meshes.xf(o + Vector3(c.x * 0.32, 0.4, c.y * 0.32)), pal[1].darkened(0.35)])
			p.append([Meshes.prism(0.8, 0.3, 0.8), Meshes.xf(o + Vector3(0, 0.95, 0)), [pal[1], Palette.WEALTH.darkened(0.2), team][i]])
			p.append([Meshes.box(0.6, 0.3, 0.4), Meshes.xf(o + Vector3(0, 0.15, 0)), pal[0].darkened(0.1)])
		Meshes._banner(p, Vector3(w * 0.42, base_y, -d * 0.42), 1.8, team)
	elif def.has("produce"):
		_barracks(p, forma, w, d, pal, team, base_y, type)
	elif def.has("deposito"):
		_store(p, forma, w, d, pal, team, base_y)
	else:
		_hut(p, forma, Vector3(0, base_y, 0), w * 0.78, d * 0.72, 0.9, pal)
		Meshes._banner(p, Vector3(w * 0.38, base_y, d * 0.38), 1.5, team)
	var mesh := Meshes.merge(p)
	_cache[key] = mesh
	return mesh


## Casa típica de cada civilización, apoyada en `at`.
static func _hut(p: Array, forma: String, at: Vector3, w: float, d: float, h: float, pal: Array) -> void:
	var walls: Color = pal[0]
	var roof: Color = pal[1]
	match forma:
		"inca":
			# Muros de piedra en hiladas, puerta trapezoidal y techo de paja a cuatro aguas.
			p.append([Meshes.box(w, h * 0.75, d), Meshes.xf(at + Vector3(0, h * 0.375, 0)), walls])
			p.append([Meshes.box(w + 0.02, 0.05, d + 0.02), Meshes.xf(at + Vector3(0, h * 0.25, 0)), walls.darkened(0.12)])
			p.append([Meshes.box(w + 0.02, 0.05, d + 0.02), Meshes.xf(at + Vector3(0, h * 0.5, 0)), walls.darkened(0.12)])
			p.append([Meshes.cyl(0.0, maxf(w, d) * 0.78, h * 0.85, 4), Meshes.xf(at + Vector3(0, h * 0.75 + h * 0.42, 0), Vector3(0, 45, 0), Vector3(w / maxf(w, d), 1, d / maxf(w, d))), roof])
			p.append([Meshes.box(0.22, h * 0.45, 0.04), Meshes.xf(at + Vector3(0, h * 0.22, d * 0.5 + 0.01)), roof.darkened(0.5)])
		"mapuche":
			# Ruka: domo ovalado de paja que llega al suelo.
			p.append([Meshes.sphere(0.5, 14), Meshes.xf(at + Vector3(0, h * 0.15, 0), Vector3.ZERO, Vector3(w, h * 2.0, d)), roof])
			p.append([Meshes.cyl(w * 0.47, w * 0.5, 0.18, 14), Meshes.xf(at + Vector3(0, 0.09, 0), Vector3.ZERO, Vector3(1, 1, d / w)), walls.darkened(0.2)])
			p.append([Meshes.box(0.28, h * 0.5, 0.05), Meshes.xf(at + Vector3(0, h * 0.25, d * 0.48)), roof.darkened(0.55)])
			p.append([Meshes.cyl(0.04, 0.06, 0.25, 6), Meshes.xf(at + Vector3(0, h * 1.1, 0)), roof.darkened(0.3)])
		"guarani":
			# Casa larga: techo a dos aguas hasta el suelo y frentes de barro.
			p.append([Meshes.prism(d * 1.05, h * 1.25, w), Meshes.xf(at + Vector3(0, h * 0.625, 0), Vector3(0, 90, 0)), roof])
			p.append([Meshes.box(0.06, h * 0.9, d * 0.8), Meshes.xf(at + Vector3(w * 0.5, h * 0.42, 0)), walls])
			p.append([Meshes.box(0.07, h * 0.5, 0.26), Meshes.xf(at + Vector3(w * 0.51, h * 0.25, 0)), roof.darkened(0.55)])
		"etiopia":
			# Tukul: muro redondo y techo cónico con remate.
			var r := minf(w, d) * 0.48
			p.append([Meshes.cyl(r, r, h * 0.6, 16), Meshes.xf(at + Vector3(0, h * 0.3, 0)), walls])
			p.append([Meshes.cyl(0.0, r * 1.3, h * 0.9, 16), Meshes.xf(at + Vector3(0, h * 0.6 + h * 0.45, 0)), roof])
			p.append([Meshes.cyl(0.02, 0.02, 0.3, 4), Meshes.xf(at + Vector3(0, h * 1.55, 0)), pal[2]])
			p.append([Meshes.box(0.24, h * 0.4, 0.05), Meshes.xf(at + Vector3(0, h * 0.2, r - 0.01)), roof.darkened(0.55)])
		"palmares":
			# Choza de pau-a-pique y palma, alero bajo y amplio.
			p.append([Meshes.box(w * 0.92, h * 0.6, d * 0.85), Meshes.xf(at + Vector3(0, h * 0.3, 0)), walls])
			p.append([Meshes.prism(w * 1.25, h * 0.55, d * 1.2), Meshes.xf(at + Vector3(0, h * 0.6 + h * 0.27, 0)), roof])
			for i in 5:
				p.append([Meshes.box(w * 1.2, 0.03, 0.06), Meshes.xf(at + Vector3(0, h * 0.62 + i * 0.09, -d * 0.55 + i * 0.13), Vector3(-25, 0, 0)), roof.darkened(0.12)])
			p.append([Meshes.box(0.24, h * 0.42, 0.05), Meshes.xf(at + Vector3(0, h * 0.21, d * 0.43)), roof.darkened(0.55)])
		"ayutthaya":
			# Pabellón sobre pilotes, techo de dos niveles en rojo con remates dorados.
			for c in [Vector2(-1, -1), Vector2(1, -1), Vector2(-1, 1), Vector2(1, 1)]:
				p.append([Meshes.cyl(0.05, 0.05, h * 0.3, 6), Meshes.xf(at + Vector3(c.x * w * 0.4, h * 0.15, c.y * d * 0.38)), pal[2].darkened(0.3)])
			p.append([Meshes.box(w * 0.85, h * 0.45, d * 0.75), Meshes.xf(at + Vector3(0, h * 0.52, 0)), walls])
			p.append([Meshes.prism(w * 1.05, h * 0.55, d * 0.95), Meshes.xf(at + Vector3(0, h * 1.02, 0), Vector3(0, 90, 0), Vector3(1, 1, 1)), roof])
			p.append([Meshes.prism(w * 0.7, h * 0.45, d * 0.65), Meshes.xf(at + Vector3(0, h * 1.38, 0), Vector3(0, 90, 0)), roof.lightened(0.08)])
			p.append([Meshes.box(0.05, 0.05, d * 0.7), Meshes.xf(at + Vector3(0, h * 1.62, 0)), pal[2]])
			for z in [-1, 1]:
				p.append([Meshes.cyl(0.0, 0.04, 0.25, 5), Meshes.xf(at + Vector3(0, h * 1.7, z * d * 0.33), Vector3(z * 25, 0, 0)), pal[2]])
		_:
			p.append([Meshes.box(w, h * 0.75, d), Meshes.xf(at + Vector3(0, h * 0.375, 0)), walls])
			p.append([Meshes.prism(w * 1.1, h * 0.6, d * 1.1), Meshes.xf(at + Vector3(0, h * 1.05, 0), Vector3(0, 90, 0)), roof])


static func _center(p: Array, forma: String, w: float, d: float, pal: Array, team: Color, by: float) -> void:
	p.append([Meshes.box(w - 0.5, 0.18, d - 0.5), Meshes.xf(Vector3(0, by + 0.09, 0)), pal[0].darkened(0.12)])
	by += 0.18
	_hut(p, forma, Vector3(0, by, -d * 0.08), w * 0.55, d * 0.5, 1.5, pal)
	_hut(p, forma, Vector3(-w * 0.3, by, d * 0.25), w * 0.28, d * 0.26, 0.9, pal)
	_hut(p, forma, Vector3(w * 0.3, by, d * 0.25), w * 0.28, d * 0.26, 0.9, pal)
	Meshes._banner(p, Vector3(w * 0.4, by, -d * 0.38), 2.6, team)
	Meshes._banner(p, Vector3(-w * 0.4, by, -d * 0.38), 2.6, team)


static func _barracks(p: Array, forma: String, w: float, d: float, pal: Array, team: Color, by: float, type: String) -> void:
	_hut(p, forma, Vector3(0, by, -d * 0.2), w * 0.85, d * 0.45, 1.1, pal)
	for i in 5:
		p.append([Meshes.box(0.08, 0.42, 0.08), Meshes.xf(Vector3(-w * 0.43 + i * w * 0.215, by + 0.21, d * 0.42)), pal[1].darkened(0.3)])
	p.append([Meshes.box(w * 0.9, 0.06, 0.06), Meshes.xf(Vector3(0, by + 0.38, d * 0.42)), pal[1].darkened(0.3)])
	if type == "kraal":
		p.append([Meshes.box(w * 0.9, 0.06, 0.06), Meshes.xf(Vector3(0, by + 0.6, d * 0.42)), pal[1].darkened(0.3)])
		p.append([Meshes.cyl(0.22, 0.22, 0.6, 10), Meshes.xf(Vector3(w * 0.25, by + 0.3, d * 0.15)), Color("8c8478")])
	Meshes._banner(p, Vector3(-w * 0.42, by, d * 0.2), 2.0, team)
	Meshes._banner(p, Vector3(w * 0.42, by, d * 0.2), 2.0, team)


static func _store(p: Array, forma: String, w: float, d: float, pal: Array, team: Color, by: float) -> void:
	for c in [Vector2(-1, -1), Vector2(1, -1), Vector2(-1, 1), Vector2(1, 1)]:
		p.append([Meshes.box(0.1, 0.9, 0.1), Meshes.xf(Vector3(c.x * w * 0.38, by + 0.45, c.y * d * 0.38)), pal[1].darkened(0.35)])
	match forma:
		"etiopia", "mapuche":
			p.append([Meshes.cyl(0.0, w * 0.58, 0.55, 14), Meshes.xf(Vector3(0, by + 1.15, 0)), pal[1]])
		"inca":
			p.append([Meshes.cyl(w * 0.3, w * 0.32, 0.7, 12), Meshes.xf(Vector3(-w * 0.15, by + 0.35, 0)), pal[0]])
			p.append([Meshes.cyl(0.0, w * 0.36, 0.45, 12), Meshes.xf(Vector3(-w * 0.15, by + 0.92, 0)), pal[1]])
		_:
			p.append([Meshes.prism(w * 0.95, 0.45, d * 0.95), Meshes.xf(Vector3(0, by + 1.1, 0)), pal[1]])
	p.append([Meshes.box(0.45, 0.38, 0.45), Meshes.xf(Vector3(w * 0.15, by + 0.2, d * 0.1), Vector3(0, 15, 0)), pal[0].darkened(0.1)])
	p.append([Meshes.cyl(0.17, 0.19, 0.4), Meshes.xf(Vector3(-w * 0.1, by + 0.2, d * 0.2)), pal[2]])
	Meshes._banner(p, Vector3(w * 0.42, by, d * 0.42), 1.6, team)


static func _tower(p: Array, forma: String, pal: Array, team: Color, by: float) -> void:
	var stone: Color = pal[2] if forma in ["inca", "etiopia"] else pal[0]
	p.append([Meshes.cyl(0.6, 0.78, 2.5, 10 if forma != "inca" else 6), Meshes.xf(Vector3(0, by + 1.25, 0)), stone])
	if forma == "ayutthaya":
		p.append([Meshes.prism(1.5, 0.9, 1.5), Meshes.xf(Vector3(0, by + 2.95, 0)), pal[1]])
	elif forma == "etiopia":
		p.append([Meshes.sphere(0.6, 10), Meshes.xf(Vector3(0, by + 2.6, 0), Vector3.ZERO, Vector3(1, 0.7, 1)), stone.lightened(0.1)])
	else:
		p.append([Meshes.cyl(0.82, 0.72, 0.3, 10), Meshes.xf(Vector3(0, by + 2.6, 0)), stone.lightened(0.08)])
		for i in 8:
			var a := TAU * i / 8.0
			p.append([Meshes.box(0.2, 0.25, 0.2), Meshes.xf(Vector3(cos(a) * 0.7, by + 2.85, sin(a) * 0.7)), stone.lightened(0.08)])
	Meshes._banner(p, Vector3(0, by + 2.6, 0), 1.2, team)


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
	for side in [Vector3(0, 0, -1), Vector3(0, 0, 1)]:
		p.append([Meshes.box(w - 0.3, hgt, 0.3), Meshes.xf(Vector3(0, hgt / 2, side.z * (d / 2 - 0.25))), col])
	for side in [Vector3(-1, 0, 0), Vector3(1, 0, 0)]:
		p.append([Meshes.box(0.3, hgt, d - 0.3), Meshes.xf(Vector3(side.x * (w / 2 - 0.25), hgt / 2, 0)), col])
	for i in 6:
		var o := -w / 2 + 0.4 + i * (w - 0.8) / 5.0
		for e in [Vector3(o, hgt + 0.1, -(d / 2 - 0.25)), Vector3(o, hgt + 0.1, d / 2 - 0.25)]:
			p.append([Meshes.box(0.22, 0.2, 0.22), Meshes.xf(e), col.lightened(0.06)])


# ---------------------------------------------------------------- Unidades

static func unit(type: String, def: Dictionary, team: Color, style: Dictionary) -> ArrayMesh:
	var forma: String = style.get("forma", "")
	var key := "u_%s_%s_%s" % [forma, type, team.to_html()]
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
		_person(p, fn, Vector3(0, rider_y, 0), team, pal, forma, def)
	var mesh := Meshes.merge(p)
	_cache[key] = mesh
	return mesh


static func _person(p: Array, fn: String, at: Vector3, team: Color, pal: Array, forma: String, def: Dictionary) -> void:
	var clay := Palette.CLAY
	var cloth: Color = pal[0].lightened(0.2)
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
			p.append([Meshes.box(r * 2.6, 0.32, r * 1.8), Meshes.xf(at + Vector3(0, 0.58, 0)), Color("3b3a44")]) # poncho
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
