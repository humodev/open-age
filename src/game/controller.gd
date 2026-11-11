class_name Controller
extends Node
## Traduce la entrada del jugador en comandos de la simulación (docs/07, "Controles").

signal selection_changed

const P := 1000
const O := SimEntity.Order
const SLOT_KEYS: Array[int] = [KEY_Q, KEY_W, KEY_E, KEY_R, KEY_A, KEY_S, KEY_D, KEY_F, KEY_Z, KEY_X, KEY_C, KEY_V]
const SLOT_LABELS: Array[String] = ["Q", "W", "E", "R", "A", "S", "D", "F", "Z", "X", "C", "V"]
const VILLAGER_BUILDS := {0: "casa", 1: "granja", 2: "deposito", 3: "cuartel", 4: "torre", 6: "centro", 7: "hito"}

const DESCS := {
	"casa": "Aumenta la población máxima.",
	"granja": "Alimento infinito y lento. Un aldeano por granja.",
	"deposito": "Depósito de los cuatro recursos. Ubicalo cerca de lo que recolectás.",
	"cuartel": "Entrena unidades de choque, distancia y línea.",
	"torre": "Defensa a distancia.",
	"centro": "Nuevo centro: aldeanos, depósito, población y defensa. Cuenta como hito.",
	"hito": "Al terminarse, avanza de edad. Cuenta para la victoria.",
	"aldeano": "Recolecta, construye y repara la economía.",
	"guerrero": "Choque: rápido, vence a la distancia; pierde contra la línea.",
	"hondero": "Distancia: frágil, vence a la línea; pierde contra el choque.",
	"lancero": "Línea: lento y resistente, vence al choque; pierde contra la distancia.",
	"detener": "Detiene la orden actual.",
	"atacar": "Avanza y pelea con todo lo que encuentre (clic izquierdo en el destino).",
}

var sim: Sim
var view: WorldView
var cam: RtsCamera
var local: int
var hud: Control # HUD (zona que bloquea clics en el mapa)
var selection: Array[int] = []
var mode := "" # "", "place", "amove"
var place_type := ""
var groups := {}
var enabled := true

var _ghost: MeshInstance3D
var _ghost_mat: StandardMaterial3D
var press_pos := Vector2.ZERO
var _pressing := false
var dragging := false
var _last_click_ms := 0
var _last_click_id := -1
var _idle_cycle := 0
var _last_group_key := -1
var _last_group_ms := 0


func setup(s: Sim, v: WorldView, c: RtsCamera, local_player: int) -> void:
	sim = s
	view = v
	cam = c
	local = local_player
	_ghost = MeshInstance3D.new()
	_ghost_mat = StandardMaterial3D.new()
	_ghost_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_ghost_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_ghost.material_override = _ghost_mat
	_ghost.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_ghost.visible = false
	view.add_child(_ghost)


# ---------------------------------------------------------------- Consultas

func selected_entities() -> Array[SimEntity]:
	var out: Array[SimEntity] = []
	for id in selection:
		var e: SimEntity = sim.by_id.get(id)
		if e != null and e.alive:
			out.append(e)
	return out


func _prune() -> void:
	var keep: Array[int] = []
	for id in selection:
		var e: SimEntity = sim.by_id.get(id)
		if e != null and e.alive:
			keep.append(id)
	if keep.size() != selection.size():
		_set_selection(keep)


func _set_selection(ids: Array[int]) -> void:
	selection = ids
	view.selected.clear()
	for id in ids:
		view.selected[id] = true
	if mode == "place" and not _has_villager():
		cancel_mode()
	selection_changed.emit()


func _has_villager() -> bool:
	for e in selected_entities():
		if e.owner == local and e.fn == "civil":
			return true
	return false


func _own_unit_ids() -> Array:
	var ids := []
	for e in selected_entities():
		if e.owner == local and e.is_unit():
			ids.append(e.id)
	return ids


func pick(screen: Vector2) -> int:
	var best := -1
	var best_d := 26.0 * 40.0 / cam.zoom
	for e in sim.actives:
		if not e.is_unit():
			continue
		var v: Dictionary = view.visuals.get(e.id, {})
		if v.is_empty():
			continue
		var wp: Vector3 = (v["node"] as Node3D).position + Vector3(0, 0.45, 0)
		if cam.cam.is_position_behind(wp):
			continue
		var d := cam.cam.unproject_position(wp).distance_to(screen)
		if d < best_d:
			best = e.id
			best_d = d
	if best >= 0:
		return best
	var g := cam.ground_at(screen)
	var occ := sim.map.occupant(int(floor(g.x)), int(floor(g.z)))
	if occ >= 0 and sim.by_id.has(occ):
		return occ
	return -1


