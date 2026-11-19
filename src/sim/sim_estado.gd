class_name SimEstado
extends RefCounted
## Instantáneas del estado de la simulación (proceso/37-red/02).
##
## Una foto es todo el grafo de objetos de `Sim` en un tick, entre dos pasos: entidades,
## jugadores, IA, comercio, sitios, grupos, colas, niebla, mapa (con las grillas de caminos),
## comandos pendientes, contadores y la próxima id. Se recorre por reflexión (las variables de
## cada guión), así un campo nuevo entra solo.
##
## - Los objetos de los guiones de la simulación van a una tabla; las referencias a ellos se
##   escriben como Vector4i(_REF, índice) (la simulación no usa Vector4i), y se conserva la
##   identidad: la misma entidad en `entities`, `by_id` y `_owned` vuelve como un solo objeto.
## - Los datos (`SimData`), la telemetría y la red no son estado: se toman de la partida armada.
##   El `def` de una entidad, si es el mismo diccionario de los datos, se guarda como
##   referencia (jugador, tabla, tipo) y no como copia.
## - Las grillas de caminos (AStarGrid2D) se guardan casilla por casilla (sólidas y pesos).
## - Los arreglos tipados llevan su tipo, para volver tipados.
##
## Cargar: se arma la misma partida en el tick 0 (Guardado.armar, SimScenario) y se le
## vuelca la foto encima. Los objetos únicos (mapa, niebla, IA, escenario…) se reusan por guión
## y orden de aparición; las entidades se crean de nuevo. Al final se compara el hash.
## Determinista: solo enteros del estado; los pesos de las grillas son los floats que ya tenían.

const VERSION := 1
const MAGIA := 0x4F544F46 # "FOTO"
const _REF := 1 # objeto de la tabla
const _EXT := 2 # objeto de afuera (datos, telemetría, red)
const _NAT := 3 # grilla de caminos
const _DEF := 4 # def de entidad que es la de los datos
const _TYP := 9 # arreglo tipado
const _ENTIDAD := "res://src/sim/sim_entity.gd"
## Guiones que no son estado de la partida: se reusan los de la partida armada.
const _AFUERA := ["res://src/sim/sim_data.gd", "res://src/sim/sim_telemetry.gd"]

static var _props := {} # ruta del guión -> PackedStringArray de sus variables
static var _j_def := -1 # posición de `def` entre las variables de SimEntity
static var _j_compuestos := PackedInt32Array() # las de SimEntity que no son valores simples

var _sim: Sim
var _solo_descubrir := false
var _ids := {} # Object -> índice en _objs
var _objs: Array = [] # [índice de guión, valores]
var _cola: Array = []
var _guiones: Array = [] # [ruta, nombres]
var _guion_idx := {}
var _ext: Array = [] # rutas
var _ext_ids := {} # Object -> índice
var _nats: Array = []
var _nat_ids := {}
var _error := ""
# Al cargar
var _objetos: Array = []
var _ext_obj: Array = []
var _nat_obj: Array = []


# ---------------------------------------------------------------- Tomar

## La foto comprimida (zstd) del estado de `sim`. Se toma entre dos pasos.
static func tomar(sim: Sim) -> PackedByteArray:
	var raw := var_to_bytes(foto(sim))
	var z := raw.compress(FileAccess.COMPRESSION_ZSTD)
	var out := PackedByteArray()
	out.resize(12)
	out.encode_u32(0, MAGIA)
	out.encode_u32(4, VERSION)
	out.encode_u32(8, raw.size())
	out.append_array(z)
	return out


## La foto sin comprimir (un Variant sin objetos).
static func foto(sim: Sim) -> Dictionary:
	var e := SimEstado.new()
	e._sim = sim
	e._recorrer(sim)
	if e._error != "":
		push_error("SimEstado: " + e._error)
	return {"v": VERSION, "tick": sim.tick, "hash": sim.state_hash(), "guiones": e._guiones, "objs": e._objs, "ext": e._ext, "nat": e._nats}


