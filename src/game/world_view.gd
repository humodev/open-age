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
var velocidad := 1.0 # velocidad del juego (main.gd): las animaciones de trabajo la siguen
var _anim_frame := 0
var _anim_div := 1
var _anim_vis := 0 # figuras con esqueleto propio en pantalla (el presupuesto por cuadro)
var _anim_total := 0 # todas las figuras animadas en pantalla
var _anim_total_prev := 0
var _anim_div_comp := 1
var _anim_cam: Camera3D
var _anim_k := 1.0 # distancia real por unidad de zoom de la cámara (RtsCamera.k_dist)
var render_us := 0 # tiempo acumulado en render (tools/aldeanos_animados.gd lo lee para medir)
# --- fluidez 7 --- la base linda: tierra pisada, pilas, granjas, tocones, estandartes y modo foto
var base_linda := BaseLinda.new()
var _arboles := {} # id -> true (los que dejan tocón)
# --- fin fluidez 7 ---


func setup(s: Sim, local_player: int) -> void:
	sim = s
	local = local_player
	_unit_k = float(sim.data.reglas.get("escala_visual", {}).get("unidad_pct", 100)) / 100.0
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
	base_linda.setup(self) # --- fluidez 7 ---
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
	var grass_k := float(sim.data.reglas.get("escala_visual", {}).get("pasto_pct", 100)) / 100.0 # matas por debajo de la rodilla (proceso/24, 4p)
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
			var sc := (1.15 + float((hsh / 7) % 50) / 100.0) * grass_k
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
				_arboles[e.id] = true # --- fluidez 7 ---
			"arbusto":
				bushes.append(e)
			_:
				var mi := MeshInstance3D.new()
				mi.mesh = _resource_mesh(e)
				mi.position = to_world(e.x, e.y)
				mi.rotation.y = float(_hash(e.id) % 360) * PI / 180.0
				mi.scale = Vector3.ONE * _res_k(e)
				add_child(mi)
				visuals[e.id] = {"node": mi, "kind": "rock", "max": e.amount, "cur": mi.position, "prev": mi.position, "k0": _res_k(e)}
	# Árboles más altos que la gente, como en AoE4 (proceso/24, 4p; reglas.escala_visual).
	var ev: Dictionary = sim.data.reglas.get("escala_visual", {})
	var tk := Vector2(float(ev.get("arbol_ancho_pct", 100)), float(ev.get("arbol_alto_pct", 100))) / 100.0
	for k in kinds.size():
		_trees.append_array(_make_mm(Meshes.tree_mesh(int(kinds[k])), trees[k], tk))
	_bushes = _make_mm(Meshes.bush_mesh(), bushes)


## Árboles y arbustos en MultiMesh partidos en trozos de CHUNK casillas: con los modelos
## generados (más polígonos que los procedurales) así se descarta lo que queda fuera de
## cámara y cada trozo elige su nivel de detalle.
## `tk`: escala del ancho (x) y del alto (y).
func _make_mm(mesh: Mesh, list: Array, tk := Vector2.ONE) -> Array:
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
			var b := lean * Basis(Vector3.UP, float(hsh % 628) / 100.0).scaled(Vector3(s * tk.x, s * tk.y * (0.9 + float(hsh % 23) / 100.0), s * tk.x))
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
		var body: Node3D = null
		var bk := _unit_k
		# Gente animada (KayKit; proceso/27-animaciones): aldeanos y soldados a pie, persona de
		# alto 1, a la escala de la gente.
		if AldeanoAnimado.usa(e.def, e.type):
			var civ := str(sim.players[e.owner].get("civ", "")) if e.owner >= 0 and e.owner < sim.players.size() else ""
			var tropa: Dictionary = _age_cfg(e.owner, _age_of(e.owner)).get("tropa", {})
			var av := AldeanoAnimado.crear(sim.dp(e.owner).civ.get("estilo", {}), team, FIGURE_H * _unit_k, civ, e.type, e.def, tropa)
			v["anim"] = av
			var sx := AldeanoAnimado.sexo(e.id, e.def) # --- aldeanos por retrato ---
			if sx != "" and not av.tropa:
				AldeanoAnimado.vestir(av, civ, sx, _age_of(e.owner))
				v["sexo"] = sx
				v["civ"] = civ
				v["anim_age"] = _age_of(e.owner) # la ropa cambia con la edad
			if av.tropa:
				v["anim_age"] = _age_of(e.owner) # el equipo cambia con la edad
			body = av.node
			bk = FIGURE_H * _unit_k
		else:
			body = _model_for(e.owner, e.type, msize, true, team)
		if body == null:
			body = MeshInstance3D.new()
			(body as MeshInstance3D).mesh = unit_mesh_for(e)
			v["age"] = _age_of(e.owner) # la maqueta cambia de equipo con la edad
			# La gente de maqueta, al alto de la persona generada (proceso/24, 4p): el cuerpo mide
			# lo mismo que el aldeano y la lanza sobresale. El elefante, la corte móvil y los
			# animales ya tienen su tamaño.
			if not (e.def.get("animal", false) or e.def.get("elefante", false) or e.def.has("despliega_en")):
				bk *= FIGURE_H / MAQUETA_H
		v["k"] = bk
		body.scale = Vector3.ONE * bk
		root.add_child(body)
		root.add_child(Meshes.team_disc(team, maxf(0.25, e.radius / 1000.0 + 0.05)))
		var carry := MeshInstance3D.new()
		carry.mesh = Meshes.box(0.2, 0.18, 0.16)
		carry.position = Vector3(0, 0.5, -0.2)
		carry.visible = false
		body.add_child(carry)
		# Silueta del color del equipo cuando la tapa un árbol o un edificio (proceso/24, 4p).
		var sil := _silueta(team)
		_each_geo(body, func(g: GeometryInstance3D) -> void: g.material_overlay = sil)
		var rr := maxf(0.85, e.radius / 500.0 + 0.3)
		var ring := _ring(0, Vector2(rr, rr))
		root.add_child(ring)
		v.merge({"kind": "unit", "body": body, "carry": carry, "ring": ring, "yaw": 0.0, "lunge": 0.0, "spawn": 0.0, "phase": randf() * TAU})
	else:
		var found := MeshInstance3D.new()
		found.mesh = Meshes.foundation_mesh(e.w, e.h)
		root.add_child(found)
		var ring := _ring(1, Vector2(e.w + 0.3, e.h + 0.3))
		root.add_child(ring)
		v.merge({"kind": "building", "found": found, "ring": ring, "pop": 0.0})
		_build_struct(e, v, _look(e))
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


