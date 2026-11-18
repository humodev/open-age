class_name PartidaConfig
## --- partida a medida --- (proceso/31) Configuración de una partida personalizada, como la
## de AoE: mapa, un renglón por jugador (tipo, pueblo, dificultad, estilo, equipo, color) y las
## opciones de partida. La arman la pantalla «Partida personalizada», --jugadores=…,
## --partida=archivo.json y --preset=1v3. No es estado de la simulación: se traduce a los
## argumentos de main.gd (lugares, colores, terreno, semilla, opciones) y nada más.
##
## Un jugador: {"tipo": "vos"|"ia"|"cerrado", "civ": clave|"azar", "dificultad": clave,
## "estilo": clave, "equipo": 0 (sin equipo) o 1..4, "color": índice de Palette.TEAM o -1}.

const RUTA := "user://partida_a_medida.json"
const MAX := 8
const TIPOS := ["vos", "ia", "cerrado"]
const TAMANOS := ["chico", "normal", "grande"]
## Presets rápidos: tipo y equipo de cada renglón (los demás quedan cerrados).
const PRESETS := {
	"1v1": [["vos", 1], ["ia", 2]],
	"1v3": [["vos", 1], ["ia", 2], ["ia", 2], ["ia", 2]],
	"1v6": [["vos", 1], ["ia", 2], ["ia", 2], ["ia", 2], ["ia", 2], ["ia", 2], ["ia", 2]],
	"2v2": [["vos", 1], ["ia", 1], ["ia", 2], ["ia", 2]],
	"4v4": [["vos", 1], ["ia", 1], ["ia", 1], ["ia", 1], ["ia", 2], ["ia", 2], ["ia", 2], ["ia", 2]],
	"tct": [["vos", 0], ["ia", 0], ["ia", 0], ["ia", 0]],
}
const PRESETS_ORDEN := ["1v1", "1v3", "1v6", "2v2", "4v4", "tct"]
const PRESETS_NOMBRE := {"1v1": "1 contra 1", "1v3": "1 contra 3", "1v6": "1 contra 6", "2v2": "2 contra 2", "4v4": "4 contra 4", "tct": "Todos contra todos"}


## Jugador por defecto del renglón i.
static func jugador(i: int) -> Dictionary:
	return {"tipo": "vos" if i == 0 else ("ia" if i == 1 else "cerrado"), "civ": "azar", "dificultad": "normal", "estilo": "normal", "equipo": 0, "color": i}


## Configuración de siempre: 1 contra 1 al azar con las opciones de partida del menú.
static func defecto() -> Dictionary:
	var js: Array = []
	for i in MAX:
		js.append(jugador(i))
	return {"jugadores": js, "terreno": "", "tamano": "normal", "semilla": -1, "recursos": "normal", "sitios": true, "hitos": true, "maravilla": true, "tiempo": 0, "ubicacion": "juntos"}


## Aplica un preset: tipo y equipo de cada renglón; pueblo, dificultad y color se conservan.
static func aplicar_preset(cfg: Dictionary, nombre: String) -> bool:
	if not PRESETS.has(nombre):
		return false
	var p: Array = PRESETS[nombre]
	var js: Array = cfg["jugadores"]
	for i in MAX:
		if i < p.size():
			js[i]["tipo"] = p[i][0]
			js[i]["equipo"] = p[i][1]
		else:
			js[i]["tipo"] = "cerrado"
	return true


