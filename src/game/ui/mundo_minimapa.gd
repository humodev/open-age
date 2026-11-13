extends RefCounted
## Capas extra del minimapa: destellos donde te atacan, sitios sagrados con el color
## de quien los tiene, recursos disputados y aldeanos ociosos. Se dibuja dentro de la
## transformación del minimapa (coordenadas en casillas).

const P := 1000.0
const O := SimEntity.Order
## Destellos: uno por zona de 8×8 casillas cada 2,5 s como máximo.
const ZONA := 8
const ESPERA := 2.5
const DURA := 1.6

var sim: Sim
var local: int
var _t := 0.0
var _flashes: Array[Dictionary] = []
var _last_flash := {} # zona -> tiempo
var _disputed: Array[SimEntity] = []
var _scan := 0.0


func _init(s: Sim, local_player: int) -> void:
	sim = s
	local = local_player


func flash(x: int, y: int) -> void:
	var zone := Vector2i(x / int(P) / ZONA, y / int(P) / ZONA)
	if _t - float(_last_flash.get(zone, -99.0)) < ESPERA:
		return
	_last_flash[zone] = _t
	_flashes.append({"p": Vector2(x / P, y / P), "t": 0.0})


func process(delta: float) -> void:
	_t += delta
	for f in _flashes:
		f["t"] += delta
	_flashes = _flashes.filter(func(f: Dictionary) -> bool: return f["t"] < DURA)
	_scan -= delta
	if _scan <= 0.0:
		_scan = 2.0
		# Recursos disputados: la riqueza que no es de casa (arcilla del centro).
		_disputed.clear()
		for e in sim.entities:
			if e.alive and e.is_resource() and e.res_kind == "riqueza" and e.res_owner != local:
				_disputed.append(e)


## Capas en coordenadas de casillas (la transformación del minimapa ya está puesta).
func draw(ci: CanvasItem, view: WorldView, px: float) -> void:
	var pulse := 0.5 + 0.5 * sin(_t * 4.0)
	# Recursos disputados: aro dorado que late.
	for e in _disputed:
		if not e.alive or (view.fog_on and not sim.fog.is_explored(local, e)):
			continue
		var c := Vector2(e.x / P, e.y / P)
		ci.draw_arc(c, 2.6 + pulse * 0.8, 0, TAU, 16, Color(Palette.WEALTH, 0.55 + 0.35 * pulse), px * 1.5, true)
	# Sitios sagrados: rombo con el color de quien lo tiene; si alguien lo está tomando, su color late.
	var cfg: Dictionary = sim.data.reglas.get("sitios", {})
	for e in sim.actives:
		if not e.is_building() or not e.def.get("sagrado", false) or view.fog_state(e) == 0:
			continue
		var c := Vector2(e.x / P, e.y / P)
		var r := 3.2
		var dia := PackedVector2Array([c + Vector2(0, -r), c + Vector2(r, 0), c + Vector2(0, r), c + Vector2(-r, 0)])
		ci.draw_colored_polygon(dia, Color(0, 0, 0, 0.6))
		var inner := PackedVector2Array([c + Vector2(0, -r * 0.7), c + Vector2(r * 0.7, 0), c + Vector2(0, r * 0.7), c + Vector2(-r * 0.7, 0)])
		ci.draw_colored_polygon(inner, Palette.team(e.holder) if e.holder >= 0 else Color(0.95, 0.92, 0.85))
		if e.capture > 0 and e.aux >= 0 and view.fog_state(e) == 2 and not cfg.is_empty():
			var k := clampf(float(e.capture) / float(cfg["captura_ms"]), 0.0, 1.0)
			ci.draw_arc(c, r + 1.2, -PI * 0.5, -PI * 0.5 + TAU * k, 16, Palette.team(e.aux), px * 2.0, true)
	# Aldeanos ociosos: aro claro que parpadea.
	for e in sim.actives:
		if e.owner == local and e.fn == "civil" and e.inside < 0 and e.order == O.IDLE:
			ci.draw_arc(Vector2(e.x / P, e.y / P), 2.2, 0, TAU, 12, Color(Palette.UI_ACCENT, 0.4 + 0.6 * pulse), px * 1.5, true)
	# Destellos de ataque.
	for f in _flashes:
		var k: float = f["t"] / DURA
		var p: Vector2 = f["p"]
		ci.draw_circle(p, 2.0 + k * 7.0, Color(Palette.UI_BAD, 0.45 * (1.0 - k)))
		ci.draw_arc(p, 3.0 + k * 9.0, 0, TAU, 20, Color(Palette.UI_BAD, 1.0 - k), px * 2.0, true)
