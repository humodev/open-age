class_name WorldView
extends Node3D
## Dibuja el estado de la simulación. No decide nada (docs/06-arquitectura.md).

const P := 1000.0
const LEVEL_H := 1.7 # metros por nivel de altura
static var _vh := PackedFloat32Array() # alturas de vértices (n+1)²
const SPLAT_RES := 2 # píxeles de mezcla por casilla
const CHUNK := 16 # casillas por trozo de malla del terreno
const RELIEF_AMP := 0.22 # ondulación visual sobre los niveles de la simulación
var _splat_img: Image
var _chunks := {} # Vector2i -> MeshInstance3D
var _unit_k := 1.0 # escala de las unidades (reglas.json, escala_visual)
var _clutter_at := {} # casilla -> [multimesh, índice] del detalle del suelo
var _splat_tex: ImageTexture
static var _vn := 0
const O := SimEntity.Order

var sim: Sim
var local: int
var visuals := {} # id -> Dictionary
var selected := {} # id -> true
var hovered := -1
var ground_mat: ShaderMaterial

var _trees: Array[MultiMeshInstance3D] = []
var _bushes: Array = [] # MultiMeshInstance3D por trozo
var _res_slot := {} # id -> [multimesh, índice, transform]
var _fx: Array[Dictionary] = [] # proyectiles, marcadores, muertes, polvo
var _rally_flag: Node3D
var _time := 0.0
var fog_on := true
var _fog_img: Image
var _fog_tex: ImageTexture
var _fog_t := 0.0
var _fog_tick := -1
var _water_mat: ShaderMaterial


func setup(s: Sim, local_player: int) -> void:
	sim = s
	local = local_player
	_build_ground()
	_build_resources()
	_build_clutter()
	_build_crags()
	var n := sim.map.n
	_fog_img = Image.create_from_data(n, n, false, Image.FORMAT_R8, sim.fog.grids[local])
	_fog_tex = ImageTexture.create_from_image(_fog_img)
	ground_mat.set_shader_parameter("fog_tex", _fog_tex)
	ground_mat.set_shader_parameter("fog_on", fog_on)
	if _water_mat != null:
		_water_mat.set_shader_parameter("fog_tex", _fog_tex)
		_water_mat.set_shader_parameter("fog_on", fog_on)
	_rally_flag = _make_flag()
	_rally_flag.visible = false
	add_child(_rally_flag)
	on_tick([])
	for v in visuals.values():
		v["prev"] = v["cur"]


static func to_world(x: int, y: int, h: float = 0.0) -> Vector3:
	var wx := x / P
	var wz := y / P
	return Vector3(wx, h + height_at(wx, wz), wz)


## Altura del terreno suavizado en un punto del mundo (interpolación bilineal).
static func height_at(wx: float, wz: float) -> float:
	if _vn == 0:
		return 0.0
	var fx := clampf(wx, 0.0, _vn - 1.001)
	var fz := clampf(wz, 0.0, _vn - 1.001)
	var ix := int(fx)
	var iz := int(fz)
	var tx := fx - ix
	var tz := fz - iz
	var a := _vh[iz * _vn + ix]
	var b := _vh[iz * _vn + ix + 1]
	var c := _vh[(iz + 1) * _vn + ix]
	var d := _vh[(iz + 1) * _vn + ix + 1]
	return lerpf(lerpf(a, b, tx), lerpf(c, d, tx), tz)


# ---------------------------------------------------------------- Construcción de la escena

func _build_ground() -> void:
	var n := float(sim.map.n)
	var plane := PlaneMesh.new()
	plane.size = Vector2(n + 160.0, n + 160.0)
	plane.subdivide_width = 4
	plane.subdivide_depth = 4
	var mi := MeshInstance3D.new()
	mi.mesh = plane
	mi.position = Vector3(n / 2.0, 0, n / 2.0)
	ground_mat = ShaderMaterial.new()
	ground_mat.shader = preload("res://src/game/shaders/ground.gdshader")
	ground_mat.set_shader_parameter("color_a", Palette.GROUND_A)
	ground_mat.set_shader_parameter("color_b", Palette.GROUND_B)
	ground_mat.set_shader_parameter("dirt", Palette.DIRT)
	ground_mat.set_shader_parameter("map_size", n)
	var noise := FastNoiseLite.new()
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	noise.frequency = 0.008
	noise.fractal_octaves = 4
	var tex := NoiseTexture2D.new()
	tex.width = 512
	tex.height = 512
	tex.seamless = true
	tex.normalize = true
	tex.generate_mipmaps = true
	tex.noise = noise
	ground_mat.set_shader_parameter("noise_tex", tex)
	var T := "res://assets/texturas/suelo/%s.jpg"
	for pair in [["t_grass", "pasto_color"], ["t_dry", "pasto_seco_color"], ["t_dirt", "tierra_color"], ["t_mud", "barro_color"], ["t_rock", "roca_color"], ["n_grass", "pasto_normal"], ["n_dirt", "tierra_normal"], ["n_rock", "roca_normal"]]:
		ground_mat.set_shader_parameter(pair[0], load(T % pair[1]))
	var tn: Array = sim.terrain_def().get("tinte", [100, 100, 100]) # porcentajes
	ground_mat.set_shader_parameter("tint", Color(tn[0] / 100.0, tn[1] / 100.0, tn[2] / 100.0))
	# Tintes del suelo por bioma (data/ambiente.json → suelo).
	var su: Dictionary = Ambiente.of(sim.terrain)["suelo"]
	ground_mat.set_shader_parameter("dry_tint", Ambiente.col(su["seco"]))
	ground_mat.set_shader_parameter("dirt_tint", Ambiente.col(su["tierra"]))
	ground_mat.set_shader_parameter("rock_tint", Ambiente.col(su["roca"]))
	ground_mat.set_shader_parameter("lush_col", Ambiente.col(su["alto"]))
	ground_mat.set_shader_parameter("wet_k", Ambiente.pct(su["humedo"]))
	_build_splat()
	var b0 := sim.bases[0] + Vector2i(2, 2)
	var b1 := sim.bases[1] + Vector2i(2, 2)
	ground_mat.set_shader_parameter("bases", Vector4(b0.x, b0.y, b1.x, b1.y))
	mi.material_override = ground_mat
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.position.y = -1.4 # el borde exterior queda debajo de cauces y orillas
	add_child(mi)
	_build_terrain()


