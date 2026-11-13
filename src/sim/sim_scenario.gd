class_name SimScenario
extends RefCounted
## Motor de escenarios: ejecuta una misión de data/campanas/ dentro de la simulación (docs/campanas/).
## Es determinista: arma el mapa, evalúa objetivos cada segundo y dispara eventos.

const P := 1000

var sim: Sim
var mission: Dictionary
var civ: String
var objectives: Array[Dictionary] = []
var triggers: Array[Dictionary] = []
var result := "" # "", "victoria", "derrota"
var trained := {} # tipo -> cantidad entrenada por el jugador
var destroyed := {} # "jugador:tipo" -> edificios perdidos por ese jugador a manos del jugador 0
var kills := 0 # unidades enemigas abatidas por el jugador 0
var _seen := {} # tipos protegidos que llegaron a existir


## Crea la simulación de una misión. El jugador es el 0; los rivales, 1..n.
static func create(m: Dictionary, civ_key: String) -> Sim:
	var civs: Array = [civ_key]
	for r: Dictionary in m.get("rivales", []):
		civs.append(r.get("faccion", "invasores"))
	var mapa: Dictionary = m.get("mapa", {})
	var s := Sim.new(int(mapa.get("semilla", 1)), civs.size(), null, {"terreno": mapa.get("terreno", "llano"), "civs": civs, "sin_sitios": true})
	var sc := SimScenario.new()
	sc.sim = s
	sc.mission = m
	sc.civ = civ_key
	s.scenario = sc
	sc._setup()
	return s


func _setup() -> void:
	var m := mission
	var j: Dictionary = m.get("jugador", {})
	var p0: Dictionary = sim.players[0]
	p0["age"] = int(j.get("edad", 1))
	for k in j.get("recursos", {}):
		p0["res"][k] = int(j["recursos"][k])
	var capital := _capital(0)
	var extra := int(j.get("aldeanos", 6)) - _count(0, "aldeano")
	for i in maxi(0, extra):
		sim.spawn_near(capital, "aldeano")
	for t: Dictionary in j.get("tropas", []):
		_spawn_group(0, t["tipo"], int(t["n"]), capital)
	# Rivales: edad, base, tropas y lo que haga falta para sus objetivos.
	sim.ais = []
	var rivals: Array = m.get("rivales", [])
	for i in rivals.size():
		var pid := i + 1
		var r: Dictionary = rivals[i]
		var age := int(r.get("edad", 1))
		sim.players[pid]["age"] = age
		for k in sim.players[pid]["res"]:
			sim.players[pid]["res"][k] = int(sim.players[pid]["res"][k]) + 300 * age
		var ai := SimAI.new(sim, pid)
		ai.personality = r.get("ia", "normal")
		sim.ais.append(ai)
		var cap := _capital(pid)
		if cap == null:
			continue
		_place_near(pid, "casa", cap, 2)
		_place_near(pid, "cuartel", cap, 1)
		if age >= 2:
			_place_near(pid, "torre", cap, 1)
		_place_near(pid, "granja", cap, 2)
		var garrison := 3 + 3 * age if ai.personality != "pasiva" else 2 + age
		for k in garrison:
			_spawn_group(pid, ["lancero", "hondero", "guerrero"][k % 3] if age >= 2 else ["guerrero", "hondero"][k % 2], 1, cap)
	for o: Dictionary in m.get("objetivos", []):
		var oo := o.duplicate(true)
		oo["estado"] = "oculto" if o.get("oculto", false) else "activo"
		oo["desde"] = 0
		objectives.append(oo)
		if o["tipo"] == "destruir":
			var pr: Dictionary = o["params"]
			var who := int(pr.get("jugador", 1))
			if who > 0 and who < sim.players.size():
				var need := int(pr.get("n", 1)) - _count(who, pr["tipo"])
				_place_near(who, pr["tipo"], _capital(who), need)
	for e: Dictionary in m.get("eventos", []):
		var ee := e.duplicate(true)
		ee["hecho"] = false
		triggers.append(ee)
	sim._update_players()
	for pid in sim.players.size():
		sim._update_fog(pid)


# ---------------------------------------------------------------- Cada tick

