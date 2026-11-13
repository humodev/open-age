extends SceneTree
## Repetición: una partida grabada, pasada por JSON y reproducida llega al mismo estado (D-012).

func _init() -> void:
	var opts := {"civs": ["guaranies", "mapuches"], "terreno": "llano"}
	var a := Sim.new(321, 2, null, opts)
	a.ais = [SimAI.new(a, 1)]
	var vill := []
	for e in a.actives:
		if e.owner == 0 and e.fn == "civil":
			vill.append(e.id)
	var b0 := a.bases[0]
	for i in 1800:
		if i == 5:
			var bush := a.find_resource(0, "alimento", b0.x * 1000, b0.y * 1000, 30000)
			a.push_command({"t": "target", "player": 0, "ids": vill.slice(0, 4), "target": bush.id})
		if i == 30:
			a.push_command({"t": "build", "player": 0, "ids": vill.slice(4, 6), "type": "casa", "tx": b0.x - 3, "ty": b0.y + 6})
		if i == 200:
			var cap: SimEntity = null
			for e in a.actives:
				if e.owner == 0 and e.capital:
					cap = e
			a.push_command({"t": "train", "player": 0, "building": cap.id, "type": "aldeano"})
		a.step()
	var text := JSON.stringify({"comandos": a.recording})
	var back: Dictionary = JSON.parse_string(text)
	var b := Sim.new(321, 2, null, opts)
	b.ais = [SimAI.new(b, 1)]
	b.schedule(Sim.intify(back["comandos"]))
	for i in 1800:
		b.step()
	var ok := a.state_hash() == b.state_hash()
	print("comandos grabados=%d hash original=%d repetición=%d" % [a.recording.size(), a.state_hash(), b.state_hash()])
	print("REPETICIÓN: %s" % ("OK" if ok else "FALLO"))
	quit(0 if ok else 1)
