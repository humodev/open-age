extends SceneTree
## Partida IA contra IA con resumen por minuto (docs/08, "Pruebas").
## Uso: godot --headless --path . -s tests/ai_match.gd -- --seed=N --minutes=M

func _init() -> void:
	var args := {}
	for a in OS.get_cmdline_user_args():
		var kv := a.trim_prefix("--").split("=", true, 1)
		args[kv[0]] = kv[1] if kv.size() > 1 else "1"
	var s := Sim.new(int(args.get("seed", "1234")))
	s.ais = [SimAI.new(s, 0), SimAI.new(s, 1)]
	var minutes := int(args.get("minutes", "30"))
	var t0 := Time.get_ticks_msec()
	for m in minutes:
		for i in 600:
			s.step()
			for ev in s.events:
				if ev["t"] in ["age", "defeat", "victory"]:
					print("  [%s] %s" % [_t(s.tick), ev])
		var line := "%s " % _t(s.tick)
		for pid in 2:
			var p: Dictionary = s.players[pid]
			var mil := 0
			for e in s.actives:
				if e.owner == pid and e.is_military():
					mil += 1
			line += "| J%d edad %d pob %3d/%3d ejército %3d bajas %3d " % [pid, p["age"], p["pop"], p["pop_cap"], mil, p["stats"]["bajas"]]
		print(line)
		if s.game_over:
			break
	print("ganador=%d · %.2f ms por tick" % [s.winner, (Time.get_ticks_msec() - t0) / float(s.tick)])
	quit()


func _t(tick: int) -> String:
	var sec := tick / 10
	return "%02d:%02d" % [sec / 60, sec % 60]
