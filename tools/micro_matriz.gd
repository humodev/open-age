extends SceneTree
## Matriz de peleas aisladas: choque, distancia, línea y mezclas, con y sin micro (proceso/24, 5a).
## Amplía tests/micro.gd y el micro2.gd del veterano: mismo armado (dos grupos a 14 casillas,
## ataque en movimiento), pero con la capa común en los dos bandos (sin bonos de pueblo), la edad
## que se pida y un parche de datos en memoria para probar propuestas sin tocar data/.
##
## Uso:
##   godot --headless --path . -s tools/micro_matriz.gd
##   godot --headless --path . -s tools/micro_matriz.gd -- --parche=ruta/parche.json --edad=2
##   godot --headless --path . -s tools/micro_matriz.gd -- --civs=guaranies,mapuches --casos="lancero:5+hondero:5|guerrero:10|nada"
##
## Opciones:
##   --civs=a,b    pueblos de los bandos A y B (vacío: capa común, sin reemplazos ni módulos)
##   --edad=N      edad de los dos bandos (por defecto 2: está el lancero)
##   --compras     los dos bandos con lo que reemplaza al bono por edad desde el paso 1 del juego
##                 tardío (la herrería I de ataque en la II, más los niveles veterano y élite en la III y la IV)
##   --parche=F    JSON con {"reglas": {...}, "unidades": {tipo: {campo: valor}},
##                 "civs": {pueblo: {"unidades": {...}, "unidades_nuevas": {...}}}}; se fusiona
##                 en memoria antes de armar las tablas de cada pueblo
##   --casos=...   lista separada por ";" de "A|B|modo[|formación]"; A y B son "tipo:n+tipo:n"
##   --set=NOMBRE  solo los casos de ese conjunto de la matriz por defecto (base, mezcla, kiteo)
##   --variantes=N repite cada pelea N veces (hasta 10) con otra semilla y el bando B corrido de
##                 costado; la pelea es caótica y una sola corrida engaña. Con N > 1 imprime cuántas
##                 gana A y el promedio de vivos de cada lado
##
## Modos (los aplica solo el bando A; B siempre va con ataque en movimiento):
##   nada        ataque en movimiento, sin micro
##   foco        los de distancia tiran todos al enemigo con menos vida a su alcance
##   kitear      el kiteo del veterano: si un enemigo está a 2,2 casillas, alejarse 3 (tests/micro.gd B)
##   escalonar   kiteo bien hecho (AoE4): tirar cuando la carga está lista; mientras recarga, si
##               un cuerpo a cuerpo está a menos del 60 % del alcance, alejarse 2 casillas
##   mantener    la línea forma y mantiene posición; la distancia mantiene detrás y tira
##   mantener+escalonar  la línea mantiene y la distancia escalona detrás de ella
##   esquivar    --- esport 1a --- cada unidad que está donde va a caer un tiro de asedio de área
##               (Sim.shells) se corre fuera del área y vuelve al ataque cuando cae (200 ms de reacción)
## Formación (opcional): bloque, linea, abierta, columna (la del grupo de AoE4, data/reglas.json).

const O := SimEntity.Order
const P := 1000
const KITE_PCT := 60
const MAX_TICKS := 1500

var data: SimData
var civs: Array = ["", ""]
var age := 2
var variants := 1
var purchases := false
const SHIFTS := [0, -1, 1, -2, 2, 0, -1, 1, -2, 2]


