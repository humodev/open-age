class_name RedValidar
extends RefCounted
## Validación de lo que llega por la red (proceso/37-red/02): un cliente roto o modificado no
## tiene que tumbar al otro. Cada mensaje se mira antes de usarlo: que sea un diccionario con
## un "tipo" conocido, que cada campo tenga su tipo y que los tamaños no se pasen de los topes
## de data/red.json (validacion). Lo que no pasa se descarta y se cuenta.

## Campos de cada mensaje: nombre -> tipo de Variant. Los marcados con "?" pueden faltar.
const CAMPOS := {
	"hola": {"civ": TYPE_STRING, "color": TYPE_INT, "listo": TYPE_BOOL, "inyectado?": TYPE_INT},
	"elijo": {"civ": TYPE_STRING, "color": TYPE_INT, "listo": TYPE_BOOL},
	"sala": {"sala": TYPE_DICTIONARY},
	"empezar": {"args": TYPE_DICTIONARY},
	"retomar": {"args": TYPE_DICTIONARY, "log": TYPE_ARRAY, "hashes": TYPE_ARRAY, "reanudado": TYPE_INT, "foto?": TYPE_PACKED_BYTE_ARRAY, "inyectado?": TYPE_INT, "pausas?": TYPE_DICTIONARY},
	"turnos": {"log": TYPE_ARRAY},
	"turno": {"j": TYPE_INT, "n": TYPE_INT, "c": TYPE_ARRAY, "pausa?": TYPE_BOOL},
	"hash": {"j": TYPE_INT, "t": TYPE_INT, "h": TYPE_INT},
	"reanudar": {"n": TYPE_INT},
	"ping": {"t": TYPE_INT},
	"pong": {"t": TYPE_INT},
}
## Claves de un comando que la simulación usa como enteros.
const ENTEROS := ["player", "x", "y", "tx", "ty", "target", "building", "edificio", "unit", "n", "index", "max", "rumbo", "tick"]


## Por qué se descarta `m` ("" si está bien). `local`: el jugador de esta máquina (nadie
## puede mandar turnos ni hashes a su nombre). `cfg`: data/red.json → validacion.
static func motivo(m: Variant, local: int, cfg: Dictionary) -> String:
	if not m is Dictionary:
		return "no es un diccionario"
	var d: Dictionary = m
	var tipo: Variant = d.get("tipo")
	if not tipo is String or not CAMPOS.has(tipo):
		return "tipo desconocido"
	var campos: Dictionary = CAMPOS[tipo]
	for k: String in campos:
		var nom := k.trim_suffix("?")
		if not d.has(nom):
			if k.ends_with("?"):
				continue
			return "%s sin %s" % [tipo, nom]
		if typeof(d[nom]) != int(campos[k]):
			return "%s.%s con otro tipo" % [tipo, nom]
	if d.size() > campos.size() + 1:
		return "%s con campos de más" % tipo
	var tope_texto := int(cfg.get("max_texto", 64))
	match tipo:
		"hola", "elijo":
			if (d["civ"] as String).length() > tope_texto:
				return "civ demasiado larga"
		"turno", "hash":
			if int(d["j"]) == local or int(d["j"]) < 0:
				return "%s a nombre de otro jugador" % tipo
			if tipo == "turno":
				if int(d["n"]) < 0:
					return "turno negativo"
				var c: Array = d["c"]
				if c.size() > int(cfg.get("max_comandos_por_turno", 100)):
					return "demasiados comandos en un turno"
				for cmd in c:
					var r := comando(cmd, cfg)
					if r != "":
						return r
		"turnos":
			for x in (d["log"] as Array):
				var r := motivo(x, local, cfg)
				if r != "":
					return "turnos: " + r
	return ""


## Un comando de la simulación: un diccionario chico de claves de texto con valores simples
## (enteros, verdadero o falso, textos cortos) o listas y diccionarios chicos de esos.
static func comando(cmd: Variant, cfg: Dictionary) -> String:
	if not cmd is Dictionary:
		return "comando que no es un diccionario"
	var c: Dictionary = cmd
	if c.size() > int(cfg.get("max_claves_comando", 24)):
		return "comando con demasiadas claves"
	if not c.get("t") is String:
		return "comando sin tipo"
	for k in c:
		if not k is String:
			return "clave de comando que no es texto"
		if k in ENTEROS and typeof(c[k]) != TYPE_INT:
			return "comando %s: %s no es entero" % [c["t"], k]
		if not _simple(c[k], cfg, 0):
			return "comando %s: %s inválido" % [c["t"], k]
	return ""


static func _simple(v: Variant, cfg: Dictionary, nivel: int) -> bool:
	match typeof(v):
		TYPE_INT, TYPE_BOOL, TYPE_VECTOR2I:
			return true
		TYPE_STRING:
			return (v as String).length() <= int(cfg.get("max_texto", 64))
		TYPE_ARRAY:
			var a: Array = v
			if nivel >= 2 or a.size() > int(cfg.get("max_lista", 2000)):
				return false
			for x in a:
				if not _simple(x, cfg, nivel + 1):
					return false
			return true
		TYPE_DICTIONARY:
			var d: Dictionary = v
			if nivel >= 2 or d.size() > int(cfg.get("max_claves_comando", 24)):
				return false
			for k in d:
				if not (k is String or k is int) or not _simple(d[k], cfg, nivel + 1):
					return false
			return true
	return false
