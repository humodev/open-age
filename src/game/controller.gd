class_name Controller
extends Node
## Traduce la entrada del jugador en comandos de la simulación (docs/07, "Controles").

signal selection_changed

const P := 1000
const O := SimEntity.Order
const SLOT_KEYS: Array[int] = [KEY_Q, KEY_W, KEY_E, KEY_R, KEY_A, KEY_S, KEY_D, KEY_F, KEY_Z, KEY_X, KEY_C, KEY_V]
const SLOT_LABELS: Array[String] = ["Q", "W", "E", "R", "A", "S", "D", "F", "Z", "X", "C", "V"]
const RES_LABEL := {"alimento": "alimento", "granja": "granjas", "madera": "madera", "piedra": "piedra", "riqueza": "riqueza", "*": "todos los recursos"}

const MundoColocacion := preload("res://src/game/ui/mundo_colocacion.gd") # --- mundo ---

const DESCS := {
	"casa": "Aumenta la población máxima.",
	"granja": "Alimento infinito y lento. Un aldeano por granja.",
	"deposito": "Depósito de los cuatro recursos. Ubicalo cerca de lo que recolectás.",
	"cuartel": "Entrena unidades de choque, distancia y línea.",
	"torre": "Defensa a distancia.",
	"centro": "Nuevo centro: aldeanos, depósito, población y defensa. Cuenta como hito.",
	"refugio": "Las unidades entran al edificio propio más cercano con lugar. Cada una suma una flecha.",
	"campana": "Todos los aldeanos cercanos se refugian en centros y torres.",
	"calma": "Los aldeanos salen y vuelven a su trabajo.",
	"expulsar": "Saca a todas las unidades alojadas.",
	"empalizada": "Cerco barato de troncos. Arrastrá para trazar una línea.",
	"puerta": "Deja pasar solo a tus unidades. Se puede poner sobre una empalizada propia.",
	"ariete": "Asedio: derriba edificios. No ataca unidades; vulnerable al choque.",
	"aldeano": "Recolecta, construye y repara la economía.",
	"explorador": "Rápido y de visión amplia. Descubre el mapa; pelea mal.",
	"guerrero": "Choque: rápido, vence a la distancia; pierde contra la línea.",
	"hondero": "Distancia: frágil, vence a la línea; pierde contra el choque.",
	"lancero": "Línea: lento y resistente, vence al choque; pierde contra la distancia.",
	"detener": "Detiene la orden actual.",
	"atacar": "Avanza y pelea con todo lo que encuentre (clic izquierdo en el destino).",
	# --- grilla ---
	"menu_economia": "Casas, granjas, depósitos, centro, mercado y los edificios económicos propios de tu pueblo.",
	"menu_militar": "Cuarteles y edificios militares propios; torres, cercos, puertas y caminos.",
	"volver": "Vuelve a la grilla del aldeano (también Esc o clic derecho sobre la grilla).",
	# --- fin grilla ---
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
var mouse_override := Vector2(-1, -1) # posición virtual para pruebas automáticas

var _ghost: MeshInstance3D
var _line_drag := false
var _line_start := Vector2i.ZERO
var _line_ghosts: Array[MeshInstance3D] = []
var _ghost_mat: StandardMaterial3D
var press_pos := Vector2.ZERO
var _pressing := false
var dragging := false
var _last_click_ms := 0
var _last_click_id := -1
var _idle_cycle := 0
var _last_group_key := -1
var _last_group_ms := 0
# --- mundo ---
var cola: RefCounted # órdenes en cola con mayúsculas (src/game/ui/mundo_cola.gd)
# --- fin mundo ---
# --- grilla ---
var submenu := "" # submenú abierto del aldeano: "", "economia" o "militar" (src/game/ui/grilla.gd)
# --- fin grilla ---
# --- cursores ---
var cursores: Node # cursores contextuales (src/game/ui/cursores.gd)
# --- fin cursores ---


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
		if e != null and e.alive and e.inside < 0 and (not e.is_unit() or view.fog_state(e) == 2):
			keep.append(id)
	if keep.size() != selection.size():
		_set_selection(keep, true)


func _set_selection(ids: Array[int], keep_menu: bool = false) -> void:
	# --- grilla --- (una selección nueva vuelve a la raíz de la grilla)
	if not keep_menu or ids.is_empty():
		submenu = Grilla.RAIZ
	# --- fin grilla ---
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
		if not e.is_unit() or e.inside >= 0:
			continue
		var v: Dictionary = view.visuals.get(e.id, {})
		if v.is_empty() or view.fog_state(e) < 2:
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
	if occ >= 0 and sim.by_id.has(occ) and view.fog_state(sim.by_id[occ]) > 0:
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
		# --- grilla --- (raíz: submenús, detener, refugio e hitos; dentro: edificios en casillas fijas)
		var slots := villager_slots()
		if submenu == Grilla.RAIZ:
			out.append({"slot": Grilla.fija("economia", 0), "id": "economia", "icon": "menu_economia", "kind": "submenu", "menu": Grilla.ECONOMIA, "name": "Construir: economía", "cost": {}, "desc": DESCS["menu_economia"], "locked": ""})
			out.append({"slot": Grilla.fija("militar", 1), "id": "militar", "icon": "menu_militar", "kind": "submenu", "menu": Grilla.MILITAR, "name": "Construir: militar y defensa", "cost": {}, "desc": DESCS["menu_militar"], "locked": ""})
			out.append({"slot": Grilla.fija("detener", 5), "id": "detener", "icon": "detener", "kind": "stop", "name": "Detener", "cost": {}, "desc": DESCS["detener"], "locked": ""})
			out.append({"slot": Grilla.fija("refugio", 7), "id": "refugio", "icon": "refugio", "kind": "garrison", "name": "Refugiarse", "cost": {}, "desc": DESCS["refugio"], "locked": ""})
		else:
			out.append({"slot": Grilla.fija("volver", 11), "id": "volver", "icon": "volver", "kind": "back", "name": "Volver", "cost": {}, "desc": DESCS["volver"], "locked": ""})
		# --- fin grilla ---
		for slot in slots:
			var type: String = slots[slot]
			var def: Dictionary = sim.dp(local).edificios[type]
			var cmd := {"slot": slot, "id": type, "icon": Glyphs.resolve(def, type), "kind": "build", "name": def["nombre"], "cost": sim.dp(local).cost_of(type, age), "desc": DESCS.get(type, def.get("desc", "")), "locked": ""}
			if age < def.get("edad_min", 1):
				cmd["locked"] = "Requiere edad %s" % Sim._roman(def["edad_min"])
			if sim.dp(local).is_hito(type):
				if age >= sim.dp(local).edades.size():
					cmd["locked"] = "Edad máxima alcanzada"
				else:
					cmd["name"] = "%s · avanzar a edad %s" % [def["nombre"], Sim._roman(age + 1)]
					cmd["desc"] = "%s\n%s\n%s" % [def.get("desc", ""), effects_text(def.get("efectos", [])), unlocks_text(age + 1)]
					if sim.hito_in_progress(local):
						cmd["locked"] = "Ya hay un hito en obra"
			out.append(cmd)
	elif first.is_unit() and first.def.has("despliega_en"):
		out.append({"slot": 0, "id": "armar", "icon": "centro", "kind": "unpack", "name": "Armar la corte aquí", "cost": {}, "desc": "La corte se asienta donde está: vuelve a ser la capital.", "locked": "", "unit": first.id})
	elif first.is_unit():
		out.append({"slot": Grilla.fija("atacar", 4), "id": "atacar", "icon": "atacar", "kind": "amove", "name": "Atacar en movimiento", "cost": {}, "desc": DESCS["atacar"], "locked": ""}) # --- grilla ---
		out.append({"slot": Grilla.fija("detener", 5), "id": "detener", "icon": "detener", "kind": "stop", "name": "Detener", "cost": {}, "desc": DESCS["detener"], "locked": ""}) # --- grilla ---
		out.append({"slot": Grilla.fija("refugio", 7), "id": "refugio", "icon": "refugio", "kind": "garrison", "name": "Refugiarse", "cost": {}, "desc": DESCS["refugio"], "locked": ""}) # --- grilla ---
	elif first.is_building() and first.built:
		var i := 0
		for type: String in first.def.get("produce", []):
			var udef: Dictionary = sim.dp(local).unidades[type]
			var cmd := {"slot": i, "id": type, "icon": Glyphs.resolve(udef, type), "kind": "train", "name": udef["nombre"], "cost": sim.dp(local).cost_of(type, age), "desc": DESCS.get(type, ""), "locked": "", "building": first.id}
			if age < udef.get("edad_min", 1):
				cmd["locked"] = "Requiere edad %s" % Sim._roman(udef["edad_min"])
			out.append(cmd)
			i += 1
		# Investigaciones: en cada ranura, la primera de la cadena que falta.
		var used := {}
		for tech: String in sim.dp(local).tecnologias:
			var t: Dictionary = sim.dp(local).tecnologias[tech]
			if t["edificio"] != first.type or used.has(t["ranura"]) or sim.players[local]["techs"].has(tech):
				continue
			used[t["ranura"]] = true
			var why := sim.research_block(local, tech)
			out.append({"slot": t["ranura"], "id": tech, "icon": t["icono"], "kind": "research", "name": t["nombre"], "cost": t["costo"], "desc": effects_text(t["efectos"]), "locked": why, "tech": true, "building": first.id})
		if first.capital or first.type == "centro":
			var on: bool = sim.players[local]["alarm"]
			out.append({"slot": 8, "id": "calma" if on else "campana", "icon": "calma" if on else "campana", "kind": "alarm", "name": "Toque de calma" if on else "Campana", "cost": {}, "desc": DESCS["calma" if on else "campana"], "locked": "", "on": not on})
		if first.def.get("mercado", false):
			var lot: int = sim.data.reglas["mercado"]["lote"]
			var fee: int = sim.data.reglas["mercado"]["comision_pct"]
			var kinds := ["alimento", "madera", "piedra"]
			for ki in kinds.size():
				var k: String = kinds[ki]
				var price := sim.trade_price(local, k)
				out.append({"slot": ki, "id": "vender_" + k, "icon": k, "kind": "trade", "op": "vender", "recurso": k, "building": first.id, "name": "Vender %d de %s → %d de riqueza" % [lot, Palette.RES_NAMES[k].to_lower(), price * (100 - fee) / 100], "cost": {k: lot}, "desc": "El precio baja con cada venta.", "locked": ""})
				out.append({"slot": 4 + ki, "id": "comprar_" + k, "icon": k, "kind": "trade", "op": "comprar", "recurso": k, "building": first.id, "name": "Comprar %d de %s" % [lot, Palette.RES_NAMES[k].to_lower()], "cost": {"riqueza": price}, "desc": "El precio sube con cada compra.", "locked": ""})
		if first.def.has("empaca_en"):
			out.append({"slot": 7, "id": "desarmar", "icon": "carga", "kind": "pack", "name": "Desarmar la corte", "cost": {}, "desc": "La corte se levanta y camina con su gente: viaja lenta y se vuelve a armar donde haga falta.", "locked": "" if first.queue.is_empty() else "Esperá que termine la cola", "building": first.id})
		if first.capital and sim.dp(local).has_mod("regalo_cumbi"):
			var rc: Dictionary = sim.dp(local).mod("regalo_cumbi")
			var why_c := ""
			if int(sim.players[local]["age"]) < int(rc.get("edad", 3)):
				why_c = "Desde la edad III"
			elif sim.mods.cumbi_target(local) == null:
				why_c = "No hay ingenio en tu mitad del mapa"
			elif int(sim.players[local]["res"].get(rc["recurso"], 0)) < int(rc["costo"]):
				why_c = "Hace falta %d de mit'a" % int(rc["costo"])
			out.append({"slot": 9, "id": "cumbi", "icon": "riqueza", "kind": "cumbi", "name": "Regalo de cumbi", "cost": {}, "desc": "Tela fina como regalo político: %d de mit'a por el ingenio de tu mitad del mapa. Cobrás su botín sin pelear y queda un tambo inca. Si lo destruyen, el ingenio vuelve a los 6 minutos." % int(rc["costo"]), "locked": why_c})
		if first.def.has("regimiento") and first.built:
			var rg: Dictionary = first.def["regimiento"]
			var why_r := ""
			if first.mode == "regimiento":
				why_r = "Ya está asignado a un regimiento"
			elif int(sim.players[local]["age"]) < int(rg.get("edad", 2)):
				why_r = "Desde la edad II"
			out.append({"slot": 10, "id": "regimiento", "icon": "jinete", "kind": "regimiento", "name": "Dar el gult a un regimiento" if first.mode == "" else "Gult de regimiento", "cost": {}, "desc": "El gult deja de pagar tributo y, a cambio, los jinetes que se entrenan a %d casillas o menos cuestan %d %% menos (hasta %d %% con varios gult). No tiene vuelta atrás." % [int(rg["radio"]) / 1000, int(rg["descuento_pct"]), int(rg["tope_pct"])], "locked": why_r, "building": first.id})
		if first.def.has("ganado") and first.built:
			var g: Dictionary = first.def["ganado"]
			var cap := sim.mods.corral_cap(first)
			var why := ""
			if first.feast_age == int(sim.players[local]["age"]):
				why = "Ya hubo kawiñ en este corral en esta edad"
			elif first.heads <= 1:
				why = "Hace falta más de una cabeza"
			elif sim.tick - first.last_combat < 100:
				why = "No se puede en combate"
			out.append({"slot": 10, "id": "kawin", "icon": "alimento", "kind": "kawin", "name": "Kawiñ: la fiesta (%d/%d cabezas)" % [first.heads, cap], "cost": {}, "desc": "Se come el rebaño salvo una cabeza: %d de alimento por cabeza. Después, %d s sin cría. Una vez por corral y por edad. Cada cabeza da %d de riqueza por minuto mientras viva." % [int(g["fiesta_alimento"]), int(g["fiesta_pausa_ms"]) / 1000, int(g["riqueza_por_cabeza"])], "locked": why, "building": first.id})
		var oficios: Dictionary = sim.dp(local).mod("oficios") if sim.dp(local).has_mod("oficios") else {}
		if int(oficios.get("puestos", {}).get(first.type, 0)) > 0:
			var stop := " (parados: bajo asedio)" if not first.crafts.is_empty() and sim.mods.craft_stopped(first) else ""
			out.append({"slot": 10, "id": "desalojar", "icon": "expulsar", "kind": "desalojar", "name": "Vaciar oficios (%d/%d)%s" % [first.crafts.size(), int(oficios["puestos"][first.type]), stop], "cost": {}, "desc": "La gente que trabaja en los oficios de este edificio (herrero, alfarero, cestero, tejedor de palma) sale a recolectar. Cada puesto da %d de riqueza por minuto mientras no haya asedio; los puestos se vuelven a llenar con la gente que llega." % int(oficios["por_min"]), "locked": "" if not first.crafts.is_empty() else "No hay nadie en los oficios", "building": first.id})
		if first.def.get("guarnicion", 0) > 0:
			out.append({"slot": 11, "id": "expulsar", "icon": "expulsar", "kind": "ungarrison", "name": "Expulsar guarnición", "cost": {}, "desc": DESCS["expulsar"], "locked": "" if not first.garrison.is_empty() else "No hay unidades alojadas"})
	return out


# --- grilla ---
## Edificios que muestra la grilla del aldeano: {casilla: tipo}. En la raíz, solo los hitos de la
## edad siguiente (Z economía, X militar); en un submenú, sus edificios en casillas fijas (Grilla).
## Con `menu` se pide un submenú sin abrirlo (pruebas).
func villager_slots(menu: String = "?") -> Dictionary:
	var which := submenu if menu == "?" else menu
	if which == Grilla.RAIZ:
		return Grilla.hitos(sim.dp(local), int(sim.players[local]["age"]))
	return Grilla.edificios(sim.dp(local), which)


## Abre un submenú del aldeano ("economia", "militar") o vuelve a la raíz ("").
func open_submenu(menu: String) -> void:
	submenu = menu
	if hud != null and hud.has_method("hide_tip"):
		hud.hide_tip()
# --- fin grilla ---


func run_command(cmd: Dictionary) -> void:
	if hud != null and hud.main.get("audio") != null:
		hud.main.audio.ui("clic" if cmd.get("locked", "") == "" else "error", -12.0)
	if cmd.get("locked", "") != "":
		hud_notify(cmd["locked"])
		return
	match cmd["kind"]:
		"build":
			if not sim.can_afford(local, cmd["cost"]):
				hud_notify(missing_text(cmd["cost"])) # --- grilla ---
				return
			mode = "place"
			place_type = cmd["id"]
			_ghost.mesh = view.building_mesh_for(local, place_type, sim.dp(local).edificios[place_type])
			_ghost.visible = true
			view.set_grid(true)
		"train":
			var shift := Input.is_key_pressed(KEY_SHIFT)
			for e in selected_entities():
				if e.is_building() and e.type == sim.by_id[cmd["building"]].type and e.owner == local:
					for k in (5 if shift else 1):
						sim.push_command({"t": "train", "player": local, "building": e.id, "type": cmd["id"]})
		"stop":
			# --- mundo ---
			if cola != null:
				cola.limpiar(_own_unit_ids())
			# --- fin mundo ---
			sim.push_command({"t": "stop", "player": local, "ids": _own_unit_ids()})
		"research":
			sim.push_command({"t": "research", "player": local, "building": cmd["building"], "tech": cmd["id"]})
		"garrison":
			sim.push_command({"t": "garrison", "player": local, "ids": _own_unit_ids(), "building": -1})
		"alarm":
			sim.push_command({"t": "alarm", "player": local, "on": cmd["on"]})
		"trade":
			sim.push_command({"t": "trade", "player": local, "building": cmd["building"], "recurso": cmd["recurso"], "op": cmd["op"]})
		"pack":
			sim.push_command({"t": "pack", "player": local, "building": cmd["building"]})
		"unpack":
			sim.push_command({"t": "unpack", "player": local, "unit": cmd["unit"]})
		"desalojar":
			sim.push_command({"t": "desalojar", "player": local, "building": cmd["building"]})
		"kawin":
			sim.push_command({"t": "kawin", "player": local, "building": cmd["building"]})
		"regimiento":
			sim.push_command({"t": "regimiento", "player": local, "building": cmd["building"]})
		"cumbi":
			sim.push_command({"t": "cumbi", "player": local})
		"ungarrison":
			for e in selected_entities():
				if e.is_building() and e.owner == local:
					sim.push_command({"t": "ungarrison", "player": local, "building": e.id})
		"amove":
			mode = "amove"
		# --- grilla ---
		"submenu":
			open_submenu(cmd["menu"])
		"back":
			open_submenu(Grilla.RAIZ)
		# --- fin grilla ---


func cancel_mode() -> void:
	mode = ""
	place_type = ""
	_ghost.visible = false
	_line_drag = false
	_show_line([])
	view.set_grid(false)
	Input.set_default_cursor_shape(Input.CURSOR_ARROW)


func hud_notify(msg: String, tipo: String = "decision") -> void:
	if hud != null:
		hud.notify(msg, -1.0, tipo) # --- avisos --- (tipo del aviso: decision o info)


# --- grilla ---
## "Faltan 40 de madera y 10 de piedra": qué falta para pagar un costo (P3).
func missing_text(cost: Dictionary) -> String:
	var res: Dictionary = sim.players[local]["res"]
	var parts: Array[String] = []
	for k in cost:
		var falta := int(cost[k]) - int(res.get(k, 0))
		if falta > 0:
			var rp: Dictionary = sim.dp(local).mod("recurso_propio") if sim.dp(local).has_mod("recurso_propio") else {}
			var nombre: String = Palette.RES_NAMES.get(k, rp.get("nombre", k) if rp.get("clave", "") == k else k)
			parts.append("%d de %s" % [falta, nombre.to_lower()])
	if parts.is_empty():
		return "Recursos insuficientes"
	return "Faltan " + (", ".join(parts.slice(0, -1)) + " y " + parts[-1] if parts.size() > 1 else parts[0])
# --- fin grilla ---


# ---------------------------------------------------------------- Entrada

func _process(_delta: float) -> void:
	if not enabled:
		return
	_prune()
	var m := mouse_pos()
	view.hovered = -1 if _over_hud(m) or dragging else pick(m)
	# --- cursores ---
	if cursores != null:
		cursores.call("usar", cursor_action(m))
	# --- fin cursores ---
	if mode == "place":
		var tam: Array = sim.dp(local).edificios[place_type]["tam"]
		var g := cam.ground_at(m)
		var tx := int(floor(g.x - tam[0] / 2.0 + 0.5))
		var ty := int(floor(g.z - tam[1] / 2.0 + 0.5))
		_ghost.position = Vector3(tx + tam[0] / 2.0, 0.02, ty + tam[1] / 2.0)
		var ok := sim.can_place(place_type, tx, ty, local) and sim.can_afford(local, sim.dp(local).cost_of(place_type, sim.players[local]["age"]))
		_ghost_mat.albedo_color = Color(0.5, 1.0, 0.6, 0.55) if ok else Color(1.0, 0.35, 0.3, 0.55)
		_ghost.set_meta("tile", Vector2i(tx, ty))
		if _line_drag:
			_ghost.visible = false
			_show_line(line_tiles(_line_start, Vector2i(tx, ty)))
		else:
			_ghost.visible = true


# --- cursores ---
## Qué haría un clic en este punto, como nombre de cursor (src/game/ui/cursores.gd):
## "" (flecha), "mover", "atacar", "recolectar_<recurso>", "construir", "reparar", "refugio",
## "depositar", "reunion" o "no". Repite las reglas de Sim._cmd_target sin tocar la simulación.
func cursor_action(m: Vector2) -> String:
	if _over_hud(m) or dragging:
		return ""
	if mode == "amove":
		return "atacar"
	if mode == "place":
		var tile: Vector2i = _ghost.get_meta("tile", Vector2i(-1, -1))
		return "construir" if sim.can_place(place_type, tile.x, tile.y, local) else "no"
	var sel := selected_entities()
	if sel.is_empty() or sel[0].owner != local:
		return ""
	var units: Array[SimEntity] = []
	for e in sel:
		if e.owner == local and e.is_unit():
			units.append(e)
	var t: SimEntity = sim.by_id.get(view.hovered)
	if units.is_empty():
		for e in sel:
			if e.is_building() and e.def.has("produce"):
				return "reunion"
		return ""
	if t == null or not t.alive or units.has(t):
		return "mover"
	var civil := false
	var hits := false
	for e in units:
		civil = civil or e.fn == "civil"
		hits = hits or not (t.is_unit() and e.def.get("solo_edificios", false))
	if sim.hostile(local, t):
		return "atacar" if hits else "no"
	if t.is_resource():
		return "recolectar_" + t.res_kind if civil else "mover"
	if t.is_building() and t.owner == local:
		if civil and not t.built:
			return "construir"
		if civil and t.hp < t.hp_max:
			return "reparar"
		if civil and t.def.get("fuente", "") != "":
			return "recolectar_" + String(t.def["fuente"])
		for e in units:
			if e.fn == "civil" and e.carry > 0 and t.built and (t.def.get("deposito", []) as Array).has(e.carry_res):
				return "depositar"
		if sim.garrison_cap(t) > 0:
			return "refugio" if t.garrison.size() < sim.garrison_cap(t) else "no"
	return "mover"
# --- fin cursores ---


func mouse_pos() -> Vector2:
	return mouse_override if mouse_override.x >= 0 else get_viewport().get_mouse_position()


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
	if event is InputEventMouseButton and not event.pressed and event.button_index == MOUSE_BUTTON_LEFT and _line_drag:
		_finish_line()
		get_viewport().set_input_as_handled()
		return
	# La suelta del arrastre puede ocurrir sobre la interfaz.
	if event is InputEventMouseButton and not event.pressed and event.button_index == MOUSE_BUTTON_LEFT and _pressing:
		_left_release(event.position)
		_pressing = false
		dragging = false
		get_viewport().set_input_as_handled()


func _mouse_button(mb: InputEventMouseButton) -> void:
	if mb.button_index == MOUSE_BUTTON_LEFT and mb.pressed:
		if mode == "place" and sim.dp(local).edificios[place_type].get("linea", false):
			_line_drag = true
			_line_start = _ghost.get_meta("tile", Vector2i.ZERO)
			return
		if mode == "place":
			_place()
			return
		if mode == "amove":
			var g := cam.ground_at(mb.position)
			# --- mundo ---
			if cola != null and Input.is_key_pressed(KEY_SHIFT):
				cola.orden_amove(_own_unit_ids(), g)
				view.add_marker(g, Palette.UI_BAD)
				return
			if cola != null:
				cola.limpiar(_own_unit_ids())
			# --- fin mundo ---
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
		if e.owner != local or e.inside >= 0:
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
		# --- mundo ---
		if cola != null and cola.orden_derecha(ids, t, g, Input.is_key_pressed(KEY_SHIFT)):
			view.add_marker(g, Color(Palette.UI_GOOD, 0.6))
			return
		# --- fin mundo ---
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
	var cost := sim.dp(local).cost_of(place_type, sim.players[local]["age"])
	if not sim.can_place(place_type, tile.x, tile.y, local):
		hud_notify(MundoColocacion.motivo(sim, local, place_type, tile.x, tile.y)) # --- mundo ---
		return
	if not sim.can_afford(local, cost):
		hud_notify(missing_text(cost)) # --- grilla ---
		cancel_mode()
		return
	var ids := []
	for e in selected_entities():
		if e.owner == local and e.fn == "civil":
			ids.append(e.id)
	sim.push_command({"t": "build", "player": local, "ids": ids, "type": place_type, "tx": tile.x, "ty": tile.y})
	view.add_marker(_ghost.position, Palette.UI_ACCENT)
	if not Input.is_key_pressed(KEY_SHIFT) or sim.dp(local).is_hito(place_type):
		cancel_mode()
		submenu = Grilla.RAIZ # --- grilla --- (colocado el edificio, la grilla vuelve a la raíz)


func _key(k: InputEventKey) -> void:
	var code := k.physical_keycode
	if code == KEY_ESCAPE:
		if mode != "":
			cancel_mode()
		elif submenu != Grilla.RAIZ and _has_villager(): # --- grilla ---
			open_submenu(Grilla.RAIZ)
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
			hud_notify("Grupo %d asignado" % n, "info")
		# --- avisos --- (Mayús + n suma la selección al grupo)
		elif k.shift_pressed and not selection.is_empty():
			var merged: Array = groups.get(n, []).duplicate()
			for id in selection:
				if not merged.has(id):
					merged.append(id)
			groups[n] = merged
			hud_notify("Grupo %d: %d unidades" % [n, merged.size()], "info")
		# --- fin avisos ---
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
	# --- avisos --- (Espacio: último ataque o suceso con lugar; Inicio: recorre los anteriores)
	if (code == KEY_SPACE or code == KEY_HOME) and hud != null and hud.get("avisos") != null:
		var at: Variant = hud.avisos.saltar(code == KEY_HOME)
		if at is Vector3:
			cam.look_at_point(at)
		else:
			hud_notify("No hay avisos con lugar para ir", "info")
		return
	# --- fin avisos ---
	if code == KEY_H:
		for e in sim.actives:
			if e.owner == local and e.is_building() and (e.capital or e.type == "centro"):
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
		hud_notify("No hay aldeanos inactivos", "info")
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


## Texto de efectos generado desde los datos: los números no se escriben a mano (D-008).
func effects_text(efectos: Array) -> String:
	var parts: Array[String] = []
	for ef: Dictionary in efectos:
		match ef["tipo"]:
			"tasa":
				parts.append("+%d%% de recolección de %s" % [ef["pct"], RES_LABEL.get(ef["recurso"], ef["recurso"])])
			"carga":
				parts.append("+%d de carga por viaje" % ef["n"])
			"ataque":
				parts.append("+%d de ataque militar" % ef["n"])
			"armadura":
				parts.append("+%d de armadura militar" % ef["n"])
			"vida_pct":
				parts.append("+%d%% de vida militar" % ef["pct"])
			"velocidad_pct":
				parts.append("+%d%% de velocidad militar" % ef["pct"])
			"edificio_vida_pct":
				parts.append("+%d%% de vida de los edificios" % ef["pct"])
			"edificio_ataque":
				parts.append("+%d de ataque de centros, torres e hitos" % ef["n"])
			"edificio_alcance":
				parts.append("+%.1f casillas de alcance de los edificios" % (ef["n"] / 1000.0))
	return " · ".join(parts)


## Qué se habilita al llegar a una edad, leído de los datos.
func unlocks_text(age: int) -> String:
	var names: Array[String] = []
	for k in sim.dp(local).unidades:
		if sim.dp(local).unidades[k].get("edad_min", 1) == age:
			names.append(sim.dp(local).unidades[k]["nombre"])
	for k in sim.dp(local).edificios:
		if sim.dp(local).edificios[k].get("edad_min", 1) == age:
			names.append(sim.dp(local).edificios[k]["nombre"])
	var techs := 0
	for k in sim.dp(local).tecnologias:
		if sim.dp(local).tecnologias[k].get("edad_min", 1) == age:
			techs += 1
	var bonus: int = sim.dp(local).edades[age - 1].get("bono_ataque", 0)
	var txt := "Edad %s habilita: %s" % [Sim._roman(age), ", ".join(names)] if not names.is_empty() else "Edad %s habilita:" % Sim._roman(age)
	if techs > 0:
		txt += "%s%d investigaciones" % [", " if not names.is_empty() else " ", techs]
	if bonus > 0:
		txt += ". Ataque militar +%d%%." % bonus
	return txt


## Casillas de una línea 4-conexa (sin huecos en diagonal por donde colarse).
static func line_tiles(a: Vector2i, b: Vector2i) -> Array:
	var out := [[a.x, a.y]]
	var x := a.x
	var y := a.y
	var dx := absi(b.x - a.x)
	var dy := -absi(b.y - a.y)
	var sx := 1 if a.x < b.x else -1
	var sy := 1 if a.y < b.y else -1
	var err := dx + dy
	while (x != b.x or y != b.y) and out.size() < 80:
		var e2 := 2 * err
		if e2 - dy > dx - e2:
			err += dy
			x += sx
		else:
			err += dx
			y += sy
		out.append([x, y])
	return out


func _show_line(tiles: Array) -> void:
	while _line_ghosts.size() < tiles.size():
		var g := MeshInstance3D.new()
		g.mesh = view.building_mesh_for(local, place_type, sim.dp(local).edificios[place_type])
		g.material_override = _ghost_mat.duplicate()
		g.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		view.add_child(g)
		_line_ghosts.append(g)
	var cost := sim.dp(local).cost_of(place_type, sim.players[local]["age"]) if place_type != "" else {}
	var budget: int = sim.players[local]["res"].get("madera", 0)
	for i in _line_ghosts.size():
		var g := _line_ghosts[i]
		g.visible = i < tiles.size()
		if not g.visible:
			continue
		var t: Array = tiles[i]
		g.position = Vector3(t[0] + 0.5, 0.02, t[1] + 0.5)
		budget -= int(cost.get("madera", 0))
		var ok := sim.can_place(place_type, t[0], t[1], local) and budget >= 0
		(g.material_override as StandardMaterial3D).albedo_color = Color(0.5, 1.0, 0.6, 0.55) if ok else Color(1.0, 0.35, 0.3, 0.55)


func _finish_line() -> void:
	_line_drag = false
	var tile: Vector2i = _ghost.get_meta("tile", _line_start)
	var tiles := line_tiles(_line_start, tile)
	var ids := []
	for e in selected_entities():
		if e.owner == local and e.fn == "civil":
			ids.append(e.id)
	sim.push_command({"t": "build_line", "player": local, "ids": ids, "type": place_type, "tiles": tiles})
	_show_line([])
	if not Input.is_key_pressed(KEY_SHIFT):
		cancel_mode()
		submenu = Grilla.RAIZ # --- grilla ---
