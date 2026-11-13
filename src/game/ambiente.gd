class_name Ambiente
## Ambiente visual por tipo de mapa: luz, cielo, niebla, agua, suelo y detalle
## (data/ambiente.json). Solo imagen; la simulación no lo lee.

static var _raw: Dictionary
static var _cache := {}


## Datos del mapa ya mezclados con "base".
static func of(terrain: String) -> Dictionary:
	if _cache.has(terrain):
		return _cache[terrain]
	if _raw.is_empty():
		_raw = JSON.parse_string(FileAccess.get_file_as_string("res://data/ambiente.json"))
	var d := _merge(_raw["base"], _raw.get(terrain, {}))
	_cache[terrain] = d
	return d


static func _merge(a: Dictionary, b: Dictionary) -> Dictionary:
	var out := a.duplicate(true)
	for k in b:
		if out.get(k) is Dictionary and b[k] is Dictionary:
			out[k] = _merge(out[k], b[k])
		else:
			out[k] = b[k]
	return out


static func col(v: Variant) -> Color:
	return Color.html(String(v))


static func cols(list: Array) -> Array[Color]:
	var out: Array[Color] = []
	for v in list:
		out.append(Color.html(String(v)))
	return out


## Entero en porcentaje a fracción.
static func pct(v: Variant) -> float:
	return float(v) / 100.0
