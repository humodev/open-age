extends SceneTree
## El tutorial jugado al pie de la letra (proceso/23-como-aoe4/03-aprender-a-jugar.md).
##
## Un principiante hace exactamente lo que dicen los objetivos y la Guía, y nada más.
## Sale con código 1 si la misión no termina como se espera.
##
##   --modo=letra   sigue el texto: tres a la madera y tres a los frutos, aldeanos nuevos a la
##                  riqueza, explorador al sitio, guerreros y campana si no alcanzan. Debe ganar.
##                  Cuando se acaban los frutos cerca, la Guía pide una granja (o12): la levanta.
##                  Pone 2 guerreros de guardia en el sitio (o13) y compra la herrería (o14).
##   --modo=indefenso  hace todo menos defenderse: no entrena guerreros hasta que pasa el
##                  ataque y no toca la campana. No puede quedar trabada: o gana o pierde con
##                  un motivo (antes, sin aldeanos, la misión seguía abierta para siempre).

var s: Sim
var modo := "letra"


func t() -> String:
	return "%02d:%02d" % [s.tick / 600, (s.tick / 10) % 60]


func mine(type: String) -> Array:
	var out := []
	for e in s.actives:
		if e.alive and e.owner == 0 and e.type == type and e.inside < 0:
			out.append(e)
	return out


func nearest(kind: String, x: int, y: int) -> SimEntity:
	var best: SimEntity = null
	var bd := 1 << 60
	for e in s.entities:
		if e.alive and e.is_resource() and e.type == kind and e.amount > 0:
			var d := Sim.dist(e.x, e.y, x, y)
			if d < bd:
				bd = d
				best = e
	return best


func place(type: String, c: Vector2i, rmin: int) -> Vector2i:
	for r in range(rmin, 20):
		for dy in range(-r, r + 1):
			for dx in range(-r, r + 1):
				if (abs(dx) == r or abs(dy) == r) and s.can_place(type, c.x + dx, c.y + dy, 0):
					return Vector2i(c.x + dx, c.y + dy)
	return Vector2i(-1, -1)


func ids(arr: Array) -> Array:
	return arr.map(func(e: SimEntity) -> int: return e.id)