## Tick y hash de una foto comprimida sin abrirla toda ({} si no es una foto).
static func cabecera(bytes: PackedByteArray) -> Dictionary:
	var f := _abrir(bytes)
	return {} if f.is_empty() else {"tick": int(f["tick"]), "hash": int(f["hash"])}


func _recorrer(raiz: Object) -> void:
	_ref(raiz)
	var i := 0
	while i < _cola.size():
		var o: Object = _cola[i]
		var gi: int = _objs[i][0]
		if _solo_descubrir and (_guiones[gi][0] as String) == _ENTIDAD:
			i += 1
			continue
		var nombres: PackedStringArray = _guiones[gi][1]
		var vals: Array
		if o is SimEntity:
			# Las entidades son casi todo el estado: se leen de una vez (inst_to_dict, en el
			# orden de `nombres`) y solo se recorre lo que no es un valor simple.
			vals = inst_to_dict(o).values().slice(2)
			for j in _j_compuestos:
				var t := typeof(vals[j])
				if t == TYPE_ARRAY or t == TYPE_DICTIONARY or t == TYPE_OBJECT:
					vals[j] = _enc_def(o) if j == _j_def else _enc(vals[j])
		else:
			vals = []
			vals.resize(nombres.size())
			for j in nombres.size():
				vals[j] = _enc(o.get(nombres[j]))
		_objs[i][1] = vals
		i += 1


func _enc(v: Variant) -> Variant:
	match typeof(v):
		TYPE_OBJECT:
			return _ref(v)
		TYPE_ARRAY:
			var a: Array = v
			var out: Array = []
			if a.is_typed():
				var b := a.get_typed_builtin()
				var sc: Script = a.get_typed_script()
				out.append(Vector4i(_TYP, b, 0, 0))
				out.append(String(a.get_typed_class_name()))
				out.append(sc.resource_path if sc != null else "")
				if b != TYPE_OBJECT and b != TYPE_ARRAY and b != TYPE_DICTIONARY:
					out.append_array(a)
					return out
			for x in a:
				out.append(_enc(x))
			return out
		TYPE_DICTIONARY:
			var d: Dictionary = v
			var out := {}
			for k in d:
				var kk: Variant = _enc(k) if typeof(k) == TYPE_OBJECT else k
				out[kk] = _enc(d[k])
			return out
	return v


func _ref(o: Object) -> Variant:
	if o == null:
		return null
	if _ids.has(o):
		return Vector4i(_REF, _ids[o], 0, 0)
	if o is AStarGrid2D:
		if not _nat_ids.has(o):
			_nat_ids[o] = _nats.size()
			_nats.append(null if _solo_descubrir else _enc_grilla(o))
		return Vector4i(_NAT, _nat_ids[o], 0, 0)
	var sc: Script = o.get_script()
	if sc == null:
		_error = "objeto sin guión en el estado: %s" % o.get_class()
		return null
	var ruta := sc.resource_path
	if ruta in _AFUERA or (not ruta.begins_with("res://src/sim/") and not _ids.is_empty()):
		if not _ext_ids.has(o):
			if ruta in _ext:
				_error = "dos objetos de afuera del mismo guión: %s" % ruta
			_ext_ids[o] = _ext.size()
			_ext.append(ruta)
		return Vector4i(_EXT, _ext_ids[o], 0, 0)
	if not _guion_idx.has(ruta):
		_guion_idx[ruta] = _guiones.size()
		_guiones.append([ruta, _nombres(o, ruta)])
	var idx := _objs.size()
	_ids[o] = idx
	_objs.append([_guion_idx[ruta], null])
	_cola.append(o)
	return Vector4i(_REF, idx, 0, 0)