## Malla de terreno con alturas suavizadas y plano de agua (D-027).
func _build_terrain() -> void:
	var map := sim.map
	var n := map.n
	var vn := n + 1
	var raw := PackedFloat32Array()
	raw.resize(vn * vn)
	for j in vn:
		for i in vn:
			var sum := 0.0
			var cnt := 0
			for dz in [-1, 0]:
				for dx in [-1, 0]:
					var tx: int = clampi(i + dx, 0, n - 1)
					var tz: int = clampi(j + dz, 0, n - 1)
					var w := map.water[tz * n + tx]
					if map.rock[tz * n + tx] != 0:
						sum += (float(map.h_at(tx, tz)) + 1.5 + float((tx * 7 + tz * 13) % 5) * 0.12) * LEVEL_H # peñasco
					else:
						sum += -0.9 if w == 1 else (-0.55 if w == 2 else float(map.h_at(tx, tz)) * LEVEL_H)
					cnt += 1
			raw[j * vn + i] = sum / cnt
	# Suavizado para lomas redondeadas; las mesetas guardan sus paredes.
	for pass_i in int(sim.terrain_def().get("suavizado", 2)):
		var out := raw.duplicate()
		for j in range(1, vn - 1):
			for i in range(1, vn - 1):
				var acc := 0.0
				for dz in [-1, 0, 1]:
					for dx in [-1, 0, 1]:
						acc += raw[(j + dz) * vn + i + dx]
				out[j * vn + i] = acc / 9.0
		raw = out
	# Orillas sin escalones: el borde del agua sigue la forma de cada casilla, así
	# que se suaviza más cerca de la orilla, donde se ve la línea (etapa 16).
	var shore := PackedInt32Array()
	for j in range(2, vn - 2):
		for i in range(2, vn - 2):
			var wet := 0
			for dz in range(-3, 3):
				for dx in range(-3, 3):
					if map.is_water(i + dx, j + dz):
						wet += 1
			if wet > 0 and wet < 36 and map.rock[clampi(j, 0, n - 1) * n + clampi(i, 0, n - 1)] == 0:
				shore.append(j * vn + i)
	# Donde el vértice toca dos o más casillas de agua, el suavizado puede hundir
	# pero no levantar: los arroyos de una casilla no quedan en seco.
	var keep := PackedFloat32Array()
	keep.resize(shore.size())
	for k in shore.size():
		var i := shore[k] % vn
		var j := shore[k] / vn
		var touch := 0
		for d in [Vector2i(-1, -1), Vector2i(0, -1), Vector2i(-1, 0), Vector2i(0, 0)]:
			if map.is_water(i + d.x, j + d.y):
				touch += 1
		keep[k] = minf(raw[shore[k]], -0.3) if touch >= 2 else INF
	for pass_i in 4:
		var out := raw.duplicate()
		for k in shore.size():
			var idx := shore[k]
			var acc := 0.0
			for dz in [-vn, 0, vn]:
				for dx in [-1, 0, 1]:
					acc += raw[idx + dz + dx]
			out[idx] = minf(acc / 9.0, keep[k])
		raw = out
	# Ondulación suave para que el llano no sea una mesa (solo imagen; docs/10).
	var noise := FastNoiseLite.new()
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	noise.seed = hash(sim.terrain) ^ sim.entities.size()
	noise.frequency = 0.045
	noise.fractal_octaves = 3
	# Cerca del agua la ondulación se apaga de a poco (si se corta de golpe, la
	# orilla queda con dientes).
	var wd := PackedInt32Array()
	wd.resize(n * n)
	wd.fill(99)
	var front: Array[Vector2i] = []
	for tz in n:
		for tx in n:
			if map.water[tz * n + tx] != 0:
				wd[tz * n + tx] = 0
				front.append(Vector2i(tx, tz))
	for step in 4:
		var nxt: Array[Vector2i] = []
		for t in front:
			for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
				var q: Vector2i = t + d
				if q.x >= 0 and q.y >= 0 and q.x < n and q.y < n and wd[q.y * n + q.x] > step + 1:
					wd[q.y * n + q.x] = step + 1
					nxt.append(q)
		front = nxt
	for j in vn:
		for i in vn:
			var dmin := 99
			for d in [Vector2i(-1, -1), Vector2i(0, -1), Vector2i(-1, 0), Vector2i(0, 0)]:
				var tx := clampi(i + d.x, 0, n - 1)
				var tz := clampi(j + d.y, 0, n - 1)
				dmin = mini(dmin, wd[tz * n + tx])
			var k := clampf((dmin - 1) / 3.0, 0.0, 1.0)
			if k > 0.0:
				raw[j * vn + i] += noise.get_noise_2d(i, j) * RELIEF_AMP * k
	_vh = raw
	_vn = vn
	for cz in ceili(n / float(CHUNK)):
		for cx in ceili(n / float(CHUNK)):
			_rebuild_chunk(cx, cz)
	var has_water := false
	for w in map.water:
		if w != 0:
			has_water = true
			break
	if has_water:
		var plane := PlaneMesh.new()
		plane.size = Vector2(n, n)
		var wmi := MeshInstance3D.new()
		wmi.mesh = plane
		wmi.position = Vector3(n / 2.0, -0.18, n / 2.0)
		_water_mat = ShaderMaterial.new()
		_water_mat.shader = preload("res://src/game/shaders/water.gdshader")
		_water_mat.set_shader_parameter("map_size", float(n))
		_water_mat.set_shader_parameter("water_tex", _water_texture())
		# Agua y reflejo por bioma (data/ambiente.json → agua, cielo, sol).
		var amb := Ambiente.of(sim.terrain)
		var ag: Dictionary = amb["agua"]
		for pair in [["deep", "hondo"], ["shallow", "bajo"], ["silt", "turbio"], ["foam_col", "espuma"]]:
			_water_mat.set_shader_parameter(pair[0], Ambiente.col(ag[pair[1]]))
		_water_mat.set_shader_parameter("turbidity", Ambiente.pct(ag["turbidez"]))
		_water_mat.set_shader_parameter("reflect_k", Ambiente.pct(ag["reflejo"]))
		_water_mat.set_shader_parameter("sky_top", Ambiente.col(amb["cielo"]["cenit"]))
		_water_mat.set_shader_parameter("sky_hor", Ambiente.col(amb["cielo"]["horizonte"]))
		var sun := Basis.from_euler(Vector3(deg_to_rad(-float(amb["sol"]["altura"])), deg_to_rad(float(amb["sol"]["rumbo"])), 0.0))
		_water_mat.set_shader_parameter("sun_dir", sun.z)
		var ondas := OndasAgua.new()
		ondas.name = "OndasAgua"
		ondas.view = self
		ondas.mat = _water_mat
		add_child(ondas)
		var rip := FastNoiseLite.new()
		rip.noise_type = FastNoiseLite.TYPE_SIMPLEX
		rip.frequency = 0.035
		rip.fractal_octaves = 3
		var rtex := NoiseTexture2D.new()
		rtex.width = 256
		rtex.height = 256
		rtex.seamless = true
		rtex.as_normal_map = true
		rtex.bump_strength = 6.0
		rtex.generate_mipmaps = true
		rtex.noise = rip
		_water_mat.set_shader_parameter("ripple", rtex)
		var fz := FastNoiseLite.new()
		fz.noise_type = FastNoiseLite.TYPE_CELLULAR
		fz.frequency = 0.06
		var ftex := NoiseTexture2D.new()
		ftex.width = 256
		ftex.height = 256
		ftex.seamless = true
		ftex.generate_mipmaps = true
		ftex.noise = fz
		_water_mat.set_shader_parameter("foam_noise", ftex)
		wmi.material_override = _water_mat
		wmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(wmi)


## Reconstruye un trozo de la malla del terreno desde `_vh`. Las normales salen
## del campo de alturas, así no hay costuras entre trozos.
func _rebuild_chunk(cx: int, cz: int) -> void:
	var n := sim.map.n
	var vn := _vn
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for j in range(cz * CHUNK, mini(n, (cz + 1) * CHUNK)):
		for i in range(cx * CHUNK, mini(n, (cx + 1) * CHUNK)):
			for c in [Vector2i(i, j), Vector2i(i + 1, j), Vector2i(i + 1, j + 1), Vector2i(i, j), Vector2i(i + 1, j + 1), Vector2i(i, j + 1)]:
				var hl := _vh[c.y * vn + maxi(c.x - 1, 0)]
				var hr := _vh[c.y * vn + mini(c.x + 1, vn - 1)]
				var hu := _vh[maxi(c.y - 1, 0) * vn + c.x]
				var hd := _vh[mini(c.y + 1, vn - 1) * vn + c.x]
				st.set_normal(Vector3(hl - hr, 2.0, hu - hd).normalized())
				st.add_vertex(Vector3(c.x, _vh[c.y * vn + c.x], c.y))
	var key := Vector2i(cx, cz)
	var mi: MeshInstance3D = _chunks.get(key)
	if mi == null:
		mi = MeshInstance3D.new()
		mi.material_override = ground_mat
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
		add_child(mi)
		_chunks[key] = mi
	mi.mesh = st.commit()


