extends SceneTree
## Íconos de la grilla (proceso/28): en las seis civilizaciones y en cada edad, ninguna grilla de
## construir, entrenar o investigar repite un ícono en dos casillas, y ningún comando de esos cae en
## el glifo de reserva (el círculo de Glyphs.draw). Con `--ver`, el inventario: qué ícono usa cada
## edificio, unidad e investigación, y cuáles se comparten entre comandos distintos.
##   godot --headless --path . -s tests/iconos.gd [-- --ver]

const CIVS := ["tawantinsuyu", "mapuches", "guaranies", "etiopia", "palmares", "ayutthaya"]
const KINDS := ["build", "train", "research"]


func _init() -> void:
	var ver := OS.get_cmdline_user_args().has("--ver")
	var fallas: Array[String] = []
	var uso := {} # ícono -> {id: true}
	var grillas := 0
	for civ in CIVS:
		var s := Sim.new(7, 2, null, {"civs": [civ, "mapuches" if civ != "mapuches" else "guaranies"]})
		var dd: SimData = s.dp(0)
		var ctl := Controller.new()
		ctl.sim = s
		ctl.local = 0
		for age in range(1, dd.edades.size() + 1):
			s.players[0]["age"] = age
			var listas: Array = []
			# El aldeano: raíz y los dos submenús.
			var ald := s.spawn_unit("aldeano", 0, 20, 20)
			ctl.selection = [ald.id] as Array[int]
			for m in [Grilla.RAIZ, Grilla.ECONOMIA, Grilla.MILITAR]:
				ctl.submenu = m
				listas.append(["%s e%d aldeano/%s" % [civ, age, m if m != "" else "raiz"], ctl.commands()])
			ctl.submenu = ""
			for type: String in dd.edificios:
				if dd.edificios[type].get("tam", []).is_empty():
					continue
				var b := s.spawn_building(type, 0, 4, 4, true)
				ctl.selection = [b.id] as Array[int]
				var cmds := ctl.commands()
				listas.append(["%s e%d %s" % [civ, age, type], cmds])
				for menu in [Controller.INVESTIGAR, Controller.HERRERIA]: # --- ronda 7 --- también la herrería
					if cmds.any(func(c: Dictionary) -> bool: return c.get("menu", "") == menu):
						ctl.submenu = menu
						listas.append(["%s e%d %s/%s" % [civ, age, type, menu], ctl.commands()])
						ctl.submenu = ""
			for l: Array in listas:
				grillas += 1
				var vistos := {}
				for c: Dictionary in l[1]:
					if not KINDS.has(c["kind"]):
						continue
					var ic := String(c["icon"])
					if not uso.has(ic):
						uso[ic] = {}
					uso[ic][String(c["id"])] = true
					if not Iconos.conocido(ic):
						fallas.append("%s: '%s' usa el glifo de reserva ('%s')" % [l[0], c["id"], ic])
					if vistos.has(ic) and vistos[ic] != c["id"]:
						fallas.append("%s: '%s' y '%s' comparten el ícono '%s'" % [l[0], vistos[ic], c["id"], ic])
					vistos[ic] = c["id"]
					if int(c.get("edad", 0)) <= 0 and not (c["kind"] == "build" and s.dp(0).is_hito(c["id"])):
						fallas.append("%s: '%s' no dice a qué edad pertenece" % [l[0], c["id"]])
		ctl.free()
	if ver:
		var keys := uso.keys()
		keys.sort()
		for ic in keys:
			var ids: Array = (uso[ic] as Dictionary).keys()
			print("%s%-28s %s" % ["* " if ids.size() > 1 else "  ", ic, ", ".join(ids)])
	_paleta_edades(fallas)
	var unicas := {}
	for f in fallas:
		unicas[f.substr(f.find(" ", f.find(" ") + 1) + 1)] = f
	for f in unicas.values():
		print("FALLO ", f)
	print("ICONOS: %d grillas, %d íconos distintos, %s" % [grillas, uso.size(), "OK" if fallas.is_empty() else "FALLO (%d)" % unicas.size()])
	quit(0 if fallas.is_empty() else 1)


## Paleta de las edades (data/iconos.json → edades): cada edad más luminosa que la anterior (se
## ordenan también en grises), ΔE ≥ 20 entre vecinas en las cuatro visiones de tests/test_paleta.gd,
## lejos del ámbar de «falta» y del rojo de «bloquea», y el texto a 4,5:1 sobre la casilla.
func _paleta_edades(fallas: Array[String]) -> void:
	var tp := preload("res://tests/test_paleta.gd")
	var fondo: Color = tp.FONDO
	var cols: Array[Color] = []
	for a in range(1, 5):
		cols.append(Iconos.color_edad(a))
		var k: float = tp.contraste(Iconos.texto_edad(a), fondo)
		if k < 4.5:
			fallas.append("edad %d: el texto %s a %.1f:1 sobre la casilla (mínimo 4,5)" % [a, Iconos.texto_edad(a).to_html(false), k])
		for otro in ["falta", "bloquea"]:
			for v in tp.VISIONES:
				var d: float = tp.delta_e(cols[-1], Iconos.color_estado(otro, Color.BLACK), v)
				if d < 20.0:
					fallas.append("edad %d y «%s» a ΔE %.1f en %s" % [a, otro, d, v])
	for i in range(1, cols.size()):
		if tp.luminancia(cols[i]) <= tp.luminancia(cols[i - 1]) * 1.3:
			fallas.append("edad %d no es bastante más luminosa que la %d (%.2f y %.2f)" % [i + 1, i, tp.luminancia(cols[i]), tp.luminancia(cols[i - 1])])
		for v in tp.VISIONES:
			var d: float = tp.delta_e(cols[i], cols[i - 1], v)
			if d < 20.0:
				fallas.append("edades %d y %d a ΔE %.1f en %s" % [i, i + 1, d, v])
	print("EDADES: luminancia %s" % " · ".join(cols.map(func(c: Color) -> String: return "%.2f" % tp.luminancia(c))))


## Al salir se sueltan las partidas creadas (ciclos de referencias; proceso/24, paso 6e).
func _finalize() -> void:
	Sim.soltar_todas()
