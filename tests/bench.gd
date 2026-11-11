extends SceneTree
## Criterio de H1 (docs/02): 200 unidades peleando sin caídas de rendimiento.

func _init() -> void:
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