## Aplana el suelo bajo un edificio y lo funde con el entorno (docs/10, "Huella aplanada").
func _flatten_footprint(e: SimEntity) -> void:
	if _vn == 0:
		return
	var vn := _vn
	var target := 0.0
	var cnt := 0
	for j in range(e.ty, e.ty + e.h + 1):
		for i in range(e.tx, e.tx + e.w + 1):
			target += _vh[clampi(j, 0, vn - 1) * vn + clampi(i, 0, vn - 1)]
			cnt += 1
	target /= maxf(1.0, cnt)
	var m := 2 # casillas de transición
	for j in range(e.ty - m, e.ty + e.h + m + 1):
		for i in range(e.tx - m, e.tx + e.w + m + 1):
			if i < 0 or j < 0 or i >= vn or j >= vn:
				continue
			if sim.map.is_water(i, j) or sim.map.is_water(i - 1, j) or sim.map.is_water(i, j - 1) or sim.map.is_water(i - 1, j - 1):
				continue # las orillas no se levantan
			var dx := maxi(maxi(e.tx - i, i - (e.tx + e.w)), 0)
			var dz := maxi(maxi(e.ty - j, j - (e.ty + e.h)), 0)
			var d := maxi(dx, dz)
			var k := 1.0 if d == 0 else (1.0 - float(d) / (m + 1)) * 0.85
			_vh[j * vn + i] = lerpf(_vh[j * vn + i], target, k)
	# El detalle del suelo de alrededor sigue a la nueva altura.
	for j in range(e.ty - m - 1, e.ty + e.h + m + 1):
		for i in range(e.tx - m - 1, e.tx + e.w + m + 1):
			var cl: Array = _clutter_at.get(Vector2i(i, j), [])
			if cl.is_empty():
				continue
			var t: Transform3D = cl[2]
			t.origin.y = height_at(t.origin.x, t.origin.z) - 0.02
			cl[2] = t
			(cl[0] as MultiMesh).set_instance_transform(cl[1], t)
	var c0 := Vector2i(maxi(0, e.tx - m - 1) / CHUNK, maxi(0, e.ty - m - 1) / CHUNK)
	var c1 := Vector2i(mini(vn - 2, e.tx + e.w + m + 1) / CHUNK, mini(vn - 2, e.ty + e.h + m + 1) / CHUNK)
	for cz in range(c0.y, c1.y + 1):
		for cx in range(c0.x, c1.x + 1):
			_rebuild_chunk(cx, cz)


## Datos del agua por vértice: R profundidad (0 orilla, 1 hondo), G río (0 lago)
## y BA dirección de la corriente, tomada del trazo de cada río (docs/10).
func _water_texture() -> ImageTexture:
	var map := sim.map
	var vn := _vn
	var flow := {} # casilla -> Vector2
	for path: Array in sim.rivers:
		for i in path.size():
			var a: Vector2i = path[maxi(0, i - 2)]
			var b: Vector2i = path[mini(path.size() - 1, i + 2)]
			var dir := Vector2(b - a).normalized()
			var p: Vector2i = path[i]
			for dy in range(-4, 5):
				for dx in range(-4, 5):
					var t := p + Vector2i(dx, dy)
					if not flow.has(t):
						flow[t] = dir
	var img := Image.create(vn, vn, false, Image.FORMAT_RGBA8)
	var ford := Image.create(vn, vn, false, Image.FORMAT_L8)
	for j in vn:
		for i in vn:
			var wet := false
			var deep := false
			var shallow := 0
			for d in [Vector2i(-1, -1), Vector2i(0, -1), Vector2i(-1, 0), Vector2i(0, 0)]:
				if map.is_water(i + d.x, j + d.y):
					wet = true
					if map.water[clampi(j + d.y, 0, map.n - 1) * map.n + clampi(i + d.x, 0, map.n - 1)] == 1:
						deep = true
					else:
						shallow += 1
			var depth := clampf((-0.18 - _vh[j * vn + i]) / 0.7, 0.0, 1.0) if wet else 0.0
			if wet and not deep:
				depth = minf(depth, 0.1) # vado: agua baja que se ve cruzable
			var f: Vector2 = flow.get(Vector2i(i, j), Vector2.ZERO)
			img.set_pixel(i, j, Color(depth, 1.0 if flow.has(Vector2i(i, j)) else 0.0, f.x * 0.5 + 0.5, f.y * 0.5 + 0.5))
			ford.set_pixel(i, j, Color(shallow / 4.0, 0, 0))
	# Cuatro veces más fina y con interpolación cúbica: los bordes de la mezcla no
	# muestran el escalón de cada casilla (etapa 16).
	img.resize(vn * 4, vn * 4, Image.INTERPOLATE_CUBIC)
	ford.resize(vn * 4, vn * 4, Image.INTERPOLATE_CUBIC)
	if _water_mat != null:
		_water_mat.set_shader_parameter("ford_tex", ImageTexture.create_from_image(ford))
	return ImageTexture.create_from_image(img)


## Mezcla del suelo: R tierra pisada, G barro, B pasto seco (docs/10).
func _build_splat() -> void:
	var map := sim.map
	var n := map.n
	var res := n * SPLAT_RES
	_splat_img = Image.create(res, res, false, Image.FORMAT_RGBA8)
	var dry: float = sim.terrain_def().get("seco", 10) / 100.0
	for y in res:
		for x in res:
			var tx := x / SPLAT_RES
			var ty := y / SPLAT_RES
			var wet := 0.0
			for d in [Vector2i(0, 0), Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1), Vector2i(2, 0), Vector2i(-2, 0), Vector2i(0, 2), Vector2i(0, -2)]:
				if map.is_water(tx + d.x, ty + d.y):
					wet = maxf(wet, 1.0 - (absf(d.x) + absf(d.y)) * 0.3)
			_splat_img.set_pixel(x, y, Color(0.0, wet, clampf(dry + map.h_at(tx, ty) * 0.12, 0.0, 1.0), 1.0))
	# Tierra pisada alrededor de cada base inicial.
	for b in sim.bases.slice(0, sim.players.size()):
		_paint_dirt(Vector2(b.x + 2, b.y + 2), 6.5, 0.85)
	_splat_tex = ImageTexture.create_from_image(_splat_img)
	ground_mat.set_shader_parameter("splat", _splat_tex)
	# Segunda mezcla: R manchas de pasto alto (las mismas que usa el detalle), G pedregal
	# al pie de los peñascos.
	var img2 := Image.create(res, res, false, Image.FORMAT_RG8)
	var lush := DetalleSuelo.lush_noise(sim.terrain)
	var lush_k := Ambiente.pct(Ambiente.of(sim.terrain)["detalle"]["pasto_alto"])
	var rocks: Array[Vector2i] = []
	for ty in n:
		for tx in n:
			if map.rock[ty * n + tx] != 0:
				rocks.append(Vector2i(tx, ty))
	var scree := PackedFloat32Array()
	scree.resize(n * n)
	for r in rocks:
		for dy in range(-3, 4):
			for dx in range(-3, 4):
				var t := r + Vector2i(dx, dy)
				if t.x < 0 or t.y < 0 or t.x >= n or t.y >= n:
					continue
				var k := clampf(1.0 - (Vector2(dx, dy).length() - 0.8) / 2.6, 0.0, 1.0)
				scree[t.y * n + t.x] = maxf(scree[t.y * n + t.x], k)
	for y in res:
		for x in res:
			var fx := (x + 0.5) / SPLAT_RES
			var fy := (y + 0.5) / SPLAT_RES
			var l := DetalleSuelo.lush_at(lush, fx, fy, lush_k)
			if map.is_water(int(fx), int(fy)):
				l = 0.0
			img2.set_pixel(x, y, Color(l, scree[int(fy) * n + int(fx)], 0.0))
	ground_mat.set_shader_parameter("splat2", ImageTexture.create_from_image(img2))


