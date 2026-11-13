extends SceneTree
## Humo de campañas: cada misión se arma y corre unos minutos sin errores (docs/campanas/).

func _init() -> void:
	var minutes := 3
	var ai_player := false
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--minutes="):
			minutes = int(a.split("=")[1])
		if a == "--ia-jugador":
			ai_player = true
	for f in DirAccess.get_files_at("res://data/campanas"):
		if not f.ends_with(".json"):
			continue
		var camp: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/campanas/" + f))
		for m: Dictionary in camp["misiones"]:
			var s := SimScenario.create(m, camp["civ"])
			if ai_player:
				# Una IA juega del lado del jugador para probar que la misión se puede ganar.
				var me := SimAI.new(s, 0, "dificil")
				me.personality = "agresiva"
				s.ais.append(me)
			var dialogs := 0
			var objs := 0
			for i in minutes * 600:
				if s.scenario.result != "":
					break
				s.step()
				for ev in s.events:
					if ev["t"] == "dialogo":
						dialogs += 1
					elif ev["t"] == "objetivo":
						objs += 1
			var sc := s.scenario
			var states := []
			for o in sc.objectives:
				states.append("%s:%s" % [o["id"], o["estado"]])
			print("%-16s %-28s %5s resultado=%-9s %s" % [m["id"], m["titulo"].substr(0, 28), "%d:%02d" % [s.tick / 600, (s.tick / 10) % 60], sc.result if sc.result != "" else "(abierta)", " ".join(states)])
	quit()
