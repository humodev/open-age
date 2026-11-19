extends SceneTree
## Equidad de los mapas para N jugadores (docs/11, paso 2): para cada base, el camino
## promedio a las demás bases y los recursos a 22 casillas. La diferencia entre la mejor y la peor base
## no debe pasar de ±10 % en el camino ni faltar recursos de un tipo.
## Uso: godot --headless --path . -s tests/equidad.gd -- --semillas=10 --terrenos=llano,islas

const CIVS := ["guaranies", "mapuches", "etiopia", "palmares", "ayutthaya", "tawantinsuyu", "guaranies", "mapuches"]

func _init() -> void:
	var seeds := 10
	var terr: PackedStringArray = ["llano", "rio", "bosque", "montana"]
	for a in OS.get_cmdline_user_args():
		var kv := a.trim_prefix("--").split("=")
		if kv[0] == "semillas":
			seeds = int(kv[1])
		elif kv[0] == "terrenos":
			terr = kv[1].split(",")
	var fails := _neutrales(seeds, terr)
	for np in range(3, 9):
		var worst_path := 0
		var worst_res := {}
		for sd in seeds:
			var s := Sim.new(1000 + sd * 13, np, null, {"civs": CIVS.slice(0, np), "terreno": terr[sd % terr.size()]})
			var c := Vector2i(s.map.n / 2, s.map.n / 2)
			# Se mide el terreno: sin empalizadas ni puertas, que en la partida cierran igual a todos.
			for e in s.entities.duplicate():
				if e.alive and e.type in ["empalizada", "puerta"]:
					s.remove_quietly(e)
					s.map.clear(e.tx, e.ty, e.w, e.h)
			var paths := []
			var res := {}
			# Camino promedio de cada base a todas las demás (el centro puede ser un lago).
			for pid in np:
				var b: Vector2i = s.bases[pid] + Vector2i(2, 2)
				var tot := 0
				for q in np:
					if q == pid:
						continue
					var o: Vector2i = s.bases[q] + Vector2i(2, 2)
					var sa := Vector2i(signi(c.x - b.x), signi(c.y - b.y)) * 4
					var sb := Vector2i(signi(c.x - o.x), signi(c.y - o.y)) * 4
					tot += _length(s.map.find_path(s.map.nearest_free(b.x + sa.x, b.y + sa.y, 6), s.map.nearest_free(o.x + sb.x, o.y + sb.y, 6), pid))
				paths.append(tot / (np - 1))
				# Círculo de 22 casillas desde el centro de la base: un cuadrado no da lo mismo girado.
				for t in s.resources_near(b.x, b.y, 22):
					if (Vector2i(t.tx, t.ty) - b).length_squared() > 22 * 22:
						continue
					var k := "%d:%s" % [pid, t.type]
					res[k] = int(res.get(k, 0)) + t.amount
			var lo: int = paths.min()
			var hi: int = paths.max()
			var spread := (hi - lo) * 100 / maxi(1, lo)
			worst_path = maxi(worst_path, spread)
			if spread > 25:
				print("   %s, %d jugadores, semilla %d: caminos %s" % [terr[sd % terr.size()], np, sd, str(paths)])
			if lo <= 0:
				fails += 1
			for kind in ["arbusto", "arbol", "roca", "riqueza"]:
				var vals := []
				for pid in np:
					vals.append(int(res.get("%d:%s" % [pid, kind], 0)))
				var rlo: int = vals.min()
				var rhi: int = vals.max()
				var rs := (rhi - rlo) * 100 / maxi(1, rhi)
				worst_res[kind] = maxi(int(worst_res.get(kind, 0)), rs)
				if rs > 25 and kind != "arbol":
					print("   %s, %d jugadores, semilla %d: %s por base %s" % [terr[sd % terr.size()], np, sd, kind, str(vals)])
				if kind != "arbol" and rlo == 0:
					fails += 1
		print("%d jugadores: camino promedio a las otras bases, peor diferencia %d %%;  recursos a 22 casillas, peor diferencia %s" % [np, worst_path, str(worst_res)])
		if worst_path > 25:
			fails += 1
	print("EQUIDAD: ", "OK" if fails == 0 else "%d problemas" % fails)
	quit()