## Pinta tierra pisada en un círculo (centro y radio en casillas).
func _paint_dirt(c: Vector2, r: float, strength: float) -> void:
	var res := _splat_img.get_width()
	var k := float(SPLAT_RES)
	for y in range(int((c.y - r) * k), int((c.y + r) * k) + 1):
		for x in range(int((c.x - r) * k), int((c.x + r) * k) + 1):
			if x < 0 or y < 0 or x >= res or y >= res:
				continue
			var d := Vector2(x / k, y / k).distance_to(c) / r
			if d > 1.0:
				continue
			var px := _splat_img.get_pixel(x, y)
			px.r = maxf(px.r, strength * (1.0 - d * d))
			_splat_img.set_pixel(x, y, px)


## Edificio nuevo: tierra pisada alrededor y sombra de contacto.
func _settle_building(e: SimEntity, root: Node3D) -> void:
	if e.def.get("sagrado", false) or e.def.get("linea", false):
		return
	for j in range(e.ty, e.ty + e.h):
		for i in range(e.tx, e.tx + e.w):
			var cl: Array = _clutter_at.get(Vector2i(i, j), [])
			if not cl.is_empty():
				(cl[0] as MultiMesh).set_instance_transform(cl[1], Transform3D(Basis().scaled(Vector3.ZERO), Vector3.ZERO))
	if not e.def.get("transitable", false):
		_flatten_footprint(e)
		_paint_dirt(Vector2(e.tx + e.w / 2.0, e.ty + e.h / 2.0), maxf(e.w, e.h) * 0.85 + 0.8, 0.9 if e.capital else 0.75)
		if _splat_tex != null:
			_splat_tex.update(_splat_img)
		var dec := Decal.new()
		dec.texture_albedo = _contact_tex()
		dec.size = Vector3(e.w * 1.25, 2.0, e.h * 1.25)
		dec.modulate = Color(0, 0, 0, 0.55)
		dec.position.y = 0.2
		dec.cull_mask = 1
		root.add_child(dec)


static var _contact: Texture2D


static func _contact_tex() -> Texture2D:
	if _contact == null:
		var g := Gradient.new()
		g.set_color(0, Color(0, 0, 0, 0.75))
		g.set_color(1, Color(0, 0, 0, 0.0))
		var t := GradientTexture2D.new()
		t.gradient = g
		t.fill = GradientTexture2D.FILL_RADIAL
		t.fill_from = Vector2(0.5, 0.5)
		t.fill_to = Vector2(1.0, 0.5)
		t.width = 128
		t.height = 128
		_contact = t
	return _contact


## Detalle del suelo según el bioma; solo imagen (docs/10, etapa 16): matas, pasto
## alto en manchas, flores, piedritas en laderas y juncos o totora en las orillas.
## Las hojas se mueven con el viento (shaders/grass.gdshader). Se agrupa en
## bloques de 32 casillas para que la cámara descarte lo que no ve.
func _build_clutter() -> void:
	var map := sim.map
	var n := map.n
	var dry: float = sim.terrain_def().get("seco", 10) / 100.0
	var det: Dictionary = Ambiente.of(sim.terrain)["detalle"]
	var dens := int(det["densidad"])
	var flower_pct := int(det["flores_pct"])
	var reed_pct := int(det["juncos_pct"])
	var lush := DetalleSuelo.lush_noise(sim.terrain)
	var lush_k := Ambiente.pct(det["pasto_alto"])
	const BLOCK := 32
	var nb := ceili(n / float(BLOCK))
	var kinds := 6
	var lists := [] # bloque * kinds + tipo -> [[transform, tx, ty, brillo]]
	lists.resize(nb * nb * kinds)
	for i in lists.size():
		lists[i] = []
	var sides := [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]
	for ty in n:
		for tx in n:
			if map.occupant(tx, ty) != -1:
				continue
			var hsh := _hash(tx * 7919 + ty * 104729 + 17)
			var roll := (hsh / 100) % 100
			var ox := float((hsh / 10000) % 80) / 100.0 + 0.1
			var oz := float((hsh / 800000) % 80) / 100.0 + 0.1
			var kind := -1
			# Orilla: hacia qué lado está el agua honda (los vados quedan despejados).
			var to_water := Vector2.ZERO
			var near_ford := false
			var w := map.water[ty * n + tx]
			for d: Vector2i in sides:
				if not map.in_bounds(tx + d.x, ty + d.y):
					continue
				var wd := map.water[(ty + d.y) * n + tx + d.x]
				if w == 0 and wd == 1:
					to_water += Vector2(d)
				elif w == 1 and wd == 0:
					to_water -= Vector2(d) # desde el agua, hacia la tierra
				if wd == 2 or w == 2:
					near_ford = true
			if w == 2 or near_ford:
				continue
			if to_water != Vector2.ZERO:
				var reed_roll := (hsh / 37) % 100
				if reed_roll < (reed_pct if w == 0 else reed_pct * 2 / 3):
					kind = DetalleSuelo.JUNCOS
					var tw := to_water.normalized()
					# En tierra, contra el agua; en el agua, pegado a la orilla.
					ox = 0.5 + tw.x * (0.38 if w == 0 else 0.3) + float(hsh % 21 - 10) / 100.0
					oz = 0.5 + tw.y * (0.38 if w == 0 else 0.3) + float((hsh / 21) % 21 - 10) / 100.0
			if kind == -1 and w != 0:
				continue
			if kind == -1:
				var l := DetalleSuelo.lush_at(lush, tx + 0.5, ty + 0.5, lush_k)
				if map.is_slope(tx, ty) or map.rock[ty * n + tx] != 0:
					if hsh % 100 < dens:
						kind = DetalleSuelo.PIEDRAS
				elif l > 0.35 and hsh % 100 < 80:
					kind = DetalleSuelo.FLORES if roll < flower_pct * 2 else DetalleSuelo.PASTO_ALTO
				elif hsh % 100 < dens:
					if roll < 10:
						kind = DetalleSuelo.PIEDRAS
					elif roll < 10 + flower_pct and dry < 0.6:
						kind = DetalleSuelo.FLORES
					elif roll < 14 + int(dry * 70.0):
						kind = DetalleSuelo.MATA_SECA
					else:
						kind = DetalleSuelo.MATA
			if kind == -1:
				continue
			var p := Vector3(tx + ox, 0, ty + oz)
			p.y = height_at(p.x, p.z) - 0.02
			var sc := 1.15 + float((hsh / 7) % 50) / 100.0
			var b := 0.85 + float((hsh / 13) % 25) / 100.0
			var blk := (ty / BLOCK) * nb + tx / BLOCK
			lists[blk * kinds + kind].append([Transform3D(Basis(Vector3.UP, float(hsh % 628) / 100.0).scaled(Vector3(sc, sc, sc)), p), tx, ty, b])
	var meshes := []
	for kind in kinds:
		meshes.append(DetalleSuelo.mesh(kind, det))
	var gm := DetalleSuelo.material()
	gm.set_shader_parameter("map_size", float(n))
	gm.set_shader_parameter("wind", Ambiente.pct(det["viento"]))
	gm.set_shader_parameter("fog_on", false)
	for li in lists.size():
		var list: Array = lists[li]
		if list.is_empty():
			continue
		var kind := li % kinds
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.use_colors = true
		mm.mesh = meshes[kind]
		mm.instance_count = list.size()
		for i in list.size():
			var it: Array = list[i]
			mm.set_instance_transform(i, it[0])
			mm.set_instance_color(i, Color(it[3], it[3], it[3]))
			_clutter_at[Vector2i(it[1], it[2])] = [mm, i, it[0]]
		var mmi := MultiMeshInstance3D.new()
		mmi.multimesh = mm
		mmi.material_override = gm
		mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		mmi.visibility_range_end = 95.0 # de lejos no se ven y no se pagan
		add_child(mmi)
	# La niebla se crea después del detalle (setup); se le pasa al terminar.
	(func() -> void:
		if _fog_tex != null:
			gm.set_shader_parameter("fog_tex", _fog_tex)
			gm.set_shader_parameter("fog_on", fog_on)).call_deferred()


