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
	for type: String in dd.unidades["aldeano"].get("construye", []):
		if not dd.edificios.has(type) or dd.is_hito(type) or menu_de(dd, type) != menu:
			continue
		var slot := int(table.get(type, -1))
		if slot >= 0 and not out.has(slot):
			out[slot] = type
		else:
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
	return String((cfg().get("iconos", {}) as Dictionary).get(type, ""))
