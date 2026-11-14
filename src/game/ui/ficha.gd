class_name Ficha
extends Control
## Ficha al pasar el mouse (docs/07, "Interfaz"): retrato, nombre en la lengua del pueblo
## y en castellano llano, pueblo y bandera, función, qué hace, estadísticas, costo, estado
## actual de la entidad y contra qué es fuerte o débil. Todo sale de data/ y de la simulación,
## que aquí solo se lee.
##
## Fuentes, por prioridad:
##   1. zonas registradas por otros paneles (retratos de la selección, cola de producción);
##   2. botón de la grilla de comandos (Hud.show_tip la abre con show_command);
##   3. entidad del mundo bajo el cursor (WorldView.hovered, que calcula el Controller).
##
## Para capturas: `-- --ficha=tipo` fija la ficha sobre la primera entidad de ese tipo
## (propia si hay), `-- --ficha=cmd:N` sobre la ranura N de la grilla de la selección y
## `-- --ficha=zona:N` sobre la zona N registrada (retratos de la selección, cola).

const O := SimEntity.Order
const W := 392.0
const PAD := 14.0
const PORTRAIT := 104.0
const DELAY_WORLD := 0.45
const DELAY_ZONE := 0.22
const DELAY_CMD := 0.1
const RETRATOS := "res://assets/generados/retratos"

const FN_NAMES := {"civil": "civil", "choque": "choque", "distancia": "distancia", "linea": "línea", "explorador": "exploradores", "asedio": "asedio", "edificio": "edificios"}
const FN_ROLE := {
	"civil": "Civil · recolecta, construye y repara",
	"choque": "Choque · cuerpo a cuerpo, rápido y pesado",
	"distancia": "Distancia · golpea desde lejos, frágil de cerca",
	"linea": "Línea · escudo al frente y lanza larga",
	"explorador": "Exploración · rápido y de visión amplia",
	"asedio": "Asedio · derriba edificios",
}
const RES_DESC := {
	"madera": "Los aldeanos la talan y la llevan al depósito más cercano.",
	"alimento": "Alimento que se junta a mano; se agota y no vuelve.",
	"piedra": "Piedra para torres, centros y obras grandes. Se pica despacio.",
	"riqueza": "Riqueza: paga tropas de élite, investigaciones e hitos.",
}

var hud: Hud
var sim: Sim
var ctrl: Controller

static var _tex_cache := {}

var _zones: Array = [] # [Control fuente, Rect2 global, payload]
var _cmd: Dictionary = {}
var _cmd_anchor := Rect2()
var _key := "" # qué se muestra (para reiniciar el retraso al cambiar)
var _payload: Dictionary = {}
var _wait := 0.0
var _alpha := 0.0
var _pin := ""


func setup(h: Hud) -> void:
	hud = h
	sim = h.sim
	ctrl = h.ctrl
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	z_index = 50
	visible = false
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--ficha="):
			_pin = a.substr(8)


# ---------------------------------------------------------------- Enganches

## Una zona de pantalla que, al pasar el mouse, muestra la ficha de `payload`
## ({"id": entidad} o {"type": tipo, "owner": jugador}). Se registran al dibujar.
func zone(src: Control, r: Rect2, payload: Dictionary) -> void:
	_zones.append([src, Rect2(src.get_global_transform() * r.position, r.size), payload])


## Borra las zonas de un panel antes de que vuelva a dibujarlas.
func zones_begin(src: Control) -> void:
	var keep: Array = []
	for z in _zones:
		if z[0] != src and is_instance_valid(z[0]):
			keep.append(z)
	_zones = keep


## Comandos con ficha propia: construir, entrenar e investigar.
static func handles(cmd: Dictionary) -> bool:
	return cmd.get("kind", "") in ["build", "train", "research"]


func show_command(cmd: Dictionary, anchor: Rect2) -> void:
	_cmd = cmd
	_cmd_anchor = anchor


func hide_command() -> void:
	_cmd = {}


# ---------------------------------------------------------------- Ciclo

func _process(delta: float) -> void:
	var want := _pick()
	var key := str(want.get("key", ""))
	if key != _key:
		_key = key
		_payload = want
		_wait = float(want.get("delay", 0.0))
		_alpha = 0.0
	else:
		_payload = want
	if key == "" or _blocked():
		visible = false
		return
	_wait -= delta
	if _wait > 0.0:
		visible = false
		return
	_alpha = minf(1.0, _alpha + delta / 0.12)
	modulate.a = _alpha
	visible = true
	size = Vector2(W, _paint(false))
	_place()
	queue_redraw()


func _blocked() -> bool:
	if hud == null or not hud.visible:
		return true
	for n in ["_menu", "_end", "_options", "_help"]:
		var c: Control = hud.get(n)
		if c != null and c.visible:
			return true
	return false


## Qué mostrar ahora, con su retraso.
func _pick() -> Dictionary:
	if _pin != "":
		return _pinned()
	var m := ctrl.mouse_pos()
	for i in range(_zones.size() - 1, -1, -1):
		var z: Array = _zones[i]
		if not is_instance_valid(z[0]) or not (z[0] as Control).is_visible_in_tree():
			continue
		if (z[1] as Rect2).has_point(m):
			var p: Dictionary = (z[2] as Dictionary).duplicate()
			p["key"] = "z:%s" % str(z[2])
			p["delay"] = DELAY_ZONE
			p["at"] = z[1]
			return p
	if not _cmd.is_empty():
		return {"key": "c:%s:%s" % [_cmd.get("id", ""), _cmd.get("slot", -1)], "cmd": _cmd, "delay": DELAY_CMD, "at": _cmd_anchor}
	if ctrl.mode != "" or ctrl.dragging or hud.blocks(m):
		return {}
	var id := ctrl.view.hovered
	if id < 0:
		id = _site_under(m)
	if id >= 0 and sim.by_id.has(id):
		return {"key": "e:%d" % id, "id": id, "delay": DELAY_WORLD}
	return {}