func _init() -> void:
	var patch_path := ""
	var cases_arg := ""
	var only_set := ""
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--civs="):
			civs = Array(a.substr(7).split(","))
			while civs.size() < 2:
				civs.append("")
		elif a.begins_with("--edad="):
			age = int(a.substr(7))
		elif a == "--compras":
			purchases = true
		elif a.begins_with("--parche="):
			patch_path = a.substr(9)
		elif a.begins_with("--casos="):
			cases_arg = a.substr(8)
		elif a.begins_with("--set="):
			only_set = a.substr(6)
		elif a.begins_with("--variantes="):
			variants = clampi(int(a.substr(12)), 1, SHIFTS.size())
	data = SimData.load_default()
	if patch_path != "":
		_apply_patch(patch_path)
	print("# micro_matriz · civs %s / %s · edad %d%s · parche %s" % [civs[0] if civs[0] != "" else "capa común", civs[1] if civs[1] != "" else "capa común", age, " con compras" if purchases else "", patch_path if patch_path != "" else "ninguno"])
	print("# bonos %s" % JSON.stringify(data.reglas.get("bonos", {})))
	for t in ["guerrero", "hondero", "lancero", "jinete", "catapulta"]:
		var d: Dictionary = data.for_civ(civs[0]).unidades.get(t, {})
		if not d.is_empty():
			print("# %s: pv %d, ataque %d, armadura %d/%d, alcance %d, cadencia %d, velocidad %d, costo %s" % [t, d["pv"], d["ataque"], d.get("armadura", 0), d.get("armadura_distancia", d.get("armadura", 0)), d["alcance"], d["cadencia_ms"], d["velocidad"], JSON.stringify(d.get("costo", {}))])
	var cases: Array = []
	if cases_arg != "":
		for c in cases_arg.split(";"):
			if c.strip_edges() != "":
				cases.append(["custom"] + Array(c.strip_edges().split("|")))
	else:
		cases = _default_cases()
	if variants > 1:
		print("# %d variantes por pelea (semilla 3..%d, B corrido 0, -1, 1, -2, 2 casillas)" % [variants, 2 + variants])
		print("conjunto | A | B | modo | formación | tiempo medio | gana A | A vivos (prom.) | B vivos (prom.) | costo A / B")
	else:
		print("conjunto | A | B | modo | formación | tiempo | A vivos (vida) | B vivos (vida) | costo A / B")
	for c in cases:
		if only_set != "" and c[0] != only_set:
			continue
		_case(c)
	quit()


func _default_cases() -> Array:
	var g := "guerrero:10"
	var h := "hondero:10"
	var l := "lancero:10"
	var j := "jinete:5"
	var m := "lancero:5+hondero:5"
	return [
		["base", g, g, "nada"],
		["base", h, h, "nada"],
		["base", l, l, "nada"],
		["base", h, g, "nada"],
		["base", h, g, "foco"],
		["base", h, l, "nada"],
		["base", g, l, "nada"],
		["base", j, h, "nada"],
		["base", l, j, "nada"],
		["base", g, j, "nada"],
		["kiteo", h, g, "kitear"],
		["kiteo", h, g, "escalonar"],
		["kiteo", h, l, "kitear"],
		["kiteo", h, l, "escalonar"],
		["kiteo", h, j, "escalonar"],
		["mezcla", m, g, "nada"],
		["mezcla", m, g, "mantener"],
		["mezcla", m, g, "foco"],
		["mezcla", m, g, "mantener+escalonar"],
		["mezcla", m, g, "nada", "linea"],
		["mezcla", m, j, "nada"],
		["mezcla", m, h, "nada"],
		["mezcla", m, l, "nada"],
		["mezcla", "guerrero:5+hondero:5", m, "nada"],
		# --- esport 1a --- el triángulo a igual costo y mano a mano (proceso/34-hacia-esport/01a)
		["triangulo", "lancero:9", "jinete:5", "nada"],
		["triangulo", "lancero:5", "jinete:5", "nada"],
		["triangulo", "lancero:1", "jinete:1", "nada"],
		["triangulo", "guerrero:9", "hondero:10", "nada"],
		["triangulo", "hondero:10", "lancero:8", "nada"],
		["triangulo", "guerrero:1", "hondero:1", "nada"],
		["triangulo", "hondero:1", "lancero:1", "nada"],
		# --- esport 1a --- contra el asedio de área: sin micro, esquivando y en formación abierta
		["area", "hondero:10", "catapulta:2+lancero:4", "nada"],
		["area", "hondero:10", "catapulta:2+lancero:4", "esquivar"],
		["area", "hondero:10", "catapulta:2+lancero:4", "nada", "abierta"],
		["area", "lancero:10", "catapulta:2+hondero:6", "nada"],
		["area", "lancero:10", "catapulta:2+hondero:6", "esquivar"],
	]


