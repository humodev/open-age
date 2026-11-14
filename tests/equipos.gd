extends SceneTree
## Partidas por equipos (docs/11, pasos 1 y 4): 2v2 (y el mismo con los equipos
## cambiados de lado), 3v3 y todos contra todos con 6, de IA. Nadie debe matar a un
## aliado y la partida termina con un equipo ganador (o sigue abierta al tiempo límite).
## También: las puertas de un aliado lo dejan pasar y las de un rival no.
## Uso: godot --headless --path . -s tests/equipos.gd -- --minutes=30 [--solo=3v3]

func _init() -> void:
	var minutes := 30
	var only := ""
	for a in OS.get_cmdline_user_args():
		var kv := a.trim_prefix("--").split("=")
		if kv[0] == "minutes":
			minutes = int(kv[1])
		elif kv[0] == "solo":
			only = kv[1]
	var fails := _gates()
	var setups := [
		["2v2", ["tawantinsuyu", "mapuches", "guaranies", "etiopia"], [0, 1, 0, 1]],
		["2v2", ["tawantinsuyu", "mapuches", "guaranies", "etiopia"], [1, 0, 1, 0]],
		["2v2", ["palmares", "ayutthaya", "mapuches", "tawantinsuyu"], [0, 1, 0, 1]],
		["2v2", ["palmares", "ayutthaya", "mapuches", "tawantinsuyu"], [1, 0, 1, 0]],
		["3v3", ["tawantinsuyu", "mapuches", "guaranies", "etiopia", "palmares", "ayutthaya"], [0, 1, 0, 1, 0, 1]],
		["3v3", ["tawantinsuyu", "mapuches", "guaranies", "etiopia", "palmares", "ayutthaya"], [1, 0, 1, 0, 1, 0]],
		["ffa6", ["tawantinsuyu", "mapuches", "guaranies", "etiopia", "palmares", "ayutthaya"], [0, 1, 2, 3, 4, 5]],
	]
	for st in setups:
		if only != "" and st[0] != only:
			continue
		var np: int = st[1].size()
		var s := Sim.new(321, np, null, {"civs": st[1], "equipos": st[2], "terreno": "llano"})
		s.ais = []
		for pid in np:
			s.ais.append(SimAI.new(s, pid))
		var friendly := 0
		var kills := 0
		var tributes := 0
		while s.tick < minutes * 600 and not s.game_over:
			s.step()
			for ev in s.events:
				if ev["t"] == "tributo":
					tributes += 1
				if ev["t"] == "died" and int(ev.get("by", -1)) >= 0 and int(ev.get("owner", -1)) >= 0:
					kills += 1
					if not s.enemies(int(ev["by"]), int(ev["owner"])) and int(ev["by"]) != int(ev["owner"]):
						friendly += 1
		var line := "%-4s %s equipos %s  %d:%02d  bajas %d  fuego amigo %d  tributos %d" % [st[0], str(st[1]), str(st[2]), s.tick / 600, (s.tick / 10) % 60, kills, friendly, tributes]
		if s.game_over:
			line += "  ganó el equipo %d" % s.winner_team
		for pid in np:
			line += "  | j%d %s edad %d %s" % [pid, str(st[1][pid]).left(4), s.players[pid]["age"], "derrotado" if s.players[pid]["defeated"] else "en pie"]
		print(line)
		if friendly > 0:
			fails += 1
	print("EQUIPOS: ", "OK" if fails == 0 else "%d problemas" % fails)
	quit()


## Fortines 2v2: el jugador 0 entra por la puerta de su aliado (2) y no por la del rival (1).
func _gates() -> int:
	var s := Sim.new(77, 4, null, {"civs": ["guaranies", "mapuches", "etiopia", "palmares"], "equipos": [0, 1, 0, 1], "terreno": "fortines"})
	var bad := 0
	for pair in [[2, true], [1, false]]:
		var owner: int = pair[0]
		var gate: SimEntity = null
		for e in s.entities:
			if e.alive and e.owner == owner and e.type == "puerta":
				gate = e
				break
		if gate == null:
			print("puertas: el jugador %d no tiene puerta" % owner)
			bad += 1
			continue
		var passes := not s.map.is_solid(gate.tx, gate.ty, 0)
		print("puertas: la del jugador %d %s al jugador 0" % [owner, "deja pasar" if passes else "no deja pasar"])
		if passes != pair[1]:
			bad += 1
	return bad
