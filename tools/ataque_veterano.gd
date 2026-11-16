extends SceneTree
## El boom del veterano de AoE4 con su ataque (proceso/24, paso 6b; ronda 6, informe 01): el
## script con el que el veterano jugó contra la experta (`apertura3.gd`), traído a tools/. Juega
## por script una apertura limpia (aldeanos sin parar, hito apenas alcanza, dos edificios
## militares en la edad II) y ataca en movimiento a la capital rival desde el minuto `--ataque`.
## Imprime, minuto a minuto, aldeanos, ejército y banco de los dos.
## Diferencia con el del veterano: la IA piensa solo dentro de Sim.step (el suyo además la hacía
## pensar a mano antes de cada paso, dos veces por pensada).
## Uso: godot --headless --path . -s tools/ataque_veterano.gd -- --civ=tawantinsuyu --rival=etiopia
##        --min=20 --plan=boom --ataque=12 --const=4 --dif=experta [--seed=7] [--nivel=clave=valor]

const O := SimEntity.Order
var s: Sim
var me := 0
var civ := "guaranies"
var rival := "mapuches"
var seed_v := 7
var minutes := 20
var attack_min := 11
var ratio_I := {"alimento": 50, "madera": 25, "riqueza": 25}
var plan := "boom"
var farms_this_tick := 0
var ratio_II := {"alimento": 40, "madera": 25, "riqueza": 22, "piedra": 13}
var first_farm := -1
var claimed := 0
var log_age := {}
var hito_placed := {}
var idle_vs := [0, 0] # aldeano-segundos ociosos, mío y de la IA
var tc_idle := [0, 0] # segundos con el centro sin producir aldeanos
var built_log: Array = []
var rejects := {}
var first_mil := -1
var attack_sent := -1
var army_peak := [0, 0]
var supply_blocked := 0
var defenses := 0
var diff := "normal"
var recursos := "normal"
var tlim := 0
var sitios_no := false
var hitos_no := false
var builders := 3
var hito_threat := {}
var hito_hpmin := {}
var bld_tick := {}
var tweaks := []


func _init() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--civ="): civ = a.substr(6)
		if a.begins_with("--rival="): rival = a.substr(8)
		if a.begins_with("--seed="): seed_v = int(a.substr(7))
		if a.begins_with("--min="): minutes = int(a.substr(6))
		if a.begins_with("--ataque="): attack_min = int(a.substr(9))
		if a.begins_with("--plan="): plan = a.substr(7)
		if a.begins_with("--dif="): diff = a.substr(6)
		if a.begins_with("--recursos="): recursos = a.substr(11)
		if a.begins_with("--tiempo="): tlim = int(a.substr(9))
		if a == "--sitios=no": sitios_no = true
		if a == "--hitos=no": hitos_no = true
		if a.begins_with("--const="): builders = int(a.substr(8))
		if a.begins_with("--nivel="):
			var kv := a.substr(8)
			var eq := kv.find("=")
			tweaks.append([kv.substr(0, eq), JSON.parse_string(kv.substr(eq + 1))])
	var data := SimData.load_default()
	for tw in tweaks:
		var node: Dictionary = data.reglas["dificultades"][diff]
		var keys: PackedStringArray = (tw[0] as String).split(".")
		for i in keys.size() - 1:
			node = node[keys[i]]
		node[keys[keys.size() - 1]] = _ints(tw[1])
	s = Sim.new(seed_v, 2, data, {"civs": [civ, rival], "terreno": "llano", "recursos": recursos, "tiempo_limite_min": tlim, "sitios_sin_victoria": sitios_no, "hitos_sin_victoria": hitos_no})
	s.ais = [SimAI.new(s, 1, diff)]
	var ticks_per_s := 1000 / int(s.tick_ms)
	var total := minutes * 60 * ticks_per_s
	print("== %s (yo, script, plan %s, %d constructores, recursos %s, tiempo %d) contra %s (IA %s), semilla %d" % [civ, plan, builders, recursos, tlim, rival, diff, seed_v])
	for t in total:
		if t % ticks_per_s == 0:
			_think(t / ticks_per_s)
		s.step()
		for ev in s.events:
			if ev.get("t") == "notice" and int(ev.get("player", -1)) == me:
				rejects[ev["text"]] = int(rejects.get(ev["text"], 0)) + 1
		if s.game_over:
			print("FIN en %s, gana %d, motivo %s" % [_mmss(t / ticks_per_s), s.winner, s.end_reason])
			var hs := []
			var cores := 0
			for e in s.entities:
				if e.type == "sitio_sagrado":
					hs.append(e.holder)
				if e.alive and e.owner == me and e.is_building() and (e.capital or e.def.get("hito", false)):
					cores += 1
			print("   puntaje: %d contra %d" % [s.score(0), s.score(1)])
			print("   sitios en manos de: %s · capital e hitos propios en pie: %d" % [hs, cores])
			break
	_report()
	quit()


