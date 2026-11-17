extends SceneTree
## Sitios sagrados en mapas de varios (jugadores de prueba, proceso/22): al menos uno por
## jugador en todos los terrenos con agua y fortines. El del centro puede faltar si es un lago.
## Uso: godot --headless --path . -s tests/sitios.gd
func _init() -> void:
	var civs := ["guaranies", "mapuches", "etiopia", "palmares", "ayutthaya", "tawantinsuyu", "guaranies", "mapuches"]
	var fails := 0
	for t in ["islas", "rio", "fortines", "bosque", "delta", "llano"]:
		for np in [3, 4, 6, 8]:
			var worst := 99
			for sd in 6:
				var s := Sim.new(5 + sd * 48, np, null, {"civs": civs.slice(0, np), "terreno": t})
				var n := 0
				for e in s.entities:
					if e.alive and e.def.get("sagrado", false):
						n += 1
				worst = mini(worst, n)
			if worst < np:
				fails += 1
				print("  FALLA %s con %d jugadores: %d sitios" % [t, np, worst])
	print("SITIOS: ", "OK" if fails == 0 else "%d mapas con pocos sitios" % fails)
	quit()


## Al salir se sueltan las partidas creadas (ciclos de referencias; proceso/24, paso 6e).
func _finalize() -> void:
	Sim.soltar_todas()
