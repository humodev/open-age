class_name SimData
extends RefCounted
## Carga los JSON de data/ y los convierte a enteros (docs/06-arquitectura.md, "Determinismo").

var reglas: Dictionary
var unidades: Dictionary
var edificios: Dictionary
var recursos: Dictionary
var edades: Array


static func load_default() -> SimData:
	var d := SimData.new()
	d.reglas = _load("res://data/reglas.json")
	d.unidades = _load("res://data/unidades.json")
	d.edificios = _load("res://data/edificios.json")
	d.recursos = _load("res://data/recursos.json")
	d.edades = _load("res://data/edades.json")["edades"]
	return d


static func _load(path: String) -> Variant:
	var f := FileAccess.open(path, FileAccess.READ)
	assert(f != null, "No se pudo abrir %s" % path)
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	assert(parsed != null, "JSON inválido en %s" % path)
	return _to_int(parsed, path)


static func _to_int(v: Variant, path: String) -> Variant:
	match typeof(v):
		TYPE_FLOAT:
			assert(v == floorf(v), "Valor con decimales en %s: %s" % [path, v])
			return int(v)
		TYPE_DICTIONARY:
			var out := {}
			for k in v:
				if String(k).begins_with("_"):
					continue
				out[k] = _to_int(v[k], path)
			return out
		TYPE_ARRAY:
			var arr := []
			for item in v:
				arr.append(_to_int(item, path))
			return arr
	return v


func def_of(type: String) -> Dictionary:
	if unidades.has(type):
		return unidades[type]
	if edificios.has(type):
		return edificios[type]
	return recursos.get(type, {})


## Costo efectivo: el hito cuesta según la edad de destino.
func cost_of(type: String, age: int) -> Dictionary:
	if type == "hito":
		if age >= edades.size():
			return {}
		return edades[age].get("hito_costo", {})
	return def_of(type).get("costo", {})


func build_time_of(type: String, age: int) -> int:
	if type == "hito":
		if age >= edades.size():
			return 0
		return edades[age].get("hito_tiempo_ms", 0)
	return def_of(type).get("tiempo_ms", 0)