func _init() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--modo="):
			modo = a.split("=")[1]
	var camp: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/campanas/tutorial.json"))
	s = SimScenario.create(camp["misiones"][0], camp["civ"])
	var cap: SimEntity = s.scenario._capital(0)
	var ui: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/interfaz.json"))
	var frutos_radio: int = int(ui["consejos"]["frutos_radio"]) * Sim.P
	var c := Vector2i(cap.tx, cap.ty)
	var v := mine("aldeano")
	var first := {}
	for e in v:
		first[e.id] = true
	var tree := nearest("arbol", cap.x, cap.y)
	var bush := nearest("arbusto", cap.x, cap.y)
	# Una sola fuente de alimento: "los arbustos con frutos". Los demás, a la madera.
	var food_ids := {}
	s.push_command({"t": "target", "player": 0, "ids": ids(v.slice(0, 3)), "target": tree.id})
	s.push_command({"t": "target", "player": 0, "ids": ids(v.slice(3, 6)), "target": bush.id})
	for e in v.slice(3, 6):
		food_ids[e.id] = true
	var step := {}
	var att_seen := -1
	var alarm := false
	var last_dialog := ""
	var wealth_ids := {}
	var done_at := {} # objetivo -> tick en que se cumplió
	var raiders := 0 # saqueadores que hay que abatir (o9)
	for o in s.scenario.objectives:
		if o["id"] == "o9":
			raiders = int(o["params"]["n"])
	var dialogs_hito := 0 # mensajes de la Guía mientras se construye el hito
	var hito_tick := -1
	for i in 30 * 600:
		s.step()
		for ev in s.events:
			if ev["t"] == "objetivo":
				if ev["estado"] == "hecho":
					done_at[ev["id"]] = s.tick
				print(t(), " objetivo ", ev["estado"], " ", ev["id"], " ", String(ev["texto"]).substr(0, 70))
			elif ev["t"] == "dialogo":
				last_dialog = ev["texto"]
				if hito_tick >= 0:
					dialogs_hito += 1
				print(t(), " guía: ", String(ev["texto"]).substr(0, 80))
			elif ev["t"] == "mision":
				print(t(), " MISIÓN ", ev["resultado"], " · ", ev.get("motivo", ""))
		if s.scenario.result != "":
			break
		if s.tick % 30 != 0:
			continue
		var r: Dictionary = s.players[0]["res"]
		v = mine("aldeano")
		var objs := {}
		for o in s.scenario.objectives:
			objs[o["id"]] = o["estado"]
		var enemies := []
		for e in s.actives:
			if e.alive and e.owner == 1 and e.is_unit() and Sim.dist(e.x, e.y, cap.x, cap.y) < 20000:
				enemies.append(e)
		if not enemies.is_empty() and att_seen < 0:
			att_seen = s.tick
			print(t(), " llegan %d saqueadores; tengo %d guerreros y %d aldeanos" % [enemies.size(), mine("guerrero").size(), v.size()])
		# "Defendé el pueblo".
		if not enemies.is_empty() and not mine("guerrero").is_empty():
			s.push_command({"t": "target", "player": 0, "ids": ids(mine("guerrero")), "target": enemies[0].id})
		# "Faltan 30 segundos. Si no te alcanzan los guerreros, … tocá la campana".
		if modo == "letra" and not alarm and not step.has("campana") and last_dialog.begins_with("Faltan 30") and mine("guerrero").size() < 4:
			step["campana"] = true
			s.push_command({"t": "alarm", "player": 0, "on": true})
			alarm = true
			print(t(), " toco la campana con %d guerreros" % mine("guerrero").size())
		# "Cuando pase el peligro, Z otra vez los devuelve al trabajo".
		# "Pasó el peligro": cayeron los saqueadores que pide o9 (o9 ya no se cumple antes que o8).
		var raid_over: bool = s.scenario.kills >= raiders
		if alarm and raid_over:
			s.push_command({"t": "alarm", "player": 0, "on": false})
			alarm = false
			print(t(), " calma")
		if alarm:
			continue
		# Aldeanos sin trabajo: vuelven a lo suyo (madera; los de la riqueza, a la riqueza).
		var idle := v.filter(func(e: SimEntity) -> bool: return e.order == SimEntity.Order.IDLE)
		if not idle.is_empty() and s.tick % 100 == 0:
			for e: SimEntity in idle:
				var kind := "riqueza" if wealth_ids.has(e.id) else ("arbusto" if food_ids.has(e.id) else "arbol")
				var src := nearest(kind, e.x, e.y)
				# El aviso "Se acabaron los frutos cerca" (src/game/ui/consejos.gd) dice: hacé granjas.
				if kind == "arbusto" and (src == null or Sim.dist(src.x, src.y, cap.x, cap.y) > frutos_radio):
					if s.can_afford(0, s.dp(0).cost_of("granja", 1)):
						var p := place("granja", c, 5)
						s.push_command({"t": "build", "player": 0, "ids": [e.id], "type": "granja", "tx": p.x, "ty": p.y})
						if not step.has("granjas"):
							step["granjas"] = true
							print(t(), " se acabaron los frutos cerca: hago granjas (%s)" % s.dp(0).edificios["granja"]["nombre"])
					continue
				if src == null:
					src = nearest("arbol", e.x, e.y)
				s.push_command({"t": "target", "player": 0, "ids": [e.id], "target": src.id})
		# "Se acaban los frutos: construí una granja junto al centro" (o12, jugador nuevo, ronda 4):
		# la levanta uno de los que juntan frutos, que se queda a trabajarla.
		if objs.get("o12") == "activo" and not step.has("granja_obj") and s.can_afford(0, s.dp(0).cost_of("granja", s.players[0]["age"])):
			var cosecheros := v.filter(func(e: SimEntity) -> bool: return food_ids.has(e.id))
			if cosecheros.is_empty():
				cosecheros = v.slice(0, 1)
			if not cosecheros.is_empty():
				var p := place("granja", c, 5)
				s.push_command({"t": "build", "player": 0, "ids": [cosecheros[0].id], "type": "granja", "tx": p.x, "ty": p.y})
				step["granja_obj"] = true
				print(t(), " objetivo de la granja: la levanto con un aldeano de los frutos")
		if objs.get("o2") == "activo" and not step.has("casa") and int(r["madera"]) >= 50:
			var p := place("casa", c, 4)
			s.push_command({"t": "build", "player": 0, "ids": [v[0].id], "type": "casa", "tx": p.x, "ty": p.y})
			step["casa"] = true
		if objs.get("o3") == "activo" and cap.queue.size() < 1:
			s.push_command({"t": "train", "player": 0, "building": cap.id, "type": "aldeano"})
		# "Mandá a los aldeanos nuevos a la veta dorada".
		if objs.get("o4") == "activo":
			var nuevos := v.filter(func(e: SimEntity) -> bool: return not first.has(e.id) and not wealth_ids.has(e.id))
			if not nuevos.is_empty():
				for e: SimEntity in nuevos:
					wealth_ids[e.id] = true
				s.push_command({"t": "target", "player": 0, "ids": ids(nuevos), "target": nearest("riqueza", cap.x, cap.y).id})
		# "Mandalo hacia el centro del mapa" y "dejá al explorador parado al lado".
		var ex := mine("explorador")
		if objs.get("o5") == "activo" and not step.has("explorar") and not ex.is_empty():
			s.push_command({"t": "move", "player": 0, "ids": ids(ex), "x": s.map.n * 500, "y": s.map.n * 500})
			step["explorar"] = true
		if objs.get("o6") == "activo" and not step.has("sitio") and not ex.is_empty():
			for e in s.actives:
				if e.alive and e.def.get("sagrado", false):
					s.push_command({"t": "move", "player": 0, "ids": ids(ex), "x": e.x + 1500, "y": e.y})
			step["sitio"] = true
		if objs.get("o7") == "activo" and not step.has("cuartel") and int(r["madera"]) >= 150:
			var p := place("cuartel", c, 5)
			var builders := v.filter(func(e: SimEntity) -> bool: return not food_ids.has(e.id) and not wealth_ids.has(e.id)).slice(0, 2)
			s.push_command({"t": "build", "player": 0, "ids": ids(builders), "type": "cuartel", "tx": p.x, "ty": p.y})
			step["cuartel"] = true
		if objs.get("o8") == "activo" and (modo == "letra" or raid_over):
			for cu in mine("cuartel"):
				if cu.built and cu.queue.is_empty():
					s.push_command({"t": "train", "player": 0, "building": cu.id, "type": "guerrero"})
		# "Elegí: economía (Z)": el hito de economía cuando alcanza.
		# Con los que queden (en modo indefenso, con el combate de la etapa 23, sobreviven 2).
		if objs.get("o10") == "activo" and not step.has("hito") and not v.is_empty():
			var hito: String = s.dp(0).hitos[0][0]
			if s.can_afford(0, s.dp(0).cost_of(hito, 1)):
				var p := place(hito, c, 6)
				s.push_command({"t": "build", "player": 0, "ids": ids(v.slice(0, mini(4, v.size()))), "type": hito, "tx": p.x, "ty": p.y})
				step["hito"] = true
				hito_tick = s.tick
				print(t(), " construyo el hito ", hito, " con ", r)
		# "Poné guardia en el sitio sagrado: mandá 2 guerreros a pararse al lado (si no te quedan,
		# entrená más)" (o13, proceso/36).
		if objs.get("o13") == "activo" and not step.has("guardia") and mine("guerrero").size() < 2:
			for cu in mine("cuartel"):
				if cu.built and cu.queue.is_empty():
					s.push_command({"t": "train", "player": 0, "building": cu.id, "type": "guerrero"})
		if objs.get("o13") == "activo" and not step.has("guardia") and mine("guerrero").size() >= 2:
			for e in s.actives:
				if e.alive and e.def.get("sagrado", false):
					s.push_command({"t": "move", "player": 0, "ids": ids(mine("guerrero").slice(0, 2)), "x": e.x + 1500, "y": e.y})
			step["guardia"] = true
			print(t(), " mando 2 guerreros de guardia al sitio")
		# "Con el cuartel seleccionado, comprá Armas templadas (herrería)" (o14, proceso/36).
		if objs.get("o14") == "activo" and not step.has("herreria") and s.can_afford(0, s.tech_cost(0, "ataque_cc_1")):
			for cu in mine("cuartel"):
				if cu.built:
					s.push_command({"t": "research", "player": 0, "building": cu.id, "tech": "ataque_cc_1"})
					step["herreria"] = true
					print(t(), " compro Armas templadas en el cuartel")
					break
		if s.tick % 1800 == 0:
			print(t(), " recursos ", r, " · aldeanos ", v.size(), " · guerreros ", mine("guerrero").size())
	var res: String = s.scenario.result
	print("RESULTADO modo=%s %s a las %s · motivo: %s" % [modo, res if res != "" else "(abierta)", t(), s.scenario.motivo])
	var ok := res == "victoria" if modo == "letra" else (res == "victoria" or res == "derrota" and s.scenario.motivo != "")
	# Orden de los objetivos 8 y 9 (jugador nuevo, ronda 3): abatir a los saqueadores no se adelanta.
	if done_at.has("o9") and int(done_at.get("o8", 1 << 60)) > int(done_at["o9"]):
		print("FALLA: «abatí a los saqueadores» se cumplió antes que «entrená 5 guerreros»")
		ok = false
	# Granja (o12): si los frutos se acabaron, el tutorial la pidió, y en modo letra se cumple.
	var o12 := ""
	for o in s.scenario.objectives:
		if o["id"] == "o12":
			o12 = o["estado"]
	print("objetivo de la granja (o12): %s" % o12)
	if modo == "letra" and o12 == "activo":
		print("FALLA: la Guía pidió la granja y quedó sin hacer")
		ok = false
	# La espera del hito tiene mensajes de la Guía.
	if res == "victoria" and hito_tick >= 0:
		print("mensajes de la Guía mientras sube el hito: %d" % dialogs_hito)
		if dialogs_hito < 2:
			print("FALLA: la obra del hito pasa sin mensajes de la Guía")
			ok = false
	# La guardia del sitio (o13) pide tantos guerreros como la regla (reglas.sitios.guarnicion_pob).
	var pob := int(s.data.reglas["sitios"].get("guarnicion_pob", 0))
	for o in s.scenario.objectives:
		if o["id"] == "o13" and not String(o["texto"]).contains("%d guerreros" % pob):
			print("FALLA: el texto de o13 no pide %d guerreros (reglas.sitios.guarnicion_pob)" % pob)
			ok = false
		if modo == "letra" and o["id"] in ["o13", "o14"] and o["estado"] != "hecho":
			print("FALLA: %s quedó %s" % [o["id"], o["estado"]])
			ok = false
	print("OK" if ok else "FALLA")
	quit(0 if ok else 1)


## Al salir se sueltan las partidas creadas (ciclos de referencias; proceso/24, paso 6e).
func _finalize() -> void:
	Sim.soltar_todas()
