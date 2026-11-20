extends SceneTree
## Lecciones de la Guía y consejos de aprendizaje (proceso/36-aprendizaje), sin pantalla:
##   - cada lección del orden existe y tiene título, qué es, cuándo conviene y consejo;
##   - los marcadores ({reglas:…}, {casillas:…}, {min:…}, {edad:…}) se resuelven todos;
##   - cada consejo nombra una lección que existe;
##   - las entidades que más se eligen tienen su «¿Cómo se usa?» (centro, cuartel, mercado,
##     sitio, muralla, maravilla, catapulta, comerciante, aldeano).
## Sale con código 1 si algo falla.

const GUIA := preload("res://src/game/ui/registro_guia.gd")


func _init() -> void:
	var ok := true
	var d: Dictionary = GUIA.data()
	var reglas: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/reglas.json"))
	var lecs: Dictionary = d.get("lecciones", {})
	for id in d.get("orden", []):
		var lec: Dictionary = lecs.get(id, {})
		if lec.is_empty():
			print("FALLA: la lección %s del orden no existe" % id)
			ok = false
			continue
		for campo in ["titulo", "que", "cuando", "consejo"]:
			var t := GUIA.texto(String(lec.get(campo, "")), reglas)
			if t == "" or t.contains("{"):
				print("FALLA: %s.%s vacío o con un marcador sin resolver: %s" % [id, campo, t])
				ok = false
		print("%-12s %s · %d letras" % [id, lec["titulo"], (String(lec["que"]) + String(lec["cuando"]) + String(lec["consejo"])).length()])
	for k in d.get("consejos", {}):
		if String(k).begins_with("_"):
			continue
		var c: Dictionary = d["consejos"][k]
		var t := GUIA.texto(String(c.get("texto", "")), reglas)
		if t == "" or t.contains("{"):
			print("FALLA: consejo %s vacío o con un marcador sin resolver" % k)
			ok = false
		if c.has("leccion") and not lecs.has(c["leccion"]):
			print("FALLA: el consejo %s nombra la lección %s, que no existe" % [k, c["leccion"]])
			ok = false
	# «¿Cómo se usa?» en una partida de verdad: guaraníes (0, sin muralla de piedra) y Etiopía (1).
	var s := Sim.new(11, 2, null, {"civs": ["guaranies", "etiopia"], "terreno": "llano"})
	var casos := [[0, "centro", "repeticion", true], [0, "cuartel", "herreria", true], [0, "centro", "herreria", false],
		[0, "mercado", "mercado", true], [0, "sitio_sagrado", "sitios", true], [0, "maravilla", "maravilla", true],
		[0, "catapulta", "asedio_area", true], [0, "comerciante", "comercio", true], [0, "aldeano", "mercado", true],
		[0, "aldeano", "muralla", false], [1, "aldeano", "muralla", true], [1, "muralla", "muralla", true]]
	for c in casos:
		var e := SimEntity.new()
		e.type = c[1]
		e.owner = c[0]
		var dd := s.dp(c[0])
		if dd.edificios.has(e.type):
			e.def = dd.edificios[e.type]
			e.cat = SimEntity.Cat.BUILDING
		elif dd.unidades.has(e.type):
			e.def = dd.unidades[e.type]
			e.cat = SimEntity.Cat.UNIT
			e.fn = String(e.def.get("funcion", e.type))
		else:
			print("FALLA: %s no está en el pueblo %d" % [e.type, c[0]])
			ok = false
			continue
		var got: Array = GUIA.lecciones_de(s, e)
		print("¿Cómo se usa? %d %-14s → %s" % [c[0], e.type, ", ".join(got)])
		if got.has(c[2]) != c[3]:
			print("FALLA: %s %s la lección %s" % [e.type, "no ofrece" if c[3] else "no debería ofrecer", c[2]])
			ok = false
	# --- ronda 9 --- El índice: solo las del pueblo, por edad.
	for pid in [0, 1]:
		var ids: Array = GUIA.indice(s, pid)
		var eds := []
		for id in ids:
			eds.append(int(lecs[id].get("edad", 1)))
		print("Índice %d: %s" % [pid, ", ".join(ids)])
		var sorted_eds := eds.duplicate()
		sorted_eds.sort()
		if eds != sorted_eds:
			print("FALLA: el índice %d no va por edad: %s" % [pid, str(eds)])
			ok = false
		if ids.has("muralla") != (pid == 1):
			print("FALLA: la muralla %s en el índice del pueblo %d" % ["falta" if pid == 1 else "aparece", pid])
			ok = false
	# --- ronda 9 --- La G abre la Guía: la puerta del muro va en otra tecla y la lección la nombra.
	var tp := Teclas.tecla("puerta_muro")
	if tp == 0 or tp == Teclas.tecla("guia"):
		print("FALLA: la puerta del muro no tiene tecla propia (choca con la Guía)")
		ok = false
	var mur := GUIA.texto(String(lecs["muralla"]["consejo"]), reglas)
	if not mur.contains(Teclas.texto("puerta_muro") + " pone una puerta") or mur.contains(Teclas.texto("guia") + " pone"):
		print("FALLA: la lección de muralla no nombra la tecla de la puerta: %s" % mur)
		ok = false
	for c in Teclas.choques():
		for a in Teclas.choques()[c]:
			if a in ["puerta_muro", "como_se_usa"]:
				print("FALLA: la tecla de %s choca con %s" % [a, str(Teclas.choques()[c])])
				ok = false
	print("OK" if ok else "FALLA")
	quit(0 if ok else 1)


func _finalize() -> void:
	Sim.soltar_todas()