static func _nombres(o: Object, ruta: String) -> PackedStringArray:
	if not _props.has(ruta):
		var out := PackedStringArray()
		if ruta == _ENTIDAD:
			# El orden de inst_to_dict (sin "@subpath" ni "@path"), el mismo de _recorrer.
			out = PackedStringArray(inst_to_dict(o).keys().slice(2))
			_j_def = out.find("def")
			# Las variables que pueden tener arreglos, diccionarios u objetos (por su tipo declarado).
			var simples := [TYPE_BOOL, TYPE_INT, TYPE_FLOAT, TYPE_STRING, TYPE_VECTOR2I, TYPE_VECTOR2, TYPE_RECT2I, TYPE_STRING_NAME]
			_j_compuestos = PackedInt32Array()
			for p in o.get_property_list():
				var k := out.find(str(p["name"]))
				if k >= 0 and not int(p["type"]) in simples:
					_j_compuestos.append(k)
		else:
			for p in o.get_property_list():
				if int(p["usage"]) & PROPERTY_USAGE_SCRIPT_VARIABLE:
					out.append(str(p["name"]))
		_props[ruta] = out
	return _props[ruta]


## El def de una entidad: si es el mismo diccionario de los datos (la capa común o la de la
## civilización de algún jugador), una referencia; si es propio (copia), el contenido.
func _enc_def(e: SimEntity) -> Variant:
	var d: Dictionary = e.def
	for p in range(-1, _sim.players.size()):
		var sd: SimData = _sim.data if p < 0 else _sim.dp(p)
		var tabs := [sd.unidades, sd.edificios, sd.recursos]
		for t in 3:
			var tab: Dictionary = tabs[t]
			if tab.has(e.type) and is_same(tab[e.type], d):
				return [Vector4i(_DEF, p, t, 0), e.type]
	return _enc(d)


func _enc_grilla(a: AStarGrid2D) -> Array:
	var r := a.region
	var sol := PackedByteArray()
	sol.resize(r.size.x * r.size.y)
	var widx := PackedInt32Array()
	var wval := PackedFloat32Array()
	var i := 0
	for y in range(r.position.y, r.end.y):
		for x in range(r.position.x, r.end.x):
			var c := Vector2i(x, y)
			if a.is_point_solid(c):
				sol[i] = 1
			var w := a.get_point_weight_scale(c)
			if w != 1.0:
				widx.append(i)
				wval.append(w)
			i += 1
	return [r, a.cell_size, a.offset, a.cell_shape, a.diagonal_mode, a.default_compute_heuristic, a.default_estimate_heuristic, a.jumping_enabled, sol, widx, wval]


# ---------------------------------------------------------------- Cargar

static func _abrir(bytes: PackedByteArray) -> Dictionary:
	if bytes.size() < 12 or bytes.decode_u32(0) != MAGIA or bytes.decode_u32(4) != VERSION:
		return {}
	var raw := bytes.slice(12).decompress(bytes.decode_u32(8), FileAccess.COMPRESSION_ZSTD)
	var v: Variant = bytes_to_var(raw)
	return v if v is Dictionary else {}


## Vuelca una foto en `sim`, que tiene que ser la misma partida recién armada (tick 0, misma
## semilla, opciones, IA o misión). Devuelve si quedó con el hash de la foto.
static func cargar(sim: Sim, bytes: PackedByteArray) -> bool:
	var f := _abrir(bytes)
	if f.is_empty():
		push_error("SimEstado: no es una foto (o es de otra versión)")
		return false
	return restaurar(sim, f)


static func restaurar(sim: Sim, f: Dictionary) -> bool:
	var e := SimEstado.new()
	e._sim = sim
	if not e._volcar(f):
		return false
	var ok := sim.state_hash() == int(f["hash"])
	if not ok:
		push_error("SimEstado: la foto del tick %d no dio el mismo hash" % int(f["tick"]))
	return ok