func _mmss(sec: int) -> String:
	return "%d:%02d" % [sec / 60, sec % 60]


func _mine(pid: int, pred: Callable) -> Array[SimEntity]:
	var out: Array[SimEntity] = []
	for e in s.actives:
		if e.alive and e.owner == pid and pred.call(e):
			out.append(e)
	return out


func _villagers(pid: int) -> Array[SimEntity]:
	return _mine(pid, func(e): return e.is_unit() and e.fn == "civil" and e.inside < 0)


func _army(pid: int) -> Array[SimEntity]:
	return _mine(pid, func(e): return e.is_military())


func _capital(pid: int) -> SimEntity:
	for e in s.actives:
		if e.alive and e.owner == pid and e.is_building() and e.capital:
			return e
	return null


func _villager_maker(pid: int) -> SimEntity:
	for e in s.actives:
		if e.alive and e.owner == pid and e.is_building() and e.built and (e.def.get("produce", []) as Array).has("aldeano"):
			return e
	return null


func _spot(type: String, c: Vector2i, rmin: int, rmax: int) -> Vector2i:
	for r in range(rmin, rmax):
		for dy in range(-r, r + 1):
			for dx in range(-r, r + 1):
				if absi(dx) != r and absi(dy) != r:
					continue
				if s.can_place(type, c.x + dx, c.y + dy, me):
					return Vector2i(c.x + dx, c.y + dy)
	return Vector2i(-1, -1)


func _counts_by_kind(vill: Array[SimEntity]) -> Dictionary:
	var c := {"alimento": 0, "madera": 0, "piedra": 0, "riqueza": 0, "obra": 0, "ocioso": 0}
	for v in vill:
		if v.order == O.BUILD:
			c["obra"] += 1
		elif v.order in [O.GATHER, O.RETURN] and c.has(v.gather_kind):
			c[v.gather_kind] += 1
		elif v.order == O.IDLE:
			c["ocioso"] += 1
		elif v.order == O.MOVE and v.gather_kind != "" and c.has(v.gather_kind):
			c[v.gather_kind] += 1
	return c


func _has_type(pid: int, type: String, include_unbuilt := true) -> int:
	var n := 0
	for e in s.actives:
		if e.alive and e.owner == pid and e.type == type and (include_unbuilt or e.built):
			n += 1
	return n


func _unbuilt(pid: int, type: String) -> bool:
	for e in s.actives:
		if e.alive and e.owner == pid and e.type == type and not e.built:
			return true
	return false


func _build(type: String, near: Vector2i, rmin: int, rmax: int, workers: Array) -> bool:
	var cost := s.dp(me).cost_of(type, s.players[me]["age"])
	if not s.can_afford(me, cost):
		return false
	var sp := _spot(type, near, rmin, rmax)
	if sp.x < 0:
		rejects["sin lugar para " + type] = int(rejects.get("sin lugar para " + type, 0)) + 1
		return false
	var ids := []
	for w in workers:
		ids.append(w.id)
	s.push_command({"t": "build", "player": me, "ids": ids, "type": type, "tx": sp.x, "ty": sp.y})
	built_log.append("%s %s" % [_mmss(s.tick / 10), type])
	return true


func _nearest(list: Array[SimEntity], p: Vector2i, n: int) -> Array:
	var arr := list.duplicate()
	arr.sort_custom(func(a, b): return (Vector2i(a.x / 1000, a.y / 1000) - p).length_squared() < (Vector2i(b.x / 1000, b.y / 1000) - p).length_squared())
	return arr.slice(0, n)