## Los sitios sagrados son transitables: no ocupan casillas y el pick del Controller no los ve.
func _site_under(m: Vector2) -> int:
	var g := ctrl.cam.ground_at(m)
	for e in sim.actives:
		if e.alive and e.def.get("sagrado", false) and g.x >= e.tx and g.x < e.tx + e.w and g.z >= e.ty and g.z < e.ty + e.h:
			if ctrl.view.fog_state(e) > 0:
				return e.id
	return -1


func _pinned() -> Dictionary:
	if _pin.begins_with("zona:"):
		var n := int(_pin.substr(5))
		if n >= _zones.size():
			return {}
		var p: Dictionary = (_zones[n][2] as Dictionary).duplicate()
		p.merge({"key": "pin", "delay": 0.0, "at": _zones[n][1]})
		return p
	if _pin.begins_with("cmd:"):
		var slot := int(_pin.substr(4))
		for c in ctrl.commands():
			if c["slot"] == slot:
				var card: Control = hud.get("_card")
				return {"key": "pin", "cmd": c, "delay": 0.0, "at": card.get_global_rect() if card != null else Rect2()}
		return {}
	var best: SimEntity = null
	for e in sim.entities:
		if e.alive and e.type == _pin and e.inside < 0 and (best == null or (e.owner == hud.local and best.owner != hud.local)):
			best = e
	if best == null:
		return {}
	var sp := ctrl.cam.cam.unproject_position(WorldView.to_world(best.x, best.y))
	return {"key": "pin", "id": best.id, "delay": 0.0, "mouse": sp}


## Junto al cursor sin taparlo; anclada arriba del panel si viene de la interfaz. Nunca sale de la pantalla.
func _place() -> void:
	var scr := get_viewport_rect().size
	var p: Vector2
	if _payload.has("at"):
		var a: Rect2 = _payload["at"]
		p = Vector2(a.end.x - size.x, a.position.y - size.y - 10)
		if _payload.has("id") or _payload.has("type"):
			p = Vector2(a.position.x + a.size.x * 0.5 - size.x * 0.5, a.position.y - size.y - 10)
		if p.y < 8:
			p.y = a.end.y + 10
	else:
		var m: Vector2 = _payload.get("mouse", ctrl.mouse_pos())
		p = m + Vector2(24, 26)
		if p.x + size.x > scr.x - 8:
			p.x = m.x - size.x - 18
		if p.y + size.y > scr.y - 8:
			p.y = m.y - size.y - 14
	p.x = clampf(p.x, 8, maxf(8, scr.x - size.x - 8))
	p.y = clampf(p.y, 8, maxf(8, scr.y - size.y - 8))
	position = p


func _draw() -> void:
	if _key == "":
		return
	var sb := Hud.panel_box(9)
	sb.bg_color = Color(0.06, 0.065, 0.075, 0.96)
	sb.border_color = Color(Palette.UI_ACCENT, 0.28)
	sb.shadow_size = 14
	draw_style_box(sb, Rect2(Vector2.ZERO, size))
	_paint(true)


# ---------------------------------------------------------------- Contenido

## Arma la ficha del pedido actual: un diccionario con todo lo que se dibuja.
func _content() -> Dictionary:
	if _payload.has("cmd"):
		return _cmd_content(_payload["cmd"])
	if _payload.has("id"):
		var e: SimEntity = sim.by_id.get(_payload["id"])
		if e == null or not e.alive:
			return {}
		return _entity_content(e)
	if _payload.has("type"):
		return _type_content(int(_payload.get("owner", hud.local)), _payload["type"])
	return {}


func _base(owner: int, type: String) -> Dictionary:
	var dd := sim.dp(owner)
	var def: Dictionary = dd.def_of(type)
	var common: Dictionary = sim.data.def_of(type)
	var c := {"owner": owner, "type": type, "def": def, "name": def.get("nombre", type), "alt": "", "lines": [], "stats": [], "cost": {}, "time": 0, "state": [], "strong": "", "weak": "", "foot": [], "is_res": false}
	var base_name: String = common.get("nombre", "")
	if base_name != "" and base_name != c["name"] and dd.clave != "":
		c["alt"] = base_name
	c["tex"] = portrait(dd.clave, type)
	return c


func _type_content(owner: int, type: String) -> Dictionary:
	var dd := sim.dp(owner)
	var c := _base(owner, type)
	var def: Dictionary = c["def"]
	var age: int = sim.players[owner]["age"] if owner >= 0 else 1
	c["cost"] = dd.cost_of(type, age)
	if dd.unidades.has(type):
		c["role"] = _unit_role(def)
		c["desc"] = Controller.DESCS.get(type, def.get("desc", ""))
		c["time"] = int(def.get("tiempo_ms", 0))
		c["stats"] = _unit_stats(owner, def, -1, -1)
		_counters(c, def.get("funcion", ""), def)
	elif dd.edificios.has(type):
		c["role"] = _building_role(dd, type, def)
		c["desc"] = _building_desc(dd, type, def)
		c["time"] = dd.build_time_of(type, age)
		c["stats"] = _building_stats(owner, def, -1, -1)
		_counters(c, "edificio", def)
	elif dd.tecnologias.has(type):
		c["role"] = "Investigación · %s" % dd.edificios.get(def.get("edificio", ""), {}).get("nombre", "")
		c["desc"] = def.get("desc", "")
		c["effects"] = ctrl.effects_text(def.get("efectos", []))
		c["cost"] = def.get("costo", {})
		c["time"] = int(def.get("tiempo_ms", 0))
	return c


