extends SceneTree
## Revisión de la gente animada (proceso/27-animaciones): aldeanos (paso 1) y soldados (paso 2).
##
##   godot --path . -s tools/aldeanos_animados.gd -- --modo=poses [--dir=screenshots/anim]
##       Vitrina: los seis pueblos en fila, cada uno en una acción, sin partida.
##   godot --path . -s tools/aldeanos_animados.gd -- --modo=trabajo --civ=guaranies --terreno=llano --nofog --mute [--mirar=madera|piedra|alimento|riqueza] [--seguir=S]
##       Partida: aldeanos talando, picando, cosechando y construyendo de cerca; captura y, con
##       --seguir, S segundos más (para grabar con --write-movie).
##   godot --path . -s tools/aldeanos_animados.gd -- --modo=fps --civ=guaranies --terreno=llano --nofog --mute [--animaciones=0]
##       200 aldeanos en pantalla (100 caminando, 100 trabajando): cuadros por segundo.
##       Con --soldados=200 --aldeanos=100: 100 soldados que marchan en formación de un lado a
##       otro, 100 que pelean (con vida de sobra, para que no se mueran) y los aldeanos. Con
##       --compartir=0, sin esqueletos compartidos.
##   godot --path . -s tools/aldeanos_animados.gd -- --modo=tropas [--civs=a,b] [--accion=golpe|quieto|caminar|golpeado|bloquear|morir] [--edad=1..4] [--t=0.5]
##       Vitrina de soldados: una fila por pueblo con cada tipo a pie, sin partida.
##   godot --path . -s tools/aldeanos_animados.gd -- --modo=batalla --civ=mapuches --rival=tawantinsuyu --terreno=llano --nofog --mute [--edad=3] [--zoom=10] [--seguir=S]
##       Batalla de cerca: los soldados a pie de los dos pueblos, en línea, chocan; capturas y,
##       con --seguir, S segundos más (para grabar con --write-movie).

var args := {}
var dir := "screenshots/anim"
var main: Node


func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		var kv := a.trim_prefix("--").split("=", true, 1)
		args[kv[0]] = kv[1] if kv.size() > 1 else "1"
	dir = args.get("dir", dir)
	DirAccess.make_dir_recursive_absolute(dir)
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	RenderingServer.viewport_set_measure_render_time(root.get_viewport_rid(), true)
	match args.get("modo", "poses"):
		"poses":
			_poses.call_deferred()
		"tropas":
			_tropas.call_deferred()
		_:
			main = load("res://src/game/main.tscn").instantiate()
			root.add_child(main)
			_partida.call_deferred()


func _frames(n: int) -> void:
	for i in n:
		await process_frame


func _shot(name: String) -> void:
	await _frames(3)
	var img := root.get_texture().get_image()
	img.save_png("%s/%s.png" % [dir, name])
	print("captura: %s/%s.png" % [dir, name])


# ---------------------------------------------------------------- Vitrina sin partida

func _poses() -> void:
	var w := Node3D.new()
	root.add_child(w)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-50, 150, 0)
	sun.shadow_enabled = true
	w.add_child(sun)
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR
	env.environment.background_color = Color(0.62, 0.7, 0.76)
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color(0.7, 0.72, 0.75)
	env.environment.ambient_light_energy = 0.8
	w.add_child(env)
	var floor := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(40, 40)
	floor.mesh = pm
	var fm := StandardMaterial3D.new()
	fm.albedo_color = Color(0.45, 0.52, 0.32)
	floor.material_override = fm
	w.add_child(floor)
	var cam := Camera3D.new()
	w.add_child(cam)
	cam.fov = 30
	var civs: Array = str(args.get("civs", "tawantinsuyu,mapuches,guaranies,etiopia,palmares,ayutthaya")).split(",")
	var acts: Array = str(args.get("acciones", "quieto,caminar,talar,picar,cosechar,construir,juntar,pegar,morir")).split(",")
	# --tiempos=0.1,0.3,…: una sola acción en varios momentos del ciclo (para revisar herramientas).
	var tiempos: Array = str(args.get("tiempos", "")).split(",", false)
	if not tiempos.is_empty():
		var one: String = acts[0]
		acts = []
		for x in tiempos:
			acts.append(one)
	var team := [Color("2f6fd6"), Color("d63a2f"), Color("e0b21c"), Color("3aa04a"), Color("8a4ad6"), Color("e07a1c")]
	var avs: Array = []
	for i in civs.size():
		var civ: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/civs/%s.json" % civs[i]))
		var st: Dictionary = civ.get("estilo", {})
		for j in acts.size():
			var av := AldeanoAnimado.crear(st, team[i], 1.0)
			var n: Node3D = av.node
			n.position = Vector3((j - acts.size() / 2.0) * 0.9, 0, -i * 1.2)
			n.rotation.y = 0.5
			w.add_child(n)
			avs.append([av, acts[j], st, team[i], float(tiempos[j]) if not tiempos.is_empty() else -1.0])
	cam.position = Vector3(0.5, 4.2, 7.5)
	cam.look_at(Vector3(0, 0.3, -3.0))
	var t := float(args.get("t", "0.55"))
	for a in avs:
		_pose(a[0], a[1], a[2], a[3], t if a[4] < 0.0 else a[4])
	if args.has("lado"):
		for a in avs:
			(a[0].node as Node3D).rotation.y = -PI / 2
	await _shot("poses")
	# De cerca, un pueblo por vez: el primero de la fila de cada acción.
	cam.fov = 22
	cam.position = Vector3(0.0, 1.6, 4.6)
	cam.look_at(Vector3(0, 0.45, 0))
	await _shot("poses_cerca")
	quit(0)


