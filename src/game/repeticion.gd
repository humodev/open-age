class_name BarraRepeticion
extends PanelContainer
## Línea de tiempo de una repetición (proceso/30-fluidez/07): pausa, velocidad ×1 a ×8
## (data/interfaz.json → guardado.velocidades) y saltar a un minuto. Saltar arma la
## repetición de nuevo y la re-simula sin dibujo hasta ese tick (main.saltar_repeticion).
## La cámara queda libre: el controlador está apagado y no hay niebla.

var main # Main
var total := 0 # ticks de la repetición
var _slider: HSlider
var _hora: Label
var _pausa: Button
var _vel: Array[Button] = []
var _arrastrando := false


func setup(m, total_ticks: int) -> void:
	main = m
	total = maxi(1, total_ticks)
	name = "Repeticion"
	anchor_left = 0.5
	anchor_right = 0.5
	anchor_top = 1.0
	anchor_bottom = 1.0
	offset_left = -380
	offset_right = 380
	offset_top = -64
	offset_bottom = -12
	mouse_filter = Control.MOUSE_FILTER_STOP
	var sb := Hud.panel_box(8)
	sb.set_content_margin_all(8)
	add_theme_stylebox_override("panel", sb)
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 8)
	add_child(hb)
	_pausa = Button.new()
	_pausa.custom_minimum_size = Vector2(84, 0)
	_pausa.pressed.connect(func() -> void: main.set_paused(not main.paused))
	hb.add_child(_pausa)
	_slider = HSlider.new()
	_slider.min_value = 0
	_slider.max_value = total
	_slider.step = 1
	_slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_slider.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_slider.tooltip_text = "Arrastrá para saltar a otro momento de la partida"
	_slider.drag_started.connect(func() -> void: _arrastrando = true)
	_slider.drag_ended.connect(func(_c: bool) -> void:
		_arrastrando = false
		main.saltar_repeticion(int(_slider.value)))
	hb.add_child(_slider)
	_hora = Label.new()
	_hora.custom_minimum_size = Vector2(118, 0)
	_hora.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	if Hud.font != null:
		_hora.add_theme_font_override("font", Hud.font)
	hb.add_child(_hora)
	for v in Guardado.cfg().get("velocidades", [1, 2, 4, 8]):
		var b := Button.new()
		b.text = "×%d" % int(v)
		b.toggle_mode = true
		b.set_meta("v", float(v))
		b.pressed.connect(func() -> void: main.speed = float(v))
		hb.add_child(b)
		_vel.append(b)
	var salir := Button.new()
	salir.text = "Salir"
	salir.pressed.connect(func() -> void: main.to_menu())
	hb.add_child(salir)


func _process(_d: float) -> void:
	if main == null or main.sim == null:
		return
	var t: int = main.sim.tick
	if t >= total and not main.paused:
		main.set_paused(true) # llegó al final: queda quieta
	if not _arrastrando:
		_slider.set_value_no_signal(mini(t, total))
	var shown := int(_slider.value) if _arrastrando else t
	var tms: int = main.sim.tick_ms
	_hora.text = "%s / %s" % [_mmss(shown * tms), _mmss(total * tms)]
	_pausa.text = "Seguir" if main.paused else "Pausa"
	for b in _vel:
		b.set_pressed_no_signal(is_equal_approx(float(b.get_meta("v")), main.speed))


static func _mmss(ms: int) -> String:
	return "%d:%02d" % [ms / 60000, (ms / 1000) % 60]
