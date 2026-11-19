extends SceneTree
## --- comercio --- Medidas del comercio (proceso/33-comercio, §5).
##
## Sin --partida: por terreno y mapa, la distancia de cada base a cada neutral y al aliado, la
## riqueza por viaje y por minuto (en la IV, sin saturación) y la equidad.
##   godot --headless --path . -s tools/comercio_medida.gd -- [--terrenos=llano,rio]
##
## Con --partida=1: IA contra IA sin vista; cada minuto la riqueza por fuente (libro «origen»:
## casa, disputado, comercio, mercado…), comerciantes vivos y muertos, rutas cortadas. Al final,
## las dos metas: en 1v1, comercio ≤ 15 % de la riqueza antes del minuto 25; en 2v2 de 45 min,
## 30–45 % de la riqueza después del 30.
##   godot --headless --path . -s tools/comercio_medida.gd -- --partida=1 [--min=30] [--seed=7]
##        [--terreno=llano] [--dif=experta] [--equipos=0,1] [--ubicacion=juntos] [--cada=5]

const P := 1000
const POOL := ["tawantinsuyu", "mapuches", "guaranies", "etiopia", "palmares", "ayutthaya", "tawantinsuyu", "mapuches"]


func _init() -> void:
	var args := {}
	for a in OS.get_cmdline_user_args():
		var kv := a.trim_prefix("--").split("=")
		args[kv[0]] = kv[1] if kv.size() > 1 else "1"
	if args.has("partida"):
		_match(args)
	else:
		_table(args)
	quit()


# ------------------------------------------------------------------ sin partida

func _table(args: Dictionary) -> void:
	var terr: PackedStringArray = str(args.get("terrenos", "llano,rio,bosque,montana,islas,altiplano")).split(",")
	var cases := [["1v1", 2, [0, 1], "normal"], ["2v2", 4, [0, 0, 1, 1], "normal"], ["2v2 grande", 4, [0, 0, 1, 1], "grande"], ["3v3", 6, [0, 0, 0, 1, 1, 1], "normal"], ["4v4", 8, [0, 0, 0, 0, 1, 1, 1, 1], "normal"], ["4 todos", 4, [0, 1, 2, 3], "normal"]]
	print("Por viaje y por minuto en la IV, sin saturación, desde un mercado a 8 casillas de la capital hacia el centro.")
	print("| Mapa | Terreno | L | Neutrales | d (cerca / lejos) | Por viaje | Por minuto | Aliado (d, por min) |")
	print("|---|---|---|---|---|---|---|---|")
	for cs in cases:
		for t in terr:
			var np: int = cs[1]
			var s := Sim.new(7, np, null, {"civs": POOL.slice(0, np), "equipos": cs[2], "ubicacion_equipos": "juntos", "terreno": t, "tamano": cs[3]})
			for p in s.players:
				p["age"] = 4
			var homes := []
			for pid in np:
				homes.append(_home(s, pid))
			var c: SimComercio = s.comercio
			var h: SimEntity = homes[0]
			if h == null or c.neutrals.is_empty():
				print("| %s | %s | %d | %d | – | – | – | – |" % [cs[0], t, s.map.n, c.neutrals.size()])
				continue
			var ds := []
			for m in c.neutrals:
				ds.append(SimComercio.octil(h, m))
			var near: SimEntity = c.neutrals[ds.find(ds.min())]
			var far: SimEntity = c.neutrals[ds.find(ds.max())]
			var g1 := c.gain(0, h, near)
			var g2 := c.gain(0, h, far)
			var ally := "–"
			for q in range(1, np):
				if not s.enemies(0, q) and homes[q] != null:
					var ga := c.gain(0, h, homes[q])
					ally = "%d, %d" % [SimComercio.octil(h, homes[q]), ga * 60000 / c.trip_ms(0, h, homes[q])]
					break
			print("| %s | %s | %d | %d | %d / %d | %d / %d | %d / %d | %s |" % [cs[0], t, s.map.n, c.neutrals.size(), ds.min(), ds.max(), g1, g2, g1 * 60000 / c.trip_ms(0, h, near), g2 * 60000 / c.trip_ms(0, h, far), ally])


