extends SceneTree
## Arte de la guerra (C-38, proceso/52): cada misión se arma y se juega con un jugador simple
## que hace lo que dice la Guía. Sale con código 1 si alguna no se gana o si la medalla de oro
## no es más rápida que la plata y la plata que el bronce.
##
##   godot --headless --path . -s tests/arte_guerra.gd [-- --mision=arte-3]
##
## Imprime el tiempo de cada victoria y la medalla que daría (sirve para calibrar los
## umbrales de data/campanas/arte_guerra.json → medallas).

const Medallas := preload("res://src/game/ui/arte_guerra.gd")

var s: Sim
var cap: SimEntity


func t() -> String:
	return "%d:%02d" % [s.tick / 600, (s.tick / 10) % 60]


func mine(types: Array) -> Array:
	var out := []
	for e in s.actives:
		if e.alive and e.owner == 0 and e.is_unit() and e.inside < 0 and (types.is_empty() or e.type in types):
			out.append(e)
	return out


func military() -> Array:
	return mine([]).filter(func(e: SimEntity) -> bool: return e.type != "aldeano" and e.type != "explorador" and e.type != "rebano")


func ids(arr: Array) -> Array:
	return arr.map(func(e: SimEntity) -> int: return e.id)


func nearest(kind: String, x: int, y: int, maxd: int = 1 << 60) -> SimEntity:
	var best: SimEntity = null
	var bd := maxd
	for e in s.entities:
		if e.alive and e.is_resource() and e.type == kind and e.amount > 0:
			var d := Sim.dist(e.x, e.y, x, y)
			if d < bd:
				bd = d
				best = e
	return best


func place(type: String, c: Vector2i, rmin: int) -> Vector2i:
	for r in range(rmin, 24):
		for dy in range(-r, r + 1):
			for dx in range(-r, r + 1):
				if (abs(dx) == r or abs(dy) == r) and s.can_place(type, c.x + dx, c.y + dy, 0):
					return Vector2i(c.x + dx, c.y + dy)
	return Vector2i(-1, -1)


func enemies_near(radio: int) -> Array:
	var out := []
	for e in s.actives:
		if e.alive and e.owner == 1 and e.is_unit() and Sim.dist(e.x, e.y, cap.x, cap.y) < radio:
			out.append(e)
	return out


func closest(arr: Array, x: int, y: int) -> SimEntity:
	var best: SimEntity = null
	var bd := 1 << 60
	for e: SimEntity in arr:
		var d := Sim.dist(e.x, e.y, x, y)
		if d < bd:
			bd = d
			best = e
	return best


func enemy_building(type: String) -> SimEntity:
	for e in s.actives:
		if e.alive and e.owner == 1 and e.is_building() and e.type == type:
			return e
	return null


func objs() -> Dictionary:
	var out := {}
	for o in s.scenario.objectives:
		out[o["id"]] = o["estado"]
	return out


## Lo económico de todas: aldeanos a trabajar, casas antes de llenarse y el centro entrenando.
func economia(train: bool, wealth: bool) -> void:
	var r: Dictionary = s.players[0]["res"]
	var v := mine(["aldeano"])
	var i := 0
	for e: SimEntity in v:
		i += 1
		if e.order != SimEntity.Order.IDLE:
			continue
		var kind: String = ["arbusto", "arbol", "arbol", "riqueza" if wealth else "arbusto"][e.id % 4]
		var src := nearest(kind, cap.x, cap.y, 22000)
		if src == null and kind == "arbusto":
			if s.can_afford(0, s.dp(0).cost_of("granja", 1)):
				var p := place("granja", Vector2i(cap.tx, cap.ty), 5)
				s.push_command({"t": "build", "player": 0, "ids": [e.id], "type": "granja", "tx": p.x, "ty": p.y})
				continue
			kind = "arbol"
		if src == null:
			src = nearest(kind, e.x, e.y)
		if src != null:
			s.push_command({"t": "target", "player": 0, "ids": [e.id], "target": src.id})
	var p0: Dictionary = s.players[0]
	var building_house := false
	for e in s.actives:
		if e.alive and e.owner == 0 and e.type == "casa" and not e.built:
			building_house = true
	if int(p0["pop"]) >= int(p0["pop_cap"]) - 3 and not building_house and int(r["madera"]) >= 50 and not v.is_empty():
		var p := place("casa", Vector2i(cap.tx, cap.ty), 4)
		s.push_command({"t": "build", "player": 0, "ids": [v[0].id], "type": "casa", "tx": p.x, "ty": p.y})
	if train and cap.queue.size() < 2:
		s.push_command({"t": "train", "player": 0, "building": cap.id, "type": "aldeano"})


