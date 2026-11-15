extends SceneTree
## Uso: godot --headless --path . -s tools/duelo.gd -- --a=etiopia --b=mapuches (6 partidas de 25 min, con y sin grupos)
## Duelo rápido entre dos civs, con y sin movimiento en grupo (min_unidades enorme = sin grupos).
func _init() -> void:
	var a := "etiopia"
	var b := "mapuches"
	for args in OS.get_cmdline_user_args():
		if args.begins_with("--a="): a = args.split("=")[1]
		if args.begins_with("--b="): b = args.split("=")[1]
	for grouped in [true, false]:
		var wins := {a: 0, b: 0}
		for sd in 6:
			var pair := [a, b] if sd % 2 == 0 else [b, a]
			var s := Sim.new(700 + sd * 31, 2, null, {"civs": pair})
			if not grouped:
				s.data.reglas["grupo"]["min_unidades"] = 9999
			s.ais = [SimAI.new(s, 0), SimAI.new(s, 1)]
			while s.tick < 25 * 600 and not s.game_over:
				s.step()
			var w := -1
			if s.winner >= 0:
				w = s.winner
			else:
				var sc := []
				for pid in 2:
					var p: Dictionary = s.players[pid]
					sc.append(int(p["age"]) * 1000 + int(p["pop"]) * 10 + int(p["stats"]["bajas"]))
				w = 0 if sc[0] > sc[1] else 1
			wins[pair[w]] += 1
		s_print(grouped, wins)
	quit()
func s_print(g: bool, w: Dictionary) -> void:
	print("con grupos " if g else "sin grupos ", w)
