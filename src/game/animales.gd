class_name Animales
extends RefCounted
## Siluetas de los animales (data/arte_animales.json; proceso/24, 4d): camélidos de cuello
## largo, cabras, bovinos con cuernos, cerdos, ciervos y tapires. Una malla por especie,
## compartida por todos los animales de esa especie. El frente mira hacia +Z.

static var _data := {}
static var _parts := {}
static var _meshes := {}


static func data() -> Dictionary:
	if _data.is_empty():
		var raw: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/arte_animales.json"))
		_data = raw if raw is Dictionary else {"especies": {}}
	return _data


## Especie del rebaño de un pueblo.
static func rebano(civ: String) -> String:
	var t: Dictionary = data().get("rebano_por_civ", {})
	return str(t.get(civ, t.get("_defecto", "oveja")))


## Especie de un animal sin dueño: `kind` es venado (caza) o rebano_salvaje (suelto); `civ`, el
## pueblo de la base más cercana; `h`, un número propio del animal para variar la caza.
static func salvaje(kind: String, civ: String, terrain: String, h: int) -> String:
	var d := data()
	var by_t: Dictionary = d.get("caza_por_terreno", {})
	if by_t.has(terrain):
		var lt: Array = by_t[terrain]
		return str(lt[absi(h) % lt.size()])
	if kind == "rebano_salvaje":
		var s: Dictionary = d.get("sueltos_por_civ", {})
		return str(s.get(civ, s.get("_defecto", "oveja")))
	var c: Dictionary = d.get("caza_por_civ", {})
	var l: Array = c.get(civ, c.get("_defecto", ["venado"]))
	return str(l[absi(h) % l.size()])


static func mesh(sp: String) -> ArrayMesh:
	if _meshes.has(sp):
		return _meshes[sp]
	var m := Meshes.merge(parts(sp))
	_meshes[sp] = m
	return m


## Partes [malla, transform, color] de la especie, en el origen (para sumarlas a otra malla:
## las llamas de oro del Qorikancha, el ganado de un hito).
static func parts(sp: String) -> Array:
	if _parts.has(sp):
		return _parts[sp]
	var e: Dictionary = data().get("especies", {}).get(sp, {})
	if e.is_empty():
		e = {"forma": "camelido", "color": "#c9b08a"}
	var p: Array = []
	match str(e.get("forma", "camelido")):
		"camelido":
			_camelid(p, e)
		"cabra":
			_goat(p, e)
		"bovino":
			_bovine(p, e)
		"cerdo":
			_pig(p, e)
		"ciervo":
			_deer(p, e)
		"tapir":
			_tapir(p, e)
	var k := float(e.get("escala_pct", 100)) / 100.0
	if not is_equal_approx(k, 1.0):
		var s := Transform3D(Basis.IDENTITY.scaled(Vector3.ONE * k), Vector3.ZERO)
		for part: Array in p:
			part[1] = s * (part[1] as Transform3D)
	_parts[sp] = p
	return p


static func _c(e: Dictionary, key: String, def: String) -> Color:
	return Color(str(e.get(key, def)))


static func _legs(p: Array, leg: float, r: float, hx: float, hz: float, col: Color) -> void:
	for c: Vector2 in [Vector2(-hx, hz), Vector2(hx, hz), Vector2(-hx, -hz), Vector2(hx, -hz)]:
		p.append([Meshes.cyl(r * 0.85, r, leg, 6), Meshes.xf(Vector3(c.x, leg / 2.0, c.y)), col])


static func _horn(p: Array, pts: Array, r: float, col: Color) -> void:
	for i in pts.size() - 1:
		CivMeshes._pole(p, pts[i], pts[i + 1], r * (1.0 - 0.3 * i), col)


