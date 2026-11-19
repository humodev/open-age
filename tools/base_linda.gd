extends SceneTree
## La base linda (proceso/30-fluidez/08-base-linda.md): prueba del modo foto y de la opción de
## estandartes en una partida de verdad.
##
##   godot --path . -s tools/base_linda.gd -- --civ=guaranies --terreno=llano --mute [--dir=screenshots/base-linda]
##
## Captura la partida con la interfaz, aprieta la tecla del modo foto (eventos reales) y captura
## sin interfaz; después pasa los estandartes a «ninguna» y a «todas» y cuenta los edificios rehechos.

var dir := "screenshots/base-linda"
var main: Node
var fallas := 0


func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		var kv := a.trim_prefix("--").split("=", true, 1)
		if kv[0] == "dir" and kv.size() > 1:
			dir = kv[1]
	DirAccess.make_dir_recursive_absolute(dir)
	main = load("res://src/game/main.tscn").instantiate()
	root.add_child(main)
	_correr.call_deferred()


func _frames(n: int) -> void:
	for i in n:
		await process_frame


func _shot(name: String) -> void:
	await _frames(3)
	root.get_texture().get_image().save_png("%s/%s.png" % [dir, name])
	print("captura: %s/%s.png" % [dir, name])


func _check(que: String, ok: bool) -> void:
	print("%s %s" % ["OK  " if ok else "FALLA", que])
	if not ok:
		fallas += 1


func _tecla(code: int) -> void:
	for pressed in [true, false]:
		var ev := InputEventKey.new()
		ev.physical_keycode = code as Key
		ev.keycode = code as Key
		ev.pressed = pressed
		Input.parse_input_event(ev)
		await _frames(2)


func _correr() -> void:
	await _frames(30)
	var hud: Control = main.hud
	_check("interfaz visible al empezar", hud.visible)
	await _shot("con-interfaz")
	await _tecla(Teclas.tecla("modo_foto"))
	_check("modo foto: la interfaz se oculta con %s" % Teclas.texto("modo_foto"), not hud.visible)
	await _shot("modo-foto")
	await _tecla(Teclas.tecla("modo_foto"))
	_check("modo foto: vuelve con la misma tecla", hud.visible)
	# Estandartes: al cambiar la opción, la vista rehace los edificios (BaseLinda.render).
	var antes := Opciones.banderas
	for modo in ["ninguna", "todas", "importantes"]:
		Opciones.banderas = modo
		await _frames(90)
		var pendientes := 0
		# Lo que no se ve (el rival bajo la niebla) se rehace cuando aparece.
		for id: int in main.view.visuals:
			var v: Dictionary = main.view.visuals[id]
			var e: SimEntity = main.sim.by_id.get(id)
			if v["kind"] == "building" and e != null and main.view.fog_state(e) == 2 and str(v["look"]) == "":
				pendientes += 1
		_check("estandartes «%s»: edificios rehechos" % modo, pendientes == 0 and main.view.base_linda._modo_banderas == modo)
	Opciones.banderas = antes
	print("BASE LINDA: %d fallas" % fallas)
	quit(1 if fallas > 0 else 0)
