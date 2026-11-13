extends Control
## Registro de sucesos (F5): lista desplegable con los últimos avisos, con hora.
## Clic en un suceso con lugar: la cámara va ahí. Rueda: recorre la lista.

const C := preload("res://src/game/ui/panel_comun.gd")
const ROW := 21.0
const ROWS_OPEN := 14
const HEAD := 30.0

var hud: Hud
var datos # PanelDatos
var expanded := false
var _scroll := 0
var _hover := -1
var _rows: Array = [] # [Rect2, índice en datos.log]


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	mouse_exited.connect(func() -> void: _hover = -1)


func toggle() -> void:
	expanded = not expanded
	_scroll = 0
	if expanded:
		datos.log_unread = 0


func _process(_d: float) -> void:
	var n: int = mini(datos.log.size(), ROWS_OPEN) if expanded else mini(datos.log.size(), 1)
	var h := HEAD + n * ROW + (8.0 if n > 0 else 2.0)
	if size.y != h:
		size.y = h
	if expanded:
		datos.log_unread = 0
	queue_redraw()


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		_hover = -1
		for r in _rows:
			if (r[0] as Rect2).has_point(event.position):
				_hover = r[1]
	elif event is InputEventMouseButton and event.pressed:
		match event.button_index:
			MOUSE_BUTTON_WHEEL_UP:
				_scroll = maxi(0, _scroll - 1)
			MOUSE_BUTTON_WHEEL_DOWN:
				_scroll = mini(maxi(0, datos.log.size() - ROWS_OPEN), _scroll + 1)
			MOUSE_BUTTON_LEFT:
				if event.position.y < HEAD:
					toggle()
				else:
					for r in _rows:
						if (r[0] as Rect2).has_point(event.position):
							_go(datos.log[r[1]])
		accept_event()


func _go(entry: Dictionary) -> void:
	if int(entry["x"]) < 0:
		return
	hud.cam.look_at_point(WorldView.to_world(entry["x"], entry["y"]))
	if hud._mini != null:
		hud._mini.ping(entry["x"], entry["y"])


func _draw() -> void:
	_rows.clear()
	draw_style_box(Hud.panel_box(8), Rect2(Vector2.ZERO, size))
	var unread: int = datos.log_unread
	C.text(self, Vector2(14, 20), "Sucesos", 14, Palette.UI_TEXT, true)
	if unread > 0 and not expanded:
		var badge := "%d nuevo%s" % [unread, "s" if unread > 1 else ""]
		C.text(self, Vector2(84, 20), badge, 12, Palette.UI_ACCENT, true)
	C.text(self, Vector2(0, 20), "F5  %s" % ("▴" if expanded else "▾"), 12, Palette.UI_DIM, false, size.x - 12, HORIZONTAL_ALIGNMENT_RIGHT)
	var list: Array = datos.log
	if list.is_empty():
		return
	var n: int = mini(list.size(), ROWS_OPEN) if expanded else 1
	var y := HEAD + 2
	for i in n:
		var idx: int = list.size() - 1 - i - (_scroll if expanded else 0)
		if idx < 0:
			break
		var e: Dictionary = list[idx]
		var r := Rect2(4, y, size.x - 8, ROW)
		_rows.append([r, idx])
		if idx == _hover and int(e["x"]) >= 0:
			draw_rect(r, Color(1, 1, 1, 0.07))
		C.text(self, Vector2(12, y + 15), C.fmt_time(e["t"]), 12, Palette.UI_DIM)
		C.text(self, Vector2(56, y + 15), e["txt"], 13, e["col"], false, size.x - 56 - 26)
		if int(e["x"]) >= 0:
			C.text(self, Vector2(0, y + 15), "◎", 12, Palette.UI_DIM, false, size.x - 12, HORIZONTAL_ALIGNMENT_RIGHT)
		y += ROW
	if expanded and list.size() > ROWS_OPEN:
		var k := float(_scroll) / float(list.size() - ROWS_OPEN)
		var track := ROWS_OPEN * ROW
		draw_rect(Rect2(size.x - 4, HEAD + 2 + (track - 24) * k, 2, 24), Color(1, 1, 1, 0.25))
