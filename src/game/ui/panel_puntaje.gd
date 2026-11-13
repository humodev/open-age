extends Control
## Puntaje en vivo (F6): chico, una fila por jugador, con su edad.
## La fórmula está en data/interfaz.json → "puntaje"; es solo informativa.

const C := preload("res://src/game/ui/panel_comun.gd")
const ROW := 20.0

var hud: Hud
var datos # PanelDatos
var _t := 0.0
var _scores: Array = []


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _process(delta: float) -> void:
	_t -= delta
	if _t <= 0.0 or _scores.size() != hud.sim.players.size():
		_t = 0.5
		_scores.clear()
		for p in hud.sim.players:
			_scores.append(datos.score(p["id"]))
	var h := 8.0 + hud.sim.players.size() * ROW
	if size.y != h:
		size.y = h
	queue_redraw()


func _draw() -> void:
	var sim := hud.sim
	var sb := Hud.panel_box(8)
	sb.shadow_size = 4
	draw_style_box(sb, Rect2(Vector2.ZERO, size))
	var y := 4.0
	var best := 1
	for s in _scores:
		best = maxi(best, s)
	for p in sim.players:
		var pid: int = p["id"]
		var col := Palette.team(pid)
		draw_rect(Rect2(10, y + 5, 4, ROW - 10), col)
		var name := C.player_name(sim, pid, hud.local)
		C.text(self, Vector2(22, y + 15), name, 12, Palette.UI_TEXT if pid == hud.local else Palette.UI_DIM, pid == hud.local, size.x - 150)
		C.text(self, Vector2(size.x - 128, y + 15), Sim._roman(p["age"]), 12, Palette.UI_DIM, true)
		var sc: int = _scores[pid] if pid < _scores.size() else 0
		C.bar(self, Rect2(size.x - 104, y + 9, 40, 4), float(sc) / best, col)
		C.text(self, Vector2(0, y + 15), "✗" if p["defeated"] else str(sc), 13, Palette.UI_TEXT, true, size.x - 10, HORIZONTAL_ALIGNMENT_RIGHT)
		y += ROW