func _cmd_content(cmd: Dictionary) -> Dictionary:
	var c := _type_content(hud.local, cmd["id"])
	if cmd["kind"] == "research":
		c["glyph"] = cmd.get("icon", "")
	c["name"] = cmd.get("name", c["name"])
	if cmd["kind"] == "build" and sim.dp(hud.local).is_hito(cmd["id"]):
		c["desc"] = cmd.get("desc", "")
	c["cost"] = cmd.get("cost", c["cost"])
	c["check_cost"] = true
	c["hotkey"] = Controller.SLOT_LABELS[cmd["slot"]]
	var n := 0
	for e in sim.actives:
		if e.alive and e.owner == hud.local and e.type == cmd["id"]:
			n += 1
	match cmd["kind"]:
		"train":
			var b: SimEntity = sim.by_id.get(cmd.get("building", -1))
			var queued := b.queue.count(cmd["id"]) if b != null else 0
			if n > 0:
				c["state"].append(["Tenés %d en el mapa" % n, Palette.UI_DIM])
			if queued > 0:
				c["state"].append(["%d en la cola de este edificio" % queued, Palette.UI_ACCENT])
			c["foot"].append(["Clic: entrenar · Mayús + clic: cinco", Palette.UI_DIM])
		"build":
			if n > 0:
				c["state"].append(["Tenés %d construidos" % n, Palette.UI_DIM])
			var maxes: Array = c["def"].get("maximo_por_edad", [])
			if not maxes.is_empty():
				var age: int = sim.players[hud.local]["age"]
				c["state"].append(["Máximo en esta edad: %d" % int(maxes[mini(age, maxes.size()) - 1]), Palette.UI_DIM])
			c["foot"].append(["Clic y elegí el lugar · Mayús: varios seguidos", Palette.UI_DIM])
		"research":
			c["foot"].append(["Clic: investigar en este edificio", Palette.UI_DIM])
	if cmd.get("locked", "") != "":
		c["foot"].append([cmd["locked"], Palette.UI_BAD])
	return c


func _entity_content(e: SimEntity) -> Dictionary:
	var fog := ctrl.view.fog_state(e)
	var live := fog == 2 or e.owner == hud.local
	if e.is_resource():
		return _resource_content(e, live)
	var c := _type_content(e.owner, e.type)
	c["entity"] = e
	if e.is_unit():
		c["stats"] = _unit_stats(e.owner, e.def, e.hp, e.hp_max)
	else:
		c["stats"] = _building_stats(e.owner, e.def, e.hp, e.hp_max)
	if int(_payload.get("n", 1)) > 1:
		c["state"].append(["%d de este tipo en la selección (mostrando una)" % int(_payload["n"]), Palette.UI_ACCENT])
	if e.def.get("sagrado", false):
		c["stats"] = []
		c["weak"] = ""
		c["no_hp"] = true
	if not live:
		c["state"].append(["Fuera de la vista: lo último que se vio", Palette.UI_DIM])
		return c
	if e.def.get("sagrado", false):
		_site_state(c, e)
	elif e.is_unit():
		_unit_state(c, e)
	else:
		_building_state(c, e)
	return c


func _resource_content(e: SimEntity, live: bool) -> Dictionary:
	var c := _base(-1, e.type)
	c["is_res"] = true
	c["entity"] = e
	c["tex"] = portrait("", e.type)
	var kind := e.res_kind
	var def: Dictionary = c["def"]
	c["role"] = "Recurso · %s" % Palette.RES_NAMES.get(kind, kind).to_lower()
	c["desc"] = def.get("desc", RES_DESC.get(kind, ""))
	if not live:
		c["state"].append(["Fuera de la vista", Palette.UI_DIM])
		return c
	var full := maxi(e.amount, int(def.get("cantidad", e.amount)))
	c["bar"] = [float(e.amount) / float(maxi(1, full)), Palette.RES.get(kind, Palette.UI_ACCENT)]
	c["state"].append(["Quedan %d de %d" % [e.amount, full], Palette.RES.get(kind, Palette.UI_TEXT)])
	var workers := 0
	for u in sim.actives:
		if u.alive and u.is_unit() and u.target == e.id and (u.order == O.GATHER or u.order == O.RETURN):
			workers += 1
	if workers > 0:
		c["state"].append(["%d %s trabajando acá" % [workers, "aldeano" if workers == 1 else "aldeanos"], Palette.UI_TEXT])
	if e.res_owner >= 0:
		c["state"].append(["Arcilla de %s" % _who(e.res_owner), Palette.team(e.res_owner).lightened(0.25)])
	elif def.get("recurso", "") == "riqueza" and e.type == "riqueza":
		c["state"].append(["Disputada: la saca quien llegue", Palette.UI_DIM])
	return c


# ---------------------------------------------------------------- Textos desde los datos

func _unit_role(def: Dictionary) -> String:
	var r: String = FN_ROLE.get(def.get("funcion", ""), "")
	var extra: Array[String] = []
	if def.get("elefante", false):
		extra.append("elefante de guerra")
	elif def.get("montado", false):
		extra.append("a caballo")
	if def.get("polvora", false):
		extra.append("pólvora")
	if not extra.is_empty():
		r += " · " + ", ".join(extra)
	return r


