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
var motivo := "" # por qué terminó la misión (se muestra en la pantalla de fin)
var cuenta := {} # cuenta regresiva a la vista: {"texto", "fin" (tick)}; vacía si no hay
var sites_win := true # si tener todos los sitios gana la partida (mapa.sitios.victoria)


## Crea la simulación de una misión. El jugador es el 0; los rivales, 1..n.
static func create(m: Dictionary, civ_key: String) -> Sim:
	var civs: Array = [civ_key]
	for r: Dictionary in m.get("rivales", []):
		civs.append(r.get("faccion", "invasores"))
	var mapa: Dictionary = m.get("mapa", {})
	var opts := {"terreno": mapa.get("terreno", "llano"), "civs": civs, "sin_sitios": true}
	# Sitios sagrados propios de la misión (el tutorial los enseña): no ganan la partida si así se pide.
	if mapa.has("sitios") and not bool(mapa["sitios"].get("victoria", true)):
		opts["sitios_sin_victoria"] = true
	# Relieve real del lugar (tools/relieve_real.py, docs/10), si la misión lo tiene.
	var rpath := "res://data/relieve/%s.json" % m.get("id", "")
	if mapa.get("relieve_real", true) and FileAccess.file_exists(rpath):
		var rd: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(rpath))
		opts["relieve"] = {"alturas": rd["alturas"], "agua": rd["agua"]}
	var s := Sim.new(int(mapa.get("semilla", 1)), civs.size(), null, opts)
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
		var ai := SimAI.new(sim, pid, r.get("dificultad", "normal"))
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
	# Sitios sagrados de la misión: desplazamientos desde la capital del jugador, hacia el centro.
	var cap0 := _capital(0)
	if cap0 != null:
		for d: Array in m.get("mapa", {}).get("sitios", {}).get("lugares", []):
			var sx := signi(sim.map.n / 2 - cap0.tx)
			var sy := signi(sim.map.n / 2 - cap0.ty)
			var t := sim.map.nearest_free(cap0.tx + sx * int(d[0]), cap0.ty + sy * int(d[1]), 8)
			if t.x >= 0 and sim.map.is_free_rect(t.x, t.y, 2, 2):
				sim.spawn_building("sitio_sagrado", -1, t.x, t.y, true)
	for o: Dictionary in m.get("objetivos", []):
		var oo := o.duplicate(true)
		oo["estado"] = "oculto" if o.get("oculto", false) else "activo"
		oo["desde"] = 0
		if oo["estado"] == "activo":
			oo["base"] = _gathered(0)
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
	# La tropa que la misión da al empezar no tranca el entrenamiento: el exceso sobre el tope
	# queda como población extra (todas las misiones arrancaban con "hay más gente que lugar").
	for p in sim.players:
		if int(p["pop"]) > int(p["pop_cap"]):
			p["pob_extra"] = int(p["pop"]) - int(p["pop_cap"])
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
	# Eventos con espera ("cuando": {..., "espera": segundos}): se disparan cuando vence.
	for e in triggers:
		if not e["hecho"] and e.has("listo") and sim.tick >= int(e["listo"]):
			e["hecho"] = true
			_act(e["accion"])
	if not cuenta.is_empty() and sim.tick >= int(cuenta["fin"]):
		cuenta = {}
	if sim.tick == 0:
		_fire("inicio", 0)
	_obras()
	_agotados()
	for o in objectives:
		if o["estado"] != "activo":
			continue
		# "despues_de": no se cumple antes que esos objetivos (el tutorial: abatir a los
		# saqueadores no se adelanta a "entrená 5 guerreros"; jugador nuevo, ronda 3).
		if not _done(o.get("despues_de", [])):
			continue
		var st := _eval(o)
		if st == "hecho":
			o["estado"] = "hecho"
			sim.events.append({"t": "objetivo", "id": o["id"], "estado": "hecho", "texto": o["texto"]})
			_fire("objetivo", o["id"])
		elif st == "fallado":
			o["estado"] = "fallado"
			if motivo == "" and not o.get("secundario", false):
				motivo = String(o.get("params", {}).get("texto_fallo", ""))
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
				# "nuevos": solo lo entrenado desde que apareció el objetivo.
				if pr.get("nuevos", false):
					n -= int((o.get("base_entrenadas", {}) as Dictionary).get(t, 0))
			return "hecho" if n >= int(pr.get("n", 1)) else ""
		"recolectar":
			return "hecho" if int(p0["res"].get(pr["recurso"], 0)) >= int(pr.get("n", 0)) else ""
		"juntar":
			# Lo juntado desde que apareció el objetivo, no lo que hay en el banco (gastar no lo deshace).
			var now := _gathered(0)
			var base: Dictionary = o.get("base", {})
			for k in pr.get("recursos", {}):
				if int(now.get(k, 0)) - int(base.get(k, 0)) < int(pr["recursos"][k]):
					return ""
			return "hecho"
		"explorar":
			# Un sitio sagrado (o cualquier edificio del tipo pedido) ya visto por el jugador.
			var kind: String = pr.get("tipo", "sitio_sagrado")
			for e in sim.actives:
				if e.alive and e.type == kind and sim.fog.is_explored(0, e):
					return "hecho"
			return ""
		"sitio":
			var held := 0
			for e in sim.actives:
				if e.alive and e.def.get("sagrado", false) and e.holder == 0:
					held += 1
			return "hecho" if held >= int(pr.get("n", 1)) else ""
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


## ¿Están cumplidos todos estos objetivos (ids)?
func _done(ids: Variant) -> bool:
	if ids is String:
		ids = [ids]
	for id in ids:
		for o in objectives:
			if o["id"] == id and o["estado"] != "hecho":
				return false
	return true


