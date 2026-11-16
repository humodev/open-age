extends Node
## Avisos que enseñan (proceso/23-como-aoe4/03-aprender-a-jugar.md), como los consejos de AoE4:
##   - aldeanos sin trabajo durante un rato;
##   - se acabaron los frutos cerca del centro;
##   - un recurso que se acumula sin gastarse (sobre todo la riqueza);
##   - el rival tiene todos los sitios sagrados: perdés en M:SS (y su par, "los tenés vos").
##   - ejército grande en casa y recursos de sobra durante un rato: atacá o subí de edad.
##   - aldeanos que caminan lejos para dejar lo que juntan: levantá el almacén del pueblo ahí.
##
## Solo mira la simulación y llama a `hud.notify`. Se apagan en Opciones ("Avisos que enseñan").
## Los tiempos son de juego, no de reloj: con la partida a ×4 se revisa cuatro veces más seguido.
## Umbrales en data/interfaz.json → consejos.

var hud # Hud
var cfg: Dictionary = {}
var _last_check := -1 # tick de la última revisión
var _since := {} # clave -> segundos de juego que lleva la situación
var _said := {} # clave -> segundo de juego del último aviso
var _bushes_near := -1 # arbustos con frutos cerca del centro en la revisión anterior (-1: sin revisar)
var _sites_streak := -1 # jugador que tenía todos los sitios en la revisión anterior

const HINTS := {
	"riqueza": "Usala en tropas, investigaciones o el hito de la próxima edad (F4 dice qué falta).",
	"alimento": "Entrená aldeanos y tropas, o guardalo para el hito de la próxima edad.",
	"madera": "Construí casas, granjas, otro edificio militar o almacenes cerca de los recursos.",
	"piedra": "Las torres, las murallas y los hitos de las edades altas piden piedra.",
}


func setup(h) -> void:
	hud = h
	var path := "res://data/interfaz.json"
	if FileAccess.file_exists(path):
		cfg = (JSON.parse_string(FileAccess.get_file_as_string(path)) as Dictionary).get("consejos", {})


func _process(_d: float) -> void:
	if hud == null or hud.sim == null:
		return
	var sim: Sim = hud.sim
	var every := maxi(1, int(cfg.get("revisar_s", 5)) * 1000 / sim.tick_ms)
	if _last_check >= 0 and sim.tick - _last_check < every:
		return
	var dt := 0 if _last_check < 0 else (sim.tick - _last_check) * sim.tick_ms / 1000
	_last_check = sim.tick
	if not Opciones.consejos or sim.game_over or hud._local_is_ai() or sim.players[hud.local]["defeated"]:
		return
	check(dt)


## Una revisión: `dt` son los segundos de juego desde la anterior.
func check(dt: int) -> void:
	_idle(dt)
	_bushes()
	_floating(dt)
	_sites()
	_push(dt)
	_far(dt)


func _now() -> int:
	return hud.sim.tick * hud.sim.tick_ms / 1000


## Avisa si pasó `repetir` segundos desde el último aviso con esa clave.
func _say(key: String, text: String, tipo: String, repeat_s: int, lugar: Variant = null) -> bool:
	var now := _now()
	if _said.has(key) and now - int(_said[key]) < repeat_s:
		return false
	_said[key] = now
	hud.notify(text, 9.0, tipo, lugar)
	return true


# ---------------------------------------------------------------- Aldeanos ociosos

func _idle(dt: int) -> void:
	var sim: Sim = hud.sim
	var idle: Array[SimEntity] = []
	for e in sim.actives:
		if e.alive and e.owner == hud.local and e.is_unit() and e.fn == "civil" and e.inside < 0 and e.order == SimEntity.Order.IDLE:
			idle.append(e)
	if idle.size() < int(cfg.get("ociosos_min", 1)):
		_since["ociosos"] = 0
		return
	_since["ociosos"] = int(_since.get("ociosos", 0)) + dt
	if int(_since["ociosos"]) < int(cfg.get("ociosos_s", 20)):
		return
	var n := idle.size()
	var txt := ("Tenés %d aldeanos sin trabajo" % n) if n > 1 else "Tenés un aldeano sin trabajo"
	txt += "\nLa tecla punto (.) elige uno ocioso; con clic derecho en un recurso se pone a juntar."
	_say("ociosos", txt, "decision", int(cfg.get("repetir_s", 90)), hud._lugar_de(idle[0].x, idle[0].y))


