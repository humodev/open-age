extends SceneTree
## Criterio de H1 (docs/02): 200 unidades peleando sin caídas de rendimiento.

func _init() -> void:
	for a in OS.get_cmdline_user_args():
		if a == "--jugadores=6":
			_six()
			quit()
			return
	var s := Sim.new(7)
	var types := ["guerrero", "hondero", "lancero"]
	for pid in 2:
		for i in 100:
			var x := (40 + (i % 10) * 1) * 1000 + 500 + pid * 14000
			var y := (54 + i / 10) * 1000 + 500
			s.spawn_unit(types[i % 3], pid, x, y)
	# Que se encuentren en el medio.
	var ids0 := []
	var ids1 := []
	for e in s.entities:
		if e.is_unit() and e.is_military():
			(ids0 if e.owner == 0 else ids1).append(e.id)
	s.push_command({"t": "move", "player": 0, "ids": ids0, "x": 64000, "y": 59000, "amove": true})
	s.push_command({"t": "move", "player": 1, "ids": ids1, "x": 44000, "y": 59000, "amove": true})
	var worst := 0
	var total := 0
	var n := 600
	for i in n:
		var t0 := Time.get_ticks_usec()
		s.step()
		var dt := Time.get_ticks_usec() - t0
		total += dt
		worst = maxi(worst, dt)
	var alive := 0
	for e in s.entities:
		if e.is_unit():
			alive += 1
	print("200 unidades, %d ticks: promedio %.2f ms, peor %.2f ms, presupuesto %d ms; vivas al final: %d" % [n, total / 1000.0 / n, worst / 1000.0, s.tick_ms, alive])
	quit()


## docs/11, paso 6: 6 jugadores × 150 unidades que convergen al centro, y una
## partida de 6 IA de 20 minutos. A ×4 de velocidad entran 4 ticks en los 100 ms
## de presupuesto: cada tick tiene que quedar por debajo de 25 ms en promedio.
func _six() -> void:
	var s := Sim.new(7, 6, null, {"civs": ["guaranies", "mapuches", "etiopia", "palmares", "ayutthaya", "tawantinsuyu"], "terreno": "llano"})
	var types := ["guerrero", "hondero", "lancero"]
	var c := s.map.n * 500
	for pid in 6:
		var b: Vector2i = s.bases[pid] + Vector2i(2, 2)
		var ids := []
		for i in 150:
			var t := s.map.nearest_free(b.x + (i % 15) - 7, b.y + i / 15 - 5, 12)
			var u := s.spawn_unit(types[i % 3], pid, t.x * 1000 + 500, t.y * 1000 + 500)
			ids.append(u.id)
		s.push_command({"t": "move", "player": pid, "ids": ids, "x": c, "y": c, "amove": true})
	var worst := 0
	var total := 0
	var n := 900
	for i in n:
		var t0 := Time.get_ticks_usec()
		s.step()
		var dt := Time.get_ticks_usec() - t0
		total += dt
		worst = maxi(worst, dt)
	print("6 jugadores × 150 unidades, %d ticks: promedio %.2f ms, peor %.2f ms (a ×4: %.0f ms de 100 por cuadro)" % [n, total / 1000.0 / n, worst / 1000.0, total / 1000.0 / n * 4])
	var g := Sim.new(11, 6, null, {"civs": ["guaranies", "mapuches", "etiopia", "palmares", "ayutthaya", "tawantinsuyu"], "terreno": "llano"})
	g.ais = []
	for pid in 6:
		g.ais.append(SimAI.new(g, pid))
	worst = 0
	total = 0
	var late := 0
	var late_n := 0
	n = 20 * 600
	var units := 0
	for i in n:
		var t0 := Time.get_ticks_usec()
		g.step()
		var dt := Time.get_ticks_usec() - t0
		total += dt
		worst = maxi(worst, dt)
		if i >= n - 600:
			late += dt
			late_n += 1
	for e in g.entities:
		if e.alive and e.is_unit():
			units += 1
	print("6 IA, 20 minutos: promedio %.2f ms, último minuto %.2f ms, peor %.2f ms; unidades vivas al final %d" % [total / 1000.0 / n, late / 1000.0 / maxi(1, late_n), worst / 1000.0, units])
