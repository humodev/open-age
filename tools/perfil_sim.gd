extends SceneTree
## Perfilador reproducible de la simulación (proceso/32-ronda-8/04-rendimiento.md).
## Partidas IA contra IA armadas como la partida a medida (proceso/31): 1 contra 6 y 4 contra 4,
## 40 minutos, en modo headless. Mide por tick el tiempo propio de cada sistema (sin contar lo
## que llama adentro): IA (cada `think`), caminos (find_path), grupos, movimiento, blancos
## (find_enemy), combate, recolección, find_resource, edificios, separación, tablas, niebla,
## telemetría y el resto. Da promedio, p95 y peor tick, en qué tick y qué sistema hizo cada pico,
## y hasta qué minuto alcanza ×4 (cuatro ticks por cada 100 ms: 25 ms por tick).
##
## El reloj se mide desde afuera: subclases de Sim, SimAI, SimMap, SimGroups y SimTelemetry que
## envuelven los métodos. No cambian el resultado: el hash final es el mismo que con --plano.
##
## Uso:
##   godot --headless --path . -s tools/perfil_sim.gd -- [--partida=1v6|4v4|ambas] [--minutos=40]
##         [--semilla=42] [--picos=12] [--plano]
## --plano: sin envoltorios, solo el tiempo total de cada tick (para comparar con lo medido).

const CIVS := ["guaranies", "mapuches", "etiopia", "palmares", "ayutthaya", "tawantinsuyu"]
## [dificultad, equipo] por lugar. El 0 es la IA que ocupa el lugar de «vos» (experta).
const PARTIDAS := {
	"1v6": [["experta", 0], ["experta", 1], ["experta", 1], ["dificil", 1], ["dificil", 1], ["normal", 1], ["normal", 1]],
	"4v4": [["experta", 0], ["dificil", 0], ["dificil", 0], ["normal", 0], ["experta", 1], ["dificil", 1], ["dificil", 1], ["normal", 1]],
}
const SECCIONES := ["ia", "caminos", "grupos", "movimiento", "blancos", "combate", "recoleccion", "find_resource", "edificios", "separacion", "tablas", "jugadores", "niebla", "telemetria", "ordenes", "segundo", "animales", "victoria", "resto"]


## Reloj con pila: cada sección se lleva su tiempo propio (lo de adentro va a la sección de adentro).
class Prof:
	static var on := false
	static var cur := {} # sección -> µs propios en este tick
	static var _t0 := PackedInt64Array()
	static var _child := PackedInt64Array()
	static var _name: Array[String] = []
	static var ai_us := PackedInt64Array() # µs de think por jugador en este tick

	static func enter(n: String) -> void:
		_t0.append(Time.get_ticks_usec())
		_child.append(0)
		_name.append(n)

	static func leave() -> void:
		var i := _t0.size() - 1
		var el := Time.get_ticks_usec() - _t0[i]
		var n: String = _name[i]
		cur[n] = int(cur.get(n, 0)) + el - _child[i]
		_t0.resize(i)
		_child.resize(i)
		_name.resize(i)
		if i > 0:
			_child[i - 1] += el


