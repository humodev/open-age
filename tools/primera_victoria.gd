extends SceneTree
## La primera victoria del jugador nuevo (proceso/24, 4q). Juega el plan del principiante de la
## ronda 5 (novato5.gd: ahorra en la edad I, hito a los ~8 min, taller y 2–4 arietes en la II,
## ataca con 15 soldados o más y 2 arietes o más, «A y clic» en la base rival cada 20 s) contra
## una IA y anota qué mata a su tropa (por tipo de atacante), si los arietes llegan y pegan,
## cuánto daño le hace a los edificios y qué tiene la IA para defenderse.
## Arreglo respecto del script del jugador: el hito se pide una sola vez (el suyo lo volvía a
## pedir cada 20 s en la edad II y mandaba 4 aldeanos a una obra que no se podía pagar).
##   godot --headless --path . -s tools/primera_victoria.gd -- --seeds=7,21,3 --min=30 [--dif=facil] [--detalle=1]
## Variantes: --tropa=N y --arietes=N (con cuánto sale a atacar; 15 y 2), --tope1=N (tropa en la
## edad I; 8): con --tropa=10 --arietes=0 --tope1=15 es un apuro sin asedio en la edad I.
## --nivel=clave:valor,… cambia la dificultad sin tocar los datos.

var s: Sim
const ME := 0
var center_id := -1
var detalle := false
var data_over: SimData = null

# Medidas
var dmg_by := {}     # daño recibido por mi tropa, por atacante
var kills_by := {}   # bajas de mi tropa, por quien dio el último golpe
var last_hit := {}   # id -> atacante
var my_bdmg := {}    # daño mío a edificios rivales, por tipo de edificio
var ram_bdmg := 0
var ram_udmg := 0
var ram_dmg_by := {}  # daño recibido por los arietes, por atacante: [daño, golpes] (proceso/24, 6f)    # daño de arietes a unidades (no debería)
var ram_closest := 1 << 60
var ram_lost := 0
var bld_lost := {}
var my_kills := {}   # unidades de la IA que maté (militar, aldeano)
var my_hits := {}    # golpes de mi tropa (sin asedio) por blanco (proceso/24, 5d)
var ai_bld := {}
var first_bld_min := -1
var ram_kill_by := {}


func t() -> String:
	var sec := s.tick * s.tick_ms / 1000
	return "%02d:%02d" % [sec / 60, sec % 60]


func L(m: String) -> void:
	if detalle:
		print(t(), " ", m)


func mine(type: String) -> Array:
	var out := []
	for e in s.actives:
		if e.alive and e.owner == ME and e.type == type and e.inside < 0:
			out.append(e)
	return out


func nearest_res(kind: String, x: int, y: int) -> SimEntity:
	var best: SimEntity = null
	var bd := 1 << 60
	for e in s.entities:
		if e.alive and e.is_resource() and e.type == kind and Sim.dist(e.x, e.y, s.bases[ME].x * 1000, s.bases[ME].y * 1000) < 30000:
			var d := Sim.dist(e.x, e.y, x, y)
			if d < bd:
				bd = d
				best = e
	return best


func place(type: String, rmin: int) -> Vector2i:
	var b: Vector2i = s.bases[ME]
	for r in range(rmin, 28):
		for dy in range(-r, r + 1):
			for dx in range(-r, r + 1):
				if abs(dx) == r or abs(dy) == r:
					if s.can_place(type, b.x + dx, b.y + dy, ME):
						return Vector2i(b.x + dx, b.y + dy)
	return Vector2i(-1, -1)


func send(ids: Array, kind: String) -> void:
	if ids.is_empty():
		return
	var c: SimEntity = s.by_id.get(center_id)
	var r := nearest_res(kind, c.x if c != null else 0, c.y if c != null else 0)
	if r != null:
		s.push_command({"t": "target", "player": ME, "ids": ids, "target": r.id})


func res() -> Dictionary:
	return s.players[ME]["res"]


