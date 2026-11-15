extends RefCounted
## Atajos de selección y cámara como AoE4 (proceso/23, parte B). El controlador los llama
## desde el teclado y la barra de recursos desde sus botones; acá no hay entrada, solo lógica.
##
##   .            siguiente aldeano ocioso (Mayús o Ctrl: todos)
##   ,            siguiente militar ocioso (Mayús o Ctrl: todos)
##   M            todos los militares
##   T            todos los del tipo de lo seleccionado, en todo el mapa (también doble clic en un edificio)
##   Tab          recorre los edificios de producción
##   Ctrl + F7…F9 guarda la cámara; F7…F9 vuelve (F1–F6 son los paneles y F10 la pausa)

const O := SimEntity.Order

static var _cfg: Dictionary = {}

var ctrl: Controller
var marcas := {} # tecla -> Vector3 (punto que mira la cámara)
var _cycle := {"aldeano": -1, "militar": -1, "produccion": -1}


func _init(c: Controller) -> void:
	ctrl = c


## data/interfaz.json → "ordenes" (teclas de los marcadores, tamaño de la cola global, bengalas).
static func cfg() -> Dictionary:
	if _cfg.is_empty():
		var path := "res://data/interfaz.json"
		var all: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(path)) if FileAccess.file_exists(path) else {}
		_cfg = all.get("ordenes", {})
		_cfg["frases_ia"] = all.get("frases_ia", {})
	return _cfg


## Aldeanos sin nada que hacer (afuera de los edificios).
func ociosos_aldeanos() -> Array[SimEntity]:
	var out: Array[SimEntity] = []
	for e in ctrl.sim.actives:
		if e.alive and e.owner == ctrl.local and e.fn == "civil" and e.inside < 0 and e.order == O.IDLE:
			out.append(e)
	return out


## Militares quietos sin orden (mantener posición no cuenta como ocioso: es una orden).
func ociosos_militares() -> Array[SimEntity]:
	var out: Array[SimEntity] = []
	for e in ctrl.sim.actives:
		if e.alive and e.owner == ctrl.local and e.is_military() and e.inside < 0 and e.order == O.IDLE:
			out.append(e)
	return out


## Siguiente ocioso (centra la cámara) o todos. `militar`: militares en vez de aldeanos.
func ocioso(militar: bool, todos: bool) -> void:
	var list := ociosos_militares() if militar else ociosos_aldeanos()
	if list.is_empty():
		ctrl.hud_notify("No hay %s ociosos" % ("militares" if militar else "aldeanos"), "info")
		return
	var ids: Array[int] = []
	if todos:
		for e in list:
			ids.append(e.id)
	else:
		var k := "militar" if militar else "aldeano"
		_cycle[k] = (int(_cycle[k]) + 1) % list.size()
		ids.append(list[_cycle[k]].id)
	ctrl.select_ids(ids)
	ctrl.center_on_selection()


func todos_militares() -> void:
	var ids: Array[int] = []
	for e in ctrl.sim.actives:
		if e.alive and e.owner == ctrl.local and e.is_military() and e.inside < 0:
			ids.append(e.id)
	if ids.is_empty():
		ctrl.hud_notify("No tenés militares", "info")
		return
	ctrl.select_ids(ids)


## Todos los del tipo de lo seleccionado, en todo el mapa (edificios terminados o unidades).
func todos_del_tipo(type: String = "") -> void:
	if type == "":
		var sel := ctrl.selected_entities()
		if sel.is_empty() or sel[0].owner != ctrl.local:
			return
		type = sel[0].type
	var ids: Array[int] = []
	for e in ctrl.sim.actives:
		if e.alive and e.owner == ctrl.local and e.type == type and e.inside < 0:
			ids.append(e.id)
	ctrl.select_ids(ids)


## Edificios propios que entrenan, en orden de id.
func produccion() -> Array[SimEntity]:
	var out: Array[SimEntity] = []
	for e in ctrl.sim.actives:
		if e.alive and e.owner == ctrl.local and e.is_building() and e.built and not (e.def.get("produce", []) as Array).is_empty():
			out.append(e)
	return out


func recorrer_produccion() -> void:
	var list := produccion()
	if list.is_empty():
		return
	_cycle["produccion"] = (int(_cycle["produccion"]) + 1) % list.size()
	ctrl.select_ids([list[_cycle["produccion"]].id] as Array[int])
	ctrl.center_on_selection()


## Marcador de cámara: guardar (Ctrl) o ir.
func marca(tecla: String, guardar: bool) -> void:
	if guardar:
		marcas[tecla] = ctrl.cam.focus
		ctrl.hud_notify("Cámara guardada en %s" % tecla, "info")
	elif marcas.has(tecla):
		ctrl.cam.look_at_point(marcas[tecla])
	else:
		ctrl.hud_notify("%s no tiene cámara guardada (Ctrl + %s la guarda)" % [tecla, tecla], "info")


## Aldeanos que trabajan un recurso (Mayús + clic en el recurso de la barra).
func trabajando(kind: String) -> void:
	var ids: Array[int] = []
	for e in ctrl.sim.actives:
		if e.alive and e.owner == ctrl.local and e.fn == "civil" and e.inside < 0 and (e.order == O.GATHER or e.order == O.RETURN) and e.gather_kind == kind:
			ids.append(e.id)
	if not ids.is_empty():
		ctrl.select_ids(ids)
