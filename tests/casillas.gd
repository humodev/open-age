extends SceneTree
## Casillas de la grilla de los edificios (jugador nuevo, ronda 4): en las seis civilizaciones y en
## cada edad, ningún edificio pone dos comandos en la misma casilla, y el aldeano y el explorador
## del centro quedan fijos en Q y W. Recorre todos los edificios del pueblo (los del aldeano, los
## hitos y los que no construye nadie, como el centro), terminados y con la cola vacía, con la
## grilla real (Controller.commands) y la misma búsqueda que usan el dibujo y la tecla
## (Controller.cmd_at).
##   godot --headless --path . -s tests/casillas.gd [-- --ver]

const CIVS := ["tawantinsuyu", "mapuches", "guaranies", "etiopia", "palmares", "ayutthaya"]


func _init() -> void:
	var ver := OS.get_cmdline_user_args().has("--ver")
	var fallas: Array[String] = []
	var revisados := 0
	for civ in CIVS:
		var s := Sim.new(7, 2, null, {"civs": [civ, "mapuches" if civ != "mapuches" else "guaranies"]})
		var dd: SimData = s.dp(0)
		var ctl := Controller.new()
		ctl.sim = s
		ctl.local = 0
		for age in range(1, dd.edades.size() + 1):
			s.players[0]["age"] = age
			for type: String in dd.edificios:
				var def: Dictionary = dd.edificios[type]
				if def.get("tam", []).is_empty():
					continue
				var b := s.spawn_building(type, 0, 4, 4, true)
				ctl.selection = [b.id] as Array[int]
				var cmds := ctl.commands()
				revisados += 1
				_revisar(cmds, "%s e%d %s" % [civ, age, type], fallas)
				# Si las investigaciones no entran, van a un submenú: también se revisa.
				var sub: Array = cmds.filter(func(c: Dictionary) -> bool: return c.get("menu", "") == Controller.INVESTIGAR)
				if not sub.is_empty():
					ctl.submenu = Controller.INVESTIGAR
					var inner := ctl.commands()
					_revisar(inner, "%s e%d %s/investigaciones" % [civ, age, type], fallas)
					if Controller.cmd_at(inner, 11).get("kind", "") != "back":
						fallas.append("%s e%d %s: el submenú de investigaciones no tiene Volver en V" % [civ, age, type])
					var n := inner.filter(func(c: Dictionary) -> bool: return c["kind"] == "research").size()
					if not String(sub[0]["name"]).contains("(%d)" % n):
						fallas.append("%s e%d %s: el submenú anuncia «%s» y muestra %d" % [civ, age, type, sub[0]["name"], n])
					if ver and age == 1:
						print("%s e%d %s/investigaciones %s" % [civ, age, type, " ".join(inner.map(func(c: Dictionary) -> String: return "%s=%s" % [Controller.SLOT_LABELS[int(c["slot"])], c["id"]]))])
					ctl.submenu = ""
				var line := "%s e%d %-16s" % [civ, age, type]
				for c in cmds:
					line += " %s=%s" % [Controller.SLOT_LABELS[int(c["slot"])] if int(c["slot"]) >= 0 and int(c["slot"]) < 12 else str(c["slot"]), c["id"]]
				for want in [["aldeano", 0], ["explorador", 1]]:
					if (def.get("produce", []) as Array).has(want[0]) and Controller.cmd_at(cmds, want[1]).get("id", "") != want[0]:
						fallas.append("%s e%d %s: en %s no está %s (está '%s')" % [civ, age, type, Controller.SLOT_LABELS[want[1]], want[0], Controller.cmd_at(cmds, want[1]).get("id", "")])
				if ver and age == 1:
					print(line)
		ctl.free()
	for f in fallas:
		print("FALLO ", f)
	print("CASILLAS: %d grillas revisadas, %s" % [revisados, "OK" if fallas.is_empty() else "FALLO (%d)" % fallas.size()])
	quit(0 if fallas.is_empty() else 1)


## Ninguna casilla con dos comandos y todas dentro de la grilla.
func _revisar(cmds: Array[Dictionary], donde: String, fallas: Array[String]) -> void:
	var seen := {}
	for c in cmds:
		var sl := int(c["slot"])
		if sl < 0 or sl > 11:
			fallas.append("%s: '%s' fuera de la grilla (%d)" % [donde, c["id"], sl])
		elif seen.has(sl):
			fallas.append("%s: '%s' y '%s' en la misma casilla %s" % [donde, seen[sl], c["id"], Controller.SLOT_LABELS[sl]])
		else:
			seen[sl] = c["id"]
