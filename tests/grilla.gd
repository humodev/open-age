extends SceneTree
## Grilla estable (src/game/ui/grilla.gd): en las seis civilizaciones, cada edificio del aldeano
## tiene su casilla en la tabla de data/interfaz.json, ninguna se pisa, la misma función cae en la
## misma tecla, y los dos hitos de cada edad van en Z (economía) y X (militar) con íconos distintos.
##   godot --headless --path . -s tests/grilla.gd

const CIVS := ["tawantinsuyu", "mapuches", "guaranies", "etiopia", "palmares", "ayutthaya"]


func _init() -> void:
	var fallas: Array[String] = []
	var base := SimData.load_default()
	var donde := {} # tipo común -> "menu:casilla" visto en la primera civ
	var labels := ["Q", "W", "E", "R", "A", "S", "D", "F", "Z", "X", "C", "V"]
	var back := Grilla.fija("volver", 11)
	for civ in CIVS:
		var dd := base.for_civ(civ)
		var linea := "%-13s" % civ
		for menu in [Grilla.ECONOMIA, Grilla.MILITAR]:
			var table: Dictionary = Grilla.cfg().get(menu, {})
			var slots := Grilla.edificios(dd, menu)
			var parts: Array[String] = []
			for s in range(12):
				if slots.has(s):
					var t: String = slots[s]
					parts.append("%s=%s" % [labels[s], t])
					if not table.has(t):
						fallas.append("%s: '%s' no está en la tabla de %s" % [civ, t, menu])
					if s == back:
						fallas.append("%s: '%s' ocupa la casilla de Volver" % [civ, t])
					var k := "%s:%d" % [menu, s]
					if t in ["casa", "granja", "deposito", "centro", "mercado", "cuartel", "torre", "empalizada", "puerta"]:
						if donde.has(t) and donde[t] != k:
							fallas.append("%s: '%s' cambia de lugar (%s, antes %s)" % [civ, t, k, donde[t]])
						donde[t] = k
			linea += "  %s[%s]" % [menu.substr(0, 3), " ".join(parts)]
		# Todo lo que construye el aldeano aparece en algún submenú (salvo los hitos).
		var vistos := {}
		for menu in [Grilla.ECONOMIA, Grilla.MILITAR]:
			for t in Grilla.edificios(dd, menu).values():
				vistos[t] = true
		for t: String in dd.unidades["aldeano"].get("construye", []):
			if dd.edificios.has(t) and not dd.is_hito(t) and not vistos.has(t):
				fallas.append("%s: '%s' no aparece en la grilla" % [civ, t])
		# Hitos: Z economía, X militar, íconos distintos.
		for age in range(1, dd.hitos.size() + 1):
			var h := Grilla.hitos(dd, age)
			var z: String = h.get(Grilla.fija("hito_economia", 8), "")
			var x: String = h.get(Grilla.fija("hito_militar", 9), "")
			if z == "" or x == "":
				fallas.append("%s edad %d: faltan hitos en Z o X (%s)" % [civ, age, h])
				continue
			var iz := Glyphs.resolve(dd.edificios[z], z)
			var ix := Glyphs.resolve(dd.edificios[x], x)
			if iz == ix:
				fallas.append("%s edad %d: los dos hitos tienen el mismo ícono (%s)" % [civ, age, iz])
			linea += "  e%d[Z=%s X=%s]" % [age, z, x]
		print(linea)
	for f in fallas:
		print("FALLO ", f)
	print("GRILLA: ", "OK" if fallas.is_empty() else "FALLO (%d)" % fallas.size())
	quit(0 if fallas.is_empty() else 1)
