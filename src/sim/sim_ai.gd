class_name SimAI
extends RefCounted
## IA de escaramuza (docs/08-ia-rival.md). Emite comandos como un jugador; corre dentro de la simulación.

const P := 1000
const O := SimEntity.Order

var sim: Sim
var player: int
var wave := 0
var last_attack := -100000
var eta := -100000 # cuándo llegó la última oleada (mientras marcha, cuándo se estima que llega: `_track_wave`)
var ready_since := -1 # desde cuándo espera su turno con la oleada lista (`_team_turn`)
var ready_seen := -100000 # última pensada en que estaba lista
var _wave_ids: Array = [] # la oleada que todavía no llegó
var _wave_pt := Vector2i(-1, -1) # adónde va
var last_target := -1 # edificio al que fue la última oleada (`_attack`, para no repetir frente con las aliadas)
var last_raid := 0 # incursiones y control del mapa: por tiempo transcurrido, no por tick exacto
var last_spot := 0
var last_road := 0
var last_engine := -1000
var last_elephant := -1000
var last_mill := 0
var _eng_mark_tick := 0
var _eng_mark_val := 0
var _eng_rate := 0
var _no_route := {} # edificio -> tick desde el que se vuelve a intentar el camino
var last_site := 0
var _detour := {} # sin tomar sitios: unidad -> {"exit": Vector2i, "goal": Vector2i, "amove": bool} (sale de un sitio ajeno)
var _weighted := false # sin tomar sitios: ya se cargó el peso de los sitios en la grilla de caminos
var last_tribute := 0
var _flares_done := {} # bengalas aliadas ya atendidas (id -> true)
var _flare_units := {} # unidades que fueron a una bengala -> tick hasta el que se quedan allá
# --- equipos ronda 3 ---
var _asks: Array[Dictionary] = [] # pedidos de aliados que esperan: {de, recurso, n, hasta}
var _flare_wave: Dictionary = {} # bengala de ataque que espera la próxima oleada: {x, y, de, hasta}
var _flare_march: Dictionary = {} # tropa en marcha a una bengala de ataque: {x, y, sx, sy, ids, hasta}
# --- fin equipos ronda 3 ---
var _said := {} # frase -> tick en que se dijo (para no repetir: reglas.equipos.ia_frases_calma_ticks)
var focus := -1 # jugador enemigo al que apunta el ataque; los aliados se suman (docs/11)
var rally := Vector2i(-1, -1)
var calm_since := 0
var personality := "normal" # estilo: pacifica, normal, acosadora, agresiva (reglas.json → estilos_ia); pasiva en campañas
var level: Dictionary = {} # dificultad (reglas.json → dificultades)
var centers: Array[SimEntity] = [] # edificios propios terminados que entrenan aldeanos (capital incluida)
var last_expand := 0
var last_hunt := 0
var last_hito_hit := -100000 # último envío contra un hito rival en obra
var last_contest := -100000 # última decisión de la disputa de sitios (`disputa_sitios`)
var _squad := {} # grupo que va a un sitio: {site, ids, kind (recupera/defiende), hasta}
var _site_cool := {} # sitio -> tick hasta el que no se vuelve a ir (tras una retirada)
var _contest_held := false # con la cuenta rival corriendo y sin fuerza para ir: el ejército se junta
var _holding: Dictionary = {} # lo que se junta para el centro siguiente (experta); vacío si nada
var _ctype := "-" # edificio con el que se expande (calculado una vez: `_center_type`)
var _stores := {} # almacenes propios (id -> casilla), para ver cuáles se perdieron
var _stores_lost: Array = [] # [casilla, tick] de los almacenes perdidos hace poco
var _built_ids := {} # edificios propios terminados en la pensada anterior (`rendicion`)
var _lost_buildings := 0 # cuántos de esos se perdieron en la partida (`rendicion`)
var _peak_built := 0 # lo más que tuvo terminado a la vez (`rendicion.quedan_pct`)
var _army_n := 0 # ejército propio en la pensada (para `_min_army`)
var _seen := 0 # mayor ejército rival visto hace poco (`ejercito_segun_rival`)
var _seen_tick := -100000
# --- paso 7 --- (docs/diseno/27, §4; reglas.ia_edad_iv, ia_maravilla)
var _goal := "" # lo que se ahorra este turno: el hito de la edad siguiente o la maravilla
var _age4_tick := -1 # cuándo llegó a la IV
var last_wonder_hit := -100000 # último envío contra una maravilla rival
var last_trade := -100000
var mercado_compra := {} # lotes comprados por recurso (para las mediciones; no es estado de la partida)
var mercado_venta := {} # lotes vendidos por recurso
var _wonder_on := false # ya decidió levantar la maravilla: sigue juntando aunque baje un poco la tropa
# --- muralla --- (reglas.ia_muralla; proceso/32-ronda-8/06)
var _wall_alert := false # el rival vino con tropa a la base antes de la III: amuralla en la II
var _wall_tiles: Array = [] # casillas del lienzo trazado ([] si todavía no)
var _wall_check := -100000 # última mirada de la tropa rival cerca

# Reparto de aldeanos por recurso: reglas.json → ia_economia.
var ratio_early := {}
var ratio_late := {}
var max_villagers := 42


func _init(s: Sim, pid: int, difficulty: String = "normal") -> void:
	sim = s
	player = pid
	set_difficulty(difficulty)


## La dificultad puede traer su propio reparto de aldeanos (la experta, más alimento).
func set_difficulty(key: String) -> void:
	level = sim.data.reglas["dificultades"].get(key, sim.data.reglas["dificultades"]["normal"])
	max_villagers = level["max_aldeanos"]
	ratio_early = level.get("proporcion_temprana", sim.data.reglas["ia_economia"]["proporcion_temprana"])
	ratio_late = level.get("proporcion_tardia", sim.data.reglas["ia_economia"]["proporcion_tardia"])


func thinks_now() -> bool:
	return (sim.tick + player * 5) % int(level["piensa_cada_ticks"]) == 0


func think() -> void:
	var p: Dictionary = sim.players[player]
	var vill: Array[SimEntity] = []
	var army: Array[SimEntity] = []
	var by_type := {}
	var centro: SimEntity = null
	centers.clear()
	for e in sim.owned(player):
		if not e.alive or e.owner != player:
			continue
		if e.is_unit():
			if e.inside >= 0:
				continue
			if e.fn == "civil":
				vill.append(e)
			elif e.is_military():
				army.append(e)
		elif e.is_building():
			if not by_type.has(e.type):
				by_type[e.type] = []
			by_type[e.type].append(e)
			if e.built and (e.capital or centro == null and (e.def.get("produce", []) as Array).has("aldeano")):
				centro = e
			if e.built and (e.def.get("produce", []) as Array).has("aldeano"):
				centers.append(e)
	if centro == null:
		if not army.is_empty():
			_attack(army)
		return
	if rally.x < 0:
		# La base enemiga más cercana (con equipos, nunca la de un aliado).
		var enemy_base := sim.bases[(player + 1) % sim.bases.size()]
		var best_eb := 1 << 60
		for j in mini(sim.players.size(), sim.bases.size()):
			if sim.enemies(player, j):
				var eb := sim.bases[j]
				var d := Sim.dist(eb.x * P, eb.y * P, centro.x, centro.y)
				if d < best_eb:
					best_eb = d
					enemy_base = eb
		rally = Vector2i(centro.x + (enemy_base.x * P - centro.x) / 6, centro.y + (enemy_base.y * P - centro.y) / 6)
		# El punto tiene que poderse alcanzar: un claro rodeado de árboles deja al
		# ejército dando vueltas (telemetría, proceso/20). Si no llega, se acerca a la base.
		var from := sim.map.nearest_free(centro.tx + centro.w / 2, centro.ty + centro.h + 1, 6, player)
		for k in 6:
			var rt := sim.map.nearest_free(rally.x / P, rally.y / P, 4, player)
			if rt.x >= 0 and from.x >= 0:
				var path := sim.map.find_path(from, rt, player)
				if not path.is_empty() and path[path.size() - 1] == rt:
					rally = Vector2i(rt.x * P + P / 2, rt.y * P + P / 2)
					break
			rally = Vector2i(rally.x + (centro.x - rally.x) / 4, rally.y + (centro.y - rally.y) / 4)

	# --- equipos ronda 3 --- lo pedido por un aliado se aparta antes de gastar (ver _reserve)
	_requests(p)
	var held := _reserve(p, 1)
	_army_n = army.size()
	_watch_rival_army()
	# --- paso 7 --- en la IV se ahorra para la maravilla (si le conviene) con lo mismo que el hito.
	if int(p["age"]) >= 4 and _age4_tick < 0:
		_age4_tick = sim.tick
	_goal = _hito_type(p)
	var saving := _wants_hito(p, vill.size(), by_type)
	if not saving and (_wonder_on and _keeps_wonder() or _wants_wonder(p, vill.size(), _threat(centro) != null)):
		saving = true
		_wonder_on = true
		_goal = _wonder_type()
	else:
		_wonder_on = false
	_economy(p, vill, centro, saving)
	_buildings(p, vill, centro, by_type, saving)
	var held_levels := _levels(p, army, by_type, saving, _threat(centro) != null)
	var held_late := _late_buys(p, army, by_type, saving, _threat(centro) != null) # --- paso 3 ---
	var held_own := _own_buys(p, army, by_type, saving, centro) if held_late.is_empty() else {} # --- paso 6 ---
	_dig_traps(p, vill, centro, by_type, saving) # --- paso 6 ---
	_production(p, vill, army, centro, by_type, saving)
	var held_smith := _smith(p, army, by_type, saving) if held_levels.is_empty() else {}
	_research(p, by_type, saving)
	_sink(p, by_type, saving) # --- ronda 8, 05 ---
	_engine(p, vill, centro, by_type, saving)
	_reserve(p, -1, held_levels)
	_reserve(p, -1, held_late) # --- paso 3 ---
	_reserve(p, -1, held_own) # --- paso 6 ---
	_reserve(p, -1, held_smith)
	# Ronda 8: el mercado mira lo que hay de verdad (sin lo apartado para niveles y mejoras que
	# todavía no alcanzan): apartado, la etíope trabada por 85 de piedra veía todo en cero.
	# Lo pedido por un aliado sigue apartado.
	_trade(p, by_type)
	sim.comercio.ai_think(self, p, by_type, vill, army, centro, saving) # --- comercio --- (proceso/33, §6)
	_reserve(p, -1, held) # --- equipos ronda 3 ---
	_animals(centro)
	_alarm(p, vill, army, centro)
	_tribute(p, saving)
	if _surrenders(by_type, centro):
		return
	_military(army, centro)
	_flares(army, centro)
	_aim_ground(army) # --- esport 1a ---
	# Al final: mira también las órdenes que el resto de la IA acaba de dar en este turno.
	# Sin victoria por sitios (opción de partida, tutorial) no hace falta: tomarlos no gana.
	if not level.get("toma_sitios", true) and not sim._opts.get("sitios_sin_victoria", false):
		_avoid_sites(army)


## Eje del hito según la edad: económico para la II, militar para la III y
## económico para la IV; el estilo agresivo va siempre por lo militar. Cada hito
## declara su eje en los datos ("eje"), así no depende del orden de la lista.
func _hito_type(p: Dictionary) -> String:
	var dd := sim.dp(player)
	var opts: Array = dd.hitos[clampi(p["age"] - 1, 0, 2)]
	var want := "militar" if p["age"] == 2 or personality == "agresiva" else "economia"
	for o: String in opts:
		if dd.edificios.get(o, {}).get("eje", "") == want:
			return o
	return opts[0]


## Lo que reemplaza al bono de ataque por edad (docs/diseno/27, paso 1; reglas.ia_niveles), en
## todas las dificultades y antes que la tropa: lo que tiene `ia_prioridad` (la herrería I de
## ataque, cuerpo a cuerpo y distancia) y los niveles veterano y élite de las líneas con más
## tropa. La herrería (paso 2) va después, en `_smith`. Una compra por turno; su costo queda
## apartado hasta el final del turno (la orden se paga en el tick siguiente), así la tropa no
## gasta la misma plata. Devuelve lo apartado.
func _levels(p: Dictionary, army: Array[SimEntity], by_type: Dictionary, saving: bool, threatened: bool) -> Dictionary:
	var cfg: Dictionary = sim.data.reglas.get("ia_niveles", {})
	if cfg.is_empty() or not level.get("niveles", true) or int(p["age"]) < 2 or (saving and not cfg.get("ahorrando", true)) or (saving and _goal_is_wonder()): # --- paso 7 --- la maravilla junta todo
		return {}
	var techs: Dictionary = sim.dp(player).tecnologias
	var count := {}
	for u in army:
		var l := SimData.line_of(u.def)
		if l != "":
			count[l] = int(count.get(l, 0)) + 1
	# --- paso 4 --- el asedio no compite por las dos líneas: tiene su propia regla
	var siege_n := int(count.get("asedio", 0))
	count.erase("asedio")
	# --- fin paso 4 ---
	var lines: Array = []
	for l in count:
		if int(count[l]) >= int(cfg.get("tropa_minima", 1)):
			lines.append(l)
	lines.sort_custom(func(a: String, b: String) -> bool: return count[a] > count[b] or (count[a] == count[b] and a < b))
	var n_first := int(cfg.get("lineas_primero", 2))
	# Sin tropa suficiente (recién perdió el ejército), las líneas que más edificios entrenan.
	if lines.size() < n_first:
		var made := {}
		for k in by_type:
			for b: SimEntity in by_type[k]:
				if b.built:
					for l in sim.dp(player).lines_made_by(b.def):
						made[l] = int(made.get(l, 0)) + 1
		var extra: Array = made.keys().filter(func(l: String) -> bool: return not lines.has(l))
		extra.erase("asedio") # --- paso 4 ---
		extra.sort_custom(func(a: String, b: String) -> bool: return made[a] > made[b] or (made[a] == made[b] and a < b))
		lines.append_array(extra)
	lines = lines.slice(0, n_first)
	var want: Array[String] = []
	for k: String in techs:
		if techs[k].get("ia_prioridad", false):
			want.append(k)
	# --- paso 4 --- el nivel del asedio, apenas hay asedio (reemplaza al bono por edad que tenía)
	if siege_n >= int(sim.data.reglas.get("ia_asedio", {}).get("asedio_para_nivel", 1 << 20)):
		for lvl in [1, 2]:
			for k: String in techs:
				if techs[k].get("linea", "") == "asedio" and int(techs[k].get("nivel", 0)) == lvl:
					want.append(k)
	# --- fin paso 4 ---
	for lvl in [1, 2]:
		for l: String in lines:
			for k: String in techs:
				if techs[k].get("linea", "") == l and int(techs[k].get("nivel", 0)) == lvl:
					want.append(k)
	for tech in want:
		if sim.research_block(player, tech) != "":
			continue
		var cost: Dictionary = techs[tech]["costo"]
		var ok := true
		for k in cost:
			if int(p["res"].get(k, 0)) < int(cost[k]):
				ok = false
		var where: SimEntity = null
		var anywhere := false
		for k in by_type:
			for b: SimEntity in by_type[k]:
				if b.built and sim.tech_here(techs[tech], b):
					anywhere = true
					if b.queue.size() < 2 and where == null:
						where = b
		if not anywhere:
			continue
		var held := {}
		if ok and where != null:
			sim.push_command({"t": "research", "player": player, "building": where.id, "tech": tech})
			for r in cost:
				held[r] = int(cost[r])
				p["res"][r] = int(p["res"][r]) - int(cost[r])
			return held
		# Todavía no alcanza: se junta (la tropa no gasta lo que ya hay de ese costo), salvo
		# con la base atacada. Sin esto, la tropa que cuesta riqueza la gastaba antes de llegar
		# a 150 y el veterano tardaba hasta 16 minutos (proceso/26, paso 5).
		if cfg.get("junta", false) and not threatened:
			for r in cost:
				var take := mini(int(cost[r]), int(p["res"].get(r, 0)))
				held[r] = take
				p["res"][r] = int(p["res"][r]) - take
			return held
	return {}


## Herrería (docs/diseno/27, paso 2; reglas.ia_niveles.herreria), después de los niveles y de la
## tropa, y antes de las demás investigaciones; no en un turno en que se compró o se juntó para
## un nivel, ni mientras ahorra para el hito, ni en las dificultades que no investigan. El ataque
## de la clase con más tropa propia (cuerpo a cuerpo o distancia) y la armadura contra la clase
## con más tropa rival a la vista, la tanda que falte de cada uno. Las otras dos quedan para
## `_research`, con lo que sobra. Sin juntar: compra si alcanza el costo más la reserva.
## Devuelve lo apartado (la orden se paga en el tick siguiente).
func _smith(p: Dictionary, army: Array[SimEntity], by_type: Dictionary, saving: bool) -> Dictionary:
	var cfg: Dictionary = sim.data.reglas.get("ia_niveles", {}).get("herreria", {})
	if cfg.is_empty() or saving or not level.get("investiga", false) or int(p["age"]) < 2:
		return {}
	var count := {}
	for u in army:
		var l := SimData.line_of(u.def)
		if l != "":
			count[l] = int(count.get(l, 0)) + 1
	var ranged := int(count.get("distancia", 0)) + int(count.get("polvora", 0))
	var melee := 0
	for l in count:
		melee += int(count[l])
	melee -= ranged
	var foe_ranged := 0
	var foe_melee := 0
	for e in sim.military():
		if e.alive and e.owner >= 0 and e.is_unit() and e.is_military() and sim.enemies(player, e.owner) and sim.fog.is_visible(player, e):
			if sim.is_ranged(e):
				foe_ranged += 1
			else:
				foe_melee += 1
	var groups: Array[String] = ["ataque_distancia" if ranged > melee else "ataque_cuerpo", "armadura_distancia" if foe_ranged > foe_melee else "armadura_cuerpo"]
	groups = groups.slice(0, int(cfg.get("grupos", 2)))
	var reserve := int(cfg.get("reserva", 0))
	var techs: Dictionary = sim.dp(player).tecnologias
	for g in groups:
		for tech: String in techs:
			if techs[tech].get("herreria", "") != g or sim.research_block(player, tech) != "":
				continue
			var cost: Dictionary = techs[tech]["costo"]
			var ok := true
			for k in cost:
				if int(p["res"].get(k, 0)) < int(cost[k]) + reserve:
					ok = false
			if not ok:
				break
			for k in by_type:
				for b: SimEntity in by_type[k]:
					if b.built and b.queue.size() < 2 and sim.tech_here(techs[tech], b):
						sim.push_command({"t": "research", "player": player, "building": b.id, "tech": tech})
						var held := {}
						for r in cost:
							held[r] = int(cost[r])
							p["res"][r] = int(p["res"][r]) - int(cost[r])
						return held
			break
	return {}


func _research(p: Dictionary, by_type: Dictionary, saving: bool) -> void:
	if saving or not level["investiga"]:
		return
	var reserve := 150
	var techs: Array = sim.dp(player).tecnologias.keys()
	# La tecnología del motor va primero (crítica 03, regla 5).
	techs.sort_custom(func(a: String, b: String) -> bool: return bool(sim.dp(player).tecnologias[a].get("motor", false)) and not bool(sim.dp(player).tecnologias[b].get("motor", false)))
	for tech: String in techs:
		var t: Dictionary = sim.dp(player).tecnologias[tech]
		if sim.research_block(player, tech) != "" or t.get("propia", false): # --- paso 6 --- las propias, en _own_buys
			continue
		if t.has("camino_de") or t.has("repite"): # --- ronda 8, 05 --- el camino y el sumidero, en _late_buys y _sink
			continue
		var surplus := true
		for k in t["costo"]:
			if p["res"][k] < t["costo"][k] + reserve:
				surplus = false
		if not surplus:
			continue
		for k in by_type:
			for b: SimEntity in by_type[k]:
				if b.built and b.queue.size() < 2 and sim.tech_here(t, b):
					sim.push_command({"t": "research", "player": player, "building": b.id, "tech": tech})
					return


## --- paso 3 --- Economía del final y escuela de la IV (docs/diseno/27, §1.1, §1.3 y §4.3;
## reglas.ia_compras_tardias): en el orden de los datos, una por turno, cuando alcanza el costo
## (con el descuento de los registros) más la reserva. Si la primera que sirve no alcanza, no
## pasa a otra: espera, y desde `junta_desde_edad` junta para ella. Su costo queda apartado hasta
## el final del turno, como el de los niveles.
func _late_buys(p: Dictionary, army: Array[SimEntity], by_type: Dictionary, saving: bool, threatened: bool) -> Dictionary:
	var cfg: Dictionary = sim.data.reglas.get("ia_compras_tardias", {})
	if cfg.is_empty() or not level["investiga"] or (saving and not cfg.get("ahorrando", false)):
		return {}
	var techs: Dictionary = sim.dp(player).tecnologias
	var reserve := int(cfg.get("reserva", 0))
	for tech0: String in cfg.get("orden", []):
		var tech := _pick_path() if tech0 == "@camino" else tech0 # --- ronda 8, 05 ---
		if not techs.has(tech) or sim.research_block(player, tech) != "":
			continue
		if not _late_useful(techs[tech], army):
			continue
		var where: SimEntity = null
		for k in by_type:
			for b: SimEntity in by_type[k]:
				if b.built and b.queue.size() < 2 and sim.tech_here(techs[tech], b) and where == null:
					where = b
		if where == null:
			continue
		var cost := sim.tech_cost(player, tech)
		for r in cost:
			if int(p["res"].get(r, 0)) < int(cost[r]) + reserve:
				# En la IV junta, como los niveles: aparta lo que ya tiene de ese costo para que
				# la tropa no lo gaste (salvo con la base atacada). Sin esto, en las partidas de
				# prueba la IA llegaba a la IV y no compraba nada en diez minutos (proceso/26, 07).
				var held_j := {}
				if cfg.get("junta", false) and int(p["age"]) >= int(cfg.get("junta_desde_edad", 4)) and not threatened:
					for rr in cost:
						var take := mini(int(cost[rr]), int(p["res"].get(rr, 0)))
						held_j[rr] = take
						p["res"][rr] = int(p["res"][rr]) - take
				return held_j
		sim.push_command({"t": "research", "player": player, "building": where.id, "tech": tech})
		var held := {}
		for r in cost:
			held[r] = int(cost[r])
			p["res"][r] = int(p["res"][r]) - int(cost[r])
		return held
	return {}