# ---------------------------------------------------------------- Comandos de la grilla

## Lista de comandos de la selección actual (docs/07, grilla 4×3).
func commands() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var sel := selected_entities()
	if sel.is_empty() or sel[0].owner != local:
		return out
	var p: Dictionary = sim.players[local]
	var age: int = p["age"]
	var first := sel[0]
	if _has_villager():
		for slot in VILLAGER_BUILDS:
			var type: String = VILLAGER_BUILDS[slot]
			var def: Dictionary = sim.data.edificios[type]
			var cmd := {"slot": slot, "id": type, "icon": type, "kind": "build", "name": def["nombre"], "cost": sim.data.cost_of(type, age), "desc": DESCS.get(type, ""), "locked": ""}
			if age < def.get("edad_min", 1):
				cmd["locked"] = "Requiere edad %s" % Sim._roman(def["edad_min"])
			if type == "hito":
				if age >= sim.data.edades.size():
					cmd["locked"] = "Edad máxima alcanzada"
					cmd["name"] = "Hito"
				else:
					cmd["name"] = "Hito: avanzar a edad %s · %s" % [Sim._roman(age + 1), sim.data.edades[age]["nombre"]]
					if sim.hito_in_progress(local):
						cmd["locked"] = "Ya hay un hito en obra"
			out.append(cmd)
		out.append({"slot": 5, "id": "detener", "icon": "detener", "kind": "stop", "name": "Detener", "cost": {}, "desc": DESCS["detener"], "locked": ""})
	elif first.is_unit():
		out.append({"slot": 4, "id": "atacar", "icon": "atacar", "kind": "amove", "name": "Atacar en movimiento", "cost": {}, "desc": DESCS["atacar"], "locked": ""})
		out.append({"slot": 5, "id": "detener", "icon": "detener", "kind": "stop", "name": "Detener", "cost": {}, "desc": DESCS["detener"], "locked": ""})
	elif first.is_building() and first.built:
		var i := 0
		for type: String in first.def.get("produce", []):
			var udef: Dictionary = sim.data.unidades[type]
			var cmd := {"slot": i, "id": type, "icon": type, "kind": "train", "name": udef["nombre"], "cost": sim.data.cost_of(type, age), "desc": DESCS.get(type, ""), "locked": "", "building": first.id}
			if age < udef.get("edad_min", 1):
				cmd["locked"] = "Requiere edad %s" % Sim._roman(udef["edad_min"])
			out.append(cmd)
			i += 1
	return out


func run_command(cmd: Dictionary) -> void:
	if cmd.get("locked", "") != "":
		hud_notify(cmd["locked"])
		return
	match cmd["kind"]:
		"build":
			if not sim.can_afford(local, cmd["cost"]):
				hud_notify("Recursos insuficientes")
				return
			mode = "place"
			place_type = cmd["id"]
			_ghost.mesh = Meshes.building_mesh(place_type, Palette.team(local))
			_ghost.visible = true
			view.set_grid(true)
		"train":
			var shift := Input.is_key_pressed(KEY_SHIFT)
			for e in selected_entities():
				if e.is_building() and e.type == sim.by_id[cmd["building"]].type and e.owner == local:
					for k in (5 if shift else 1):
						sim.push_command({"t": "train", "player": local, "building": e.id, "type": cmd["id"]})
		"stop":
			sim.push_command({"t": "stop", "player": local, "ids": _own_unit_ids()})
		"amove":
			mode = "amove"
			Input.set_default_cursor_shape(Input.CURSOR_CROSS)


func cancel_mode() -> void:
	mode = ""
	place_type = ""
	_ghost.visible = false
	view.set_grid(false)
	Input.set_default_cursor_shape(Input.CURSOR_ARROW)


func hud_notify(msg: String) -> void:
	if hud != null:
		hud.notify(msg)


# ---------------------------------------------------------------- Entrada