static var _siluetas := {} # color del equipo -> ShaderMaterial


## Material de la silueta de una unidad tapada (shaders/silueta.gdshader), uno por equipo.
static func _silueta(team: Color) -> ShaderMaterial:
	var key := team.to_html()
	if not _siluetas.has(key):
		var m := ShaderMaterial.new()
		m.shader = preload("res://src/game/shaders/silueta.gdshader")
		m.set_shader_parameter("color", Color(team.r, team.g, team.b, 0.6))
		_siluetas[key] = m
	return _siluetas[key]


static var _models := {} # ruta -> PackedScene (o null si no existe)
const FIGURE_H := 1.25 # alto de una persona generada, antes de escala_visual.unidad_pct
const MAQUETA_H := 0.92 # alto de la persona de maqueta (CivMeshes._person: cabeza arriba a 0,92)
## Giro de los edificios generados (GLB): vienen con la puerta en +z, el lado que la cámara no
## ve (mira hacia +x+z, RtsCamera.YAW_DEG). Media vuelta, como las mallas procedurales
## (Meshes.face_camera); conserva la huella (proceso/24, 4e).
const GLB_FRENTE_YAW := PI


## Modelo GLB generado (assets/generados/modelos) declarado por la civilización en estilo.modelos.
## Se escala para que su mayor lado horizontal mida `size` y se apoya en el suelo.
func _model_for(owner: int, type: String, size: float, unit: bool, team := Color.WHITE) -> Node3D:
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
	var center := Vector2(box.position.x + box.size.x / 2.0, box.position.z + box.size.z / 2.0)
	var waist: Dictionary = {}
	if unit and box.size.y > horiz * 1.3:
		# Figura de pie (aldeanos, arqueros): se escala por la altura, no por la herramienta o
		# el arco que sobresale, y se centra en la cintura; así mide lo mismo que la maqueta
		# y la herramienta no la corre del disco (proceso/19-arte-y-sonido).
		k = FIGURE_H / box.size.y
		waist = _waist(path, inst, box)
		center = waist["c"]
	var holder := Node3D.new()
	if not unit:
		holder.position.y = -0.08 # asentado: apenas hundido en el suelo
	inst.scale = Vector3.ONE * k
	inst.position = Vector3(-center.x * k, -box.position.y * k, -center.y * k)
	if unit:
		inst.rotation.y = 0.0
	holder.add_child(inst)
	if not waist.is_empty():
		# Faja del color del equipo, como el cinturón de la maqueta: se lee aunque el disco
		# quede tapado por un campo o por otras unidades.
		var band := MeshInstance3D.new()
		var tm := TorusMesh.new()
		tm.inner_radius = 0.86
		tm.outer_radius = 1.0
		tm.rings = 16
		tm.ring_segments = 6
		band.mesh = tm
		var r: Vector2 = waist["r"]
		band.scale = Vector3(r.x * k * 1.18, box.size.y * k * 1.0, r.y * k * 1.18)
		band.position = Vector3(0, float(waist["y"]) * k, 0) + Vector3(0, holder.position.y, 0)
		band.material_override = Meshes.mat(team, 0.7)
		band.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		holder.add_child(band)
		holder.set_meta("band", band)
	_each_geo(inst, func(g: GeometryInstance3D) -> void:
		g.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
		_matte(g))
	if not unit:
		_equipo_edificio(inst, name, path, team)
	return holder


static var _equipo_cfg := {}
static var _equipo_mats := {} # "<id del material>_<color>" -> ShaderMaterial
static var _equipo_masks := {} # ruta -> Texture2D


## Color del equipo en un edificio generado (proceso/58-edificios-locales): las telas, toldos y
## fajas que la referencia pintó en rojo plano toman el color del jugador con la máscara
## <modelo>_mascara.png (tools/mascara_equipo_3d.py --edificio) y equipo_3d.gdshader, como los
## aldeanos de Meshy. Sin entrada en data/modelos_equipo.json, el modelo queda como está.
static func _equipo_edificio(inst: Node3D, name: String, path: String, team: Color) -> void:
	if _equipo_cfg.is_empty():
		var raw: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/modelos_equipo.json"))
		_equipo_cfg = raw if raw is Dictionary else {"_vacio": true}
	var cfg: Dictionary = (_equipo_cfg.get("mascaras", {}) as Dictionary).get(name, {})
	if cfg.is_empty():
		return
	var mpath := path.get_basename() + "_mascara.png"
	if not _equipo_masks.has(mpath):
		_equipo_masks[mpath] = load(mpath) if ResourceLoader.exists(mpath) else null
	var mask: Texture2D = _equipo_masks[mpath]
	if mask == null:
		return
	_each_geo(inst, func(g: GeometryInstance3D) -> void:
		if not g is MeshInstance3D or (g as MeshInstance3D).mesh == null:
			return
		var mi := g as MeshInstance3D
		for i in mi.mesh.get_surface_count():
			var base := mi.get_surface_override_material(i)
			if base == null:
				base = mi.mesh.surface_get_material(i)
			if not base is StandardMaterial3D or (base as StandardMaterial3D).albedo_texture == null:
				continue
			var key := "%d_%s" % [base.get_instance_id(), team.to_html()]
			if not _equipo_mats.has(key):
				var m := ShaderMaterial.new()
				m.shader = load("res://src/game/shaders/equipo_3d.gdshader")
				m.set_shader_parameter("textura", (base as StandardMaterial3D).albedo_texture)
				m.set_shader_parameter("mascara", mask)
				m.set_shader_parameter("equipo", team)
				m.set_shader_parameter("luz_ref", float(cfg.get("luz_ref", 0.08)))
				_equipo_mats[key] = m
			mi.set_surface_override_material(i, _equipo_mats[key]))