## --- ronda 8, 05 --- Camino de la escuela que elige la IA (proceso/32-ronda-8/05;
## reglas.ia_sumidero): con una maravilla rival en pie, el del asedio si lo tiene; si no, el
## primero que tenga de los que prefiere su pueblo (civs/<pueblo>.json → escuela.ia_caminos) o,
## sin preferencia, de `caminos`. Devuelve la mejora del camino ("camino_guerra"), o "".
func _pick_path() -> String:
	var cfg: Dictionary = sim.data.reglas.get("ia_sumidero", {})
	var techs: Dictionary = sim.dp(player).tecnologias
	var chosen := sim.school_path(player)
	if chosen != "":
		return "camino_" + chosen
	var order: Array = []
	if _rival_wonder() != null:
		order.append(String(cfg.get("camino_contra_maravilla", "asedio")))
	order.append_array(sim.dp(player).civ.get("escuela", {}).get("ia_caminos", []))
	order.append_array(cfg.get("caminos", []))
	for c in order:
		if techs.has("camino_" + str(c)):
			return "camino_" + str(c)
	return ""


## --- ronda 8, 05 --- El sumidero de la IV (reglas.ia_sumidero): con lo que pasa de la reserva,
## sin estar juntando para la maravilla, compra otra vez la mejora que se repite de su camino y
## entrena la guardia, la élite cara (hasta `guardia_por_turno` por pensada y mientras haya lugar
## de población). Va después de la tropa común y de las mejoras: gasta lo que nadie más usa.
func _sink(p: Dictionary, by_type: Dictionary, saving: bool) -> void:
	var cfg: Dictionary = sim.data.reglas.get("ia_sumidero", {})
	if cfg.is_empty() or not level["investiga"] or int(p["age"]) < int(cfg.get("desde_edad", 4)):
		return
	# Juntando para la maravilla, no toca lo que ella pide: gasta solo lo que la meta no usa
	# (en la medición, 14 000 de alimento quietos mientras juntaba madera, piedra y riqueza).
	var keep: Dictionary = (cfg.get("reserva", {}) as Dictionary).duplicate()
	if saving:
		var gc := _goal_cost(p)
		for r in gc:
			keep[r] = int(keep.get(r, 0)) + int(gc[r])
	var held := {} # lo pedido en este turno: se descuenta de la vista y se devuelve al final
	_sink_buys(p, by_type, cfg, keep, held)
	_reserve(p, -1, held)


func _sink_buys(p: Dictionary, by_type: Dictionary, cfg: Dictionary, keep: Dictionary, held: Dictionary) -> void:
	var techs: Dictionary = sim.dp(player).tecnologias
	var path := sim.school_path(player)
	var rep := ""
	if path == "": # sin camino todavía (juntando para la maravilla no pasa por _late_buys)
		rep = _pick_path()
	else:
		for tech: String in techs:
			if techs[tech].has("repite") and String(techs[tech].get("camino", "")) == path and sim.research_block(player, tech) == "":
				rep = tech
				break
	if rep != "" and sim.research_block(player, rep) != "":
		rep = ""
	if rep != "" and _sink_affords(p, sim.tech_cost(player, rep), keep):
		var where: SimEntity = null
		for k in by_type:
			for b: SimEntity in by_type[k]:
				if where == null and b.built and b.queue.size() < 2 and sim.tech_here(techs[rep], b):
					where = b
		if where != null:
			sim.push_command({"t": "research", "player": player, "building": where.id, "tech": rep})
			_hold(p, sim.tech_cost(player, rep), held)
	var unit: String = cfg.get("unidad", "")
	var udef: Dictionary = sim.dp(player).unidades.get(unit, {})
	if udef.is_empty() or int(p["age"]) < int(udef.get("edad_min", 1)):
		return
	var n := int(cfg.get("guardia_por_turno", 1))
	var pop := int(p["pop"])
	for k in by_type:
		for b: SimEntity in by_type[k]:
			if n <= 0:
				return
			if not b.built or b.queue.size() >= 2 or not (b.def.get("produce", []) as Array).has(unit):
				continue
			pop += int(udef.get("pob", 1))
			if pop > int(p["pop_cap"]):
				return
			var cost := sim.train_cost(player, b, unit)
			if not _sink_affords(p, cost, keep):
				return
			sim.push_command({"t": "train", "player": player, "building": b.id, "type": unit})
			_hold(p, cost, held)
			n -= 1


func _sink_affords(p: Dictionary, cost: Dictionary, keep: Dictionary) -> bool:
	for r in cost:
		if int(p["res"].get(r, 0)) < int(cost[r]) + int(keep.get(r, 0)):
			return false
	return true


## Descuenta `cost` de la vista de este turno y lo anota en `held` (se devuelve con `_reserve`).
func _hold(p: Dictionary, cost: Dictionary, held: Dictionary) -> void:
	for r in cost:
		p["res"][r] = int(p["res"][r]) - int(cost[r])
		held[r] = int(held.get(r, 0)) + int(cost[r])


## --- paso 6 --- Saberes propios (docs/diseno/27, §3; data/civs → ia_propias.orden; reglas.ia_propias):
## en el orden del pueblo, la primera que todavía no compró, que sirve (las condiciones de `_own_ok`),
## que se puede investigar en un edificio suyo y que alcanza con el costo más la reserva (ahorrando
## para el hito o la maravilla, además de lo que pide la meta). Si ninguna alcanza, desde la edad
## `junta_desde_edad` aparta lo que ya tiene para la primera (salvo con la base atacada o ahorrando),
## como los niveles. Una por turno; su costo queda apartado hasta el final del turno.
func _own_buys(p: Dictionary, army: Array[SimEntity], by_type: Dictionary, saving: bool, centro: SimEntity) -> Dictionary:
	var own: Dictionary = sim.dp(player).civ.get("ia_propias", {})
	var cfg: Dictionary = sim.data.reglas.get("ia_propias", {})
	if own.is_empty() or cfg.is_empty() or not level.get("investiga", false):
		return {}
	var techs: Dictionary = sim.dp(player).tecnologias
	# Que se juegue el final (proceso/26-juego-tardio/14): desde `temprana_desde_ms`, las propias de
	# hasta la edad `temprana_edad_max` se compran aunque ahorre para el hito (sin apartar la meta):
	# son baratas y así el rival ve lo propio del pueblo entre el minuto 10 y el 15.
	var early_on: bool = sim.tick * sim.tick_ms >= int(cfg.get("temprana_desde_ms", 1 << 40))
	var no_saving_buys: bool = saving and not own.get("ahorrando", true) # el pueblo no compra saberes mientras ahorra para el hito
	var goal: Dictionary = _goal_cost(p) if saving else {}
	var first: Dictionary = {}
	for item: Dictionary in own.get("orden", []):
		var tech: String = item["tec"]
		if not techs.has(tech) or sim.players[player]["techs"].has(tech) or sim.players[player]["pending"].has(tech):
			continue
		var early: bool = early_on and int(techs[tech].get("edad_min", 1)) <= int(cfg.get("temprana_edad_max", 0))
		if no_saving_buys and not early:
			continue
		if int(p["age"]) < int(techs[tech].get("edad_min", 1)) or not _own_ok(item, army, by_type, centro):
			continue
		var where: SimEntity = null
		for k in by_type:
			for b: SimEntity in by_type[k]:
				if b.built and b.queue.size() < 2 and sim.tech_here(techs[tech], b) and where == null:
					where = b
		if where == null or sim.research_block(player, tech) != "":
			continue
		var cost := sim.tech_cost(player, tech)
		if first.is_empty():
			first = cost
		var ok := true
		for r in cost:
			ok = ok and int(p["res"].get(r, 0)) >= int(cost[r]) + int(cfg.get("reserva", 0)) + (0 if early else int(goal.get(r, 0)))
		if not ok:
			continue
		sim.push_command({"t": "research", "player": player, "building": where.id, "tech": tech})
		var held := {}
		for r in cost:
			held[r] = int(cost[r])
			p["res"][r] = int(p["res"][r]) - int(cost[r])
		return held
	if first.is_empty() or saving or int(p["age"]) < int(cfg.get("junta_desde_edad", 99)) or _threat(centro) != null:
		return {}
	var held_j := {}
	for r in first:
		var take := mini(int(first[r]), int(p["res"].get(r, 0)))
		held_j[r] = take
		p["res"][r] = int(p["res"][r]) - take
	return held_j


## --- paso 6 --- Las condiciones de una compra propia: `tropa` ({lineas, tipos, n}: tanta tropa de
## esas líneas o tipos; sin lista, toda), `granjas` y `corrales` (cuántas terminadas), `agua` (agua a
## 10 casillas de la capital).
func _own_ok(item: Dictionary, army: Array[SimEntity], by_type: Dictionary, centro: SimEntity) -> bool:
	if item.has("tropa"):
		var tr: Dictionary = item["tropa"]
		var lines: Array = tr.get("lineas", [])
		var types: Array = tr.get("tipos", [])
		var n := 0
		for u in army:
			if (lines.is_empty() and types.is_empty()) or lines.has(SimData.line_of(u.def)) or types.has(u.type):
				n += 1
		if n < int(tr["n"]):
			return false
	for k in [["granjas", "granja"], ["corrales", "corral"]]:
		if item.has(k[0]):
			var built := 0
			for b: SimEntity in by_type.get(k[1], []):
				built += 1 if b.built else 0
			if built < int(item[k[0]]):
				return false
	if item.get("agua", false) and not sim._near_water(centro.tx, centro.ty, centro.w, centro.h, 10):
		return false
	return true


## --- paso 6 --- Hoyos con estacas (mapuches): con la mejora comprada, cava de a uno por turno
## hasta `ia_propias.trampas` del pueblo, en un abanico delante del centro hacia el rival
## (reglas.ia_propias: trampas_adelante, trampas_ancho). No mientras ahorra para el hito.
func _dig_traps(p: Dictionary, vill: Array[SimEntity], centro: SimEntity, by_type: Dictionary, saving: bool) -> void:
	var own: Dictionary = sim.dp(player).civ.get("ia_propias", {})
	var cfg: Dictionary = sim.data.reglas.get("ia_propias", {})
	var want := int(own.get("trampas", 0))
	if want <= 0 or saving or vill.is_empty() or not level.get("investiga", false):
		return
	var dd := sim.dp(player)
	var trap := ""
	for k in dd.edificios:
		if dd.edificios[k].has("trampa"):
			trap = k
	if trap == "" or sim.build_block(player, trap) != "" or int(p["age"]) < int(dd.edificios[trap].get("edad_min", 1)):
		return
	var have: int = (by_type.get(trap, []) as Array).size()
	if have >= want or not sim.can_afford(player, sim.build_cost(player, trap)):
		return
	var eb := Vector2i(centro.tx, centro.ty)
	var best := 1 << 60
	for j in mini(sim.players.size(), sim.bases.size()):
		if sim.enemies(player, j):
			var d := Sim.dist(sim.bases[j].x * P, sim.bases[j].y * P, centro.x, centro.y)
			if d < best:
				best = d
				eb = sim.bases[j]
	var c := Vector2i(centro.tx + centro.w / 2, centro.ty + centro.h / 2)
	var dir := Vector2i(signi(eb.x - c.x), signi(eb.y - c.y))
	var ahead := int(cfg.get("trampas_adelante", 8))
	var spread := int(cfg.get("trampas_ancho", 6))
	var side := Vector2i(-dir.y, dir.x)
	var off := (have % maxi(1, spread)) - spread / 2
	var at := c + dir * ahead + side * off * 2
	var site := _site_near(trap, at, 0, 0)
	if site.x >= 0:
		_build_at(trap, site, vill, 1)


## --- paso 3 --- ¿Le sirve a este pueblo? La mejora de una línea que no entrena en ningún
## edificio, no; las del asedio, solo si tiene asedio en el ejército.
func _late_useful(t: Dictionary, army: Array[SimEntity]) -> bool:
	for ef: Dictionary in t.get("efectos", []):
		if ef.has("lineas"):
			var dd := sim.dp(player)
			var made := false
			for b in dd.edificios:
				for l in dd.lines_made_by(dd.edificios[b]):
					made = made or (ef["lineas"] as Array).has(l)
			if not made:
				return false
		if String(ef["tipo"]).begins_with("asedio"):
			var siege := false
			for u in army:
				siege = siege or u.fn == "asedio"
			if not siege:
				return false
	return true


## Campana si el enemigo llega a la base con más tropas que las propias; calma pasado el peligro.
func _alarm(p: Dictionary, vill: Array[SimEntity], army: Array[SimEntity], centro: SimEntity) -> void:
	var enemies := 0
	var defenders := 0
	# Experta (`campana_en_centros`): también en los centros nuevos; antes un ataque al segundo
	# centro mataba a sus aldeanos sin campana (veterano, ronda 6: de 36 a 20 aldeanos).
	var watch: Array[SimEntity] = [centro]
	if level.get("campana_en_centros", false):
		for c in centers:
			if c != centro:
				watch.append(c)
	for c in watch:
		var en := 0
		for e in sim.military():
			if e.alive and e.owner >= 0 and sim.enemies(player, e.owner) and e.is_military() and sim.dist_to(e, c) < 16000:
				en += 1
		var de := 0
		for u in army:
			if sim.dist_to(u, c) < 20000:
				de += 1
		if c == centro or en - de > enemies - defenders:
			enemies = en
			defenders = de
	if enemies > 0:
		calm_since = sim.tick
	if not p["alarm"] and enemies >= 2 and enemies > defenders:
		sim.push_command({"t": "alarm", "player": player, "on": true, "max": enemies * int(level.get("campana_por_enemigo", sim.data.reglas.get("ia_campana_por_enemigo", 3)))})
	elif p["alarm"] and enemies == 0 and sim.tick - calm_since > int(sim.data.reglas.get("ia_campana_calma_ticks", 50)):
		sim.push_command({"t": "alarm", "player": player, "on": false})


## Rendición (la fácil, `rendicion`; proceso/24, 4q): como la IA de AoE4, abandona cuando
## la partida está perdida y así el principiante gana su primera partida sin tener que
## arrasar hasta el último edificio. Se rinde si perdió `edificios_perdidos` edificios
## terminados (sin contar caminos) y todavía tiene tropa enemiga en la base, o si su capital
## quedó en `capital_pct` % de la vida o menos. Las demás dificultades no la tienen.
func _surrenders(by_type: Dictionary, centro: SimEntity) -> bool:
	var cfg: Dictionary = level.get("rendicion", {})
	if cfg.is_empty():
		return false
	var now := {}
	for k in by_type:
		for b: SimEntity in by_type[k]:
			if b.built and not b.def.get("camino", false):
				now[b.id] = true
	for id in _built_ids:
		if not now.has(id):
			var b: SimEntity = sim.by_id.get(id)
			if b == null or not b.alive:
				_lost_buildings += 1
	_built_ids = now
	_peak_built = maxi(_peak_built, now.size())
	var threat := _threat(centro)
	var beaten: bool = _lost_buildings >= int(cfg["edificios_perdidos"]) and threat != null
	# Que se juegue el final (proceso/26-juego-tardio/14): perder casas sueltas en incursiones no
	# alcanza; además le quedan como mucho `quedan_pct` % de los edificios que llegó a tener.
	if beaten and cfg.has("quedan_pct"):
		beaten = now.size() * 100 <= _peak_built * int(cfg["quedan_pct"])
	var capital: SimEntity = null
	for k in by_type:
		for b: SimEntity in by_type[k]:
			if b.capital:
				capital = b
	# --- paso 7 --- Normal, difícil y experta (docs/diseno/27, §4.4.4), con umbrales más duros:
	# además tiene menos de `ejercito_rival_pct` % del mayor ejército rival visto y la capital atacada.
	if beaten and cfg.has("ejercito_rival_pct"):
		beaten = _army_n * 100 < _seen * int(cfg["ejercito_rival_pct"]) and capital != null \
				and Sim.dist(threat.x, threat.y, capital.x, capital.y) <= int(sim.data.reglas["ia_economia"]["amenaza_capital"])
	if cfg.has("capital_pct") and capital != null and capital.hp * 100 <= capital.hp_max * int(cfg["capital_pct"]):
		beaten = true
	if not beaten:
		return false
	sim.push_command({"t": "resign", "player": player, "motivo": "rendicion"})
	return true


# ---------------------------------------------------------------- Economía

func _economy(p: Dictionary, vill: Array[SimEntity], centro: SimEntity, saving: bool) -> void:
	var ratio: Dictionary = (ratio_early if p["age"] < 2 else ratio_late).duplicate()
	# El reparto propio de la dificultad es para alimentar centros: sin centros que entrenen
	# aldeanos (Palmares los suma con la fama), el de siempre.
	if level.has("proporcion_temprana") and _center_type() == "":
		var eco: Dictionary = sim.data.reglas["ia_economia"]
		ratio = (eco["proporcion_temprana"] if p["age"] < 2 else eco["proporcion_tardia"]).duplicate()
	# Ajuste por banco: menos gente en lo que sobra, más en lo que falta para el hito.
	var hito_cost: Dictionary = _goal_cost(p) if saving else {}
	for k in Sim.RES_KINDS:
		if p["res"][k] > 600:
			ratio[k] = ratio[k] / 3
		if hito_cost.has(k) and p["res"][k] < hito_cost[k]:
			ratio[k] += int(level.get("refuerzo_hito", sim.data.reglas["ia_economia"]["refuerzo_hito"]))
		elif saving and k != "madera" and (not hito_cost.has(k) or p["res"][k] >= hito_cost[k]):
			ratio[k] = ratio[k] / 3 # lo que ya alcanza para el hito libera gente para lo que falta
	# Centro siguiente (experta): más gente en lo que falta para pagarlo (la piedra, sobre todo).
	var ec := _expansion_need(p, vill.size(), false)
	for k in ec:
		if ratio.has(k) and int(p["res"][k]) < int(ec[k]):
			ratio[k] += int(level["expansion"]["refuerzo_pct"])
	var counts := {"alimento": 0, "madera": 0, "piedra": 0, "riqueza": 0}
	var idle: Array[SimEntity] = []
	for v in vill:
		if (v.order == O.GATHER or v.order == O.RETURN) and counts.has(v.gather_kind):
			counts[v.gather_kind] += 1
		elif v.order == O.IDLE:
			idle.append(v)
	# Aldeanos virtuales (crítica 03, regla 3): la riqueza que da el motor propio cuenta
	# como gente ya puesta en riqueza, así la IA no carga la arcilla de más.
	var virt := _engine_rate(p) / 30
	counts["riqueza"] += virt
	# Reasignar uno si la proporción está muy desbalanceada.
	if idle.is_empty() and vill.size() >= 8:
		var tot := vill.size() + virt
		var over := _most(counts, ratio, tot, true)
		var under := _most(counts, ratio, tot, false)
		if over != under and counts[over] - tot * ratio[over] / 100 >= 2 and tot * ratio[under] / 100 - counts[under] >= 2:
			for v in vill:
				if v.order == O.GATHER and v.gather_kind == over and v.carry == 0:
					idle.append(v)
					counts[over] -= 1
					break
	for v in idle:
		var kind := _most(counts, ratio, vill.size() + virt + 1, false)
		# Con varios centros (experta), cada aldeano trabaja alrededor del más cercano.
		var home := _home(v, centro)
		# Alimento: primero los animales propios (como AoE4), carneados de a uno.
		if kind == "alimento":
			# Primero la carne abierta; un animal nuevo recién cuando no queda (una llama por vez).
			var meat := sim.find_resource(player, "alimento", centro.x, centro.y, int(sim.data.reglas["animales"]["cadena_radio"]) * 2, -1, v.id, "carne")
			var beast: SimEntity = meat if meat != null else _own_animal(centro)
			if beast != null:
				sim.push_command({"t": "target", "player": player, "ids": [v.id], "target": beast.id})
				counts[kind] += 1
				continue
		var t := sim.find_resource(player, kind, home.x, home.y, 40000, -1, v.id)
		# Alimento lejos de todo almacén (venados, animales sueltos del medio): como en AoE4,
		# cuando se acaba lo cercano conviene pasar a las granjas antes que caminar (la edad III
		# se atrasaba hasta 25 minutos; proceso/23, paso 10).
		if t != null and kind == "alimento" and not t.is_building():
			var drop := sim.nearest_dropoff(player, kind, t.x, t.y)
			if drop == null or sim.dist_to(t, drop) > int(sim.data.reglas["ia_economia"]["alimento_lejos"]):
				t = null
		if t == null and kind == "alimento":
			if sim.can_afford(player, sim.dp(player).cost_of("granja", p["age"])):
				var site := _farm_site(home)
				if site.x >= 0:
					sim.push_command({"t": "build", "player": player, "ids": [v.id], "type": "granja", "tx": site.x, "ty": site.y})
					counts[kind] += 1
					continue
			kind = "madera"
			t = sim.find_resource(player, kind, home.x, home.y, 60000, -1, v.id)
		if t == null:
			for k in Sim.RES_KINDS:
				t = sim.find_resource(player, k, v.x, v.y, 60000, -1, v.id)
				if t != null:
					kind = k
					break
		if t != null:
			sim.push_command({"t": "target", "player": player, "ids": [v.id], "target": t.id})
			counts[kind] += 1


## El centro desde el que trabaja `v`: la capital, salvo que la dificultad se expanda
## (`expansion`) y haya otro centro más cerca.
func _home(v: SimEntity, centro: SimEntity) -> SimEntity:
	if centers.size() < 2 or not level.has("expansion"):
		return centro
	var best := centro
	var best_d := Sim.dist(v.x, v.y, centro.x, centro.y)
	for c in centers:
		var d := Sim.dist(v.x, v.y, c.x, c.y)
		if d < best_d:
			best = c
			best_d = d
	return best


func _most(counts: Dictionary, ratio: Dictionary, total: int, over: bool) -> String:
	var best := "alimento"
	var best_v: int = -(1 << 40)
	for k in Sim.RES_KINDS:
		var diff: int = (counts[k] * 100 - total * ratio[k]) if over else (total * ratio[k] - counts[k] * 100)
		if diff > best_v:
			best_v = diff
			best = k
	return best


# ---------------------------------------------------------------- Construcción

