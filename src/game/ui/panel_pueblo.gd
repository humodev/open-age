extends PanelContainer
## "Cómo juega mi pueblo" (F1 o desde la pausa): la ficha de la civilización en
## palabras llanas, armada desde data/civs/<clave>.json (frase, motor propio,
## fortalezas, debilidades, hitos y consejos), y los controles.

const C := preload("res://src/game/ui/panel_comun.gd")

var hud: Hud
var _rt: RichTextLabel
var _dim: ColorRect


## Arma el diálogo con su fondo oscuro, como los de Hud._make_dialog.
func build(h: Hud) -> void:
	hud = h
	_dim = ColorRect.new()
	_dim.color = Color(0, 0, 0, 0.45)
	_dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_dim.mouse_filter = Control.MOUSE_FILTER_STOP
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_dim.add_child(center)
	var sb := Hud.panel_box(10)
	sb.content_margin_left = 30
	sb.content_margin_right = 30
	sb.content_margin_top = 22
	sb.content_margin_bottom = 22
	add_theme_stylebox_override("panel", sb)
	center.add_child(self)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 12)
	add_child(vb)
	_rt = RichTextLabel.new()
	_rt.bbcode_enabled = true
	_rt.scroll_active = true
	_rt.custom_minimum_size = Vector2(900, 700)
	_rt.add_theme_font_override("normal_font", Hud.font)
	_rt.add_theme_font_override("bold_font", Hud.font_b)
	_rt.add_theme_font_override("italics_font", Hud.font)
	_rt.add_theme_font_size_override("normal_font_size", 16)
	_rt.add_theme_font_size_override("bold_font_size", 16)
	_rt.add_theme_color_override("default_color", Palette.UI_TEXT)
	vb.add_child(_rt)
	var close := Button.new()
	close.text = "Cerrar (F1)"
	close.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	close.custom_minimum_size = Vector2(260, 0)
	close.pressed.connect(func() -> void: visible = false)
	vb.add_child(close)
	hud.add_child(_dim)
	visibility_changed.connect(func() -> void:
		_dim.visible = visible
		if visible:
			_rt.text = compose()
			_rt.scroll_to_line(0))
	visible = false
	_dim.visible = false


func _h(s: String) -> String:
	return "\n[font_size=19][b][color=#%s]%s[/color][/b][/font_size]\n" % [Palette.UI_ACCENT.to_html(false), s]


func _dimc(s: String) -> String:
	return "[color=#%s]%s[/color]" % [Palette.UI_DIM.to_html(false), s]


func compose() -> String:
	var sim := hud.sim
	var pid := hud.local
	var dd := sim.dp(pid)
	var c: Dictionary = dd.civ
	var out := ""
	if c.is_empty():
		out += "[font_size=30][b]Tu pueblo[/b][/font_size]\n" + _dimc("Partida sin civilización: la capa común.") + "\n"
	else:
		out += "[font_size=30][b]%s[/b][/font_size]   %s\n" % [c.get("nombre", ""), _dimc(c.get("region", ""))]
		out += "[color=#%s][font_size=19]«%s»[/font_size][/color]\n\n" % [Palette.UI_ACCENT.to_html(false), c.get("frase", "")]
		out += "%s\n" % c.get("descripcion", "")
		var ages: Array = c.get("edades", [])
		if not ages.is_empty():
			out += _dimc("Edades: " + " → ".join(ages)) + "\n"

	# Motor propio.
	var engine := _engine_lines(dd)
	if not engine.is_empty():
		out += _h("Tu motor propio")
		for l in engine:
			out += "•  %s\n" % l

	# Lo distinto.
	var own := _unique_lines(dd)
	if not own.is_empty():
		out += _h("Lo que tenés y los demás no")
		for l in own:
			out += "•  %s\n" % l

	# Fortalezas y debilidades.
	out += _h("Fuerte en")
	for l in _strengths(dd):
		out += "[color=#%s]+[/color]  %s\n" % [Palette.UI_GOOD.to_html(false), l]
	out += _h("Flojo en")
	for l in _weaknesses(dd):
		out += "[color=#%s]−[/color]  %s\n" % [Palette.UI_BAD.to_html(false), l]

	# Hitos.
	out += _h("Hitos: cómo subís de edad")
	out += _dimc("En cada edad elegís uno de dos hitos: uno de economía y uno militar. El que no elegís se pierde.") + "\n"
	for i in dd.hitos.size():
		var opts: Array = dd.hitos[i]
		var age_n: String = dd.edades[i + 1]["nombre"] if i + 1 < dd.edades.size() else ""
		out += "\n[b]Edad %s · %s[/b]\n" % [Sim._roman(i + 2), age_n]
		for key: String in opts:
			var def: Dictionary = dd.edificios.get(key, {})
			var eje := C.eje_of(def, key)
			var ef: String = hud.ctrl.effects_text(def.get("efectos", []))
			var rent: Dictionary = def.get("renta", {})
			for r in rent:
				ef += ("%s+%d de %s por minuto" % [" · " if ef != "" else "", rent[r], C.res_name(sim, pid, r).to_lower()])
			out += "   [color=#%s]%s[/color]  %s: %s %s\n" % [C.eje_color(eje).to_html(false), C.EJE_NAMES.get(eje, eje).to_upper(), def.get("nombre", key), def.get("desc", ""), _dimc(ef)]

	# Consejos.
	out += _h("Consejos")
	for l in _tips(dd):
		out += "•  %s\n" % l

	out += _h("Controles")
	out += "Clic izquierdo: seleccionar (arrastrar para un grupo; doble clic: todos los del tipo)\nClic derecho: mover, atacar, recolectar, construir, reparar o alojar\nGrilla Q W E R / A S D F / Z X C V: construir, entrenar, investigar\nA y clic: atacar en movimiento · S: detener · Supr: eliminar\nCtrl + 1…9: grupos · H: centro · . : aldeano inactivo · Z en el centro: campana\nFlechas, bordes o botón del medio: cámara · F3: velocidad · Esc: pausa\n"
	out += "F1: tu pueblo · F2: economía · F4: avance de edad · F5: registro de sucesos · F6: puntaje\n"
	return out


