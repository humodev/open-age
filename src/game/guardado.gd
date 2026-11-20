class_name Guardado
extends RefCounted
## Guardar, cargar y repeticiones (proceso/30-fluidez/07, frente 6). La simulación es
## determinista y por comandos: una partida es «cómo se armó (semilla, opciones, IA o misión)
## + los comandos de los humanos hasta el tick T». Cargar es armarla igual y re-simular hasta
## T sin dibujo. Una repetición es lo mismo, guardado al terminar, y se mira desde un tick.
##
## --- instantaneas --- (proceso/37-red/02) Junto al .json va un .foto (binario, zstd) con la
## foto del estado en el tick del guardado (SimEstado) y, en las repeticiones, una foto cada
## `fotos_cada_min` minutos. Cargar arma la partida en el tick 0, vuelca la foto más cercana
## que no se pase y re-simula solo lo que falta. Sin .foto (guardados viejos), como antes.

const DIR_PARTIDAS := "user://partidas/"
const DIR_REPES := "user://repeticiones/"
const VERSION := 2 # 2: con .foto al lado
## Lo que no tiene que volver a pasar al cargar (capturas, pruebas, la carga misma).
const ARGS_FUERA := ["autotest", "shot", "shot-at", "panel", "select", "cam", "abrir", "ayuda", "grilla", "cargar", "replay", "desde", "velocidad", "salir-a", "perf", "contar-avisos", "menu"]

static var _cfg := {}


## data/interfaz.json → guardado.
static func cfg() -> Dictionary:
	if _cfg.is_empty():
		var all: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/interfaz.json"))
		_cfg = all.get("guardado", {})
	return _cfg


## Los argumentos de la partida sin lo que es de la prueba o de la carga.
static func args_limpios(args: Dictionary) -> Dictionary:
	var a := args.duplicate(true)
	for k in ARGS_FUERA:
		a.erase(k)
	return a


## El guardado: la meta de la partida, el tick, los comandos hasta ahí y el hash del estado
## (para comprobar al cargar que se llegó al mismo lugar).
static func datos(meta: Dictionary, sim: Sim) -> Dictionary:
	var d := meta.duplicate(true)
	d["version"] = VERSION
	d["tick"] = sim.tick
	d["hash"] = sim.state_hash()
	d["ms"] = sim.tick * sim.tick_ms
	d["comandos"] = sim.recording.duplicate(true)
	# --- instantaneas --- la foto de este tick (la periódica si ya se sacó) y las periódicas
	var fotos: Dictionary = sim.get_meta("fotos", {})
	d["foto"] = fotos[sim.tick] if fotos.has(sim.tick) else SimEstado.tomar(sim)
	if not fotos.is_empty():
		d["fotos"] = fotos.duplicate()
	var civs: Array = []
	for p in sim.players:
		civs.append(str(p["civ"]))
	d["civs"] = civs
	d["terreno"] = sim.terrain
	return d


static func escribir(path: String, d: Dictionary) -> bool:
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	# --- instantaneas --- las fotos van al .foto; el .json queda chico (la lista lo lee entero)
	var j := d.duplicate()
	for k in ["foto", "fotos", "_ruta"]:
		j.erase(k)
	if d.has("foto"):
		var fotos: Dictionary = d.get("fotos", {})
		j["fotos_ticks"] = fotos.keys()
		var fb := FileAccess.open(ruta_foto(path), FileAccess.WRITE)
		if fb == null:
			push_error("guardado: no se pudo escribir %s" % ruta_foto(path))
			return false
		fb.store_buffer(var_to_bytes({"tick": int(d["tick"]), "foto": d["foto"], "fotos": fotos}))
		fb.close()
	elif FileAccess.file_exists(ruta_foto(path)):
		DirAccess.remove_absolute(ruta_foto(path))
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		push_error("guardado: no se pudo escribir %s" % path)
		return false
	f.store_string(JSON.stringify(j))
	f.close()
	return true


