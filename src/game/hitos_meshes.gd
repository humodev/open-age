class_name HitosMeshes
extends RefCounted
## Hitos con arquitectura propia (data/arte_hitos.json; proceso/24-tras-la-segunda-ronda/
## 4d-hitos-y-animales.md). Cada hito tiene una silueta que se lee a la distancia y que no
## se parece a los edificios comunes del pueblo. Los materiales salen del aspecto de la edad
## del dueño (data/arte_edades.json): muro, techo y acento, aparejo, dorado, pisos de techo y
## alto del rewe. Las mallas las guarda CivMeshes.building (por pueblo, tipo, color y edad).

static var _data := {}
# Estado del armado en curso (un hito a la vez; todo en el hilo principal).
static var _p: Array = []
static var _cfg: Dictionary = {}
static var _pal: Array = []
static var _team := Color.WHITE
static var _hw := 1.7 # medio lado útil (dentro del margen)
static var _hd := 1.7
static var _e: Dictionary = {}

const WATER := Color("4c7e96")
const ROCK := Color("8a7d6c")
const THATCH_DRY := Color("b49a5e")
const DARK := Color("2a2420")
const IRON := Color("3a3836")


static func data() -> Dictionary:
	if _data.is_empty():
		var raw: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/arte_hitos.json"))
		var flat := {}
		if raw is Dictionary:
			for civ: String in (raw as Dictionary).get("civs", {}):
				var by_civ: Dictionary = raw["civs"][civ]
				for type: String in by_civ:
					flat[type] = by_civ[type]
		_data = flat if not flat.is_empty() else {"_vacio": {}}
	return _data


static func has(type: String) -> bool:
	return data().has(type) and type != "_vacio"


## Arma el hito `type` en `p`. Devuelve false si no tiene forma propia.
static func build(p: Array, type: String, w: float, d: float, pal: Array, team: Color, cfg: Dictionary) -> bool:
	if not has(type):
		return false
	_e = data()[type]
	_p = p
	_cfg = cfg
	_pal = pal
	_team = team
	_hw = w / 2.0 - CivMeshes.margin()
	_hd = d / 2.0 - CivMeshes.margin()
	var first := p.size()
	match str(_e.get("forma", "")):
		"ushnu": _ushnu()
		"pukara_anillos": _pukara()
		"aqllawasi": _aqllawasi()
		"kallanka": _kallanka()
		"qorikancha": _qorikancha()
		"vilcabamba": _vilcabamba()
		"nguillatuwe": _nguillatuwe()
		"rewe_malon": _rewe_malon()
		"rewe_caballos": _rewe_caballos()
		"rewe_monte": _rewe_monte()
		"parlamento": _parlamento()
		"weichan": _weichan()
		"oga_guasu": _oga_guasu()
		"aty_guasu": _aty_guasu()
		"mision": _mision()
		"monte": _monte()
		"tava": _tava()
		"trinchera": _trinchera()
		"iglesia_redonda": _iglesia_redonda()
		"lalibela": _lalibela()
		"amba": _amba()
		"remonta": _remonta()
		"gondar": _gondar()
		"alianza": _alianza()
		"macaco": _macaco()
		"mocambo_guerra": _mocambo_guerra()
		"cerca_anillos": _cerca_anillos()
		"ferraria": _ferraria()
		"cucau": _cucau()
		"serra_barriga": _serra_barriga()
		"wat_prang": _wat_prang()
		"kraal": _kraal()
		"puerto": _puerto()
		"fortaleza_isla": _fortaleza_isla()
		"junco": _junco()
		"guardia": _guardia()
		_:
			return false
	# Las formas se arman con el frente hacia +z; la cámara mira hacia +x+z (RtsCamera.YAW_DEG),
	# así que se giran media vuelta para que la portada, la escalinata o el muro curvo den a
	# la cámara (como todos los edificios: Meshes.face_camera).
	Meshes.face_camera(p, first)
	_p = []
	return true


# ---------------------------------------------------------------- Piezas

static func _box(sz: Vector3, at: Vector3, col: Color, rot := Vector3.ZERO) -> void:
	_p.append([Meshes.box(sz.x, sz.y, sz.z), Meshes.xf(at, rot), col])


static func _cyl(rt: float, rb: float, h: float, at: Vector3, col: Color, seg := 12, rot := Vector3.ZERO, scl := Vector3.ONE) -> void:
	_p.append([Meshes.cyl(rt, rb, h, seg), Meshes.xf(at, rot, scl), col])


static func _sph(r: float, at: Vector3, col: Color, scl := Vector3.ONE, seg := 10) -> void:
	_p.append([Meshes.sphere(r, seg), Meshes.xf(at, Vector3.ZERO, scl), col])


static func _glow(r: float, at: Vector3, col: Color, energy: float) -> void:
	_p.append([Meshes.sphere(r, 8), Meshes.xf(at, Vector3.ZERO, Vector3(1, 0.7, 1)), col, energy])


static func _gold() -> Color:
	return Palette.WEALTH


static func _dorado() -> bool:
	return _cfg.get("dorado", false)


## Muro recto entre dos puntos del suelo (o a la altura de `a.y`).
static func _seg(a: Vector3, b: Vector3, hgt: float, thick: float, col: Color, extra := 0.0) -> void:
	var dx := b.x - a.x
	var dz := b.z - a.z
	var l := sqrt(dx * dx + dz * dz) + extra
	_p.append([Meshes.box(l, hgt, thick), Meshes.xf(Vector3((a.x + b.x) / 2.0, a.y + hgt / 2.0, (a.z + b.z) / 2.0), Vector3(0, rad_to_deg(atan2(-dz, dx)), 0)), col])


## Punto de un arco: ángulo 0 hacia +x, PI/2 hacia +z (el frente).
static func _arc_pt(c: Vector3, r: float, a: float) -> Vector3:
	return c + Vector3(cos(a) * r, 0, sin(a) * r)


## Muro en arco de `a0` a `a1` (radianes) en `n` tramos; `courses`: hiladas marcadas.
static func _arc_wall(c: Vector3, r: float, a0: float, a1: float, n: int, hgt: float, thick: float, col: Color, courses := 0) -> void:
	for i in n:
		var pa := _arc_pt(c, r, lerpf(a0, a1, float(i) / n))
		var pb := _arc_pt(c, r, lerpf(a0, a1, float(i + 1) / n))
		_seg(pa, pb, hgt, thick, col, thick * 0.35)
		for k in courses:
			var y := hgt * float(k + 1) / float(courses + 1)
			_seg(pa + Vector3(0, y, 0), pb + Vector3(0, y, 0), 0.018, thick + 0.016, col.darkened(0.14), thick * 0.35)


## Postes aguzados en arco (empalizadas, cercas, anillos de lanzas).
static func _stakes_arc(c: Vector3, r: float, a0: float, a1: float, step: float, hgt: float, rad: float, col: Color, tip := Palette.TRUNK) -> void:
	var n := maxi(2, int(absf(a1 - a0) * r / step))
	for i in n + 1:
		var o := _arc_pt(c, r, lerpf(a0, a1, float(i) / n))
		var lh := hgt * (0.92 + 0.08 * float((i * 7) % 3) / 2.0)
		_cyl(rad, rad * 1.1, lh, o + Vector3(0, lh / 2.0, 0), col, 5)
		_cyl(0.0, rad, rad * 2.2, o + Vector3(0, lh + rad * 1.1, 0), tip, 5)


static func _stakes_line(a: Vector3, b: Vector3, step: float, hgt: float, rad: float, col: Color) -> void:
	var n := maxi(1, int(a.distance_to(b) / step))
	for i in n + 1:
		var o := a.lerp(b, float(i) / n)
		var lh := hgt * (0.92 + 0.08 * float((i * 7) % 3) / 2.0)
		_cyl(rad, rad * 1.1, lh, o + Vector3(0, lh / 2.0, 0), col, 5)
		_cyl(0.0, rad, rad * 2.2, o + Vector3(0, lh + rad * 1.1, 0), Palette.TRUNK, 5)


## Techo a dos aguas con la cumbrera a lo largo de x, apoyado en `at`.
static func _gable(at: Vector3, lx: float, wz: float, h: float, col: Color) -> void:
	_p.append([Meshes.prism(wz, h, lx), Meshes.xf(at + Vector3(0, h / 2.0, 0), Vector3(0, 90, 0)), col])


## Techo a cuatro aguas sobre un rectángulo de medios lados hx, hz.
static func _hip(at: Vector3, hx: float, hz: float, h: float, col: Color) -> void:
	var m := maxf(hx, hz)
	_p.append([Meshes.cyl(0.0, m * 1.414, h, 4), Meshes.xf(at + Vector3(0, h / 2.0, 0), Vector3(0, 45, 0), Vector3(hx / m, 1, hz / m)), col])


## Galpón: muros y techo a dos aguas (cumbrera a lo largo de x), con alero.
static func _hall(at: Vector3, lx: float, wz: float, wall_h: float, roof_h: float, walls: Color, roof: Color, eave := 0.12) -> void:
	_box(Vector3(lx, wall_h, wz), at + Vector3(0, wall_h / 2.0, 0), walls)
	_gable(at + Vector3(0, wall_h - 0.02, 0), lx + eave, wz + eave * 2.0, roof_h, roof)


## Vano trapezoidal (más angosto arriba), la marca de la arquitectura inca. `along_x`: en
## una cara que mira a ±x.
static func _trap(at: Vector3, wt: float, wb: float, h: float, col: Color, along_x := false) -> void:
	var scl := Vector3(0.25, 1, 1) if along_x else Vector3(1, 1, 0.25)
	_p.append([Meshes.cyl(wt * 0.707, wb * 0.707, h, 4), Meshes.xf(at + Vector3(0, h / 2.0, 0), Vector3(0, 45, 0), scl), col])


## Losa entre dos puntos (rampas, caminos de subida).
static func _slab(a: Vector3, b: Vector3, width: float, thick: float, col: Color) -> void:
	var dir := b - a
	var l := dir.length()
	if l < 0.001:
		return
	var x := dir / l
	var z := x.cross(Vector3.UP)
	if z.length() < 0.01:
		z = Vector3.FORWARD
	z = z.normalized()
	var y := z.cross(x).normalized()
	_p.append([Meshes.box(l, thick, width), Transform3D(Basis(x, y, z), (a + b) / 2.0), col])


static func _tree(at: Vector3, h: float, col := Palette.FOLIAGE) -> void:
	_cyl(0.04, 0.06, h * 0.55, at + Vector3(0, h * 0.275, 0), Palette.TRUNK, 6)
	_sph(h * 0.24, at + Vector3(0, h * 0.68, 0), col, Vector3(1, 0.85, 1), 8)
	_sph(h * 0.17, at + Vector3(h * 0.1, h * 0.86, -h * 0.05), col.lightened(0.08), Vector3.ONE, 8)


static func _conifer(at: Vector3, h: float, col := Color("3a5a3a")) -> void:
	_cyl(0.04, 0.05, h * 0.3, at + Vector3(0, h * 0.15, 0), Palette.TRUNK, 6)
	_cyl(0.0, h * 0.2, h * 0.8, at + Vector3(0, h * 0.6, 0), col, 8)


## Palmera (pindoba, babaçu): tronco algo inclinado y penacho de hojas caídas.
static func _palm(at: Vector3, h: float, lean := Vector2(0.15, 0.05)) -> void:
	var top := at + Vector3(lean.x, h, lean.y)
	CivMeshes._pole(_p, at, top, 0.045, Color("8a7a5a"))
	for i in 8:
		var ang := TAU * i / 8.0 + 0.3
		var droop := 28.0 + (i % 3) * 8.0
		var dir := Vector3(cos(ang), 0, -sin(ang))
		_p.append([Meshes.box(0.62, 0.02, 0.13), Meshes.xf(top + dir * 0.27 + Vector3(0, -0.08, 0), Vector3(0, rad_to_deg(ang), -droop)), Color("4a7a3a") if i % 2 == 0 else Color("3f6a34")])
	_sph(0.07, top, Color("6a5a3a"))