## `extra` suma recursos que todavía no están en el banco (el kawiñ mapuche); con `strict`,
## un recurso por debajo de la mitad es un no (sin el ahorro intermitente).
func _wants_hito(p: Dictionary, n_vill: int, by_type: Dictionary, extra: Dictionary = {}, strict: bool = false) -> bool:
	if p["age"] >= sim.dp(player).edades.size() or sim.hito_in_progress(player) or p["age"] >= int(level.get("edad_max", 99)):
		return false
	var need: int = 13 + 8 * (int(p["age"]) - 1)
	if p["age"] >= 2 and not by_type.has("cuartel"):
		return false
	if n_vill < need:
		return false
	# En la edad I se ahorra apenas hay aldeanos suficientes, como en AoE: el avance
	# a la II es la prioridad (compuerta de la etapa 1: edad II entre 6:30 y 9:00).
	if p["age"] == 1:
		return true
	# --- paso 7 --- Hacia la IV: con la economía y el ejército hechos y sin un rival mucho más
	# fuerte a la vista, el hito va primero (reglas.ia_edad_iv).
	if not strict and _wants_up(p, n_vill):
		return true
	# Experta (`ahorro_con_minimo`): con el ejército mínimo de la edad hecho, el hito va primero,
	# sin el ahorro intermitente (la edad III llegaba a los 15–20 minutos o nunca; veterano, ronda 6).
	if not strict and (level.get("ahorro_continuo", false) or level.get("ahorro_con_minimo", false) and _army_n >= _min_army(p)):
		return true
	# Después, solo si el hito está al alcance: cada recurso cubre al menos la mitad.
	var cost: Dictionary = sim.dp(player).cost_of(_hito_type(p), p["age"])
	for k in cost:
		if (int(p["res"][k]) + int(extra.get(k, 0))) * 2 < int(cost[k]):
			return false if strict else sim.tick % 1200 < 400 # ahorro intermitente para no congelar el ejército
	return true


## Motor propio de cada civ (docs/diseno/revision-economia/v3/04, §9.3).
func _engine(p: Dictionary, vill: Array[SimEntity], centro: SimEntity, by_type: Dictionary, saving: bool) -> void:
	if sim.tick - last_engine < 50:
		return
	last_engine = sim.tick
	var dd := sim.dp(player)
	match dd.clave:
		"guaranies":
			# Quemar (roza otra vez, sin yerbal) solo si falta alimento para el próximo hito.
			var need := int(dd.cost_of(_hito_type(p), p["age"]).get("alimento", 0)) if p["age"] < dd.edades.size() else 0
			var mode := "quemar" if saving and int(p["res"]["alimento"]) < need else "crecer"
			if str(p.get("modo_monte", "crecer")) != mode:
				sim.push_command({"t": "modo_monte", "player": player, "modo": mode})
			# Rozas para la gente del alimento: las que se agotan pasan a yerbal o capuera.
			# Una roza nueva solo si hay gente del alimento sin roza y el alimento no sobra.
			var food_people := 0
			for v in vill:
				if v.gather_kind == "alimento" and (v.order == O.GATHER or v.order == O.RETURN or v.order == O.IDLE):
					food_people += 1
			var rozas: int = (by_type.get("granja", []) as Array).size()
			if rozas < food_people and int(p["res"]["alimento"]) < 600 and int(p["res"]["madera"]) >= int(dd.cost_of("granja", p["age"]).get("madera", 0)) + 30:
				_try_build("granja", p, vill, centro, 1)
		"ayutthaya":
			_elephants(p, vill, centro)
		"etiopia":
			_found_court(p, vill, centro, by_type)
		"mapuches":
			if p["age"] >= dd.edades.size():
				return
			var need := int(dd.cost_of(_hito_type(p), p["age"]).get("alimento", 0))
			var food := int(p["res"]["alimento"])
			var feasts: Array[SimEntity] = []
			for c: SimEntity in by_type.get("corral", []):
				if c.built and c.heads >= 4 and c.feast_age != int(p["age"]):
					feasts.append(c)
			if feasts.is_empty():
				return
			# Los más llenos primero (a igual cabezas, el más viejo: determinista).
			feasts.sort_custom(func(a: SimEntity, b: SimEntity) -> bool: return a.heads > b.heads or a.heads == b.heads and a.id < b.id)
			var best: SimEntity = feasts[0]
			# Desde la edad II el ejército (alimento y riqueza, y la riqueza sobra por el ganado)
			# se come el alimento apenas llega, y nunca se junta la mitad del hito: la IA no entraba
			# en el ahorro y llegaba a la edad III a las ~20 min (proceso/24, 3b). Si la fiesta de
			# los corrales más llenos (`ia_economia.kawin_corrales`) completa esa mitad, se hace:
			# el ganado se vuelve el alimento que destraba el ahorro.
			feasts.resize(mini(feasts.size(), int(sim.data.reglas["ia_economia"]["kawin_corrales"])))
			var gain := 0
			for c in feasts:
				gain += (c.heads - 1) * int(c.def["ganado"]["fiesta_alimento"])
			if p["age"] >= 2 and food * 2 < need and _wants_hito(p, vill.size(), by_type, {"alimento": gain}, true):
				for c in feasts:
					sim.push_command({"t": "kawin", "player": player, "building": c.id})
			# Ahorrando, el corral más lleno si con él casi alcanza, una vez por edad.
			elif saving and food < need and food + (best.heads - 1) * int(best.def["ganado"]["fiesta_alimento"]) >= need - 100:
				sim.push_command({"t": "kawin", "player": player, "building": best.id})
		"palmares":
			# Guarda fama para el hito solo mientras ahorra para él; si no, la gente sigue llegando.
			if bool(p.get("guardar_fama", true)) != saving:
				sim.push_command({"t": "guardar", "player": player, "res": "fama", "on": saving})
			# La gente que llega por la fama respeta el tope de aldeanos de la dificultad, como
			# los centros de las otras civs. Cuentan también los guarecidos; los de los oficios
			# no (son el motor, como los aldeanos virtuales de las otras civs).
			var people := 0
			for e in sim.owned(player):
				if e.alive and e.owner == player:
					if e.is_unit() and e.fn == "civil":
						people += 1
					elif e.is_building():
						people -= e.crafts.size()
			var welcome := people < max_villagers
			if bool(p.get("acogida_pausa", false)) == welcome:
				sim.push_command({"t": "acoger", "player": player, "on": welcome})
		"tawantinsuyu":
			var want_res := 60 if saving else 0
			if int(p.get("reserva_mita", 0)) != want_res:
				sim.push_command({"t": "reserve", "player": player, "res": "mita", "n": want_res})
			# Regalo de cumbi en la edad III, si sobra mit'a por encima de la reserva.
			if dd.has_mod("regalo_cumbi") and int(p["age"]) >= int(dd.mod("regalo_cumbi").get("edad", 3)) and int(p["res"]["mita"]) >= int(dd.mod("regalo_cumbi")["costo"]) + 60 and sim.mods.cumbi_target(player) != null:
				sim.push_command({"t": "cumbi", "player": player})
			var shops: Array = by_type.get("taller_tejido", [])
			# En la edad I, un solo taller antes del hito II (aunque se esté ahorrando: rinde riqueza para el hito).
			if vill.size() < 10 or not dd.edificios.has("taller_tejido") or (p["age"] == 1 and shops.size() >= 1):
				return
			var cfg: Dictionary = dd.mod("recurso_propio")
			var by_age: Array = cfg.get("por_aldeano_por_edad", [cfg.get("por_aldeano", 4)])
			var income := vill.size() * int(by_age[clampi(int(p["age"]) - 1, 0, by_age.size() - 1)])
			var cost: Dictionary = dd.cost_of("taller_tejido", p["age"])
			if income - 30 * shops.size() >= 30 and int(p["res"]["madera"]) >= int(cost.get("madera", 0)) + 60:
				_try_build("taller_tejido", p, vill, centro, 1)


## Corte etíope (§9.3): cuando a la arcilla junto a la corte le quedan menos de 100,
## fundar la corte junto a la arcilla propia con más riqueza (o la del centro desde la III).
func _found_court(p: Dictionary, vill: Array[SimEntity], centro: SimEntity, by_type: Dictionary) -> void:
	var dd := sim.dp(player)
	if not dd.edificios.has("corte_nueva") or by_type.has("corte_nueva") or by_type.has("gondar") or vill.is_empty():
		return
	if not sim.can_afford(player, dd.cost_of("corte_nueva", p["age"])):
		return
	var near_left := 0
	var best: SimEntity = null
	for t in sim.entities:
		if not (t.alive and t.is_resource() and t.type == "riqueza" and t.amount > 0):
			continue
		var d := Sim.dist(t.x, t.y, centro.x, centro.y)
		if d <= 14000 and (t.res_owner == player or t.res_owner < 0):
			near_left += t.amount
		var ok_owner := t.res_owner == player or (t.res_owner < 0 and int(p["age"]) >= 3)
		if ok_owner and d > 14000 and t.amount >= 300 and (best == null or t.amount > best.amount or (t.amount == best.amount and t.id < best.id)):
			best = t
	if near_left >= 100 or best == null:
		return
	for r in range(5, 9):
		for dy in range(-r, r + 1):
			for dx in range(-r, r + 1):
				if absi(dx) != r and absi(dy) != r:
					continue
				var tx := best.tx + dx
				var ty := best.ty + dy
				if sim.can_place("corte_nueva", tx, ty, player):
					var v := _nearest_villager(vill, tx * P, ty * P)
					sim.push_command({"t": "build", "player": player, "ids": [v.id], "type": "corte_nueva", "tx": tx, "ty": ty})
					return


## Elefantes del rey (§9.3): entrenar hasta el máximo de la edad y llevar cada uno
## junto a su grupo de aldeanos: el 1.º a la madera, el 2.º al alimento, el 3.º a la piedra.
func _elephants(p: Dictionary, vill: Array[SimEntity], centro: SimEntity) -> void:
	var dd := sim.dp(player)
	if not dd.unidades.has("elefante_rey"):
		return
	var eles: Array[SimEntity] = []
	for e in sim.owned(player):
		if e.alive and e.owner == player and e.type == "elefante_rey":
			eles.append(e)
	var maxes: Array = dd.unidades["elefante_rey"]["maximo_por_edad"]
	var want := int(maxes[clampi(int(p["age"]) - 1, 0, maxes.size() - 1)]) + sim.mods.engine_max_bonus(player, "elefante_rey")
	var queued := 0
	for q in centro.queue:
		if q == "elefante_rey":
			queued += 1
	if eles.size() + queued < want and centro.queue.size() < 2 and vill.size() >= 8 and sim.can_afford(player, dd.cost_of("elefante_rey", p["age"])):
		sim.push_command({"t": "train", "player": player, "building": centro.id, "type": "elefante_rey"})
	if sim.tick - last_elephant < 300:
		return
	last_elephant = sim.tick
	var kinds := ["madera", "alimento", "piedra"]
	for i in eles.size():
		var kind: String = kinds[mini(i, kinds.size() - 1)]
		var sx := 0
		var sy := 0
		var n := 0
		for v in vill:
			if v.gather_kind == kind and (v.order == O.GATHER or v.order == O.RETURN):
				var t: SimEntity = sim.by_id.get(v.target)
				if t != null:
					sx += t.x
					sy += t.y
					n += 1
		if n < 2:
			continue
		var tx := sx / n
		var ty := sy / n
		var el := eles[i]
		if Sim.dist(el.x, el.y, tx, ty) > int(sim.data.reglas["ia_economia"]["elefante_cerca"]) and el.order == O.IDLE:
			sim.push_command({"t": "move", "player": player, "ids": [el.id], "x": tx, "y": ty})


## Riqueza por minuto del motor propio (último minuto), según el libro de ingresos.
func _engine_rate(p: Dictionary) -> int:
	var now := int(p["stats"].get("origen", {}).get("propio", {}).get("riqueza", 0))
	if sim.tick - _eng_mark_tick >= 600:
		_eng_rate = maxi(0, now - _eng_mark_val) * 600 / maxi(1, sim.tick - _eng_mark_tick)
		_eng_mark_tick = sim.tick
		_eng_mark_val = now
	return _eng_rate


## Reserva del próximo hito: no gastar un recurso propio (mit'a, fama, kulliñ)
## por debajo de lo que pide el hito siguiente (crítica 03, regla 2).
func _keeps_reserve(p: Dictionary, cost: Dictionary) -> bool:
	if p["age"] >= sim.dp(player).edades.size():
		return true
	var need: Dictionary = sim.dp(player).cost_of(_hito_type(p), p["age"])
	for k in cost:
		if k in Sim.RES_KINDS or not need.has(k):
			continue
		if int(p["res"].get(k, 0)) - int(cost[k]) < int(need[k]):
			return false
	return true


func _buildings(p: Dictionary, vill: Array[SimEntity], centro: SimEntity, by_type: Dictionary, saving: bool) -> void:
	if vill.is_empty():
		return
	var unbuilt := {}
	var houses_unbuilt := 0
	for k in by_type:
		for b: SimEntity in by_type[k]:
			if not b.built:
				unbuilt[k] = true
				if k == "casa":
					houses_unbuilt += 1
	# Casas. Con más de un centro (experta) se produce más rápido: más margen por cada centro
	# extra y más de una casa a la vez. Con uno solo, como siempre (la madera va al cuartel).
	var extra := maxi(0, centers.size() - 1)
	var margin: int = 3 + (by_type.get("cuartel", []) as Array).size() * 2 + int(level.get("casas_margen_por_centro", 0)) * extra
	var at_once: int = int(level.get("casas_a_la_vez", 1)) if extra > 0 else 1
	if p["pop_cap"] < sim.data.reglas["pob_max"] and p["pop_cap"] - p["pop"] <= margin and houses_unbuilt < at_once:
		_try_build("casa", p, vill, centro, 1)
	# Expansión (experta): segundo y tercer centro, aunque se esté ahorrando para el hito.
	_expand(p, vill, centro, by_type, saving, unbuilt)
	# Hito.
	if saving and sim.can_afford(player, _goal_cost(p)):
		_try_build(_goal, p, vill, centro, _goal_builders())
		return
	_center_towers(p, vill, by_type, unbuilt)
	# Juntando para el centro, lo demás espera (como con el mercado): si no, la madera se va
	# siempre antes en granjas, cuarteles y almacenes (Ayutthaya con 1 centro a los 25 minutos).
	if not _holding.is_empty():
		return
	# Edificio principal de producción: el de la unidad preferida de la civ (el färäs bet
	# etíope, la warak'a kancha inca) o el cuartel. Es el que se multiplica cuando sobra.
	var main := _main_producer()
	var n_cuartel: int = by_type.get(main, []).size()
	var rich: bool = p["res"]["alimento"] > 800 and p["res"]["madera"] > 300 and n_cuartel < int(level.get("productores_max", 5))
	# El segundo principal, recién cuando hay uno de cada uno de los otros (si no, los
	# guaraníes levantaban dos casas del arco y ningún cuartel).
	var others_missing := false
	if p["age"] >= 2:
		for t in _producer_types() + (["cuartel"] if main != "cuartel" else []):
			if t != main and by_type.get(t, []).is_empty() and p["age"] >= int(sim.dp(player).edificios[t].get("edad_min", 1)):
				others_missing = true
	if (n_cuartel == 0 and vill.size() >= 11) or (not others_missing and ((n_cuartel == 1 and p["age"] >= 2 and vill.size() >= 24) or rich)):
		if not unbuilt.has(main) and p["age"] >= int(sim.dp(player).edificios[main].get("edad_min", 1)):
			_try_build(main, p, vill, centro, 2)
	# El edificio de la unidad preferida de la civ (`ia_unidades`: el jinete noble etíope sale
	# del färäs bet) va tan temprano como el primer cuartel.
	if vill.size() >= 11:
		var pref: Array = sim.dp(player).civ.get("ia_unidades", [])
		for t in _producer_types():
			if by_type.get(t, []).size() > 0 or unbuilt.has(t) or p["age"] < int(sim.dp(player).edificios[t].get("edad_min", 1)):
				continue
			var makes: Array = sim.dp(player).edificios[t].get("produce", [])
			var wanted_unit := false
			for u in pref:
				if makes.has(u):
					wanted_unit = true
			if wanted_unit:
				_try_build(t, p, vill, centro, 2)
				break
	# Los demás edificios de producción (campo de tiro, corral de guerra, taller…): uno de cada
	# uno después del primer cuartel; más si sobra (proceso/21, paso 10).
	# Desde la edad II: antes, la madera y el alimento van al hito (salud de la IA: Ayutthaya
	# llegaba a la II a las 10:52 por levantar campo de tiro y taller antes).
	if n_cuartel >= 1 and vill.size() >= 14 and p["age"] >= 2:
		for t in _producer_types() + (["cuartel"] if main != "cuartel" else []):
			if t == main:
				continue
			var have: int = by_type.get(t, []).size()
			if unbuilt.has(t) or p["age"] < int(sim.dp(player).edificios[t].get("edad_min", 1)):
				continue
			if have == 0 or (rich and have < 2):
				_try_build(t, p, vill, centro, 2)
				break
	# Almacenes junto a los recursos lejanos: el de ese recurso (leñera, granero, barrero…),
	# según los que tenga la civ (proceso/21). Sin almacén para ese recurso, nada: lo cubren
	# sus edificios propios (lof, mocambo, elefante).
	# Primero el recurso con más aldeanos lejos (proceso/24, paso 1b: la madera quedaba sin
	# almacén cuando el alimento lejano iba primero y no se podía construir). Cuentan solo
	# los almacenes que todavía tienen ese recurso cerca: el bosque se agota y se corre.
	var eco: Dictionary = sim.data.reglas["ia_economia"]
	_track_stores(by_type, eco)
	var order := []
	for kind in ["alimento", "madera", "riqueza", "piedra"]:
		var far_n := _far_gatherers(vill, kind)
		if far_n.size() >= 3:
			order.append([far_n.size(), kind, far_n])
	order.sort_custom(func(a, b): return a[0] > b[0] or a[0] == b[0] and a[1] < b[1])
	for o in order:
		var kind: String = o[1]
		var dtype := _dropsite_for(kind)
		if dtype == "" or unbuilt.has(dtype):
			continue
		# Un lof o un mocambo como almacén también es un edificio que entrena tropa: tope más bajo.
		var alt: bool = sim.dp(player).edificios.get(dtype, {}).has("produce")
		var all_n: int = (by_type.get(dtype, []) as Array).size()
		if alt and all_n >= int(eco["almacen_alternativo_cantidad"]) or all_n >= int(eco["almacen_max"]):
			continue
		if not alt and _useful_stores(by_type.get(dtype, []), kind) >= int(eco["almacen_utiles"]):
			continue
		var far: SimEntity = o[2][o[2].size() / 2]
		var site := _site_near(dtype, Vector2i(far.x / P, far.y / P), 1)
		if site.x < 0 or _store_lost_near(site, eco):
			continue
		# Si no alcanza, se espera (no se gasta en otro almacén menos urgente).
		if sim.can_afford(player, sim.dp(player).cost_of(dtype, p["age"])):
			sim.push_command({"t": "build", "player": player, "ids": [_nearest_villager(vill, far.x, far.y).id], "type": dtype, "tx": site.x, "ty": site.y})
		break
	# Edificios propios de la civilización (corral, gult, mocambo, kraal...), uno por paso.
	var wanted := {}
	for t: String in sim.dp(player).civ.get("ia_edificios", []):
		wanted[t] = int(wanted.get(t, 0)) + 1
	for t: String in wanted:
		var have: int = (by_type.get(t, []) as Array).size()
		var def: Dictionary = sim.dp(player).edificios.get(t, {})
		# Piezas de motor: hasta el máximo de la edad (y no la lista fija de los datos).
		if def.has("maximo_por_edad"):
			var maxes: Array = def["maximo_por_edad"]
			wanted[t] = int(maxes[clampi(int(p["age"]) - 1, 0, maxes.size() - 1)]) + sim.mods.engine_max_bonus(player, t)
		if have < int(wanted[t]) and not unbuilt.has(t) and int(def.get("edad_min", 1)) <= p["age"] and vill.size() >= 10 + have * (3 if def.has("maximo_por_edad") else 6):
			_try_build(t, p, vill, centro, 2)
			break
	# Mercado desde la edad II, después de producción, almacenes y edificios propios: con todo
	# separado la madera no alcanza, y sin mercado la IA no cambia la riqueza que le sobra por lo
	# que le falta (proceso/21, pasos 13 y 17). Si no le alcanza, guarda la madera: lo que sigue
	# (caminos, torre) espera.
	if p["age"] >= 2 and not by_type.has("mercado") and not unbuilt.has("mercado") and vill.size() >= 20:
		_try_build("mercado", p, vill, centro, 2)
		# Sin plata para el mercado, la madera se guarda: si no, granjas y almacenes se la llevan
		# siempre antes (salud de la IA: Etiopía y Palmares sin mercado al minuto 15).
		var mcost: Dictionary = sim.dp(player).cost_of("mercado", p["age"])
		if not sim.can_afford(player, mcost):
			return
	# Caminos (módulo caminos): une a la capital el primer edificio desconectado.
	# La fácil no tiende caminos (`caminos: false`): el tramo es un edificio y la tropa del
	# principiante en ataque en movimiento se quedaba pegándole (proceso/24, 4q).
	if sim.dp(player).has_mod("caminos") and level.get("caminos", true) and sim.tick - last_road >= 200 and not unbuilt.has("camino"):
		last_road = sim.tick
		for k in by_type:
			if k == "camino":
				continue
			for bb: SimEntity in by_type[k]:
				if bb.built and not bb.capital and not sim.mods.connected(bb) and sim.tick >= int(_no_route.get(bb.id, 0)):
					var tiles := _road_tiles(bb, centro)
					if not tiles.is_empty():
						var v := _nearest_villager(vill, bb.x, bb.y)
						sim.push_command({"t": "build_line", "player": player, "ids": [v.id], "type": "camino", "tiles": tiles})
						return
					_no_route[bb.id] = sim.tick + 1200 # sin paso: se reintenta en 2 minutos
					sim.tele.add(sim.tick, "ia_sin_ruta", player, bb.tx, bb.ty, {"tipo": bb.type}, "isr:%d" % bb.id, 1200)
	if not saving:
		_fortress(p, vill, centro, by_type, unbuilt) # --- paso 4 --- (ahorrando para el hito, no)
	_wall(p, vill, centro, by_type, saving) # --- muralla ---
	# Torre (la fácil, ninguna: `torres_max`; proceso/24, 4q).
	if p["age"] >= 2 and sim.dp(player).edificios.has("torre") and by_type.get("torre", []).size() < int(level.get("torres_max", 1)) and p["res"]["piedra"] >= 250 and not (saving and _goal_is_wonder()): # --- paso 7 --- la piedra de la maravilla
		_try_build("torre", p, vill, centro, 1)


