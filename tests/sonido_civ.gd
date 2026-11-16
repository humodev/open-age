extends SceneTree
## Sonido por pueblo (proceso/24-tras-la-segunda-ronda/4g-sonido.md):
## 1. cada archivo de data/audio.json y de la música por pueblo carga y dura algo;
## 2. los seis pueblos tienen los cuatro sonidos;
## 3. partidas de IA contra IA con un GameAudio por jugador: al subir de edad suena la fanfarria propia y al
##    recibir un ataque, la alarma propia, sin errores;
## 4. una ráfaga de sucesos no dispara una ráfaga de sonidos.
## Uso: godot --headless --path . -s tests/sonido_civ.gd [-- --minutes=12]

const CIVS := ["tawantinsuyu", "mapuches", "guaranies", "etiopia", "palmares", "ayutthaya"]
const KINDS := ["fanfarria", "alarma", "entrenado", "orden"]

var fails := 0


func _check(ok: bool, msg: String) -> void:
	print(("ok    " if ok else "FALLA ") + msg)
	if not ok:
		fails += 1


func _init() -> void:
	# Los reproductores solo suenan dentro del árbol: se corre en el primer cuadro.
	_run.call_deferred()


func _run() -> void:
	var minutes := 12
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--minutes="):
			minutes = int(a.split("=")[1])
	var cfg := GameAudio.cfg()
	# 1 y 2: archivos.
	var paths := {}
	for civ in CIVS:
		var c: Dictionary = cfg["civs"].get(civ, {})
		for k in KINDS:
			_check(c.has(k), "%s tiene %s" % [civ, k])
			if c.has(k):
				paths[c[k]] = true
		for mood in c.get("musica", {}):
			for p in c["musica"][mood]:
				paths[p] = true
		for mood in GameAudio.CIV_MUSIC.get(civ, {}):
			for p in GameAudio.CIV_MUSIC[civ][mood]:
				paths[p] = true
	for p in paths:
		var s: AudioStream = load(GameAudio.BASE + p) if ResourceLoader.exists(GameAudio.BASE + p) else null
		_check(s != null and s.get_length() > 0.05, "carga %s (%.2f s)" % [p, s.get_length() if s != null else 0.0])
	_check(GameAudio.new()._civ_music("etiopia", "paz").size() >= 1, "Etiopía tiene música de paz propia")

	# 3: partidas.
	var played := {}  # civ -> {kind: true}
	var aged := {}    # civ -> llegó a la edad II
	for pair in [["tawantinsuyu", "mapuches"], ["etiopia", "palmares"], ["guaranies", "ayutthaya"]]:
		var s := Sim.new(77, 2, null, {"civs": pair})
		s.ais = [SimAI.new(s, 0), SimAI.new(s, 1)]
		var auds: Array[GameAudio] = []
		for pid in 2:
			var au := GameAudio.new()
			root.add_child(au)
			au.sim = s
			au.local = pid
			auds.append(au)
		var dt := s.tick_ms / 1000.0
		for i in minutes * 600:
			s.step()
			for pid in 2:
				var au := auds[pid]
				au._clock += dt
				var before: Dictionary = au._civ_next.duplicate()
				au.on_events(s.events)
				for k in au._civ_next:
					if before.get(k, -1.0) != au._civ_next[k]:
						played.get_or_add(pair[pid], {})[k] = true
		for pid in 2:
			aged[pair[pid]] = int(s.players[pid]["age"]) >= 2
			print("   %s: edad %d, sonaron %s" % [pair[pid], s.players[pid]["age"], played.get(pair[pid], {}).keys()])
			auds[pid].queue_free()
	for civ in CIVS:
		var got: Dictionary = played.get(civ, {})
		_check(got.has("fanfarria") or not aged.get(civ, false), "%s: fanfarria al subir de edad%s" % [civ, "" if aged.get(civ, false) else " (no subió en la partida; ver el suceso forzado)"])
		_check(got.has("entrenado"), "%s: sonido de entrenado" % civ)
	var alarms := CIVS.filter(func(c: String) -> bool: return played.get(c, {}).has("alarma"))
	print("   alarma propia en partida: ", alarms)

	# Ataque recibido y subida de edad forzados, para los pueblos que no los tuvieron en la partida.
	for civ in CIVS:
		var s := Sim.new(5, 2, null, {"civs": [civ, "mapuches"]})
		var au := GameAudio.new()
		root.add_child(au)
		au.sim = s
		au._clock = 100.0
		au.on_events([{"t": "age", "player": 0, "age": 2, "hito": ""}])
		au.on_events([{"t": "alert", "player": 0, "x": 0, "y": 0}])
		var streams := []
		for p in au._pool:
			if p.stream != null:
				streams.append(p.stream.resource_path.get_file())
		_check(streams.has("%s_fanfarria.ogg" % civ) and streams.has("%s_alarma.ogg" % civ), "%s: suceso de edad y de ataque → %s" % [civ, streams])
		# 4: ráfaga. 30 unidades entrenadas en el mismo cuadro y 30 órdenes: suena una de cada.
		var n0 := _sonando(au)
		for i in 30:
			au.on_events([{"t": "trained", "id": 1, "player": 0, "type": "aldeano"}])
			au.civ_sfx("orden")
		_check(_sonando(au) - n0 <= 2, "%s: ráfaga de 60 sucesos → %d sonidos" % [civ, _sonando(au) - n0])
		au.queue_free()
	# El genérico sigue para un pueblo sin sonidos propios (rival de campaña).
	var s2 := Sim.new(5, 2, null, {"civs": ["adal", "etiopia"]})
	var au2 := GameAudio.new()
	root.add_child(au2)
	au2.sim = s2
	_check(not au2.civ_sfx("fanfarria"), "adal sin fanfarria propia: suena la genérica")
	au2.queue_free()

	print("RESULTADO: ", "OK" if fails == 0 else "%d FALLAS" % fails)
	quit(1 if fails > 0 else 0)


func _sonando(au: GameAudio) -> int:
	var n := 0
	for p in au._pool:
		if p.stream != null and p.stream.resource_path.contains("/civ/"):
			n += 1
	return n
