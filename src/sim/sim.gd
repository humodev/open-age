class_name Sim
extends RefCounted
## Simulación determinista. No usa nodos ni tiempo real (docs/06-arquitectura.md).

const P := 1000
const EC := 4000 # tamaño de celda de la tabla de búsqueda de enemigos
const INTERACT := 420 # distancia extra para recolectar, construir y entregar
const O := SimEntity.Order
const RES_KINDS: Array[String] = ["alimento", "madera", "piedra", "riqueza"]

var data: SimData
var tick: int = 0
var tick_ms: int
var map: SimMap
var fog: SimFog
var mods: SimMods
var groups: SimGroups # movimiento en grupo (proceso/21)
var comercio: SimComercio # --- comercio --- mercados neutrales y rutas (proceso/33)
var tele := SimTelemetry.new() # proceso/20: solo mira, no es estado
var _cur_cmd := "" # orden que se está aplicando (solo para la telemetría)
var rng: SimRng
var entities: Array[SimEntity] = [] # todas, en orden de id
var actives: Array[SimEntity] = [] # unidades y edificios, en orden de id
var by_id := {}
var next_id := 1
## Ids aparte para lo que el mapa agrega sin alterar la partida (los mercados neutrales,
## proceso/34-hacia-esport/01d): si tomaran de `next_id`, corrían en 2 el id de todo lo que se
## crea después y con él la fase de los `(tick + id) % k`; la primera victoria del principiante
## pasaba de 6 de 8 a 3 de 8 solo por eso. Mientras `id_aparte > 0`, `_new_entity` usa este.
const ID_APARTE := 1 << 28
var id_aparte := 0
var players: Array[Dictionary] = []
var bases: Array[Vector2i] = []
var ais: Array = []
var scenario: SimScenario = null
var events: Array[Dictionary] = []
var game_over := false
var winner := -1
var winner_team := -1
## Por qué terminó (proceso/24, paso 4b): "conquista", "sitios", "tiempo" o "" mientras sigue.
var end_reason := ""
var _time_limit_tick := 0 # tick del tiempo límite (opts.tiempo_limite_min); 0 = sin límite
var terrain := ""
var water_form := "" # forma del agua elegida (cruce, lago, costados, anillo, brazos)
var rivers: Array = [] # trazos de río para la imagen; no son estado
var _fort_gaps: Array = [] # [jugador, casillas, puerta] de las salidas de cada fortín
var _base_dirs: Array[Vector2i] = [] # mapas para N: dirección de cada base hacia el centro (milésimas)
var _opts: Dictionary = {}

var _pending := {} # tick -> Array[Dictionary]
var flares: Array[Dictionary] = [] # bengalas vivas: {id, player, x, y, tipo, tick} (proceso/23, parte B)
var _next_flare := 1
# --- esport 1a --- Tiros del asedio de área en vuelo: {tick (de llegada), x, y, a (el que tira), atk}.
# Pegan al llegar en el punto, no en el blanco: quien se mueve lo esquiva (D-031).
var shells: Array[Dictionary] = []
var requests: Array[Dictionary] = [] # pedidos de recursos entre aliados: {de, a, recurso, n, tick}
var recording: Array = [] # comandos externos (humanos) para repeticiones
var _in_step := false
var _grid := {} # celda de 1 casilla -> unidades (separación)
var _ehash := {} # celda de EC -> unidades y edificios (búsqueda)
var _res_cells := {} # celda de RC casillas -> recursos
var _wild: Array[SimEntity] = [] # animales sueltos que se pueden reclamar (proceso/23)
var _unreach_res := {} # recurso al que un jugador no llega: id * 64 + jugador -> tick hasta el que no se elige (paso 6c)
var _auras: Array = [] # por jugador: hitos terminados con aura (reglas.aura_hito), de este tick
var _dirty := false
var _teams := PackedInt32Array() # equipo de cada jugador (copia de players[i].equipo)
var _emask := {} # celda de `_ehash` -> bits de dueños presentes (bit 0: naturaleza)
var _foe_bits := PackedInt32Array() # por jugador: bits de quienes le pueden ser blanco
var _retarget_every := 3 # reglas.blancos.rebusca_cada_ticks (se lee una vez: corre por cada unidad que ataca)
const _NONE: Array = [] # celda vacía de las grillas: sin crear un arreglo por consulta
const RC := 8


func _init(seed_value: int, num_players: int = 2, data_override: SimData = null, opts: Dictionary = {}) -> void:
	if _vivas.size() >= 64: # torneos: miles de partidas; las ya liberadas se descartan
		_vivas = _vivas.filter(func(w: WeakRef) -> bool: return w.get_ref() != null)
	_vivas.append(weakref(self)) # paso 6e: para soltar_todas() al cerrar
	data = data_override if data_override != null else SimData.load_default()
	_opts = opts
	tick_ms = data.reglas["tick_ms"]
	_retarget_every = maxi(1, int(data.reglas["blancos"]["rebusca_cada_ticks"]))
	rng = SimRng.new(seed_value)
	# Escaramuza de 3 o más jugadores: mapa más grande y bases en círculo (docs/11).
	var size: int = data.reglas["mapa_tam"]
	if num_players > 2 and not opts.get("sin_sitios", false):
		size = int(data.reglas.get("mapa_tam_por_jugadores", {}).get(str(num_players), size))
		# --- partida a medida --- tamaño chico/normal/grande (reglas.opciones_partida.tamano_mapa_pct)
		var pct := int(data.reglas["opciones_partida"].get("tamano_mapa_pct", {}).get(str(opts.get("tamano", "normal")), 100))
		if pct != 100:
			size = size * pct / 100 / 8 * 8
	map = SimMap.new(size, num_players)
	map.path_cfg = data.reglas.get("caminos", {})
	fog = SimFog.new(size, num_players)
	fog.map = map
	fog.vision_per_level = data.reglas["vision_por_nivel"]
	mods = SimMods.new(self)
	groups = SimGroups.new(self)
	comercio = SimComercio.new(self) # --- comercio ---
	for i in num_players:
		players.append({
			"id": i,
			"res": _starting_res(opts),
			"age": 1,
			"pop": 0,
			"pop_cap": 0,
			"defeated": false,
			"alert_tick": -100000,
			"stats": {"recolectado": 0, "entrenadas": 0, "bajas": 0, "muertes": 0, "edificios_destruidos": 0},
			"techs": {}, # investigaciones terminadas
			"pending": {}, # investigaciones en cola
			"mods": {}, # modificadores acumulados (docs/05, "Investigaciones")
			"alarm": false,
			"disp": [0, 0, 0, 0, 0], # baldes de lo disputado (se crean siempre: leerlos no cambia el estado)
			"disp_min": 0,
			"civ": (opts.get("civs", []) as Array)[i] if i < (opts.get("civs", []) as Array).size() else "",
			"equipo": int((opts.get("equipos", []) as Array)[i]) if i < (opts.get("equipos", []) as Array).size() else i,
		})
	for p in players:
		var dd := data.for_civ(p["civ"])
		if dd.has_mod("recurso_propio"):
			var rp: Dictionary = dd.mod("recurso_propio")
			p["res"][rp["clave"]] = int(rp.get("inicial", 0))
		for k in dd.civ.get("recursos_iniciales", {}):
			p["res"][k] = dd.civ["recursos_iniciales"][k]
	_time_limit_tick = int(opts.get("tiempo_limite_min", 0)) * 60000 / tick_ms
	terrain = opts.get("terreno", "")
	if terrain == "":
		var kinds: Array = data.reglas["terrenos"].keys()
		terrain = kinds[rng.range_i(0, kinds.size() - 1)]
	# Equipos fijos durante la partida; las puertas dejan pasar a todo el equipo (docs/11, paso 4).
	for pid in players.size():
		_teams.append(int(players[pid].get("equipo", pid)))
		map.teams[pid] = team_of(pid)
	# Para saltear en `find_enemy` las celdas donde solo hay aliados.
	for pid in players.size():
		var bits := 1 # la naturaleza (ingenios hostiles)
		for q in players.size():
			if enemies(pid, q):
				bits |= 1 << (q + 1)
		_foe_bits.append(bits)
	_generate_map()
	_civ_landscape()
	_update_players()
	for pid in players.size():
		_update_fog(pid)


## Recursos con los que arranca cada jugador según la opción `recursos` (normal, medios,
## altos; reglas.opciones_partida.recursos). Una clave desconocida arranca con lo normal.
func _starting_res(opts: Dictionary) -> Dictionary:
	var key := str(opts.get("recursos", "normal"))
	var tbl: Dictionary = data.reglas.get("opciones_partida", {}).get("recursos", {})
	return ((tbl[key] if tbl.has(key) else data.reglas["recursos_iniciales"]) as Dictionary).duplicate()


## Datos de la civilización del jugador (capa común si no tiene).
func dp(pid: int) -> SimData:
	if pid < 0 or pid >= players.size():
		return data
	return data.for_civ(players[pid]["civ"])


# ---------------------------------------------------------------- Comandos

## Programa un comando. Desde la IA (dentro de un tick) entra en el tick siguiente.
func push_command(cmd: Dictionary, delay: int = 0) -> void:
	var at := tick + delay
	if _in_step:
		at = maxi(at, tick + 1)
	cmd["tick"] = at
	if not _in_step:
		recording.append(cmd.duplicate(true))
	if not _pending.has(at):
		_pending[at] = []
	_pending[at].append(cmd)


## Convierte lo leído de JSON a enteros donde corresponde (JSON no distingue 5 de 5.0).
static func intify(v: Variant) -> Variant:
	if v is float and v == floorf(v):
		return int(v)
	if v is Array:
		var out := []
		for x in v:
			out.append(intify(x))
		return out
	if v is Dictionary:
		var d := {}
		for k in v:
			d[k] = intify(v[k])
		return d
	return v


## Repetición: programa comandos grabados en sus ticks originales.
func schedule(cmds: Array) -> void:
	for c: Dictionary in cmds:
		var at: int = c["tick"]
		if not _pending.has(at):
			_pending[at] = []
		_pending[at].append(c)


func _apply(c: Dictionary) -> void:
	var pid: int = c.get("player", -1)
	if pid < 0 or pid >= players.size() or players[pid]["defeated"]:
		return
	_cur_cmd = "%s:%s" % [c.get("t", ""), c.get("type", c.get("tech", c.get("recurso", "")))] # para la telemetría
	# Órdenes por tipo (stats): miden la atención que pide cada civ (docs/diseno/.../v3/04, §6).
	var oc: Dictionary = players[pid]["stats"].get_or_add("ordenes", {})
	var okey: String = c["t"] + (":" + str(c["type"]) if c.has("type") else "")
	oc[okey] = int(oc.get(okey, 0)) + 1
	match c["t"]:
		"move":
			var mv := _own_units(pid, c.get("ids", []))
			# En grupo salvo "suelto" (Alt): los que no entran al grupo van como antes.
			# "form" (bloque, linea, abierta, columna) y "rumbo" (0..15, del arrastre del clic derecho).
			if not c.get("suelto", false):
				mv = groups.form(pid, mv, c["x"], c["y"], c.get("amove", false), {}, str(c.get("form", "")), int(c.get("rumbo", -1)))
			_cmd_move(pid, mv, c["x"], c["y"], c.get("amove", false))
		"formar":
			# Cambia la formación en el lugar (proceso/23, parte B): un grupo con destino en su centro.
			_cmd_formar(pid, _own_units(pid, c.get("ids", [])), str(c.get("form", "")), int(c.get("rumbo", -1)))
		"mantener":
			# Mantener posición: no se mueve, ataca lo que tenga a su alcance. Otra orden la corta.
			for e in _own_units(pid, c.get("ids", [])):
				if e.fn != "civil":
					_set_idle(e)
					e.group = -1
					e.order = O.HOLD
		"patrullar":
			_cmd_patrol(pid, _own_units(pid, c.get("ids", [])), int(c["x"]), int(c["y"]))
		"suelo": # --- esport 1a --- atacar el suelo (solo el asedio de área)
			_cmd_ground(pid, _own_units(pid, c.get("ids", [])), int(c["x"]), int(c["y"]))
		"bengala":
			_cmd_flare(pid, int(c["x"]), int(c["y"]), str(c.get("tipo", ""))) # --- fluidez 4 --- (intención elegida en la rueda)
		"pedir":
			_cmd_ask(pid, int(c["a"]), str(c["recurso"]))
		"target":
			var tu := _own_units(pid, c.get("ids", []))
			var tt: SimEntity = by_id.get(c["target"])
			# Lejos y sin pelea: marchan en grupo y al llegar cada uno hace lo pedido (proceso/21).
			if tt != null and tt.alive and not hostile(pid, tt) and not c.get("suelto", false) and not comercio.all_traders_to(pid, tu, tt): # --- comercio --- la ruta no va en grupo
				tu = groups.form(pid, tu, tt.x, tt.y, false, {"target": tt.id})
			_cmd_target(pid, tu, c["target"])
		"build":
			var bu := _own_units(pid, c.get("ids", []))
			_cmd_build(pid, bu, c["type"], c["tx"], c["ty"])
			# Cimiento lejos: los constructores van en bloque y se sueltan cerca de la obra.
			if not bu.is_empty() and bu[0].order == O.BUILD:
				var fb: SimEntity = by_id.get(bu[0].target)
				if fb != null and not c.get("suelto", false):
					groups.form(pid, bu, fb.x, fb.y, false, {"target": fb.id})
		"build_line":
			_cmd_build_line(pid, _own_units(pid, c.get("ids", [])), c["type"], c["tiles"])
		"train":
			_cmd_train(pid, c["building"], c["type"])
		"cancel":
			_cmd_cancel(pid, c["building"], c.get("index", -1))
		"repetir":
			_cmd_repeat(pid, int(c["building"]), str(c.get("type", "")), bool(c.get("on", true)))
		"tope_aldeanos":
			var rep: Dictionary = data.reglas.get("repeticion", {})
			players[pid]["tope_aldeanos"] = clampi(int(c["n"]), int(rep.get("tope_min", 10)), int(rep.get("tope_max", 200)))
		"rally":
			_cmd_rally(pid, c["building"], c["x"], c["y"], c.get("target", -1))
		"research":
			_cmd_research(pid, c["building"], c["tech"])
		"garrison":
			_cmd_garrison(pid, _own_units(pid, c.get("ids", [])), c.get("building", -1))
		"cumbi":
			mods.cumbi_gift(pid)
		"regimiento":
			# Gult asignado a un regimiento (desde la edad II, sin vuelta atrás).
			var gb: SimEntity = by_id.get(c["building"])
			if gb != null and gb.alive and gb.owner == pid and gb.def.has("regimiento") and gb.mode == "" and int(players[pid]["age"]) >= int(gb.def["regimiento"].get("edad", 2)):
				gb.mode = "regimiento"
				events.append({"t": "notice", "player": pid, "text": "Gult asignado a un regimiento"})
		"kawin":
			# Kawiñ (la fiesta mapuche): se come el rebaño del corral salvo una cabeza.
			var kb: SimEntity = by_id.get(c["building"])
			if kb != null and kb.alive and kb.owner == pid:
				mods.feast(kb)
		"desalojar":
			# Saca a la gente de los oficios de un edificio (Palmares).
			var cb: SimEntity = by_id.get(c["building"])
			if cb != null and cb.alive and cb.owner == pid:
				eject_crafts(cb)
		"ungarrison":
			_cmd_ungarrison(pid, c["building"])
		"alarm":
			_cmd_alarm(pid, c.get("on", true), int(c.get("max", -1)))
		"modo_monte":
			players[pid]["modo_monte"] = "quemar" if str(c["modo"]) == "quemar" else "crecer"
		"resiembra":
			players[pid]["resiembra"] = bool(c["on"])
		"guardar":
			# "Guardar <recurso> para el hito" (fama de Palmares): prendido por defecto.
			players[pid]["guardar_" + str(c["res"])] = bool(c["on"])
		"acoger":
			# Acogida prendida o en pausa (Palmares): con la pausa la fama se junta y no llega gente.
			players[pid]["acogida_pausa"] = not bool(c["on"])
		"reserve":
			# Reserva de un recurso propio que los motores de conversión no tocan.
			players[pid]["reserva_" + str(c["res"])] = clampi(int(c["n"]), 0, 1000)
		"trade":
			_cmd_trade(pid, c["building"], c["recurso"], c["op"])
		# --- comercio --- ruta a un mercado (con punto de paso opcional) y punto de paso nuevo
		"ruta":
			var rm: SimEntity = by_id.get(int(c.get("mercado", -1)))
			comercio.order_route(pid, _own_units(pid, c.get("ids", [])), rm, Vector2i(int(c.get("x", -1)), int(c.get("y", -1))))
		"ruta_paso":
			comercio.set_waypoint(pid, _own_units(pid, c.get("ids", [])), int(c["x"]), int(c["y"]))
		"tributo":
			_cmd_tribute(pid, int(c["a"]), str(c["recurso"]), int(c["n"]))
		"pack":
			_cmd_pack(pid, c["building"])
		"unpack":
			_cmd_unpack(pid, c["unit"])
		"stop":
			for e in _own_units(pid, c.get("ids", [])):
				_set_idle(e)
		"delete":
			for id in c.get("ids", []):
				var e: SimEntity = by_id.get(id)
				if e != null and e.owner == pid and not e.is_resource():
					if e.is_building() and not e.built:
						_refund(pid, dp(pid).cost_of(e.type, players[pid]["age"]))
					_kill(e)
		"resign":
			# Con motivo (la IA fácil que se rinde, proceso/24 4q): si así termina la partida,
			# el final lo dice.
			var why := String(c.get("motivo", ""))
			if why != "" and end_reason == "":
				var teams := {}
				for pl in players:
					if not pl["defeated"] and pl["id"] != pid:
						teams[team_of(pl["id"])] = true
				if teams.size() <= 1:
					end_reason = why
				events.append({"t": "rendicion", "player": pid})
			_defeat(pid)


func _own_units(pid: int, ids: Array) -> Array[SimEntity]:
	var out: Array[SimEntity] = []
	var sorted := ids.duplicate()
	sorted.sort()
	for id in sorted:
		var e: SimEntity = by_id.get(id)
		if e != null and e.alive and e.owner == pid and e.is_unit() and e.inside < 0:
			e.patrol = false # cualquier orden nueva corta la patrulla
			out.append(e)
	return out


## Cambiar de formación sin moverse: el grupo se arma de nuevo con destino en su centro.
## Sin rumbo pedido, el que la mayoría guardó de su última formación (o el de la tabla, 0).
func _cmd_formar(pid: int, units: Array[SimEntity], form: String, rumbo: int) -> void:
	var mil: Array[SimEntity] = []
	var cx := 0
	var cy := 0
	var votes := {}
	for e in units:
		if e.is_military():
			mil.append(e)
			cx += e.x
			cy += e.y
			if e.rumbo >= 0:
				votes[e.rumbo] = int(votes.get(e.rumbo, 0)) + 1
	if mil.is_empty():
		return
	cx /= mil.size()
	cy /= mil.size()
	if rumbo < 0:
		var best := -1
		var keys := votes.keys()
		keys.sort()
		for k in keys:
			if best < 0 or int(votes[k]) > int(votes[best]):
				best = k
		rumbo = maxi(0, best)
	var rest := groups.form(pid, mil, cx, cy, false, {}, form, rumbo)
	_cmd_move(pid, rest, cx, cy, false)


## Patrulla: cada unidad va del lugar donde está a su punto del destino (repartido como al
## mover) y vuelve, atacando lo que ve. Los aldeanos no patrullan.
func _cmd_patrol(pid: int, units: Array[SimEntity], x: int, y: int) -> void:
	var pu: Array[SimEntity] = []
	for e in units:
		if e.fn != "civil":
			pu.append(e)
	var starts := []
	for e in pu:
		starts.append(Vector2i(e.x, e.y))
	_cmd_move(pid, pu, x, y, true)
	for i in pu.size():
		pu[i].patrol = true
		pu[i].pat_x = starts[i].x
		pu[i].pat_y = starts[i].y


## Bengala (Alt + clic): "atacá acá", o "defendé acá" si cae cerca de lo propio o de un aliado.
## Es estado de la partida: la IA aliada la lee y responde (SimAI._flares).
func _cmd_flare(pid: int, x: int, y: int, elegido: String = "") -> void:
	var cfg: Dictionary = data.reglas["equipos"]["bengala"]
	x = clampi(x, 0, map.n * P - 1)
	y = clampi(y, 0, map.n * P - 1)
	var kind := "atacar"
	# --- fluidez 4 --- Con la rueda (Alt + arrastrar) la intención viene elegida: atacar, defender,
	# juntarse o mirar (reglas.equipos.bengala.tipos). Sin elegir, se deduce como siempre.
	var auto := not (elegido in (cfg.get("tipos", []) as Array))
	if not auto:
		kind = elegido
	for e in actives:
		if not auto:
			break
		# --- fin fluidez 4 ---
		if e.alive and e.is_building() and e.owner >= 0 and not enemies(pid, e.owner) and dist(e.x, e.y, x, y) <= int(cfg["defender_radio"]):
			kind = "defender"
			break
	flares.append({"id": _next_flare, "player": pid, "x": x, "y": y, "tipo": kind, "tick": tick})
	_next_flare += 1
	while flares.size() > int(cfg["max_por_partida"]):
		flares.pop_front()
	events.append({"t": "bengala", "player": pid, "x": x, "y": y, "tipo": kind})


## Pedido de recursos a un aliado: queda anotado; la IA lo atiende si le sobra (SimAI._requests).
func _cmd_ask(pid: int, to: int, kind: String) -> void:
	if to < 0 or to >= players.size() or to == pid or team_of(pid) != team_of(to) or players[to]["defeated"]:
		return
	if not kind in RES_KINDS:
		return
	var cfg: Dictionary = data.reglas["equipos"]["pedido"]
	for r in requests:
		if int(r["de"]) == pid and int(r["a"]) == to and r["recurso"] == kind:
			return # ya está pedido
	requests.append({"de": pid, "a": to, "recurso": kind, "n": int(cfg["lote"]), "tick": tick})
	events.append({"t": "pedido", "de": pid, "a": to, "recurso": kind, "n": int(cfg["lote"])})


## La IA (u otra regla) dice algo en el chat del equipo: el HUD arma la frase (data/interfaz.json → frases_ia).
func say(pid: int, key: String, extra: Dictionary = {}) -> void:
	var ev := {"t": "ia_dice", "player": pid, "clave": key}
	ev.merge(extra)
	events.append(ev)


func _cmd_move(pid: int, units: Array[SimEntity], x: int, y: int, amove: bool) -> void:
	var n := units.size()
	if n == 0:
		return
	var cols := 1
	while cols * cols < n:
		cols += 1
	var rows := (n + cols - 1) / cols
	var sp := int(data.reglas["grupo"]["separacion"])
	for i in n:
		var e := units[i]
		var gx := x + (i % cols) * sp - (cols - 1) * sp / 2
		var gy := y + (i / cols) * sp - (rows - 1) * sp / 2
		var t := map.nearest_free(clampi(gx / P, 0, map.n - 1), clampi(gy / P, 0, map.n - 1), 8, pid)
		if t.x >= 0 and map.is_solid(gx / P, gy / P, pid):
			gx = t.x * P + P / 2
			gy = t.y * P + P / 2
		e.target = -1
		e.group = -1
		e.resume_amove = false
		e.order = O.ATTACK_MOVE if amove else O.MOVE
		e.amove_x = gx
		e.amove_y = gy
		_set_goal(e, gx, gy)


## Equipo de un jugador (docs/11): por defecto cada uno es su propio equipo.
func team_of(pid: int) -> int:
	return _teams[pid] if pid >= 0 and pid < _teams.size() else -1


## ¿Son enemigos dos jugadores? Nunca lo son consigo mismos ni con su equipo.
## Se llama por cada candidato de `find_enemy`: lee el arreglo, no el diccionario.
func enemies(a: int, b: int) -> bool:
	return a >= 0 and b >= 0 and a != b and a < _teams.size() and b < _teams.size() and _teams[a] != _teams[b]


## ¿`t` es enemigo de `pid`? Los de otro jugador y los neutrales hostiles (ingenios).
func hostile(pid: int, t: SimEntity) -> bool:
	return t.alive and ((t.owner >= 0 and enemies(pid, t.owner)) or (t.owner < 0 and pid >= 0 and bool(t.def.get("hostil", false))))


func _cmd_target(pid: int, units: Array[SimEntity], target_id: int) -> void:
	var t: SimEntity = by_id.get(target_id)
	if t == null or not t.alive:
		return
	var plain: Array[SimEntity] = []
	var meat: SimEntity = null
	# --- comercio --- comerciantes sobre un mercado: ruta (el resto sigue con lo de siempre)
	if comercio.dest_kind(pid, t) != "":
		var traders: Array[SimEntity] = []
		var rest: Array[SimEntity] = []
		for e in units:
			if e.def.get("comerciante", false):
				traders.append(e)
			else:
				rest.append(e)
		if not traders.is_empty() and comercio.order_route(pid, traders, t) < traders.size():
			for e in traders:
				if e.order != O.TRADE:
					plain.append(e)
		units = rest
	for e in units:
		if t.is_unit() and t.def.get("animal", false) and t.owner == pid:
			# Aldeano sobre un animal propio: lo carnea; el resto lo junta (proceso/23, C-32).
			if e.fn == "civil":
				if meat == null and t.alive:
					meat = _slaughter(t)
				if meat != null and meat.alive:
					_order_gather(e, meat)
			else:
				plain.append(e)
			continue
		if hostile(pid, t):
			if t.is_unit() and e.def.get("solo_edificios", false):
				plain.append(e)
			else:
				_order_attack(e, t)
		elif t.is_resource():
			if e.fn == "civil":
				_order_gather(e, t)
			else:
				plain.append(e)
		elif t.is_unit() and t.owner == pid and garrison_cap(t) > 0 and not e.def.get("navega", false) and e.def.get("pob", 1) > 0:
			e.order = O.GARRISON # --- paso 6 --- subir a la canoa (ygá)
			e.target = t.id
			e.path_target = -1
		elif e.fn == "civil" and can_repair_unit(pid, t):
			_order_build(e, t) # --- paso 3 --- el asedio se repara en el campo (escuela)
		elif t.is_building() and t.owner == pid:
			if e.fn == "civil" and (not t.built or t.hp < t.hp_max):
				_order_build(e, t)
			elif e.fn == "civil" and t.def.get("fuente", "") != "":
				_order_gather(e, t)
			elif e.fn == "civil" and e.carry > 0 and _accepts(t, e.carry_res):
				e.order = O.RETURN
				e.aux = t.id
				e.path_target = -1
			elif garrison_cap(t) > 0:
				e.order = O.GARRISON
				e.target = t.id
				e.path_target = -1
			else:
				plain.append(e)
		else:
			plain.append(e)
	if plain.size() > 0:
		_cmd_move(pid, plain, t.x, t.y, false)


func _cmd_build(pid: int, units: Array[SimEntity], type: String, tx: int, ty: int) -> void:
	var p := players[pid]
	if not dp(pid).edificios.has(type):
		return
	var def: Dictionary = dp(pid).edificios[type]
	if p["age"] < def.get("edad_min", 1):
		_notify(pid, "Requiere edad %s" % _roman(def.get("edad_min", 1)))
		return
	if def.get("avanza_edad", false):
		if p["age"] >= dp(pid).edades.size():
			return
		if hito_in_progress(pid):
			_notify(pid, "Ya hay un hito en obra")
			return
	# --- paso 7 --- la maravilla: una por jugador y con las condiciones de su pueblo; la corte
	# etíope no se muda mientras está en pie Fasil Gəbbi.
	var why := build_block(pid, type)
	if why != "":
		_notify(pid, why)
		return
	var cost := build_cost(pid, type)
	if not can_afford(pid, cost):
		_notify(pid, "Recursos insuficientes")
		return
	if not can_place(type, tx, ty, pid):
		_notify(pid, "No se puede construir ahí")
		return
	_replace_wall(type, tx, ty, pid)
	_pay(pid, cost)
	var b := spawn_building(type, pid, tx, ty, false)
	b.build_time = dp(pid).build_time_of(type, p["age"]) * (100 + mod(pid, "obra_t:" + type)) / 100 # --- paso 6 --- óga de takuára
	events.append({"t": "placed", "id": b.id, "player": pid})
	if def.get("maravilla", false): # --- paso 7 --- todos se enteran y la ven (como en AoE4)
		events.append({"t": "maravilla_obra", "id": b.id, "player": pid})
	for e in units:
		if e.fn == "civil":
			_order_build(e, b)


func _cmd_train(pid: int, bid: int, type: String, quiet := false) -> bool:
	var b: SimEntity = by_id.get(bid)
	if b == null or not b.alive or b.owner != pid or not b.built:
		return false
	if not (b.def.get("produce", []) as Array).has(type):
		return false
	var p := players[pid]
	var udef: Dictionary = dp(pid).unidades.get(type, {})
	if udef.has("maximo_por_edad"):
		var maxes: Array = udef["maximo_por_edad"]
		var have := 0
		for e in actives:
			if e.alive and e.owner == pid and e.type == type:
				have += 1
			if e.alive and e.owner == pid and e.is_building():
				for q in e.queue:
					if q == type:
						have += 1
		if have >= int(maxes[clampi(int(p["age"]) - 1, 0, maxes.size() - 1)]) + mods.engine_max_bonus(pid, type):
			if not quiet:
				_notify(pid, "Máximo de %s en esta edad" % str(udef.get("nombre", type)))
			return false
	if p["age"] < comercio.unit_age_min(pid, type): # --- esport 2b --- el comerciante del 1v1
		if not quiet:
			_notify(pid, "Requiere edad %s" % _roman(comercio.unit_age_min(pid, type)))
		return false
	# --- paso 4 --- reemplazada desde esta edad (el ariete inca y el guaraní pasan al asedio de área)
	var rep := dp(pid).replaced_by(type, int(p["age"]))
	if rep != "":
		if not quiet:
			_notify(pid, "Ahora se entrena %s" % str(dp(pid).unidades[rep].get("nombre", rep)))
		return false
	# --- fin paso 4 ---
	if b.queue.size() >= data.reglas["cola_max"]:
		if not quiet:
			_notify(pid, "Cola llena")
		return false
	var why_t := train_block(pid, b, type)
	if why_t != "":
		if not quiet:
			_notify(pid, why_t)
		return false
	var cost := train_cost(pid, b, type)
	if not can_afford(pid, cost):
		if not quiet:
			_notify(pid, "Recursos insuficientes")
		return false
	_pay(pid, cost)
	b.queue.append(type)
	b.queue_paid.append(cost.duplicate())
	return true


# --- frente 1 --- (proceso/30) producción que se repite sola, como la «auto-queue» de AoE4.
## Prende o apaga la repetición de `type` en el edificio. Es estado del edificio: entra en las
## repeticiones de partidas y en la red, porque llega como comando.
func _cmd_repeat(pid: int, bid: int, type: String, on: bool) -> void:
	var b: SimEntity = by_id.get(bid)
	if b == null or not b.alive or b.owner != pid or not b.is_building():
		return
	if not on:
		if type == "" or b.repeat == type:
			b.repeat = ""
		return
	if type.begins_with("@") or not (b.def.get("produce", []) as Array).has(type):
		return
	b.repeat = type


## Tope de aldeanos del jugador para la repetición (la regla y el comando tope_aldeanos).
func villager_cap(pid: int) -> int:
	return int(players[pid].get("tope_aldeanos", int(data.reglas.get("repeticion", {}).get("tope_aldeanos", 80))))


## Aldeanos vivos y en cola del jugador (lo que mide el tope de la repetición).
func villagers_and_queued(pid: int) -> int:
	var n := 0
	for e in owned(pid):
		if not e.alive or e.owner != pid:
			continue
		if e.fn == "civil" and e.is_unit():
			n += 1
		elif e.is_building():
			for q in e.queue:
				if not q.begins_with("@") and str(dp(pid).unidades.get(q, {}).get("funcion", "")) == "civil":
					n += 1
	return n