class PSim extends Sim:
	func _update_unit(e: SimEntity) -> void:
		Prof.enter("movimiento"); super(e); Prof.leave()
	func _update_building(b: SimEntity) -> void:
		Prof.enter("edificios"); super(b); Prof.leave()
	func _path_for(e: SimEntity, from: Vector2i, to: Vector2i) -> Array[Vector2i]:
		Prof.enter("caminos"); var r = super(e, from, to); Prof.leave(); return r
	func find_enemy(e: SimEntity, radius: int, units_only: bool) -> SimEntity:
		Prof.enter("blancos"); var r = super(e, radius, units_only); Prof.leave(); return r
	func _do_attack(e: SimEntity) -> void:
		Prof.enter("combate"); super(e); Prof.leave()
	func _do_hold(e: SimEntity) -> void:
		Prof.enter("combate"); super(e); Prof.leave()
	func _aura_combat() -> void:
		Prof.enter("combate"); super(); Prof.leave()
	func _do_gather(e: SimEntity) -> void:
		Prof.enter("recoleccion"); super(e); Prof.leave()
	func _do_return(e: SimEntity) -> void:
		Prof.enter("recoleccion"); super(e); Prof.leave()
	func _do_build(e: SimEntity) -> void:
		Prof.enter("recoleccion"); super(e); Prof.leave()
	func find_resource(owner: int, kind: String, x: int, y: int, max_d: int, exclude: int = -1, worker: int = -1, only_type: String = "") -> SimEntity:
		Prof.enter("find_resource"); var r = super(owner, kind, x, y, max_d, exclude, worker, only_type); Prof.leave(); return r
	func nearest_dropoff(owner: int, kind: String, x: int, y: int) -> SimEntity:
		Prof.enter("find_resource"); var r = super(owner, kind, x, y); Prof.leave(); return r
	func _separate() -> void:
		Prof.enter("separacion"); super(); Prof.leave()
	func _rebuild_hashes() -> void:
		Prof.enter("tablas"); super(); Prof.leave()
	func _update_players() -> void:
		Prof.enter("jugadores"); super(); Prof.leave()
	func _update_fog(pid: int) -> void:
		Prof.enter("niebla"); super(pid); Prof.leave()
	func _apply(c: Dictionary) -> void:
		Prof.enter("ordenes"); super(c); Prof.leave()
	func _aura_heal() -> void:
		Prof.enter("segundo"); super(); Prof.leave()
	func _wonders() -> void:
		Prof.enter("segundo"); super(); Prof.leave()
	func _claim_animals() -> void:
		Prof.enter("animales"); super(); Prof.leave()
	func _check_victory() -> void:
		Prof.enter("victoria"); super(); Prof.leave()


class PAI extends SimAI:
	func think() -> void:
		var t := Time.get_ticks_usec()
		Prof.enter("ia"); super(); Prof.leave()
		if Prof.ai_us.size() > player:
			Prof.ai_us[player] += Time.get_ticks_usec() - t


