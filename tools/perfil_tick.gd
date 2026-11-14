extends SceneTree
## Perfil de un tick por partes con 6 jugadores × 150 unidades (docs/11, paso 6).
## Copia el cuerpo de `Sim.step()`: si cambia step(), actualizar acá.
## Uso: godot --headless --path . -s tools/perfil_tick.gd
func _init() -> void:
	var s := Sim.new(7, 6, null, {"civs": ["guaranies", "mapuches", "etiopia", "palmares", "ayutthaya", "tawantinsuyu"], "terreno": "llano"})
	var types := ["guerrero", "hondero", "lancero"]
	var c := s.map.n * 500
	for pid in 6:
		var b: Vector2i = s.bases[pid] + Vector2i(2, 2)
		var ids := []
		for i in 150:
			var t := s.map.nearest_free(b.x + (i % 15) - 7, b.y + i / 15 - 5, 12)
			ids.append(s.spawn_unit(types[i % 3], pid, t.x * 1000 + 500, t.y * 1000 + 500).id)
		s.push_command({"t": "move", "player": pid, "ids": ids, "x": c, "y": c, "amove": true})
	var acc := {}
	for i in 600:
		var T := {}
		var t := Time.get_ticks_usec()
		s._in_step = true
		s.events.clear()
		var cmds: Array = s._pending.get(s.tick, [])
		s._pending.erase(s.tick)
		for cc in cmds:
			s._apply(cc)
		T["cmds"] = Time.get_ticks_usec() - t; t = Time.get_ticks_usec()
		s._rebuild_hashes()
		T["hashes"] = Time.get_ticks_usec() - t; t = Time.get_ticks_usec()
		s._update_players()
		T["players"] = Time.get_ticks_usec() - t; t = Time.get_ticks_usec()
		for e in s.actives.duplicate():
			if e.alive and e.is_unit() and e.inside < 0:
				var o: int = e.order
				var t1 := Time.get_ticks_usec()
				s._update_unit(e)
				acc["o%d" % o] = acc.get("o%d" % o, 0) + Time.get_ticks_usec() - t1
				acc["n%d" % o] = acc.get("n%d" % o, 0) + 1000
			elif e.alive and e.is_building():
				s._update_building(e)
		T["units"] = Time.get_ticks_usec() - t; t = Time.get_ticks_usec()
		s._separate()
		T["separate"] = Time.get_ticks_usec() - t; t = Time.get_ticks_usec()
		if s.tick % 10 == 0:
			s.mods.tick_second()
		T["mods"] = Time.get_ticks_usec() - t; t = Time.get_ticks_usec()
		for pid in 6:
			if (s.tick + pid) % int(s.data.reglas["niebla_cada_ticks"]) == 0:
				s._update_fog(pid)
		T["fog"] = Time.get_ticks_usec() - t; t = Time.get_ticks_usec()
		if s._dirty:
			s._cleanup()
		T["cleanup"] = Time.get_ticks_usec() - t
		s.tick += 1
		s._in_step = false
		for k in T:
			acc[k] = acc.get(k, 0) + T[k]
	for k in acc:
		print("%-10s %.2f ms" % [k, acc[k] / 600000.0])
	quit()