## Mercado de `pid` a 8 casillas de su capital hacia el centro (o el primer lugar libre).
func _home(s: Sim, pid: int) -> SimEntity:
	var b: Vector2i = s.bases[pid] + Vector2i(2, 2)
	var c := Vector2i(s.map.n / 2, s.map.n / 2)
	var d := Vector2i(signi(c.x - b.x), signi(c.y - b.y))
	for r in 20:
		for k in range(-r, r + 1):
			var t := b + d * 8 + Vector2i(k, r - absi(k))
			if s.map.is_free_rect(t.x - 1, t.y - 1, 5, 5) and not s.map.is_water(t.x, t.y):
				return s.spawn_building("mercado", pid, t.x, t.y, true)
	return null


# ------------------------------------------------------------------ partida

func _match(args: Dictionary) -> void:
	var minutes := int(args.get("min", "30"))
	var sd := int(args.get("seed", "7"))
	var terr := str(args.get("terreno", "llano"))
	var dif := str(args.get("dif", "experta"))
	var every := int(args.get("cada", "5"))
	var teams: Array = Array(str(args.get("equipos", "0,1")).split(",")).map(func(x: String) -> int: return int(x))
	var np := teams.size()
	var s := Sim.new(sd, np, null, {"civs": POOL.slice(0, np), "equipos": teams, "ubicacion_equipos": str(args.get("ubicacion", "juntos")), "terreno": terr})
	s.ais = []
	for pid in np:
		s.ais.append(SimAI.new(s, pid, dif))
	print("Partida %s, %s, %s, semilla %d, mapa %d, %d neutrales, %d min" % [str(teams), terr, dif, sd, s.map.n, s.comercio.neutrals.size(), minutes])
	var snaps := {} # minuto -> por jugador [riqueza total, comercio]
	var first_trade := []
	first_trade.resize(np)
	first_trade.fill(-1)
	while s.tick < minutes * 600 and not s.game_over:
		s.step()
		if s.tick % 600 != 0:
			continue
		var mn := s.tick / 600
		var row := []
		for pid in np:
			var w := _wealth(s, pid)
			row.append(w)
			if w[1] > 0 and first_trade[pid] < 0:
				first_trade[pid] = mn
		snaps[mn] = row
		if mn % every == 0:
			var line := "  %2d min:" % mn
			for pid in np:
				var st: Dictionary = s.comercio.stats.get(pid, {})
				var alive := 0
				for e in s.owned(pid):
					if e.alive and e.is_unit() and e.def.get("comerciante", false):
						alive += 1
				line += "  J%d e%d riq %d com %d (%d vivos, %d muertos, %d cortes)" % [pid, s.players[pid]["age"], row[pid][0], row[pid][1], alive, int(st.get("muertos", 0)), int(st.get("cortes", 0))]
			print(line)
	var last: int = s.tick / 600
	print("Primer cobro (min): %s; fin al min %d%s" % [str(first_trade), last, " (terminó: gana el equipo %d)" % s.winner_team if s.game_over else ""])
	# Meta 1: hasta el minuto 25. Meta 2: después del 30.
	var m25 := mini(25, last)
	if snaps.has(m25):
		var tot := 0
		var com := 0
		for pid in np:
			tot += int(snaps[m25][pid][0])
			com += int(snaps[m25][pid][1])
		print("META 1 (antes del min %d): comercio %d de %d de riqueza = %d %% (meta ≤ 15 %%)" % [m25, com, tot, com * 100 / maxi(1, tot)])
	if last > 30 and snaps.has(30):
		var tot := 0
		var com := 0
		for pid in np:
			tot += int(snaps[last][pid][0]) - int(snaps[30][pid][0])
			com += int(snaps[last][pid][1]) - int(snaps[30][pid][1])
		print("META 2 (del min 30 al %d): comercio %d de %d de riqueza = %d %% (meta 30–45 %%)" % [last, com, tot, com * 100 / maxi(1, tot)])
	var killed := 0
	for pid in np:
		killed += int(s.comercio.stats.get(pid, {}).get("muertos", 0))
	print("Comerciantes muertos en total: %d (meta: alguna ruta atacada, > 10 en el 2v2)" % killed)


## [riqueza ingresada por todas las fuentes, por comercio] del libro «origen».
func _wealth(s: Sim, pid: int) -> Array:
	var book: Dictionary = s.players[pid]["stats"].get("origen", {})
	var tot := 0
	for k in book:
		tot += int((book[k] as Dictionary).get("riqueza", 0))
	return [tot, int((book.get("comercio", {}) as Dictionary).get("riqueza", 0))]


func _finalize() -> void:
	Sim.soltar_todas()
