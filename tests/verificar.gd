extends SceneTree
## Notas de verificación fuera de la pantalla (proceso/28, ronda 7): las «[verificar…]» siguen en
## data/ pero ninguna llega al jugador. Revisa la tabla de la partida ya limpia (todas las fichas
## salen de ahí), las ayudas de todas las grillas de los seis pueblos en las cuatro edades y las
## campañas como las carga el menú. Con `--ver`, cómo queda cada texto que tenía nota.
##   godot --headless --path . -s tests/verificar.gd [-- --ver]

const CIVS := ["tawantinsuyu", "mapuches", "guaranies", "etiopia", "palmares", "ayutthaya"]


func _init() -> void:
	var ver := OS.get_cmdline_user_args().has("--ver")
	var fallas: Array[String] = []
	var crudas := _cuenta(SimData.load_default(), [])
	var ayudas := 0
	for civ in CIVS:
		var s := Sim.new(7, 2, null, {"civs": [civ, "mapuches" if civ != "mapuches" else "guaranies"]})
		if ver and civ == CIVS[0]:
			var antes: Array = []
			_cuenta(s.data, antes)
			for t: String in antes:
				print("· ", Textos.limpiar(t).substr(maxi(0, t.findn("verificar") - 60), 140))
		Textos.limpiar_todo(s.data) # lo mismo que hace main.gd al armar la escena
		var quedan: Array = []
		_cuenta(s.data, quedan)
		for t in quedan:
			fallas.append("%s: la tabla conserva «%s»" % [civ, str(t).substr(0, 90)])
		var dd: SimData = s.dp(0)
		var ctl := Controller.new()
		ctl.sim = s
		ctl.local = 0
		for age in range(1, dd.edades.size() + 1):
			s.players[0]["age"] = age
			var ald := s.spawn_unit("aldeano", 0, 20, 20)
			var listas: Array = []
			ctl.selection = [ald.id] as Array[int]
			for m in [Grilla.RAIZ, Grilla.ECONOMIA, Grilla.MILITAR]:
				ctl.submenu = m
				listas.append_array(ctl.commands())
			ctl.submenu = ""
			for type: String in dd.edificios:
				if dd.edificios[type].get("tam", []).is_empty():
					continue
				var b := s.spawn_building(type, 0, 4, 4, true)
				ctl.selection = [b.id] as Array[int]
				var cmds := ctl.commands()
				listas.append_array(cmds)
				for c: Dictionary in cmds:
					if c.get("kind", "") == "submenu":
						ctl.submenu = c["menu"]
						listas.append_array(ctl.commands())
						ctl.submenu = ""
			for c: Dictionary in listas:
				ayudas += 1
				for k in ["name", "desc", "common", "locked"]:
					if str(c.get(k, "")).findn("verificar") >= 0:
						fallas.append("%s e%d: «%s» muestra «%s»" % [civ, age, c["id"], str(c[k]).substr(0, 90)])
		ctl.free()
	var camp := 0
	for c in CampaignUI.load_campaigns():
		var q: Array = []
		camp += _cuenta(c, q)
		for t in q:
			fallas.append("campaña %s: «%s»" % [c["_clave"], str(t).substr(0, 90)])
	var unicas := {}
	for f in fallas:
		unicas[f] = true
	for f in unicas:
		print("FALLO ", f)
	print("VERIFICAR: %d textos con nota en los datos; %d ayudas revisadas; %s" % [crudas, ayudas, "OK" if fallas.is_empty() and crudas > 0 else "FALLO (%d)" % unicas.size()])
	quit(0 if fallas.is_empty() and crudas > 0 else 1)


## Cuántos textos nombran «verificar» (y cuáles, en `out`).
func _cuenta(v: Variant, out: Array) -> int:
	var n := 0
	if v is SimData:
		var d: SimData = v
		for t in [d.reglas, d.unidades, d.edificios, d.recursos, d.edades, d.tecnologias, d.civ, d.modulos]:
			n += _cuenta(t, out)
		for k in d.civs:
			n += _cuenta(d.civs[k], out)
	elif v is Dictionary:
		for k in v:
			n += _cuenta(v[k], out)
	elif v is Array:
		for x in v:
			n += _cuenta(x, out)
	elif v is String and (v as String).findn("verificar") >= 0:
		out.append(v)
		n += 1
	return n