# ------------------------------------------------------------------ parche de datos

func _apply_patch(path: String) -> void:
	var f := FileAccess.open(path, FileAccess.READ)
	assert(f != null, "No se pudo abrir el parche %s" % path)
	var p: Dictionary = JSON.parse_string(f.get_as_text())
	_deep_merge(data.reglas, SimData._to_int(p.get("reglas", {}), path))
	_deep_merge(data.unidades, SimData._to_int(p.get("unidades", {}), path))
	var civ_patch: Dictionary = SimData._to_int(p.get("civs", {}), path)
	var keys: Array = data.civs.keys()
	for key in keys:
		var raw: Dictionary = (data.civs[key] as SimData).civ
		if civ_patch.has(key):
			_deep_merge(raw, civ_patch[key])
		data.civs[key] = data._merge(raw)


func _deep_merge(dst: Dictionary, src: Dictionary) -> void:
	for k in src:
		if src[k] is Dictionary and dst.get(k) is Dictionary:
			_deep_merge(dst[k], src[k])
		else:
			dst[k] = src[k]


# ------------------------------------------------------------------ pelea

func _parse(spec: String) -> Array:
	var out := []
	for part in spec.split("+"):
		var kv := part.split(":")
		out.append([kv[0], int(kv[1]) if kv.size() > 1 else 1])
	return out


func _spawn(s: Sim, type: String, owner: int, n: int, cx: int, cy: int) -> Array:
	var ids := []
	for i in n:
		var t := s.map.nearest_free(cx + i % 5, cy + i / 5, 8, owner)
		ids.append(s.spawn_unit(type, owner, t.x * P + 500, t.y * P + 500).id)
	return ids


func _alive(s: Sim, ids: Array) -> int:
	var n := 0
	for id in ids:
		var e: SimEntity = s.by_id.get(id)
		if e != null and e.alive:
			n += 1
	return n


func _hp(s: Sim, ids: Array) -> int:
	var n := 0
	for id in ids:
		var e: SimEntity = s.by_id.get(id)
		if e != null and e.alive:
			n += e.hp
	return n


func _cost(s: Sim, owner: int, groups: Array) -> int:
	var n := 0
	for g in groups:
		var c: Dictionary = s.dp(owner).unidades[g[0]].get("costo", {})
		for r in c:
			n += int(c[r]) * int(g[1])
	return n


func _case(c: Array) -> void:
	var mode: String = c[3]
	var form: String = c[4] if c.size() > 4 else ""
	if variants == 1:
		var r := _fight(c, 0)
		print("%s | %s | %s | %s | %s | %.1f s | %d/%d (%d%%) | %d/%d (%d%%) | %d / %d" % [c[0], c[1], c[2], mode, form if form != "" else "-", r["t"] / 10.0, r["va"], r["na"], r["hpa"], r["vb"], r["nb"], r["hpb"], r["ca"], r["cb"]])
		return
	var wins := 0
	var sum_a := 0
	var sum_b := 0
	var sum_t := 0
	var r := {}
	for v in variants:
		r = _fight(c, v)
		sum_a += r["va"]
		sum_b += r["vb"]
		sum_t += r["t"]
		if r["va"] > 0 and r["vb"] == 0:
			wins += 1
	print("%s | %s | %s | %s | %s | %.1f s | %d/%d | %.1f/%d | %.1f/%d | %d / %d" % [c[0], c[1], c[2], mode, form if form != "" else "-", sum_t / 10.0 / variants, wins, variants, float(sum_a) / variants, r["na"], float(sum_b) / variants, r["nb"], r["ca"], r["cb"]])