# ---------------------------------------------------------------- Frutos

## Arbustos con frutos a `frutos_radio` casillas del centro: cuando pasan de haber a no haber, avisa.
func _bushes() -> void:
	var sim: Sim = hud.sim
	var cap: SimEntity = null
	for e in sim.actives:
		if e.alive and e.owner == hud.local and e.is_building() and e.capital:
			cap = e
			break
	if cap == null:
		return
	var r := int(cfg.get("frutos_radio", 16)) * Sim.P
	var n := 0
	for e in sim.entities:
		if e.alive and e.type == "arbusto" and e.is_resource() and e.amount > 0 and absi(e.x - cap.x) <= r and absi(e.y - cap.y) <= r:
			n += 1
	if _bushes_near > 0 and n == 0:
		var granja: String = String(sim.dp(hud.local).edificios.get("granja", {}).get("nombre", "granjas"))
		_say("frutos", "Se acabaron los frutos cerca del centro\nPara seguir juntando alimento, construí %s (Economía) o mandá aldeanos a otros arbustos." % granja, "decision", 1 << 30)
	_bushes_near = n


# ---------------------------------------------------------------- Recursos sin gastar

func _floating(dt: int) -> void:
	var p: Dictionary = hud.sim.players[hud.local]
	var lim: Dictionary = cfg.get("flotando", {})
	for k in lim:
		var key := "flot_" + str(k)
		var have := int(p["res"].get(k, 0))
		if have <= int(lim[k]):
			_since[key] = 0
			continue
		_since[key] = int(_since.get(key, 0)) + dt
		if int(_since[key]) < int(cfg.get("flotando_s", 60)):
			continue
		var name: String = Palette.RES_NAMES.get(k, str(k)).to_lower()
		if _say(key, "Estás juntando %s que no gastás (%d)\n%s" % [name, have, HINTS.get(k, "")], "decision", int(cfg.get("repetir_s", 90))):
			_since[key] = 0
			return # de a un recurso por revisión


# ---------------------------------------------------------------- Sitios sagrados

func _sites() -> void:
	var sim: Sim = hud.sim
	var holder := CuentaGrande.sites_holder(sim)
	if holder < 0:
		_sites_streak = -1
		return
	var left := CuentaGrande.sites_left_s(sim, holder)
	var rep := int(cfg.get("sitios_repetir_s", 60))
	var fresh := holder != _sites_streak
	_sites_streak = holder
	if fresh:
		_said.erase("sitios")
	if sim.enemies(hud.local, holder):
		# El sitio más cercano que no es tuyo: ahí hay que ir.
		var at: Variant = null
		for e in sim.actives:
			if e.alive and e.def.get("sagrado", false):
				at = hud._lugar_de(e.x, e.y)
				break
		_say("sitios", "%s tiene todos los sitios sagrados: perdés en %s\nLlevá tropas a pararse en un sitio: con tener uno se corta la cuenta." % [Palette.team_name(holder), Hud._fmt_time(left)], "ataque", rep, at)
	elif fresh:
		_say("sitios", "%s todos los sitios sagrados: ganás en %s\nDefendelos: si el rival pisa uno, la cuenta se corta." % ["Tenés" if holder == hud.local else "Tu equipo tiene", Hud._fmt_time(left)], "hito", 1 << 30)


# ---------------------------------------------------------------- Empujón