## Peñascos: bloques de roca sobre las casillas que no se pasan, para que se lean
## como barrera y no como loma (docs/10).
func _build_crags() -> void:
	var map := sim.map
	var n := map.n
	var list: Array[Transform3D] = []
	for ty in n:
		for tx in n:
			if map.rock[ty * n + tx] == 0:
				continue
			var hsh := _hash(tx * 7919 + ty * 104729 + 5)
			var p := Vector3(tx + 0.5 + float(hsh % 40 - 20) / 100.0, 0, ty + 0.5 + float((hsh / 40) % 40 - 20) / 100.0)
			p.y = height_at(p.x, p.z) - 0.3
			var sc := 1.1 + float((hsh / 7) % 60) / 100.0
			var b := Basis(Vector3.UP, float(hsh % 628) / 100.0).scaled(Vector3(sc, sc * (0.8 + float(hsh % 50) / 100.0), sc))
			list.append(Transform3D(b, p))
	if list.is_empty():
		return
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = Meshes.rock_mesh("penasco")
	mm.instance_count = list.size()
	for i in list.size():
		mm.set_instance_transform(i, list[i])
	var mmi := MultiMeshInstance3D.new()
	mmi.multimesh = mm
	mmi.lod_bias = 0.3 # el peñasco generado tiene más polígonos que la caja procedural
	add_child(mmi)


func _build_resources() -> void:
	var kinds: Array = sim.terrain_def().get("arboles", [0, 1])
	var trees: Array[Array] = []
	for k in kinds:
		trees.append([])
	var bushes: Array = []
	for e in sim.entities:
		if not e.is_resource():
			continue
		match e.type:
			"arbol":
				trees[_hash(e.id) % trees.size()].append(e)
			"arbusto":
				bushes.append(e)
			_:
				var mi := MeshInstance3D.new()
				mi.mesh = Meshes.rock_mesh(e.type)
				mi.position = to_world(e.x, e.y)
				mi.rotation.y = float(_hash(e.id) % 360) * PI / 180.0
				add_child(mi)
				visuals[e.id] = {"node": mi, "kind": "rock", "max": e.amount, "cur": mi.position, "prev": mi.position}
	for k in kinds.size():
		_trees.append_array(_make_mm(Meshes.tree_mesh(int(kinds[k])), trees[k]))
	_bushes = _make_mm(Meshes.bush_mesh(), bushes)


## Árboles y arbustos en MultiMesh partidos en trozos de CHUNK casillas: con los modelos
## generados (más polígonos que los procedurales) así se descarta lo que queda fuera de
## cámara y cada trozo elige su nivel de detalle.
func _make_mm(mesh: Mesh, list: Array) -> Array:
	var groups := {}
	for e in list:
		var key := Vector2i(e.tx / CHUNK, e.ty / CHUNK)
		if not groups.has(key):
			groups[key] = []
		groups[key].append(e)
	var out: Array = []
	for key in groups:
		var part: Array = groups[key]
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.use_colors = true
		mm.mesh = mesh
		mm.instance_count = part.size()
		for i in part.size():
			var e: SimEntity = part[i]
			var hsh := _hash(e.id)
			var s := 0.82 + float(hsh % 45) / 100.0
			var jitter := Vector3(float(hsh % 7 - 3) * 0.04, 0, float((hsh / 7) % 7 - 3) * 0.04)
			var p := to_world(e.x, e.y) + jitter
			p.y = height_at(p.x, p.z)
			# Giro libre, alto un poco distinto del ancho y una leve inclinación.
			var la := float((hsh / 11) % 628) / 100.0
			var lean := Basis(Vector3(cos(la), 0, sin(la)), float((hsh / 13) % 5) * 0.015)
			var b := lean * Basis(Vector3.UP, float(hsh % 628) / 100.0).scaled(Vector3(s, s * (0.9 + float(hsh % 23) / 100.0), s))
			var t := Transform3D(b, p)
			mm.set_instance_transform(i, t)
			mm.set_instance_color(i, Color.WHITE)
			_res_slot[e.id] = [mm, i, t, e.tx, e.ty, -1]
		var mmi := MultiMeshInstance3D.new()
		mmi.multimesh = mm
		mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
		mmi.lod_bias = 0.2
		add_child(mmi)
		out.append(mmi)
	return out


static func _hash(v: int) -> int:
	var x := (v * 2654435761) & 0xffffffff
	x ^= x >> 15
	return x & 0x7fffffff


func _make_visual(e: SimEntity) -> Dictionary:
	var root := Node3D.new()
	var team := Palette.team(e.owner)
	var v := {"node": root, "type": e.type, "owner": e.owner}
	if e.is_unit():
		var msize := 2.6 if e.def.get("elefante", false) else (1.7 if e.def.get("montado", false) else 0.9)
		var body: Node3D = _model_for(e.owner, e.type, msize, true)
		if body == null:
			body = MeshInstance3D.new()
			(body as MeshInstance3D).mesh = unit_mesh_for(e)
		_unit_k = float(sim.data.reglas.get("escala_visual", {}).get("unidad_pct", 100)) / 100.0
		body.scale = Vector3.ONE * _unit_k
		root.add_child(body)
		root.add_child(Meshes.team_disc(team, maxf(0.25, e.radius / 1000.0 + 0.05)))
		var carry := MeshInstance3D.new()
		carry.mesh = Meshes.box(0.2, 0.18, 0.16)
		carry.position = Vector3(0, 0.5, -0.2)
		carry.visible = false
		body.add_child(carry)
		var rr := maxf(0.85, e.radius / 500.0 + 0.3)
		var ring := _ring(0, Vector2(rr, rr))
		root.add_child(ring)
		v.merge({"kind": "unit", "body": body, "carry": carry, "ring": ring, "yaw": 0.0, "lunge": 0.0, "spawn": 0.0, "phase": randf() * TAU})
	else:
		var struct: Node3D = _model_for(e.owner, e.type, minf(e.w, e.h) * 0.98, false)
		if struct == null:
			struct = MeshInstance3D.new()
			(struct as MeshInstance3D).mesh = building_mesh_for(e.owner, e.type, e.def)
		else:
			Meshes.team_banner(struct, Vector3(e.w * 0.42, 0, -e.h * 0.42), Palette.team(e.owner))
		struct = _stretch_to_scale(e, struct)
		root.add_child(struct)
		var found := MeshInstance3D.new()
		found.mesh = Meshes.foundation_mesh(e.w, e.h)
		root.add_child(found)
		var ring := _ring(1, Vector2(e.w + 0.3, e.h + 0.3))
		root.add_child(ring)
		v.merge({"kind": "building", "struct": struct, "found": found, "ring": ring, "pop": 0.0})
		_settle_building(e, root)
		if e.def.get("sagrado", false):
			var flag := MeshInstance3D.new()
			flag.mesh = Meshes.box(0.05, 0.5, 0.6)
			flag.position = Vector3(0.18, 1.75, 0.3)
			var pole := MeshInstance3D.new()
			pole.mesh = Meshes.cyl(0.03, 0.03, 0.6, 6)
			pole.position = Vector3(0, 1.75, 0)
			pole.material_override = Meshes.mat(Palette.WOOD_BEAM)
			root.add_child(pole)
			root.add_child(flag)
			v["flag"] = flag
	root.position = to_world(e.x, e.y)
	add_child(root)
	v["cur"] = root.position
	v["prev"] = root.position
	return v