## ¿Por qué no se repite ahora? "" si entra otra. No toca lo apartado (reserva_<recurso>),
## necesita lugar de población y, con aldeanos, no pasa el tope.
func repeat_block(b: SimEntity) -> String:
	var pid := b.owner
	var type := b.repeat
	var p := players[pid]
	var udef: Dictionary = dp(pid).unidades.get(type, {})
	if int(p["pop"]) + int(udef.get("pob", 1)) > int(p["pop_cap"]):
		return "pob"
	var cost := train_cost(pid, b, type)
	for k in cost:
		if int(p["res"].get(k, 0)) - int(p.get("reserva_" + k, 0)) < int(cost[k]):
			return "recursos"
	if str(udef.get("funcion", "")) == "civil" and villagers_and_queued(pid) >= villager_cap(pid):
		return "tope"
	return ""


func _repeat_try(b: SimEntity) -> void:
	if repeat_block(b) == "":
		_cmd_train(b.owner, b.id, b.repeat, true)
# --- fin frente 1 ---


func _cmd_cancel(pid: int, bid: int, index: int) -> void:
	var b: SimEntity = by_id.get(bid)
	if b == null or not b.alive or b.owner != pid or b.queue.is_empty():
		return
	if index < 0 or index >= b.queue.size():
		index = b.queue.size() - 1
	var type: String = b.queue[index]
	b.queue.remove_at(index)
	var paid: Dictionary = b.queue_paid[index] if index < b.queue_paid.size() else {}
	if index < b.queue_paid.size():
		b.queue_paid.remove_at(index)
	if index == 0:
		b.queue_progress = 0
	if type.begins_with("@"):
		players[pid]["pending"].erase(type.substr(1))
		type = type.substr(1)
	# Se devuelve lo que se pagó, no el precio de ahora (con descuentos que cambian, crítica 03b).
	_refund(pid, paid if not paid.is_empty() else dp(pid).cost_of(type, players[pid]["age"]))


## ¿Se puede investigar `tech` ahora? Devuelve "" o el motivo.
func research_block(pid: int, tech: String) -> String:
	var t: Dictionary = dp(pid).tecnologias.get(tech, {})
	var p := players[pid]
	if t.is_empty():
		return "Desconocida"
	if p["techs"].has(tech):
		return "Ya investigada"
	if p["pending"].has(tech):
		return "En investigación"
	if t.has("requiere") and not p["techs"].has(t["requiere"]):
		return "Requiere %s" % dp(pid).tecnologias[t["requiere"]]["nombre"]
	if p["age"] < t.get("edad_min", 1):
		return "Requiere edad %s" % _roman(t["edad_min"])
	if t.has("requiere_hito") and not has_done_hito(pid, t["requiere_hito"]): # --- paso 6 --- la vía guaraní
		return "Requiere el hito %s" % dp(pid).edificios.get(t["requiere_hito"], {}).get("nombre", t["requiere_hito"])
	# --- ronda 8, 05 --- caminos de la escuela: el primero que se elige cierra los otros.
	var chosen := school_path(pid)
	if t.has("camino_de") and chosen != "":
		return "Ya elegiste el %s" % String(dp(pid).tecnologias.get("camino_" + chosen, {}).get("nombre", chosen)).to_lower()
	if t.has("camino") and chosen != String(t["camino"]):
		return "Requiere el %s" % String(dp(pid).tecnologias.get("camino_" + String(t["camino"]), {}).get("nombre", t["camino"])).to_lower()
	return ""


## --- ronda 8, 05 --- Camino de la escuela que eligió `pid` ("guerra", "asedio", "defensa"),
## también si está en investigación; "" si ninguno.
func school_path(pid: int) -> String:
	var p := players[pid]
	var techs: Dictionary = dp(pid).tecnologias
	for d: Dictionary in [p["techs"], p["pending"]]:
		for k in d:
			var cd: String = techs.get(k, {}).get("camino_de", "")
			if cd != "":
				return cd
	return ""


## --- ronda 8, 05 --- Veces que `pid` compró la mejora que se repite `tech`.
func times_done(pid: int, tech: String) -> int:
	return int(players[pid].get("repetidas", {}).get(tech, 0))


## ¿Se puede investigar `t` en el edificio `b`? Por capacidad, no por tipo
## (docs/diseno/jugabilidad/03-propuesta.md §2.4): `"en": {"deposito": "madera"}` vale en
## cualquier edificio que reciba madera; `{"tipo": "centro"}`, en el centro o la capital
## (el lof mapuche). Sin `en`, el tipo de `"edificio"`, como antes.
func tech_here(t: Dictionary, b: SimEntity) -> bool:
	var en: Dictionary = t.get("en", {})
	if en.has("deposito"):
		return (b.def.get("deposito", []) as Array).has(en["deposito"])
	if en.has("tipo"):
		return b.type == en["tipo"] or (en["tipo"] == "centro" and b.capital)
	if en.has("linea"):
		# Niveles por línea: en cualquier edificio que entrene esa línea (docs/diseno/27, §1.1).
		return dp(b.owner).lines_made_by(b.def).has(en["linea"])
	if en.get("escuela", false):
		# --- paso 3 --- La escuela de la IV (docs/diseno/27, §1.3): en la capital y en los
		# edificios que nombra el pueblo (la kallanka real, el parlamento, la tava, Gondar, el Macaco).
		return b.capital or (dp(b.owner).civ.get("escuela", {}).get("edificios", []) as Array).has(b.type)
	if en.get("militar", false):
		# Mejoras militares: en cualquier edificio que entrene tropa (cuartel, campo de tiro, corral, taller…).
		# La herrería (`sin_deposito`, paso 2), no en los que además son almacén o centro (el lof, el
		# mocambo, la qollqa): su grilla ya está llena de economía.
		if en.get("sin_deposito", false) and not (b.def.get("deposito", []) as Array).is_empty():
			return false
		var units: Dictionary = dp(b.owner).unidades
		for u in b.def.get("produce", []):
			if units.get(u, {}).get("funcion", "") in ["choque", "distancia", "linea", "asedio"]:
				return true
		return false
	return t.get("edificio", "") == b.type


func _cmd_research(pid: int, bid: int, tech: String) -> void:
	var b: SimEntity = by_id.get(bid)
	if b == null or not b.alive or b.owner != pid or not b.built:
		return
	var t: Dictionary = dp(pid).tecnologias.get(tech, {})
	if t.is_empty() or not tech_here(t, b):
		return
	var why := research_block(pid, tech)
	if why != "":
		_notify(pid, why)
		return
	if b.queue.size() >= data.reglas["cola_max"]:
		_notify(pid, "Cola llena")
		return
	var cost := tech_cost(pid, tech) # --- paso 3 --- (con el descuento de los registros)
	if not can_afford(pid, cost):
		_notify(pid, "Recursos insuficientes")
		return
	_pay(pid, cost)
	players[pid]["pending"][tech] = true
	b.queue.append("@" + tech)
	b.queue_paid.append(cost)


## --- paso 3 --- ¿Los aldeanos de `pid` pueden reparar la unidad `t`? Solo el asedio propio
## dañado, con la reparación en el campo de la escuela (docs/diseno/27, §1.3).
func can_repair_unit(pid: int, t: SimEntity) -> bool:
	return t.is_unit() and t.owner == pid and t.fn == "asedio" and t.hp < t.hp_max and mod(pid, "asedio_rep") > 0


## --- paso 3 --- Costo de una investigación para `pid`: el de los datos, menos el descuento de
## los registros de la escuela (`costo_tec_pct`, para las de su edad o más; docs/diseno/27, §1.3).
func tech_cost(pid: int, tech: String) -> Dictionary:
	var base: Dictionary = dp(pid).tecnologias.get(tech, {}).get("costo", {})
	var age := int(dp(pid).tecnologias.get(tech, {}).get("edad_min", 1))
	var off := 0
	for a in range(1, age + 1):
		off += mod(pid, "tec_desc:%d" % a)
	# --- ronda 8, 05 --- la que se repite cuesta `crece_pct` % más del base por cada vez comprada.
	var rep: Dictionary = dp(pid).tecnologias.get(tech, {}).get("repite", {})
	var grow := 100 + int(rep.get("crece_pct", 0)) * times_done(pid, tech)
	if rep.get("compuesto", false): # --- esport 2a --- cada vez, `crece_pct` % más que la anterior
		grow = 100
		for i in times_done(pid, tech):
			grow = grow * (100 + int(rep["crece_pct"])) / 100
	var out := {}
	for k in base:
		out[k] = int(base[k]) * grow / 100 * (100 - mini(off, 100)) / 100
	return out


## Mercado: compra o vende un lote por riqueza; el precio sube al comprar y baja al vender.
## Tributo a un aliado (docs/11): sale todo, llega menos la comisión de `reglas.equipos`.
func _cmd_tribute(pid: int, to: int, kind: String, n: int) -> void:
	if to < 0 or to >= players.size() or to == pid or enemies(pid, to) or team_of(pid) != team_of(to):
		return
	if players[to]["defeated"] or not kind in ["alimento", "madera", "piedra", "riqueza"]:
		return
	var res: Dictionary = players[pid]["res"]
	n = mini(n, int(res.get(kind, 0)))
	if n <= 0:
		return
	var got := n * (100 - int(data.reglas["equipos"]["tributo_comision_pct"])) / 100
	res[kind] -= n
	players[to]["res"][kind] = int(players[to]["res"].get(kind, 0)) + got
	ledger(pid, "tributo_dado", kind, -n)
	ledger(to, "tributo", kind, got)
	events.append({"t": "tributo", "de": pid, "a": to, "recurso": kind, "n": got})


func _cmd_trade(pid: int, bid: int, kind: String, op: String) -> void:
	var b: SimEntity = by_id.get(bid)
	if b == null or not b.alive or b.owner != pid or not b.built or not b.def.get("mercado", false):
		return
	if not kind in ["alimento", "madera", "piedra"]:
		return
	var cfg: Dictionary = data.reglas["mercado"]
	var p := players[pid]
	var price: int = trade_price(pid, kind)
	var lot: int = cfg["lote"]
	var res: Dictionary = p["res"]
	if op == "comprar":
		if int(res["riqueza"]) < price:
			_notify(pid, "Falta riqueza")
			return
		res["riqueza"] -= price
		res[kind] += lot
		ledger(pid, "mercado", kind, lot)
		p["precios"][kind] = mini(int(cfg["maximo"]), price + int(cfg["paso"]))
	else:
		if int(res[kind]) < lot:
			_notify(pid, "No alcanza para vender")
			return
		res[kind] -= lot
		var got := price * (100 - int(cfg["comision_pct"])) / 100 * (100 + mod(pid, "venta_pct")) / 100 # --- paso 6 --- makuñ
		res["riqueza"] += got
		ledger(pid, "mercado", "riqueza", got)
		p["precios"][kind] = maxi(int(cfg["minimo"]), price - int(cfg["paso"]))
	events.append({"t": "trade", "player": pid})


func trade_price(pid: int, kind: String) -> int:
	var p := players[pid]
	if not p.has("precios"):
		var start: int = data.reglas["mercado"]["precio_inicial"]
		p["precios"] = {"alimento": start, "madera": start, "piedra": start}
		p["precios_tick"] = tick
	# Los precios vuelven de a poco al inicial (reglas.mercado: piso, paso y regreso).
	var cfg: Dictionary = data.reglas["mercado"]
	var every := int(cfg.get("regreso_cada_ticks", 0))
	if every > 0:
		var steps := (tick - int(p.get("precios_tick", tick))) / every
		if steps > 0:
			p["precios_tick"] = int(p.get("precios_tick", tick)) + steps * every
			var base := int(cfg["precio_inicial"])
			var mv := steps * int(cfg.get("regreso_paso", 1))
			for k in p["precios"]:
				var v := int(p["precios"][k])
				p["precios"][k] = mini(base, v + mv) if v < base else maxi(base, v - mv)
	return p["precios"][kind]


## Base móvil (kätäma etíope): el edificio se desarma en una unidad lenta que lo lleva.
func _cmd_pack(pid: int, bid: int) -> void:
	var b: SimEntity = by_id.get(bid)
	if b == null or not b.alive or b.owner != pid or not b.built or not b.def.has("empaca_en") or not b.queue.is_empty():
		return
	if not mods.wonder_fx(pid, "corte_fija").is_empty(): # --- paso 7 --- Fasil Gəbbi en pie
		_notify(pid, "Con %s en pie la corte ya no se muda" % wonder_of(pid).def.get("nombre", "la maravilla"))
		return
	var kind: String = b.def["empaca_en"]
	var tile := Vector2i(b.tx + b.w / 2, b.ty + b.h / 2)
	var ratio := b.hp * 100 / b.hp_max
	var was_capital := b.capital
	b.capital = false
	_kill(b)
	var u := spawn_unit(kind, pid, tile.x * P + P / 2, tile.y * P + P / 2)
	u.hp = maxi(1, u.hp_max * ratio / 100)
	u.capital = was_capital
	events.append({"t": "packed", "id": u.id, "player": pid})


func _cmd_unpack(pid: int, uid: int) -> void:
	var u: SimEntity = by_id.get(uid)
	if u == null or not u.alive or u.owner != pid or not u.def.has("despliega_en"):
		return
	var kind: String = u.def["despliega_en"]
	var tam: Array = dp(pid).edificios[kind]["tam"]
	var tx: int = u.x / P - int(tam[0]) / 2
	var ty: int = u.y / P - int(tam[1]) / 2
	if not can_place(kind, tx, ty, pid):
		_notify(pid, "No hay lugar parejo para armar la corte")
		return
	var ratio := u.hp * 100 / u.hp_max
	var was_capital := u.capital
	_kill(u)
	var b := spawn_building(kind, pid, tx, ty, true)
	b.hp = maxi(1, b.hp_max * ratio / 100)
	b.capital = was_capital
	events.append({"t": "built", "id": b.id, "player": pid})


func _cmd_garrison(_pid: int, units: Array[SimEntity], bid: int) -> void:
	for e in units:
		e.order = O.GARRISON
		e.target = bid
		e.path_target = -1


func _cmd_ungarrison(pid: int, bid: int) -> void:
	var b: SimEntity = by_id.get(bid)
	if b == null or b.owner != pid:
		return
	if b.is_unit(): # --- paso 6 --- bajar de la canoa
		_unload(b, 2)
		return
	_eject(b)


## Campana: los aldeanos cercanos se refugian; al apagarla vuelven a trabajar.
## Campana: los aldeanos se refugian. Con `max` >= 0 solo los `max` más cercanos al
## enemigo (la IA no vacía la economía por un ataque chico; crítica de balance).
func _cmd_alarm(pid: int, on: bool, max_n: int = -1) -> void:
	players[pid]["alarm"] = on
	if not on:
		for e in owned(pid):
			if e.alive and e.owner == pid and e.fn == "civil" and e.order == O.GARRISON:
				_set_idle(e)
				var res := find_resource(pid, e.gather_kind, e.x, e.y, data.reglas["radio_retomar"], -1, e.id) if e.gather_kind != "" else null
				if res != null:
					_order_gather(e, res)
		for b in buildings_of(pid):
			if b.alive and b.owner == pid and b.is_building() and not b.garrison.is_empty():
				_eject(b)
		return
	var radius: int = data.reglas["radio_campana"]
	var cands: Array[SimEntity] = []
	for e in owned(pid):
		if e.alive and e.owner == pid and e.fn == "civil" and e.inside < 0:
			cands.append(e)
	if max_n >= 0 and cands.size() > max_n:
		# Los más amenazados primero: distancia al soldado enemigo más cercano; desempate por id.
		var danger := {}
		for e in cands:
			var best := 1 << 60
			for o in military():
				if o.alive and o.owner >= 0 and enemies(pid, o.owner) and o.is_military():
					best = mini(best, Sim.dist(e.x, e.y, o.x, o.y))
			danger[e.id] = best
		cands.sort_custom(func(a: SimEntity, b: SimEntity) -> bool: return danger[a.id] < danger[b.id] or (danger[a.id] == danger[b.id] and a.id < b.id))
		cands = cands.slice(0, max_n)
	for e in cands:
		var b := nearest_shelter(pid, e.x, e.y, e.id)
		if b != null and dist_to(e, b) <= radius:
			e.order = O.GARRISON
			e.target = b.id
			e.path_target = -1
	events.append({"t": "alarm", "player": pid})


func garrison_cap(b: SimEntity) -> int:
	return int(b.def.get("guarnicion", 0)) if b.built else 0


## Edificio propio con lugar libre más cercano, contando a quienes ya van en camino.
func nearest_shelter(pid: int, x: int, y: int, exclude_walker: int = -1) -> SimEntity:
	var incoming := {}
	for e in owned(pid):
		if e.alive and e.owner == pid and e.order == O.GARRISON and e.id != exclude_walker and e.target >= 0:
			incoming[e.target] = incoming.get(e.target, 0) + 1
	var best: SimEntity = null
	var best_d := 1 << 60
	var probe := SimEntity.new()
	probe.x = x
	probe.y = y
	for b in buildings_of(pid):
		if not b.alive or b.owner != pid or not b.is_building():
			continue
		if b.garrison.size() + int(incoming.get(b.id, 0)) >= garrison_cap(b):
			continue
		var d := dist_to(probe, b)
		if d < best_d:
			best = b
			best_d = d
	return best


func _do_garrison(e: SimEntity) -> void:
	var b: SimEntity = by_id.get(e.target)
	if b != null and b.is_unit() and (not b.alive or b.owner != e.owner or b.garrison.size() >= garrison_cap(b)):
		_set_idle(e) # --- paso 6 --- la canoa se fue o está llena
		return
	if b == null or not b.alive or b.owner != e.owner or b.garrison.size() >= garrison_cap(b):
		b = nearest_shelter(e.owner, e.x, e.y, e.id)
		if b == null:
			_set_idle(e)
			return
		e.target = b.id
		e.path_target = -1
	var boat_reach := int(data.reglas.get("canoa", {}).get("alcance_embarque", 0)) if b.is_unit() else 0
	if not _approach(e, b, e.radius + INTERACT + boat_reach):
		if e.stuck > 25:
			_tele_stuck(e)
			_set_idle(e)
		return
	e.inside = b.id
	e.order = O.IDLE
	e.path.clear()
	e.x = b.x
	e.y = b.y
	b.garrison.append(e.id)
	events.append({"t": "garrison", "id": e.id, "building": b.id})


## Saca a la gente de los oficios: vuelven a ser aldeanos que recolectan.
func eject_crafts(b: SimEntity) -> void:
	var ids := b.crafts.duplicate()
	b.crafts.clear()
	for id in ids:
		var e: SimEntity = by_id.get(id)
		if e == null or not e.alive:
			continue
		e.inside = -1
		var tile := _spawn_tile(b)
		e.x = tile.x * P + P / 2
		e.y = tile.y * P + P / 2
		_set_idle(e)
		var res := find_resource(e.owner, "alimento", e.x, e.y, data.reglas["radio_retomar"], -1, e.id)
		if res != null:
			_order_gather(e, res)
		events.append({"t": "ungarrison", "id": e.id})


## Saca a todas las unidades alojadas. Los aldeanos vuelven a recolectar.
func _eject(b: SimEntity) -> void:
	var ids := b.garrison.duplicate()
	b.garrison.clear()
	for id in ids:
		var e: SimEntity = by_id.get(id)
		if e == null or not e.alive:
			continue
		e.inside = -1
		var tile := _spawn_tile(b)
		e.x = tile.x * P + P / 2
		e.y = tile.y * P + P / 2
		_set_idle(e)
		if e.fn == "civil" and e.gather_kind != "":
			var res := find_resource(e.owner, e.gather_kind, e.x, e.y, data.reglas["radio_retomar"], -1, e.id)
			if res != null:
				_order_gather(e, res)
		events.append({"t": "ungarrison", "id": e.id})


# ---------------------------------------------------------------- Modificadores

func mod(pid: int, key: String) -> int:
	if pid < 0:
		return 0
	return players[pid]["mods"].get(key, 0)


func _add_mod(pid: int, key: String, v: int) -> void:
	players[pid]["mods"][key] = mod(pid, key) + v


func _apply_effects(pid: int, efectos: Array) -> void:
	for ef: Dictionary in efectos:
		match ef["tipo"]:
			"tasa":
				var keys: Array = ["alimento", "granja", "madera", "piedra", "riqueza"] if ef["recurso"] == "*" else [ef["recurso"]]
				for k in keys:
					_add_mod(pid, "tasa:" + k, ef["pct"])
			"carga":
				_add_mod(pid, "carga", ef["n"])
			"ataque":
				for f in ef["funciones"]:
					_add_mod(pid, "ataque:" + f, ef["n"])
			"ataque_pct":
				for l in ef["lineas"]:
					_add_mod(pid, "atk_pct:" + l, ef["pct"])
			"armadura":
				# Sin `contra`, contra las dos; con `contra` (herrería, paso 2), solo contra cuerpo
				# a cuerpo ("cuerpo") o contra distancia ("distancia").
				var pre: String = ARMOR_KEYS.get(ef.get("contra", ""), "armadura:")
				for f in ef["funciones"]:
					_add_mod(pid, pre + f, ef["n"])
			"vida_pct":
				for f in ef.get("funciones", []):
					_add_mod(pid, "vida:" + f, ef["pct"])
				for l in ef.get("lineas", []):
					_add_mod(pid, "vida_l:" + l, ef["pct"])
			"velocidad_pct":
				for f in ef["funciones"]:
					_add_mod(pid, "vel:" + f, ef["pct"])
			"edificio_vida_pct":
				# --- paso 4 --- `tipos`: solo esos edificios (la fortaleza reforzada)
				if ef.has("tipos"):
					for ty in ef["tipos"]:
						_add_mod(pid, "b_vida_t:" + str(ty), ef["pct"])
				else:
					_add_mod(pid, "b_vida", ef["pct"])
			"motor_pct":
				_add_mod(pid, "motor", ef["pct"])
			"edificio_ataque":
				_add_mod(pid, "b_ataque", ef["n"])
			"edificio_alcance":
				_add_mod(pid, "b_alcance", ef["n"])
			# --- paso 3 --- escuela de la IV (docs/diseno/27, §1.3)
			"asedio_pct":
				_add_mod(pid, "asedio_pct", ef["pct"])
			"asedio_reparable":
				_add_mod(pid, "asedio_rep", 1)
			"costo_tec_pct":
				_add_mod(pid, "tec_desc:%d" % int(ef["edad_min"]), ef["pct"])
			# --- fin paso 3 ---
			# --- paso 4 --- flechas por andanada (aspilleras) y reparación más rápida
			"edificio_flechas":
				if ef.has("tipos"):
					for ty in ef["tipos"]:
						_add_mod(pid, "b_flechas_t:" + str(ty), ef["n"])
				else:
					_add_mod(pid, "b_flechas", ef["n"])
			"reparacion_pct":
				_add_mod(pid, "reparacion", ef["pct"])
			# --- fin paso 4 ---
			# --- paso 6 --- saberes propios (docs/diseno/27, §3; data/civs → tecnologias_nuevas)
			"relevo_pct", "corral_pct", "mercado_venta_pct", "velocidad_vado_pct", "emboscada_pct":
				_add_mod(pid, {"relevo_pct": "relevo_pct", "corral_pct": "corral_pct", "mercado_venta_pct": "venta_pct", "velocidad_vado_pct": "vel_vado", "emboscada_pct": "emboscada"}[ef["tipo"]], ef["pct"])
			"arreo_extra", "potiro_extra":
				_add_mod(pid, "arreo_extra" if ef["tipo"] == "arreo_extra" else "potiro", ef["n"])
			"regen_monte":
				_add_mod(pid, "regen_monte", ef["n"])
				players[pid]["regen_monte_espera"] = int(ef.get("espera_ms", 0))
			"carga_rio":
				_add_mod(pid, "carga_rio", ef["n"])
				players[pid]["carga_rio_radio"] = int(ef.get("radio", 2))
			"renta":
				var rt: Dictionary = players[pid].get_or_add("renta_tipos", {})
				for ty in ef["tipos"]:
					var r1: Dictionary = rt.get_or_add(str(ty), {})
					r1[ef["recurso"]] = int(r1.get(ef["recurso"], 0)) + int(ef["por_min"])
			"costo_unidad_pct":
				for ty in ef["tipos"]:
					_add_mod(pid, "costo_u:" + str(ty), ef["pct"])
			"costo_edificio_pct":
				for ty in ef["tipos"]:
					_add_mod(pid, "costo_b:%s:%s" % [ty, ef.get("recurso", "*")], ef["pct"])
			"obra_pct":
				for ty in ef["tipos"]:
					_add_mod(pid, "obra_t:" + str(ty), ef["pct"])
			"cantidad_pct":
				for ty in ef["tipos"]:
					_add_mod(pid, "cant_pct:" + str(ty), ef["pct"])
			"alcance":
				for ty in ef["tipos"]:
					_add_mod(pid, "alcance_u:" + str(ty), ef["n"])
			"armadura_rio":
				for f in ef["funciones"]:
					_add_mod(pid, "armadura_rio:" + str(f), ef["n"])
				players[pid]["armadura_rio_radio"] = int(ef.get("radio", 2))
			# "habilita": no suma nada; el edificio pide la mejora (`requiere_tec`, build_block)
			# --- paso 6, par 2 --- Etiopía y Palmares (docs/diseno/27, §3.4 y §3.5)
			"oficios_pct", "espinas_pct", "altura_pct":
				_add_mod(pid, ef["tipo"], ef["pct"])
			"renta_pct", "esquiva_pct":
				for ty in ef["tipos"]:
					_add_mod(pid, ("renta_pct:" if ef["tipo"] == "renta_pct" else "esquiva:") + str(ty), ef["pct"])
			"ataque_ruta_pct":
				for l in ef["lineas"]:
					_add_mod(pid, "atk_ruta:" + str(l), ef["pct"])
				players[pid]["ruta_req"] = (ef.get("edificios", ["mercado"]) as Array)
				if ef.get("comercio", false): # --- comercio --- la ruta abierta es un viaje cobrado hace poco
					players[pid]["ruta_comercio"] = true
			"comercio_pct": # --- comercio --- el comerciante rinde más (amole, moradores, astilleros)
				_add_mod(pid, "comercio_pct", ef["pct"])
			"kilombo":
				players[pid]["kilombo"] = {"cada": int(ef["cada"]), "tipo": String(ef["unidad"]), "n": 0}
			"vision_edificio":
				var vx: Dictionary = fog.vision_extra.get_or_add(pid, {})
				for ty in ef["tipos"]:
					vx[str(ty)] = int(vx.get(str(ty), 0)) + int(ef["n"])
			# --- paso 6, par 3 --- Tawantinsuyu y Ayutthaya (docs/diseno/27, §3.1 y §3.6)
			"camino_pct", "suai_pct":
				_add_mod(pid, ef["tipo"], ef["pct"])
			"regen_tropa":
				_add_mod(pid, "regen_tropa", ef["n"])
				players[pid]["regen_tropa_espera"] = int(ef.get("espera_ms", 0))
			"trepanacion":
				players[pid]["trepanacion"] = {"pct": int(ef["pct"]), "radio": int(ef["radio"]), "vida_pct": int(ef["vida_pct"]), "tipos": ef["tipos"], "edificios": ef["edificios"], "n": 0}
			# --- fin paso 6 ---
	for e in owned(pid):
		if e.alive and e.owner == pid:
			_apply_stats(e)


## Vida máxima y velocidad según datos y modificadores; conserva la proporción de vida.
func _apply_stats(e: SimEntity) -> void:
	var base: int = e.def["pv"]
	var pct := mod(e.owner, "b_vida") + mod(e.owner, "b_vida_t:" + e.type) if e.is_building() else mod(e.owner, "vida:" + e.fn) + aura_mod(e, "vida:" + e.fn)
	if e.is_unit():
		var line := SimData.line_of(e.def)
		if line != "":
			pct += mod(e.owner, "vida_l:" + line) + aura_mod(e, "vida_l:" + line)
	var new_max := base * (100 + pct) / 100
	if e.hp_max > 0 and new_max != e.hp_max:
		e.hp = maxi(1, e.hp * new_max / e.hp_max)
	e.hp_max = new_max
	if e.is_unit():
		e.speed = int(e.def["velocidad"]) * (100 + mod(e.owner, "vel:" + e.fn) + aura_mod(e, "vel:" + e.fn)) / 100 * int(data.reglas.get("velocidad_pct", 100)) / 100 * tick_ms / 1000


func _cmd_rally(pid: int, bid: int, x: int, y: int, target_id: int) -> void:
	var b: SimEntity = by_id.get(bid)
	if b == null or not b.alive or b.owner != pid:
		return
	b.rally_set = true
	b.rally_x = x
	b.rally_y = y
	b.rally_target = target_id
	# --- fluidez 2 --- se recuerda qué recurso era, por si se agota antes de que salga el aldeano
	var rt: SimEntity = by_id.get(target_id)
	b.rally_res = rt.type if rt != null and rt.alive and rt.is_resource() else ""
	b.rally_kind = rt.res_kind if rt != null and rt.alive and rt.is_resource() else ""


## Suelta una partida que ya no se usa: mods, grupos, IA y escenario guardan `sim` y forman
## ciclos de referencias que nunca se liberan (miles de objetos "leaked" al salir, y una
## partida entera colgada en memoria por cada reinicio). No cambia el estado: después de
## esto la partida ya no avanza (proceso/24, paso 6e).
func soltar() -> void:
	for ai in ais:
		ai.sim = null
	ais = []
	if mods != null:
		mods.sim = null
	if groups != null:
		groups.sim = null
	if scenario != null:
		scenario.sim = null


## Las partidas creadas desde que arrancó el programa (referencias débiles: no las retienen).
static var _vivas: Array = []

## Suelta todas las partidas que sigan vivas: las pruebas lo llaman al terminar (_finalize)
## para no dejar miles de objetos colgados al salir.
static func soltar_todas() -> void:
	for w in _vivas:
		var s: Sim = w.get_ref()
		if s != null:
			s.soltar()
	_vivas.clear()


# ---------------------------------------------------------------- Paso

func step() -> void:
	_in_step = true
	map.now = tick
	events.clear()
	var cmds: Array = _pending.get(tick, [])
	_pending.erase(tick)
	for c in cmds:
		_apply(c)
	_cur_cmd = "en_marcha" # lo que se rechace después no viene de una orden de este tick
	if not flares.is_empty() or not requests.is_empty():
		_expire_calls()
	if _ai_of != ais:
		_spread_ai()
	for k in ais.size():
		var ai = ais[k]
		if (tick + _ai_phase[k]) % _ai_every[k] == 0 and not players[ai.player]["defeated"]:
			ai.think()
	groups.tick()
	_rebuild_hashes()
	if not shells.is_empty(): # --- esport 1a ---
		_land_shells()
	_update_players()
	for b in all_buildings():
		if b.is_building() and not b.built:
			b.workers_prev = b.workers_now
			b.workers_now = 0
	var count := actives.size()
	for i in count:
		var e := actives[i]
		if not e.alive:
			continue
		if e.is_unit():
			if e.inside < 0:
				_update_unit(e)
		elif e.is_building():
			_update_building(e)
	_separate()
	if not mods.traps.is_empty(): # --- paso 6 --- hoyos con estacas
		mods.tick_traps()
	if tick % 10 == 0:
		mods.tick_second()
		_aura_heal()
		_aura_combat() # --- paso 4 ---
		_wonders() # --- paso 7 ---
	var every: int = data.reglas["niebla_cada_ticks"]
	for pid in players.size():
		if (tick + team_of(pid)) % every == 0:
			_update_fog(pid)
	if _dirty:
		_cleanup()
	_claim_animals()
	tele.check_idle(self)
	if tick % 10 == 5 and not game_over:
		_check_victory()
	if _time_limit_tick > 0 and tick >= _time_limit_tick and not game_over and scenario == null:
		end_by_time()
	if scenario != null:
		scenario.on_step()
	tick += 1
	_in_step = false