## Araucaria (pewen) adulta: tronco recto y desnudo, y arriba la copa en paraguas, más ancha
## que alta y plana encima; las ramas salen en rayos y suben en la punta, con los mechones de
## hojas al final. No es un pino de pisos (ronda 3 de jugadores; proceso/24, 4i).
static func _araucaria(at: Vector3, h: float) -> void:
	var leaf := Color("2f4a2c")
	var bark := Color("6e5a48")
	var r := h * 0.24
	var cy := h * 0.84
	_cyl(0.045 * h / 3.0 + 0.02, 0.07 * h / 3.0 + 0.025, cy, at + Vector3(0, cy / 2.0, 0), bark, 7)
	# Copa: cono invertido y achatado, plano arriba.
	_cyl(r, r * 0.35, h * 0.12, at + Vector3(0, cy + h * 0.04, 0), leaf, 12)
	_sph(r * 0.95, at + Vector3(0, cy + h * 0.1, 0), leaf.lightened(0.06), Vector3(1, 0.22, 1), 12)
	for i in 9:
		var a := TAU * i / 9.0 + 0.2
		var dir := Vector3(cos(a), 0, sin(a))
		var tip := at + dir * r * 1.05 + Vector3(0, cy + h * 0.1, 0)
		CivMeshes._pole(_p, at + Vector3(0, cy - h * 0.02, 0), tip, 0.025, bark.darkened(0.1))
		_sph(0.11 + 0.02 * (i % 2), tip + Vector3(0, 0.03, 0), leaf.lightened(0.04 * (i % 3)), Vector3(1.3, 0.6, 1.3), 6)
	# Unas pocas ramas bajas secas, como en los pewen viejos.
	for i in 2:
		var a := TAU * i / 2.0 + 0.9
		CivMeshes._pole(_p, at + Vector3(0, cy * (0.6 + i * 0.1), 0), at + Vector3(cos(a) * r * 0.5, cy * (0.6 + i * 0.1) + 0.12, sin(a) * r * 0.5), 0.015, bark)


static func _fire(at: Vector3) -> void:
	for i in 3:
		_box(Vector3(0.36, 0.05, 0.06), at + Vector3(0, 0.03, 0), Palette.TRUNK, Vector3(0, i * 60, 0))
	_glow(0.11, at + Vector3(0, 0.1, 0), Color("ff8a2a"), 1.6)
	for i in 8:
		var a := TAU * i / 8.0
		_sph(0.05, at + Vector3(cos(a) * 0.24, 0.03, sin(a) * 0.24), Palette.STONE_DARK, Vector3(1, 0.6, 1), 5)


static func _water(at: Vector3, sx: float, sz: float) -> void:
	_box(Vector3(sx, 0.04, sz), at + Vector3(0, 0.02, 0), WATER)
	_box(Vector3(sx * 0.7, 0.045, 0.03), at + Vector3(sx * 0.05, 0.025, -sz * 0.15), WATER.lightened(0.25))
	_box(Vector3(sx * 0.5, 0.045, 0.03), at + Vector3(-sx * 0.1, 0.025, sz * 0.2), WATER.lightened(0.25))


## Cañón sobre cureña, apuntando según `yaw` (0 = hacia +z).
static func _cannon(at: Vector3, yaw: float, col := IRON) -> void:
	var dir := Vector3(sin(deg_to_rad(yaw)), 0, cos(deg_to_rad(yaw)))
	var side := Vector3(dir.z, 0, -dir.x)
	for s: float in [-1.0, 1.0]:
		_cyl(0.11, 0.11, 0.04, at + side * s * 0.13 + Vector3(0, 0.11, 0), Palette.TRUNK, 10, Vector3(0, yaw, 90))
	_box(Vector3(0.2, 0.08, 0.4), at + Vector3(0, 0.14, 0) - dir * 0.05, Palette.WOOD_BEAM, Vector3(0, yaw, 0))
	CivMeshes._pole(_p, at + Vector3(0, 0.2, 0) - dir * 0.2, at + Vector3(0, 0.27, 0) + dir * 0.38, 0.05, col)


## Suma las partes de otra pieza (animal, caballo, elefante) trasladadas, giradas y escaladas.
## `tint`: pinta todo de un color (las llamas de oro).
static func _put(parts: Array, at: Vector3, yaw: float, k: float, tint: Variant = null) -> void:
	var t := Transform3D(Basis(Vector3.UP, deg_to_rad(yaw)).scaled(Vector3.ONE * k), at)
	for part: Array in parts:
		var q: Array = [part[0], t * (part[1] as Transform3D), tint if tint != null else part[2]]
		if tint != null:
			q.append(0.3)
		elif part.size() > 3:
			q.append(part[3])
		_p.append(q)


static func _horse(at: Vector3, yaw: float, k := 0.7) -> void:
	var tmp: Array = []
	CivMeshes._horse(tmp, _team)
	_put(tmp, at, yaw, k)


static func _animal(sp: String, at: Vector3, yaw: float, k := 1.0, tint: Variant = null) -> void:
	_put(Animales.parts(sp), at, yaw, k, tint)


static func _banner(at: Vector3, h := 1.6) -> void:
	Meshes._banner(_p, at, h, _team)


## Bloque de muro con el aparejo de la edad (pirca, piedra o cantería).
static func _stone_block(sz: Vector3, at: Vector3, col: Color) -> void:
	_box(sz, at + Vector3(0, sz.y / 2.0, 0), col)
	CivMeshes._aparejo(_p, str(_cfg.get("aparejo", "")), at, sz.x, sz.z, sz.y, col, false, "inca")


# ---------------------------------------------------------------- Tawantinsuyu

## Ushnu: plataforma baja y ancha de cuerpos de piedra gris frente a la plaza, la escalinata al
## frente, arriba la portada trapezoidal de doble jamba y, detrás, la tiana (Vilcashuamán).
## No es una pirámide: es ancha y baja, sin remate de oro (ronda 3 de jugadores; proceso/24, 4i).
static func _ushnu() -> void:
	var stone := Color(str(_e.get("piedra", "#8d8880")))
	var n := int(_e.get("pisos", 5))
	var th := float(_e.get("alto_piso_cm", 15)) / 100.0
	var cz := -0.45
	var bx := _hw * 2.0 - 0.15
	var bz := _hd * 2.0 - 1.0
	var dx := 0.24
	var dz := 0.14
	_box(Vector3(_hw * 2.0, 0.04, _hd * 2.0), Vector3(0, 0.02, 0), Palette.DIRT.lightened(0.18))
	for i in n:
		var col := stone if i % 2 == 0 else stone.darkened(0.06)
		_stone_block(Vector3(bx - i * dx, th, bz - i * dz), Vector3(0, i * th, cz), col)
		_box(Vector3(bx - i * dx + 0.02, 0.025, bz - i * dz + 0.02), Vector3(0, (i + 1) * th - 0.012, cz), stone.lightened(0.06))
	var top := n * th
	# Escalinata al frente: una sola rampa de peldaños, angosta y baja.
	var z0 := cz + bz / 2.0
	var steps := n * 2
	for j in steps:
		var hj := top - j * th / 2.0
		_box(Vector3(0.5, hj, 0.1), Vector3(0, hj / 2.0, z0 - (n - 1) * dz / 2.0 + j * 0.1 - 0.12), stone.lightened(0.04))
	# Portada trapezoidal de doble jamba arriba de la escalinata.
	var pz := cz + (bz - (n - 1) * dz) / 2.0 - 0.18
	# Vano abierto: se ve el cielo y la sombra a través. Jambas inclinadas hacia adentro (más
	# angosto arriba), la exterior adelante y la interior un paso más atrás.
	var ph := 0.82
	var lean := 5.0
	for s: float in [-1.0, 1.0]:
		_box(Vector3(0.22, ph, 0.24), Vector3(s * 0.36, top + ph / 2.0, pz + 0.04), stone.darkened(0.04), Vector3(0, 0, s * lean))
		_box(Vector3(0.12, ph - 0.1, 0.2), Vector3(s * 0.22, top + (ph - 0.1) / 2.0, pz - 0.14), stone.darkened(0.12), Vector3(0, 0, s * lean))
	_box(Vector3(0.98, 0.14, 0.26), Vector3(0, top + ph + 0.05, pz + 0.04), stone.lightened(0.04))
	_box(Vector3(0.6, 0.12, 0.22), Vector3(0, top + ph - 0.08, pz - 0.14), stone.darkened(0.08))
	_box(Vector3(0.5, 0.02, 0.4), Vector3(0, top + 0.01, pz - 0.05), stone.darkened(0.3))
	# La tiana: asiento doble de piedra detrás de la portada.
	_box(Vector3(0.62, 0.16, 0.3), Vector3(0, top + 0.08, cz - 0.3), stone.lightened(0.1))
	_box(Vector3(0.62, 0.26, 0.08), Vector3(0, top + 0.21, cz - 0.42), stone.lightened(0.1))
	_cyl(0.13, 0.1, 0.08, Vector3(0.7, top + 0.04, cz - 0.1), stone.darkened(0.25), 10)
	# Canal de las libaciones, de la plataforma a la plaza.
	_box(Vector3(0.08, 0.03, 1.0), Vector3(1.0, 0.05, 1.0), stone.darkened(0.3))


## Pukara de frontera: cerro con muros concéntricos en terrazas, parapeto corrido y vigía.
static func _pukara() -> void:
	var stone: Color = _pal[0]
	var n := int(_e.get("anillos", 3))
	var ap := str(_cfg.get("aparejo", "pirca"))
	_cyl(1.25, _hw, 0.3, Vector3(0, 0.15, 0), Palette.DIRT.darkened(0.12), 14)
	var top := 0.3
	var r := 0.0
	for i in n:
		r = _hw - 0.1 - i * 0.4
		top = 0.3 + (i + 1) * 0.45
		_cyl(r, r * 1.04, top, Vector3(0, top / 2.0, 0), stone if i % 2 == 0 else stone.darkened(0.06), 14)
		CivMeshes._aparejo(_p, ap if ap != "" else "pirca", Vector3(0, top - 0.45, 0), r / 0.48, r / 0.48, 0.45, stone, true, "inca")
		_cyl(r - 0.05, r - 0.05, 0.03, Vector3(0, top + 0.015, 0), Color("7d7a4c"), 14)
		_box(Vector3(0.42, top, 0.26), Vector3(0, top / 2.0, r + 0.08), stone.lightened(0.1))
	_arc_wall(Vector3(0, top, 0), r - 0.06, 0, TAU, 14, 0.22, 0.09, stone.lightened(0.05))
	CivMeshes._hut(_p, "inca", Vector3(-0.05, top, -0.08), 0.62, 0.55, 0.8, _pal, {"aparejo": ap})
	if _dorado():
		_cyl(r + 0.01, r + 0.01, 0.06, Vector3(0, top - 0.06, 0), _gold(), 14)


## Aqllawasi: recinto de muro alto y una sola portada de doble jamba; galpones adentro y un
## tejido de tocapu colgado.
static func _aqllawasi() -> void:
	var walls: Color = _pal[0]
	var roof: Color = _pal[1]
	var h := float(_e.get("alto_cm", 115)) / 100.0
	var t := 0.22
	for side in [[Vector3(-_hw, 0, -_hd), Vector3(_hw, 0, -_hd)], [Vector3(-_hw, 0, _hd), Vector3(_hw, 0, _hd)], [Vector3(-_hw, 0, -_hd), Vector3(-_hw, 0, _hd)], [Vector3(_hw, 0, -_hd), Vector3(_hw, 0, _hd)]]:
		_seg(side[0], side[1], h, t, walls, t)
	CivMeshes._aparejo(_p, str(_cfg.get("aparejo", "")), Vector3.ZERO, _hw * 2.0 + t, _hd * 2.0 + t, h, walls, false, "inca")
	var fz := _hd + t / 2.0
	_trap(Vector3(0, 0, fz + 0.004), 0.36, 0.5, 0.98, walls.darkened(0.18))
	_trap(Vector3(0, 0, fz + 0.02), 0.22, 0.32, 0.82, DARK)
	for x: float in [-1.25, -0.8, 0.8, 1.25]:
		_trap(Vector3(x, 0.38, fz + 0.01), 0.14, 0.2, 0.36, walls.darkened(0.4))
	# Tocapu: cuadros de colores colgados sobre el muro.
	var tc: Array = [Color("a63a2a"), Color("e2b13c"), DARK, Color("f0e6d0")]
	for i in 6:
		_box(Vector3(0.14, 0.14, 0.02), Vector3(-0.42 - (i % 3) * 0.15 + 0.15, h - 0.25 - (i / 3) * 0.15, fz + 0.03), tc[(i + i / 3) % 4])
	_hall(Vector3(0, 0, -0.78), 2.8, 0.95, h + 0.12, 0.85, walls.darkened(0.04), roof)
	for x: float in [-0.8, 0.8]:
		_hall(Vector3(x, 0, 0.55), 1.0, 0.75, h + 0.05, 0.7, walls.darkened(0.04), roof)
	if _dorado():
		for side in [[Vector3(-_hw, h, _hd), Vector3(_hw, h, _hd)], [Vector3(-_hw, h, -_hd), Vector3(_hw, h, -_hd)]]:
			_seg(side[0], side[1], 0.06, t + 0.02, _gold(), t)


