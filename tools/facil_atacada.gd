extends SceneTree
## La fácil atacada no se multiplica (jugador nuevo, ronda 4). El jugador 0 no tiene IA: desde el
## minuto `--desde` deja `--tropa` guerreros quietos en el borde de la base de la fácil, hacia el
## centro del mapa (se reponen cuando caen): un acoso que la deja «amenazada» todo el tiempo sin
## tirarle nada, como el principiante sin asedio que sigue el aviso «A y clic en la base rival».
## Se anota el ejército y la población de la fácil por minuto. En el informe: de 39 a 147 de
## población (novato4.gd, semilla 7).
##   godot --headless --path . -s tools/facil_atacada.gd -- --minutes=30 --seeds=7,21 --desde=12 --tropa=4


func _init() -> void:
	var args := {"minutes": "30", "seeds": "7,21", "desde": "12", "tropa": "4", "civ": "tawantinsuyu", "casillas": "18"}
	for a in OS.get_cmdline_user_args():
		var kv := a.trim_prefix("--").split("=", true, 1)
		args[kv[0]] = kv[1] if kv.size() > 1 else "1"
	for sd_s in String(args["seeds"]).split(","):
		var s := Sim.new(int(sd_s), 2, null, {"civs": ["guaranies", args["civ"]], "terreno": "llano", "sin_sitios": true})
		s.ais = [SimAI.new(s, 1, "facil")]
		var base: Vector2i = s.bases[1]
		var max_army := 0
		var max_pop := 0
		var linea := ""
		while s.tick < int(args["minutes"]) * 600 and not s.game_over:
			s.step()
			if s.tick >= int(args["desde"]) * 600 and s.tick % 50 == 0:
				var mine := 0
				for e in s.actives:
					mine += 1 if e.owner == 0 and e.is_unit() and e.fn == "choque" else 0
				var mid := s.map.n / 2
				var dx := mid - base.x
				var dy := mid - base.y
				var dl := maxi(1, absi(dx) + absi(dy))
				var k := int(args["casillas"])
				for i in int(args["tropa"]) - mine:
					var u := s.spawn_unit("guerrero", 0, (base.x + dx * k / dl) * 1000 + i * 600, (base.y + dy * k / dl) * 1000)
					s.push_command({"t": "mantener", "player": 0, "ids": [u.id]})
			if s.tick % 600 == 0:
				var army := 0
				for e in s.actives:
					army += 1 if e.owner == 1 and e.is_unit() and e.is_military() else 0
				max_army = maxi(max_army, army)
				max_pop = maxi(max_pop, int(s.players[1]["pop"]))
				linea += " %d:%d/%d" % [s.tick / 600, army, s.players[1]["pop"]]
		print("semilla %s  min:ejército/pob%s" % [sd_s, linea])
		print("semilla %s  máximo ejército %d, población %d" % [sd_s, max_army, max_pop])
	quit()
