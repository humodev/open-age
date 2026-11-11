class_name Meshes
extends RefCounted
## Piezas de maqueta construidas con primitivas y fusionadas en una malla por tipo (docs/07).
## Convención: el frente de una unidad mira hacia +Z.

static var _mats := {}
static var _cache := {}


static func mat(c: Color, rough: float = 0.88, emission: float = 0.0) -> StandardMaterial3D:
	var key := "%s_%.2f_%.2f" % [c.to_html(), rough, emission]
	if _mats.has(key):
		return _mats[key]
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = rough
	m.metallic_specular = 0.25
	if emission > 0.0:
		m.emission_enabled = true
		m.emission = c
		m.emission_energy_multiplier = emission
	_mats[key] = m
	return m


## Fusiona partes [malla, transform, color] en una ArrayMesh con una superficie por color.
static func merge(parts: Array) -> ArrayMesh:
	var by_color := {}
	var order: Array = []
	for part in parts:
		var c: Color = part[2]
		var key := c.to_html()
		if not by_color.has(key):
			by_color[key] = []
			order.append(key)
		by_color[key].append(part)
	var out := ArrayMesh.new()
	for key in order:
		var st := SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		for part in by_color[key]:
			st.append_from(part[0], 0, part[1])
		st.generate_normals()
		var arrays := st.commit_to_arrays()
		out.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
		var c: Color = by_color[key][0][2]
		var emission: float = by_color[key][0][3] if by_color[key][0].size() > 3 else 0.0
		out.surface_set_material(out.get_surface_count() - 1, mat(c, 0.88, emission))
	return out


static func xf(pos: Vector3, rot_deg: Vector3 = Vector3.ZERO, scl: Vector3 = Vector3.ONE) -> Transform3D:
	var b := Basis.from_euler(rot_deg * (PI / 180.0)).scaled(scl)
	return Transform3D(b, pos)


static func box(sx: float, sy: float, sz: float) -> BoxMesh:
	var m := BoxMesh.new()
	m.size = Vector3(sx, sy, sz)
	return m


static func cyl(r_top: float, r_bot: float, hgt: float, seg: int = 12) -> CylinderMesh:
	var m := CylinderMesh.new()
	m.top_radius = r_top
	m.bottom_radius = r_bot
	m.height = hgt
	m.radial_segments = seg
	m.rings = 1
	return m


static func sphere(r: float, seg: int = 12) -> SphereMesh:
	var m := SphereMesh.new()
	m.radius = r
	m.height = r * 2.0
	m.radial_segments = seg
	m.rings = seg / 2
	return m


static func capsule(r: float, hgt: float) -> CapsuleMesh:
	var m := CapsuleMesh.new()
	m.radius = r
	m.height = hgt
	m.radial_segments = 12
	m.rings = 4
	return m


static func prism(sx: float, sy: float, sz: float) -> PrismMesh:
	var m := PrismMesh.new()
	m.size = Vector3(sx, sy, sz)
	return m


# ---------------------------------------------------------------- Unidades