## "vos:guaranies:1:azul,ia:mapuches:dificil:2:rojo,…" → jugadores. Cada parte se reconoce
## sola: tipo (vos, ia, cerrado), pueblo (o azar), dificultad, estilo, equipo (1 a 4; 0, - o
## sin = sin equipo) y color (nombre del modo de colores o c1…c8). El orden no importa.
static func parse_jugadores(s: String, data: SimData) -> Array:
	var out: Array = []
	var nombres: Array = []
	for x in Palette.TEAM_NAMES:
		nombres.append(_llano(x))
	for parte in s.split(",", false):
		if out.size() >= MAX:
			break
		var j := jugador(out.size())
		j["tipo"] = "ia"
		j["equipo"] = 0
		j["color"] = -1
		for tok in parte.strip_edges().split(":", false):
			var t := _llano(tok.strip_edges())
			if t in TIPOS:
				j["tipo"] = t
			elif t == "azar" or data.civs.has(t):
				j["civ"] = t
			elif data.reglas["dificultades"].has(t):
				j["dificultad"] = t
			elif data.reglas["estilos_ia"].has(t):
				j["estilo"] = t
			elif t in ["-", "sin", "0"]:
				j["equipo"] = 0
			elif t.is_valid_int() and int(t) >= 1 and int(t) <= 4:
				j["equipo"] = int(t)
			elif nombres.has(t):
				j["color"] = nombres.find(t)
			elif t.begins_with("c") and t.substr(1).is_valid_int():
				j["color"] = clampi(int(t.substr(1)) - 1, 0, MAX - 1)
			else:
				push_warning("--jugadores: no entiendo «%s»" % tok)
		out.append(j)
	return out


## Archivo JSON con la misma forma que defecto() (las claves que falten quedan como siempre).
## Los jugadores pueden venir como lista de diccionarios o como el texto de --jugadores.
static func desde_json(texto: String, data: SimData) -> Dictionary:
	var cfg := defecto()
	var d = JSON.parse_string(texto)
	if not (d is Dictionary):
		push_warning("partida a medida: el JSON no es un objeto")
		return {}
	for k in cfg:
		if k != "jugadores" and d.has(k):
			cfg[k] = d[k]
	if d.get("preset", "") != "":
		aplicar_preset(cfg, str(d["preset"]))
	var js = d.get("jugadores", null)
	if js is String:
		js = parse_jugadores(js, data)
	if js is Array:
		var lista: Array = []
		for i in MAX:
			var j := jugador(i)
			j["tipo"] = "cerrado"
			if i < (js as Array).size() and js[i] is Dictionary:
				j.merge(js[i], true)
				j["equipo"] = int(j["equipo"])
				j["color"] = int(j["color"])
			lista.append(j)
		cfg["jugadores"] = lista
	return cfg


## Completa una lista corta de jugadores (de --jugadores) hasta MAX con renglones cerrados.
static func con_jugadores(js: Array) -> Dictionary:
	var cfg := defecto()
	for i in MAX:
		if i < js.size():
			cfg["jugadores"][i] = js[i]
		else:
			cfg["jugadores"][i]["tipo"] = "cerrado"
	return cfg


## Por qué no se puede jugar ("" si se puede).
static func problema(cfg: Dictionary) -> String:
	var abiertos := 0
	var vos := 0
	var equipos := {}
	for i in MAX:
		var j: Dictionary = cfg["jugadores"][i]
		if j["tipo"] == "cerrado":
			continue
		abiertos += 1
		vos += 1 if j["tipo"] == "vos" else 0
		equipos[_equipo_sim(j, i)] = true
	if abiertos < 2:
		return "Hacen falta al menos dos jugadores."
	if vos > 1:
		return "Solo un jugador puede ser «Vos»."
	if equipos.size() < 2:
		return "Todos están en el mismo equipo: no habría rivales."
	return ""


static func _equipo_sim(j: Dictionary, i: int) -> int:
	var e := int(j.get("equipo", 0))
	return e - 1 if e >= 1 else 10 + i # sin equipo: un equipo propio


## Colores sin repetir: el pedido si está libre; si no, el primero libre.
static func colores(jugs: Array) -> Array:
	var usados := {}
	var out: Array = []
	for j: Dictionary in jugs:
		var c := int(j.get("color", -1))
		if c < 0 or c >= MAX or usados.has(c):
			c = -1
		out.append(c)
		if c >= 0:
			usados[c] = true
	for i in out.size():
		if out[i] < 0:
			for c in MAX:
				if not usados.has(c):
					out[i] = c
					usados[c] = true
					break
	return out


