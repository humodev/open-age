extends SceneTree
## Aldeanos trabados (proceso/24, paso 6c): IA contra IA (cada civ contra sí misma) y, cada
## 30 s, cuántos aldeanos del alimento están "trabados": con orden de juntar, sin carga ni
## trabajando, a 3 casillas o menos de su recurso y sin alcanzarlo (los que se deslizaban contra
## los árboles de una carne encerrada). Al final, el peor momento, la edad y el alimento.
## Uso: godot --headless --path . -s tools/aldeanos_trabados.gd -- [--civ=tawantinsuyu]
##        [--seed=41] [--dificultad=normal] [--minutes=12] [--terreno=llano]
func _init() -> void:
	var civ := "tawantinsuyu"
	var sd := 41
	var dif := "normal"
	var minutes := 12
	var terrain := "llano"
	for a in OS.get_cmdline_user_args():
		var kv := a.trim_prefix("--").split("=")
		match kv[0]:
			"civ": civ = kv[1]
			"seed": sd = int(kv[1])
			"dificultad": dif = kv[1]
			"minutes": minutes = int(kv[1])
			"terreno": terrain = kv[1]
	var s := Sim.new(sd, 2, null, {"civs": [civ, civ], "terreno": terrain})
	s.ais = [SimAI.new(s, 0, dif), SimAI.new(s, 1, dif)]
	var line := ["", ""]
	var worst := [0, 0]
	var sum := [0, 0]
	while s.tick < minutes * 600 and not s.game_over:
		s.step()
		if s.tick % 300 != 0:
			continue
		for pid in 2:
			var stuck := 0
			var food_v := 0
			for e in s.actives:
				if not (e.alive and e.owner == pid and e.type == "aldeano" and e.order == SimEntity.Order.GATHER and e.gather_kind == "alimento"):
					continue
				food_v += 1
				var t: SimEntity = s.by_id.get(e.target)
				if t == null or e.anchored or e.carry > 0:
					continue
				var d := s.dist_to(e, t)
				if d > e.radius + Sim.INTERACT and d <= 3000:
					stuck += 1
			worst[pid] = maxi(worst[pid], stuck)
			sum[pid] += stuck
			if s.tick % 600 == 0:
				line[pid] += " %d'%d/%d" % [s.tick / 600, stuck, food_v]
	for pid in 2:
		print("%s %s s%d P%d · edad %d · alimento %d · recolectado %d · trabados/del alimento por minuto:%s · peor %d, suma %d" % [civ, dif, sd, pid, s.players[pid]["age"], s.players[pid]["res"]["alimento"], s.players[pid]["stats"]["recolectado"], line[pid], worst[pid], sum[pid]])
	quit()
