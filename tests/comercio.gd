extends SceneTree
## --- comercio --- Pruebas del comercio (proceso/33-comercio): la fórmula en cinco distancias,
## el propio al 50 %, el aliado +20 %, la saturación, el cobro al volver, que no cuenta para lo
## disputado, el mercado tomado por presencia, la muralla que corta el camino y los avisos.
## Uso: godot --headless --path . -s tests/comercio.gd

const P := 1000
var fails := 0


func _check(ok: bool, what: String) -> void:
	print(("  ok   " if ok else "  FALLA ") + what)
	if not ok:
		fails += 1


func _init() -> void:
	_formula()
	_saturation()
	_trip_and_pay()
	_ally()
	_blocked()
	_walled()
	print("COMERCIO: ", "OK" if fails == 0 else "%d fallas" % fails)
	quit(0 if fails == 0 else 1)


## Partida sin IA, sin animales; el jugador 0 en la edad `age`.
func _sim(np: int = 2, opts: Dictionary = {}, age: int = 4) -> Sim:
	var o := {"terreno": "llano", "sin_animales": true}
	o.merge(opts, true)
	var s := Sim.new(77, np, null, o)
	for p in s.players:
		p["age"] = age
	return s


## Un edificio terminado de `pid` en el primer lugar libre cerca de (tx, ty).
func _put(s: Sim, type: String, pid: int, tx: int, ty: int) -> SimEntity:
	for r in 30:
		for dy in range(-r, r + 1):
			for dx in range(-r, r + 1):
				if maxi(absi(dx), absi(dy)) != r:
					continue
				var x := tx + dx
				var y := ty + dy
				if s.map.is_free_rect(x - 1, y - 1, 5, 5) and not s.map.is_water(x, y):
					return s.spawn_building(type, pid, x, y, true)
	return null


func _trader(s: Sim, pid: int, near: SimEntity) -> SimEntity:
	var t := s.map.nearest_free(near.tx + 1, near.ty + 4, 6, pid)
	return s.spawn_unit("comerciante", pid, t.x * P + P / 2, t.y * P + P / 2)


func _step_until(s: Sim, cond: Callable, max_ticks: int) -> bool:
	for i in max_ticks:
		s.step()
		if cond.call():
			return true
	return false


# ------------------------------------------------------------------ fórmula

func _formula() -> void:
	print("Fórmula G = d·(d·A/L + B)/100 (A 220, B 10) y la tabla del diseño (§2):")
	var s := _sim()
	var c: SimComercio = s.comercio
	for row in [[30, 128, 18], [60, 128, 68], [90, 128, 148], [120, 176, 192], [170, 240, 282]]:
		var g := c.formula(row[0], row[1])
		_check(absi(g - int(row[2])) <= 2, "d %d, L %d: %d (diseño ~%d)" % [row[0], row[1], g, row[2]])
	# Propio al 50 % y edad III al 70 %: dos mercados propios y un neutral.
	var home := _put(s, "mercado", 0, s.bases[0].x + 8, s.bases[0].y)
	var other := _put(s, "mercado", 0, s.bases[0].x, s.bases[0].y + 30)
	var d := SimComercio.octil(home, other)
	var full := c.formula(d, s.map.n)
	_check(c.gain(0, home, other, 4) == full * 50 / 100, "propio al 50 %%: %d de %d (d %d)" % [c.gain(0, home, other, 4), full, d])
	var neu: SimEntity = c.neutrals[0]
	var dn := SimComercio.octil(home, neu)
	_check(c.gain(0, home, neu, 4) == c.formula(dn, s.map.n), "neutral al 100 %% en la IV: %d (d %d)" % [c.gain(0, home, neu, 4), dn])
	_check(c.gain(0, home, neu, 3) == c.formula(dn, s.map.n) * 70 / 100, "neutral al 70 %% en la III: %d" % c.gain(0, home, neu, 3))
	_check(c.gain(0, home, neu, 2) == 0, "en la II, nada")
	var enemy := _put(s, "mercado", 1, s.bases[1].x - 6, s.bases[1].y)
	_check(c.dest_kind(0, enemy) == "", "con el mercado enemigo no se comercia")
	_check(s.comercio.neutrals.size() >= 2, "hay %d neutrales" % s.comercio.neutrals.size())


