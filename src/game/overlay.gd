class_name Overlay
extends Control
## Barras de vida, progreso de obra y rectángulo de selección (docs/07, legibilidad).

const HEIGHTS := {"centro": 3.2, "casa": 1.7, "deposito": 1.8, "granja": 0.6, "cuartel": 2.3, "torre": 3.7, "hito_economia": 3.2, "hito_guerra": 3.5, "empalizada": 1.4, "puerta": 1.8, "muralla": 1.9, "puerta_piedra": 2.1, "torre_muralla": 3.2}

var sim: Sim
var ctrl: Controller
var cam: RtsCamera


func setup(s: Sim, c: Controller, camera: RtsCamera) -> void:
	sim = s
	ctrl = c
	cam = camera
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


## Ticks que la barra de una unidad sigue a la vista después de su último golpe
## (data/interfaz.json → mundo.barras_combate_s).
static var _combat_s := -1.0
static var _mundo := {} # --- veterano ronda 5 --- data/interfaz.json → mundo

static func combat_ticks(s: Sim) -> int:
	if _combat_s < 0.0:
		_combat_s = float(mundo().get("barras_combate_s", 4))
	return int(_combat_s * 1000.0) / maxi(1, s.tick_ms)


# --- veterano ronda 5 ---
## data/interfaz.json → "mundo" (barras, ícono de ocioso).
static func mundo() -> Dictionary:
	if _mundo.is_empty():
		var all: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/interfaz.json"))
		_mundo = all.get("mundo", {})
	return _mundo


## ¿Se dibuja la barra de vida? Como en AoE4: lo elegido, lo que está bajo el mouse, lo dañado y
## las obras. Las unidades sanas que pelean, solo con la opción «Barras de las tropas sanas al
## pelear» (antes era siempre, y en una batalla de 30 contra 30 el rojo tapaba a las figuras).
## `todas`: Alt mantenido o «Barras de vida siempre visibles».
static func barra_visible(s: Sim, e: SimEntity, sel: bool, hov: bool, todas: bool, ticks: int = -1) -> bool:
	if sel or hov or e.hp < e.hp_max or (e.is_building() and not e.built) or (todas and e.hp_max > 1):
		return true
	return Opciones.barras_pelea and en_combate(s, e, ticks)


## Alto de la barra de una unidad sobre el suelo: la cabeza (la lanza o el arco no cuentan);
## los montados y los elefantes, su figura entera. Se mide una vez por unidad.
func _alto_barra(e: SimEntity, v: Dictionary) -> float:
	if v.has("alto_barra"):
		return v["alto_barra"]
	var persona := WorldView.FIGURE_H * ctrl.view._unit_k
	var alto := persona
	if e.type == "ariete":
		alto = 1.45
	elif v.has("body") and is_instance_valid(v["body"]):
		var top := WorldView._aabb(v["body"], Transform3D.IDENTITY).end.y
		if e.def.get("montado", false) or top > persona * 2.05:
			alto = top
	alto += float((mundo().get("barra_unidad", {}) as Dictionary).get("sobre_cabeza", 0.12))
	v["alto_barra"] = alto
	return alto
# --- fin veterano ronda 5 ---


## --- combate --- ¿Una unidad pegó o recibió un golpe hace poco? Su barra se ve sin Alt
## ni la opción "barras siempre".
static func en_combate(s: Sim, e: SimEntity, ticks: int = -1) -> bool:
	return e.is_unit() and s.tick - e.last_combat <= (ticks if ticks >= 0 else combat_ticks(s))


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	var view := ctrl.view
	var zoom_k := clampf(40.0 / cam.zoom, 0.6, 1.6)
	var all_bars := Input.is_key_pressed(KEY_ALT) and ctrl.enabled # --- mundo --- Alt: todas las barras
	all_bars = all_bars or Opciones.barras_siempre # --- opciones --- barras de vida siempre visibles
	var combat_ticks := Overlay.combat_ticks(sim)
	# --- veterano ronda 5 --- barras de unidad finas, sobre la cabeza (data/interfaz.json → mundo.barra_unidad)
	var bu: Dictionary = Overlay.mundo().get("barra_unidad", {})
	var uk := minf(zoom_k, float(bu.get("tope_zoom", 1.4)))
	var uw := float(bu.get("ancho_px", 18)) * uk
	var uh := maxf(2.0, round(float(bu.get("alto_px", 2)) * uk))
	for e in sim.actives:
		var sel := view.selected.has(e.id)
		var hov := view.hovered == e.id
		# --- combate --- (proceso/24, 4k; veterano ronda 5: las sanas al pelear, solo con la opción)
		if not Overlay.barra_visible(sim, e, sel, hov, all_bars, combat_ticks):
			continue
		var v: Dictionary = view.visuals.get(e.id, {})
		if v.is_empty() or e.inside >= 0 or view.fog_state(e) < 2:
			continue
		var wp: Vector3 = (v["node"] as Node3D).position
		wp.y += _alto_barra(e, v) if e.is_unit() else HEIGHTS.get(e.type, 2.0)
		if cam.cam.is_position_behind(wp):
			continue
		var sp := cam.cam.unproject_position(wp)
		var w := uw if e.is_unit() else 64.0 * zoom_k
		var r := Rect2(sp.x - w / 2, sp.y - (uh if e.is_unit() else 0.0), w, uh if e.is_unit() else 5.0)
		draw_rect(r.grow(1), Color(0, 0, 0, 0.45 if e.is_unit() else 0.6))
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