static func leer(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var v: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not (v is Dictionary and (v as Dictionary).has("comandos")):
		return {}
	(v as Dictionary)["_ruta"] = path # --- instantaneas --- para encontrar el .foto
	return v


# --- instantaneas ---
static func ruta_foto(path: String) -> String:
	return path.get_basename() + ".foto"


## Borra un guardado con su .foto.
static func borrar(path: String) -> void:
	DirAccess.remove_absolute(path)
	if FileAccess.file_exists(ruta_foto(path)):
		DirAccess.remove_absolute(ruta_foto(path))


## Las fotos de un guardado: {tick: bytes} (la del tick del guardado y las periódicas).
## Vienen en `d` si se acaba de armar en memoria, o del .foto al lado del .json.
static func fotos_de(d: Dictionary) -> Dictionary:
	var out := {}
	if d.has("foto"):
		out = (d.get("fotos", {}) as Dictionary).duplicate()
		out[int(d["tick"])] = d["foto"]
		return out
	var ruta := ruta_foto(str(d.get("_ruta", "")))
	if d.has("_ruta") and FileAccess.file_exists(ruta):
		var v: Variant = bytes_to_var(FileAccess.get_file_as_bytes(ruta))
		if v is Dictionary and int((v as Dictionary).get("tick", -1)) == int(d.get("tick", -2)):
			out = ((v as Dictionary).get("fotos", {}) as Dictionary).duplicate()
			out[int(v["tick"])] = v["foto"]
	return out


## Foto periódica para saltar en la repetición: pasados `fotos_cada_min` minutos de juego
## desde la última, se guarda una en la partida (meta "fotos"). La toma main.gd entre dos
## pasos, una vez por cuadro, antes del autoguardado (que con el mismo intervalo la reusa).
static func foto_periodica(sim: Sim) -> void:
	var cada := int(cfg().get("fotos_cada_min", 5)) * 60000 / maxi(1, sim.tick_ms)
	if cada <= 0 or sim.tick < cada:
		return
	var fotos: Dictionary = sim.get_meta("fotos", {})
	var ultima := 0
	for t: int in fotos:
		ultima = maxi(ultima, t)
	if sim.tick - ultima >= cada:
		fotos[sim.tick] = SimEstado.tomar(sim)
		sim.set_meta("fotos", fotos)
# --- fin instantaneas ---


## Arma la simulación de un guardado o una repetición en el tick 0, con los comandos
## programados y ya grabados (si se vuelve a guardar, siguen ahí).
## --- instantaneas --- con `hasta` > 0, vuelca la foto más cercana a `hasta` que no se pase
## (la simulación queda en ese tick; falta re-simular de ahí a `hasta` con avanzar()).
static func armar(d: Dictionary, hasta := -1) -> Sim:
	var s := _armar0(d)
	if hasta <= 0:
		return s
	var fotos := fotos_de(d)
	var mejor := -1
	for t: int in fotos:
		if t <= hasta and t > mejor:
			mejor = t
	if mejor <= 0:
		return s
	if not SimEstado.cargar(s, fotos[mejor]):
		push_warning("guardado: la foto del tick %d no sirve; se re-simula desde el principio" % mejor)
		return _armar0(d)
	# La foto trae lo grabado hasta su tick; lo grabado después se vuelve a programar.
	var cmds: Array = Sim.intify(d["comandos"])
	var resto := cmds.slice(s.recording.size())
	s.recording = cmds.duplicate(true)
	s.schedule(resto)
	# Las fotos siguen con la partida (si se vuelve a guardar, no se pierden).
	var guardar := {}
	for t: int in fotos:
		if t <= s.tick:
			guardar[t] = fotos[t]
	s.set_meta("fotos", guardar)
	return s


static func _armar0(d: Dictionary) -> Sim:
	var s: Sim
	if d.has("campana"):
		var camp: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/campanas/%s.json" % d["campana"]))
		s = SimScenario.create(camp["misiones"][int(d.get("mision", 0))], camp["civ"])
	else:
		var ropts: Dictionary = Sim.intify(d["opciones"])
		s = Sim.new(int(d["semilla"]), (ropts.get("civs", [0, 0]) as Array).size(), null, ropts)
		s.ais = []
		for pid in d.get("ias", []):
			var c: Dictionary = (d.get("ia_cfg", {}) as Dictionary).get(str(int(pid)), {})
			var ai := SimAI.new(s, int(pid), c.get("dificultad", d.get("dificultad", "normal")))
			ai.personality = c.get("estilo", d.get("estilo", "normal"))
			s.ais.append(ai)
	var cmds: Array = Sim.intify(d["comandos"])
	s.recording = cmds.duplicate(true)
	s.schedule(cmds)
	return s


## Re-simula hasta `hasta` o hasta gastar `ms` milisegundos (-1: sin tope). Devuelve si llegó.
static func avanzar(s: Sim, hasta: int, ms: int = -1) -> bool:
	var t0 := Time.get_ticks_msec()
	while s.tick < hasta:
		s.step()
		if ms >= 0 and Time.get_ticks_msec() - t0 >= ms:
			break
	return s.tick >= hasta


## Lo que identifica la partida dentro del guardado (sin comandos ni estado).
static func meta_de(d: Dictionary) -> Dictionary:
	var m := d.duplicate(true)
	for k in ["comandos", "tick", "hash", "ms", "version", "civs", "terreno", "foto", "fotos", "fotos_ticks", "_ruta"]:
		m.erase(k)
	return m


## Archivos de una carpeta, del más nuevo al más viejo: [[ruta, datos], …] (sin los comandos).
static func lista(dir: String) -> Array:
	var out: Array = []
	if not DirAccess.dir_exists_absolute(dir):
		return out
	var files := Array(DirAccess.get_files_at(dir)).filter(func(f: String) -> bool: return f.ends_with(".json"))
	for f: String in files:
		var path := dir + f
		var d := leer(path)
		if d.is_empty():
			continue
		d.erase("comandos")
		d["_mtime"] = FileAccess.get_modified_time(path)
		out.append([path, d])
	out.sort_custom(func(a: Array, b: Array) -> bool: return int(a[1]["_mtime"]) > int(b[1]["_mtime"]))
	return out


## Deja los `n` más nuevos que empiezan con `prefijo` y borra los demás.
static func podar(dir: String, prefijo: String, n: int) -> void:
	var l := lista(dir).filter(func(it: Array) -> bool: return (it[0] as String).get_file().begins_with(prefijo))
	for i in range(n, l.size()):
		borrar(l[i][0])


## Una línea para la lista: «2026-11-19 21:40 · Autoguardado · guaranies contra mapuches · llano · 12:30».
static func describir(path: String, d: Dictionary) -> String:
	var ms := int(d.get("ms", 0))
	var quien := " contra ".join(d.get("civs", []))
	if d.has("campana"):
		quien = "Campaña %s, misión %d" % [d["campana"], int(d.get("mision", 0)) + 1]
	var nombre := path.get_file()
	var tipo := "Autoguardado · " if nombre.begins_with("auto") else ("Al salir · " if nombre.begins_with("salida") else "")
	var fecha := Time.get_datetime_string_from_unix_time(int(d.get("_mtime", 0))).replace("T", " ").left(16)
	return "%s · %s%s · %s · %d:%02d" % [fecha, tipo, quien, d.get("terreno", ""), ms / 60000, (ms / 1000) % 60]


## Diálogo con la lista de partidas o repeticiones: elegir llama a `al_elegir(ruta)`.
## Se cuelga de `padre` y se cierra solo con «Volver» o al elegir.
static func dialogo(padre: Node, titulo: String, dir: String, al_elegir: Callable) -> Control:
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.55)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.add_child(center)
	var pc := PanelContainer.new()
	var sb := Hud.panel_box(10)
	sb.set_content_margin_all(24)
	pc.add_theme_stylebox_override("panel", sb)
	center.add_child(pc)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 10)
	pc.add_child(vb)
	var tl := Label.new()
	tl.text = titulo
	tl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	if Hud.font_b != null:
		tl.add_theme_font_override("font", Hud.font_b)
	tl.add_theme_font_size_override("font_size", Hud.ts(28))
	vb.add_child(tl)
	var sc := ScrollContainer.new()
	sc.custom_minimum_size = Vector2(640, 360)
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	vb.add_child(sc)
	var items := VBoxContainer.new()
	items.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sc.add_child(items)
	var l := lista(dir)
	if l.is_empty():
		var e := Label.new()
		e.text = "Todavía no hay nada guardado."
		e.add_theme_color_override("font_color", Palette.UI_DIM)
		items.add_child(e)
	for it: Array in l:
		var path: String = it[0]
		var row := HBoxContainer.new()
		var b := Button.new()
		b.text = describir(path, it[1])
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.pressed.connect(func() -> void:
			dim.queue_free()
			al_elegir.call(path))
		row.add_child(b)
		var x := Button.new()
		x.text = "Borrar"
		x.tooltip_text = "Borra este archivo"
		x.pressed.connect(func() -> void:
			borrar(path)
			row.queue_free())
		row.add_child(x)
		items.add_child(row)
	var back := Button.new()
	back.text = "Volver"
	back.pressed.connect(dim.queue_free)
	vb.add_child(back)
	padre.add_child(dim)
	return dim