## Kallanka real: galpón largo a dos aguas con hastiales de piedra y muchas portadas a la plaza.
static func _kallanka() -> void:
	var walls: Color = _pal[0]
	var roof: Color = _pal[1]
	var cz := -0.45
	var lx := _hw * 2.0 - 0.1
	var wz := 1.3
	var wh := 1.0
	_stone_block(Vector3(lx, wh, wz), Vector3(0, 0, cz), walls)
	# Hastiales de piedra (asoman en los extremos) y techo de paja encima.
	_p.append([Meshes.prism(wz - 0.02, 0.92, lx), Meshes.xf(Vector3(0, wh + 0.46, cz), Vector3(0, 90, 0)), walls.darkened(0.05)])
	_p.append([Meshes.prism(wz + 0.34, 1.08, lx - 0.16), Meshes.xf(Vector3(0, wh - 0.06 + 0.54, cz), Vector3(0, 90, 0)), roof])
	_box(Vector3(lx - 0.16, 0.06, 0.08), Vector3(0, wh + 1.0, cz), roof.darkened(0.25))
	var n := int(_e.get("puertas", 5))
	for i in n:
		var x := lerpf(-lx / 2.0 + 0.35, lx / 2.0 - 0.35, float(i) / maxf(1.0, n - 1.0))
		_trap(Vector3(x, 0, cz + wz / 2.0 + 0.01), 0.16, 0.26, 0.72, DARK)
	_box(Vector3(lx, 0.04, 1.1), Vector3(0, 0.02, 0.85), Palette.DIRT.lightened(0.15))
	# Lanzas en sus soportes, frente a las portadas.
	for r in 2:
		var x0 := -0.9 + r * 1.8
		_box(Vector3(0.7, 0.05, 0.05), Vector3(x0, 0.75, 1.15), Palette.WOOD_BEAM)
		for i in 5:
			CivMeshes._pole(_p, Vector3(x0 - 0.3 + i * 0.15, 0, 1.25), Vector3(x0 - 0.3 + i * 0.15, 1.45, 1.1), 0.015, Palette.WOOD_BEAM)
			_cyl(0.0, 0.03, 0.12, Vector3(x0 - 0.3 + i * 0.15, 1.5, 1.09), Palette.CLAY_DARK, 5)
	if _dorado():
		_box(Vector3(lx + 0.02, 0.06, wz + 0.02), Vector3(0, wh - 0.05, cz), _gold())


## Qorikancha: el muro curvo de cantería con banda de oro, el templo detrás con el disco del
## sol y el jardín de figuras de oro.
static func _qorikancha() -> void:
	var stone: Color = _pal[0].lightened(0.1)
	var roof: Color = _pal[1]
	var h := float(_e.get("alto_cm", 130)) / 100.0
	var c := Vector3(0, 0, -0.25)
	var r := _hw - 0.12
	_arc_wall(c, r, 0.0, PI, 14, h, 0.26, stone, 5)
	_seg(Vector3(-r, 0, -0.25), Vector3(-r, 0, -_hd), h, 0.26, stone, 0.26)
	_seg(Vector3(r, 0, -0.25), Vector3(r, 0, -_hd), h, 0.26, stone, 0.26)
	_seg(Vector3(-r, 0, -_hd), Vector3(r, 0, -_hd), h, 0.26, stone, 0.26)
	var band := 0.1 if _dorado() else 0.06
	for i in 14:
		var pa := _arc_pt(c + Vector3(0, h - band, 0), r, PI * i / 14.0)
		var pb := _arc_pt(c + Vector3(0, h - band, 0), r, PI * (i + 1) / 14.0)
		_seg(pa, pb, band, 0.28, _gold(), 0.1)
	_trap(c + Vector3(0, 0, r + 0.14), 0.24, 0.36, 0.9, DARK)
	# Templo del sol, más alto que el muro, con techo de paja y el disco de oro al frente.
	var tz := -0.95
	_stone_block(Vector3(2.2, 1.75, 0.95), Vector3(0, 0, tz), stone.darkened(0.03))
	_hip(Vector3(0, 1.73, tz), 1.22, 0.6, 1.0, roof)
	_cyl(0.32, 0.32, 0.04, Vector3(0, 1.38, tz + 0.5), _gold(), 18, Vector3(90, 0, 0))
	for i in 12:
		var a := TAU * i / 12.0
		_box(Vector3(0.05, 0.16, 0.02), Vector3(cos(a) * 0.4, 1.38 + sin(a) * 0.4, tz + 0.5), _gold(), Vector3(0, 0, rad_to_deg(a) - 90.0))
	_trap(Vector3(0.7, 0, tz + 0.49), 0.18, 0.26, 0.8, DARK)
	_trap(Vector3(-0.7, 0, tz + 0.49), 0.18, 0.26, 0.8, DARK)
	# El jardín de oro: llamas y maíz de oro en el patio.
	_animal("llama", Vector3(-0.55, 0, 0.35), 35.0, 0.6, _gold())
	_animal("llama", Vector3(0.6, 0, 0.45), -30.0, 0.55, _gold())
	for i in 5:
		_cyl(0.012, 0.02, 0.45, Vector3(-0.15 + i * 0.08, 0.22, 0.75 - (i % 2) * 0.1), _gold(), 4)


## Vilcabamba: cerro con andenes en la ceja de selva, casas de techo empinado y monte.
static func _vilcabamba() -> void:
	var walls: Color = _pal[0]
	var roof: Color = _pal[1]
	_cyl(0.85, 1.5, 0.9, Vector3(0.1, 0.45, -0.3), Color("6f6a54"), 9)
	_cyl(0.6, 0.85, 0.35, Vector3(0.05, 1.07, -0.35), Color("77705a"), 9, Vector3(0, 20, 0))
	for i in 3:
		var w := 1.8 - i * 0.35
		_box(Vector3(w, 0.3, 0.42), Vector3(-0.5 + i * 0.05, 0.15 + i * 0.3, 1.05 - i * 0.36), walls.darkened(0.05))
		_box(Vector3(w - 0.05, 0.04, 0.38), Vector3(-0.5 + i * 0.05, 0.31 + i * 0.3, 1.05 - i * 0.36), Color("6f8a44"))
	var y := 1.22
	_stone_block(Vector3(0.75, 0.6, 0.55), Vector3(-0.15, y, -0.35), walls)
	_hip(Vector3(-0.15, y + 0.58, -0.35), 0.45, 0.35, 0.8, roof)
	_stone_block(Vector3(0.55, 0.5, 0.45), Vector3(0.55, y - 0.15, 0.15), walls)
	_gable(Vector3(0.55, y + 0.33, 0.15), 0.62, 0.6, 0.45, Color("9e4a32")) # teja, como en Espíritu Pampa
	for t: Vector3 in [Vector3(-1.3, 0, -1.2), Vector3(1.35, 0, -1.25), Vector3(1.4, 0, 0.6), Vector3(-1.4, 0, -0.2), Vector3(0.9, 0, 1.3), Vector3(-0.2, 0, -1.45)]:
		_tree(t, 1.9 + absf(t.x) * 0.3, Color("2f5a30"))
	_slab(Vector3(0.9, 0, 1.0), Vector3(0.55, y - 0.15, 0.4), 0.22, 0.06, Palette.DIRT)


# ---------------------------------------------------------------- Mapuches

## Rewe: poste escalonado tallado (con la cara arriba) y ramas de canelo atadas.
static func _rewe(at: Vector3, hgt := -1.0) -> float:
	var h := hgt if hgt > 0.0 else maxf(2.2, float(_cfg.get("rewe_cm", 220)) / 100.0 + 0.2)
	_cyl(0.28, 0.34, 0.12, at + Vector3(0, 0.06, 0), Palette.DIRT.darkened(0.08), 10)
	_cyl(0.11, 0.14, h, at + Vector3(0, h / 2.0, 0), Palette.WOOD_BEAM, 8)
	var n := 6
	for i in n:
		_box(Vector3(0.3, 0.06, 0.14), at + Vector3(0, 0.3 + i * (h - 0.6) / n, 0.12), Palette.TRUNK)
	_sph(0.13, at + Vector3(0, h + 0.08, 0), Palette.WOOD_BEAM, Vector3(1, 1.2, 1), 8)
	_box(Vector3(0.12, 0.03, 0.02), at + Vector3(0, h + 0.1, 0.12), DARK)
	for s: float in [-1.0, 1.0]:
		_cyl(0.0, 0.17, 0.7, at + Vector3(s * 0.2, h - 0.35, 0.02), Palette.FOLIAGE_2, 7, Vector3(0, 0, s * -12))
	return h


## Toki kura: el hacha de piedra del toqui, en lo alto de su poste.
static func _toki(at: Vector3, h := 1.7) -> void:
	_cyl(0.045, 0.055, h, at + Vector3(0, h / 2.0, 0), Palette.WOOD_BEAM, 6)
	_box(Vector3(0.34, 0.2, 0.07), at + Vector3(0.12, h - 0.05, 0), Color("3f5a4a"))
	_cyl(0.0, 0.1, 0.07, at + Vector3(0.3, h - 0.05, 0), Color("3f5a4a"), 3, Vector3(90, 0, -90))


## Nguillatuwe: el rewe con canelos en el centro del campo y las ramadas en media luna.
static func _nguillatuwe() -> void:
	_cyl(_hw * 0.95, _hw, 0.03, Vector3(0, 0.015, 0), Palette.DIRT.lightened(0.12), 18)
	_rewe(Vector3(0, 0, -0.1))
	for s: float in [-1.0, 1.0]:
		_tree(Vector3(s * 0.42, 0, -0.3), 1.5, Palette.FOLIAGE_2)
	var r := _hw - 0.2
	for i in 7:
		var a := PI + 0.25 + i * (PI - 0.5) / 6.0
		var o := _arc_pt(Vector3.ZERO, r, a)
		var yaw := rad_to_deg(-a) + 90.0
		var fwd := -o.normalized()
		for s: float in [-1.0, 1.0]:
			var side := Vector3(fwd.z, 0, -fwd.x) * s * 0.2
			_cyl(0.025, 0.03, 1.0, o + side + fwd * 0.12 + Vector3(0, 0.5, 0), Palette.WOOD_BEAM, 5)
		_box(Vector3(0.6, 0.07, 0.5), o + Vector3(0, 0.92, 0), Color("7d7a45"), Vector3(-18, yaw, 0))
	_animal("chilihueque", Vector3(-0.45, 0, 0.75), 20.0, 0.85)
	_animal("chilihueque", Vector3(0.5, 0, 0.7), -40.0, 0.8)


## Ruka grande (la del toqui o la del lonko): el domo de paja de la casa común del pueblo, con
## el aspecto de la edad.
static func _ruka(at: Vector3, w: float, d: float, h: float) -> void:
	CivMeshes._hut(_p, "mapuche", at, w, d, h, _pal, _cfg)


## Canelo (foye): árbol sagrado y de la paz, de copa alta y clara.
static func _canelo(at: Vector3, h: float) -> void:
	_tree(at, h, Palette.FOLIAGE_2.lightened(0.05))


## Toqui de malón: la ruka grande del toqui, la toki kura (el hacha de piedra, insignia del
## toqui) en su poste junto a un canelo, el haz de lanzas de colihue y el botín. Sin rewe: el
## rewe es el altar de la machi y queda solo en el nguillatuwe (ronda 3; proceso/24, 4i).
static func _rewe_malon() -> void:
	_box(Vector3(_hw * 2.0, 0.03, _hd * 2.0), Vector3(0, 0.015, 0), Palette.DIRT.lightened(0.1))
	_ruka(Vector3(-0.1, 0, -0.4), 1.95, 1.35, 1.15)
	_canelo(Vector3(0.75, 0, 0.55), 1.7)
	_toki(Vector3(0.4, 0, 0.75), 2.0)
	var apex := Vector3(-0.6, 2.0, 0.6)
	for i in 9:
		var a := TAU * i / 9.0
		var base := Vector3(-0.6 + cos(a) * 0.36, 0, 0.6 + sin(a) * 0.36)
		CivMeshes._pole(_p, base, apex + (apex - base) * 0.12, 0.016, Color("b8a660"))
	# Botín del malón: fardos y una montura.
	_box(Vector3(0.36, 0.22, 0.26), Vector3(0.05, 0.11, 0.85), Color("6b5a3a"))
	_box(Vector3(0.3, 0.18, 0.22), Vector3(0.05, 0.31, 0.85), Color("3b3a44"))