func _saturation() -> void:
	print("Saturación por ruta (10 libres, −3 % cada uno, piso 60):")
	var c: SimComercio = _sim().comercio
	_check(c.saturation(10) == 100, "10 comerciantes: 100 %")
	_check(c.saturation(11) == 97, "11: 97 %")
	_check(c.saturation(20) == 70, "20: 70 % (rinden como 14)")
	_check(c.saturation(30) == 60, "30: piso 60 %")


# ------------------------------------------------------------------ viaje

func _trip_and_pay() -> void:
	print("Viaje al neutral: cobra al volver, no al cargar; no cuenta para lo disputado:")
	var s := _sim()
	var home := _put(s, "mercado", 0, s.bases[0].x + 6, s.bases[0].y + 6)
	var neu: SimEntity = s.comercio.neutrals[0]
	var u := _trader(s, 0, home)
	s.push_command({"t": "target", "player": 0, "ids": [u.id], "target": neu.id})
	s.step()
	_check(u.order == SimEntity.Order.TRADE, "clic derecho en el neutral: orden de ruta")
	var r0: int = s.players[0]["res"]["riqueza"]
	var loaded := _step_until(s, func() -> bool: return u.trade_gain > 0, 4000)
	var expect := s.comercio.gain(0, home, neu)
	_check(loaded and u.trade_gain == expect, "cargó %d (esperado %d) en %d s" % [u.trade_gain, expect, s.tick * s.tick_ms / 1000])
	_check(s.players[0]["res"]["riqueza"] == r0, "todavía no cobró")
	var g := u.trade_gain
	var paid := _step_until(s, func() -> bool: return s.players[0]["res"]["riqueza"] > r0, 4000)
	_check(paid and s.players[0]["res"]["riqueza"] - r0 == g, "cobró %d al volver, a los %d s" % [s.players[0]["res"]["riqueza"] - r0, s.tick * s.tick_ms / 1000])
	var book: Dictionary = s.players[0]["stats"].get("origen", {})
	_check(int(book.get("comercio", {}).get("riqueza", 0)) == g, "libro: «comercio» %d" % int(book.get("comercio", {}).get("riqueza", 0)))
	var disp := 0
	for v in s.players[0]["disp"]:
		disp += int(v)
	_check(disp == 0, "lo disputado sigue en 0")
	_check(u.order == SimEntity.Order.TRADE and u.trade_leg == SimComercio.Leg.IDA, "vuelve a salir")
	# Si lo matan cargado, no cobra.
	_step_until(s, func() -> bool: return u.trade_gain > 0, 4000)
	var r1: int = s.players[0]["res"]["riqueza"]
	s._kill(u)
	for i in 50:
		s.step()
	_check(s.players[0]["res"]["riqueza"] == r1, "muerto con la carga: no cobra nada")


func _ally() -> void:
	print("Mercado aliado: 100 % y el aliado recibe 20 % creado:")
	var s := _sim(4, {"equipos": [0, 0, 1, 1], "ubicacion_equipos": "juntos"})
	var home := _put(s, "mercado", 0, s.bases[0].x + 4, s.bases[0].y + 4)
	var amk := _put(s, "mercado", 1, s.bases[1].x + 4, s.bases[1].y + 4)
	_check(s.comercio.dest_kind(0, amk) == "aliado", "el mercado del aliado es destino")
	var u := _trader(s, 0, home)
	s.push_command({"t": "target", "player": 0, "ids": [u.id], "target": amk.id})
	var a0: int = s.players[1]["res"]["riqueza"]
	var r0: int = s.players[0]["res"]["riqueza"]
	var g := s.comercio.gain(0, home, amk)
	var paid := _step_until(s, func() -> bool: return s.players[0]["res"]["riqueza"] > r0, 6000)
	var got: int = s.players[0]["res"]["riqueza"] - r0
	var extra: int = s.players[1]["res"]["riqueza"] - a0
	_check(paid and got == g, "el dueño cobra %d (esperado %d)" % [got, g])
	_check(extra == g * 20 / 100, "el aliado recibe %d (20 %% de %d)" % [extra, g])


