extends SceneTree
## Disputa de sitios sagrados (proceso/24, paso 5b): partidas IA contra IA en espejo (cada civ
## contra sí misma) con tiempo límite, y por partida cuántas veces arranca la cuenta de victoria
## por sitios, cuántas se interrumpe (alguien recupera un sitio), cuántas llega a cero (gana por
## sitios), cuántos sitios se le quitan al rival y con cuánto ejército vivo pierde quien pierde
## por sitios (el veterano perdió con 94 militares vivos, ronda 3).
## Uso: godot --headless --path . -s tools/disputa_sitios.gd -- [--modo=normal|experta]
##        [--civs=a,b] [--seeds=41,42] [--terrenos=llano,rio] [--minutes=30] [--parte=i/n] [--apagado]
## --modo=normal: normal contra normal; --modo=experta: experta contra difícil (la experta cambia
## de lado con la semilla). --apagado: sin `disputa_sitios` en ninguna dificultad (como antes).
func _init() -> void:
	var civs := ["tawantinsuyu", "mapuches", "guaranies", "etiopia", "palmares", "ayutthaya"]
	var seeds := [41, 42]
	var terrains := ["llano"]
	var minutes := 30
	var mode := "normal"
	var part := 0
	var parts := 1
	var off := false
	for a in OS.get_cmdline_user_args():
		var kv := a.trim_prefix("--").split("=")
		match kv[0]:
			"modo": mode = kv[1]
			"civs": civs = Array(kv[1].split(","))
			"seeds": seeds = Array(kv[1].split(",")).map(func(x): return int(x))
			"terrenos": terrains = Array(kv[1].split(","))
			"minutes": minutes = int(kv[1])
			"apagado": off = true
			"parte":
				part = int(kv[1].split("/")[0])
				parts = int(kv[1].split("/")[1])
	var dif := ["normal", "normal"] if mode == "normal" else ["experta", "dificil"]
	print("disputa de sitios · %s contra %s · %d minutos · semillas %s · terrenos %s%s" % [dif[0], dif[1], minutes, seeds, terrains, " · APAGADO" if off else ""])
	print("cuenta: arranca / se interrumpe / llega a cero (por jugador A/B; A = %s) · quitados = sitios que se le sacan al rival · ejército del que pierde por sitios" % dif[0])
	var tot := {"arranca": 0, "corta": 0, "cero": 0, "quita": 0, "partidas": 0, "sitios": 0, "conquista": 0, "puntos": 0, "gana_a": 0}
	var gi := 0
	for civ in civs:
		for terrain in terrains:
			for sd in seeds:
				gi += 1
				if (gi - 1) % parts != part:
					continue
				var a: int = sd % 2 # el jugador A cambia de lado con la semilla
				var data := SimData.load_default()
				if off:
					for k in data.reglas["dificultades"]:
						data.reglas["dificultades"][k].erase("disputa_sitios")
				var s := Sim.new(sd, 2, data, {"civs": [civ, civ], "terreno": terrain, "tiempo_limite_min": minutes})
				s.ais = [null, null]
				s.ais[a] = SimAI.new(s, a, dif[0])
				s.ais[1 - a] = SimAI.new(s, 1 - a, dif[1])
				var starts := [0, 0]
				var cuts := [0, 0]
				var takes := [0, 0]
				var running := [false, false]
				var max_s := [0, 0]
				var holders := {}
				var first_cut := ""
				while not s.game_over and s.tick < (minutes + 1) * 600:
					s.step()
					if s.tick % 10 != 0:
						continue
					for pid in 2:
						var ms := int(s.players[pid].get("sitios_ms", 0))
						if ms > 0 and not running[pid]:
							starts[pid] += 1
							running[pid] = true
						elif ms == 0 and running[pid] and not s.game_over:
							cuts[pid] += 1
							running[pid] = false
							if first_cut == "":
								first_cut = "%d:%02d" % [s.tick / 600, (s.tick / 10) % 60]
						max_s[pid] = maxi(max_s[pid], ms / 1000)
					for e in s.actives:
						if e.alive and e.def.get("sagrado", false):
							var h := int(holders.get(e.id, -1))
							if e.holder != h:
								if h >= 0 and e.holder >= 0:
									takes[e.holder] += 1
								holders[e.id] = e.holder
				var how := "nadie"
				var loser_army := ""
				if s.winner >= 0:
					var reason := "puntos" if s.end_reason == "tiempo" else s.end_reason
					how = "%s (%s)" % ["A" if s.winner == a else "B", reason]
					if s.winner == a:
						tot["gana_a"] += 1
					if tot.has(reason):
						tot[reason] += 1
					if reason == "sitios":
						loser_army = " · pierde con %d militares" % _army(s, 1 - s.winner)
				tot["partidas"] += 1
				for pid in 2:
					tot["arranca"] += starts[pid]
					tot["corta"] += cuts[pid]
					tot["quita"] += takes[pid]
				var zero := [1 if s.end_reason == "sitios" and s.winner == a else 0, 1 if s.end_reason == "sitios" and s.winner == 1 - a else 0]
				tot["cero"] += zero[0] + zero[1]
				print("%-13s %-6s s%-3d %5s gana %-14s cuenta A %d/%d/%d (máx %3ds) B %d/%d/%d (máx %3ds) · quitados A %d B %d%s" % [civ, terrain, sd, "%d:%02d" % [s.tick / 600, (s.tick / 10) % 60], how, starts[a], cuts[a], zero[0], max_s[a], starts[1 - a], cuts[1 - a], zero[1], max_s[1 - a], takes[a], takes[1 - a], loser_army])
	print("\nTOTAL %d partidas · cuentas que arrancan %d, se interrumpen %d, llegan a cero %d · sitios quitados al rival %d · fin: sitios %d, conquista %d, puntos %d · gana A %d" % [tot["partidas"], tot["arranca"], tot["corta"], tot["cero"], tot["quita"], tot["sitios"], tot["conquista"], tot["puntos"], tot["gana_a"]])
	quit()


func _army(s: Sim, pid: int) -> int:
	var n := 0
	for e in s.actives:
		if e.alive and e.owner == pid and e.is_unit() and e.is_military():
			n += 1
	return n