func train_at(building: String, unit: String, cola: int = 2) -> void:
	for e in s.actives:
		if e.alive and e.owner == 0 and e.type == building and e.built and e.queue.size() < cola:
			s.push_command({"t": "train", "player": 0, "building": e.id, "type": unit})


## Tropa contra los enemigos que se acercan a la capital; campana si los aldeanos corren peligro.
func defender(tropa: Array, alarma: bool, state: Dictionary) -> void:
	var en := enemies_near(26000)
	if not en.is_empty() and not tropa.is_empty():
		var target := closest(en, cap.x, cap.y)
		s.push_command({"t": "target", "player": 0, "ids": ids(tropa), "target": target.id})
	if not alarma:
		return
	var cerca := enemies_near(14000)
	var flojos := military().size() < cerca.size() + 2
	if not cerca.is_empty() and not state.get("alarm", false) and flojos:
		s.push_command({"t": "alarm", "player": 0, "on": true})
		state["alarm"] = true
	elif (cerca.is_empty() or not flojos) and state.get("alarm", false):
		s.push_command({"t": "alarm", "player": 0, "on": false})
		state["alarm"] = false


func jugar(m: Dictionary, camp: Dictionary) -> Dictionary:
	s = SimScenario.create(m, camp["civ"])
	cap = s.scenario._capital(0)
	var id: String = m["id"]
	var state := {}
	var max_ticks := int(m["medallas"]["bronce"]) * 10 * 2
	for i in max_ticks:
		s.step()
		for ev in s.events:
			if ev["t"] == "objetivo" and ev["estado"] in ["hecho", "fallado"]:
				print("  %s objetivo %s %s" % [t(), ev["estado"], ev["id"]])
			elif ev["t"] == "mision":
				print("  %s MISIÓN %s %s" % [t(), ev["resultado"], ev.get("motivo", "")])
		if s.scenario.result != "":
			break
		if s.tick % 20 != 0:
			continue
		var o := objs()
		match id:
			"arte-1":
				economia(true, true)
				if o.get("o3") == "activo" and not state.has("almacen") and s.can_afford(0, s.dp(0).cost_of("almacen_madera", 1)):
					var ar := nearest("arbol", cap.x, cap.y)
					var p := place("almacen_madera", Vector2i(ar.tx, ar.ty), 2)
					var v := mine(["aldeano"])
					s.push_command({"t": "build", "player": 0, "ids": [v[1].id], "type": "almacen_madera", "tx": p.x, "ty": p.y})
					state["almacen"] = true
			"arte-2":
				economia(false, true)
				train_at("cuartel", "guerrero" if s.tick % 120 < 80 else "lancero")
				defender(military(), true, state)
			"arte-3":
				economia(false, true)
				var pick := "guerrero"
				if o.get("o2") == "activo":
					pick = "hondero"
				elif o.get("o3") == "activo":
					pick = "lancero"
				train_at("cuartel" if pick != "hondero" else "campo_tiro", pick)
				defender(mine([pick]), true, state)
				# Los demás esperan detrás, junto al centro.
				var otros := military().filter(func(e: SimEntity) -> bool: return e.type != pick and e.order == SimEntity.Order.IDLE and Sim.dist(e.x, e.y, cap.x, cap.y) > 6000)
				if not otros.is_empty():
					s.push_command({"t": "move", "player": 0, "ids": ids(otros), "x": cap.x, "y": cap.y + 4000})
			"arte-4":
				economia(false, false)
				var sitios := []
				for e in s.actives:
					if e.alive and e.def.get("sagrado", false):
						sitios.append(e)
				if not state.has("repartidos"):
					var g := mine(["guerrero"])
					for k in sitios.size():
						var par := g.slice(k * 2, k * 2 + 2)
						if not par.is_empty():
							s.push_command({"t": "move", "player": 0, "ids": ids(par), "x": sitios[k].x + 1500, "y": sitios[k].y})
					state["repartidos"] = true
			"arte-5":
				economia(false, false)
				var torre := enemy_building("torre")
				var blanco := torre if torre != null else enemy_building("cuartel")
				if blanco != null and s.tick % 60 == 0:
					var esc := mine(["guerrero", "lancero", "hondero"])
					var sieges := mine(["ariete"])
					var en := []
					for e in s.actives:
						if e.alive and e.owner == 1 and e.is_unit() and e.type != "aldeano":
							en.append(e)
					var amenaza := closest(en, blanco.x, blanco.y)
					# La escolta va adelante: pelea con la tropa que cuida el blanco, y si no hay, al blanco.
					if not esc.is_empty():
						if amenaza != null and Sim.dist(amenaza.x, amenaza.y, blanco.x, blanco.y) < 20000:
							s.push_command({"t": "target", "player": 0, "ids": ids(esc), "target": amenaza.id})
						else:
							s.push_command({"t": "target", "player": 0, "ids": ids(esc), "target": blanco.id})
					# El asedio, atrás de la escolta, contra el blanco.
					var idle_s := sieges.filter(func(e: SimEntity) -> bool: return e.order == SimEntity.Order.IDLE or e.target != blanco.id)
					if not idle_s.is_empty():
						s.push_command({"t": "target", "player": 0, "ids": ids(idle_s), "target": blanco.id})
					if s.tick % 600 == 0:
						print("  %s escolta %d, asedio %d, rivales %d, blanco %s %d" % [t(), esc.size(), sieges.size(), en.size(), blanco.type, blanco.hp])
	var seg := s.tick * s.tick_ms / 1000
	if s.scenario.result != "victoria":
		# Para entender por qué quedó abierta: qué queda del rival, los sitios y la tropa propia.
		for e in s.actives:
			if e.alive and (e.owner == 1 and (e.is_unit() or e.type in ["torre", "cuartel"]) or e.def.get("sagrado", false)):
				print("    rival/sitio %s dueño %d a %d de la capital, vida %d, orden %d, sostiene %d" % [e.type, e.owner, Sim.dist(e.x, e.y, cap.x, cap.y), e.hp, e.order if e.is_unit() else -1, e.holder if e.def.get("sagrado", false) else -9])
		for e in military():
			print("    mío %s a %d, orden %d" % [e.type, Sim.dist(e.x, e.y, cap.x, cap.y), e.order])
		print("    objetivos ", objs(), " · bajas ", s.scenario.kills)
	return {"resultado": s.scenario.result, "segundos": seg, "motivo": s.scenario.motivo}


