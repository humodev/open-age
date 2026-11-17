extends RefCounted
## Autotest de los íconos y los estados de la grilla (proceso/28-iconos-y-estados), con la grilla
## real del centro: un estado por casilla (disponible, falta, bloqueado por edad, en curso, aviso
## de población llena), la primera línea de la ayuda en su color (rojo solo si bloquea) y que la
## ficha relea el comando en vez de quedarse con el del momento en que entró el mouse. Deja
## capturas en screenshots/iconos_*.png. Lo llama main.gd → _autotest.


static func correr(m: Node, check: Callable) -> void:
	var sim: Sim = m.sim
	var ctrl: Controller = m.ctrl
	var hud: Hud = m.hud
	var local: int = m.local
	var p: Dictionary = sim.players[local]
	var saved_res: Dictionary = (p["res"] as Dictionary).duplicate()
	var saved_age: int = p["age"]
	var saved_cap: int = p["pop_cap"]
	var rojo := Iconos.color_estado("bloquea", Palette.UI_BAD)
	var capital: SimEntity = null
	for e in sim.actives:
		if e.alive and e.owner == local and e.is_building() and e.built and (e.capital or e.type == "centro"):
			capital = e
			break
	if capital == null:
		check.call("hay un centro para probar la grilla", false)
		return
	ctrl.open_submenu(Grilla.RAIZ)
	ctrl.select_ids([capital.id] as Array[int])
	var b := sim.bases[local]
	m.cam.look_at_point(Vector3(b.x + 2, 0, b.y + 2))
	m.paused = true
	await m._frames(3)
	# 1. Sin recursos y en la edad I: falta (aldeano) y bloqueado por edad (una investigación de la II).
	for k in p["res"]:
		p["res"][k] = 0
	p["age"] = 1
	var cmds := ctrl.commands()
	var ald := _de(cmds, "aldeano")
	check.call("sin recursos, el aldeano está en «falta» (%s)" % EstadoCasilla.estado(ald, p["res"]), EstadoCasilla.estado(ald, p["res"]) == "falta")
	var l_falta := EstadoCasilla.lineas_ayuda(ald, p["res"], ctrl.missing_text(ald.get("cost", {})))
	check.call("la ayuda empieza con «Falta: …» en ámbar, no en rojo (%s)" % _txt(l_falta), _txt(l_falta).begins_with("Falta: ") and not _usa(l_falta, rojo))
	var bloq := {}
	for c in cmds:
		if c["kind"] == "research" and int(c.get("edad", 0)) >= 2 and EstadoCasilla.estado(c, p["res"]) == "bloqueado":
			bloq = c
			break
	check.call("una investigación de la edad %d queda «bloqueado» (%s)" % [int(bloq.get("edad", 0)), bloq.get("id", "?")], not bloq.is_empty())
	if not bloq.is_empty():
		var l_bloq := EstadoCasilla.lineas_ayuda(bloq, p["res"], "")
		var edad_col := Iconos.texto_edad(int(bloq["edad"]))
		check.call("su ayuda dice «Necesita la edad %s» en rojo y la edad en su color (%s)" % [Sim._roman(int(bloq["edad"])), _txt(l_bloq)], _txt(l_bloq).begins_with("Necesita la edad") and _usa(l_bloq, rojo) and _usa(l_bloq, edad_col))
		_ayuda(m, bloq)
		await m._frames(20)
		m.get_viewport().get_texture().get_image().save_png("screenshots/iconos_bloqueado.png")
	await m._frames(2)
	check.call("la grilla dibuja lo mismo que resuelve (aldeano en Q)", (hud._card.dibujadas.get(0, {}) as Dictionary).get("id", "") == "aldeano")
	_ayuda(m, ald)
	await m._frames(20)
	m.get_viewport().get_texture().get_image().save_png("screenshots/iconos_falta.png")
	# 2. La ficha relee el comando: se le pasa el de antes (sin recursos) y ya alcanza.
	for k in p["res"]:
		p["res"][k] = 5000
	var viejo := ald.duplicate()
	var fc: Dictionary = hud.ficha._cmd_content(viejo)
	var st: Array = fc.get("status", [])
	check.call("con recursos, la ficha del aldeano dice «Podés entrenarlo» aunque el mouse entró sin recursos (%s)" % _txt(st), _txt(st).begins_with("Podés") and not _usa(st, rojo))
	# 3. Edad II con recursos: la investigación ya está disponible y su línea es verde.
	p["age"] = 2
	cmds = ctrl.commands()
	var disp := _de(cmds, str(bloq.get("id", "")))
	if not disp.is_empty():
		var l_ok := EstadoCasilla.lineas_ayuda(disp, p["res"], "")
		check.call("en la edad II la misma investigación se puede: «%s», sin rojo" % _txt(l_ok), EstadoCasilla.estado(disp, p["res"]) == "disponible" and _txt(l_ok).begins_with("Podés") and not _usa(l_ok, rojo))
		fc = hud.ficha._cmd_content(bloq)
		check.call("la ficha que se abrió en la edad I ya no dice «Necesita…» (%s)" % _txt(fc.get("status", [])), not _txt(fc.get("status", [])).contains("Necesita"))
		_ayuda(m, disp)
		await m._frames(20)
		m.get_viewport().get_texture().get_image().save_png("screenshots/iconos_disponible.png")
		# 4. Pedida: queda «en curso» con su tilde.
		sim.push_command({"t": "research", "player": local, "building": capital.id, "tech": disp["id"]})
		sim.step()
		cmds = ctrl.commands()
		var curso := _de(cmds, str(disp["id"]))
		check.call("pedida, la investigación queda «en curso» (%s)" % EstadoCasilla.estado(curso, p["res"]), EstadoCasilla.estado(curso, p["res"]) == "en_curso")
		var l_cur := EstadoCasilla.lineas_ayuda(curso, p["res"], "")
		check.call("…y la ayuda no lo pinta de rojo (%s)" % _txt(l_cur), not _usa(l_cur, rojo))
		_ayuda(m, curso)
		await m._frames(20)
		m.get_viewport().get_texture().get_image().save_png("screenshots/iconos_en_curso.png")
	# 5. Población llena: el aldeano sigue disponible, con aviso propio y sin rojo.
	p["pop_cap"] = int(p["pop"])
	cmds = ctrl.commands()
	ald = _de(cmds, "aldeano")
	var l_pob := EstadoCasilla.lineas_ayuda(ald, p["res"], "")
	check.call("con la población llena, el aldeano está en «aviso» (%s)" % EstadoCasilla.estado(ald, p["res"]), EstadoCasilla.estado(ald, p["res"]) == "aviso")
	check.call("…la ayuda dice «Podés entrenarlo» y avisa en ámbar, sin rojo (%s)" % _txt(l_pob), _txt(l_pob).begins_with("Podés") and _txt(l_pob).contains("Población llena") and not _usa(l_pob, rojo))
	_ayuda(m, ald)
	await m._frames(20)
	m.get_viewport().get_texture().get_image().save_png("screenshots/iconos_aviso_pob.png")
	# 6. Cada casilla de investigación dice su edad (franja) y ningún ícono se repite.
	var vistos := {}
	var repetidos := []
	var sin_edad := []
	for c in cmds:
		if c["kind"] in ["build", "train", "research"]:
			if vistos.has(c["icon"]):
				repetidos.append(c["id"])
			vistos[c["icon"]] = true
			if int(c.get("edad", 0)) <= 0:
				sin_edad.append(c["id"])
	check.call("en la grilla del centro ningún ícono se repite (%s)" % str(repetidos), repetidos.is_empty())
	check.call("cada casilla dice a qué edad pertenece (%s)" % str(sin_edad), sin_edad.is_empty())
	hud.hide_tip()
	for k in saved_res:
		p["res"][k] = saved_res[k]
	p["age"] = saved_age
	p["pop_cap"] = saved_cap
	m.paused = false
	await m._frames(2)


static func _de(cmds: Array, id: String) -> Dictionary:
	for c: Dictionary in cmds:
		if c.get("id", "") == id:
			return c
	return {}


static func _txt(lineas: Array) -> String:
	var parts: Array[String] = []
	for ln: Array in lineas:
		var s := ""
		for seg: Array in ln:
			s += String(seg[0])
		parts.append(s)
	return " / ".join(parts)


static func _usa(lineas: Array, col: Color) -> bool:
	for ln: Array in lineas:
		for seg: Array in ln:
			if (seg[1] as Color).is_equal_approx(col):
				return true
	return false


static func _ayuda(m: Node, c: Dictionary) -> void:
	var card: Control = m.hud._card
	m.hud.show_tip(c, card.get_global_rect())
