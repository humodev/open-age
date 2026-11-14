extends SceneTree
## Movimiento en grupo (proceso/21, docs/diseno/jugabilidad/03-propuesta.md §5.5): mide cómo
## llega un grupo mandado lejos. Es la línea de base del plan; los pasos de formación y
## grupo en marcha tienen que mejorarla.
##   - diferencia de llegada: entre la primera y la última unidad que llega (s);
##   - dispersión: a cuántas casillas del centro del grupo queda la más alejada al llegar;
##   - estiramiento: la mayor distancia al centro del grupo durante la marcha.
## Uso: godot --headless --path . -s tests/grupos.gd [-- --objetivo=1]
##   Con --objetivo=1 falla si no se cumplen los objetivos de la propuesta (3 s y 4 casillas).

const CASES := [
	["24 militares mixtos a 40 casillas", ["lancero", "guerrero", "hondero", "jinete"], 24, 40],
	["12 aldeanos a 40 casillas", ["aldeano"], 12, 40],
	["12 aldeanos a 6 casillas", ["aldeano"], 12, 6],
]


func _init() -> void:
	var strict := OS.get_cmdline_user_args().has("--objetivo=1")
	var fails := 0
	for c in CASES:
		var r := _measure(c[1], c[2], c[3])
		print("%-36s llegada %5.1f s · dispersión %4.1f casillas · estiramiento %4.1f casillas · llegaron %d/%d" % [c[0], r["spread_s"], r["disp"], r["stretch"], r["arrived"], c[2]])
		if r["arrived"] < c[2]:
			fails += 1
		if strict and c[3] >= 20 and (r["spread_s"] > 3.0 or r["disp"] > 4.0):
			fails += 1
	print("GRUPOS: ", "OK" if fails == 0 else "%d fallas" % fails)
	quit()


func _measure(types: Array, count: int, dist: int) -> Dictionary:
	var s := Sim.new(3, 2, null, {"civs": ["mapuches", "guaranies"], "terreno": "llano", "sin_sitios": true})
	# Un lugar despejado: se limpian los recursos y edificios de una franja del mapa.
	var y0 := s.map.n / 2
	var x0 := 20
	for e in s.entities.duplicate():
		if e.alive and (e.is_resource() or e.is_building()) and absi(e.ty - y0) < 14 and e.tx > x0 - 12 and e.tx < x0 + dist + 12:
			s.remove_quietly(e)
			s.map.clear(e.tx, e.ty, e.w, e.h)
	var ids := []
	for i in count:
		var u := s.spawn_unit(types[i % types.size()], 0, (x0 + (i % 6)) * 1000 + 500, (y0 - 3 + i / 6) * 1000 + 500)
		ids.append(u.id)
	var gx := (x0 + dist) * 1000
	var gy := y0 * 1000
	s.push_command({"t": "move", "player": 0, "ids": ids, "x": gx, "y": gy})
	var arrive := {}
	var stretch := 0
	for t in 1200:
		s.step()
		var cx := 0
		var cy := 0
		for id in ids:
			var u: SimEntity = s.by_id[id]
			cx += u.x
			cy += u.y
		cx /= ids.size()
		cy /= ids.size()
		for id in ids:
			var u: SimEntity = s.by_id[id]
			stretch = maxi(stretch, Sim.dist(u.x, u.y, cx, cy))
			if not arrive.has(id) and u.order == SimEntity.Order.IDLE:
				arrive[id] = s.tick
		if arrive.size() == ids.size():
			break
	var first := 1 << 30
	var last := 0
	for id in arrive:
		first = mini(first, arrive[id])
		last = maxi(last, arrive[id])
	var ax := 0
	var ay := 0
	for id in ids:
		ax += s.by_id[id].x
		ay += s.by_id[id].y
	ax /= ids.size()
	ay /= ids.size()
	var disp := 0
	for id in ids:
		disp = maxi(disp, Sim.dist(s.by_id[id].x, s.by_id[id].y, ax, ay))
	return {"spread_s": (last - first) * s.tick_ms / 1000.0 if arrive.size() > 0 else -1.0, "disp": disp / 1000.0, "stretch": stretch / 1000.0, "arrived": arrive.size()}