static func unit_mesh(type: String, team: Color) -> ArrayMesh:
	var key := "u_%s_%s" % [type, team.to_html()]
	if _cache.has(key):
		return _cache[key]
	var p: Array = []
	var clay := Palette.CLAY
	var shade := Palette.CLAY_SHADE
	match type:
		"aldeano":
			p.append([capsule(0.17, 0.6), xf(Vector3(0, 0.32, 0)), clay])
			p.append([sphere(0.12), xf(Vector3(0, 0.74, 0)), clay])
			p.append([cyl(0.178, 0.178, 0.07), xf(Vector3(0, 0.42, 0)), team])
			p.append([cyl(0.16, 0.2, 0.06, 10), xf(Vector3(0, 0.83, 0)), shade]) # sombrero
		"guerrero":
			p.append([capsule(0.22, 0.72), xf(Vector3(0, 0.38, 0)), clay])
			p.append([sphere(0.135), xf(Vector3(0, 0.86, 0)), clay])
			p.append([cyl(0.226, 0.226, 0.1), xf(Vector3(0, 0.52, 0)), team])
			p.append([box(0.3, 0.06, 0.12), xf(Vector3(0, 0.96, 0)), team]) # tocado
			p.append([cyl(0.025, 0.03, 0.5, 6), xf(Vector3(0.27, 0.55, 0.12), Vector3(35, 0, 0)), Palette.WOOD_BEAM])
			p.append([sphere(0.09, 8), xf(Vector3(0.27, 0.74, 0.27)), Palette.CLAY_DARK]) # maza
		"hondero":
			p.append([capsule(0.15, 0.66), xf(Vector3(0, 0.34, 0)), clay])
			p.append([sphere(0.115), xf(Vector3(0, 0.78, 0)), clay])
			p.append([cyl(0.155, 0.155, 0.07), xf(Vector3(0, 0.46, 0)), team])
			p.append([cyl(0.018, 0.018, 0.42, 6), xf(Vector3(0.12, 0.66, 0.2), Vector3(70, 0, 0)), Palette.WOOD_BEAM]) # brazo extendido
			p.append([sphere(0.05, 6), xf(Vector3(0.12, 0.74, 0.4)), Palette.STONE_DARK])
			p.append([box(0.22, 0.12, 0.08), xf(Vector3(-0.1, 0.42, -0.14)), shade]) # bolsa
		"lancero":
			p.append([capsule(0.2, 0.7), xf(Vector3(0, 0.37, 0)), clay])
			p.append([sphere(0.125), xf(Vector3(0, 0.84, 0)), clay])
			p.append([cyl(0.13, 0.15, 0.08, 10), xf(Vector3(0, 0.95, 0)), Palette.CLAY_DARK]) # casco
			p.append([cyl(0.26, 0.26, 0.05, 16), xf(Vector3(0.02, 0.48, 0.24), Vector3(90, 0, 0)), team]) # escudo
			p.append([cyl(0.12, 0.12, 0.06, 12), xf(Vector3(0.02, 0.48, 0.27), Vector3(90, 0, 0)), Palette.CLAY_SHADE])
			p.append([cyl(0.018, 0.018, 1.6, 6), xf(Vector3(-0.24, 0.8, 0.05)), Palette.WOOD_BEAM]) # lanza
			p.append([cyl(0.0, 0.045, 0.16, 6), xf(Vector3(-0.24, 1.66, 0.05)), Palette.CLAY_DARK])
	var mesh := merge(p)
	_cache[key] = mesh
	return mesh


static func team_disc(team: Color, r: float) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = cyl(r, r, 0.02, 20)
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(team, 0.55)
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mi.material_override = m
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.position.y = 0.012
	return mi


# ---------------------------------------------------------------- Edificios