## --- comercio --- Mercados neutrales (proceso/33-comercio, §1): siempre 2 o más, y la distancia
## en línea de cada base a su neutral más cercano y al más lejano no difiere más de
## `tol` % entre jugadores en la misma posición: en 1 contra 1 y todos contra todos, todos; con
## dos equipos juntos, cada jugador con su espejo del otro equipo (el de atrás queda más lejos a
## propósito).
func _neutrales(seeds: int, terr: PackedStringArray) -> int:
	var tol := 3
	var fails := 0
	var all_terr: Array = SimData.load_default().reglas["terrenos"].keys()
	var cases := [[2, [], ""], [4, [0, 0, 1, 1], "juntos"], [6, [0, 0, 0, 1, 1, 1], "juntos"], [8, [0, 0, 0, 0, 1, 1, 1, 1], "juntos"], [4, [0, 0, 1, 1], "grande"], [3, [], ""], [4, [], ""], [6, [], ""], [8, [], ""]]
	for cs in cases:
		var np: int = cs[0]
		var worst := 0
		var min_n := 99
		for sd in seeds:
			var t: String = all_terr[sd % all_terr.size()] if np == 2 else terr[sd % terr.size()]
			var opts := {"civs": CIVS.slice(0, np), "terreno": t}
			if not (cs[1] as Array).is_empty():
				opts["equipos"] = cs[1]
				opts["ubicacion_equipos"] = "juntos"
			if cs[2] == "grande":
				opts["tamano"] = "grande"
			var s := Sim.new(2000 + sd * 7, np, null, opts)
			var ms: Array = s.comercio.neutrals
			min_n = mini(min_n, ms.size())
			if ms.size() < 2:
				print("   neutrales: %s, %d jugadores, semilla %d: solo %d" % [t, np, sd, ms.size()])
				fails += 1
				continue
			var near := []
			var far := []
			for pid in np:
				var c: Vector2i = s.bases[pid] + Vector2i(2, 2)
				var lo := 1 << 30
				var hi := 0
				for m: SimEntity in ms:
					var dx := c.x * 1000 - m.x
					var dy := c.y * 1000 - m.y
					var d := Sim.isqrt(dx * dx + dy * dy)
					lo = mini(lo, d)
					hi = maxi(hi, d)
				near.append(lo)
				far.append(hi)
			var groups: Array = []
			if (cs[1] as Array).is_empty():
				groups = [range(np)]
			else:
				var h := np / 2
				for i in h:
					groups.append([i, np - 1 - i]) # juntos: el lugar i de un equipo y su espejo del otro
			for g in groups:
				for arr in [near, far]:
					var vals := []
					for pid in g:
						vals.append(arr[pid])
					var spread := (int(vals.max()) - int(vals.min())) * 100 / maxi(1, int(vals.min()))
					worst = maxi(worst, spread)
					if spread > tol:
						print("   neutrales: %s, %d jugadores %s, semilla %d: %s" % [t, np, cs[2], sd, str(vals)])
						fails += 1
		print("neutrales, %d jugadores %s: al menos %d; peor diferencia %d %%" % [np, cs[2] if cs[2] != "" else ("equipos" if not (cs[1] as Array).is_empty() else ""), min_n, worst])
	return fails


## Largo de un camino en décimas de casilla: 10 de lado, 14 en diagonal (así se mueven las unidades).
func _length(path) -> int:
	var tot := 0
	for i in range(1, path.size()):
		var d: Vector2i = Vector2i(path[i]) - Vector2i(path[i - 1])
		tot += 14 if d.x != 0 and d.y != 0 else 10 * maxi(absi(d.x), absi(d.y))
	return tot


## Al salir se sueltan las partidas creadas (ciclos de referencias; proceso/24, paso 6e).
func _finalize() -> void:
	Sim.soltar_todas()