## Turnos de la IA (proceso/32-ronda-8/04, rendimiento): cada IA piensa cada
## `piensa_cada_ticks`, en la fase de siempre (`SimAI.thinks_now`: jugador × 5). Con 7 u 8
## jugadores esas fases caían todas en el mismo tick (5 y 10 ticks, fase múltiplo de 5) y ese
## tick sumaba el `think` de todas. Si la fase de siempre ya está ocupada por otra IA, se le da
## la menos cargada: en 1 contra 1 nada cambia; con muchas, como mucho dos por tick. Al elegir,
## el tick de «cada segundo» (tick % 10 == 0: mods, auras, maravillas) cuenta como media IA.
var _ai_of: Array = []
var _ai_phase := PackedInt32Array()
var _ai_every := PackedInt32Array()
func _spread_ai() -> void:
	_ai_of = ais.duplicate()
	_ai_phase.resize(ais.size())
	_ai_every.resize(ais.size())
	var span := 10 # el ciclo de «cada segundo»
	for k in ais.size():
		var ev := maxi(1, int(ais[k].level["piensa_cada_ticks"]))
		_ai_every[k] = ev
		var a := span
		var b := ev
		while b != 0:
			var r := a % b
			a = b
			b = r
		span = span / a * ev
	var solo_ia := PackedInt32Array() # IA que piensan en cada tick del ciclo
	solo_ia.resize(span)
	var carga := PackedInt32Array() # en medias IA: cada IA 2, el tick de cada segundo 1
	carga.resize(span)
	for t in range(0, span, 10):
		carga[t] = 1
	for k in ais.size():
		var ev := _ai_every[k]
		var want := (int(ais[k].player) * 5) % ev
		var best := want
		if _phase_load(solo_ia, want, ev) > 0:
			var best_max := 1 << 30
			for ph in ev:
				var m := _phase_load(carga, ph, ev)
				if m < best_max:
					best = ph
					best_max = m
		_ai_phase[k] = best
		for t in range((ev - best) % ev, span, ev):
			solo_ia[t] += 1
			carga[t] += 2


## Carga máxima de los ticks (dentro del ciclo) en los que piensa una IA con esa fase.
func _phase_load(carga: PackedInt32Array, phase: int, every: int) -> int:
	var m := 0
	for t in range((every - phase) % every, carga.size(), every):
		m = maxi(m, carga[t])
	return m


## Bengalas y pedidos vencidos se borran (reglas.equipos.bengala.dura_ticks, pedido.dura_ticks).
func _expire_calls() -> void:
	var fd := int(data.reglas["equipos"]["bengala"]["dura_ticks"])
	var rd := int(data.reglas["equipos"]["pedido"]["dura_ticks"])
	flares = flares.filter(func(f: Dictionary) -> bool: return tick - int(f["tick"]) <= fd)
	requests = requests.filter(func(r: Dictionary) -> bool: return tick - int(r["tick"]) <= rd)


func _update_players() -> void:
	for p in players:
		p["pop"] = 0
		p["pop_cap"] = 0
	for e in actives:
		if not e.alive or e.owner < 0:
			continue
		if e.is_unit():
			players[e.owner]["pop"] += e.def.get("pob", 1)
		elif e.is_building() and e.built:
			players[e.owner]["pop_cap"] += e.def.get("pob", 0)
	for p in players:
		p["pop_cap"] = mini(p["pop_cap"] + int(p.get("pob_extra", 0)), data.reglas["pob_max"])
	_auras.resize(players.size())
	for pid in players.size():
		_auras[pid] = []
	_aura_g.resize(players.size())
	for pid in players.size():
		_aura_g[pid] = []
	for e in actives:
		if e.alive and e.owner >= 0 and e.built and e.def.get("hito", false) and not aura_of(e).is_empty():
			_auras[e.owner].append(e)
			var a := aura_of(e)
			if a.has("recoleccion_pct"):
				_aura_g[e.owner].append([e, int(a["recoleccion_pct"]), a.get("recursos", null), int(a["radio"])])


## Aura de un hito según el lugar (C-33, como AoE4): la propia del hito o la de su eje en
## reglas.aura_hito. Economía: recolección más rápida cerca; militar: cura a la tropa cerca.
func aura_of(b: SimEntity) -> Dictionary:
	if b.def.has("aura"):
		return b.def["aura"]
	return data.reglas.get("aura_hito", {}).get(String(b.def.get("eje", "")), {})


## Recolección extra (%) de un recurso junto a un hito propio con aura de recolección.
## Corre por cada aldeano que junta: lee `_aura_g` (de `_update_players`, una vez por tick).
var _aura_g: Array = [] # por jugador: [hito, recoleccion_pct, recursos o null, radio]
func _aura_gather(owner: int, t: SimEntity, kind: String) -> int:
	if owner < 0 or owner >= _aura_g.size():
		return 0
	var best := 0
	for g: Array in _aura_g[owner]:
		if g[2] != null and not (g[2] as Array).has(kind):
			continue
		if dist_to(t, g[0]) <= g[3]:
			best = maxi(best, g[1])
	return best


## Cura de los hitos con aura militar: cada segundo, a la tropa propia y aliada que está cerca.
func _aura_heal() -> void:
	for pid in _auras.size():
		for h: SimEntity in _auras[pid]:
			var a := aura_of(h)
			if not a.has("cura_por_s"):
				continue
			var r := int(a["radio"])
			for u in military():
				if u.alive and u.is_unit() and u.inside < 0 and u.owner >= 0 and u.is_military() and u.hp < u.hp_max and not enemies(pid, u.owner) and dist_to(u, h) <= r:
					u.hp = mini(u.hp_max, u.hp + int(a["cura_por_s"]))


# --- paso 4 --- Hitos militares con aura (C-76 a, docs/diseno/27 §4.2)

## ¿El hito `def`, terminado al llegar a la edad `age`, da su bono de combate solo en su aura?
## (reglas.aura_hito.militar.combate_desde_edad: los hitos militares de la III y la IV).
func hito_combat_in_aura(def: Dictionary, age: int) -> bool:
	if String(def.get("eje", "")) != "militar" or not def.get("avanza_edad", false):
		return false
	var desde := int(data.reglas.get("aura_hito", {}).get("militar", {}).get("combate_desde_edad", 0))
	return desde > 0 and age >= desde


const AURA_TYPES := ["ataque", "armadura", "vida_pct", "velocidad_pct", "ataque_pct"]


## Separa los efectos de un hito: [los que siguen siendo globales, las claves de combate en aura].
func _split_aura(efectos: Array) -> Array:
	var keep: Array = []
	var aura := {}
	for ef: Dictionary in efectos:
		var t: String = ef["tipo"]
		if not t in AURA_TYPES:
			keep.append(ef)
			continue
		match t:
			"ataque":
				for f in ef["funciones"]:
					aura["ataque:" + f] = int(aura.get("ataque:" + f, 0)) + int(ef["n"])
			"armadura":
				var pre: String = ARMOR_KEYS.get(ef.get("contra", ""), "armadura:")
				for f in ef["funciones"]:
					aura[pre + f] = int(aura.get(pre + f, 0)) + int(ef["n"])
			"vida_pct":
				for f in ef.get("funciones", []):
					aura["vida:" + f] = int(aura.get("vida:" + f, 0)) + int(ef["pct"])
				for l in ef.get("lineas", []):
					aura["vida_l:" + l] = int(aura.get("vida_l:" + l, 0)) + int(ef["pct"])
			"velocidad_pct":
				for f in ef["funciones"]:
					aura["vel:" + f] = int(aura.get("vel:" + f, 0)) + int(ef["pct"])
			"ataque_pct":
				for l in ef["lineas"]:
					aura["atk_pct:" + l] = int(aura.get("atk_pct:" + l, 0)) + int(ef["pct"])
	return [keep, aura]


## Lo que suma el aura de los hitos militares a una unidad que está dentro (bits de `aura_bits`).
func aura_mod(e: SimEntity, key: String) -> int:
	if e.aura_bits == 0 or e.owner < 0:
		return 0
	var list: Array = players[e.owner].get("aura_combate", [])
	var v := 0
	for i in list.size():
		if e.aura_bits & (1 << i):
			v += int((list[i]["mods"] as Dictionary).get(key, 0))
	return v


## Cada segundo: qué tropa propia está dentro del aura de cada hito militar en pie.
func _aura_combat() -> void:
	var radio := int(data.reglas.get("aura_hito", {}).get("militar", {}).get("radio", 0))
	var lists: Array = []
	var any := false
	for p in players:
		lists.append(p.get("aura_combate", _NONE))
		any = any or not (lists[-1] as Array).is_empty()
	if not any:
		return # nadie tiene hitos militares con aura: no hay bits que limpiar
	for u in all_units():
		if not u.alive or not u.is_unit() or u.owner < 0:
			continue
		var list: Array = lists[u.owner]
		if list.is_empty() and u.aura_bits == 0:
			continue
		var bits := 0
		if u.inside < 0 and u.is_military():
			for i in list.size():
				var h: SimEntity = by_id.get(int(list[i]["id"]))
				if h != null and h.alive and h.built and dist_to(u, h) <= radio:
					bits |= 1 << i
		if bits != u.aura_bits:
			u.aura_bits = bits
			_apply_stats(u)
# --- fin paso 4 ---


func _rebuild_hashes() -> void:
	_grid.clear()
	_ehash.clear()
	_emask.clear()
	for e in actives:
		if not e.alive or e.inside >= 0:
			continue
		if e.is_unit():
			var k := (e.x / P) * 4096 + e.y / P
			if not _grid.has(k):
				_grid[k] = []
			_grid[k].append(e)
			var ek := (e.x / EC) * 1024 + e.y / EC
			if not _ehash.has(ek):
				_ehash[ek] = []
			_ehash[ek].append(e)
			_emask[ek] = int(_emask.get(ek, 0)) | (1 << (e.owner + 1))
		elif e.is_building():
			for cx in range(e.tx * P / EC, ((e.tx + e.w) * P - 1) / EC + 1):
				for cy in range(e.ty * P / EC, ((e.ty + e.h) * P - 1) / EC + 1):
					var ek := cx * 1024 + cy
					if not _ehash.has(ek):
						_ehash[ek] = []
					_ehash[ek].append(e)
					_emask[ek] = int(_emask.get(ek, 0)) | (1 << (e.owner + 1))


func _update_fog(pid: int) -> void:
	# Visión compartida con el equipo (reglas.json → equipos.vision_compartida).
	var shared: bool = data.reglas.get("equipos", {}).get("vision_compartida", true)
	# Con visión compartida, el equipo ve lo mismo: se calcula para el primero y se copia.
	if shared:
		for q in pid:
			if team_of(q) == team_of(pid):
				fog.copy_from(pid, q)
				return
	var sources: Array = []
	for e in actives:
		if e.alive and e.inside < 0 and e.owner >= 0 and (e.owner == pid or (shared and not enemies(pid, e.owner) and team_of(e.owner) == team_of(pid))):
			sources.append(e)
	fog.update(pid, sources)


# ---------------------------------------------------------------- Unidades

func _update_unit(e: SimEntity) -> void:
	if e.cooldown > 0:
		e.cooldown -= tick_ms
	match e.order:
		O.IDLE:
			_do_idle(e)
		O.MOVE:
			e.anchored = false
			if e.group >= 0:
				if groups.member_step(e):
					e.group = -1
					_set_idle(e)
			elif _follow(e):
				_set_idle(e)
		O.ATTACK_MOVE:
			e.anchored = false
			if (tick + e.id) % 3 == 0:
				var t := find_enemy(e, e.def["vision"], false)
				if t != null:
					e.order = O.ATTACK
					e.target = t.id
					e.resume_amove = true
					e.auto_tgt = true
					e.path_target = -1
					return
			if e.group >= 0:
				if groups.member_step(e):
					e.group = -1
					_set_idle(e)
			elif _follow(e):
				if e.patrol:
					_patrol_turn(e)
				else:
					_set_idle(e)
		O.ATTACK:
			_do_attack(e)
		O.HOLD:
			_do_hold(e)
		O.GROUND: # --- esport 1a ---
			_do_ground(e)
		O.GATHER:
			_do_gather(e)
		O.RETURN:
			_do_return(e)
		O.BUILD:
			_do_build(e)
		O.GARRISON:
			_do_garrison(e)
		O.TRADE:
			comercio.update(e) # --- comercio ---


## Patrulla: llegó a una punta, da la vuelta hacia la otra.
func _patrol_turn(e: SimEntity) -> void:
	var nx := e.pat_x
	var ny := e.pat_y
	e.pat_x = e.amove_x
	e.pat_y = e.amove_y
	e.amove_x = nx
	e.amove_y = ny
	_set_goal(e, nx, ny)


## Mantener posición: no se mueve; ataca lo que tenga a su alcance y suelta lo que se aleja.
func _do_hold(e: SimEntity) -> void:
	e.anchored = true
	var reach := reach_of(e)
	var t: SimEntity = by_id.get(e.target)
	if t == null or not t.alive or dist_to(e, t) > reach:
		e.target = -1
		t = null
		if (tick + e.id) % int(data.reglas["ordenes"]["mantener_busca_cada_ticks"]) == 0:
			t = find_enemy(e, reach, false)
			if t != null:
				e.target = t.id
	if t != null and e.cooldown <= 0:
		_hit(e, t)
		e.cooldown = e.def["cadencia_ms"]


func _set_idle(e: SimEntity) -> void:
	e.order = O.IDLE
	e.target = -1
	e.path.clear()
	e.path_i = 0
	e.path_target = -1
	e.anchored = false
	e.resume_amove = false


func _do_idle(e: SimEntity) -> void:
	e.anchored = false
	if e.is_military() and (tick + e.id) % 4 == 0:
		var t := find_enemy(e, e.def["vision"], false)
		if t != null:
			_order_attack(e, t, true)


## `auto`: el blanco lo eligió la unidad (respuesta, inactiva que ve a alguien); si es false
## es orden directa y se respeta aunque aparezca algo más importante.
func _order_attack(e: SimEntity, t: SimEntity, auto := false) -> void:
	e.order = O.ATTACK
	e.target = t.id
	e.path_target = -1
	e.resume_amove = false
	e.auto_tgt = auto


func _order_gather(e: SimEntity, t: SimEntity) -> void:
	e.order = O.GATHER
	e.target = t.id
	e.path_target = -1
	e.gather_kind = resource_kind_of(t)


func _order_build(e: SimEntity, b: SimEntity) -> void:
	e.order = O.BUILD
	e.target = b.id
	e.path_target = -1


func _do_attack(e: SimEntity) -> void:
	var t: SimEntity = by_id.get(e.target)
	if t == null or not t.alive:
		if e.resume_amove:
			e.order = O.ATTACK_MOVE
			e.target = -1
			if e.group < 0:
				_set_goal(e, e.amove_x, e.amove_y) # en grupo vuelve a su lugar en la formación
		else:
			_set_idle(e)
			_do_idle(e)
		return
	# Blanco elegido por su cuenta contra un aldeano o un edificio: cada tantos ticks mira si
	# hay algo más importante en su visión (proceso/24, 5d). Contra militares no rebusca.
	if e.auto_tgt and (tick + e.id) % _retarget_every == 0 and not (t.cat == SimEntity.Cat.UNIT and t.is_military()) \
			and not e.def.get("solo_edificios", false):
		var better := find_enemy(e, e.def["vision"], false)
		if better != null and better != t and target_class(e, better) < target_class(e, t):
			e.target = better.id
			e.path_target = -1
			t = better
	var reach := reach_of(e)
	if _approach(e, t, reach):
		# --- paso 6 --- el weichafe montado tarda en bajarse del caballo cuando llega a pelear (no
		# entre un blanco y el siguiente: solo si venía de `desmonta_tras_ms` sin combate)
		if not e.anchored and e.def.has("desmonta_ms") and tick - e.last_combat >= int(e.def.get("desmonta_tras_ms", 0)) / tick_ms:
			e.cooldown = maxi(e.cooldown, int(e.def["desmonta_ms"]))
		e.anchored = true
		if e.cooldown <= 0:
			_hit(e, t)
			e.cooldown = e.def["cadencia_ms"]
	elif e.stuck > 25:
		_tele_stuck(e)
		_set_idle(e)


func _do_gather(e: SimEntity) -> void:
	var cap: int = int(e.def.get("carga", 10)) + mod(e.owner, "carga")
	var t: SimEntity = by_id.get(e.target)
	# --- paso 6 --- Ygá (guaraníes): el que junta junto al agua carga más.
	if t != null and e.owner >= 0 and mod(e.owner, "carga_rio") > 0 and _res_near_water(t, int(players[e.owner].get("carga_rio_radio", 2))):
		cap += mod(e.owner, "carga_rio")
	if not _valid_source(e, t):
		# Como las ovejas de AoE4: si hay un animal propio cerca, se carnea antes que buscar
		# otra cosa. Cubre la carne que se terminó (carnear en cadena) y el animal suelto que
		# el mismo aldeano reclamó al llegar (jugadores de prueba, ronda 2).
		# Solo si venía de carne o de un animal: el que juntaba frutos sigue con el arbusto
		# de al lado y no va a carnear la llama (el autor, 2026-11-16).
		var from_beast: bool = e.carry_src == "carne" or (t != null and (t.type == "carne" or t.def.get("animal", false)))
		if e.gather_kind == "alimento" and from_beast:
			# Primero la carne que ya está abierta cerca; se carnea otro animal recién cuando no
			# queda (como las ovejas de AoE4; el autor: "no deberían matar todas las llamas de una").
			var radius := int(data.reglas["animales"]["cadena_radio"])
			var open_meat := find_resource(e.owner, "alimento", e.x, e.y, radius, -1, e.id, "carne")
			if open_meat != null:
				_order_gather(e, open_meat)
				return
			var beast := _own_animal_near(e, radius)
			if beast != null:
				var meat := _slaughter(beast)
				if meat != null and meat.alive:
					_order_gather(e, meat)
					return
		# Primero otro del mismo tipo (el arbusto, el árbol o la veta de al lado), como AoE4.
		var same: String = t.type if t != null and t.is_resource() else ("" if e.carry_src in ["", "granja", "carne"] else e.carry_src)
		t = null
		if same != "":
			t = find_resource(e.owner, e.gather_kind, e.x, e.y, data.reglas["radio_rebusca"], -1, e.id, same)
		if t == null:
			t = find_resource(e.owner, e.gather_kind, e.x, e.y, data.reglas["radio_rebusca"], -1, e.id)
		if t == null and e.carry == 0: # --- fluidez 2 --- más lejos, cerca de otro depósito propio
			t = _rebusca_lejos(e.owner, e.x, e.y, e.gather_kind, same, e.id)
		if t == null:
			if e.carry > 0:
				e.order = O.RETURN
				e.aux = -1
				e.path_target = -1
			else:
				_set_idle(e)
			return
		e.target = t.id
		e.path_target = -1
	var kind := resource_kind_of(t)
	if e.carry >= cap or (e.carry > 0 and e.carry_res != kind):
		if tele.on and e.carry >= cap:
			var drop := nearest_dropoff(e.owner, e.carry_res, e.x, e.y)
			if drop != null:
				tele.trip(e.owner, e.carry_res, dist_to(e, drop) / P)
		e.order = O.RETURN
		e.aux = -1
		e.path_target = -1
		return
	var in_range: bool
	var fresh := e.path_target != t.id # elige camino en este tick
	if t.def.get("transitable", false):
		in_range = _approach(e, t, 0)
	else:
		in_range = _approach(e, t, e.radius + INTERACT)
	if not in_range:
		if fresh:
			e.prog_d = 1 << 60
			e.prog_i = 0
			e.prog_tick = tick
		# Recurso al que no se llega (paso 6c): el camino no termina junto a él (nadie del
		# jugador lo vuelve a elegir por un rato), o pasan sin_avance_ticks a más de una casilla
		# sin acercarse ni pasar de casilla del camino (se desliza contra algo; ese aldeano va a
		# otro). A una casilla o menos no cuenta: es la cola de gente alrededor de la carne.
		var d := dist_to(e, t)
		if d < e.prog_d or e.path_i > e.prog_i or d <= P:
			e.prog_d = mini(d, e.prog_d)
			e.prog_i = maxi(e.path_i, e.prog_i)
			e.prog_tick = tick
		var cfg: Dictionary = data.reglas["recurso_inalcanzable"]
		var no_path := fresh and e.path_target == t.id and not _path_reaches(e, t)
		if e.stuck > 25 or no_path or tick - e.prog_tick >= int(cfg["sin_avance_ticks"]):
			if no_path:
				_unreach_res[t.id * 64 + e.owner] = tick + int(cfg["olvido_ticks"])
			var alt: SimEntity = null
			if t.is_resource():
				alt = find_resource(e.owner, e.gather_kind, e.x, e.y, data.reglas["radio_rebusca"], t.id, e.id, t.type)
			if alt == null:
				alt = find_resource(e.owner, e.gather_kind, e.x, e.y, data.reglas["radio_rebusca"], t.id, e.id)
			if alt != null:
				e.target = alt.id
				e.path_target = -1
			elif e.carry > 0:
				e.order = O.RETURN
				e.aux = -1
				e.path_target = -1
			else:
				_set_idle(e)
		return
	e.prog_d = 1 << 60 # si lo empujan fuera de alcance, vuelve a contar desde ahí
	e.anchored = true
	if t.is_building():
		t.farmer = e.id
	var rate_key: String = String(t.def.get("tasa_clave", "granja")) if t.is_building() else String(t.def.get("tasa_clave", kind))
	var clay := mods.clay_bonus(e.owner, t) if t.is_resource() and t.type == "riqueza" else 0
	var rate: int = int(e.def["tasa"].get(rate_key, e.def["tasa"].get("granja", 0))) * (100 + mod(e.owner, "tasa:" + rate_key) + _site_bonus(t) + clay + _aura_gather(e.owner, t, kind)) / 100
	e.carry_res = kind
	e.carry_src = "granja" if t.is_building() else t.type
	# Arcilla ajena o del centro: con el techo de lo disputado lleno, no se extrae.
	if kind == "riqueza" and t.is_resource() and t.res_owner != e.owner and disputed_room(e.owner) - e.carry <= 0:
		return
	e.gather_acc += rate * tick_ms / 1000
	while e.gather_acc >= 1000 and e.carry < cap:
		e.gather_acc -= 1000
		e.carry += 1
		if t.is_resource() or t.def.has("cantidad"):
			t.amount -= 1
			if t.amount <= 0:
				_exhaust(t)
				break


## ¿El camino recién elegido termina junto a `t` (o adentro, si se camina)? Si no, no hay
## forma de llegar: el buscador devolvió el tramo hasta lo más cerca que se puede.
func _path_reaches(e: SimEntity, t: SimEntity) -> bool:
	if e.path.is_empty():
		return true # sin camino calculado: no se juzga acá
	var end: Vector2i = e.path[e.path.size() - 1]
	return end.x >= t.tx - 1 and end.x <= t.tx + t.w and end.y >= t.ty - 1 and end.y <= t.ty + t.h


## Bonificación por sitio de una granja: ladera (andenes) o agua cercana (arrozales).
func _site_bonus(t: SimEntity) -> int:
	if not t.is_building():
		return 0
	var bonus := 0
	if t.def.has("bono_ladera_pct"):
		for yy in range(t.ty, t.ty + t.h):
			for xx in range(t.tx, t.tx + t.w):
				if map.is_slope(xx, yy) or map.h_at(xx, yy) > 0:
					return int(t.def["bono_ladera_pct"])
	if t.def.has("bono_agua_pct") and _near_water(t.tx, t.ty, t.w, t.h, 2):
		bonus += int(t.def["bono_agua_pct"])
	return bonus


## --- paso 6 --- ¿La fuente está a `r` casillas del agua? Se guarda por fuente (no se mueven).
var _water_near_cache := {}
func _res_near_water(t: SimEntity, r: int) -> bool:
	var k := t.id * 8 + r
	if not _water_near_cache.has(k):
		_water_near_cache[k] = _near_water(t.tx, t.ty, t.w, t.h, r)
	return _water_near_cache[k]


func _near_water(tx: int, ty: int, w: int, h: int, r: int) -> bool:
	for yy in range(ty - r, ty + h + r):
		for xx in range(tx - r, tx + w + r):
			if map.is_water(xx, yy):
				return true
	return false


## Fuente agotada. Una chacra de roza deja otra fuente en su lugar (sucesión del monte).
func _exhaust(t: SimEntity) -> void:
	var leaves: String = t.def.get("deja", "")
	var tx := t.tx
	var ty := t.ty
	var owner := t.owner if t.is_building() else t.res_owner
	# Quienes trabajaban ahí siguen en el mismo lugar con lo que sigue (crítica 03b, trampa 5).
	var workers: Array[SimEntity] = []
	for u in actives:
		if u.alive and u.is_unit() and u.target == t.id and (u.order == O.GATHER or u.order == O.RETURN):
			workers.append(u)
	_kill(t)
	var next: SimEntity = null
	if t.is_building() and leaves != "" and owner >= 0:
		next = _roza_follows(t, owner, tx, ty)
	elif t.is_resource() and t.def.has("reabre") and owner >= 0:
		next = _roza_reopens(t, owner, tx, ty)
	elif leaves != "" and data.recursos.has(leaves):
		next = spawn_resource(leaves, tx, ty)
	if next != null:
		events.append({"t": "succession", "x": tx, "y": ty, "type": next.type})
		for u in workers:
			if u.order == O.GATHER:
				_order_gather(u, next)


## Roza guaraní agotada (docs/diseno/revision-economia/v3/04, §3.5.3): con "dejar
## crecer" deja un yerbal del dueño (si no pasa el tope de yerbales activos; si no,
## capuera); con "quemar", la roza se reabre al 60 % sin yerbal.
func _roza_follows(t: SimEntity, owner: int, tx: int, ty: int) -> SimEntity:
	var leaves: String = t.def["deja"]
	var dd := dp(owner)
	if players[owner].get("modo_monte", "crecer") == "quemar":
		var again := spawn_building(t.type, owner, tx, ty, true)
		again.amount = int(t.def.get("cantidad", 0)) * int(t.def.get("quemar_pct", 60)) / 100
		return again
	var caps: Array = t.def.get("yerbales_por_edad", [])
	if not caps.is_empty():
		var active := 0
		for e in entities:
			if e.alive and e.is_resource() and e.type == leaves and e.res_owner == owner:
				active += 1
		if active >= int(caps[clampi(int(players[owner]["age"]) - 1, 0, caps.size() - 1)]):
			var cap_type: String = t.def.get("capuera", "")
			return spawn_resource(cap_type, tx, ty) if data.recursos.has(cap_type) else null
	var y := spawn_resource(leaves, tx, ty)
	y.res_owner = owner
	return y


## Yerbal agotado: la roza se reabre sola en el mismo lugar si el dueño tiene la
## madera (dejando una reserva). Si no alcanza, el suelo queda libre.
func _roza_reopens(t: SimEntity, owner: int, tx: int, ty: int) -> SimEntity:
	var type: String = t.def["reabre"]
	var dd := dp(owner)
	if not dd.edificios.has(type) or not players[owner].get("resiembra", true):
		return null
	var cost := dd.cost_of(type, players[owner]["age"])
	var reserve := int(t.def.get("reserva_madera", 100))
	if int(players[owner]["res"].get("madera", 0)) < int(cost.get("madera", 0)) + reserve or not can_afford(owner, cost):
		events.append({"t": "notice", "player": owner, "text": "Rozas en espera: falta madera para reabrir"})
		return null
	_pay(owner, cost)
	return spawn_building(type, owner, tx, ty, true)


## Aparece una unidad junto a un edificio (acogida, liberación, refuerzos).
func spawn_near(b: SimEntity, type: String, owner: int = -2) -> SimEntity:
	var tile := _spawn_tile(b)
	return spawn_unit(type, b.owner if owner == -2 else owner, tile.x * P + P / 2, tile.y * P + P / 2)


func _do_return(e: SimEntity) -> void:
	var d: SimEntity = by_id.get(e.aux)
	var d_ok := d != null and d.alive and (_accepts(d, e.carry_res) if d.is_building() else (d.def.get("deposito", []) as Array).has(e.carry_res))
	if not d_ok:
		d = nearest_dropoff(e.owner, e.carry_res, e.x, e.y)
		if d == null:
			_set_idle(e)
			return
		e.aux = d.id
		e.path_target = -1
	if not _approach(e, d, e.radius + INTERACT):
		if e.stuck > 25:
			_tele_stuck(e)
			_set_idle(e)
		return
	players[e.owner]["res"][e.carry_res] += e.carry
	players[e.owner]["stats"]["recolectado"] += e.carry
	var origin := _gather_origin(e)
	ledger(e.owner, origin, e.carry_res, e.carry)
	if d.is_unit() and d.def.has("tributo"):
		_tribute(e, d)
	if origin == "disputado" and e.carry_res == "riqueza":
		disputed_add(e.owner, e.carry)
	events.append({"t": "deposit", "id": e.id, "res": e.carry_res, "n": e.carry})
	e.carry = 0
	e.gather_acc = 0
	e.order = O.GATHER
	e.path_target = -1


func _do_build(e: SimEntity) -> void:
	var b: SimEntity = by_id.get(e.target)
	if b == null or not b.alive or (b.built and b.hp >= b.hp_max):
		if b != null and b.alive and b.built and b.def.get("fuente", "") != "" and _farm_free(b, e.id):
			_order_gather(e, b)
			return
		# Almacén recién terminado (como en AoE4): quien lo levantó recolecta lo más
		# cercano de lo que ese almacén recibe (docs/diseno/jugabilidad/02-auditoria.md, §2).
		if b != null and b.alive and b.built and not b.capital and not (b.def.get("deposito", []) as Array).is_empty() and b.def.get("fuente", "") == "":
			var best: SimEntity = null
			var best_d := 1 << 60
			for kind in b.def["deposito"]:
				var r := find_resource(e.owner, kind, b.x, b.y, data.reglas["radio_retomar"], -1, e.id)
				if r != null and dist_to(b, r) < best_d:
					best = r
					best_d = dist_to(b, r)
			if best != null:
				_order_gather(e, best)
				return
		var next := _nearest_unbuilt(e.owner, e.x, e.y, int(data.reglas["grupo"]["ayuda_obra_radio"]))
		if next != null:
			_order_build(e, next)
			return
		# Vuelve a lo que recolectaba antes de construir.
		var res: SimEntity = null
		if e.gather_kind != "":
			res = find_resource(e.owner, e.gather_kind, e.x, e.y, data.reglas["radio_retomar"], -1, e.id)
		if res != null:
			_order_gather(e, res)
		else:
			_set_idle(e)
		return
	if not _approach(e, b, e.radius + INTERACT):
		if e.stuck > 25:
			_tele_stuck(e)
			_set_idle(e)
		return
	e.anchored = true
	if b.built:
		# Reparación: a la velocidad de construcción, sin costo en H1.
		var t_rep: int = maxi(1, dp(b.owner).build_time_of(b.type, 1))
		b.hp = mini(b.hp_max, b.hp + maxi(1, b.hp_max * tick_ms * (100 + mod(b.owner, "reparacion")) / 100 / t_rep)) # --- paso 4 --- reparación rápida
		return
	if b.build_time <= 0:
		_complete(b)
		return
	# La vida sube en proporción exacta al progreso; el daño recibido se conserva.
	# Rendimiento decreciente (P-006): con n constructores la obra tarda tiempo × 3/(n+2).
	b.workers_now += 1
	var step_ms := mods.build_step(b, maxi(1, b.workers_prev))
	var before := (b.hp_max - 1) * b.progress / b.build_time
	b.progress = mini(b.build_time, b.progress + step_ms)
	var after := (b.hp_max - 1) * b.progress / b.build_time
	b.hp = mini(b.hp_max, b.hp + after - before)
	if b.progress >= b.build_time:
		_complete(b)


