extends SceneTree
## Peleas aisladas para medir si la micro paga (proceso/23, C-31). La escribió el jugador
## veterano de AoE4 (proceso/22); queda como prueba fija del combate.
## Uso: godot --headless --path . -s tests/micro.gd

const O := SimEntity.Order
const P := 1000


func _init() -> void:
	print("== A. 10 honderos contra 10 guerreros, los dos con ataque en movimiento")
	_fight("hondero", "guerrero", 10, 10, "nada")
	print("== B. Lo mismo, pero los honderos retroceden cuando un guerrero se acerca (kiteo)")
	_fight("hondero", "guerrero", 10, 10, "kitear")
	print("== C. 10 honderos contra 10 lanceros (distancia contra línea)")
	_fight("hondero", "lancero", 10, 10, "nada")
	print("== D. 10 guerreros contra 10 lanceros (choque contra línea)")
	_fight("guerrero", "lancero", 10, 10, "nada")
	print("== E. 8 jinetes contra 10 honderos (choque contra distancia)")
	_fight("jinete", "hondero", 8, 10, "nada")
	print("== F. 10 honderos con todo el fuego a un blanco por vez (foco) contra 10 guerreros")
	_fight("hondero", "guerrero", 10, 10, "foco")
	print("== G. Retirada: 6 jinetes + 6 lanceros pasan junto a 8 honderos con orden de mover (sin ataque)")
	_retreat(false)
	print("== H. La misma retirada, suelta (Alt)")
	_retreat(true)
	quit()


func _sim() -> Sim:
	var s := Sim.new(3, 2, null, {"civs": ["guaranies", "mapuches"], "terreno": "llano", "sin_sitios": true})
	# Despejar el centro: sin recursos en un radio de 14 casillas.
	return s


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


func _fight(ta: String, tb: String, na: int, nb: int, mode: String) -> void:
	var s := _sim()
	var c := s.map.n / 2
	var a := _spawn(s, ta, 0, na, c - 9, c - 1)
	var b := _spawn(s, tb, 1, nb, c + 5, c - 1)
	s.push_command({"t": "move", "player": 0, "ids": a, "x": (c + 8) * P, "y": c * P, "amove": true})
	s.push_command({"t": "move", "player": 1, "ids": b, "x": (c - 8) * P, "y": c * P, "amove": true})
	var hp0 := [_hp(s, a), _hp(s, b)]
	var t := 0
	while t < 1200 and _alive(s, a) > 0 and _alive(s, b) > 0:
		if t % 5 == 0 and t > 0:
			if mode == "kitear":
				for id in a:
					var u: SimEntity = s.by_id.get(id)
					if u == null or not u.alive:
						continue
					var foe := s.find_enemy(u, 2200, true)
					if foe != null:
						# alejarse 3 casillas en la dirección contraria
						var dx := u.x - foe.x
						var dy := u.y - foe.y
						var l := maxi(1, int(sqrt(float(dx * dx + dy * dy))))
						s.push_command({"t": "move", "player": 0, "ids": [id], "x": u.x + dx * 3000 / l, "y": u.y + dy * 3000 / l, "suelto": true})
					elif u.order == O.IDLE or u.order == O.MOVE and u.group < 0:
						s.push_command({"t": "move", "player": 0, "ids": [id], "x": (c + 8) * P, "y": c * P, "amove": true, "suelto": true})
			elif mode == "foco":
				var tgt := -1
				var low := 1 << 30
				for id in b:
					var e: SimEntity = s.by_id.get(id)
					if e != null and e.alive and e.hp < low:
						low = e.hp
						tgt = id
				if tgt >= 0:
					s.push_command({"t": "target", "player": 0, "ids": a, "target": tgt})
		s.step()
		t += 1
	print("   %.1f s · quedan %s %d/%d (vida %d%%) · %s %d/%d (vida %d%%)" % [t / 10.0, ta, _alive(s, a), na, _hp(s, a) * 100 / maxi(1, hp0[0]), tb, _alive(s, b), nb, _hp(s, b) * 100 / maxi(1, hp0[1])])


func _retreat(loose: bool) -> void:
	var s := _sim()
	var c := s.map.n / 2
	var jin := _spawn(s, "jinete", 0, 6, c - 12, c - 2)
	var lan := _spawn(s, "lancero", 0, 6, c - 12, c + 1)
	var hon := _spawn(s, "hondero", 1, 8, c - 2, c + 5)
	var ids := jin + lan
	s.players[0]["age"] = 2
	s.push_command({"t": "move", "player": 0, "ids": ids, "x": (c + 14) * P, "y": c * P, "suelto": loose})
	var first_arrive := -1
	var all_arrive := -1
	for t in 400:
		s.step()
		var arrived := 0
		for id in ids:
			var e: SimEntity = s.by_id.get(id)
			if e != null and e.alive and absi(e.x - (c + 14) * P) < 3000 and absi(e.y - c * P) < 3000:
				arrived += 1
		if arrived > 0 and first_arrive < 0:
			first_arrive = t
		if arrived == _alive(s, ids) and all_arrive < 0 and arrived > 0:
			all_arrive = t
	print("   llegan %d/12 (jinetes %d, lanceros %d); primero a los %.1f s, todos a los %.1f s; vida de los jinetes %d" % [_alive(s, ids), _alive(s, jin), _alive(s, lan), first_arrive / 10.0, all_arrive / 10.0, _hp(s, jin)])