func _fight(c: Array, v: int) -> Dictionary:
	var sa := _parse(c[1])
	var sb := _parse(c[2])
	var mode: String = c[3]
	var form: String = c[4] if c.size() > 4 else ""
	var s := Sim.new(3 + v, 2, data, {"civs": civs, "terreno": "llano", "sin_sitios": true})
	s.players[0]["age"] = age
	s.players[1]["age"] = age
	if purchases:
		s.grant_age_purchases(0, age)
		s.grant_age_purchases(1, age)
	var cx := s.map.n / 2
	var a := []
	var melee_a := []
	var ranged_a := []
	var row := 0
	for g in sa:
		var ids := _spawn(s, g[0], 0, g[1], cx - 9 - row * 2, cx - 1)
		a += ids
		if s.is_ranged(s.by_id[ids[0]]):
			ranged_a += ids
		else:
			melee_a += ids
		row += 1
	var b := []
	for g in sb:
		b += _spawn(s, g[0], 1, g[1], cx + 5, cx - 1 + SHIFTS[v])
	var goal_a := Vector2i((cx + 8) * P, cx * P)
	if mode.begins_with("mantener"):
		s.push_command({"t": "formar", "player": 0, "ids": a, "form": form if form != "" else "bloque", "rumbo": 4})
	else:
		var cmd := {"t": "move", "player": 0, "ids": a, "x": goal_a.x, "y": goal_a.y, "amove": true}
		if form != "":
			cmd["form"] = form
		s.push_command(cmd)
	s.push_command({"t": "move", "player": 1, "ids": b, "x": (cx - 8) * P, "y": cx * P, "amove": true})
	var hp0 := [_hp(s, a), _hp(s, b)]
	var dodging := {} # --- esport 1a --- id -> tick en que cae el tiro que esquiva
	var t := 0
	while t < MAX_TICKS and _alive(s, a) > 0 and _alive(s, b) > 0:
		if mode.begins_with("mantener") and t == 40:
			s.push_command({"t": "mantener", "player": 0, "ids": melee_a if mode == "mantener+escalonar" else a})
		match mode:
			"kitear":
				if t % 5 == 0 and t > 0:
					_kite_veteran(s, ranged_a, goal_a)
			"escalonar":
				if t % 2 == 0 and t > 0:
					_kite_stutter(s, ranged_a, goal_a, false)
			"mantener+escalonar":
				if t % 2 == 0 and t > 40:
					_kite_stutter(s, ranged_a, goal_a, true)
			"foco":
				if t % 5 == 0 and t > 0:
					_focus(s, ranged_a, b)
			"esquivar":
				if t % 2 == 0 and t > 0:
					_dodge(s, a, goal_a, dodging)
		s.step()
		t += 1
	return {"t": t, "va": _alive(s, a), "na": a.size(), "hpa": _hp(s, a) * 100 / maxi(1, hp0[0]), "vb": _alive(s, b), "nb": b.size(), "hpb": _hp(s, b) * 100 / maxi(1, hp0[1]), "ca": _cost(s, 0, sa), "cb": _cost(s, 1, sb)}


## El kiteo del veterano (tests/micro.gd, caso B): alejarse 3 casillas de quien esté a 2,2.
func _kite_veteran(s: Sim, ids: Array, goal: Vector2i) -> void:
	for id in ids:
		var u: SimEntity = s.by_id.get(id)
		if u == null or not u.alive:
			continue
		var foe := s.find_enemy(u, 2200, true)
		if foe != null:
			_away(s, u, foe, 3000)
		elif u.order == O.IDLE or u.order == O.MOVE and u.group < 0:
			s.push_command({"t": "move", "player": 0, "ids": [id], "x": goal.x, "y": goal.y, "amove": true, "suelto": true})


