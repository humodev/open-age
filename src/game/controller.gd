class_name Controller
extends Node
## Traduce la entrada del jugador en comandos de la simulación (docs/07, "Controles").

signal selection_changed

const P := 1000
const O := SimEntity.Order
const SLOT_KEYS: Array[int] = [KEY_Q, KEY_W, KEY_E, KEY_R, KEY_A, KEY_S, KEY_D, KEY_F, KEY_Z, KEY_X, KEY_C, KEY_V]
const SLOT_LABELS: Array[String] = ["Q", "W", "E", "R", "A", "S", "D", "F", "Z", "X", "C", "V"] # de fábrica: las de verdad, etiqueta()
const RES_LABEL := {"alimento": "alimento", "granja": "granjas", "madera": "madera", "piedra": "piedra", "riqueza": "riqueza", "*": "todos los recursos"}

const MundoColocacion := preload("res://src/game/ui/mundo_colocacion.gd") # --- mundo ---
const Atajos := preload("res://src/game/ui/atajos.gd") # --- órdenes ---
const FORMAS := {"form_bloque": ["bloque", "Bloque"], "form_linea": ["linea", "Línea"], "form_abierta": ["abierta", "Abierta"], "form_columna": ["columna", "Columna"]}

const DESCS := {
	"casa": "Aumenta la población máxima.",
	"granja": "Alimento infinito y lento. Un aldeano por granja.",
	"deposito": "Depósito de los cuatro recursos. Ubicalo cerca de lo que recolectás.",
	"torre": "Defensa a distancia.",
	"centro": "Nuevo centro: aldeanos, depósito, población y defensa. Cuenta como hito.",
	"refugio": "Las unidades entran al edificio propio más cercano con lugar. Cada una suma una flecha.",
	"campana": "Todos los aldeanos cercanos se refugian en centros y torres.",
	"calma": "Los aldeanos salen y vuelven a su trabajo.",
	"expulsar": "Saca a todas las unidades alojadas.",
	"empalizada": "Cerco barato de troncos. Arrastrá para trazar una línea.",
	"puerta": "Deja pasar solo a tus unidades. Se puede poner sobre una empalizada propia.",
	"muralla": "Muro de piedra: mucha vida y armadura; solo el asedio lo rompe. Caro y de obra lenta. Arrastrá para trazar; encima de la empalizada, la refuerza.",
	"puerta_piedra": "Puerta de piedra: deja pasar solo a tus unidades. Va sobre un tramo propio o sobre la puerta de madera.",
	"torre_muralla": "Torre de piedra que dispara. Se levanta solo encima de un tramo propio de muralla.",
	"ariete": "Asedio: derriba edificios. No ataca unidades; vulnerable al choque.",
	"aldeano": "Recolecta, construye y repara la economía.",
	"explorador": "Rápido y de visión amplia. Descubre el mapa; pelea mal.",
	"guerrero": "Choque: rápido, vence a la distancia; pierde contra la línea.",
	"hondero": "Distancia: frágil, vence a la línea; pierde contra el choque.",
	"lancero": "Línea: lento y resistente, vence al choque; pierde contra la distancia.",
	"detener": "Detiene la orden actual.",
	"atacar": "Avanza y pelea con todo lo que encuentre (clic izquierdo en el destino).",
	# --- órdenes --- (proceso/23, parte B)
	"mantener": "No se mueven: atacan solo lo que tengan a su alcance. Cualquier otra orden lo corta.",
	"patrullar": "Van y vuelven entre donde están y el punto que marques (clic izquierdo), atacando lo que vean.",
	"form_bloque": "Rectángulo de dos de ancho por uno de fondo: la línea adelante, la distancia atrás y los montados en las alas.",
	"form_linea": "Dos filas, muy ancha: la distancia reparte el daño y nadie queda atrás sin disparar.",
	"form_abierta": "Como el bloque, con el doble de espacio: sufre menos el daño en área (elefantes, andanadas).",
	"form_columna": "Dos de ancho: para caminos (Qhapaq Ñan), vados y pasos angostos.",
	# --- fin órdenes ---
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
# --- fluidez 2 --- muro: encadenar desde el extremo, puerta en el trazo, cifras y huecos
var _line_chain := Vector2i(-1, -1) # extremo del último trazo puesto con Mayús
var _line_skip := false # el trazo arranca en el extremo anterior: esa casilla ya tiene muro
var _line_gate := Vector2i(-1, -1) # casilla del trazo marcada como puerta (G mientras se arrastra)
var linea_info: Array = [] # renglones [texto, color] junto al cursor mientras se arrastra
var huecos: Array = [] # casillas [x, y] de los huecos del último muro (se marcan unos segundos)
var huecos_hasta := 0 # Time.get_ticks_msec() hasta el que se marcan
# --- fin fluidez 2 ---
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
# --- órdenes --- (proceso/23, parte B)
var atajos: RefCounted # src/game/ui/atajos.gd
var formacion := "bloque" # formación elegida en la grilla: va en cada orden de mover
var rpressing := false # clic derecho apretado: al soltar se ordena; arrastrar elige el rumbo
var rpress_pos := Vector2.ZERO
# --- fin órdenes ---


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
	atajos = Atajos.new(self) # --- órdenes ---


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
		grilla_mixta = "" # --- ronda 6 ---
	# --- fin grilla ---
	selection = ids
	view.selected.clear()
	for id in ids:
		view.selected[id] = true
	if mode == "place" and not _has_villager():
		cancel_mode()
	selection_changed.emit()
	if not keep_menu: Respuesta.al_elegir(self, ids)  # --- fluidez 3 ---


# --- ronda 6 ---
## Z X C V son hitos en la grilla del aldeano y formaciones en la militar (veterano, ronda 6: «con
## los dos elegidos, ¿cuál gana?»). Como AoE4: con aldeanos y tropas elegidos a la vez, la grilla
## es la del tipo principal de la selección —el más numeroso; si empatan, la militar— y Tab
## cambia a la otra. `commands()` decide con esto, así que la grilla, la tecla, el clic y la ficha
## leen lo mismo (Controller.cmd_at). Una selección nueva vuelve al principal.
var grilla_mixta := "" # "": el principal; "aldeanos" o "tropas": lo eligió Tab


## Hay aldeanos propios y otras unidades propias elegidos a la vez.
func seleccion_mixta() -> bool:
	var v := false
	var o := false
	for e in selected_entities():
		if e.owner == local and e.is_unit():
			if e.fn == "civil":
				v = true
			else:
				o = true
	return v and o


## La grilla que manda con la selección actual: la del aldeano o no.
func grilla_aldeano() -> bool:
	if not _has_villager():
		return false
	if not seleccion_mixta():
		return true
	if grilla_mixta != "":
		return grilla_mixta == "aldeanos"
	var nv := 0
	var no := 0
	for e in selected_entities():
		if e.owner == local and e.is_unit():
			if e.fn == "civil":
				nv += 1
			else:
				no += 1
	return nv > no


## Tab con selección mixta: pasa a la otra grilla (vuelve a la raíz del aldeano).
func cambiar_grilla_mixta() -> void:
	grilla_mixta = "tropas" if grilla_aldeano() else "aldeanos"
	submenu = Grilla.RAIZ
	if mode == "place":
		cancel_mode()
	if hud != null and hud.has_method("hide_tip"):
		hud.hide_tip()
	selection_changed.emit()
# --- fin ronda 6 ---


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


## Entidad bajo el punto de la pantalla. `para_orden` (cursor y clic derecho): una unidad de la
## propia selección cuenta como si estuviera media distancia de captura más lejos, porque nadie se
## da una orden a sí mismo; así el animal propio que el aldeano está por carnear gana aunque el
## aldeano esté pegado o le pase por delante (jugador nuevo, ronda 4: el cursor decía «mover»
## según dónde caminaba el aldeano).
func pick(screen: Vector2, para_orden: bool = false) -> int:
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
		if para_orden and view.selected.has(e.id):
			d += 13.0 * 40.0 / cam.zoom
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
	# --- ronda 6 --- con selección mixta y la grilla militar, manda la primera tropa
	var de_aldeano := grilla_aldeano()
	if not de_aldeano and first.is_unit() and first.fn == "civil":
		for e in sel:
			if e.owner == local and e.is_unit() and e.fn != "civil":
				first = e
				break
	if de_aldeano:
		# --- grilla --- (raíz: submenús, detener, refugio e hitos; dentro: edificios en casillas fijas)
		var slots := villager_slots()
		if submenu == Grilla.RAIZ:
			out.append({"slot": Grilla.fija("economia", 0), "id": "economia", "icon": "menu_economia", "kind": "submenu", "menu": Grilla.ECONOMIA, "name": "Construir: economía", "cost": {}, "desc": DESCS["menu_economia"], "locked": ""})
			out.append({"slot": Grilla.fija("militar", 1), "id": "militar", "icon": "menu_militar", "kind": "submenu", "menu": Grilla.MILITAR, "name": "Construir: militar y defensa", "cost": {}, "desc": DESCS["menu_militar"], "locked": ""})
			out.append({"slot": Grilla.fija("detener", 5), "id": "detener", "icon": "detener", "kind": "stop", "name": "Detener", "cost": {}, "desc": DESCS["detener"], "locked": ""})
			out.append({"slot": Grilla.fija("refugio", 7), "id": "refugio", "icon": "refugio", "kind": "garrison", "name": "Refugiarse", "cost": {}, "desc": DESCS["refugio"], "locked": ""})
			# --- fluidez 2 --- reparar lo dañado de la zona, repartidos y en cadena
			var rz := int(MundoColocacion.cfg().get("reparar_zona_radio", 12))
			out.append({"slot": Grilla.fija("reparar_zona", 6), "id": "reparar_zona", "icon": "vida", "kind": "reparar_zona", "name": "Reparar (zona)", "cost": {}, "desc": "Los aldeanos elegidos se reparten entre los edificios propios dañados a %d casillas, del más cercano al más lejano, y siguen en cadena hasta que no quede nada." % rz, "locked": "" if _danados_zona() > 0 else "No hay edificios dañados a %d casillas" % rz})
			# --- fin fluidez 2 ---
		else:
			out.append({"slot": Grilla.fija("volver", 11), "id": "volver", "icon": "volver", "kind": "back", "name": "Volver", "cost": {}, "desc": DESCS["volver"], "locked": ""})
		# --- fin grilla ---
		for slot in slots:
			var type: String = slots[slot]
			var def: Dictionary = sim.dp(local).edificios[type]
			var cmd := {"slot": slot, "id": type, "icon": Glyphs.resolve(def, type), "kind": "build", "name": def["nombre"], "common": common_name(type), "cost": sim.build_cost(local, type), "desc": DESCS.get(type, def.get("desc", "")), "locked": ""}
			if age < def.get("edad_min", 1):
				cmd["locked"] = "Requiere edad %s" % Sim._roman(def["edad_min"])
			# --- paso 7 --- la maravilla (una, la de la vía, sin el Pacto de Cucaú) y la corte fija
			if cmd["locked"] == "" and sim.build_block(local, type) != "":
				cmd["locked"] = sim.build_block(local, type)
			if def.get("maravilla", false):
				cmd["common"] = "Maravilla · edad IV"
				cmd["desc"] = "%s\n%s" % [def.get("desc", ""), wonder_text(def)]
				var pide := wonder_hito_text(def) # --- ronda 8 --- qué hito pide (o impide), arriba de todo
				if pide != "":
					cmd["desc"] = pide + "\n" + cmd["desc"]
			if sim.dp(local).is_hito(type):
				if age >= sim.dp(local).edades.size():
					cmd["locked"] = "Edad máxima alcanzada"
				else:
					cmd["name"] = "%s · avanzar a edad %s" % [def["nombre"], Sim._roman(age + 1)]
					cmd["common"] = "Hito · edad %s" % Sim._roman(age + 1)
					cmd["common_corto"] = "Edad %s" % Sim._roman(age + 1) # si no entra (ronda 5: «Hito · edad I…»)
					cmd["common_dos"] = ["Hito", "Edad %s" % Sim._roman(age + 1)] # --- ronda 6 --- sin perder «hito»
					cmd["desc"] = "%s\n%s\n%s" % [def.get("desc", ""), hito_effects_text(def, age + 1), unlocks_text(age + 1)] # --- paso 4 --- aura
					if sim.hito_in_progress(local):
						cmd["locked"] = "Ya hay un hito en obra"
			out.append(cmd)
	elif first.is_unit() and first.def.has("despliega_en"):
		out.append({"slot": 0, "id": "armar", "icon": "centro", "kind": "unpack", "name": "Armar la corte aquí", "cost": {}, "desc": "La corte se asienta donde está: vuelve a ser la capital.", "locked": "", "unit": first.id})
	elif first.is_unit() and int(first.def.get("guarnicion", 0)) > 0:
		# --- paso 6 --- La canoa: bajar a la gente en la orilla más cercana.
		out.append({"slot": Grilla.fija("detener", 5), "id": "detener", "icon": "detener", "kind": "stop", "name": "Detener", "cost": {}, "desc": DESCS["detener"], "locked": ""})
		out.append({"slot": 11, "id": "expulsar", "icon": "expulsar", "kind": "ungarrison", "name": "Desembarcar (%d/%d)" % [first.garrison.size(), sim.garrison_cap(first)], "cost": {}, "desc": "Baja a la gente en la orilla más cercana (a 2 casillas o menos). Para subir, elegí la tropa o los aldeanos y hacé clic derecho sobre la canoa.", "locked": "" if not first.garrison.is_empty() else "No va nadie en la canoa"})
	elif first.is_unit():
		out.append({"slot": Grilla.fija("atacar", 4), "id": "atacar", "icon": "atacar", "kind": "amove", "name": "Atacar en movimiento", "cost": {}, "desc": DESCS["atacar"], "locked": ""}) # --- grilla ---
		out.append({"slot": Grilla.fija("detener", 5), "id": "detener", "icon": "detener", "kind": "stop", "name": "Detener", "cost": {}, "desc": DESCS["detener"], "locked": ""}) # --- grilla ---
		out.append({"slot": Grilla.fija("refugio", 7), "id": "refugio", "icon": "refugio", "kind": "garrison", "name": "Refugiarse", "cost": {}, "desc": DESCS["refugio"], "locked": ""}) # --- grilla ---
		# --- órdenes --- (mantener, patrullar y formaciones: solo si hay militares)
		var mil := false
		for e in sel:
			mil = mil or (e.owner == local and e.is_military())
		if mil:
			out.append({"slot": Grilla.fija("mantener", 6), "id": "mantener", "icon": "mantener", "kind": "hold", "name": "Mantener posición", "cost": {}, "desc": DESCS["mantener"], "locked": ""})
			out.append({"slot": Grilla.fija("patrullar", 2), "id": "patrullar", "icon": "patrullar", "kind": "patrol", "name": "Patrullar", "cost": {}, "desc": DESCS["patrullar"], "locked": ""})
			for k in FORMAS:
				out.append({"slot": Grilla.fija(k, 8), "id": k, "icon": k, "kind": "form", "form": FORMAS[k][0], "name": "Formación: %s%s" % [FORMAS[k][1], " (elegida)" if formacion == FORMAS[k][0] else ""], "cost": {}, "desc": DESCS[k] + " Arrastrá el clic derecho para elegir hacia dónde mira.", "locked": ""})
		# --- fin órdenes ---
	elif first.is_building() and first.built:
		# --- casillas --- aldeano en Q y explorador en W (interfaz.json → grilla.unidades_fijas);
		# las demás unidades, en orden, a las libres de la primera fila.
		var fijas: Dictionary = Grilla.cfg().get("unidades_fijas", {})
		var produce: Array = first.def.get("produce", [])
		var reservadas := {}
		for type: String in produce:
			if fijas.has(type):
				reservadas[int(fijas[type])] = true
		var i := 0
		for type: String in produce:
			var udef: Dictionary = sim.dp(local).unidades[type]
			if sim.dp(local).replaced_by(type, age) != "":
				continue # --- paso 4 --- el ariete inca y el guaraní pasan al asedio de área en la III
			var slot := int(fijas.get(type, -1))
			if slot < 0:
				while reservadas.has(i):
					i += 1
				slot = i
				i += 1
			var cmd := {"slot": slot, "id": type, "icon": Glyphs.resolve(udef, type), "kind": "train", "name": udef["nombre"], "common": common_name(type), "cost": sim.train_cost(local, first, type), "desc": DESCS.get(type, str(udef.get("desc", ""))), "locked": "", "building": first.id}
			if udef.get("propia", false): # --- paso 6 --- el saber y su evidencia
				cmd["desc"] = "%s\nEvidencia: %s" % [udef.get("desc", ""), udef.get("evidencia", "")]
			if age < udef.get("edad_min", 1):
				cmd["locked"] = "Requiere edad %s" % Sim._roman(udef["edad_min"])
			elif sim.train_block(local, first, type) != "":
				cmd["locked"] = sim.train_block(local, first, type)
			out.append(cmd)
		# Investigaciones: de cada cadena (hachas → hachas_2), la primera que falta. Su casilla se
		# reparte al final (_ubicar_investigaciones): no pisan lo que entrena el edificio.
		var research: Array[Dictionary] = []
		var school: Array[Dictionary] = [] # --- paso 3 ---
		var used := {}
		var techs: Dictionary = sim.dp(local).tecnologias
		for tech: String in techs:
			var t: Dictionary = techs[tech]
			var root := tech
			while techs.get(root, {}).has("requiere") and techs.has(techs[root]["requiere"]):
				root = techs[root]["requiere"]
			if not sim.tech_here(t, first) or used.has(root) or sim.players[local]["techs"].has(tech):
				continue
			if t.has("requiere_hito") and not sim.has_done_hito(local, t["requiere_hito"]):
				continue # --- paso 6 --- la mejora de la otra vía (guaraníes) no se muestra
			# --- ronda 8, 05 --- caminos de la escuela: antes de elegir, solo los caminos; después,
			# solo lo del camino elegido.
			var path := sim.school_path(local)
			if (t.has("camino_de") and path != "") or (t.has("camino") and String(t["camino"]) != path):
				continue
			used[root] = true
			var why := sim.research_block(local, tech)
			var pref := int(t["ranura"]) if produce.is_empty() else int((Grilla.cfg().get("investigaciones_con_tropa", {}) as Dictionary).get(tech if not t.has("requiere") else root, t["ranura"]))
			var rc := {"slot": pref, "id": tech, "icon": Iconos.de_tecnologia(tech, t), "kind": "research", "name": tech_name(tech), "corto": str(t.get("nombre_corto", "")), "cost": sim.tech_cost(local, tech), "desc": effects_text(t["efectos"]), "locked": why, "tech": true, "building": first.id}
			if t.get("propia", false): # --- paso 6 --- el saber y su evidencia
				rc["desc"] = "%s\n%s\nEvidencia: %s" % [rc["desc"], t.get("desc", ""), t.get("evidencia", "")]
			elif t.has("camino_de"): # --- ronda 8, 05 ---
				rc["desc"] = str(t.get("desc", ""))
			elif t.has("repite"):
				var rp: Dictionary = t["repite"]
				rc["desc"] = "%s\nSe repite: %d de %d. Cada vez cuesta %d %% más del costo base." % [rc["desc"], sim.times_done(local, tech), int(rp.get("max", 1)), int(rp.get("crece_pct", 0))]
			# --- paso 3 --- La escuela de la IV va en su propio submenú, con el nombre del pueblo.
			if t.get("escuela", false):
				school.append(rc)
			else:
				research.append(rc)
		_marcar_recomendado(research + school, first) # --- ronda 7 ---
		if submenu == ESCUELA:
			var inner: Array[Dictionary] = [{"slot": Grilla.fija("volver", 11), "id": "volver", "icon": "volver", "kind": "back", "name": "Volver", "cost": {}, "desc": "Vuelve a la grilla del edificio (también Esc o clic derecho sobre la grilla).", "locked": ""}]
			_repartir(school, {Grilla.fija("volver", 11): "volver"})
			for c in school:
				if int(c["slot"]) >= 0:
					inner.append(c)
			return inner
		var esc := escuela_info()
		if not school.is_empty() and int(sim.players[local]["age"]) >= int(sim.dp(local).tecnologias[school[0]["id"]].get("edad_min", 1)):
			out.append({"slot": Grilla.fija("escuela", 7), "id": ESCUELA, "icon": "escuela", "kind": "submenu", "menu": ESCUELA, "name": "%s (%d)" % [esc["nombre"], school.size()], "cost": {}, "desc": "%s\nMejoras: %s." % [esc["desc"], ", ".join(school.map(func(c: Dictionary) -> String: return c["name"]))], "locked": "", "recomendado": school.any(func(c: Dictionary) -> bool: return c.get("recomendado", false))})
		# --- fin paso 3 ---
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
			out.append({"slot": 9, "id": "desarmar", "icon": "carga", "kind": "pack", "name": "Desarmar la corte", "cost": {}, "desc": "La corte se levanta y camina con su gente: viaja lenta y se vuelve a armar donde haga falta.", "locked": "" if first.queue.is_empty() else "Esperá que termine la cola", "building": first.id})
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
		# Las mejoras militares primero: quedan en A S D F como en el cuartel (también en el mocambo).
		var mil_first: Array[Dictionary] = research.filter(func(c: Dictionary) -> bool: return techs.get(c["id"], {}).get("en", {}).get("militar", false))
		mil_first.append_array(research.filter(func(c: Dictionary) -> bool: return not techs.get(c["id"], {}).get("en", {}).get("militar", false)))
		out = _ubicar_investigaciones(out, mil_first)
	_marcar_estados(out) # --- iconos ---
	return out


## --- casillas --- (jugador nuevo, ronda 4) Reparte las investigaciones de un edificio sin pisar lo
## que ya tiene casilla: lo que entrena (Q W E R, el aldeano siempre en Q y el explorador en W),
## la campana, el mercado, la guarnición… Cada una va a su `ranura` de los datos si está libre (las
## del depósito quedan en Q W E del almacén); si no, a la primera libre desde A, y después de Q.
## Si no entran todas, van juntas a un submenú «Investigaciones» (casilla libre; V vuelve).
## tests/casillas.gd recorre todos los edificios de las seis civilizaciones.
func _ubicar_investigaciones(out: Array[Dictionary], research: Array[Dictionary]) -> Array[Dictionary]:
	var taken := {}
	for c in out:
		var sl := int(c["slot"])
		if taken.has(sl):
			# Dos comandos fijos en la misma casilla (no pasa con los datos de hoy): al primero libre.
			for alt in _ORDEN_LIBRE:
				if not taken.has(alt):
					push_warning("Grilla: '%s' choca con '%s' en %s; va a %s" % [c["id"], taken[sl], etiqueta(sl), etiqueta(alt)])
					c["slot"] = alt
					sl = alt
					break
		taken[sl] = c["id"]
	if research.is_empty():
		return out
	var free := 0
	for sl in 12:
		free += 0 if taken.has(sl) else 1
	# --- ronda 7 --- (veterano: el cuartel lleno en la III, 12 de 12) Si no quedan libres_min
	# casillas libres, la herrería va a su submenú y deja lugar para lo de la IV.
	var herr: Array[Dictionary] = research.filter(func(c: Dictionary) -> bool: return sim.dp(local).tecnologias.get(c["id"], {}).has("herreria"))
	if research.size() > free - int(Grilla.cfg().get("libres_min", 0)) and herr.size() > 1 and research.size() - herr.size() + 1 <= free - int(Grilla.cfg().get("libres_min", 0)):
		if submenu == HERRERIA:
			var inner_h: Array[Dictionary] = [{"slot": Grilla.fija("volver", 11), "id": "volver", "icon": "volver", "kind": "back", "name": "Volver", "cost": {}, "desc": "Vuelve a la grilla del edificio (también Esc o clic derecho sobre la grilla).", "locked": ""}]
			_repartir(herr, {Grilla.fija("volver", 11): "volver"})
			for c in herr:
				if int(c["slot"]) >= 0:
					inner_h.append(c)
			return inner_h
		var rest: Array[Dictionary] = [{"slot": int(herr[0]["slot"]), "id": HERRERIA, "icon": "yunque", "kind": "submenu", "menu": HERRERIA, "name": "Herrería (%d)" % herr.size(), "cost": {}, "desc": "Ataque y armadura de la tropa: " + ", ".join(herr.map(func(c: Dictionary) -> String: return c["name"])) + ".", "locked": "", "recomendado": herr.any(func(c: Dictionary) -> bool: return c.get("recomendado", false))}]
		rest.append_array(research.filter(func(c: Dictionary) -> bool: return not herr.has(c)))
		_repartir(rest, taken)
		out.append_array(rest)
		return out
	# --- fin ronda 7 ---
	if research.size() <= free:
		_repartir(research, taken)
		out.append_array(research)
		return out
	# No entran: un submenú con todas (la casilla libre más a la derecha de abajo).
	if submenu == INVESTIGAR:
		var inner: Array[Dictionary] = [{"slot": Grilla.fija("volver", 11), "id": "volver", "icon": "volver", "kind": "back", "name": "Volver", "cost": {}, "desc": "Vuelve a la grilla del edificio (también Esc o clic derecho sobre la grilla).", "locked": ""}]
		_repartir(research, {Grilla.fija("volver", 11): "volver"})
		for c in research:
			if int(c["slot"]) >= 0:
				inner.append(c)
		return inner
	for alt in [11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0]:
		if not taken.has(alt):
			out.append({"slot": alt, "id": INVESTIGAR, "icon": "investigar", "kind": "submenu", "menu": INVESTIGAR, "name": "Investigaciones (%d)" % research.filter(func(c: Dictionary) -> bool: return c["kind"] == "research").size(), "cost": {}, "desc": "Mejoras que se investigan en este edificio: " + ", ".join(research.map(func(c: Dictionary) -> String: return c["name"])) + ".", "locked": "", "recomendado": research.any(func(c: Dictionary) -> bool: return c.get("recomendado", false))})
			break
	return out


const INVESTIGAR := "investigar"
const ESCUELA := "escuela" # --- paso 3 --- submenú de la escuela de la IV
const HERRERIA := "herreria" # --- ronda 7 --- submenú de la herrería cuando la grilla se llena


## --- ronda 7 --- (jugador nuevo: «¿qué compro primero?») Marca con `recomendado` la mejora que
## conviene comprar primero en este edificio, entre las que ya se pueden pedir, en el orden de
## compra de la IA (data/interfaz.json → grilla._doc_recomendado). Solo lee la simulación.
func _marcar_recomendado(cands: Array, b: SimEntity) -> void:
	var dd := sim.dp(local)
	var best: Dictionary = {}
	var best_rank := 1 << 30
	for c: Dictionary in cands:
		if str(c.get("locked", "")) != "":
			continue
		var r := _rango_recomendado(String(c["id"]), dd.tecnologias.get(c["id"], {}), b)
		if r < best_rank:
			best_rank = r
			best = c
	if not best.is_empty():
		best["recomendado"] = true
		best["desc"] = "★ Recomendada: la que conviene comprar primero acá.\n" + str(best.get("desc", ""))


## Menor es mejor; 1 << 30 si la IA no la tiene en ningún orden.
func _rango_recomendado(tech: String, t: Dictionary, b: SimEntity) -> int:
	if t.get("ia_prioridad", false):
		return 0
	var lin: String = t.get("linea", "")
	if lin != "" and t.has("nivel"):
		var n := int(_tropa_por_linea().get(lin, 0))
		if n >= int(sim.data.reglas.get("ia_niveles", {}).get("tropa_minima", 1)):
			return 1000 - mini(n, 999)
	var tardias: Array = sim.data.reglas.get("ia_compras_tardias", {}).get("orden", [])
	if tardias.has(tech):
		return 2000 + tardias.find(tech)
	var propias: Array = sim.dp(local).civ.get("ia_propias", {}).get("orden", [])
	for i in propias.size():
		if str((propias[i] as Dictionary).get("tec", "")) == tech:
			return 3000 + i
	if lin != "" and t.has("nivel") and sim.dp(local).lines_made_by(b.def).has(lin):
		return 4000
	return 1 << 30


var _tropa_tick := -1
var _tropa: Dictionary = {}


## Tropa propia por línea (una vez por tick).
func _tropa_por_linea() -> Dictionary:
	if _tropa_tick == sim.tick:
		return _tropa
	_tropa_tick = sim.tick
	_tropa = {}
	for e in sim.actives:
		if e.alive and e.owner == local and e.is_unit():
			var l := SimData.line_of(e.def)
			if l != "":
				_tropa[l] = int(_tropa.get(l, 0)) + 1
	return _tropa
const _ORDEN_LIBRE: Array[int] = [4, 5, 6, 7, 8, 9, 10, 0, 1, 2, 3, 11]


## --- paso 3 --- La escuela de la IV del jugador local (docs/diseno/27, §1.3): nombre y ficha de
## data/civs/<pueblo>.json → escuela. Con una variante por hito (los guaraníes de la vía monte
## tienen el óga guasu), vale la del hito que tiene en pie. Sin pueblo, «Escuela».
func escuela_info() -> Dictionary:
	var esc: Dictionary = sim.dp(local).civ.get("escuela", {})
	var out := {"nombre": esc.get("nombre", "Escuela"), "desc": esc.get("desc", "Las mejoras de la edad IV."), "tecnologias": {}}
	var variants: Dictionary = esc.get("variantes", {})
	if variants.is_empty():
		return out
	for e in sim.actives:
		if e.alive and e.owner == local and e.is_building() and e.built and variants.has(e.type):
			var v: Dictionary = variants[e.type]
			out["nombre"] = v.get("nombre", out["nombre"])
			out["desc"] = v.get("desc", out["desc"])
			out["tecnologias"] = v.get("tecnologias", {})
			break
	return out


## --- paso 3 --- Nombre de una investigación para el jugador local (con la variante de su escuela).
func tech_name(tech: String) -> String:
	var t: Dictionary = sim.dp(local).tecnologias.get(tech, {})
	if t.get("escuela", false):
		var v: Dictionary = escuela_info()["tecnologias"].get(tech, {})
		if v.has("nombre"):
			return v["nombre"]
	if t.has("repite"): # --- ronda 8, 05 --- la que se repite dice qué vez es
		return "%s %d/%d" % [t.get("nombre", tech), sim.times_done(local, tech) + 1, int(t["repite"].get("max", 1))]
	return t.get("nombre", tech)


## Primero, cada una a su ranura si está libre; después, las que quedan a la primera libre.
func _repartir(research: Array[Dictionary], taken: Dictionary) -> void:
	var rest: Array[Dictionary] = []
	for c in research:
		var sl := int(c["slot"])
		if sl >= 0 and sl < 12 and not taken.has(sl):
			taken[sl] = c["id"]
		else:
			rest.append(c)
	for c in rest:
		c["slot"] = -1
		for alt in _ORDEN_LIBRE:
			if not taken.has(alt):
				taken[alt] = c["id"]
				c["slot"] = alt
				break
# --- fin casillas ---


# --- iconos --- (proceso/28) Lo que la casilla necesita para mostrar su estado de un vistazo:
## `edad` (la edad a la que pertenece: color de la franja y de la pastilla), `tope` (bloqueado por
## el máximo por edad, con su propia pastilla), `aviso` (no bloquea: población llena, el pedido
## espera lugar), `en_curso` (investigación ya pedida) y `en_cola` (cuántas de esa tropa hay en
## la cola de lo elegido). Solo lee la simulación.
func _marcar_estados(out: Array[Dictionary]) -> void:
	var dd := sim.dp(local)
	var p: Dictionary = sim.players[local]
	var age: int = p["age"]
	var sel := selected_entities()
	for c in out:
		match String(c.get("kind", "")):
			"build":
				var def: Dictionary = dd.edificios.get(c["id"], {})
				if dd.is_hito(c["id"]):
					c["edad"] = age + 1 if age < dd.edades.size() else 0
				else:
					c["edad"] = int(def.get("edad_min", 1))
				if c["locked"] == "" and not sim.engine_room(c["id"], local):
					c["locked"] = "Máximo en esta edad: %d" % _maximo_edad(def, c["id"])
					c["tope"] = true
			"train":
				var udef: Dictionary = dd.unidades.get(c["id"], {})
				c["edad"] = int(udef.get("edad_min", 1))
				var n := 0
				var rep := false # --- frente 1 --- algún edificio elegido lo repite
				for e in sel:
					if e.is_building() and e.owner == local:
						n += e.queue.count(c["id"])
						rep = rep or e.repeat == c["id"]
				c["en_cola"] = n
				c["repite"] = rep
				if c["locked"] == "":
					c["desc"] = (str(c.get("desc", "")) + "\n" if str(c.get("desc", "")) != "" else "") + "Ctrl + clic: %s. Clic derecho: saca una de la cola (Mayús: 5)." % ("deja de repetir" if rep else "se repite sola (como AoE4)")
				if c["locked"] != "":
					continue
				if udef.has("maximo_por_edad"):
					var have := 0
					for e in sim.actives:
						if e.alive and e.owner == local:
							have += 1 if e.type == c["id"] else 0
							if e.is_building():
								have += e.queue.count(c["id"])
					var cap := _maximo_edad(udef, c["id"])
					if have >= cap:
						c["locked"] = "Máximo en esta edad: %d" % cap
						c["tope"] = true
						continue
				if int(p["pop"]) + int(udef.get("pob", 1)) > int(p["pop_cap"]):
					c["aviso"] = "Población llena (%d/%d): entra a la cola y sale cuando haya lugar" % [int(p["pop"]), int(p["pop_cap"])]
			"research":
				c["edad"] = int(dd.tecnologias.get(c["id"], {}).get("edad_min", 1))
				if c["locked"] == "En investigación":
					c["en_curso"] = true


func _maximo_edad(def: Dictionary, type: String) -> int:
	var maxes: Array = def.get("maximo_por_edad", [])
	if maxes.is_empty():
		return 0
	return int(maxes[clampi(int(sim.players[local]["age"]) - 1, 0, maxes.size() - 1)]) + int(sim.mods.engine_max_bonus(local, type))
# --- fin iconos ---


## Comando de una casilla: el único lugar donde se resuelve qué hay en cada casilla. Lo usan el
## dibujo de la grilla (hud.gd), la tecla, el clic y la ficha, para que lo que se ve sea lo que se
## ejecuta (jugador nuevo, ronda 4). tests/casillas.gd verifica que no haya dos en una casilla.
static func cmd_at(cmds: Array, slot: int) -> Dictionary:
	for c: Dictionary in cmds:
		if int(c.get("slot", -1)) == slot:
			return c
	return {}


# --- grilla ---
## Edificios que muestra la grilla del aldeano: {casilla: tipo}. En la raíz, solo los hitos de la
## edad siguiente (Z economía, X militar); en un submenú, sus edificios en casillas fijas (Grilla).
## Con `menu` se pide un submenú sin abrirlo (pruebas).
func villager_slots(menu: String = "?") -> Dictionary:
	var which := submenu if menu == "?" else menu
	if which == Grilla.RAIZ:
		var root := Grilla.hitos(sim.dp(local), int(sim.players[local]["age"]))
		var wt := wonder_build_type() # --- paso 7 --- la maravilla, junto a los hitos (C)
		if wt != "" and int(sim.players[local]["age"]) >= int(sim.dp(local).edificios[wt].get("edad_min", 1)):
			root[Grilla.fija("maravilla", 10)] = wt
		return root
	return Grilla.edificios(sim.dp(local), which)


## --- paso 7 --- La maravilla que muestra la grilla: la que se puede levantar (los guaraníes
## tienen una por vía); si ninguna, la primera, con el motivo en el candado.
func wonder_build_type() -> String:
	var dd := sim.dp(local)
	var first := ""
	for t: String in dd.unidades["aldeano"].get("construye", []):
		if dd.edificios.get(t, {}).get("maravilla", false):
			if sim.build_block(local, t) == "":
				return t
			if first == "":
				first = t
	return first


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
			# --- veterano ronda 4 --- como AoE4: cada pulsación entrena UNA unidad en el edificio
			# de cola más corta (Mayús: 5 en total, no 5 por edificio).
			# --- frente 1 --- Ctrl + clic (o Ctrl + tecla): prende o apaga la repetición.
			if Input.is_key_pressed(KEY_CTRL):
				alternar_repeticion(cmd)
				return
			var shift := Input.is_key_pressed(KEY_SHIFT)
			for k in (5 if shift else 1):
				var e := cola_mas_corta(cmd)
				if e == null:
					break
				_pendientes[e.id] = int(_pendientes.get(e.id, 0)) + 1
				sim.push_command({"t": "train", "player": local, "building": e.id, "type": cmd["id"]})
			# --- fin veterano ronda 4 ---
		"stop":
			# --- mundo ---
			if cola != null:
				cola.limpiar(_own_unit_ids())
			# --- fin mundo ---
			sim.push_command({"t": "stop", "player": local, "ids": _own_unit_ids()})
		# --- fluidez 2 ---
		"reparar_zona":
			if cola != null and cola.reparar_zona(_own_unit_ids()) == 0:
				hud_notify("No hay edificios dañados cerca")
		# --- fin fluidez 2 ---
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
				if (e.is_building() or int(e.def.get("guarnicion", 0)) > 0) and e.owner == local: # --- paso 6 --- también la canoa
					sim.push_command({"t": "ungarrison", "player": local, "building": e.id})
		"amove":
			mode = "amove"
		# --- órdenes ---
		"patrol":
			mode = "patrol"
		"hold":
			sim.push_command({"t": "mantener", "player": local, "ids": _own_unit_ids()})
		"form":
			formacion = cmd["form"]
			sim.push_command({"t": "formar", "player": local, "ids": _own_unit_ids(), "form": formacion})
		# --- fin órdenes ---
		# --- grilla ---
		"submenu":
			open_submenu(cmd["menu"])
		"back":
			open_submenu(Grilla.RAIZ)
		# --- fin grilla ---


# --- veterano ronda 4 ---
## Pedidos de entrenar que todavía no entraron a la simulación (entran en el próximo tick):
## {id del edificio: cantidad}. Se vacía en _process cuando avanzó el tick.
var _pendientes := {}
var _pendientes_tick := -1


## Entre los edificios elegidos del tipo del comando, el de cola más corta (contando lo pedido
## en este cuadro); a igual cola, el que está más cerca de terminar lo que entrena, y después
## el de menor id. null si todos tienen la cola llena.
func cola_mas_corta(cmd: Dictionary) -> SimEntity:
	if sim.tick != _pendientes_tick:
		_pendientes.clear()
		_pendientes_tick = sim.tick
	var tipo: String = sim.by_id[cmd["building"]].type if sim.by_id.has(cmd["building"]) else ""
	var tope := int(sim.data.reglas.get("cola_max", 5))
	var mejor: SimEntity = null
	var mejor_n := 0
	for e in selected_entities():
		if not (e.is_building() and e.built and e.type == tipo and e.owner == local):
			continue
		var n: int = e.queue.size() + int(_pendientes.get(e.id, 0))
		if n >= tope:
			continue
		if mejor == null or n < mejor_n or (n == mejor_n and n > 0 and e.queue_progress > mejor.queue_progress):
			mejor = e
			mejor_n = n
	return mejor
# --- fin veterano ronda 4 ---


# --- frente 1 --- (proceso/30) producción que se maneja sola
## Edificios elegidos, propios y terminados, del tipo del edificio del comando.
func _edificios_del_cmd(cmd: Dictionary) -> Array[SimEntity]:
	var out: Array[SimEntity] = []
	var tipo: String = sim.by_id[cmd["building"]].type if sim.by_id.has(cmd["building"]) else ""
	for e in selected_entities():
		if e.is_building() and e.built and e.type == tipo and e.owner == local:
			out.append(e)
	return out


## Prende la repetición de la unidad del comando en los edificios elegidos de ese tipo; si
## todos ya la repetían, la apaga. Va como comando de la simulación (repeticiones y red).
## Devuelve si quedó prendida.
func alternar_repeticion(cmd: Dictionary) -> bool:
	var bs := _edificios_del_cmd(cmd)
	var todos := not bs.is_empty()
	for e in bs:
		todos = todos and e.repeat == cmd["id"]
	for e in bs:
		sim.push_command({"t": "repetir", "player": local, "building": e.id, "type": cmd["id"], "on": not todos})
	if not bs.is_empty():
		var nombre := str(cmd.get("name", cmd["id"]))
		hud_notify("%s: %s" % [nombre, "ya no se repite" if todos else "se repite sola (Ctrl + clic para cortarla)"], "info")
	return not todos


## Saca `n` unidades del tipo del comando de la cola, de la última hacia atrás y del edificio
## elegido que tenga más de ese tipo (el reverso de cola_mas_corta). Devuelve cuántas sacó.
func sacar_de_cola(cmd: Dictionary, n: int) -> int:
	var colas := {} # id -> copia de la cola (los índices se corren al sacar en el mismo tick)
	var bs := _edificios_del_cmd(cmd)
	for e in bs:
		colas[e.id] = e.queue.duplicate()
	var hechas := 0
	for k in n:
		var mejor: SimEntity = null
		var mejor_n := 0
		for e in bs:
			var c: int = (colas[e.id] as Array).count(cmd["id"])
			if c > mejor_n:
				mejor = e
				mejor_n = c
		if mejor == null:
			break
		var q: Array = colas[mejor.id]
		var idx := q.rfind(cmd["id"])
		q.remove_at(idx)
		sim.push_command({"t": "cancel", "player": local, "building": mejor.id, "index": idx})
		hechas += 1
	return hechas


## Tope de aldeanos de la repetición: sube o baja un paso (data/reglas.json → repeticion).
func cambiar_tope_aldeanos(signo: int) -> void:
	var rep: Dictionary = sim.data.reglas.get("repeticion", {})
	sim.push_command({"t": "tope_aldeanos", "player": local, "n": sim.villager_cap(local) + signo * int(rep.get("paso", 5))})
# --- fin frente 1 ---


func cancel_mode() -> void:
	mode = ""
	place_type = ""
	_ghost.visible = false
	_line_drag = false
	_show_line([])
	_line_chain = Vector2i(-1, -1) # --- fluidez 2 ---
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
		# --- fluidez 2 --- la granja se pega al depósito de alimento o a la granja vecina
		var pegada := MundoColocacion.pegar_granja(sim, local, place_type, tx, ty)
		tx = pegada.x
		ty = pegada.y
		# --- fin fluidez 2 ---
		_ghost.position = Vector3(tx + tam[0] / 2.0, 0.02, ty + tam[1] / 2.0)
		var ok := sim.can_place(place_type, tx, ty, local) and sim.can_afford(local, sim.dp(local).cost_of(place_type, sim.players[local]["age"]))
		_ghost_mat.albedo_color = Color(0.5, 1.0, 0.6, 0.55) if ok else Color(1.0, 0.35, 0.3, 0.55)
		_ghost.set_meta("tile", Vector2i(tx, ty))
		if _line_drag:
			_ghost.visible = false
			_show_line(trazo(Vector2i(tx, ty))) # --- fluidez 2 ---
		else:
			_ghost.visible = true


# --- cursores ---
## Qué haría un clic en este punto, como nombre de cursor (src/game/ui/cursores.gd):
## "" (flecha), "mover", "atacar", "recolectar_<recurso>", "construir", "reparar", "refugio",
## "depositar", "reunion" o "no". Repite las reglas de Sim._cmd_target sin tocar la simulación.
func cursor_action(m: Vector2) -> String:
	if _over_hud(m) or dragging:
		return ""
	if mode == "amove" or mode == "patrol":
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
	if units.is_empty():
		for e in sel:
			if e.is_building() and e.def.has("produce"):
				return "reunion"
		return ""
	# El mismo blanco que tomaría el clic derecho (_right_click), calculado en este punto: no el
	# `hovered` del cuadro anterior, que podía ser otro (el autotest lo veía de a ratos).
	var t: SimEntity = sim.by_id.get(pick(m, true))
	# --- fluidez 2 --- sobre una huella fantasma, el aldeano reconstruye
	if (t == null or not t.alive) and cola != null and units.any(func(e: SimEntity) -> bool: return e.fn == "civil"):
		var gp := cam.ground_at(m)
		if not cola.huella_en(int(gp.x * P), int(gp.z * P)).is_empty():
			return "construir"
	# --- fin fluidez 2 ---
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
	# --- paso 6 --- Canoa propia: subir.
	if t.is_unit() and t.owner == local and sim.garrison_cap(t) > 0 and not units.any(func(e: SimEntity) -> bool: return e.def.get("navega", false)):
		return "refugio" if t.garrison.size() < sim.garrison_cap(t) else "no"
	# Animal propio: el aldeano lo carnea (cursor de juntar alimento).
	if t.is_unit() and t.owner == local and t.def.get("animal", false):
		return "recolectar_alimento" if civil else "mover"
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
	# --- fluidez 4 --- (suelta del Alt + clic: bengala con la intención de la rueda)
	if event is InputEventMouseButton and not event.pressed and event.button_index == MOUSE_BUTTON_LEFT \
			and hud != null and hud.get("ordenes_capa") != null and not hud.ordenes_capa.rueda.is_empty():
		var r: Array = hud.ordenes_capa.cerrar_rueda(event.position)
		flare(r[0], r[1])
		get_viewport().set_input_as_handled()
		return
	# --- fin fluidez 4 ---
	# --- órdenes --- (suelta del clic derecho: orden, con rumbo si se arrastró)
	if event is InputEventMouseButton and not event.pressed and event.button_index == MOUSE_BUTTON_RIGHT and rpressing:
		rpressing = false
		_right_click(rpress_pos, drag_rumbo(event.position))
		get_viewport().set_input_as_handled()
		return
	# --- fin órdenes ---
	# --- fluidez 2 --- G mientras se arrastra el muro: la casilla bajo el cursor va de puerta
	if _line_drag and event is InputEventKey and event.pressed and not event.echo and (event as InputEventKey).physical_keycode == KEY_G:
		marcar_puerta()
		get_viewport().set_input_as_handled()
		return
	# --- fin fluidez 2 ---
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
			# --- fluidez 2 --- con Mayús, el trazo sigue desde el extremo del anterior
			_line_gate = Vector2i(-1, -1)
			_line_skip = Input.is_key_pressed(KEY_SHIFT) and _line_chain.x >= 0
			if _line_skip:
				_line_start = _line_chain
			# --- fin fluidez 2 ---
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
		# --- órdenes ---
		if mode == "patrol":
			var gp := cam.ground_at(mb.position)
			sim.push_command({"t": "patrullar", "player": local, "ids": _own_unit_ids(), "x": int(gp.x * P), "y": int(gp.z * P)})
			view.add_marker(gp, Palette.UI_BAD)
			cancel_mode()
			return
		if Input.is_key_pressed(KEY_ALT):
			# --- fluidez 4 --- Alt + clic: bengala automática; Alt + arrastrar: rueda de intención
			if hud != null and hud.get("ordenes_capa") != null:
				hud.ordenes_capa.abrir_rueda(mb.position, cam.ground_at(mb.position))
			else:
				flare(cam.ground_at(mb.position))
			# --- fin fluidez 4 ---
			return
		# --- fin órdenes ---
		_pressing = true
		dragging = false
		press_pos = mb.position
	elif mb.button_index == MOUSE_BUTTON_RIGHT and mb.pressed:
		if mode != "":
			cancel_mode()
			return
		# --- órdenes --- (con unidades, la orden sale al soltar: arrastrar elige el rumbo)
		if not _own_unit_ids().is_empty():
			rpressing = true
			rpress_pos = mb.position
			return
		# --- fin órdenes ---
		_right_click(mb.position)


func _left_release(pos: Vector2) -> void:
	var shift := Input.is_key_pressed(KEY_SHIFT)
	if dragging:
		_box_select(Rect2(press_pos, pos - press_pos).abs(), shift)
		return
	var id := pick(pos)
	var now := Time.get_ticks_msec()
	if id >= 0 and id == _last_click_id and now - _last_click_ms < 350:
		# --- órdenes --- (doble clic en un edificio propio: todos los de su tipo en el mapa)
		var de: SimEntity = sim.by_id.get(id)
		if de != null and de.is_building() and de.owner == local:
			atajos.todos_del_tipo(de.type)
			_last_click_ms = 0
			return
		# --- fin órdenes ---
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


# --- órdenes ---
## Rumbo (0..15) del arrastre del clic derecho, o -1 si fue un clic corto. Se calcula con la
## misma tabla de enteros que la simulación (SimGroups.heading), así la orden llega cerrada.
func drag_rumbo(pos: Vector2) -> int:
	if pos.distance_to(rpress_pos) < float(Atajos.cfg().get("arrastre_rumbo_px", 24)):
		return -1
	var a := cam.ground_at(rpress_pos)
	var b := cam.ground_at(pos)
	var dx := int((b.x - a.x) * P)
	var dy := int((b.z - a.z) * P)
	if dx == 0 and dy == 0:
		return -1
	return SimGroups.heading(dx, dy)


## Bengala (Alt + clic en el mapa o el minimapa): atacá o defendé acá. Solo con aliados.
func flare(g: Vector3, tipo: String = "") -> void: # --- fluidez 4 --- (tipo: intención de la rueda)
	var ally := false
	for p in sim.players:
		ally = ally or (p["id"] != local and not sim.enemies(local, p["id"]) and not p["defeated"])
	if not ally:
		hud_notify("Las bengalas son para avisarle a un aliado", "info")
		return
	var cmd := {"t": "bengala", "player": local, "x": int(g.x * P), "y": int(g.z * P)}
	if tipo != "": # --- fluidez 4 ---
		cmd["tipo"] = tipo
	sim.push_command(cmd)
# --- fin órdenes ---


func _right_click(pos: Vector2, rumbo: int = -1) -> void:
	var sel := selected_entities()
	if sel.is_empty() or sel[0].owner != local:
		Respuesta.error(self)  # --- fluidez 3 ---
		return
	var g := cam.ground_at(pos)
	var target := pick(pos, true)
	var ids := _own_unit_ids()
	if not ids.is_empty():
		var t: SimEntity = sim.by_id.get(target)
		_orden_ack()
		# --- fluidez 2 --- clic derecho de los aldeanos en una huella fantasma: reconstruir
		if t == null and cola != null and _has_villager():
			var h: Dictionary = cola.huella_en(int(g.x * P), int(g.z * P))
			if not h.is_empty():
				var civiles := ids.filter(func(id: int) -> bool: return (sim.by_id[id] as SimEntity).fn == "civil")
				var why: String = cola.reconstruir(civiles, h, Input.is_key_pressed(KEY_SHIFT))
				if why != "":
					hud_notify(why)
				else:
					view.add_marker(g, Palette.UI_ACCENT)
				return
		# --- fin fluidez 2 ---
		# --- mundo ---
		if cola != null and cola.orden_derecha(ids, t, g, Input.is_key_pressed(KEY_SHIFT)):
			view.add_marker(g, Color(Palette.UI_GOOD, 0.6))
			return
		# --- fin mundo ---
		# Alt + clic derecho: suelto, sin formación (cada uno a su velocidad: para retirarse).
		var loose := Input.is_key_pressed(KEY_ALT)
		# Un animal propio (llama, cabra…) no es un aliado más: el aldeano lo carnea (la simulación ya lo hace).
		var own_animal: bool = t != null and t.is_unit() and t.owner == local and t.def.get("animal", false)
		if t != null and t.id not in ids and (not (t.is_unit() and t.owner == local) or own_animal):
			sim.push_command({"t": "target", "player": local, "ids": ids, "target": t.id, "suelto": loose})
			var col := Palette.UI_BAD if t.owner >= 0 and t.owner != local else Palette.UI_ACCENT
			view.add_marker(WorldView.to_world(t.x, t.y), col)
			Respuesta.blanco(self, t, col)  # --- fluidez 3 ---
		else:
			sim.push_command({"t": "move", "player": local, "ids": ids, "x": int(g.x * P), "y": int(g.z * P), "suelto": loose, "form": formacion, "rumbo": rumbo}) # --- órdenes ---
			view.add_marker(g, Palette.UI_BAD if loose else Palette.UI_GOOD)
		return
	# Edificios: punto de reunión.
	for e in sel:
		if e.is_building() and e.def.has("produce"):
			sim.push_command({"t": "rally", "player": local, "building": e.id, "x": int(g.x * P), "y": int(g.z * P), "target": target})
	view.add_marker(g, Palette.UI_ACCENT)


## Sonido corto del pueblo al dar una orden a las tropas (data/audio.json; con su propio límite).
func _orden_ack() -> void:
	if hud != null and hud.main.get("audio") != null:
		Respuesta.orden(self)  # --- fluidez 3 ---


func _place() -> void:
	var tile: Vector2i = _ghost.get_meta("tile", Vector2i(-1, -1))
	var cost := sim.dp(local).cost_of(place_type, sim.players[local]["age"])
	if not sim.can_place(place_type, tile.x, tile.y, local):
		Respuesta.error(self)  # --- fluidez 3 ---
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
	# --- fluidez 2 --- con Mayús, los cimientos se levantan en el orden en que se pusieron
	if cola != null:
		cola.colocar(ids, place_type, tile.x, tile.y, Input.is_key_pressed(KEY_SHIFT))
	else:
		sim.push_command({"t": "build", "player": local, "ids": ids, "type": place_type, "tx": tile.x, "ty": tile.y})
	# --- fin fluidez 2 ---
	view.add_marker(_ghost.position, Palette.UI_ACCENT)
	Respuesta.cimiento(self, _ghost.position, place_type)  # --- fluidez 3 ---
	if not Input.is_key_pressed(KEY_SHIFT) or sim.dp(local).is_hito(place_type):
		cancel_mode()
		submenu = Grilla.RAIZ # --- grilla --- (colocado el edificio, la grilla vuelve a la raíz)


func _key(k: InputEventKey) -> void:
	var code := k.physical_keycode
	if code == KEY_ESCAPE:
		if mode != "":
			cancel_mode()
		elif submenu != Grilla.RAIZ and (grilla_aldeano() or submenu == INVESTIGAR or submenu == ESCUELA or submenu == HERRERIA): # --- grilla --- (--- ronda 6 ---, ronda 7)
			open_submenu(Grilla.RAIZ)
		elif not selection.is_empty():
			_set_selection([] as Array[int])
		elif hud != null:
			hud.toggle_menu()
		get_viewport().set_input_as_handled()
		return
	# --- veterano ronda 4 --- las teclas salen de Teclas (Opciones → Teclas): grupos 0…9,
	# marcadores, ociosos, ejército, centros y la grilla se pueden reasignar.
	var acc := Teclas.accion(code)
	if acc.begins_with("grupo_"):
		var n := int(acc.trim_prefix("grupo_"))
		# Alt + número vuelve a un marcador y Ctrl + Alt + número lo guarda (proceso/24, 4k):
		# Ctrl + número sigue siendo de los grupos de control.
		if k.alt_pressed:
			if n >= 1 and n <= int(Atajos.cfg().get("marcadores", 8)):
				atajos.marca(n, k.ctrl_pressed)
				get_viewport().set_input_as_handled()
			return
		_grupo(n, k.ctrl_pressed, k.shift_pressed)
		return
	if acc.begins_with("marcador_"):
		atajos.marca(int(acc.trim_prefix("marcador_")), k.ctrl_pressed)
		get_viewport().set_input_as_handled()
		return
	match acc:
		"ocioso_aldeano":
			atajos.ocioso(false, k.shift_pressed or k.ctrl_pressed)
			return
		"ocioso_militar":
			atajos.ocioso(true, k.shift_pressed or k.ctrl_pressed)
			return
		"ejercito":
			atajos.todos_militares()
			return
		"del_tipo":
			atajos.todos_del_tipo()
			return
		"produccion":
			if seleccion_mixta(): # --- ronda 6 --- Tab con aldeanos y tropas: la otra grilla
				cambiar_grilla_mixta()
			else:
				atajos.recorrer_produccion()
			get_viewport().set_input_as_handled()
			return
		"ir_aviso", "avisos_atras":
			# --- avisos --- (Espacio: último ataque o suceso con lugar; Inicio: recorre los anteriores)
			if hud != null and hud.get("avisos") != null:
				var at: Variant = hud.avisos.saltar(acc == "avisos_atras")
				if at is Vector3:
					cam.look_at_point(at)
					Respuesta.pulso(self, at)  # --- fluidez 3 ---
				else:
					hud_notify("No hay avisos con lugar para ir", "info")
			return
		"centro":
			atajos.recorrer_centros(k.shift_pressed)
			return
		# --- veterano ronda 5 --- atajos globales: campana, todos los aldeanos y la producción
		"campana":
			atajos.campana()
			get_viewport().set_input_as_handled()
			return
		"todos_aldeanos":
			atajos.todos_aldeanos()
			return
		"produccion_todos":
			atajos.todos_produccion()
			get_viewport().set_input_as_handled()
			return
		# --- fin veterano ronda 5 ---
		"borrar":
			var ids := []
			for e in selected_entities():
				if e.owner == local:
					ids.append(e.id)
			sim.push_command({"t": "delete", "player": local, "ids": ids})
			return
	if acc.begins_with("grilla_"):
		var slot := int(acc.trim_prefix("grilla_"))
		var cmd := cmd_at(commands(), slot) # lo mismo que dibuja la grilla (hud.gd)
		if not cmd.is_empty():
			run_command(cmd)
		return
	# --- fin veterano ronda 4 ---


# --- veterano ronda 4 ---
## Grupo de control `n` (0…9): Ctrl asigna, Mayús suma, solo elige (dos toques: centra).
## Con grupos exclusivos (Opciones → Teclas, como AoE4) asignar o sumar saca a esas unidades
## de los otros grupos.
func _grupo(n: int, asignar: bool, sumar: bool) -> void:
	if asignar or (sumar and not selection.is_empty()):
		var merged: Array = [] if asignar else groups.get(n, []).duplicate()
		for id in selection:
			if not merged.has(id):
				merged.append(id)
		groups[n] = merged
		var sacadas := 0
		if Teclas.grupos_exclusivos:
			for g in groups.keys():
				if g == n:
					continue
				var resto: Array = (groups[g] as Array).filter(func(id: int) -> bool: return not merged.has(id))
				sacadas += (groups[g] as Array).size() - resto.size()
				groups[g] = resto
		var extra := " (salen de otro grupo)" if sacadas > 0 else ""
		hud_notify(("Grupo %d asignado" % n if asignar else "Grupo %d: %d unidades" % [n, merged.size()]) + extra, "info")
		return
	if groups.has(n):
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
# --- fin veterano ronda 4 ---


# --- veterano ronda 4 ---
## Tecla de la casilla `slot` de la grilla tal como está asignada (Opciones → Teclas).
static func etiqueta(slot: int) -> String:
	return Teclas.texto("grilla_%d" % slot)
# --- fin veterano ronda 4 ---


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
	Respuesta.pulso(self, c / sel.size())  # --- fluidez 3 ---


func select_ids(ids: Array[int]) -> void:
	_set_selection(ids)


## Texto de efectos generado desde los datos: los números no se escriben a mano (D-008).
## --- aprender --- Nombre común de un edificio o una unidad (la capa sin civilización: "Casa",
## "Leñera", "Aldeano"), para la grilla con nombres; vacío si el propio ya es ese o no hay común
## (los edificios propios de una civ). Jugador nuevo, ronda 3. Los almacenes, por lo que reciben
## (proceso/24, 4m: el tapyi guaraní es "Granero y leñera", no "Leñera"): Grilla.comun.
func common_name(type: String) -> String:
	return Grilla.comun(sim.data, sim.dp(local), type)


func effects_text(efectos: Array) -> String:
	var parts: Array[String] = []
	for ef: Dictionary in efectos:
		match ef["tipo"]:
			"tasa":
				parts.append("+%d%% de recolección de %s" % [ef["pct"], RES_LABEL.get(ef["recurso"], ef["recurso"])])
			"carga":
				parts.append("+%d de carga por viaje" % ef["n"])
			"ataque":
				parts.append("+%d de ataque %s" % [ef["n"], functions_text(ef.get("funciones", []))])
			"armadura":
				var contra: String = {"cuerpo": " contra cuerpo a cuerpo", "distancia": " contra distancia"}.get(ef.get("contra", ""), "")
				var who := functions_text(ef.get("funciones", []))
				if contra != "" and who == "militar":
					who = "de toda la tropa"
				parts.append("+%d de armadura %s%s" % [ef["n"], who, contra])
			"vida_pct":
				if ef.has("lineas"):
					parts.append("+%d%% de vida de %s" % [ef["pct"], lines_text(ef["lineas"])])
				elif ef.get("funciones", []) == ["civil"]:
					parts.append("+%d%% de vida de los aldeanos" % ef["pct"]) # --- paso 3 ---
				else:
					parts.append("+%d%% de vida militar" % ef["pct"])
			"ataque_pct":
				parts.append("+%d%% de ataque de %s" % [ef["pct"], lines_text(ef["lineas"])])
			"velocidad_pct":
				if ef.get("funciones", []) == ["civil"]:
					parts.append("+%d%% de velocidad de los aldeanos" % ef["pct"]) # --- paso 3 ---
				else:
					parts.append("+%d%% de velocidad militar" % ef["pct"])
			# --- paso 3 --- escuela de la IV
			"asedio_pct":
				parts.append("+%d%% de ataque del asedio contra edificios" % ef["pct"])
			"asedio_reparable":
				parts.append("Los aldeanos reparan el asedio en el campo")
			"costo_tec_pct":
				parts.append("−%d%% de costo de las mejoras de la edad %s" % [ef["pct"], Sim._roman(ef["edad_min"])])
			"edificio_vida_pct":
				parts.append("+%d%% de vida de los edificios" % ef["pct"])
			"edificio_ataque":
				parts.append("+%d de ataque de centros, torres e hitos" % ef["n"])
			"edificio_alcance":
				parts.append("+%.1f casillas de alcance de los edificios" % (ef["n"] / 1000.0))
			# --- paso 4 ---
			"edificio_flechas":
				parts.append("+%d %s por andanada de %s" % [ef["n"], "flecha" if int(ef["n"]) == 1 else "flechas", "las fortalezas" if ef.has("tipos") else "centros, torres, fortalezas e hitos"])
			"reparacion_pct":
				parts.append("+%d%% de velocidad de reparación" % ef["pct"])
			# --- fin paso 4 ---
			# --- paso 6 --- saberes propios
			"habilita":
				parts.append("Permite construir: %s" % ", ".join((ef["edificios"] as Array).map(func(t: String) -> String: return String(sim.dp(local).edificios.get(t, {}).get("nombre", t)))))
			"relevo_pct":
				parts.append("El relevo cura %d%% más" % ef["pct"])
			"arreo_extra":
				parts.append("+%d %s arreada por minuto" % [ef["n"], "cabeza" if int(ef["n"]) == 1 else "cabezas"])
			"corral_pct":
				parts.append("+%d%% de cabezas por corral" % ef["pct"])
			"renta":
				parts.append("+%d de %s por minuto por cada %s" % [ef["por_min"], RES_LABEL.get(ef["recurso"], ef["recurso"]), ", ".join((ef["tipos"] as Array).map(func(t: String) -> String: return String(sim.dp(local).edificios.get(t, {}).get("nombre", t))))])
			"mercado_venta_pct":
				parts.append("+%d%% de riqueza por lo que se vende en el mercado" % ef["pct"])
			"costo_unidad_pct":
				parts.append("%d%% de costo de %s" % [ef["pct"], ", ".join((ef["tipos"] as Array).map(func(t: String) -> String: return String(sim.dp(local).unidades.get(t, {}).get("nombre", t))))])
			"cantidad_pct":
				parts.append("+%d%% de duración de las rozas" % ef["pct"])
			"velocidad_vado_pct":
				parts.append("+%d%% de velocidad en los vados" % ef["pct"])
			"carga_rio":
				parts.append("+%d de carga a %d casillas del agua" % [ef["n"], ef.get("radio", 2)])
			"regen_monte":
				parts.append("La tropa junto al monte sana %d de vida por segundo fuera de combate" % ef["n"])
			"obra_pct":
				parts.append("%d%% de tiempo de obra de %s" % [ef["pct"], ", ".join((ef["tipos"] as Array).map(func(t: String) -> String: return String(sim.dp(local).edificios.get(t, {}).get("nombre", t))))])
			"costo_edificio_pct":
				parts.append("%d%% de %s en casas y almacenes" % [ef["pct"], RES_LABEL.get(ef.get("recurso", ""), "costo")])
			"potiro_extra":
				parts.append("+%d%% de obra por constructor (potirõ)" % ef["n"])
			"alcance":
				parts.append("+%.0f %s de alcance de %s" % [ef["n"] / 1000.0, "casilla" if int(ef["n"]) == 1000 else "casillas", ", ".join((ef["tipos"] as Array).map(func(t: String) -> String: return String(sim.dp(local).unidades.get(t, {}).get("nombre", t))))])
			"armadura_rio":
				parts.append("+%d de armadura %s a %d casillas del agua" % [ef["n"], functions_text(ef.get("funciones", [])), ef.get("radio", 2)])
			"emboscada_pct":
				parts.append("+%d%% de daño de la emboscada" % ef["pct"])
			# --- paso 6, par 2 --- Etiopía y Palmares
			"renta_pct":
				parts.append("+%d%% de renta de %s" % [ef["pct"], ", ".join((ef["tipos"] as Array).map(func(t: String) -> String: return String(sim.dp(local).edificios.get(t, {}).get("nombre", t))))])
			"altura_pct":
				parts.append("+%d%% de defensa en altura" % ef["pct"])
			"ataque_ruta_pct":
				parts.append("+%d%% de ataque a la pólvora mientras haya un mercado propio en pie" % ef["pct"])
			"oficios_pct":
				parts.append("+%d%% de riqueza de los oficios" % ef["pct"])
			"espinas_pct":
				parts.append("+%d%% de daño de las espinas de las cercas" % ef["pct"])
			"esquiva_pct":
				parts.append("-%d%% de daño de la distancia mientras se mueven (%s)" % [ef["pct"], ", ".join((ef["tipos"] as Array).map(func(t: String) -> String: return String(sim.dp(local).unidades.get(t, {}).get("nombre", t))))])
			"kilombo":
				parts.append("De cada %d que llegan por la fama, 1 entra como %s" % [ef["cada"], String(sim.dp(local).unidades.get(ef["unidad"], {}).get("nombre", ef["unidad"]))])
			"vision_edificio":
				parts.append("+%d casillas de visión de %s" % [int(ef["n"]) / 1000, ", ".join((ef["tipos"] as Array).map(func(t: String) -> String: return String(sim.dp(local).edificios.get(t, {}).get("nombre", t))))])
			# --- paso 6, par 3 --- Tawantinsuyu y Ayutthaya
			"camino_pct":
				parts.append("+%d%% de velocidad en los caminos" % ef["pct"])
			"suai_pct":
				parts.append("+%d%% de riqueza del suai" % ef["pct"])
			"regen_tropa":
				parts.append("La tropa sana %d de vida por segundo tras %d s sin pelear" % [ef["n"], int(ef.get("espera_ms", 0)) / 1000])
			"trepanacion":
				parts.append("%d%% de %s que caen a golpes a %d casillas de %s no mueren: vuelven con el %d%% de la vida" % [ef["pct"], ", ".join((ef["tipos"] as Array).map(func(t: String) -> String: return String(sim.dp(local).unidades.get(t, {}).get("nombre", t)))), ef["radio"], ", ".join((ef["edificios"] as Array).map(func(t: String) -> String: return String(sim.dp(local).edificios.get(t, {}).get("nombre", t)))), ef["vida_pct"]])
			# --- fin paso 6 ---
	return " · ".join(parts)


## --- ronda 8 --- Qué hito pide la maravilla (la vía guaraní) o cuál la impide (el Pacto de
## Cucaú), y si ya está hecho: el veterano llegó a la IV sin saberlo (proceso/22-testers/ronda-8).
func wonder_hito_text(def: Dictionary) -> String:
	var dd := sim.dp(local)
	if def.has("requiere_hito"):
		var h: String = def["requiere_hito"]
		var n: String = dd.edificios.get(h, {}).get("nombre", h)
		return "Pide el hito %s: hay que haberlo elegido al subir de edad. %s" % [n, "Ya lo tenés." if sim.has_done_hito(local, h) else "Todavía no lo levantaste."]
	if def.has("impide_hito"):
		var h: String = def["impide_hito"]
		var n: String = dd.edificios.get(h, {}).get("nombre", h)
		return "Con el hito %s no se puede levantar. %s" % [n, "Lo levantaste: esta maravilla quedó cerrada." if sim.has_done_hito(local, h) else "No lo levantaste: sigue abierta."]
	return ""


## --- paso 7 --- Qué da la maravilla mientras está en pie y cómo gana (docs/diseno/27, §4.1), con
## los números de los datos (data/civs → edificios.maravilla.efectos_maravilla; reglas.maravilla).
func wonder_text(def: Dictionary) -> String:
	var parts: Array[String] = []
	for ef: Dictionary in def.get("efectos_maravilla", []):
		match String(ef["tipo"]):
			"inundacion":
				parts.append("Cuando entran %d o más soldados enemigos al llano junto al agua (a %d casillas), se inunda: andan %d%% más lento durante %d s, una vez cada %d minutos" % [ef["enemigos_min"], ef["radio"], ef["frenado_pct"], int(ef["dura_ms"]) / 1000, int(ef["cada_ms"]) / 60000])
			"sitios_protegidos":
				parts.append("Sin enemigos a %d casillas, los rivales no pueden tomar los sitios sagrados a %d casillas" % [ef["libre_radio"], ef["radio"]])
			"obra_colectiva":
				parts.append("El potirõ suma +%d%% más por cada constructor" % ef["pct_por_constructor"])
			"sigilo_monte":
				parts.append("La tropa escondida en el monte se ve desde el %d%% de la distancia" % ef["deteccion_pct"])
			"renta_pct":
				parts.append("+%d%% de renta de los gult de todo el mapa" % ef["pct"])
			"corte_fija":
				parts.append("La corte deja de mudarse")
			"fama_sin_tope":
				parts.append("La fama no se pierde por el tope")
			"acogida_pct":
				parts.append("La acogida cuesta el %d%%" % ef["pct"])
			"crecida":
				parts.append("El agua baja a %d casillas de la capital frena %d%% a la tropa enemiga, salvo a %d casillas de una torre o un fuerte suyo" % [ef["radio"], ef["frenado_pct"], ef["torre_radio"]])
	var mins := int(sim.data.reglas.get("maravilla", {}).get("victoria_ms", 0)) / 60000
	var win := "Victoria: si sigue en pie %d minutos después de terminada, gana su pueblo; si cae, la cuenta se pierde." % mins
	if def.has("sitiada"):
		win = "Victoria: si sigue en pie %d minutos, gana. No cae: con tropa enemiga a %d casillas, la cuenta vuelve a empezar." % [mins, int(def["sitiada"].get("radio", 3))]
	if sim._opts.get("maravilla_sin_victoria", false):
		win = "En esta partida la maravilla no gana (opciones de partida)."
	return ("Mientras está en pie: " + "; ".join(parts) + ".\n" if not parts.is_empty() else "") + win


## --- paso 4 --- Efectos de un hito que lleva a `dest_age`: los de combate de los hitos
## militares de la III y la IV valen en su aura (C-76 a; reglas.aura_hito.militar).
func hito_effects_text(def: Dictionary, dest_age: int) -> String:
	var efs: Array = def.get("efectos", [])
	if not sim.hito_combat_in_aura(def, dest_age):
		return effects_text(efs)
	var glob: Array = []
	var aura: Array = []
	for ef: Dictionary in efs:
		(aura if String(ef["tipo"]) in Sim.AURA_TYPES else glob).append(ef)
	var parts: Array[String] = []
	if not glob.is_empty():
		parts.append(effects_text(glob))
	if not aura.is_empty():
		var r := int(sim.data.reglas.get("aura_hito", {}).get("militar", {}).get("radio", 0))
		parts.append("A %d casillas del hito o menos: %s" % [r / 1000, effects_text(aura)])
	return " · ".join(parts)


## Nombre de las líneas de un efecto: «toda la tropa» si son todas (docs/diseno/27, §1.1).
const LEVEL_NAMES := ["común", "veterano", "élite"]
const LINE_NAMES := {"choque": "choque a pie", "distancia": "la distancia", "linea": "la línea", "montados": "los montados", "polvora": "la pólvora"}


## Quién recibe una mejora por función (la herrería separa cuerpo a cuerpo y distancia, paso 2).
static func functions_text(funciones: Array) -> String:
	var has_d := funciones.has("distancia")
	var has_c := funciones.has("choque") or funciones.has("linea")
	if has_d and not has_c:
		return "de la tropa a distancia"
	if has_c and not has_d:
		return "de la tropa cuerpo a cuerpo"
	return "militar"


static func lines_text(lineas: Array) -> String:
	if lineas.size() >= LINE_NAMES.size():
		return "toda la tropa"
	var names: Array[String] = []
	for l in lineas:
		names.append(LINE_NAMES.get(l, "el asedio" if l == "asedio" else l)) # --- paso 4 ---
	if names.size() == 1 and lineas[0] == "choque":
		return "la tropa de choque a pie"
	return ", ".join(names)


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
	var bonus: int = sim.dp(local).edades[age - 1].get("bono_ataque_edificio", 0)
	var txt := "Edad %s habilita: %s" % [Sim._roman(age), ", ".join(names)] if not names.is_empty() else "Edad %s habilita:" % Sim._roman(age)
	if techs > 0:
		txt += "%s%d investigaciones" % [", " if not names.is_empty() else " ", techs]
	# La tropa ya no sube sola con la edad (paso 1 del juego tardío): lo dicen los niveles.
	var level := 0
	for k in sim.dp(local).tecnologias:
		var t: Dictionary = sim.dp(local).tecnologias[k]
		if t.has("nivel") and int(t.get("edad_min", 1)) == age:
			level = int(t["nivel"])
	if level > 0:
		txt += ". Nivel %s para cada línea, en el edificio que la entrena" % LEVEL_NAMES[level]
	# --- paso 3 --- la escuela de la IV, con su nombre
	var school := 0
	for k in sim.dp(local).tecnologias:
		var t: Dictionary = sim.dp(local).tecnologias[k]
		if t.get("escuela", false) and int(t.get("edad_min", 1)) == age:
			school += 1
	if school > 0:
		txt += ". Escuela: %s (%d mejoras, en la capital)" % [escuela_info()["nombre"], school]
	if bonus > 0:
		txt += ". Ataque de edificios +%d%%." % bonus # --- paso 4 --- el asedio sube con sus niveles
	return txt


## Casillas de una línea 4-conexa (sin huecos en diagonal por donde colarse).
static func line_tiles(a: Vector2i, b: Vector2i, tope: int = 80) -> Array:
	var out := [[a.x, a.y]]
	var x := a.x
	var y := a.y
	var dx := absi(b.x - a.x)
	var dy := -absi(b.y - a.y)
	var sx := 1 if a.x < b.x else -1
	var sy := 1 if a.y < b.y else -1
	var err := dx + dy
	while (x != b.x or y != b.y) and out.size() < tope:
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
	# --- fluidez 2 --- presupuesto con todos los recursos, cifras junto al cursor y huecos
	var plan := plan_linea(tiles)
	var estados: Array = plan["estados"]
	for i in _line_ghosts.size():
		var g := _line_ghosts[i]
		g.visible = i < tiles.size()
		if not g.visible:
			continue
		var t: Array = tiles[i]
		g.position = Vector3(t[0] + 0.5, 0.02, t[1] + 0.5)
		var col := Color(0.5, 1.0, 0.6, 0.55)
		if estados[i] == "puerta":
			col = Color(Palette.UI_ACCENT, 0.7)
		elif estados[i] != "ok":
			col = Color(1.0, 0.35, 0.3, 0.55)
		(g.material_override as StandardMaterial3D).albedo_color = col
	linea_info = plan["info"]
	# --- fin fluidez 2 ---


# --- fluidez 2 --- (proceso/30-fluidez/02-constructor.md)
## Casillas del trazo hasta `end`: con el tope de data/constructor.json y sin la casilla del
## extremo anterior cuando se encadena con Mayús.
func trazo(end: Vector2i) -> Array:
	var tiles := line_tiles(_line_start, end, int(MundoColocacion.cfg().get("muro_tope", 80)) + (1 if _line_skip else 0))
	if _line_skip and not tiles.is_empty():
		tiles.pop_front()
	return tiles


## Qué pasa con cada casilla del trazo: "ok", "puerta", "hueco" o "falta" (no alcanza), con los
## renglones «n tramos · costo · alcanzan k» y los huecos por causa. Cuenta todos los recursos.
func plan_linea(tiles: Array) -> Dictionary:
	var age: int = sim.players[local]["age"]
	var cost := sim.dp(local).cost_of(place_type, age) if place_type != "" else {}
	var gate := MundoColocacion.tipo_puerta(sim, local, place_type)
	var res: Dictionary = (sim.players[local]["res"] as Dictionary).duplicate()
	var total := {}
	var estados := []
	var tramos := 0
	var alcanzan := 0
	var causas := {}
	var lista_huecos := []
	var refuerza := 0
	for t: Array in tiles:
		var tipo := place_type
		if gate != "" and Vector2i(t[0], t[1]) == _line_gate:
			tipo = gate
		if not sim.can_place(tipo, t[0], t[1], local):
			estados.append("hueco")
			lista_huecos.append(t)
			var c := MundoColocacion.causa_hueco(sim, t[0], t[1])
			causas[c] = int(causas.get(c, 0)) + 1
			continue
		tramos += 1
		if sim._own_piece_under(tipo, t[0], t[1], local) != null: # --- muralla --- reforzar
			refuerza += 1
		var c2: Dictionary = cost if tipo == place_type else sim.dp(local).cost_of(tipo, age)
		for k in c2:
			total[k] = int(total.get(k, 0)) + int(c2[k])
		var ok := true
		for k in c2:
			ok = ok and int(res.get(k, 0)) >= int(c2[k])
		if ok:
			for k in c2:
				res[k] = int(res.get(k, 0)) - int(c2[k])
			alcanzan += 1
			estados.append("puerta" if tipo != place_type else "ok")
		else:
			estados.append("falta")
	var info := []
	if not tiles.is_empty():
		info.append(["%d %s · %s · alcanzan %d" % [tramos, "tramo" if tramos == 1 else "tramos", MundoColocacion.costo_texto(total), alcanzan], Palette.UI_TEXT if alcanzan == tramos else Palette.UI_BAD])
		if not causas.is_empty():
			var parts := []
			for c in causas:
				parts.append(c if causas.size() == 1 else "%d por %s" % [causas[c], c])
			var nh := lista_huecos.size()
			info.append(["%d %s: %s" % [nh, "hueco" if nh == 1 else "huecos", ", ".join(parts)], Palette.UI_BAD])
		if refuerza > 0:
			info.append(["Refuerza %d %s" % [refuerza, "tramo" if refuerza == 1 else "tramos"], Palette.UI_DIM])
		if gate != "":
			info.append(["G: puerta en la casilla del cursor" if _line_gate.x < 0 else "Puerta en el trazo (G la mueve)", Palette.UI_DIM])
		if tiles.size() >= int(MundoColocacion.cfg().get("muro_tope", 80)):
			info.append(["Tope de %d casillas por trazo" % int(MundoColocacion.cfg().get("muro_tope", 80)), Palette.UI_ACCENT])
		info.append(["Mayús: seguir desde el extremo", Palette.UI_DIM])
	return {"estados": estados, "info": info, "huecos": lista_huecos, "causas": causas, "tramos": tramos, "alcanzan": alcanzan, "total": total, "refuerza": refuerza}


## G mientras se arrastra: la casilla del trazo más cercana al cursor va de puerta.
func marcar_puerta() -> void:
	var tile: Vector2i = _ghost.get_meta("tile", _line_start)
	var tiles := trazo(tile)
	if tiles.is_empty() or MundoColocacion.tipo_puerta(sim, local, place_type) == "":
		return
	var g := cam.ground_at(mouse_pos())
	var best: Array = tiles[0]
	for t: Array in tiles:
		if Vector2(t[0] + 0.5, t[1] + 0.5).distance_to(Vector2(g.x, g.z)) < Vector2(best[0] + 0.5, best[1] + 0.5).distance_to(Vector2(g.x, g.z)):
			best = t
	_line_gate = Vector2i(best[0], best[1])
# --- fin fluidez 2 ---


func _finish_line() -> void:
	_line_drag = false
	var tile: Vector2i = _ghost.get_meta("tile", _line_start)
	var tiles := trazo(tile) # --- fluidez 2 ---
	var ids := []
	for e in selected_entities():
		if e.owner == local and e.fn == "civil":
			ids.append(e.id)
	# --- fluidez 2 --- la puerta va aparte; los huecos se avisan y quedan marcados
	var plan := plan_linea(tiles)
	var gate := MundoColocacion.tipo_puerta(sim, local, place_type)
	var muro := []
	for t: Array in tiles:
		if gate == "" or Vector2i(t[0], t[1]) != _line_gate:
			muro.append(t)
	if not muro.is_empty():
		sim.push_command({"t": "build_line", "player": local, "ids": ids, "type": place_type, "tiles": muro})
	if gate != "" and _line_gate.x >= 0 and tiles.any(func(t: Array) -> bool: return Vector2i(t[0], t[1]) == _line_gate):
		sim.push_command({"t": "build", "player": local, "ids": [] if not muro.is_empty() else ids, "type": gate, "tx": _line_gate.x, "ty": _line_gate.y})
	huecos = plan["huecos"]
	if not huecos.is_empty():
		huecos_hasta = Time.get_ticks_msec() + int(MundoColocacion.cfg().get("huecos_marca_s", 6)) * 1000
		var parts := []
		for c in plan["causas"]:
			parts.append(c)
		var nombre := String(sim.dp(local).edificios[place_type].get("nombre", "El muro"))
		if hud != null: # con lugar: Espacio lleva al primer hueco
			hud.notify("%s quedó con %d %s (%s)" % [nombre, huecos.size(), "hueco" if huecos.size() == 1 else "huecos", ", ".join(parts)], -1.0, "info", Vector3(huecos[0][0] + 0.5, 0, huecos[0][1] + 0.5))
	linea_info = []
	_line_gate = Vector2i(-1, -1)
	_line_chain = Vector2i(-1, -1)
	if Input.is_key_pressed(KEY_SHIFT):
		_line_chain = Vector2i(tiles[-1][0], tiles[-1][1]) if not tiles.is_empty() else _line_start
	_line_skip = false
	# --- fin fluidez 2 ---
	_show_line([])
	if not Input.is_key_pressed(KEY_SHIFT):
		cancel_mode()
		submenu = Grilla.RAIZ # --- grilla ---


# --- fluidez 2 ---
## Edificios propios dañados cerca de los aldeanos elegidos (para el candado de «Reparar (zona)»).
func _danados_zona() -> int:
	if cola == null:
		return 0
	var n := 0
	var cx := 0
	var cy := 0
	for e in selected_entities():
		if e.owner == local and e.fn == "civil":
			cx += e.x
			cy += e.y
			n += 1
	if n == 0:
		return 0
	return 1 if cola.danado_cerca(cx / n, cy / n, int(MundoColocacion.cfg().get("reparar_zona_radio", 12)) * P) != null else 0
# --- fin fluidez 2 ---