## Toqui de caballería: el corral grande de los caballos, la ruka y el palenque con las monturas.
static func _rewe_caballos() -> void:
	_ruka(Vector3(-0.65, 0, -0.7), 1.0, 0.8, 0.85)
	var c := Vector3(0.22, 0, 0.25)
	var r := 0.9
	_cyl(r, r, 0.02, c + Vector3(0, 0.01, 0), Palette.DIRT.darkened(0.05), 16)
	_stakes_arc(c, r, 0.0, TAU - 0.5, 0.18, 0.75, 0.04, Palette.WOOD_BEAM, Palette.WOOD_BEAM)
	for y: float in [0.32, 0.6]:
		for i in 12:
			var a0 := (TAU - 0.5) * i / 12.0
			var a1 := (TAU - 0.5) * (i + 1) / 12.0
			_seg(_arc_pt(c, r, a0) + Vector3(0, y, 0), _arc_pt(c, r, a1) + Vector3(0, y, 0), 0.04, 0.04, Palette.TRUNK, 0.02)
	_horse(c + Vector3(-0.3, 0, 0.15), 30.0, 0.7)
	_horse(c + Vector3(0.35, 0, -0.2), -110.0, 0.7)
	_horse(c + Vector3(0.1, 0, 0.5), 160.0, 0.65)
	# Palenque: travesaño con las monturas de cuero.
	var pq := Vector3(0.75, 0, -0.85)
	for s: float in [-1.0, 1.0]:
		_cyl(0.03, 0.035, 0.6, pq + Vector3(s * 0.32, 0.3, 0), Palette.WOOD_BEAM, 5)
	_box(Vector3(0.75, 0.05, 0.05), pq + Vector3(0, 0.58, 0), Palette.WOOD_BEAM)
	for s: float in [-0.18, 0.18]:
		_box(Vector3(0.18, 0.12, 0.26), pq + Vector3(s, 0.62, 0), Color("5a3a24"))


## Toqui del monte: un pewenal (tres araucarias grandes), la ruka entre los troncos, los
## piñones (ngülliw) juntados y la trampa de foso.
static func _rewe_monte() -> void:
	_cyl(_hw, _hw, 0.03, Vector3(0, 0.015, 0), Color("6a6a3e"), 16)
	_araucaria(Vector3(-0.7, 0, -0.65), 3.3)
	_araucaria(Vector3(0.7, 0, -0.75), 3.9)
	_araucaria(Vector3(0.55, 0, 0.6), 2.9)
	_ruka(Vector3(-0.35, 0, 0.1), 0.95, 0.75, 0.8)
	# Piñones en canastos y en la pila.
	for i in 3:
		_cyl(0.11, 0.08, 0.16, Vector3(0.05 + i * 0.2, 0.08, -0.05), Color("9a7a48"), 8)
		_sph(0.09, Vector3(0.05 + i * 0.2, 0.17, -0.05), Color("7a4a2a"), Vector3(1, 0.5, 1), 6)
	_sph(0.2, Vector3(-0.85, 0.05, 0.75), Color("7a4a2a"), Vector3(1, 0.4, 1), 8)
	_cyl(0.2, 0.2, 0.02, Vector3(0.0, 0.02, 0.85), DARK, 10)
	for i in 5:
		CivMeshes._pole(_p, Vector3(-0.15 + i * 0.07, 0.02, 0.77 + (i % 2) * 0.12), Vector3(0.15 + i * 0.02, 0.05, 0.93 - (i % 2) * 0.1), 0.012, Palette.TRUNK)


## Parlamento: la gran ramada sobre muchos postes, con los bancos enfrentados, el canelo de la
## paz, los agasajos y el ganado de la feria.
static func _parlamento() -> void:
	var cz := -0.3
	var lx := _hw * 2.0 - 0.15
	var lz := 1.55
	for i in 4:
		var x := -lx / 2.0 + 0.08 + i * (lx - 0.16) / 3.0
		for j in 3:
			var z := cz - lz / 2.0 + 0.08 + j * (lz - 0.16) / 2.0
			_cyl(0.04, 0.05, 1.35, Vector3(x, 0.675, z), Palette.WOOD_BEAM, 6)
	_box(Vector3(lx + 0.1, 0.06, lz + 0.1), Vector3(0, 1.36, cz), Color("6e6a3e"))
	for i in 10:
		_sph(0.24, Vector3(-lx / 2.0 + 0.2 + (i % 5) * (lx - 0.4) / 4.0, 1.42, cz + (i / 5) * 0.7 - 0.35), Color("5e6a36") if i % 2 == 0 else Color("6a7440"), Vector3(1.3, 0.4, 1.1), 6)
	for z in [cz - 0.35, cz + 0.35]:
		_cyl(0.07, 0.07, lx - 0.3, Vector3(0, 0.08, z), Palette.TRUNK, 6, Vector3(0, 0, 90))
	_canelo(Vector3(0.9, 0, 0.8), 1.5)
	_box(Vector3(0.34, 0.2, 0.24), Vector3(-0.85, 0.1, 0.8), Color("2e3a6a"))
	_box(Vector3(0.3, 0.18, 0.22), Vector3(-0.85, 0.29, 0.8), Color("7a2a22"))
	_cyl(0.11, 0.09, 0.22, Vector3(-0.5, 0.11, 0.9), Color("8a5a3a"), 8)
	_animal("vaca", Vector3(0.15, 0, 0.85), 80.0, 0.6)


## Gran weichan: el campo de guerra, con el anillo de lanzas alrededor del fuego del consejo,
## la toki kura y los caballos listos.
static func _weichan() -> void:
	_cyl(_hw, _hw, 0.03, Vector3(0, 0.015, 0), Palette.DIRT, 16)
	_fire(Vector3(0, 0, 0.1))
	_toki(Vector3(0, 0, -0.55), 2.3)
	var r := _hw - 0.1
	for i in 18:
		var a := TAU * i / 18.0
		var o := _arc_pt(Vector3.ZERO, r, a)
		var lh := 2.6 if i % 2 == 0 else 2.2
		CivMeshes._pole(_p, o, o * 1.05 + Vector3(0, lh, 0), 0.018, Color("b8a660"))
		_cyl(0.0, 0.04, 0.2, o * 1.05 + Vector3(0, lh + 0.09, 0), IRON, 5)
	for k in 4:
		var a := PI * 0.25 + k * PI * 0.5
		var o := _arc_pt(Vector3.ZERO, 0.62, a)
		_horse(o, rad_to_deg(-a), 0.55)


# ---------------------------------------------------------------- Guaraníes

## Casa larga de paja hasta el suelo, con la cumbrera a lo largo de x (o de z si `along_z`).
static func _longhouse(at: Vector3, l: float, wid: float, h: float, along_z := false) -> void:
	var roof: Color = _pal[1]
	var yaw := 0.0 if along_z else 90.0
	_p.append([Meshes.prism(wid, h, l), Meshes.xf(at + Vector3(0, h / 2.0, 0), Vector3(0, yaw, 0)), roof])
	var ridge := Vector3(0.06, 0.06, l) if along_z else Vector3(l, 0.06, 0.06)
	_box(ridge, at + Vector3(0, h, 0), roof.darkened(0.25))
	var end := Vector3(0, 0, l / 2.0 + 0.005) if along_z else Vector3(l / 2.0 + 0.005, 0, 0)
	for s: float in [-1.0, 1.0]:
		_box(Vector3(0.3, h * 0.35, 0.03) if along_z else Vector3(0.03, h * 0.35, 0.3), at + end * s + Vector3(0, h * 0.17, 0), DARK)


## Yvyra'i: bastón ritual alto con plumas.
static func _feather_pole(at: Vector3, h: float, gourd := false) -> void:
	_cyl(0.025, 0.03, h, at + Vector3(0, h / 2.0, 0), Palette.WOOD_BEAM, 5)
	for i in 5:
		var a := TAU * i / 5.0
		_cyl(0.0, 0.025, 0.24, at + Vector3(cos(a) * 0.05, h + 0.06, sin(a) * 0.05), Color("d94a2a") if i % 2 == 0 else Color("f2c94a"), 4, Vector3(cos(a) * 25, 0, sin(a) * 25))
	if gourd:
		_sph(0.1, at + Vector3(0, h - 0.05, 0), Color("b8945a"), Vector3(1, 1.25, 1), 8)


## Oga guasu: la casa grande comunal, con los bastones rituales y el mbaraka del karai.
static func _oga_guasu() -> void:
	var cz := -0.5
	_longhouse(Vector3(0, 0, cz), _hw * 2.0 - 0.1, 1.85, 2.2)
	for x: float in [-1.0, -0.2, 0.6]:
		_box(Vector3(0.36, 0.55, 0.03), Vector3(x, 0.28, cz + 0.8), DARK, Vector3(-22, 0, 0))
	_box(Vector3(_hw * 2.0, 0.04, 1.0), Vector3(0, 0.02, 1.05), Palette.DIRT.lightened(0.15))
	_feather_pole(Vector3(-0.9, 0, 1.15), 1.6)
	_feather_pole(Vector3(0.0, 0, 1.25), 1.9, true)
	_feather_pole(Vector3(0.9, 0, 1.15), 1.6)
	if _cfg.get("horcones", false):
		CivMeshes._horcones(_p, Vector3(0, 0, cz), _hw * 2.0 - 0.1, 1.9, 0.7)


## Aty guasu: la plaza entre casas largas, el fuego y la ronda de asientos de la asamblea.
static func _aty_guasu() -> void:
	_longhouse(Vector3(0, 0, -1.25), 2.8, 0.85, 1.25)
	_longhouse(Vector3(-1.3, 0, 0.1), 2.0, 0.8, 1.15, true)
	_longhouse(Vector3(1.3, 0, 0.1), 2.0, 0.8, 1.15, true)
	_fire(Vector3(0, 0, 0.2))
	for i in 10:
		var a := TAU * i / 10.0
		var o := _arc_pt(Vector3(0, 0, 0.2), 0.6, a)
		_cyl(0.06, 0.06, 0.32, o + Vector3(0, 0.06, 0), Palette.TRUNK, 6, Vector3(0, rad_to_deg(-a), 90))
	_feather_pole(Vector3(-0.45, 0, -0.65), 1.7)
	_feather_pole(Vector3(0.45, 0, -0.65), 1.7)
	var apex := Vector3(0.55, 1.3, 1.1)
	for i in 6:
		var a := TAU * i / 6.0
		CivMeshes._pole(_p, Vector3(0.55 + cos(a) * 0.2, 0, 1.1 + sin(a) * 0.2), apex, 0.012, Palette.WOOD_BEAM)


## Iglesia de reducción: nave con galerías sobre columnas, teja, frente con frontón, campanario
## de madera aparte y la cruz de la plaza.
static func _mision() -> void:
	var walls := Color("c99a76")
	var tile := Color("9e4a32")
	var cx := -0.2
	var cz := -0.45
	var hw := 0.62
	var l := 2.1
	_box(Vector3(hw * 2.0, 1.45, l), Vector3(cx, 0.725, cz), walls)
	_p.append([Meshes.prism(hw * 2.0 + 0.85, 0.85, l + 0.1), Meshes.xf(Vector3(cx, 1.42 + 0.425, cz)), tile])
	for s: float in [-1.0, 1.0]:
		for i in 5:
			_cyl(0.04, 0.045, 1.4, Vector3(cx + s * (hw + 0.36), 0.7, cz - l / 2.0 + 0.15 + i * (l - 0.3) / 4.0), Palette.WOOD_BEAM, 6)
	var fz := cz + l / 2.0 + 0.06
	_box(Vector3(hw * 2.0 + 0.2, 1.9, 0.12), Vector3(cx, 0.95, fz), walls.lightened(0.12))
	_p.append([Meshes.prism(hw * 2.0 + 0.2, 0.55, 0.12), Meshes.xf(Vector3(cx, 1.9 + 0.275, fz)), walls.lightened(0.12)])
	_box(Vector3(0.36, 0.75, 0.03), Vector3(cx, 0.38, fz + 0.06), DARK)
	_cyl(0.18, 0.18, 0.03, Vector3(cx, 0.75, fz + 0.06), DARK, 10, Vector3(90, 0, 0))
	_box(Vector3(0.04, 0.4, 0.04), Vector3(cx, 2.6, fz), Palette.WOOD_BEAM)
	_box(Vector3(0.22, 0.04, 0.04), Vector3(cx, 2.68, fz), Palette.WOOD_BEAM)
	# Campanario de madera, aparte.
	var bt := Vector3(1.3, 0, 0.55)
	for c: Vector2 in [Vector2(-1, -1), Vector2(1, -1), Vector2(-1, 1), Vector2(1, 1)]:
		_cyl(0.035, 0.04, 2.2, bt + Vector3(c.x * 0.2, 1.1, c.y * 0.2), Palette.WOOD_BEAM, 5)
	for y: float in [0.7, 1.4]:
		_box(Vector3(0.44, 0.04, 0.44), bt + Vector3(0, y, 0), Palette.TRUNK)
	_hip(bt + Vector3(0, 2.18, 0), 0.3, 0.3, 0.38, tile)
	_sph(0.11, bt + Vector3(0, 1.95, 0), Color("8a6a3a"), Vector3(1, 1.1, 1), 8)
	# Cruz de la plaza.
	var cr := Vector3(1.0, 0, 1.25)
	_box(Vector3(0.07, 1.6, 0.07), cr + Vector3(0, 0.8, 0), Palette.WOOD_BEAM)
	_box(Vector3(0.5, 0.07, 0.07), cr + Vector3(0, 1.25, 0), Palette.WOOD_BEAM)
	_box(Vector3(0.3, 0.12, 0.3), cr + Vector3(0, 0.06, 0), walls)


