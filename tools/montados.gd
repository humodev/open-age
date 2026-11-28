extends SceneTree
## Revisión de los montados y los animales animados (proceso/63-montados-y-animales).
##
##   godot --headless --path . -s tools/montados.gd -- --modo=paso
##       Paso contra velocidad: de cada modelo, a qué velocidad pide ir cada clip de andar (el
##       casco apoyado no patina) y, para cada unidad montada y cada rebaño, cuánto hay que
##       acelerar o frenar la animación a su velocidad de la simulación; si se pasa de los topes
##       (juego.vel_min_pct y vel_max_pct), cuánto patina.
##   godot --path . -s tools/montados.gd -- --modo=batalla --civ=mapuches --rival=mapuches --terreno=llano --nofog --mute [--zoom=12] [--dir=...]
##       Los montados del pueblo, en dos equipos, chocan; capturas.
##   godot --path . -s tools/montados.gd -- --modo=fps --civ=ayutthaya --terreno=llano --nofog --mute [--caballos=60 --elefantes=10] [--montados=0]
##       60 jinetes y 10 elefantes en pantalla (la mitad marcha, la otra mitad pelea con vida de
##       sobra): cuadros por segundo.

var args := {}
var dir := "screenshots/montados"
var main: Node


func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		var kv := a.trim_prefix("--").split("=", true, 1)
		args[kv[0]] = kv[1] if kv.size() > 1 else "1"
	dir = args.get("dir", dir)
	DirAccess.make_dir_recursive_absolute(dir)
	if args.get("modo", "paso") == "paso":
		_paso.call_deferred()
		return
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	RenderingServer.viewport_set_measure_render_time(root.get_viewport_rid(), true)
	main = load("res://src/game/main.tscn").instantiate()
	root.add_child(main)
	_partida.call_deferred()


# ---------------------------------------------------------------- paso contra velocidad

func _paso() -> void:
	var cq := CuadrupedoAnimado.cfg()
	var reglas: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/reglas.json"))
	var vpct := float(reglas.get("velocidad_pct", 100)) / 100.0
	var k := 1.25 * float(reglas.get("escala_visual", {}).get("unidad_pct", 100)) / 100.0 # alto de la persona
	print("persona: %.3f casillas · velocidad_pct %d" % [k, int(vpct * 100)])
	# Unidades montadas: velocidad de cada una (data/unidades.json y data/civs).
	var vel := {}
	var uj: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/unidades.json"))
	for t: String in uj:
		if uj[t] is Dictionary and uj[t].has("velocidad"):
			vel[t] = int(uj[t]["velocidad"])
	for f in DirAccess.get_files_at("res://data/civs"):
		if not f.ends_with(".json"):
			continue
		var c: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/civs/" + f))
		for grupo in ["unidades", "unidades_nuevas"]:
			for t: String in c.get(grupo, {}):
				var d: Variant = c[grupo][t]
				if d is Dictionary and d.has("velocidad"):
					vel[f.get_basename() + ":" + t] = int(d["velocidad"])
					if not vel.has(t):
						vel[t] = int(d["velocidad"])
	var peor := 0.0
	var lineas := []
	for key: String in CuadrupedoAnimado.montados().get("unidades", {}):
		var m: Dictionary = CuadrupedoAnimado.montados()["unidades"][key]
		var md := CuadrupedoAnimado._modelo(str(m["montura"]))
		var v := float(vel.get(key, vel.get(key.split(":")[-1], 0))) / 1000.0 * vpct
		var alto := float(md["alto_persona"]) * k
		peor = maxf(peor, _linea(lineas, key, md, alto, v))
	for sp: String in Animales.data().get("especies", {}):
		var md := CuadrupedoAnimado.especie(sp)
		if md.is_empty():
			continue
		var alto := Animales.mesh(sp).get_aabb().size.y * float(reglas.get("escala_visual", {}).get("unidad_pct", 100)) / 100.0
		peor = maxf(peor, _linea(lineas, "rebaño " + sp, md, alto, float(vel.get("rebano", 900)) / 1000.0 * vpct))
	for l in lineas:
		print(l)
	print("PASO peor patinada %.1f %%" % (peor * 100.0))
	quit(0)


