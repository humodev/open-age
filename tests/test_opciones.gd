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