## --ia-detalle: el tiempo de la IA repartido por parte de `think` (secciones ia.*).
class PAIDet extends PAI:
	func _levels(p: Dictionary, army: Array[SimEntity], by_type: Dictionary, saving: bool, threatened: bool) -> Dictionary:
		Prof.enter("ia._levels"); var r = super(p, army, by_type, saving, threatened); Prof.leave(); return r
	func _smith(p: Dictionary, army: Array[SimEntity], by_type: Dictionary, saving: bool) -> Dictionary:
		Prof.enter("ia._smith"); var r = super(p, army, by_type, saving); Prof.leave(); return r
	func _research(p: Dictionary, by_type: Dictionary, saving: bool) -> void:
		Prof.enter("ia._research"); super(p, by_type, saving); Prof.leave()
	func _late_buys(p: Dictionary, army: Array[SimEntity], by_type: Dictionary, saving: bool, threatened: bool) -> Dictionary:
		Prof.enter("ia._late_buys"); var r = super(p, army, by_type, saving, threatened); Prof.leave(); return r
	func _own_buys(p: Dictionary, army: Array[SimEntity], by_type: Dictionary, saving: bool, centro: SimEntity) -> Dictionary:
		Prof.enter("ia._own_buys"); var r = super(p, army, by_type, saving, centro); Prof.leave(); return r
	func _dig_traps(p: Dictionary, vill: Array[SimEntity], centro: SimEntity, by_type: Dictionary, saving: bool) -> void:
		Prof.enter("ia._dig_traps"); super(p, vill, centro, by_type, saving); Prof.leave()
	func _alarm(p: Dictionary, vill: Array[SimEntity], army: Array[SimEntity], centro: SimEntity) -> void:
		Prof.enter("ia._alarm"); super(p, vill, army, centro); Prof.leave()
	func _surrenders(by_type: Dictionary, centro: SimEntity) -> bool:
		Prof.enter("ia._surrenders"); var r = super(by_type, centro); Prof.leave(); return r
	func _economy(p: Dictionary, vill: Array[SimEntity], centro: SimEntity, saving: bool) -> void:
		Prof.enter("ia._economy"); super(p, vill, centro, saving); Prof.leave()
	func _engine(p: Dictionary, vill: Array[SimEntity], centro: SimEntity, by_type: Dictionary, saving: bool) -> void:
		Prof.enter("ia._engine"); super(p, vill, centro, by_type, saving); Prof.leave()
	func _buildings(p: Dictionary, vill: Array[SimEntity], centro: SimEntity, by_type: Dictionary, saving: bool) -> void:
		Prof.enter("ia._buildings"); super(p, vill, centro, by_type, saving); Prof.leave()
	func _watch_rival_army() -> void:
		Prof.enter("ia._watch_rival_army"); super(); Prof.leave()
	func _production(p: Dictionary, vill: Array[SimEntity], army: Array[SimEntity], centro: SimEntity, by_type: Dictionary, saving: bool) -> void:
		Prof.enter("ia._production"); super(p, vill, army, centro, by_type, saving); Prof.leave()
	func _threat(centro: SimEntity) -> SimEntity:
		Prof.enter("ia._threat"); var r = super(centro); Prof.leave(); return r
	func _military(army: Array[SimEntity], centro: SimEntity) -> void:
		Prof.enter("ia._military"); super(army, centro); Prof.leave()
	func _attack(army: Array[SimEntity]) -> void:
		Prof.enter("ia._attack"); super(army); Prof.leave()
	func _animals(centro: SimEntity) -> void:
		Prof.enter("ia._animals"); super(centro); Prof.leave()
	func _tribute(p: Dictionary, saving: bool) -> void:
		Prof.enter("ia._tribute"); super(p, saving); Prof.leave()
	func _requests(p: Dictionary) -> void:
		Prof.enter("ia._requests"); super(p); Prof.leave()
	func _flares(army: Array[SimEntity], centro: SimEntity) -> void:
		Prof.enter("ia._flares"); super(army, centro); Prof.leave()
	func _trade(p: Dictionary, by_type: Dictionary) -> void:
		Prof.enter("ia._trade"); super(p, by_type); Prof.leave()
	func _avoid_sites(army: Array[SimEntity]) -> void:
		Prof.enter("ia._avoid_sites"); super(army); Prof.leave()


class PMap extends SimMap:
	func find_path(from: Vector2i, to: Vector2i, pid: int = -1) -> Array[Vector2i]:
		Prof.enter("caminos"); var r = super(from, to, pid); Prof.leave(); return r
	func find_boat_path(from: Vector2i, to: Vector2i) -> Array[Vector2i]:
		Prof.enter("caminos"); var r = super(from, to); Prof.leave(); return r


class PGroups extends SimGroups:
	func tick() -> void:
		Prof.enter("grupos"); super(); Prof.leave()


class PMods extends SimMods:
	func tick_second() -> void:
		Prof.enter("segundo"); super(); Prof.leave()


class PTele extends SimTelemetry:
	func check_idle(sim: Sim) -> void:
		Prof.enter("telemetria"); super(sim); Prof.leave()


## Copia las variables de script de `from` en `to` (mismo estado, otra clase).
static func _copy(from: Object, to: Object) -> void:
	for p in from.get_property_list():
		if int(p["usage"]) & PROPERTY_USAGE_SCRIPT_VARIABLE:
			to.set(p["name"], from.get(p["name"]))


func _make(nombre: String, semilla: int, plano: bool, ia_det: bool) -> Sim:
	var lug: Array = PARTIDAS[nombre]
	var opts := {"terreno": "llano", "civs": [], "equipos": [], "tiempo_limite_min": 60, "ubicacion_equipos": "juntos"}
	for i in lug.size():
		opts["civs"].append(CIVS[(i + semilla) % CIVS.size()])
		opts["equipos"].append(lug[i][1])
	var s: Sim = Sim.new(semilla, lug.size(), null, opts) if plano else PSim.new(semilla, lug.size(), null, opts)
	if not plano:
		var m := PMap.new(8, 1)
		_copy(s.map, m)
		s.map = m
		s.fog.map = m
		var g := PGroups.new(s)
		_copy(s.groups, g)
		s.groups = g
		var md := PMods.new(s)
		_copy(s.mods, md)
		s.mods = md
		var t := PTele.new()
		_copy(s.tele, t)
		s.tele = t
	s.ais = []
	for pid in lug.size():
		var ai: SimAI = SimAI.new(s, pid, lug[pid][0]) if plano else (PAIDet.new(s, pid, lug[pid][0]) if ia_det else PAI.new(s, pid, lug[pid][0]))
		s.ais.append(ai)
	return s