## Argumentos de main.gd: lugares (con «Vos» primero), colores, mapa y opciones de partida.
## Sin «Vos», la partida es IA contra IA (aivai).
static func a_args(cfg: Dictionary) -> Dictionary:
	var abiertos: Array = []
	for i in MAX:
		var j: Dictionary = cfg["jugadores"][i]
		if j["tipo"] != "cerrado":
			var k := j.duplicate()
			k["_i"] = i
			abiertos.append(k)
	var hay_vos := false
	for i in abiertos.size():
		if abiertos[i]["tipo"] == "vos":
			hay_vos = true
			if i > 0: # el jugador local es siempre el 0
				var v = abiertos[i]
				abiertos.remove_at(i)
				abiertos.insert(0, v)
			break
	var cols := colores(abiertos)
	var lugares: Array = []
	for j: Dictionary in abiertos:
		lugares.append({"civ": str(j["civ"]), "equipo": _equipo_sim(j, int(j["_i"])), "ia": j["tipo"] != "vos", "dificultad": str(j["dificultad"]), "estilo": str(j["estilo"])})
	var out := {
		"lugares": lugares,
		"colores": cols,
		"terreno": str(cfg.get("terreno", "")),
		"tamano": str(cfg.get("tamano", "normal")),
		"recursos": str(cfg.get("recursos", "normal")),
		"sitios": "si" if bool(cfg.get("sitios", true)) else "no",
		"hitos": "si" if bool(cfg.get("hitos", true)) else "no",
		"maravilla": "si" if bool(cfg.get("maravilla", true)) else "no",
		"tiempo": str(int(cfg.get("tiempo", 0))),
		"ubicacion": str(cfg.get("ubicacion", "juntos")),
	}
	if int(cfg.get("semilla", -1)) >= 0:
		out["seed"] = str(int(cfg["semilla"]))
	if not hay_vos:
		out["aivai"] = "1"
	return out


## La última configuración de la pantalla (no la de las pruebas: Opciones.solo_lectura).
static func cargar() -> Dictionary:
	var cfg := defecto()
	if Opciones.solo_lectura or not FileAccess.file_exists(RUTA): # las capturas, siempre igual
		return cfg
	var f := FileAccess.open(RUTA, FileAccess.READ)
	if f == null:
		return cfg
	var d = JSON.parse_string(f.get_as_text())
	if not (d is Dictionary) or not (d.get("jugadores", null) is Array):
		return cfg
	for k in cfg:
		if k == "jugadores" or not d.has(k):
			continue
		if cfg[k] is int and (d[k] is float or d[k] is int):
			cfg[k] = int(d[k])
		elif typeof(d[k]) == typeof(cfg[k]):
			cfg[k] = d[k]
	for i in mini(MAX, (d["jugadores"] as Array).size()):
		var j = d["jugadores"][i]
		if j is Dictionary:
			for k in ["tipo", "civ", "dificultad", "estilo"]:
				if j.get(k, null) is String:
					cfg["jugadores"][i][k] = j[k]
			for k in ["equipo", "color"]:
				if j.has(k):
					cfg["jugadores"][i][k] = int(j[k])
	return cfg


static func guardar(cfg: Dictionary) -> void:
	if Opciones.solo_lectura:
		return
	var f := FileAccess.open(RUTA, FileAccess.WRITE)
	if f == null:
		push_warning("partida a medida: no se pudo guardar %s" % RUTA)
		return
	f.store_string(JSON.stringify(cfg, "  "))


## Sin tildes ni mayúsculas: «Guaraníes» → «guaranies», «Rojo» → «rojo».
static func _llano(s: String) -> String:
	var t := s.to_lower()
	for p in [["á", "a"], ["é", "e"], ["í", "i"], ["ó", "o"], ["ú", "u"], ["ñ", "n"]]:
		t = t.replace(p[0], p[1])
	return t