func _building_role(dd: SimData, type: String, def: Dictionary) -> String:
	if def.get("sagrado", false):
		return "Sitio sagrado · se toma con presencia"
	if def.get("avanza_edad", false):
		return "Hito · lleva a la edad siguiente"
	var parts: Array[String] = []
	if def.has("produce"):
		var names: Array[String] = []
		for u: String in def["produce"]:
			names.append(dd.unidades.get(u, {}).get("nombre", u))
		parts.append("Entrena: " + ", ".join(names))
	if def.has("conversion"):
		parts.append("Motor de economía")
	if def.has("renta"):
		parts.append("Renta sin aldeanos")
	if def.has("fuente"):
		parts.append("Fuente de alimento")
	if def.get("mercado", false):
		parts.append("Comercio")
	if def.has("deposito") and not def.has("produce"):
		parts.append("Depósito")
	if def.has("flechas") and not def.has("produce"):
		parts.append("Defensa a distancia")
	if def.get("linea", false):
		parts.append("Muralla")
	if def.has("pob") and parts.is_empty():
		parts.append("Vivienda · +%d de población" % def["pob"])
	if def.get("camino", false):
		parts.append("Camino")
	return " · ".join(parts)


func _building_desc(dd: SimData, type: String, def: Dictionary) -> String:
	var d: String = def.get("desc", "")
	if d == "":
		d = Controller.DESCS.get(type, "")
	if def.has("deposito"):
		var names: Array[String] = []
		for k: String in def["deposito"]:
			names.append(Palette.RES_NAMES.get(k, k).to_lower())
		d += ("\n" if d != "" else "") + "Recibe %s." % ", ".join(names)
	return d


func _unit_stats(owner: int, def: Dictionary, hp: int, hp_max: int) -> Array:
	var fn: String = def.get("funcion", "")
	var atk: int = def.get("ataque", 0)
	var atk_bonus := sim.mod(owner, "ataque:" + fn) if owner >= 0 else 0
	var arm: int = def.get("armadura", 0)
	var arm_bonus := sim.mod(owner, "armadura:" + fn) if owner >= 0 else 0
	var reach: int = def.get("alcance", 0)
	var out := [
		["Vida", "%d/%d" % [hp, hp_max] if hp >= 0 else str(def.get("pv", 0)), _hp_col(hp, hp_max)],
		["Ataque", _plus(atk, atk_bonus), Palette.UI_TEXT],
		["Armadura", _plus(arm, arm_bonus), Palette.UI_TEXT],
		["Alcance", "contacto" if reach <= 1000 else "%.1f casillas" % (reach / 1000.0), Palette.UI_TEXT],
		["Velocidad", "%.2f" % (def.get("velocidad", 0) / 1000.0), Palette.UI_TEXT],
		["Cadencia", "%.1f s" % (def.get("cadencia_ms", 0) / 1000.0), Palette.UI_TEXT],
		["Visión", "%d" % (def.get("vision", 0) / 1000), Palette.UI_TEXT],
		["Población", str(def.get("pob", 1)), Palette.UI_TEXT],
	]
	if def.has("carga"):
		out.append(["Carga", str(int(def["carga"]) + (sim.mod(owner, "carga") if owner >= 0 else 0)), Palette.UI_TEXT])
	if def.has("municion"):
		out.append(["Munición", str(def["municion"]), Palette.UI_TEXT])
	return out


func _building_stats(owner: int, def: Dictionary, hp: int, hp_max: int) -> Array:
	var out := [["Vida", "%d/%d" % [hp, hp_max] if hp >= 0 else str(def.get("pv", 0)), _hp_col(hp, hp_max)], ["Armadura", str(def.get("armadura", 0)), Palette.UI_TEXT]]
	if def.has("ataque"):
		out.append(["Ataque", _plus(int(def["ataque"]), sim.mod(owner, "b_ataque") if owner >= 0 else 0), Palette.UI_TEXT])
		out.append(["Alcance", "%.1f casillas" % (def.get("alcance", 0) / 1000.0), Palette.UI_TEXT])
	if def.get("guarnicion", 0) > 0:
		out.append(["Guarnición", str(def["guarnicion"]), Palette.UI_TEXT])
	if def.has("pob"):
		out.append(["Población", "+%d" % def["pob"], Palette.UI_TEXT])
	var tam: Array = def.get("tam", [])
	if tam.size() == 2:
		out.append(["Tamaño", "%d×%d" % [tam[0], tam[1]], Palette.UI_TEXT])
	if def.has("vision"):
		out.append(["Visión", "%d" % (int(def["vision"]) / 1000), Palette.UI_TEXT])
	return out


## Contadores de reglas.json: multiplicadores de daño de una función contra otra.
func _counters(c: Dictionary, fn: String, def: Dictionary) -> void:
	var tab: Dictionary = sim.data.reglas.get("contadores", {})
	var strong: Array[String] = []
	var weak: Array[String] = []
	var mine: Dictionary = tab.get(fn, {})
	for t: String in mine:
		var k := int(mine[t])
		if k > 100:
			strong.append("%s ×%s" % [FN_NAMES.get(t, t), _mult(k)])
		elif k == 0:
			weak.append("no daña a %s" % FN_NAMES.get(t, t))
		elif k < 100 and fn != "edificio":
			weak.append("pega poco a %s (×%s)" % [FN_NAMES.get(t, t), _mult(k)])
	for f: String in tab:
		var k := int((tab[f] as Dictionary).get(fn, 100))
		if k > 100 and f != fn:
			weak.append("sufre contra %s ×%s" % [FN_NAMES.get(f, f), _mult(k)])
	if def.get("solo_edificios", false):
		weak.append("no ataca unidades")
	c["strong"] = ", ".join(strong)
	c["weak"] = ", ".join(weak)


