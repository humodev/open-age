extends Control
## Capa de órdenes sobre el mundo (proceso/23, parte B):
##   - bengalas (suceso "bengala" de la simulación): un aro que late y una banderita con el
##     color de quien la tiró, unos segundos, también en el minimapa;
##   - la flecha del rumbo mientras se arrastra el clic derecho;
##   - la ayuda del modo patrullar.
## No toma clics.

const Atajos := preload("res://src/game/ui/atajos.gd")

var hud: Hud
var flares: Array[Dictionary] = [] # {x, y, player, tipo, t} en casillas y segundos (el minimapa también las lee)


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)


func on_events(events: Array) -> void:
	for ev in events:
		if ev["t"] != "bengala":
			continue
		var pid := int(ev["player"])
		# Solo las del propio equipo: la del rival no se ve.
		if pid != hud.local and hud.sim.enemies(hud.local, pid):
			continue
		flares.append({"x": int(ev["x"]) / 1000.0, "y": int(ev["y"]) / 1000.0, "player": pid, "tipo": ev["tipo"], "t": 0.0})
		var quien := "Tu bengala" if pid == hud.local else "Bengala de %s" % Palette.team_name(pid)
		var que := "atacá acá" if ev["tipo"] == "atacar" else "defendé acá"
		hud.notify("%s: %s" % [quien, que], -1.0, "ataque" if ev["tipo"] == "atacar" else "decision", WorldView.to_world(int(ev["x"]), int(ev["y"])))
		if hud.main.get("audio") != null:
			hud.main.audio.ui("clic", -6.0)


func _process(delta: float) -> void:
	var dura := float(Atajos.cfg().get("bengala_s", 8))
	for f in flares:
		f["t"] += delta
	flares = flares.filter(func(f: Dictionary) -> bool: return f["t"] < dura)
	queue_redraw()


func _draw() -> void:
	var cam: RtsCamera = hud.cam
	for f in flares:
		var wp := Vector3(f["x"], WorldView.height_at(f["x"], f["y"]), f["y"])
		if cam.cam.is_position_behind(wp):
			continue
		var sp := cam.cam.unproject_position(wp)
		var col := Palette.team(f["player"])
		var k: float = fmod(f["t"], 1.0)
		draw_arc(sp, 14.0 + k * 60.0, 0, TAU, 40, Color(col.lightened(0.3), 1.0 - k), 5.0, true)
		draw_arc(sp, 14.0 + fmod(k + 0.5, 1.0) * 60.0, 0, TAU, 40, Color(col.lightened(0.3), 1.0 - fmod(k + 0.5, 1.0)), 3.0, true)
		draw_circle(sp, 6.0, Color.WHITE)
		draw_line(sp, sp + Vector2(0, -70), Color.WHITE, 3.0, true)
		Glyphs.draw(self, "bengala", Rect2(sp + Vector2(-8, -100), Vector2(56, 56)), col.lightened(0.25))
		var txt := "¡Atacá acá!" if f["tipo"] == "atacar" else "¡Defendé acá!"
		var tw := Hud.font_b.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 16).x
		draw_rect(Rect2(sp + Vector2(-tw / 2 - 8, -128), Vector2(tw + 16, 24)), Color(0, 0, 0, 0.6))
		draw_string(Hud.font_b, sp + Vector2(-tw / 2, -110), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color.WHITE)
	var ctrl: Controller = hud.ctrl
	# Flecha del rumbo mientras se arrastra el clic derecho.
	if ctrl.rpressing:
		var m := ctrl.mouse_pos()
		if m.distance_to(ctrl.rpress_pos) >= float(Atajos.cfg().get("arrastre_rumbo_px", 24)):
			var d := (m - ctrl.rpress_pos).normalized()
			draw_line(ctrl.rpress_pos, m, Color(Palette.UI_GOOD, 0.9), 4.0, true)
			draw_colored_polygon(PackedVector2Array([m + d * 10, m - d * 12 + d.orthogonal() * 10, m - d * 12 - d.orthogonal() * 10]), Palette.UI_GOOD)
			draw_string(Hud.font_b, ctrl.rpress_pos + Vector2(-80, 26), "Formación: %s" % ctrl.formacion, HORIZONTAL_ALIGNMENT_CENTER, 160, 13, Color.WHITE)
	if ctrl.mode == "patrol":
		draw_string(Hud.font_b, ctrl.mouse_pos() + Vector2(18, 30), "Patrullar hasta acá", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color.WHITE)