## Pone un aldeano de la vitrina en una acción, avanzado `t` segundos.
func _pose(av: AldeanoAnimado.Estado, act: String, st: Dictionary, team: Color, t: float) -> void:
	var acts: Dictionary = AldeanoAnimado.cfg().get("acciones", {})
	if not av.tropa:
		var tool: String = acts.get(act, {}).get("herramienta", "") if not args.has("herramienta") else str(args["herramienta"])
		av.mi.mesh = AldeanoAnimado.malla(st, team, tool, Palette.RES.get("madera", Color.WHITE) if act == "caminar" else Color(0, 0, 0, 0))
	AldeanoAnimado._propio(av)
	var ap: AnimationPlayer = av.ap
	var a: Dictionary = acts.get(act, {})
	var names: Array = a.get("anims", [a.get("anim", "Idle_A")])
	ap.play("+".join(PackedStringArray(names)))
	ap.advance(t * ap.current_animation_length if not act.begins_with("morir") else 2.0)


# ---------------------------------------------------------------- Vitrina de soldados

## Los tipos de soldado a pie de un pueblo, con su ficha (la común con lo del pueblo encima).
func _tipos_a_pie(civ: Dictionary) -> Array:
	var base: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/unidades.json"))
	var out := []
	var all: Dictionary = {}
	for k in base:
		if base[k] is Dictionary:
			all[k] = (base[k] as Dictionary).duplicate()
	for src in [civ.get("unidades", {}), civ.get("unidades_nuevas", {})]:
		for k in src:
			var d: Dictionary = all.get(src[k].get("reemplaza", k), {}).duplicate()
			d.merge(src[k], true)
			all[k] = d
	for k in all:
		if str(all[k].get("funcion", "civil")) != "civil" and AldeanoAnimado.usa(all[k], k):
			out.append([k, all[k]])
	return out


