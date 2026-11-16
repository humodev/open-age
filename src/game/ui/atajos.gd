extends RefCounted
## Atajos de selección y cámara como AoE4 (proceso/23, parte B). El controlador los llama
## desde el teclado y la barra de recursos desde sus botones; acá no hay entrada, solo lógica.
##
##   .            siguiente aldeano ocioso (Mayús o Ctrl: todos)
##   ,            siguiente militar ocioso (Mayús o Ctrl: todos)
##   M            todos los militares (centra la cámara en el grueso)
##   H            el centro siguiente (dos toques o Mayús + H: centra la cámara)
##   T            todos los del tipo de lo seleccionado, en todo el mapa (también doble clic en un edificio)
##   Tab          recorre los edificios de producción
##   Alt + 1…8    vuelve a un marcador de cámara; Ctrl + Alt + 1…8 lo guarda (Ctrl + número
##                es de los grupos de control, como en AoE4). F7…F9 son atajos de los
##                marcadores 1 a 3 (Ctrl + F guarda); F1–F6 son los paneles y F10 la pausa.
##   B            la campana del centro, desde cualquier lado (otra vez: toque de calma)
##   N            todos los aldeanos
##   P            todos los edificios de producción militar (como AoE4)
##   Todas estas son las de fábrica: se reasignan en Opciones → Teclas (src/game/ui/teclas.gd).

const O := SimEntity.Order

static var _cfg: Dictionary = {}

var ctrl: Controller
var marcas := {} # marcador (1…8) -> Vector3 (punto que mira la cámara)
var _cycle := {"aldeano": -1, "militar": -1, "produccion": -1, "centro": -1}
var _centro_ms := -100000 # --- veterano ronda 4 --- último toque de H (doble toque: centra)


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
	centrar_en_grueso() # --- veterano ronda 4 --- (M lleva la cámara, como «,» y el doble toque del grupo)


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


# --- veterano ronda 4 ---
## Centra la cámara en la unidad elegida más cercana al promedio: con el ejército partido en
## dos, el promedio puede caer en el medio de la nada; así se mira a tropa de verdad.
func centrar_en_grueso() -> void:
	var sel := ctrl.selected_entities()
	if sel.is_empty():
		return
	var c := Vector2.ZERO
	for e in sel:
		c += Vector2(e.x, e.y)
	c /= sel.size()
	var mejor: SimEntity = sel[0]
	for e in sel:
		if Vector2(e.x, e.y).distance_squared_to(c) < Vector2(mejor.x, mejor.y).distance_squared_to(c):
			mejor = e
	ctrl.cam.look_at_point(WorldView.to_world(mejor.x, mejor.y))


## Centros propios (la capital primero, después por id): lo que recorre H.
func centros() -> Array[SimEntity]:
	var out: Array[SimEntity] = []
	for e in ctrl.sim.actives:
		if e.alive and e.owner == ctrl.local and e.is_building() and (e.capital or e.type == "centro"):
			if e.capital:
				out.push_front(e)
			else:
				out.append(e)
	return out


## H: el centro siguiente (como en AoE4). Dos toques seguidos o Mayús + H centran la cámara;
## un toque solo cambia la selección, para encolar aldeanos sin perder de vista la pelea.
func recorrer_centros(centrar: bool) -> void:
	var list := centros()
	if list.is_empty():
		ctrl.hud_notify("No tenés centros", "info")
		return
	var now := Time.get_ticks_msec()
	var doble := now - _centro_ms < int(Teclas.cfg().get("doble_toque_ms", 350))
	_centro_ms = now
	if doble:
		_centro_ms = -100000
		var ya := ctrl.selected_entities()
		if ya.size() == 1 and list.has(ya[0]):
			ctrl.center_on_selection()
			return
	var actual := -1
	var sel := ctrl.selected_entities()
	if sel.size() == 1:
		actual = list.find(sel[0])
	_cycle["centro"] = (actual + 1) % list.size() if actual >= 0 else 0
	ctrl.select_ids([list[_cycle["centro"]].id] as Array[int])
	if centrar:
		ctrl.center_on_selection()
# --- fin veterano ronda 4 ---


# --- veterano ronda 5 --- atajos globales (proceso/22-testers/ronda-5, veterano, punto 2)
## Todos los aldeanos propios (afuera de los edificios), trabajen o no.
func todos_aldeanos() -> void:
	var ids: Array[int] = []
	for e in ctrl.sim.actives:
		if e.alive and e.owner == ctrl.local and e.fn == "civil" and e.inside < 0:
			ids.append(e.id)
	if ids.is_empty():
		ctrl.hud_notify("No tenés aldeanos", "info")
		return
	ctrl.select_ids(ids)


## Edificios terminados que entrenan tropa (sin los centros, que entrenan aldeanos): con todos
## elegidos, la grilla encola en el de cola más corta, y Mayús reparte cinco.
func produccion_militar() -> Array[SimEntity]:
	var out: Array[SimEntity] = []
	for e in produccion():
		if not (e.def.get("produce", []) as Array).has("aldeano") and not e.capital:
			out.append(e)
	return out


func todos_produccion() -> void:
	var list := produccion_militar()
	if list.is_empty():
		ctrl.hud_notify("No tenés edificios de producción militar", "info")
		return
	var ids: Array[int] = []
	for e in list:
		ids.append(e.id)
	ctrl.select_ids(ids)


## La campana sin elegir el centro: los aldeanos cercanos se refugian; otra vez, toque de calma.
func campana() -> void:
	if centros().is_empty():
		ctrl.hud_notify("Sin centro no hay campana", "info")
		return
	var on: bool = not bool(ctrl.sim.players[ctrl.local].get("alarm", false))
	ctrl.sim.push_command({"t": "alarm", "player": ctrl.local, "on": on})
	if not on: # al sonar, avisa el HUD con el suceso de la simulación («¡Campana!…»)
		ctrl.hud_notify("Toque de calma: vuelven al trabajo", "info")
# --- fin veterano ronda 5 ---


## Marcador de cámara `n` (1…8): guardar (Ctrl) o ir.
func marca(n: int, guardar: bool) -> void:
	if guardar:
		marcas[n] = ctrl.cam.focus
		ctrl.hud_notify("Cámara guardada en el marcador %d (Alt + %d vuelve)" % [n, n], "info")
	elif marcas.has(n):
		ctrl.cam.look_at_point(marcas[n])
	else:
		ctrl.hud_notify("El marcador %d está vacío (Ctrl + Alt + %d guarda la cámara)" % [n, n], "info")


## Aldeanos que trabajan un recurso (Mayús + clic en el recurso de la barra).
func trabajando(kind: String) -> void:
	var ids: Array[int] = []
	for e in ctrl.sim.actives:
		if e.alive and e.owner == ctrl.local and e.fn == "civil" and e.inside < 0 and (e.order == O.GATHER or e.order == O.RETURN) and e.gather_kind == kind:
			ids.append(e.id)
	if not ids.is_empty():
		ctrl.select_ids(ids)
