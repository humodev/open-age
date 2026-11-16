extends SceneTree
## Escala (proceso/22-testers/ronda-4/03-escala-veterano.md y proceso/24-tras-la-segunda-ronda/
## 4p-escala.md): mide lo que se dibuja, en unidades de mundo (una casilla = 1), de unidades,
## edificios (edad I), árboles, arbustos, rocas y animales, para cada civ, y lo pasa a
## "personas" (cuántas veces el alto del aldeano).
##
## Dos altos por edificio: el total (con estandartes y mástiles) y el del cuerpo (los vértices
## del medio de la planta, sin los estandartes de las esquinas), que es lo que se lee como edificio.
##
## Uso: godot --headless --path . -s tools/escala.gd [-- --civs=guaranies,tawantinsuyu]
## Al final imprime la tabla de proporciones (casa, cuartel, centro, hito, torre y árbol en
## personas), en Markdown.

var civs := ["tawantinsuyu", "mapuches", "guaranies", "etiopia", "palmares", "ayutthaya"]
var resumen := {} # civ -> {casa, cuartel, centro, hito: [..], torre}


func _init() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--civs="):
			civs = a.substr(7).split(",")
	call_deferred("_run")


func _box(n: Node) -> AABB:
	return WorldView._aabb(n, Transform3D.IDENTITY)


## Alto del cuerpo: el punto más alto de la superficie bajo una grilla de 9×9 rayos verticales
## en el 64 % central de la huella (los estandartes y los mástiles van en las esquinas, a más
## de 0,38 del lado, y son finos: no los toca ningún rayo).
func _body_top(n: Node3D, w: float, d: float) -> float:
	var tris := PackedVector3Array()
	_collect_tris(n, Transform3D.IDENTITY, tris)
	var top := 0.0
	for i in 9:
		for j in 9:
			var x := (float(i) / 8.0 - 0.5) * w * 0.64
			var z := (float(j) / 8.0 - 0.5) * d * 0.64
			for t in range(0, tris.size(), 3):
				var a := tris[t]
				var b := tris[t + 1]
				var c := tris[t + 2]
				if maxf(a.y, maxf(b.y, c.y)) <= top:
					continue
				if x < minf(a.x, minf(b.x, c.x)) or x > maxf(a.x, maxf(b.x, c.x)) or z < minf(a.z, minf(b.z, c.z)) or z > maxf(a.z, maxf(b.z, c.z)):
					continue
				var hit: Variant = Geometry3D.ray_intersects_triangle(Vector3(x, 100.0, z), Vector3.DOWN, a, b, c)
				if hit == null:
					hit = Geometry3D.ray_intersects_triangle(Vector3(x, 100.0, z), Vector3.DOWN, a, c, b)
				if hit != null:
					top = maxf(top, (hit as Vector3).y)
	return top


func _collect_tris(n: Node, xf: Transform3D, out: PackedVector3Array) -> void:
	var t := xf
	if n is Node3D:
		t = xf * (n as Node3D).transform
	if n is MeshInstance3D and (n as MeshInstance3D).mesh != null and (n as MeshInstance3D).visible:
		var m := (n as MeshInstance3D).mesh
		for s in m.get_surface_count():
			var arr := m.surface_get_arrays(s)
			var vs: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
			var idx: PackedInt32Array = arr[Mesh.ARRAY_INDEX] if arr[Mesh.ARRAY_INDEX] != null else PackedInt32Array()
			if idx.is_empty():
				for v in vs:
					out.append(t * v)
			else:
				for k in idx:
					out.append(t * vs[k])
	for c in n.get_children():
		_collect_tris(c, t, out)