func _tropas() -> void:
	var w := _escena()
	var cam: Camera3D = w.get_meta("cam")
	var civs: Array = str(args.get("civs", "tawantinsuyu,mapuches,guaranies,etiopia,palmares,ayutthaya")).split(",")
	var act0: String = args.get("accion", "golpe")
	var edad := int(args.get("edad", "3"))
	var team := [Color("2f6fd6"), Color("d63a2f"), Color("e0b21c"), Color("3aa04a"), Color("8a4ad6"), Color("e07a1c")]
	var maxcol := 0
	for i in civs.size():
		var civ: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/civs/%s.json" % civs[i]))
		var st: Dictionary = civ.get("estilo", {})
		var tropa: Dictionary = CivMeshes.age_cfg(civs[i], str(st.get("forma", "")), edad).get("tropa", {})
		var tipos := _tipos_a_pie(civ)
		# --tipo=X --tiempos=0,0.2,…: un solo tipo en varios momentos del ciclo.
		var tiempos: Array = str(args.get("tiempos", "")).split(",", false)
		if args.has("tipo"):
			tipos = tipos.filter(func(x: Array) -> bool: return x[0] == args["tipo"])
			if not tiempos.is_empty() and not tipos.is_empty():
				var one: Array = tipos[0]
				tipos = []
				for x in tiempos:
					tipos.append(one)
		maxcol = maxi(maxcol, tipos.size())
		for j in tipos.size():
			var av := AldeanoAnimado.crear(st, team[i % team.size()], 1.0, civs[i], tipos[j][0], tipos[j][1], tropa)
			av.node.position = Vector3((j - 3.0) * 0.9, 0, -i * 1.2)
			av.node.rotation.y = float(args.get("giro", "0.5")) if not args.has("lado") else -PI / 2
			w.add_child(av.node)
			var act := act0
			match act0:
				"golpe":
					act = av.golpe_act
				"quieto":
					act = av.quieto_act
			_pose(av, act, st, team[i % team.size()], float(tiempos[j]) if j < tiempos.size() and args.has("tipo") else float(args.get("t", "0.5")))
			print("%s %s: %s %s impacto=%.2f" % [civs[i], tipos[j][0], av.eq, act, AldeanoAnimado._imp(av.golpe_act) / maxf(0.01, float(AldeanoAnimado._len.get(AldeanoAnimado._anim_of.get(av.golpe_act, ""), 1.0)))])
	cam.position = Vector3(0.5, 4.2, 7.5)
	cam.look_at(Vector3(0, 0.3, -3.0))
	await _shot("tropas_%s" % act0)
	cam.fov = 20
	cam.position = Vector3(0.0, 1.5, 4.2)
	cam.look_at(Vector3(0, 0.5, 0))
	await _shot("tropas_%s_cerca" % act0)
	quit(0)


func _escena() -> Node3D:
	var w := Node3D.new()
	root.add_child(w)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-50, 150, 0)
	sun.shadow_enabled = true
	w.add_child(sun)
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR
	env.environment.background_color = Color(0.62, 0.7, 0.76)
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color(0.7, 0.72, 0.75)
	env.environment.ambient_light_energy = 0.8
	w.add_child(env)
	var floor := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(40, 40)
	floor.mesh = pm
	var fm := StandardMaterial3D.new()
	fm.albedo_color = Color(0.45, 0.52, 0.32)
	floor.material_override = fm
	w.add_child(floor)
	var cam := Camera3D.new()
	w.add_child(cam)
	cam.fov = 30
	w.set_meta("cam", cam)
	return w


# ---------------------------------------------------------------- En partida

func _partida() -> void:
	await _frames(5)
	if args.has("max_por_cuadro"): # para medir: cuántas figuras con esqueleto propio por cuadro
		AldeanoAnimado.cfg()
		AldeanoAnimado.max_por_cuadro = int(args["max_por_cuadro"])
	main.cam.edge_pan = false # el mouse en el borde de la ventana no mueve la cámara
	var sim: Sim = main.sim
	var b: Vector2i = sim.bases[0]
	for k in sim.players[0]["res"]:
		sim.players[0]["res"][k] = 5000
	if args.get("modo") == "fps":
		await _fps(sim, b)
		quit(0)
		return
	if args.get("modo") == "batalla":
		await _batalla(sim)
		quit(0)
		return
	# Aldeanos a cada trabajo, cerca de la base.
	var vill: Array[int] = []
	for e in sim.actives:
		if e.owner == 0 and e.fn == "civil" and e.inside < 0:
			vill.append(e.id)
	for i in 8:
		var t := sim.map.nearest_free(b.x + 4 + i % 4, b.y + 4 + i / 4, 6, 0)
		vill.append(sim.spawn_unit("aldeano", 0, t.x * 1000 + 500, t.y * 1000 + 500).id)
	var groups := {"madera": vill.slice(0, 4), "piedra": vill.slice(4, 7), "riqueza": vill.slice(7, 9), "alimento": vill.slice(9, 11)}
	var spot := Vector2(b.x + 2, b.y + 2)
	for kind in groups:
		var r: SimEntity = sim.find_resource(0, kind, b.x * 1000, b.y * 1000, 40000)
		if r != null:
			# Cada uno a un recurso distinto cerca del primero (árboles vecinos), para que no se amontonen.
			var ids: Array = groups[kind]
			for n in ids.size():
				var rr: SimEntity = sim.find_resource(0, kind, r.x + (n % 2) * 2500 - 1200, r.y + (n / 2) * 2500 - 1200, 4000) if kind == "madera" else r
				sim.push_command({"t": "target", "player": 0, "ids": [ids[n]], "target": (rr if rr != null else r).id})
			if kind == "madera":
				spot = Vector2(r.x / 1000.0, r.y / 1000.0)
	# Una casa en obra con tres constructores.
	var bt := sim.map.nearest_free(b.x + 6, b.y - 4, 8, 0)
	var builders: Array = vill.slice(11, 14)
	sim.push_command({"t": "build", "player": 0, "ids": builders, "type": "casa", "tx": bt.x, "ty": bt.y})
	await _game_secs(sim, 14.0)
	var cam_at: String = args.get("mirar", "madera")
	var focus := spot
	if cam_at != "madera":
		var r2: SimEntity = sim.find_resource(0, cam_at, b.x * 1000, b.y * 1000, 40000)
		if r2 != null:
			focus = Vector2(r2.x / 1000.0, r2.y / 1000.0)
	main.cam.look_at_point(Vector3(focus.x, 0, focus.y))
	main.cam.zoom = float(args.get("zoom", "9"))
	main.cam.set("_zoom_target", main.cam.zoom)
	await _frames(6)
	var civ: String = args.get("civ", "x")
	await _shot("trabajo_%s_%s" % [civ, cam_at])
	# Video: correr con --write-movie video.avi --fixed-fps 30 y --seguir=S (segundos de juego
	# después de la captura); después se recorta con ffmpeg (proceso/27-animaciones/README.md).
	var seguir := float(args.get("seguir", "0"))
	if seguir > 0.0:
		print("video desde el cuadro ", Engine.get_frames_drawn())
		await _game_secs(sim, seguir)
	quit(0)


