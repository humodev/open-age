class_name WorldView
extends Node3D
## Dibuja el estado de la simulación. No decide nada (docs/06-arquitectura.md).

const P := 1000.0
const O := SimEntity.Order

var sim: Sim
var local: int
var visuals := {} # id -> Dictionary
var selected := {} # id -> true
var hovered := -1
var ground_mat: ShaderMaterial

var _trees: Array[MultiMeshInstance3D] = []
var _bushes: MultiMeshInstance3D
var _res_slot := {} # id -> [multimesh, índice, transform]
var _fx: Array[Dictionary] = [] # proyectiles, marcadores, muertes, polvo
var _rally_flag: Node3D
var _time := 0.0


func setup(s: Sim, local_player: int) -> void:
	sim = s
	local = local_player
	_build_ground()
	_build_resources()
	_rally_flag = _make_flag()
	_rally_flag.visible = false
	add_child(_rally_flag)
	on_tick([])
	for v in visuals.values():
		v["prev"] = v["cur"]


static func to_world(x: int, y: int, h: float = 0.0) -> Vector3:
	return Vector3(x / P, h, y / P)


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
	var b0 := sim.bases[0] + Vector2i(2, 2)
	var b1 := sim.bases[1] + Vector2i(2, 2)
	ground_mat.set_shader_parameter("bases", Vector4(b0.x, b0.y, b1.x, b1.y))
	mi.material_override = ground_mat
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mi)


func _build_resources() -> void:
	var trees: Array[Array] = [[], []]
	var bushes: Array = []
	for e in sim.entities:
		if not e.is_resource():
			continue
		match e.type:
			"arbol":
				trees[_hash(e.id) % 2].append(e)
			"arbusto":
				bushes.append(e)
			_:
				var mi := MeshInstance3D.new()
				mi.mesh = Meshes.rock_mesh(e.type)
				mi.position = to_world(e.x, e.y)
				mi.rotation.y = float(_hash(e.id) % 360) * PI / 180.0
				add_child(mi)
				visuals[e.id] = {"node": mi, "kind": "rock", "max": e.amount, "cur": mi.position, "prev": mi.position}
	for variant in 2:
		_trees.append(_make_mm(Meshes.tree_mesh(variant), trees[variant]))
	_bushes = _make_mm(Meshes.bush_mesh(), bushes)


func _make_mm(mesh: Mesh, list: Array) -> MultiMeshInstance3D:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = mesh
	mm.instance_count = list.size()
	for i in list.size():
		var e: SimEntity = list[i]
		var hsh := _hash(e.id)
		var s := 0.85 + float(hsh % 40) / 100.0
		var jitter := Vector3(float(hsh % 7 - 3) * 0.04, 0, float((hsh / 7) % 7 - 3) * 0.04)
		var t := Transform3D(Basis(Vector3.UP, float(hsh % 628) / 100.0).scaled(Vector3(s, s * (0.9 + float(hsh % 23) / 100.0), s)), to_world(e.x, e.y) + jitter)
		mm.set_instance_transform(i, t)
		_res_slot[e.id] = [mm, i, t]
	var mmi := MultiMeshInstance3D.new()
	mmi.multimesh = mm
	add_child(mmi)
	return mmi


static func _hash(v: int) -> int:
	var x := (v * 2654435761) & 0xffffffff
	x ^= x >> 15
	return x & 0x7fffffff


func _make_visual(e: SimEntity) -> Dictionary:
	var root := Node3D.new()
	var team := Palette.team(e.owner)
	var v := {"node": root, "type": e.type, "owner": e.owner}
	if e.is_unit():
		var body := MeshInstance3D.new()
		body.mesh = Meshes.unit_mesh(e.type, team)
		root.add_child(body)
		root.add_child(Meshes.team_disc(team, 0.3 if e.fn != "civil" else 0.25))
		var carry := MeshInstance3D.new()
		carry.mesh = Meshes.box(0.2, 0.18, 0.16)
		carry.position = Vector3(0, 0.5, -0.2)
		carry.visible = false
		body.add_child(carry)
		var ring := _ring(0, Vector2(0.85, 0.85))
		root.add_child(ring)
		v.merge({"kind": "unit", "body": body, "carry": carry, "ring": ring, "yaw": 0.0, "lunge": 0.0, "spawn": 0.0, "phase": randf() * TAU})
	else:
		var struct := MeshInstance3D.new()
		struct.mesh = Meshes.building_mesh(e.type, team)
		root.add_child(struct)
		var found := MeshInstance3D.new()
		found.mesh = Meshes.foundation_mesh(e.w, e.h)
		root.add_child(found)
		var ring := _ring(1, Vector2(e.w + 0.3, e.h + 0.3))
		root.add_child(ring)
		v.merge({"kind": "building", "struct": struct, "found": found, "ring": ring, "pop": 0.0})
	root.position = to_world(e.x, e.y)
	add_child(root)
	v["cur"] = root.position
	v["prev"] = root.position
	return v


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
				(v["node"] as Node3D).scale = Vector3(1, k, 1)
	_render_rally()
	_render_fx(delta)


func _render_unit(e: SimEntity, v: Dictionary, alpha: float, delta: float) -> void:
	var node: Node3D = v["node"]
	node.visible = e.inside < 0
	if not node.visible:
		v["prev"] = v["cur"]
		return
	var body: MeshInstance3D = v["body"]
	var prev: Vector3 = v["prev"]
	var cur: Vector3 = v["cur"]
	node.position = prev.lerp(cur, alpha)
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
	if moving:
		bob = absf(sin(_time * 11.0 + phase)) * 0.06
		tilt = sin(_time * 11.0 + phase) * 0.06
	elif e.anchored and (e.order == O.GATHER or e.order == O.BUILD):
		tilt = maxf(0.0, sin(_time * 6.0 + phase)) * 0.35
	v["lunge"] = maxf(0.0, float(v["lunge"]) - delta * 5.0)
	var lunge: float = v["lunge"]
	body.position = Vector3(0, bob, lunge * 0.22)
	body.rotation.x = tilt + lunge * 0.3
	v["spawn"] = maxf(0.0, float(v["spawn"]) - delta * 3.0)
	body.scale = Vector3.ONE * (1.0 - float(v["spawn"]) * 0.7)
	var carry: MeshInstance3D = v["carry"]
	carry.visible = e.carry > 0
	if carry.visible:
		carry.material_override = Meshes.mat(Palette.RES.get(e.carry_res, Color.WHITE))
	_update_ring(e, v)


func _render_building(e: SimEntity, v: Dictionary, delta: float) -> void:
	var struct: MeshInstance3D = v["struct"]
	var found: MeshInstance3D = v["found"]
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