func on_step() -> void:
	for ev in sim.events:
		match ev["t"]:
			"trained":
				if ev.get("player", -1) == 0 and ev.has("type"):
					trained[ev["type"]] = int(trained.get(ev["type"], 0)) + 1
			"died":
				if ev.get("by", -1) == 0 and ev.get("owner", -1) > 0:
					if ev["cat"] == SimEntity.Cat.UNIT:
						kills += 1
					else:
						var key := "%d:%s" % [ev["owner"], ev["type"]]
						destroyed[key] = int(destroyed.get(key, 0)) + 1
	if sim.tick % 10 != 0 or result != "":
		return
	_fire("tiempo", sim.tick * sim.tick_ms / 1000)
	if sim.tick == 0:
		_fire("inicio", 0)
	for o in objectives:
		if o["estado"] != "activo":
			continue
		var st := _eval(o)
		if st == "hecho":
			o["estado"] = "hecho"
			sim.events.append({"t": "objetivo", "id": o["id"], "estado": "hecho", "texto": o["texto"]})
			_fire("objetivo", o["id"])
		elif st == "fallado":
			o["estado"] = "fallado"
			sim.events.append({"t": "objetivo", "id": o["id"], "estado": "fallado", "texto": o["texto"]})
	_check_end()


func _eval(o: Dictionary) -> String:
	var pr: Dictionary = o.get("params", {})
	var p0: Dictionary = sim.players[0]
	match o["tipo"]:
		"construir":
			return "hecho" if _count(0, pr["tipo"], true) >= int(pr.get("n", 1)) else ""
		"entrenar":
			var n := 0
			for t in _aliases(pr["tipo"]):
				n += int(trained.get(t, 0))
			return "hecho" if n >= int(pr.get("n", 1)) else ""
		"recolectar":
			return "hecho" if int(p0["res"].get(pr["recurso"], 0)) >= int(pr.get("n", 0)) else ""
		"edad":
			return "hecho" if int(p0["age"]) >= int(pr.get("n", 2)) else ""
		"sobrevivir":
			return "hecho" if (sim.tick - int(o["desde"])) * sim.tick_ms / 1000 >= int(pr.get("segundos", 60)) else ""
		"destruir_hitos":
			var who := int(pr.get("jugador", 1))
			return "hecho" if who < sim.players.size() and sim.players[who]["defeated"] else ""
		"destruir":
			var who := int(pr.get("jugador", 1))
			var n := 0
			for t in _aliases(pr["tipo"], who):
				n += int(destroyed.get("%d:%s" % [who, t], 0))
			return "hecho" if n >= int(pr.get("n", 1)) else ""
		"matar":
			return "hecho" if kills >= int(pr.get("n", 1)) else ""
		"proteger":
			var have := _count(int(pr.get("jugador", 0)), pr["tipo"], false)
			if have > 0:
				_seen[o["id"]] = true
			elif _seen.has(o["id"]):
				return "fallado"
			# Sigue activo: se cumple al terminar la misión si nunca cayó.
			return ""
	return ""


func _check_end() -> void:
	if sim.players[0]["defeated"]:
		_finish("derrota")
		return
	var all_done := true
	for o in objectives:
		if o.get("secundario", false):
			continue
		if o["estado"] == "fallado":
			_finish("derrota")
			return
		if o["tipo"] == "proteger":
			continue
		if o["estado"] != "hecho":
			all_done = false
	if all_done:
		for o in objectives:
			if o["tipo"] == "proteger" and o["estado"] == "activo":
				o["estado"] = "hecho"
		_finish("victoria")


func _finish(r: String) -> void:
	result = r
	sim.events.append({"t": "mision", "resultado": r})


# ---------------------------------------------------------------- Eventos

func _fire(kind: String, value: Variant) -> void:
	for e in triggers:
		if e["hecho"]:
			continue
		var c: Dictionary = e["cuando"]
		if c["tipo"] != kind:
			continue
		if kind == "tiempo" and int(value) < int(c.get("valor", 0)):
			continue
		if kind == "objetivo" and String(c.get("valor", "")) != String(value):
			continue
		e["hecho"] = true
		_act(e["accion"])


