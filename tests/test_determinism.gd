extends SceneTree
## Dos partidas IA contra IA con la misma semilla deben dar el mismo hash en cada tick (docs/06).

const TICKS := 3000


func _init() -> void:
	var a := _make(1234)
	var b := _make(1234)
	var c := _make(99)
	var ok := true
	for i in TICKS:
		a.step()
		b.step()
		c.step()
		if a.state_hash() != b.state_hash():
			push_error("Desincronización en el tick %d" % i)
			ok = false
			break
	var p0: Dictionary = a.players[0]
	var p1: Dictionary = a.players[1]
	print("ticks=%d hash=%d" % [a.tick, a.state_hash()])
	print("J0 edad=%d pob=%d/%d res=%s stats=%s" % [p0["age"], p0["pop"], p0["pop_cap"], p0["res"], p0["stats"]])
	print("J1 edad=%d pob=%d/%d res=%s stats=%s" % [p1["age"], p1["pop"], p1["pop_cap"], p1["res"], p1["stats"]])
	print("game_over=%s winner=%d entidades=%d" % [a.game_over, a.winner, a.entities.size()])
	if a.state_hash() == c.state_hash():
		push_error("Semillas distintas dieron el mismo estado")
		ok = false
	print("DETERMINISMO: %s" % ("OK" if ok else "FALLO"))
	quit(0 if ok else 1)


func _make(seed_value: int) -> Sim:
	var s := Sim.new(seed_value)
	s.ais = [SimAI.new(s, 0), SimAI.new(s, 1)]
	return s