## Cómo funciona el motor de la civilización, con los números de los datos.
func _engine_lines(dd: SimData) -> Array[String]:
	var out: Array[String] = []
	var m: Dictionary = dd.modulos
	var capital := String(dd.edificios.get("centro", {}).get("nombre", "centro"))
	if m.has("recurso_propio"):
		var rp: Dictionary = m["recurso_propio"]
		var src: Array[String] = []
		if int(rp.get("por_aldeano", 0)) > 0 or not (rp.get("por_aldeano_por_edad", []) as Array).is_empty():
			src.append("tus aldeanos lo generan solos")
		for t in rp.get("por_edificio", {}):
			src.append("cada %s da %d por minuto" % [dd.def_of(t).get("nombre", t).to_lower(), rp["por_edificio"][t]])
		out.append("[b]%s[/b] es tu recurso propio: %s. Tiene tope (%d al empezar) y lo que pasa del tope se pierde." % [rp["nombre"], ", ".join(src) if not src.is_empty() else "llega por tus edificios", int(rp.get("tope", 0))])
	if m.has("acogida"):
		var ac: Dictionary = m["acogida"]
		out.append("No entrenás aldeanos: cada %d de %s llega una persona sola, si tenés lugar de población." % [ac["costo"], C.res_name(hud.sim, hud.local, ac["recurso"]).to_lower()])
	if m.has("caminos"):
		var cm: Dictionary = m["caminos"]
		out.append("Caminos: quien los recorre va %d %% más rápido, y los edificios unidos a la %s por caminos producen %d %% más rápido." % [cm["velocidad_pct"], capital.to_lower(), cm["bono_conectado_pct"]])
	if m.has("obra_colectiva"):
		out.append("Trabajo colectivo: cada aldeano de más en una obra suma %d %% (en los demás pueblos, cada uno suma menos)." % m["obra_colectiva"]["pct_por_constructor"])
	if m.has("saqueo"):
		var sq: Dictionary = m["saqueo"]
		var txt := "Saqueo: pegarle a edificios enemigos te da %s" % C.res_name(hud.sim, hud.local, sq["recurso"]).to_lower()
		if int(sq.get("por_aldeano", 0)) > 0:
			txt += ", y %d por cada aldeano enemigo caído" % sq["por_aldeano"]
		out.append(txt + ".")
	if m.has("liberacion"):
		out.append("Liberación: al destruir edificios enemigos se suman %d personas a tu pueblo." % int(m["liberacion"].get("aldeanos", 1)))
	for t in dd.edificios:
		var d: Dictionary = dd.edificios[t]
		if d.has("conversion"):
			var cv: Dictionary = d["conversion"]
			var gives: Array[String] = []
			for g in cv["da"]:
				gives.append("%d de %s" % [cv["da"][g], C.res_name(hud.sim, hud.local, g).to_lower()])
			out.append("%s: convierte %d de %s por minuto en %s. Si falta, rinde el %d %%." % [d["nombre"], cv["consume_min"], C.res_name(hud.sim, hud.local, cv["de"]).to_lower(), ", ".join(gives), int(cv.get("piso_pct", 0))])
		elif d.has("renta") and not d.get("avanza_edad", false):
			var gives2: Array[String] = []
			for g in d["renta"]:
				gives2.append("%d de %s" % [d["renta"][g], C.res_name(hud.sim, hud.local, g).to_lower()])
			out.append("%s: rinde %s por minuto, sin aldeanos." % [d["nombre"], ", ".join(gives2)])
	return out