## Experta (`torre_por_centro`): una torre junto a cada centro nuevo, del lado del rival, como
## el jugador de AoE4 que hace boom (veterano, ronda 6). Solo con la piedra que sobra después
## de lo que pide el hito siguiente.
func _center_towers(p: Dictionary, vill: Array[SimEntity], by_type: Dictionary, unbuilt: Dictionary) -> void:
	var cfg: Dictionary = level.get("torre_por_centro", {})
	if cfg.is_empty() or p["age"] < 2 or unbuilt.has("torre") or not sim.dp(player).edificios.has("torre"):
		return
	if p["age"] < int(sim.dp(player).edificios["torre"].get("edad_min", 1)):
		return
	var cost: Dictionary = sim.dp(player).cost_of("torre", p["age"])
	var keep: Dictionary = sim.dp(player).cost_of(_hito_type(p), p["age"]) if p["age"] < sim.dp(player).edades.size() and not sim.hito_in_progress(player) else {}
	for k in cost:
		if int(p["res"].get(k, 0)) < int(cost[k]) + int(keep.get(k, 0)):
			return
	var r := int(cfg["radio"])
	for c in centers:
		if c.capital:
			continue
		var has := false
		for t: SimEntity in by_type.get("torre", []):
			if Sim.dist(t.x, t.y, c.x, c.y) <= r:
				has = true
				break
		if has:
			continue
		# Del lado de la base rival más cercana.
		var eb := Vector2i(c.tx, c.ty)
		var best := 1 << 60
		for j in mini(sim.players.size(), sim.bases.size()):
			if sim.enemies(player, j):
				var d := Sim.dist(sim.bases[j].x * P, sim.bases[j].y * P, c.x, c.y)
				if d < best:
					best = d
					eb = sim.bases[j]
		var off := int(cfg["adelante"])
		var at := Vector2i(c.tx + c.w / 2 + signi(eb.x - c.tx) * off, c.ty + c.h / 2 + signi(eb.y - c.ty) * off)
		var site := _site_near("torre", at, 1)
		if site.x >= 0:
			_build_at("torre", site, vill, int(cfg["constructores"]))
		return


## El ejército mínimo de la edad (`ejercito_minimo_ahorrando`) y, en la experta
## (`ejercito_segun_rival`), al menos `pct` % del mayor ejército rival visto en los últimos
## `memoria_ticks` (hasta `tope`): si ve venir un ejército grande, no se queda con el mínimo.
func _min_army(p: Dictionary) -> int:
	var mins: Array = level.get("ejercito_minimo_ahorrando", sim.data.reglas["ia_economia"]["ejercito_minimo_ahorrando"])
	var n := int(mins[clampi(int(p["age"]) - 1, 0, mins.size() - 1)])
	var cfg: Dictionary = level.get("ejercito_segun_rival", {})
	if not cfg.is_empty() and sim.tick - _seen_tick <= int(cfg["memoria_ticks"]):
		n = maxi(n, mini(_seen * int(cfg["pct"]) / 100, int(cfg["tope"])))
	return n


## Cuenta el ejército rival a la vista (con la niebla de la IA: lo que ven sus unidades y
## edificios) y recuerda el mayor (`ejercito_segun_rival`).
func _watch_rival_army() -> void:
	var cfg: Dictionary = level.get("ejercito_segun_rival", {})
	if cfg.is_empty() and level.get("sube_a_la_iv", false): # --- paso 7 --- mira al rival antes de subir
		cfg = sim.data.reglas.get("ia_edad_iv", {})
	if cfg.is_empty():
		return
	var n := 0
	for e in sim.military():
		if e.alive and e.owner >= 0 and e.is_unit() and e.is_military() and sim.enemies(player, e.owner) and sim.fog.is_visible(player, e):
			n += 1
	if n >= _seen or sim.tick - _seen_tick > int(cfg["memoria_ticks"]):
		_seen = n
		_seen_tick = sim.tick


## Almacenes perdidos: los que estaban en la pensada anterior y ya no están (rotos por el
## rival). La IA los volvía a levantar en el mismo lugar sin fin: 55 graneros en 20 minutos
## junto a los venados del medio (veterano, ronda 3; proceso/24, paso 4f).
func _track_stores(by_type: Dictionary, eco: Dictionary) -> void:
	var types := {}
	for kind in ["alimento", "madera", "riqueza", "piedra"]:
		var t := _dropsite_for(kind)
		if t != "":
			types[t] = true
	var now := {}
	for t in types:
		for b: SimEntity in by_type.get(t, []):
			now[b.id] = Vector2i(b.tx, b.ty)
	for id in _stores:
		if not now.has(id):
			_stores_lost.append([_stores[id], sim.tick])
	_stores = now
	var wait := int(eco["almacen_perdido_espera_ticks"])
	while not _stores_lost.is_empty() and sim.tick - int(_stores_lost[0][1]) > wait:
		_stores_lost.pop_front()


## Si cerca de `site` se perdieron `almacen_perdido_max` almacenes o más en la espera, no se
## vuelve a construir ahí.
func _store_lost_near(site: Vector2i, eco: Dictionary) -> bool:
	var r := int(eco["almacen_perdido_radio"])
	var n := 0
	for l in _stores_lost:
		var t: Vector2i = l[0]
		if absi(t.x - site.x) <= r and absi(t.y - site.y) <= r:
			n += 1
	return n >= int(eco["almacen_perdido_max"])


func _main_producer() -> String:
	var pref: Array = sim.dp(player).civ.get("ia_unidades", [])
	if not pref.is_empty():
		for t in _producer_types():
			if (sim.dp(player).edificios[t].get("produce", []) as Array).has(pref[0]):
				return t
	return "cuartel"


## Edificios de producción militar de la civ, además del cuartel y de los que ya levanta
## por `ia_edificios` (lof, mocambo, corral…).
func _producer_types() -> Array[String]:
	var dd := sim.dp(player)
	var own: Array = dd.civ.get("ia_edificios", [])
	var out: Array[String] = []
	for t in dd.unidades.get("aldeano", {}).get("construye", []):
		if t == "cuartel" or own.has(t):
			continue
		var def: Dictionary = dd.edificios.get(t, {})
		if def.is_empty() or def.get("avanza_edad", false) or def.has("pob"):
			continue
		for u in def.get("produce", []):
			if dd.unidades.get(u, {}).get("funcion", "") in ["choque", "distancia", "linea", "asedio"]:
				out.append(t)
				break
	return out


## El almacén más barato de la civ que recibe `kind`. Primero los almacenes puros; si la civ
## no tiene (mapuches, la madera de Palmares), su edificio barato que también recibe (lof,
## mocambo), hasta `ia_economia.almacen_alternativo_max`. Nunca un centro ni un hito.
func _dropsite_for(kind: String) -> String:
	var dd := sim.dp(player)
	var alt_max := int(sim.data.reglas["ia_economia"]["almacen_alternativo_max"])
	for pure in [true, false]:
		var best := ""
		var best_cost := 1 << 30
		for t in dd.unidades.get("aldeano", {}).get("construye", []):
			var def: Dictionary = dd.edificios.get(t, {})
			if def.is_empty() or not (def.get("deposito", []) as Array).has(kind) or def.get("avanza_edad", false):
				continue
			if pure and (def.has("pob") or def.has("produce")):
				continue
			var c := 0
			for k in dd.cost_of(t, 1):
				c += int(dd.cost_of(t, 1)[k])
			if not pure and c > alt_max:
				continue
			if c < best_cost:
				best_cost = c
				best = t
		if best != "":
			return best
	return ""


## Recursos que trabajan los aldeanos de `kind` lejos de todo depósito.
func _far_gatherers(vill: Array[SimEntity], kind: String) -> Array:
	var far := []
	var lim := int(sim.data.reglas["ia_economia"]["almacen_lejos"])
	# Los depósitos de `kind` se juntan una vez (con 100 aldeanos, `Sim.nearest_dropoff` por
	# aldeano recorría todas las entidades cien veces por pensada). Mismo filtro, mismo orden y
	# mismo desempate que `Sim.nearest_dropoff`: el resultado no cambia.
	var drops: Array[SimEntity] = []
	for b in sim.owned(player):
		if not b.alive or b.owner != player:
			continue
		if b.is_unit():
			if (b.def.get("deposito", []) as Array).has(kind) and b.inside < 0:
				drops.append(b)
		elif b.is_building() and b.built and (b.def.get("deposito", []) as Array).has(kind):
			drops.append(b)
	var probe := SimEntity.new()
	for v in vill:
		if v.order == O.GATHER and v.gather_kind == kind:
			var t: SimEntity = sim.by_id.get(v.target)
			if t == null or t.is_building():
				continue
			probe.x = t.x
			probe.y = t.y
			var d: SimEntity = null
			var best_d := 1 << 60
			for b in drops:
				var dd := sim.dist_to(probe, b)
				if dd < best_d or (dd == best_d and d != null and b.id < d.id):
					d = b
					best_d = dd
			if d == null or sim.dist_to(t, d) > lim:
				far.append(t)
	return far


## Almacenes con recursos de `kind` todavía cerca (los de un bosque agotado no cuentan).
func _useful_stores(stores: Array, kind: String) -> int:
	var n := 0
	var lim := int(sim.data.reglas["ia_economia"]["almacen_lejos"])
	for b: SimEntity in stores:
		if b.built and sim.find_resource(player, kind, b.x, b.y, lim, -1, -1) != null:
			n += 1
	return n


func _try_build(type: String, p: Dictionary, vill: Array[SimEntity], centro: SimEntity, workers: int) -> void:
	if not sim.can_afford(player, sim.dp(player).cost_of(type, p["age"])):
		return
	var site := _site(type, centro, 1)
	if site.x < 0:
		return
	_build_at(type, site, vill, workers)


## Manda a construir `type` en `site` a los `workers` aldeanos libres más cercanos.
func _build_at(type: String, site: Vector2i, vill: Array[SimEntity], workers: int) -> void:
	var ids := []
	var used := {}
	for i in workers:
		var best: SimEntity = null
		var best_d := 1 << 60
		for v in vill:
			if used.has(v.id) or v.order == O.BUILD or v.carry > 4:
				continue
			var d := Sim.dist(v.x, v.y, site.x * P, site.y * P)
			if d < best_d:
				best = v
				best_d = d
		if best == null:
			break
		used[best.id] = true
		ids.append(best.id)
	if ids.is_empty():
		return
	sim.push_command({"t": "build", "player": player, "ids": ids, "type": type, "tx": site.x, "ty": site.y})


## Expansión como en AoE4 (dificultad experta, `dificultades.<nivel>.expansion`): un segundo
## centro, y un tercero si hay lugar, junto a la riqueza, la piedra o el bosque, de este lado
## del mapa. Los mapuches se expanden con lofs (su centro). Los centros nuevos entrenan aldeanos
## y reciben todos los recursos; los aldeanos trabajan alrededor del más cercano (`_home`).
func _expand(p: Dictionary, vill: Array[SimEntity], centro: SimEntity, by_type: Dictionary, saving: bool, unbuilt: Dictionary) -> void:
	var cfg: Dictionary = level.get("expansion", {})
	if cfg.is_empty():
		return
	var ctype := _center_type()
	if ctype == "" or unbuilt.has(ctype):
		_holding = {}
		return
	# Ahorrando, el centro no toca lo que pide el hito (la piedra de la edad III).
	var need := _expansion_need(p, vill.size(), saving)
	_holding = {}
	if need.is_empty():
		return
	var short := false
	var start := true
	for k in need:
		if int(p["res"].get(k, 0)) < int(need[k]):
			short = true
		if int(p["res"].get(k, 0)) * 100 < int(need[k]) * int(cfg["junta_desde_pct"]):
			start = false
	if short:
		# Con `junta_desde_pct` de cada cosa, se junta lo que falta y se deja de gastar en lo demás.
		if start:
			_holding = sim.dp(player).cost_of(ctype, p["age"])
		return
	if sim.tick - last_expand < int(cfg["cada_ticks"]):
		return
	last_expand = sim.tick
	var site := _expansion_site(ctype, centro, cfg)
	if site.x >= 0:
		_build_at(ctype, site, vill, int(cfg["constructores"]))


## Lo que hace falta en el banco para el centro siguiente (más lo del hito si se ahorra), o
## vacío si no toca expandirse: sin `expansion`, con todos los centros, sin la edad o sin los
## aldeanos de `expansion.aldeanos`.
func _expansion_need(p: Dictionary, n_vill: int, saving: bool) -> Dictionary:
	var cfg: Dictionary = level.get("expansion", {})
	if cfg.is_empty() or centers.size() >= int(cfg["centros_max"]):
		return {}
	var ctype := _center_type()
	var dd := sim.dp(player)
	if ctype == "" or p["age"] < maxi(int(dd.edificios[ctype].get("edad_min", 1)), int(cfg.get("edad_min", 1))):
		return {}
	var needs: Array = cfg["aldeanos"]
	if n_vill < int(needs[clampi(centers.size() - 1, 0, needs.size() - 1)]):
		return {}
	var out: Dictionary = dd.cost_of(ctype, p["age"]).duplicate()
	# `reserva_hito`: el centro nunca se come lo del hito siguiente, aunque no se esté ahorrando.
	if saving or cfg.get("reserva_hito", false) and p["age"] < dd.edades.size() and p["age"] < int(level.get("edad_max", 99)) and not sim.hito_in_progress(player):
		var hc: Dictionary = _goal_cost(p)
		for k in out:
			out[k] = int(out[k]) + int(hc.get(k, 0))
	return out


## El edificio con el que la civ se expande: el centro si lo construye; si no, el más barato
## de los que entrenan aldeanos (el lof mapuche).
func _center_type() -> String:
	if _ctype != "-":
		return _ctype
	_ctype = ""
	var dd := sim.dp(player)
	var best_c := 1 << 30
	for t in dd.unidades.get("aldeano", {}).get("construye", []):
		var def: Dictionary = dd.edificios.get(t, {})
		if def.is_empty() or not (def.get("produce", []) as Array).has("aldeano"):
			continue
		if t == "centro":
			_ctype = t
			return t
		var c := 0
		for k in dd.cost_of(t, 1):
			c += int(dd.cost_of(t, 1)[k])
		if c < best_c:
			best_c = c
			_ctype = t
	return _ctype


## Lugar para un centro nuevo: junto al recurso más cercano de `expansion.recursos` (en ese
## orden de preferencia) entre `distancia_min` y `distancia_max` de la capital, a
## `separacion` o más de los otros centros y más cerca de la base propia que de las rivales
## (`lado_pct`). Se prueban los `candidatos` más cercanos.
func _expansion_site(ctype: String, centro: SimEntity, cfg: Dictionary) -> Vector2i:
	var kinds: Array = cfg["recursos"]
	var dmin := int(cfg["distancia_min"])
	var dmax := int(cfg["distancia_max"])
	var sep := int(cfg["separacion"])
	var side := int(cfg["lado_pct"])
	var cands := []
	for t in sim.entities:
		if not (t.alive and t.is_resource() and t.amount > 0) or not kinds.has(t.res_kind):
			continue
		if t.res_owner >= 0 and t.res_owner != player:
			continue
		var d := Sim.dist(t.x, t.y, centro.x, centro.y)
		if d < dmin or d > dmax:
			continue
		var ok := true
		for c in centers:
			if Sim.dist(t.x, t.y, c.x, c.y) < sep:
				ok = false
				break
		if ok:
			for j in mini(sim.players.size(), sim.bases.size()):
				if sim.enemies(player, j) and Sim.dist(t.x, t.y, sim.bases[j].x * P, sim.bases[j].y * P) * 100 < d * side:
					ok = false
					break
		if ok:
			cands.append([kinds.find(t.res_kind), d, t.id, t])
	cands.sort_custom(func(a, b): return a[0] < b[0] or a[0] == b[0] and (a[1] < b[1] or a[1] == b[1] and a[2] < b[2]))
	var tam: Array = sim.dp(player).edificios[ctype]["tam"]
	var radius := int(cfg["radio_lugar"])
	for i in mini(cands.size(), int(cfg["candidatos"])):
		var t: SimEntity = cands[i][3]
		for r in range(1, radius + 1):
			for dy in range(-r, r + 1):
				for dx in range(-r, r + 1):
					if absi(dx) != r and absi(dy) != r:
						continue
					var tx: int = t.tx + dx - int(tam[0]) / 2
					var ty: int = t.ty + dy - int(tam[1]) / 2
					if tx < 2 or ty < 2 or tx + int(tam[0]) > sim.map.n - 2 or ty + int(tam[1]) > sim.map.n - 2:
						continue
					if sim.map.is_free_rect(tx - 1, ty - 1, int(tam[0]) + 2, int(tam[1]) + 2) and sim.can_place(ctype, tx, ty, player):
						return Vector2i(tx, ty)
	return Vector2i(-1, -1)


func _nearest_villager(vill: Array[SimEntity], x: int, y: int) -> SimEntity:
	var best := vill[0]
	var best_d := 1 << 60
	for v in vill:
		var d := Sim.dist(v.x, v.y, x, y)
		if d < best_d and v.order != O.BUILD:
			best = v
			best_d = d
	return best


func _site(type: String, centro: SimEntity, margin: int) -> Vector2i:
	return _site_near(type, Vector2i(centro.tx + 2, centro.ty + 2), margin, 4)


## Lugar para una granja: si rinde más junto al agua (arrozal de Ayutthaya), primero junto al
## agua a `ia_economia.granja_agua_radio` del centro o menos; si no, lo de siempre. Antes
## ningún arrozal de la IA tenía el bono, ni en río ni en delta (proceso/24, paso 3).
func _farm_site(centro: SimEntity) -> Vector2i:
	var def: Dictionary = sim.dp(player).edificios.get("granja", {})
	if def.has("bono_agua_pct"):
		var tam: Array = def["tam"]
		var c := Vector2i(centro.tx + 2, centro.ty + 2)
		for r in range(3, int(sim.data.reglas["ia_economia"]["granja_agua_radio"])):
			for dy in range(-r, r + 1):
				for dx in range(-r, r + 1):
					if absi(dx) != r and absi(dy) != r:
						continue
					var tx: int = c.x + dx - int(tam[0]) / 2
					var ty: int = c.y + dy - int(tam[1]) / 2
					if sim._near_water(tx, ty, tam[0], tam[1], 2) and sim.can_place("granja", tx, ty, player):
						return Vector2i(tx, ty)
	return _site("granja", centro, 0)


## Busca un lugar libre en anillos alrededor de `c`, dejando `margin` casillas de paso.
func _site_near(type: String, c: Vector2i, margin: int, min_r: int = 1) -> Vector2i:
	if not sim.dp(player).edificios.has(type):
		return Vector2i(-1, -1)
	if not sim.engine_room(type, player):
		return Vector2i(-1, -1) # sin cupo en la edad: ningún lugar va a servir
	var tam: Array = sim.dp(player).edificios[type]["tam"]
	var w: int = tam[0]
	var h: int = tam[1]
	for r in range(min_r, 30):
		for dy in range(-r, r + 1):
			for dx in range(-r, r + 1):
				if absi(dx) != r and absi(dy) != r:
					continue
				var tx := c.x + dx - w / 2
				var ty := c.y + dy - h / 2
				if tx < 2 or ty < 2 or tx + w > sim.map.n - 2 or ty + h > sim.map.n - 2:
					continue
				if sim.map.is_free_rect(tx - margin, ty - margin, w + margin * 2, h + margin * 2) and sim.can_place(type, tx, ty, player):
					return Vector2i(tx, ty)
	sim.tele.add(sim.tick, "ia_sin_lugar", player, c.x, c.y, {"tipo": type}, "isl:%d:%s" % [player, type], 600)
	return Vector2i(-1, -1)


# ---------------------------------------------------------------- Producción