func _think(sec: int) -> void:
	var p: Dictionary = s.players[me]
	var cap := _capital(me)
	if cap == null:
		return
	var base := Vector2i(cap.tx, cap.ty)
	var vill := _villagers(me)
	var dd := s.dp(me)
	# --- registro de los dos jugadores
	for pid in 2:
		var pa: int = s.players[pid]["age"]
		if not log_age.has("%d-%d" % [pid, pa]):
			log_age["%d-%d" % [pid, pa]] = sec
		if not hito_placed.has("%d-%d" % [pid, pa]) and s.hito_in_progress(pid):
			hito_placed["%d-%d" % [pid, pa]] = sec
		for v in _villagers(pid):
			if v.order == O.IDLE:
				idle_vs[pid] += 1
		var vm := _villager_maker(pid)
		if vm != null and vm.queue.is_empty():
			tc_idle[pid] += 1
		army_peak[pid] = maxi(army_peak[pid], _army(pid).size())
		for hb in s.actives:
			if hb.alive and hb.owner == pid and hb.def.get("avanza_edad", false) and not hb.built:
				var k := "%d-%d" % [pid, s.players[pid]["age"]]
				hito_hpmin[k] = mini(int(hito_hpmin.get(k, 1 << 30)), hb.hp * 100 / maxi(1, hb.hp_max))
				for en in s.actives:
					if en.alive and en.is_military() and en.owner == 1 - pid and absi(en.x - hb.x) < 12000 and absi(en.y - hb.y) < 12000:
						hito_threat[k] = int(hito_threat.get(k, 0)) + 1
						break
	if sec % 60 == 0:
		_snapshot(sec)
	if sec % 60 == 0 and attack_sent >= 0:
		var ec := _capital(1)
		var ar := _army(me)
		if ec != null and not ar.is_empty():
			var mx := 0
			var my := 0
			var ords := {}
			for u in ar:
				mx += u.x
				my += u.y
				ords[u.order] = int(ords.get(u.order, 0)) + 1
				var tg: SimEntity = s.by_id.get(u.target)
				if tg != null and tg.alive and u.order == O.ATTACK:
					var kk := "%s/%d" % [tg.type, tg.owner]
					ords[kk] = int(ords.get(kk, 0)) + 1
			mx /= ar.size()
			my /= ar.size()
			print("     ejército: centro (%d,%d), capital rival %s en (%d,%d) vida %d/%d, a %d casillas · órdenes %s" % [mx / 1000, my / 1000, ec.type, ec.tx, ec.ty, ec.hp, ec.hp_max, int(sqrt(float((mx - ec.x) * (mx - ec.x) + (my - ec.y) * (my - ec.y)))) / 1000, ords])
	# --- explorador: sale a reclamar animales sueltos; el rebaño lejos se arrea a casa
	for ex in _mine(me, func(e): return e.type == "explorador"):
		if ex.order == O.IDLE:
			var w: SimEntity = null
			for e in s.entities:
				if e.alive and e.type == "rebano_salvaje" and (w == null or s.dist_to(ex, e) < s.dist_to(ex, w)):
					w = e
			if w != null and s.dist_to(ex, w) < 60000:
				s.push_command({"t": "move", "player": me, "ids": [ex.id], "x": w.x, "y": w.y})
	if sec % 10 == 0:
		var far_ids := []
		for a in _mine(me, func(e): return e.type == "rebano"):
			if absi(a.x - cap.x) > 7000 or absi(a.y - cap.y) > 7000:
				far_ids.append(a.id)
		if not far_ids.is_empty():
			s.push_command({"t": "move", "player": me, "ids": far_ids, "x": cap.x + 3000, "y": cap.y + 3000, "suelto": true})
	# --- aldeanos sin parar (hasta 60)
	var vm := _villager_maker(me)
	if vm != null and vill.size() < 60 and vm.queue.size() < 2:
		if p["pop"] < p["pop_cap"]:
			s.push_command({"t": "train", "player": me, "building": vm.id, "type": "aldeano"})
		elif vm.queue.is_empty():
			supply_blocked += 1
	var c := _counts_by_kind(vill)
	# --- hito: apenas alcanza, con 3 constructores
	if p["age"] < dd.edades.size() and not s.hito_in_progress(me):
		var htype: String = dd.hitos[p["age"] - 1][0]
		if s.can_afford(me, dd.cost_of(htype, p["age"])):
			_build(htype, base, 5, 16, _nearest(vill, base, builders))
			return
	var saving_hito := false
	if p["age"] >= 3 and p["age"] < dd.edades.size() and not s.hito_in_progress(me) and sec < 13 * 60:
		saving_hito = true
	farms_this_tick = 0
	# --- casas: antes de trabarse
	var house := "casa" if dd.edificios.has("casa") else ""
	if house != "" and p["pop_cap"] - p["pop"] <= 4 and not _unbuilt(me, house) and p["pop_cap"] < 200:
		var wood := vill.filter(func(v): return v.gather_kind == "madera")
		if not wood.is_empty():
			_build(house, base, 4, 14, _nearest(wood, base, 1))
	# --- almacenes junto a la madera y la riqueza
	for k in ["madera", "riqueza", "alimento", "piedra"]:
		var ds := _dropsite_type(k)
		if ds == "" or c[k] < 3:
			continue
		var far := 0
		var near_src: SimEntity = null
		for v in vill:
			if v.gather_kind == k and v.target >= 0:
				var t: SimEntity = s.by_id.get(v.target)
				if t != null:
					var drop := s.nearest_dropoff(me, k, t.x, t.y)
					if drop == null or s.dist_to(t, drop) > 6000:
						far += 1
						near_src = t
		if far >= 3 and near_src != null and not _unbuilt(me, ds):
			var ws := _nearest(vill.filter(func(v): return v.gather_kind == k), Vector2i(near_src.tx, near_src.ty), 2)
			_build(ds, Vector2i(near_src.tx, near_src.ty), 2, 7, ws)
	# --- edad II en adelante: producción militar
	if p["age"] >= 2 or (plan == "rush" and sec >= 150):
		var prods := _military_buildings()
		var mb := 0
		for type in prods:
			mb += _has_type(me, type)
		if mb < 2 + (1 if sec > 13 * 60 else 0) and not saving_hito:
			for type in prods:
				if _has_type(me, type) < 1 + (1 if sec > 13 * 60 else 0) and dd.edificios[type].get("edad_min", 1) <= p["age"]:
					if _build(type, base, 6, 18, _nearest(vill, base, 3)):
						break
		for e in s.actives:
			if e.alive and e.owner == me and e.is_building() and e.built and prods.has(e.type) and e.queue.size() < 1:
				for u in (e.def.get("produce", []) as Array):
					if u == "aldeano" or int(dd.unidades.get(u, {}).get("edad_min", 1)) > p["age"]:
						continue
					if dd.unidades[u].get("funcion", "") in ["asedio", "explorador"]:
						continue
					if s.can_afford(me, s.train_cost(me, e, u)):
						s.push_command({"t": "train", "player": me, "building": e.id, "type": u})
						if first_mil < 0:
							first_mil = sec
						break
		# granjas cuando se acaba lo silvestre
	# --- ociosos al recurso que más falta
	var ratio: Dictionary = ratio_I if p["age"] == 1 else ratio_II
	for v in vill:
		if v.order != O.IDLE:
			continue
		var best := ""
		var best_gap := -1000000
		var tot := maxi(1, vill.size())
		for k in ratio:
			var gap: int = ratio[k] * tot / 100 - c[k]
			if gap > best_gap:
				best_gap = gap
				best = k
		var t := s.find_resource(me, best, v.x, v.y, 30000)
		if best == "alimento":
			var herd := _mine(me, func(e): return e.type == "rebano" and absi(e.x - cap.x) < 9000 and absi(e.y - cap.y) < 9000)
			var meat := s.find_resource(me, "alimento", cap.x, cap.y, 6000)
			if not herd.is_empty() and (meat == null or meat.type != "carne"):
				s.push_command({"t": "target", "player": me, "ids": [v.id], "target": herd[0].id})
				c["alimento"] += 1
				continue
			if meat != null and meat.type == "carne":
				t = meat
		if t == null and best == "alimento" and farms_this_tick == 0:
			if first_farm < 0:
				first_farm = sec
			farms_this_tick += 1
			if _build("granja", base, 3, 12, [v]):
				c["alimento"] += 1
				continue
		if t == null:
			t = s.find_resource(me, "madera", v.x, v.y, 40000)
			best = "madera"
		if t != null:
			s.push_command({"t": "target", "player": me, "ids": [v.id], "target": t.id})
			c[best] += 1
	# --- defensa: enemigos a menos de 20 casillas de la capital
	var army := _army(me)
	var threat := 0
	var tx := 0
	var ty := 0
	for e in s.actives:
		if e.alive and e.owner == 1 and e.is_unit() and e.fn != "civil" and absi(e.x - cap.x) < 20000 and absi(e.y - cap.y) < 20000:
			threat += 1
			tx = e.x
			ty = e.y
	if threat >= 3:
		if not s.players[me].get("alarm", false):
			s.push_command({"t": "alarm", "player": me, "on": true})
			defenses += 1
		if not army.is_empty() and sec % 3 == 0:
			var dids := []
			for u in army:
				dids.append(u.id)
			s.push_command({"t": "move", "player": me, "ids": dids, "x": tx, "y": ty, "amove": true})
		return
	elif s.players[me].get("alarm", false):
		s.push_command({"t": "alarm", "player": me, "on": false})
	# --- ataque en movimiento a la base rival
	if sec >= attack_min * 60 and sec % 60 == 0 and army.size() >= 8:
		var ecap := _capital(1)
		if ecap != null:
			var ids := []
			for u in army:
				ids.append(u.id)
			s.push_command({"t": "move", "player": me, "ids": ids, "x": ecap.x, "y": ecap.y, "amove": true})
			if attack_sent < 0:
				attack_sent = sec
				print("  %s ataque en movimiento con %d unidades" % [_mmss(sec), ids.size()])