## Ejército grande en casa y recursos sin gastar durante un rato (jugador nuevo, ronda 3: su
## jugador "aplicado" terminaba con 7.000 recursos y 25 soldados que nunca salían).
## Umbrales en interfaz.json → consejos.empujon. No en campañas: ahí manda el objetivo.
func _push(dt: int) -> void:
	var sim: Sim = hud.sim
	var c: Dictionary = cfg.get("empujon", {})
	if c.is_empty() or sim.scenario != null:
		return
	var p: Dictionary = sim.players[hud.local]
	var cap: SimEntity = null
	for e in sim.actives:
		if e.alive and e.owner == hud.local and e.is_building() and e.capital:
			cap = e
			break
	var total := 0
	var home := 0
	var r := int(c.get("casa_radio", 22)) * Sim.P
	for e in sim.actives:
		if e.alive and e.owner == hud.local and e.is_unit() and e.is_military() and e.inside < 0:
			total += 1
			if cap != null and absi(e.x - cap.x) <= r and absi(e.y - cap.y) <= r:
				home += 1
	var bank := 0
	for k in Sim.RES_KINDS:
		bank += int(p["res"].get(k, 0))
	if cap == null or total < int(c.get("ejercito_min", 15)) or home * 100 < total * int(c.get("en_casa_pct", 75)) or bank < int(c.get("recursos_min", 2000)):
		_since["empujon"] = 0
		return
	_since["empujon"] = int(_since.get("empujon", 0)) + dt
	if int(_since["empujon"]) < int(c.get("durante_s", 90)):
		return
	# --- dónde y con qué --- (jugador nuevo, ronda 4: «la base rival está en la niebla y no sé
	# dónde queda»; «mis 20 soldados no tiran ningún edificio»). Rumbo a la capital rival más
	# cercana, marcada en el minimapa y con lugar para Espacio; y qué asedio tira edificios.
	var rival := _rival_capital(cap)
	var how := "Elegí tus tropas, A y clic en la base rival"
	if rival != null:
		var seen: bool = sim.fog.is_explored(hud.local, rival)
		how += " (%s hacia el %s: marcada en el minimapa, Espacio te lleva)" % ["la viste" if seen else "está", _rumbo(cap, rival)]
	var siege := _asedio_texto(int(p["age"]))
	if siege != "":
		how += ".\n" + siege
	if int(p["age"]) < sim.dp(hud.local).edades.size():
		how += ".\nO con un aldeano encargá el hito de la próxima edad (Z o X)"
	if _say("empujon", "Tenés ejército y recursos de sobra: atacá o subí de edad\n%s." % how, "decision", int(c.get("repetir_s", 240)), WorldView.to_world(rival.x, rival.y) if rival != null else null):
		_since["empujon"] = 0
		if rival != null and hud.has_method("senalar_minimapa"):
			hud.senalar_minimapa(rival.x, rival.y)


## La capital (o el centro) rival más cercana a la nuestra.
func _rival_capital(cap: SimEntity) -> SimEntity:
	var sim: Sim = hud.sim
	var best: SimEntity = null
	for e in sim.actives:
		if e.alive and e.is_building() and e.owner >= 0 and sim.enemies(hud.local, e.owner) and (e.capital or e.type == "centro"):
			if best == null or Sim.dist(e.x, e.y, cap.x, cap.y) < Sim.dist(best.x, best.y, cap.x, cap.y):
				best = e
	return best


## Rumbo de `a` a `b` como lo muestran la pantalla y el minimapa (que giran con la cámara):
## arriba es el norte.
func _rumbo(a: SimEntity, b: SimEntity) -> String:
	var d := Vector3(b.x - a.x, 0, b.y - a.y)
	var cam: RtsCamera = hud.ctrl.cam if hud.ctrl != null else null
	var right := cam.right_xz() if cam != null else Vector3(1, 0, 0)
	var fwd := cam.forward_xz() if cam != null else Vector3(0, 0, -1)
	var sx := d.dot(right)
	var sy := d.dot(fwd)
	var names := ["este", "noreste", "norte", "noroeste", "oeste", "sudoeste", "sur", "sudeste"]
	return names[posmod(int(round(atan2(sy, sx) / (PI / 4.0))), 8)]