static func _mult(k: int) -> String:
	var s := "%.2f" % (k / 100.0)
	return s.rstrip("0").rstrip(".")


static func _plus(base: int, bonus: int) -> String:
	return str(base) if bonus == 0 else "%d (+%d)" % [base + bonus, bonus]


static func _hp_col(hp: int, hp_max: int) -> Color:
	if hp < 0:
		return Palette.UI_TEXT
	return Palette.UI_GOOD if hp * 3 > hp_max else Palette.UI_BAD


func _who(pid: int) -> String:
	if pid < 0:
		return "nadie"
	if pid == hud.local:
		return "tu pueblo"
	var civ: String = sim.dp(pid).civ.get("nombre", "")
	return "%s (%s)" % [civ, Palette.TEAM_NAMES[pid % Palette.TEAM_NAMES.size()]] if civ != "" else Palette.TEAM_NAMES[pid % Palette.TEAM_NAMES.size()]


func _name_of(e: SimEntity) -> String:
	if e == null:
		return ""
	return e.def.get("nombre", e.type)


# ---------------------------------------------------------------- Estado actual

func _unit_state(c: Dictionary, e: SimEntity) -> void:
	var t: SimEntity = sim.by_id.get(e.target)
	var txt := ""
	match e.order:
		O.IDLE:
			txt = "Inactivo"
		O.MOVE:
			txt = "En marcha"
		O.ATTACK_MOVE:
			txt = "Avanza peleando con lo que encuentre"
		O.ATTACK:
			txt = "Combate contra %s de %s" % [_name_of(t), _who(t.owner)] if t != null else "Combatiendo"
		O.GATHER:
			txt = "Recolecta %s%s" % [Palette.RES_NAMES.get(e.gather_kind, "").to_lower(), " en %s" % _name_of(t) if t != null else ""]
		O.RETURN:
			txt = "Lleva %s al depósito" % Palette.RES_NAMES.get(e.carry_res, "").to_lower()
		O.BUILD:
			if t != null and t.is_building():
				txt = ("Repara %s" if t.built else "Construye %s · %d%%") % ([_name_of(t)] if t.built else [_name_of(t), t.progress * 100 / maxi(1, t.build_time)])
			else:
				txt = "Construyendo"
		O.GARRISON:
			txt = "Va a refugiarse%s" % (" en %s" % _name_of(t) if t != null else "")
	if txt != "":
		c["state"].append([txt, Palette.UI_TEXT])
	if e.carry > 0:
		c["state"].append(["Carga %d de %s" % [e.carry, Palette.RES_NAMES.get(e.carry_res, e.carry_res).to_lower()], Palette.RES.get(e.carry_res, Palette.UI_TEXT)])
	if e.slow_until > sim.tick:
		c["state"].append(["Frenado (boleadoras)", Palette.UI_BAD])
	if e.def.has("municion"):
		c["state"].append(["Disparos: %d de %d" % [maxi(0, int(e.def["municion"]) - e.shots), e.def["municion"]], Palette.UI_DIM])
	if sim.tick - e.last_combat < 30:
		c["state"].append(["En combate", Palette.UI_BAD])


func _building_state(c: Dictionary, e: SimEntity) -> void:
	var dd := sim.dp(e.owner)
	if not e.built:
		var k := e.progress * 100 / maxi(1, e.build_time)
		c["bar"] = [k / 100.0, Palette.UI_ACCENT]
		c["state"].append(["En obra · %d%% · %d %s" % [k, e.workers_now, "constructor" if e.workers_now == 1 else "constructores"], Palette.UI_TEXT])
		return
	if not e.queue.is_empty():
		var first: String = e.queue[0]
		var k := float(e.queue_progress) / float(maxi(1, dd.queue_time(first)))
		var left := (dd.queue_time(first) - e.queue_progress) / 1000
		c["bar"] = [k, Palette.UI_ACCENT]
		c["state"].append(["Produce %s · %d%% · %d s" % [_queue_name(dd, first), int(k * 100), left], Palette.UI_TEXT])
		if e.queue.size() > 1:
			var rest: Array[String] = []
			for i in range(1, e.queue.size()):
				rest.append(_queue_name(dd, e.queue[i]))
			c["state"].append(["Después: " + ", ".join(rest), Palette.UI_DIM])
		var p: Dictionary = sim.players[e.owner]
		if e.queue_progress == 0 and p["pop"] >= p["pop_cap"]:
			c["state"].append(["Detenido: población llena", Palette.UI_BAD])
	elif e.def.has("produce") and e.owner == hud.local:
		c["state"].append(["Sin nada en producción", Palette.UI_DIM])
	var cap := sim.garrison_cap(e)
	if cap > 0:
		var shots: int = int(e.def.get("flechas", 1)) + e.garrison.size() if e.def.has("ataque") else 0
		var txt := "Guarnición %d/%d" % [e.garrison.size(), cap]
		if shots > 0:
			txt += " · %d %s" % [shots, "flecha" if shots == 1 else "flechas"]
		c["state"].append([txt, Palette.UI_ACCENT if not e.garrison.is_empty() else Palette.UI_DIM])
	if e.def.get("fuente", "") != "":
		var f: SimEntity = sim.by_id.get(e.farmer)
		var worked := f != null and f.alive and f.target == e.id
		c["state"].append(["Trabajada por un aldeano" if worked else "Sin aldeano asignado", Palette.UI_TEXT if worked else Palette.UI_DIM])
		if e.def.has("cantidad"):
			c["state"].append(["Quedan %d de alimento" % e.amount, Palette.RES["alimento"]])
	if e.def.has("renta"):
		var parts: Array[String] = []
		var r: Dictionary = e.def["renta"]
		for k: String in r:
			parts.append("%d de %s" % [r[k], _res_name(dd, k)])
		c["state"].append(["Rinde %s por minuto" % ", ".join(parts), Palette.UI_GOOD])
	if e.def.has("conversion"):
		_engine_state(c, e, dd)
	if e.def.has("deposito") and e.owner == hud.local:
		var near := 0
		for u in sim.actives:
			if u.alive and u.owner == e.owner and u.order == O.RETURN and u.aux == e.id:
				near += 1
		if near > 0:
			c["state"].append(["%d %s trayendo recursos" % [near, "aldeano" if near == 1 else "aldeanos"], Palette.UI_DIM])
	if e.def.has("efectos") and e.def.get("avanza_edad", false):
		var fx := ctrl.effects_text(e.def["efectos"])
		if fx != "":
			c["state"].append(["Efecto: " + fx, Palette.UI_GOOD])
	if e.rally_set and e.owner == hud.local:
		c["state"].append(["Punto de reunión marcado", Palette.UI_DIM])


