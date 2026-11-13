extends SceneTree
## Humo de campañas: cada misión se arma y corre unos minutos sin errores (docs/campanas/).

func _init() -> void:
	var minutes := 3
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--minutes="):
			minutes = int(a.split("=")[1])
	for f in DirAccess.get_files_at("res://data/campanas"):
		if not f.ends_with(".json"):
			continue
		var camp: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/campanas/" + f))
		for m: Dictionary in camp["misiones"]:
			var s := SimScenario.create(m, camp["civ"])
			var dialogs := 0
			var objs := 0
			for i in minutes * 600:
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
			print("%-16s %-28s jugadores=%d terreno=%-7s diálogos=%d cambios=%d resultado=%s %s" % [m["id"], m["titulo"].substr(0, 28), s.players.size(), s.terrain, dialogs, objs, sc.result, states])
	quit()