## Monte libre: claro en la selva, refugios bajos, hamaca y fuego, tapados por los árboles.
static func _monte() -> void:
	var trees: Array = [Vector3(-1.25, 0, -1.2), Vector3(-0.2, 0, -1.35), Vector3(1.2, 0, -1.1), Vector3(-1.35, 0, 0.3), Vector3(1.35, 0, 0.35), Vector3(-0.6, 0, 1.25), Vector3(0.8, 0, 1.3)]
	for i in trees.size():
		_tree(trees[i], 2.8 + float(i % 3) * 0.35, Color("2f5a30") if i % 2 == 0 else Color("3a6a34"))
	for t: Vector3 in [Vector3(-0.55, 0, -0.35), Vector3(0.55, 0, -0.5)]:
		for s: float in [-1.0, 1.0]:
			_cyl(0.025, 0.03, 0.7, t + Vector3(s * 0.35, 0.35, 0.25), Palette.WOOD_BEAM, 5)
		_box(Vector3(0.85, 0.05, 0.75), t + Vector3(0, 0.5, 0.0), _pal[1], Vector3(-32, 0, 0))
	# Hamaca entre dos árboles.
	var a := Vector3(-1.35, 0.75, 0.3)
	var b := Vector3(-0.6, 0.75, 1.25)
	_slab(a, a.lerp(b, 0.5) + Vector3(0, -0.2, 0), 0.22, 0.03, Color("e8e0cc"))
	_slab(a.lerp(b, 0.5) + Vector3(0, -0.2, 0), b, 0.22, 0.03, Color("e8e0cc"))
	_fire(Vector3(0.2, 0, 0.45))


## Tava fortificada: el frente de piedra de la iglesia, la cruz de la plaza y la empalizada.
static func _tava() -> void:
	var stone := Color("b9805e")
	var tile := Color("9e4a32")
	var fz := -0.1
	_box(Vector3(1.6, 1.8, 1.3), Vector3(0, 0.9, fz - 0.75), stone.darkened(0.08))
	_p.append([Meshes.prism(1.8, 0.75, 1.35), Meshes.xf(Vector3(0, 1.8 + 0.375, fz - 0.75)), tile])
	_box(Vector3(2.1, 2.3, 0.2), Vector3(0, 1.15, fz), stone)
	_p.append([Meshes.prism(2.1, 0.65, 0.2), Meshes.xf(Vector3(0, 2.3 + 0.325, fz)), stone])
	for x: float in [-0.95, -0.35, 0.35, 0.95]:
		_box(Vector3(0.1, 2.2, 0.06), Vector3(x, 1.1, fz + 0.12), stone.lightened(0.12))
	for x: float in [-0.65, 0.0, 0.65]:
		var big := x == 0.0
		_box(Vector3(0.3 if big else 0.22, 0.7 if big else 0.55, 0.03), Vector3(x, 0.35 if big else 0.28, fz + 0.11), DARK)
	for s: float in [-1.0, 1.0]:
		_sph(0.1, Vector3(s * 1.0, 2.38, fz), stone.lightened(0.1), Vector3.ONE, 8)
	_box(Vector3(0.05, 0.4, 0.05), Vector3(0, 3.1, fz), Palette.WOOD_BEAM)
	_box(Vector3(0.22, 0.05, 0.05), Vector3(0, 3.18, fz), Palette.WOOD_BEAM)
	var cr := Vector3(-0.9, 0, 0.85)
	_box(Vector3(0.07, 1.5, 0.07), cr + Vector3(0, 0.75, 0), Palette.WOOD_BEAM)
	_box(Vector3(0.45, 0.07, 0.07), cr + Vector3(0, 1.15, 0), Palette.WOOD_BEAM)
	_stakes_line(Vector3(-_hw, 0, _hd), Vector3(-0.35, 0, _hd), 0.17, 0.95, 0.06, Palette.WOOD_BEAM)
	_stakes_line(Vector3(0.35, 0, _hd), Vector3(_hw, 0, _hd), 0.17, 0.95, 0.06, Palette.WOOD_BEAM)
	_stakes_line(Vector3(-_hw, 0, -_hd), Vector3(-_hw, 0, _hd), 0.17, 0.95, 0.06, Palette.WOOD_BEAM)
	_stakes_line(Vector3(_hw, 0, -_hd), Vector3(_hw, 0, _hd), 0.17, 0.95, 0.06, Palette.WOOD_BEAM)


## Ñande retã: trinchera y terraplén con empalizada, cañones de tacuara y el estandarte.
static func _trinchera() -> void:
	var r := _hw - 0.3
	var gap := 0.32
	_arc_wall(Vector3.ZERO, _hw - 0.06, 0, TAU, 20, 0.03, 0.16, DARK)
	_arc_wall(Vector3.ZERO, r, PI / 2.0 + gap, PI / 2.0 + TAU - gap, 16, 0.42, 0.42, Palette.DIRT.darkened(0.1))
	_stakes_arc(Vector3(0, 0.42, 0), r - 0.05, PI / 2.0 + gap, PI / 2.0 + TAU - gap, 0.17, 0.75, 0.05, Palette.WOOD_BEAM)
	for s: float in [-1.0, 1.0]:
		var o := _arc_pt(Vector3.ZERO, r - 0.05, PI / 2.0 + s * (gap + 0.1))
		_box(Vector3(0.28, 0.32, 0.12), o + Vector3(0, 0.16, -0.12), Palette.WOOD_BEAM)
		CivMeshes._pole(_p, o + Vector3(0, 0.34, -0.3), o + Vector3(s * 0.05, 0.4, 0.4), 0.06, Color("b8a660"))
		for k in 3:
			_cyl(0.068, 0.068, 0.04, o.lerp(o + Vector3(s * 0.05, 0.06, 0.7), 0.2 + k * 0.25) + Vector3(0, 0.35, -0.3), Palette.TRUNK, 8, Vector3(80, 0, 0))
	_longhouse(Vector3(0, 0, -0.35), 1.5, 0.8, 1.1)
	_banner(Vector3(0.0, 0, 0.35), 2.6)
	var apex := Vector3(-0.6, 1.5, 0.35)
	for i in 6:
		var a := TAU * i / 6.0
		CivMeshes._pole(_p, Vector3(-0.6 + cos(a) * 0.22, 0, 0.35 + sin(a) * 0.22), apex, 0.014, Palette.WOOD_BEAM)


# ---------------------------------------------------------------- Etiopía

## Iglesia redonda: atrio con muro y portería, zócalo, galería de postes bajo el alero, tambor y
## techo cónico empinado (no un hongo: el alero cae sobre la galería), cruz con huevos de avestruz.
static func _iglesia_redonda() -> void:
	var walls: Color = _pal[0]
	var roof: Color = _pal[1]
	var stone := Color("8c8478")
	var rr := _hw - 0.12
	_arc_wall(Vector3.ZERO, rr, PI / 2.0 + 0.28, PI / 2.0 + TAU - 0.28, 20, 0.55, 0.16, stone)
	var gz := Vector3(0, 0, rr)
	_box(Vector3(0.62, 0.65, 0.5), gz + Vector3(0, 0.325, 0), walls)
	_cyl(0.0, 0.5, 0.55, gz + Vector3(0, 0.92, 0), roof, 4, Vector3(0, 45, 0))
	_box(Vector3(0.26, 0.45, 0.02), gz + Vector3(0, 0.22, 0.26), DARK)
	_cyl(0.98, 1.04, 0.22, Vector3(0, 0.11, 0), stone, 20)
	var eave := 1.42
	for i in 14:
		var a := TAU * i / 14.0
		_cyl(0.03, 0.035, eave - 0.22, Vector3(cos(a) * 0.9, 0.22 + (eave - 0.22) / 2.0, sin(a) * 0.9), Palette.WOOD_BEAM, 5)
	var dh := 1.25
	_cyl(0.66, 0.66, dh, Vector3(0, 0.22 + dh / 2.0, 0), walls.lightened(0.08), 18)
	CivMeshes._aparejo(_p, str(_cfg.get("aparejo", "")), Vector3(0, 0.22, 0), 0.66 / 0.48, 0.66 / 0.48, dh, walls, true, "etiopia")
	_box(Vector3(0.26, 0.62, 0.03), Vector3(0, 0.53, 0.66), DARK)
	for a: float in [PI * 0.25, PI * 0.75, -PI * 0.5]:
		_box(Vector3(0.1, 0.18, 0.03), Vector3(cos(a) * 0.665, 1.1, sin(a) * 0.665), DARK, Vector3(0, rad_to_deg(-a) + 90.0, 0))
	# Techo cónico empinado (más alto que ancho), con el borde del alero marcado.
	var rh := 2.05
	_cyl(1.02, 1.04, 0.06, Vector3(0, eave + 0.03, 0), roof.darkened(0.18), 18)
	_cyl(0.0, 1.0, rh, Vector3(0, eave + rh / 2.0, 0), roof, 18)
	_cyl(0.48, 0.5, 0.05, Vector3(0, eave + rh * 0.52, 0), roof.darkened(0.12), 18)
	var top := eave + rh + 0.1
	_cyl(0.02, 0.02, 0.7, Vector3(0, top + 0.3, 0), _gold(), 4)
	_box(Vector3(0.3, 0.04, 0.04), Vector3(0, top + 0.55, 0), _gold())
	_box(Vector3(0.04, 0.04, 0.3), Vector3(0, top + 0.55, 0), _gold())
	for i in 4:
		_sph(0.05, Vector3(0, top + 0.06 + i * 0.1, 0), Color("f2ecdf"), Vector3(1, 1.25, 1), 6)
	for t: Vector3 in [Vector3(-1.05, 0, -0.95), Vector3(1.1, 0, -0.85), Vector3(0.2, 0, -1.35), Vector3(-1.3, 0, 0.2)]:
		_conifer(t, 2.0 + absf(t.z) * 0.3)


## Lalibela: iglesia tallada en la roca, en cruz y dentro de su foso, con el techo al ras de la
## meseta y la cruz en relieve; celdas en las paredes del foso.
static func _lalibela() -> void:
	var rock := Color("a26a4c")
	var h := 1.05
	var pit := 1.05
	var wall := _hw - pit
	_box(Vector3(_hw * 2.0, h, wall), Vector3(0, h / 2.0, -pit - wall / 2.0), rock)
	_box(Vector3(wall, h, pit * 2.0), Vector3(-pit - wall / 2.0, h / 2.0, 0), rock.darkened(0.04))
	_box(Vector3(wall, h, pit * 2.0), Vector3(pit + wall / 2.0, h / 2.0, 0), rock.darkened(0.04))
	# Frente: la roca con la zanja de bajada.
	var gx := 0.55
	_box(Vector3(_hw + gx - 0.22, h, wall), Vector3((-_hw + gx - 0.22) / 2.0, h / 2.0, pit + wall / 2.0), rock)
	_box(Vector3(_hw - gx - 0.22, h, wall), Vector3((_hw + gx + 0.22) / 2.0, h / 2.0, pit + wall / 2.0), rock)
	for j in 6:
		var y := h - (j + 1) * h / 6.0
		_box(Vector3(0.42, maxf(0.02, y), 0.12), Vector3(gx, maxf(0.02, y) / 2.0, _hd - 0.06 - j * 0.11), rock.lightened(0.06))
	_box(Vector3(pit * 2.0, 0.04, pit * 2.0), Vector3(0, 0.02, 0), rock.darkened(0.3))
	var ch := rock.lightened(0.07)
	_box(Vector3(1.55, 0.14, 0.62), Vector3(0, 0.07, 0), ch.darkened(0.1))
	_box(Vector3(0.62, 0.14, 1.55), Vector3(0, 0.07, 0), ch.darkened(0.1))
	_box(Vector3(1.45, h, 0.52), Vector3(0, h / 2.0, 0), ch)
	_box(Vector3(0.52, h, 1.45), Vector3(0, h / 2.0, 0), ch)
	# Cruces en relieve sobre el techo, como en Bete Giyorgis.
	_box(Vector3(1.2, 0.03, 0.14), Vector3(0, h + 0.012, 0), ch.darkened(0.2))
	_box(Vector3(0.14, 0.03, 1.2), Vector3(0, h + 0.012, 0), ch.darkened(0.2))
	_box(Vector3(0.8, 0.035, 0.05), Vector3(0, h + 0.02, 0), ch.lightened(0.1))
	_box(Vector3(0.05, 0.035, 0.8), Vector3(0, h + 0.02, 0), ch.lightened(0.1))
	for s: float in [-1.0, 1.0]:
		for y: float in [0.35, 0.72]:
			_box(Vector3(0.1, 0.16, 0.02), Vector3(s * 0.12, y, 0.73), DARK)
			_box(Vector3(0.02, 0.16, 0.1), Vector3(0.73 * s, y, 0.12), DARK)
			_box(Vector3(0.02, 0.16, 0.1), Vector3(0.73 * s, y, -0.12), DARK)
		for z: float in [-0.5, 0.2]:
			_box(Vector3(0.02, 0.22, 0.18), Vector3(s * (pit - 0.005), 0.3, z), DARK)
	_box(Vector3(0.2, 0.5, 0.03), Vector3(0, 0.25, 0.735), DARK)
	CivMeshes._hut(_p, "etiopia", Vector3(-1.2, h, -1.2), 0.55, 0.55, 0.7, _pal, {})
	_conifer(Vector3(1.25, h, -1.25), 1.5)
	_conifer(Vector3(-1.3, h, 0.9), 1.2)