## Motor de conversión: lee el mismo criterio que la simulación (SimMods._conversions) sin tocarla.
func _engine_state(c: Dictionary, e: SimEntity, dd: SimData) -> void:
	var cv: Dictionary = e.def["conversion"]
	var src: String = cv["de"]
	var p: Dictionary = sim.players[e.owner]
	var reserve := int(p.get("reserva_" + src, 0))
	var boost := 100 + sim.mod(e.owner, "motor")
	var pct := 100
	if int(p["res"].get(src, 0)) - reserve < int(cv["consume_min"]) / 60 + 1:
		pct = int(cv.get("piso_pct", 0)) if reserve == 0 else 0
	var gives: Array[String] = []
	for k: String in cv["da"]:
		gives.append("%d de %s" % [int(cv["da"][k]) * pct / 100 * boost / 100, _res_name(dd, k)])
	c["state"].append(["Motor: %d de %s/min → %s/min" % [cv["consume_min"], _res_name(dd, src), ", ".join(gives)], Palette.UI_GOOD if pct == 100 else Palette.UI_ACCENT])
	if pct < 100:
		c["state"].append(["Falta %s: rinde al %d%%" % [_res_name(dd, src), pct], Palette.UI_BAD])
	if boost > 100:
		c["state"].append(["Mejora de motor: +%d%%" % (boost - 100), Palette.UI_DIM])


func _site_state(c: Dictionary, e: SimEntity) -> void:
	var cfg: Dictionary = sim.data.reglas.get("sitios", {})
	c["state"].append(["Lo controla %s" % _who(e.holder), Palette.team(e.holder).lightened(0.2) if e.holder >= 0 else Palette.UI_DIM])
	if e.capture > 0 and e.aux >= 0 and e.aux != e.holder:
		var k := float(e.capture) / float(maxi(1, int(cfg.get("captura_ms", 1))))
		c["bar"] = [k, Palette.team(e.aux)]
		c["state"].append(["Lo está tomando %s · %d%%" % [_who(e.aux), int(k * 100)], Palette.team(e.aux).lightened(0.2)])
	var rents: Array = cfg.get("renta_por_cantidad", [cfg.get("renta_riqueza", 0)])
	var parts: Array[String] = []
	for r in rents:
		parts.append(str(r))
	c["state"].append(["Rinde riqueza por minuto: %s, según sea el primer sitio de su dueño, el segundo o el tercero" % " / ".join(parts), Palette.UI_DIM])
	var total := 0
	for s in sim.actives:
		if s.alive and s.def.get("sagrado", false):
			total += 1
	for p in sim.players:
		if int(p.get("sitios_ms", 0)) > 0:
			var left := (int(cfg.get("victoria_ms", 0)) - int(p["sitios_ms"])) / 1000
			c["state"].append(["%s tiene los %d sitios: gana en %s" % [_who(p["id"]).capitalize() if p["id"] != hud.local else "Tu pueblo", total, Hud._fmt_time(left)], Palette.UI_BAD if p["id"] != hud.local else Palette.UI_GOOD])


func _queue_name(dd: SimData, item: String) -> String:
	if item.begins_with("@"):
		return dd.tecnologias.get(item.substr(1), {}).get("nombre", item)
	return dd.unidades.get(item, {}).get("nombre", item)


func _res_name(dd: SimData, k: String) -> String:
	if Palette.RES_NAMES.has(k):
		return Palette.RES_NAMES[k].to_lower()
	var rp: Dictionary = dd.mod("recurso_propio")
	if rp.get("clave", "") == k:
		return rp.get("nombre", k)
	return k


# ---------------------------------------------------------------- Retratos

## Retrato pre-renderizado (tools/render_retratos.gd): primero el de la civilización, después el común.
static func portrait(civ: String, type: String) -> Texture2D:
	var key := civ + "/" + type
	if _tex_cache.has(key):
		return _tex_cache[key]
	var tex: Texture2D = null
	for folder in [civ, "comun"]:
		if folder == "":
			continue
		var path := "%s/%s/%s.png" % [RETRATOS, folder, type]
		if ResourceLoader.exists(path):
			tex = load(path)
		elif FileAccess.file_exists(path):
			var img := Image.load_from_file(ProjectSettings.globalize_path(path))
			if img != null:
				tex = ImageTexture.create_from_image(img)
		if tex != null:
			break
	_tex_cache[key] = tex
	return tex


