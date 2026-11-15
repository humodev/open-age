extends SceneTree
## Informe de telemetría (proceso/20-telemetria): lee los .jsonl que dejan las partidas
## (user://telemetria/) o las pruebas (--telemetria=carpeta) y escribe un informe en
## Markdown más un mapa de calor por partida, sobre el mapa regenerado desde su semilla.
##
## Uso: godot --headless --path . -s tools/telemetria.gd -- --entrada=carpeta|archivo [--salida=carpeta] [--mapas=0]
##   Sin --entrada lee user://telemetria/. --mapas=0 no dibuja los mapas de calor.

const COLORS := {
	"trabada": Color(1.0, 0.15, 0.1),
	"sin_camino": Color(1.0, 0.6, 0.0),
	"ocioso": Color(1.0, 1.0, 0.2),
	"ia_sin_lugar": Color(0.9, 0.2, 0.9),
	"ia_sin_ruta": Color(0.6, 0.3, 1.0),
}
const CELL := 8 # casillas por celda para agrupar los lugares problemáticos


func _init() -> void:
	var src := "user://telemetria"
	var out := "user://telemetria/informe"
	var maps := true
	for a in OS.get_cmdline_user_args():
		var kv := a.trim_prefix("--").split("=")
		match kv[0]:
			"entrada":
				src = kv[1]
			"salida":
				out = kv[1]
			"mapas":
				maps = kv[1] != "0"
	var files: Array[String] = []
	if DirAccess.dir_exists_absolute(src):
		for f in DirAccess.get_files_at(src):
			if f.ends_with(".jsonl"):
				files.append(src.path_join(f))
	elif FileAccess.file_exists(src):
		files.append(src)
	files.sort()
	if files.is_empty():
		print("Sin archivos de telemetría en ", src)
		quit()
		return
	DirAccess.make_dir_recursive_absolute(out)
	var totals := {}
	var by_civ := {} # civ -> tipo -> n
	var msgs := {} # mensaje de rechazo -> n
	var no_site := {} # civ:edificio -> n
	var stuck := {} # tipo de unidad:orden -> n
	var slow := [] # ms de los ticks lentos
	var errors := {} # lugar · mensaje -> veces (SCRIPT ERROR del juego)
	var trips := {} # civ -> recurso -> [viajes, suma de casillas, máxima]
	var rows: Array[String] = []
	for path in files:
		var lines := FileAccess.get_file_as_string(path).split("\n", false)
		if lines.is_empty():
			continue
		var head: Dictionary = JSON.parse_string(lines[0])
		var evs: Array = []
		for i in range(1, lines.size()):
			evs.append(JSON.parse_string(lines[i]))
		var civs: Array = head.get("civs", [])
		var hv: Dictionary = head.get("viajes", {})
		for k: String in hv:
			var parts := k.split(":")
			var tc: String = civs[int(parts[0])] if int(parts[0]) < civs.size() else "-"
			var tv: Array = hv[k]
			var acc: Array = (trips.get_or_add(tc, {}) as Dictionary).get_or_add(parts[1], [0, 0, 0])
			acc[0] += int(tv[0])
			acc[1] += int(tv[1])
			acc[2] = maxi(acc[2], int(tv[2]))
		var cells := {}
		var local := {}
		for ev in evs:
			var tipo: String = ev[1]
			var pid := int(ev[2])
			var det: Dictionary = ev[5]
			totals[tipo] = int(totals.get(tipo, 0)) + 1
			local[tipo] = int(local.get(tipo, 0)) + 1
			var civ: String = civs[pid] if pid >= 0 and pid < civs.size() else "-"
			var bc: Dictionary = by_civ.get_or_add(civ, {})
			bc[tipo] = int(bc.get(tipo, 0)) + 1
			match tipo:
				"rechazo":
					var m := "%s · %s · %s%s" % [civ, det.get("msg", ""), det.get("orden", "?"), " (IA)" if det.get("ia", false) else ""]
					msgs[m] = int(msgs.get(m, 0)) + 1
				"ia_sin_lugar":
					var k := "%s · %s" % [civ, det.get("tipo", "")]
					no_site[k] = int(no_site.get(k, 0)) + 1
				"trabada":
					var k2 := "%s (orden %s)" % [det.get("tipo", ""), _order_name(int(det.get("orden", -1)))]
					stuck[k2] = int(stuck.get(k2, 0)) + 1
				"tick_lento":
					slow.append(int(det.get("ms", 0)))
				"error_script":
					var ke := "%s · %s" % [det.get("lugar", "?"), det.get("msg", "")]
					errors[ke] = int(errors.get(ke, 0)) + 1
			if int(ev[3]) >= 0 and tipo in ["trabada", "sin_camino", "ocioso"]:
				var key := Vector2i(int(ev[3]) / CELL, int(ev[4]) / CELL)
				cells[key] = int(cells.get(key, 0)) + 1
		var hot := cells.keys()
		hot.sort_custom(func(a: Vector2i, b: Vector2i) -> bool: return cells[a] > cells[b])
		var hot_txt := []
		for c in hot.slice(0, 3):
			hot_txt.append("(%d, %d): %d" % [c.x * CELL + CELL / 2, c.y * CELL + CELL / 2, cells[c]])
		var name := path.get_file().get_basename()
		rows.append("| %s | %s | %s | %d:%02d | %s | %s |" % [name, head.get("terreno", "?"), ", ".join(civs), int(head.get("ticks", 0)) / 600, (int(head.get("ticks", 0)) / 10) % 60, _short(local), "; ".join(hot_txt)])
		if maps:
			_heatmap(head, evs, out.path_join(name + ".png"))
	var md := PackedStringArray()
	md.append("# Informe de telemetría")
	md.append("")
	md.append("%d partidas leídas de `%s`." % [files.size(), src])
	md.append("")
	md.append("## Totales por tipo")
	md.append("")
	md.append("| Tipo | Sucesos | Por partida |")
	md.append("|---|---|---|")
	for t in _sorted(totals):
		md.append("| %s | %d | %.1f |" % [t, totals[t], float(totals[t]) / files.size()])
	md.append("")
	md.append("## Por civ")
	md.append("")
	md.append("| Civ | Trabadas | Sin camino | Ociosos | Rechazos | IA sin lugar | IA sin ruta |")
	md.append("|---|---|---|---|---|---|---|")
	for c in _sorted_keys(by_civ):
		var bc: Dictionary = by_civ[c]
		md.append("| %s | %d | %d | %d | %d | %d | %d |" % [c, bc.get("trabada", 0), bc.get("sin_camino", 0), bc.get("ocioso", 0), bc.get("rechazo", 0), bc.get("ia_sin_lugar", 0), bc.get("ia_sin_ruta", 0)])
	md.append("")
	if not trips.is_empty():
		md.append("## Viajes al depósito")
		md.append("")
		md.append("Casillas del recurso al depósito más cercano cuando el aldeano se llena (media y máxima). Viajes largos: faltan almacenes.")
		md.append("")
		md.append("| Civ | Alimento | Madera | Riqueza | Piedra |")
		md.append("|---|---|---|---|---|")
		for c in _sorted_keys(trips):
			var cells_t := []
			for kind in ["alimento", "madera", "riqueza", "piedra"]:
				var tv: Array = trips[c].get(kind, [0, 0, 0])
				cells_t.append("-" if tv[0] == 0 else "%d (máx %d)" % [tv[1] / tv[0], tv[2]])
			md.append("| %s | %s |" % [c, " | ".join(cells_t)])
		md.append("")
	_top(md, "Órdenes rechazadas más frecuentes", msgs)
	_top(md, "Edificios que la IA no pudo ubicar", no_site)
	_top(md, "Unidades que se rinden (tipo y orden)", stuck)
	_top(md, "Errores de script del juego", errors)
	if not slow.is_empty():
		slow.sort()
		md.append("## Ticks lentos")
		md.append("")
		md.append("%d ticks por encima del presupuesto; mediana %d ms, peor %d ms." % [slow.size(), slow[slow.size() / 2], slow[slow.size() - 1]])
		md.append("")
	md.append("## Partidas")
	md.append("")
	md.append("Lugares con más problemas: celdas de %d casillas, por trabadas, caminos imposibles y ociosos." % CELL)
	md.append("")
	md.append("| Partida | Terreno | Civs | Duración | Sucesos | Lugares con más problemas |")
	md.append("|---|---|---|---|---|---|")
	md.append_array(rows)
	var f := FileAccess.open(out.path_join("informe.md"), FileAccess.WRITE)
	f.store_string("\n".join(md) + "\n")
	print("Informe: ", ProjectSettings.globalize_path(out.path_join("informe.md")))
	for t in _sorted(totals):
		print("  %-14s %d" % [t, totals[t]])
	quit()