func _complete(b: SimEntity) -> void:
	b.built = true
	b.progress = b.build_time
	events.append({"t": "built", "id": b.id, "player": b.owner})
	_apply_stats(b)
	if b.def.has("funda_corte"):
		_move_court(b)
		return
	if b.def.get("maravilla", false): # --- paso 7 --- arranca la cuenta (ver `_wonders`)
		events.append({"t": "maravilla", "id": b.id, "player": b.owner})
	if b.def.get("avanza_edad", false):
		var p := players[b.owner]
		(p.get_or_add("hitos_hechos", []) as Array).append(b.type) # --- paso 7 --- (requiere_hito, impide_hito)
		p["age"] = mini(dp(b.owner).edades.size(), p["age"] + 1)
		_age_veins(b.owner, int(p["age"])) # vetas nuevas en la III y la IV (proceso/32-ronda-8/02)
		# --- paso 4 --- C-76 a): desde la III, el bono de combate de los hitos militares vale
		# en su aura, no en todo el mapa (docs/diseno/27, §4.2).
		var efs: Array = b.def.get("efectos", [])
		if hito_combat_in_aura(b.def, int(p["age"])):
			var split := _split_aura(efs)
			efs = split[0]
			if not (split[1] as Dictionary).is_empty():
				(p.get_or_add("aura_combate", []) as Array).append({"id": b.id, "mods": split[1]})
		_apply_effects(b.owner, efs)
		# --- fin paso 4 ---
		events.append({"t": "age", "player": b.owner, "age": p["age"], "hito": b.type})


## La corte se muda (Etiopía, §3.5.4): en el lugar del cimiento aparece la capital
## con el porcentaje de vida de la vieja, que desaparece. Si la nueva quedó lejos y
## junto a arcilla con riqueza, hay fiesta: los gult cercanos rinden el doble 60 s.
func _move_court(b: SimEntity) -> void:
	var pid := b.owner
	var fc: Dictionary = b.def["funda_corte"]
	var old: SimEntity = null
	for e in buildings_of(pid):
		if e.alive and e.owner == pid and e.is_building() and e.capital:
			old = e
			break
	var pct := 100
	var far := true
	if old != null:
		pct = old.hp * 100 / maxi(1, old.hp_max)
		far = Sim.dist(old.x, old.y, b.x, b.y) >= int(fc.get("fiesta_distancia", 25)) * P
	var tx := b.tx
	var ty := b.ty
	remove_quietly(b)
	map.clear(tx, ty, b.w, b.h)
	_close_corridors_of(tx, ty, b.w, b.h, b.id)
	if old != null:
		_eject(old)
		remove_quietly(old)
		map.clear(old.tx, old.ty, old.w, old.h)
		_close_corridors_of(old.tx, old.ty, old.w, old.h, old.id)
	var court := spawn_building(str(fc["edificio"]), pid, tx, ty, true)
	court.capital = true
	court.hp = maxi(1, court.hp_max * pct / 100)
	players[pid]["corte_tick"] = tick
	events.append({"t": "notice", "player": pid, "text": "La corte se asentó en su nuevo lugar"})
	if not far:
		return
	var fiestas: Array = players[pid].get_or_add("fiestas", [])
	for t in resources_near(tx + 2, ty + 2, 6):
		if t.type == "riqueza" and t.amount >= int(fc.get("fiesta_arcilla", 300)) and not fiestas.has(t.id):
			fiestas.append(t.id)
			players[pid]["fiesta_until"] = tick + int(fc.get("fiesta_ms", 60000)) / tick_ms
			events.append({"t": "notice", "player": pid, "text": "¡Fiesta de llegada! Los gult cercanos rinden el doble por un minuto"})
			break


## Ataque con mejoras y porcentaje, antes del contador y la armadura. Lo usa también el
## panel de la unidad, así muestra lo mismo que pega (jugadores de prueba, proceso/22).
func effective_attack(a: SimEntity) -> int:
	var atk: int = a.def.get("ataque", 0)
	if a.is_building():
		atk += mod(a.owner, "b_ataque")
		return atk * (100 + attack_pct(a.owner, a.def, true)) / 100
	atk += mod(a.owner, "ataque:" + a.fn) + aura_mod(a, "ataque:" + a.fn) # --- paso 4 --- aura
	if not mods.mando.is_empty(): # --- paso 6, par 2 --- capitães de mocambo
		atk += int(mods.mando.get(a.id, 0))
	var line := SimData.line_of(a.def)
	return atk * (100 + attack_pct(a.owner, a.def, false) + (aura_mod(a, "atk_pct:" + line) if line != "" else 0)) / 100


## Porcentaje de ataque (docs/diseno/27, paso 1): los edificios que disparan siguen subiendo
## con la edad (`bono_ataque_edificio`); la tropa, solo con lo que se compra por línea
## (`ataque_pct`: la herrería I de ataque, veterano y élite). El asedio, desde el paso 4, con
## sus niveles (veterano_asedio, elite_asedio).
func attack_pct(pid: int, def: Dictionary, building: bool) -> int:
	if pid < 0:
		return 0
	if building:
		return int(dp(pid).edades[players[pid]["age"] - 1].get("bono_ataque_edificio", 0))
	var line := SimData.line_of(def)
	if line == "":
		return 0
	# --- paso 6, par 2 --- pólvora de Massawa: solo con la ruta abierta (un mercado propio en pie)
	return mod(pid, "atk_pct:" + line) + (mod(pid, "atk_ruta:" + line) if players[pid].get("ruta", false) else 0)


## Nivel de la línea de una unidad para `pid`: 0 común, 1 veterano, 2 élite (la interfaz).
func line_level(pid: int, def: Dictionary) -> int:
	var line := SimData.line_of(def)
	if pid < 0 or line == "":
		return 0
	var best := 0
	var techs: Dictionary = dp(pid).tecnologias
	for k in players[pid]["techs"]:
		var t: Dictionary = techs.get(k, {})
		if t.get("linea", "") == line:
			best = maxi(best, int(t.get("nivel", 0)))
	return best


## Lo que antes daba gratis la edad, para quien empieza en una edad avanzada (misiones):
## las investigaciones con `ia_prioridad` desde su edad y los niveles de cada línea hasta la
## edad de inicio, como si las hubiera comprado.
func grant_age_purchases(pid: int, age: int) -> void:
	var techs: Dictionary = dp(pid).tecnologias
	for k in techs:
		var t: Dictionary = techs[k]
		if int(t.get("edad_min", 1)) > age or players[pid]["techs"].has(k):
			continue
		if t.get("ia_prioridad", false) or t.has("nivel"):
			_finish_tech(pid, k)


## Armadura contra cuerpo a cuerpo o contra distancia (como AoE4, C-31). Sin
## `armadura_distancia` en el dato, vale la misma que contra cuerpo a cuerpo.
func effective_armor(t: SimEntity, ranged: bool = false) -> int:
	var base := int(t.def.get("armadura_distancia", t.def.get("armadura", 0))) if ranged else int(t.def.get("armadura", 0))
	if not t.is_unit():
		return base
	var extra := 0
	# --- paso 6 --- el ka'aguygua junto al monte; los arqueros guaraníes junto al río (Mbororé)
	if t.def.has("armadura_monte") and mods.in_forest(t):
		extra += int(t.def["armadura_monte"])
	if t.def.has("armadura_cerca") and mods.near_wall(t, int(t.def["armadura_cerca"]["radio"]), t.def["armadura_cerca"].get("fuertes", false)): # --- paso 6, par 2 --- guarnição da cerca
		extra += int(t.def["armadura_cerca"]["n"])
	if t.owner >= 0 and mod(t.owner, "armadura_rio:" + t.fn) > 0 and mods.near_water(t, int(players[t.owner].get("armadura_rio_radio", 2))):
		extra += mod(t.owner, "armadura_rio:" + t.fn)
	return base + armor_bonus(t.owner, t.fn, ranged) + aura_armor(t, ranged) + extra


## --- paso 6 --- Alcance de una unidad: el de los datos más el de las mejoras (Mbororé: el cañón de tacuara).
func reach_of(e: SimEntity) -> int:
	return int(e.def.get("alcance", 0)) + (mod(e.owner, "alcance_u:" + e.type) if e.owner >= 0 else 0)


## Prefijo del modificador de armadura según `contra` (paso 2 del juego tardío: la herrería
## separa la armadura contra cuerpo a cuerpo de la armadura contra distancia).
const ARMOR_KEYS := {"": "armadura:", "cuerpo": "armadura_c:", "distancia": "armadura_d:"}


## Armadura que suman las mejoras a una función: la de las dos clases más la de la clase del golpe.
func armor_bonus(pid: int, fn: String, ranged: bool) -> int:
	return mod(pid, "armadura:" + fn) + mod(pid, ("armadura_d:" if ranged else "armadura_c:") + fn)


## --- paso 4 --- La armadura del aura de los hitos militares, con la misma separación.
func aura_armor(t: SimEntity, ranged: bool) -> int:
	if t.aura_bits == 0:
		return 0
	return aura_mod(t, "armadura:" + t.fn) + aura_mod(t, ("armadura_d:" if ranged else "armadura_c:") + t.fn)


## ¿Pega a distancia? Decide qué armadura usa el blanco.
func is_ranged(a: SimEntity) -> bool:
	return int(a.def.get("alcance", 0)) > int(data.reglas.get("alcance_distancia", 1500))


## Bono plano de `a` contra `t` (reglas.bonos por función, más el `bono` propio de la unidad,
## que puede nombrar funciones o "montado"). Reemplaza a los multiplicadores entre unidades.
func attack_bonus(a: SimEntity, t: SimEntity) -> int:
	if not t.is_unit():
		return 0
	var rb: Dictionary = (data.reglas.get("bonos", {}) as Dictionary).get(a.fn, {})
	var b := int(rb.get(t.fn, 0))
	var own: Dictionary = a.def.get("bono", {})
	b += int(own.get(t.fn, 0))
	if t.def.get("montado", false) or t.def.get("elefante", false):
		b += int(own.get("montado", 0)) + int(rb.get("montado", 0)) # --- esport 1a --- reglas.bonos también contra «montado»
	return b


func _hit(a: SimEntity, t: SimEntity) -> void:
	if t.def.get("indestructible", false): # --- comercio --- el mercado neutral no se rompe
		return
	# --- esport 1a --- El asedio de área contra tropa tira al punto donde está el blanco y pega al
	# llegar (D-031, reemplaza a D-021 solo para él): quien se mueve a tiempo lo esquiva.
	if a.def.has("area_borde_pct") and t.is_unit():
		_fire_shell(a, t.x, t.y)
		return
	# --- fin esport 1a ---
	var atk := effective_attack(a) + attack_bonus(a, t)
	# --- paso 6 --- Carga (kona de waiki): el primer golpe después de un rato sin pelear pega más y derriba.
	if a.def.has("carga_golpe") and t.is_unit() and tick - a.last_combat >= int(a.def["carga_golpe"]["espera_ms"]) / tick_ms:
		atk += int(a.def["carga_golpe"]["extra"])
		t.slow_until = maxi(t.slow_until, tick + int(a.def["carga_golpe"]["frena_ms"]) / tick_ms)
	if a.fn == "asedio" and t.is_building():
		atk = atk * (100 + mod(a.owner, "asedio_pct")) / 100 # --- paso 3 --- escuela: oficio del asedio
	var mult := counter_mult(a, t) # --- paso 4 ---
	var armor := effective_armor(t, is_ranged(a))
	# Altura (D-027): quien dispara desde más arriba pega más fuerte.
	if int(a.def.get("alcance", 0)) > 1500:
		var dh := map.h_at(a.x / P, a.y / P) - map.h_at(t.x / P, t.y / P)
		if dh > 0:
			atk = atk * (100 + dh * int(data.reglas["bono_altura_pct"])) / 100
	var dmg := maxi(data.reglas["danio_minimo"], atk * mult / 100 - armor)
	dmg = mods.damage(a, t, dmg)
	t.hp -= dmg
	if t.hp <= 0 and t.is_unit() and t.owner >= 0 and players[t.owner].has("trepanacion"): # --- paso 6, par 3 --- cirugía de cráneo
		mods.trepan(a, t)
	if t.hp <= 0 and t.built and t.def.has("sitiada"): # --- paso 7 --- la maravilla sitiada no cae (C-97 a)
		t.hp = 1
	# Espinas (cerca con estrepes de Palmares): devuelve daño al atacante cuerpo a cuerpo.
	if t.def.has("espinas") and a.is_unit() and int(a.def.get("alcance", 0)) <= 1500:
		a.hp -= int(t.def["espinas"]) * (100 + mod(t.owner, "espinas_pct")) / 100 # --- paso 6, par 2 --- forja y fojos
		if a.hp <= 0:
			mods.on_kill(a, t)
			_kill(a)
	mods.on_hit(a, t, dmg)
	# Daño en área (elefantes): una fracción a los enemigos cercanos al objetivo.
	if a.def.has("area") and t.is_unit() and not a.def.has("area_borde_pct"): # --- paso 4 --- el asedio de área va por _splash
		var r: int = a.def["area"]
		for o in all_units():
			if o != t and o.alive and o.is_unit() and o.inside < 0 and o.owner >= 0 and enemies(a.owner, o.owner) and absi(o.x - t.x) <= r and absi(o.y - t.y) <= r:
				o.hp -= maxi(1, dmg * int(a.def.get("area_pct", 50)) / 100)
				if o.hp <= 0:
					mods.on_kill(o, a)
					_kill(o)
	# --- paso 4 --- Asedio de área (catapulta y la de cada pueblo): golpe con caída hacia el borde.
	if a.def.has("area_borde_pct"):
		_splash(a, t)
	# --- fin paso 4 ---
	# Munición limitada (cañón de tacuara): se rompe tras n disparos.
	if a.def.has("municion"):
		a.shots += 1
		if a.shots >= int(a.def["municion"]):
			a.hp = 0
			_kill(a)
	var ranged: bool = a.def.get("alcance", 0) > 1500
	events.append({"t": "hit", "a": a.id, "b": t.id, "ranged": ranged, "dmg": dmg})
	if t.owner >= 0:
		if t.is_unit() and t.is_military() and t.order == O.IDLE:
			_order_attack(t, a, true)
		elif t.is_unit() and t.order == O.ATTACK and t.auto_tgt and a.is_unit() and a.is_military() \
				and a.alive and not t.def.get("solo_edificios", false):
			# Le pega un militar mientras ella, por su cuenta, le pegaba a un aldeano o a un
			# edificio: se da vuelta (proceso/24, 5d).
			var cur: SimEntity = by_id.get(t.target)
			if cur == null or not cur.alive or target_class(t, cur) >= TC_CIVIL:
				t.target = a.id
				t.path_target = -1
		var p := players[t.owner]
		if tick - p["alert_tick"] > 150:
			p["alert_tick"] = tick
			events.append({"t": "alert", "player": t.owner, "x": t.x, "y": t.y})
	if t.hp <= 0:
		if t.owner >= 0:
			players[t.owner]["stats"]["muertes"] += 1
		if a.owner >= 0:
			players[a.owner]["stats"]["bajas"] += 1
			if t.is_building() and t.owner >= 0 and enemies(a.owner, t.owner):
				players[a.owner]["stats"]["edificios_destruidos"] = int(players[a.owner]["stats"].get("edificios_destruidos", 0)) + 1
		mods.on_kill(t, a)
		_kill(t, a)


# --- paso 4 ---
## Multiplicador de `a` contra `t`: reglas.contadores, pisado por los `contadores` propios del
## que pega (el asedio de área pega a la tropa), por los de `recibe` del blanco (los
## incendiarios mapuches no son máquinas: la distancia los daña entero) y, contra edificios, por
## `bono_material` (madera o piedra: `material`, o piedra si cuesta piedra o es hito).
func counter_mult(a: SimEntity, t: SimEntity) -> int:
	var mult: int = data.reglas["contadores"].get(a.fn, {}).get(t.fn, 100)
	if a.def.has("contadores"):
		mult = int((a.def["contadores"] as Dictionary).get(t.fn, mult))
	if t.def.has("recibe"):
		# --- muralla --- por tipo antes que por función (los incendiarios, contra la piedra)
		mult = int((t.def["recibe"] as Dictionary).get(a.type, (t.def["recibe"] as Dictionary).get(a.fn, mult)))
	if t.is_building() and a.def.has("bono_material"):
		mult = mult * int((a.def["bono_material"] as Dictionary).get(material_of(t.def), 100)) / 100
	return mult


static func material_of(def: Dictionary) -> String:
	if def.has("material"):
		return String(def["material"])
	return "piedra" if int((def.get("costo", {}) as Dictionary).get("piedra", 0)) > 0 or def.get("avanza_edad", false) else "madera"


## Daño de área alrededor del blanco: a cada enemigo a `area` o menos, el golpe que le tocaría
## (con su armadura), entero en el centro y `area_borde_pct` en el borde. Busca en la grilla de
## enemigos (`_ehash`), así no cuesta recorrer todo el mapa por disparo.
func _splash(a: SimEntity, t: SimEntity) -> void:
	if a.owner < 0:
		return
	var r := int(a.def["area"])
	var edge := int(a.def["area_borde_pct"])
	var base := effective_attack(a)
	var ranged := is_ranged(a)
	var cx := t.x
	var cy := t.y
	for gx in range(maxi(0, (cx - r) / EC), (cx + r) / EC + 1):
		for gy in range(maxi(0, (cy - r) / EC), (cy + r) / EC + 1):
			var cell: Array = _ehash.get(gx * 1024 + gy, _NONE)
			for o: SimEntity in cell:
				if o == t or not o.alive or not o.is_unit() or o.inside >= 0 or o.owner < 0 or not enemies(a.owner, o.owner):
					continue
				var d := Sim.dist(cx, cy, o.x, o.y)
				if d > r:
					continue
				var full := maxi(int(data.reglas["danio_minimo"]), (base + attack_bonus(a, o)) * counter_mult(a, o) / 100 - effective_armor(o, ranged))
				var dmg := maxi(1, mods.damage(a, o, full * (100 - (100 - edge) * d / r) / 100))
				o.hp -= dmg
				if o.hp <= 0:
					players[o.owner]["stats"]["muertes"] += 1
					players[a.owner]["stats"]["bajas"] += 1
					mods.on_kill(o, a)
					_kill(o, a)
	events.append({"t": "area", "a": a.id, "x": cx, "y": cy, "r": r})


# --- esport 1a --- Asedio de área esquivable y ataque al suelo (D-031).
## Ticks de vuelo del tiro de `a`: el suyo (`vuelo_ticks`) o el de reglas.asedio_area.
func shell_ticks(a: SimEntity) -> int:
	return maxi(1, int(a.def.get("vuelo_ticks", int((data.reglas.get("asedio_area", {}) as Dictionary).get("vuelo_ticks", 1)))))


## Tira al punto (x, y): el golpe sale ahora (con la altura de ahora) y llega en shell_ticks.
func _fire_shell(a: SimEntity, x: int, y: int) -> void:
	var atk := effective_attack(a)
	if int(a.def.get("alcance", 0)) > 1500:
		var dh := map.h_at(a.x / P, a.y / P) - map.h_at(clampi(x / P, 0, map.n - 1), clampi(y / P, 0, map.n - 1))
		if dh > 0:
			atk = atk * (100 + dh * int(data.reglas["bono_altura_pct"])) / 100
	var fly := shell_ticks(a)
	shells.append({"tick": tick + fly, "x": x, "y": y, "a": a, "atk": atk})
	a.last_combat = tick
	events.append({"t": "tiro", "a": a.id, "x": x, "y": y, "ticks": fly})
	# Munición limitada (cañón de tacuara): se rompe tras n disparos.
	if a.def.has("municion"):
		a.shots += 1
		if a.shots >= int(a.def["municion"]):
			a.hp = 0
			_kill(a)


## Los tiros que llegan en este tick pegan en su punto, en el orden en que salieron.
func _land_shells() -> void:
	var keep: Array[Dictionary] = []
	for sh in shells:
		if int(sh["tick"]) <= tick:
			_shell_hit(sh)
		else:
			keep.append(sh)
	shells = keep


## Golpe de área en el punto: a cada enemigo a `area` o menos, entero en el centro y
## `area_borde_pct` en el borde, con su armadura (como _splash, pero sin blanco: pega a quien
## esté ahí cuando llega). El tiro llega aunque el que tiró haya muerto.
func _shell_hit(sh: Dictionary) -> void:
	var a: SimEntity = sh["a"]
	if a.owner < 0 or players[a.owner]["defeated"]:
		return
	var r := int(a.def["area"])
	var edge := int(a.def["area_borde_pct"])
	var base := int(sh["atk"])
	var ranged := is_ranged(a)
	var cx := int(sh["x"])
	var cy := int(sh["y"])
	var alerted := {}
	for gx in range(maxi(0, (cx - r) / EC), (cx + r) / EC + 1):
		for gy in range(maxi(0, (cy - r) / EC), (cy + r) / EC + 1):
			var cell: Array = _ehash.get(gx * 1024 + gy, _NONE)
			for o: SimEntity in cell:
				if not o.alive or not o.is_unit() or o.inside >= 0 or o.owner < 0 or not enemies(a.owner, o.owner):
					continue
				var d := Sim.dist(cx, cy, o.x, o.y)
				if d > r:
					continue
				var full := maxi(int(data.reglas["danio_minimo"]), (base + attack_bonus(a, o)) * counter_mult(a, o) / 100 - effective_armor(o, ranged))
				var dmg := maxi(1, mods.damage(a, o, full * (100 - (100 - edge) * d / r) / 100))
				o.hp -= dmg
				mods.on_hit(a, o, dmg)
				events.append({"t": "hit", "a": a.id, "b": o.id, "ranged": false, "dmg": dmg, "area": true})
				if o.hp <= 0:
					players[o.owner]["stats"]["muertes"] += 1
					players[a.owner]["stats"]["bajas"] += 1
					mods.on_kill(o, a)
					_kill(o, a)
					continue
				# La tropa quieta que recibe el golpe sale a buscar al que tiró, y el dueño recibe el aviso.
				if o.is_military() and o.order == O.IDLE and a.alive:
					_order_attack(o, a, true)
				if not alerted.has(o.owner) and tick - int(players[o.owner]["alert_tick"]) > 150:
					alerted[o.owner] = true
					players[o.owner]["alert_tick"] = tick
					events.append({"t": "alert", "player": o.owner, "x": o.x, "y": o.y})
	events.append({"t": "area", "a": a.id, "x": cx, "y": cy, "r": r})


## ¿Puede atacar el suelo? El asedio de área (el que tiene `area_borde_pct`).
static func can_ground(e: SimEntity) -> bool:
	return e.is_unit() and e.def.has("area_borde_pct")


## Orden de atacar el suelo: va hasta tener el punto a su alcance y tira ahí hasta otra orden.
func _cmd_ground(_pid: int, units: Array[SimEntity], x: int, y: int) -> void:
	x = clampi(x, 100, map.n * P - 100)
	y = clampi(y, 100, map.n * P - 100)
	for e in units:
		if not can_ground(e):
			continue
		_set_idle(e)
		e.group = -1
		e.patrol = false
		e.order = O.GROUND
		e.gnd_x = x
		e.gnd_y = y


func _do_ground(e: SimEntity) -> void:
	if dist(e.x, e.y, e.gnd_x, e.gnd_y) > reach_of(e):
		e.anchored = false
		if e.path.is_empty() or e.goal_x != e.gnd_x or e.goal_y != e.gnd_y:
			if e.stuck > 25:
				_set_idle(e)
				return
			_set_goal(e, e.gnd_x, e.gnd_y)
		if _follow(e):
			_set_idle(e)
		return
	e.path.clear()
	e.path_i = 0
	e.stuck = 0
	e.anchored = true
	if e.cooldown <= 0:
		_fire_shell(e, e.gnd_x, e.gnd_y)
		e.cooldown = e.def["cadencia_ms"]
# --- fin esport 1a ---


## Flechas de una andanada: las propias, las de las mejoras (aspilleras) y una por unidad adentro.
func volley_shots(b: SimEntity) -> int:
	return int(b.def.get("flechas", 1)) + mod(b.owner, "b_flechas") + mod(b.owner, "b_flechas_t:" + b.type) + b.garrison.size()
# --- fin paso 4 ---


func _kill(e: SimEntity, killer: SimEntity = null) -> void:
	if not e.alive:
		return
	e.alive = false
	e.hp = 0
	_dirty = true
	if e.is_unit() and e.def.get("comerciante", false):
		comercio.on_died(e) # --- comercio --- (mediciones)
	if e.is_unit() and e.def.has("carne"):
		_leave_meat(e) # un animal muerto (también uno robado al rival) deja su carne
	if e.is_unit() and not e.garrison.is_empty(): # --- paso 6 --- la canoa se hunde: nadan a la orilla
		_unload(e, int(data.reglas.get("canoa", {}).get("nado_casillas", 3)), true)
	if e.is_building() or e.is_resource():
		map.clear(e.tx, e.ty, e.w, e.h, e.is_resource())
	if e.is_building():
		_close_corridors_of(e.tx, e.ty, e.w, e.h, e.id)
		mods.on_building_removed(e)
		_eject(e)
		eject_crafts(e)
		for item in e.queue:
			if item.begins_with("@"):
				players[e.owner]["pending"].erase(item.substr(1))
	events.append({"t": "died", "id": e.id, "owner": e.owner, "type": e.type, "cat": e.cat, "by": killer.owner if killer != null else -1, "x": e.x, "y": e.y})
	if e.is_building() and e.def.get("maravilla", false) and e.owner >= 0: # --- paso 7 ---
		events.append({"t": "maravilla_cae", "id": e.id, "player": e.owner, "terminada": e.built, "tipo": e.type, "x": e.x, "y": e.y})


func _cleanup() -> void:
	_dirty = false
	var keep: Array[SimEntity] = []
	for e in entities:
		if e.alive:
			keep.append(e)
		else:
			by_id.erase(e.id)
	entities = keep
	var keep_a: Array[SimEntity] = []
	for e in actives:
		if e.alive:
			keep_a.append(e)
	actives = keep_a
	var keep_m: Array[SimEntity] = []
	for e in _military:
		if e.alive:
			keep_m.append(e)
	_military = keep_m
	var keep_b: Array[SimEntity] = []
	for e in _buildings:
		if e.alive:
			keep_b.append(e)
	_buildings = keep_b
	var keep_u: Array[SimEntity] = []
	for e in _units:
		if e.alive:
			keep_u.append(e)
	_units = keep_u
	var keep_s: Array[SimEntity] = []
	for e in _sacred:
		if e.alive:
			keep_s.append(e)
	_sacred = keep_s
	for d: Dictionary in [_owned, _owned_b, _fighters]:
		for k in d:
			var keep_o: Array[SimEntity] = []
			for e: SimEntity in d[k]:
				if e.alive:
					keep_o.append(e)
			d[k] = keep_o


# ---------------------------------------------------------------- Edificios

func _update_building(b: SimEntity) -> void:
	if not b.built:
		# Cimientos que se levantan solos (la corte nueva etíope).
		if b.def.get("autoconstruye", false) and b.build_time > 0:
			b.progress = mini(b.build_time, b.progress + tick_ms)
			b.hp = maxi(b.hp, b.hp_max * int(b.def.get("vida_inicial_pct", 25)) / 100)
			if b.progress >= b.build_time:
				_complete(b)
		return
	if b.repeat != "" and b.queue.is_empty(): # --- frente 1 ---
		_repeat_try(b)
	if not b.queue.is_empty():
		var item: String = b.queue[0]
		var p := players[b.owner]
		var is_tech := item.begins_with("@")
		if not is_tech and b.queue_progress == 0 and p["pop"] + int(dp(b.owner).unidades[item].get("pob", 1)) > p["pop_cap"]:
			if (tick + b.id) % 100 == 0:
				_notify(b.owner, "Población llena")
		else:
			var pct := mods.production_pct(b)
			# Lof extra (mapuches, §3.5.2): fuera de la capital entrenan más lento.
			if not b.capital and not is_tech and b.def.has("lento_fuera_de_capital_pct"):
				pct = pct * 100 / (100 + int(b.def["lento_fuera_de_capital_pct"]))
			b.queue_progress += tick_ms * pct / 100
			if b.queue_progress >= dp(b.owner).queue_time(item):
				b.queue.remove_at(0)
				if not b.queue_paid.is_empty():
					b.queue_paid.remove_at(0)
				b.queue_progress = 0
				if is_tech:
					_finish_tech(b.owner, item.substr(1))
				else:
					_spawn_from(b, item)
	if b.def.has("ataque"):
		if b.cooldown > 0:
			b.cooldown -= tick_ms
		else:
			# Andanada: flechas propias más una por unidad alojada.
			var reach: int = int(b.def["alcance"]) + mod(b.owner, "b_alcance")
			var shots: int = volley_shots(b) # --- paso 4 --- aspilleras
			var t := find_enemy(b, reach, true)
			if t != null:
				for i in shots:
					if not t.alive:
						t = find_enemy(b, reach, true)
						if t == null:
							break
					_hit(b, t)
				b.cooldown = b.def["cadencia_ms"]


func _finish_tech(pid: int, tech: String) -> void:
	var p := players[pid]
	p["pending"].erase(tech)
	var rep: Dictionary = dp(pid).tecnologias[tech].get("repite", {})
	if rep.is_empty():
		p["techs"][tech] = true
	else:
		# --- ronda 8, 05 --- la que se repite: queda abierta hasta la última vez.
		var done: Dictionary = p.get_or_add("repetidas", {})
		done[tech] = int(done.get(tech, 0)) + 1
		if rep.has("max") and int(done[tech]) >= int(rep["max"]): # --- esport 2a --- sin `max`, sin tope
			p["techs"][tech] = true
	_apply_effects(pid, dp(pid).tecnologias[tech]["efectos"])
	events.append({"t": "tech", "player": pid, "tech": tech})


func _spawn_from(b: SimEntity, type: String) -> void:
	var tile := _spawn_tile(b)
	if dp(b.owner).unidades[type].get("navega", false): # --- paso 6 --- la canoa sale al agua
		var wt := water_tile_near(b, int(dp(b.owner).unidades[type].get("agua_max", 5)))
		if wt.x >= 0:
			tile = wt
	var u := spawn_unit(type, b.owner, tile.x * P + P / 2, tile.y * P + P / 2)
	players[b.owner]["stats"]["entrenadas"] += 1
	events.append({"t": "trained", "id": u.id, "player": b.owner, "type": type})
	if not b.rally_set:
		return
	var rt: SimEntity = by_id.get(b.rally_target)
	if u.def.get("comerciante", false) and comercio.dest_kind(b.owner, rt) != "" and rt != b: # --- comercio --- reunión en un mercado: sale a la ruta
		u.trade_home = b.id
		comercio.order_route(b.owner, [u], rt)
		if u.order == O.TRADE:
			return
	if rt != null and rt.alive and u.fn == "civil" and (rt.is_resource() or (rt.is_building() and rt.owner == b.owner and rt.def.get("fuente", "") != "")):
		_order_gather(u, rt)
	elif rt != null and rt.alive and u.fn == "civil" and rt.is_building() and rt.owner == b.owner and not rt.built:
		_order_build(u, rt)
	elif u.fn == "civil" and b.rally_kind != "" and (rt == null or not rt.alive or (rt.is_resource() and rt.amount <= 0)):
		# --- fluidez 2 --- la reunión estaba en un recurso que se agotó: el más cercano del mismo
		# tipo junto al punto, o lejos, cerca de otro depósito propio (reglas.rebusca_lejos).
		var alt := find_resource(b.owner, b.rally_kind, b.rally_x, b.rally_y, data.reglas["radio_rebusca"], -1, u.id, b.rally_res)
		if alt == null:
			alt = find_resource(b.owner, b.rally_kind, b.rally_x, b.rally_y, data.reglas["radio_rebusca"], -1, u.id)
		if alt == null:
			alt = _rebusca_lejos(b.owner, b.rally_x, b.rally_y, b.rally_kind, b.rally_res, u.id)
		if alt != null:
			b.rally_target = alt.id # la reunión sigue en el recurso nuevo
			_order_gather(u, alt)
		else:
			_cmd_move(b.owner, [u] as Array[SimEntity], b.rally_x, b.rally_y, false)
	else:
		_cmd_move(b.owner, [u] as Array[SimEntity], b.rally_x, b.rally_y, u.is_military())


func _spawn_tile(b: SimEntity) -> Vector2i:
	for r in range(1, 6):
		for xx in range(b.tx - r, b.tx + b.w + r):
			if not map.is_solid(xx, b.ty + b.h - 1 + r, b.owner):
				return Vector2i(xx, b.ty + b.h - 1 + r)
		for yy in range(b.ty - r, b.ty + b.h + r):
			if not map.is_solid(b.tx + b.w - 1 + r, yy, b.owner):
				return Vector2i(b.tx + b.w - 1 + r, yy)
			if not map.is_solid(b.tx - r, yy, b.owner):
				return Vector2i(b.tx - r, yy)
		for xx in range(b.tx - r, b.tx + b.w + r):
			if not map.is_solid(xx, b.ty - r, b.owner):
				return Vector2i(xx, b.ty - r)
	return Vector2i(b.tx, b.ty + b.h)


