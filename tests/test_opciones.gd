extends SceneTree
## Opciones guardadas (src/game/ui/opciones.gd): ida y vuelta por ConfigFile y escala automática.
## Usa un archivo de prueba propio: no toca user://opciones.cfg.
##   godot --headless --path . -s tests/test_opciones.gd

const PRUEBA := "user://opciones_prueba.cfg"


func _init() -> void:
	var fallas: Array[String] = []
	var check := func(nombre: String, cond: bool) -> void:
		print(("OK    " if cond else "FALLO ") + nombre)
		if not cond:
			fallas.append(nombre)

	Opciones.restablecer()
	Opciones.escala = 1.25
	Opciones.paleta = "tritanopia"
	Opciones.musica = 35.0
	Opciones.ambiente = 10.0
	Opciones.bordes = false
	Opciones.velocidad_camara = 150.0
	Opciones.barras_siempre = true
	Opciones.guardar(PRUEBA)
	Opciones.restablecer()
	check.call("restablecer vuelve a los valores de fábrica", Opciones.escala == 0.0 and Opciones.paleta == "normal" and Opciones.bordes)
	Opciones.cargar(PRUEBA)
	check.call("se recupera la escala (%s)" % Opciones.escala, Opciones.escala == 1.25)
	check.call("se recupera la paleta (%s)" % Opciones.paleta, Opciones.paleta == "tritanopia")
	check.call("se recuperan los volúmenes", Opciones.musica == 35.0 and Opciones.ambiente == 10.0 and Opciones.efectos == 100.0)
	check.call("se recupera la cámara", not Opciones.bordes and Opciones.velocidad_camara == 150.0)
	check.call("se recuperan las barras siempre visibles", Opciones.barras_siempre)
	Opciones.solo_lectura = true
	Opciones.escala = 0.8
	Opciones.guardar(PRUEBA)
	Opciones.cargar(PRUEBA)
	check.call("en solo lectura no se escribe", Opciones.escala == 1.25)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(PRUEBA))

	# --- veterano ronda 4 --- teclas reasignables (src/game/ui/teclas.gd)
	Opciones.solo_lectura = false
	Teclas.de_fabrica()
	check.call("de fábrica: H recorre los centros", Teclas.accion(KEY_H) == "centro" and Teclas.tecla("grilla_0") == KEY_Q)
	check.call("de fábrica: sin choques", Teclas.choques().is_empty())
	check.call("de fábrica: F7 es el marcador 1 y 0 el grupo 0", Teclas.accion(KEY_F7) == "marcador_1" and Teclas.accion(KEY_0) == "grupo_0")
	var otra := Teclas.asignar("centro", KEY_J)
	check.call("asignar J al centro: J lo hace y H queda libre", otra == "" and Teclas.accion(KEY_J) == "centro" and Teclas.accion(KEY_H) == "")
	otra = Teclas.asignar("centro", KEY_M)
	check.call("asignar una tecla usada intercambia (M era el ejército, pasa a J: %s)" % Teclas.texto("ejercito"), otra == "ejercito" and Teclas.tecla("ejercito") == KEY_J and Teclas.choques().is_empty())
	Teclas.grupos_exclusivos = true
	Opciones.guardar(PRUEBA)
	Teclas.de_fabrica()
	check.call("volver a las de fábrica deshace los cambios", Teclas.accion(KEY_H) == "centro" and Teclas.accion(KEY_M) == "ejercito" and not Teclas.grupos_exclusivos)
	Opciones.cargar(PRUEBA)
	check.call("se recuperan las teclas guardadas (centro %s, ejército %s)" % [Teclas.texto("centro"), Teclas.texto("ejercito")], Teclas.tecla("centro") == KEY_M and Teclas.tecla("ejercito") == KEY_J)
	check.call("se recuperan los grupos exclusivos", Teclas.grupos_exclusivos)
	var cf := ConfigFile.new()
	cf.load(PRUEBA)
	check.call("el archivo guarda las teclas por nombre (centro = %s)" % cf.get_value("teclas", "centro", "?"), cf.get_value("teclas", "centro", "") == "M" and cf.get_value("teclas", "marcador_4", "?") == "")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(PRUEBA))
	Teclas.perfil("aoe4")
	check.call("perfil AoE4: marcadores en F1–F4", Teclas.accion(KEY_F1) == "marcador_1" and Teclas.accion(KEY_F4) == "marcador_4")
	check.call("perfil AoE4: los paneles siguen teniendo tecla y no hay choques (%s)" % str(Teclas.choques()), Teclas.choques().is_empty() and Teclas.tecla("ayuda") != 0 and Teclas.tecla("economia") != 0 and Teclas.tecla("puntaje") != 0)
	check.call("perfil AoE4: grupos exclusivos", Teclas.grupos_exclusivos)
	check.call("Esc, Mayús y las flechas no se asignan", Teclas.reservada(KEY_ESCAPE) and Teclas.reservada(KEY_SHIFT) and Teclas.reservada(KEY_LEFT) and not Teclas.reservada(KEY_J))
	Teclas.de_fabrica()
	# --- fin veterano ronda 4 ---

	# --- veterano ronda 5 --- atajos globales, los ocho marcadores y las barras al pelear
	Teclas.de_fabrica()
	check.call("de fábrica: B campana, N todos los aldeanos y P la producción militar", Teclas.accion(KEY_B) == "campana" and Teclas.accion(KEY_N) == "todos_aldeanos" and Teclas.accion(KEY_P) == "produccion_todos")
	check.call("de fábrica: los atajos nuevos no chocan (%s)" % str(Teclas.choques()), Teclas.choques().is_empty())
	var marcadores := 0
	for a: Array in Teclas.acciones():
		if str(a[0]).begins_with("marcador_"):
			marcadores += 1
	check.call("la lista de teclas tiene los 8 marcadores (%d)" % marcadores, marcadores == 8)
	Teclas.perfil("aoe4")
	check.call("perfil AoE4: los atajos nuevos siguen y no hay choques (%s)" % str(Teclas.choques()), Teclas.choques().is_empty() and Teclas.tecla("campana") == KEY_B and Teclas.tecla("marcador_8") == 0)
	# Un archivo de antes, sin los atajos nuevos, donde el jugador puso la B en los centros: la
	# campana queda sin tecla en vez de chocar.
	var vieja := ConfigFile.new()
	vieja.set_value("teclas", "centro", "B")
	vieja.set_value("teclas", "ejercito", "M")
	vieja.save(PRUEBA)
	Opciones.cargar(PRUEBA)
	check.call("archivo viejo con B en los centros: B sigue en los centros, la campana sin tecla y sin choques", Teclas.tecla("centro") == KEY_B and Teclas.tecla("campana") == 0 and Teclas.tecla("todos_aldeanos") == KEY_N and Teclas.choques().is_empty())
	DirAccess.remove_absolute(ProjectSettings.globalize_path(PRUEBA))
	Teclas.de_fabrica()
	Opciones.restablecer()
	check.call("de fábrica: las tropas sanas que pelean no muestran barra", not Opciones.barras_pelea)
	Opciones.barras_pelea = true
	Opciones.guardar(PRUEBA)
	Opciones.restablecer()
	Opciones.cargar(PRUEBA)
	check.call("se recupera «barras de las tropas sanas al pelear»", Opciones.barras_pelea)
	Opciones.restablecer()
	Teclas.de_fabrica()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(PRUEBA))
	# --- fin veterano ronda 5 ---

	# --- ronda 6 --- la primera victoria contra la IA queda guardada (y «Restablecer» no la borra)
	Opciones.victorias = {}
	var r1: Array = Opciones.registrar_victoria("facil", PRUEBA)
	check.call("la primera victoria contra la IA es la primera (y la primera en Fácil)", r1 == [true, true])
	Opciones.victorias = {}
	Opciones.restablecer()
	Opciones.cargar(PRUEBA)
	check.call("se recupera la victoria contra la Fácil (%s)" % str(Opciones.victorias), int(Opciones.victorias.get("facil", 0)) == 1)
	var r2: Array = Opciones.registrar_victoria("facil", PRUEBA)
	check.call("la segunda en Fácil ya no es la primera", r2 == [false, false] and int(Opciones.victorias.get("facil", 0)) == 2)
	var r3: Array = Opciones.registrar_victoria("normal", PRUEBA)
	check.call("la primera en Normal es primera en esa dificultad, no contra la IA", r3 == [false, true])
	Opciones.restablecer()
	check.call("restablecer no borra las victorias", int(Opciones.victorias.get("normal", 0)) == 1)
	Opciones.victorias = {}
	DirAccess.remove_absolute(ProjectSettings.globalize_path(PRUEBA))
	# --- fin ronda 6 ---

	# Escala automática: 1,0 a 1080p, ×2 a 4K, 0,85 como piso a 1366×768.
	Opciones.escala = 0.0
	check.call("automática a 1920×1080 = 1,0", is_equal_approx(Opciones.factor(Vector2(1920, 1080)), 1.0))
	check.call("automática a 3840×2160 = 2,0", is_equal_approx(Opciones.factor(Vector2(3840, 2160)), 2.0))
	check.call("automática a 1366×768 = 0,85 (%d %%)" % Opciones.auto_pct(Vector2(1366, 768)), is_equal_approx(Opciones.factor(Vector2(1366, 768)), 0.85))
	check.call("150 % a 1366×768 deja al menos 1280×720 lógicos", Vector2(1366, 768).x / Opciones.factor(Vector2(1366, 768), 1.5) >= 1280.0 - 0.5)
	var chica := Vector2(1024, 600)
	var logico := chica / Opciones.factor(chica)
	check.call("la automática deja al menos 1280×720 lógicos en 1024×600 (%d×%d)" % [logico.x, logico.y], logico.x >= 1279.5 and logico.y >= 719.5)
	print("OPCIONES: ", "OK" if fallas.is_empty() else "FALLO (%d)" % fallas.size())
	quit(0 if fallas.is_empty() else 1)