## Llama, chilihueque, guanaco: patas largas, cuello largo casi vertical, cabeza chica con
## orejas en banana y la cola alzada.
static func _camelid(p: Array, e: Dictionary) -> void:
	var col := _c(e, "color", "#e8dcc4")
	var face := _c(e, "cara", e.get("color", "#e8dcc4")).lerp(col, 0.3)
	var leg := float(e.get("patas_cm", 34)) / 100.0
	var neck := float(e.get("cuello_cm", 50)) / 100.0
	var g := float(e.get("grueso_pct", 100)) / 100.0
	var by := leg + 0.13
	p.append([Meshes.sphere(0.2, 12), Meshes.xf(Vector3(0, by, 0), Vector3.ZERO, Vector3(0.95 * g, 0.8 * g, 1.5)), col])
	if e.get("lana", false):
		# Vellón que cuelga a los costados.
		p.append([Meshes.sphere(0.21, 10), Meshes.xf(Vector3(0, by - 0.05, -0.02), Vector3.ZERO, Vector3(1.05 * g, 0.62, 1.35)), col.darkened(0.08)])
	if e.has("vientre"):
		p.append([Meshes.sphere(0.18, 10), Meshes.xf(Vector3(0, by - 0.07, 0.02), Vector3.ZERO, Vector3(0.88 * g, 0.55, 1.3)), _c(e, "vientre", "#efe6d6")])
	var nb := Vector3(0, by + 0.06, 0.24)
	var nt := nb + Vector3(0, neck, 0.06)
	CivMeshes._pole(p, nb, nt, 0.06 * g, col)
	p.append([Meshes.sphere(0.075, 10), Meshes.xf(nt + Vector3(0, 0.02, 0.04), Vector3.ZERO, Vector3(0.9, 0.85, 1.45)), col])
	p.append([Meshes.box(0.065, 0.06, 0.09), Meshes.xf(nt + Vector3(0, -0.005, 0.13)), face])
	for sx: float in [-1.0, 1.0]:
		p.append([Meshes.cyl(0.0, 0.022, 0.13, 4), Meshes.xf(nt + Vector3(sx * 0.04, 0.12, 0.0), Vector3(-8, 0, -sx * 10)), col.darkened(0.12)])
	p.append([Meshes.cyl(0.025, 0.035, 0.12, 6), Meshes.xf(Vector3(0, by + 0.07, -0.31), Vector3(-55, 0, 0)), col.darkened(0.05)])
	var lc: Color = col.lightened(0.3) if e.has("vientre") else col.darkened(0.2)
	_legs(p, leg, 0.03, 0.085, 0.19, lc)


## Cabra y oveja: patas cortas, cuello corto inclinado, cuernos hacia atrás y barba (cabra) o
## vellón y cara oscura (oveja); cola parada.
static func _goat(p: Array, e: Dictionary) -> void:
	var col := _c(e, "color", "#3a3530")
	var leg := 0.21
	var wool: bool = e.get("lana", false)
	var by := leg + 0.12
	p.append([Meshes.sphere(0.17, 10), Meshes.xf(Vector3(0, by, 0), Vector3.ZERO, Vector3(1.0 if not wool else 1.25, 0.85 if not wool else 1.05, 1.45)), col])
	var face := _c(e, "cara", e.get("color", "#3a3530"))
	CivMeshes._pole(p, Vector3(0, by + 0.04, 0.18), Vector3(0, by + 0.2, 0.27), 0.05, col)
	var hd := Vector3(0, by + 0.21, 0.3)
	p.append([Meshes.sphere(0.065, 8), Meshes.xf(hd, Vector3(25, 0, 0), Vector3(0.8, 0.85, 1.5)), face])
	for sx: float in [-1.0, 1.0]:
		p.append([Meshes.box(0.08, 0.02, 0.035), Meshes.xf(hd + Vector3(sx * 0.07, 0.02, -0.03), Vector3(0, 0, sx * -20)), face.darkened(0.1)])
	if str(e.get("cuernos", "cabra")) == "cabra":
		for sx: float in [-1.0, 1.0]:
			_horn(p, [hd + Vector3(sx * 0.025, 0.05, -0.01), hd + Vector3(sx * 0.04, 0.15, -0.07), hd + Vector3(sx * 0.06, 0.18, -0.16)], 0.018, Color("8a7a60"))
		p.append([Meshes.cyl(0.02, 0.0, 0.08, 5), Meshes.xf(hd + Vector3(0, -0.07, 0.06)), col.darkened(0.2)]) # barba
	elif str(e.get("cuernos", "")) == "ibice":
		# Íbice: cuernos grandes y nudosos en arco hacia atrás, casi hasta el lomo.
		for sx: float in [-1.0, 1.0]:
			_horn(p, [hd + Vector3(sx * 0.025, 0.05, -0.01), hd + Vector3(sx * 0.05, 0.18, -0.06), hd + Vector3(sx * 0.07, 0.26, -0.17), hd + Vector3(sx * 0.08, 0.27, -0.3), hd + Vector3(sx * 0.08, 0.2, -0.4)], 0.026, _c(e, "cuerno_color", "#5a4e40"))
		p.append([Meshes.cyl(0.02, 0.0, 0.07, 5), Meshes.xf(hd + Vector3(0, -0.07, 0.06)), col.darkened(0.2)]) # barba
	p.append([Meshes.cyl(0.0, 0.025, 0.08, 5), Meshes.xf(Vector3(0, by + 0.13, -0.25), Vector3(-25, 0, 0)), col])
	_legs(p, leg, 0.026, 0.08, 0.16, face.darkened(0.15) if wool else col.darkened(0.2))