func _production(p: Dictionary, vill: Array[SimEntity], army: Array[SimEntity], centro: SimEntity, by_type: Dictionary, saving: bool) -> void:
	# Las órdenes se aplican en el tick siguiente: cada una gasta de este presupuesto, así
	# el segundo edificio no pide con la misma plata (telemetría: ~80 rechazos por partida).
	var budget: Dictionary = (p["res"] as Dictionary).duplicate()
	if level.get("aldeanos_en_todos_los_centros", false):
		# Experta: aldeanos sin parar desde todos los centros (también ahorrando).
		var queued := 0
		for c in centers:
			queued += c.queue.count("aldeano")
		for c in centers:
			if c.queue.is_empty() and vill.size() + queued < max_villagers and _spend(budget, sim.dp(player).cost_of("aldeano", p["age"])):
				sim.push_command({"t": "train", "player": player, "building": c.id, "type": "aldeano"})
				queued += 1
	elif centro.queue.is_empty() and vill.size() < max_villagers and (centro.def.get("produce", []) as Array).has("aldeano"):
		if _spend(budget, sim.dp(player).cost_of("aldeano", p["age"])):
			sim.push_command({"t": "train", "player": player, "building": centro.id, "type": "aldeano"})
	var threatened := _threat(centro) != null
	# Tope de ejército por dificultad (la fácil: 15). Si atacan la base, el de emergencia
	# (`ejercito_max_amenazada`; sin él, ninguno): la fácil atacada pasaba de 39 a 147 de
	# población y el ataque que le pide el aviso no se podía ganar (jugador nuevo, ronda 4).
	var tope := int(level.get("ejercito_max", 1 << 20))
	if threatened:
		tope = int(level.get("ejercito_max_amenazada", 1 << 20))
	# Con tope, cuenta también lo que está en cola: cada edificio encola hasta dos y el tope se
	# pasaba por 10 (el de emergencia de 30 llegaba a 40).
	var en_cola := 0
	if level.has("ejercito_max"):
		for b in sim.buildings_of(player):
			if b.owner == player and b.is_building() and not b.queue.is_empty():
				for q: String in b.queue:
					var ud: Dictionary = sim.dp(player).unidades.get(q, {})
					en_cola += 1 if not ud.is_empty() and ud.get("funcion", "") in ["choque", "distancia", "linea", "asedio"] else 0
	if army.size() + en_cola >= tope:
		return
	# Ahorrando para el hito, solo se mantiene un ejército mínimo por edad con lo que sobra por
	# encima de su costo. Cortar del todo dejaba a Etiopía con 9 de ejército y 979 de alimento
	# en el banco; gastar todo lo que sobra demoraba la edad III 3–4 minutos (proceso/24).
	# --- paso 7 --- la maravilla se sigue juntando con la base atacada si hay tropa (si no, se
	# gastaba en un minuto lo juntado en diez).
	if saving and (not threatened or _goal_is_wonder() and army.size() >= _min_army(p)):
		if army.size() >= _min_army(p) and not threatened:
			return
		var hc: Dictionary = _goal_cost(p)
		for k in hc:
			budget[k] = maxi(0, int(budget.get(k, 0)) - int(hc[k]))
	# Juntando para el centro (experta), la tropa sale de lo que sobra por encima, salvo que
	# esté por debajo del mínimo de la edad (`ejercito_minimo_ahorrando`): no se corta.
	if not threatened and army.size() >= _min_army(p):
		for k in _holding:
			budget[k] = maxi(0, int(budget.get(k, 0)) - int(_holding[k]))
	var order := _counter_order(p)
	var producers: Array = []
	for k in by_type:
		for b: SimEntity in by_type[k]:
			if b.built and b.capital == false and _makes_military(b):
				producers.append(b)
	for b: SimEntity in producers:
		if not b.built:
			continue
		if not b.rally_set:
			sim.push_command({"t": "rally", "player": player, "building": b.id, "x": rally.x, "y": rally.y})
		if b.queue.size() >= 2:
			continue
		# Arietes desde la edad II: sin asedio los ataques no derriban edificios.
		var makes: Array = b.def.get("produce", [])
		# --- paso 4 --- el asedio contra edificios puede ser el ariete, su reemplazo de la III
		# (hondero de piedra caliente, cañón de tacuara) o los incendiarios mapuches; y el asedio
		# de área sale si el rival junta tropa (reglas.ia_asedio).
		var siege := _siege_units(makes, int(p["age"]))
		var ram: String = siege[0]
		var area: String = siege[1]
		var want_ram: bool = p["age"] >= 2 and ram != "" and _count(army, ram) < 1 + wave / 2 and army.size() >= 6
		var want_area: bool = area != "" and area != ram and _wants_area_siege(army, area)
		# Con las dos, la que falta más (el ariete solo, sin el de área, llenaba el taller).
		var pick := ""
		if want_area and (not want_ram or _count(army, area) < _count(army, ram)):
			pick = area
		elif want_ram:
			pick = ram
		if pick != "" and _spend(budget, sim.dp(player).cost_of(pick, p["age"])):
			sim.push_command({"t": "train", "player": player, "building": b.id, "type": pick})
			continue
		# --- fin paso 4 ---
		# La preferida si alcanza; si no, la siguiente que se pueda pagar.
		for type in order:
			if not makes.has(type) or p["age"] < int(sim.dp(player).unidades.get(type, {}).get("edad_min", 1)):
				continue # solo lo que este edificio produce y la edad permite (antes repetía órdenes rechazadas)
			var c := sim.dp(player).cost_of(type, p["age"])
			if _keeps_reserve(p, c) and _spend(budget, c):
				sim.push_command({"t": "train", "player": player, "building": b.id, "type": type})
				break


# --- paso 4 ---
## [asedio contra edificios, asedio de área] que `makes` entrena en la edad `age` ("" si no hay).
## Lo reemplazado (el ariete inca y el guaraní desde la III) no cuenta; el reemplazo hace las dos cosas.
func _siege_units(makes: Array, age: int) -> Array:
	var dd := sim.dp(player)
	var ram := ""
	var area := ""
	for u: String in makes:
		var d: Dictionary = dd.unidades.get(u, {})
		if d.get("funcion", "") != "asedio" or age < int(d.get("edad_min", 1)) or dd.replaced_by(u, age) != "":
			continue
		if d.has("area_borde_pct") and area == "":
			area = u
		if (d.get("solo_edificios", false) or d.has("reemplaza")) and ram == "":
			ram = u
	return [ram, area]


# --- esport 1a ---
## Ataque al suelo (reglas.ia_asedio.suelo): cada `cada_ticks`, cada asedio de área que pelea
## tira al punto de la tropa rival más amontonada a su alcance (+ `margen`): el enemigo con más
## enemigos a `area` o menos, si son `grupo_min` o más. Sin montón a tiro, vuelve a atacar en
## movimiento hacia donde tiraba. Apunta adonde están: la tropa que se mueve a tiempo lo esquiva.
var _last_aim := -1000
func _aim_ground(army: Array[SimEntity]) -> void:
	var cfg: Dictionary = sim.data.reglas.get("ia_asedio", {}).get("suelo", {})
	if cfg.is_empty() or sim.tick - _last_aim < int(cfg["cada_ticks"]):
		return
	_last_aim = sim.tick
	var need := int(cfg["grupo_min"])
	for u in army:
		if not Sim.can_ground(u) or not u.alive or not (u.order in [O.ATTACK, O.ATTACK_MOVE, O.GROUND]):
			continue
		var reach := sim.reach_of(u) + int(cfg["margen"])
		var r := int(u.def["area"])
		var near: Array[SimEntity] = []
		for gx in range(maxi(0, (u.x - reach) / Sim.EC), (u.x + reach) / Sim.EC + 1):
			for gy in range(maxi(0, (u.y - reach) / Sim.EC), (u.y + reach) / Sim.EC + 1):
				for o: SimEntity in sim._ehash.get(gx * 1024 + gy, Sim._NONE):
					if o.alive and o.is_unit() and o.inside < 0 and o.owner >= 0 and sim.enemies(player, o.owner) and Sim.dist(u.x, u.y, o.x, o.y) <= reach:
						near.append(o)
		var best: SimEntity = null
		var best_n := 0
		for o in near:
			var n := 0
			for q in near:
				if absi(q.x - o.x) <= r and absi(q.y - o.y) <= r and Sim.dist(q.x, q.y, o.x, o.y) <= r:
					n += 1
			if n > best_n:
				best_n = n
				best = o
		if best != null and best_n >= need:
			if u.order != O.GROUND or Sim.dist(u.gnd_x, u.gnd_y, best.x, best.y) > r / 2:
				sim.push_command({"t": "suelo", "player": player, "ids": [u.id], "x": best.x, "y": best.y})
		elif u.order == O.GROUND:
			sim.push_command({"t": "move", "player": player, "ids": [u.id], "x": u.gnd_x, "y": u.gnd_y, "amove": true, "suelto": true})
# --- fin esport 1a ---


## Asedio de área (reglas.ia_asedio): con ejército propio y tropa rival que valga la pena, hasta
## 1 + oleada / oleadas_por_unidad (tope).
func _wants_area_siege(army: Array[SimEntity], type: String) -> bool:
	var cfg: Dictionary = sim.data.reglas.get("ia_asedio", {})
	if cfg.is_empty() or army.size() < int(cfg["ejercito_min"]):
		return false
	if _count(army, type) >= mini(int(cfg["tope"]), 1 + wave / maxi(1, int(cfg["oleadas_por_unidad"]))):
		return false
	var foes := 0
	for e in sim.military():
		if e.alive and e.owner >= 0 and e.is_unit() and e.is_military() and sim.enemies(player, e.owner):
			foes += 1
			if foes >= int(cfg["enemigos_min"]):
				return true
	return false


## Fortaleza (reglas.ia_asedio): desde su edad, junto al centro del lado del rival, cuando no
## ahorra para el hito siguiente (lo decide `_buildings`).
func _fortress(p: Dictionary, vill: Array[SimEntity], centro: SimEntity, by_type: Dictionary, unbuilt: Dictionary) -> void:
	var cfg: Dictionary = sim.data.reglas.get("ia_asedio", {})
	var dd := sim.dp(player)
	if cfg.is_empty() or not dd.edificios.has("fortaleza") or unbuilt.has("fortaleza"):
		return
	if p["age"] < int(dd.edificios["fortaleza"].get("edad_min", 1)) or vill.size() < int(cfg["aldeanos_min"]):
		return
	if (by_type.get("fortaleza", []) as Array).size() >= int(level.get("fortalezas", cfg["fortalezas_por_defecto"])):
		return
	if not sim.can_afford(player, dd.cost_of("fortaleza", p["age"])):
		return
	var eb := Vector2i(centro.tx, centro.ty)
	var best := 1 << 60
	for j in mini(sim.players.size(), sim.bases.size()):
		if sim.enemies(player, j):
			var d := Sim.dist(sim.bases[j].x * P, sim.bases[j].y * P, centro.x, centro.y)
			if d < best:
				best = d
				eb = sim.bases[j]
	var off := int(cfg["adelante"])
	var at := Vector2i(centro.tx + centro.w / 2 + signi(eb.x - centro.tx) * off, centro.ty + centro.h / 2 + signi(eb.y - centro.ty) * off)
	var site := _site_near("fortaleza", at, 1)
	if site.x >= 0:
		_build_at("fortaleza", site, vill, int(cfg["constructores"]))
# --- fin paso 4 ---


# --- muralla --- (reglas.ia_muralla; proceso/32-ronda-8/06)
## Muralla de piedra (dificultades con `muralla`: la difícil y la experta). Un lienzo recto del
## lado del rival, a uno de los `radios` del centro (el más libre), con la puerta en el medio: en la II si el rival
## ya vino con tropa a la base (`_wall_alert`), si no en la III; después, `torres` torres encima.
## No con el hito o la maravilla en ahorro, salvo amenazada. Un solo lienzo por partida.
func _wall(p: Dictionary, vill: Array[SimEntity], centro: SimEntity, by_type: Dictionary, saving: bool) -> void:
	var cfg: Dictionary = sim.data.reglas.get("ia_muralla", {})
	if cfg.is_empty() or not level.get("muralla", false):
		return
	var age := int(p["age"])
	if age <= 2 and not _wall_alert and sim.tick - _wall_check >= int(cfg["mira_cada_ticks"]):
		_wall_check = sim.tick
		var t := _threat(centro)
		_wall_alert = t != null and t.is_military()
	var dd := sim.dp(player)
	var wall := _wall_type(dd)
	if wall == "" or age < int(dd.edificios[wall].get("edad_min", 1)):
		return
	if age < (int(cfg["edad_temprana"]) if _wall_alert else int(cfg["edad"])):
		return
	# Ahorrando para el hito de la II a la III no, salvo con la alerta; desde la III la muralla
	# va aunque ahorre (la experta ahorra siempre), salvo para la maravilla.
	if vill.size() < int(cfg["aldeanos_min"]) or saving and (age < int(cfg["edad"]) and not _wall_alert or _goal_is_wonder()):
		return
	if _wall_tiles.is_empty():
		# El radio con más casillas libres (la base de la III ya está llena de granjas y edificios).
		var tiles := []
		for r in cfg["radios"]:
			var cand := _wall_line(centro, int(r), int(cfg["tramos"]))
			if cand.size() > tiles.size():
				tiles = cand
		var cost: Dictionary = dd.cost_of(wall, age)
		var need := {}
		for k in cost:
			need[k] = int(cost[k]) * tiles.size() + int(cfg["reserva"].get(k, 0))
		if tiles.size() < int(cfg["tramos"]) / 2 or not sim.can_afford(player, need):
			return
		var ids := []
		for v in vill:
			if v.order != O.BUILD and v.carry <= 4 and ids.size() < int(cfg["constructores"]):
				ids.append(v.id)
		if ids.is_empty():
			return
		_wall_tiles = tiles
		var mid: Array = tiles[tiles.size() / 2]
		var gate: String = dd.edificios[wall].get("su_puerta", "")
		var rest := tiles.filter(func(t: Array) -> bool: return t != mid)
		sim.push_command({"t": "build_line", "player": player, "ids": ids, "type": wall, "tiles": rest})
		if gate != "" and dd.edificios.has(gate):
			sim.push_command({"t": "build", "player": player, "ids": [], "type": gate, "tx": mid[0], "ty": mid[1]})
		sim.tele.add(sim.tick, "ia_muralla", player, mid[0], mid[1], {"tramos": tiles.size(), "edad": age, "alerta": _wall_alert}, "imu:%d" % player, 1)
		return
	# Torres encima del lienzo terminado, desde la edad siguiente a la del lienzo o la III.
	var tower := _wall_tower_type(dd, wall)
	if tower == "" or age < int(cfg["torres_edad"]) or saving and _goal_is_wonder() or (by_type.get(tower, []) as Array).size() >= int(cfg["torres"]):
		return
	for b: SimEntity in by_type.get(tower, []):
		if not b.built:
			return
	if not sim.can_afford(player, dd.cost_of(tower, age)):
		return
	var n := _wall_tiles.size()
	for i in int(cfg["torres"]):
		var t: Array = _wall_tiles[n * (1 + 2 * i) / (2 * int(cfg["torres"]))]
		var w: SimEntity = sim.by_id.get(sim.map.occupant(t[0], t[1]))
		if w != null and w.alive and w.owner == player and w.type == wall and w.built:
			_build_at(tower, Vector2i(t[0], t[1]), vill, 2)
			return


## La muralla del pueblo: lo que levanta el aldeano en línea, de piedra y que no se camina.
func _wall_type(dd: SimData) -> String:
	for k: String in dd.unidades["aldeano"].get("construye", []):
		var d: Dictionary = dd.edificios.get(k, {})
		if d.get("linea", false) and not d.get("transitable", false) and Sim.material_of(d) == "piedra":
			return k
	return ""


## La torre que va encima de `wall` (`solo_sobre`), o "".
func _wall_tower_type(dd: SimData, wall: String) -> String:
	for k: String in dd.unidades["aldeano"].get("construye", []):
		var d: Dictionary = dd.edificios.get(k, {})
		if d.get("solo_sobre", false) and (d.get("sobre", []) as Array).has(wall):
			return k
	return ""


## Casillas del lienzo: recto, perpendicular a la línea entre el centro y la base rival más
## cercana, a `radio` casillas del centro y de `n` casillas (paso a paso en cuatro direcciones,
## sin diagonales por donde se cuele la tropa). Solo las que se pueden construir ahora.
func _wall_line(centro: SimEntity, radio: int, n: int) -> Array:
	var c := Vector2i(centro.tx + centro.w / 2, centro.ty + centro.h / 2)
	var eb := c
	var best := 1 << 60
	for j in mini(sim.players.size(), sim.bases.size()):
		if sim.enemies(player, j):
			var d := Sim.dist(sim.bases[j].x, sim.bases[j].y, c.x, c.y)
			if d < best:
				best = d
				eb = sim.bases[j]
	var dx := eb.x - c.x
	var dy := eb.y - c.y
	var l := maxi(1, Sim.dist(0, 0, dx, dy))
	var mid := Vector2i(c.x + dx * radio / l, c.y + dy * radio / l)
	var half := n / 2
	var a := Vector2i(mid.x - dy * half / l, mid.y + dx * half / l)
	var b := Vector2i(mid.x + dy * half / l, mid.y - dx * half / l)
	var out := []
	var x := a.x
	var y := a.y
	var ddx := absi(b.x - a.x)
	var ddy := -absi(b.y - a.y)
	var sx := 1 if a.x < b.x else -1
	var sy := 1 if a.y < b.y else -1
	var err := ddx + ddy
	var all := [[x, y]]
	while (x != b.x or y != b.y) and all.size() < n * 2:
		var e2 := 2 * err
		if e2 - ddy > ddx - e2:
			err += ddy
			x += sx
		else:
			err += ddx
			y += sy
		all.append([x, y])
	var wall := _wall_type(sim.dp(player))
	for t: Array in all:
		if sim.can_place(wall, t[0], t[1], player):
			out.append(t)
	return out
# --- fin muralla ---


## Unidades en orden de preferencia: primero la que vence a la función enemiga más numerosa (triángulo, docs/05).
## Descuenta `cost` del presupuesto si alcanza.
func _spend(budget: Dictionary, cost: Dictionary) -> bool:
	for k in cost:
		if int(budget.get(k, 0)) < int(cost[k]):
			return false
	for k in cost:
		budget[k] = int(budget.get(k, 0)) - int(cost[k])
	return true


func _counter_order(p: Dictionary) -> Array[String]:
	var counts := {"choque": 0, "distancia": 0, "linea": 0}
	for e in sim.military():
		if e.alive and e.owner >= 0 and sim.enemies(player, e.owner) and e.is_military() and counts.has(e.fn):
			counts[e.fn] += 1
	var top := "choque"
	for k in counts:
		if counts[k] > counts[top]:
			top = k
	var pick := {"choque": "lancero", "distancia": "guerrero", "linea": "hondero"}[top] as String
	if counts[top] == 0:
		pick = ["hondero", "guerrero", "lancero"][(sim.tick / 160) % 3]
	var out: Array[String] = []
	# --- paso 6 --- Las unidades propias (ia_propias.unidades) primero, mientras no pasen su
	# `max_pct` del ejército; `contra_montados`: solo si el rival tiene al menos tantos montados.
	var own: Dictionary = sim.dp(player).civ.get("ia_propias", {})
	if not own.is_empty():
		var mine := {}
		var army_n := 0
		var foe_mounted := 0
		for e in sim.military():
			if not e.alive or not e.is_unit() or not e.is_military():
				continue
			if e.owner == player:
				army_n += 1
				mine[e.type] = int(mine.get(e.type, 0)) + 1
			elif e.owner >= 0 and sim.enemies(player, e.owner) and (e.def.get("montado", false) or e.def.get("elefante", false)):
				foe_mounted += 1
		for it: Dictionary in own.get("unidades", []):
			var ty: String = it["tipo"]
			if int(mine.get(ty, 0)) * 100 >= int(it.get("max_pct", 100)) * maxi(1, army_n):
				continue
			if foe_mounted < int(it.get("contra_montados", 0)):
				continue
			if int(p["age"]) < int(it.get("desde_edad", 1)):
				continue # `desde_edad`: antes no entra al orden (y no corre el turno de ia_unidades)
			out.append(ty)
	for t: String in sim.dp(player).civ.get("ia_unidades", []):
		if (sim.tick / 50 + out.size()) % 3 == 0:
			out.append(t)
	out.append(pick)
	for t: String in ["hondero", "guerrero", "lancero"]:
		if not out.has(t):
			out.append(t)
	var dd := sim.dp(player)
	return out.filter(func(t: String) -> bool: return dd.unidades.has(t) and dd.unidades[t]["edad_min"] <= p["age"])


# ---------------------------------------------------------------- Ejército

## Amenaza: un enemigo cerca de la capital o de cualquier edificio propio. La capital
## etíope es una corte que se muda: mirar solo la capital dejaba la base atacada sin ver
## (y la IA seguía ahorrando para el hito sin entrenar, proceso/21, paso 16).
## Rendimiento (proceso/32-ronda-8/04): `think` la pide hasta 11 veces y cada vez recorría
## todo dos veces. El estado no cambia dentro de un tick de la IA (las órdenes van al siguiente):
## se calcula una vez por tick y centro.
var _threat_tick := -1
var _threat_centro: SimEntity = null
var _threat_res: SimEntity = null
func _threat(centro: SimEntity) -> SimEntity:
	if _threat_tick != sim.tick or _threat_centro != centro:
		_threat_tick = sim.tick
		_threat_centro = centro
		_threat_res = _threat_calc(centro)
	return _threat_res


func _threat_calc(centro: SimEntity) -> SimEntity:
	var eco: Dictionary = sim.data.reglas["ia_economia"]
	var near_cap := int(eco["amenaza_capital"])
	var near_b := int(eco["amenaza_edificio"])
	# Celdas de 4 casillas cerca de los edificios propios: así cada enemigo se mira una sola
	# vez (comparar todos contra todos costaba 7 ms por tick con 6 jugadores).
	var cell := 4 * P
	var r := near_b / cell + 1
	var near_cells := {}
	# El hito propio en obra también se defiende (`ataca_hito_en_obra`: quien ataca el ajeno cuida el suyo).
	var guard_hito: bool = level.get("ataca_hito_en_obra", false)
	for b in sim.buildings_of(player):
		if b.alive and b.owner == player and b.is_building() and (b.built or guard_hito and (b.def.get("hito", false) or b.def.get("maravilla", false))) and b != centro and b.def.get("fuente", "") == "":
			var bx := b.x / cell
			var by := b.y / cell
			for dy in range(-r, r + 1):
				for dx in range(-r, r + 1):
					near_cells[(bx + dx) * 4096 + by + dy] = true
	var best: SimEntity = null
	var best_d := 1 << 60
	for e in sim.actives:
		if not (e.alive and e.owner >= 0 and e.is_unit() and sim.enemies(player, e.owner) and (e.is_military() or e.fn == "explorador")):
			continue
		var d := sim.dist_to(e, centro)
		var hit := d < near_cap or near_cells.has((e.x / cell) * 4096 + e.y / cell)
		if hit and d < best_d:
			best = e
			best_d = d
	return best