func _dropsite_type(k: String) -> String:
	var best := ""
	var best_c := 1 << 30
	for type in s.dp(me).edificios:
		var d: Dictionary = s.dp(me).edificios[type]
		if (d.get("deposito", []) as Array).has(k) and not d.get("avanza_edad", false) and int(d.get("pob", 0)) == 0 and int(d.get("edad_min", 1)) <= int(s.players[me]["age"]):
			var cc := 0
			for r in d.get("costo", {}):
				cc += int(d["costo"][r])
			if cc > 0 and cc < best_c:
				best_c = cc
				best = type
	return best


func _military_buildings() -> Array:
	var out := []
	for type in s.dp(me).edificios:
		var d: Dictionary = s.dp(me).edificios[type]
		if d.get("avanza_edad", false):
			continue
		for u in (d.get("produce", []) as Array):
			var ud: Dictionary = s.dp(me).unidades.get(u, {})
			if ud.get("funcion", "civil") in ["choque", "distancia", "linea"] and not out.has(type) and int(d.get("pob", 0)) == 0:
				out.append(type)
	return out


func _snapshot(sec: int) -> void:
	var line := "  %s" % _mmss(sec)
	for pid in 2:
		var vill := _villagers(pid)
		var c := _counts_by_kind(vill)
		var p: Dictionary = s.players[pid]
		var all_v := _mine(pid, func(e): return e.is_unit() and e.fn == "civil").size()
		line += " | P%d ed%d ald %d/%d (A%d M%d P%d R%d obra%d ocio%d) ej %d pob %d/%d res A%d M%d P%d R%d" % [pid, p["age"], vill.size(), all_v, c["alimento"], c["madera"], c["piedra"], c["riqueza"], c["obra"], c["ocioso"], _army(pid).size(), p["pop"], p["pop_cap"], p["res"]["alimento"], p["res"]["madera"], p["res"]["piedra"], p["res"]["riqueza"]]
	print(line)