func _game_secs(sim: Sim, s: float) -> void:
	var until: int = sim.tick + int(s * 1000.0 / sim.tick_ms)
	while sim.tick < until:
		await process_frame


## Un campo abierto (casi sin árboles ni agua) cerca del centro del mapa.
func _campo(sim: Sim, w: int, h: int) -> Vector2i:
	var c := sim.map.n / 2
	for r in range(0, sim.map.n / 2 - 14, 2):
		for d in [Vector2i(0, 0), Vector2i(r, 0), Vector2i(-r, 0), Vector2i(0, r), Vector2i(0, -r), Vector2i(r, r), Vector2i(-r, -r), Vector2i(r, -r), Vector2i(-r, r)]:
			var x0: int = c + d.x
			var y0: int = c + d.y
			var malas := 0
			var ok := true
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


## Los tipos a pie animados de un jugador (con los propios del pueblo).
func _tipos_jugador(sim: Sim, pid: int) -> Array:
	var out := []
	var uu: Dictionary = sim.dp(pid).unidades
	for k in ["guerrero", "lancero", "hondero", "arcabucero"]:
		if uu.has(k) and AldeanoAnimado.usa(uu[k], k):
			out.append(k)
	for k in sim.dp(pid).civ.get("unidades_nuevas", {}):
		if uu.has(k) and AldeanoAnimado.usa(uu[k], k) and str(uu[k].get("funcion", "")) in ["choque", "linea", "distancia"]:
			out.append(k)
	return out


## Batalla de cerca entre los soldados a pie de los dos pueblos.
func _batalla(sim: Sim) -> void:
	var edad := int(args.get("edad", "3"))
	sim.ais = [] # sin IA: los dos bandos solo hacen lo que se les manda
	for p in sim.players:
		p["age"] = edad # solo para el equipo de la edad en la imagen
	var c := _campo(sim, 10, 6)
	var ids := [[], []]
	for pid in 2:
		var tipos := _tipos_jugador(sim, pid)
		# Cuerpo a cuerpo en las filas de adelante, los de tiro atrás; una fila por tipo.
		tipos.sort_custom(func(a: String, b: String) -> bool: return (str(sim.dp(pid).unidades[a].get("funcion", "")) == "distancia") < (str(sim.dp(pid).unidades[b].get("funcion", "")) == "distancia"))
		var por := int(args.get("por_tipo", "5"))
		for k in tipos.size():
			for j in por:
				var x := c.x + (-3 - k if pid == 0 else 3 + k)
				var y := c.y - por / 2 + j
				var t := sim.map.nearest_free(x, y, 4, pid)
				ids[pid].append(sim.spawn_unit(tipos[k], pid, t.x * 1000 + 500, t.y * 1000 + 500).id)
		print("jugador %d (%s): %s" % [pid, sim.players[pid].get("civ", ""), str(tipos)])
	if args.has("sin_hud"):
		(main.get_node("UI") as CanvasLayer).visible = false
	await _game_secs(sim, 1.0)
	_mirar(Vector3(c.x + 0.5, 0, c.y + 0.5))
	for pid in 2:
		sim.push_command({"t": "move", "player": pid, "ids": ids[pid], "x": c.x * 1000 + 500, "y": c.y * 1000 + 500, "amove": true})
	var tag := "%s_%s" % [sim.players[0].get("civ", ""), sim.players[1].get("civ", "")]
	if args.has("seguir"):
		print("video desde el cuadro ", Engine.get_frames_drawn())
		await _game_secs(sim, float(args["seguir"]))
		return
	for t in [2.5, 5.0, 8.0, 12.0]:
		await _game_secs(sim, t - _last_t)
		_last_t = t
		_mirar(Vector3(c.x + 0.5, 0, c.y + 0.5))
		await _shot("batalla_%s_%04.1f" % [tag, t])


