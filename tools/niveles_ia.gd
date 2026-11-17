extends SceneTree
## ¿La IA compra a tiempo lo que reemplaza al bono de ataque por edad? (proceso/26, paso 5;
## docs/diseno/27, paso 1). Partidas IA contra IA: por jugador, el minuto de cada edad, de la
## herrería I de ataque (ataque_cc_1 y ataque_dist_1, con el +10 %), de cada nivel veterano y
## élite y de cada tanda de la herrería (paso 2), y cuántos niveles tenía al terminar. En la
## columna de la herrería: ac/ad = ataque cuerpo a cuerpo / distancia, rc/rd = armadura contra
## cuerpo a cuerpo / contra distancia, con la tanda (ac2 = ataque cuerpo a cuerpo II). Las partidas se reparten como en el torneo (--parte=i/n).
##
## Uso:
##   godot --headless --path . -s tools/niveles_ia.gd -- --minutes=30 --seeds=1 --dificultad=normal
##   godot --headless --path . -s tools/niveles_ia.gd -- --dificultad=facil,experta --parte=0/3

func _init() -> void:
	var minutes := 30
	var seeds := 1
	var diffs: Array = ["normal"]
	var part := 0
	var parts := 1
	for a in OS.get_cmdline_user_args():
		var kv := a.trim_prefix("--").split("=")
		match kv[0]:
			"minutes":
				minutes = int(kv[1])
			"seeds":
				seeds = int(kv[1])
			"dificultad":
				diffs = Array(kv[1].split(","))
			"parte":
				part = int(kv[1].split("/")[0])
				parts = int(kv[1].split("/")[1])
	var data := SimData.load_default()
	var civs: Array = []
	for k in data.civs:
		if not data.civs[k].civ.get("solo_ia", false):
			civs.append(k)
	civs.sort()
	# Cada pueblo juega una vez por semilla y dificultad, contra el siguiente de la lista.
	var game_i := 0
	print("dificultad | semilla | pueblo | rival | II | ataque I (cc, dist) | III | veteranos (min) | IV | élites (min) | herrería (min) | niveles al final | ganador")
	for diff: String in diffs:
		for sd in seeds:
			for i in civs.size():
				game_i += 1
				if (game_i - 1) % parts != part:
					continue
				var pair: Array = [civs[i], civs[(i + 1 + sd) % civs.size()]]
				var s := Sim.new(2000 + i * 13 + sd * 7, 2, null, {"civs": pair})
				s.ais = [SimAI.new(s, 0, diff), SimAI.new(s, 1, diff)]
				var log := [{}, {}]
				while s.tick < minutes * 600 and not s.game_over:
					s.step()
					for ev in s.events:
						if ev["t"] == "age":
							log[ev["player"]]["edad%d" % int(ev["age"])] = s.tick
						elif ev["t"] == "tech":
							var k: String = ev["tech"]
							if s.dp(ev["player"]).tecnologias.get(k, {}).has("herreria") or k.begins_with("veterano_") or k.begins_with("elite_"):
								log[ev["player"]][k] = s.tick
				for pid in 2:
					var l: Dictionary = log[pid]
					var vets := []
					var elis := []
					var smith := []
					for k: String in l:
						if SMITH.has(k.left(k.length() - 2)) and k != "ataque_cc_1" and k != "ataque_dist_1":
							smith.append([l[k], "%s%s %s" % [SMITH[k.left(k.length() - 2)], k.right(1), _m(l[k])]])
						if k.begins_with("veterano_"):
							vets.append("%s %s" % [k.substr(9), _m(l[k])])
						elif k.begins_with("elite_"):
							elis.append("%s %s" % [k.substr(6), _m(l[k])])
					smith.sort_custom(func(a: Array, b: Array) -> bool: return int(a[0]) < int(b[0]))
					var smith_txt := ", ".join(smith.map(func(x: Array) -> String: return x[1]))
					print("%s | %d | %s | %s | %s | %s, %s | %s | %s | %s | %s | %s | %d | %d" % [diff, sd, pair[pid], pair[1 - pid], _m(l.get("edad2", -1)), _m(l.get("ataque_cc_1", -1)), _m(l.get("ataque_dist_1", -1)), _m(l.get("edad3", -1)), ", ".join(vets) if not vets.is_empty() else "-", _m(l.get("edad4", -1)), ", ".join(elis) if not elis.is_empty() else "-", smith_txt if smith_txt != "" else "-", vets.size() + elis.size(), s.winner])
	quit()


const SMITH := {"ataque_cc": "ac", "ataque_dist": "ad", "armadura_cc": "rc", "armadura_dist": "rd"}


func _m(tick: int) -> String:
	if tick < 0:
		return "-"
	return "%d:%02d" % [tick / 600, tick / 10 % 60]