static var _models := {} # ruta -> PackedScene (o null si no existe)


## Modelo GLB generado (assets/generados/modelos) declarado por la civilización en estilo.modelos.
## Se escala para que su mayor lado horizontal mida `size` y se apoya en el suelo.
func _model_for(owner: int, type: String, size: float, unit: bool) -> Node3D:
	var name: String = sim.dp(owner).civ.get("estilo", {}).get("modelos", {}).get(type, "")
	if name == "":
		return null
	var path := "res://assets/generados/modelos/%s.glb" % name
	if not _models.has(path):
		_models[path] = load(path) if ResourceLoader.exists(path) else null
	var ps: PackedScene = _models[path]
	if ps == null:
		return null
	var inst: Node3D = ps.instantiate()
	var box := _aabb(inst, Transform3D.IDENTITY)
	var horiz := maxf(box.size.x, box.size.z)
	if horiz <= 0.0001:
		return null
	var k := size / horiz
	var holder := Node3D.new()
	if not unit:
		holder.position.y = -0.08 # asentado: apenas hundido en el suelo
	inst.scale = Vector3.ONE * k
	inst.position = Vector3(-(box.position.x + box.size.x / 2.0) * k, -box.position.y * k, -(box.position.z + box.size.z / 2.0) * k)
	if unit:
		inst.rotation.y = 0.0
	holder.add_child(inst)
	_each_geo(holder, func(g: GeometryInstance3D) -> void:
		g.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
		_matte(g))
	return holder


static var _matte_cache := {}


## Materiales mates como la maqueta: sin metal, rugosos y un poco más claros.
static func _matte(g: GeometryInstance3D) -> void:
	if not g is MeshInstance3D or (g as MeshInstance3D).mesh == null:
		return
	var mi := g as MeshInstance3D
	for i in mi.mesh.get_surface_count():
		var m := mi.mesh.surface_get_material(i)
		if not m is StandardMaterial3D:
			continue
		if not _matte_cache.has(m):
			var c := (m as StandardMaterial3D).duplicate() as StandardMaterial3D
			c.metallic = 0.0
			c.roughness = 0.92
			c.metallic_specular = 0.2
			c.albedo_color = Color(1.18, 1.15, 1.1)
			c.cull_mode = BaseMaterial3D.CULL_DISABLED # las mallas generadas son de una sola cara
			_matte_cache[m] = c
		mi.set_surface_override_material(i, _matte_cache[m])


static func _aabb(n: Node, xf: Transform3D) -> AABB:
	var out := AABB()
	var first := true
	var t := xf
	if n is Node3D:
		t = xf * (n as Node3D).transform
	if n is MeshInstance3D and (n as MeshInstance3D).mesh != null:
		var b := t * (n as MeshInstance3D).mesh.get_aabb()
		out = b
		first = false
	for c in n.get_children():
		var cb := _aabb(c, t)
		if cb.size == Vector3.ZERO:
			continue
		out = cb if first else out.merge(cb)
		first = false
	return out


static func _each_geo(n: Node, f: Callable) -> void:
	if n is GeometryInstance3D:
		f.call(n)
	for c in n.get_children():
		_each_geo(c, f)


## Escala coherente (docs/10, paso 5): cada edificio llega al menos a la altura
## de su categoría, para que una casa mida unas tres veces un aldeano.
func _stretch_to_scale(e: SimEntity, struct: Node3D) -> Node3D:
	var ev: Dictionary = sim.data.reglas.get("escala_visual", {})
	var mins: Dictionary = ev.get("altura_min_cm", {})
	var cat := ""
	var dd := sim.dp(e.owner)
	if e.capital or e.type == dd.civ.get("inicio_edificio", "centro") or e.type == "centro":
		cat = "capital"
	elif e.type == "casa" or e.type == dd.civ.get("casa", ""):
		cat = "casa"
	elif e.type.begins_with("torre") or e.def.get("torre", false):
		cat = "torre"
	else:
		for row in dd.hitos:
			if (row as Array).has(e.type):
				cat = "hito"
		if cat == "" and e.def.has("entrena"):
			cat = "produccion"
	var outer := Node3D.new()
	outer.add_child(struct)
	if cat == "" or not mins.has(cat) or e.def.get("transitable", false):
		return outer
	var h := _aabb(struct, Transform3D.IDENTITY).size.y
	if h < 0.3:
		return outer
	var want := float(mins[cat]) / 100.0
	struct.scale.y *= clampf(want / h, 1.0, float(ev.get("estirar_max_pct", 150)) / 100.0)
	return outer


## Malla de unidad según la civilización del dueño (CivMeshes) o la de la capa común.
func unit_mesh_for(e: SimEntity) -> Mesh:
	var style: Dictionary = sim.dp(e.owner).civ.get("estilo", {})
	if style.is_empty():
		return Meshes.unit_mesh(e.type, Palette.team(e.owner))
	return CivMeshes.unit(e.type, e.def, Palette.team(e.owner), style)


## Malla de edificio según la civilización; los hitos eligen forma por opción y edad.
func building_mesh_for(owner: int, type: String, def: Dictionary) -> Mesh:
	var dd := sim.dp(owner)
	var style: Dictionary = dd.civ.get("estilo", {})
	if style.is_empty():
		return Meshes.building_mesh(type, Palette.team(owner))
	var variant := 0
	var tier := 0
	for row in dd.hitos.size():
		var idx: int = (dd.hitos[row] as Array).find(type)
		if idx >= 0:
			variant = idx
			tier = row
	return CivMeshes.building(type, def, Palette.team(owner), style, variant, tier)


func _ring(shape: int, size: Vector2) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = size
	mi.mesh = plane
	var m := Meshes.ring_material(Color.WHITE)
	m.set_shader_parameter("shape", shape)
	m.set_shader_parameter("size", size)
	m.set_shader_parameter("thickness", 0.07 if shape == 0 else 0.1)
	mi.material_override = m
	mi.position.y = 0.03
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.visible = false
	return mi


func _make_flag() -> Node3D:
	var root := Node3D.new()
	var pole := MeshInstance3D.new()
	pole.mesh = Meshes.cyl(0.03, 0.03, 1.4, 6)
	pole.position.y = 0.7
	pole.material_override = Meshes.mat(Palette.WOOD_BEAM)
	root.add_child(pole)
	var cloth := MeshInstance3D.new()
	cloth.mesh = Meshes.box(0.04, 0.4, 0.55)
	cloth.position = Vector3(0, 1.2, 0.28)
	cloth.material_override = Meshes.mat(Palette.team(local))
	root.add_child(cloth)
	return root


# ---------------------------------------------------------------- Ticks