static var _waists := {} # ruta -> {c: centro xz, r: radios xz, y: alto de la cintura}, en coordenadas del modelo


## Cintura de una figura generada: los vértices a media altura de la cadera, sin la herramienta
## (se toma el percentil 70 de la distancia al centro, no el máximo).
static func _waist(path: String, inst: Node3D, box: AABB) -> Dictionary:
	if _waists.has(path):
		return _waists[path]
	var pts := PackedVector3Array()
	_collect_verts(inst, Transform3D.IDENTITY, pts)
	var y := box.position.y + box.size.y * 0.5
	var band := box.size.y * 0.05
	var xs: Array[float] = []
	var zs: Array[float] = []
	for p in pts:
		if absf(p.y - y) < band:
			xs.append(p.x)
			zs.append(p.z)
	var out := {"c": Vector2(box.position.x + box.size.x / 2.0, box.position.z + box.size.z / 2.0), "r": Vector2(0.1, 0.1) * box.size.y, "y": y - box.position.y}
	if xs.size() >= 8:
		xs.sort()
		zs.sort()
		var c := Vector2(xs[xs.size() / 2], zs[zs.size() / 2])
		var dx: Array[float] = []
		var dz: Array[float] = []
		for i in xs.size():
			dx.append(absf(xs[i] - c.x))
			dz.append(absf(zs[i] - c.y))
		dx.sort()
		dz.sort()
		var cap := box.size.y * 0.16
		out["c"] = c
		out["r"] = Vector2(minf(dx[int(dx.size() * 0.7)], cap), minf(dz[int(dz.size() * 0.7)], cap))
	_waists[path] = out
	return out


static func _collect_verts(n: Node, xf: Transform3D, out: PackedVector3Array) -> void:
	var t := xf
	if n is Node3D:
		t = xf * (n as Node3D).transform
	if n is MeshInstance3D and (n as MeshInstance3D).mesh != null:
		var m := (n as MeshInstance3D).mesh
		for i in m.get_surface_count():
			for v: Vector3 in m.surface_get_arrays(i)[Mesh.ARRAY_VERTEX]:
				out.append(t * v)
	for c in n.get_children():
		_collect_verts(c, t, out)


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


## Escala coherente (docs/10, paso 5; proceso/24-tras-la-segunda-ronda/4p-escala.md): cada
## edificio llega al menos al alto de su categoría (reglas.escala_visual.altura_min_cm), medido en
## el cuerpo, sin estandartes. 0 si el tipo no tiene categoría.
func _want_h(e: SimEntity) -> float:
	return _want_h_of(e.owner, e.type, e.def, e.capital)


func _want_h_of(owner: int, type: String, def: Dictionary, capital: bool) -> float:
	var ev: Dictionary = sim.data.reglas.get("escala_visual", {})
	var mins: Dictionary = ev.get("altura_min_cm", {})
	var cat := ""
	var dd := sim.dp(owner)
	if def.get("maravilla", false): # --- paso 7 ---
		cat = "maravilla"
	elif capital or type == dd.civ.get("inicio_edificio", "centro") or type == "centro":
		cat = "capital"
	elif type == "casa" or type == dd.civ.get("casa", ""):
		cat = "casa"
	elif type.begins_with("torre") or def.get("torre", false) or def.get("fortaleza", false): # --- paso 4 ---
		cat = "torre"
	elif def.get("mercado", false): # --- veterano ronda 5 --- (el mercado no se levantaba)
		cat = "mercado"
	else:
		for row in dd.hitos:
			if (row as Array).has(type):
				cat = "hito"
		if cat == "" and def.has("produce"):
			cat = "produccion"
	if cat == "" or not mins.has(cat) or def.get("transitable", false):
		return 0.0
	return float(mins[cat]) / 100.0


## Modelo generado: se estira parejo hasta el alto de la categoría. `h`: alto del modelo en la
## edad I, así lo que crece con la edad no se pierde al estirar.
func _stretch_k(e: SimEntity, h: float) -> float:
	var want := _want_h(e)
	if want <= 0.0 or h < 0.3:
		return 1.0
	var ev: Dictionary = sim.data.reglas.get("escala_visual", {})
	# --- veterano ronda 5 --- tope propio de un modelo (la ruka: domo bajo)
	var modelo: String = sim.dp(e.owner).civ.get("estilo", {}).get("modelos", {}).get(e.type, "")
	# C-106: el tope vale también para el modelo del pipeline del mismo nombre («local/mapuches_casa»).
	var topes: Dictionary = ev.get("estirar_modelo_max_por_modelo", {})
	var tope := float(topes.get(modelo, topes.get(modelo.get_file(), ev.get("estirar_modelo_max_pct", 150))))
	return clampf(want / h, 1.0, tope / 100.0)


## Maqueta: cómo subir muros y techos hasta el alto de la categoría (Meshes.levante), calculado
## con el cuerpo de la edad I. Los hitos pueden poner su propio tope (data/arte_hitos.json →
## levantar_max_pct: los chatos, como el ushnu, no se vuelven pirámides).
## `age`: la edad que se dibuja (el baluarte bajo de algunos pueblos no se levanta a torre).
func _lev_for(owner: int, type: String, def: Dictionary, capital: bool, age: int) -> Dictionary:
	var want := _want_h_of(owner, type, def, capital)
	if want <= 0.0:
		return {}
	if type == "torre" and str(_age_cfg(owner, age).get("torre", "")) in CivMeshes.arte().get("torres_bajas", []):
		return {}
	var ev: Dictionary = sim.data.reglas.get("escala_visual", {})
	var kmax := float(ev.get("estirar_max_pct", 150)) / 100.0
	var art: String = def.get("arte", type) if def.get("maravilla", false) else type # --- paso 7 ---
	if HitosMeshes.has(art):
		kmax = minf(kmax, float(HitosMeshes.data()[art].get("levantar_max_pct", kmax * 100.0)) / 100.0)
	var h1 := CivMeshes.alto_cuerpo(building_mesh_for(owner, type, def, 1, {}))
	return Meshes.levante(h1, want, float(ev.get("zocalo_cm", 40)) / 100.0, float(ev.get("techo_pct", 50)) / 100.0, kmax)


