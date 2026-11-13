extends RefCounted
## Lo que los paneles saben de la partida. Solo lee la simulación: nunca llama a
## funciones que la modifiquen (ni siquiera `disputed_room`, que crea sus baldes
## y cambiaría el hash del estado). Muestrea desde la interfaz.

const C := preload("res://src/game/ui/panel_comun.gd")

var sim: Sim
var local: int
var cfg: Dictionary = {}
var sample_s := 30
var window_s := 60
var log_max := 80

## Muestras cada `sample_s` segundos: {"t": s, "p": [por jugador {...}]}.
var samples: Array = []
## Edades alcanzadas: {"t": s, "player": pid, "age": n, "hito": clave}.
var ages: Array = []
## Registro de sucesos: {"t": s, "txt", "col", "x", "y", "kind"} (x, y en milésimas; -1 sin lugar).
var log: Array = []
var log_unread := 0
var built := [] # edificios terminados por jugador
var lost_b := [] # edificios perdidos por jugador
var razed := [] # edificios enemigos destruidos por jugador

var _ring: Array = [] # una foto por segundo: {"tick", "tot": [por jugador {recurso: n}], "org": {origen: {recurso: n}} del local}
var _fight := {} # combate en curso, para resumir bajas en el registro


func _init(s: Sim, local_player: int) -> void:
	sim = s
	local = local_player
	var path := "res://data/interfaz.json"
	if FileAccess.file_exists(path):
		cfg = JSON.parse_string(FileAccess.get_file_as_string(path))
	sample_s = int(cfg.get("muestreo_s", 30))
	window_s = int(cfg.get("ventana_ingreso_s", 60))
	log_max = int(cfg.get("sucesos_max", 80))
	for p in sim.players:
		built.append(0)
		lost_b.append(0)
		razed.append(0)
	for p in sim.players:
		if int(p["age"]) > 1:
			ages.append({"t": 0, "player": p["id"], "age": int(p["age"]), "hito": ""})
	_photo()
	_sample()


func now_s() -> int:
	return sim.tick * sim.tick_ms / 1000


# ---------------------------------------------------------------- Lecturas

## Total juntado por recurso, sumando el libro de orígenes de la simulación.
func totals(pid: int) -> Dictionary:
	var out := {}
	var book: Dictionary = sim.players[pid]["stats"].get("origen", {})
	for o in book:
		for k in book[o]:
			out[k] = int(out.get(k, 0)) + int(book[o][k])
	return out


func origin_book(pid: int) -> Dictionary:
	return sim.players[pid]["stats"].get("origen", {})


## Ingreso por minuto de un recurso en la última ventana (la escala si la partida es más corta).
func rate(pid: int, k: String) -> int:
	if _ring.size() < 2:
		return 0
	var a: Dictionary = _ring[0]
	var b: Dictionary = _ring[-1]
	var dt: int = (int(b["tick"]) - int(a["tick"])) * sim.tick_ms
	if dt <= 0:
		return 0
	var d: int = int(b["tot"][pid].get(k, 0)) - int(a["tot"][pid].get(k, 0))
	return d * 60000 / dt


## Ingreso por minuto de un recurso desde un origen (jugador local).
func origin_rate(origin: String, k: String) -> int:
	if _ring.size() < 2:
		return 0
	var a: Dictionary = _ring[0]
	var b: Dictionary = _ring[-1]
	var dt: int = (int(b["tick"]) - int(a["tick"])) * sim.tick_ms
	if dt <= 0:
		return 0
	var d: int = int(b["org"].get(origin, {}).get(k, 0)) - int(a["org"].get(origin, {}).get(k, 0))
	return d * 60000 / dt


## Lo disputado, leído sin tocar la simulación: [usado, techo de la ventana, techo por minuto].
func disputed(pid: int) -> Array:
	var dc: Dictionary = sim.data.reglas.get("disputado", {})
	if dc.is_empty():
		return [0, 0, 0]
	var caps: Array = dc["tope_por_min"]
	var nb := int(dc["baldes"])
	var per_min := int(caps[clampi(int(sim.players[pid]["age"]) - 1, 0, caps.size() - 1)])
	var p: Dictionary = sim.players[pid]
	var used := 0
	if p.has("disp"):
		var ticks_min := 60000 / sim.tick_ms
		var minute := sim.tick / ticks_min
		var last := int(p["disp_min"])
		var arr: Array = p["disp"]
		if minute - last < nb:
			var stale := {}
			for m in range(last + 1, minute + 1):
				stale[m % nb] = true
			for i in arr.size():
				if not stale.has(i):
					used += int(arr[i])
	return [used, per_min * nb, per_min]