## Nombre del atacante: tipo, y «+guarnición» si es un edificio con gente adentro.
func who(a: SimEntity) -> String:
	if a.is_building():
		return a.type + ("+guarnición" if a.garrison.size() > 0 else "")
	return a.type


func watch_events() -> void:
	for ev in s.events:
		var k: String = ev.get("t", "")
		if k == "hit":
			var a: SimEntity = s.by_id.get(ev["a"])
			var b: SimEntity = s.by_id.get(ev["b"])
			if a == null or b == null:
				continue
			if b.owner == ME and b.is_unit() and (b.is_military() or b.type == "ariete") and a.owner == 1:
				var w := who(a)
				dmg_by[w] = int(dmg_by.get(w, 0)) + int(ev["dmg"])
				last_hit[b.id] = w
				if b.type == "ariete":
					var rd: Array = ram_dmg_by.get(w, [0, 0])
					ram_dmg_by[w] = [rd[0] + int(ev["dmg"]), rd[1] + 1]
					if OS.has_environment("DBG6F"): print("DBG %d ram %d hp %d/%d dmg %d by %s" % [s.tick, b.id, b.hp, b.hp_max, ev["dmg"], w])
			if a.owner == ME and b.owner == 1 and a.is_unit() and a.is_military() and a.fn != "asedio":
				var hk := "militar" if b.is_unit() and b.is_military() else ("aldeano" if b.is_unit() else \
					("camino" if b.def.get("camino", false) else ("transitable" if b.def.get("transitable", false) else \
					("edif. que dispara" if b.def.has("ataque") else "edificio"))))
				my_hits[hk] = int(my_hits.get(hk, 0)) + 1
			if a.owner == ME and b.owner == 1:
				if b.is_building():
					my_bdmg[b.type] = int(my_bdmg.get(b.type, 0)) + int(ev["dmg"])
					if a.type == "ariete":
						ram_bdmg += int(ev["dmg"])
				elif a.type == "ariete":
					ram_udmg += int(ev["dmg"])
		elif k == "died":
			if int(ev["owner"]) == ME and int(ev["cat"]) == 0 and ev["type"] != "aldeano":
				var w: String = last_hit.get(ev["id"], "?")
				kills_by[w] = int(kills_by.get(w, 0)) + 1
				if ev["type"] == "ariete":
					ram_lost += 1
					ram_kill_by[w] = int(ram_kill_by.get(w, 0)) + 1
			elif int(ev["owner"]) == 1 and int(ev["by"]) == ME and int(ev["cat"]) == 0:
				var kk: String = "aldeano" if ev["type"] == "aldeano" else "militar"
				my_kills[kk] = int(my_kills.get(kk, 0)) + 1
			elif int(ev["owner"]) == 1 and int(ev["by"]) == ME and int(ev["cat"]) == 1:
				bld_lost[ev["type"]] = int(bld_lost.get(ev["type"], 0)) + 1
				if first_bld_min < 0:
					first_bld_min = s.tick / 600


func _init() -> void:
	var a := {"seeds": "7,21,3", "min": "30", "dif": "facil", "civ": "guaranies", "rival": "tawantinsuyu"}
	for x in OS.get_cmdline_user_args():
		var kv := x.trim_prefix("--").split("=")
		a[kv[0]] = kv[1] if kv.size() > 1 else "1"
	detalle = a.get("detalle", "0") == "1"
	# --nivel=clave:valor,clave:valor cambia la dificultad para probar (sin tocar los datos).
	if a.has("nivel"):
		data_over = SimData.load_default()
		var lv: Dictionary = data_over.reglas["dificultades"][a["dif"]]
		for kv in String(a["nivel"]).split(","):
			var p := kv.split(":")
			lv[p[0]] = (p[1] == "true") if p[1] in ["true", "false"] else int(p[1])
		print("nivel %s: %s" % [a["dif"], a["nivel"]])
	var wins := 0
	for sd in String(a["seeds"]).split(","):
		wins += 1 if play(int(sd), a) else 0
	print("RESUMEN dif=%s semillas=%s: ganó %d de %d" % [a["dif"], a["seeds"], wins, String(a["seeds"]).split(",").size()])
	quit()