# ---------------------------------------------------------------- Aspecto por edad y obra

## Edad del dueño (1 a 4); los neutrales, la I.
func _age_of(owner: int) -> int:
	if owner < 0 or owner >= sim.players.size():
		return 1
	return int(sim.players[owner].get("age", 1))


## Aspecto del pueblo del dueño en una edad (data/arte_edades.json).
func _age_cfg(owner: int, age: int) -> Dictionary:
	if owner < 0 or owner >= sim.players.size():
		return {}
	var style: Dictionary = sim.dp(owner).civ.get("estilo", {})
	return CivMeshes.age_cfg(str(sim.players[owner].get("civ", "")), str(style.get("forma", "")), age)


## Qué se dibuja: "f<edad>" terminado, "o<etapa>_<edad>" en obra (etapas de data/arte_edades.json).
func _look(e: SimEntity) -> String:
	var age := _age_of(e.owner)
	if e.built:
		return "f%d" % age
	var pct := 100 * e.progress / maxi(1, e.build_time)
	var stage := 0
	for t in CivMeshes.arte().get("obra", {}).get("etapas_pct", [33, 66]):
		if pct >= int(t):
			stage += 1
	return "o%d_%d" % [stage, age]


## Arma el cuerpo del edificio para `look`. Terminado: el modelo generado (con los adornos de
## la edad) o la maqueta de la edad. En obra: siempre la maqueta, cortada a la altura de la
## etapa, con andamio y material. Se rehace solo cuando cambia la etapa o la edad.
func _build_struct(e: SimEntity, v: Dictionary, look: String) -> void:
	var old: Node3D = v.get("struct")
	if old != null and is_instance_valid(old):
		old.queue_free()
	v["look"] = look
	v["fog_drawn"] = -1
	var age := _age_of(e.owner)
	var cfg := _age_cfg(e.owner, age)
	var mg := CivMeshes.margin()
	var outer := Node3D.new()
	var team := Palette.team(e.owner)
	var model: Node3D = null
	if e.built:
		var esc := minf(1.0, float(cfg.get("escala_pct", 100)) / 100.0)
		var esc1 := minf(1.0, float(_age_cfg(e.owner, 1).get("escala_pct", 100)) / 100.0)
		var cerco := 0.2 if cfg.has("cerco") and (CivMeshes._is_center(e.type, e.def) or e.capital) else 0.0
		var body := maxf(0.8, minf(e.w, e.h) - 2.0 * mg - cerco)
		# sin_modelo: en esa edad el tipo deja el modelo generado y usa la maqueta (el centro
		# etíope en Gondar pasa de la tienda real al castillo; proceso/24, 4i).
		if not (cfg.get("sin_modelo", []) as Array).has(e.type):
			model = _model_for(e.owner, e.type, body * esc, false, team)
		if model != null:
			if cfg.has("modelo_tinte"):
				_tint(model, Color(cfg["modelo_tinte"]))
			var top := _aabb(model, Transform3D.IDENTITY).end.y # el techo, sin el estandarte
			model.rotation.y = GLB_FRENTE_YAW
			var h := _aabb(model, Transform3D.IDENTITY).size.y
			var k := _stretch_k(e, h * esc1 / maxf(esc, 0.01))
			var alto := float(cfg.get("alto_pct", 100)) / 100.0
			model.scale.y *= k * alto
			outer.add_child(model)
			# El estandarte va aparte: no se estira con el modelo (media vuelta, como el modelo).
			var flag_at := Node3D.new()
			flag_at.rotation.y = GLB_FRENTE_YAW
			if CivMeshes.bandera_para(e.type, e.def): # --- fluidez 7 --- solo donde importa y más chico
				Meshes.bandera_k = CivMeshes.bandera_escala()
				Meshes.team_banner(flag_at, Vector3(e.w * 0.42, 0, -e.h * 0.42), team)
				Meshes.bandera_k = 1.0
			outer.add_child(flag_at)
			var dm := CivMeshes.decor(e.type, e.def, team, cfg, e.w, e.h, top * k * alto, body * esc)
			if dm != null:
				var di := MeshInstance3D.new()
				di.mesh = dm
				outer.add_child(di)
	if model == null:
		# Se suben muros y techos, no se estira todo: puertas, cercos y estandartes quedan a la
		# escala de la gente (Meshes.levantar).
		var fin := building_mesh_for(e.owner, e.type, e.def, age, _lev_for(e.owner, e.type, e.def, e.capital, age))
		var k := 1.0
		var mi := MeshInstance3D.new()
		outer.add_child(mi)
		if e.built:
			mi.mesh = fin
		else:
			var stage := int(look.substr(1, 1))
			var cuts: Array = CivMeshes.arte().get("obra", {}).get("corte_pct", [14, 50, 82])
			var top := fin.get_aabb().end.y
			var cut := top * float(cuts[clampi(stage, 0, cuts.size() - 1)]) / 100.0
			mi.mesh = Meshes.clip_below(fin, cut)
			if not (e.def.get("linea", false) or e.def.get("puerta", false) or e.def.get("transitable", false)):
				var ex := MeshInstance3D.new()
				ex.mesh = CivMeshes.obra(stage, e.w, e.h, cut * k, cfg)
				outer.add_child(ex)
	(v["node"] as Node3D).add_child(outer)
	v["struct"] = outer


static var _tint_cache := {}


