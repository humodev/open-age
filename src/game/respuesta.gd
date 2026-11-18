class_name Respuesta
extends RefCounted
## Respuesta inmediata (etapa 30, frente 3): el sonido al elegir y al errar, la orden por función,
## el cimiento con su polvo, el destello del blanco y el pulso al saltar con la cámara.
## Solo la vista: lee la simulación y no la toca. El controlador la llama con una línea por gancho
## (marcadas `# --- fluidez 3 ---`); los volúmenes y los interruptores están en data/respuesta.json.

static var _cfg: Dictionary = {}
## Cuántas veces sonó o se vio cada cosa (el autotest lo lee).
static var cuenta := {}


static func cfg() -> Dictionary:
	if _cfg.is_empty():
		var raw: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/respuesta.json"))
		_cfg = raw if raw is Dictionary else {"sonido": {"activo": false}, "efectos": {"activo": false}}
	return _cfg


## La entrada `nombre` del bloque `bloque` ("sonido" o "efectos"), o {} si está apagada.
static func de(bloque: String, nombre: String) -> Dictionary:
	var b: Dictionary = cfg().get(bloque, {})
	if not b.get("activo", true):
		return {}
	var d: Dictionary = b.get(nombre, {})
	return d if d.get("activo", true) else {}


static func _contar(k: String) -> void:
	cuenta[k] = int(cuenta.get(k, 0)) + 1


static func _audio(c: Controller) -> GameAudio:
	if c.hud == null or c.hud.get("main") == null:
		return null
	return c.hud.main.get("audio") as GameAudio


## Categoría de lo elegido: aldeano, tropa, edificio o ajeno (rival, recurso, animal suelto).
static func categoria(c: Controller, ids: Array[int]) -> String:
	var civiles := 0
	var tropas := 0
	var edificios := 0
	for id in ids:
		var e: SimEntity = c.sim.by_id.get(id)
		if e == null or e.owner != c.local:
			continue
		if e.is_building():
			edificios += 1
		elif e.fn == "civil":
			civiles += 1
		elif e.is_unit():
			tropas += 1
	if civiles + tropas + edificios == 0:
		return "ajeno"
	if tropas >= civiles and tropas > 0:
		return "tropa"
	return "aldeano" if civiles > 0 else "edificio"


## Función de la orden según la mayoría de las unidades elegidas: civil, a_pie, montado o asedio.
static func funcion(c: Controller) -> String:
	var n := {"civil": 0, "a_pie": 0, "montado": 0, "asedio": 0}
	for e in c.selected_entities():
		if e.owner != c.local or not e.is_unit():
			continue
		var f := "a_pie"
		if e.fn in ["civil", "ganado", "carga"]:
			f = "civil"
		elif e.fn == "asedio":
			f = "asedio"
		elif e.def.get("montado", false) or e.def.get("elefante", false) or e.fn == "explorador":
			f = "montado"
		n[f] += 1
	var mejor := "a_pie"
	for f: String in ["a_pie", "montado", "asedio", "civil"]:
		if n[f] > n[mejor]:
			mejor = f
	return mejor


# ---------------------------------------------------------------- ganchos del controlador

static func al_elegir(c: Controller, ids: Array[int]) -> void:
	if ids.is_empty():
		return
	var a := _audio(c)
	if a != null and a.elegir(categoria(c, ids)):
		_contar("elegir")


static func error(c: Controller) -> void:
	var a := _audio(c)
	if a != null and a.respuesta_ui("error", "ui/ui_error.ogg"):
		_contar("error")


static func orden(c: Controller) -> void:
	var a := _audio(c)
	if a != null and a.orden(funcion(c)):
		_contar("orden")


static func cimiento(c: Controller, pos: Vector3, tipo: String) -> void:
	var a := _audio(c)
	if a != null and a.respuesta_ui("cimiento", "ui/ui_cimiento.ogg"):
		_contar("cimiento")
	var tam: Variant = c.sim.dp(c.local).def_of(tipo).get("tam", [2, 2])
	var lado := float(maxi(int(tam[0]), int(tam[1]))) if tam is Array and tam.size() >= 2 else 2.0
	if c.view.polvo_cimiento(pos, lado):
		_contar("polvo")


static func blanco(c: Controller, t: SimEntity, color: Color) -> void:
	if c.view.destello(t, color):
		_contar("destello")


static func pulso(c: Controller, pos: Vector3) -> void:
	if c.view.pulso(pos):
		_contar("pulso")