func _init() -> void:
	var args := {}
	for a in OS.get_cmdline_user_args():
		var kv := a.trim_prefix("--").split("=", true, 1)
		args[kv[0]] = kv[1] if kv.size() > 1 else "1"
	var cual := str(args.get("partida", "ambas"))
	var lista: Array = ["1v6", "4v4"] if cual == "ambas" else [cual]
	for nombre in lista:
		_run(nombre, int(args.get("semilla", "42")), int(args.get("minutos", "40")), int(args.get("picos", "12")), args.has("plano"), args.has("ia-detalle"))
	quit()


func _run(nombre: String, semilla: int, minutos: int, n_picos: int, plano: bool, ia_det: bool) -> void:
	var s := _make(nombre, semilla, plano, ia_det)
	var ia_sub := {} # ia.* -> [µs total, peor µs en un tick]
	var n_ticks := minutos * 60000 / s.tick_ms
	var tpm := 60000 / s.tick_ms
	var np := s.players.size()
	var total := PackedInt32Array()
	total.resize(n_ticks)
	var NS := SECCIONES.size()
	var plano_s := PackedInt32Array() # tick * NS + sección (los arreglos empacados se copian: uno solo)
	plano_s.resize(n_ticks * NS)
	var ia_pid := PackedInt32Array() # el jugador que más pensó en el tick
	ia_pid.resize(n_ticks)
	var hecho := 0
	var t_reloj := Time.get_ticks_msec()
	for i in n_ticks:
		if s.game_over:
			break
		Prof.cur = {}
		Prof.ai_us = PackedInt64Array()
		Prof.ai_us.resize(np)
		Prof.ai_us.fill(0)
		var t0 := Time.get_ticks_usec()
		s.step()
		var dt := Time.get_ticks_usec() - t0
		total[i] = dt
		var suma := 0
		for k: String in Prof.cur:
			var v := int(Prof.cur[k])
			var si := SECCIONES.find(k)
			if si < 0: # ia.*: va a la IA en la tabla y se detalla aparte
				si = 0
				var acc: Array = ia_sub.get(k, [0, 0])
				ia_sub[k] = [acc[0] + v, maxi(acc[1], v)]
			plano_s[i * NS + si] += v
			suma += v
		plano_s[i * NS + NS - 1] = maxi(0, dt - suma)
		var best := 0
		for pid in np:
			if Prof.ai_us[pid] > Prof.ai_us[best]:
				best = pid
		ia_pid[i] = best
		hecho = i + 1
	var reloj_s := (Time.get_ticks_msec() - t_reloj) / 1000.0
	var unidades := 0
	for e in s.entities:
		if e.alive and e.is_unit():
			unidades += 1
	print("")
	print("=== %s · semilla %d · %d ticks (%.1f min de juego) en %.0f s de reloj%s ===" % [nombre, semilla, hecho, hecho / float(tpm), reloj_s, " · PLANO" if plano else ""])
	print("hash final %d · unidades vivas %d · fin: %s (ganador equipo %d)" % [s.state_hash(), unidades, s.end_reason if s.game_over else "sigue", s.winner_team])
	total.resize(hecho)
	print("TICK      promedio %6.2f ms · p95 %6.2f · peor %7.2f (tick %d, min %.1f) · >25 ms: %d · >40: %d · >100: %d" % [_avg(total), _pct(total, 95), _max(total) / 1000.0, _argmax(total), _argmax(total) / float(tpm), _over(total, 25000), _over(total, 40000), _over(total, 100000)])
	if not plano:
		var por := {}
		for k in NS:
			var a := PackedInt32Array()
			a.resize(hecho)
			for i in hecho:
				a[i] = plano_s[i * NS + k]
			por[SECCIONES[k]] = a
		print("%-14s %8s %8s %8s %8s" % ["sistema", "prom ms", "p95 ms", "peor ms", "% total"])
		var tot_sum := 0
		for v in total:
			tot_sum += v
		var orden := SECCIONES.duplicate()
		orden.sort_custom(func(a: String, b: String) -> bool: return _sum(por[a], hecho) > _sum(por[b], hecho))
		for k in orden:
			var a: PackedInt32Array = por[k]
			print("%-14s %8.2f %8.2f %8.2f %7.1f%%" % [k, _avg(a), _pct(a, 95), _max(a) / 1000.0, 100.0 * _sum(a, hecho) / maxf(1.0, tot_sum)])
		# Picos: los n peores ticks, con el sistema que más pesó.
		var idx := range(hecho)
		idx.sort_custom(func(a: int, b: int) -> bool: return total[a] > total[b])
		if not ia_sub.is_empty():
			var ks := ia_sub.keys()
			ks.sort_custom(func(a: String, b: String) -> bool: return ia_sub[a][0] > ia_sub[b][0])
			var l := "IA por parte (prom ms/tick · peor ms):"
			for k: String in ks:
				l += " %s %.2f·%.1f" % [k.trim_prefix("ia."), ia_sub[k][0] / 1000.0 / hecho, ia_sub[k][1] / 1000.0]
			print(l)
		print("Picos (tick · min · total ms · sistema que más pesó · segundo):")
		for j in mini(n_picos, idx.size()):
			var i: int = idx[j]
			var parts: Array = []
			for k in SECCIONES:
				parts.append([k, plano_s[i * NS + SECCIONES.find(k)]])
			parts.sort_custom(func(a: Array, b: Array) -> bool: return a[1] > b[1])
			var n0: String = parts[0][0]
			if n0 == "ia":
				n0 = "ia (j%d)" % ia_pid[i]
			print("  %6d  %5.1f  %7.2f  %-16s %6.2f · %s %.2f" % [i, i / float(tpm), total[i] / 1000.0, n0, parts[0][1] / 1000.0, parts[1][0], parts[1][1] / 1000.0])
	# Por minuto: promedio y peor; ×4 alcanza mientras el promedio del minuto quede bajo 25 ms.
	var hasta := -1
	var linea := "por minuto (prom/peor ms):"
	for m in ceili(hecho / float(tpm)):
		var sl := total.slice(m * tpm, mini(hecho, (m + 1) * tpm))
		if hasta == m - 1 and _avg(sl) < 25.0:
			hasta = m
		if m % 5 == 4 or m == ceili(hecho / float(tpm)) - 1:
			linea += " m%d %.1f/%.0f" % [m + 1, _avg(sl), _max(sl) / 1000.0]
	print(linea)
	print("×4 alcanza (promedio del minuto < 25 ms) hasta el minuto %d de %d" % [hasta + 1, ceili(hecho / float(tpm))])
	s.soltar()


static func _avg(a: PackedInt32Array) -> float:
	return _sum(a, a.size()) / 1000.0 / maxi(1, a.size())


static func _sum(a: PackedInt32Array, n: int) -> int:
	var t := 0
	for i in mini(n, a.size()):
		t += a[i]
	return t


static func _pct(a: PackedInt32Array, p: int) -> float:
	if a.is_empty():
		return 0.0
	var b := a.duplicate()
	b.sort()
	return b[mini(b.size() - 1, b.size() * p / 100)] / 1000.0


static func _max(a: PackedInt32Array) -> int:
	var m := 0
	for v in a:
		m = maxi(m, v)
	return m


static func _argmax(a: PackedInt32Array) -> int:
	var m := 0
	for i in a.size():
		if a[i] > a[m]:
			m = i
	return m


static func _over(a: PackedInt32Array, us: int) -> int:
	var c := 0
	for v in a:
		if v > us:
			c += 1
	return c


func _finalize() -> void:
	Sim.soltar_todas()