func play(seed: int, a: Dictionary) -> bool:
	dmg_by = {}; kills_by = {}; last_hit = {}; my_bdmg = {}; ram_bdmg = 0; ram_udmg = 0; ram_dmg_by = {}
	ram_closest = 1 << 60; ram_lost = 0; bld_lost = {}; first_bld_min = -1; ram_kill_by = {}; my_kills = {}; my_hits = {}
	var minutes := int(a["min"])
	s = Sim.new(seed, 2, data_over, {"civs": [a["civ"], a["rival"]], "terreno": "llano", "sitios_sin_victoria": true})
	s.ais = [SimAI.new(s, 1, a["dif"])]
	center_id = -1
	for e in s.actives:
		if e.owner == ME and e.capital:
			center_id = e.id
	var vills := mine("aldeano")
	var ids := vills.map(func(v): return v.id)
	send(ids.slice(0, 3), "arbol")
	send(ids.slice(3, 6), "arbusto")
	var built_cuartel := false
	var wealth_sent := false
	var hito_tried := false
	var alarm_on := false
	var attacks := 0
	var attacking := false
	var lost_army := 0
	var prev_army := 0
	var sent_max := 0
	var rb: Vector2i = s.bases[1]
	var cap_hp_min := 1 << 30
	var ai_army_max := 0
	var ai_def_at_attack := []
	while s.tick < minutes * 600:
		s.step()
		watch_events()
		if s.game_over:
			break
		var vnow := mine("aldeano")
		var cobj: SimEntity = s.by_id.get(center_id)
		var enemies_near := []
		if s.tick % 10 == 0:
			var bx: int = s.bases[ME].x * 1000
			var by: int = s.bases[ME].y * 1000
			for e in s.actives:
				if e.alive and e.owner == 1 and e.is_unit() and e.is_military():
					if Sim.dist(e.x, e.y, bx, by) < 18000:
						enemies_near.append(e)
			for r in mine("ariete"):
				ram_closest = mini(ram_closest, Sim.dist(r.x, r.y, rb.x * 1000, rb.y * 1000))
		if s.tick % 600 == 0:
			var aa := 0
			for e in s.actives:
				if e.alive and e.owner == 1:
					if e.is_unit() and e.is_military():
						aa += 1
					if e.is_building() and e.capital:
						cap_hp_min = mini(cap_hp_min, e.hp)
			ai_army_max = maxi(ai_army_max, aa)
			var ai: SimAI = s.ais[0]
			var cen: SimEntity = null
			for e in s.actives:
				if e.alive and e.owner == 1 and e.capital:
					cen = e
			var mine_mil := 0
			for e in s.actives:
				if e.alive and e.owner == ME and e.is_military() and Sim.dist(e.x, e.y, rb.x * 1000, rb.y * 1000) < 25000:
					mine_mil += 1
			L("min %d: aldeanos %d, edad %d, res %s | IA pob %d ejército %d · perdió %d edificios · amenaza %s · míos en su base %d" % [s.tick / 600, vnow.size(), s.players[0]["age"], res(), s.players[1]["pop"], aa, ai._lost_buildings, cen != null and ai._threat(cen) != null, mine_mil])
		if detalle and attacking and s.tick % 100 == 0:
			var mine_far := 0
			var mine_all := 0
			var ai_near := {}
			var dsum := 0
			var orders := {}
			for e in s.actives:
				if e.alive and e.is_unit() and e.is_military():
					var d := Sim.dist(e.x, e.y, rb.x * 1000, rb.y * 1000)
					if e.owner == ME:
						mine_all += 1
						dsum += d / 1000
						var tg: SimEntity = s.by_id.get(e.target)
						var ok: String = str(e.order) + (":" + tg.type if tg != null and e.order == SimEntity.Order.ATTACK else "")
						orders[ok] = int(orders.get(ok, 0)) + 1
						mine_far += 1 if d < 25000 else 0
					elif e.owner == 1 and d < 25000:
						ai_near[e.type] = int(ai_near.get(e.type, 0)) + 1
			L("  pelea: míos %d (a 25 casillas de su base %d, dist media %d, órdenes %s) · suyos cerca %s · bajas %s" % [mine_all, mine_far, dsum / maxi(1, mine_all), orders, ai_near, kills_by])
		if s.tick % 200 != 0 and enemies_near.is_empty():
			continue
		if not enemies_near.is_empty() and s.tick % 50 != 0:
			continue
		var army := []
		for k in ["guerrero", "lancero", "hondero"]:
			army += mine(k)
		if army.size() < prev_army:
			lost_army += prev_army - army.size()
		prev_army = army.size()
		if not enemies_near.is_empty():
			if not army.is_empty() and not attacking:
				s.push_command({"t": "target", "player": ME, "ids": army.map(func(e): return e.id), "target": enemies_near[0].id})
			if enemies_near.size() >= 4 and not alarm_on:
				s.push_command({"t": "alarm", "player": ME, "on": true})
				alarm_on = true
		elif alarm_on:
			s.push_command({"t": "alarm", "player": ME, "on": false})
			alarm_on = false
		if cobj == null or not cobj.alive:
			continue
		var idle_ids := []
		for v in vnow:
			if v.order == SimEntity.Order.IDLE:
				idle_ids.append(v.id)
		if not idle_ids.is_empty() and enemies_near.is_empty():
			send(idle_ids, "arbusto" if int(res()["alimento"]) < int(res()["madera"]) else "arbol")
		if cobj.queue.is_empty() and int(s.players[0]["pop"]) < int(s.players[0]["pop_cap"]) and vnow.size() < 20:
			s.push_command({"t": "train", "player": ME, "building": cobj.id, "type": "aldeano"})
		if int(s.players[0]["pop"]) >= int(s.players[0]["pop_cap"]) - 2 and int(res()["madera"]) >= 60 and vnow.size() > 1:
			var spot := place("casa", 4)
			s.push_command({"t": "build", "player": ME, "ids": [vnow[0].id], "type": "casa", "tx": spot.x, "ty": spot.y})
		if not built_cuartel and s.tick >= 2400 and int(res()["madera"]) >= 150:
			var spot := place("cuartel", 5)
			s.push_command({"t": "build", "player": ME, "ids": [vnow[1].id, vnow[2].id], "type": "cuartel", "tx": spot.x, "ty": spot.y})
			built_cuartel = true
		var tope_ej := int(a.get("tope1", "8")) if int(s.players[0]["age"]) < 2 else 25
		for cu in mine("cuartel"):
			if cu.built and cu.queue.is_empty() and army.size() < tope_ej:
				s.push_command({"t": "train", "player": ME, "building": cu.id, "type": "guerrero"})
		# Aplicado: granjas, campo de tiro, riqueza
		if mine("granja").size() < mini(2 + vnow.size() / 5, 8) and int(res()["madera"]) >= 60 and s.tick >= 1800 and vnow.size() > 6:
			var gs := place("granja", 4)
			var gv: SimEntity = vnow[(9 + mine("granja").size()) % vnow.size()]
			s.push_command({"t": "build", "player": ME, "ids": [gv.id], "type": "granja", "tx": gs.x, "ty": gs.y})
		if mine("campo_tiro").is_empty() and built_cuartel and int(res()["madera"]) >= 100 and s.tick % 600 == 0:
			var cs := place("campo_tiro", 6)
			s.push_command({"t": "build", "player": ME, "ids": [vnow[6].id], "type": "campo_tiro", "tx": cs.x, "ty": cs.y})
		for ct in mine("campo_tiro"):
			if ct.built and ct.queue.is_empty() and army.size() < maxi(tope_ej, 10):
				s.push_command({"t": "train", "player": ME, "building": ct.id, "type": "hondero"})
		if s.tick == 1800 and vnow.size() > 10:
			send([vnow[7].id, vnow[8].id, vnow[9].id], "riqueza")
		# Asedio en la edad II
		var rams: Array = mine("ariete")
		if int(s.players[0]["age"]) >= 2:
			if mine("taller").is_empty() and int(res()["madera"]) >= 150 and s.tick % 600 == 0 and vnow.size() > 8:
				var ts := place("taller", 6)
				s.push_command({"t": "build", "player": ME, "ids": [vnow[7].id, vnow[8].id], "type": "taller", "tx": ts.x, "ty": ts.y})
			for tl in mine("taller"):
				if tl.built and tl.queue.is_empty() and rams.size() < 4:
					s.push_command({"t": "train", "player": ME, "building": tl.id, "type": "ariete"})
		var listo: bool = army.size() >= int(a.get("tropa", "15")) and rams.size() >= int(a.get("arietes", "2"))
		if listo and enemies_near.is_empty():
			if not attacking:
				attacks += 1
				var ai_home := 0
				for e in s.actives:
					if e.alive and e.owner == 1 and e.is_unit() and e.is_military() and Sim.dist(e.x, e.y, rb.x * 1000, rb.y * 1000) < 20000:
						ai_home += 1
				ai_def_at_attack.append("%s:%d+%d contra %d" % [t(), army.size(), rams.size(), ai_home])
				L("ataque %d con %d y %d arietes; la IA tiene %d en casa" % [attacks, army.size(), rams.size(), ai_home])
			attacking = true
			sent_max = maxi(sent_max, army.size() + rams.size())
			var all: Array = army + rams
			s.push_command({"t": "move", "player": ME, "ids": all.map(func(e): return e.id), "x": rb.x * 1000 + 2000, "y": rb.y * 1000 + 2000, "amove": true})
		elif army.size() < 8:
			attacking = false
		if not wealth_sent and s.tick >= 3600 and vnow.size() > 6:
			send([vnow[3].id, vnow[4].id], "riqueza")
			wealth_sent = true
		if not hito_tried and int(s.players[0]["age"]) == 1 and int(res()["alimento"]) >= 500 and int(res()["riqueza"]) >= 300:
			var spot := place("karai_palabra", 6)
			s.push_command({"t": "build", "player": ME, "ids": vnow.slice(0, 4).map(func(e): return e.id), "type": "karai_palabra", "tx": spot.x, "ty": spot.y})
			hito_tried = true
	# Lo que tiene la IA al final
	ai_bld = {}
	for e in s.actives:
		if e.alive and e.owner == 1 and e.is_building() and e.type != "camino":
			ai_bld[e.type] = int(ai_bld.get(e.type, 0)) + 1
	var won: bool = s.game_over and s.winner == ME
	var mm := s.tick / 600
	var ss := s.tick / 10 % 60
	print("semilla %d: %s a las %02d:%02d (%s) · ataques %d (%s) · tropa perdida %d" % [seed, "GANA" if won else ("pierde" if s.game_over else "sin terminar"), mm, ss, s.end_reason, attacks, ", ".join(ai_def_at_attack), lost_army])
	print("  bajas propias por último golpe: %s · bajas que hice: %s" % [_sorted(kills_by), _sorted(my_kills)])
	print("  golpes de mi tropa (sin asedio) por blanco: %s" % _sorted(my_hits))
	print("  daño recibido por atacante: %s" % _sorted(dmg_by))
	print("  daño a los arietes por atacante [daño, golpes]: %s" % str(ram_dmg_by))
	print("  arietes: más cerca de la capital rival %d casillas · perdidos %d (%s) · daño a edificios %d · a unidades %d" % [ram_closest / 1000, ram_lost, _sorted(ram_kill_by), ram_bdmg, ram_udmg])
	print("  daño mío a edificios: %s · tirados: %s (primero al minuto %d) · capital rival mín %d" % [_sorted(my_bdmg), _sorted(bld_lost), first_bld_min, cap_hp_min])
	print("  IA: ejército máx %d · edificios al final %s" % [ai_army_max, _sorted(ai_bld)])
	return won


func _sorted(d: Dictionary) -> String:
	var ks := d.keys()
	ks.sort_custom(func(x, y): return int(d[x]) > int(d[y]))
	return ", ".join(ks.map(func(k): return "%s %d" % [k, d[k]]))
