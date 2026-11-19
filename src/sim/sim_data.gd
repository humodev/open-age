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
var reemplazos := {} # --- paso 4 --- unidad -> la que la reemplaza desde su edad_min


static func load_default() -> SimData:
	var d := SimData.new()
	d.reglas = _load("res://data/reglas.json")
	d.unidades = _load("res://data/unidades.json")
	d.edificios = _load("res://data/edificios.json")
	d.recursos = _load("res://data/recursos.json")
	d.edades = _load("res://data/edades.json")["edades"]
	d.tecnologias = _load("res://data/tecnologias.json")
	d.hitos = [["hito_economia", "hito_guerra"], ["hito_economia", "hito_guerra"], ["hito_economia", "hito_guerra"]]
	d._junto_a() # --- ronda 8, 05 ---
	for f in DirAccess.get_files_at("res://data/civs"):
		if f.ends_with(".json"):
			var c: Dictionary = _load("res://data/civs/" + f)
			var key := f.get_basename()
			c["clave"] = key
			d.civs[key] = d._merge(c)
	return d


## --- ronda 8, 05 --- `junto_a`: la unidad se entrena en cada edificio que entrena a esa otra
## (la guardia de la IV, junto al guerrero). Orden fijo: el de las claves, ordenadas.
func _junto_a() -> void:
	var ukeys: Array = unidades.keys()
	ukeys.sort()
	for u in ukeys:
		var with: String = unidades[u].get("junto_a", "")
		if with == "":
			continue
		for b in edificios:
			var pr: Array = edificios[b].get("produce", [])
			if pr.has(with) and not pr.has(u):
				var npr := pr.duplicate()
				npr.append(u)
				edificios[b]["produce"] = npr


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
	m._junto_a() # --- ronda 8, 05 ---
	# Niveles por línea (veterano, élite): solo los de las líneas que el pueblo entrena en
	# algún edificio (los guaraníes no tienen montados; los incas, solo desde Vilcabamba).
	var made := {}
	for b in m.edificios:
		for l in m.lines_made_by(m.edificios[b]):
			made[l] = true
	for k in m.tecnologias.keys():
		var lin: String = m.tecnologias[k].get("en", {}).get("linea", "")
		if lin != "" and not made.has(lin):
			m.tecnologias.erase(k)
	# --- ronda 8, 05 --- Caminos de la escuela: sin la línea que piden (`requiere_linea`) o fuera de
	# los del pueblo (`escuela.caminos`), no están; con ellos se van sus mejoras (`camino`).
	var allowed: Array = c.get("escuela", {}).get("caminos", [])
	var gone := {}
	for k in m.tecnologias.keys():
		var t: Dictionary = m.tecnologias[k] if m.tecnologias[k] is Dictionary else {}
		var cd: String = t.get("camino_de", "")
		if cd == "":
			continue
		var rl: String = t.get("requiere_linea", "")
		if (rl != "" and not made.has(rl)) or (not allowed.is_empty() and not allowed.has(cd)):
			gone[cd] = true
			m.tecnologias.erase(k)
	for k in m.tecnologias.keys():
		if m.tecnologias[k] is Dictionary and gone.has(String(m.tecnologias[k].get("camino", ""))):
			m.tecnologias.erase(k)
	# --- paso 4 --- Una unidad que `reemplaza` a otra desde su edad (el hondero de piedra
	# caliente y el cañón de tacuara pasan a la ranura del asedio de área en la III).
	for u in m.unidades:
		var rep: String = m.unidades[u].get("reemplaza", "")
		if rep != "" and m.unidades.has(rep):
			m.reemplazos[rep] = u
	# --- fin paso 4 ---
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
		# --- paso 7 --- `hereda`: parte de otro de la tabla ya fusionada (la maravilla de la vía
		# monte guaraní hereda costo, vida y obra de la maravilla común y cambia nombre y efecto).
		var src: String = (extra[k] as Dictionary).get("hereda", "")
		if src != "" and out.has(src):
			var merged_h: Dictionary = (out[src] as Dictionary).duplicate(true)
			for f in extra[k]:
				merged_h[f] = extra[k][f]
			out[k] = merged_h
			continue
		out[k] = (extra[k] as Dictionary).duplicate(true)
	return out


## Tabla de una civilización, o la capa común si no existe.
func for_civ(key: String) -> SimData:
	return civs.get(key, self)


## Línea de una unidad para los niveles veterano y élite (docs/diseno/27, §1.1): pólvora,
## montados (montado o elefante) o su función (choque, distancia, linea). Vacío si no es tropa.
## El asedio es su propia línea desde el paso 4 (veterano_asedio, elite_asedio).
static func line_of(def: Dictionary) -> String:
	var fn: String = def.get("funcion", "")
	# --- paso 4 ---
	if fn == "asedio":
		return "asedio"
	# --- fin paso 4 ---
	if not fn in ["choque", "distancia", "linea"]:
		return ""
	if def.get("polvora", false):
		return "polvora"
	if def.get("montado", false) or def.get("elefante", false):
		return "montados"
	return fn


## Líneas que entrena un edificio (por su `produce`, con las unidades de esta tabla).
func lines_made_by(bdef: Dictionary) -> Array:
	var out := []
	for u in bdef.get("produce", []):
		var l := line_of(unidades.get(u, {}))
		if l != "" and not out.has(l):
			out.append(l)
	return out


## --- paso 4 --- ¿`type` ya no se entrena en la edad `age` porque otra lo reemplaza?
## Devuelve la clave del reemplazo o "".
func replaced_by(type: String, age: int) -> String:
	var rep: String = reemplazos.get(type, "")
	if rep != "" and age >= int(unidades[rep].get("edad_min", 1)):
		return rep
	return ""


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