func _military(army: Array[SimEntity], centro: SimEntity) -> void:
	_track_wave()
	if army.is_empty():
		return
	var threat := _threat(centro)
	var ally := _ally_threat(centro)
	if threat != null:
		_say("atacan", {})
	# El grupo que va a un sitio sigue a lo suyo: se cuida, se retira o se disuelve.
	var left := _site_clock()
	if not _squad.is_empty():
		var ccfg := _contest_cfg()
		if ccfg.is_empty():
			_squad = {}
		else:
			_squad_step(ccfg, left >= 0 and left <= int(ccfg["desesperado_ms"]))
	if not _squad.is_empty():
		army = _without(army, _squad["ids"])
	# Experta (`defensa_proporcional`): a la amenaza va lo que hace falta y el resto sigue con lo
	# suyo. Antes un explorador o un grupito rival cerca de un almacén retenía a todo el ejército
	# en la base, y la difícil ganaba por sitios con la experta mirando (proceso/24, paso 4f).
	# Con la cuenta de sitios rival corriendo, todas las que disputan sitios defienden así.
	var prop: Dictionary = level.get("defensa_proporcional", {})
	if prop.is_empty() and left >= 0 and not _contest_cfg().is_empty():
		prop = _contest_cfg()["defensa_proporcional"]
	if threat != null and ally == null and not prop.is_empty():
		army = _defend_some(army, threat, prop)
		if army.is_empty():
			return
		threat = null
	if threat != null or ally != null:
		var ids := []
		var help := []
		# Si atacan a los dos, una parte va igual al aliado (jugadores de prueba, ronda 2).
		var part := 100 if threat == null else int(sim.data.reglas["equipos"].get("ia_ayuda_parte_pct", 0))
		var free: Array[SimEntity] = []
		for u in army:
			if u.order != O.ATTACK and not _at_flare(u):
				free.append(u)
		for i in free.size():
			if ally != null and help.size() < free.size() * part / 100:
				help.append(free[i].id)
			else:
				ids.append(free[i].id)
		if threat != null and not ids.is_empty():
			sim.push_command({"t": "move", "player": player, "ids": ids, "x": threat.x, "y": threat.y, "amove": true})
		if not help.is_empty():
			sim.push_command({"t": "move", "player": player, "ids": help, "x": ally.x, "y": ally.y, "amove": true})
			_say("voy_defender", {"a": _ally_under(ally), "n": help.size()})
		return
	var st: Dictionary = sim.data.reglas.get("estilos_ia", {}).get(personality, {})
	if personality == "paz": # solo para las pruebas de economía: no pelea fuera de su base
		st = {"ataca_base": false, "incursiones": "no", "controla_mapa": false}
	var need: int = int(st.get("ataque_base", level["ataque_base"])) + int(st.get("ataque_paso", level["ataque_paso"])) * wave
	var gap: int = int(st.get("ataque_espera_ticks", level["ataque_espera_ticks"]))
	var attacks: bool = st.get("ataca_base", personality != "pasiva") and sim.tick >= int(level.get("primer_ataque_ticks", 0))
	var home := army
	# --- ronda 8, 05 --- La maravilla rival va antes que los sitios: si se la deja, gana.
	if attacks and _hit_wonder(army):
		return
	army = _contest_sites(army, left)
	if army.is_empty():
		if _contest_held:
			_regroup(home)
		return
	if attacks and _hit_wonder(army): # --- paso 7 --- la maravilla rival va primero
		return
	if attacks and _hit_hito(army):
		return
	var ready: bool = attacks and army.size() >= need and sim.tick - last_attack > gap
	if ready and ready_since < 0:
		ready_since = sim.tick
	if ready:
		ready_seen = sim.tick
	else:
		ready_since = -1
	if ready and _team_turn():
		wave += 1
		last_attack = sim.tick
		ready_since = -1
		_attack(army)
		return
	if attacks and _hunt(army):
		return
	# Los estilos que no atacan la base no entran en ella: quien quede adentro vuelve.
	if not attacks and st.has("respeta_radio"):
		# Las incursiones entran y salen: solo vuelve quien ya terminó (está ocioso).
		_leash(army, int(st["respeta_radio"]), st.get("incursiones", "no") == "si")
	# Incursiones (malón, correría, acoso): las unidades más rápidas golpean la economía rival.
	var raids: String = st.get("incursiones", "civ")
	var raid_on: bool = (raids == "si" or (raids == "civ" and bool(sim.dp(player).civ.get("ia_incursiones", false)))) and level.get("incursiones", true)
	var every := int(st.get("incursion_cada_ticks", 900))
	if raid_on and sim.tick - last_raid >= every and army.size() >= 5:
		last_raid = sim.tick
		var prey: SimEntity = null
		var best_d := 1 << 60
		for e in sim.actives:
			if e.alive and e.owner >= 0 and sim.enemies(player, e.owner) and e.inside < 0 and (e.fn == "civil" or e.def.has("fuente") or e.def.has("deposito")):
				var d := Sim.dist(e.x, e.y, rally.x, rally.y)
				if d < best_d:
					best_d = d
					prey = e
		if prey != null:
			var fast := army.duplicate()
			fast.sort_custom(func(a: SimEntity, b: SimEntity) -> bool: return a.speed > b.speed)
			var ids := []
			for u in fast:
				if ids.size() >= int(st.get("incursion_tam", 5)):
					break
				if (u.order == O.IDLE or u.order == O.MOVE) and not _at_flare(u):
					ids.append(u.id)
			if not ids.is_empty():
				sim.push_command({"t": "move", "player": player, "ids": ids, "x": prey.x, "y": prey.y, "amove": true})
	# Control del mapa: la mitad del ejército ocioso ocupa un punto disputado.
	if st.get("controla_mapa", false) and sim.tick - last_spot >= 600 and army.size() >= 6:
		last_spot = sim.tick
		var spot := _map_spot(int(st.get("respeta_radio", 0)))
		if spot.x >= 0:
			var ids := []
			for u in army:
				if u.order == O.IDLE and ids.size() < army.size() / 2 and not _at_flare(u): # --- equipos ronda 3 ---
					ids.append(u.id)
			if not ids.is_empty():
				sim.push_command({"t": "move", "player": player, "ids": ids, "x": spot.x, "y": spot.y, "amove": true})
	# Ingenios neutrales: desde la edad II, un grupo los asalta por el botín (§3.2).
	if personality != "paz" and sim.players[player]["age"] >= 2 and army.size() >= 8 and sim.tick - last_mill >= 900:
		last_mill = sim.tick
		var mill: SimEntity = null
		var best_m := 1 << 60
		for e in sim.actives:
			if e.alive and e.owner < 0 and e.def.has("botin_por_edad"):
				var d := Sim.dist(e.x, e.y, rally.x, rally.y)
				if d < best_m:
					best_m = d
					mill = e
		if mill != null and sim.disputed_room(player) >= 50:
			var ids := []
			for u in army:
				if u.order == O.IDLE and ids.size() < maxi(6, army.size() * 2 / 3) and not _at_flare(u): # --- equipos ronda 3 ---
					ids.append(u.id)
			if ids.size() >= 6:
				sim.push_command({"t": "move", "player": player, "ids": ids, "x": mill.x, "y": mill.y, "amove": true})
	# Sitios sagrados: un grupo chico va a tomar el más cercano que no controla.
	if sim.tick - last_site >= 300 and army.size() >= 6 and level.get("toma_sitios", true) and sim.can_take_sites(player): # --- esport 1a --- desde la II
		last_site = sim.tick
		var site: SimEntity = null
		var best := 1 << 60
		# Quien disputa sitios no manda el grupo chico a un sitio con enemigos (era goteo): eso lo
		# decide `_contest_sites`, con fuerza proporcional.
		var guard := _contest_cfg()
		for e in sim.actives:
			if e.alive and e.def.get("sagrado", false) and (e.holder < 0 or sim.enemies(player, e.holder)) and (guard.is_empty() or _foes_hp(e, int(guard["radio"])) == 0):
				var d := Sim.dist(e.x, e.y, rally.x, rally.y)
				if d < best:
					best = d
					site = e
		if site != null:
			var ids := []
			for u in army:
				if u.order == O.IDLE and ids.size() < int(level.get("sitio_grupo", 4)) and not _at_flare(u): # --- equipos ronda 3 ---
					ids.append(u.id)
			if not ids.is_empty():
				sim.push_command({"t": "move", "player": player, "ids": ids, "x": site.x, "y": site.y, "amove": true})
	_regroup(army)


## Reagrupar a las unidades inactivas en el punto de reunión.
func _regroup(army: Array[SimEntity]) -> void:
	var idle := []
	for u in army:
		if u.order == O.IDLE and Sim.dist(u.x, u.y, rally.x, rally.y) > 6000 and sim.tick - last_attack > 900 and not _near_site(u) and not _at_flare(u):
			idle.append(u.id)
	if not idle.is_empty():
		sim.push_command({"t": "move", "player": player, "ids": idle, "x": rally.x, "y": rally.y})


## Manda a la amenaza `factor_pct` de los enemigos que hay a `radio` de ella (al menos `minimo`),
## contando a los propios que ya están ahí; los más cercanos primero. Devuelve el resto del ejército.
func _defend_some(army: Array[SimEntity], threat: SimEntity, cfg: Dictionary) -> Array[SimEntity]:
	var r := int(cfg["radio"])
	var enemies := 0
	for e in sim.actives:
		if e.alive and e.owner >= 0 and e.is_unit() and sim.enemies(player, e.owner) and (e.is_military() or e.fn == "explorador") and Sim.dist(e.x, e.y, threat.x, threat.y) <= r:
			enemies += 1
	var need := maxi(int(cfg["minimo"]), enemies * int(cfg["factor_pct"]) / 100)
	var rest: Array[SimEntity] = []
	var cand := []
	for u in army:
		var d := Sim.dist(u.x, u.y, threat.x, threat.y)
		if d <= r:
			need -= 1 # ya está ahí
		elif u.order == O.ATTACK:
			continue # peleando en otro lado: sigue
		elif _at_flare(u):
			rest.append(u)
		else:
			cand.append([d, u.id, u])
	cand.sort_custom(func(a, b): return a[0] < b[0] or a[0] == b[0] and a[1] < b[1])
	var ids := []
	for c in cand:
		if ids.size() < need:
			ids.append((c[2] as SimEntity).id)
		else:
			rest.append(c[2])
	if not ids.is_empty():
		sim.push_command({"t": "move", "player": player, "ids": ids, "x": threat.x, "y": threat.y, "amove": true})
	return rest


## Disputa de sitios (`disputa_sitios`: normal, difícil y experta; reglas.ia_disputa_sitios).
## Como en AoE4: si el rival tiene `sitios_rival_min` sitios o más, o corre su cuenta de victoria,
## un grupo proporcional a lo que defiende el sitio va a recuperar el más barato (cerca y poco
## defendido), y si se acercan enemigos a un sitio propio, un grupo proporcional lo defiende. Sin
## fuerza suficiente no va (nada de goteo) y el grupo se retira si pierde la pelea. Devuelve el
## ejército que queda libre; con la cuenta corriendo y sin fuerza para ir, ninguno (se junta).
## Antes la experta mandaba todo con la cuenta corriendo y las demás solo grupos de 4 (el veterano
## perdió por sitios con 94 militares vivos, ronda 3; proceso/24, paso 5b).
func _contest_sites(army: Array[SimEntity], left: int) -> Array[SimEntity]:
	var cfg := _contest_cfg()
	if cfg.is_empty():
		return army
	var r := int(cfg["radio"])
	var desperate := left >= 0 and left <= int(cfg["desesperado_ms"])
	var free: Array[SimEntity] = []
	var rest: Array[SimEntity] = army
	for u in army:
		if u.order != O.ATTACK and not _at_flare(u):
			free.append(u)
	var none: Array[SimEntity] = []
	if sim.tick - last_contest < int(cfg["cada_ticks"]):
		return none if _contest_held and left >= 0 else rest
	last_contest = sim.tick
	_contest_held = false
	var sites: Array[SimEntity] = []
	var theirs := 0
	for e in sim.actives:
		if e.alive and e.def.get("sagrado", false):
			sites.append(e)
	if sites.is_empty():
		return rest
	var holds := {}
	for st in sites:
		if st.holder >= 0 and sim.enemies(player, st.holder):
			var tm := sim.team_of(st.holder)
			holds[tm] = int(holds.get(tm, 0)) + 1
			theirs = maxi(theirs, int(holds[tm]))
	var pressed := left >= 0 or theirs >= mini(int(cfg["sitios_rival_min"]), sites.size())
	# Refuerzo del grupo que ya va, en bloque de `refuerzo_min` o más.
	if not _squad.is_empty():
		var site: SimEntity = sim.by_id.get(int(_squad["site"]), null)
		if site != null and (left >= 0 or _squad["kind"] == "defiende"):
			var need := _site_need(cfg, site, left >= 0) - _hp_of(_squad["ids"])
			var sent := _pick_for(free, site, need, int(cfg["refuerzo_min"]), desperate)
			if not sent.is_empty():
				_squad["ids"].append_array(sent)
				sim.push_command({"t": "move", "player": player, "ids": sent, "x": site.x, "y": site.y, "amove": true})
				return _without(rest, sent)
		return rest
	# Defender los sitios propios cuando se acercan enemigos.
	for st in sites:
		if st.holder < 0 or sim.enemies(player, st.holder):
			continue
		var foes := _foes_hp(st, int(cfg["defensa_radio"]))
		if foes <= 0:
			continue
		var need := foes * int(cfg["fuerza_pct"]) / 100 - _own_hp_near(st, r)
		if need <= 0:
			continue
		var sent := _pick_for(free, st, need, mini(int(cfg["grupo_min"]), free.size()), false)
		if not sent.is_empty():
			_squad_go(st, sent, "defiende", cfg)
			return _without(rest, sent)
	if not pressed:
		return rest
	# Recuperar: el sitio rival más barato (distancia más defensa) que se pueda con lo que hay.
	var best: SimEntity = null
	var best_cost := 1 << 60
	var best_need := 0
	var free_hp := _hp_of_units(free)
	for st in sites:
		if st.holder < 0 or not sim.enemies(player, st.holder):
			continue
		if not desperate and int(_site_cool.get(st.id, -1)) > sim.tick:
			continue
		var need := _site_need(cfg, st, left >= 0)
		if not desperate and (need > free_hp or free.size() < int(cfg["grupo_min"])):
			continue
		var cost := Sim.dist(st.x, st.y, rally.x, rally.y) / P + _foes_hp(st, r) / int(cfg["hp_por_casilla"])
		if cost < best_cost:
			best_cost = cost
			best = st
			best_need = need
	if best == null:
		# Con la cuenta corriendo y sin fuerza: nada de incursiones ni oleadas, se junta.
		_contest_held = left >= 0
		return none if _contest_held else rest
	var sent := _pick_for(free, best, free_hp + 1 if desperate else best_need, int(cfg["grupo_min"]), desperate)
	if sent.is_empty():
		return rest
	_squad_go(best, sent, "recupera", cfg)
	_say("ataco", {"a": best.holder})
	return _without(rest, sent)


## La configuración de la disputa para esta dificultad (vacía si no disputa). `disputa_sitios`
## puede ser `true` o un diccionario que cambia claves de reglas.ia_disputa_sitios.
func _contest_cfg() -> Dictionary:
	var own: Variant = level.get("disputa_sitios", false)
	if own is bool and not own or not level.get("toma_sitios", true):
		return {}
	var cfg: Dictionary = (sim.data.reglas["ia_disputa_sitios"] as Dictionary).duplicate()
	if own is Dictionary:
		cfg.merge(own, true)
	return cfg


## Lo que falta para ir a un sitio: `fuerza_pct` de la vida de los enemigos que lo cuidan
## (`fuerza_pct_cuenta` con la cuenta corriendo), y al menos `grupo_min` unidades de vida media.
func _site_need(cfg: Dictionary, st: SimEntity, counting: bool) -> int:
	var pct := int(cfg["fuerza_pct_cuenta"] if counting else cfg["fuerza_pct"])
	return _foes_hp(st, int(cfg["radio"])) * pct / 100


## Vida de los militares enemigos a `r` del sitio.
func _foes_hp(st: SimEntity, r: int) -> int:
	return _foes_hp_at(st.x, st.y, r)


## Vida de los militares enemigos a `r` de un punto (cuadro, como la captura de los sitios).
func _foes_hp_at(x: int, y: int, r: int) -> int:
	var hp := 0
	for e in sim.military():
		if e.alive and e.owner >= 0 and e.is_unit() and e.inside < 0 and e.is_military() and sim.enemies(player, e.owner) and absi(e.x - x) <= r and absi(e.y - y) <= r:
			hp += e.hp
	return hp


## Vida de los militares propios a `r` del sitio.
func _own_hp_near(st: SimEntity, r: int) -> int:
	var hp := 0
	for e in sim.owned(player):
		if e.alive and e.owner == player and e.is_unit() and e.inside < 0 and e.is_military() and absi(e.x - st.x) <= r and absi(e.y - st.y) <= r:
			hp += e.hp
	return hp


func _hp_of(ids: Array) -> int:
	var hp := 0
	for id in ids:
		var u: SimEntity = sim.by_id.get(id, null)
		if u != null and u.alive:
			hp += u.hp
	return hp


func _hp_of_units(list: Array[SimEntity]) -> int:
	var hp := 0
	for u in list:
		hp += u.hp
	return hp


## Los más cercanos al sitio hasta juntar `need` de vida y `min_n` unidades; vacío si no se llega
## (salvo `all_in`: entonces van los que haya).
func _pick_for(free: Array[SimEntity], st: SimEntity, need: int, min_n: int, all_in: bool) -> Array:
	var cand := []
	for u in free:
		cand.append([Sim.dist(u.x, u.y, st.x, st.y), u.id, u])
	cand.sort_custom(func(a, b): return a[0] < b[0] or a[0] == b[0] and a[1] < b[1])
	var ids := []
	var hp := 0
	for c in cand:
		if hp >= need and ids.size() >= min_n:
			break
		ids.append(c[1])
		hp += (c[2] as SimEntity).hp
	if (hp < need or ids.size() < min_n) and not all_in:
		return []
	return ids


func _without(list: Array[SimEntity], ids: Array) -> Array[SimEntity]:
	var out: Array[SimEntity] = []
	for u in list:
		if not ids.has(u.id):
			out.append(u)
	return out


func _squad_go(st: SimEntity, ids: Array, kind: String, cfg: Dictionary) -> void:
	_squad = {"site": st.id, "ids": ids, "kind": kind, "hasta": sim.tick + int(cfg["grupo_max_ticks"])}
	sim.push_command({"t": "move", "player": player, "ids": ids, "x": st.x, "y": st.y, "amove": true})


## El grupo en marcha: se disuelve si el sitio quedó en manos propias sin enemigos cerca o se
## venció el plazo; se retira (y el sitio espera `espera_tras_retirada_ticks`) si su vida queda por
## debajo de `retirada_pct` de la de los enemigos del sitio, salvo que la cuenta esté por terminar.
func _squad_step(cfg: Dictionary, desperate: bool) -> void:
	var alive := []
	var cx := 0
	var cy := 0
	for id in _squad["ids"]:
		var u: SimEntity = sim.by_id.get(id, null)
		if u != null and u.alive:
			alive.append(id)
			cx += u.x
			cy += u.y
	_squad["ids"] = alive
	var st: SimEntity = sim.by_id.get(int(_squad["site"]), null)
	if alive.is_empty() or st == null or not st.alive or sim.tick > int(_squad["hasta"]):
		_squad = {}
		return
	# La pelea puede ser en el camino: cuentan los enemigos del sitio o los de alrededor del grupo.
	var foes := _foes_hp(st, int(cfg["radio"]))
	var ours_now := st.holder >= 0 and not sim.enemies(player, st.holder)
	if ours_now and foes == 0:
		_squad = {}
		return
	foes = maxi(foes, _foes_hp_at(cx / alive.size(), cy / alive.size(), int(cfg["radio"])))
	if not desperate and foes > 0 and _hp_of(alive) * 100 < foes * int(cfg["retirada_pct"]):
		_site_cool[st.id] = sim.tick + int(cfg["espera_tras_retirada_ticks"])
		sim.push_command({"t": "move", "player": player, "ids": alive, "x": rally.x, "y": rally.y, "suelto": true})
		_squad = {}


## Milisegundos que le faltan a la cuenta de sitios rival más avanzada; -1 si no corre ninguna.
func _site_clock() -> int:
	var left := -1
	var total := int(sim.data.reglas["sitios"]["victoria_ms"])
	for q in sim.players:
		if sim.enemies(player, q["id"]) and int(q.get("sitios_ms", 0)) > 0:
			var l := total - int(q["sitios_ms"])
			if left < 0 or l < left:
				left = l
	return left


## Hito rival en obra (`ataca_hito_en_obra`, reglas.ia_hito_en_obra): es el blanco más rico
## de la partida, como el landmark de AoE4 (95–125 s de obra). Con `ejercito_min` o más, el
## ejército libre va a pegarle, cada `cada_ticks`; nadie vuelve al punto de reunión mientras
## (veterano, ronda 3: ningún enemigo se acercaba a 12 casillas de un hito en obra).
func _hit_hito(army: Array[SimEntity]) -> bool:
	if not level.get("ataca_hito_en_obra", false):
		return false
	var cfg: Dictionary = sim.data.reglas["ia_hito_en_obra"]
	if army.size() < int(cfg["ejercito_min"]) or sim.tick - last_hito_hit < int(cfg["cada_ticks"]):
		return false
	var ref := army[0]
	var target: SimEntity = null
	var best_d := 1 << 60
	for e in sim.all_buildings():
		if e.alive and e.is_building() and not e.built and e.owner >= 0 and sim.enemies(player, e.owner) and e.def.get("hito", false):
			var d := sim.dist_to(ref, e)
			if d < best_d:
				best_d = d
				target = e
	if target == null:
		return false
	last_hito_hit = sim.tick
	var ids := []
	for u in army:
		if u.order != O.ATTACK and not _at_flare(u):
			ids.append(u.id)
	if ids.is_empty():
		return true
	focus = target.owner
	_say("ataco", {"a": target.owner})
	sim.push_command({"t": "target", "player": player, "ids": ids, "target": target.id})
	return true


# --- paso 7 --- Edad IV y maravilla (docs/diseno/27, §4; reglas.ia_edad_iv e ia_maravilla)

## ¿Ahorra sin pausa para el hito de la IV? Solo las dificultades con `sube_a_la_iv`, desde
## `desde_edad`, con `aldeanos_min` aldeanos, el ejército mínimo de la edad hecho y sin un rival
## que le saque más de `rival_pct_max` % de ejército (el mayor que vio hace poco). Antes la IA
## normal ahorraba un tercio del tiempo y en 45 minutos casi nunca llegaba (proceso/26, 07 y 10).
func _wants_up(p: Dictionary, n_vill: int) -> bool:
	var cfg: Dictionary = sim.data.reglas.get("ia_edad_iv", {})
	if cfg.is_empty() or not level.get("sube_a_la_iv", false) or int(p["age"]) < int(cfg["desde_edad"]):
		return false
	if n_vill < int(cfg["aldeanos_min"]) or _army_n < _min_army(p):
		return false
	return not _rival_ahead(int(cfg["rival_pct_max"]), int(cfg["memoria_ticks"]))


## ¿El mayor ejército rival visto en `memory` ticks supera `pct` % del propio?
func _rival_ahead(pct: int, memory: int) -> bool:
	return sim.tick - _seen_tick <= memory and _seen * 100 > maxi(1, _army_n) * pct


## La maravilla que este pueblo puede levantar ahora ("" si ninguna: ya tiene una, le falta la
## vía o el Pacto de Cucaú la impide).
func _wonder_type() -> String:
	var dd := sim.dp(player)
	for t: String in dd.unidades["aldeano"].get("construye", []):
		if dd.edificios.get(t, {}).get("maravilla", false) and sim.build_block(player, t) == "":
			return t
	return ""