func _unique_lines(dd: SimData) -> Array[String]:
	var out: Array[String] = []
	var c: Dictionary = dd.civ
	for t in c.get("edificios_nuevos", {}):
		var d: Dictionary = dd.edificios.get(t, {})
		if d.get("avanza_edad", false):
			continue
		out.append("[b]%s[/b] (edificio): %s" % [d.get("nombre", t), d.get("desc", "")])
	for t in c.get("unidades_nuevas", {}):
		var u: Dictionary = dd.unidades.get(t, {})
		out.append("[b]%s[/b] (unidad de %s, desde la edad %s)" % [u.get("nombre", t), C.FN_NAMES.get(u.get("funcion", ""), u.get("funcion", "")), Sim._roman(int(u.get("edad_min", 1)))])
	return out


func _strengths(dd: SimData) -> Array[String]:
	var out: Array[String] = []
	var m: Dictionary = dd.modulos
	if m.has("sigilo"):
		out.append("Emboscadas: tus unidades junto a los árboles no se ven de lejos (a menos de %d casillas sí) y su primer golpe pega %d %% más." % [int(m["sigilo"].get("radio_deteccion", 3000)) / 1000, int(m["sigilo"].get("emboscada_pct", 0))])
	if m.has("relevo"):
		out.append("Relevo: las unidades que salen del combate se curan solas (%d %% por segundo tras %d s)." % [m["relevo"]["pct_por_seg"], int(m["relevo"]["espera_ms"]) / 1000])
	if m.has("defensa_altura"):
		out.append("La altura: tus unidades reciben %d %% menos de daño de quien les pega desde abajo." % m["defensa_altura"]["pct"])
	if m.has("obra_colectiva"):
		out.append("Construir rápido con muchos aldeanos a la vez.")
	if m.has("caminos"):
		out.append("Moverse y producir rápido dentro de la red de caminos.")
	for t in dd.civ.get("unidades_nuevas", {}):
		var u: Dictionary = dd.unidades.get(t, {})
		out.append("%s: unidad propia de %s." % [u.get("nombre", t), C.FN_NAMES.get(u.get("funcion", ""), "")])
	for t in dd.edificios:
		if dd.edificios[t].get("oculto", false):
			out.append("%s: invisible para el rival hasta que se acerca." % dd.edificios[t]["nombre"])
		if int(dd.edificios[t].get("espinas", 0)) > 0:
			out.append("%s: hiere a quien la ataca." % dd.edificios[t]["nombre"])
	if out.is_empty():
		out.append(String(dd.civ.get("descripcion", "Equilibrado.")))
	return out


func _weaknesses(dd: SimData) -> Array[String]:
	var out: Array[String] = []
	if dd.civ.get("debilidad", "") != "":
		out.append(dd.civ["debilidad"])
	var missing: Array[String] = []
	for t in dd.civ.get("sin_edificios", []):
		if t in ["hito_economia", "hito_guerra"]:
			continue
		missing.append(String(hud.sim.data.edificios.get(t, {}).get("nombre", t)).to_lower())
	if not missing.is_empty():
		out.append("No tenés: %s." % ", ".join(missing))
	if dd.has_mod("acogida"):
		out.append("Sin lugar de población no llega nadie: las casas son tu crecimiento.")
	if dd.has_mod("recurso_propio"):
		out.append("Si %s queda al tope, lo que se genera se pierde." % String(dd.mod("recurso_propio")["nombre"]).to_lower())
	return out


func _tips(dd: SimData) -> Array[String]:
	var out: Array[String] = []
	var m: Dictionary = dd.modulos
	if m.has("recurso_propio"):
		var rp: Dictionary = m["recurso_propio"]
		var tops: Array[String] = []
		for t in rp.get("tope_por_edificio", {}):
			tops.append("%s (+%d)" % [dd.def_of(t).get("nombre", t), rp["tope_por_edificio"][t]])
		var t2 := "Gastá %s antes de que llegue al tope" % rp["nombre"]
		if not tops.is_empty():
			t2 += ", o subí el tope con " + ", ".join(tops)
		out.append(t2 + ". El panel de economía (F2) muestra en qué se gasta.")
	if m.has("caminos"):
		out.append("Trazá caminos desde la capital hasta tus talleres y cuarteles: los desconectados no reciben el bono.")
	if m.has("acogida"):
		out.append("Construí casas antes de llenarte: con la población llena la fama se acumula y no llega nadie.")
	if m.has("sigilo"):
		out.append("Esperá al rival en el monte: un ataque desde los árboles empieza ganando.")
	if m.has("saqueo"):
		out.append("Las incursiones a edificios y aldeanos enemigos pagan: no hace falta destruirlos para ganar algo.")
	if m.has("relevo"):
		out.append("Rotá las tropas: sacá a las heridas unos segundos y vuelven enteras.")
	if m.has("obra_colectiva"):
		out.append("Para un hito o una defensa urgente, mandá a todos los aldeanos juntos a la misma obra.")
	if m.has("defensa_altura"):
		out.append("Elegí dónde pelear: defendé desde las lomas y evitá el llano.")
	out.append("Lo disputado (riqueza del centro, sitios y botín) tiene tope por edad: mirá la barra en el panel de economía (F2).")
	out.append("Ningún hito es mejor siempre: el de economía rinde a la larga, el militar te deja pelear antes (F4).")
	return out
