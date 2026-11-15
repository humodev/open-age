class_name CuentaGrande
extends Control
## Cuenta regresiva grande, arriba al centro (proceso/23-como-aoe4/03-aprender-a-jugar.md).
##
## Como en AoE4: cuando un jugador (o su equipo) tiene todos los sitios sagrados, todos ven
## cuánto le falta para ganar, con el color de quien los tiene. En las misiones, la misma caja
## muestra la cuenta del escenario ("Llegan los saqueadores"). Solo lee la simulación.

const ANCHO := 380.0
const ALTO := 66.0

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
	if holder >= 0:
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