## ¿Ahorra para la maravilla? En la IV, `tras_iv_ticks` después de llegar, con `aldeanos_min`
## aldeanos y `ejercito_min` de tropa, sin la base atacada (salvo con `ejercito_min`), sin un rival más fuerte a la vista y
## sin una maravilla rival en pie (a esa se la va a romper: `_hit_wonder`). Sin la victoria por
## maravilla no la levanta.
func _wants_wonder(p: Dictionary, n_vill: int, threatened: bool) -> bool:
	var cfg: Dictionary = sim.data.reglas.get("ia_maravilla", {})
	if cfg.is_empty() or not level.get("maravilla", false) or int(p["age"]) < 4:
		return false
	# Con la base atacada sigue juntando si tiene tropa; si no, primero la defensa.
	if threatened and _army_n < int(cfg["ejercito_min"]):
		return false
	if sim._opts.get("maravilla_sin_victoria", false) or sim.scenario != null:
		return false
	if sim.tick - _age4_tick < int(cfg["tras_iv_ticks"]) or n_vill < int(cfg["aldeanos_min"]) or _army_n < int(cfg["ejercito_min"]):
		return false
	if _rival_ahead(int(cfg["rival_pct_max"]), int(cfg["memoria_ticks"])) or _rival_wonder() != null:
		return false
	return _wonder_type() != ""


## ¿Lo que se ahorra este turno es la maravilla?
func _goal_is_wonder() -> bool:
	return sim.dp(player).edificios.get(_goal, {}).get("maravilla", false)


## Ya decidida la maravilla, sigue juntando mientras se pueda levantar, no haya una rival y le
## quede al menos `sigue_ejercito_pct` % de `ejercito_min` (si no, el banco se iba en tropa cada vez
## que bajaba un soldado del mínimo y no se juntaba nunca).
func _keeps_wonder() -> bool:
	var cfg: Dictionary = sim.data.reglas["ia_maravilla"]
	return _wonder_type() != "" and _rival_wonder() == null and _army_n * 100 >= int(cfg["ejercito_min"]) * int(cfg["sigue_ejercito_pct"])


## Lo que cuesta lo que se ahorra este turno (el hito o la maravilla).
func _goal_cost(p: Dictionary) -> Dictionary:
	return sim.dp(player).cost_of(_goal, p["age"])


## Cuántos aldeanos van a la obra de lo que se ahorra.
func _goal_builders() -> int:
	if sim.dp(player).edificios.get(_goal, {}).get("maravilla", false):
		return int(sim.data.reglas["ia_maravilla"]["constructores"])
	return int(level.get("hito_constructores", 4))


## La maravilla rival más cercana a la base (en obra o terminada), o null.
func _rival_wonder() -> SimEntity:
	var best: SimEntity = null
	var best_d := 1 << 60
	for e in sim.all_buildings():
		if e.alive and e.is_building() and e.owner >= 0 and sim.enemies(player, e.owner) and e.def.get("maravilla", false):
			var d := Sim.dist(e.x, e.y, rally.x, rally.y)
			if d < best_d:
				best_d = d
				best = e
	return best


## Maravilla rival (reglas.ia_maravilla.ataque): es el blanco que decide la partida. Con
## `ejercito_min` o más, todo el ejército libre va a romperla cada `cada_ticks`; terminada y con
## la cuenta corriendo, va aunque sea poco. A la sitiada (Palmares) se la rodea: con tropa
## adentro su cuenta se corta.
func _hit_wonder(army: Array[SimEntity]) -> bool:
	var cfg: Dictionary = sim.data.reglas.get("ia_maravilla", {}).get("ataque", {})
	if cfg.is_empty() or not level.get("ataca_maravilla", false) or army.is_empty():
		return false
	var target := _rival_wonder()
	if target == null:
		return false
	var counting := target.built
	if army.size() < int(cfg["ejercito_min"]) and not counting:
		return false
	if sim.tick - last_wonder_hit < int(cfg["cada_ticks"]):
		return true # sigue a lo suyo: nadie vuelve al punto de reunión mientras
	last_wonder_hit = sim.tick
	var ids := []
	for u in army:
		if u.order != O.ATTACK and not _at_flare(u):
			ids.append(u.id)
	if ids.is_empty():
		return true
	focus = target.owner
	_say("ataco", {"a": target.owner})
	sim.push_command({"t": "target", "player": player, "ids": ids, "target": target.id})
	return true


## Base rival: sus edificios principales (capital, centros e hitos).
func _enemy_cores() -> Array[SimEntity]:
	var out: Array[SimEntity] = []
	for e in sim.actives:
		if e.alive and e.is_building() and e.owner >= 0 and sim.enemies(player, e.owner) and (e.capital or e.def.get("hito", false) or e.def.has("produce") and e.def.get("deposito", []).size() > 2):
			out.append(e)
	return out


## Vuelve al punto de reunión quien haya entrado a la base rival.
func _leash(army: Array[SimEntity], radius: int, idle_only: bool = false) -> void:
	var cores := _enemy_cores()
	var back := []
	for u in army:
		if idle_only and u.order != O.IDLE or _at_flare(u):
			continue
		for c in cores:
			if Sim.dist(u.x, u.y, c.x, c.y) < radius:
				back.append(u.id)
				break
	if not back.is_empty():
		# Retirada suelta: cada uno a su velocidad, sin esperar a la formación.
		sim.push_command({"t": "move", "player": player, "ids": back, "x": rally.x, "y": rally.y, "suelto": true})


## Punto del mapa para ocupar: un sitio sagrado ajeno, o el centro del mapa,
## siempre fuera del radio de las bases rivales si el estilo lo pide.
func _map_spot(radius: int) -> Vector2i:
	var cores := _enemy_cores()
	var options: Array[Vector2i] = []
	for e in sim.actives:
		if e.alive and e.def.get("sagrado", false) and (e.holder < 0 or sim.enemies(player, e.holder)) and level.get("toma_sitios", true) and sim.can_take_sites(player): # --- esport 1a ---
			options.append(Vector2i(e.x, e.y))
	# El centro también tiene un sitio en 1 contra 1: la IA que no toma sitios (la fácil) no
	# va ahí, se queda en su punto de reunión (jugadores de prueba, ronda 2).
	if level.get("toma_sitios", true):
		var c := sim.map.n * P / 2
		options.append(Vector2i(c, c))
	for o in options:
		var ok := true
		for core in cores:
			if radius > 0 and Sim.dist(o.x, o.y, core.x, core.y) < radius:
				ok = false
		if ok:
			return o
	return Vector2i(-1, -1)


func _attack(army: Array[SimEntity]) -> void:
	var target: SimEntity = null
	var best_d := 1 << 60
	var ref := army[0]
	focus = _pick_rival(ref)
	# Ronda 8: lo que las aliadas atacaron hace poco no se repite (otro frente), si hay otro blanco.
	var taken := {}
	var esc := _escalon()
	for ai in sim.ais:
		if ai != self and ai.player != player and not sim.enemies(player, ai.player) and ai.last_target >= 0 and sim.tick - ai.eta < esc:
			taken[ai.last_target] = true
	var alt: SimEntity = null
	var best_alt := 1 << 60
	for e in sim.actives:
		# También lo que cuenta para la victoria (mocambos, lofs): si no, un rival sin ejército
		# seguía vivo para siempre (todos contra todos abierto a los 60 minutos, proceso/22).
		# Sin victoria por hitos (opciones de partida), cualquier edificio que cuente: Sim.counts_for_victory.
		if e.alive and e.is_building() and e.owner >= 0 and sim.enemies(player, e.owner) and sim.counts_for_victory(e):
			if focus >= 0 and e.owner != focus:
				continue
			var d := sim.dist_to(ref, e)
			if d < best_d:
				target = e
				best_d = d
			if d < best_alt and not e.id in taken:
				alt = e
				best_alt = d
	if target == null:
		return
	if alt != null:
		target = alt
	last_target = target.id
	_say("ataco", {"a": target.owner})
	var ids := []
	for u in army:
		if not _at_flare(u): # --- equipos ronda 3 --- los que van a la bengala siguen a lo suyo
			ids.append(u.id)
	# Se para del lado de quien llega, a 3 casillas del blanco.
	var dx := ref.x - target.x
	var dy := ref.y - target.y
	var l := maxi(1, Sim.isqrt(dx * dx + dy * dy))
	sim.push_command({"t": "move", "player": player, "ids": ids, "x": target.x + dx * 3000 / l, "y": target.y + dy * 3000 / l, "amove": true})
	_wave_ids = ids
	_wave_pt = Vector2i(target.x, target.y)
	_track_wave(true) # recién salen: todavía no están en marcha


## Desfase entre las oleadas de un mismo equipo (reglas.json → equipos.ia_escalon; la
## dificultad puede traer su `escalon_ticks`).
func _escalon() -> int:
	return int(level.get("escalon_ticks", sim.data.reglas["equipos"].get("ia_escalon", {}).get("desfase_ticks", 0)))


## Ronda 8: ¿le toca a esta IA largar su oleada? No, si una IA aliada largó la suya hace menos
## del desfase, ni mientras esa oleada siga en marcha (hasta `marcha_max_ticks` desde que
## salió) o haya llegado hace menos del desfase: así llegan de a una aunque el camino de una
## sea más largo. Con `escalon_marcha: false` (la fácil, que tiene poca tropa y el mapa grande
## la dejaba casi sin atacar) cuenta solo el desfase entre salidas. Estimar la llegada no
## alcanzaba: un río o un bosque alargan el camino y las oleadas se juntaban igual. Antes, en
## el 1 contra 6, las seis fáciles salían en el mismo minuto y llegaban 90 soldados juntos;
## ahora llegan de a una, como un equipo que se turna: entre las que esperan, va primero la
## que espera desde antes (proceso/32-ronda-8).
func _team_turn() -> bool:
	var cfg: Dictionary = sim.data.reglas["equipos"].get("ia_escalon", {})
	var d := _escalon()
	if d <= 0:
		return true
	var march: bool = level.get("escalon_marcha", true) # la fácil: solo el desfase entre salidas
	for ai in sim.ais:
		if ai != self and ai.player != player and not sim.enemies(player, ai.player) and not sim.players[ai.player]["defeated"]:
			var since: int = sim.tick - ai.last_attack
			if since < d or march and (ai.eta > sim.tick - d or not ai._wave_ids.is_empty() and since < int(cfg.get("marcha_max_ticks", 0))):
				return false
			# Por turno: la aliada que espera desde antes va primero (si no, la que repetía
			# oleadas cada 50 s no dejaba salir nunca a otra).
			if ai.ready_since >= 0 and sim.tick - ai.ready_seen <= int(cfg.get("lista_vigente_ticks", 0)):
				if ai.ready_since < ready_since or ai.ready_since == ready_since and ai.player < player:
					return false
	return true


## Corrige la llegada estimada de la oleada en marcha: desde el centro de los que siguen vivos,
## en línea recta y al paso medio. Si el camino es más largo que la recta, la estimación se
## corre sola. Llegó cuando el centro está a `equipos.ia_escalon.llegada` del blanco, cuando
## menos de la mitad sigue en marcha (pelea en el camino o ya volvió) o pasado `marcha_max_ticks`.
func _track_wave(leaving: bool = false) -> void:
	if _wave_ids.is_empty():
		return
	var cfg: Dictionary = sim.data.reglas["equipos"].get("ia_escalon", {})
	var going := 0
	var sx := 0
	var sy := 0
	var sp := 0
	var n := 0
	for id in _wave_ids:
		var u: SimEntity = sim.by_id.get(id)
		if u != null and u.alive and u.speed > 0:
			sx += u.x
			sy += u.y
			sp += u.speed
			n += 1
			if u.order == O.ATTACK_MOVE or u.order == O.MOVE:
				going += 1
	if n == 0:
		_wave_ids = []
		return
	var d := Sim.dist(sx / n, sy / n, _wave_pt.x, _wave_pt.y)
	if d <= int(cfg.get("llegada", 0)) or not leaving and going * 2 < n or sim.tick - last_attack > int(cfg.get("marcha_max_ticks", 0)):
		_wave_ids = []
		eta = sim.tick
		return
	eta = sim.tick + d / maxi(1, sp / n)


## Cacería (sin victoria por hitos, opciones de partida): cuando el rival elegido ya casi no
## tiene ejército (`ia_caza.ejercito_rival_max`) o se le saca `ia_caza.ventaja_pct`, el ejército se reparte en grupos de
## `ia_caza.grupo` y cada grupo va al siguiente edificio que cuenta para la victoria, del más
## cercano al más lejano, cada `ia_caza.cada_ticks`. Antes la IA esperaba la oleada siguiente
## (cada vez más grande) y volvía a reunirse: al mapuche le quedaban 41 edificios a los 45
## minutos (proceso/24, paso 4b). Con hitos no cambia nada.
func _hunt(army: Array[SimEntity]) -> bool:
	if not sim._opts.get("hitos_sin_victoria", false):
		return false
	var cfg: Dictionary = sim.data.reglas["ia_caza"]
	if sim.tick - last_hunt < int(cfg["cada_ticks"]):
		return false
	last_hunt = sim.tick
	var ref := army[0]
	var rival := _pick_rival(ref)
	if rival < 0:
		return false
	var rival_army := 0
	for e in sim.owned(rival):
		if e.alive and e.owner == rival and e.is_unit() and e.is_military():
			rival_army += 1
	# También cuando se le saca `ventaja_pct` de ventaja: si no, una guerra pareja de 40 minutos
	# terminaba recién cuando el rival se quedaba sin nadie.
	if rival_army > int(cfg["ejercito_rival_max"]) and army.size() * 100 < rival_army * int(cfg["ventaja_pct"]):
		return false
	var targets := []
	for e in sim.buildings_of(rival):
		if e.alive and e.owner == rival and e.is_building() and sim.counts_for_victory(e):
			targets.append([sim.dist_to(ref, e), e.id, e])
	if targets.is_empty():
		return false
	targets.sort_custom(func(a, b): return a[0] < b[0] or a[0] == b[0] and a[1] < b[1])
	# Solo los que no van ya a un blanco (los de ATTACK_MOVE siguen a lo suyo).
	var free: Array[SimEntity] = []
	for u in army:
		if (u.order == O.IDLE or u.order == O.MOVE) and not _at_flare(u):
			free.append(u)
	if free.is_empty():
		return true
	var size := maxi(1, int(cfg["grupo"]))
	var i := 0
	var k := 0
	while i < free.size():
		var ids := []
		for j in range(i, mini(i + size, free.size())):
			ids.append(free[j].id)
		var t: SimEntity = targets[k % targets.size()][2]
		sim.push_command({"t": "move", "player": player, "ids": ids, "x": t.x, "y": t.y, "amove": true})
		i += size
		k += 1
	focus = rival
	last_attack = sim.tick # que nadie vuelva al punto de reunión mientras caza
	return true


## Animal propio más cercano a la capital que nadie esté carneando (el que ya tiene un
## aldeano encima se deja). Un objetivo por pensada: si no, todos van al mismo.
func _own_animal(centro: SimEntity) -> SimEntity:
	var best: SimEntity = null
	var bd := 1 << 60
	for e in sim.owned(player):
		if e.alive and e.owner == player and e.def.get("animal", false):
			var d := sim.dist_to(e, centro)
			if d < bd:
				bd = d
				best = e
	return best


## Explorador y rebaño (como AoE4, proceso/23): el explorador va a los animales sueltos más
## cercanos para reclamarlos, y los animales propios lejos de la capital se arrean a casa.
func _animals(centro: SimEntity) -> void:
	var every := int(sim.data.reglas["animales"]["arreo_cada_ticks"])
	if (sim.tick + player * 7) % every != 0:
		return
	var scouts: Array = []
	var far := []
	for e in sim.owned(player):
		if not e.alive or e.owner != player or not e.is_unit():
			continue
		if e.fn == "explorador" and e.order == O.IDLE:
			scouts.append(e)
		elif e.def.get("animal", false) and e.order == O.IDLE and sim.dist_to(e, centro) > 6000:
			far.append(e.id)
	if not far.is_empty():
		sim.push_command({"t": "move", "player": player, "ids": far, "x": centro.x + 3000, "y": centro.y + 3000, "suelto": true})
	if scouts.is_empty():
		return
	var wild: SimEntity = null
	var wd := 60000
	for e in sim.entities:
		if e.alive and e.is_resource() and e.def.get("reclamable", false):
			var d := sim.dist_to(e, centro)
			if d < wd:
				wd = d
				wild = e
	if wild != null:
		sim.push_command({"t": "move", "player": player, "ids": [scouts[0].id], "x": wild.x, "y": wild.y})


## Rival del próximo ataque. Si un aliado ya va contra alguien, se suma; si no,
## el estilo elige: el más cercano o el de menos ejército.
func _pick_rival(ref: SimEntity) -> int:
	for ai in sim.ais:
		if ai != self and ai.focus >= 0 and not sim.enemies(player, ai.player) and ai.player != player:
			if sim.enemies(player, ai.focus) and not sim.players[ai.focus]["defeated"]:
				return ai.focus
	var st: Dictionary = sim.data.reglas.get("estilos_ia", {}).get(personality, {})
	var how: String = st.get("objetivo", "cercano")
	var best := -1
	var best_v := 1 << 60
	for j in sim.players.size():
		if not sim.enemies(player, j) or sim.players[j]["defeated"] or j >= sim.bases.size():
			continue
		var v := 0
		if how == "debil":
			for e in sim.owned(j):
				if e.alive and e.owner == j and e.is_military():
					v += 1
		else:
			var b := sim.bases[j]
			v = Sim.dist(b.x * P, b.y * P, ref.x, ref.y)
		if v < best_v:
			best_v = v
			best = j
	return best


## Unidad que fue a la bengala de un aliado y todavía está en eso: nadie la desvía.
func _at_flare(u: SimEntity) -> bool:
	return int(_flare_units.get(u.id, -1)) >= sim.tick


## El aliado al que pertenece lo que ataca `t`: el dueño del edificio aliado más cercano.
func _ally_under(t: SimEntity) -> int:
	var best := -1
	var best_d := 1 << 60
	for e in sim.all_buildings():
		if e.alive and e.is_building() and e.owner >= 0 and e.owner != player and not sim.enemies(player, e.owner):
			var d := sim.dist_to(t, e)
			if d < best_d:
				best_d = d
				best = e.owner
	return best


## Amenaza en la base de un aliado cercano: el ejército va a ayudar.
func _ally_threat(centro: SimEntity) -> SimEntity:
	var eq: Dictionary = sim.data.reglas.get("equipos", {})
	var radius := int(eq.get("ia_ayuda_radio", 0))
	var near := int(eq.get("ia_ayuda_amenaza", 22000))
	if radius <= 0:
		return null
	for e in sim.all_buildings():
		if not e.alive or not e.is_building() or not e.capital or e.owner == player or e.owner < 0 or sim.enemies(player, e.owner):
			continue
		if Sim.dist(e.x, e.y, centro.x, centro.y) > radius:
			continue
		for t in sim.military():
			if t.alive and t.owner >= 0 and sim.enemies(player, t.owner) and t.is_military() and sim.dist_to(t, e) < near:
				return t
	return null


## Tributo: lo que sobra va al aliado al que le falta (reglas.equipos.ia_tributo).
func _tribute(p: Dictionary, saving: bool) -> void:
	var cfg: Dictionary = sim.data.reglas.get("equipos", {}).get("ia_tributo", {})
	if cfg.is_empty() or saving or sim.tick < int(cfg.get("desde_ticks", 0)) or sim.tick - last_tribute < int(cfg["cada_ticks"]):
		return
	if not _asks.is_empty(): # --- equipos ronda 3 --- con un pedido esperando, nada de regalos
		return
	last_tribute = sim.tick
	for kind in ["alimento", "madera", "piedra", "riqueza"]:
		if int(p["res"].get(kind, 0)) <= int(cfg["sobra"]):
			continue
		for j in sim.players.size():
			if j == player or sim.enemies(player, j) or sim.team_of(j) != sim.team_of(player) or sim.players[j]["defeated"]:
				continue
			if int(sim.players[j]["res"].get(kind, 0)) < int(cfg["falta"]):
				sim.push_command({"t": "tributo", "player": player, "a": j, "recurso": kind, "n": int(cfg["lote"])})
				_say("mando", {"a": j, "recurso": kind, "n": int(cfg["lote"])}, true)
				return


## Frase en el chat del equipo (suceso "ia_dice"). Solo si tiene aliados; no repite la
## misma antes de `ia_frases_calma_ticks` salvo `always` (respuestas a un pedido o bengala).
func _say(key: String, extra: Dictionary, always: bool = false) -> void:
	var has_ally := false
	for j in sim.players.size():
		if j != player and not sim.enemies(player, j) and not sim.players[j]["defeated"]:
			has_ally = true
	if not has_ally:
		return
	var calm := int(sim.data.reglas["equipos"]["ia_frases_calma_ticks"])
	if not always and sim.tick - int(_said.get(key, -calm - 1)) <= calm:
		return
	_said[key] = sim.tick
	sim.say(player, key, extra)


## --- equipos ronda 3 --- Pedidos de recursos de un aliado. Pesan más que el tributo espontáneo:
## se atienden primero en cada pensada, con un margen más chico (`pedido.sobra`), y mientras
## esperan no hay regalos. Si no alcanza, el pedido espera hasta `pedido.espera_ticks`; al vencer,
## manda otro recurso que le sobre (`pedido.sobra_otro`) o avisa que no puede. Antes se
## contestaba una sola vez y la madera nunca alcanzaba (3 de 18, ronda 3).
func _requests(p: Dictionary) -> void:
	var cfg: Dictionary = sim.data.reglas["equipos"]["pedido"]
	if not sim.requests.is_empty():
		var keep: Array[Dictionary] = []
		for r in sim.requests:
			if int(r["a"]) != player:
				keep.append(r)
				continue
			var dup := false # el mismo pedido otra vez mientras espera: sigue el primero
			for q in _asks:
				dup = dup or (int(q["de"]) == int(r["de"]) and q["recurso"] == r["recurso"])
			if dup:
				continue
			_asks.append({"de": int(r["de"]), "recurso": r["recurso"], "n": int(r["n"]), "hasta": sim.tick + int(cfg.get("espera_ticks", 0))})
		sim.requests = keep
	if _asks.is_empty():
		return
	var left: Array[Dictionary] = []
	var gave := false
	for a in _asks:
		var to := int(a["de"])
		if sim.players[to]["defeated"] or gave:
			if not sim.players[to]["defeated"]:
				left.append(a)
			continue
		var kind: String = a["recurso"]
		var n := int(a["n"])
		if int(p["res"].get(kind, 0)) >= n + int(cfg["sobra"]):
			sim.push_command({"t": "tributo", "player": player, "a": to, "recurso": kind, "n": n})
			_say("mando", {"a": to, "recurso": kind, "n": n}, true)
			gave = true # uno por pensada: el banco se lee antes de que el tributo lo descuente
		elif sim.tick >= int(a["hasta"]):
			var other := ""
			for k in ["alimento", "madera", "piedra", "riqueza"]:
				if k != kind and int(p["res"].get(k, 0)) >= n + int(cfg.get("sobra_otro", 1 << 30)):
					other = k
					break
			if other != "":
				sim.push_command({"t": "tributo", "player": player, "a": to, "recurso": other, "n": n})
				_say("mando_otro", {"a": to, "recurso": other, "pedido": kind, "n": n}, true)
				gave = true
			else:
				_say("no_sobra", {"a": to, "recurso": kind}, true)
		else:
			if not a.get("avisado", false):
				a["avisado"] = true
				_say("junto", {"a": to, "recurso": kind}, true)
			left.append(a)
	_asks = left