## Una línea del informe: el clip que toca a esa velocidad, el factor de la animación y lo que
## patina (0 si el factor queda dentro de los topes). Devuelve la patinada.
func _linea(out: Array, nombre: String, md: Dictionary, alto: float, v: float) -> float:
	var s := alto / float(md["h0"])
	var j: Dictionary = (md["tipo"] as Dictionary).get("juego", {})
	var an := "galope" if v > float(j.get("galope_desde", 1.8)) and (md["paso"] as Dictionary).has("galope") else "caminar"
	var vc := float(md["paso"].get(an, 1.0)) * s # casillas por segundo del clip a ritmo 1
	var f := v / vc
	var lo := float(j.get("vel_min_pct", 60)) / 100.0
	var hi := float(j.get("vel_max_pct", 170)) / 100.0
	var fc := clampf(f, lo, hi)
	var patina := absf(1.0 - fc / f) if f > 0.0 else 0.0
	out.append("%-28s alto %.2f · %.2f casillas/s · caminar %.2f/s galope %.2f/s · usa %-7s ritmo %.2f%s" % [nombre, alto, v,
		float(md["paso"].get("caminar", 0.0)) * s, float(md["paso"].get("galope", 0.0)) * s, an, f,
		"" if patina < 0.001 else " (tope %.2f: patina %.0f %%)" % [fc, patina * 100.0]])
	return patina


# ---------------------------------------------------------------- partida

func _frames(n: int) -> void:
	for i in n:
		await process_frame


func _shot(name: String) -> void:
	await _frames(3)
	var img := root.get_texture().get_image()
	img.save_png("%s/%s.png" % [dir, name])
	print("captura: %s/%s.png" % [dir, name])


func _game_secs(sim: Sim, s: float) -> void:
	var until: int = sim.tick + int(s * 1000.0 / sim.tick_ms)
	while sim.tick < until:
		await process_frame


func _partida() -> void:
	await _frames(5)
	main.cam.edge_pan = false
	var sim: Sim = main.sim
	sim.ais = []
	if args.get("modo") == "fps":
		await _fps(sim)
	else:
		await _batalla(sim)
	quit(0)


## Un campo abierto cerca del centro del mapa.
func _campo(sim: Sim, w: int, h: int) -> Vector2i:
	var c := sim.map.n / 2
	for r in range(0, sim.map.n / 2 - 14, 2):
		for d in [Vector2i(0, 0), Vector2i(r, 0), Vector2i(-r, 0), Vector2i(0, r), Vector2i(0, -r), Vector2i(r, r), Vector2i(-r, -r)]:
			var x0: int = c + d.x
			var y0: int = c + d.y
			var ok := true
			var malas := 0
			for ty in range(y0 - h, y0 + h + 1):
				for tx in range(x0 - w, x0 + w + 1):
					if tx < 0 or ty < 0 or tx >= sim.map.n or ty >= sim.map.n or sim.map.is_water(tx, ty):
						ok = false
						break
					if sim.map.occupied[ty * sim.map.n + tx] != -1:
						malas += 1
				if not ok:
					break
			if ok and malas <= 8:
				return Vector2i(x0, y0)
	return Vector2i(c, c)


## Los tipos montados (con línea en montados.unidades) de un jugador.
func _montados(sim: Sim, pid: int) -> Array:
	var out := []
	var civ := str(sim.players[pid].get("civ", ""))
	var uu: Dictionary = sim.dp(pid).unidades
	for k: String in uu:
		if not CuadrupedoAnimado.montado_de(civ, k, uu[k]).is_empty():
			out.append(k)
	out.sort()
	return out


func _mirar(p: Vector3, zoom: float) -> void:
	main.cam.look_at_point(p + Vector3(float(args.get("dx", "0")), 0, float(args.get("dz", "0"))))
	main.cam.zoom = zoom
	main.cam.set("_zoom_target", zoom)
	if args.has("pitch"):
		main.cam.pitch_deg = float(args["pitch"])


