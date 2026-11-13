class_name SimData
extends RefCounted
## Carga los JSON de data/ y los convierte a enteros (docs/06-arquitectura.md, "Determinismo").

var reglas: Dictionary
var unidades: Dictionary
var edificios: Dictionary
var recursos: Dictionary
var edades: Array
var tecnologias: Dictionary
# --- Civilización (docs/03 y data/civs/) ---
var clave := "" # vacío: capa común sin civilización
var civ: Dictionary = {} # el JSON crudo de la civilización
var hitos: Array = [] # por edad de destino (II, III, IV): lista de claves de hito
var modulos: Dictionary = {}
var civs := {} # clave -> SimData fusionada (solo en la tabla base)


static func load_default() -> SimData:
	var d := SimData.new()
	d.reglas = _load("res://data/reglas.json")
	d.unidades = _load("res://data/unidades.json")
	d.edificios = _load("res://data/edificios.json")
	d.recursos = _load("res://data/recursos.json")
	d.edades = _load("res://data/edades.json")["edades"]
	d.tecnologias = _load("res://data/tecnologias.json")
	d.hitos = [["hito_economia", "hito_guerra"], ["hito_economia", "hito_guerra"], ["hito_economia", "hito_guerra"]]
	for f in DirAccess.get_files_at("res://data/civs"):
		if f.ends_with(".json"):
			var c: Dictionary = _load("res://data/civs/" + f)
			var key := f.get_basename()
			c["clave"] = key
			d.civs[key] = d._merge(c)
	return d


## Tabla completa de una civilización: la capa común con sus reemplazos y agregados.
func _merge(c: Dictionary) -> SimData:
	var m := SimData.new()
	m.reglas = reglas
	m.recursos = recursos
	m.clave = c["clave"]
	m.civ = c
	m.unidades = _overlay(unidades, c.get("unidades", {}), c.get("unidades_nuevas", {}), c.get("sin_unidades", []))
	m.edificios = _overlay(edificios, c.get("edificios", {}), c.get("edificios_nuevos", {}), c.get("sin_edificios", []))
	m.tecnologias = _overlay(tecnologias, c.get("tecnologias", {}), c.get("tecnologias_nuevas", {}), c.get("sin_tecnologias", []))
	for b in c.get("produce", {}):
		if m.edificios.has(b):
			m.edificios[b]["produce"] = c["produce"][b]
	if c.has("construye"):
		m.unidades["aldeano"]["construye"] = c["construye"]
	m.edades = edades.duplicate(true)
	var names: Array = c.get("edades", [])
	for i in mini(names.size(), m.edades.size()):
		m.edades[i]["nombre"] = names[i]
	m.hitos = c.get("hitos", hitos)
	m.modulos = c.get("modulos", {})
	return m


static func _overlay(base: Dictionary, over: Dictionary, extra: Dictionary, remove: Array) -> Dictionary:
	var out := base.duplicate(true)
	for k in remove:
		out.erase(k)
	for k in over:
		if out.has(k):
			var merged: Dictionary = out[k]
			for f in over[k]:
				merged[f] = over[k][f]
	for k in extra:
		out[k] = (extra[k] as Dictionary).duplicate(true)
	return out


## Tabla de una civilización, o la capa común si no existe.
func for_civ(key: String) -> SimData:
	return civs.get(key, self)


func mod(name: String) -> Dictionary:
	return modulos.get(name, {})


func has_mod(name: String) -> bool:
	return modulos.has(name)


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
	if tecnologias.has(type):
		return tecnologias[type]
	if edificios.has(type):
		return edificios[type]
	return recursos.get(type, {})


func is_hito(type: String) -> bool:
	return edificios.get(type, {}).get("avanza_edad", false)


## Costo efectivo: los hitos cuestan según la edad de destino.
func cost_of(type: String, age: int) -> Dictionary:
	if is_hito(type):
		if age >= edades.size():
			return {}
		var c: Dictionary = (edades[age].get("hito_costo", {}) as Dictionary).duplicate()
		var extra: Dictionary = edificios[type].get("costo_extra", {})
		for k in extra:
			c[k] = int(c.get(k, 0)) + int(extra[k])
		return c
	return def_of(type).get("costo", {})


func build_time_of(type: String, age: int) -> int:
	if is_hito(type):
		if age >= edades.size():
			return 0
		return edades[age].get("hito_tiempo_ms", 0)
	return def_of(type).get("tiempo_ms", 0)


## Tiempo de un elemento de cola: unidad o investigación ("@clave").
func queue_time(item: String) -> int:
	if item.begins_with("@"):
		return tecnologias[item.substr(1)]["tiempo_ms"]
	return unidades[item]["tiempo_ms"]
