class_name Textos
extends RefCounted
## Texto para el jugador (proceso/28, ronda 7 de jugadores): las notas de trabajo de los
## historiadores («[verificar…]», «La grafía, a verificar.») quedan en data/ y en los documentos,
## pero no llegan a la pantalla. La interfaz limpia su copia al cargar: la tabla de la partida
## (main.gd, _build_scene: la de la simulación ya armada), la del menú y la de las campañas. Solo cambia texto que
## nombra «verificar»; ninguna clave ni número, así que la simulación no se entera (mismo hash).
## tests/verificar.gd revisa que no quede ninguna en lo que se muestra.

static var _re_nota: RegEx
static var _re_frase: RegEx
static var _re_clausula: RegEx


static func _compilar() -> void:
	if _re_nota != null:
		return
	# «, [verificar el pasaje]» o « [verificar]»: la nota y la coma que la separaba.
	_re_nota = RegEx.create_from_string("(?i),?\\s*\\[verificar[^\\]]*\\]")
	# «La grafía, a verificar.» o «Lo sostiene Furlong: a verificar el detalle.»: la frase entera.
	_re_frase = RegEx.create_from_string("(?i)(?:^|(?<=[.!?]))\\s*[^.;\\n]*\\ba verificar\\b[^.;\\n]*\\.")
	# «Documentado (las lanzas); a verificar la azagaya…»: la cláusula tras el punto y coma.
	_re_clausula = RegEx.create_from_string("(?i);\\s*a verificar\\b[^.;\\n]*")


## El texto sin las notas de verificación.
static func limpiar(s: String) -> String:
	if s.findn("verificar") < 0:
		return s
	_compilar()
	var t := _re_nota.sub(s, "", true)
	t = _re_frase.sub(t, "", true)
	t = _re_clausula.sub(t, "", true)
	return t.replace(" )", ")").replace("( ", "(").strip_edges()


## Limpia en el lugar todos los textos de un diccionario o una lista (y lo que tengan adentro).
static func limpiar_todo(v: Variant) -> void:
	if v is Dictionary:
		for k in v:
			if v[k] is String:
				v[k] = limpiar(v[k])
			else:
				limpiar_todo(v[k])
	elif v is Array:
		for i in (v as Array).size():
			if v[i] is String:
				v[i] = limpiar(v[i])
			else:
				limpiar_todo(v[i])
	elif v is SimData:
		var d: SimData = v
		for t in [d.reglas, d.unidades, d.edificios, d.recursos, d.edades, d.tecnologias, d.civ, d.modulos]:
			limpiar_todo(t)
		for k in d.civs:
			limpiar_todo(d.civs[k])


## La tabla de datos lista para mostrar: sin notas y con los niveles nombrados por la tropa.
static func datos(d: SimData) -> SimData:
	limpiar_todo(d)
	nombres_niveles(d)
	return d


## Ronda 7 (jugador nuevo): «Choque veterano» y «Línea veterana» se confundían. Cada nivel por
## línea dice la tropa del pueblo: «Lanceros veteranos», «Lanceros de élite»
## (data/interfaz.json → grilla.niveles). Solo el nombre que se muestra.
static func nombres_niveles(d: SimData) -> void:
	var tabla: Dictionary = Grilla.cfg().get("niveles", {})
	for k in d.civs:
		var dd: SimData = d.civs[k]
		var lineas: Dictionary = tabla.get(dd.clave, {})
		for tech in dd.tecnologias:
			var t: Dictionary = dd.tecnologias[tech]
			var par: Array = lineas.get(str(t.get("linea", "")), [])
			if par.size() < 2 or not t.has("nivel"):
				continue
			t["nombre"] = "%s %s" % [par[0], par[1]] if int(t["nivel"]) == 1 else "%s de élite" % par[0]
			# Para la casilla con la franja de lo que falta (un solo renglón): «Lanceros vet.».
			t["nombre_corto"] = "%s %s" % [par[2] if par.size() > 2 else par[0], tabla.get("_corto", ["vet.", "élite"])[mini(int(t["nivel"]), 2) - 1]]


## --- C-71 a --- Nombres por edad (docs/diseno/26, regla 5): una unidad o un edificio puede
## llevar `nombre_edad: {"<edad>": {"nombre": ..., "desc": ...}}` para cuando la historia cambia
## dentro de la partida (los bayingyi y la caballería kathe de Birmania, desde la IV). Solo texto:
## la simulación no lo lee. Vale la entrada de la edad más alta que el dueño ya alcanzó.
static func _por_edad(sim: Sim, owner: int, def: Dictionary) -> Dictionary:
	var ne: Dictionary = def.get("nombre_edad", {})
	if ne.is_empty() or sim == null or owner < 0 or owner >= sim.players.size():
		return {}
	var age := int(sim.players[owner].get("age", 1))
	var best := 0
	var out := {}
	for k: String in ne:
		if int(k) <= age and int(k) > best:
			best = int(k)
			out = ne[k]
	return out


static func nombre_de(sim: Sim, owner: int, def: Dictionary, fallback: String) -> String:
	return str(_por_edad(sim, owner, def).get("nombre", def.get("nombre", fallback)))


static func desc_de(sim: Sim, owner: int, def: Dictionary, fallback: String) -> String:
	return str(_por_edad(sim, owner, def).get("desc", fallback))