func on_tick(events: Array) -> void:
	for e in sim.actives:
		var v: Dictionary = visuals.get(e.id, {})
		if v.is_empty():
			v = _make_visual(e)
			visuals[e.id] = v
			if e.is_unit():
				v["spawn"] = 1.0
		v["prev"] = v["cur"]
		v["cur"] = to_world(e.x, e.y)
	for ev in events:
		match ev["t"]:
			"died":
				_on_died(ev["id"])
			"absorbed":
				# Cabeza de ganado que entró al corral: se va sin animación de muerte.
				var av: Dictionary = visuals.get(ev["id"], {})
				if not av.is_empty():
					(av["node"] as Node3D).queue_free()
					visuals.erase(ev["id"])
					selected.erase(ev["id"])
			"hit":
				_on_hit(ev)
			"built":
				var v: Dictionary = visuals.get(ev["id"], {})
				if not v.is_empty():
					v["pop"] = 1.0
			"deposit":
				pass


func _on_died(id: int) -> void:
	if _res_slot.has(id):
		var slot: Array = _res_slot[id]
		var mm: MultiMesh = slot[0]
		mm.set_instance_transform(slot[1], Transform3D(Basis().scaled(Vector3.ZERO), Vector3.ZERO))
		_res_slot.erase(id)
		return
	var v: Dictionary = visuals.get(id, {})
	if v.is_empty():
		return
	visuals.erase(id)
	selected.erase(id)
	var node: Node3D = v["node"]
	if v.get("ring") != null:
		v["ring"].visible = false
	if v["kind"] == "unit":
		_fx.append({"kind": "die_unit", "node": node, "t": 0.0, "dur": 2.2, "yaw": node.rotation.y})
	else:
		_fx.append({"kind": "die_building", "node": node, "t": 0.0, "dur": 2.5})
		for i in 8:
			_dust(node.position + Vector3(randf_range(-1.2, 1.2), 0.2, randf_range(-1.2, 1.2)), 0.6 + randf() * 0.6)


func _on_hit(ev: Dictionary) -> void:
	var a: SimEntity = sim.by_id.get(ev["a"])
	var b: SimEntity = sim.by_id.get(ev["b"])
	var va: Dictionary = visuals.get(ev["a"], {})
	if a != null and b != null and fog_state(a) < 2 and fog_state(b) < 2:
		return
	if ev["ranged"] and a != null:
		var from := to_world(a.x, a.y, 0.85 if a.is_unit() else 3.0)
		var to := to_world(b.x, b.y, 0.45) if b != null else from
		if b != null and not b.is_unit():
			to.y = 0.8
		_projectile(from, to, a.is_building())
	elif not va.is_empty() and va["kind"] == "unit":
		va["lunge"] = 1.0
	if b != null and b.is_building():
		var vb: Dictionary = visuals.get(ev["b"], {})
		if not vb.is_empty() and randf() < 0.35:
			_dust(to_world(b.x, b.y, 0.3) + Vector3(randf_range(-0.8, 0.8), 0.2, randf_range(-0.8, 0.8)), 0.35)


func _projectile(from: Vector3, to: Vector3, arrow: bool) -> void:
	var mi := MeshInstance3D.new()
	if arrow:
		mi.mesh = Meshes.box(0.04, 0.04, 0.45)
		mi.material_override = Meshes.mat(Palette.WOOD_BEAM)
	else:
		mi.mesh = Meshes.sphere(0.06, 6)
		mi.material_override = Meshes.mat(Palette.STONE_DARK)
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mi)
	mi.position = from
	var dur := clampf(from.distance_to(to) / 16.0, 0.12, 0.6)
	_fx.append({"kind": "proj", "node": mi, "t": 0.0, "dur": dur, "from": from, "to": to, "arc": from.distance_to(to) * 0.18})


func _dust(pos: Vector3, size: float) -> void:
	var mi := MeshInstance3D.new()
	mi.mesh = Meshes.sphere(0.5, 8)
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(Palette.DIRT, 0.7)
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mi.material_override = m
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.position = pos
	mi.scale = Vector3.ONE * 0.1
	add_child(mi)
	_fx.append({"kind": "dust", "node": mi, "t": 0.0, "dur": 1.1, "size": size, "mat": m})


## Marcador de orden en el suelo.
func add_marker(pos: Vector3, color: Color) -> void:
	var mi := _ring(0, Vector2(1.2, 1.2))
	mi.visible = true
	var m: ShaderMaterial = mi.material_override
	m.set_shader_parameter("color", color)
	m.set_shader_parameter("thickness", 0.1)
	mi.position = pos + Vector3(0, 0.04, 0)
	add_child(mi)
	_fx.append({"kind": "marker", "node": mi, "t": 0.0, "dur": 0.55, "mat": m, "color": color})


# ---------------------------------------------------------------- Imagen

func render(alpha: float, delta: float) -> void:
	_time += delta
	for id in visuals:
		var v: Dictionary = visuals[id]
		var e: SimEntity = sim.by_id.get(id)
		if e == null:
			continue
		match v["kind"]:
			"unit":
				_render_unit(e, v, alpha, delta)
			"building":
				_render_building(e, v, delta)
			"rock":
				var k := 0.45 + 0.55 * float(e.amount) / float(v["max"])
				var rock: MeshInstance3D = v["node"]
				rock.scale = Vector3(1, k, 1)
				var fs := fog_state(e)
				rock.visible = fs > 0
				rock.material_overlay = Meshes.fog_overlay() if fs == 1 else null
	_render_rally()
	_render_fx(delta)
	_render_fog(delta)


func tick_counter() -> int:
	return sim.tick


var _stealth_tick := -1
var _stealth := {}


## Enemigo escondido que el jugador local no detecta (se recalcula una vez por tick).
func _stealthed(e: SimEntity) -> bool:
	if _stealth_tick != sim.tick:
		_stealth_tick = sim.tick
		_stealth.clear()
	if not _stealth.has(e.id):
		_stealth[e.id] = sim.mods.is_hidden_now(e) and not sim.mods.detected_by(e, local)
	return _stealth[e.id]


## Estado de niebla del jugador local (2 = visible) para una entidad.
func fog_state(e: SimEntity) -> int:
	if not fog_on or e.owner == local:
		return 2
	if sim.fog.is_visible(local, e):
		return 0 if _stealthed(e) else 2
	return 1 if sim.fog.is_explored(local, e) else 0


func _render_fog(delta: float) -> void:
	if not fog_on:
		return
	_fog_t -= delta
	if _fog_t > 0.0 or _fog_tick == sim.tick:
		return
	_fog_t = 0.1
	_fog_tick = sim.tick
	_fog_img.set_data(sim.map.n, sim.map.n, false, Image.FORMAT_R8, sim.fog.grids[local])
	_fog_tex.update(_fog_img)
	# Árboles y arbustos: ocultos sin explorar, atenuados fuera de la vista.
	for id in _res_slot:
		var slot: Array = _res_slot[id]
		var st := sim.fog.state(local, slot[3], slot[4])
		if st == slot[5]:
			continue
		slot[5] = st
		var mm: MultiMesh = slot[0]
		if st == 0:
			mm.set_instance_transform(slot[1], Transform3D(Basis().scaled(Vector3.ZERO), Vector3.ZERO))
		else:
			mm.set_instance_transform(slot[1], slot[2])
			mm.set_instance_color(slot[1], Color.WHITE if st == 2 else Color(0.42, 0.44, 0.48))


