extends SceneTree
## Estilos de la IA (reglas.json → estilos_ia): cada estilo contra una IA que no
## ataca, midiendo cuánto entra a la base rival y cuánto daño hace.
## Uso: godot --headless --path . -s tests/estilos_ia.gd -- --minutes=20

func _init() -> void:
	var minutes := 20
	for a in OS.get_cmdline_user_args():
		var kv := a.trim_prefix("--").split("=")
		if kv[0] == "minutes":
			minutes = int(kv[1])
	var data := SimData.load_default()
	var fails := 0
	for style in data.reglas["estilos_ia"]:
		for sd in [3, 11]:
			var s := Sim.new(700 + sd, 2, null, {"civs": ["guaranies", "mapuches"], "terreno": "llano"})
			var victim := SimAI.new(s, 0, "normal")
			victim.personality = "pasiva"
			var ai := SimAI.new(s, 1, "dificil")
			ai.personality = style
			s.ais = [victim, ai]
			var capital: SimEntity = null
			for e in s.actives:
				if e.owner == 0 and e.capital:
					capital = e
			var inside := 0 # ticks-unidad del ejército del estilo dentro de 20 casillas de la capital rival
			var start_v := 0
			while s.tick < minutes * 600 and not s.game_over:
				s.step()
				if s.tick % 50 == 0:
					for e in s.actives:
						if e.alive and e.owner == 1 and e.is_unit() and e.fn != "civil" and Sim.dist(e.x, e.y, capital.x, capital.y) < 20000:
							inside += 1
			var lost_v: int = s.players[0]["stats"]["muertes"]
			var lost_b := 0
			for e in s.entities:
				if e.owner == 0 and e.is_building() and not e.alive:
					lost_b += 1
			var sites := 0
			for e in s.actives:
				if e.alive and e.def.get("sagrado", false) and e.holder == 1:
					sites += 1
			print("%-10s semilla %2d  dentro de la base: %5d  bajas que causó: %3d  edificios destruidos: %2d  sitios: %d  %s" % [style, sd, inside, lost_v, lost_b, sites, ("ganó " + str(s.winner)) if s.game_over else ""])
			if not data.reglas["estilos_ia"][style].get("ataca_base", true) and lost_b > 2:
				fails += 1
	print("ESTILOS: ", "OK" if fails == 0 else "%d partidas donde un estilo sin ataque destruyó la base" % fails)
	quit()