## Búfalo y vaca: cuerpo ancho y pesado, patas cortas y gruesas, cabeza baja y adelante; el
## búfalo con los cuernos grandes en media luna hacia atrás.
static func _bovine(p: Array, e: Dictionary) -> void:
	var col := _c(e, "color", "#55585c")
	var leg := 0.24
	var by := leg + 0.19
	p.append([Meshes.sphere(0.25, 12), Meshes.xf(Vector3(0, by, 0), Vector3.ZERO, Vector3(1.0, 0.85, 1.6)), col])
	p.append([Meshes.sphere(0.2, 10), Meshes.xf(Vector3(0, by + 0.07, 0.2), Vector3.ZERO, Vector3(1.05, 0.9, 1.0)), col.darkened(0.05)]) # cruz
	if e.get("giba", false): # --- C-72 a --- la giba del cebú sobre la cruz, y la papada
		p.append([Meshes.sphere(0.11, 8), Meshes.xf(Vector3(0, by + 0.25, 0.26), Vector3.ZERO, Vector3(0.9, 1.0, 1.1)), col.darkened(0.12)])
		p.append([Meshes.box(0.06, 0.14, 0.18), Meshes.xf(Vector3(0, by - 0.12, 0.38)), col.darkened(0.08)])
	var hd := Vector3(0, by + 0.0, 0.5)
	p.append([Meshes.sphere(0.1, 10), Meshes.xf(hd, Vector3(30, 0, 0), Vector3(0.95, 0.85, 1.45)), col.darkened(0.08)])
	p.append([Meshes.box(0.13, 0.08, 0.08), Meshes.xf(hd + Vector3(0, -0.07, 0.1)), col.darkened(0.3)])
	var horn := _c(e, "cuerno_color", "#d9cfb8")
	if str(e.get("cuernos", "")) == "bufalo":
		# Cuernos gruesos y grises en media luna: salen de lo alto de la frente hacia los
		# costados, se curvan hacia atrás y suben un poco, con las puntas hacia adentro, pegados
		# al plano de la cabeza. Nada hacia adelante ni hacia abajo (no son colmillos).
		for sx: float in [-1.0, 1.0]:
			_horn(p, [hd + Vector3(sx * 0.05, 0.09, -0.05), hd + Vector3(sx * 0.17, 0.12, -0.1), hd + Vector3(sx * 0.25, 0.15, -0.2), hd + Vector3(sx * 0.24, 0.18, -0.32), hd + Vector3(sx * 0.15, 0.2, -0.4)], 0.048, horn)
	else:
		for sx: float in [-1.0, 1.0]:
			_horn(p, [hd + Vector3(sx * 0.06, 0.07, -0.02), hd + Vector3(sx * 0.15, 0.13, 0.0)], 0.022, horn)
	for sx: float in [-1.0, 1.0]:
		p.append([Meshes.box(0.08, 0.025, 0.04), Meshes.xf(hd + Vector3(sx * 0.11, 0.02, -0.05)), col.darkened(0.1)])
	CivMeshes._pole(p, Vector3(0, by + 0.1, -0.38), Vector3(0, by - 0.18, -0.42), 0.015, col.darkened(0.15))
	p.append([Meshes.sphere(0.035, 6), Meshes.xf(Vector3(0, by - 0.2, -0.42)), col.darkened(0.35)])
	_legs(p, leg, 0.05, 0.13, 0.25, col.darkened(0.25))


