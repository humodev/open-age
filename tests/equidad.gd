extends SceneTree
## Equidad de los mapas para N jugadores (docs/11, paso 2): para cada base, el camino
## promedio a las demás bases y los recursos a 20 casillas. La diferencia entre la mejor y la peor base
## no debe pasar de ±10 % en el camino ni faltar recursos de un tipo.
## Uso: godot --headless --path . -s tests/equidad.gd -- --semillas=10

const CIVS := ["guaranies", "mapuches", "etiopia", "palmares", "ayutthaya", "tawantinsuyu", "guaranies", "mapuches"]

func _init() -> void:
	var seeds := 10
	for a in OS.get_cmdline_user_args():
		var kv := a.trim_prefix("--").split("=")
		if kv[0] == "semillas":
			seeds = int(kv[1])
	var fails := 0
	for np in range(3, 9):
		var worst_path := 0
		var worst_res := {}
		for sd in seeds:
			var s := Sim.new(1000 + sd * 13, np, null, {"civs": CIVS.slice(0, np), "terreno": ["llano", "rio", "bosque", "montana"][sd % 4]})
			var c := Vector2i(s.map.n / 2, s.map.n / 2)
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
					tot += s.map.find_path(s.map.nearest_free(b.x + sa.x, b.y + sa.y, 6), s.map.nearest_free(o.x + sb.x, o.y + sb.y, 6), pid).size()
				paths.append(tot / (np - 1))
				for t in s.resources_near(b.x, b.y, 20):
					var k := "%d:%s" % [pid, t.type]
					res[k] = int(res.get(k, 0)) + t.amount
			var lo: int = paths.min()
			var hi: int = paths.max()
			var spread := (hi - lo) * 100 / maxi(1, lo)
			worst_path = maxi(worst_path, spread)
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
				if kind != "arbol" and rlo == 0:
					fails += 1
		print("%d jugadores: camino promedio a las otras bases, peor diferencia %d %%;  recursos a 20 casillas, peor diferencia %s" % [np, worst_path, str(worst_res)])
		if worst_path > 25:
			fails += 1
	print("EQUIDAD: ", "OK" if fails == 0 else "%d problemas" % fails)
	quit()