func _render_unit(e: SimEntity, v: Dictionary, alpha: float, delta: float) -> void:
	var node: Node3D = v["node"]
	node.visible = e.inside < 0 and fog_state(e) == 2
	if not node.visible:
		v["prev"] = v["cur"]
		return
	var body: Node3D = v["body"]
	# Sigilo: las unidades propias escondidas en el monte se ven translúcidas.
	if e.owner == local and (tick_counter() + e.id) % 5 == 0:
		v["hidden"] = sim.mods.is_hidden_now(e)
	if v.get("hidden", false) != v.get("hidden_drawn", false):
		v["hidden_drawn"] = v.get("hidden", false)
		_each_geo(body, func(g: GeometryInstance3D) -> void: g.transparency = 0.45 if v["hidden_drawn"] else 0.0)
	var prev: Vector3 = v["prev"]
	var cur: Vector3 = v["cur"]
	var before := node.position
	node.position = prev.lerp(cur, alpha)
	# El paso sigue a la distancia recorrida: no patina a ninguna velocidad de juego.
	v["walk"] = float(v.get("walk", 0.0)) + Vector2(node.position.x - before.x, node.position.z - before.z).length()
	var move := cur - prev
	var moving := move.length_squared() > 0.00004
	var want: float = v["yaw"]
	if moving:
		want = atan2(move.x, move.z)
	elif e.order == O.ATTACK or e.anchored:
		var t: SimEntity = sim.by_id.get(e.target)
		if t != null:
			var d := to_world(t.x, t.y) - node.position
			if d.length_squared() > 0.0001:
				want = atan2(d.x, d.z)
	v["yaw"] = lerp_angle(float(v["yaw"]), want, clampf(delta * 10.0, 0.0, 1.0))
	node.rotation.y = v["yaw"]
	# Animaciones de maqueta: paso, trabajo y golpe.
	var phase: float = v["phase"]
	var bob := 0.0
	var tilt := 0.0
	var heavy: bool = e.def.get("elefante", false)
	var mounted: bool = e.def.get("montado", false)
	if moving:
		var stride := 3.2 if heavy else (6.5 if mounted else 9.0) # radianes por casilla
		var amp := 0.05 if heavy else (0.09 if mounted else 0.06)
		var w := float(v["walk"]) * stride + phase
		bob = absf(sin(w)) * amp * _unit_k
		tilt = sin(w) * (0.025 if heavy else 0.06)
		if heavy:
			body.rotation.z = sin(w * 0.5) * 0.04
	elif e.order == O.ATTACK and e.anchored and int(e.def.get("alcance", 0)) > 1500:
		# Tensar antes del disparo: se inclina hacia atrás a medida que se recarga.
		var k := 1.0 - clampf(float(e.cooldown) / float(maxi(1, int(e.def.get("cadencia_ms", 1000)))), 0.0, 1.0)
		tilt = -k * 0.18
	elif e.anchored and (e.order == O.GATHER or e.order == O.BUILD):
		tilt = maxf(0.0, sin(_time * 6.0 + phase)) * 0.35
	v["lunge"] = maxf(0.0, float(v["lunge"]) - delta * 5.0)
	var lunge: float = v["lunge"]
	body.position = Vector3(0, bob, lunge * 0.22)
	body.rotation.x = tilt + lunge * 0.3
	v["spawn"] = maxf(0.0, float(v["spawn"]) - delta * 3.0)
	body.scale = Vector3.ONE * _unit_k * (1.0 - float(v["spawn"]) * 0.7)
	var carry: MeshInstance3D = v["carry"]
	carry.visible = e.carry > 0
	if carry.visible:
		carry.material_override = Meshes.mat(Palette.RES.get(e.carry_res, Color.WHITE))
	_update_ring(e, v)


func _render_building(e: SimEntity, v: Dictionary, delta: float) -> void:
	var struct: Node3D = v["struct"]
	var found: MeshInstance3D = v["found"]
	if v.has("flag"):
		(v["flag"] as MeshInstance3D).material_override = Meshes.mat(Palette.team(e.holder) if e.holder >= 0 else Color("e8e2d4"), 0.6, 0.25)
	var fs := fog_state(e)
	(v["node"] as Node3D).visible = fs > 0
	if fs != int(v.get("fog_drawn", -1)):
		v["fog_drawn"] = fs
		var ov := Meshes.fog_overlay() if fs == 1 else null
		_each_geo(struct, func(g: GeometryInstance3D) -> void: g.material_overlay = ov)
	if e.built:
		found.visible = false
		v["pop"] = maxf(0.0, float(v["pop"]) - delta * 2.5)
		var pop: float = v["pop"]
		struct.scale = Vector3(1.0 + pop * 0.06, 1.0 + pop * 0.1, 1.0 + pop * 0.06)
	else:
		found.visible = true
		var k := float(e.progress) / float(maxi(1, e.build_time))
		struct.scale = Vector3(1, 0.04 + 0.96 * k, 1)
		struct.visible = k > 0.01
	_update_ring(e, v)


func _update_ring(e: SimEntity, v: Dictionary) -> void:
	var ring: MeshInstance3D = v["ring"]
	var sel := selected.has(e.id)
	var hov := hovered == e.id
	ring.visible = sel or hov
	if ring.visible:
		var c := Color(1, 1, 1, 0.95)
		if e.owner != local:
			c = Color(Palette.UI_BAD, 0.95)
		if hov and not sel:
			c.a = 0.45
		(ring.material_override as ShaderMaterial).set_shader_parameter("color", c)


func _render_rally() -> void:
	_rally_flag.visible = false
	if selected.size() != 1:
		return
	var b: SimEntity = sim.by_id.get(selected.keys()[0])
	if b == null or not b.is_building() or b.owner != local or not b.rally_set:
		return
	_rally_flag.visible = true
	_rally_flag.position = to_world(b.rally_x, b.rally_y)
	_rally_flag.rotation.y = sin(_time * 2.0) * 0.15


func _render_fx(delta: float) -> void:
	var keep: Array[Dictionary] = []
	for f in _fx:
		f["t"] += delta
		var k: float = clampf(f["t"] / f["dur"], 0.0, 1.0)
		var node: Node3D = f["node"]
		match f["kind"]:
			"proj":
				var from: Vector3 = f["from"]
				var to: Vector3 = f["to"]
				var p := from.lerp(to, k)
				p.y += sin(k * PI) * float(f["arc"])
				var dir := p - node.position
				if dir.length_squared() > 0.00001 and absf(dir.normalized().y) < 0.99:
					node.look_at_from_position(node.position, p, Vector3.UP)
				node.position = p
			"marker":
				node.scale = Vector3.ONE * (1.0 - k * 0.5)
				var c: Color = f["color"]
				(f["mat"] as ShaderMaterial).set_shader_parameter("color", Color(c, 1.0 - k))
			"die_unit":
				var fall := clampf(f["t"] / 0.35, 0.0, 1.0)
				node.rotation = Vector3(fall * PI * 0.5 * 0.95, f["yaw"], 0)
				node.position.y = -maxf(0.0, f["t"] - 1.2) * 0.4
			"die_building":
				node.position.y = -k * k * 3.2
				node.rotation.z = sin(f["t"] * 30.0) * 0.015 * (1.0 - k)
			"dust":
				var s: float = f["size"]
				node.scale = Vector3.ONE * (0.2 + k * s * 1.6)
				node.position.y += delta * 0.4
				(f["mat"] as StandardMaterial3D).albedo_color.a = 0.6 * (1.0 - k)
		if k >= 1.0:
			node.queue_free()
		else:
			keep.append(f)
	_fx = keep


func set_grid(on: bool) -> void:
	ground_mat.set_shader_parameter("grid_alpha", 0.09 if on else 0.0)