# ---------------------------------------------------------------- Dibujo

## Mide (y dibuja si `paint`) la ficha; devuelve la altura.
func _paint(paint: bool) -> float:
	var c := _content()
	if c.is_empty():
		return 40.0
	var owner: int = c["owner"]
	var team := Palette.team(owner)
	var x0 := PAD
	var y := PAD
	var tw := W - PAD * 2
	# Retrato.
	var pr := Rect2(x0, y, PORTRAIT, PORTRAIT)
	if paint:
		_draw_portrait(pr, c, team)
	# Encabezado a la derecha del retrato.
	var hx := x0 + PORTRAIT + 12
	var hw := W - hx - PAD
	var hy := y + 20
	if paint:
		draw_string(Hud.font_b, Vector2(hx, hy), c["name"], HORIZONTAL_ALIGNMENT_LEFT, hw - (28 if c.has("hotkey") else 0), 19, Palette.UI_TEXT)
		if c.has("hotkey"):
			draw_string(Hud.font_b, Vector2(hx, hy), "[%s]" % c["hotkey"], HORIZONTAL_ALIGNMENT_RIGHT, hw, 13, Palette.UI_DIM)
	if c["alt"] != "":
		hy += 19
		if paint:
			draw_string(Hud.font, Vector2(hx, hy), c["alt"], HORIZONTAL_ALIGNMENT_LEFT, hw, 14, Palette.UI_DIM)
	hy += 22
	if paint:
		_flag(Vector2(hx, hy - 11), team, owner < 0 and not c["is_res"])
		draw_string(Hud.font, Vector2(hx + 20, hy), _people_line(c), HORIZONTAL_ALIGNMENT_LEFT, hw - 20, 14, team.lightened(0.35) if owner >= 0 else Palette.UI_DIM)
	var role: String = c.get("role", "")
	if role != "":
		var rh := Hud.font_b.get_multiline_string_size(role, HORIZONTAL_ALIGNMENT_LEFT, hw, 13).y
		if paint:
			draw_multiline_string(Hud.font_b, Vector2(hx, hy + 20), role, HORIZONTAL_ALIGNMENT_LEFT, hw, 13, -1, Palette.UI_ACCENT)
		hy += 6 + rh
	y = maxf(y + PORTRAIT, hy) + 10
	# Barra (vida, obra, cola o recurso).
	var e: SimEntity = c.get("entity")
	var bars: Array = []
	if e != null and not c["is_res"] and e.hp_max > 0 and not c.get("no_hp", false):
		bars.append([float(e.hp) / float(e.hp_max), _hp_col(e.hp, e.hp_max), 5.0])
	if c.has("bar"):
		bars.append([c["bar"][0], c["bar"][1], 3.0 if not bars.is_empty() else 5.0])
	for bar: Array in bars:
		if paint:
			draw_rect(Rect2(x0, y, tw, bar[2]), Color(0, 0, 0, 0.5))
			draw_rect(Rect2(x0, y, tw * clampf(bar[0], 0, 1), bar[2]), bar[1])
		y += bar[2] + 3
	if not bars.is_empty():
		y += 6
	# Descripción.
	var desc: String = c.get("desc", "")
	if desc != "":
		var dh := Hud.font.get_multiline_string_size(desc, HORIZONTAL_ALIGNMENT_LEFT, tw, 14).y
		if paint:
			draw_multiline_string(Hud.font, Vector2(x0, y + 13), desc, HORIZONTAL_ALIGNMENT_LEFT, tw, 14, -1, Color(Palette.UI_TEXT, 0.82))
		y += dh + 8
	var fx: String = c.get("effects", "")
	if fx != "":
		var fh := Hud.font_b.get_multiline_string_size(fx, HORIZONTAL_ALIGNMENT_LEFT, tw, 14).y
		if paint:
			draw_multiline_string(Hud.font_b, Vector2(x0, y + 13), fx, HORIZONTAL_ALIGNMENT_LEFT, tw, 14, -1, Palette.UI_GOOD)
		y += fh + 8
	# Estadísticas en grilla de cuatro columnas.
	var stats: Array = c["stats"]
	if not stats.is_empty():
		y = _rule(y, paint)
		var cw := tw / 4.0
		for i in stats.size():
			var s: Array = stats[i]
			var sx := x0 + (i % 4) * cw
			var sy := y + (i / 4) * 36
			if paint:
				draw_string(Hud.font, Vector2(sx, sy + 11), s[0], HORIZONTAL_ALIGNMENT_LEFT, cw - 4, 11, Palette.UI_DIM)
				draw_string(Hud.font_b, Vector2(sx, sy + 28), s[1], HORIZONTAL_ALIGNMENT_LEFT, cw - 4, 14 if String(s[1]).length() < 9 else 12, s[2])
		y += ceili(stats.size() / 4.0) * 36 + 2
	# Costo y tiempo.
	var cost: Dictionary = c["cost"]
	if not cost.is_empty() or int(c["time"]) > 0:
		y = _rule(y, paint)
		if paint:
			_draw_cost(Vector2(x0, y), cost, int(c["time"]), c.get("check_cost", false), owner)
		y += 28
	# Estado actual.
	var state: Array = c["state"]
	if not state.is_empty():
		y = _rule(y, paint)
		if paint:
			draw_string(Hud.font_b, Vector2(x0, y + 12), "AHORA", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(Palette.UI_ACCENT, 0.85))
		y += 18
		for s: Array in state:
			var sh := Hud.font.get_multiline_string_size(s[0], HORIZONTAL_ALIGNMENT_LEFT, tw - 12, 14).y
			if paint:
				draw_circle(Vector2(x0 + 3, y + 8), 2.2, s[1])
				draw_multiline_string(Hud.font, Vector2(x0 + 12, y + 13), s[0], HORIZONTAL_ALIGNMENT_LEFT, tw - 12, 14, -1, s[1])
			y += sh + 3
		y += 3
	# Fortalezas y debilidades.
	for pair in [["Fuerte contra", c["strong"], Palette.UI_GOOD], ["Débil", c["weak"], Palette.UI_BAD]]:
		if pair[1] == "":
			continue
		var txt: String = "%s: %s" % [pair[0], pair[1]]
		var th := Hud.font.get_multiline_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, tw, 13).y
		if paint:
			draw_multiline_string(Hud.font, Vector2(x0, y + 13), txt, HORIZONTAL_ALIGNMENT_LEFT, tw, 13, -1, Color(pair[2], 0.9))
		y += th + 4
	# Pie: atajos y bloqueos.
	for f: Array in c["foot"]:
		if paint:
			draw_string(Hud.font_b if f[1] == Palette.UI_BAD else Hud.font, Vector2(x0, y + 14), f[0], HORIZONTAL_ALIGNMENT_LEFT, tw, 13, f[1])
		y += 19
	return y + PAD - 4