## Escalonar (stutter step): tirar con la carga lista, alejarse mientras recarga.
func _kite_stutter(s: Sim, ids: Array, goal: Vector2i, behind_line: bool) -> void:
	for id in ids:
		var u: SimEntity = s.by_id.get(id)
		if u == null or not u.alive:
			continue
		var reach: int = u.def["alcance"]
		var foe := _nearest_foe(s, u, int(u.def["vision"]))
		if foe == null:
			if u.order == O.IDLE or u.order == O.MOVE and u.group < 0:
				s.push_command({"t": "move", "player": 0, "ids": [id], "x": goal.x, "y": goal.y, "amove": true, "suelto": true})
			continue
		var d := s.dist_to(u, foe)
		var melee := not s.is_ranged(foe)
		if u.cooldown > 0 and melee and d < reach * KITE_PCT / 100:
			_away(s, u, foe, 2000)
		elif u.cooldown <= 0 and d <= reach:
			if u.order != O.ATTACK or u.target != foe.id:
				s.push_command({"t": "target", "player": 0, "ids": [id], "target": foe.id, "suelto": true})
		elif not behind_line and u.order != O.ATTACK and u.order != O.MOVE:
			s.push_command({"t": "target", "player": 0, "ids": [id], "target": foe.id, "suelto": true})
		elif behind_line and u.order == O.MOVE and u.path.is_empty():
			s.push_command({"t": "mantener", "player": 0, "ids": [id]})


func _nearest_foe(s: Sim, u: SimEntity, radius: int) -> SimEntity:
	var best: SimEntity = null
	var bd := 1 << 60
	for e in s.actives:
		if e.alive and e.is_unit() and e.owner >= 0 and e.owner != u.owner and e.inside < 0:
			var d := s.dist_to(u, e)
			if d <= radius and d < bd:
				bd = d
				best = e
	return best


func _away(s: Sim, u: SimEntity, foe: SimEntity, how_far: int) -> void:
	var dx := u.x - foe.x
	var dy := u.y - foe.y
	var l := maxi(1, int(sqrt(float(dx * dx + dy * dy))))
	s.push_command({"t": "move", "player": 0, "ids": [u.id], "x": u.x + dx * how_far / l, "y": u.y + dy * how_far / l, "suelto": true})


# --- esport 1a ---
## Esquivar el asedio de área: quien está a `area` + 0,3 casillas de donde va a caer un tiro rival
## se corre `area` + 0,6 casillas desde ese punto; cuando el tiro cayó, vuelve al ataque.
func _dodge(s: Sim, ids: Array, goal: Vector2i, dodging: Dictionary) -> void:
	for id in ids:
		var u: SimEntity = s.by_id.get(id)
		if u == null or not u.alive:
			continue
		if dodging.has(id):
			if s.tick > int(dodging[id]):
				dodging.erase(id)
				s.push_command({"t": "move", "player": 0, "ids": [id], "x": goal.x, "y": goal.y, "amove": true, "suelto": true})
			continue
		for sh in s.shells:
			var src: SimEntity = sh["a"]
			if src.owner == u.owner:
				continue
			var r := int(src.def["area"])
			var px := int(sh["x"])
			var py := int(sh["y"])
			if Sim.dist(u.x, u.y, px, py) <= r + 300:
				var dx := u.x - px
				var dy := u.y - py
				if dx == 0 and dy == 0:
					dy = 1
				var l := maxi(1, int(sqrt(float(dx * dx + dy * dy))))
				var go := r + 600
				s.push_command({"t": "move", "player": 0, "ids": [id], "x": px + dx * go / l, "y": py + dy * go / l, "suelto": true})
				dodging[id] = int(sh["tick"])
				break
# --- fin esport 1a ---


## Fuego concentrado: los de distancia, al enemigo con menos vida que esté a su alcance.
func _focus(s: Sim, ids: Array, foes: Array) -> void:
	var by_target := {}
	for id in ids:
		var u: SimEntity = s.by_id.get(id)
		if u == null or not u.alive:
			continue
		var tgt := -1
		var low := 1 << 30
		for fid in foes:
			var e: SimEntity = s.by_id.get(fid)
			if e != null and e.alive and e.hp < low and s.dist_to(u, e) <= int(u.def["alcance"]) + 1000:
				low = e.hp
				tgt = fid
		if tgt >= 0 and (u.order != O.ATTACK or u.target != tgt):
			by_target.get_or_add(tgt, []).append(id)
	for tgt in by_target:
		s.push_command({"t": "target", "player": 0, "ids": by_target[tgt], "target": tgt, "suelto": true})