## Tono de la edad sobre un modelo generado (data/arte_edades.json → modelo_tinte): más
## apagado en la edad I, más claro y limpio desde la III. Materiales compartidos por tono.
static func _tint(n: Node, tint: Color) -> void:
	_each_geo(n, func(g: GeometryInstance3D) -> void:
		if not g is MeshInstance3D or (g as MeshInstance3D).mesh == null:
			return
		var mi := g as MeshInstance3D
		for i in mi.mesh.get_surface_count():
			var m := mi.get_surface_override_material(i)
			if m is ShaderMaterial: # color del equipo (proceso/58): el tono de la edad va en `tinte`
				var ks := "%d_%s" % [m.get_instance_id(), tint.to_html()]
				if not _tint_cache.has(ks):
					var sm := (m as ShaderMaterial).duplicate() as ShaderMaterial
					var t0: Color = sm.get_shader_parameter("tinte") if sm.get_shader_parameter("tinte") != null else Color(1.18, 1.15, 1.1)
					sm.set_shader_parameter("tinte", t0 * tint)
					_tint_cache[ks] = sm
				mi.set_surface_override_material(i, _tint_cache[ks])
				continue
			if not m is StandardMaterial3D:
				continue
			var key := "%d_%s" % [m.get_instance_id(), tint.to_html()]
			if not _tint_cache.has(key):
				var c := (m as StandardMaterial3D).duplicate() as StandardMaterial3D
				c.albedo_color = (m as StandardMaterial3D).albedo_color * tint
				_tint_cache[key] = c
			mi.set_surface_override_material(i, _tint_cache[key]))


## Escala de un recurso del mapa: la caza y los animales sueltos van a la escala de la gente
## (escala_visual.unidad_pct), como el rebaño; rocas y minas, no.
func _res_k(e: SimEntity) -> float:
	return _unit_k if e.type == "venado" or e.type == "rebano_salvaje" else 1.0


## Malla de un recurso del mapa. La caza y los animales sueltos toman la especie de la región:
## la del terreno, si tiene fauna propia, o la del pueblo de la base más cercana
## (data/arte_animales.json). Solo imagen: la simulación no sabe de especies.
func _resource_mesh(e: SimEntity) -> Mesh:
	if e.type != "venado" and e.type != "rebano_salvaje":
		return Meshes.rock_mesh(e.type)
	var civ := ""
	var best := -1
	for i in mini(sim.players.size(), sim.bases.size()):
		var b: Vector2i = sim.bases[i]
		var dx := e.tx - b.x
		var dy := e.ty - b.y
		if best < 0 or dx * dx + dy * dy < best:
			best = dx * dx + dy * dy
			civ = str(sim.players[i].get("civ", ""))
	return Animales.mesh(Animales.salvaje(e.type, civ, str(sim.terrain), _hash(e.id)))


## Malla de unidad según la civilización del dueño (CivMeshes) o la de la capa común; las
## tropas cambian de equipo con la edad.
func unit_mesh_for(e: SimEntity) -> Mesh:
	if e.def.get("animal", false):
		# Rebaño con la silueta de la especie del pueblo (data/arte_animales.json).
		var civ := str(sim.players[e.owner].get("civ", "")) if e.owner >= 0 and e.owner < sim.players.size() else ""
		return Animales.mesh(Animales.rebano(civ))
	var style: Dictionary = sim.dp(e.owner).civ.get("estilo", {})
	if style.is_empty():
		return Meshes.unit_mesh(e.type, Palette.team(e.owner))
	var civ_u := str(sim.players[e.owner].get("civ", "")) if e.owner >= 0 and e.owner < sim.players.size() else "" # --- paso 6, par 3 ---
	return CivMeshes.unit(e.type, e.def, Palette.team(e.owner), style, _age_cfg(e.owner, _age_of(e.owner)), civ_u)


## Malla de edificio según la civilización y la edad (por defecto, la del dueño); los hitos
## eligen forma por opción y edad de destino. `lev`: cómo levantarla (Meshes.levante); sin
## darlo, el de su categoría, así la vista previa al colocar mide lo mismo que el edificio.
func building_mesh_for(owner: int, type: String, def: Dictionary, age: int = -1, lev: Variant = null) -> Mesh:
	if def.get("mercado_neutral", false): # --- comercio --- el neutral se ve según el terreno, con banderín ocre
		return Meshes.building_mesh("mercado_neutral_" + str((sim.terrain_def().get("neutral", {}) as Dictionary).get("estilo", "feria")), Palette.WEALTH.darkened(0.15))
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
	if age < 0:
		age = _age_of(owner)
	if lev == null:
		lev = _lev_for(owner, type, def, false, age)
	return CivMeshes.building(type, def, Palette.team(owner), style, variant, tier, _age_cfg(owner, age), lev)


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
			"recurso_nuevo":
				# Recurso que aparece en la partida (la carne de un animal): la vista solo crea los del principio.
				var re: SimEntity = sim.by_id.get(ev["id"])
				if re != null and re.alive and not visuals.has(re.id):
					var mi := MeshInstance3D.new()
					mi.mesh = _resource_mesh(re)
					mi.position = to_world(re.x, re.y)
					mi.rotation.y = float(_hash(re.id) % 360) * PI / 180.0
					mi.scale = Vector3.ONE * _res_k(re)
					add_child(mi)
					visuals[re.id] = {"node": mi, "kind": "rock", "max": re.amount, "cur": mi.position, "prev": mi.position, "k0": _res_k(re)}
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
			"tiro": # --- esport 1a --- asedio de área: el tiro vuela al punto y marca dónde cae
				_on_shell(ev)
			# --- paso 4 --- asedio de área: polvo en el círculo del golpe
			"area":
				var c := to_world(int(ev["x"]), int(ev["y"]), 0.2)
				var rr := float(ev["r"]) / 1000.0
				for i in 6:
					_dust(c + Vector3(randf_range(-rr, rr) * 0.7, 0.0, randf_range(-rr, rr) * 0.7), 0.45 + randf() * 0.35)
			"built":
				var v: Dictionary = visuals.get(ev["id"], {})
				if not v.is_empty():
					v["pop"] = 1.0
			"deposit":
				base_linda.deposito(ev) # --- fluidez 7 ---


