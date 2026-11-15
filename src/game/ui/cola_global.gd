extends Control
## Cola global de producción (proceso/23, parte B; AoE4 desde abril de 2022): arriba de la
## pantalla, un ícono por edificio propio que está produciendo, con su avance y cuántos
## quedan en cola. Clic: selecciona el edificio y lleva la cámara. Mayús + clic: todos los
## edificios de ese tipo. Va a la derecha de la barra de recursos.

const ICON := 44.0
const SEP := 4.0

var hud: Hud
var _hits: Array = [] # [Rect2, edificio]
var _hover := -1


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	mouse_exited.connect(func() -> void:
		_hover = -1
		hud.hide_tip())


## Edificios propios con algo en cola, en orden de id (lo que se dibuja).
func items() -> Array[SimEntity]:
	var out: Array[SimEntity] = []
	var cap := int(hud.ctrl.atajos.cfg().get("cola_global_max", 14))
	for e in hud.sim.actives:
		if e.alive and e.owner == hud.local and e.is_building() and e.built and not e.queue.is_empty():
			out.append(e)
			if out.size() >= cap:
				break
	return out


func _has_point(p: Vector2) -> bool:
	for h in _hits:
		if (h[0] as Rect2).has_point(p):
			return true
	return false


func _gui_input(ev: InputEvent) -> void:
	if ev is InputEventMouseMotion:
		var h := -1
		for i in _hits.size():
			if (_hits[i][0] as Rect2).has_point(ev.position):
				h = i
		if h != _hover:
			_hover = h
			if h < 0:
				hud.hide_tip()
			else:
				var b: SimEntity = _hits[h][1]
				var item: String = b.queue[0] if not b.queue.is_empty() else ""
				var what: String = hud.sim.dp(b.owner).tecnologias.get(item.substr(1), {}).get("nombre", item) if item.begins_with("@") else hud.sim.dp(b.owner).unidades.get(item, {}).get("nombre", item)
				hud.show_tip({"name": "%s · %s" % [b.def.get("nombre", b.type), what], "desc": "%d en cola. Clic: ir al edificio. Mayús + clic: todos los edificios de este tipo." % b.queue.size(), "cost": {}, "locked": ""}, Rect2(global_position + (_hits[h][0] as Rect2).position + Vector2(0, 190), Vector2(ICON, ICON)))
	elif ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
		for h in _hits:
			if (h[0] as Rect2).has_point(ev.position):
				var b: SimEntity = h[1]
				if Input.is_key_pressed(KEY_SHIFT):
					hud.ctrl.atajos.todos_del_tipo(b.type)
				else:
					hud.ctrl.select_ids([b.id] as Array[int])
					hud.ctrl.center_on_selection()
				accept_event()
				return


func _process(_d: float) -> void:
	queue_redraw()


func _draw() -> void:
	_hits.clear()
	var list := items()
	if list.is_empty():
		return
	var x := 0.0
	var w := list.size() * (ICON + SEP) - SEP + 12.0
	var sb := Hud.panel_box(8)
	sb.shadow_size = 4
	draw_style_box(sb, Rect2(0, 0, w, ICON + 10))
	x = 6.0
	for i in list.size():
		var b := list[i]
		var r := Rect2(x, 5, ICON, ICON)
		var cell := StyleBoxFlat.new()
		cell.set_corner_radius_all(6)
		cell.bg_color = Color(1, 1, 1, 0.14 if i == _hover else 0.06)
		draw_style_box(cell, r)
		var item: String = b.queue[0]
		Glyphs.draw(self, hud.queue_icon(item), r.grow(-8), Palette.UI_ACCENT if item.begins_with("@") else Palette.UI_TEXT)
		var k := float(b.queue_progress) / float(maxi(1, hud.sim.dp(b.owner).queue_time(item)))
		draw_rect(Rect2(r.position.x + 3, r.end.y - 6, r.size.x - 6, 4), Color(0, 0, 0, 0.5))
		draw_rect(Rect2(r.position.x + 3, r.end.y - 6, (r.size.x - 6) * clampf(k, 0, 1), 4), Palette.UI_ACCENT)
		if b.queue.size() > 1:
			draw_string(Hud.font_b, r.position + Vector2(0, 14), str(b.queue.size()), HORIZONTAL_ALIGNMENT_RIGHT, r.size.x - 4, 12, Palette.UI_ACCENT)
		_hits.append([r, b])
		x += ICON + SEP