# ---------------------------------------------------------------- Canoas (paso 6)

## ¿La casilla es sólida para `e`? La canoa (`navega`) solo anda por el agua (honda o vado); el
## resto, como siempre (map.is_solid con sus puertas).
func solid_for(e: SimEntity, tx: int, ty: int) -> bool:
	if e.def.get("navega", false):
		return not map.is_water(tx, ty)
	return map.is_solid(tx, ty, e.owner)


## Agua libre más cerca del edificio `b`, a `r` casillas o menos de su borde ((-1, -1) si no hay).
func water_tile_near(b: SimEntity, r: int) -> Vector2i:
	for k in range(1, r + 1):
		for yy in range(b.ty - k, b.ty + b.h + k):
			for xx in range(b.tx - k, b.tx + b.w + k):
				if (xx == b.tx - k or xx == b.tx + b.w + k - 1 or yy == b.ty - k or yy == b.ty + b.h + k - 1) and map.is_water(xx, yy):
					return Vector2i(xx, yy)
	return Vector2i(-1, -1)


## Baja a los que van en la canoa `boat` a la tierra libre más cercana, a `r` casillas o menos. Sin
## orilla cerca, se quedan arriba (con un aviso) o, si se hunde (`sinking`), se ahogan.
func _unload(boat: SimEntity, r: int, sinking: bool = false) -> void:
	var cx := boat.x / P
	var cy := boat.y / P
	var land := Vector2i(-1, -1)
	var best := 1 << 30
	for yy in range(cy - r, cy + r + 1):
		for xx in range(cx - r, cx + r + 1):
			if map.in_bounds(xx, yy) and not map.is_water(xx, yy) and not map.is_solid(xx, yy, boat.owner):
				var d := (xx - cx) * (xx - cx) + (yy - cy) * (yy - cy)
				if d < best:
					best = d
					land = Vector2i(xx, yy)
	if land.x < 0:
		if not sinking:
			_notify(boat.owner, "Acercá la canoa a la orilla para bajar")
			return
		for id in boat.garrison:
			var u: SimEntity = by_id.get(id)
			if u != null and u.alive:
				u.inside = -1
				_kill(u)
		boat.garrison.clear()
		return
	var ids := boat.garrison.duplicate()
	boat.garrison.clear()
	for id in ids:
		var e: SimEntity = by_id.get(id)
		if e == null or not e.alive:
			continue
		e.inside = -1
		e.x = land.x * P + P / 2
		e.y = land.y * P + P / 2
		_set_idle(e)
		events.append({"t": "ungarrison", "id": e.id})


func _path_for(e: SimEntity, from: Vector2i, to: Vector2i) -> Array[Vector2i]:
	if e.def.get("navega", false):
		return map.find_boat_path(from, to)
	return map.find_path(from, to, e.owner)


# ---------------------------------------------------------------- Movimiento

func _set_goal(e: SimEntity, gx: int, gy: int, target_id: int = -1) -> void:
	gx = clampi(gx, 100, map.n * P - 100)
	gy = clampi(gy, 100, map.n * P - 100)
	e.goal_x = gx
	e.goal_y = gy
	e.path_target = target_id
	e.path_tick = tick
	e.stuck = 0
	var from := Vector2i(e.x / P, e.y / P)
	var to := Vector2i(gx / P, gy / P)
	if solid_for(e, from.x, from.y):
		var f2 := map.nearest_free(from.x, from.y, 6, e.owner) if not e.def.get("navega", false) else map.nearest_water(from.x, from.y, 6)
		e.path = [from] as Array[Vector2i]
		if f2.x >= 0:
			e.path.append_array(_path_for(e, f2, to))
		e.path_i = 1
	else:
		e.path = _path_for(e, from, to)
		e.path_i = 1
	# Telemetría: el camino no llega a la casilla pedida (y la casilla no es sólida: no es un edificio).
	if tele.on and e.owner >= 0 and not map.is_solid(to.x, to.y, e.owner) and (e.path.is_empty() or e.path[e.path.size() - 1] != to):
		tele.add(tick, "sin_camino", e.owner, to.x, to.y, {"desde": [from.x, from.y], "tipo": e.type}, "sc:%d" % e.id, 100)


## Avanza por el camino. Devuelve true al llegar (o al rendirse si está trabado).
func _follow(e: SimEntity) -> bool:
	if e.stuck > 15:
		_tele_stuck(e)
		return true
	var goal_tile := Vector2i(e.goal_x / P, e.goal_y / P)
	while e.path_i < e.path.size():
		var wp := e.path[e.path_i]
		var last := e.path_i == e.path.size() - 1
		var px := wp.x * P + P / 2
		var py := wp.y * P + P / 2
		if last and wp == goal_tile and not solid_for(e, wp.x, wp.y):
			px = e.goal_x
			py = e.goal_y
		if not last and dist(e.x, e.y, px, py) < 380:
			e.path_i += 1
			continue
		if _step_toward(e, px, py):
			e.path_i += 1
			return e.path_i >= e.path.size()
		return false
	if solid_for(e, goal_tile.x, goal_tile.y):
		return true
	return _step_toward(e, e.goal_x, e.goal_y)


## Avanza en línea recta. Devuelve true si llegó al punto.
func _step_toward(e: SimEntity, px: int, py: int) -> bool:
	return step_toward_speed(e, px, py, mods.speed(e))


## Como `_step_toward`, con una velocidad dada (los grupos: corrida de rezagados).
func step_toward_speed(e: SimEntity, px: int, py: int, spd: int) -> bool:
	var dx := px - e.x
	var dy := py - e.y
	var d := isqrt(dx * dx + dy * dy)
	if d == 0:
		return true
	var nx := px
	var ny := py
	if d > spd:
		nx = e.x + dx * spd / d
		ny = e.y + dy * spd / d
	var moved := _try_move(e, nx, ny)
	if moved == 2:
		e.stuck = 0
		return d <= spd
	if moved == 0:
		e.stuck += 1
	return false


## 2 = movimiento completo, 1 = deslizó por un eje, 0 = bloqueado.
func _try_move(e: SimEntity, nx: int, ny: int) -> int:
	var lim := map.n * P - 50
	nx = clampi(nx, 50, lim)
	ny = clampi(ny, 50, lim)
	# --- equipos ronda 3 --- Sin cortar esquinas: pasar en diagonal entre dos casillas sólidas
	# (dos árboles, un muro y una casa) metía a la unidad en un bolsillo de 1 a 3 casillas libres
	# del que el buscador de caminos (diagonal solo sin obstáculos) no la saca: 1297 caminos
	# imposibles en el 2v2 de fortines, todos de unidades que entraron así (proceso/24, paso 4l).
	# Ahora vale la misma regla que el buscador; si no puede, se desliza por un eje.
	var cx := e.x / P
	var cy := e.y / P
	var tx := nx / P
	var ty := ny / P
	if e.def.get("navega", false): # --- paso 6 --- la canoa, solo por el agua
		var bc := tx != cx and ty != cy and (not map.is_water(tx, cy) or not map.is_water(cx, ty))
		if not map.is_water(cx, cy) or (map.is_water(tx, ty) and not bc):
			e.x = nx
			e.y = ny
			return 2
		if map.is_water(nx / P, e.y / P):
			e.x = nx
			return 1
		if map.is_water(e.x / P, ny / P):
			e.y = ny
			return 1
		return 0
	var corner := tx != cx and ty != cy and (map.is_solid(tx, cy, e.owner) or map.is_solid(cx, ty, e.owner))
	if map.is_solid(cx, cy, e.owner) or (not map.is_solid(tx, ty, e.owner) and not corner):
		e.x = nx
		e.y = ny
		return 2
	if not map.is_solid(nx / P, e.y / P, e.owner):
		e.x = nx
		return 1
	if not map.is_solid(e.x / P, ny / P, e.owner):
		e.y = ny
		return 1
	return 0


## Se acerca a la entidad hasta `reach`. Devuelve true si ya está en alcance.
func _approach(e: SimEntity, t: SimEntity, reach: int) -> bool:
	var d := dist_to(e, t)
	if d <= reach:
		e.path.clear()
		e.path_i = 0
		e.stuck = 0
		return true
	e.anchored = false
	if t.is_unit():
		if d < 2500:
			_step_toward(e, t.x, t.y)
			return false
		var ttile := Vector2i(t.x / P, t.y / P)
		if e.path_target != t.id or (tick - e.path_tick >= 8 and ttile != Vector2i(e.goal_x / P, e.goal_y / P)):
			_set_goal(e, t.x, t.y, t.id)
		_follow(e)
		return false
	if e.path_target != t.id:
		if t.def.get("transitable", false):
			_set_goal(e, t.x, t.y, t.id)
		else:
			# Al costado libre más cercano a quien llega, no al centro: hacia el centro, el
			# camino terminaba siempre en la misma casilla del borde (el autor, 2026-11-15:
			# "para depositar recursos hay que ir solo por un lugar específico").
			var side := _side_tile(e, t)
			_set_goal(e, side.x * P + P / 2, side.y * P + P / 2, t.id)
	if _follow(e):
		var cx := clampi(e.x, t.tx * P, (t.tx + t.w) * P)
		var cy := clampi(e.y, t.ty * P, (t.ty + t.h) * P)
		_step_toward(e, cx, cy)
	return false


## Casilla libre junto al edificio `t` más cercana a `e` (la del centro si no hay ninguna).
func _side_tile(e: SimEntity, t: SimEntity) -> Vector2i:
	var best := Vector2i(t.x / P, t.y / P)
	var best_d := 1 << 60
	for yy in range(t.ty - 1, t.ty + t.h + 1):
		for xx in range(t.tx - 1, t.tx + t.w + 1):
			if xx >= t.tx and xx < t.tx + t.w and yy >= t.ty and yy < t.ty + t.h:
				continue
			if not map.in_bounds(xx, yy) or map.is_solid(xx, yy, e.owner):
				continue
			var d := dist(e.x, e.y, xx * P + P / 2, yy * P + P / 2)
			if d < best_d:
				best_d = d
				best = Vector2i(xx, yy)
	return best


func _separate() -> void:
	# Cada par se separa cada `separacion_cada_ticks` ticks con el empujón multiplicado:
	# la misma velocidad de separación por la mitad del trabajo (docs/11, paso 6).
	var every := maxi(1, int(data.reglas.get("separacion_cada_ticks", 1)))
	var cap := 160 * every
	for e in all_units():
		if not e.alive or not e.is_unit() or e.inside >= 0:
			continue
		if (e.id + tick) % every != 0:
			continue
		var cx := e.x / P
		var cy := e.y / P
		for ox in range(cx - 1, cx + 2):
			for oy in range(cy - 1, cy + 2):
				var cell: Array = _grid.get(ox * 4096 + oy, _NONE)
				for o: SimEntity in cell:
					if o.id <= e.id or not o.alive:
						continue
					var rr := e.radius + o.radius
					var dx := o.x - e.x
					var dy := o.y - e.y
					if absi(dx) >= rr or absi(dy) >= rr:
						continue
					var d2 := dx * dx + dy * dy
					if d2 >= rr * rr:
						continue
					var d := isqrt(d2)
					if d == 0:
						dx = 1 if (e.id & 1) == 0 else -1
						dy = 0
						d = 1
					var push := mini((rr - d), cap)
					var we := 50
					if e.anchored and not o.anchored:
						we = 15
					elif o.anchored and not e.anchored:
						we = 85
					var pe := push * we / 100
					var po := push - pe
					_try_move(o, o.x + dx * po / d, o.y + dy * po / d)
					_try_move(e, e.x - dx * pe / d, e.y - dy * pe / d)


# ---------------------------------------------------------------- Consultas

## Prioridad de blanco automático de una unidad, como AoE4 (proceso/24, 5d): cuanto más chica,
## más importante. Dentro de la misma clase gana el más cercano. El militar que le pega va
## primero por otro lado: `_hit` la da vuelta hacia él en el momento del golpe. Entre militares
## no se ordena por "quién me tiene de blanco": cuesta en el bench (persiguen al de atrás) y
## cambia las peleas entre tropas, que no son lo que se arregla acá.
const TC_MILITARY := 1  # militar
const TC_CIVIL := 2     # aldeano (y cualquier unidad no militar)
const TC_SHOOTER := 3   # edificio terminado que dispara y la tiene a su alcance (torre, centro)
const TC_BUILDING := 4  # otro edificio
const TC_FLOOR := 5     # pieza transitable (granja, andén, gult, corral): lo último
const TC_STEP := 1 << 24 # más que cualquier distancia del mapa


func target_class(e: SimEntity, o: SimEntity) -> int:
	if o.is_unit():
		return TC_MILITARY if o.is_military() else TC_CIVIL
	return _building_class(e, o, dist_to(e, o))


func _building_class(e: SimEntity, o: SimEntity, d: int) -> int:
	if o.def.get("transitable", false):
		return TC_FLOOR
	if o.built and o.def.has("ataque") and d <= int(o.def["alcance"]) + mod(o.owner, "b_alcance"):
		return TC_SHOOTER
	return TC_BUILDING


## El enemigo más importante a `radius` de `e`. Una unidad elige por `target_class` y nunca
## elige sola un edificio con `sin_blanco_automatico` (los caminos: solo con orden directa); un
## edificio que dispara mantiene su criterio (distancia, con los aldeanos y los edificios más lejos).
func find_enemy(e: SimEntity, radius: int, units_only: bool) -> SimEntity:
	var by_unit := e.is_unit()
	var buildings_only: bool = by_unit and e.def.get("solo_edificios", false)
	var best: SimEntity = null
	var best_score := 1 << 60
	var x0 := maxi(0, (e.x - radius) / EC)
	var x1 := (e.x + radius) / EC
	var y0 := maxi(0, (e.y - radius) / EC)
	var y1 := (e.y + radius) / EC
	var foes := _foe_bits[e.owner] if e.owner >= 0 and e.owner < _foe_bits.size() else -1
	for cx in range(x0, x1 + 1):
		for cy in range(y0, y1 + 1):
			if int(_emask.get(cx * 1024 + cy, 0)) & foes == 0:
				continue
			var cell: Array = _ehash.get(cx * 1024 + cy, _NONE)
			for o: SimEntity in cell:
				if not o.alive or o.owner == e.owner:
					continue
				if o.owner >= 0 and e.owner >= 0 and not enemies(e.owner, o.owner):
					continue # aliado
				# Neutrales: solo los hostiles, y nunca entre neutrales.
				if o.owner < 0 and (e.owner < 0 or not bool(o.def.get("hostil", false))):
					continue
				if e.owner < 0 and o.type == "comerciante": # --- comercio --- el ingenio no le tira al comerciante
					continue
				if units_only and not o.is_unit():
					continue
				if buildings_only and not o.is_building():
					continue
				# Caminos: solo con orden directa (5d).
				if by_unit and o.is_building() and o.def.get("sin_blanco_automatico", false):
					continue
				if mods.is_hidden_now(o) and not mods.detected_by(o, e.owner):
					continue
				var d := dist_to(e, o)
				if d > radius:
					continue
				var score := d
				if by_unit:
					# target_class(e, o) en línea: esto corre por cada candidato.
					if o.cat == SimEntity.Cat.UNIT:
						score += (TC_MILITARY if o.is_military() else TC_CIVIL) * TC_STEP
					else:
						score += _building_class(e, o, d) * TC_STEP
				elif not o.is_unit():
					score += 6000
				elif not o.is_military():
					score += 3000
				if score < best_score or (score == best_score and o.id < best.id):
					best = o
					best_score = score
	return best


func find_resource(owner: int, kind: String, x: int, y: int, max_d: int, exclude: int = -1, worker: int = -1, only_type: String = "") -> SimEntity:
	var best: SimEntity = null
	var best_d := max_d + 1
	var probe := SimEntity.new()
	probe.x = x
	probe.y = y
	if kind == "alimento" and only_type == "":
		for t in buildings_of(owner):
			if t.alive and t.is_building() and t.owner == owner and t.built and t.id != exclude and t.def.get("fuente", "") == kind and _farm_free(t, worker):
				var d := dist_to(probe, t)
				if d < best_d:
					best = t
					best_d = d
	# Recursos del mapa: anillos de celdas hasta que no puedan mejorar.
	var cx := x / P / RC
	var cy := y / P / RC
	var max_r := max_d / P / RC + 1
	var skip := not _unreach_res.is_empty() and owner >= 0
	for r in range(0, max_r + 1):
		if best != null and (r - 1) * RC * P > best_d:
			break
		for dy in range(-r, r + 1):
			for dx in range(-r, r + 1):
				if absi(dx) != r and absi(dy) != r:
					continue
				var cell: Array = _res_cells.get((cx + dx) * 1024 + cy + dy, [])
				for t: SimEntity in cell:
					if not t.alive or t.id == exclude or t.res_kind != kind or t.amount <= 0 or (only_type != "" and t.type != only_type):
						continue
					if kind == "riqueza" and t.res_owner != owner and disputed_room(owner) <= 0:
						continue # techo de lo disputado lleno: no sirve ir a esa arcilla
					if skip and tick < int(_unreach_res.get(t.id * 64 + owner, -1)):
						continue # no se llega (paso 6c)
					var d := dist_to(probe, t)
					if d < best_d or (d == best_d and best != null and t.id < best.id):
						if not map.has_free_neighbor(t.tx, t.ty, t.w, t.h):
							continue
						best = t
						best_d = d
	return best

func nearest_dropoff(owner: int, kind: String, x: int, y: int) -> SimEntity:
	var best: SimEntity = null
	var best_d := 1 << 60
	var probe := SimEntity.new()
	probe.x = x
	probe.y = y
	for b in owned(owner):
		if not b.alive or b.owner != owner:
			continue
		# Depósitos que caminan (elefante del rey de Ayutthaya): unidades con "deposito".
		if b.is_unit():
			if not (b.def.get("deposito", []) as Array).has(kind) or b.inside >= 0:
				continue
		elif not b.is_building() or not b.built or not _accepts(b, kind):
			continue
		var d := dist_to(probe, b)
		if d < best_d or (d == best_d and best != null and b.id < best.id):
			best = b
			best_d = d
	return best


# --- fluidez 2 --- (proceso/30-fluidez/02-constructor.md)
## Rebusca lejana: el recurso de `kind` (primero del tipo `only_type`) más cercano a (x, y) entre
## los que están a reglas.rebusca_lejos.radio_deposito de un depósito propio terminado que lo
## recibe, con ese depósito a rebusca_lejos.max o menos. null si no hay o si está apagada.
func _rebusca_lejos(owner: int, x: int, y: int, kind: String, only_type: String, worker: int) -> SimEntity:
	var cfg: Dictionary = data.reglas.get("rebusca_lejos", {})
	var max_d := int(cfg.get("max", 0))
	if max_d <= 0 or kind == "":
		return null
	var probe := SimEntity.new()
	probe.x = x
	probe.y = y
	var tipos := [only_type, ""] if only_type != "" else [""]
	for tipo: String in tipos:
		var best: SimEntity = null
		var best_d := 1 << 60
		for b in buildings_of(owner):
			if not b.alive or b.owner != owner or not b.is_building() or not b.built or not _accepts(b, kind):
				continue
			if dist_to(probe, b) > max_d:
				continue
			var r := find_resource(owner, kind, b.x, b.y, int(cfg["radio_deposito"]), -1, worker, tipo)
			if r == null or (r.is_building() and tipo == ""):
				continue # las granjas ya las busca la rebusca de siempre
			var d := dist_to(probe, r)
			if d < best_d or (d == best_d and r.id < best.id):
				best = r
				best_d = d
		if best != null:
			return best
	return null
# --- fin fluidez 2 ---


func _nearest_unbuilt(owner: int, x: int, y: int, max_d: int) -> SimEntity:
	var best: SimEntity = null
	var best_d := max_d + 1
	var probe := SimEntity.new()
	probe.x = x
	probe.y = y
	for b in buildings_of(owner):
		if b.alive and b.is_building() and b.owner == owner and not b.built:
			var d := dist_to(probe, b)
			if d < best_d:
				best = b
				best_d = d
	return best


func _valid_source(e: SimEntity, t: SimEntity) -> bool:
	if t == null or not t.alive:
		return false
	if t.is_resource():
		return t.amount > 0
	return t.is_building() and t.owner == e.owner and t.built and t.def.get("fuente", "") != "" and _farm_free(t, e.id)


func _farm_free(farm: SimEntity, worker: int) -> bool:
	if farm.farmer == -1 or farm.farmer == worker:
		return true
	var f: SimEntity = by_id.get(farm.farmer)
	if f == null or not f.alive or f.target != farm.id or not (f.order == O.GATHER or f.order == O.RETURN):
		farm.farmer = -1
		return true
	return false


func _accepts(b: SimEntity, kind: String) -> bool:
	return b.built and (b.def.get("deposito", []) as Array).has(kind)


func resource_kind_of(t: SimEntity) -> String:
	if t.is_resource():
		return t.res_kind
	return t.def.get("fuente", "")


func dist_to(e: SimEntity, t: SimEntity) -> int:
	if t.is_unit():
		return maxi(0, dist(e.x, e.y, t.x, t.y) - t.radius)
	var cx := clampi(e.x, t.tx * P, (t.tx + t.w) * P)
	var cy := clampi(e.y, t.ty * P, (t.ty + t.h) * P)
	return dist(e.x, e.y, cx, cy)


static func dist(ax: int, ay: int, bx: int, by: int) -> int:
	var dx := bx - ax
	var dy := by - ay
	return isqrt(dx * dx + dy * dy)


## Raíz cuadrada entera con corrección (determinista).
static func isqrt(n: int) -> int:
	if n <= 0:
		return 0
	var r := int(sqrt(float(n)))
	while r * r > n:
		r -= 1
	while (r + 1) * (r + 1) <= n:
		r += 1
	return r


func can_afford(pid: int, cost: Dictionary) -> bool:
	var res: Dictionary = players[pid]["res"]
	for k in cost:
		if res.get(k, 0) < cost[k]:
			return false
	return true


func _pay(pid: int, cost: Dictionary) -> void:
	for k in cost:
		players[pid]["res"][k] -= cost[k]


func _refund(pid: int, cost: Dictionary) -> void:
	for k in cost:
		players[pid]["res"][k] += cost[k]


func can_place(type: String, tx: int, ty: int, pid: int = -1) -> bool:
	if not dp(pid).edificios.has(type):
		return false
	var tam: Array = dp(pid).edificios[type]["tam"]
	if tx < 0 or ty < 0 or tx + tam[0] > map.n or ty + tam[1] > map.n:
		return false
	if dp(pid).edificios[type].get("puerta", false) and _own_wall_at(tx, ty, pid) != null:
		return true
	# --- muralla --- (proceso/32-ronda-8/06) encima de una pieza propia: reforzar la empalizada,
	# la puerta de piedra sobre la de madera, la torre sobre un tramo de muralla.
	if _own_piece_under(type, tx, ty, pid) != null:
		return true
	if dp(pid).edificios[type].get("solo_sobre", false):
		return false
	# --- fin muralla ---
	var def: Dictionary = dp(pid).edificios.get(type, data.edificios.get(type, {}))
	if not map.is_free_rect(tx, ty, tam[0], tam[1]):
		return false
	if pid >= 0 and (def.has("maximo_por_edad") or def.has("separacion")) and not _engine_slot_ok(type, def, tx, ty, pid):
		return false
	if pid >= 0 and def.has("funda_corte") and not _court_site_ok(def["funda_corte"], tx, ty, pid):
		return false
	if def.get("requiere_agua", false) and not _near_water(tx, ty, tam[0], tam[1], 2):
		return false
	if def.get("permite_ladera", false):
		for yy in range(ty, ty + tam[1]):
			for xx in range(tx, tx + tam[0]):
				if map.is_water(xx, yy):
					return false
		return true
	return map.is_flat(tx, ty, tam[0], tam[1])


## Pasillo entre edificios pegados (el autor, 2026-11-15: "en AoE4, entre edificios pegados
## igual queda un caminito"). El más nuevo de dos edificios que se tocan deja caminable su fila
## de casillas contra el más viejo: queda un pasillo de una casilla y se pueden pegar. Los
## muros (`linea`), las puertas y `reglas.pasillo_entre_edificios.cierran` no abren: cierran.
func _corridor_ok(b: SimEntity) -> bool:
	var cfg: Dictionary = data.reglas.get("pasillo_entre_edificios", {})
	return b.is_building() and bool(cfg.get("activo", false)) and not b.def.get("transitable", false) \
		and not b.def.get("linea", false) and not b.def.get("puerta", false) and not (cfg.get("cierran", []) as Array).has(b.type)


## Vuelve a tapar la huella de `b` y abre las casillas del borde que tocan a un edificio más viejo.
func _refresh_corridor(b: SimEntity) -> void:
	if not _corridor_ok(b):
		return
	map.mark(b.tx, b.ty, b.w, b.h, b.id, true)
	for yy in range(b.ty, b.ty + b.h):
		for xx in range(b.tx, b.tx + b.w):
			if xx > b.tx and xx < b.tx + b.w - 1 and yy > b.ty and yy < b.ty + b.h - 1:
				continue
			for d in [Vector2i(-1, 0), Vector2i(1, 0), Vector2i(0, -1), Vector2i(0, 1)]:
				var nx: int = xx + d.x
				var ny: int = yy + d.y
				if nx >= b.tx and nx < b.tx + b.w and ny >= b.ty and ny < b.ty + b.h:
					continue
				var o: SimEntity = by_id.get(map.occupant(nx, ny))
				if o != null and o.alive and o.id < b.id and _corridor_ok(o):
					map.open_tile(xx, yy)
					break


## Al sacar un edificio: los más nuevos que lo tocaban cierran el pasillo que le dejaban.
func _close_corridors_of(tx: int, ty: int, w: int, h: int, gone_id: int) -> void:
	var seen := {}
	for yy in range(ty - 1, ty + h + 1):
		for xx in range(tx - 1, tx + w + 1):
			var o: SimEntity = by_id.get(map.occupant(xx, yy))
			if o != null and o.alive and o.id > gone_id and not seen.has(o.id):
				seen[o.id] = true
				_refresh_corridor(o)


## ¿Queda cupo para otra pieza de motor de este tipo en la edad actual? Sin mirar el lugar:
## la IA lo pregunta antes de recorrer cientos de lugares que fallarían todos.
func engine_room(type: String, pid: int) -> bool:
	var def: Dictionary = dp(pid).edificios.get(type, {})
	var maxes: Array = def.get("maximo_por_edad", [])
	if maxes.is_empty():
		return true
	var count := 0
	for e in owned(pid):
		if e.alive and e.owner == pid and e.type == type:
			count += 1
	var age := clampi(int(players[pid]["age"]) - 1, 0, maxes.size() - 1)
	return count < int(maxes[age]) + int(mods.engine_max_bonus(pid, type))


## Piezas de motor (docs/diseno/revision-economia/v3/04, §3.1): máximo por edad,
## contando las que están en obra, y separación mínima entre piezas del mismo tipo.
func _engine_slot_ok(type: String, def: Dictionary, tx: int, ty: int, pid: int) -> bool:
	var maxes: Array = def.get("maximo_por_edad", [])
	var sep := int(def.get("separacion", 0))
	var count := 0
	for e in owned(pid):
		if not e.alive or e.owner != pid or e.type != type:
			continue
		count += 1
		if sep > 0 and maxi(absi(e.tx - tx), absi(e.ty - ty)) < sep:
			return false
	if not maxes.is_empty():
		var age := clampi(int(players[pid]["age"]) - 1, 0, maxes.size() - 1)
		if count >= int(maxes[age]) + int(mods.engine_max_bonus(pid, type)):
			return false
	return true


## ¿Se puede fundar la corte acá? Una cada 5 min, sin cimiento en obra, sin Gondar,
## lejos de bases militares rivales y sin combate cerca.
func _court_site_ok(fc: Dictionary, tx: int, ty: int, pid: int) -> bool:
	if tick - int(players[pid].get("corte_tick", -100000)) < int(fc.get("cada_ms", 300000)) / tick_ms:
		return false
	var cx := tx * P + 2 * P
	var cy := ty * P + 2 * P
	var far := int(fc.get("lejos_de", 20)) * P
	var fight := int(fc.get("sin_combate", 15)) * P
	# Por listas (proceso/32-ronda-8/07): la IA etíope prueba ~200 casillas seguidas y recorrer
	# actives en cada una costaba 320 ms. Es la misma pregunta (sí o no), sin depender del orden.
	for e in buildings_of(pid):
		if e.alive and (e.def.has("funda_corte") or e.def.get("capital_fija", false)):
			return false
	for q in players.size():
		if not enemies(pid, q):
			continue
		for e in buildings_of(q):
			if e.alive and Sim.dist(e.x, e.y, cx, cy) < far and (e.capital or e.type in ["torre", "cuartel", "centro"] or _cost_total(e.def.get("costo", {})) >= 150):
				return false
		for e in fighters_of(q):
			if e.alive and e.is_military() and tick - e.last_combat < 100 and Sim.dist(e.x, e.y, cx, cy) < fight:
				return false
	return true


func _cost_total(c: Dictionary) -> int:
	var t := 0
	for k in c:
		t += int(c[k])
	return t


## Empalizada propia en la casilla (una puerta puede reemplazarla).
func _own_wall_at(tx: int, ty: int, pid: int) -> SimEntity:
	var w: SimEntity = by_id.get(map.occupant(tx, ty))
	if w != null and w.alive and w.owner == pid and w.def.get("linea", false):
		return w
	return null


func _replace_wall(type: String, tx: int, ty: int, pid: int) -> void:
	var under := _own_piece_under(type, tx, ty, pid) # --- muralla ---
	if under != null:
		_kill(under)
		return
	if not dp(pid).edificios[type].get("puerta", false):
		return
	var w := _own_wall_at(tx, ty, pid)
	if w != null:
		_kill(w)


## --- muralla --- La pieza propia de 1×1 que `type` reemplaza en la casilla (su lista `sobre`:
## la empalizada bajo la muralla, la puerta de madera bajo la de piedra, el tramo bajo la torre).
func _own_piece_under(type: String, tx: int, ty: int, pid: int) -> SimEntity:
	var over: Array = dp(pid).edificios[type].get("sobre", [])
	if over.is_empty() or pid < 0:
		return null
	var w: SimEntity = by_id.get(map.occupant(tx, ty))
	if w != null and w.alive and w.owner == pid and w.w == 1 and w.h == 1 and over.has(w.type):
		return w
	return null


## Construcción en línea (empalizadas): un cimiento por casilla; los aldeanos siguen de uno al siguiente.
func _cmd_build_line(pid: int, units: Array[SimEntity], type: String, tiles: Array) -> void:
	var def: Dictionary = dp(pid).edificios.get(type, {})
	if not def.get("linea", false):
		return
	if int(players[pid]["age"]) < int(def.get("edad_min", 1)): # --- muralla --- la de piedra, desde la II
		_notify(pid, "Requiere edad %s" % _roman(def.get("edad_min", 1)))
		return
	var cost := dp(pid).cost_of(type, players[pid]["age"])
	var first: SimEntity = null
	var placed := 0
	for t in tiles:
		if not can_afford(pid, cost):
			_notify(pid, "Recursos insuficientes")
			break
		if not can_place(type, t[0], t[1], pid):
			continue
		_replace_wall(type, t[0], t[1], pid) # --- muralla --- reforzar la empalizada
		_pay(pid, cost)
		var b := spawn_building(type, pid, t[0], t[1], false)
		placed += 1
		if first == null:
			first = b
	if first == null:
		return
	events.append({"t": "placed", "id": first.id, "player": pid})
	for e in units:
		if e.fn == "civil":
			_order_build(e, first)


func hito_in_progress(pid: int) -> bool:
	for b in owned(pid):
		if b.alive and b.owner == pid and b.def.get("avanza_edad", false) and not b.built:
			return true
	return false


