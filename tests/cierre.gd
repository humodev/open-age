extends SceneTree
## Cierre del juego (proceso/24, paso 6e): abre el menú, opcionalmente pasa por una partida,
## y pide cerrar la ventana como lo haría el sistema. El juego tiene que salir solo, en orden,
## con código 0 y sin "double free" ni objetos colgados.
##   godot --headless --path . -s tests/cierre.gd                            menú y cerrar
##   godot --headless --path . -s tests/cierre.gd -- --menu --partidas=3     del menú a 3 partidas seguidas y cerrar
##   godot --headless --path . -s tests/cierre.gd -- --menu --boton          menú y botón «Salir» en vez de la ventana
## (main.gd lee los mismos argumentos: sin --menu arranca directo en una partida.)

var _main: Node
var _frames := 0
var _partidas := 0
var _reinicios := 0
var _pedido := false
var _boton := false


func _init() -> void:
	for a in OS.get_cmdline_user_args():
		if a == "--boton":
			_boton = true
		elif a.begins_with("--partidas="):
			_partidas = maxi(1, int(a.get_slice("=", 1)))
	_main = (load("res://src/game/main.tscn") as PackedScene).instantiate()
	_poner.call_deferred()
	process_frame.connect(_cuadro)


func _poner() -> void:
	root.add_child(_main)
	current_scene = _main


func _cuadro() -> void:
	_frames += 1
	if _pedido:
		if _frames > 600:
			print("CIERRE: FALLO (no salió solo)")
			quit(1)
		return
	if _frames % 40 == 0 and _reinicios < _partidas:
		_reinicios += 1
		print("cierre: partida %d" % _reinicios)
		_main.call("_start", {"civ": "guaranies", "rival": "mapuches", "terreno": "llano", "seed": str(_reinicios), "mute": "1"})
		return
	if _frames >= 40 * (_partidas + 1) + 20:
		_pedido = true
		if _boton:
			var b := _buscar_salir(_main)
			print("cierre: botón «Salir» del menú: ", b != null)
			if b == null:
				quit(1)
				return
			b.pressed.emit()
			return
		print("cierre: se pide cerrar la ventana")
		_main.propagate_notification(Node.NOTIFICATION_WM_CLOSE_REQUEST)


func _buscar_salir(n: Node) -> Button:
	if n is Button and (n as Button).text == "Salir" and (n as Button).is_visible_in_tree():
		return n
	for c in n.get_children():
		var b := _buscar_salir(c)
		if b != null:
			return b
	return null