func _init() -> void:
	var solo := ""
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--mision="):
			solo = a.split("=")[1]
	var camp: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/campanas/arte_guerra.json"))
	var ok := true
	if (camp["misiones"] as Array).size() != 5:
		print("FALLA: tienen que ser cinco misiones")
		ok = false
	for m: Dictionary in camp["misiones"]:
		if solo != "" and m["id"] != solo:
			continue
		var md: Dictionary = m.get("medallas", {})
		if not (int(md.get("oro", 0)) < int(md.get("plata", 0)) and int(md.get("plata", 0)) < int(md.get("bronce", 0))):
			print("FALLA: %s: las medallas tienen que ir oro < plata < bronce (%s)" % [m["id"], md])
			ok = false
		print("%s · %s" % [m["id"], m["titulo"]])
		var r := jugar(m, camp)
		var medalla := Medallas.medalla(m, int(r["segundos"])) if r["resultado"] == "victoria" else ""
		print("%s: %s a los %d:%02d · medalla: %s %s" % [m["id"], r["resultado"] if r["resultado"] != "" else "(abierta)", int(r["segundos"]) / 60, int(r["segundos"]) % 60, medalla if medalla != "" else "ninguna", r["motivo"]])
		if r["resultado"] != "victoria":
			print("FALLA: %s no se ganó siguiendo a la Guía" % m["id"])
			ok = false
		Sim.soltar_todas()
	print("OK" if ok else "FALLA")
	quit(0 if ok else 1)


func _finalize() -> void:
	Sim.soltar_todas()