func _notify(pid: int, msg: String) -> void:
	events.append({"t": "notify", "player": pid, "msg": msg})
	tele.add(tick, "rechazo", pid, -1, -1, {"msg": msg, "orden": _cur_cmd, "ia": _is_ai(pid)}, "rz:%d:%s:%s" % [pid, msg, _cur_cmd], 50)


func _is_ai(pid: int) -> bool:
	for ai in ais:
		if ai.player == pid:
			return true
	return false


## Carne de un animal: un recurso en su casilla (o la libre más cercana).
func _leave_meat(a: SimEntity) -> SimEntity:
	var t := map.nearest_free(a.x / P, a.y / P, 4)
	if t.x < 0 or not map.is_free_rect(t.x, t.y, 1, 1):
		return null
	var m := spawn_resource("carne", t.x, t.y)
	m.amount = int(a.def.get("carne", m.amount))
	return m


func _own_animal_near(e: SimEntity, r: int) -> SimEntity:
	var best: SimEntity = null
	var bd := r + 1
	for a in actives:
		if a.alive and a.owner == e.owner and a.def.get("animal", false):
			var d := dist(a.x, a.y, e.x, e.y)
			if d < bd or (d == bd and best != null and a.id < best.id):
				bd = d
				best = a
	return best


## Carnear: el aldeano convierte su animal en carne y se pone a juntarla.
func _slaughter(a: SimEntity) -> SimEntity:
	var m := _leave_meat(a)
	a.def = a.def.duplicate()
	a.def.erase("carne") # remove_quietly no vuelve a dejar carne
	remove_quietly(a)
	return m


## Animales sueltos: pasan a ser del jugador con la unidad más cercana a `reclamo_radio`
## (como las ovejas de AoE4). Una vez por segundo.
func _claim_animals() -> void:
	if _wild.is_empty() or tick % 10 != 3:
		return
	var r := int(data.reglas["animales"]["reclamo_radio"])
	var rt := r / P + 1
	var keep: Array[SimEntity] = []
	for w in _wild:
		if not w.alive:
			continue
		var best: SimEntity = null
		var bd := r + 1
		for dy in range(-rt, rt + 1):
			for dx in range(-rt, rt + 1):
				for u: SimEntity in _grid.get((w.tx + dx) * 4096 + w.ty + dy, _NONE):
					if not u.alive or u.owner < 0 or u.def.get("animal", false) or u.inside >= 0:
						continue
					var d := dist(u.x, u.y, w.x, w.y)
					if d < bd or (d == bd and best != null and u.id < best.id):
						bd = d
						best = u
		if best == null:
			keep.append(w)
			continue
		var x := w.x
		var y := w.y
		w.alive = false
		map.clear(w.tx, w.ty, w.w, w.h)
		_dirty = true
		events.append({"t": "absorbed", "id": w.id, "owner": -1})
		spawn_unit("rebano", best.owner, x, y)
		events.append({"t": "animal_reclamado", "player": best.owner, "x": x, "y": y})
	_wild = keep


## Telemetría: una unidad se rindió (no puede llegar o quedó trabada).
func _tele_stuck(e: SimEntity) -> void:
	if tele.on and e.owner >= 0:
		tele.add(tick, "trabada", e.owner, e.x / P, e.y / P, {"tipo": e.type, "orden": int(e.order), "destino": [e.goal_x / P, e.goal_y / P]}, "tb:%d" % e.id, 100)


static func _roman(n: int) -> String:
	return ["", "I", "II", "III", "IV"][clampi(n, 0, 4)]


# ---------------------------------------------------------------- Victoria

## Conquista (siempre): pierde quien se queda sin los edificios que cuentan. Con la victoria
## por hitos (la de siempre) cuentan la capital, los hitos y lo marcado `cuenta_victoria`;
## sin ella (opts.hitos_sin_victoria), cualquier edificio terminado salvo muros, puertas y
## caminos, y hay que arrasar todo.
func _check_victory() -> void:
	var has_hito := []
	has_hito.resize(players.size())
	has_hito.fill(false)
	for b in all_buildings():
		if b.alive and b.owner >= 0 and b.is_building() and b.built and counts_for_victory(b):
			has_hito[b.owner] = true
	for p in players:
		if not p["defeated"] and not has_hito[p["id"]]:
			_defeat(p["id"])


## ¿Este edificio mantiene vivo a su dueño? (ver `_check_victory`; la IA ataca estos).
func counts_for_victory(b: SimEntity) -> bool:
	if not _opts.get("hitos_sin_victoria", false):
		return b.def.get("hito", false) or b.capital or b.def.get("cuenta_victoria", false)
	return not (b.def.get("linea", false) or b.def.get("camino", false) or b.type == "puerta" or b.def.get("sagrado", false) or b.def.has("trampa"))


## Puntaje (reglas.puntaje): recursos juntados, bajas, edificios enemigos destruidos, edad e
## investigaciones. Decide la partida con tiempo límite; la interfaz lo muestra (F6).
func score(pid: int) -> int:
	var pc: Dictionary = data.reglas["puntaje"]
	var p := players[pid]
	var tot := 0
	var book: Dictionary = p["stats"].get("origen", {})
	for o in book:
		for k in book[o]:
			tot += int(book[o][k])
	var s := tot / maxi(1, int(pc["recursos_por_punto"]))
	s += int(p["stats"]["bajas"]) * int(pc["por_baja"])
	s += int(p["stats"].get("edificios_destruidos", 0)) * int(pc["por_edificio_destruido"])
	s += (int(p["age"]) - 1) * int(pc["por_edad"])
	s += (p["techs"] as Dictionary).size() * int(pc["por_investigacion"])
	# --- paso 7 --- La maravilla en pie suma puntos (docs/diseno/27, §4.4).
	var w := wonder_of(pid)
	if w != null and w.built:
		s += int(pc.get("por_maravilla", 0))
	return s


## Puntaje de un equipo: la suma de sus jugadores (también los derrotados).
func team_score(team: int) -> int:
	var s := 0
	for p in players:
		if team_of(p["id"]) == team:
			s += score(p["id"])
	return s


## Tiempo límite (opts.tiempo_limite_min): gana el equipo con más puntos, entre los que siguen
## en pie. Si los dos primeros empatan, no gana nadie (winner = -1).
func end_by_time() -> void:
	var best := -1
	var best_s := -1
	var tie := false
	var seen := {}
	for p in players:
		var tm := team_of(p["id"])
		if p["defeated"] or seen.has(tm):
			continue
		seen[tm] = true
		var ts := team_score(tm)
		if ts > best_s:
			best_s = ts
			best = tm
			tie = false
		elif ts == best_s:
			tie = true
	game_over = true
	end_reason = "tiempo"
	winner = -1
	winner_team = -1
	if not tie and best >= 0:
		winner_team = best
		for p in players:
			if team_of(p["id"]) == best and not p["defeated"]:
				winner = p["id"]
				break
	events.append({"t": "victory", "player": winner, "equipo": winner_team, "motivo": "tiempo"})


## El monte paga al rey (Ayutthaya, §3.5.6): parte de lo que se entrega a un elefante
## del rey entra además como riqueza, según el origen de la carga, con tope por
## minuto y por elefante. Si otro elefante propio está a menos de la separación,
## cobra solo el de id menor.
func _tribute(e: SimEntity, d: SimEntity) -> void:
	var tb: Dictionary = d.def["tributo"]
	var suai := 100 + mod(d.owner, "suai_pct") # --- paso 6, par 3 --- cerámica de Si Satchanalai
	var pct := int(tb.get(e.carry_src, 0)) * suai / 100
	if pct <= 0:
		return
	var sep := int(tb.get("separacion", 8)) * P
	for o in actives:
		if o != d and o.alive and o.owner == d.owner and o.type == d.type and o.id < d.id and Sim.dist(o.x, o.y, d.x, d.y) < sep:
			return
	var minute := tick / 600
	if d.trib_min != minute:
		d.trib_min = minute
		d.trib_used = 0
	var caps: Array = tb["tope_por_edad"]
	var cap := (int(caps[clampi(int(players[d.owner]["age"]) - 1, 0, caps.size() - 1)]) + mods.tribute_cap_bonus(d.owner)) * suai / 100
	var add := mini(e.carry * pct / 100, cap - d.trib_used)
	if add <= 0:
		return
	d.trib_used += add
	players[d.owner]["res"]["riqueza"] = int(players[d.owner]["res"]["riqueza"]) + add
	ledger(d.owner, "propio", "riqueza", add)


## --- paso 6 --- Por qué no se puede entrenar `type` en `b` además de la edad, la cola y el costo
## ("" si se puede): la canoa necesita agua cerca del edificio.
func train_block(_pid: int, b: SimEntity, type: String) -> String:
	var udef: Dictionary = dp(b.owner).unidades.get(type, {})
	if udef.get("navega", false) and water_tile_near(b, int(udef.get("agua_max", 5))).x < 0:
		return "Hace falta agua a %d casillas o menos" % int(udef.get("agua_max", 5))
	return ""


## --- paso 6 --- Costo de levantar `type` para `pid`: el de la tabla con los descuentos de las
## mejoras por tipo y recurso (óga de takuára: casas y almacenes con menos madera).
func build_cost(pid: int, type: String) -> Dictionary:
	var cost := dp(pid).cost_of(type, players[pid]["age"]).duplicate()
	for k in cost:
		var pct := mod(pid, "costo_b:%s:%s" % [type, k]) + mod(pid, "costo_b:%s:*" % type)
		if pct != 0:
			cost[k] = int(cost[k]) * (100 + pct) / 100
	return cost


## Costo de entrenar en un edificio: el de la tabla, menos el descuento de los gult
## en regimiento cercanos para los jinetes (Etiopía, §3.5.4).
func train_cost(pid: int, b: SimEntity, type: String) -> Dictionary:
	var cost := dp(pid).cost_of(type, players[pid]["age"]).duplicate()
	var udef: Dictionary = dp(pid).unidades.get(type, {})
	var own := mod(pid, "costo_u:" + type) # --- paso 6 --- kawellu: la gente a caballo cuesta menos
	if own != 0:
		for k in cost:
			cost[k] = int(cost[k]) * (100 + own) / 100
	if not udef.get("montado", false) or b == null:
		return cost
	var pct := 0
	for g in owned(pid):
		if g.alive and g.owner == pid and g.mode == "regimiento" and g.built and g.def.has("regimiento"):
			var rg: Dictionary = g.def["regimiento"]
			if Sim.dist(g.x, g.y, b.x, b.y) <= int(rg["radio"]):
				pct = mini(int(rg["tope_pct"]), pct + int(rg["descuento_pct"]))
	if pct > 0:
		for k in cost:
			cost[k] = int(cost[k]) * (100 - pct) / 100
	return cost


## Saca una unidad del juego sin que cuente como muerte (la cabeza que entra al corral).
func remove_quietly(e: SimEntity) -> void:
	if not e.alive:
		return
	e.alive = false
	_dirty = true
	events.append({"t": "absorbed", "id": e.id, "owner": e.owner})


## Orden "clic derecho sobre esto" para unidades sueltas (la usa el grupo al soltarse).
func order_target(pid: int, units: Array[SimEntity], target_id: int) -> void:
	_cmd_target(pid, units, target_id)


func order_move(e: SimEntity, x: int, y: int) -> void:
	_cmd_move(e.owner, [e] as Array[SimEntity], x, y, false)


## Recursos vivos a `r` casillas (Chebyshev) de la casilla dada, por celdas.
func resources_near(tx: int, ty: int, r: int) -> Array[SimEntity]:
	var out: Array[SimEntity] = []
	for cy in range((ty - r) / RC - 1, (ty + r) / RC + 2):
		for cx in range((tx - r) / RC - 1, (tx + r) / RC + 2):
			for t: SimEntity in _res_cells.get(cx * 1024 + cy, []):
				if t.alive and absi(t.tx - tx) <= r and absi(t.ty - ty) <= r:
					out.append(t)
	return out


## Lo que pide el próximo hito de un recurso propio (fama, mit'a) por encima del costo común.
func hito_extra_need(pid: int, key: String) -> int:
	var age := int(players[pid]["age"])
	var dd := dp(pid)
	if age > dd.hitos.size():
		return 0
	var need := 0
	for h: String in dd.hitos[age - 1]:
		need = maxi(need, int(dd.edificios.get(h, {}).get("costo_extra", {}).get(key, 0)))
	return need


## --- esport 1a --- ¿Puede tomar sitios sagrados? Desde reglas.sitios.captura_edad_min (la II).
func can_take_sites(pid: int) -> bool:
	return pid >= 0 and int(players[pid]["age"]) >= int(_opts.get("sitios_captura_edad_min", data.reglas["sitios"].get("captura_edad_min", 1)))


## Lo disputado: riqueza de lugares que se pelean (arcilla del centro, sitios,
## botín), con techo por edad en una ventana de N baldes de un minuto
## (docs/diseno/revision-economia/v3/04, §3.2). Devuelve cuánto entra todavía.
func disputed_room(pid: int) -> int:
	var cfg: Dictionary = data.reglas.get("disputado", {})
	if cfg.is_empty() or pid < 0:
		return 1 << 30
	var caps: Array = cfg["tope_por_min"]
	var cap := int(caps[clampi(int(players[pid]["age"]) - 1, 0, caps.size() - 1)]) * int(cfg["baldes"])
	var sum := 0
	for v in _disp_buckets(pid):
		sum += int(v)
	return maxi(0, cap - sum)


func disputed_add(pid: int, n: int) -> void:
	if n <= 0 or pid < 0:
		return
	var b := _disp_buckets(pid)
	var nb := b.size()
	b[(tick / 600) % nb] = int(b[(tick / 600) % nb]) + n


func _disp_buckets(pid: int) -> Array:
	var p := players[pid]
	var nb := int(data.reglas.get("disputado", {}).get("baldes", 5))
	var minute := tick / 600
	if (p["disp"] as Array).size() != nb:
		var arr := []
		arr.resize(nb)
		arr.fill(0)
		p["disp"] = arr
	while int(p["disp_min"]) < minute:
		p["disp_min"] = int(p["disp_min"]) + 1
		(p["disp"] as Array)[int(p["disp_min"]) % nb] = 0
	return p["disp"]


## Libro de ingresos por origen (stats, no estado): de dónde sale cada recurso.
## Lo usan las pruebas de la economía (docs/diseno/revision-economia/v3/04, §9).
func ledger(pid: int, origin: String, res: String, n: int) -> void:
	if pid < 0 or pid >= players.size() or n == 0:
		return
	var book: Dictionary = players[pid]["stats"].get_or_add("origen", {})
	var row: Dictionary = book.get_or_add(origin, {})
	row[res] = int(row.get(res, 0)) + n


## Recolección en casa (a 20 casillas de la base inicial) o en lo disputado.
func _gather_origin(e: SimEntity) -> String:
	var t: SimEntity = by_id.get(e.target)
	if t == null:
		return "recoleccion"
	if t.is_building():
		return "granja"
	if t.type == "riqueza" and t.is_resource():
		return "casa" if t.res_owner == e.owner else "disputado"
	if t.is_resource() and t.def.has("reabre"):
		return "propio" # yerbal: motor guaraní
	var b := bases[e.owner % bases.size()] + Vector2i(2, 2)
	return "disputado" if Sim.dist(t.x, t.y, b.x * P, b.y * P) > 20 * P else "casa"


# ---------------------------------------------------------------- Maravilla (paso 7)

## La maravilla de `pid` (en obra o terminada), o null: hay una por jugador (docs/diseno/27, §4.1).
func wonder_of(pid: int) -> SimEntity:
	for e in buildings_of(pid):
		if e.alive and e.owner == pid and e.is_building() and e.def.get("maravilla", false):
			return e
	return null


## ¿`pid` hizo el hito `type` (o lo tiene en pie, como en las misiones que lo dan hecho)?
func has_done_hito(pid: int, type: String) -> bool:
	if (players[pid].get("hitos_hechos", []) as Array).has(type):
		return true
	for e in buildings_of(pid):
		if e.alive and e.owner == pid and e.type == type and e.is_building() and e.built:
			return true
	return false


## Por qué `pid` no puede levantar `type` ("" si puede, salvo la edad y el costo): la maravilla
## es una por jugador, con la vía de los guaraníes (`requiere_hito`) y sin el Pacto de Cucaú
## (`impide_hito`); con Fasil Gəbbi en pie la corte etíope no se muda (`corte_fija`).
func build_block(pid: int, type: String) -> String:
	var def: Dictionary = dp(pid).edificios.get(type, {})
	if def.has("requiere_tec") and not players[pid]["techs"].has(def["requiere_tec"]): # --- paso 6 --- el hoyo con estacas
		return "Requiere %s" % dp(pid).tecnologias.get(def["requiere_tec"], {}).get("nombre", def["requiere_tec"])
	if def.has("funda_corte") and not mods.wonder_fx(pid, "corte_fija").is_empty():
		return "Con %s en pie la corte ya no se muda" % wonder_of(pid).def.get("nombre", "la maravilla")
	if not def.get("maravilla", false):
		return ""
	if wonder_of(pid) != null:
		return "Ya hay una maravilla"
	var req: String = def.get("requiere_hito", "")
	if req != "" and not has_done_hito(pid, req):
		return "Requiere el hito %s" % dp(pid).edificios.get(req, {}).get("nombre", req)
	var no: String = def.get("impide_hito", "")
	if no != "" and has_done_hito(pid, no):
		return "%s cerró este camino" % dp(pid).edificios.get(no, {}).get("nombre", no)
	return ""


## Cuenta de la maravilla (docs/diseno/27, §4.1 y §4.4; reglas.maravilla): corre mientras la
## maravilla terminada está en pie, y si cae se pierde. La sitiada (Palmares, C-97 a) no cae:
## su cuenta vuelve a empezar mientras haya tropa enemiga adentro. Sin la victoria por maravilla
## (opción de partida) y en las misiones, no hay cuenta.
func _wonders() -> void:
	var cfg: Dictionary = data.reglas.get("maravilla", {})
	var off: bool = cfg.is_empty() or _opts.get("maravilla_sin_victoria", false) or scenario != null
	for p in players:
		var pid: int = p["id"]
		var w: SimEntity = null if p["defeated"] or off else wonder_of(pid)
		if w == null or not w.built:
			if int(p.get("maravilla_ms", 0)) != 0:
				p["maravilla_ms"] = 0
			continue
		if w.def.has("sitiada") and _enemy_troops_near(w, int(w.def["sitiada"].get("radio", 3))):
			if int(p.get("maravilla_ms", 0)) > 0:
				events.append({"t": "maravilla_sitiada", "id": w.id, "player": pid})
			p["maravilla_ms"] = 0
			continue
		p["maravilla_ms"] = int(p.get("maravilla_ms", 0)) + 1000
		if int(p["maravilla_ms"]) >= int(cfg["victoria_ms"]) and not game_over:
			win(pid, "maravilla")


## Segundos que le faltan a la cuenta de la maravilla de `pid`; -1 si no corre.
func wonder_left_s(pid: int) -> int:
	var ms := int(players[pid].get("maravilla_ms", 0))
	if ms <= 0:
		return -1
	return maxi(0, (int(data.reglas["maravilla"]["victoria_ms"]) - ms) / 1000)


## ¿Hay tropa enemiga de `b.owner` a `r` casillas o menos del borde de `b`?
func _enemy_troops_near(b: SimEntity, r: int) -> bool:
	for u in military():
		if u.alive and u.is_unit() and u.inside < 0 and u.owner >= 0 and u.is_military() and enemies(b.owner, u.owner):
			var tx := u.x / P
			var ty := u.y / P
			if tx >= b.tx - r and tx < b.tx + b.w + r and ty >= b.ty - r and ty < b.ty + b.h + r:
				return true
	return false


## Victoria directa (sitios sagrados): todos los demás pierden.
func win(pid: int, reason: String = "sitios") -> void:
	if end_reason == "":
		end_reason = reason
	for p in players:
		if enemies(pid, p["id"]):
			_defeat(p["id"])


func _defeat(pid: int) -> void:
	if players[pid]["defeated"]:
		return
	players[pid]["defeated"] = true
	events.append({"t": "defeat", "player": pid})
	var left := []
	var teams := {}
	for p in players:
		if not p["defeated"]:
			left.append(p["id"])
			teams[team_of(p["id"])] = true
	# Termina cuando queda un solo equipo en pie; gana el primer jugador de ese equipo.
	if teams.size() <= 1 and not game_over:
		game_over = true
		if end_reason == "":
			end_reason = "conquista"
		winner = left[0] if left.size() >= 1 else -1
		winner_team = team_of(winner) if winner >= 0 else -1
		events.append({"t": "victory", "player": winner, "equipo": winner_team, "motivo": end_reason})


# ---------------------------------------------------------------- Creación

func _new_entity(cat: int, type: String, owner: int, def: Dictionary) -> SimEntity:
	var e := SimEntity.new()
	if id_aparte > 0:
		e.id = id_aparte
		id_aparte += 1
	else:
		e.id = next_id
		next_id += 1
	e.cat = cat
	e.type = type
	e.owner = owner
	e.def = def
	entities.append(e)
	if cat != SimEntity.Cat.RESOURCE:
		actives.append(e)
		_own_list(_owned, owner).append(e)
		if cat == SimEntity.Cat.BUILDING:
			_own_list(_owned_b, owner).append(e)
			_buildings.append(e)
			if def.get("sagrado", false):
				_sacred.append(e)
		elif cat == SimEntity.Cat.UNIT:
			_units.append(e)
			if SimEntity.MILITARY_FNS.has(String(def.get("funcion", ""))):
				_military.append(e)
			if SimEntity.MILITARY_FNS.has(String(def.get("funcion", ""))) or String(def.get("funcion", "")) == "explorador":
				_own_list(_fighters, owner).append(e)
	by_id[e.id] = e
	return e


## Rendimiento (proceso/32-ronda-8/04): lo activo de cada dueño, en el mismo orden que
## `actives` (por id), para no recorrer las ~2000 entidades del mapa buscando las de uno.
## Se agrega en `_new_entity` y se limpia en `_cleanup`, igual que `actives`; el dueño y la
## categoría no cambian nunca. Recorrer `owned(pid)` es recorrer `actives` filtrado por dueño.
var _owned := {} # dueño -> Array[SimEntity] (unidades y edificios)
var _owned_b := {} # dueño -> Array[SimEntity] (solo edificios)
var _units: Array[SimEntity] = [] # todas las unidades, en orden de id
func all_units() -> Array[SimEntity]:
	return _units


var _buildings: Array[SimEntity] = [] # todos los edificios, en orden de id
func all_buildings() -> Array[SimEntity]:
	return _buildings


var _military: Array[SimEntity] = [] # unidades militares (is_military), en orden de id
func military() -> Array[SimEntity]:
	return _military


var _no_ent: Array[SimEntity] = [] # vacía: no se le agrega nada
func owned(pid: int) -> Array[SimEntity]:
	return _owned.get(pid, _no_ent)


func buildings_of(pid: int) -> Array[SimEntity]:
	return _owned_b.get(pid, _no_ent)


var _sacred: Array[SimEntity] = [] # sitios sagrados, en orden de id
func sacred_sites() -> Array[SimEntity]:
	return _sacred


## Militares y exploradores de un dueño (lo que la IA cuenta como amenaza), en orden de id.
var _fighters := {} # dueño -> Array[SimEntity]
func fighters_of(pid: int) -> Array[SimEntity]:
	return _fighters.get(pid, _no_ent)


static func _own_list(d: Dictionary, pid: int) -> Array[SimEntity]:
	if not d.has(pid):
		var a: Array[SimEntity] = []
		d[pid] = a
	return d[pid]


func spawn_unit(type: String, owner: int, x: int, y: int) -> SimEntity:
	var def: Dictionary = dp(owner).unidades[type]
	var e := _new_entity(SimEntity.Cat.UNIT, type, owner, def)
	e.x = x
	e.y = y
	e.fn = def["funcion"]
	e.radius = def["radio"]
	_apply_stats(e)
	e.hp = e.hp_max
	e.goal_x = x
	e.goal_y = y
	return e


func spawn_building(type: String, owner: int, tx: int, ty: int, built: bool) -> SimEntity:
	var def: Dictionary = dp(owner).edificios[type]
	var e := _new_entity(SimEntity.Cat.BUILDING, type, owner, def)
	e.tx = tx
	e.ty = ty
	e.w = def["tam"][0]
	e.h = def["tam"][1]
	e.x = tx * P + e.w * P / 2
	e.y = ty * P + e.h * P / 2
	e.fn = "edificio"
	_apply_stats(e)
	e.built = built
	e.hp = e.hp_max if built else 1
	e.build_time = dp(owner).build_time_of(type, players[owner]["age"]) if owner >= 0 else 0
	if owner < 0 and not def.get("hostil", false):
		e.hp = 1
		e.hp_max = 1
	map.mark(tx, ty, e.w, e.h, e.id, not def.get("transitable", false), owner if def.get("puerta", false) else -1)
	_refresh_corridor(e)
	if def.has("cantidad"):
		e.amount = def["cantidad"]
		if owner >= 0 and mod(owner, "cant_pct:" + type) != 0: # --- paso 6 --- kokue: la roza dura más
			e.amount = e.amount * (100 + mod(owner, "cant_pct:" + type)) / 100
	mods.on_building_placed(e)
	return e


func spawn_resource(type: String, tx: int, ty: int) -> SimEntity:
	var def: Dictionary = data.recursos[type]
	var e := _new_entity(SimEntity.Cat.RESOURCE, type, -1, def)
	e.tx = tx
	e.ty = ty
	e.w = def["tam"][0]
	e.h = def["tam"][1]
	e.x = tx * P + e.w * P / 2
	e.y = ty * P + e.h * P / 2
	e.res_kind = def["recurso"]
	e.amount = def["cantidad"]
	e.hp = 1
	e.hp_max = 1
	if def.get("reclamable", false):
		_wild.append(e)
	if _in_step:
		events.append({"t": "recurso_nuevo", "id": e.id}) # la vista crea los recursos al empezar; este aparece después
	map.mark(tx, ty, e.w, e.h, e.id, true)
	var k := (tx / RC) * 1024 + ty / RC
	if not _res_cells.has(k):
		_res_cells[k] = []
	_res_cells[k].append(e)
	return e


# ---------------------------------------------------------------- Mapa

## Mapa con simetría puntual para dos jugadores (docs/05, justo para ambos).
func _generate_map() -> void:
	var n := map.n
	if n_layout():
		_generate_map_n()
		return
	var b0 := Vector2i(22, 22)
	bases = [b0, Vector2i(n - 4 - b0.x, n - 4 - b0.y), Vector2i(b0.x, n - 4 - b0.y), Vector2i(n - 4 - b0.x, b0.y)]
	_generate_terrain()
	for pid in players.size():
		var base := bases[pid % 4]
		var dd := dp(pid)
		var start: String = dd.civ.get("inicio_edificio", "centro")
		var sb := spawn_building(start, pid, base.x, base.y, true)
		sb.capital = true
		var count: int = dd.civ.get("aldeanos_iniciales", data.reglas["aldeanos_iniciales"])
		for i in count:
			var ux := (base.x + i % 3 + (5 if pid == 0 else -2)) * P + P / 2
			var uy := (base.y + i / 3 + (1 if pid == 0 else 1)) * P + P / 2
			spawn_unit("aldeano", pid, ux, uy)
		for i in int(data.reglas["exploradores_iniciales"]):
			var sx := (base.x + (5 if pid == 0 else -2)) * P + P / 2
			var sy := (base.y + 4 + i) * P + P / 2
			spawn_unit(dd.civ.get("explorador", "explorador"), pid, sx, sy)

	_spawn_fort_walls()
	# Recursos semilla de cada civ (yerbal viejo guaraní, §3.5.3), cerca de su base.
	for pid in players.size():
		for sem: Dictionary in dp(pid).civ.get("recursos_semilla", []):
			var base := bases[pid % 4]
			var tam: Array = data.recursos[sem["tipo"]]["tam"]
			var dirx := signi(map.n / 2 - base.x)
			var diry := signi(map.n / 2 - base.y)
			var spot := Vector2i(base.x + 2 - dirx * 8, base.y + 2 + diry * 5)
			for r in 6:
				var cand := spot + Vector2i(r * dirx, -r * diry)
				if map.is_free_rect(cand.x - 1, cand.y - 1, tam[0] + 2, tam[1] + 2):
					var y := spawn_resource(sem["tipo"], cand.x, cand.y)
					y.amount = int(sem.get("cantidad", y.amount))
					y.res_owner = pid
					break

	var c0 := Vector2i(b0.x + 2, b0.y + 2) # centro de la base 0
	var dirs: Array[Vector2i] = [Vector2i(1, 0), Vector2i(1, 1), Vector2i(0, 1), Vector2i(-1, 1), Vector2i(-1, 0), Vector2i(-1, -1), Vector2i(0, -1), Vector2i(1, -1)]
	# Barajar direcciones con el generador de la partida.
	for i in range(dirs.size() - 1, 0, -1):
		var j := rng.range_i(0, i)
		var tmp := dirs[i]
		dirs[i] = dirs[j]
		dirs[j] = tmp
	# Preferir direcciones hacia el centro del mapa para los recursos clave.
	var inward: Array[Vector2i] = []
	var outward: Array[Vector2i] = []
	for d in dirs:
		if d.x + d.y >= 0:
			inward.append(d)
		else:
			outward.append(d)
	var picks: Array[Vector2i] = inward + outward

	_cluster_sym("arbusto", c0 + _scale_dir(picks[0], 7), int(data.reglas["animales"]["arbustos_base"]))
	_blob_sym(c0 + _scale_dir(picks[1], 13), 4, 85)
	# Piedra de casa: dos vetas y una más a media distancia, del mismo lado (proceso/32-ronda-8/02).
	# La segunda iba a (2, -1) de la primera y casi nunca entraba: el 1 contra 1 tenía una sola.
	var rm: Dictionary = data.reglas.get("recursos_mapa", {})
	_res_sym_near("roca", c0 + _scale_dir(picks[2], 10), _min_amt("roca", int(rm.get("roca_cerca", -1))), false)
	_res_sym_near("roca", c0 + _scale_dir(picks[2], 10) + Vector2i(3, -1), _min_amt("roca", int(rm.get("roca_cerca", -1))), false)
	_res_sym_near("roca", c0 + _scale_dir(picks[2], int(rm.get("roca_media_dist", 22))), _min_amt("roca", int(rm.get("roca_media", -1))), false)
	# Arcilla de casa (2 pozos) y de flanco: del jugador (docs/diseno/revision-economia/v3/04, §2.2).
	var cl: Dictionary = data.reglas.get("arcilla", {})
	_res_sym("riqueza", c0 + _scale_dir(picks[3], 10), _min_amt("riqueza", int(cl.get("base", -1))), true)
	_res_sym("riqueza", c0 + _scale_dir(picks[3], 10) + Vector2i(-1, 2), _min_amt("riqueza", int(cl.get("base", -1))), true)
	_blob_sym(c0 + _scale_dir(picks[4], 15), 3, 80)
	# Animales (como AoE4, proceso/23, C-32): el kit de la base 0 y su espejo para la 1,
	# cada uno con las cantidades de su civ.
	if players.size() >= 2 and not _opts.get("sin_animales", false):
		# Sueltos a unas 15 casillas: más cerca los reclamaban los aldeanos al pasar y el explorador
		# no tenía trabajo (jugadores de prueba, ronda 2).
		var spots := [c0 + _scale_dir(picks[5], 5), c0 + _scale_dir(picks[6], 15), c0 + _scale_dir(picks[7], 19), c0 + _scale_dir(picks[1], 22)]
		for pid in 2:
			var sp: Array = spots if pid == 0 else spots.map(func(v: Vector2i) -> Vector2i: return _mirror(v, 1, 1))
			_animal_kit(pid, sp)
		var an: Dictionary = data.reglas["animales"]
		_cluster_sym("rebano_salvaje", Vector2i(n / 2 + n / 6, n / 2 - n / 6), int(an["sueltos_entre_bases"]))

	# Bases extra (campañas con tres o cuatro jugadores): recursos propios sin simetría.
	for extra in range(2, mini(players.size(), 4)):
		var ce := bases[extra] + Vector2i(2, 2)
		var dirx := Vector2i(signi(n / 2 - ce.x), signi(n / 2 - ce.y))
		_cluster_sym("arbusto", ce + Vector2i(dirx.x * 7, 0), 6)
		_res_sym("roca", ce + Vector2i(0, dirx.y * 9))
		_res_sym("riqueza", ce + Vector2i(dirx.x * 9, dirx.y * 5))
		_blob_sym(ce + Vector2i(dirx.x * 4, dirx.y * 13), 3, 80)

	# Sitios sagrados: uno al centro y pares simétricos (docs/05, "Victoria").
	if players.size() == 2 and not _opts.get("sin_sitios", false):
		var sites: int = data.reglas["sitios"]["cantidad"]
		var spots: Array[Vector2i] = [Vector2i(n / 2 - 1, n / 2 - 1), Vector2i(n / 2 - 18, n / 2 + 14), Vector2i(n / 2 + 16, n / 2 - 16)]
		for i in mini(sites, spots.size()):
			var t := map.nearest_free(spots[i].x, spots[i].y, 8)
			if t.x >= 0 and map.is_free_rect(t.x, t.y, 2, 2):
				spawn_building("sitio_sagrado", -1, t.x, t.y, true)

	# Ingenios neutrales hostiles (§3.2): uno por jugador, en la esquina sin base de su
	# lado, espejados. Solo en escaramuza (las campañas no tienen sitios ni ingenios).
	if players.size() == 2 and not _opts.get("sin_sitios", false) and data.edificios.has("ingenio"):
		var ing: Dictionary = data.reglas.get("ingenios", {})
		var dist := int(ing.get("distancia_base", 34))
		var spot := map.nearest_free(c0.x + dist, c0.y - dist / 3, 10)
		for r in 10:
			var cand := Vector2i(spot.x + r, spot.y)
			var mc := _mirror(cand, 3, 3)
			if map.in_bounds(cand.x, cand.y) and map.is_free_rect(cand.x - 1, cand.y - 1, 5, 5) and map.is_free_rect(mc.x - 1, mc.y - 1, 5, 5) and map.is_flat(cand.x, cand.y, 3, 3) and map.is_flat(mc.x, mc.y, 3, 3):
				spawn_building("ingenio", -1, cand.x, cand.y, true)
				spawn_building("ingenio", -1, mc.x, mc.y, true)
				break

	# Recursos disputados en el centro.
	var mid := n / 2
	# Arcilla del centro (disputada) y de flanco (propia).
	_res_sym_near("riqueza", Vector2i(mid - 9, mid + 5), _min_amt("riqueza", int(cl.get("centro_por_jugador", -1))), false)
	_res_sym("riqueza", c0 + _scale_dir(picks[5], int(cl.get("flanco_dist", 18))), _min_amt("riqueza", int(cl.get("flanco", -1))), true)
	# Lejos y disputado: escala con las casillas por jugador (proceso/32-ronda-8/02).
	_res_sym_near("roca", Vector2i(mid + 8, mid - 16), _far_amt("roca", "roca_lejos"), false)
	_res_sym_near("riqueza", Vector2i(mid + 14, mid + 6), _far_amt("riqueza", "riqueza_lejos"), false)
	_cluster_sym("arbusto", Vector2i(mid - 18, mid + 2), 6)

	# Bosques.
	var tries := 0
	var made := 0
	var td := terrain_def()
	var forests := int(td.get("bosques", 13))
	while made < forests and tries < 300:
		tries += 1
		var c := Vector2i(rng.range_i(5, n - 6), rng.range_i(5, n - 6))
		if _near_base(c, 17) or absi(c.x - c.y) < 6 and absi(c.x + c.y - n) < 20 or comercio.near_neutral(c, 11):
			continue
		_blob_sym(c, rng.range_i(3, 6), 78)
		made += 1
	# Matorral suelto en mapas secos.
	for k in int(td.get("arbustos_extra", 0)):
		var c := Vector2i(rng.range_i(8, n - 9), rng.range_i(8, n - 9))
		if not _near_base(c, 16):
			_cluster_sym("arbusto", c, 5)
	# Bordes boscosos.
	for i in n:
		for depth in int(td.get("borde", 3)):
			var chance := 70 - depth * 25
			if rng.range_i(0, 99) < chance:
				_tree_sym(Vector2i(i, depth))
			if rng.range_i(0, 99) < chance:
				_tree_sym(Vector2i(depth, i))
	# --- comercio --- dos mercados neutrales sobre la mediatriz (proceso/33-comercio, §1). Al final,
	# talando alrededor: los bosques y el resto del mapa quedan como sin ellos (la primera victoria
	# del principiante bajaba de 2 de 3 a 0 de 3 con los bosques corridos).
	if players.size() == 2 and not _opts.get("sin_sitios", false) and not _opts.get("sin_mercados", false):
		comercio.place_1v1()