func _people_line(c: Dictionary) -> String:
	var owner: int = c["owner"]
	if c["is_res"]:
		return "Naturaleza"
	if owner < 0:
		return "Naturaleza · de quien lo sostenga"
	var civ: String = sim.dp(owner).civ.get("nombre", "")
	var who := "Tu pueblo" if owner == hud.local else ("Aliado %s" if not sim.enemies(hud.local, owner) else "Rival %s") % Palette.TEAM_NAMES[owner % Palette.TEAM_NAMES.size()].to_lower()
	return "%s · %s" % [civ, who] if civ != "" else who


func _rule(y: float, paint: bool) -> float:
	if paint:
		draw_line(Vector2(PAD, y + 2), Vector2(W - PAD, y + 2), Color(1, 1, 1, 0.07), 1)
	return y + 8


func _flag(at: Vector2, team: Color, neutral: bool) -> void:
	draw_line(at + Vector2(1, 0), at + Vector2(1, 14), Palette.UI_DIM, 1.5)
	var pts := PackedVector2Array([at + Vector2(2, 0), at + Vector2(14, 2), at + Vector2(11, 5), at + Vector2(14, 8), at + Vector2(2, 9)])
	draw_colored_polygon(pts, Palette.UI_DIM if neutral else team)


func _draw_portrait(r: Rect2, c: Dictionary, team: Color) -> void:
	var owner: int = c["owner"]
	var tint: Color = team if owner >= 0 else (Palette.RES.get(c["def"].get("recurso", ""), Palette.UI_DIM) if c["is_res"] else Palette.UI_DIM)
	var sb := StyleBoxFlat.new()
	sb.set_corner_radius_all(8)
	sb.bg_color = Color(0.09, 0.095, 0.105, 1)
	draw_style_box(sb, r)
	# Degradado sobrio: luz del color del dueño arriba, oscuro abajo.
	var g := r.grow(-2)
	var top := Color(tint.darkened(0.35), 0.55)
	var bot := Color(0.06, 0.065, 0.075, 0.0)
	draw_polygon(PackedVector2Array([g.position, Vector2(g.end.x, g.position.y), g.end, Vector2(g.position.x, g.end.y)]), PackedColorArray([top, top, bot, bot]))
	var tex: Texture2D = c.get("tex")
	if tex != null:
		draw_texture_rect(tex, r.grow(-3), false)
	else:
		var icon: String = c.get("glyph", "")
		if icon == "":
			icon = c["def"].get("recurso", "") if c["is_res"] else Glyphs.resolve(c["def"], c["type"])
		var col: Color = Palette.RES.get(icon, Palette.UI_TEXT)
		Glyphs.draw(self, icon, r.grow(-24), col)
	var border := StyleBoxFlat.new()
	border.set_corner_radius_all(8)
	border.draw_center = false
	border.border_color = Color(tint, 0.75)
	border.set_border_width_all(1)
	draw_style_box(border, r)


func _draw_cost(at: Vector2, cost: Dictionary, time_ms: int, check: bool, owner: int) -> void:
	var res: Dictionary = sim.players[owner]["res"] if owner >= 0 else {}
	var x := at.x
	var keys: Array = Sim.RES_KINDS.duplicate()
	for k in cost:
		if not keys.has(k):
			keys.append(k)
	var rp: Dictionary = sim.dp(maxi(owner, 0)).mod("recurso_propio")
	for k in keys:
		if not cost.has(k):
			continue
		var col: Color = Palette.RES.get(k, Color(rp.get("color", "#cccccc")))
		Glyphs.draw(self, k if Palette.RES.has(k) else rp.get("icono", "riqueza"), Rect2(x, at.y + 2, 18, 18), col)
		var ok: bool = not check or int(res.get(k, 0)) >= int(cost[k])
		draw_string(Hud.font_b, Vector2(x + 22, at.y + 17), str(cost[k]), HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Palette.UI_TEXT if ok else Palette.UI_BAD)
		x += 70
	if time_ms > 0:
		draw_string(Hud.font, Vector2(at.x, at.y + 17), "Tiempo %d s" % (time_ms / 1000), HORIZONTAL_ALIGNMENT_RIGHT, W - PAD * 2, 14, Palette.UI_DIM)