func _on_died(id: int) -> void:
	if _res_slot.has(id):
		var slot: Array = _res_slot[id]
		var mm: MultiMesh = slot[0]
		mm.set_instance_transform(slot[1], Transform3D(Basis().scaled(Vector3.ZERO), Vector3.ZERO))
		_res_slot.erase(id)
		if _arboles.has(id): # --- fluidez 7 --- el árbol talado deja el tocón
			_arboles.erase(id)
			base_linda.tocon(slot[2])
		return
	base_linda.olvidar(id) # --- fluidez 7 ---
	var v: Dictionary = visuals.get(id, {})
	if v.is_empty():
		return
	visuals.erase(id)
	selected.erase(id)
	var node: Node3D = v["node"]
	if v.get("ring") != null:
		v["ring"].visible = false
	if v["kind"] == "unit" and v.has("anim"):
		var ap := AldeanoAnimado.morir(v["anim"])
		_fx.append({"kind": "die_anim", "node": node, "t": 0.0, "dur": 2.6, "ap": ap})
	elif v["kind"] == "unit":
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
	if ev.get("area", false): # --- esport 1a --- el golpe de un tiro que llegó: solo la reacción
		var vh: Dictionary = visuals.get(ev["b"], {})
		if not vh.is_empty() and vh.has("anim"):
			vh["recibe"] = true
		return
	if ev["ranged"] and a != null:
		var from := to_world(a.x, a.y, 0.85 if a.is_unit() else 3.0)
		var to := to_world(b.x, b.y, 0.45) if b != null else from
		if b != null and not b.is_unit():
			to.y = 0.8
		# Flecha desde torres y desde arqueros y ballesteros animados; piedra o bala, el resto.
		var flecha := a.is_building() or (va.has("anim") and str((va["anim"] as AldeanoAnimado.Estado).eq.get("arma", "")) in ["arco", "ballesta"])
		_projectile(from, to, flecha)
		if not va.is_empty() and va["kind"] == "unit":
			va["golpe"] = true # el tiro sale con el gesto (gente animada)
	elif not va.is_empty() and va["kind"] == "unit":
		va["lunge"] = 1.0
		va["golpe"] = true
	# Reacción del que recibe el golpe (gente animada).
	var vr: Dictionary = visuals.get(ev["b"], {})
	if not vr.is_empty() and vr.has("anim"):
		vr["recibe"] = true
	if b != null and b.is_building():
		var vb: Dictionary = visuals.get(ev["b"], {})
		if not vb.is_empty() and randf() < 0.35:
			_dust(to_world(b.x, b.y, 0.3) + Vector3(randf_range(-0.8, 0.8), 0.2, randf_range(-0.8, 0.8)), 0.35)


# --- esport 1a ---
## Tiro del asedio de área: la piedra vuela al punto en el tiempo de la simulación y un anillo
## en el suelo muestra dónde va a caer (se ve si se ve al que tira o el punto).
func _on_shell(ev: Dictionary) -> void:
	var a: SimEntity = sim.by_id.get(ev["a"])
	var x := int(ev["x"])
	var y := int(ev["y"])
	var seen := not fog_on or (a != null and fog_state(a) == 2) or sim.fog.state(local, x / 1000, y / 1000) == 2
	if not seen:
		return
	var to := to_world(x, y, 0.2)
	var dur := float(int(ev["ticks"]) * sim.tick_ms) / 1000.0
	if a != null:
		var from := to_world(a.x, a.y, 1.0)
		_projectile(from, to, false)
		var f: Dictionary = _fx[_fx.size() - 1]
		f["dur"] = dur
		f["arc"] = maxf(1.5, from.distance_to(to) * 0.35)
		(f["node"] as Node3D).scale = Vector3.ONE * 2.2
	var r := 1.0
	if a != null:
		r = float(a.def.get("area", 1000)) / 1000.0
	var mi := _ring(0, Vector2(r * 2.0, r * 2.0))
	mi.visible = true
	var m: ShaderMaterial = mi.material_override
	m.set_shader_parameter("color", Color(Palette.UI_BAD, 0.8))
	m.set_shader_parameter("thickness", 0.06)
	mi.position = to + Vector3(0, -0.14, 0)
	add_child(mi)
	_fx.append({"kind": "marker", "node": mi, "t": 0.0, "dur": dur, "mat": m, "color": Color(Palette.UI_BAD, 0.8)})
# --- fin esport 1a ---


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
	_estela(mi, arrow) # --- fluidez 3 ---
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


# --- fluidez 3 --- respuesta inmediata (data/respuesta.json → efectos; src/game/respuesta.gd)
static var _estela_mat := {}


## Estela corta detrás de la flecha o de la piedra: dice de dónde viene el tiro. Va pegada al
## proyectil, que mira hacia adelante con -Z: la estela queda en +Z.
func _estela(proj: MeshInstance3D, flecha: bool) -> void:
	var d: Dictionary = Respuesta.de("efectos", "estela")
	if d.is_empty():
		return
	var largo := float(d.get("largo_flecha" if flecha else "largo_piedra", 0.8))
	if not _estela_mat.has(flecha):
		var m := StandardMaterial3D.new()
		m.albedo_color = Color(Palette.UI_TEXT if flecha else Palette.DIRT, float(d.get("alfa", 0.45)))
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		_estela_mat[flecha] = m
	var t := MeshInstance3D.new()
	t.mesh = Meshes.box(0.025 if flecha else 0.05, 0.025 if flecha else 0.05, largo)
	t.material_override = _estela_mat[flecha]
	t.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	t.position = Vector3(0, 0, largo * 0.5 + (0.2 if flecha else 0.05))
	proj.add_child(t)