## ¿Mapa para muchos jugadores? Escaramuza de 3 o más (las campañas usan sus bases fijas).
func n_layout() -> bool:
	return players.size() > 2 and not _opts.get("sin_sitios", false)


## Mapa para N jugadores (docs/11, paso 2): bases en círculo, todas a la misma
## distancia del centro, y el mismo juego de recursos en coordenadas locales de cada
## base (adelante = hacia el centro). No hay simetría exacta con 6 u 8 lados, pero
## cada base recibe lo mismo; tests/equidad.gd lo mide.
## Paisaje propio de una civ junto a su base (proceso/24, paso 3): el khlong de Ayutthaya, un
## canal de agua baja (se camina, no se edifica) para que el arrozal tenga su agua. Antes ningún
## arrozal de la IA tenía el bono: casi ningún mapa trae agua a menos de 30 casillas de la base.
## Con relieve real (misiones) manda la geografía del lugar.
func _civ_landscape() -> void:
	if _opts.has("relieve"):
		return
	for pid in mini(players.size(), bases.size()):
		var dd := dp(pid)
		if not dd.has_mod("khlong"):
			continue
		var cfg: Dictionary = dd.mod("khlong")
		var c := bases[pid] + Vector2i(2, 2)
		var dist := int(cfg["distancia"])
		var long := int(cfg["largo"])
		var wide := int(cfg["ancho"])
		# Ocho rumbos en orden fijo; el primero donde el canal entra entero en lugar libre.
		for d in [Vector2i(-1, 0), Vector2i(0, -1), Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, -1), Vector2i(1, -1), Vector2i(-1, 1), Vector2i(1, 1)]:
			var mid: Vector2i = c + d * dist
			var along := Vector2i(-d.y, d.x) if d.x == 0 or d.y == 0 else Vector2i(d.x, -d.y)
			var tiles: Array[Vector2i] = []
			for i in range(-long / 2, long - long / 2):
				for j in wide:
					var t: Vector2i = mid + along * i + d * j
					tiles.append(t)
					if d.x != 0 and d.y != 0:
						tiles.append(t + Vector2i(d.x, 0)) # en diagonal, sin huecos
			var ok := true
			for t in tiles:
				if not map.in_bounds(t.x, t.y) or map.occupant(t.x, t.y) != -1 or map.is_water(t.x, t.y) or map.is_rock(t.x, t.y):
					ok = false
					break
			if ok:
				for t in tiles:
					map.set_water(t.x, t.y, 2)
				break


func _generate_map_n() -> void:
	var n := map.n
	var np := players.size()
	var tbl: Array = data.reglas["bases_circulo"][str(np)]
	var r := n / 2 - 24
	bases = []
	_base_dirs = []
	for i in np:
		var d: Array = tbl[i]
		var c := Vector2i(n / 2 + int(d[0]) * r / 1000, n / 2 + int(d[1]) * r / 1000)
		bases.append(c - Vector2i(2, 2))
		_base_dirs.append(Vector2i(-int(d[0]), -int(d[1]))) # hacia el centro, en milésimas
	# El terreno se arma con las bases en el orden del círculo (ríos, islas y cercos
	# suponen que la 0 y la 1 son vecinas); después cada jugador toma su lugar.
	_generate_terrain()
	var ring_bases := bases.duplicate()
	var slot := _team_slots()
	for pid in np:
		bases[pid] = ring_bases[slot[pid]]
		_base_dirs[pid] = Vector2i(-int(tbl[slot[pid]][0]), -int(tbl[slot[pid]][1]))
	for g in _fort_gaps:
		g[0] = slot.find(int(g[0]))
	for pid in np:
		var base := bases[pid]
		var dd := dp(pid)
		var sb := spawn_building(dd.civ.get("inicio_edificio", "centro"), pid, base.x, base.y, true)
		sb.capital = true
		var count: int = dd.civ.get("aldeanos_iniciales", data.reglas["aldeanos_iniciales"])
		for i in count:
			var off := _local(pid, 5 + i / 3, i % 3 - 1)
			spawn_unit("aldeano", pid, (base.x + 2 + off.x) * P + P / 2, (base.y + 2 + off.y) * P + P / 2)
		for i in int(data.reglas["exploradores_iniciales"]):
			var off := _local(pid, 4, 3 + i)
			spawn_unit(dd.civ.get("explorador", "explorador"), pid, (base.x + 2 + off.x) * P + P / 2, (base.y + 2 + off.y) * P + P / 2)
	_spawn_fort_walls()
	var cl: Dictionary = data.reglas.get("arcilla", {})
	# El mismo juego de recursos para cada base: (adelante, costado) en casillas.
	for pid in np:
		var c := bases[pid] + Vector2i(2, 2)
		_cluster_at("arbusto", c + _local(pid, 7, -2), int(data.reglas["animales"]["arbustos_base"]))
		if not _opts.get("sin_animales", false):
			_animal_kit(pid, [c + _local(pid, 4, 4), c + _local(pid, 14, 6), c + _local(pid, 18, -6), c + _local(pid, 20, 8)])
		_blob_fixed(c + _local(pid, -3, 13), 4)
		_blob_fixed(c + _local(pid, -3, -13), 3)
		var rm: Dictionary = data.reglas.get("recursos_mapa", {})
		_res_at("roca", c + _local(pid, 1, -10), _min_amt("roca", int(rm.get("roca_cerca", -1))), -1)
		_res_at("roca", c + _local(pid, 3, -11), _min_amt("roca", int(rm.get("roca_cerca", -1))), -1)
		# Veta de media distancia, atrás y del lado de la piedra (proceso/32-ronda-8/02).
		var md := int(rm.get("roca_media_dist", 22))
		_res_at("roca", c + _local(pid, -md * 2 / 5, -md * 9 / 10), _min_amt("roca", int(rm.get("roca_media", -1))), -1)
		_res_at("riqueza", c + _local(pid, 2, 10), _min_amt("riqueza", int(cl.get("base", 900))), pid)
		_res_at("riqueza", c + _local(pid, 4, 11), _min_amt("riqueza", int(cl.get("base", 900))), pid)
		_res_at("riqueza", c + _local(pid, 11, -15), _min_amt("riqueza", int(cl.get("flanco", 1500))), pid)
		if data.edificios.has("ingenio"):
			var ig := c + _local(pid, 30, 14)
			var t := map.nearest_free(ig.x, ig.y, 8)
			if t.x >= 0 and map.is_free_rect(t.x - 1, t.y - 1, 5, 5) and map.is_flat(t.x, t.y, 3, 3):
				spawn_building("ingenio", -1, t.x, t.y, true)
	# Sitios sagrados: uno al centro y uno entre cada par de bases vecinas (en el círculo).
	var spots: Array[Vector2i] = [Vector2i(n / 2 - 1, n / 2 - 1)]
	for i in np:
		var a: Vector2i = ring_bases[i] + Vector2i(2, 2)
		var b: Vector2i = ring_bases[(i + 1) % np] + Vector2i(2, 2)
		var mid := (a + b) / 2
		spots.append(mid + (Vector2i(n / 2, n / 2) - mid) / 3)
	# Si el lugar cae en el agua o está ocupado, se acerca al centro hasta que entre: antes se
	# perdía en silencio (islas quedaba con 1 sitio; jugadores de prueba, proceso/22).
	var mid := Vector2i(n / 2, n / 2)
	for sp in spots:
		var placed := false
		for k in 9:
			var c: Vector2i = sp + (mid - sp) * k / 8
			# El del centro no se corre: fuera del centro quedaría más cerca de alguien. Si el
			# centro es un lago, ese sitio no va (y los demás siguen siendo simétricos).
			for rr in range(0, 2 if sp == mid else 6):
				for dy in range(-rr, rr + 1):
					for dx in range(-rr, rr + 1):
						if placed or maxi(absi(dx), absi(dy)) != rr:
							continue
						var t := c + Vector2i(dx, dy)
						if map.in_bounds(t.x, t.y) and map.is_free_rect(t.x - 1, t.y - 1, 4, 4) and not map.is_water(t.x, t.y) and not map.is_water(t.x + 1, t.y + 1):
							spawn_building("sitio_sagrado", -1, t.x, t.y, true)
							placed = true
			if placed:
				break
	# Arcilla del centro: 1000 por jugador, en anillo.
	for i in np:
		var d: Vector2i = _base_dirs[i]
		_res_at("riqueza", Vector2i(n / 2, n / 2) - Vector2i(d.x * 9 / 1000, d.y * 9 / 1000), _min_amt("riqueza", int(cl.get("centro_por_jugador", 1000))), -1)
	# Lejos y disputado (proceso/32-ronda-8/02): entre cada par de bases vecinas, una veta de
	# piedra un poco hacia afuera y una de riqueza un poco hacia el centro (el sitio queda a 1/3).
	# Cada par la comparte: por jugador toca lo de una veta de cada una; escala con las casillas.
	for i in np:
		var a: Vector2i = ring_bases[i] + Vector2i(2, 2)
		var b: Vector2i = ring_bases[(i + 1) % np] + Vector2i(2, 2)
		var mb := (a + b) / 2
		_res_at("roca", mb - (mid - mb) / 8, _far_amt("roca", "roca_lejos"), -1)
		_res_at("riqueza", mb + (mid - mb) / 6, _far_amt("riqueza", "riqueza_lejos"), -1)
	# --- comercio --- mercados neutrales entre equipos o entre bases vecinas (proceso/33, §1),
	# antes de los bosques: los bosques no se les ponen encima.
	if not _opts.get("sin_mercados", false):
		comercio.place_n(ring_bases, slot)
	# Bosques y bordes.
	var made := 0
	var tries := 0
	var forests := int(terrain_def().get("bosques", 13)) * np / 2
	while made < forests and tries < forests * 25:
		tries += 1
		var fc := Vector2i(rng.range_i(5, n - 6), rng.range_i(5, n - 6))
		if _near_base(fc, 27) or absi(fc.x - n / 2) + absi(fc.y - n / 2) < 14 or comercio.near_neutral(fc, 11):
			continue
		_blob_at(fc, rng.range_i(3, 6), 78)
		made += 1
	for i in n:
		for depth in int(terrain_def().get("borde", 3)):
			var chance := 70 - depth * 25
			for t in [Vector2i(i, depth), Vector2i(depth, i), Vector2i(i, n - 1 - depth), Vector2i(n - 1 - depth, i)]:
				if rng.range_i(0, 99) < chance:
					_tree_at(t)


## Lugar en el círculo de cada jugador (opts.ubicacion_equipos, proceso/24, paso 4b):
## - "juntos": los de un mismo equipo, vecinos (por equipo en orden de aparición);
## - "mezclados": un lugar de cada equipo por vuelta, así nadie tiene al aliado al lado;
## - sin la opción, el orden de los jugadores (lo de siempre: tests y repeticiones viejas).
## Todos contra todos queda igual en los tres casos.
func _team_slots() -> Array:
	var np := players.size()
	var order: Array = []
	var groups: Array = [] # jugadores por equipo, en orden de aparición
	var gidx := {}
	for pid in np:
		var tm := team_of(pid)
		if not gidx.has(tm):
			gidx[tm] = groups.size()
			groups.append([])
		groups[gidx[tm]].append(pid)
	match str(_opts.get("ubicacion_equipos", "")):
		"juntos":
			for g in groups:
				order.append_array(g)
		"mezclados":
			var k := 0
			while order.size() < np:
				for g in groups:
					if k < (g as Array).size():
						order.append(g[k])
				k += 1
		_:
			order = range(np)
	var slot: Array = []
	slot.resize(np)
	for i in np:
		slot[order[i]] = i
	return slot


## Desplazamiento local de una base: `fwd` casillas hacia el centro y `side` de costado.
func _local(pid: int, fwd: int, side: int) -> Vector2i:
	var f: Vector2i = _base_dirs[pid]
	var sd := Vector2i(-f.y, f.x)
	return Vector2i((f.x * fwd + sd.x * side) / 1000, (f.y * fwd + sd.y * side) / 1000)


## Copias de una casilla, una por base: se mide adelante y de costado desde la
## base 0 y se repite desde cada base. La primera es la casilla misma.
func _sym_points(t: Vector2i) -> Array[Vector2i]:
	if not n_layout():
		return [t, _mirror(t, 1, 1)]
	var c0 := bases[0] + Vector2i(2, 2)
	var f: Vector2i = _base_dirs[0]
	var d := t - c0
	var fwd := _div_near(d.x * f.x + d.y * f.y, 1000)
	var side := _div_near(-d.x * f.y + d.y * f.x, 1000)
	var out: Array[Vector2i] = [t]
	for i in range(1, bases.size()):
		out.append(bases[i] + Vector2i(2, 2) + _local_near(i, fwd, side))
	return out


## La inversa: a qué casilla del sector de la base 0 corresponde `t` (la base
## de la que `t` está más cerca, girada).
func _to_frame0(t: Vector2i) -> Vector2i:
	var best := 0
	var bd := 1 << 30
	for i in bases.size():
		var c := bases[i] + Vector2i(2, 2)
		var dd := (t.x - c.x) * (t.x - c.x) + (t.y - c.y) * (t.y - c.y)
		if dd < bd:
			bd = dd
			best = i
	if best == 0:
		return t
	var c := bases[best] + Vector2i(2, 2)
	var f: Vector2i = _base_dirs[best]
	var d := t - c
	var fwd := _div_near(d.x * f.x + d.y * f.y, 1000)
	var side := _div_near(-d.x * f.y + d.y * f.x, 1000)
	return bases[0] + Vector2i(2, 2) + _local_near(0, fwd, side)


## Como `_local`, pero redondeando al más cercano (para copiar formas sin correrlas).
func _local_near(pid: int, fwd: int, side: int) -> Vector2i:
	var f: Vector2i = _base_dirs[pid]
	return Vector2i(_div_near(f.x * fwd - f.y * side, 1000), _div_near(f.y * fwd + f.x * side, 1000))


static func _div_near(a: int, b: int) -> int:
	return (a + b / 2) / b if a >= 0 else -((-a + b / 2) / b)


## Pincel de río sin espejo (mapas para N: el giro ya lo puso en cada sector).
func _paint_brush(p: Vector2i, width: int, ford: bool) -> void:
	var n := map.n
	for dy in range(-width, width + 1):
		for dx in range(-width, width + 1):
			if absi(dx) + absi(dy) > width + 1:
				continue
			var t := p + Vector2i(dx, dy)
			if not map.in_bounds(t.x, t.y) or _near_base(t, 12):
				continue
			var cur := map.water[t.y * n + t.x]
			if cur == 2 or (cur == 1 and not ford):
				continue
			map.set_water(t.x, t.y, 2 if ford else 1)
	for dy in range(-width - 4, width + 5):
		for dx in range(-width - 4, width + 5):
			var t := p + Vector2i(dx, dy)
			if map.in_bounds(t.x, t.y):
				var cap := 0 if maxi(absi(dx), absi(dy)) <= width + 2 else 1
				map.height[t.y * n + t.x] = mini(map.height[t.y * n + t.x], cap)


## Fortines para N: el mismo cerco en el marco de cada base (adelante hacia el
## centro), con salida adelante, atrás y a los costados.
func _fort_rings_n(fd: Dictionary) -> void:
	var r := int(fd.get("radio", 18))
	var thick := int(fd.get("grosor", 3))
	var half := int(fd.get("hueco", 5)) / 2
	var sd := rng.range_i(1, 1 << 20)
	var mid := r + thick / 2
	var e := r + thick + 4
	for pid in bases.size():
		var c := bases[pid] + Vector2i(2, 2)
		var f: Vector2i = _base_dirs[pid]
		var gaps := {}
		for ty in range(c.y - e, c.y + e + 1):
			for tx in range(c.x - e, c.x + e + 1):
				if not map.in_bounds(tx, ty):
					continue
				var dx := tx - c.x
				var dy := ty - c.y
				var fwd := _div_near(dx * f.x + dy * f.y, 1000)
				var side := _div_near(-dx * f.y + dy * f.x, 1000)
				var along := maxi(absi(fwd), absi(side))
				var across := absi(side) if absi(fwd) >= absi(side) else absi(fwd)
				var key := Vector2i(signi(fwd), 0) if absi(fwd) >= absi(side) else Vector2i(0, signi(side))
				if across <= half:
					# Salida: la empalizada llena todo el grosor del cerco; con el giro, una
					# franja más fina deja huecos en diagonal en algunas bases y en otras no.
					if along >= r and along < r + thick:
						if not gaps.has(key):
							gaps[key] = []
						gaps[key].append(Vector3i(tx, ty, across))
					continue
				var wob := 0 if across <= half + 2 else (_vnoise(fwd + 500, side + 500, 6, sd) - 500) / 250
				var cheb := along + wob
				if cheb >= r and cheb < r + thick:
					map.set_rock(tx, ty)
		for key in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			if not gaps.has(key):
				continue
			# La salida llena todo el grosor del cerco: la puerta también, como una columna de
			# 3 de ancho en el medio. Con una sola casilla de puerta, el dueño no podía cruzar las
			# empalizadas de adelante y de atrás y quedaba encerrado (jugadores de prueba, proceso/22).
			var tiles: Array[Vector2i] = []
			var gates: Array[Vector2i] = []
			for v: Vector3i in gaps[key]:
				tiles.append(Vector2i(v.x, v.y))
				if v.z <= 1:
					gates.append(Vector2i(v.x, v.y))
			_fort_gaps.append([pid, tiles, gates])


## Islas para N: cada base en su isla, una al centro y una entre cada par de
## vecinas, unidas por bajíos. Se marca la tierra con todas las islas y se
## inunda el resto; los bajíos de la base 0 se copian a las demás.
func _islands_n() -> void:
	var n := map.n
	var mid := Vector2i(n / 2, n / 2)
	var np := bases.size()
	var c0 := bases[0] + Vector2i(2, 2)
	var c1 := bases[1] + Vector2i(2, 2)
	var chord := isqrt((c1 - c0).length_squared())
	var rb := mini(27, chord * 3 / 10)
	var rf := mini(13, chord / 6)
	var isl: Array = [[mid, 14]]
	var between: Array[Vector2i] = []
	for i in np:
		var a := bases[i] + Vector2i(2, 2)
		var b := bases[(i + 1) % np] + Vector2i(2, 2)
		var m := (a + b) / 2
		# Hacia afuera, hasta el círculo de las bases.
		var out := m - mid
		var ol := maxi(1, isqrt(out.length_squared()))
		var rad := isqrt((a - mid).length_squared())
		var bt := mid + out * rad / ol
		between.append(bt)
		isl.append([a, rb])
		isl.append([bt, rf])
	var sd := rng.range_i(1, 1 << 20)
	for ty in n:
		for tx in n:
			var t0 := _to_frame0(Vector2i(tx, ty))
			var land := false
			for it in isl:
				var cc: Vector2i = it[0]
				var r: int = it[1]
				var rr := r * 10 + (_vnoise(t0.x, t0.y, 7, sd) - 500) * r * 7 / 1000
				var d2 := (tx - cc.x) * (tx - cc.x) + (ty - cc.y) * (ty - cc.y)
				if d2 * 100 <= rr * rr:
					land = true
					break
			if not land and not _near_base(Vector2i(tx, ty), 12):
				map.set_water(tx, ty, 1)
	# Bajíos: el mismo meandro en el marco de cada base, dibujado entero en cada una
	# (girar casilla por casilla deja agujeros en diagonal y corta el paso en algunas).
	for pair in [[c0, mid], [c0, between[0]], [c0, between[np - 1]], [between[0], mid]]:
		var a0: Vector2i = pair[0]
		var b0: Vector2i = pair[1]
		var L := maxi(1, isqrt((b0 - a0).length_squared()))
		var steps := L * 2
		var offs := PackedInt32Array()
		var off := 0
		var vel := 0
		for k in steps + 1:
			offs.append(off)
			var lim := mini(60, mini(k, steps - k) * 5)
			if rng.range_i(0, 1) == 0:
				vel = clampi(vel + rng.range_i(-2, 2), -6, 6)
			off = clampi(off + vel, -lim, lim)
		var pa := _sym_points(a0)
		var pb := _sym_points(b0)
		for i in np:
			var d: Vector2i = pb[i] - pa[i]
			var perp := Vector2i(-d.y, d.x)
			for k in steps + 1:
				var p: Vector2i = pa[i] + Vector2i(d.x * k / steps, d.y * k / steps) + Vector2i(perp.x * offs[k] / (10 * L), perp.y * offs[k] / (10 * L))
				for dy in range(-1, 2):
					for dx in range(-1, 2):
						var t := p + Vector2i(dx, dy)
						if map.in_bounds(t.x, t.y) and map.water[t.y * n + t.x] == 1:
							map.set_water(t.x, t.y, 2)


## Animales de un jugador (proceso/23, C-32). `spots`: [junto a la capital (propios),
## cerca (sueltos), manada de venados 1, manada de venados 2]; las cantidades salen de
## `reglas.animales` con lo que cambie la civ (`civ.animales`: los guaraníes, cazadores,
## sin rebaño y con más venados).
func _animal_kit(pid: int, spots: Array) -> void:
	var an: Dictionary = (data.reglas["animales"] as Dictionary).duplicate()
	an.merge(dp(pid).civ.get("animales", {}), true)
	var home: Vector2i = spots[0]
	for i in int(an["inicial"]):
		var t := map.nearest_free(home.x + i % 3, home.y + i / 3, 6)
		if t.x >= 0:
			spawn_unit("rebano", pid, t.x * P + P / 2, t.y * P + P / 2)
	_cluster_at("rebano_salvaje", spots[1], int(an["sueltos_cerca"]))
	var herds := int(an["venados_manadas"])
	for h in herds:
		var c: Vector2i = spots[2 + h % 2] + Vector2i((h / 2) * 3, (h / 2) * -3)
		_cluster_at("venado", c, int(an["venados_por_manada"]))


func _res_at(type: String, t: Vector2i, amount: int, owner: int, hops: int = 0) -> void:
	var tam: Array = data.recursos[type]["tam"]
	var spot := t
	# Espiral hasta 9 casillas: cada base tiene que recibir todo su juego de recursos,
	# aunque en islas su lugar caiga en el agua.
	var tries: Array[Vector2i] = [Vector2i.ZERO]
	# Los de una base buscan cerca y, si no hay lugar, se acercan a la base: una
	# espiral grande los podía correr afuera (islas).
	var max_r := 3 if owner >= 0 and hops < 4 else 9
	for rr in range(1, max_r + 1):
		for dy in range(-rr, rr + 1):
			for dx in range(-rr, rr + 1):
				if maxi(absi(dx), absi(dy)) == rr:
					tries.append(Vector2i(dx, dy))
	for off in tries:
		spot = t + off
		if spot.x >= 1 and spot.y >= 1 and spot.x + tam[0] < map.n - 1 and spot.y + tam[1] < map.n - 1 and map.is_free_rect(spot.x - 1, spot.y - 1, tam[0] + 2, tam[1] + 2):
			var wet := false
			for yy in range(spot.y, spot.y + tam[1]):
				for xx in range(spot.x, spot.x + tam[0]):
					if map.is_water(xx, yy):
						wet = true
			if not wet:
				var e := spawn_resource(type, spot.x, spot.y)
				if amount > 0:
					e.amount = amount
				e.res_owner = owner
				return
	# Sin lugar en la espiral (en islas, todo agua): se acerca a su base de a pasos.
	if owner >= 0 and owner < bases.size() and hops < 4:
		var home := bases[owner] + Vector2i(2, 2)
		_res_at(type, t + (home - t) / 4, amount, owner, hops + 1)


func _tree_at(t: Vector2i) -> void:
	if map.in_bounds(t.x, t.y) and not _near_base(t, 9) and map.occupant(t.x, t.y) == -1 and not map.is_water(t.x, t.y):
		# Con N bases, ningún árbol a 2 casillas de un vado: un bosque en la punta de un
		# bajío deja una isla sin salida (en los mapas de 2 queda como estaba).
		if n_layout():
			for dy in range(-2, 3):
				for dx in range(-2, 3):
					if map.in_bounds(t.x + dx, t.y + dy) and map.water[(t.y + dy) * map.n + t.x + dx] == 2:
						return
		spawn_resource("arbol", t.x, t.y)


func _blob_at(c: Vector2i, r: int, density: int) -> void:
	for dy in range(-r, r + 1):
		for dx in range(-r, r + 1):
			if dx * dx + dy * dy > r * r + rng.range_i(0, r):
				continue
			if rng.range_i(0, 99) < density:
				_tree_at(c + Vector2i(dx, dy))


## Bosque de forma fija, sin azar: el de cada base tiene que ser igual al de las otras.
func _blob_fixed(c: Vector2i, r: int) -> void:
	for dy in range(-r, r + 1):
		for dx in range(-r, r + 1):
			if dx * dx + dy * dy <= r * r + r / 2:
				_tree_at(c + Vector2i(dx, dy))


func _cluster_at(type: String, c: Vector2i, count: int) -> void:
	var offs: Array[Vector2i] = [Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1), Vector2i(-1, 0), Vector2i(0, -1), Vector2i(2, 1), Vector2i(1, 2), Vector2i(-1, 1), Vector2i(2, 0)]
	for i in mini(count, offs.size()):
		var t := c + offs[i]
		if map.in_bounds(t.x, t.y) and map.occupant(t.x, t.y) == -1 and not map.is_water(t.x, t.y):
			spawn_resource(type, t.x, t.y)


func _scale_dir(d: Vector2i, dist_tiles: int) -> Vector2i:
	if d.x != 0 and d.y != 0:
		return d * (dist_tiles * 7 / 10)
	return d * dist_tiles


func _near_base(t: Vector2i, r: int) -> bool:
	for i in mini(maxi(players.size(), 2), bases.size()):
		var b := bases[i]
		var c := b + Vector2i(2, 2)
		if absi(t.x - c.x) < r and absi(t.y - c.y) < r:
			return true
	return false


func _mirror(t: Vector2i, w: int, h: int) -> Vector2i:
	return Vector2i(map.n - t.x - w, map.n - t.y - h)


## Recurso y su espejo. `amount` > 0 cambia la cantidad; `owner_pair` marca la
## arcilla de casa: el original es del jugador 0 y el espejo del 1.
func _res_sym(type: String, t: Vector2i, amount: int = -1, owner_pair: bool = false) -> void:
	var tam: Array = data.recursos[type]["tam"]
	var m := _mirror(t, tam[0], tam[1])
	if t.x < 1 or t.y < 1 or t.x + tam[0] > map.n - 1 or t.y + tam[1] > map.n - 1:
		return
	if not map.is_free_rect(t.x - 1, t.y - 1, tam[0] + 2, tam[1] + 2) or not map.is_free_rect(m.x - 1, m.y - 1, tam[0] + 2, tam[1] + 2):
		return
	for yy in range(t.y, t.y + tam[1]):
		for xx in range(t.x, t.x + tam[0]):
			if map.is_water(xx, yy) or map.is_water(m.x + xx - t.x, m.y + yy - t.y):
				return
	var a := spawn_resource(type, t.x, t.y)
	var b := spawn_resource(type, m.x, m.y)
	if amount > 0:
		a.amount = amount
		b.amount = amount
	if owner_pair:
		a.res_owner = 0
		b.res_owner = 1


## Cantidad de una veta según el carácter del terreno (terrenos.<t>.minerales_pct). Con
## `amount` <= 0 parte de la de recursos.json.
func _min_amt(type: String, amount: int) -> int:
	var base := amount if amount > 0 else int(data.recursos[type]["cantidad"])
	var pct := int((terrain_def().get("minerales_pct", {}) as Dictionary).get(str(data.recursos[type]["recurso"]), 100))
	return maxi(1, base * pct / 100)


