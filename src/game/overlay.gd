class_name Overlay
extends Control
## Barras de vida, progreso de obra y rectángulo de selección (docs/07, legibilidad).

const HEIGHTS := {"centro": 3.2, "casa": 1.7, "deposito": 1.8, "granja": 0.6, "cuartel": 2.3, "torre": 3.7, "hito_economia": 3.2, "hito_guerra": 3.5, "empalizada": 1.4, "puerta": 1.8}

var sim: Sim
var ctrl: Controller
var cam: RtsCamera


func setup(s: Sim, c: Controller, camera: RtsCamera) -> void:
	sim = s
	ctrl = c
	cam = camera
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	var view := ctrl.view
	var zoom_k := clampf(40.0 / cam.zoom, 0.6, 1.6)
	var all_bars := Input.is_key_pressed(KEY_ALT) and ctrl.enabled # --- mundo --- Alt: todas las barras
	all_bars = all_bars or Opciones.barras_siempre # --- opciones --- barras de vida siempre visibles
	for e in sim.actives:
		var sel := view.selected.has(e.id)
		var hov := view.hovered == e.id
		var damaged := e.hp < e.hp_max
		if not (sel or hov or damaged or (e.is_building() and not e.built) or (all_bars and e.hp_max > 1)):
			continue
		var v: Dictionary = view.visuals.get(e.id, {})
		if v.is_empty() or e.inside >= 0 or view.fog_state(e) < 2:
			continue
		var wp: Vector3 = (v["node"] as Node3D).position
		wp.y += (1.6 if e.type == "ariete" else 1.2) if e.is_unit() else HEIGHTS.get(e.type, 2.0)
		if cam.cam.is_position_behind(wp):
			continue
		var sp := cam.cam.unproject_position(wp)
		var w := (30.0 if e.is_unit() else 64.0) * zoom_k
		var r := Rect2(sp.x - w / 2, sp.y, w, 4.0 if e.is_unit() else 5.0)
		draw_rect(r.grow(1), Color(0, 0, 0, 0.6))
		var k := float(e.hp) / float(e.hp_max)
		var col := Palette.team(e.owner)
		if e.owner == ctrl.local:
			col = Palette.UI_GOOD.lerp(Palette.UI_BAD, clampf(1.0 - k * 1.6, 0.0, 1.0))
		# --- contraste --- por debajo del 25 % la barra titila: la vida baja no depende solo del color
		if k < 0.25:
			col.a = 0.35 + 0.65 * absf(sin(Time.get_ticks_msec() / 160.0))
		# --- fin contraste ---
		draw_rect(Rect2(r.position, Vector2(r.size.x * k, r.size.y)), col)
		if e.is_building() and not e.built:
			var pk := float(e.progress) / float(maxi(1, e.build_time))
			var pr := Rect2(r.position + Vector2(0, r.size.y + 3), Vector2(r.size.x, 3))
			draw_rect(pr.grow(1), Color(0, 0, 0, 0.6))
			draw_rect(Rect2(pr.position, Vector2(pr.size.x * pk, pr.size.y)), Palette.UI_ACCENT)
			# --- mundo --- porcentaje de obra y constructores, al pasar el mouse o seleccionado
			if (sel or hov) and Hud.font_b != null:
				var txt := "%d%%" % int(pk * 100.0)
				var wk := maxi(e.workers_now, e.workers_prev)
				if wk > 0:
					txt += " · %d %s" % [wk, "constructor" if wk == 1 else "constructores"]
				var fs := 12
				var tw := Hud.font_b.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
				var tp := Vector2(sp.x - tw / 2, pr.end.y + 13)
				draw_string_outline(Hud.font_b, tp, txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, 3, Color(0, 0, 0, 0.7))
				draw_string(Hud.font_b, tp, txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Palette.UI_ACCENT)
	if ctrl.dragging:
		var m := ctrl.mouse_pos()
		var box := Rect2(ctrl.press_pos, m - ctrl.press_pos).abs()
		draw_rect(box, Color(1, 1, 1, 0.07))
		draw_rect(box, Color(1, 1, 1, 0.75), false, 1.0)