## Aldeanos por tarea del jugador.
func villagers(pid: int) -> Dictionary:
	var out := {"total": 0, "ociosos": 0, "construyendo": 0, "en marcha": 0, "refugiados": 0, "otros": 0}
	for e in sim.actives:
		if not e.alive or e.owner != pid or e.fn != "civil" or not e.is_unit():
			continue
		out["total"] += 1
		var key := "otros"
		if e.inside >= 0:
			key = "refugiados"
		elif e.order == SimEntity.Order.GATHER or e.order == SimEntity.Order.RETURN:
			key = e.gather_kind if e.gather_kind != "" else e.carry_res
			if key == "":
				key = "otros"
		elif e.order == SimEntity.Order.BUILD:
			key = "construyendo"
		elif e.order == SimEntity.Order.IDLE:
			key = "ociosos"
		elif e.order == SimEntity.Order.MOVE:
			key = "en marcha"
		out[key] = int(out.get(key, 0)) + 1
	return out


func army(pid: int) -> int:
	var n := 0
	for e in sim.actives:
		if e.alive and e.owner == pid and e.is_unit() and e.fn != "civil" and e.fn != "explorador":
			n += 1
	return n


func score(pid: int) -> int:
	var pc: Dictionary = cfg.get("puntaje", {})
	var p: Dictionary = sim.players[pid]
	var tot := 0
	var t := totals(pid)
	for k in t:
		tot += int(t[k])
	var s := tot / maxi(1, int(pc.get("recursos_por_punto", 10)))
	s += int(p["stats"]["bajas"]) * int(pc.get("por_baja", 0))
	s += int(razed[pid]) * int(pc.get("por_edificio_destruido", 0))
	s += (int(p["age"]) - 1) * int(pc.get("por_edad", 0))
	s += (p["techs"] as Dictionary).size() * int(pc.get("por_investigacion", 0))
	return s


func orders(pid: int) -> int:
	var n := 0
	var oc: Dictionary = sim.players[pid]["stats"].get("ordenes", {})
	for k in oc:
		n += int(oc[k])
	return n


func age_time(pid: int, age: int) -> int:
	for a in ages:
		if a["player"] == pid and a["age"] == age:
			return a["t"]
	return -1


# ---------------------------------------------------------------- Registro

func add_log(txt: String, col: Color, x: int = -1, y: int = -1, kind := "") -> void:
	log.append({"t": now_s(), "txt": txt, "col": col, "x": x, "y": y, "kind": kind})
	log_unread += 1
	while log.size() > log_max:
		log.pop_front()


func _name_of(type: String, pid: int) -> String:
	return sim.dp(pid).def_of(type).get("nombre", type)


func _minor(type: String, pid: int) -> bool:
	var d: Dictionary = sim.dp(pid).edificios.get(type, {})
	return d.get("linea", false) or d.get("camino", false) or type in ["empalizada", "puerta"]


# ---------------------------------------------------------------- Cada tick

func on_events(events: Array) -> void:
	for ev in events:
		var pid: int = ev.get("player", -2)
		match ev["t"]:
			"built":
				var b: SimEntity = sim.by_id.get(ev["id"])
				if pid >= 0 and pid < built.size():
					built[pid] += 1
				if b != null and pid == local and not _minor(b.type, pid):
					add_log("Edificio terminado: %s" % _name_of(b.type, pid), Palette.UI_TEXT, b.x, b.y, "edificio")
			"tech":
				if pid == local:
					add_log("Investigación terminada: %s" % sim.dp(pid).tecnologias[ev["tech"]]["nombre"], Palette.UI_ACCENT, -1, -1, "tech")
			"age":
				ages.append({"t": now_s(), "player": pid, "age": ev["age"], "hito": ev.get("hito", "")})
				var hdef: Dictionary = sim.dp(pid).edificios.get(ev.get("hito", ""), {})
				var eje: String = C.eje_of(hdef, ev.get("hito", ""))
				var b2: SimEntity = null
				for e in sim.actives:
					if e.alive and e.owner == pid and e.type == ev.get("hito", "") and e.built:
						b2 = e
				var who := "Llegaste" if pid == local else "%s llegó" % Palette.TEAM_NAMES[pid % Palette.TEAM_NAMES.size()]
				var where := b2 != null and (pid == local or sim.fog.is_explored(local, b2))
				add_log("%s a la edad %s con %s (%s)" % [who, Sim._roman(ev["age"]), hdef.get("nombre", "un hito"), C.EJE_NAMES.get(eje, eje).to_lower()], Palette.UI_ACCENT if pid == local else Palette.team(pid), b2.x if where else -1, b2.y if where else -1, "edad")
			"alert":
				if pid == local:
					add_log("¡Nos atacan!", Palette.UI_BAD, ev["x"], ev["y"], "ataque")
			"sitio":
				var site: SimEntity = sim.by_id.get(ev.get("id", -1))
				add_log("Sitio sagrado tomado por %s" % ("tu pueblo" if pid == local else Palette.TEAM_NAMES[pid % Palette.TEAM_NAMES.size()]), Palette.UI_GOOD if pid == local else Palette.UI_BAD, site.x if site != null else -1, site.y if site != null else -1, "sitio")
			"died":
				_on_died(ev)
			"defeat":
				add_log("%s fue derrotado" % ("Tu pueblo" if pid == local else Palette.TEAM_NAMES[pid % Palette.TEAM_NAMES.size()]), Palette.UI_BAD if pid == local else Palette.UI_GOOD, -1, -1, "fin")
	if sim.tick % maxi(1, 1000 / sim.tick_ms) == 0:
		_photo()
	if sim.tick % maxi(1, sample_s * 1000 / sim.tick_ms) == 0:
		_sample()
	if not _fight.is_empty() and sim.tick - int(_fight["last"]) > 8000 / sim.tick_ms:
		_flush_fight()