## Veta lejana por jugador: reglas.recursos_mapa.<clave> con lejos_ref_casillas casillas por
## jugador, en proporción a las de este mapa (proceso/32-ronda-8/02).
func _far_amt(type: String, key: String) -> int:
	var rm: Dictionary = data.reglas.get("recursos_mapa", {})
	var per := map.n * map.n / maxi(2, players.size())
	var amount := int(rm.get(key, -1))
	if amount <= 0:
		return _min_amt(type, -1)
	return _min_amt(type, maxi(100, amount * per / maxi(1, int(rm.get("lejos_ref_casillas", per))) / 100 * 100))


## Como `_res_sym`, pero si el lugar no sirve (agua, árboles, otra veta) prueba en espiral hasta
## 6 casillas: con un río la piedra de casa o la del centro se perdían en silencio.
func _res_sym_near(type: String, t: Vector2i, amount: int, owner_pair: bool) -> void:
	var tam: Array = data.recursos[type]["tam"]
	for rr in 7:
		for dy in range(-rr, rr + 1):
			for dx in range(-rr, rr + 1):
				if maxi(absi(dx), absi(dy)) != rr:
					continue
				var c := t + Vector2i(dx, dy)
				var m := _mirror(c, tam[0], tam[1])
				if c.x < 1 or c.y < 1 or c.x + tam[0] > map.n - 1 or c.y + tam[1] > map.n - 1:
					continue
				if not map.is_free_rect(c.x - 1, c.y - 1, tam[0] + 2, tam[1] + 2) or not map.is_free_rect(m.x - 1, m.y - 1, tam[0] + 2, tam[1] + 2):
					continue
				var wet := false
				for yy in range(c.y, c.y + tam[1]):
					for xx in range(c.x, c.x + tam[0]):
						if map.is_water(xx, yy) or map.is_water(m.x + xx - c.x, m.y + yy - c.y):
							wet = true
				if wet:
					continue
				_res_sym(type, c, amount, owner_pair)
				return


## Vetas nuevas al llegar a una edad (reglas.recursos_mapa.vetas_por_edad): propias, a veta_dist
## casillas de la capital, en el primer rumbo libre de ocho (orden fijo). Solo en escaramuza.
func _age_veins(pid: int, age: int) -> void:
	var rm: Dictionary = data.reglas.get("recursos_mapa", {})
	var list: Array = (rm.get("vetas_por_edad", {}) as Dictionary).get(str(age), [])
	if list.is_empty() or _opts.get("sin_sitios", false) or pid >= bases.size():
		return
	var c := bases[pid] + Vector2i(2, 2)
	for capital in actives:
		if capital.alive and capital.owner == pid and capital.capital:
			c = Vector2i(capital.tx + capital.w / 2, capital.ty + capital.h / 2)
			break
	var dist0 := int(rm.get("veta_dist", 16))
	var dirs: Array[Vector2i] = [Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 0), Vector2i(0, -1), Vector2i(1, 1), Vector2i(-1, 1), Vector2i(-1, -1), Vector2i(1, -1)]
	var k := (pid + age) % dirs.size()
	for v: Dictionary in list:
		var type: String = v["tipo"]
		var tam: Array = data.recursos[type]["tam"]
		var placed := false
		for dd in range(0, 12, 3):
			for j in dirs.size():
				var s := c + _scale_dir(dirs[(k + j) % dirs.size()], dist0 + dd)
				if s.x < 2 or s.y < 2 or s.x + tam[0] > map.n - 2 or s.y + tam[1] > map.n - 2:
					continue
				if not map.is_free_rect(s.x - 1, s.y - 1, tam[0] + 2, tam[1] + 2) or map.is_water(s.x, s.y) or map.is_water(s.x + tam[0] - 1, s.y + tam[1] - 1):
					continue
				var e := spawn_resource(type, s.x, s.y)
				e.amount = _min_amt(type, int(v.get("cantidad", -1)))
				e.res_owner = pid if type == "riqueza" else -1
				k = (k + j + 1) % dirs.size()
				placed = true
				break
			if placed:
				break


func _tree_sym(t: Vector2i) -> void:
	var m := _mirror(t, 1, 1)
	if not map.in_bounds(t.x, t.y) or _near_base(t, 9) or _near_base(m, 9):
		return
	if map.occupant(t.x, t.y) != -1 or map.occupant(m.x, m.y) != -1 or map.is_water(t.x, t.y) or map.is_water(m.x, m.y):
		return
	spawn_resource("arbol", t.x, t.y)
	spawn_resource("arbol", m.x, m.y)


func _blob_sym(c: Vector2i, r: int, density: int) -> void:
	for dy in range(-r, r + 1):
		for dx in range(-r, r + 1):
			var d2 := dx * dx + dy * dy
			if d2 > r * r + rng.range_i(0, r):
				continue
			if rng.range_i(0, 99) < density:
				_tree_sym(c + Vector2i(dx, dy))


func _cluster_sym(type: String, c: Vector2i, count: int) -> void:
	var offs: Array[Vector2i] = [Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1), Vector2i(-1, 0), Vector2i(0, -1), Vector2i(2, 1), Vector2i(1, 2), Vector2i(-1, 1), Vector2i(2, 0)]
	for i in mini(count, offs.size()):
		var t := c + offs[i]
		var m := _mirror(t, 1, 1)
		if map.occupant(t.x, t.y) == -1 and map.occupant(m.x, m.y) == -1 and map.in_bounds(t.x, t.y) and not map.is_water(t.x, t.y) and not map.is_water(m.x, m.y):
			spawn_resource(type, t.x, t.y)
			spawn_resource(type, m.x, m.y)


## Parámetros del tipo de mapa (reglas.json, "terrenos").
func terrain_def() -> Dictionary:
	return data.reglas["terrenos"].get(terrain, data.reglas["terrenos"]["llano"])


## Relieve y agua con simetría puntual; las bases quedan llanas (D-027, docs/10).
func _generate_terrain() -> void:
	var td := terrain_def()
	if _opts.has("relieve"):
		_relief_real(_opts["relieve"], td.get("relieve", {}).get("umbrales", [72, 90]))
		return
	if td.has("relieve"):
		_relief_noise(td["relieve"])
	else:
		_relief_hills(int(td.get("colinas", 4)), int(td.get("nivel_max", 2)))
	if td.has("rio"):
		_water_layout(td["rio"])
	var lr: Array = td.get("laguna_radio", [2, 3])
	for k in int(td.get("lagunas", 0)):
		var c := Vector2i(rng.range_i(10, map.n - 11), rng.range_i(10, map.n - 11))
		if not _near_base(c, 18):
			_lake_blob(c, rng.range_i(int(lr[0]), int(lr[1])))
	if td.has("fortines"):
		if n_layout():
			_fort_rings_n(td["fortines"])
		else:
			_fort_rings(td["fortines"])
	if int(td.get("penascos", 0)) > 0:
		_crags(int(td["penascos"]))
	_ensure_crossings()


## Colinas redondas en mesetas de nivel 1..top (mapas clásicos).
func _relief_hills(hills: int, top: int) -> void:
	var n := map.n
	var made := 0
	var tries := 0
	while made < hills and tries < 200:
		tries += 1
		var c := Vector2i(rng.range_i(6, n - 7), rng.range_i(6, n - 7))
		if _near_base(c, 15):
			continue
		var r := rng.range_i(4, 9)
		var lvl := rng.range_i(1, top)
		for l in range(1, lvl + 1):
			var rr := r - (l - 1) * 2
			if rr < 2:
				break
			for dy in range(-rr, rr + 1):
				for dx in range(-rr, rr + 1):
					if dx * dx + dy * dy > rr * rr + rng.range_i(0, rr):
						continue
					var t := c + Vector2i(dx, dy)
					var pts := _sym_points(t)
					var ok := map.in_bounds(t.x, t.y)
					for q in pts:
						if _near_base(q, 11):
							ok = false
					if not ok:
						continue
					for q in pts:
						if map.in_bounds(q.x, q.y) and map.h_at(q.x, q.y) < l:
							map.height[q.y * n + q.x] = l
		made += 1


## Relieve orgánico: ruido de valor entero en dos octavas, cortado en niveles
## por umbrales. Umbrales juntos hacen paredes (amba); separados, terrazas.
func _relief_noise(rd: Dictionary) -> void:
	var n := map.n
	var sc := int(rd.get("escala", 14))
	var cuts: Array = rd.get("umbrales", [60, 80])
	var bias: String = rd.get("sesgo", "")
	var s1 := rng.range_i(1, 1 << 20)
	var s2 := rng.range_i(1, 1 << 20)
	for ty in n:
		for tx in n:
			var idx := ty * n + tx
			var m := _mirror(Vector2i(tx, ty), 1, 1)
			var sx := tx
			var sy := ty
			if n_layout():
				# Con N bases, cada casilla toma el ruido de su lugar girado al sector de la base 0.
				var c0 := _to_frame0(Vector2i(tx, ty))
				sx = c0.x
				sy = c0.y
				m = Vector2i(tx, ty)
			elif idx > m.y * n + m.x:
				continue # la mitad espejada se copia
			var v := (_vnoise(sx, sy, sc, s1) * 2 + _vnoise(sx, sy, maxi(3, sc / 2), s2)) / 30 # 0..100
			if bias == "esquinas":
				# Cordillera en las dos esquinas sin base (la antidiagonal).
				var dc := mini(tx + (n - 1 - ty), (n - 1 - tx) + ty)
				v += maxi(0, 46 - dc * 46 / (n * 6 / 10))
			# Las bases quedan llanas, con rampa suave alrededor.
			var db := 1 << 20
			for i in mini(maxi(players.size(), 2), bases.size()):
				var c := bases[i] + Vector2i(2, 2)
				db = mini(db, maxi(absi(tx - c.x), absi(ty - c.y)))
				if not n_layout():
					var cm := _mirror(c, 1, 1)
					db = mini(db, maxi(absi(tx - cm.x), absi(ty - cm.y)))
			v -= maxi(0, (19 - db) * 9)
			var lvl := 0
			for cut in cuts:
				if v >= int(cut):
					lvl += 1
			map.height[idx] = lvl
			map.height[m.y * n + m.x] = lvl


## Relieve de un lugar real: percentiles 00..99 por casilla y agua (0, 1 o 2),
## como filas de texto. Sin simetría: las misiones no la necesitan.
func _relief_real(rd: Dictionary, cuts: Array) -> void:
	var n := map.n
	var rows: Array = rd["alturas"]
	var wrows: Array = rd["agua"]
	for ty in mini(n, rows.size()):
		var row: String = rows[ty]
		var wrow: String = wrows[ty]
		for tx in mini(n, row.length() / 2):
			var v := row.substr(tx * 2, 2).to_int()
			var db := 1 << 20
			for i in mini(maxi(players.size(), 2), bases.size()):
				var c := bases[i] + Vector2i(2, 2)
				db = mini(db, maxi(absi(tx - c.x), absi(ty - c.y)))
			v -= maxi(0, (19 - db) * 9)
			var lvl := 0
			for cut in cuts:
				if v >= int(cut):
					lvl += 1
			map.height[ty * n + tx] = lvl
	for ty in mini(n, wrows.size()):
		var wrow: String = wrows[ty]
		for tx in mini(n, wrow.length()):
			var k := wrow.unicode_at(tx) - 48
			if k > 0 and not _near_base(Vector2i(tx, ty), 9):
				map.set_water(tx, ty, k)
				map.height[ty * n + tx] = 0


## Ruido de valor entero (0..1000) con interpolación suavizada; determinista.
func _vnoise(x: int, y: int, sc: int, sd: int) -> int:
	var gx := x / sc
	var gy := y / sc
	var fx := (x % sc) * 1000 / sc
	var fy := (y % sc) * 1000 / sc
	fx = fx * fx * (3000 - 2 * fx) / 1000000
	fy = fy * fy * (3000 - 2 * fy) / 1000000
	var a := _lattice(gx, gy, sd)
	var b := _lattice(gx + 1, gy, sd)
	var c := _lattice(gx, gy + 1, sd)
	var d := _lattice(gx + 1, gy + 1, sd)
	var top := a + (b - a) * fx / 1000
	var bot := c + (d - c) * fx / 1000
	return top + (bot - top) * fy / 1000


static func _lattice(x: int, y: int, sd: int) -> int:
	var h := (x * 374761393 + y * 668265263 + sd * 2147483647) & 0x7fffffff
	h = ((h ^ (h >> 13)) * 1274126177) & 0x7fffffff
	return (h ^ (h >> 16)) % 1001


## Río por la antidiagonal (que la simetría deja fija), corrido `shift` casillas.
## Forma del agua, elegida al azar entre las del tipo de mapa (como los mapas
## de AoE4: la misma idea con otra forma en cada semilla). Todo respeta la
## simetría puntual porque cada casilla se pinta junto con su espejo.
func _water_layout(rd: Dictionary) -> void:
	var forms: Array = rd.get("formas", ["cruce"])
	water_form = str(forms[rng.range_i(0, forms.size() - 1)])
	var w := int(rd.get("ancho", 1))
	var fe := int(rd.get("vados", 22))
	# Con 3 o más jugadores se dibuja lo de la base 0 y el giro lo copia a las demás
	# (`_sym_points`): los ríos salen del centro entre dos bases vecinas.
	if n_layout():
		match water_form:
			"cruce":
				_river_through_center(w, fe, false)
			"lago":
				_river_through_center(w, fe, true)
			"costados":
				_river_through_center(w, fe, false, map.n / 5)
			"anillo":
				_moat(w)
			"islas":
				_islands_n()
			"brazos":
				_moat(w)
				_river_through_center(w, fe, false)
		return
	match water_form:
		"cruce":
			_river_through_center(w, fe, false)
		"lago":
			_river_through_center(w, fe, true)
		"costados":
			_side_river(w, fe)
		"anillo":
			_moat(w)
		"ninguno":
			pass
		"islas":
			_islands()
		"brazos":
			_river_through_center(w, fe, false)
			_river_parallel(int(rd.get("brazos", 15)), maxi(1, w - 1), maxi(6, fe - 3))


## Río que pasa por el centro con un ángulo al azar y meandros suaves. Se
## dibuja solo la mitad; el espejo completa la otra.
func _river_through_center(w: int, fe: int, lake: bool, from_k: int = 0) -> void:
	var n := map.n
	var dirs: Array[Vector2i] = [Vector2i(1, -1), Vector2i(2, -1), Vector2i(1, -2), Vector2i(1, 0), Vector2i(0, 1)]
	var d := dirs[rng.range_i(0, dirs.size() - 1)]
	if n_layout():
		# Entre la base 0 y la 1, hacia afuera: el giro hace un río entre cada par de vecinas.
		d = -(_base_dirs[0] + _base_dirs[1])
	var m := maxi(absi(d.x), absi(d.y))
	var perp := Vector2i(-d.y, d.x)
	var c := Vector2i(n / 2, n / 2)
	var lake_r := 0
	if lake:
		lake_r = rng.range_i(9, 13)
		_lake_blob(c, lake_r)
	var off := 0 # desvío lateral en décimas de casilla
	var vel := 0
	var path: Array[Vector2i] = []
	var k := 0
	while k < n:
		var p := c + Vector2i(d.x * k / m, d.y * k / m) + Vector2i(perp.x * off / (10 * m), perp.y * off / (10 * m))
		if not map.in_bounds(p.x, p.y):
			break
		if k >= from_k:
			path.append(p)
			_paint_river(p, w, k > lake_r and (k % fe) < 3)
		if rng.range_i(0, 2) == 0:
			vel = clampi(vel + rng.range_i(-2, 2), -6, 6)
		off = clampi(off + vel, -90, 90)
		k += 1
	_record_river(path)


## Ríos a los costados: cada uno encierra una esquina sin base, con sus
## recursos detrás. El espejo pone el otro en la esquina opuesta.
func _side_river(w: int, fe: int) -> void:
	var n := map.n
	var a := Vector2i(rng.range_i(n * 50 / 100, n * 70 / 100), -2)
	var b := Vector2i(n + 1, rng.range_i(n * 30 / 100, n * 50 / 100))
	_record_river(_meander(a, b, w, fe, 0))


## Traza un río de `a` a `b` con meandros (desvío lateral con inercia) y lo pinta.
func _meander(a: Vector2i, b: Vector2i, w: int, fe: int, no_ford_until: int) -> Array[Vector2i]:
	var d := b - a
	var m := maxi(absi(d.x), absi(d.y))
	var perp := Vector2i(-d.y, d.x)
	var plen := maxi(1, maxi(absi(perp.x), absi(perp.y)))
	var off := 0 # décimas de casilla
	var vel := 0
	var path: Array[Vector2i] = []
	for k in m + 1:
		# El desvío se apaga en los extremos para que el río llegue a su destino.
		var lim := mini(140, mini(k, m - k) * 12)
		var p := a + Vector2i(d.x * k / m, d.y * k / m) + Vector2i(perp.x * off / (10 * plen), perp.y * off / (10 * plen))
		if map.in_bounds(p.x, p.y):
			path.append(p)
			_paint_river(p, w, k > no_ford_until and (k % fe) < 3)
		if rng.range_i(0, 1) == 0:
			vel = clampi(vel + rng.range_i(-3, 3), -9, 9)
		off = clampi(off + vel, -lim, lim)
	return path


## Foso en anillo alrededor de una loma central, con cuatro vados.
func _moat(w: int) -> void:
	var n := map.n
	var c := Vector2i(n / 2, n / 2)
	var r := rng.range_i(13, 17)
	for ty in range(c.y - r - w - 2, c.y + r + w + 3):
		for tx in range(c.x - r - w - 2, c.x + r + w + 3):
			var dx := tx - c.x
			var dy := ty - c.y
			var d2 := dx * dx + dy * dy
			var t := Vector2i(tx, ty)
			if d2 < r * r:
				if map.in_bounds(tx, ty) and not map.is_water(tx, ty):
					map.height[ty * n + tx] = maxi(map.height[ty * n + tx], 1)
				continue
			if d2 > (r + w + 1) * (r + w + 1):
				continue
			var ford := absi(dx) <= 1 or absi(dy) <= 1
			_set_water_sym(t, 2 if ford else 1)


## Brazo paralelo al río central (deltas).
func _river_parallel(shift: int, width: int, fe: int) -> void:
	var n := map.n
	var off := 0
	var path: Array[Vector2i] = []
	for i in range(0, n + shift):
		if rng.range_i(0, 3) == 0:
			off = clampi(off + rng.range_i(-1, 1), -6, 6)
		var p := Vector2i(i + off + shift, n - 1 - i + off + shift)
		if map.in_bounds(p.x, p.y):
			path.append(p)
		_paint_river(p, width, (i % fe) < 3)
	_record_river(path)


## Fortín natural (como las mesetas encerradas de AoE4): un cerco de peñas casi
## cuadrado alrededor de cada base, con una salida de `hueco` casillas en cada
## lado. Las salidas arrancan cerradas con la empalizada y la puerta de la civ.
func _fort_rings(fd: Dictionary) -> void:
	var n := map.n
	var r := int(fd.get("radio", 18))
	var thick := int(fd.get("grosor", 3))
	var half := int(fd.get("hueco", 5)) / 2
	var sd := rng.range_i(1, 1 << 20)
	var c := bases[0] + Vector2i(2, 2)
	for ty in range(c.y - r - thick - 3, c.y + r + thick + 4):
		for tx in range(c.x - r - thick - 3, c.x + r + thick + 4):
			if not map.in_bounds(tx, ty):
				continue
			var dx := tx - c.x
			var dy := ty - c.y
			var across := absi(dy) if absi(dx) >= absi(dy) else absi(dx)
			if across <= half:
				continue # salida
			# Borde irregular, salvo junto a las salidas, para que la empalizada las cierre justo.
			var wob := 0 if across <= half + 2 else (_vnoise(tx, ty, 6, sd) - 500) / 250
			var cheb := maxi(absi(dx), absi(dy)) + wob
			if cheb >= r and cheb < r + thick:
				_set_rock_sym(Vector2i(tx, ty))
	# Salidas: la línea del medio del cerco, de lado a lado del hueco.
	var mid := r + thick / 2
	for side: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
		var tiles: Array[Vector2i] = []
		var perp := Vector2i(side.y, side.x)
		for k in range(-half, half + 1):
			tiles.append(c + side * mid + perp * k)
		var gate := c + side * mid
		_fort_gaps.append([0, tiles, gate])
		var mt: Array[Vector2i] = []
		for t in tiles:
			mt.append(_mirror(t, 1, 1))
		_fort_gaps.append([1, mt, _mirror(gate, 1, 1)])


## Cierra las salidas del fortín con la empalizada y la puerta de cada civ.
func _spawn_fort_walls() -> void:
	for g in _fort_gaps:
		var pid: int = g[0]
		if pid >= players.size():
			continue
		var dd := dp(pid)
		for t: Vector2i in g[1]:
			var is_gate: bool = (g[2] as Array).has(t) if g[2] is Array else t == g[2]
			var type := "puerta" if is_gate else "empalizada"
			if not dd.edificios.has(type) or not map.in_bounds(t.x, t.y) or not map.is_free_rect(t.x, t.y, 1, 1):
				continue
			spawn_building(type, pid, t.x, t.y, true)


## Peñascos sueltos: manchones de roca que no se pasan, simétricos.
func _crags(count: int) -> void:
	var n := map.n
	var made := 0
	var tries := 0
	while made < count and tries < count * 20:
		tries += 1
		var c := Vector2i(rng.range_i(6, n - 7), rng.range_i(6, n - 7))
		if _near_base(c, 20) or _near_base(_mirror(c, 1, 1), 20) or absi(c.x - n / 2) + absi(c.y - n / 2) < 12:
			continue
		var r := rng.range_i(1, 3)
		var sd := rng.range_i(1, 1 << 20)
		for dy in range(-r - 1, r + 2):
			for dx in range(-r - 1, r + 2):
				var t := c + Vector2i(dx, dy)
				var rr := r * 10 + (_vnoise(t.x, t.y, 3, sd) - 500) * 12 / 1000
				if (dx * dx + dy * dy) * 100 <= rr * rr:
					_set_rock_sym(t)
		made += 1


func _set_rock_sym(t: Vector2i) -> void:
	if n_layout():
		var pts := _sym_points(t)
		for q in pts:
			if _near_base(q, 10):
				return
		for q in pts:
			if map.in_bounds(q.x, q.y):
				map.set_rock(q.x, q.y)
		return
	var m := _mirror(t, 1, 1)
	if not map.in_bounds(t.x, t.y) or _near_base(t, 10) or _near_base(m, 10):
		return
	map.set_rock(t.x, t.y)
	map.set_rock(m.x, m.y)


## Islas: cada base en su isla, una isla grande al centro y dos en los
## costados, unidas por bajíos que se vadean (el juego no tiene barcos, D-020).
func _islands() -> void:
	var n := map.n
	var c0 := bases[0] + Vector2i(2, 2)
	var mid := Vector2i(n / 2, n / 2)
	var fa := Vector2i(n * 3 / 4, n / 4)
	var isl := [[c0, 27], [mid, 14], [fa, 13]]
	var sd := rng.range_i(1, 1 << 20)
	for ty in n:
		for tx in n:
			var t := Vector2i(tx, ty)
			var m := _mirror(t, 1, 1)
			if ty * n + tx > m.y * n + m.x:
				continue
			var land := false
			for it in isl:
				for cc: Vector2i in [it[0], _mirror(it[0], 1, 1)]:
					var r: int = it[1]
					var rr := r * 10 + (_vnoise(tx, ty, 7, sd) - 500) * r * 7 / 1000
					var d2 := (tx - cc.x) * (tx - cc.x) + (ty - cc.y) * (ty - cc.y)
					if d2 * 100 <= rr * rr:
						land = true
			if not land:
				_set_water_sym(t, 1)
	for pair in [[c0, mid], [c0, fa], [c0, _mirror(fa, 1, 1)], [fa, mid]]:
		_causeway(pair[0], pair[1])


## Bajío: convierte en vado el agua a lo largo de un camino con meandros.
func _causeway(a: Vector2i, b: Vector2i) -> void:
	var d := b - a
	var m := maxi(1, maxi(absi(d.x), absi(d.y)))
	var perp := Vector2i(-d.y, d.x)
	var plen := maxi(1, maxi(absi(perp.x), absi(perp.y)))
	var off := 0
	var vel := 0
	for k in m + 1:
		var lim := mini(60, mini(k, m - k) * 10)
		var p := a + Vector2i(d.x * k / m, d.y * k / m) + Vector2i(perp.x * off / (10 * plen), perp.y * off / (10 * plen))
		for dy in range(-1, 2):
			for dx in range(-1, 2):
				var t := p + Vector2i(dx, dy)
				if map.in_bounds(t.x, t.y) and map.water[t.y * map.n + t.x] == 1:
					_set_water_sym(t, 2)
		if rng.range_i(0, 1) == 0:
			vel = clampi(vel + rng.range_i(-2, 2), -6, 6)
		off = clampi(off + vel, -lim, lim)


## Pincel de río: agua (o vado) y cauce rebajado alrededor. Un vado nunca
## vuelve a ser agua profunda, así el paso queda entero.
func _paint_river(p: Vector2i, width: int, ford: bool) -> void:
	var n := map.n
	if n_layout():
		for q in _sym_points(p):
			_paint_brush(q, width, ford)
		return
	for dy in range(-width, width + 1):
		for dx in range(-width, width + 1):
			if absi(dx) + absi(dy) > width + 1:
				continue
			var t := p + Vector2i(dx, dy)
			if not map.in_bounds(t.x, t.y):
				continue
			var cur := map.water[t.y * n + t.x]
			if cur == 2 or (cur == 1 and not ford):
				continue
			_set_water_sym(t, 2 if ford else 1)
	for dy in range(-width - 4, width + 5):
		for dx in range(-width - 4, width + 5):
			var t := p + Vector2i(dx, dy)
			if not map.in_bounds(t.x, t.y):
				continue
			var cap := 0 if maxi(absi(dx), absi(dy)) <= width + 2 else 1
			var m := _mirror(t, 1, 1)
			map.height[t.y * n + t.x] = mini(map.height[t.y * n + t.x], cap)
			map.height[m.y * n + m.x] = mini(map.height[m.y * n + m.x], cap)


func _set_water_sym(t: Vector2i, kind: int) -> void:
	if n_layout():
		var pts := _sym_points(t)
		for q in pts:
			if _near_base(q, 12):
				return
		for q in pts:
			if map.in_bounds(q.x, q.y):
				map.set_water(q.x, q.y, kind)
		return
	var m := _mirror(t, 1, 1)
	if not map.in_bounds(t.x, t.y) or _near_base(t, 12) or _near_base(m, 12):
		return
	map.set_water(t.x, t.y, kind)
	map.set_water(m.x, m.y, kind)


## Laguna de borde irregular (ruido de valor), con su espejo.
func _lake_blob(c: Vector2i, r: int) -> void:
	var sd := rng.range_i(1, 1 << 20)
	var e := r + r / 2 + 1
	for dy in range(-e, e + 1):
		for dx in range(-e, e + 1):
			var t := c + Vector2i(dx, dy)
			var rr := r * 10 + (_vnoise(t.x, t.y, 5, sd) - 500) * r * 9 / 1000 # décimas: borde con entrantes
			if (dx * dx + dy * dy) * 100 <= rr * rr:
				if not _near_base(t, 13) and not _near_base(_mirror(t, 1, 1), 13):
					_set_water_sym(t, 1)


## Trazo del río para la imagen (dirección de la corriente). No es estado.
func _record_river(path: Array[Vector2i]) -> void:
	if path.size() < 2:
		return
	if n_layout():
		for i in bases.size():
			var cp: Array[Vector2i] = []
			for t in path:
				cp.append(_sym_points(t)[i])
			rivers.append(cp)
		return
	# La mitad espejada va al revés, así la corriente sigue un solo sentido
	# en los ríos que cruzan por el centro.
	var mp: Array[Vector2i] = []
	for i in range(path.size() - 1, -1, -1):
		mp.append(_mirror(path[i], 1, 1))
	rivers.append(mp + path if path[0].distance_squared_to(Vector2i(map.n / 2, map.n / 2)) < 9 else path)
	if path[0].distance_squared_to(Vector2i(map.n / 2, map.n / 2)) >= 9:
		rivers.append(mp)


## Si el agua deja una base aislada, agrega vados en franjas (simétricas)
## hasta que haya paso.
func _ensure_crossings() -> void:
	var n := map.n
	if players.size() < 2:
		return
	for step in [12, 8, 5, 3]:
		if _bases_connected():
			return
		for ty in n:
			for tx in n:
				if map.water[ty * n + tx] == 1 and (tx % step == 0 or ty % step == 0):
					var t := Vector2i(tx, ty)
					if n_layout():
						for q in _sym_points(t):
							if map.in_bounds(q.x, q.y) and map.water[q.y * n + q.x] == 1:
								map.set_water(q.x, q.y, 2)
						continue
					var m := _mirror(t, 1, 1)
					map.set_water(t.x, t.y, 2)
					map.set_water(m.x, m.y, 2)


func _bases_connected() -> bool:
	var n := map.n
	var a := bases[0] + Vector2i(2, 2)
	var seen := PackedByteArray()
	seen.resize(n * n)
	var stack: Array[Vector2i] = [a]
	seen[a.y * n + a.x] = 1
	while not stack.is_empty():
		var p: Vector2i = stack.pop_back()
		for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			var q: Vector2i = p + d
			if map.in_bounds(q.x, q.y) and seen[q.y * n + q.x] == 0 and map.water[q.y * n + q.x] != 1 and map.rock[q.y * n + q.x] == 0:
				seen[q.y * n + q.x] = 1
				stack.append(q)
	for i in range(1, mini(players.size(), bases.size())):
		var b := bases[i] + Vector2i(2, 2)
		if seen[b.y * n + b.x] == 0:
			return false
	return true


# ---------------------------------------------------------------- Hash

func state_hash() -> int:
	var h := 2166136261
	for e in entities:
		for v in [e.id, e.x, e.y, e.hp, e.order, e.target, e.carry, e.amount, e.progress, e.queue.size(), e.queue_progress, e.inside, e.group]:
			h = ((h ^ (v & 0xffffffff)) * 16777619) & 0xffffffff
		if e.order == O.GROUND: # --- esport 1a ---
			for v in [e.gnd_x, e.gnd_y]:
				h = ((h ^ (v & 0xffffffff)) * 16777619) & 0xffffffff
		if e.patrol or e.rumbo >= 0:
			for v in [int(e.patrol), e.pat_x, e.pat_y, e.rumbo]:
				h = ((h ^ (v & 0xffffffff)) * 16777619) & 0xffffffff
	for f in flares:
		for v in [f["id"], f["player"], f["x"], f["y"], f["tick"]]:
			h = ((h ^ (int(v) & 0xffffffff)) * 16777619) & 0xffffffff
	for r in requests:
		for v in [r["de"], r["a"], r["n"], r["tick"]]:
			h = ((h ^ (int(v) & 0xffffffff)) * 16777619) & 0xffffffff
	for sh in shells: # --- esport 1a ---
		for v in [sh["tick"], sh["x"], sh["y"], (sh["a"] as SimEntity).id, sh["atk"]]:
			h = ((h ^ (int(v) & 0xffffffff)) * 16777619) & 0xffffffff
	h = groups.hash_into(h)
	for p in players:
		# Todos los recursos, también los propios (mit'a, fama, kulliñ), en orden fijo.
		var keys: Array = (p["res"] as Dictionary).keys()
		keys.sort()
		for k in keys:
			h = ((h ^ (int(p["res"][k]) & 0xffffffff)) * 16777619) & 0xffffffff
		h = ((h ^ int(p["age"])) * 16777619) & 0xffffffff
		h = ((h ^ int(p["pop"])) * 16777619) & 0xffffffff
		for v in p.get("disp", []):
			h = ((h ^ int(v)) * 16777619) & 0xffffffff
	for i in map.water.size():
		if map.water[i] != 0 or map.rock[i] != 0:
			h = ((h ^ (i * 4 + map.water[i] + map.rock[i] * 3)) * 16777619) & 0xffffffff
	return h