static func building_mesh(type: String, team: Color) -> ArrayMesh:
	var key := "b_%s_%s" % [type, team.to_html()]
	if _cache.has(key):
		return _cache[key]
	var p: Array = []
	var clay := Palette.CLAY
	var shade := Palette.CLAY_SHADE
	var dark := Palette.CLAY_DARK
	var roof := Palette.ROOF
	match type:
		"centro":
			p.append([box(3.8, 0.3, 3.8), xf(Vector3(0, 0.15, 0)), dark])
			p.append([box(3.4, 0.2, 3.4), xf(Vector3(0, 0.4, 0)), shade])
			p.append([box(2.4, 1.3, 2.0), xf(Vector3(0, 1.15, -0.2)), clay])
			p.append([prism(2.7, 0.9, 2.3), xf(Vector3(0, 2.25, -0.2)), roof])
			p.append([box(2.72, 0.08, 0.12), xf(Vector3(0, 1.82, 0.95)), team])
			p.append([box(0.9, 0.85, 1.0), xf(Vector3(-1.2, 0.92, 0.9)), clay])
			p.append([prism(1.05, 0.55, 1.15), xf(Vector3(-1.2, 1.62, 0.9)), roof])
			p.append([box(0.9, 0.85, 1.0), xf(Vector3(1.2, 0.92, 0.9)), clay])
			p.append([prism(1.05, 0.55, 1.15), xf(Vector3(1.2, 1.62, 0.9)), roof])
			p.append([box(0.6, 0.8, 0.06), xf(Vector3(0, 0.9, 0.82)), Palette.WOOD_BEAM]) # puerta
			_banner(p, Vector3(1.55, 0.5, -1.4), 2.6, team)
			_banner(p, Vector3(-1.55, 0.5, -1.4), 2.6, team)
		"casa":
			p.append([box(1.7, 0.15, 1.5), xf(Vector3(0, 0.075, 0)), dark])
			p.append([box(1.4, 0.75, 1.15), xf(Vector3(0, 0.52, 0)), clay])
			p.append([prism(1.6, 0.6, 1.3), xf(Vector3(0, 1.2, 0), Vector3(0, 90, 0)), roof])
			p.append([box(0.32, 0.5, 0.05), xf(Vector3(0.2, 0.4, 0.58)), Palette.WOOD_BEAM])
			p.append([box(0.3, 0.08, 0.06), xf(Vector3(0.2, 0.7, 0.6)), team])
		"deposito":
			p.append([box(1.8, 0.12, 1.8), xf(Vector3(0, 0.06, 0)), dark])
			for c in [Vector2(-0.75, -0.75), Vector2(0.75, -0.75), Vector2(-0.75, 0.75), Vector2(0.75, 0.75)]:
				p.append([box(0.12, 1.0, 0.12), xf(Vector3(c.x, 0.6, c.y)), Palette.WOOD_BEAM])
			p.append([prism(1.9, 0.45, 1.9), xf(Vector3(0, 1.32, 0)), roof])
			p.append([box(0.5, 0.4, 0.5), xf(Vector3(-0.35, 0.32, -0.2), Vector3(0, 15, 0)), shade])
			p.append([box(0.4, 0.32, 0.4), xf(Vector3(0.35, 0.28, 0.1), Vector3(0, -10, 0)), shade])
			p.append([cyl(0.18, 0.2, 0.42), xf(Vector3(0.1, 0.33, -0.45)), dark])
			_banner(p, Vector3(0.82, 0.12, 0.82), 1.6, team)
		"granja":
			p.append([box(2.9, 0.06, 2.9), xf(Vector3(0, 0.03, 0)), Palette.FIELD_B])
			for i in 6:
				p.append([box(2.6, 0.09, 0.22), xf(Vector3(0, 0.07, -1.15 + i * 0.46)), Palette.FIELD_A])
			for c in [Vector2(-1.4, -1.4), Vector2(1.4, -1.4), Vector2(-1.4, 1.4), Vector2(1.4, 1.4)]:
				p.append([box(0.08, 0.35, 0.08), xf(Vector3(c.x, 0.18, c.y)), Palette.WOOD_BEAM])
			p.append([box(0.08, 0.12, 0.2), xf(Vector3(1.4, 0.32, -1.4)), team])
		"cuartel":
			p.append([box(2.9, 0.15, 2.9), xf(Vector3(0, 0.075, 0)), dark])
			p.append([box(2.5, 1.0, 1.4), xf(Vector3(0, 0.65, -0.6)), clay])
			p.append([prism(1.6, 0.5, 2.7), xf(Vector3(0, 1.4, -0.6), Vector3(0, 90, 0)), roof])
			p.append([box(2.52, 0.1, 0.1), xf(Vector3(0, 1.1, 0.12)), team])
			for i in 5:
				p.append([box(0.08, 0.4, 0.08), xf(Vector3(-1.3 + i * 0.65, 0.35, 1.35)), Palette.WOOD_BEAM])
			p.append([box(2.7, 0.06, 0.06), xf(Vector3(0, 0.5, 1.35)), Palette.WOOD_BEAM])
			p.append([cyl(0.04, 0.04, 0.9, 6), xf(Vector3(0.6, 0.6, 0.6), Vector3(0, 0, 15)), Palette.WOOD_BEAM]) # poste de práctica
			_banner(p, Vector3(-1.3, 0.15, 0.6), 2.0, team)
			_banner(p, Vector3(1.3, 0.15, 0.6), 2.0, team)
		"torre":
			p.append([box(1.8, 0.2, 1.8), xf(Vector3(0, 0.1, 0)), dark])
			p.append([cyl(0.62, 0.78, 2.6, 10), xf(Vector3(0, 1.5, 0)), clay])
			p.append([cyl(0.82, 0.72, 0.3, 10), xf(Vector3(0, 2.95, 0)), shade])
			for i in 8:
				var a := TAU * i / 8.0
				p.append([box(0.2, 0.25, 0.2), xf(Vector3(cos(a) * 0.7, 3.22, sin(a) * 0.7), Vector3(0, -rad_to_deg(a), 0)), shade])
			p.append([box(0.1, 0.35, 0.05), xf(Vector3(0, 1.4, 0.75)), Palette.WOOD_BEAM])
			_banner(p, Vector3(0, 3.0, 0), 1.2, team)
		"hito":
			# Plataforma escalonada: obra estatal genérica de la capa común.
			p.append([box(3.9, 0.5, 3.9), xf(Vector3(0, 0.25, 0)), dark])
			p.append([box(3.1, 0.5, 3.1), xf(Vector3(0, 0.75, 0)), shade])
			p.append([box(2.3, 0.5, 2.3), xf(Vector3(0, 1.25, 0)), clay])
			p.append([box(1.5, 0.5, 1.5), xf(Vector3(0, 1.75, 0)), shade])
			p.append([box(0.9, 0.7, 0.9), xf(Vector3(0, 2.35, 0)), clay])
			p.append([box(1.0, 0.08, 1.0), xf(Vector3(0, 2.74, 0)), team])
			p.append([box(0.7, 2.0, 0.08), xf(Vector3(0, 1.0, 1.75), Vector3(-45, 0, 0)), Palette.CLAY_DARK]) # escalinata
			for c in [Vector2(-1.75, -1.75), Vector2(1.75, -1.75), Vector2(-1.75, 1.75), Vector2(1.75, 1.75)]:
				_banner(p, Vector3(c.x, 0.5, c.y), 1.4, team)
	var mesh := merge(p)
	_cache[key] = mesh
	return mesh