func _process(_delta: float) -> void:
	if not enabled:
		return
	_prune()
	var m := get_viewport().get_mouse_position()
	view.hovered = -1 if _over_hud(m) or dragging else pick(m)
	if mode == "place":
		var tam: Array = sim.data.edificios[place_type]["tam"]
		var g := cam.ground_at(m)
		var tx := int(floor(g.x - tam[0] / 2.0 + 0.5))
		var ty := int(floor(g.z - tam[1] / 2.0 + 0.5))
		_ghost.position = Vector3(tx + tam[0] / 2.0, 0.02, ty + tam[1] / 2.0)
		var ok := sim.can_place(place_type, tx, ty) and sim.can_afford(local, sim.data.cost_of(place_type, sim.players[local]["age"]))
		_ghost_mat.albedo_color = Color(0.5, 1.0, 0.6, 0.55) if ok else Color(1.0, 0.35, 0.3, 0.55)
		_ghost.set_meta("tile", Vector2i(tx, ty))


func _over_hud(m: Vector2) -> bool:
	return hud != null and hud.blocks(m)


func _unhandled_input(event: InputEvent) -> void:
	if not enabled:
		return
	if event is InputEventMouseButton:
		_mouse_button(event as InputEventMouseButton)
	elif event is InputEventMouseMotion and _pressing:
		if (event as InputEventMouseMotion).position.distance_to(press_pos) > 6:
			dragging = true
	elif event is InputEventKey and event.pressed and not event.echo:
		_key(event as InputEventKey)


func _input(event: InputEvent) -> void:
	# La suelta del arrastre puede ocurrir sobre la interfaz.
	if event is InputEventMouseButton and not event.pressed and event.button_index == MOUSE_BUTTON_LEFT and _pressing:
		_left_release(event.position)
		_pressing = false
		dragging = false
		get_viewport().set_input_as_handled()


func _mouse_button(mb: InputEventMouseButton) -> void:
	if mb.button_index == MOUSE_BUTTON_LEFT and mb.pressed:
		if mode == "place":
			_place()
			return
		if mode == "amove":
			var g := cam.ground_at(mb.position)
			sim.push_command({"t": "move", "player": local, "ids": _own_unit_ids(), "x": int(g.x * P), "y": int(g.z * P), "amove": true})
			view.add_marker(g, Palette.UI_BAD)
			if not Input.is_key_pressed(KEY_SHIFT):
				cancel_mode()
			return
		_pressing = true
		dragging = false
		press_pos = mb.position
	elif mb.button_index == MOUSE_BUTTON_RIGHT and mb.pressed:
		if mode != "":
			cancel_mode()
			return
		_right_click(mb.position)


func _left_release(pos: Vector2) -> void:
	var shift := Input.is_key_pressed(KEY_SHIFT)
	if dragging:
		_box_select(Rect2(press_pos, pos - press_pos).abs(), shift)
		return
	var id := pick(pos)
	var now := Time.get_ticks_msec()
	if id >= 0 and id == _last_click_id and now - _last_click_ms < 350:
		_select_same_type_on_screen(id)
		_last_click_ms = 0
		return
	_last_click_id = id
	_last_click_ms = now
	if id < 0:
		if not shift:
			_set_selection([] as Array[int])
		return
	var e: SimEntity = sim.by_id[id]
	if shift and e.owner == local and not selection.is_empty():
		var ids := selection.duplicate()
		if ids.has(id):
			ids.erase(id)
		else:
			ids.append(id)
		_set_selection(ids)
	else:
		_set_selection([id] as Array[int])


func _box_select(r: Rect2, add: bool) -> void:
	var units: Array[int] = []
	var buildings: Array[int] = []
	for e in sim.actives:
		if e.owner != local:
			continue
		var v: Dictionary = view.visuals.get(e.id, {})
		if v.is_empty():
			continue
		var wp: Vector3 = (v["node"] as Node3D).position + Vector3(0, 0.3, 0)
		if cam.cam.is_position_behind(wp):
			continue
		if r.grow(6).has_point(cam.cam.unproject_position(wp)):
			(units if e.is_unit() else buildings).append(e.id)
	var ids: Array[int] = units if not units.is_empty() else buildings
	if add:
		var merged := selection.duplicate()
		for id in ids:
			if not merged.has(id):
				merged.append(id)
		ids = merged
	_set_selection(ids)


func _select_same_type_on_screen(id: int) -> void:
	var src: SimEntity = sim.by_id.get(id)
	if src == null:
		return
	var size := get_viewport().get_visible_rect().size
	var ids: Array[int] = []
	for e in sim.actives:
		if e.owner != src.owner or e.type != src.type:
			continue
		var wp := WorldView.to_world(e.x, e.y)
		if cam.cam.is_position_behind(wp):
			continue
		var sp := cam.cam.unproject_position(wp)
		if Rect2(Vector2.ZERO, size).has_point(sp):
			ids.append(e.id)
	if src.owner != local:
		ids = [id] as Array[int]
	_set_selection(ids)


