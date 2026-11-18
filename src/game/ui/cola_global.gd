extends Control
## Cola global de producción (proceso/23, parte B; AoE4 desde abril de 2022): arriba de la
## pantalla, un ícono por edificio propio que está produciendo, con su avance y cuántos
## quedan en cola. Clic: selecciona el edificio y lleva la cámara. Mayús + clic: todos los
## edificios de ese tipo. Va a la derecha de la barra de recursos.
## --- frente 1 --- (proceso/30) Los que repiten llevan el bucle; los edificios de producción
## parados (sin cola hace `parado_s`) van al final, grises y con pulso. Un consejo avisa si
## quedan parados; clic derecho en uno gris lo apaga (Opciones.aviso_parados).

const ICON := 44.0
const SEP := 4.0

var hud: Hud
var _hits: Array = [] # [Rect2, edificio]
var _hover := -1
var _vacio_desde := {} # --- frente 1 --- id -> ms de juego desde que no tiene cola
var _aviso_ms := -1000000 # último consejo de parados (ms de juego)
var _parados_largos := 0

static var _cfg: Dictionary = {}


## data/interfaz.json → produccion (también lo usa hud.gd para el aviso de población).
static func cfg() -> Dictionary:
	if _cfg.is_empty():
		var path := "res://data/interfaz.json"
		if FileAccess.file_exists(path):
			_cfg = (JSON.parse_string(FileAccess.get_file_as_string(path)) as Dictionary).get("produccion", {})
		if _cfg.is_empty():
			_cfg = {"_": true}
	return _cfg


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	mouse_exited.connect(func() -> void:
		_hover = -1
		hud.hide_tip())


func _ms() -> int:
	return hud.sim.tick * int(hud.sim.data.reglas["tick_ms"])


## ¿Edificio propio y terminado que entrena unidades?
func _de_produccion(e: SimEntity) -> bool:
	return e.alive and e.owner == hud.local and e.is_building() and e.built and not (e.def.get("produce", []) as Array).is_empty()


## ¿Parado (sin cola) hace al menos parado_s segundos de juego?
func parado(e: SimEntity) -> bool:
	return e.queue.is_empty() and _vacio_desde.has(e.id) and _ms() - int(_vacio_desde[e.id]) >= int(cfg().get("parado_s", 10)) * 1000


## Edificios propios con algo en cola, en orden de id, y después los de producción parados
## (lo que se dibuja).
func items() -> Array[SimEntity]:
	var out: Array[SimEntity] = []
	var quietos: Array[SimEntity] = []
	var cap := int(hud.ctrl.atajos.cfg().get("cola_global_max", 14))
	var cap_p := int(cfg().get("cola_global_parados", 6))
	for e in hud.sim.actives:
		if not (e.alive and e.owner == hud.local and e.is_building() and e.built):
			continue
		if not e.queue.is_empty():
			if out.size() < cap:
				out.append(e)
		elif _de_produccion(e) and parado(e) and quietos.size() < cap_p:
			quietos.append(e)
	for e in quietos:
		if out.size() >= cap:
			break
		out.append(e)
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
				hud.show_tip(_tip(b), Rect2(global_position + (_hits[h][0] as Rect2).position + Vector2(0, 190), Vector2(ICON, ICON)))
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
	elif ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_RIGHT:
		# --- frente 1 --- clic derecho en un parado: prende o apaga el consejo de parados
		for h in _hits:
			if (h[0] as Rect2).has_point(ev.position) and (h[1] as SimEntity).queue.is_empty():
				alternar_aviso()
				accept_event()
				return


## Prende o apaga el consejo de parados (se guarda en las opciones).
func alternar_aviso() -> void:
	Opciones.aviso_parados = not Opciones.aviso_parados
	Opciones.guardar()
	hud.notify("Consejo de edificios parados %s (clic derecho en un ícono gris lo %s)" % ["prendido" if Opciones.aviso_parados else "apagado", "apaga" if Opciones.aviso_parados else "vuelve a prender"], 5.0, "info")