func _on_died(ev: Dictionary) -> void:
	var owner: int = ev.get("owner", -1)
	var by: int = ev.get("by", -1)
	if owner < 0:
		return
	if ev["cat"] == SimEntity.Cat.BUILDING:
		lost_b[owner] += 1
		if by >= 0 and by != owner:
			razed[by] += 1
		if _minor(ev["type"], owner):
			return
		if owner == local:
			add_log("Perdiste: %s" % _name_of(ev["type"], owner), Palette.UI_BAD, ev["x"], ev["y"], "perdida")
		elif by == local:
			add_log("Destruiste: %s" % _name_of(ev["type"], owner), Palette.UI_GOOD, ev["x"], ev["y"], "golpe")
		return
	if ev["cat"] != SimEntity.Cat.UNIT or (owner != local and by != local):
		return
	if _fight.is_empty():
		_fight = {"lost": 0, "lost_civ": 0, "killed": 0, "x": ev["x"], "y": ev["y"], "last": sim.tick}
	if owner == local:
		_fight["lost"] += 1
		if sim.dp(owner).unidades.get(ev["type"], {}).get("funcion", "") == "civil":
			_fight["lost_civ"] += 1
	else:
		_fight["killed"] += 1
	_fight["x"] = ev["x"]
	_fight["y"] = ev["y"]
	_fight["last"] = sim.tick


func _flush_fight() -> void:
	var f := _fight
	_fight = {}
	var parts: Array[String] = []
	if int(f["lost"]) > 0:
		var civ := " (%d aldeanos)" % f["lost_civ"] if int(f["lost_civ"]) > 0 else ""
		parts.append("perdiste %d%s" % [f["lost"], civ])
	if int(f["killed"]) > 0:
		parts.append("abatiste %d" % f["killed"])
	var col := Palette.UI_BAD if int(f["lost"]) > int(f["killed"]) else Palette.UI_GOOD
	add_log("Combate: " + ", ".join(parts), col, f["x"], f["y"], "combate")


func _photo() -> void:
	var tot: Array = []
	for p in sim.players:
		tot.append(totals(p["id"]))
	_ring.append({"tick": sim.tick, "tot": tot, "org": origin_book(local).duplicate(true)})
	var keep := window_s + 1
	while _ring.size() > keep:
		_ring.pop_front()


## Foto de cada jugador para los gráficos del final.
func _sample() -> void:
	var row: Array = []
	for p in sim.players:
		var pid: int = p["id"]
		var t := totals(pid)
		var sum := 0
		for k in t:
			sum += int(t[k])
		var bank := 0
		for k in Sim.RES_KINDS:
			bank += int(p["res"].get(k, 0))
		row.append({"pop": int(p["pop"]), "vill": villagers(pid)["total"], "army": army(pid), "juntado": sum, "riqueza": int(t.get("riqueza", 0)), "banco": bank, "score": score(pid), "age": int(p["age"])})
	if not samples.is_empty() and int(samples[-1]["t"]) == now_s():
		samples[-1]["p"] = row
		return
	samples.append({"t": now_s(), "p": row})


## Última foto al terminar la partida.
func close() -> void:
	if not _fight.is_empty():
		_flush_fight()
	_sample()
