extends Node
## Avisos que enseñan (proceso/23-como-aoe4/03-aprender-a-jugar.md), como los consejos de AoE4:
##   - aldeanos sin trabajo durante un rato;
##   - se acabaron los frutos cerca del centro;
##   - un recurso que se acumula sin gastarse (sobre todo la riqueza);
##   - el rival tiene todos los sitios sagrados: perdés en M:SS (y su par, "los tenés vos").
##   - ejército grande en casa y recursos de sobra durante un rato: atacá o subí de edad.
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
	var how := "Elegí tus tropas, A y clic en la base rival"
	if int(p["age"]) < sim.dp(hud.local).edades.size():
		how += "; o con un aldeano encargá el hito de la próxima edad (Z o X)"
	if _say("empujon", "Tenés ejército y recursos de sobra: atacá o subí de edad\n%s." % how, "decision", int(c.get("repetir_s", 240))):
		_since["empujon"] = 0