func _batalla(sim: Sim) -> void:
	for p in sim.players:
		p["age"] = int(args.get("edad", "3"))
	var c := _campo(sim, 10, 7)
	var ids := [[], []]
	for pid in 2:
		var tipos := _montados(sim, pid)
		var por := int(args.get("por_tipo", "4"))
		for kk in tipos.size():
			var n := 2 if sim.dp(pid).unidades[tipos[kk]].get("elefante", false) else por
			for j in n:
				var x := c.x + (-4 - kk * 2 if pid == 0 else 4 + kk * 2)
				var y := c.y - n + j * 2
				var t := sim.map.nearest_free(x, y, 4, pid)
				var u := sim.spawn_unit(tipos[kk], pid, t.x * 1000 + 500, t.y * 1000 + 500)
				u.hp_max *= 3
				u.hp = u.hp_max
				ids[pid].append(u.id)
		print("jugador %d (%s): %s" % [pid, sim.players[pid].get("civ", ""), str(tipos)])
	if ids[0].is_empty():
		print("SIN MONTADOS en ", sim.players[0].get("civ", ""))
		return
	if args.has("sin_hud"):
		(main.get_node("UI") as CanvasLayer).visible = false
	var zoom := float(args.get("zoom", "13"))
	await _game_secs(sim, 0.5)
	_mirar(Vector3(c.x + 0.5, 0, c.y + 0.5), zoom)
	await _shot("quietos_%s" % sim.players[0].get("civ", ""))
	for pid in 2:
		sim.push_command({"t": "move", "player": pid, "ids": ids[pid], "x": c.x * 1000 + 500, "y": c.y * 1000 + 500, "amove": true})
	var tag := "%s_%s" % [sim.players[0].get("civ", ""), sim.players[1].get("civ", "")]
	var last := 0.0
	for t in [float(args.get("t1", "1.4")), float(args.get("t2", "4.0")), float(args.get("t3", "9.0"))]:
		await _game_secs(sim, t - last)
		last = t
		_mirar(Vector3(c.x + 0.5, 0, c.y + 0.5), zoom)
		await _shot("batalla_%s_%04.1f" % [tag, t])


func _fps(sim: Sim) -> void:
	var c := _campo(sim, 14, 12)
	var caballo := ""
	var elefante := ""
	for pid in 1:
		for k in _montados(sim, pid):
			if sim.dp(pid).unidades[k].get("elefante", false):
				if elefante == "" or k == "chang_suek":
					elefante = k
			elif caballo == "" or k == "jinete":
				caballo = k
	if caballo == "":
		caballo = "jinete"
	var n_cab := int(args.get("caballos", "60"))
	var n_ele := int(args.get("elefantes", "10"))
	var march := []
	var fight := [[], []]
	for i in n_cab + n_ele:
		var tipo := caballo if i < n_cab else elefante
		if tipo == "":
			continue
		var pid := i % 2
		var j := i / 2
		var t := sim.map.nearest_free(c.x - 8 + (j % 8) * 2, c.y - 6 + (j / 8) * 2 + pid * 12, 12, pid)
		var u := sim.spawn_unit(tipo, pid, t.x * 1000 + 500, t.y * 1000 + 500)
		u.hp_max = 1000000
		u.hp = 1000000
		if i % 4 < 2:
			fight[pid].append(u.id)
		elif pid == 0:
			march.append(u.id)
		else:
			fight[pid].append(u.id)
	for pid in 2:
		sim.push_command({"t": "move", "player": pid, "ids": fight[pid], "x": c.x * 1000, "y": (c.y + 2) * 1000, "amove": true})
	var zoom := float(args.get("zoom", "40"))
	var go := true
	var times: Array[float] = []
	var view_ms: Array[float] = []
	for round in 6:
		_mirar(Vector3(c.x, 0, c.y), zoom)
		if not march.is_empty():
			sim.push_command({"t": "move", "player": 0, "ids": march, "x": (c.x + (10 if go else -10)) * 1000, "y": (c.y - 8) * 1000})
		go = not go
		var t1 := Time.get_ticks_usec()
		var f0 := Engine.get_process_frames()
		main.view.render_us = 0
		CuadrupedoAnimado.us_actualizar = 0
		var until: int = sim.tick + int(4.0 * 1000.0 / sim.tick_ms)
		while sim.tick < until:
			await process_frame
		var fr := Engine.get_process_frames() - f0
		var secs := (Time.get_ticks_usec() - t1) / 1000000.0
		if round >= 1:
			times.append(fr / secs)
			view_ms.append(main.view.render_us / 1000.0 / fr)
			print("  ronda %d: %.1f fps · vista %.2f ms · cuadrúpedos %.2f ms por cuadro" % [round, fr / secs, main.view.render_us / 1000.0 / fr, CuadrupedoAnimado.us_actualizar / 1000.0 / fr])
	var vis := 0
	var cuad := 0
	var cam := root.get_viewport().get_camera_3d()
	for v in main.view.visuals.values():
		if v["kind"] == "unit" and cam.is_position_in_frustum((v["node"] as Node3D).position):
			vis += 1
			if v.has("cuad"):
				cuad += 1
	await _shot("fps_%s" % ("montados" if CuadrupedoAnimado._on() else "antes"))
	times.sort()
	view_ms.sort()
	print("FPS montados=%s caballo=%s elefante=%s en pantalla=%d animados=%d mediana=%.1f min=%.1f max=%.1f vista_ms=%.2f" % [args.get("montados", "data"), caballo, elefante, vis, cuad, times[times.size() / 2], times[0], times[-1], view_ms[view_ms.size() / 2]])
