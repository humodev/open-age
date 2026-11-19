class_name Teclas
extends RefCounted
## --- veterano ronda 4 --- Teclas reasignables (proceso/22-testers/ronda-4, veterano, punto 1).
##
## Cada acción tiene una sola tecla (sin modificadores: Mayús, Ctrl y Alt cambian lo que hace
## la acción, no cuál es). Las de fábrica, los nombres y los perfiles salen de
## data/interfaz.json → "teclas"; lo que elige el jugador se guarda en user://opciones.cfg,
## sección [teclas] (Opciones.guardar). El controlador, el HUD y los paneles preguntan con
## `es(code, "accion")` o `accion(code)` en vez de comparar con KEY_… fijos.

const RUTA := "res://data/interfaz.json"

static var _cfg: Dictionary = {}
## acción -> keycode físico (0 = sin tecla).
static var mapa: Dictionary = {}
## Inverso de `mapa`: keycode -> acción (la primera si hay choques).
static var _por_tecla: Dictionary = {}
## Grupos de control exclusivos (asignar a un grupo saca de los otros, como en AoE4).
static var grupos_exclusivos := false
## --- fluidez 5 --- Números de daño sobre los golpes fuertes (MundoCapa). El perfil «aoe4» los apaga.
static var numeros_danio := true


static func cfg() -> Dictionary:
	if _cfg.is_empty():
		var all: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(RUTA)) if FileAccess.file_exists(RUTA) else {}
		_cfg = all.get("teclas", {})
	return _cfg


## [[clave, nombre, sección, tecla de fábrica], …] en el orden de la lista de Opciones.
static func acciones() -> Array:
	return cfg().get("acciones", [])


static func _asegurar() -> void:
	if mapa.is_empty():
		de_fabrica()


static func codigo(nombre: String) -> int:
	return 0 if nombre == "" else int(OS.find_keycode_from_string(nombre))


## Nombre legible de una tecla ("F1", ".", "Espacio"); "—" si no tiene.
static func nombre(code: int) -> String:
	if code == 0:
		return "—"
	var s := OS.get_keycode_string(code)
	return {"Period": ".", "Comma": ",", "Space": "Espacio", "Delete": "Supr", "Home": "Inicio", "Tab": "Tab", "Semicolon": ";", "Slash": "/", "Minus": "-", "Equal": "=", "BackSpace": "Retroceso", "Enter": "Intro", "Insert": "Insert", "End": "Fin", "PageUp": "RePág", "PageDown": "AvPág", "QuoteLeft": "º"}.get(s, s)


static func defecto(accion_: String) -> int:
	for a: Array in acciones():
		if a[0] == accion_:
			return codigo(a[3])
	return 0


static func titulo(accion_: String) -> String:
	for a: Array in acciones():
		if a[0] == accion_:
			return a[1]
	return accion_


static func tecla(accion_: String) -> int:
	_asegurar()
	return int(mapa.get(accion_, 0))


## La tecla de la acción, para textos de ayuda ("H", "F7", "—").
static func texto(accion_: String) -> String:
	return nombre(tecla(accion_))


## La acción de una tecla ("" si no hay).
static func accion(code: int) -> String:
	_asegurar()
	return _por_tecla.get(code, "")


static func es(code: int, accion_: String) -> bool:
	return code != 0 and tecla(accion_) == code


static func reservada(code: int) -> bool:
	return (cfg().get("reservadas", []) as Array).has(OS.get_keycode_string(code)) or code == 0


static func _reindexar() -> void:
	_por_tecla.clear()
	for a: Array in acciones():
		var c := int(mapa.get(a[0], 0))
		if c != 0 and not _por_tecla.has(c):
			_por_tecla[c] = a[0]


static func de_fabrica() -> void:
	mapa.clear()
	for a: Array in acciones():
		mapa[a[0]] = codigo(a[3])
	grupos_exclusivos = bool((cfg().get("perfiles", {}) as Dictionary).get("fabrica", {}).get("grupos_exclusivos", false))
	numeros_danio = bool((cfg().get("perfiles", {}) as Dictionary).get("fabrica", {}).get("numeros_danio", true)) # --- fluidez 5 ---
	_reindexar()


## Perfil de data/interfaz.json → teclas.perfiles: las de fábrica más sus cambios. El perfil
## está armado sin choques; si alguno quedara, `choques()` lo muestra en Opciones.
static func perfil(clave: String) -> void:
	var p: Dictionary = (cfg().get("perfiles", {}) as Dictionary).get(clave, {})
	de_fabrica()
	var cambios: Dictionary = p.get("teclas", {})
	for k in cambios:
		mapa[k] = codigo(cambios[k])
	grupos_exclusivos = bool(p.get("grupos_exclusivos", grupos_exclusivos))
	numeros_danio = bool(p.get("numeros_danio", numeros_danio)) # --- fluidez 5 ---
	_reindexar()


## {clave: nombre} de los perfiles, en el orden del archivo.
static func perfiles() -> Dictionary:
	var out := {}
	var ps: Dictionary = cfg().get("perfiles", {})
	for k in ps:
		out[k] = ps[k].get("nombre", k)
	return out


## Asigna `code` a la acción. Si otra acción la tenía, se intercambian (la otra queda con la
## tecla vieja de esta). Devuelve la acción que cambió de tecla por el choque ("" si ninguna).
static func asignar(accion_: String, code: int) -> String:
	_asegurar()
	var vieja := int(mapa.get(accion_, 0))
	var otra := ""
	for k in mapa:
		if k != accion_ and int(mapa[k]) == code and code != 0:
			otra = k
			break
	mapa[accion_] = code
	if otra != "":
		mapa[otra] = vieja
	_reindexar()
	return otra


## Teclas repetidas: {keycode: [acciones]} (solo las que tienen más de una).
static func choques() -> Dictionary:
	_asegurar()
	var por := {}
	for k in mapa:
		var c := int(mapa[k])
		if c != 0:
			if not por.has(c):
				por[c] = []
			por[c].append(k)
	var out := {}
	for c in por:
		if (por[c] as Array).size() > 1:
			out[c] = por[c]
	return out


static func cargar(cf: ConfigFile) -> void:
	de_fabrica()
	if cf.has_section("teclas"):
		var nuevas: Array = [] # --- veterano ronda 5 --- acciones que el archivo no conoce
		for a: Array in acciones():
			if cf.has_section_key("teclas", a[0]):
				mapa[a[0]] = codigo(str(cf.get_value("teclas", a[0], a[3])))
			else:
				nuevas.append(a[0])
		# --- veterano ronda 5 --- una acción nueva (la campana, los marcadores 5 a 8…) no le
		# roba la tecla a una que el jugador ya había elegido: queda sin tecla.
		for k in nuevas:
			var c := int(mapa[k])
			for o in mapa:
				if o != k and not nuevas.has(o) and int(mapa[o]) == c and c != 0:
					mapa[k] = 0
					break
	grupos_exclusivos = bool(cf.get_value("controles", "grupos_exclusivos", grupos_exclusivos))
	numeros_danio = bool(cf.get_value("controles", "numeros_danio", numeros_danio)) # --- fluidez 5 ---
	_reindexar()


static func guardar(cf: ConfigFile) -> void:
	_asegurar()
	for a: Array in acciones():
		var c := int(mapa.get(a[0], 0))
		cf.set_value("teclas", a[0], "" if c == 0 else OS.get_keycode_string(c))
	cf.set_value("controles", "grupos_exclusivos", grupos_exclusivos)
	cf.set_value("controles", "numeros_danio", numeros_danio) # --- fluidez 5 ---
# --- fin veterano ronda 4 ---
