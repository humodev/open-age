extends SceneTree
## A qué le pega la tropa en partidas IA contra IA (proceso/24, 5d: elección de blancos).
## Cuenta los golpes de las unidades militares (sin el asedio) según el blanco: militar que le
## pega, otro militar, aldeano, edificio que dispara, otro edificio, camino o pieza transitable.
## Cuenta también las bajas militares que murieron pegándole a un edificio.
##   godot --headless --path . -s tools/blancos.gd -- --pares=guaranies:tawantinsuyu,... --seeds=2 --min=30 [--dif=normal]

const O := SimEntity.Order


func _init() -> void:
	var pares := "guaranies:tawantinsuyu,mapuches:tawantinsuyu,etiopia:ayutthaya"
	var seeds := 2
	var minutes := 30
	var dif := "normal"
	for a in OS.get_cmdline_user_args():
		var kv := a.trim_prefix("--").split("=", true, 1)
		match kv[0]:
			"pares": pares = kv[1]
			"seeds": seeds = int(kv[1])
			"min": minutes = int(kv[1])
			"dif": dif = kv[1]
	var tot := {}
	var tot_dead := [0, 0]
	for par in pares.split(","):
		var pair: Array = Array(par.split(":"))
		for sd in seeds:
			var s := Sim.new(500 + sd * 17, 2, null, {"civs": pair})
			s.ais = [SimAI.new(s, 0, dif), SimAI.new(s, 1, dif)]
			var hits := {}
			var on_bld := {} # id -> le pegaba a un edificio en el último paso
			var dead := [0, 0] # bajas militares: total, pegándole a un edificio
			while s.tick < minutes * 600 and not s.game_over:
				s.step()
				for ev in s.events:
					if ev["t"] == "hit":
						var a: SimEntity = s.by_id.get(ev["a"])
						var b: SimEntity = s.by_id.get(ev["b"])
						if a == null or b == null or not a.is_unit() or not a.is_military() or a.fn == "asedio":
							continue
						var k := _cls(s, a, b)
						hits[k] = int(hits.get(k, 0)) + 1
					elif ev["t"] == "died" and on_bld.has(ev["id"]):
						dead[0] += 1
						if on_bld[ev["id"]]:
							dead[1] += 1
				on_bld.clear()
				for e in s.actives:
					if e.alive and e.is_unit() and e.is_military() and e.fn != "asedio" and e.owner >= 0:
						var t: SimEntity = s.by_id.get(e.target) if e.order == O.ATTACK else null
						on_bld[e.id] = t != null and t.is_building()
			var total := 0
			for k in hits:
				total += hits[k]
				tot[k] = int(tot.get(k, 0)) + hits[k]
			tot_dead[0] += dead[0]
			tot_dead[1] += dead[1]
			print("%s vs %s semilla %d: %s · ganador %s · golpes %d: %s · bajas militares %d (pegándole a un edificio %d)" % [pair[0], pair[1], 500 + sd * 17,
				"%d:%02d" % [s.tick / 600, (s.tick / 10) % 60], str(pair[s.winner]) if s.winner >= 0 else "ninguno",
				total, _fmt(hits, total), dead[0], dead[1]])
	var gt := 0
	for k in tot:
		gt += tot[k]
	print("\nTOTAL golpes %d: %s · bajas militares %d (pegándole a un edificio %d)" % [gt, _fmt(tot, gt), tot_dead[0], tot_dead[1]])
	quit()


func _cls(s: Sim, a: SimEntity, b: SimEntity) -> String:
	if b.is_unit():
		if not b.is_military():
			return "aldeano"
		return "militar_que_pega" if b.target == a.id and (b.order == O.ATTACK or b.order == O.HOLD) else "militar"
	if b.is_building():
		if b.def.get("transitable", false):
			return "camino" if b.def.get("camino", false) else "transitable"
		return "edif_dispara" if b.def.has("ataque") else "edificio"
	return "otro"


func _fmt(h: Dictionary, total: int) -> String:
	var out := []
	for k in ["militar_que_pega", "militar", "aldeano", "edif_dispara", "edificio", "camino", "transitable", "otro"]:
		if h.has(k):
			out.append("%s %d (%d%%)" % [k, h[k], h[k] * 100 / maxi(1, total)])
	return ", ".join(out)