func _report() -> void:
	print("-- campanas tocadas: %d · primera granja %s" % [defenses, _mmss(first_farm) if first_farm >= 0 else "-"])
	print("-- edades (segundo en que se llega): ", log_age)
	print("-- hito colocado: ", hito_placed)
	print("-- segundos con enemigos a 12 casillas del hito en obra: ", hito_threat, " · vida mínima del hito en obra (%): ", hito_hpmin)
	print("-- aldeano-segundos ociosos: yo %d, IA %d" % idle_vs)
	print("-- segundos con el centro sin cola: yo %d, IA %d; trabado por población %d" % [tc_idle[0], tc_idle[1], supply_blocked])
	print("-- primer militar encolado: %s; ataque: %s; pico de ejército yo %d, IA %d" % [_mmss(first_mil) if first_mil >= 0 else "-", _mmss(attack_sent) if attack_sent >= 0 else "-", army_peak[0], army_peak[1]])
	print("-- obras: ", built_log)
	print("-- avisos y rechazos: ", rejects)
	for pid in 2:
		print("-- stats P%d: %s" % [pid, s.players[pid]["stats"]])


## JSON da números con coma: los enteros vuelven a ser enteros (como en SimData).
func _ints(v: Variant) -> Variant:
	if v is float and float(int(v)) == v:
		return int(v)
	if v is Array:
		return (v as Array).map(func(x): return _ints(x))
	if v is Dictionary:
		var out := {}
		for k in v:
			out[k] = _ints(v[k])
		return out
	return v