func _tip(b: SimEntity) -> Dictionary:
	var dd := hud.sim.dp(b.owner)
	var rep := ""
	if b.repeat != "":
		rep = "\nSe repite: %s." % str(dd.unidades.get(b.repeat, {}).get("nombre", b.repeat))
		var why := hud.sim.repeat_block(b) if b.queue.is_empty() else ""
		rep += {"pob": " Frenada: población llena.", "recursos": " Frenada: no alcanza sin tocar lo apartado.", "tope": " Llegó al tope de aldeanos."}.get(why, "") as String
	if b.queue.is_empty():
		var s := (_ms() - int(_vacio_desde.get(b.id, _ms()))) / 1000
		return {"name": "%s · parado" % b.def.get("nombre", b.type), "desc": "Sin producir hace %d s.%s\nClic: ir al edificio. Mayús + clic: todos los de este tipo. Clic derecho: %s el consejo de parados." % [s, rep, "apagar" if Opciones.aviso_parados else "prender"], "cost": {}, "locked": ""}
	var item: String = b.queue[0]
	var what: String = dd.tecnologias.get(item.substr(1), {}).get("nombre", item) if item.begins_with("@") else dd.unidades.get(item, {}).get("nombre", item)
	return {"name": "%s · %s" % [b.def.get("nombre", b.type), what], "desc": "%d en cola.%s\nClic: ir al edificio. Mayús + clic: todos los edificios de este tipo." % [b.queue.size(), rep], "cost": {}, "locked": ""}


func _process(_d: float) -> void:
	_seguir_parados()
	queue_redraw()


## Cuándo se vació cada edificio de producción, y el consejo si quedan parados un rato.
func _seguir_parados() -> void:
	var now := _ms()
	var largos := 0
	var vivos := {}
	for e in hud.sim.actives:
		if not _de_produccion(e):
			continue
		vivos[e.id] = true
		if not e.queue.is_empty():
			_vacio_desde.erase(e.id)
		elif not _vacio_desde.has(e.id):
			_vacio_desde[e.id] = now
		elif now - int(_vacio_desde[e.id]) >= int(cfg().get("aviso_parados_s", 45)) * 1000:
			largos += 1
	for id in _vacio_desde.keys():
		if not vivos.has(id):
			_vacio_desde.erase(id)
	if largos > 0 and _parados_largos == 0 and Opciones.consejos and Opciones.aviso_parados and now - _aviso_ms >= int(cfg().get("aviso_parados_cada_s", 120)) * 1000:
		_aviso_ms = now
		hud.notify("%s sin producir (grises en la cola de arriba)\nClic en uno: ir. Ctrl + clic en una unidad: se repite sola. Clic derecho en un gris: no avisar más." % ("Un edificio de producción" if largos == 1 else "%d edificios de producción" % largos), 9.0, "info")
	_parados_largos = largos


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
	# Pulso de los parados (reloj de la interfaz, no de la simulación).
	var pulso := 0.5 + 0.5 * sin(Time.get_ticks_msec() / 1000.0 * TAU / float(cfg().get("pulso_s", 1.2)))
	for i in list.size():
		var b := list[i]
		var r := Rect2(x, 5, ICON, ICON)
		var cell := StyleBoxFlat.new()
		cell.set_corner_radius_all(6)
		if b.queue.is_empty():
			# --- frente 1 --- parado: gris, con el borde que late
			cell.bg_color = Color(0.5, 0.5, 0.5, 0.16 if i == _hover else 0.08)
			cell.border_color = Color(Palette.UI_ACCENT, 0.25 + 0.6 * pulso)
			cell.set_border_width_all(2)
			draw_style_box(cell, r)
			Glyphs.draw(self, Glyphs.resolve(b.def, b.type), r.grow(-9), Color(Palette.UI_DIM, 0.55 + 0.35 * pulso))
		else:
			cell.bg_color = Color(1, 1, 1, 0.14 if i == _hover else 0.06)
			draw_style_box(cell, r)
			var item: String = b.queue[0]
			Glyphs.draw(self, hud.queue_icon(item), r.grow(-8), Palette.UI_ACCENT if item.begins_with("@") else Palette.UI_TEXT)
			var k := float(b.queue_progress) / float(maxi(1, hud.sim.dp(b.owner).queue_time(item)))
			draw_rect(Rect2(r.position.x + 3, r.end.y - 6, r.size.x - 6, 4), Color(0, 0, 0, 0.5))
			draw_rect(Rect2(r.position.x + 3, r.end.y - 6, (r.size.x - 6) * clampf(k, 0, 1), 4), Palette.UI_ACCENT)
			if b.queue.size() > 1:
				draw_string(Hud.font_b, r.position + Vector2(0, 14), str(b.queue.size()), HORIZONTAL_ALIGNMENT_RIGHT, r.size.x - 4, 12, Palette.UI_ACCENT)
		if b.repeat != "":
			Hud.draw_bucle(self, r.position + Vector2(10, 11), 5.5, Palette.UI_ACCENT)
		_hits.append([r, b])
		x += ICON + SEP