var _last_t := 0.0


func _mirar(p: Vector3) -> void:
	main.cam.look_at_point(p + Vector3(float(args.get("dx", "0")), 0, float(args.get("dz", "0"))))
	main.cam.zoom = float(args.get("zoom", "11"))
	main.cam.set("_zoom_target", main.cam.zoom)
	if args.has("pitch"):
		main.cam.pitch_deg = float(args["pitch"])
	print("cámara en ", p)


## Medición: aldeanos (la mitad camina de un lado a otro y la otra mitad tala) y, con
## --soldados=N, N soldados: la mitad marcha en formación de un lado a otro y la otra mitad
## pelea en dos bandos (con vida de sobra, para que la cuenta no baje).
func _fps(sim: Sim, b: Vector2i) -> void:
	sim.ais = []
	var n_ald := int(args.get("aldeanos", "200"))
	var n_sol := int(args.get("soldados", "0"))
	var c := _campo(sim, 14, 12) if n_sol > 0 else b + Vector2i(10, 10)
	var walkers := []
	var workers := []
	var lado := 14 if n_ald > 120 else 10
	for i in n_ald:
		var t := sim.map.nearest_free(c.x - 13 + i % lado, c.y - 12 + i / lado, 10, 0) if n_sol > 0 else sim.map.nearest_free(c.x - 7 + i % 14, c.y - 7 + i / 14, 10, 0)
		var u := sim.spawn_unit("aldeano", 0, t.x * 1000 + 500, t.y * 1000 + 500)
		(walkers if i % 2 == 0 else workers).append(u.id)
	var tree: SimEntity = sim.find_resource(0, "madera", c.x * 1000, c.y * 1000, 40000)
	if tree != null:
		sim.push_command({"t": "target", "player": 0, "ids": workers, "target": tree.id})
	var march := []
	var fight := [[], []]
	var types := ["guerrero", "lancero", "hondero"]
	for i in n_sol / 2:
		var t := sim.map.nearest_free(c.x + 2 + i % 10, c.y - 12 + i / 10, 10, 0)
		march.append(sim.spawn_unit(types[i % 3], 0, t.x * 1000 + 500, t.y * 1000 + 500).id)
	for i in n_sol / 2:
		var pid := i % 2
		var j := i / 2
		var t := sim.map.nearest_free(c.x - 6 + (j % 10) + (0 if pid == 0 else 0), c.y + 3 + (j / 10) * 2 + pid, 10, pid)
		var u := sim.spawn_unit(types[j % 3], pid, t.x * 1000 + 500, t.y * 1000 + 500)
		u.hp_max = 1000000
		u.hp = 1000000
		fight[pid].append(u.id)
	for pid in 2:
		if not fight[pid].is_empty():
			sim.push_command({"t": "move", "player": pid, "ids": fight[pid], "x": (c.x - 1) * 1000, "y": (c.y + 6) * 1000, "amove": true})
	main.cam.look_at_point(Vector3(c.x, 0, c.y))
	main.cam.zoom = float(args.get("zoom", "34" if n_sol == 0 else "44"))
	main.cam.set("_zoom_target", main.cam.zoom)
	var go := true
	var times: Array[float] = []
	var view_ms: Array[float] = []
	var gpu_ms: Array[float] = []
	for round in 6:
		main.cam.look_at_point(Vector3(c.x, 0, c.y))
		main.cam.zoom = float(args.get("zoom", "34" if n_sol == 0 else "44"))
		main.cam.set("_zoom_target", main.cam.zoom)
		sim.push_command({"t": "move", "player": 0, "ids": walkers, "x": (c.x + (8 if go else -8) - (6 if n_sol > 0 else 0)) * 1000, "y": (c.y + (6 if go else -6) - (6 if n_sol > 0 else 0)) * 1000})
		if not march.is_empty():
			sim.push_command({"t": "move", "player": 0, "ids": march, "x": (c.x + (12 if go else 2)) * 1000, "y": (c.y + (-4 if go else -10)) * 1000})
		go = not go
		var t1 := Time.get_ticks_usec()
		var f0 := Engine.get_process_frames()
		main.view.render_us = 0
		main.view.base_linda.us = 0 # --- fluidez 7 ---
		AldeanoAnimado.us_actualizar = 0
		AldeanoAnimado.us_avance = 0
		AldeanoAnimado.us_coros = 0
		AldeanoAnimado.n_play = 0
		AldeanoAnimado.n_malla = 0
		var proc := 0.0
		var until: int = sim.tick + int(4.0 * 1000.0 / sim.tick_ms)
		while sim.tick < until:
			await process_frame
			proc += Performance.get_monitor(Performance.TIME_PROCESS)
		var fr := Engine.get_process_frames() - f0
		var secs := (Time.get_ticks_usec() - t1) / 1000000.0
		if round >= 1:
			times.append(fr / secs)
			view_ms.append(main.view.render_us / 1000.0 / fr)
			print("  ronda %d: %.1f fps · proceso %.2f ms · vista %.2f ms · actualizar %.2f ms (avance %.2f ms, compartidos %.2f ms) por cuadro" % [round, fr / secs, proc * 1000.0 / fr, main.view.render_us / 1000.0 / fr, AldeanoAnimado.us_actualizar / 1000.0 / fr, AldeanoAnimado.us_avance / 1000.0 / fr, AldeanoAnimado.us_coros / 1000.0 / fr])
			print("    base linda (tierra pisada, pilas, granjas) %.3f ms por cuadro" % (main.view.base_linda.us / 1000.0 / fr)) # --- fluidez 7 ---
			print("    play por cuadro %.1f · malla por cuadro %.1f · esqueletos propios %d · compartidos activos %d" % [AldeanoAnimado.n_play / float(fr), AldeanoAnimado.n_malla / float(fr), AldeanoAnimado.n_propios, AldeanoAnimado.n_coros_activos])
			gpu_ms.append(RenderingServer.viewport_get_measured_render_time_gpu(root.get_viewport_rid()))
	var vis := 0
	var anim := 0
	var cam := root.get_viewport().get_camera_3d()
	for v in main.view.visuals.values():
		if v["kind"] == "unit" and cam.is_position_in_frustum((v["node"] as Node3D).position):
			vis += 1
			if v.has("anim"):
				anim += 1
	await _shot("fps_%s_%s" % ["anim" if AldeanoAnimado.usa({"funcion": "civil"}) else "maqueta", "comp" if AldeanoAnimado.compartir else "sin"])
	times.sort()
	view_ms.sort()
	print("vista (WorldView.render) ms por cuadro: mediana=%.2f %s · GPU ms: %s" % [view_ms[view_ms.size() / 2], str(view_ms), str(gpu_ms)])
	anim = main.view._anim_total_prev
	var activos := {}
	for key: String in AldeanoAnimado._coros:
		var co: AldeanoAnimado.Coro = AldeanoAnimado._coros[key]
		if AldeanoAnimado._cuadro - co.usado <= AldeanoAnimado._retener:
			var g := key.split("|")[0]
			activos[g] = activos.get(g, 0) + 1
			if g == "Walking_A" and args.has("detalle"):
				print("   ", key, " rate=%.3f" % co.rate)
	print("esqueletos compartidos activos por animación: ", activos)
	print("FPS animaciones=%s compartir=%s unidades en pantalla=%d animadas=%d mediana=%.1f min=%.1f max=%.1f muestras=%s" % [args.get("animaciones", "data"), str(AldeanoAnimado.compartir), vis, anim, times[times.size() / 2], times[0], times[-1], str(times)])