## Cerdo y pecarí: barril sobre patas muy cortas, sin cuello, hocico de disco; el pecarí con
## crin en el lomo y collar claro.
static func _pig(p: Array, e: Dictionary) -> void:
	var col := _c(e, "color", "#9a6a62")
	var leg := 0.13
	var by := leg + 0.16
	p.append([Meshes.sphere(0.2, 12), Meshes.xf(Vector3(0, by, 0), Vector3.ZERO, Vector3(1.0, 0.9, 1.6)), col])
	var hd := Vector3(0, by - 0.01, 0.33)
	p.append([Meshes.sphere(0.12, 10), Meshes.xf(hd, Vector3.ZERO, Vector3(0.95, 0.9, 1.1)), col.darkened(0.04)])
	var long_snout: bool = e.get("crin", false)
	var sl := 0.12 if long_snout else 0.08
	p.append([Meshes.cyl(0.045, 0.065, sl, 8), Meshes.xf(hd + Vector3(0, -0.03, 0.1 + sl / 2.0), Vector3(90, 0, 0)), col.darkened(0.12)])
	p.append([Meshes.cyl(0.047, 0.047, 0.01, 8), Meshes.xf(hd + Vector3(0, -0.03, 0.1 + sl), Vector3(90, 0, 0)), col.lightened(0.15) if not long_snout else Color("2a2622")])
	for sx: float in [-1.0, 1.0]:
		p.append([Meshes.cyl(0.0, 0.045, 0.09, 3), Meshes.xf(hd + Vector3(sx * 0.07, 0.1, 0.02), Vector3(35, 0, sx * -30)), col.darkened(0.1)])
	if e.has("collar"):
		p.append([Meshes.box(0.34, 0.045, 0.04), Meshes.xf(Vector3(0, by + 0.04, 0.22), Vector3(0, 0, 0)), _c(e, "collar", "#d8d0c0")])
	if long_snout:
		p.append([Meshes.box(0.05, 0.08, 0.5), Meshes.xf(Vector3(0, by + 0.17, -0.02)), col.darkened(0.3)]) # crin
	else:
		CivMeshes._pole(p, Vector3(0, by + 0.05, -0.3), Vector3(0.03, by + 0.11, -0.36), 0.015, col)
	_legs(p, leg, 0.035, 0.1, 0.19, col.darkened(0.25))


