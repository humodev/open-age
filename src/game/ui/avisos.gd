extends Control
## Avisos del momento con jerarquía (docs/diseno/interfaz/00-auditoria.md, P6 y mejora 7).
##
## Cada aviso tiene tipo (ataque, decision, hito, info), color, ícono y fondo propio. Se apilan
## arriba al centro, el más nuevo arriba, sin pisarse; si llega el mismo texto se suma (×2).
## Los que tienen lugar en el mapa se recuerdan: Espacio lleva al último (primero los ataques)
## e Inicio recorre los anteriores. Un clic en un aviso con lugar también lleva la cámara.
## El registro completo es de otro panel (src/game/ui/panel_sucesos.gd): esto es solo el momento.

const ANCHO := 560.0
const ALTO := 38.0
const SEP := 6.0
const TIPOS := {
	"ataque": {"icono": "atacar"},
	"decision": {"icono": "decision"},
	"hito": {"icono": "hito_logro"},
	"info": {"icono": "info"},
}

var cfg: Dictionary = {}
var lista: Array[Dictionary] = [] # {texto, tipo, t, dur, n, lugar}
var historial: Array[Dictionary] = [] # {lugar: Vector3, tipo, texto}, el más nuevo al final
var _ciclo := -1
var _hits: Array = [] # [Rect2, Dictionary]


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	var path := "res://data/interfaz.json"
	var all: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(path)) if FileAccess.file_exists(path) else {}
	cfg = all.get("avisos", {})


static func color(tipo: String) -> Color:
	match tipo:
		"ataque":
			return Palette.UI_BAD
		"decision":
			return Palette.UI_ACCENT
		"hito":
			return Palette.UI_GOOD
	return Palette.UI_TEXT


## Agrega un aviso. `secs` < 0 usa la duración del tipo; `lugar` (Vector3 del mundo) lo vuelve saltable.
func push(texto: String, tipo: String = "info", secs: float = -1.0, lugar: Variant = null) -> void:
	if not TIPOS.has(tipo):
		tipo = "info"
	var dur := secs if secs > 0.0 else float((cfg.get("duracion_s", {}) as Dictionary).get(tipo, 2.6))
	for a in lista:
		if a["texto"] == texto and a["tipo"] == tipo:
			a["n"] = int(a["n"]) + 1
			a["t"] = maxf(float(a["t"]), dur)
			if lugar is Vector3:
				a["lugar"] = lugar
				_recordar(lugar, tipo, texto)
			lista.erase(a)
			lista.push_front(a)
			queue_redraw()
			return
	lista.push_front({"texto": texto, "tipo": tipo, "t": dur, "dur": dur, "n": 1, "lugar": lugar})
	var maxv := int(cfg.get("max_visibles", 4))
	while lista.size() > maxv:
		lista.pop_back()
	if lugar is Vector3:
		_recordar(lugar, tipo, texto)
	queue_redraw()


func _recordar(lugar: Vector3, tipo: String, texto: String) -> void:
	historial.append({"lugar": lugar, "tipo": tipo, "texto": texto})
	while historial.size() > int(cfg.get("historial", 12)):
		historial.pop_front()
	_ciclo = -1


## Lugar al que saltar: el último ataque (o el último suceso si no hubo ataques) con Espacio;
## con `ciclar` (Inicio), el siguiente más viejo cada vez. null si no hay ninguno.
func saltar(ciclar: bool) -> Variant:
	if historial.is_empty():
		return null
	if ciclar:
		_ciclo = (historial.size() - 1) if _ciclo <= 0 else _ciclo - 1
		return historial[_ciclo]["lugar"]
	for i in range(historial.size() - 1, -1, -1):
		if historial[i]["tipo"] == "ataque":
			_ciclo = i
			return historial[i]["lugar"]
	_ciclo = historial.size() - 1
	return historial[-1]["lugar"]


func _process(delta: float) -> void:
	if lista.is_empty():
		return
	for a in lista.duplicate():
		a["t"] = float(a["t"]) - delta
		if float(a["t"]) <= 0.0:
			lista.erase(a)
	queue_redraw()


## Alto que ocupa la pila dibujada (para correr el diálogo de campaña debajo).
func alto_usado() -> float:
	return 0.0 if _hits.is_empty() else (_hits[-1][0] as Rect2).end.y


## Solo los avisos dibujados bloquean el mouse; el resto del rectángulo deja pasar los clics.
func _has_point(p: Vector2) -> bool:
	for h in _hits:
		if (h[0] as Rect2).has_point(p):
			return true
	return false


func _gui_input(ev: InputEvent) -> void:
	if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
		for h in _hits:
			if (h[0] as Rect2).has_point(ev.position) and (h[1] as Dictionary).get("lugar") is Vector3:
				var hud := get_parent()
				hud.cam.look_at_point(h[1]["lugar"])
				accept_event()
				return
		accept_event()


func _draw() -> void:
	_hits.clear()
	var y := 0.0
	var x0 := (size.x - ANCHO) / 2.0
	var espacio := false # solo el más nuevo con lugar dice "Espacio"; los demás, "clic"
	for a in lista:
		var col := color(a["tipo"])
		var alpha := clampf(float(a["t"]) / 0.4, 0.0, 1.0)
		var texto: String = a["texto"]
		var cut := texto.find("\n")
		var titulo := texto if cut < 0 else texto.substr(0, cut)
		var resto := "" if cut < 0 else texto.substr(cut + 1)
		var rh := 0.0 if resto == "" else Hud.font.get_multiline_string_size(resto, HORIZONTAL_ALIGNMENT_LEFT, ANCHO - 60, 14).y + 2
		var h := ALTO + rh
		var r := Rect2(x0, y, ANCHO, h)
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color(0.06, 0.065, 0.075, 0.9 * alpha)
		sb.set_corner_radius_all(7)
		sb.border_color = Color(col, 0.55 * alpha)
		sb.set_border_width_all(1)
		sb.border_width_left = 5
		sb.shadow_color = Color(0, 0, 0, 0.3 * alpha)
		sb.shadow_size = 6
		draw_style_box(sb, r)
		Glyphs.draw(self, TIPOS[a["tipo"]]["icono"], Rect2(r.position + Vector2(14, 8), Vector2(22, 22)), Color(col, alpha))
		draw_string(Hud.font_b, Vector2(r.position.x + 46, r.position.y + 25), titulo, HORIZONTAL_ALIGNMENT_LEFT, ANCHO - 140, 17, Color(Palette.UI_TEXT, alpha))
		if resto != "":
			draw_multiline_string(Hud.font, Vector2(r.position.x + 46, r.position.y + 45), resto, HORIZONTAL_ALIGNMENT_LEFT, ANCHO - 60, 14, -1, Color(Palette.UI_DIM.lightened(0.15), alpha))
		var right := ""
		if int(a["n"]) > 1:
			right = "×%d" % int(a["n"])
		if a.get("lugar") is Vector3:
			right = ("%s  " % right if right != "" else "") + ("clic" if espacio else "Espacio")
			espacio = true
		if right != "":
			draw_string(Hud.font_b, Vector2(r.position.x, r.position.y + 24), right, HORIZONTAL_ALIGNMENT_RIGHT, ANCHO - 14, 13, Color(col if a.get("lugar") is Vector3 else Palette.UI_DIM, alpha))
		_hits.append([r, a])
		y += h + SEP