## «Para tirar edificios hace falta asedio: Ariete (en el Taller de tacuara, edad II).»
func _asedio_texto(age: int) -> String:
	var dd: SimData = hud.sim.dp(hud.local)
	var parts: Array[String] = []
	for u: String in dd.unidades:
		var ud: Dictionary = dd.unidades[u]
		if ud.get("funcion", "") != "asedio":
			continue
		for b: String in dd.edificios:
			if (dd.edificios[b].get("produce", []) as Array).has(u) and not dd.is_hito(b):
				var em := maxi(int(ud.get("edad_min", 1)), int(dd.edificios[b].get("edad_min", 1)))
				parts.append("%s (%s%s)" % [ud.get("nombre", u), dd.edificios[b].get("nombre", b), "" if em <= age else ", edad %s" % Sim._roman(em)])
				break
	if parts.is_empty():
		return ""
	return "Para tirar edificios hace falta asedio: " + ", ".join(parts)


# ---------------------------------------------------------------- Viajes largos

## --- depósitos de comida --- (proceso/24, 4m; el autor: "¿tengo que dejar que vuelvan hasta la
## base a traer la comida?"). Cuenta, por recurso, los aldeanos que juntan del mapa (no de granja)
## a más de `casillas` del depósito más cercano que lo recibe; si son `aldeanos_min` o más durante
## `durante_s` seguidos, nombra el almacén de su pueblo que recibe ese recurso (o el elefante del
## rey en Ayutthaya) y dónde está en la grilla. Umbrales en interfaz.json → consejos.lejos.
func _far(dt: int) -> void:
	var c: Dictionary = cfg.get("lejos", {})
	if c.is_empty():
		return
	var sim: Sim = hud.sim
	var lim := int(c.get("casillas", 12)) * Sim.P
	var far := {} # recurso -> [aldeanos lejos, recurso del mapa del primero, depósito al que van]
	for e in sim.actives:
		if not (e.alive and e.owner == hud.local and e.is_unit() and e.fn == "civil" and e.inside < 0):
			continue
		if e.order != SimEntity.Order.GATHER and e.order != SimEntity.Order.RETURN:
			continue
		var t: SimEntity = sim.by_id.get(e.target)
		if t == null or not t.alive or not t.is_resource():
			continue # las granjas no: el aviso es para la caza, los frutos, el monte y la piedra
		var kind: String = t.res_kind
		if not (c.get("recursos", []) as Array).has(kind):
			continue
		var d := sim.nearest_dropoff(hud.local, kind, t.x, t.y)
		if d != null and sim.dist_to(t, d) <= lim:
			continue
		if _store_coming(kind, t, lim):
			continue
		var f: Array = far.get(kind, [0, t, d])
		f[0] += 1
		far[kind] = f
	for kind in c.get("recursos", []):
		var key := "lejos_" + str(kind)
		var f: Array = far.get(kind, [0, null, null])
		if int(f[0]) < int(c.get("aldeanos_min", 3)):
			_since[key] = 0
			continue
		_since[key] = int(_since.get(key, 0)) + dt
		if int(_since[key]) < int(c.get("durante_s", 30)):
			continue
		var txt := far_text(kind, f[1], f[2])
		if txt != "" and _say(key, txt, "decision", int(c.get("repetir_s", 150)), hud._lugar_de(f[1].x, f[1].y)):
			_since[key] = 0
			return # de a un recurso por revisión


## Ya hay un depósito de ese recurso en obra cerca de donde juntan: no hace falta avisar.
func _store_coming(kind: String, t: SimEntity, lim: int) -> bool:
	var sim: Sim = hud.sim
	for b in sim.actives:
		if b.alive and b.owner == hud.local and b.is_building() and not b.built and (b.def.get("deposito", []) as Array).has(kind) and sim.dist_to(t, b) <= lim:
			return true
	return false