func _volcar(f: Dictionary) -> bool:
	# Los objetos de la partida armada que se reusan: por guión, en orden de aparición.
	var d := SimEstado.new()
	d._sim = _sim
	d._solo_descubrir = true
	d._recorrer(_sim)
	var propios := {} # ruta -> [objetos]
	for i in d._objs.size():
		var ruta: String = d._guiones[d._objs[i][0]][0]
		if ruta != _ENTIDAD:
			if not propios.has(ruta):
				propios[ruta] = []
			propios[ruta].append(d._cola[i])
	var de_afuera := {}
	for o: Object in d._ext_ids:
		de_afuera[(o.get_script() as Script).resource_path] = o
	var guiones: Array = f["guiones"]
	var objs: Array = f["objs"]
	_objetos.resize(objs.size())
	var usados := {}
	var cargados := {}
	for i in objs.size():
		var ruta: String = guiones[objs[i][0]][0]
		var k: int = usados.get(ruta, 0)
		usados[ruta] = k + 1
		var l: Array = propios.get(ruta, [])
		if ruta != _ENTIDAD and k < l.size():
			_objetos[i] = l[k]
		elif ruta == _ENTIDAD:
			_objetos[i] = null # se crea con sus valores (dict_to_inst), abajo
		else:
			if not cargados.has(ruta):
				cargados[ruta] = load(ruta)
			_objetos[i] = (cargados[ruta] as GDScript).new()
	if _objetos[0] != _sim:
		push_error("SimEstado: la foto no es de esta clase de partida")
		return false
	for ruta: String in f["ext"]:
		_ext_obj.append(de_afuera.get(ruta))
	for g: Array in f["nat"]:
		_nat_obj.append(_dec_grilla(g))
	# Primero las entidades (las referencias a ellas tienen que existir antes de volcar el resto).
	for i in objs.size():
		if _objetos[i] == null:
			_objetos[i] = SimEntity.new()
	for i in objs.size():
		var o: Object = _objetos[i]
		var nombres: PackedStringArray = guiones[objs[i][0]][1]
		var vals: Array = objs[i][1]
		for j in nombres.size():
			var v: Variant = vals[j]
			var t := typeof(v)
			if t == TYPE_ARRAY or t == TYPE_DICTIONARY or t == TYPE_VECTOR4I:
				v = _dec(v)
			o.set(nombres[j], v)
	return true


func _dec(v: Variant) -> Variant:
	match typeof(v):
		TYPE_VECTOR4I:
			var r: Vector4i = v
			match r.x:
				_REF:
					return _objetos[r.y]
				_EXT:
					return _ext_obj[r.y]
				_NAT:
					return _nat_obj[r.y]
			return v
		TYPE_ARRAY:
			var a: Array = v
			if not a.is_empty() and typeof(a[0]) == TYPE_VECTOR4I:
				var h: Vector4i = a[0]
				if h.x == _DEF:
					var sd: SimData = _sim.data if h.y < 0 else _sim.dp(h.y)
					return ([sd.unidades, sd.edificios, sd.recursos][h.z] as Dictionary)[a[1]]
				if h.x == _TYP:
					var base := a.slice(3)
					if h.y == TYPE_OBJECT or h.y == TYPE_ARRAY or h.y == TYPE_DICTIONARY:
						for i in base.size():
							base[i] = _dec(base[i])
					var sp: String = a[2]
					return Array(base, h.y, StringName(a[1]), load(sp) if sp != "" else null)
			for i in a.size():
				a[i] = _dec(a[i])
			return a
		TYPE_DICTIONARY:
			var d: Dictionary = v
			var claves_obj := false
			for k in d:
				if typeof(k) == TYPE_VECTOR4I:
					claves_obj = true
				d[k] = _dec(d[k])
			if claves_obj:
				var out := {}
				for k in d:
					out[_dec(k)] = d[k]
				return out
			return d
	return v


func _dec_grilla(g: Array) -> AStarGrid2D:
	var a := AStarGrid2D.new()
	a.region = g[0]
	a.cell_size = g[1]
	a.offset = g[2]
	a.cell_shape = g[3]
	a.diagonal_mode = g[4]
	a.default_compute_heuristic = g[5]
	a.default_estimate_heuristic = g[6]
	a.jumping_enabled = g[7]
	a.update()
	var r: Rect2i = g[0]
	var sol: PackedByteArray = g[8]
	var w := r.size.x
	for i in sol.size():
		if sol[i] != 0:
			a.set_point_solid(Vector2i(r.position.x + i % w, r.position.y + i / w), true)
	var widx: PackedInt32Array = g[9]
	var wval: PackedFloat32Array = g[10]
	for k in widx.size():
		var i := widx[k]
		a.set_point_weight_scale(Vector2i(r.position.x + i % w, r.position.y + i / w), wval[k])
	return a