## Ciervos y antílopes: patas largas y finas, cuello alzado, cola blanca; astas ramificadas, en
## horquilla, cuernos rectos o en espiral.
static func _deer(p: Array, e: Dictionary) -> void:
	var col := _c(e, "color", "#8a6a46")
	var leg := 0.4
	var g := float(e.get("grueso_pct", 100)) / 100.0
	var by := leg + 0.12
	p.append([Meshes.sphere(0.17, 12), Meshes.xf(Vector3(0, by, 0), Vector3.ZERO, Vector3(0.88 * g, 0.85 * g, 1.6)), col])
	p.append([Meshes.sphere(0.14, 10), Meshes.xf(Vector3(0, by - 0.05, 0.02), Vector3.ZERO, Vector3(0.8 * g, 0.55, 1.4)), col.lightened(0.22)])
	var nb := Vector3(0, by + 0.05, 0.22)
	var nt := nb + Vector3(0, 0.26, 0.1)
	CivMeshes._pole(p, nb, nt, 0.05 * g, col)
	if e.get("crin", false):
		p.append([Meshes.sphere(0.085, 8), Meshes.xf(nb.lerp(nt, 0.45), Vector3(-20, 0, 0), Vector3(1.0, 1.6, 1.0)), col.darkened(0.2)])
	var face := _c(e, "cara", e.get("color", "#8a6a46"))
	var hd := nt + Vector3(0, 0.02, 0.05)
	p.append([Meshes.sphere(0.065, 10), Meshes.xf(hd, Vector3(20, 0, 0), Vector3(0.8, 0.85, 1.6)), col])
	p.append([Meshes.box(0.05, 0.05, 0.07), Meshes.xf(hd + Vector3(0, -0.02, 0.1)), face.darkened(0.15)])
	for sx: float in [-1.0, 1.0]:
		p.append([Meshes.box(0.09, 0.025, 0.04), Meshes.xf(hd + Vector3(sx * 0.07, 0.05, -0.04), Vector3(0, 0, sx * 25)), col.darkened(0.08)])
	var top := hd + Vector3(0, 0.05, -0.02)
	var horn := Color("d9c9a8")
	match str(e.get("cuernos", "ramificadas")):
		"ramificadas":
			for sx: float in [-1.0, 1.0]:
				var a := top + Vector3(sx * 0.03, 0, 0)
				var b := top + Vector3(sx * 0.11, 0.12, -0.04)
				var c := top + Vector3(sx * 0.14, 0.27, -0.09)
				_horn(p, [a, b, c], 0.014, horn)
				_horn(p, [b, b + Vector3(-sx * 0.02, 0.1, 0.06)], 0.011, horn)
				_horn(p, [b.lerp(c, 0.6), b.lerp(c, 0.6) + Vector3(sx * 0.0, 0.08, 0.06)], 0.01, horn)
		"horquilla":
			for sx: float in [-1.0, 1.0]:
				var a := top + Vector3(sx * 0.03, 0, 0)
				var b := top + Vector3(sx * 0.09, 0.12, -0.03)
				_horn(p, [a, b, b + Vector3(sx * 0.05, 0.1, -0.06)], 0.014, horn)
				_horn(p, [b, b + Vector3(-sx * 0.01, 0.11, 0.04)], 0.011, horn)
		"rectos":
			for sx: float in [-1.0, 1.0]:
				_horn(p, [top + Vector3(sx * 0.025, 0, 0), top + Vector3(sx * 0.06, 0.2, -0.16), top + Vector3(sx * 0.08, 0.36, -0.3)], 0.016, Color("3a3530"))
		"espiral":
			for sx: float in [-1.0, 1.0]:
				_horn(p, [top + Vector3(sx * 0.03, 0, 0), top + Vector3(sx * 0.1, 0.1, -0.04), top + Vector3(sx * 0.04, 0.2, -0.08), top + Vector3(sx * 0.1, 0.3, -0.1), top + Vector3(sx * 0.07, 0.38, -0.08)], 0.02, Color("4a4038"))
	p.append([Meshes.sphere(0.05, 6), Meshes.xf(Vector3(0, by + 0.08, -0.28), Vector3.ZERO, Vector3(1, 1.3, 0.8)), Color("f2ecdf")]) # cola blanca
	_legs(p, leg, 0.022, 0.075, 0.2, col.darkened(0.22))


## Tapir (mborevi): cuerpo redondo y pesado, grupa alta, patas cortas y la trompa corta.
static func _tapir(p: Array, e: Dictionary) -> void:
	var col := _c(e, "color", "#3e3a38")
	var leg := 0.2
	var by := leg + 0.2
	p.append([Meshes.sphere(0.25, 12), Meshes.xf(Vector3(0, by, -0.02), Vector3.ZERO, Vector3(0.92, 0.9, 1.55)), col])
	p.append([Meshes.sphere(0.2, 10), Meshes.xf(Vector3(0, by + 0.04, -0.2)), col.darkened(0.04)]) # grupa
	var hd := Vector3(0, by + 0.02, 0.38)
	p.append([Meshes.cyl(0.07, 0.13, 0.24, 10), Meshes.xf(hd, Vector3(75, 0, 0)), col.darkened(0.06)])
	CivMeshes._pole(p, hd + Vector3(0, -0.03, 0.1), hd + Vector3(0, -0.1, 0.2), 0.035, col.darkened(0.15)) # trompa
	for sx: float in [-1.0, 1.0]:
		p.append([Meshes.sphere(0.04, 6), Meshes.xf(hd + Vector3(sx * 0.07, 0.11, -0.08), Vector3.ZERO, Vector3(1, 1.2, 0.5)), col.lightened(0.2)])
	if e.get("crin", false):
		p.append([Meshes.box(0.04, 0.06, 0.18), Meshes.xf(Vector3(0, by + 0.17, 0.26), Vector3(-25, 0, 0)), col.darkened(0.3)])
	_legs(p, leg, 0.05, 0.12, 0.22, col.darkened(0.2))
