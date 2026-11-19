extends SceneTree
## Cuánto tarda en cargar una partida de 4 contra 4 en el minuto M (proceso/37-red/02):
## antes (armar y re-simular desde el tick 0) y con la foto (armar y volcarla).
## `godot --headless --path . -s tests/carga_4v4.gd -- --minutos=30`


func _init() -> void:
	var minutos := 30
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--minutos="):
			minutos = int(a.get_slice("=", 1))
	var t := minutos * 600
	var opts := {"civs": ["mapuches", "etiopia", "palmares", "ayutthaya", "guaranies", "tawantinsuyu", "adal", "tupies"], "terreno": "llano", "equipos": [0, 1, 0, 1, 0, 1, 0, 1]}
	var ia := {}
	for p in 8:
		ia[str(p)] = {"dificultad": "dificil", "estilo": "normal"}
	var meta := {"semilla": 2026, "opciones": opts, "ias": [0, 1, 2, 3, 4, 5, 6, 7], "ia_cfg": ia}
	var t0 := Time.get_ticks_msec()
	var a := Guardado.armar(meta.merged({"comandos": []}))
	while a.tick < t:
		a.step()
		Guardado.foto_periodica(a)
	var ms_juego := Time.get_ticks_msec() - t0
	print("partida: %d ticks en %d ms · %d entidades (%d activas)" % [a.tick, ms_juego, a.entities.size(), a.actives.size()])
	t0 = Time.get_ticks_msec()
	var path := "user://pruebas/carga_4v4.json"
	Guardado.escribir(path, Guardado.datos(meta, a))
	print("guardar (con la foto): %d ms · .foto %d KB" % [Time.get_ticks_msec() - t0, FileAccess.get_file_as_bytes(Guardado.ruta_foto(path)).size() / 1024])
	var d := Guardado.leer(path)
	# Con la foto.
	t0 = Time.get_ticks_msec()
	var b := Guardado.armar(d, t)
	var ms_foto := Time.get_ticks_msec() - t0
	var ok_b := b.tick == t and b.state_hash() == a.state_hash()
	print("DESPUÉS (foto): %d ms · hash %s" % [ms_foto, "igual" if ok_b else "DISTINTO"])
	# Saltar al medio de la repetición.
	t0 = Time.get_ticks_msec()
	var m := Guardado.armar(d, t / 2 + 300)
	Guardado.avanzar(m, t / 2 + 300)
	print("salto al minuto %d: desde la foto del tick %d, %d ms" % [(t / 2 + 300) / 600, (t / 2 + 300) / 3000 * 3000, Time.get_ticks_msec() - t0])
	# Antes: re-simular todo.
	t0 = Time.get_ticks_msec()
	var c := Guardado.armar(d)
	Guardado.avanzar(c, t)
	var ms_antes := Time.get_ticks_msec() - t0
	var ok_c := c.state_hash() == a.state_hash()
	print("ANTES (re-simular): %d ms (%d ticks/s) · hash %s" % [ms_antes, t * 1000 / maxi(1, ms_antes), "igual" if ok_c else "DISTINTO"])
	Guardado.borrar(path)
	print("CARGA 4v4 minuto %d: %s · %.1f s → %.1f s" % [minutos, "OK" if ok_b and ok_c else "FALLO", ms_antes / 1000.0, ms_foto / 1000.0])
	quit(0 if ok_b and ok_c else 1)


func _finalize() -> void:
	Sim.soltar_todas()