## Amba: meseta de laderas a pique con el muro en el borde, casas arriba y un camino de subida.
static func _amba() -> void:
	var rock := Color("8a6e58")
	var h := 1.55
	_cyl(1.12, _hw, h, Vector3(0, h / 2.0, 0), rock, 9)
	for y: float in [0.45, 0.95]:
		_cyl(_hw - (y / h) * (_hw - 1.12) + 0.02, _hw - (y / h) * (_hw - 1.12) + 0.03, 0.07, Vector3(0, y, 0), rock.darkened(0.15), 9)
	_cyl(1.12, 1.12, 0.04, Vector3(0, h + 0.02, 0), Color("7d7a4c"), 9)
	_arc_wall(Vector3(0, h, 0), 1.02, PI / 2.0 + 0.4, PI / 2.0 + TAU - 0.4, 12, 0.3, 0.1, _pal[0])
	var hut_cfg := {"remate": _cfg.get("remate", "")}
	CivMeshes._hut(_p, "etiopia", Vector3(-0.35, h, -0.3), 0.6, 0.6, 0.85, _pal, hut_cfg)
	CivMeshes._hut(_p, "etiopia", Vector3(0.45, h, -0.15), 0.48, 0.48, 0.7, _pal, {})
	_slab(Vector3(1.55, 0, 0.95), Vector3(0.45, h, 0.95), 0.26, 0.06, Palette.DIRT.lightened(0.1))
	_conifer(Vector3(0.2, h, -0.8), 1.0)


## Remonta: corral de piedra con caballos y el establo largo.
static func _remonta() -> void:
	var stone := Color("8c8478")
	var c := Vector3(0.2, 0, 0.35)
	var r := 1.12
	_arc_wall(c, r, PI / 2.0 + 0.3, PI / 2.0 + TAU - 0.3, 16, 0.5, 0.18, stone)
	_horse(c + Vector3(-0.35, 0, 0.1), 40.0, 0.75)
	_horse(c + Vector3(0.3, 0, -0.15), -120.0, 0.75)
	_horse(c + Vector3(0.1, 0, 0.5), 170.0, 0.7)
	_hall(Vector3(0, 0, -1.3), 2.8, 0.55, 0.65, 0.6, _pal[0], _pal[1])
	_sph(0.3, Vector3(-1.3, 0.12, 0.1), THATCH_DRY, Vector3(1, 0.6, 1.3), 8)


## Recinto de Gondar: castillo de dos pisos con torres redondas y cúpulas en las esquinas y una
## torre cuadrada más alta; muro bajo alrededor.
static func _gondar() -> void:
	var stone: Color = _pal[0].lightened(0.05)
	for side in [[Vector3(-_hw, 0, -_hd), Vector3(_hw, 0, -_hd)], [Vector3(-_hw, 0, -_hd), Vector3(-_hw, 0, _hd)], [Vector3(_hw, 0, -_hd), Vector3(_hw, 0, _hd)], [Vector3(-_hw, 0, _hd), Vector3(-0.35, 0, _hd)], [Vector3(0.35, 0, _hd), Vector3(_hw, 0, _hd)]]:
		_seg(side[0], side[1], 0.5, 0.14, stone.darkened(0.08), 0.14)
	_keep(Vector3(-0.1, 0, -0.3), 1.9, 1.3, 1.85, stone, [Vector2(-1, 1), Vector2(1, 1), Vector2(-1, -1)], true)


## Castillo de Gondar (cuerpo almenado de dos pisos, ventanas en arco, torres redondas con
## cúpula en las esquinas `towers` y, si `tall`, la torre cuadrada más alta), apoyado en `c`.
static func _keep(c: Vector3, kw: float, kd: float, kh: float, stone: Color, towers: Array, tall: bool) -> void:
	var dome := Color("8a5a3a")
	var k := kh / 1.85
	_box(Vector3(kw, kh, kd), c + Vector3(0, kh / 2.0, 0), stone)
	CivMeshes._aparejo(_p, str(_cfg.get("aparejo", "piedra")), c, kw, kd, kh, stone, false, "etiopia")
	_box(Vector3(kw + 0.04, 0.06, kd + 0.04), c + Vector3(0, kh * 0.51, 0), stone.darkened(0.1))
	var nm := maxi(4, int(kw / 0.27))
	for i in nm:
		var x := c.x - kw / 2.0 + 0.1 + i * (kw - 0.2) / float(nm - 1)
		_box(Vector3(0.14, 0.14, 0.08) * Vector3(1, k, 1), Vector3(x, kh + 0.07 * k, c.z + kd / 2.0 - 0.04), stone)
		_box(Vector3(0.14, 0.14, 0.08) * Vector3(1, k, 1), Vector3(x, kh + 0.07 * k, c.z - kd / 2.0 + 0.04), stone)
	var nw := maxi(2, int(kw / 0.45))
	for row in 2:
		for i in nw:
			var x := c.x - kw * 0.32 + i * kw * 0.64 / float(nw - 1)
			var y := (0.45 + row * 0.85) * k
			_box(Vector3(0.14, 0.24 * k, 0.03), Vector3(x, y, c.z + kd / 2.0 + 0.01), DARK)
			_cyl(0.07, 0.07, 0.03, Vector3(x, y + 0.12 * k, c.z + kd / 2.0 + 0.01), DARK, 8, Vector3(90, 0, 0))
	var tr := 0.3 * minf(1.0, kw / 1.9) * 1.05
	for t: Vector2 in towers:
		var o := Vector3(c.x + t.x * kw / 2.0, 0, c.z + t.y * kd / 2.0)
		var th := kh * 1.19
		_cyl(tr, tr * 1.06, th, o + Vector3(0, th / 2.0, 0), stone.lightened(0.04), 12)
		_sph(tr * 1.03, o + Vector3(0, th, 0), dome, Vector3(1, 0.9, 1), 12)
	if tall:
		var st := Vector3(c.x + kw / 2.0 - 0.1, 0, c.z - kd / 2.0 + 0.1)
		_box(Vector3(0.62, 2.8, 0.62), st + Vector3(0, 1.4, 0), stone.lightened(0.02))
		_sph(0.3, st + Vector3(0, 2.8, 0), dome, Vector3(1, 1.0, 1), 12)
		if str(_cfg.get("remate", "")) == "cruz":
			CivMeshes._remate(_p, "cruz", st + Vector3(0, 3.1, 0))
	_box(Vector3(0.36, 0.6 * k, 0.03), Vector3(c.x, 0.3 * k, c.z + kd / 2.0 + 0.012), DARK)


## El centro etíope en Gondar (data/arte_edades.json → centro_forma: castillo): la corte deja
## de caminar y se asienta en un castillo de piedra. Más chico que el hito y sin la torre
## cuadrada alta, para no confundirse con el Recinto de Gondar; cruz en la torre del frente.
static func castillo(p: Array, at: Vector3, kw: float, kd: float, pal: Array, cfg: Dictionary) -> void:
	var prev := _p
	_p = p
	_cfg = cfg
	_pal = pal
	var stone: Color = pal[0].lightened(0.05)
	var kh := 1.45
	_keep(at, kw, kd, kh, stone, [Vector2(-1, 1), Vector2(1, 1)], false)
	# Cuerpo trasero más alto, con balcón de madera, como el castillo de Fasiladas [verificar].
	var b := at + Vector3(kw * 0.18, 0, -kd * 0.5)
	_box(Vector3(kw * 0.5, kh + 0.55, 0.5), b + Vector3(0, (kh + 0.55) / 2.0, 0), stone.darkened(0.03))
	_box(Vector3(kw * 0.5 + 0.06, 0.08, 0.16), b + Vector3(0, kh + 0.2, 0.3), Palette.WOOD_BEAM)
	for i in 4:
		var x := b.x - kw * 0.22 + i * kw * 0.147
		_box(Vector3(0.12, 0.12, 0.07), Vector3(x, kh + 0.61, b.z + 0.22), stone.darkened(0.03))
	_sph(0.26, b + Vector3(-kw * 0.12, kh + 0.55, 0), Color("8a5a3a"), Vector3(1, 0.9, 1), 12)
	if str(cfg.get("remate", "")) == "cruz":
		CivMeshes._remate(p, "cruz", b + Vector3(-kw * 0.12, kh + 0.85, 0))
	_p = prev


## Alianza con armas de fuego: campamento de la corte con la tienda real, cajones del comercio,
## mosquetes y cañones.
static func _alianza() -> void:
	var tent := Color("e8dcc6")
	var red := Color("8a2e26")
	var tc := Vector3(-0.45, 0, -0.45)
	_cyl(0.85, 0.85, 0.8, tc + Vector3(0, 0.4, 0), tent, 16)
	for i in 8:
		var a := TAU * i / 8.0
		_box(Vector3(0.12, 0.8, 0.02), tc + Vector3(cos(a) * 0.855, 0.4, sin(a) * 0.855), red, Vector3(0, rad_to_deg(-a) + 90.0, 0))
	_cyl(0.0, 1.0, 1.2, tc + Vector3(0, 0.8 + 0.6, 0), red, 16)
	_sph(0.09, tc + Vector3(0, 2.05, 0), _gold())
	_box(Vector3(0.3, 0.55, 0.02), tc + Vector3(0, 0.28, 0.86), DARK)
	for i in 5:
		var row := 0 if i < 3 else 1
		_box(Vector3(0.32, 0.26, 0.28), Vector3(0.85 + (i % 3) * 0.3 - 0.3 + row * 0.15, 0.13 + row * 0.26, -0.9), Palette.WOOD_BEAM.darkened(0.08 * (i % 2)), Vector3(0, i * 7, 0))
	_box(Vector3(0.9, 0.05, 0.05), Vector3(0.9, 0.75, 0.2), Palette.WOOD_BEAM)
	for s: float in [-1.0, 1.0]:
		_box(Vector3(0.05, 0.75, 0.05), Vector3(0.9 + s * 0.42, 0.37, 0.2), Palette.WOOD_BEAM)
	for i in 6:
		CivMeshes._pole(_p, Vector3(0.55 + i * 0.14, 0, 0.32), Vector3(0.55 + i * 0.14, 0.95, 0.16), 0.016, IRON)
	_cannon(Vector3(-0.5, 0, 1.0), 0.0)
	_cannon(Vector3(0.35, 0, 1.05), 15.0)


# ---------------------------------------------------------------- Palmares