## El blanco de la orden parpadea un instante: rojo si es un enemigo, acento si es un recurso o un
## edificio propio. Sigue a la unidad si se mueve.
func destello(e: SimEntity, color: Color) -> bool:
	var d: Dictionary = Respuesta.de("efectos", "destello")
	if d.is_empty() or e == null:
		return false
	var margen := float(d.get("margen", 1.25))
	var mi: MeshInstance3D
	if e.is_unit():
		var rr := maxf(0.85, e.radius / 500.0 + 0.3) * margen
		mi = _ring(0, Vector2(rr, rr))
	else:
		mi = _ring(1, Vector2(maxf(1.0, e.w) * margen, maxf(1.0, e.h) * margen))
	mi.visible = true
	var m: ShaderMaterial = mi.material_override
	m.set_shader_parameter("color", color)
	m.set_shader_parameter("thickness", float(d.get("grosor", 0.16)))
	mi.position = to_world(e.x, e.y, 0.06)
	add_child(mi)
	_fx.append({"kind": "destello", "node": mi, "t": 0.0, "dur": float(d.get("dur_s", 0.45)), "mat": m,
		"color": color, "id": e.id, "n": int(d.get("parpadeos", 2))})
	return true


## Aro que se abre donde cae la cámara al saltar (Espacio, grupo, aldeano inactivo).
func pulso(pos: Vector3) -> bool:
	var d: Dictionary = Respuesta.de("efectos", "pulso")
	if d.is_empty():
		return false
	var tam := float(d.get("tam", 2.2))
	var mi := _ring(0, Vector2(tam, tam))
	mi.visible = true
	var m: ShaderMaterial = mi.material_override
	m.set_shader_parameter("thickness", 0.08)
	mi.position = Vector3(pos.x, height_at(pos.x, pos.z) + 0.08, pos.z)
	add_child(mi)
	_fx.append({"kind": "pulso", "node": mi, "t": 0.0, "dur": float(d.get("dur_s", 0.45)), "mat": m,
		"color": Palette.UI_ACCENT, "crece": float(d.get("crece", 3.0))})
	return true


## Nubecitas de polvo alrededor del cimiento recién apoyado (`lado`: casillas del edificio).
func polvo_cimiento(pos: Vector3, lado: float) -> bool:
	var d: Dictionary = Respuesta.de("efectos", "polvo_cimiento")
	if d.is_empty():
		return false
	var n := int(d.get("nubes", 5))
	var r := lado * float(d.get("radio_pct", 45)) / 100.0
	for i in n:
		var a := TAU * float(i) / float(n) + randf() * 0.5
		var p := pos + Vector3(cos(a) * r, 0.15, sin(a) * r)
		_dust(p, float(d.get("tam", 0.55)))
		_polvo_claro()
	_dust(pos + Vector3(0, 0.1, 0), float(d.get("tam", 0.55)) * 1.3)
	_polvo_claro()
	return true


## El polvo del cimiento sale ya abierto y más claro que el de los golpes: se lee sobre la tierra.
func _polvo_claro() -> void:
	var f: Dictionary = _fx[_fx.size() - 1]
	f["t"] = 0.15
	(f["mat"] as StandardMaterial3D).albedo_color = Color(Palette.DIRT.lerp(Color.WHITE, 0.45), 0.7)


## Cuántos efectos de un tipo hay vivos (el autotest lo lee).
func fx_vivos(kind: String) -> int:
	var n := 0
	for f in _fx:
		if f["kind"] == kind:
			n += 1
	return n
# --- fin fluidez 3 ---


# ---------------------------------------------------------------- Imagen

func render(alpha: float, delta: float) -> void:
	var t0 := Time.get_ticks_usec()
	_time += delta
	# Presupuesto de los aldeanos animados (data/arte_animaciones.json → rendimiento): con muchos
	# en pantalla, cada uno se actualiza cada `_anim_div` cuadros.
	_anim_frame += 1
	# Las de esqueleto propio y las compartidas llevan cada una su turno: las compartidas se
	# mueven solas cada cuadro y solo hay que mirar si cambiaron de estado.
	_anim_div = maxi(1, ceili(float(_anim_vis) / float(AldeanoAnimado.max_por_cuadro)))
	_anim_div_comp = maxi(1, ceili(float(_anim_total - _anim_vis) / float(AldeanoAnimado.max_por_cuadro)))
	_anim_vis = 0
	_anim_total_prev = _anim_total
	_anim_total = 0
	_anim_cam = get_viewport().get_camera_3d()
	_anim_k = RtsCamera.k_dist() if _anim_cam != null and _anim_cam.get_parent() is RtsCamera else 1.0
	# Esqueletos compartidos entre las figuras que hacen lo mismo (rendimiento.compartir).
	AldeanoAnimado.preparar_coros(self)
	AldeanoAnimado.avanzar_coros(delta * velocidad)
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
				var k0: float = v.get("k0", 1.0)
				rock.scale = Vector3(k0, k * k0, k0)
				var fs := fog_state(e)
				rock.visible = fs > 0
				rock.material_overlay = Meshes.fog_overlay() if fs == 1 else null
	_render_rally()
	_render_fx(delta)
	_render_fog(delta)
	base_linda.render(delta) # --- fluidez 7 ---
	render_us += Time.get_ticks_usec() - t0


# --- fluidez 7 --- Modo foto: la tecla de Opciones → Teclas («modo_foto», O de fábrica).
func _unhandled_key_input(event: InputEvent) -> void:
	var k := event as InputEventKey
	if k == null or not k.pressed or k.echo or sim == null:
		return
	if Teclas.es(k.physical_keycode, "modo_foto"):
		base_linda.alternar_foto()
		get_viewport().set_input_as_handled()
