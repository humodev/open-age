class_name CuentaGrande
extends Control
## Cuenta regresiva grande, arriba al centro (proceso/23-como-aoe4/03-aprender-a-jugar.md).
##
## Como en AoE4: cuando un jugador (o su equipo) tiene todos los sitios sagrados, todos ven
## cuánto le falta para ganar, con el color de quien los tiene. En las misiones, la misma caja
## muestra la cuenta del escenario ("Llegan los saqueadores"). Solo lee la simulación.

const ANCHO := 380.0
const ALTO := 66.0
## La cuenta del tiempo límite aparece en los últimos 5 minutos (como el aviso de AoE4).
const AVISO_TIEMPO_S := 300

var sim: Sim
var local := 0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


## Jugador que tiene todos los sitios con la cuenta andando (el de menor id de su equipo); -1 si nadie.
static func sites_holder(s: Sim) -> int:
	for p in s.players:
		if not p["defeated"] and int(p.get("sitios_ms", 0)) > 0:
			return int(p["id"])
	return -1


## Segundos que faltan para el tiempo límite; -1 si la partida no tiene.
static func time_left_s(s: Sim) -> int:
	var mins := int(s._opts.get("tiempo_limite_min", 0))
	if mins <= 0:
		return -1
	return maxi(0, mins * 60 - s.tick * s.tick_ms / 1000)


## Primer jugador en pie del equipo con más puntos; -1 si hay empate arriba.
static func leader(s: Sim) -> int:
	var best := -1
	var best_s := -1
	var tie := false
	for p in s.players:
		if p["defeated"]:
			continue
		var ts := s.team_score(s.team_of(p["id"]))
		if ts > best_s:
			best_s = ts
			best = int(p["id"])
			tie = false
		elif ts == best_s and s.team_of(p["id"]) != s.team_of(best):
			tie = true
	return -1 if tie else best


## --- paso 7 --- Jugador con la cuenta de la maravilla más adelantada (-1 si ninguna corre).
static func wonder_holder(s: Sim) -> int:
	var best := -1
	var best_left := 1 << 30
	for p in s.players:
		var left := s.wonder_left_s(int(p["id"]))
		if left >= 0 and left < best_left:
			best_left = left
			best = int(p["id"])
	return best


static func sites_left_s(s: Sim, pid: int) -> int:
	return maxi(0, (int(s.data.reglas["sitios"]["victoria_ms"]) - int(s.players[pid].get("sitios_ms", 0))) / 1000)


func _process(_d: float) -> void:
	queue_redraw()


func _draw() -> void:
	if sim == null or sim.game_over:
		return
	var title := ""
	var secs := -1
	var col := Palette.UI_BAD
	var holder := sites_holder(sim)
	var wonder := wonder_holder(sim) # --- paso 7 --- la que gana antes manda
	if wonder >= 0 and (holder < 0 or sim.wonder_left_s(wonder) <= sites_left_s(sim, holder)):
		secs = sim.wonder_left_s(wonder)
		col = Palette.team(wonder)
		var wname := String(sim.wonder_of(wonder).def.get("nombre", "la maravilla")).to_upper() if sim.wonder_of(wonder) != null else "LA MARAVILLA"
		if wonder == local:
			title = "%s EN PIE · GANÁS SI RESISTE" % wname
		elif not sim.enemies(local, wonder):
			title = "MARAVILLA DE TU EQUIPO · %s" % wname
		else:
			title = "%s: %s · DESTRUILA" % [Palette.team_name(wonder).to_upper(), wname]
	elif holder >= 0:
		secs = sites_left_s(sim, holder)
		col = Palette.team(holder)
		if holder == local:
			title = "TENÉS TODOS LOS SITIOS SAGRADOS"
		elif not sim.enemies(local, holder):
			title = "TU EQUIPO TIENE TODOS LOS SITIOS"
		else:
			title = "%s TIENE TODOS LOS SITIOS SAGRADOS" % Palette.team_name(holder).to_upper()
	elif sim.scenario != null and sim.scenario.cuenta_s() >= 0:
		secs = sim.scenario.cuenta_s()
		title = String(sim.scenario.cuenta.get("texto", "")).to_upper()
	elif time_left_s(sim) >= 0 and time_left_s(sim) <= AVISO_TIEMPO_S:
		# Tiempo límite (opciones de partida): los últimos minutos, con el color de quien va ganando.
		secs = time_left_s(sim)
		var lead := leader(sim)
		col = Palette.team(lead) if lead >= 0 else Palette.UI_DIM
		if lead < 0:
			title = "TIEMPO LÍMITE · EMPATE EN PUNTOS"
		elif not sim.enemies(local, lead):
			title = "TIEMPO LÍMITE · VA GANANDO TU EQUIPO"
		else:
			title = "TIEMPO LÍMITE · VA GANANDO %s" % Palette.team_name(lead).to_upper()
	if secs < 0:
		return
	var r := Rect2((size.x - ANCHO) / 2.0, 0, ANCHO, ALTO)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.06, 0.065, 0.075, 0.92)
	sb.set_corner_radius_all(8)
	sb.border_color = col
	sb.set_border_width_all(2)
	sb.border_width_bottom = 5
	sb.shadow_color = Color(0, 0, 0, 0.35)
	sb.shadow_size = 8
	draw_style_box(sb, r)
	# En el último minuto, el número late.
	var big := col.lightened(0.25)
	if secs <= 60:
		big = big.lerp(Color.WHITE, 0.35 + 0.35 * sin(Time.get_ticks_msec() / 160.0))
	draw_string(Hud.font_b, Vector2(r.position.x, r.position.y + 20), title, HORIZONTAL_ALIGNMENT_CENTER, r.size.x, 12, Palette.UI_TEXT)
	draw_string(Hud.font_b, Vector2(r.position.x, r.position.y + 55), Hud._fmt_time(secs), HORIZONTAL_ALIGNMENT_CENTER, r.size.x, 34, big)