# ------------------------------------------------------------------ bloqueo

func _blocked() -> void:
	print("Mercado tomado: 6 de población enemiga y nadie propio: vuelve vacío con «Ruta cortada»:")
	var s := _sim()
	var home := _put(s, "mercado", 0, s.bases[0].x + 6, s.bases[0].y + 6)
	var neu: SimEntity = s.comercio.neutrals[0]
	for i in 6:
		var t := s.map.nearest_free(neu.tx + 1 + i % 3, neu.ty + 4 + i / 3, 4, 1)
		var w := s.spawn_unit("guerrero", 1, t.x * P + P / 2, t.y * P + P / 2)
		w.order = SimEntity.Order.HOLD
	var u := _trader(s, 0, home)
	var r0: int = s.players[0]["res"]["riqueza"]
	s.push_command({"t": "target", "player": 0, "ids": [u.id], "target": neu.id})
	var cut := []
	var got_cut := _step_until(s, func() -> bool:
		for ev in s.events:
			if ev["t"] == "ruta_cortada":
				cut.append(ev)
		return not cut.is_empty(), 4000)
	_check(got_cut and int(cut[0]["player"]) == 0 and cut[0]["motivo"] == "tomado", "aviso «Ruta cortada» con lugar (%s)" % [str(cut[0]) if got_cut else "nada"])
	_check(u.trade_gain == 0 and u.trade_leg == SimComercio.Leg.VUELTA, "vuelve vacío")
	_step_until(s, func() -> bool: return u.trade_leg == SimComercio.Leg.IDA, 4000)
	_check(s.players[0]["res"]["riqueza"] == r0, "no cobró nada")
	# Un solo aviso por ruta hasta que se reabra.
	var again := 0
	for i in 3000:
		s.step()
		for ev in s.events:
			if ev["t"] == "ruta_cortada":
				again += 1
	_check(again == 0, "el aviso no se repite (otro viaje cortado: %d avisos)" % again)
	_check(int(s.comercio.stats.get(0, {}).get("cortes", 0)) >= 2, "cortes contados: %d" % int(s.comercio.stats.get(0, {}).get("cortes", 0)))


func _walled() -> void:
	print("Muralla que cierra el mercado: el camino no llega y la ruta queda cortada:")
	var s := _sim()
	var home := _put(s, "mercado", 0, s.bases[0].x + 6, s.bases[0].y + 6)
	var neu: SimEntity = s.comercio.neutrals[0]
	for yy in range(neu.ty - 2, neu.ty + 5):
		for xx in range(neu.tx - 2, neu.tx + 5):
			if (xx == neu.tx - 2 or xx == neu.tx + 4 or yy == neu.ty - 2 or yy == neu.ty + 4) and s.map.occupant(xx, yy) == -1:
				s.spawn_building("muralla", 1, xx, yy, true)
	var u := _trader(s, 0, home)
	s.push_command({"t": "target", "player": 0, "ids": [u.id], "target": neu.id})
	var cut := []
	var got_cut := _step_until(s, func() -> bool:
		for ev in s.events:
			if ev["t"] == "ruta_cortada":
				cut.append(ev)
		return not cut.is_empty(), 6000)
	_check(got_cut and cut[0]["motivo"] == "cerrado", "aviso «Ruta cortada» por el camino cerrado (%s)" % [str(cut[0]) if got_cut else "nada"])


func _finalize() -> void:
	Sim.soltar_todas()