## Texto del aviso: "Tus aldeanos llevan la comida hasta el centro (25 casillas)\nLevantá un
## Tapyi junto a la caza (Q Economía → E): recibe alimento y madera." Vacío si el pueblo no tiene
## con qué recibir ese recurso lejos.
func far_text(kind: String, src: SimEntity, drop: SimEntity) -> String:
	var sim: Sim = hud.sim
	var dd := sim.dp(hud.local)
	var c: Dictionary = cfg.get("lejos", {})
	var what: String = {"alimento": "la comida", "madera": "la madera", "piedra": "la piedra"}.get(kind, Palette.RES_NAMES.get(kind, kind).to_lower())
	var lugar: String = (c.get("lugares", {}) as Dictionary).get(src.type if src != null else "", "donde juntan")
	var head := ""
	if drop == null:
		head = "Tus aldeanos no tienen dónde dejar %s" % what
	else:
		var hasta := "el centro" if drop.capital else ("el " + String(drop.def.get("nombre", "depósito")) if drop.is_building() else "el " + _short(drop.def.get("nombre", "")))
		head = "Tus aldeanos llevan %s hasta %s (%d casillas)" % [what, hasta, sim.dist_to(src, drop) / Sim.P]
	var store := best_store(dd, kind, int(sim.players[hud.local]["age"]))
	if store != "":
		var def: Dictionary = dd.edificios[store]
		var art := "una" if (c.get("femeninos", []) as Array).has(store) else "un"
		var names: Array[String] = []
		for k: String in def["deposito"]:
			names.append(Palette.RES_NAMES.get(k, k).to_lower())
		return "%s\nLevantá %s %s junto a %s (%s): recibe %s." % [head, art, def["nombre"], lugar, grid_path(dd, store), Ficha.y_lista(names)]
	var unit := walking_store(dd, kind)
	if unit.is_empty():
		return ""
	var udef: Dictionary = dd.unidades[unit[0]]
	var mine := false
	for e in sim.actives:
		mine = mine or (e.alive and e.owner == hud.local and e.type == unit[0])
	var name := _short(udef.get("nombre", unit[0]))
	if mine:
		return "%s\nLlevá tu %s junto a %s: es un almacén que camina." % [head, name, lugar]
	var where := String(dd.edificios.get(unit[1], {}).get("nombre", unit[1])).get_slice(" (", 0)
	return "%s\nLlevá un %s junto a %s: es un almacén que camina (se entrena en el %s)." % [head, name, lugar, where]


## "Elefante del rey (chang luang)" → "elefante del rey".
static func _short(n: String) -> String:
	var s := n.get_slice(" (", 0)
	return s.left(1).to_lower() + s.substr(1)


## El almacén más barato que construye el aldeano y recibe `kind`, fuera de los centros (primero
## los que ya se pueden levantar en la edad). Vacío si no hay ninguno.
static func best_store(dd: SimData, kind: String, age: int) -> String:
	var best := ""
	var best_k := 1 << 30
	for type: String in dd.unidades["aldeano"].get("construye", []):
		var def: Dictionary = dd.edificios.get(type, {})
		if def.is_empty() or dd.is_hito(type) or def.get("capital", false) or type == "centro" or not (def.get("deposito", []) as Array).has(kind):
			continue
		var k := 0
		for r in def.get("costo", {}):
			k += int(def["costo"][r])
		if int(def.get("edad_min", 1)) > age:
			k += 1 << 20
		if k < best_k:
			best = type
			best_k = k
	return best


## Unidad que hace de depósito (elefante del rey) y el edificio que la entrena: [tipo, edificio].
static func walking_store(dd: SimData, kind: String) -> Array:
	for b: String in dd.edificios:
		for u: String in dd.edificios[b].get("produce", []):
			if (dd.unidades.get(u, {}).get("deposito", []) as Array).has(kind):
				return [u, b]
	return []


## Dónde está en la grilla del aldeano: "Q Economía → E".
static func grid_path(dd: SimData, type: String) -> String:
	var menu := Grilla.menu_de(dd, type)
	var slots := Grilla.edificios(dd, menu)
	var labels: Array[String] = [] # --- veterano ronda 4 --- las teclas asignadas
	for i in 12:
		labels.append(Controller.etiqueta(i))
	var m := "%s %s" % [labels[Grilla.fija(menu, 0 if menu == Grilla.ECONOMIA else 1)], "Economía" if menu == Grilla.ECONOMIA else "Militar"]
	for s in slots:
		if slots[s] == type:
			return "%s → %s" % [m, labels[s]]
	return m