## Macaco: casa grande del rey con techo de palma y alpendre, la capilla y palmeras en la plaza.
static func _macaco() -> void:
	var walls: Color = _pal[0]
	var roof: Color = _pal[1]
	var cz := -0.5
	_box(Vector3(2.2, 0.95, 1.15), Vector3(-0.1, 0.475, cz), walls)
	_hip(Vector3(-0.1, 0.93, cz), 1.3, 0.75, 1.25, roof)
	for x: float in [-1.05, -0.4, 0.25, 0.85]:
		_cyl(0.04, 0.045, 0.75, Vector3(x, 0.375, cz + 0.95), Palette.WOOD_BEAM, 6)
	_box(Vector3(2.2, 0.05, 0.62), Vector3(-0.1, 0.82, cz + 0.85), roof.darkened(0.08), Vector3(14, 0, 0))
	_box(Vector3(0.3, 0.55, 0.03), Vector3(-0.1, 0.28, cz + 0.58), DARK)
	var ch := Vector3(1.0, 0, 0.85)
	_box(Vector3(0.55, 0.75, 0.7), ch + Vector3(0, 0.375, 0), walls.lightened(0.15))
	_gable(ch + Vector3(0, 0.73, 0), 0.6, 0.85, 0.45, roof)
	_box(Vector3(0.04, 0.35, 0.04), ch + Vector3(-0.3, 1.25, 0), Palette.WOOD_BEAM)
	_box(Vector3(0.04, 0.04, 0.18), ch + Vector3(-0.3, 1.33, 0), Palette.WOOD_BEAM)
	_box(Vector3(_hw * 2.0, 0.04, 0.9), Vector3(0, 0.02, 1.0), Palette.DIRT.lightened(0.15))
	_palm(Vector3(-1.35, 0, 0.95), 2.7, Vector2(-0.2, 0.1))
	_palm(Vector3(1.4, 0, -1.2), 3.0, Vector2(0.15, -0.1))
	_palm(Vector3(-1.35, 0, -1.3), 2.5, Vector2(-0.1, -0.15))


## Mocambo de guerra: chozas en el cerro, estacas inclinadas al frente y jirau de vigía.
static func _mocambo_guerra() -> void:
	_cyl(0.9, 1.4, 0.6, Vector3(-0.15, 0.3, -0.35), ROCK, 8)
	_box(Vector3(0.6, 0.4, 0.5), Vector3(-1.1, 0.2, 0.1), ROCK.darkened(0.1), Vector3(5, 30, 8))
	CivMeshes._hut(_p, "palmares", Vector3(-0.45, 0.6, -0.5), 0.7, 0.6, 0.8, _pal, {})
	CivMeshes._hut(_p, "palmares", Vector3(0.35, 0.6, -0.3), 0.55, 0.5, 0.7, _pal, {})
	for i in 15:
		var x := -_hw + 0.1 + i * (_hw * 2.0 - 0.2) / 14.0
		CivMeshes._pole(_p, Vector3(x, 0, 1.05), Vector3(x, 0.8, _hd + 0.1), 0.035, Palette.WOOD_BEAM)
		_cyl(0.0, 0.035, 0.1, Vector3(x, 0.83, _hd + 0.14), Palette.TRUNK, 5, Vector3(55, 0, 0))
	var j := Vector3(1.15, 0, -0.85)
	for c: Vector2 in [Vector2(-1, -1), Vector2(1, -1), Vector2(-1, 1), Vector2(1, 1)]:
		_cyl(0.035, 0.04, 1.9, j + Vector3(c.x * 0.22, 0.95, c.y * 0.22), Palette.WOOD_BEAM, 5)
	_box(Vector3(0.6, 0.05, 0.6), j + Vector3(0, 1.5, 0), Palette.TRUNK)
	_gable(j + Vector3(0, 1.88, 0), 0.7, 0.7, 0.35, _pal[1])
	CivMeshes._pole(_p, j + Vector3(-0.3, 0, 0.5), j + Vector3(-0.15, 1.5, 0.22), 0.02, Palette.WOOD_BEAM)


## Cerca real: tres anillos de cerca con las entradas desfasadas y fojos entre anillos.
static func _cerca_anillos() -> void:
	var n := int(_e.get("anillos", 3))
	var hk := float(_cfg.get("alto_pct", 100)) / 100.0
	var gate := 0.32
	for ring in n:
		var r := _hw - 0.05 - ring * 0.45
		var offs: Array[float] = [0.0, PI * 0.55, -PI * 0.55]
		var ga: float = PI / 2.0 + offs[ring % 3]
		_stakes_arc(Vector3.ZERO, r, ga + gate, ga + TAU - gate, 0.16, (1.25 - ring * 0.15) * hk, 0.055, Palette.WOOD_BEAM)
	for i in 4:
		var a := PI * 0.15 + i * PI * 0.55
		var o := _arc_pt(Vector3.ZERO, _hw - 0.28, a)
		_cyl(0.13, 0.13, 0.02, o + Vector3(0, 0.02, 0), DARK, 10)
		for k in 3:
			_cyl(0.0, 0.015, 0.14, o + Vector3((k - 1) * 0.06, 0.07, 0.0), Palette.TRUNK, 4)
	CivMeshes._hut(_p, "palmares", Vector3(0, 0, -0.1), 0.75, 0.65, 0.9, _pal, {})
	_banner(Vector3(0.3, 0, 0.25), 2.2)


## Ferraria grande: galpón de palma con la fragua encendida, fuelles, yunque y carbón.
static func _ferraria() -> void:
	var roof: Color = _pal[1]
	var cz := -0.35
	for c: Vector2 in [Vector2(-1, -1), Vector2(1, -1), Vector2(-1, 1), Vector2(1, 1)]:
		_cyl(0.045, 0.05, 1.2, Vector3(c.x * 0.95, 0.6, cz + c.y * 0.6), Palette.WOOD_BEAM, 6)
	_gable(Vector3(0, 1.18, cz), 2.3, 1.6, 0.75, roof)
	var fg := Vector3(-0.45, 0, cz - 0.1)
	_box(Vector3(0.65, 0.48, 0.55), fg + Vector3(0, 0.24, 0), Color("8a5a3a"))
	_p.append([Meshes.box(0.42, 0.05, 0.32), Meshes.xf(fg + Vector3(0, 0.5, 0)), Color("ff7a1a"), 2.2])
	_cyl(0.1, 0.14, 0.7, fg + Vector3(0, 0.85, -0.15), Color("6f6a64"), 8)
	for s: float in [-1.0, 1.0]:
		_sph(0.13, fg + Vector3(-0.42, 0.3, s * 0.14), Color("6b4a32"), Vector3(1.3, 0.7, 1.0), 8)
	var an := Vector3(0.4, 0, cz)
	_cyl(0.13, 0.15, 0.32, an + Vector3(0, 0.16, 0), Palette.TRUNK, 8)
	_box(Vector3(0.3, 0.12, 0.14), an + Vector3(0, 0.38, 0), IRON)
	_cyl(0.13, 0.12, 0.25, Vector3(0.85, 0.125, cz + 0.3), WATER.darkened(0.2), 10)
	_cyl(0.0, 0.32, 0.38, Vector3(1.15, 0.19, 0.95), Color("2a2826"), 10)
	for i in 5:
		_box(Vector3(0.6, 0.04, 0.04), Vector3(-1.0, 0.03 + (i / 3) * 0.04, 0.85 + (i % 3) * 0.06), IRON.lightened(0.1))
	_glow(0.05, fg + Vector3(0.1, 0.55, 0.05), Color("ffb040"), 2.5)


## Cucaú: aldea en hileras con roças de maíz, el paiol (granero sobre pilotes) y palmeras. Sin
## bandera blanca: no hay fuente, y el pacto se juró al modo de un soba angoleño, no como una
## rendición (ronda 3 de jugadores; proceso/24, 4i).
static func _cucau() -> void:
	for i in 5:
		_box(Vector3(_hw * 2.0 - 0.2, 0.12, 0.1), Vector3(0, 0.06, 0.65 + i * 0.2), Color("6a8a3a"))
		for k in 8:
			_cyl(0.012, 0.015, 0.4, Vector3(-1.4 + k * 0.4 + (i % 2) * 0.2, 0.2, 0.65 + i * 0.2), Color("7a9a44"), 4)
	for x: float in [-1.05, 0.0, 1.05]:
		CivMeshes._hut(_p, "palmares", Vector3(x, 0, -1.1), 0.72, 0.6, 0.85, _pal, {})
	for x: float in [-0.55, 0.55]:
		CivMeshes._hut(_p, "palmares", Vector3(x, 0, -0.15), 0.65, 0.55, 0.8, _pal, {})
	var pa := Vector3(1.25, 0, 0.0)
	for c: Vector2 in [Vector2(-1, -1), Vector2(1, -1), Vector2(-1, 1), Vector2(1, 1)]:
		_cyl(0.035, 0.04, 0.45, pa + Vector3(c.x * 0.17, 0.225, c.y * 0.17), Palette.WOOD_BEAM, 5)
	_box(Vector3(0.44, 0.4, 0.44), pa + Vector3(0, 0.65, 0), _pal[0].darkened(0.08))
	_hip(pa + Vector3(0, 0.84, 0), 0.3, 0.3, 0.4, _pal[1])
	_palm(Vector3(-1.4, 0, 0.2), 2.6, Vector2(-0.15, 0.05))
	_palm(Vector3(1.45, 0, -0.75), 2.9, Vector2(0.12, -0.08))


## Serra da Barriga: el cerro con la cerca en lo alto, el tambor y el estandarte de Zumbi.
static func _serra_barriga() -> void:
	var h := 1.2
	_cyl(1.0, _hw, h, Vector3(0, h / 2.0, 0), Color("6f6a54"), 9)
	_box(Vector3(0.7, 0.5, 0.6), Vector3(1.1, 0.25, 0.8), ROCK, Vector3(8, 25, -6))
	_box(Vector3(0.5, 0.35, 0.5), Vector3(-1.15, 0.17, 0.85), ROCK.darkened(0.1), Vector3(-6, 40, 10))
	_cyl(1.0, 1.0, 0.03, Vector3(0, h + 0.015, 0), Color("7d7a4c"), 9)
	for ring in 2:
		var r := 0.92 - ring * 0.3
		var ga: float = PI / 2.0 + ring * PI
		_stakes_arc(Vector3(0, h, 0), r, ga + 0.35, ga + TAU - 0.35, 0.15, 0.85 - ring * 0.15, 0.045, Palette.WOOD_BEAM)
	CivMeshes._hut(_p, "palmares", Vector3(-0.15, h, -0.15), 0.55, 0.45, 0.7, _pal, {})
	_cyl(0.17, 0.14, 0.42, Vector3(0.3, h + 0.21, 0.2), Palette.WOOD_BEAM, 10)
	_cyl(0.175, 0.175, 0.02, Vector3(0.3, h + 0.43, 0.2), Color("d8c8a0"), 10)
	_banner(Vector3(0.0, h, 0.35), 2.0)
	_slab(Vector3(-0.2, 0, _hd), Vector3(-0.1, h, 0.85), 0.24, 0.06, Palette.DIRT)


# ---------------------------------------------------------------- Ayutthaya

## Techos siameses escalonados (cumbrera a lo largo de x) con remates (chofa) en las puntas.
static func _thai_roof(at: Vector3, lx: float, wz: float, h: float, tiers: int, col: Color) -> float:
	var trim: Color = _gold() if _dorado() else _pal[2]
	var y := 0.0
	for i in tiers:
		var k := 1.0 - i * 0.22
		_gable(at + Vector3(0, y, 0), lx * k, wz * (1.0 - i * 0.1), h * (1.0 - i * 0.1), col.lightened(i * 0.05))
		y += h * 0.55
	var crest := y + h * 0.45 - h * 0.55
	var lk := lx * (1.0 - (tiers - 1) * 0.22)
	for s: float in [-1.0, 1.0]:
		_cyl(0.0, 0.04, 0.28, at + Vector3(s * lk / 2.0, crest + 0.1, 0), trim, 5, Vector3(0, 0, s * -25))
	return crest


## Pabellón siamés: muros y techos escalonados según la edad.
static func _thai_hall(at: Vector3, lx: float, wz: float, wall_h: float, walls: Color, roof_h := 0.6) -> float:
	var tiers := int(_cfg.get("pisos_techo", 2))
	_box(Vector3(lx, wall_h, wz), at + Vector3(0, wall_h / 2.0, 0), walls)
	return wall_h + _thai_roof(at + Vector3(0, wall_h - 0.02, 0), lx + 0.25, wz + 0.35, roof_h, maxi(1, tiers), _pal[1])