func _act(a: Dictionary) -> void:
	var pr: Dictionary = a.get("params", {})
	match a["tipo"]:
		"dialogo":
			sim.events.append({"t": "dialogo", "quien": pr.get("quien", ""), "texto": pr.get("texto", "")})
		"refuerzos":
			var who := int(pr.get("jugador", 0))
			if who < sim.players.size():
				var cap := _capital(who)
				if cap != null:
					_spawn_group(who, pr["tipo"], int(pr.get("n", 1)), cap)
					if who == 0:
						sim.events.append({"t": "notify", "player": 0, "msg": "Llegan refuerzos"})
		"ataque":
			_attack(int(pr.get("jugador", 1)), pr["tipo"], int(pr.get("n", 1)))
		"recursos":
			for k in pr:
				sim.players[0]["res"][k] = int(sim.players[0]["res"].get(k, 0)) + int(pr[k])
		"revelar":
			var g: PackedByteArray = sim.fog.grids[0]
			for i in g.size():
				if g[i] == 0:
					g[i] = 1
		"objetivo_nuevo":
			for o in objectives:
				if o["id"] == pr.get("id", "") and o["estado"] == "oculto":
					o["estado"] = "activo"
					o["desde"] = sim.tick
					sim.events.append({"t": "objetivo", "id": o["id"], "estado": "nuevo", "texto": o["texto"]})


## Una columna aparece en el borde del mapa del lado del rival y avanza sobre la capital del jugador.
func _attack(who: int, type: String, n: int) -> void:
	if who <= 0 or who >= sim.players.size():
		return
	var target := _capital(0)
	if target == null:
		return
	var base: Vector2i = sim.bases[who % 4] + Vector2i(2, 2)
	var nn := sim.map.n
	var edge := Vector2i(clampi(base.x + signi(base.x - nn / 2) * 20, 2, nn - 3), clampi(base.y + signi(base.y - nn / 2) * 20, 2, nn - 3))
	var ids := []
	var kind := _unit_for(who, type)
	for i in n:
		var t := sim.map.nearest_free(edge.x + (i % 5) - 2, edge.y + (i / 5) - 1, 10, who)
		if t.x < 0:
			continue
		var u := sim.spawn_unit(kind, who, t.x * P + P / 2, t.y * P + P / 2)
		ids.append(u.id)
	sim.push_command({"t": "move", "player": who, "ids": ids, "x": target.x, "y": target.y, "amove": true})
	sim.events.append({"t": "alert", "player": 0, "x": target.x, "y": target.y})


# ---------------------------------------------------------------- Ayudas

## Si la civilización del jugador no tiene la unidad pedida, usa la más parecida por función.
func _unit_for(pid: int, type: String) -> String:
	var dd := sim.dp(pid)
	if dd.unidades.has(type):
		return type
	var want: String = sim.data.unidades.get(type, {}).get("funcion", "choque")
	for k in dd.unidades:
		if dd.unidades[k].get("funcion", "") == want:
			return k
	return "guerrero"


func _aliases(type: String, pid: int = 0) -> Array:
	var a: Array = sim.dp(pid).civ.get("alias_campana", {}).get(type, [])
	return a if not a.is_empty() else [type]


func _count(pid: int, type: String, built_only: bool = false) -> int:
	var types := _aliases(type, pid)
	var n := 0
	for e in sim.actives:
		if e.alive and e.owner == pid and e.type in types and (not built_only or not e.is_building() or e.built):
			n += 1
	return n


func _capital(pid: int) -> SimEntity:
	var fallback: SimEntity = null
	for e in sim.actives:
		if e.alive and e.owner == pid and e.is_building():
			if e.capital:
				return e
			if fallback == null:
				fallback = e
	if fallback == null:
		for e in sim.actives:
			if e.alive and e.owner == pid:
				return e
	return fallback


func _spawn_group(pid: int, type: String, n: int, near: SimEntity) -> void:
	if near == null:
		return
	var kind := _unit_for(pid, type)
	for i in n:
		sim.spawn_near(near, kind, pid)


func _place_near(pid: int, type: String, cap: SimEntity, n: int) -> void:
	if cap == null or n <= 0 or not sim.dp(pid).edificios.has(type):
		return
	var tam: Array = sim.dp(pid).edificios[type]["tam"]
	var placed := 0
	for r in range(4, 16):
		for dy in range(-r, r + 1, 2):
			for dx in range(-r, r + 1, 2):
				if placed >= n or (absi(dx) != r and absi(dy) != r):
					continue
				var tx: int = cap.tx + dx
				var ty: int = cap.ty + dy
				if sim.can_place(type, tx, ty, pid) and sim.map.is_free_rect(tx - 1, ty - 1, int(tam[0]) + 2, int(tam[1]) + 2):
					sim.spawn_building(type, pid, tx, ty, true)
					placed += 1
		if placed >= n:
			return


func active_objectives() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for o in objectives:
		if o["estado"] != "oculto":
			out.append(o)
	return out