## Disparador "obra" (`valor`: un tipo de edificio, o "hito"): el jugador empezó a levantar uno.
## Sirve para usar la espera de una obra larga (el hito del tutorial tarda unos minutos).
func _obras() -> void:
	var want := false
	for e in triggers:
		if not e["hecho"] and not e.has("listo") and e["cuando"]["tipo"] == "obra":
			want = true
			break
	if not want:
		return
	var seen := {}
	for b in sim.actives:
		if b.alive and b.owner == 0 and b.is_building() and not b.built:
			seen[b.type] = true
			if b.def.get("hito", false) or b.def.get("avanza_edad", false):
				seen["hito"] = true
	for k in seen:
		_fire("obra", k)


## Disparador "agotado" (`valor`: un tipo de recurso del mapa; `radio`, en casillas alrededor de la
## capital; `quedan`, cuántos con algo pueden quedar): se acaba esa fuente cerca de casa. El
## tutorial lo usa para pedir una granja cuando se acaban los frutos (jugador nuevo, ronda 4:
## sin granjas, el principiante quedaba con la mitad de los aldeanos ociosos).
func _agotados() -> void:
	if sim.tick % 50 != 0:
		return
	var cap: SimEntity = null
	for e in triggers:
		if e["hecho"] or e.has("listo") or e["cuando"]["tipo"] != "agotado":
			continue
		if cap == null:
			cap = _capital(0)
			if cap == null:
				return
		var c: Dictionary = e["cuando"]
		var r := int(c.get("radio", 16)) * P
		var left := 0
		for res in sim.entities:
			if res.alive and res.is_resource() and res.type == String(c.get("valor", "")) and res.amount > 0 and absi(res.x - cap.x) <= r and absi(res.y - cap.y) <= r:
				left += 1
		if left <= int(c.get("quedan", 0)):
			_fire("agotado", c.get("valor", ""))


func _check_end() -> void:
	if sim.players[0]["defeated"]:
		if motivo == "":
			motivo = "Tu pueblo fue derrotado."
		_finish("derrota")
		return
	var all_done := true
	for o in objectives:
		if o.get("secundario", false):
			continue
		if o["estado"] == "fallado":
			if motivo == "":
				motivo = "No se cumplió: %s" % o["texto"]
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
	sim.events.append({"t": "mision", "resultado": r, "motivo": motivo})


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
		if (kind == "objetivo" or kind == "obra" or kind == "agotado") and String(c.get("valor", "")) != String(value):
			continue
		if int(c.get("espera", 0)) > 0:
			if not e.has("listo"):
				e["listo"] = sim.tick + int(c["espera"]) * 1000 / sim.tick_ms
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
			_attack(int(pr.get("jugador", 1)), pr["tipo"], int(pr.get("n", 1)), int(pr.get("distancia", 0)))
		"recursos":
			for k in pr:
				sim.players[0]["res"][k] = int(sim.players[0]["res"].get(k, 0)) + int(pr[k])
		"revelar":
			var g: PackedByteArray = sim.fog.grids[0]
			for i in g.size():
				if g[i] == 0:
					g[i] = 1
		"cuenta":
			# Cuenta regresiva a la vista (la interfaz la muestra grande, arriba al centro).
			cuenta = {"texto": pr.get("texto", ""), "fin": sim.tick + int(pr.get("segundos", 60)) * 1000 / sim.tick_ms}
		"objetivo_nuevo":
			for o in objectives:
				if o["id"] == pr.get("id", "") and o["estado"] == "oculto":
					o["estado"] = "activo"
					o["desde"] = sim.tick
					o["base"] = _gathered(0)
					o["base_entrenadas"] = trained.duplicate()
					sim.events.append({"t": "objetivo", "id": o["id"], "estado": "nuevo", "texto": o["texto"]})


## Una columna aparece en el borde del mapa del lado del rival y avanza sobre la capital del jugador.
## Con `dist` (casillas), aparece a esa distancia de la capital, en dirección al rival: así
## el aviso "llegan en 60 s" se cumple.
func _attack(who: int, type: String, n: int, dist: int = 0) -> void:
	if who <= 0 or who >= sim.players.size():
		return
	var target := _capital(0)
	if target == null:
		return
	var base: Vector2i = sim.bases[who % 4] + Vector2i(2, 2)
	var nn := sim.map.n
	var edge := Vector2i(clampi(base.x + signi(base.x - nn / 2) * 20, 2, nn - 3), clampi(base.y + signi(base.y - nn / 2) * 20, 2, nn - 3))
	if dist > 0:
		var tt := Vector2i(target.tx, target.ty)
		var d := base - tt
		var len := maxi(1, Sim.isqrt(d.x * d.x + d.y * d.y))
		edge = Vector2i(clampi(tt.x + d.x * dist / len, 2, nn - 3), clampi(tt.y + d.y * dist / len, 2, nn - 3))
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


## Total juntado por recurso (libro de orígenes de la simulación).
func _gathered(pid: int) -> Dictionary:
	var out := {}
	var book: Dictionary = sim.players[pid]["stats"].get("origen", {})
	for o in book:
		for k in book[o]:
			out[k] = int(out.get(k, 0)) + int(book[o][k])
	return out


## Segundos que le quedan a la cuenta regresiva de la misión (-1 si no hay).
func cuenta_s() -> int:
	if cuenta.is_empty():
		return -1
	return maxi(0, (int(cuenta["fin"]) - sim.tick) * sim.tick_ms / 1000)


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