static func _banner(p: Array, base: Vector3, hgt: float, team: Color) -> void:
	p.append([cyl(0.03, 0.035, hgt, 6), xf(base + Vector3(0, hgt / 2.0, 0)), Palette.WOOD_BEAM])
	p.append([box(0.04, 0.45, 0.4), xf(base + Vector3(0, hgt - 0.3, 0.22)), team])


static func foundation_mesh(w: int, h: int) -> ArrayMesh:
	var key := "f_%d_%d" % [w, h]
	if _cache.has(key):
		return _cache[key]
	var p: Array = []
	var fw := w - 0.15
	var fh := h - 0.15
	p.append([box(fw, 0.06, fh), xf(Vector3(0, 0.03, 0)), Palette.DIRT])
	var t := 0.1
	p.append([box(fw, 0.12, t), xf(Vector3(0, 0.06, -fh / 2)), Palette.WOOD_BEAM])
	p.append([box(fw, 0.12, t), xf(Vector3(0, 0.06, fh / 2)), Palette.WOOD_BEAM])
	p.append([box(t, 0.12, fh), xf(Vector3(-fw / 2, 0.06, 0)), Palette.WOOD_BEAM])
	p.append([box(t, 0.12, fh), xf(Vector3(fw / 2, 0.06, 0)), Palette.WOOD_BEAM])
	for c in [Vector2(-1, -1), Vector2(1, -1), Vector2(-1, 1), Vector2(1, 1)]:
		p.append([box(0.08, 0.9, 0.08), xf(Vector3(c.x * fw / 2, 0.45, c.y * fh / 2)), Palette.WOOD_BEAM])
	var mesh := merge(p)
	_cache[key] = mesh
	return mesh


# ---------------------------------------------------------------- Recursos