func _order_name(o: int) -> String:
	return ["ocioso", "mover", "atacar moviendo", "atacar", "recolectar", "volver", "construir", "refugiarse"][o] if o >= 0 and o < 8 else "?"


func _short(d: Dictionary) -> String:
	var parts := []
	for k in _sorted(d):
		parts.append("%s %d" % [k, d[k]])
	return ", ".join(parts)


func _sorted(d: Dictionary) -> Array:
	var ks := d.keys()
	ks.sort_custom(func(a, b) -> bool: return int(d[a]) > int(d[b]))
	return ks


func _sorted_keys(d: Dictionary) -> Array:
	var ks := d.keys()
	ks.sort()
	return ks


func _top(md: PackedStringArray, title: String, d: Dictionary) -> void:
	if d.is_empty():
		return
	md.append("## " + title)
	md.append("")
	md.append("| Qué | Veces |")
	md.append("|---|---|")
	for k in _sorted(d).slice(0, 15):
		md.append("| %s | %d |" % [k, d[k]])
	md.append("")


## Mapa regenerado desde la semilla (la generación es determinista) con los sucesos encima.
func _heatmap(head: Dictionary, evs: Array, path: String) -> void:
	var opts := {"civs": head.get("civs", []), "terreno": head.get("terreno", "")}
	if not (head.get("equipos", []) as Array).is_empty():
		opts["equipos"] = head["equipos"]
	var s := Sim.new(int(head.get("semilla", 0)), int(head.get("jugadores", 2)), null, opts)
	var n := s.map.n
	if n != int(head.get("mapa", n)):
		return # el generador cambió desde que se jugó: el mapa ya no es el mismo
	var img := Image.create(n, n, false, Image.FORMAT_RGB8)
	for y in n:
		for x in n:
			var i := y * n + x
			var c := Color(0.36, 0.45, 0.3).darkened(0.08 * s.map.height[i])
			if s.map.water[i] == 1:
				c = Color(0.15, 0.25, 0.45)
			elif s.map.water[i] == 2:
				c = Color(0.35, 0.5, 0.6)
			elif s.map.rock[i] != 0:
				c = Color(0.3, 0.28, 0.27)
			elif s.map.occupant(x, y) >= 0:
				c = Color(0.2, 0.32, 0.18)
			img.set_pixel(x, y, c.darkened(0.25))
	for b in s.bases:
		for dy in range(0, 5):
			for dx in range(0, 5):
				if s.map.in_bounds(b.x + dx, b.y + dy):
					img.set_pixel(b.x + dx, b.y + dy, Color(0.9, 0.9, 0.9))
	for ev in evs:
		var col: Color = COLORS.get(ev[1], Color(0, 0, 0, 0))
		if col.a == 0 or int(ev[3]) < 0:
			continue
		var x := int(ev[3])
		var y := int(ev[4])
		for dy in range(-1, 2):
			for dx in range(-1, 2):
				if s.map.in_bounds(x + dx, y + dy):
					img.set_pixel(x + dx, y + dy, img.get_pixel(x + dx, y + dy).lerp(col, 0.55))
	img.resize(n * 3, n * 3, Image.INTERPOLATE_NEAREST)
	img.save_png(path)