# --- fin fluidez 7 ---


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
	if e.is_building() and e.def.get("maravilla", false): # --- paso 7 --- la maravilla la ven todos
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
	if v.has("anim_age") and int(v["anim_age"]) != _age_of(e.owner):
		v["anim_age"] = _age_of(e.owner)
		if v.has("sexo"): # --- aldeanos por retrato ---
			AldeanoAnimado.vestir(v["anim"], v["civ"], v["sexo"], _age_of(e.owner))
		else:
			AldeanoAnimado.equipar(v["anim"], _age_cfg(e.owner, _age_of(e.owner)).get("tropa", {}))
	if v.has("age") and int(v["age"]) != _age_of(e.owner):
		v["age"] = _age_of(e.owner)
		(body as MeshInstance3D).mesh = unit_mesh_for(e)
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
	if v.has("anim"):
		_render_anim(e, v, moving, Vector2(node.position.x - before.x, node.position.z - before.z).length(), delta)
		v["spawn"] = maxf(0.0, float(v["spawn"]) - delta * 3.0)
		body.scale = Vector3.ONE * float(v.get("k", _unit_k)) * (1.0 - float(v["spawn"]) * 0.7)
		_update_ring(e, v)
		return
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
	body.scale = Vector3.ONE * float(v.get("k", _unit_k)) * (1.0 - float(v["spawn"]) * 0.7)
	var carry: MeshInstance3D = v["carry"]
	carry.visible = e.carry > 0
	if carry.visible:
		carry.material_override = Meshes.mat(Palette.RES.get(e.carry_res, Color.WHITE))
	_update_ring(e, v)


## Figura animada (AldeanoAnimado): fuera de la pantalla no se anima; lejos de la cámara, a la
## mitad de cuadros; con muchas en pantalla, por turnos (render): entre turno y turno se junta
## la distancia y el tiempo, y se aplican juntos. Lejos (o con mucha gente en pantalla), las
## que hacen lo mismo comparten esqueleto.
func _render_anim(e: SimEntity, v: Dictionary, moving: bool, walked: float, delta: float) -> void:
	var node: Node3D = v["node"]
	var av: AldeanoAnimado.Estado = v["anim"]
	var div := _anim_div if av.coro == null else _anim_div_comp
	var dist := 0.0
	if _anim_cam != null:
		if not _anim_cam.is_position_in_frustum(node.position + Vector3(0, 0.4, 0)):
			return
		# En la escala de la lente de referencia (proceso/59): la cámara está más cerca con la
		# lente abierta, pero lo que importa es cuánto mide la figura en pantalla.
		dist = _anim_cam.global_position.distance_to(node.position) / _anim_k
		if dist > AldeanoAnimado.lejos_m:
			div *= 2
	var lejos := dist > AldeanoAnimado.compartir_desde_m or (_anim_total_prev > AldeanoAnimado.compartir_con_mas_de and dist > AldeanoAnimado.cerca_m)
	_anim_total += 1
	if av.coro == null:
		_anim_vis += 1
	av.walk_acc += walked
	av.dt_acc += delta * velocidad
	if v.get("golpe", false):
		v["golpe"] = false
		av.golpe = true
	if v.get("recibe", false):
		v["recibe"] = false
		av.recibe = true
	if (e.id + _anim_frame) % div != 0 and not av.sin_pose():
		return
	var t0 := Time.get_ticks_usec()
	AldeanoAnimado.actualizar(av, e, sim, moving, av.walk_acc, av.dt_acc, av.golpe, av.recibe, lejos)
	av.walk_acc = 0.0
	av.dt_acc = 0.0
	av.golpe = false
	av.recibe = false
	AldeanoAnimado.us_actualizar += Time.get_ticks_usec() - t0


func _render_building(e: SimEntity, v: Dictionary, delta: float) -> void:
	var found: MeshInstance3D = v["found"]
	if v.has("flag"):
		(v["flag"] as MeshInstance3D).material_override = Meshes.mat(Palette.team(e.holder) if e.holder >= 0 else Color("e8e2d4"), 0.6, 0.25)
	var fs := fog_state(e)
	(v["node"] as Node3D).visible = fs > 0
	# Etapa de obra o edad nueva: se rehace el cuerpo (lo ajeno, solo si se ve).
	var look := _look(e)
	if look != v["look"] and fs == 2:
		var aged := e.built and str(v["look"]).begins_with("f")
		_build_struct(e, v, look)
		if aged:
			v["pop"] = 0.7
	var struct: Node3D = v["struct"]
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
		struct.scale = Vector3.ONE
	_update_ring(e, v)


func _update_ring(e: SimEntity, v: Dictionary) -> void:
	var ring: MeshInstance3D = v["ring"]
	var sel := selected.has(e.id)
	var hov := hovered == e.id
	ring.visible = (sel or hov) and not base_linda.foto() # --- fluidez 7 --- (modo foto: sin anillos)
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
			"die_anim":
				(f["ap"] as AnimationPlayer).advance(delta * velocidad)
				node.position.y = -maxf(0.0, f["t"] - 1.6) * 0.4
			"die_building":
				node.position.y = -k * k * 3.2
				node.rotation.z = sin(f["t"] * 30.0) * 0.015 * (1.0 - k)
			# --- fluidez 3 ---
			"destello":
				var e: SimEntity = sim.by_id.get(f["id"])
				var vd: Dictionary = visuals.get(f["id"], {})
				if not vd.is_empty() and is_instance_valid(vd["node"]):
					node.position = (vd["node"] as Node3D).position + Vector3(0, 0.06, 0)
				elif e != null:
					node.position = to_world(e.x, e.y, 0.06)
				var on := fmod(k * float(f["n"]) * 2.0, 2.0) < 1.2
				var cd: Color = f["color"]
				(f["mat"] as ShaderMaterial).set_shader_parameter("color", Color(cd, (1.0 - k * 0.5) if on else 0.15))
				node.scale = Vector3.ONE * (1.0 + 0.12 * sin(k * PI))
			"pulso":
				node.scale = Vector3.ONE * (1.0 + k * float(f["crece"]))
				var cp: Color = f["color"]
				(f["mat"] as ShaderMaterial).set_shader_parameter("color", Color(cp, (1.0 - k) * 0.9))
			# --- fin fluidez 3 ---
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