static func tree_mesh(variant: int) -> ArrayMesh:
	var key := "tree_%d" % variant
	if _cache.has(key):
		return _cache[key]
	var p: Array = []
	if variant == 0:
		p.append([cyl(0.07, 0.1, 0.5, 6), xf(Vector3(0, 0.25, 0)), Palette.TRUNK])
		p.append([cyl(0.0, 0.48, 0.95, 8), xf(Vector3(0, 0.85, 0)), Palette.FOLIAGE])
		p.append([cyl(0.0, 0.36, 0.75, 8), xf(Vector3(0, 1.3, 0)), Palette.FOLIAGE])
	else:
		p.append([cyl(0.07, 0.1, 0.55, 6), xf(Vector3(0, 0.27, 0)), Palette.TRUNK])
		p.append([sphere(0.45, 10), xf(Vector3(0, 0.95, 0), Vector3.ZERO, Vector3(1, 0.9, 1)), Palette.FOLIAGE_2])
		p.append([sphere(0.3, 8), xf(Vector3(0.18, 1.3, 0.05)), Palette.FOLIAGE_2])
	var mesh := merge(p)
	_cache[key] = mesh
	return mesh


static func bush_mesh() -> ArrayMesh:
	if _cache.has("bush"):
		return _cache["bush"]
	var p: Array = []
	p.append([sphere(0.36, 10), xf(Vector3(0, 0.22, 0), Vector3.ZERO, Vector3(1, 0.7, 1)), Palette.BUSH])
	p.append([sphere(0.22, 8), xf(Vector3(0.22, 0.2, 0.12), Vector3.ZERO, Vector3(1, 0.8, 1)), Palette.BUSH])
	for i in 7:
		var a := TAU * i / 7.0
		p.append([sphere(0.055, 6), xf(Vector3(cos(a) * 0.3, 0.3 + (i % 2) * 0.08, sin(a) * 0.3)), Palette.BERRY])
	var mesh := merge(p)
	_cache["bush"] = mesh
	return mesh


static func rock_mesh(kind: String) -> ArrayMesh:
	if _cache.has(kind):
		return _cache[kind]
	var p: Array = []
	var base := Palette.STONE if kind != "riqueza" else Palette.WEALTH_ROCK
	var dark := Palette.STONE_DARK if kind != "riqueza" else Palette.WEALTH_ROCK.darkened(0.15)
	p.append([box(1.0, 0.7, 0.9), xf(Vector3(-0.25, 0.3, -0.1), Vector3(8, 25, 6)), base])
	p.append([box(0.8, 0.55, 0.7), xf(Vector3(0.4, 0.25, 0.3), Vector3(-6, -20, 10)), dark])
	p.append([box(0.6, 0.45, 0.6), xf(Vector3(0.3, 0.22, -0.5), Vector3(12, 40, -8)), base])
	p.append([box(0.5, 0.35, 0.5), xf(Vector3(-0.5, 0.17, 0.55), Vector3(0, 10, 12)), dark])
	if kind == "riqueza":
		var tilts := [Vector3(12, 0, -8), Vector3(-15, 0, 10), Vector3(5, 0, 18), Vector3(-10, 0, -14), Vector3(18, 0, 4), Vector3(-6, 0, -20), Vector3(0, 0, 12)]
		var spots := [Vector3(-0.2, 0.7, -0.1), Vector3(0.35, 0.55, 0.35), Vector3(0.25, 0.5, -0.45), Vector3(-0.45, 0.4, 0.5), Vector3(0.05, 0.62, 0.1), Vector3(-0.55, 0.45, -0.35), Vector3(0.55, 0.4, -0.05)]
		for i in spots.size():
			p.append([cyl(0.0, 0.16, 0.55, 5), xf(spots[i], tilts[i]), Palette.WEALTH, 0.6])
	var mesh := merge(p)
	_cache[kind] = mesh
	return mesh


# ---------------------------------------------------------------- Efectos

static func ring_material(color: Color) -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = preload("res://src/game/shaders/ring.gdshader")
	m.set_shader_parameter("color", color)
	return m