## Prang: torre de mazorca de tradición jemer, sobre basamento, con la punta (dorada desde
## la edad III).
static func _prang(at: Vector3, h: float, col: Color) -> void:
	var s := h / 3.4
	_box(Vector3(1.15 * s, 0.45 * s, 1.15 * s), at + Vector3(0, 0.225 * s, 0), col.darkened(0.06))
	_box(Vector3(0.9 * s, 0.35 * s, 0.9 * s), at + Vector3(0, 0.62 * s, 0), col)
	var y := 0.8 * s
	_cyl(0.36 * s, 0.4 * s, 1.0 * s, at + Vector3(0, y + 0.5 * s, 0), col, 8, Vector3(0, 22.5, 0))
	y += 1.0 * s
	for i in 5:
		var r := 0.42 * s * (1.0 - i * 0.16)
		_cyl(r * 0.82, r, 0.26 * s, at + Vector3(0, y + 0.13 * s, 0), col.lightened(0.03 * i), 8, Vector3(0, 22.5, 0))
		y += 0.26 * s
	_cyl(0.0, 0.07 * s, 0.45 * s, at + Vector3(0, y + 0.22 * s, 0), _gold() if _dorado() else col.darkened(0.2), 6)
	_box(Vector3(0.3 * s, 0.4 * s, 0.03), at + Vector3(0, 0.85 * s + 0.2 * s, 0.4 * s + 0.005), DARK)


## Wat Mahathat: prang central y prangs chicos en las esquinas sobre el basamento; el viharn de
## techos escalonados al frente.
static func _wat_prang() -> void:
	var walls: Color = _pal[0]
	var plaster := walls.lightened(0.15)
	_box(Vector3(_hw * 2.0, 0.2, 2.4), Vector3(0, 0.1, -0.45), plaster.darkened(0.08))
	_box(Vector3(2.4, 0.2, 1.9), Vector3(0, 0.3, -0.5), plaster.darkened(0.04))
	_prang(Vector3(0, 0.4, -0.55), 3.3, plaster)
	for c: Vector2 in [Vector2(-1, -1), Vector2(1, -1), Vector2(-1, 1), Vector2(1, 1)]:
		_prang(Vector3(c.x * 1.2, 0.2, -0.45 + c.y * 0.9), 1.2, plaster.darkened(0.03))
	_thai_hall(Vector3(0, 0, 1.12), 1.5, 0.62, 0.6, Color("f0e8d8") if _dorado() else walls, 0.42)


## Kraal real: empalizada de troncos de teca, el elefante y el pabellón del rey sobre pilotes.
static func _kraal() -> void:
	var teak := Color("6e4a2a")
	var gap := 0.4
	_stakes_line(Vector3(-_hw, 0, -_hd), Vector3(_hw, 0, -_hd), 0.2, 1.15, 0.07, teak)
	_stakes_line(Vector3(-_hw, 0, -_hd), Vector3(-_hw, 0, _hd), 0.2, 1.15, 0.07, teak)
	_stakes_line(Vector3(_hw, 0, -_hd), Vector3(_hw, 0, _hd), 0.2, 1.15, 0.07, teak)
	_stakes_line(Vector3(-_hw, 0, _hd), Vector3(-gap, 0, _hd), 0.2, 1.15, 0.07, teak)
	_stakes_line(Vector3(gap, 0, _hd), Vector3(_hw, 0, _hd), 0.2, 1.15, 0.07, teak)
	for s: float in [-1.0, 1.0]:
		_cyl(0.09, 0.1, 1.7, Vector3(s * gap, 0.85, _hd), teak.darkened(0.1), 6)
	_box(Vector3(gap * 2.0 + 0.3, 0.12, 0.12), Vector3(0, 1.65, _hd), teak.darkened(0.1))
	_box(Vector3(_hw * 2.0 - 0.2, 0.03, _hd * 2.0 - 0.2), Vector3(0, 0.015, 0), Palette.DIRT)
	var tmp: Array = []
	CivMeshes._elephant(tmp, _team, _pal)
	_put(tmp, Vector3(-0.35, 0, 0.3), 35.0, 0.62)
	var pv := Vector3(0.75, 0, -0.85)
	for c: Vector2 in [Vector2(-1, -1), Vector2(1, -1), Vector2(-1, 1), Vector2(1, 1)]:
		_cyl(0.04, 0.045, 0.9, pv + Vector3(c.x * 0.32, 0.45, c.y * 0.28), teak, 6)
	_box(Vector3(0.8, 0.06, 0.7), pv + Vector3(0, 0.92, 0), teak.lightened(0.1))
	_thai_roof(pv + Vector3(0, 1.25, 0), 0.95, 0.85, 0.45, 2, _pal[1])
	for c: Vector2 in [Vector2(-1, -1), Vector2(1, -1), Vector2(-1, 1), Vector2(1, 1)]:
		_cyl(0.025, 0.025, 0.35, pv + Vector3(c.x * 0.3, 1.1, c.y * 0.26), teak, 5)


## Puerto real: el río al frente, muelle, depósitos sobre pilotes, tinajas y un sampán.
static func _puerto() -> void:
	var teak := Color("6e4a2a")
	_water(Vector3(0, 0, 1.05), _hw * 2.0, 1.25)
	for i in 4:
		_cyl(0.03, 0.03, 0.3, Vector3(0.45 + (i % 2) * 0.4, 0.1, 0.6 + (i / 2) * 0.6), teak, 5)
	_box(Vector3(0.55, 0.05, 1.35), Vector3(0.65, 0.22, 0.9), teak.lightened(0.15))
	for st: Array in [[Vector3(-0.75, 0, -0.75), 1.5, 1.0], [Vector3(0.95, 0, -0.95), 1.1, 0.85]]:
		var o: Vector3 = st[0]
		var lx: float = st[1]
		var wz: float = st[2]
		for c: Vector2 in [Vector2(-1, -1), Vector2(1, -1), Vector2(-1, 1), Vector2(1, 1)]:
			_cyl(0.035, 0.04, 0.35, o + Vector3(c.x * lx * 0.42, 0.175, c.y * wz * 0.4), teak, 5)
		_thai_hall(o + Vector3(0, 0.35, 0), lx, wz, 0.55, teak.lightened(0.25), 0.45)
	for i in 6:
		_sph(0.13, Vector3(-0.35 + (i % 3) * 0.27, 0.13 + (i / 3) * 0.2, 0.12 - (i / 3) * 0.08), Color("7a4a2a").darkened(0.05 * (i % 2)), Vector3(1, 1.15, 1), 8)
	var bt := Vector3(-0.75, 0.05, 1.15)
	_box(Vector3(1.1, 0.12, 0.3), bt + Vector3(0, 0.06, 0), teak)
	_p.append([Meshes.cyl(0.17, 0.17, 0.5, 10), Meshes.xf(bt + Vector3(0, 0.15, 0), Vector3(0, 0, 90), Vector3(1, 1, 0.9)), Color("8a6a40")])


## Fortaleza de la isla: muralla de ladrillo encalado con bai sema, baluarte poligonal con
## cañones y la portada de techos escalonados.
static func _fortaleza_isla() -> void:
	var wall := Color("eee8dc")
	CivMeshes._cerco(_p, "muro_blanco", 1.0, _hw, _hd)
	var bc := Vector3(1.05, 0, 1.05)
	_cyl(0.55, 0.6, 1.3, bc + Vector3(0, 0.65, 0), wall.darkened(0.03), 8, Vector3(0, 22.5, 0))
	for i in 8:
		var a := TAU * i / 8.0
		_cyl(0.0, 0.1, 0.22, bc + Vector3(cos(a) * 0.52, 1.41, sin(a) * 0.52), wall, 4, Vector3(0, 45, 0), Vector3(1, 1, 0.45))
	for a: float in [0.2, 0.95, 1.7]:
		CivMeshes._pole(_p, bc + Vector3(cos(a) * 0.4, 1.0, sin(a) * 0.4), bc + Vector3(cos(a) * 0.78, 1.02, sin(a) * 0.78), 0.055, IRON)
	var gt := Vector3(0, 0, _hd - 0.05)
	for s: float in [-1.0, 1.0]:
		_box(Vector3(0.3, 1.25, 0.34), gt + Vector3(s * 0.45, 0.625, 0), wall)
	_box(Vector3(1.2, 0.3, 0.34), gt + Vector3(0, 1.2, 0), wall)
	_thai_roof(gt + Vector3(0, 1.35, 0), 1.2, 0.6, 0.45, 2, _pal[1])
	_thai_hall(Vector3(-0.2, 0, -0.75), 2.2, 0.9, 0.75, _pal[0], 0.5)


## Junco de tributo: velas de listones, popa alta, ojo en la proa; el muelle con los cajones.
static func _junco() -> void:
	_water(Vector3(0, 0, 0.45), _hw * 2.0, 2.4)
	var hull := Color("5e3e26")
	var red := Color("9e3b2a")
	var c := Vector3(0, 0, 0.5)
	_box(Vector3(2.3, 0.32, 0.66), c + Vector3(0, 0.22, 0), hull)
	_p.append([Meshes.prism(0.66, 0.2, 2.2), Meshes.xf(c + Vector3(0, 0.0, 0), Vector3(0, 90, 180)), hull.darkened(0.15)])
	_box(Vector3(0.55, 0.38, 0.68), c + Vector3(1.0, 0.55, 0), hull.lightened(0.05))
	_box(Vector3(0.58, 0.05, 0.7), c + Vector3(1.0, 0.76, 0), red)
	_box(Vector3(0.45, 0.2, 0.62), c + Vector3(-1.15, 0.36, 0), hull, Vector3(0, 0, -12))
	_box(Vector3(2.32, 0.05, 0.68), c + Vector3(0, 0.38, 0), red)
	for s: float in [-1.0, 1.0]:
		_cyl(0.07, 0.07, 0.02, c + Vector3(-1.05, 0.33, s * 0.34), Color("f2ecdf"), 10, Vector3(90, 0, 0))
		_cyl(0.035, 0.035, 0.025, c + Vector3(-1.05, 0.33, s * 0.345), DARK, 8, Vector3(90, 0, 0))
	var masts: Array = [[-0.6, 2.3], [0.2, 2.7], [0.8, 1.8]]
	for i in mini(int(_e.get("mastiles", 3)), masts.size()):
		var mx: float = masts[i][0]
		var mh: float = masts[i][1]
		_cyl(0.03, 0.04, mh, c + Vector3(mx, 0.38 + mh / 2.0, 0), Palette.WOOD_BEAM, 6)
		var sw := 0.75 + mh * 0.1
		var sh := mh * 0.62
		_box(Vector3(sw, sh, 0.025), c + Vector3(mx + sw * 0.38, 0.38 + mh - sh / 2.0 - 0.1, 0), Color("a0522d"))
		for k in 5:
			_box(Vector3(sw + 0.04, 0.025, 0.035), c + Vector3(mx + sw * 0.38, 0.38 + mh - 0.1 - sh * float(k) / 4.0, 0), Color("5a3a22"))
	_banner(c + Vector3(1.15, 0.78, 0), 1.0)
	_box(Vector3(_hw * 2.0, 0.15, 0.6), Vector3(0, 0.075, -1.35), Palette.WOOD_BEAM)
	for i in 5:
		_box(Vector3(0.26, 0.22, 0.24), Vector3(-1.2 + i * 0.32, 0.26, -1.35), Palette.WOOD_BEAM.darkened(0.12) if i % 2 == 0 else red)
	if _dorado():
		_box(Vector3(0.28, 0.2, 0.22), Vector3(0.45, 0.48, -1.35), _gold())


## Guardia extranjera: cuartel siamés, casa a la europea, banderas de varias naciones y cañones.
static func _guardia() -> void:
	_box(Vector3(_hw * 2.0, 0.03, 1.6), Vector3(0, 0.015, 0.6), Palette.DIRT.lightened(0.12))
	_thai_hall(Vector3(0, 0, -1.0), 2.9, 0.8, 0.7, _pal[0], 0.48)
	var eu := Vector3(-1.05, 0, 0.55)
	_box(Vector3(0.8, 0.9, 0.7), eu + Vector3(0, 0.45, 0), Color("ece6da"))
	_gable(eu + Vector3(0, 0.88, 0), 0.85, 0.85, 0.6, Color("9e4a32"))
	_box(Vector3(0.22, 0.45, 0.02), eu + Vector3(0.0, 0.22, 0.36), DARK)
	_box(Vector3(0.04, 0.3, 0.04), eu + Vector3(0.0, 1.6, 0.0), DARK)
	_box(Vector3(0.18, 0.04, 0.04), eu + Vector3(0.0, 1.65, 0.0), DARK)
	var flags: Array = [Color("f2efe6"), Color("c9a24a"), Color("4a7a4a")]
	for i in 3:
		var fp := Vector3(0.45 + i * 0.42, 0, 1.15)
		_cyl(0.02, 0.025, 2.1, fp + Vector3(0, 1.05, 0), Palette.WOOD_BEAM, 5)
		_box(Vector3(0.38, 0.25, 0.02), fp + Vector3(0.2, 1.92, 0), flags[i])
	_cannon(Vector3(-0.1, 0, 0.6), 0.0)
	_cannon(Vector3(0.55, 0, 0.45), 10.0)