func _run() -> void:
	var reglas: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/reglas.json"))
	var ev: Dictionary = reglas.get("escala_visual", {})
	var unit_k := float(ev.get("unidad_pct", 100)) / 100.0
	var tree_k := float(ev.get("arbol_alto_pct", 100)) / 100.0
	print("== escala_visual: %s" % JSON.stringify(ev))
	# Naturaleza (una sola vez)
	print("== Naturaleza (alto × ancho en casillas; la casilla = 1 unidad de mundo)")
	var tree_h := []
	for v in 5:
		var m := Meshes.tree_mesh(v)
		if m != null:
			var b := m.get_aabb()
			# Factor medio de la instancia: 0,82–1,27 (media 1,045), por arbol_alto_pct.
			tree_h.append(b.size.y * 1.045 * tree_k)
			print("   árbol variante %d: malla %.2f · copa %.2f · medio en el mapa %.2f" % [v, b.size.y, maxf(b.size.x, b.size.z), b.size.y * 1.045 * tree_k])
	var bm := Meshes.bush_mesh()
	print("   arbusto: alto %.2f · ancho %.2f" % [bm.get_aabb().size.y, maxf(bm.get_aabb().size.x, bm.get_aabb().size.z)])
	var person0 := WorldView.FIGURE_H * unit_k
	print("== Animales (alto en personas, con la persona de %.2f casillas)" % person0)
	for sp: String in Animales.data().get("especies", {}):
		var am := Animales.mesh(sp)
		var ab := am.get_aabb()
		print("   %-14s alto %.2f (×%.2f persona) · largo %.2f (×%.2f)" % [sp, ab.size.y * unit_k, ab.size.y / WorldView.FIGURE_H, maxf(ab.size.x, ab.size.z) * unit_k, maxf(ab.size.x, ab.size.z) / WorldView.FIGURE_H])
	for civ in civs:
		var s := Sim.new(21, 2, null, {"civs": [civ, "mapuches" if civ != "mapuches" else "etiopia"], "terreno": "llano"})
		var dd := s.dp(0)
		var b0: Vector2i = s.bases[0]
		# Un edificio de cada tipo, terminado, en un lugar libre
		var placed := {}
		var cur := Vector2i(b0.x + 8, b0.y - 20)
		for type in dd.edificios:
			var d: Dictionary = dd.edificios[type]
			if d.get("linea", false) or d.get("puerta", false) or type in ["ingenio", "sitio_sagrado", "deposito", "hito_economia", "hito_guerra"]:
				continue
			var done := false
			for r in range(0, 40):
				for dy in range(-r, r + 1):
					for dx in range(-r, r + 1):
						if done or (absi(dx) != r and absi(dy) != r):
							continue
						var t := cur + Vector2i(dx, dy)
						if s.map.is_free_rect(t.x - 1, t.y - 1, int(d["tam"][0]) + 2, int(d["tam"][1]) + 2):
							var e := s.spawn_building(type, 0, t.x, t.y, true)
							placed[type] = e
							done = true
			cur.x += 7
			if cur.x > b0.x + 50:
				cur = Vector2i(b0.x + 8, cur.y + 8)
		for t in ["aldeano", "guerrero", "hondero", "lancero", "jinete", "explorador", "rebano"]:
			if dd.unidades.has(t):
				s.spawn_unit(t, 0, (b0.x + 3) * 1000, (b0.y - 3) * 1000)
		var view := WorldView.new()
		root.add_child(view)
		view.setup(s, 0)
		print("== %s" % civ)
		var person := 0.0
		var rows := []
		for e in s.actives:
			if not view.visuals.has(e.id) or e.owner != 0:
				continue
			var v: Dictionary = view.visuals[e.id]
			if v.get("kind") == "unit":
				var bb := _box(v["body"])
				var h := bb.size.y
				if e.type == "aldeano" and person == 0.0:
					person = h
				rows.append([e.type, "unidad", h, maxf(bb.size.x, bb.size.z), "-", e.def.get("nombre", e.type), e.def.get("velocidad", 0), 0.0])
			elif v.get("kind") == "building" and v.has("struct"):
				var sb := _box(v["struct"])
				rows.append([e.type, "edificio", sb.end.y, maxf(sb.size.x, sb.size.z), "%dx%d" % [e.w, e.h], e.def.get("nombre", e.type), 0, _body_top(v["struct"], e.w, e.h)])
		var seen := {}
		var res := {"hito": []}
		for r in rows:
			if seen.has(r[0]):
				continue
			seen[r[0]] = true
			var ratio: float = float(r[2]) / person if person > 0 else 0.0
			if r[1] == "unidad":
				print("   %-16s %-26s alto %.2f (×%.2f aldeano) · ancho %.2f · velocidad %.2f casillas/s" % [r[0], r[5], r[2], ratio, r[3], float(r[6]) / 1000.0 * float(s.data.reglas.get("velocidad_pct", 100)) / 100.0])
			else:
				var body: float = r[7]
				var rb: float = body / person if person > 0 else 0.0
				print("   %-16s %-26s cuerpo %.2f (×%.1f aldeano) · total %.2f (×%.1f) · planta %.2f · huella %s" % [r[0], r[5], body, rb, r[2], ratio, r[3], r[4]])
				var type: String = r[0]
				if type == dd.civ.get("inicio_edificio", "centro"):
					res["centro"] = rb
					res["centro_ancho"] = float(r[3]) / person
				elif type == "casa" or type == dd.civ.get("casa", ""):
					res["casa"] = rb
				elif type == "cuartel":
					res["cuartel"] = rb
				elif type == "torre":
					res["torre"] = rb
				else:
					for row in dd.hitos:
						if (row as Array).has(type):
							res["hito"].append(rb)
		resumen[civ] = res
		# Animales y recursos sueltos de esta civ
		for e in s.entities:
			if e.alive and e.is_resource() and e.type in ["roca", "riqueza", "venado"] and not seen.has(e.type) and view.visuals.has(e.id):
				seen[e.type] = true
				var rb := _box(view.visuals[e.id]["node"])
				print("   %-16s alto %.2f (×%.2f aldeano) · ancho %.2f" % [e.type, rb.size.y, rb.size.y / person if person > 0 else 0.0, maxf(rb.size.x, rb.size.z)])
		view.queue_free()
		await process_frame
	# Tabla de proporciones, en personas (alto del cuerpo / alto del aldeano).
	var tm := 0.0
	for h in tree_h:
		tm += h
	tm /= maxf(1.0, tree_h.size())
	print("\n== Proporciones en personas (cuerpo del edificio / alto del aldeano)")
	print("| Pueblo | Casa | Cuartel | Centro | Ancho del centro | Hitos (mín–máx, mediana) | Torre |")
	print("|---|---|---|---|---|---|---|")
	for civ in resumen:
		var r: Dictionary = resumen[civ]
		var hs: Array = r["hito"]
		hs.sort()
		var hito := "-" if hs.is_empty() else "%.1f–%.1f, %.1f" % [hs[0], hs[-1], hs[hs.size() / 2]]
		print("| %s | %s | %s | %s | %s | %s | %s |" % [civ, _f(r, "casa"), _f(r, "cuartel"), _f(r, "centro"), _f(r, "centro_ancho"), hito, _f(r, "torre")])
	print("Árbol medio: %.2f casillas = %.1f personas (persona de %.2f casillas)" % [tm, tm / person0, person0])
	quit()


func _f(r: Dictionary, k: String) -> String:
	return "%.1f" % float(r[k]) if r.has(k) else "-"
