extends SceneTree
## Los edificios que pone cada misión al armarse entran en el mapa (proceso/59: con los tamaños
## nuevos, como AoE4). Por misión: los edificios iniciales del jugador, la base de cada rival
## (2 casas, cuartel, torre desde la II, 2 granjas) y lo que piden los objetivos de destruir.
## Sale con código 1 si falta alguno.
##   godot --headless --path . -s tests/escenarios_caben.gd

func _count(s: Sim, pid: int, type: String) -> int:
	var n := 0
	for e in s.actives:
		if e.alive and e.owner == pid and e.type == type:
			n += 1
	return n


func _init() -> void:
	var fallas := 0
	var revisadas := 0
	for f in DirAccess.get_files_at("res://data/campanas"):
		if not f.ends_with(".json"):
			continue
		var camp: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/campanas/" + f))
		for m: Dictionary in camp["misiones"]:
			var s := SimScenario.create(m, camp["civ"])
			var pide := [] # [jugador, tipo, n]
			for b: Dictionary in (m.get("jugador", {}) as Dictionary).get("edificios", []):
				pide.append([0, b["tipo"], int(b.get("n", 1))])
			var rivals: Array = m.get("rivales", [])
			for i in rivals.size():
				var pid := i + 1
				pide.append([pid, "casa", 2])
				pide.append([pid, "cuartel", 1])
				if int((rivals[i] as Dictionary).get("edad", 1)) >= 2:
					pide.append([pid, "torre", 1])
				pide.append([pid, "granja", 2])
			for o: Dictionary in m.get("objetivos", []):
				if o["tipo"] == "destruir":
					var pr: Dictionary = o["params"]
					var who := int(pr.get("jugador", 1))
					if who > 0 and who < s.players.size():
						pide.append([who, pr["tipo"], int(pr.get("n", 1))])
			var faltan := []
			for p: Array in pide:
				if not s.dp(p[0]).edificios.has(p[1]):
					continue # el tipo no es de ese pueblo (el motor lo saltea igual)
				var hay := _count(s, p[0], p[1])
				if hay < int(p[2]):
					faltan.append("j%d %s %d/%d" % [p[0], p[1], hay, p[2]])
			revisadas += 1
			if faltan.is_empty():
				print("%-16s OK (%d pedidos)" % [m["id"], pide.size()])
			else:
				fallas += 1
				print("%-16s FALTAN %s" % [m["id"], ", ".join(faltan)])
	print("misiones: %d, con faltantes: %d" % [revisadas, fallas])
	print("ESCENARIOS: %s" % ("OK" if fallas == 0 else "FALLA"))
	quit(0 if fallas == 0 else 1)