## Bengalas de un aliado: manda una parte del ejército libre (reglas.equipos.bengala).
func _flares(army: Array[SimEntity], centro: SimEntity) -> void:
	# --- equipos ronda 3 --- la bengala que espera tropa sale apenas se junta el grupo, también
	# si la IA está ayudando a un aliado; con la base propia atacada, no.
	_flare_march_step()
	if not _flare_wave.is_empty() and _threat(centro) == null:
		_flare_wave_go(army)
	if sim.flares.is_empty():
		return
	var cfg: Dictionary = sim.data.reglas["equipos"]["bengala"]
	for f in sim.flares:
		var fid := int(f["id"])
		var from := int(f["player"])
		if _flares_done.has(fid) or from == player or sim.enemies(player, from) or sim.team_of(from) != sim.team_of(player):
			continue
		_flares_done[fid] = true
		if f["tipo"] == "mirar": # --- fluidez 4 --- «mirá acá» es solo para que lo vean
			continue
		if Sim.dist(centro.x, centro.y, int(f["x"]), int(f["y"])) > int(cfg["ia_radio"]):
			continue
		var free: Array[SimEntity] = []
		for u in army:
			if u.order != O.ATTACK:
				free.append(u)
		var fx := int(f["x"])
		var fy := int(f["y"])
		# --- equipos ronda 3 --- Ataque: no un piquete de 3 a 7 que se queda a mitad de camino
		# (1 de 4 llegó, ronda 3), sino un grupo de al menos `ia_grupo_min`: el ejército libre
		# entero si alcanza; si no, la bengala espera a la próxima oleada (`_flare_wave_go`).
		if f["tipo"] == "atacar" and int(cfg.get("ia_grupo_min", 0)) > 0:
			if not _flare_send(army, fx, fy, from):
				_flare_wave = {"x": fx, "y": fy, "de": from, "hasta": sim.tick + int(cfg["ia_espera_ticks"])}
				_say("voy_oleada", {"a": from}, true)
			continue
		# --- fin equipos ronda 3 ---
		if free.size() < int(cfg["ia_min"]):
			_say("sin_tropa", {"a": from}, true)
			continue
		free.sort_custom(func(a: SimEntity, b: SimEntity) -> bool:
			var da := Sim.dist(a.x, a.y, fx, fy)
			var db := Sim.dist(b.x, b.y, fx, fy)
			return da < db if da != db else a.id < b.id)
		var n := maxi(int(cfg["ia_min"]), free.size() * int(cfg["ia_parte_pct"]) / 100)
		var ids := []
		for i in mini(n, free.size()):
			ids.append(free[i].id)
			_flare_units[free[i].id] = sim.tick + int(cfg["dura_ticks"]) * 4
		sim.push_command({"t": "move", "player": player, "ids": ids, "x": fx, "y": fy, "amove": true})
		_say("voy_" + str(f["tipo"]), {"a": from, "n": ids.size()}, true)


# --- equipos ronda 3 ---
## Manda a la bengala de ataque todo el ejército libre si junta `ia_grupo_min`: se reúne en el
## punto de reunión y sale en formación (la que se rinde a mitad de camino era la tropa suelta).
## Quedan protegidos `ia_queda_ticks` de las otras órdenes de la IA (reunirse, incursiones,
## oleadas, defensa): antes se liberaban a los 60 s, a mitad de camino.
func _flare_send(army: Array[SimEntity], fx: int, fy: int, from: int) -> bool:
	var cfg: Dictionary = sim.data.reglas["equipos"]["bengala"]
	var ids := []
	for u in army:
		if u.order != O.ATTACK and not _at_flare(u):
			ids.append(u.id)
	if ids.size() < int(cfg["ia_grupo_min"]):
		return false
	for id in ids:
		_flare_units[id] = sim.tick + int(cfg["ia_queda_ticks"])
	# Marcha en grupo, sin pelear, hasta `ia_escala` antes de la bengala, y desde ahí ataca hasta
	# ella. Con ataque en movimiento desde el principio, un hondero que le tiraba a un ingenio
	# neutral (hostil, mucha vida) plantaba a todo el grupo en combate durante minutos, a mitad de
	# camino (traza de la ronda 3), y las peleas del camino lo desarmaban: llegaban 39 de 86
	# enviados; sin pelear, 69 de 105 (proceso/24, paso 4l).
	var cx := 0
	var cy := 0
	for u in army:
		if ids.has(u.id):
			cx += u.x
			cy += u.y
	cx /= ids.size()
	cy /= ids.size()
	var l := maxi(1, Sim.dist(cx, cy, fx, fy))
	var esc := mini(int(cfg["ia_escala"]), l)
	var sx := fx + (cx - fx) * esc / l
	var sy := fy + (cy - fy) * esc / l
	_flare_march = {"x": fx, "y": fy, "sx": sx, "sy": sy, "ids": ids, "hasta": sim.tick + int(cfg["ia_queda_ticks"])}
	sim.push_command({"t": "move", "player": player, "ids": ids, "x": sx, "y": sy})
	_say("voy_atacar", {"a": from, "n": ids.size()}, true)
	last_attack = sim.tick # cuenta como oleada: la próxima espera lo de siempre
	wave += 1
	_flare_wave = {}
	return true


## Lo que un aliado pidió se aparta mientras la IA decide en qué gastar: ve `lote + sobra`
## menos del recurso pedido, así no se lo gasta y el pedido se cumple en una pensada siguiente.
## Antes la madera nunca alcanzaba: la IA la gastaba apenas entraba (0 de 6 pedidos de madera).
## Se aparta y se devuelve dentro de la misma pensada (`sign` 1 y -1): el banco real no cambia.
func _reserve(p: Dictionary, sign: int, held: Dictionary = {}) -> Dictionary:
	if sign < 0:
		for k in held:
			p["res"][k] = int(p["res"][k]) + int(held[k])
		return {}
	var out := {}
	if _asks.is_empty():
		return out
	var cfg: Dictionary = sim.data.reglas["equipos"]["pedido"]
	for a in _asks:
		var k: String = a["recurso"]
		var want := int(a["n"]) + int(cfg["sobra"]) - int(out.get(k, 0))
		var take := clampi(want, 0, int(p["res"].get(k, 0)))
		if take > 0:
			out[k] = int(out.get(k, 0)) + take
			p["res"][k] = int(p["res"][k]) - take
	return out


## Tropa en marcha a una bengala de ataque: cuando la mayoría llegó a la escala (o ya nadie
## camina), todos los que siguen vivos atacan en movimiento hasta la bengala. Si alguno quedó
## pegándole a algo neutral (un ingenio), lo deja y sigue a la escala.
func _flare_march_step() -> void:
	if _flare_march.is_empty():
		return
	var cfg: Dictionary = sim.data.reglas["equipos"]["bengala"]
	var alive := []
	var near := 0
	var walking := 0
	var neutral := []
	for id in _flare_march["ids"]:
		var u: SimEntity = sim.by_id.get(id)
		if u == null or not u.alive:
			continue
		alive.append(id)
		if Sim.dist(u.x, u.y, int(_flare_march["sx"]), int(_flare_march["sy"])) <= int(cfg["ia_escala_llegada"]):
			near += 1
		if u.order == O.MOVE or u.order == O.ATTACK_MOVE:
			walking += 1
		elif u.order == O.ATTACK:
			var t: SimEntity = sim.by_id.get(u.target)
			if t != null and t.owner < 0:
				neutral.append(id)
	if alive.is_empty() or sim.tick > int(_flare_march["hasta"]):
		_flare_march = {}
		return
	if not neutral.is_empty():
		sim.push_command({"t": "move", "player": player, "ids": neutral, "x": int(_flare_march["sx"]), "y": int(_flare_march["sy"]), "suelto": true})
	if near * 2 >= alive.size() or walking == 0:
		sim.push_command({"t": "move", "player": player, "ids": alive, "x": int(_flare_march["x"]), "y": int(_flare_march["y"]), "amove": true})
		_flare_march = {}


## Bengala de ataque que esperaba tropa: sale cuando junta el grupo, o se olvida al vencer.
func _flare_wave_go(army: Array[SimEntity]) -> bool:
	if _flare_wave.is_empty():
		return false
	var from := int(_flare_wave["de"])
	if sim.tick > int(_flare_wave["hasta"]) or sim.players[from]["defeated"]:
		_flare_wave = {}
		_say("sin_tropa", {"a": from}, true)
		return false
	return _flare_send(army, int(_flare_wave["x"]), int(_flare_wave["y"]), from)
# --- fin equipos ronda 3 ---


func _count(list: Array[SimEntity], type: String) -> int:
	var n := 0
	for e in list:
		if e.type == type:
			n += 1
	return n


func _makes_military(b: SimEntity) -> bool:
	for t: String in b.def.get("produce", []):
		var u: Dictionary = sim.dp(player).unidades.get(t, {})
		if not u.is_empty() and u["funcion"] in ["choque", "distancia", "linea", "asedio"]:
			return true
	return false


## Mercado (reglas.json → ia_mercado; ronda 8): vende lo que le sobra y compra lo que le falta,
## primero para la meta (el hito o la maravilla) y después para el día a día. Antes solo
## vendía para la meta desde la III, así que en la II juntaba riqueza hasta `riqueza_baja` y se
## quedaba quieta: el inca pasó 34 minutos en la II con 10 000 de madera esperando 200 de
## piedra (proceso/22-testers/ronda-8). Con `mercado: "poco"` en la dificultad (la fácil) no
## comercia para la meta; solo lo general.
func _trade(p: Dictionary, by_type: Dictionary) -> void:
	var markets: Array = by_type.get("mercado", [])
	if markets.is_empty() or not (markets[0] as SimEntity).built:
		return
	var cfg: Dictionary = sim.data.reglas.get("ia_mercado", {})
	if cfg.is_empty() or sim.tick - last_trade < int(cfg["cada_ticks"]):
		return
	var m: SimEntity = markets[0]
	var res: Dictionary = p["res"]
	var lot := int(sim.data.reglas["mercado"]["lote"])
	var hc := {}
	var up: bool = int(p["age"]) < sim.dp(player).edades.size() and int(p["age"]) < int(level.get("edad_max", 99))
	if str(level.get("mercado", "meta")) == "meta" and not sim.hito_in_progress(player) and (_goal_is_wonder() or up):
		hc = _goal_cost(p)
	if not hc.is_empty():
		var short := int(res["riqueza"]) < int(hc.get("riqueza", 0))
		var spare := int(res["riqueza"]) - int(hc.get("riqueza", 0))
		for k in ["piedra", "alimento", "madera"]:
			if int(res[k]) < int(hc.get(k, 0)):
				short = true
				if spare >= sim.trade_price(player, k) + int(cfg["riqueza_reserva"]):
					last_trade = sim.tick
					_market(m, k, "comprar")
					return
		# Falta algo y la riqueza no alcanza: se vende lo que más sobra por encima de la meta.
		if short:
			var best := ""
			var best_x := 0
			for k in ["alimento", "madera", "piedra"]:
				var x := int(res[k]) - int(hc.get(k, 0)) - int(cfg["vende_sobra"])
				if x >= lot and x > best_x:
					best = k
					best_x = x
			if best != "":
				last_trade = sim.tick
				_market(m, best, "vender")
				return
	for k in ["alimento", "madera", "piedra"]:
		if int(res[k]) - int(hc.get(k, 0)) > int(cfg["sobra"]) and int(res["riqueza"]) < int(cfg["riqueza_baja"]):
			last_trade = sim.tick
			_market(m, k, "vender")
			return
	for k in ["alimento", "madera"]:
		if int(res[k]) < int(cfg["falta"]) and int(res["riqueza"]) - int(hc.get("riqueza", 0)) > int(cfg["riqueza_alta"]):
			last_trade = sim.tick
			_market(m, k, "comprar")
			return


## Una operación en el mercado; se cuenta para las mediciones (tools/ataques_equipo.gd).
func _market(m: SimEntity, k: String, op: String) -> void:
	sim.push_command({"t": "trade", "player": player, "building": m.id, "recurso": k, "op": op})
	var book: Dictionary = mercado_compra if op == "comprar" else mercado_venta
	book[k] = int(book.get(k, 0)) + 1


## La IA que no toma sitios (la fácil) no los captura al pasar (jugador nuevo, ronda 3;
## reglas.json → ia_sin_sitios). La captura no se pierde cuando el que la hace se va, así
## que varias pasadas cortas de un hondero rezagado sumaban los 10 segundos. Ahora:
## - en su grilla de caminos, el cuadro de cada sitio pesa más: sus unidades lo rodean si hay por dónde;
## - quien está adentro del cuadro de un sitio ajeno sin rivales sale al borde más cercano y sigue a su destino;
## - un destino adentro del cuadro se cambia por el borde.
## La grilla es de este jugador: las demás IA y dificultades no cambian.
func _avoid_sites(army: Array[SimEntity]) -> void:
	var cfg: Dictionary = sim.data.reglas["ia_sin_sitios"]
	var r: int = sim.data.reglas["sitios"]["radio"]
	var inner: int = r + int(cfg["margen_destino"])
	var outer: int = r + int(cfg["margen_salida"])
	var sites: Array[SimEntity] = []
	for e in sim.actives:
		if e.alive and e.def.get("sagrado", false):
			if not _weighted:
				var lo := Vector2i((e.x - inner) / P, (e.y - inner) / P)
				var hi := Vector2i((e.x + inner) / P, (e.y + inner) / P)
				for ty in range(lo.y, hi.y + 1):
					for tx in range(lo.x, hi.x + 1):
						sim.map.set_weight(player, tx, ty, int(cfg["peso_camino"]))
			if e.holder < 0 or sim.team_of(e.holder) != sim.team_of(player):
				sites.append(e)
	_weighted = true
	if sites.is_empty():
		_detour.clear()
		return
	# Órdenes de este turno que todavía no se aplicaron: mandan sobre las de ahora.
	var fresh := {}
	for c in sim._pending.get(sim.tick + 1, []):
		if int(c.get("player", -1)) == player:
			for id in c.get("ids", []):
				fresh[int(id)] = c
	var alive := {}
	for u in army:
		alive[u.id] = true
		var d: Dictionary = _detour.get(u.id, {})
		var moving := u.order == O.MOVE or u.order == O.ATTACK_MOVE
		# Su destino de verdad: el de la orden recién dada, el de la salida en curso o el de su orden.
		var goal := Vector2i(-1, -1)
		var amove := u.order == O.ATTACK_MOVE
		if fresh.has(u.id):
			var c: Dictionary = fresh[u.id]
			_detour.erase(u.id)
			d = {}
			if c["t"] != "move":
				continue
			moving = true
			goal = Vector2i(int(c["x"]), int(c["y"]))
			amove = c.get("amove", false)
		elif not d.is_empty():
			var exit: Vector2i = d["exit"]
			if moving and absi(u.amove_x - exit.x) + absi(u.amove_y - exit.y) > P:
				d = {} # otra orden pisó la salida
				_detour.erase(u.id)
			else:
				goal = d["goal"]
				amove = d["amove"]
		if goal.x < 0 and moving:
			goal = Vector2i(u.amove_x, u.amove_y)
		# Adentro de un sitio, sin rivales con quien pelear: sale al borde más cercano.
		var site := _site_box(sites, u.x, u.y, r)
		if site != null and not _rivals_in(site, r) and (d.is_empty() or u.order == O.IDLE):
			var exit := _box_exit(site, outer, Vector2i(u.x, u.y))
			if goal.x >= 0:
				goal = _outside(sites, goal, inner, outer)
			_detour[u.id] = {"exit": exit, "goal": goal, "amove": amove}
			_go(u, exit, false)
			continue
		if not d.is_empty():
			# Ya afuera: sigue a su destino.
			if u.order == O.IDLE:
				_detour.erase(u.id)
				if goal.x >= 0 and Sim.dist(u.x, u.y, goal.x, goal.y) > P:
					_go(u, goal, amove)
			continue
		# Un destino adentro de un sitio: se para en el borde.
		if moving:
			var safe := _outside(sites, goal, inner, outer)
			if safe != goal:
				_go(u, safe, amove)
	for id in _detour.keys():
		if not alive.has(id):
			_detour.erase(id)


func _go(u: SimEntity, at: Vector2i, amove: bool) -> void:
	sim.push_command({"t": "move", "player": player, "ids": [u.id], "x": at.x, "y": at.y, "amove": amove, "suelto": true})


## El sitio (de la lista) en cuyo cuadro de radio `r` está el punto; null si ninguno.
func _site_box(sites: Array[SimEntity], x: int, y: int, r: int) -> SimEntity:
	for st in sites:
		if absi(x - st.x) <= r and absi(y - st.y) <= r:
			return st
	return null


func _rivals_in(site: SimEntity, r: int) -> bool:
	for e in sim.all_units():
		if e.alive and e.is_unit() and e.owner >= 0 and e.inside < 0 and sim.enemies(player, e.owner) and absi(e.x - site.x) <= r and absi(e.y - site.y) <= r:
			return true
	return false


## Punto libre en el borde del cuadro agrandado de un sitio, del lado más cercano al punto.
func _box_exit(site: SimEntity, outer: int, from: Vector2i) -> Vector2i:
	var opts: Array[Vector2i] = [Vector2i(from.x, site.y - outer), Vector2i(from.x, site.y + outer), Vector2i(site.x - outer, from.y), Vector2i(site.x + outer, from.y)]
	var best := Vector2i(-1, -1)
	var best_d := 1 << 60
	for o in opts:
		var c := _free_point(o)
		if c.x < 0:
			continue
		var dd := Sim.dist(from.x, from.y, c.x, c.y)
		if dd < best_d:
			best_d = dd
			best = c
	return best if best.x >= 0 else Vector2i(site.x - outer, site.y)


## Centro de la casilla libre más cercana al punto, dentro del mapa; (-1, -1) si no hay.
func _free_point(at: Vector2i) -> Vector2i:
	var n := sim.map.n
	var t := sim.map.nearest_free(clampi(at.x / P, 1, n - 2), clampi(at.y / P, 1, n - 2), 3, player)
	if t.x < 0:
		return t
	return Vector2i(t.x * P + P / 2, t.y * P + P / 2)


## Si el destino cae en el cuadro de un sitio, el punto del borde más cercano.
func _outside(sites: Array[SimEntity], goal: Vector2i, inner: int, outer: int) -> Vector2i:
	var st := _site_box(sites, goal.x, goal.y, inner)
	if st == null:
		return goal
	return _box_exit(st, outer, goal)


func _near_site(u: SimEntity) -> bool:
	for e in sim.actives:
		if e.def.get("sagrado", false) and absi(e.x - u.x) < 5000 and absi(e.y - u.y) < 5000:
			return true
	return false


## Casillas libres de un camino recto (4-conexo) entre dos puntos; las ocupadas se saltean.
## Camino de un edificio a la capital por búsqueda en anchura: rodea lo ocupado,
## aprovecha los caminos que ya existen y devuelve solo las casillas nuevas.
## Vacío si no hay paso (antes trazaba en línea recta y dejaba huecos: caso F).
func _road_tiles(from_b: SimEntity, to_b: SimEntity) -> Array:
	var n := sim.map.n
	var lo := Vector2i(maxi(0, mini(from_b.tx, to_b.tx) - 8), maxi(0, mini(from_b.ty, to_b.ty) - 8))
	var hi := Vector2i(mini(n - 1, maxi(from_b.tx + from_b.w, to_b.tx + to_b.w) + 8), mini(n - 1, maxi(from_b.ty + from_b.h, to_b.ty + to_b.h) + 8))
	var prev := {}
	var queue: Array[Vector2i] = []
	for t in _ring(from_b):
		if _road_ok(t):
			prev[t] = t
			queue.append(t)
	var goal := {}
	for t in _ring(to_b):
		goal[t] = true
	var head := 0
	var end := Vector2i(-1, -1)
	while head < queue.size():
		var c: Vector2i = queue[head]
		head += 1
		if goal.has(c):
			end = c
			break
		for d: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			var q: Vector2i = c + d
			if q.x < lo.x or q.y < lo.y or q.x > hi.x or q.y > hi.y or prev.has(q) or not _road_ok(q):
				continue
			prev[q] = c
			queue.append(q)
	var out := []
	if end.x < 0:
		return out
	var cur := end
	while true:
		if not _is_road(cur):
			out.append([cur.x, cur.y])
		var back: Vector2i = prev[cur]
		if back == cur:
			break
		cur = back
	return out


func _ring(b: SimEntity) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	for x in range(b.tx, b.tx + b.w):
		out.append(Vector2i(x, b.ty - 1))
		out.append(Vector2i(x, b.ty + b.h))
	for y in range(b.ty, b.ty + b.h):
		out.append(Vector2i(b.tx - 1, y))
		out.append(Vector2i(b.tx + b.w, y))
	return out


func _is_road(t: Vector2i) -> bool:
	var id := sim.map.occupant(t.x, t.y)
	var e: SimEntity = sim.by_id.get(id) if id >= 0 else null
	return e != null and e.type == "camino"


func _road_ok(t: Vector2i) -> bool:
	return _is_road(t) or sim.can_place("camino", t.x, t.y, player)