func _right_click(pos: Vector2) -> void:
	var sel := selected_entities()
	if sel.is_empty() or sel[0].owner != local:
		return
	var g := cam.ground_at(pos)
	var target := pick(pos)
	var ids := _own_unit_ids()
	if not ids.is_empty():
		var t: SimEntity = sim.by_id.get(target)
		if t != null and t.id not in ids and not (t.is_unit() and t.owner == local):
			sim.push_command({"t": "target", "player": local, "ids": ids, "target": t.id})
			var col := Palette.UI_BAD if t.owner >= 0 and t.owner != local else Palette.UI_ACCENT
			view.add_marker(WorldView.to_world(t.x, t.y), col)
		else:
			sim.push_command({"t": "move", "player": local, "ids": ids, "x": int(g.x * P), "y": int(g.z * P)})
			view.add_marker(g, Palette.UI_GOOD)
		return
	# Edificios: punto de reunión.
	for e in sel:
		if e.is_building() and e.def.has("produce"):
			sim.push_command({"t": "rally", "player": local, "building": e.id, "x": int(g.x * P), "y": int(g.z * P), "target": target})
	view.add_marker(g, Palette.UI_ACCENT)


func _place() -> void:
	var tile: Vector2i = _ghost.get_meta("tile", Vector2i(-1, -1))
	var cost := sim.data.cost_of(place_type, sim.players[local]["age"])
	if not sim.can_place(place_type, tile.x, tile.y):
		hud_notify("No se puede construir ahí")
		return
	if not sim.can_afford(local, cost):
		hud_notify("Recursos insuficientes")
		cancel_mode()
		return
	var ids := []
	for e in selected_entities():
		if e.owner == local and e.fn == "civil":
			ids.append(e.id)
	sim.push_command({"t": "build", "player": local, "ids": ids, "type": place_type, "tx": tile.x, "ty": tile.y})
	view.add_marker(_ghost.position, Palette.UI_ACCENT)
	if not Input.is_key_pressed(KEY_SHIFT) or place_type == "hito":
		cancel_mode()


func _key(k: InputEventKey) -> void:
	var code := k.physical_keycode
	if code == KEY_ESCAPE:
		if mode != "":
			cancel_mode()
		elif not selection.is_empty():
			_set_selection([] as Array[int])
		elif hud != null:
			hud.toggle_menu()
		get_viewport().set_input_as_handled()
		return
	if code >= KEY_1 and code <= KEY_9:
		var n := code - KEY_0
		if k.ctrl_pressed:
			groups[n] = selection.duplicate()
			hud_notify("Grupo %d asignado" % n)
		elif groups.has(n):
			var ids: Array[int] = []
			for id in groups[n]:
				if sim.by_id.has(id):
					ids.append(id)
			_set_selection(ids)
			var now := Time.get_ticks_msec()
			if _last_group_key == n and now - _last_group_ms < 350:
				center_on_selection()
			_last_group_key = n
			_last_group_ms = now
		return
	if code == KEY_PERIOD:
		_select_idle_villager()
		return
	if code == KEY_H:
		for e in sim.actives:
			if e.owner == local and e.type == "centro":
				_set_selection([e.id] as Array[int])
				center_on_selection()
				return
		return
	if code == KEY_DELETE:
		var ids := []
		for e in selected_entities():
			if e.owner == local:
				ids.append(e.id)
		sim.push_command({"t": "delete", "player": local, "ids": ids})
		return
	var slot := SLOT_KEYS.find(code)
	if slot >= 0:
		for cmd in commands():
			if cmd["slot"] == slot:
				run_command(cmd)
				return


func _select_idle_villager() -> void:
	var idle: Array[SimEntity] = []
	for e in sim.actives:
		if e.owner == local and e.fn == "civil" and e.order == O.IDLE:
			idle.append(e)
	if idle.is_empty():
		hud_notify("No hay aldeanos inactivos")
		return
	_idle_cycle = (_idle_cycle + 1) % idle.size()
	_set_selection([idle[_idle_cycle].id] as Array[int])
	center_on_selection()


func center_on_selection() -> void:
	var sel := selected_entities()
	if sel.is_empty():
		return
	var c := Vector3.ZERO
	for e in sel:
		c += WorldView.to_world(e.x, e.y)
	cam.look_at_point(c / sel.size())


func select_ids(ids: Array[int]) -> void:
	_set_selection(ids)
