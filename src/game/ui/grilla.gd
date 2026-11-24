class_name Grilla
extends RefCounted
## Grilla de comandos estable (docs/diseno/interfaz/00-auditoria.md, P4 y mejora 5).
##
## El aldeano no muestra sus edificios en una sola grilla: muestra dos submenús, Economía (Q) y
## Militar (W), y los hitos en Z (economía) y X (militar). Dentro de cada submenú, cada edificio
## tiene una casilla fija por función, la misma en las seis civilizaciones. La tabla vive en
## data/interfaz.json → "grilla"; acá no hay reparto automático salvo para un edificio que la
## tabla no nombre, que va a la primera casilla libre y deja un aviso en la consola.

const RAIZ := ""
const ECONOMIA := "economia"
const MILITAR := "militar"

static var _cfg: Dictionary = {}


static func cfg() -> Dictionary:
	if _cfg.is_empty():
		var path := "res://data/interfaz.json"
		var all: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(path)) if FileAccess.file_exists(path) else {}
		_cfg = all.get("grilla", {})
	return _cfg


## Casilla de un comando fijo del aldeano o de una unidad (economia, militar, detener, refugio, …).
static func fija(name: String, fallback: int) -> int:
	return int((cfg().get("fijas", {}) as Dictionary).get(name, fallback))


## Submenú al que pertenece un edificio: "economia" o "militar".
static func menu_de(dd: SimData, type: String) -> String:
	for m in [ECONOMIA, MILITAR]:
		if (cfg().get(m, {}) as Dictionary).has(type):
			return m
	var def: Dictionary = dd.edificios.get(type, {})
	for k in ["pob", "deposito", "fuente", "renta", "motor", "mercado"]:
		if def.has(k):
			return ECONOMIA
	if def.has("produce") or def.has("flechas") or def.get("linea", false):
		return MILITAR
	return ECONOMIA


## Edificios de un submenú para la civilización: {casilla: tipo}. Los hitos no van acá.
static func edificios(dd: SimData, menu: String) -> Dictionary:
	var table: Dictionary = cfg().get(menu, {})
	var out := {}
	var pending: Array[String] = []
	# Primero los de casilla fija y después los de lista, para que una lista no ocupe una casilla fija.
	var mine: Array[String] = []
	for type: String in dd.unidades["aldeano"].get("construye", []):
		if dd.edificios.has(type) and not dd.is_hito(type) and not dd.edificios[type].get("maravilla", false) and menu_de(dd, type) == menu: # --- paso 7 --- la maravilla va en la raíz
			mine.append(type)
	mine.sort_custom(func(a: String, b: String) -> bool: return not (table.get(a, -1) is Array) and table.get(b, -1) is Array)
	for type: String in mine:
		# Una casilla fija, o una lista de casillas en orden de preferencia (la primera libre).
		var want: Variant = table.get(type, -1)
		var slots: Array = want if want is Array else [want]
		var placed := false
		for sl: Variant in slots:
			var slot := int(sl)
			if slot >= 0 and not out.has(slot):
				out[slot] = type
				placed = true
				break
		if not placed:
			pending.append(type)
	var back := fija("volver", 11)
	for type in pending:
		push_warning("Grilla: '%s' no tiene casilla en data/interfaz.json → grilla.%s" % [type, menu])
		for slot in 12:
			if not out.has(slot) and slot != back:
				out[slot] = type
				break
	return out


## Casilla de cada hito de la edad siguiente: Z para el de economía, X para el militar.
## Si las dos opciones son del mismo eje (no pasa en los datos actuales), se respeta el orden.
static func hitos(dd: SimData, age: int) -> Dictionary:
	var out := {}
	if dd.hitos.is_empty():
		return out
	var opts: Array = dd.hitos[mini(age, dd.hitos.size()) - 1] if age <= dd.hitos.size() else dd.hitos[-1]
	var z := fija("hito_economia", 8)
	var x := fija("hito_militar", 9)
	for i in mini(2, opts.size()):
		var key: String = opts[i]
		var slot := x if eje(dd.edificios.get(key, {}), key) == "militar" else z
		if out.has(slot):
			slot = z if slot == x else x
		out[slot] = key
	return out


## Eje de un hito: el campo `eje` de los datos; los comunes se deducen por su clave.
static func eje(def: Dictionary, key: String) -> String:
	if def.has("eje"):
		return def["eje"]
	return "militar" if key.contains("guerra") or def.has("produce") or def.has("flechas") else "economia"


## Ícono propio de un edificio o unidad según la tabla de la interfaz (o "" si no tiene).
static func icono(type: String) -> String:
	var propio := Iconos.de_tipo(type) # --- iconos --- (proceso/28: data/iconos.json → tipos)
	if propio != "":
		return propio
	return String((cfg().get("iconos", {}) as Dictionary).get(type, ""))


## --- depósitos de comida --- Nombre común de un tipo para un pueblo (la capa sin civilización:
## "Casa", "Granero"), o vacío si el propio ya es ese o no hay común. Un almacén se nombra por lo
## que recibe en ese pueblo: el tapyi guaraní (alimento y madera) es "Granero y leñera", no la
## "Leñera" común (proceso/24, 4m). Tabla en data/interfaz.json → grilla.comunes_deposito.
static func comun(base: SimData, dd: SimData, type: String) -> String:
	var own: Dictionary = dd.def_of(type)
	# C-30 a: «los nombres en castellano y los originales». Lo propio de un pueblo con nombre en su
	# lengua lleva su nombre en castellano en los datos (`nombre_comun`), y ese manda.
	if own.has("nombre_comun"):
		return String(own["nombre_comun"]) if own["nombre_comun"] != own.get("nombre", "") else ""
	var common: Dictionary = base.def_of(type)
	var out: String = common.get("nombre", "")
	var fixed: Dictionary = cfg().get("comunes", {})
	if fixed.has(type):
		out = fixed[type]
	elif own.has("deposito") and not own.has("funcion") and not (own.get("produce", []) as Array).has("aldeano"):
		# Siempre por lo que recibe, aunque coincida con el común: el «Barrero» no decía qué guarda
		# (jugador nuevo, ronda 4); ahora es «Depósito de piedra y riqueza».
		out = String((cfg().get("comunes_deposito", {}) as Dictionary).get(recibe_clave(own["deposito"]), out))
	return out if out != String(own.get("nombre", "")) else ""


## "alimento+madera": lo que recibe un depósito, en el orden del banco.
static func recibe_clave(dep: Array) -> String:
	var parts: Array[String] = []
	for k in Sim.RES_KINDS:
		if dep.has(k):
			parts.append(k)
	return "+".join(parts)
# --- fin depósitos de comida ---
